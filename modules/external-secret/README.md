# external-secret

Câble le Scaleway Secret Manager à [External Secrets Operator](https://external-secrets.io/) sur
un cluster déjà provisionné : identité IAM en lecture seule sur le Secret Manager, un secret
Secret Manager par namespace applicatif, et pour chaque namespace un secret Kubernetes bootstrap +
un `SecretStore` + un `ExternalSecret` pointant vers ce secret.

**Exception au périmètre général de ce repo** : ce module crée des ressources Kubernetes
(`kubernetes_secret_v1`, `kubernetes_manifest` `SecretStore`/`ExternalSecret`), alors que la règle
des autres modules de ce repo est justement de ne jamais en créer (cf README racine). Exception
assumée ici, comme pour le module [`flux`](../flux) : un module "external-secret" sans ces objets
n'aurait aucune substance.

**ESO doit déjà être installé** sur le cluster (CRD `SecretStore`/`ExternalSecret` disponibles) —
ce module ne l'installe pas, il configure uniquement les objets applicatifs qui en dépendent.

## Exemple

```hcl
module "external_secret_loki" {
  source = "git::https://<repo-url>//modules/external-secret?ref=external-secret-vX.Y.Z"

  name       = "loki"
  project_id = var.project_id
  namespaces = [
    "infra-loki",
  ]
  allowed_secrets = [
    "loki-${terraform.workspace}",
  ]
}

# then only add custom external secrets
resource "kubernetes_manifest" "loki-external-secrets" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "loki-bucket"
      namespace = "infra-loki"
    }
    spec = {
      refreshInterval = "5m"
      secretStoreRef = {
        kind = "SecretStore"
        name = "secretstore"
      }
      dataFrom = [
        {
          extract : {
            key = "id:${split("/", local.loki_secret_key_id)[1]}"
          }
        }
      ]
    }
  }
}
```

Le provider `kubernetes` doit être configuré (dans le repo consommateur, pas dans ce module) avec
les credentials du cluster cible, typiquement à partir des outputs du module `kubernetes-cluster`.

## Pré-requis manuel : le secret bootstrap

Contrairement à AWS/IRSA, Scaleway ne supporte pas l'authentification du `SecretStore` sans
credentials explicites. Ce module lit un secret Secret Manager existant (`bootstrap_secret_name`,
`"scwsm-secret"` par défaut) contenant une clé API et le recopie en secret Kubernetes dans chaque
namespace — il ne le crée pas. Avant le premier `tofu apply` :

1. Console Scaleway → IAM → Applications → l'application créée par ce module (`var.name`).
2. Ajouter une clé d'API (expiration "Never", projet préféré = celui de l'environnement).
3. Console Scaleway → Secret Manager → créer un secret type "Key/Value" nommé comme
   `bootstrap_secret_name`, avec pour valeur :
   ```json
   { "access-key": "SCWC.....", "secret-access-key": "xxxxxxxxxx" }
   ```

## Remarques

- `namespaces` ne crée aucun namespace Kubernetes : il doit déjà exister (cf périmètre "pas de
  ressource Kubernetes applicative" du repo, non concerné par l'exception ci-dessus).
- La policy IAM (`SecretManagerReadOnly` + `SecretManagerSecretAccess`) est fixée en dur : ce
  module a une seule raison d'être (le câblage ESO ↔ Secret Manager), pas une policy générique —
  utiliser [`iam-app-identity`](../iam-app-identity) pour un autre usage IAM.
- Un secret Secret Manager par namespace (clé = nom du namespace) : `dataFrom.extract` de
  l'`ExternalSecret` en recopie tout le contenu key/value vers le secret Kubernetes cible
  (`target_secret_name`, `"external-secrets"` par défaut).
