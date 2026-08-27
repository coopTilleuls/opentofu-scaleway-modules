# Changelog

## [2.1.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/cockpit-alerting-v2.0.0...cockpit-alerting-v2.1.0) (2026-08-27)


### Features

* **kubernetes-cluster:** autoscaler config ([23fa44e](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/23fa44e2009964fef8aa5cfa4532cf75e9174ed0))
* **kubernetes-cluster:** empty commit ([b9de0ae](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/b9de0aefa29669e7c517e5f3fe40bcbe8a32cae5))


### Bug Fixes

* **cockpit-alerting:** new serverless jobs alerts support ([9817c12](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/9817c1214c86ceaa49a3c62f5568402b48c42a57))

## [2.0.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/cockpit-alerting-v1.1.0...cockpit-alerting-v2.0.0) (2026-08-11)


### ⚠ BREAKING CHANGES

* **cockpit-alerting:** callers must now pass webhook_url_critical, webhook_url_warning and webhook_url_info explicitly.

### Bug Fixes

* **cockpit-alerting:** remove hardcoded OnCall webhook URLs ([bcdd2ca](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/bcdd2ca1cbd5f44b707329fec57f5c30305b4e5f))

## [1.1.0](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/cockpit-alerting-v1.0.1...cockpit-alerting-v1.1.0) (2026-08-05)


### Features

* **cockpit-alerting:** rendre les noms des sources Cockpit configurables ([e10b138](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/e10b13838dfad306cee8b8ce05a6645f8b095bb9))
* **cockpit-alerting:** rendre les noms des sources Cockpit configurables ([d3a8c2a](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/d3a8c2a5f5ccca6a717981861b12c4d61979a04b))

## [1.0.1](https://github.com/coopTilleuls/opentofu-scaleway-modules/compare/cockpit-alerting-v1.0.0...cockpit-alerting-v1.0.1) (2026-07-31)


### Bug Fixes

* **cockpit-alerting:** update runbook URL to wiki-sre.les-tilleuls.solutions ([55e017a](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/55e017a8e0dbba265d2aabe9935cf4bbf15069c1))

## 1.0.0 (2026-07-29)


### Features

* **cockpit-alerting:** add module for Scaleway Cockpit alerting via Mimir ([e54f59f](https://github.com/coopTilleuls/opentofu-scaleway-modules/commit/e54f59f9a1cdbab81e98928fd49238a73ffee295))
