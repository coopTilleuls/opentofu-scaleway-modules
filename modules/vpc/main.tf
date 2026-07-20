resource "scaleway_vpc" "this" {
  name           = var.name
  project_id     = var.project_id
  enable_routing = var.enable_routing
  tags           = var.tags
}

resource "scaleway_vpc_private_network" "this" {
  for_each = var.private_networks

  name       = each.key
  vpc_id     = scaleway_vpc.this.id
  project_id = var.project_id
  tags       = var.tags

  ipv4_subnet {
    subnet = each.value.subnet
  }
}

locals {
  # Aplatit { gw_key => { zones = [...], ... } } en { "gw_key/zone" => { gw_key, zone, ... } }
  # pour créer une gateway par (nom logique, zone) avec un for_each simple.
  gateway_instances = merge([
    for gw_key, gw in var.public_gateways : {
      for zone in gw.zones : "${gw_key}/${zone}" => merge(gw, {
        gateway_key = gw_key
        zone        = zone
      })
    }
  ]...)
}

resource "scaleway_vpc_public_gateway_ip" "gateway" {
  # scaleway_flexible_ip est la ressource IP flexible d'Elastic Metal (serveurs baremetal) : elle
  # n'a rien à voir avec l'IP publique d'une VPC Public Gateway, malgré la ressemblance du nom.
  # scaleway_vpc_public_gateway_ip est le type dédié à cet usage.
  for_each = local.gateway_instances

  zone       = each.value.zone
  project_id = var.project_id
  tags       = var.tags
}

resource "scaleway_vpc_public_gateway" "this" {
  for_each = local.gateway_instances

  name       = "${var.name}-${each.value.gateway_key}-${each.value.zone}"
  zone       = each.value.zone
  type       = each.value.type
  ip_id      = scaleway_vpc_public_gateway_ip.gateway[each.key].id
  project_id = var.project_id
  tags       = var.tags
}

resource "scaleway_ipam_ip" "gateway" {
  # Réserve, via IPAM, l'IP privée que la gateway utilisera côté private network
  # (distincte de l'IP flexible publique ci-dessus).
  for_each = local.gateway_instances

  source {
    private_network_id = scaleway_vpc_private_network.this[each.value.private_network_key].id
  }
}

resource "time_sleep" "wait_after_gateway" {
  # La gateway n'est pas immédiatement visible par l'API juste après sa création (propagation
  # asynchrone côté Scaleway) : sans ce délai, l'attachement au private network échoue par
  # intermittence avec "resource gateway with ID ... is not found" alors que la gateway existe bien.
  for_each = local.gateway_instances

  depends_on      = [scaleway_vpc_public_gateway.this]
  create_duration = "15s"
}

resource "scaleway_vpc_gateway_network" "this" {
  for_each = local.gateway_instances

  depends_on = [time_sleep.wait_after_gateway]

  gateway_id         = scaleway_vpc_public_gateway.this[each.key].id
  private_network_id = scaleway_vpc_private_network.this[each.value.private_network_key].id
  enable_masquerade  = each.value.enable_masquerade

  ipam_config {
    push_default_route = each.value.push_default_route
    ipam_ip_id         = scaleway_ipam_ip.gateway[each.key].id
  }
}

locals {
  # Aplatit { lb_key => { zones = [...] } } en { "lb_key/zone" => { lb_key, zone } }.
  reserved_lb_ip_instances = merge([
    for lb_key, lb in var.reserved_lb_ips : {
      for zone in lb.zones : "${lb_key}/${zone}" => {
        lb_key = lb_key
        zone   = zone
      }
    }
  ]...)
}

resource "scaleway_lb_ip" "this" {
  # Réserve uniquement l'IP flexible : le load balancer lui-même est créé en aval
  # (ex. par l'ingress controller), qui vient s'attacher à cette IP.
  for_each = local.reserved_lb_ip_instances

  zone       = each.value.zone
  project_id = var.project_id
  tags       = var.tags
}
