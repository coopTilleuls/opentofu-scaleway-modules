# vpc

Crée un VPC Scaleway, un ou plusieurs private networks, des public gateways (avec
leur IP privée réservée via IPAM et leur rattachement au private network), et
permet de réserver à l'avance des IPs flexibles de load-balancer (par exemple
pour figer l'IP d'un ingress controller avant de configurer le DNS).

## Exemple

```hcl
module "vpc" {
  source = "git::https://<repo-url>//modules/vpc?ref=vX.Y.Z"

  name           = "vpc-multi-az"
  project_id     = var.project_id
  enable_routing = true
  tags           = ["myproject"]

  private_networks = {
    kubernetes = { subnet = cidrsubnet(var.vpc_cidr, 6, 2) }
    tools      = { subnet = cidrsubnet(var.vpc_cidr, 6, 3) }
  }

  public_gateways = {
    kubernetes = {
      private_network_key = "kubernetes"
      zones                = var.scw_lb_zones
      type                 = "VPC-GW-S"
    }
  }

  reserved_lb_ips = {
    nginx-ingress = { zones = var.scw_lb_zones }
  }
}
```

## Remarques

- `private_networks[*].subnet` attend un CIDR complet : le calcul (par ex. via `cidrsubnet()`)
  est laissé au module appelant, afin que ce module n'ait aucune opinion sur le plan
  d'adressage global du projet.
- Chaque entrée de `public_gateways` crée une gateway par zone listée dans `zones`, toutes
  rattachées au même `private_network_key`.
- `reserved_lb_ips` ne réserve que des IPs flexibles (`scaleway_lb_ip`) ; ça ne crée pas de
  `scaleway_lb` — l'IP réservée doit être attachée lors de la création du load balancer en aval
  (par ex. via les values Helm de l'ingress controller).
