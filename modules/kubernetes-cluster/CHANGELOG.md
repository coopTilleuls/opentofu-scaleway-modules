# Changelog

## [2.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v1.0.0...kubernetes-cluster-v2.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **kubernetes-cluster:** `pools` passe de map(object(...)) à list(object(...)) et gagne une variable `zones` requise ; plusieurs champs par pool (zone/size/autoscaling/autohealing/container_runtime/public_ip_disabled) disparaissent au profit de valeurs figées ou de `sizes[]`. Les repos consommateurs doivent réécrire leur bloc `pools =` en même temps qu'ils bumpent la référence du module.

### Features

* **kubernetes-cluster:** generate node pool matrix internally ([1d0c29e](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/1d0c29eed0d80fcac9b3a3f7b18076212b19b1ac))

## 1.0.0 (2026-07-21)


### Bug Fixes

* **kubernetes-cluster:** strip region prefix before scw kubeconfig install, wait for pools ([b13e030](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/b13e030bd6f4e18d4171150cd1864fc8952582e5))
