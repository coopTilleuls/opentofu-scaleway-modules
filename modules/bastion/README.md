# bastion

Crée une instance compute Scaleway servant de bastion SSH/DBA, rattachée à un
private network (typiquement le private network "tools" du module
[`vpc`](../vpc)), avec son IP publique et un volume additionnel optionnel.

## Exemple

```hcl
module "bastion" {
  source = "git::https://<repo-url>//modules/bastion?ref=vX.Y.Z"

  name                = "bastion-${terraform.workspace}"
  project_id          = var.project_id
  image               = "debian_trixie"
  private_network_id  = module.vpc.private_network_ids["tools"]
  tags                = ["myproject"]

  additional_volume_size_gb = 100

  user_data = {
    "cloud-init" = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", { ... })
  }
}
```

## Remarques

- `image` n'a pas de valeur par défaut : les deux repos d'origine utilisent des images
  différentes (`ubuntu_noble` côté `sweeek`, `debian_trixie` côté `ffspt`).
- L'IP publique (`scaleway_instance_ip`) a `prevent_destroy = true` : c'est un point d'entrée
  connu (whitelisté côté firewall, référencé en DNS...) qui ne doit pas disparaître par erreur.
- `additional_volume_size_gb = 0` (défaut) ne crée aucun volume additionnel.
