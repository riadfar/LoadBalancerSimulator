using System.Diagnostics;
using System.Security.Cryptography;

// ── Shared state ──────────────────────────────────────────────────────────────
// Single int modified only through Interlocked — lock-free and thread-safe.
int activeLoad = 0;

var builder = WebApplication.CreateBuilder(args);
var app     = builder.Build();

// ── Console helper ────────────────────────────────────────────────────────────
// Writes a two-part line: gray timestamp, then colored direction + detail.
static void Log(
    string       direction, // "IN" | "OUT"
    string       endpoint,
    string       detail,
    int          load,
    ConsoleColor color,
    bool         isError = false)
{
    var ts    = DateTime.Now.ToString("HH:mm:ss.fff");
    var arrow = direction == "IN" ? "→" : "←";

    Console.ForegroundColor = ConsoleColor.DarkGray;
    Console.Write($"[{ts}]  ");

    Console.ForegroundColor = isError ? ConsoleColor.Red : color;
    Console.Write($"{arrow} {endpoint,-18}  ");

    Console.ForegroundColor = ConsoleColor.White;
    Console.Write($"{detail,-36}  ");

    Console.ForegroundColor = ConsoleColor.DarkYellow;
    Console.WriteLine($"activeLoad = {load}");

    Console.ResetColor();
}

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/ping  —  instant lightweight response
// ─────────────────────────────────────────────────────────────────────────────
app.MapGet("/api/ping", (HttpContext ctx) =>
{
    var sw     = Stopwatch.StartNew();
    var load   = Interlocked.Increment(ref activeLoad);
    var server = ctx.Request.Host.ToString();
    Log("IN", "/api/ping", "lightweight request received", load, ConsoleColor.Green);

    try
    {
        sw.Stop();
        return Results.Ok(new { status = "Success", type = "Lightweight", server, activeLoad = load, executionTimeMs = sw.ElapsedMilliseconds });
    }
    finally
    {
        Log("OUT", "/api/ping", "200 OK — pong!", Interlocked.Decrement(ref activeLoad), ConsoleColor.Green);
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/cpu-bound  —  simulates heavy CPU processing
// ─────────────────────────────────────────────────────────────────────────────
app.MapGet("/api/cpu-bound", (HttpContext ctx) =>
{
    var sw     = Stopwatch.StartNew();
    var load   = Interlocked.Increment(ref activeLoad);
    var server = ctx.Request.Host.ToString();
    Log("IN", "/api/cpu-bound", "starting CPU work — 5 000 × SHA-512", load, ConsoleColor.Magenta);

    try
    {
        var buffer = new byte[64];
        for (var i = 0; i < 5_000; i++)
        {
            RandomNumberGenerator.Fill(buffer);
            SHA512.HashData(buffer);
        }
        sw.Stop();
        return Results.Ok(new { status = "Success", type = "CpuBound", server, activeLoad = load, executionTimeMs = sw.ElapsedMilliseconds });
    }
    finally
    {
        Log("OUT", "/api/cpu-bound", "200 OK — CPU work complete", Interlocked.Decrement(ref activeLoad), ConsoleColor.Magenta);
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/io-bound  —  simulates a 3-second database / network delay
// ─────────────────────────────────────────────────────────────────────────────
app.MapGet("/api/io-bound", async (HttpContext ctx) =>
{
    var sw     = Stopwatch.StartNew();
    var load   = Interlocked.Increment(ref activeLoad);
    var server = ctx.Request.Host.ToString();
    Log("IN", "/api/io-bound", "simulating 3 s I/O delay…", load, ConsoleColor.Cyan);

    try
    {
        await Task.Delay(3_000);
        sw.Stop();
        return Results.Ok(new { status = "Success", type = "IoBound", server, activeLoad = load, executionTimeMs = sw.ElapsedMilliseconds });
    }
    finally
    {
        Log("OUT", "/api/io-bound", "200 OK — I/O delay finished", Interlocked.Decrement(ref activeLoad), ConsoleColor.Cyan);
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/unstable  —  50 % chance of returning 500
//
// Uses an isError flag so the finally block always owns the one-and-only
// Decrement — no chance of double-decrement or a missed decrement.
// ─────────────────────────────────────────────────────────────────────────────
app.MapGet("/api/unstable", (HttpContext ctx) =>
{
    var sw      = Stopwatch.StartNew();
    var load    = Interlocked.Increment(ref activeLoad);
    var server  = ctx.Request.Host.ToString();
    var isError = false;
    Log("IN", "/api/unstable", "rolling the dice…", load, ConsoleColor.Yellow);

    try
    {
        if (Random.Shared.NextDouble() < 0.5)
        {
            isError = true;
            return Results.StatusCode(500);
        }
        sw.Stop();
        return Results.Ok(new { status = "Success", type = "Unstable", server, activeLoad = load, executionTimeMs = sw.ElapsedMilliseconds });
    }
    finally
    {
        var after = Interlocked.Decrement(ref activeLoad);
        if (isError)
            Log("OUT", "/api/unstable", "500 — bad luck, server error", after, ConsoleColor.Red, isError: true);
        else
            Log("OUT", "/api/unstable", "200 OK — lucky roll!", after, ConsoleColor.Yellow);
    }
});

app.Run();
