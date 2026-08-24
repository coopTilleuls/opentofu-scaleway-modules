# Changelog

## [5.1.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v5.0.0...kubernetes-cluster-v5.1.0) (2026-08-24)


### Features

* **kubernetes-cluster:** autoscaler config ([23fa44e](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/23fa44e2009964fef8aa5cfa4532cf75e9174ed0))
* **kubernetes-cluster:** empty commit ([b9de0ae](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/b9de0aefa29669e7c517e5f3fe40bcbe8a32cae5))

## [5.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v4.0.0...kubernetes-cluster-v5.0.0) (2026-08-05)


### ⚠ BREAKING CHANGES

* **kubernetes-cluster:** la clé for_each (`slug`) des pools change de format pour tout node_type contenant un tiret, ce qui déplace l'adresse `scaleway_k8s_pool.this[...]` pour tout consommateur ayant déjà appliqué une version antérieure du module avec un tel node_type.

### Bug Fixes

* **kubernetes-cluster:** retirer aussi les tirets du node_type dans le slug ([454061d](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/454061dd53aa9987a6d0ad752f8f776057df2140))

## [4.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v3.0.0...kubernetes-cluster-v4.0.0) (2026-08-04)


### ⚠ BREAKING CHANGES

* **kubernetes-cluster:** la clé for_each (`slug`) des pools change de format (tirets -> underscores), ce qui déplace l'adresse `scaleway_k8s_pool.this[...]` pour tout consommateur ayant déjà appliqué une version antérieure du module.

### Bug Fixes

* **kubernetes-cluster:** pool slug/name en underscore, pas en tiret ([2818596](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/2818596a1135430f7940f629a93970bcf07665e6))

## [3.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v2.0.1...kubernetes-cluster-v3.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **kubernetes-cluster:** var.pools doit obligatoirement contenir une famille nommée "default", validé par une contrainte sur la variable.

### Bug Fixes

* **kubernetes-cluster:** size=1 uniquement sur la famille de pool "default" ([7ebc538](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/7ebc5384d25e35dc6a7db7decb4fa19b45a890f3))

## [2.0.1](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v2.0.0...kubernetes-cluster-v2.0.1) (2026-07-28)


### Bug Fixes

* **kubernetes-cluster:** size=1 requis à la création, Scaleway refuse 0 node ([78feb85](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/78feb850ce5ca502ae7f2b852769e4d9695a402c))

## [2.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/kubernetes-cluster-v1.0.0...kubernetes-cluster-v2.0.0) (2026-07-28)


### ⚠ BREAKING CHANGES

* **kubernetes-cluster:** `pools` passe de map(object(...)) à list(object(...)) et gagne une variable `zones` requise ; plusieurs champs par pool (zone/size/autoscaling/autohealing/container_runtime/public_ip_disabled) disparaissent au profit de valeurs figées ou de `sizes[]`. Les repos consommateurs doivent réécrire leur bloc `pools =` en même temps qu'ils bumpent la référence du module.

### Features

* **kubernetes-cluster:** generate node pool matrix internally ([1d0c29e](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/1d0c29eed0d80fcac9b3a3f7b18076212b19b1ac))

## 1.0.0 (2026-07-21)


### Bug Fixes

* **kubernetes-cluster:** strip region prefix before scw kubeconfig install, wait for pools ([b13e030](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/b13e030bd6f4e18d4171150cd1864fc8952582e5))
