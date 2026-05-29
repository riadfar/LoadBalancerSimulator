Core Concepts :

Server-Side Load Balancing (API Gateway Pattern): Centralizing traffic routing and load distribution through a dedicated reverse proxy (YARP) to abstract backend complexity from the client.

Client-Side Load Balancing (Smart Client Concept): Decoupling routing, retries, and failover logic from the main application code by using a custom network Interceptor to manage direct backend connections.

Round-Robin Traffic Distribution: Implementing a static, deterministic algorithm to sequentially distribute incoming requests evenly across the available backend servers.

State-Aware Routing (Least Connections): Dynamically routing traffic to the least burdened server by continuously monitoring the activeLoad (concurrent requests), optimizing real-time resource utilization.

Active Fault Tolerance & Self-Healing (Failover): Automatically detecting dead nodes (e.g., Connection Refused) or HTTP 500 errors, draining them, and seamlessly rerouting traffic to healthy instances without disrupting the user experience.

Active Health Monitoring (Health Probing): Tracking the real-time status of each backend server and dynamically updating the UI to reflect "OFFLINE" or "HEALTHY" states.

Advanced Engineering Additions : 

Heterogeneous Load Simulation: Designing specific backend endpoints to mimic real-world processing bottlenecks, including CPU-bound tasks (SHA-512 cryptographic hashing), I/O-bound tasks (simulated network delays), and lightweight Fast Pings.

Traffic Spike Simulation (Micro-Bursting): Engineering a custom stress-testing controller to fire massive, simultaneous concurrent requests to evaluate system scalability and the Load Balancer's behavior under sudden traffic surges.

Performance Telemetry & Analytics Dashboard: Building a dedicated metrics tracking system using server-side execution timers (Stopwatch) to capture precise request processing durations (Execution Time) and visualizing the data in a comprehensive analytics report.

Dynamic Header-Based Routing: Enabling runtime algorithm switching at the API Gateway level by intercepting custom HTTP headers (X-LB-Algo), allowing seamless transitions between load balancing policies without altering static URL paths.

Stateless Traffic Distribution (Random Routing): Implementing a stochastic load balancing strategy to demonstrate random distribution patterns and visually contrast them with deterministic algorithms on the live dashboard.