let atd = ./atd/package

let Config = ./configSchema.dhall

let modules = ./modules.dhall

let deployment
      : atd.Deploy Config
      = [ modules.rootModule
        --, atd.Module/optional False Config modules.extraModule
        ]

let deploy = atd.Deploy/deploy Config deployment

in  deploy
