# Load Balancing Simulation & Analytics — Technical Documentation

---

## 1. Project Conceptual Overview

This project is a full-stack, runnable simulation of the load balancing layer in distributed systems. It models the exact traffic-routing logic used by production systems like Netflix, AWS, and cloud-native service meshes — but at a scale you can observe, pause, and break on your own machine.

### Core Concepts Implemented

| Concept | Summary |
|---|---|
| **Client-Side Load Balancing** | The Flutter app itself acts as a smart client. It holds the address of every backend server and makes the routing decision before a request leaves the device. A custom Dio interceptor implements the selected algorithm on every outbound call. |
| **Server-Side Load Balancing** | The app sends every request to a single YARP gateway URL. The app is oblivious to how many backends exist. All routing intelligence lives in the gateway process — the classic proxy/API-gateway model. |
| **Header-Based Routing** | In server-side mode, the Flutter app attaches an `X-LB-Algo` HTTP header to each request. The YARP gateway reads this header and routes to the matching cluster, allowing the client to select a backend algorithm without changing the destination URL. |
| **Analytics & Execution Time Tracking** | Every backend endpoint wraps its handler in a `Stopwatch` and returns `executionTimeMs` in the JSON response. The Flutter BLoC parses this value and feeds it into a `SessionMetrics` tracker, which the user can inspect in a per-server analytics report at any point during a session. |
| **Auto-Failover & Health Checking** | The Dio interceptor's `onError` callback catches timeouts and 5xx responses, marks the failing server offline, and transparently replays the original request on the next healthy server. The UI reflects server health in real time — no user action required. |
| **Micro-Burst Stress Testing** | The dashboard exposes a custom burst controller where the user dials in exactly how many requests of each load type (Ping, CPU, I/O, Unstable) to fire simultaneously. Because the BLoC uses `concurrent()` event transformers, all requests truly fly in parallel — they do not queue behind each other. |

---

## 2. Backend Implementation (C# / .NET)

The backend is split into two distinct .NET projects: a YARP gateway that acts as the single entry point for server-side mode, and three identical API instances that serve as the actual compute nodes in both modes.

---

### The YARP Gateway

**Theory**

The gateway is a **reverse proxy**: a server that sits between the client and the real backends. The client talks only to the proxy; it has no knowledge of how many backends exist or which one will ultimately handle its request. The proxy receives the request, applies a routing policy, forwards it to one of the backend instances, and streams the response back to the client.

YARP (Yet Another Reverse Proxy) is a Microsoft-maintained library that turns an ASP.NET Core application into a fully configurable reverse proxy. Instead of writing forwarding logic manually, you declare **clusters** (groups of backend destinations) and **routes** (rules that map incoming requests to clusters).

**Header-Based Routing**

The challenge here is that the Flutter app needs to be able to *choose* which load balancing algorithm the gateway uses — without changing the URL. The solution is to have the app attach an `X-LB-Algo` HTTP header to every request. The gateway declares three separate routes, each with a `RouteHeader` match condition. When a request arrives, YARP evaluates the routes in priority order and selects the first one whose header condition is satisfied.

This means a single client URL (`http://{ip}:5000`) can result in three completely different routing behaviors purely based on a header value — no different endpoints, no query parameters.

```csharp
// ServerSideLB.Gateway/Program.cs

var destinations = new Dictionary<string, DestinationConfig>
{
    ["dest-1"] = new DestinationConfig { Address = "http://localhost:5001" },
    ["dest-2"] = new DestinationConfig { Address = "http://localhost:5002" },
    ["dest-3"] = new DestinationConfig { Address = "http://localhost:5003" },
};

builder.Services.AddReverseProxy()
    .LoadFromMemory(
        routes: new[]
        {
            // Route 1: matches when X-LB-Algo: roundRobin is present
            new RouteConfig
            {
                RouteId   = "route-rr",
                ClusterId = "cluster-rr",
                Order     = 1,
                Match = new RouteMatch
                {
                    Path    = "{**catch-all}",
                    Headers = new[]
                    {
                        new RouteHeader
                        {
                            Name   = "X-LB-Algo",
                            Values = new[] { "roundRobin" },
                            Mode   = HeaderMatchMode.ExactHeader,
                        },
                    },
                },
            },
            // Route 2: matches when X-LB-Algo: random
            // Route 3: matches when X-LB-Algo: leastConnections
            // Route 4 (fallback): no header — defaults to round-robin cluster
        },
        clusters: new[]
        {
            new ClusterConfig
            {
                ClusterId           = "cluster-rr",
                LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,
                Destinations        = destinations,
            },
            new ClusterConfig
            {
                ClusterId           = "cluster-random",
                LoadBalancingPolicy = LoadBalancingPolicies.Random,
                Destinations        = destinations,
            },
            new ClusterConfig
            {
                ClusterId           = "cluster-least",
                LoadBalancingPolicy = LoadBalancingPolicies.LeastRequests,
                Destinations        = destinations,
            },
        });

app.MapReverseProxy();
app.Run();
```

