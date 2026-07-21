# Changelog

## 1.0.0 (2026-07-21)


### Features

* **bastion:** optional Ansible provisioning, mirroring opentofu-ffspt ([d08e20b](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/d08e20ba69e18ed3e13bdc2fd043a229ac608a4d))
* **flux:** add module mirroring Flux bootstrap from opentofu-ffspt and sweeek ([2fe59aa](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/2fe59aada47b178a91e3d8a32e01d438d81a465d))


### Bug Fixes

* **vpc:** set explicit zone on scaleway_vpc_gateway_network ([74c262c](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/74c262ce8b98caa61640eb69ff094f1f1eb44fa1))
* **vpc:** use ip_address instead of address on scaleway_flexible_ip ([bcc2fd2](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/bcc2fd25dadc509e4263b41736d679f1a7438553))
* **vpc:** use scaleway_vpc_public_gateway_ip instead of scaleway_flexible_ip ([e453253](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/e453253ad9ffc888fb3335a06f6e88766fac954b))
* **vpc:** wait after flexible IP creation before attaching it to the gateway ([57c86dc](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/57c86dc6a3e3d26f3bcaa3e47f0501212b067788))
* **vpc:** wait after public gateway creation before attaching it to a private network ([516c5bb](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/516c5bbbe848198ababceffe1bf120442043b956))
