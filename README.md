# opentofu-scaleway-modules

Modules OpenTofu réutilisables pour l'infrastructure Scaleway, extraits de la
duplication constatée entre les repos `sweeek` (walibuy) et `opentofu-ffspt`
(ffsportpourtous). L'objectif : mutualiser le code d'infrastructure Scaleway
générique, sans jamais porter la gestion des objets Kubernetes applicatifs
(namespaces, RBAC, ingress, Helm releases...), qui reste volontairement
propre à chaque repo consommateur.

## Modules disponibles

| Module | Rôle |
|---|---|
| [`vpc`](modules/vpc) | VPC, private networks, public gateways (IPAM), réservation d'IPs de load-balancer |
| [`kubernetes-cluster`](modules/kubernetes-cluster) | Cluster Kapsule + pools de nodes, autoscaler, auto-upgrade, OIDC |
| [`rdb-postgresql`](modules/rdb-postgresql) | Instance RDB PostgreSQL managée + bases + utilisateurs dédiés |
| [`rdb-mysql`](modules/rdb-mysql) | Instance RDB MySQL managée + bases + utilisateurs dédiés |
| [`iam-app-identity`](modules/iam-app-identity) | Identité applicative IAM (application + clé API + policy + secret optionnel) |
| [`object-bucket`](modules/object-bucket) | Bucket Object Storage + policy (accès SRE + accès applicatif scopé) |
| [`container-registry`](modules/container-registry) | Namespace Container Registry |
| [`bastion`](modules/bastion) | Instance bastion SSH/DBA sur private network |
| [`flux`](modules/flux) | Bootstrap FluxCD (namespace, deploy key, sealed-secrets, GitRepository/Kustomization) — **exception au périmètre** ci-dessous |

Chaque module a son propre `README.md` avec un exemple d'utilisation et les
particularités à connaître.

## Conventions

- **Pas de bloc `provider` dans les modules** : chaque module hérite des providers configurés
  par le repo consommateur (bonne pratique pour un module destiné à être réutilisé dans des
  contextes différents — projets Scaleway, régions, credentials distincts).
- **Contrainte de version du provider Scaleway harmonisée** à `>= 2.79.0, < 3.0.0` sur tous les
  modules (les repos d'origine avaient des contraintes divergentes selon les couches : `~>2.57.0`,
  `~>2.74.0`, `~>2.79.0`...).
- **`lifecycle.prevent_destroy = true`** est figé en dur sur les ressources critiques (cluster
  Kubernetes, instances RDB, IP publique du bastion) : la valeur de `lifecycle` doit être une
  constante littérale en Terraform/OpenTofu (elle ne peut pas dépendre d'une variable), et une
  ressource de production ne doit pas pouvoir être détruite par un `tofu apply`/`destroy`
  accidentel.
- **Aucune ressource Kubernetes** (namespace, RBAC, ingress, Helm release, manifest...) dans ces
  modules : c'est une exigence explicite du périmètre, ces objets restent gérés directement dans
  chaque repo consommateur. **Exception assumée : le module [`flux`](modules/flux)**, dont le
  bootstrap est indissociable de ressources Kubernetes (namespace, secrets, CRD
  `GitRepository`/`Kustomization`) — un module flux qui les exclurait n'aurait aucune substance.
  Voir son README pour le détail de cette exception et de ses limites.

## Consommation depuis un repo applicatif

Chaque module se référence via une source git versionnée par tag, par exemple :

```hcl
module "vpc" {
  source = "git::https://<url-de-ce-repo>//modules/vpc?ref=v1.0.0"
  # ...
}
```

L'intégration dans les repos `sweeek` et `opentofu-ffspt` (remplacement du code dupliqué par des
appels à ces modules, choix des tags de version) est gérée séparément, hors périmètre de ce repo.

## Publication des releases

Les tags `vX.Y.Z` et les releases GitHub sont générés automatiquement par
[release-please](https://github.com/googleapis/release-please), à partir des messages de commit
conventionnels déjà utilisés dans ce repo (`feat(module): ...`, `fix(module): ...`, `chore: ...`).

- Chaque push sur `main` met à jour (ou crée) une pull request "release" proposant le prochain
  numéro de version et le `CHANGELOG.md` correspondant.
- Merger cette pull request crée le tag Git et la release GitHub associée, immédiatement
  utilisable via `ref=vX.Y.Z` (cf section ci-dessus). Rien à taguer à la main.
- Un seul numéro de version couvre tous les modules de ce repo (pas de versioning indépendant par
  module) : un `fix(vpc)` incrémente la même version qu'un `feat(bastion)`. Compromis assumé pour
  un repo mono-module-Terraform de cette taille, plutôt que des repos séparés par module.

## Validation

Chaque module a été vérifié avec `tofu init -backend=false && tofu validate` et formaté avec
`tofu fmt -recursive`.
