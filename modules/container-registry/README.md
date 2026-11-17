# container-registry

Crée un namespace Container Registry Scaleway. Se compose avec le module
[`iam-app-identity`](../iam-app-identity) pour le pull-secret utilisé par le
cluster Kubernetes (motif observé à l'identique dans les deux repos audités :
une application IAM dédiée avec la permission `ContainerRegistryReadOnly`).

## Exemple

```hcl
module "registry" {
  source = "git::https://<repo-url>//modules/container-registry?ref=container-registry-vX.Y.Z"

  name       = "myproject-cr"
  project_id = var.project_id
}

module "registry_pull_secret" {
  source = "git::https://<repo-url>//modules/iam-app-identity?ref=iam-app-identity-vX.Y.Z"

  name                 = "kubernetes-imagepullsecret"
  permission_set_names = ["ContainerRegistryReadOnly"]
  project_ids          = [var.project_id]
}
```

## Remarques

- Ce module ne crée volontairement pas la clé de pull lui-même : la logique IAM (application +
  clé API + policy) est déjà couverte par `iam-app-identity`, la dupliquer ici serait redondant.

## Rétention des tags (optionnelle)

Scaleway Container Registry n'a pas de politique de rétention native, et le provider n'en expose
aucune sur `scaleway_registry_namespace`. Renseigner `retention` crée :

- une application IAM dédiée (via [`iam-app-identity`](../iam-app-identity)), avec
  `ContainerRegistryFullAccess` sur le projet du namespace et des identifiants stockés dans
  Secret Manager ;
- un Serverless Job planifié (`scaleway_job_definition`) qui lance [`retention.py`](retention.py)
  (bibliothèque standard Python uniquement) contre l'API Registry.

### Ce que la purge sait faire

Pour chaque image (dépôt) dont le nom matche `image_regex` :

1. **Tags protégés** : un tag qui matche `protected_tag_regex` n'est jamais supprimé.
2. **Règles par famille de tags** : chaque tag est rattaché à la **première** règle de `rules` dont
   `tag_regex` le matche. Un tag qui ne matche aucune règle est conservé. Dans une règle, les
   `keep_last` tags les plus récents de l'image sont conservés, les suivants sont supprimés s'ils
   ont plus de `older_than_days` jours : il faut **les deux** conditions pour supprimer un tag.
   Par défaut `keep_last = 10` et `older_than_days = 30`. Une règle doit avoir au moins un des
   deux > 0.
3. **Digest partagé** : un tag qui pointe vers le même manifest qu'un tag conservé n'est jamais
   supprimé (sinon l'autre tag disparaîtrait aussi). Les suppressions se font sans `force`.
4. **Images sans tag** : avec `empty_image_older_than_days`, une image qui n'a plus aucun tag
   (après la purge) et dont la dernière modification date de plus de N jours est supprimée.

### Ce qu'elle ne sait pas faire

- **Manifests sans tag** (anciennes versions d'un tag réécrit, ex. `main` re-poussé) : l'API
  Scaleway ne les expose pas (pas d'équivalent de `docker image prune` côté registry), ils ne
  peuvent donc pas être ciblés.
- **Savoir ce qui est déployé** : un tag de prod qui ne bouge plus sort vite des `keep_last`.
  Protéger les tags de release via `protected_tag_regex`.

### Exemple

```hcl
module "registry" {
  source = "git::https://<repo-url>//modules/container-registry?ref=container-registry-vX.Y.Z"

  name       = "myproject-cr"
  project_id = var.project_id

  retention = {
    protected_tag_regex = "^(latest|main|v?\\d+\\.\\d+\\.\\d+)$"
    rules = [
      # Builds de commit : 10 derniers gardés, les autres supprimés après 14 jours.
      { tag_regex = "^sha-", keep_last = 10, older_than_days = 14 },
      # Builds de PR : supprimés après 7 jours, quel que soit leur nombre.
      { tag_regex = "^pr-", keep_last = 0, older_than_days = 7 },
      # Valeurs par défaut : 10 derniers gardés, les autres supprimés après 30 jours.
      { tag_regex = "^nonprod-" },
      # Tout le reste : 5 derniers gardés, les autres supprimés après 90 jours.
      { tag_regex = ".*", keep_last = 5, older_than_days = 90 },
    ]
    empty_image_older_than_days = 30
    dry_run                     = true # lire les logs du job avant de passer à false
  }
}
```

| Champ                         | Défaut               | Rôle                                                      |
|-------------------------------|----------------------|-----------------------------------------------------------|
| `rules`                       | (obligatoire, ≥ 1)   | `{ tag_regex, keep_last = 10, older_than_days = 30 }`, la première règle qui matche s'applique |
| `protected_tag_regex`         | `^latest$`           | Tags jamais supprimés                                     |
| `image_regex`                 | `.*`                 | Images concernées par la purge                            |
| `empty_image_older_than_days` | `null` (désactivé)   | Supprime les images sans tag modifiées il y a plus de N jours |
| `schedule`                    | `0 3 * * *`          | Cron du job                                               |
| `timezone`                    | `Europe/Paris`       | Fuseau du cron                                            |
| `dry_run`                     | `false`              | Liste sans supprimer (logs du job)                        |
| `job_image`                   | `python:3.13-alpine` | Image du job (doit fournir `python3`)                     |

Le job peut être lancé à la main depuis la console Serverless Jobs pour lire les logs.
