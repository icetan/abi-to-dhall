let atd = ../atd/package

let modules = ./modules.dhall

let schema = ./schema.dhall

in    λ(conf : schema.Config)
    → λ(import : schema.Import)
    → atd.Module/run schema.Output (modules.module conf import)