**Route resolution flow:**
1. Request arrives at port 5000.
2. YARP evaluates all routes with `Order = 1` first.
3. The route whose `Headers` condition matches the `X-LB-Algo` value wins.
4. YARP forwards the request to that route's cluster.
5. The cluster's `LoadBalancingPolicy` selects which destination within the cluster handles it.
6. If no header is present, the `Order = 2` fallback route catches it and routes to `cluster-rr`.

---

### Backend API Nodes

Three identical instances of `ClientSideLB.Backend` run on ports 5001, 5002, and 5003. Each exposes four endpoints that simulate different real-world workload categories.

**Load Type Simulation**

| Endpoint | Workload Type | Implementation |
|---|---|---|
| `GET /api/ping` | Lightweight | Returns immediately — simulates a fast health probe or cached response. |
| `GET /api/cpu-bound` | CPU-Intensive | Runs 5,000 iterations of SHA-512 hashing on random data — consumes real CPU cycles. |
| `GET /api/io-bound` | I/O-Bound | Awaits `Task.Delay(3000)` — simulates waiting on a database query or remote API call. |
| `GET /api/unstable` | Unreliable | 50% probability of returning HTTP 500 — simulates a flaky downstream dependency. |

**Active Load Tracking with `Interlocked`**

All four endpoints share a single `int activeLoad` variable at the top of `Program.cs`. The key constraint is that ASP.NET Core handles requests on a **thread pool**: multiple requests run on different threads simultaneously, so a naive `activeLoad++` is a race condition.

The solution is `System.Threading.Interlocked`, which performs atomic read-modify-write operations at the CPU level — no locks, no blocking:

```csharp
// Shared across all endpoints — one counter for the entire process
int activeLoad = 0;

app.MapGet("/api/cpu-bound", (HttpContext ctx) =>
{
    // Atomically increments and returns the new value — thread-safe
    var load = Interlocked.Increment(ref activeLoad);

    // ... do work ...

    try   { return Results.Ok(new { ..., activeLoad = load }); }
    finally
    {
        // Atomically decrements when the response is sent — even if an exception occurs
        Interlocked.Decrement(ref activeLoad);
    }
});
```

The Flutter app reads the `activeLoad` value from the JSON response and displays it as a live number on the server cards. Because increment and decrement both happen atomically, the number is always consistent even under a burst of 20 parallel requests.

**Execution Time Tracking with `Stopwatch`**

`System.Diagnostics.Stopwatch` is started at the very beginning of each handler — before any work begins — and stopped immediately before the response is constructed. The elapsed milliseconds are included in the response body:

```csharp
app.MapGet("/api/cpu-bound", (HttpContext ctx) =>
{
    var sw   = Stopwatch.StartNew();           // starts before all work
    var load = Interlocked.Increment(ref activeLoad);
    var server = ctx.Request.Host.ToString();

    try
    {
        // Simulate CPU work
        var buffer = new byte[64];
        for (var i = 0; i < 5_000; i++)
        {
            RandomNumberGenerator.Fill(buffer);
            SHA512.HashData(buffer);
        }

        sw.Stop();                             // stops after all work

        return Results.Ok(new
        {
            status          = "Success",
            type            = "CpuBound",
            server,
            activeLoad      = load,
            executionTimeMs = sw.ElapsedMilliseconds  // included in response
        });
    }
    finally
    {
        Interlocked.Decrement(ref activeLoad);
    }
});
```

The `/api/unstable` endpoint intentionally omits `executionTimeMs` from the `500` error branch (which returns no JSON body), so the Flutter app's JSON parser handles it safely with a `?? 0` fallback.

---

### Algorithms — Backend Context (via YARP `LoadBalancingPolicies`)

In server-side mode, YARP owns all routing decisions. The Flutter app does not implement any algorithm — it only sends the header. YARP's built-in policies handle the rest.

#### 1. Round Robin

**Theory:** Round Robin is the simplest fair-distribution algorithm. Each incoming request is assigned to the next server in a cyclic sequence: Server 1 → Server 2 → Server 3 → Server 1 → … It makes no assumptions about server capacity or current load. Over a large number of requests, every server receives an equal share.

