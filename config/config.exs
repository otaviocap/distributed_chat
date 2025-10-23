import Config

config :libcluster,
  topologies: [
    main_topology: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45999
      ]
    ]
  ]
