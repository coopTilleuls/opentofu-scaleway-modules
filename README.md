# opentofu-scaleway-modules

Modules OpenTofu réutilisables pour l'infrastructure Scaleway, extraits de la
duplication constatée entre differents repos.
L'objectif : mutualiser le code d'infrastructure Scaleway
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
| [`cockpit-alerting`](modules/cockpit-alerting) | Alerting Mimir d'un Cockpit Scaleway (alertes préconfigurées patchées + règles custom, routage OnCall) |
| [`elasticsearch-operator`](modules/elasticsearch-operator) | Installation de l'operator ECK (Elastic Cloud on Kubernetes) — **exception au périmètre** ci-dessous |
| [`rabbitmq-operator`](modules/rabbitmq-operator) | Installation des operators RabbitMQ (Cluster Operator + Messaging Topology Operator) — **exception au périmètre** ci-dessous |

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
  chaque repo consommateur. **Exceptions assumées : les modules [`flux`](modules/flux)**, dont le
  bootstrap est indissociable de ressources Kubernetes (namespace, secrets, CRD
  `GitRepository`/`Kustomization`), **[`elasticsearch-operator`](modules/elasticsearch-operator)**,
  qui installe l'operator ECK (CRD + manifests officiels), **et
  [`rabbitmq-operator`](modules/rabbitmq-operator)**, qui installe les operators RabbitMQ (Cluster
  Operator + Messaging Topology Operator) — dans les trois cas, un module qui exclurait ces objets
  n'aurait aucune substance. Voir leur README respectif pour le détail de ces exceptions et de leurs
  limites.

## Consommation depuis un repo applicatif

Chaque module se référence via une source git versionnée par tag, par exemple :

```hcl
module "vpc" {
  source = "git::https://<url-de-ce-repo>//modules/vpc?ref=vpc-v1.0.0"
  # ...
}
```

L'intégration dans les repos client (remplacement du code dupliqué par des
appels à ces modules, choix des tags de version) est gérée séparément, hors périmètre de ce repo.

## Ajouter un nouveau module

1. Créer `modules/<nom-du-module>/` avec la structure habituelle : `main.tf`, `variables.tf`,
   `outputs.tf`, `versions.tf` (bloc `terraform.required_providers`, sans bloc `provider`, cf
   [Conventions](#conventions)), et un `README.md` (rôle du module, exemple d'utilisation,
   remarques). Ne pas créer de `CHANGELOG.md` : il est généré par release-please (cf
   [Publication des releases](#publication-des-releases)).
2. Si le module crée des ressources Kubernetes, l'indiquer explicitement comme exception au
   périmètre (cf [Conventions](#conventions)) : mention dans le `README.md` du module, et dans
   ce README (ligne du tableau ci-dessus + paragraphe "Aucune ressource Kubernetes").
3. Ajouter une ligne au tableau [Modules disponibles](#modules-disponibles) ci-dessus.
4. Enregistrer le module dans release-please, dans les deux fichiers à la racine du repo :
   - `release-please-config.json` : ajouter une entrée `"modules/<nom-du-module>": {"component":
     "<nom-du-module>", "changelog-path": "CHANGELOG.md"}`.
   - `.release-please-manifest.json` : ajouter `"modules/<nom-du-module>": "0.0.0"` (version de
     départ avant toute release — release-please calculera la première version réelle, typiquement
     `1.0.0`, à partir des commits).
5. Valider avec `tofu fmt -recursive` puis, dans le répertoire du module, `tofu init
   -backend=false && tofu validate` (cf [Validation](#validation)) ; supprimer ensuite
   `.terraform/` et `.terraform.lock.hcl` générés par cette validation avant de commit.
6. Committer avec un message conventionnel `feat(<nom-du-module>): ...` (déclenche un bump
   *minor* côté release-please), ouvrir une PR et la merger sur `main`.
7. release-please ouvre alors automatiquement une PR séparée
   `chore(main): release <nom-du-module> X.Y.Z` avec le `CHANGELOG.md` du module ; la merger crée
   le tag `<nom-du-module>-vX.Y.Z` et la release GitHub, immédiatement utilisable via
   `ref=<nom-du-module>-vX.Y.Z` (cf [Consommation depuis un repo applicatif](#consommation-depuis-un-repo-applicatif)).

## Publication des releases

Les tags et les releases GitHub sont générés automatiquement par
[release-please](https://github.com/googleapis/release-please), à partir des messages de commit
conventionnels déjà utilisés dans ce repo (`feat(module): ...`, `fix(module): ...`, `chore: ...`).

- **Versioning indépendant par module** : chaque module du tableau ci-dessus a son propre numéro
  de version et son propre tag, au format `<module>-vX.Y.Z` (ex: `vpc-v1.2.0`,
  `bastion-v1.0.1`). release-please détermine, pour chaque module, quels commits ont modifié des
  fichiers sous `modules/<module>/` depuis son dernier tag, et en déduit le bump (`fix` → patch,
  `feat` → minor, `!`/`BREAKING CHANGE` → major).
- Chaque push sur `main` met à jour (ou crée) une pull request "release" par module impacté,
  proposant le prochain numéro de version et le `CHANGELOG.md` du module correspondant
  (`modules/<module>/CHANGELOG.md`).
- Merger une de ces pull requests crée le tag Git et la release GitHub associée, immédiatement
  utilisable via `ref=<module>-vX.Y.Z` dans les repos consommateurs (cf section ci-dessus). Rien
  à taguer à la main.
- Un commit qui touche plusieurs modules à la fois (à éviter autant que possible) déclenche une
  pull request de release pour chacun d'entre eux.

## Validation

Chaque module a été vérifié avec `tofu init -backend=false && tofu validate` et formaté avec
`tofu fmt -recursive`.