**How YARP handles it:** YARP maintains an atomic counter per cluster. On each incoming request it reads the counter, selects `destinations[counter % destinations.Count]`, and increments it. The operation is lock-free.

```csharp
new ClusterConfig
{
    ClusterId           = "cluster-rr",
    LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,  // single line to enable
    Destinations        = destinations,
}
```

The Flutter app activates this policy by sending `X-LB-Algo: roundRobin` on each request.

---

#### 2. Random

**Theory:** Random selection picks a destination uniformly at random on each request. It provides no ordering guarantees but achieves statistical fairness over large sample sizes. It is useful when servers are heterogeneous in ways that make a fixed cycle counterproductive, or as a simple baseline for comparison.

**How YARP handles it:** YARP calls `Random.Shared.Next(destinations.Count)` on each request.

```csharp
new ClusterConfig
{
    ClusterId           = "cluster-random",
    LoadBalancingPolicy = LoadBalancingPolicies.Random,
    Destinations        = destinations,
}
```

The Flutter app activates this by sending `X-LB-Algo: random`.

---

#### 3. Least Connections / Least Requests

**Theory:** Rather than distributing requests in a fixed pattern, Least Requests routes each new request to whichever server currently has the fewest in-flight (active) requests. This makes it adaptive: if Server 2 is processing three slow I/O-bound tasks while Servers 1 and 3 are idle, the next request will go to Server 1 or 3 — not blindly to Server 2 in rotation.

It is strictly superior to Round Robin under heterogeneous workloads because it naturally avoids overloading any single server. The downside is it requires YARP to maintain an in-memory counter of active requests per destination.

**How YARP handles it:** YARP tracks a `pendingRequests` counter per destination. On each incoming request it scans all destinations, picks the one with the minimum count, atomically increments its counter, and decrements it when the proxied response completes.

```csharp
new ClusterConfig
{
    ClusterId           = "cluster-least",
    LoadBalancingPolicy = LoadBalancingPolicies.LeastRequests,
    Destinations        = destinations,
}
```

The Flutter app activates this by sending `X-LB-Algo: leastConnections`.

---

## 3. Frontend Implementation (Flutter / Dart)

The Flutter app is built around a BLoC state management architecture. All network logic is encapsulated in a Dio interceptor, keeping the BLoC free of HTTP concerns.

---

### The Load Balancer Interceptor

**Theory**

A Dio `Interceptor` is a middleware layer that runs before and after every HTTP request made by that `Dio` instance. It gives you three lifecycle hooks:

- `onRequest` — runs before the request is sent. You can inspect and mutate `RequestOptions`.
- `onResponse` — runs after a successful response arrives. You can read the response body.
- `onError` — runs when the request fails. You can suppress the error and resolve with a different response.

The `LoadBalancerInterceptor` exploits all three hooks to implement a complete smart client:

- **`onRequest`** — determines which server to target and rewrites `options.baseUrl`.
- **`onResponse`** — reports the server as healthy and updates the live-load map used by Least Connections.
- **`onError`** — implements the failover chain.

In server-side mode, `onRequest` instead routes to the single gateway URL and attaches the `X-LB-Algo` header. The failover logic is skipped entirely (the gateway handles it internally).

**Failover Mechanism**

The failover chain follows the **Chain of Responsibility** pattern. When a retryable error occurs (timeout, connection refused, or 5xx), `onError`:

1. Marks the failing server offline via the `onHealthChanged` callback.
2. Checks whether all servers have already been tried (tracked in `RequestOptions.extra[_triedKey]`).
3. If servers remain, picks the next untried one, updates `options.baseUrl`, and retries with a **fresh Dio instance** — one that carries no interceptors, preventing infinite re-entry.
4. If that retry itself fails, the method calls itself recursively until the tried list is exhausted.
5. Only after all servers have failed does the final error surface to the caller.

```dart
@override
Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
  if (!_isRetryable(err)) return handler.next(err);

  final options = err.requestOptions;
  onHealthChanged?.call(options.baseUrl, false);  // mark server offline

  final tried = List<int>.from(options.extra[_triedKey] as List? ?? []);
  if (tried.length >= _servers.length) return handler.next(err);  // all failed

  final nextIndex = (tried.last + 1) % _servers.length;
  tried.add(nextIndex);
  options.extra[_triedKey] = tried;
  options.baseUrl = _servers[nextIndex];

  try {
    // Fresh Dio = no interceptors = no infinite loop
    final retryDio = Dio(BaseOptions(
      connectTimeout: options.connectTimeout,
      receiveTimeout: options.receiveTimeout,
    ));
    final response = await retryDio.fetch<dynamic>(options);
    onHealthChanged?.call(options.baseUrl, true);  // retry succeeded
    handler.resolve(response);
  } on DioException catch (retryErr) {
    await onError(retryErr, handler);  // try next server
  }
}
```

