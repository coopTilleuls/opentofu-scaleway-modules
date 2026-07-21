# kubernetes-cluster

Crée un cluster Kapsule (Kubernetes managé Scaleway) multi-AZ avec ses pools de
nodes, l'autoscaler, l'auto-upgrade du control plane, et optionnellement l'OIDC
(par ex. pour authentifier les développeurs via GitLab sans distribuer de
kubeconfig statique).

Ce module **ne gère aucun objet Kubernetes** (namespaces, RBAC, ingress, Helm
releases...) : ceux-ci restent la responsabilité de chaque repo consommateur
(voir la demande initiale). Il ne fait que provisionner l'infrastructure
Scaleway du cluster.

## Exemple

```hcl
module "kubernetes" {
  source = "git::https://<repo-url>//modules/kubernetes-cluster?ref=kubernetes-cluster-vX.Y.Z"

  name                = "myproject-${terraform.workspace}"
  project_id          = var.project_id
  version_prefix      = "1.35"
  private_network_id  = module.vpc.private_network_ids["kubernetes"]
  tags                = ["myproject"]

  auto_upgrade = {
    maintenance_window_day = "monday"
  }

  open_id_connect_config = {
    issuer_url     = "https://gitlab.com/.well-known/openid-configuration"
    client_id      = "myproject-${terraform.workspace}"
    required_claim = ["project_path=group/project"]
  }

  pools = {
    default = {
      zone     = "fr-par-1"
      node_type = "PRO2-XXS"
      size      = 1
      max_size  = 2
    }
  }

  # Force l'attente de la propagation réseau avant de créer les pools.
  network_dependencies = [module.vpc.gateway_network_ids]

  depends_on = [module.vpc]
}
```

## Remarques

- `version_prefix` correspond à l'argument `version` de `scaleway_k8s_cluster`, renommé pour
  éviter toute ambiguïté avec le mot-clé Terraform `version`.
- `prevent_destroy = true` est figé en dur sur le cluster : un cluster de production ne doit pas
  pouvoir être détruit par un `tofu apply`/`destroy` accidentel. Le désactiver nécessite d'éditer
  ce module.
- `pools` accepte aussi bien un pool simple par zone (cas `ffspt`) qu'une matrice riche
  zone × taille × taints (cas `sweeek`) : c'est un simple `map(object(...))`, la logique de
  génération de la matrice reste à la charge du module appelant si besoin (`for`/`merge` dans
  les `locals` du repo consommateur).
- `network_dependencies` sert uniquement à forcer, via `depends_on`, l'attente de la fin de
  création du réseau/de la gateway avant les pools (contourne un délai de propagation de route
  observé en production).
- `install_kubeconfig` est à `false` par défaut (contrairement aux repos d'origine) : ce
  `local-exec` n'a de sens que sur un poste de dev avec le CLI `scw` configuré, pas en CI.
