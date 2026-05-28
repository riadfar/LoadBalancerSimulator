using Yarp.ReverseProxy.Configuration;
using Yarp.ReverseProxy.LoadBalancing;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddReverseProxy()
    .LoadFromMemory(
        routes: new[]
        {
            new RouteConfig
            {
                RouteId   = "default-route",
                ClusterId = "backend-cluster",
                Match     = new RouteMatch { Path = "{**catch-all}" },
            },
        },
        clusters: new[]
        {
            new ClusterConfig
            {
                ClusterId           = "backend-cluster",
                LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,
                Destinations        = new Dictionary<string, DestinationConfig>
                {
                    ["dest-1"] = new DestinationConfig { Address = "http://localhost:5001" },
                    ["dest-2"] = new DestinationConfig { Address = "http://localhost:5002" },
                    ["dest-3"] = new DestinationConfig { Address = "http://localhost:5003" },
                },
            },
        });

var app = builder.Build();
app.MapReverseProxy();
app.Run("http://localhost:5000");