Retryable conditions:

```dart
bool _isRetryable(DioException err) {
  final isTimeout =
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout    ||
      err.type == DioExceptionType.sendTimeout;

  final isConnectionFailure =
      err.type == DioExceptionType.connectionError ||
      err.type == DioExceptionType.unknown;

  final isServerError =
      err.response != null && err.response!.statusCode! >= 500;

  return isTimeout || isConnectionFailure || isServerError;
}
```

---

### Algorithms — Frontend Context (Client-Side Mode)

In client-side mode, the interceptor's `onRequest` hook makes the routing decision on every request. The target server is selected by overwriting `options.baseUrl` before the request is dispatched.

#### 1. Round Robin

**Theory (client context):** The client maintains a shared cursor index. Every time a request is about to be sent, the client reads the cursor to determine the target server and then advances the cursor by one (wrapping back to 0 when it reaches the end of the list). This ensures that over any sequence of N requests, each server receives exactly `N / serverCount` of them — perfectly even distribution, regardless of how fast each server is responding.

**Implementation:**

```dart
// Static — shared across all Dio instances, ensuring global ordering
static int _rrCursor = 0;

// Inside onRequest:
if (currentAlgorithm == LoadBalancerAlgorithm.roundRobin) {
  final index = _rrCursor;
  _rrCursor = (_rrCursor + 1) % _servers.length;  // advance and wrap
  options.baseUrl = _servers[index];
}
```

The cursor is `static` so that even if the BLoC creates multiple Dio instances, they all share the same global sequence counter. Without this, each instance would independently cycle from 0, effectively sending all requests to Server 1 first.

---

#### 2. Random

**Theory (client context):** The client picks a server index using a uniform random number generator on every request. Unlike Round Robin, there is no guaranteed distribution in the short term — you might send three requests in a row to Server 2. However, the law of large numbers guarantees convergence toward equal distribution over a sufficiently large sample. It is useful as a simple no-state algorithm and as a comparison baseline.

**Implementation:**

```dart
import 'dart:math';

// Inside onRequest:
if (currentAlgorithm == LoadBalancerAlgorithm.random) {
  final index = Random().nextInt(_servers.length);  // [0, serverCount)
  options.baseUrl = _servers[index];
}
```

`Random().nextInt(n)` returns a value in `[0, n)` with uniform distribution.

---

#### 3. Least Connections

**Theory (client context):** Instead of using a fixed sequence or random selection, the client routes each request to whichever server it *believes* to currently have the lowest number of active in-flight requests. The belief is based on the `activeLoad` value returned in the JSON body of each previous response — the most recent snapshot known to the client.

This makes the algorithm adaptive. If Server 3 is processing ten slow I/O-bound tasks (high `activeLoad`) while Servers 1 and 2 have cleared their queues, the next request goes to whichever of 1 or 2 last reported the lower load — not blindly to the next server in sequence.

The tradeoff is that the load estimates are **stale**: they reflect the state at the time of the last response from that server, not the current instant. Under extreme burst conditions this can cause sub-optimal decisions, but in practice it substantially outperforms Round Robin on heterogeneous workloads.

**Implementation:**

```dart
// Updated in onResponse after every successful response
final Map<String, int> _liveLoads = {};

// In onResponse:
final load = (data['activeLoad'] as num?)?.toInt();
if (load != null) {
  _liveLoads[response.requestOptions.baseUrl] = load;
}

// In onRequest — Least Connections branch:
var minIndex = 0;
var minLoad  = _liveLoads[_servers[0]] ?? 0;   // default 0 if no data yet

for (var i = 1; i < _servers.length; i++) {
  final load = _liveLoads[_servers[i]] ?? 0;
  if (load < minLoad) {
    minLoad  = load;
    minIndex = i;
  }
}

options.baseUrl = _servers[minIndex];
```

Unknown servers (no response received yet) default to load `0`, which means they are preferred as routing targets at the start of a session — a sensible cold-start behavior.

---

### Session Analytics & Metrics

**Architecture**

The analytics system is a plain Dart class (`SessionMetrics`) held as private state inside the BLoC. It is deliberately kept outside the BLoC's sealed state classes — it does not need to be immutable or trigger UI rebuilds. Instead, the `ReportScreen` reads it as a snapshot at the moment it is opened.

