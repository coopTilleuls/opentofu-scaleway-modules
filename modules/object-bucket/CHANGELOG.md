# Changelog

## [1.0.3](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/object-bucket-v1.0.2...object-bucket-v1.0.3) (2026-07-22)


### Bug Fixes

* **object-bucket:** tolist() on both Principal.SCW to avoid mismatched tuple arities ([a4c306c](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/a4c306ca6e090b815017dbb7b5158c15b3f84d91))

## [1.0.2](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/object-bucket-v1.0.1...object-bucket-v1.0.2) (2026-07-22)


### Bug Fixes

* **object-bucket:** make app_statement.Principal.SCW a list, matching sre_statement's shape ([b80fd71](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/b80fd713526c53818ebdcc3bfa101095bdce0f5a))

## [1.0.1](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/object-bucket-v1.0.0...object-bucket-v1.0.1) (2026-07-22)


### Bug Fixes

* **object-bucket:** let callers force statement presence to avoid Invalid count argument ([c321fda](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/c321fda3e829a66c5a6bedb4c2398abe4b7a657c))

## 1.0.0 (2026-07-21)


### Bug Fixes

* **object-bucket:** set project_id on bucket policy, fix SRE group principal format ([112123e](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/112123e0be99a263f1111c227174f9acff43125e))
