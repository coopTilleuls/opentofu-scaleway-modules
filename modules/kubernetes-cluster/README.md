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

  zones = ["fr-par-1", "fr-par-2", "fr-par-3"]

  pools = [
    {
      name = "default"
      sizes = [
        { node_type = "PRO2-XXS", max_per_zone = 2 },
      ]
    },
  ]

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
- `pools` est une liste de familles de pools (nom + taints/labels + tailles) ; le module
  démultiplie lui-même chaque famille sur `var.zones` et sur ses `sizes` (une `scaleway_k8s_pool`
  par combinaison famille × taille × zone). Une taille peut se limiter à certaines zones (`zones`)
  et garder un plancher par zone (`min_per_zone`, 0 par défaut). `autoscaling`, `autohealing` et
  `container_runtime` ne sont pas paramétrables : le module suppose systématiquement un autoscaler
  actif qui pilote la taille réelle du pool depuis sa création.
- `public_ip_disabled` (`true` par défaut) : les nodes sortent par la public gateway du module
  `vpc`. Avec `false`, chaque node a son IP publique et sort seul, sans gateway ni route par
  défaut à pousser ; `network_dependencies` devient alors inutile.

  Exemple, nodes publics sur trois zones, un seul petit node dans la plus chère, et des petits
  nodes de débordement dans une famille à part, qui démarre donc à 0 :

  ```hcl
  public_ip_disabled = false
  zones              = ["fr-par-1", "fr-par-2", "fr-par-3"]

  pools = [
    {
      name = "default"
      sizes = [
        { node_type = "PRO2-XS", min_per_zone = 1, max_per_zone = 3, zones = ["fr-par-1", "fr-par-2"] },
        { node_type = "PRO2-XXS", min_per_zone = 1, max_per_zone = 1, zones = ["fr-par-3"] },
      ]
    },
    {
      name  = "overflow"
      sizes = [{ node_type = "PRO2-XXS", max_per_zone = 2, zones = ["fr-par-1", "fr-par-2"] }]
    },
  ]
  ```
- Le nom réel du pool (argument `name`) inclut un hash de `root_volume_size_in_gb` (seul attribut
  encore variable et `ForceNew` du provider) pour garantir que l'ancien et le nouveau pool n'ont
  jamais le même nom pendant la fenêtre de `create_before_destroy` — la clé du pool dans
  `pool_ids` (sortie), elle, reste stable et n'inclut pas ce hash.
- `network_dependencies` sert uniquement à forcer, via `depends_on`, l'attente de la fin de
  création du réseau/de la gateway avant les pools (contourne un délai de propagation de route
  observé en production).
- `install_kubeconfig` est à `false` par défaut (contrairement aux repos d'origine) : ce
  `local-exec` n'a de sens que sur un poste de dev avec le CLI `scw` configuré, pas en CI.
