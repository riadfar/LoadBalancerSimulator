using Yarp.ReverseProxy.Configuration;
using Yarp.ReverseProxy.LoadBalancing;

var builder = WebApplication.CreateBuilder(args);

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
            new RouteConfig
            {
                RouteId   = "route-rr",
                ClusterId = "cluster-rr",
                Order     = 1,
                Match     = new RouteMatch
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
            new RouteConfig
            {
                RouteId   = "route-random",
                ClusterId = "cluster-random",
                Order     = 1,
                Match     = new RouteMatch
                {
                    Path    = "{**catch-all}",
                    Headers = new[]
                    {
                        new RouteHeader
                        {
                            Name   = "X-LB-Algo",
                            Values = new[] { "random" },
                            Mode   = HeaderMatchMode.ExactHeader,
                        },
                    },
                },
            },
            new RouteConfig
            {
                RouteId   = "route-least",
                ClusterId = "cluster-least",
                Order     = 1,
                Match     = new RouteMatch
                {
                    Path    = "{**catch-all}",
                    Headers = new[]
                    {
                        new RouteHeader
                        {
                            Name   = "X-LB-Algo",
                            Values = new[] { "leastConnections" },
                            Mode   = HeaderMatchMode.ExactHeader,
                        },
                    },
                },
            },
            new RouteConfig
            {
                RouteId   = "route-fallback",
                ClusterId = "cluster-rr",
                Order     = 2,
                Match     = new RouteMatch { Path = "{**catch-all}" },
            },
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

var app = builder.Build();
app.MapReverseProxy();
app.Run();