```
Backend JSON Response
  └── executionTimeMs (int)
        │
        ▼
LoadBalancerBloc._handleRequest()
  ├── _metrics.recordRequest(endpoint)        — called before the network call
  └── _metrics.recordResponse(serverKey,      — called after a successful response
                              endpoint,
                              executionTimeMs)
        │
        ▼
SessionMetrics
  ├── totalPing / totalCpu / totalIo / totalUnstable  — global request counters
  └── Map<String, ServerMetrics> _servers             — per-server breakdown
        └── ServerMetrics
              ├── pingCount / cpuCount / ioCount / unstableCount
              └── totalExecutionTimeMs

        │
        ▼
ReportScreen  (reads metrics snapshot at navigation time)
  ├── _OverviewCard  — 2×2 chip grid showing global totals
  └── _ServerTile x N  — expandable card per server key
```

**Data Collection in the BLoC**

The BLoC's `_handleRequest` method contributes to metrics at two points:

```dart
Future<void> _handleRequest(String endpoint, Emitter<LoadBalancerState> emit) async {
  // 1. Count the outbound request immediately — before the network call
  _metrics.recordRequest(endpoint);

  try {
    final raw = await _networkFacade.sendRequest(endpoint);

    var activeLoad      = 0;
    var server          = '';
    var executionTimeMs = 0;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      activeLoad      = (json['activeLoad']      as num?)?.toInt() ?? 0;
      server          = (json['server']          as String?) ?? '';
      executionTimeMs = (json['executionTimeMs'] as num?)?.toInt() ?? 0;
    } catch (_) {}

    // 2. Normalize the server field (e.g. "localhost:5002") into a canonical key
    //    that matches the _serverLoads map format.
    for (final port in ['5001', '5002', '5003']) {
      if (server.contains(port)) {
        _serverLoads['$kBackendIp:$port'] = activeLoad;

        // Record per-server metrics: which server, which endpoint, how long it took
        _metrics.recordResponse('$kBackendIp:$port', endpoint, executionTimeMs);
        break;
      }
    }

    emit(LoadBalancerSuccess(...));
  } on DioException catch (e) {
    // Failures are not recorded in server metrics — only successful responses contribute
    emit(LoadBalancerFailure(...));
  }
}
```

**The `SessionMetrics` Tracker**

```dart
class ServerMetrics {
  int pingCount            = 0;
  int cpuCount             = 0;
  int ioCount              = 0;
  int unstableCount        = 0;
  int totalExecutionTimeMs = 0;
}

class SessionMetrics {
  int totalPing     = 0;
  int totalCpu      = 0;
  int totalIo       = 0;
  int totalUnstable = 0;

  final Map<String, ServerMetrics> _servers = {};

  // Exposed as an unmodifiable view — callers cannot accidentally mutate the map
  Map<String, ServerMetrics> get servers => Map.unmodifiable(_servers);

  void recordRequest(String endpoint) {
    switch (endpoint) {
      case '/api/ping':      totalPing++;     break;
      case '/api/cpu-bound': totalCpu++;      break;
      case '/api/io-bound':  totalIo++;       break;
      case '/api/unstable':  totalUnstable++; break;
    }
  }

  void recordResponse(String serverKey, String endpoint, int executionTimeMs) {
    // putIfAbsent creates a new ServerMetrics for this server on first use
    final s = _servers.putIfAbsent(serverKey, ServerMetrics.new);
    switch (endpoint) {
      case '/api/ping':      s.pingCount++;     break;
      case '/api/cpu-bound': s.cpuCount++;      break;
      case '/api/io-bound':  s.ioCount++;       break;
      case '/api/unstable':  s.unstableCount++; break;
    }
    s.totalExecutionTimeMs += executionTimeMs;
  }

  void reset() {
    totalPing = totalCpu = totalIo = totalUnstable = 0;
    _servers.clear();
  }
}
```

**ReportScreen Rendering**

The `ReportScreen` receives the `SessionMetrics` object directly — no BLoC lookup needed. It renders two sections:

- **Overview Card** — a 2×2 `Wrap` of colored `_StatChip` widgets showing global request totals (Ping in green, CPU in orange, I/O in cyan, Unstable in red).
- **Server Breakdown** — one `ExpansionTile` per entry in `metrics.servers`. Collapsed state shows the server key and total task count. Expanded state shows per-type row counts and the server's cumulative execution time, auto-formatted as `ms` or `s`:

```dart
final display = totalMs >= 1000
    ? '${(totalMs / 1000).toStringAsFixed(1)} s'
    : '$totalMs ms';
```

When a session is reset via the dashboard's refresh button, `_metrics.reset()` is called alongside `_serverLoads.clear()`, returning the report to its empty state: `"No data yet. Run a test first."`.
