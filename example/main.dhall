let atd = ./atd/package

let modules = ./modules.dhall

let schema = ./schema.dhall

in  λ(conf : schema.Config)
  → atd.StateModule/run
      schema.State
      (modules.module conf)
