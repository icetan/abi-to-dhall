let atd = ./atd/package

let modules = ./modules.dhall

let schema = ./schema.dhall

in    λ(conf : schema.Config)
    → λ(input : schema.Input)
    → atd.Module/run schema.Output (modules.module conf input)
