# bastion

Crée une instance compute Scaleway servant de bastion SSH/DBA, rattachée à un
private network (typiquement le private network "tools" du module
[`vpc`](../vpc)), avec son IP publique et un volume additionnel optionnel.

## Exemple

```hcl
module "bastion" {
  source = "git::https://<repo-url>//modules/bastion?ref=bastion-vX.Y.Z"

  name                = "bastion-${terraform.workspace}"
  project_id          = var.project_id
  image               = "debian_trixie"
  private_network_id  = module.vpc.private_network_ids["tools"]
  tags                = ["myproject"]

  additional_volume_size_gb = 100

  # cloud-init : uniquement le bootstrap "une seule fois" (user admin + clé SSH, paquets,
  # formatage/montage du volume additionnel, installation de kubectl/ansible...).
  user_data = {
    "cloud-init" = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", { ... })
  }

  # Ansible : la configuration ré-appliquable (comptes utilisateurs...), reprise du motif utilisé
  # dans opentofu-ffspt (2_environments/4_bastion/ansible/playbook.yml + group_vars/bastion.yml
  # + roles/users). Ré-exécuté à chaque `tofu apply` où l'un des triggers change, sans recréer le
  # bastion.
  ansible_playbook_path   = "${path.root}/ansible/playbook.yml"
  ansible_extra_vars_file = "${path.root}/ansible/group_vars/bastion.yml"
  ansible_triggers = {
    playbook_hash = filemd5("${path.root}/ansible/playbook.yml")
    vars_hash     = filemd5("${path.root}/ansible/group_vars/bastion.yml")
  }
}
```

## Remarques

- `image` n'a pas de valeur par défaut : les deux repos d'origine utilisent des images
  différentes (`ubuntu_noble` côté `sweeek`, `debian_trixie` côté `ffspt`).
- L'IP publique (`scaleway_instance_ip`) a `prevent_destroy = true` : c'est un point d'entrée
  connu (whitelisté côté firewall, référencé en DNS...) qui ne doit pas disparaître par erreur.
- `additional_volume_size_gb = 0` (défaut) ne crée aucun volume additionnel.
- `ansible_playbook_path = null` (défaut) : Ansible n'est pas exécuté, le bastion n'est configuré
  que par `user_data`. Le définir active un `null_resource` qui attend la fin de cloud-init
  (`cloud-init status --wait`) puis lance `ansible-playbook` en SSH sur l'IP publique du bastion.
- Le playbook et ses fichiers de variables restent dans le repo consommateur (ex: `ansible/` à côté
  de ce module) : ce module ne porte aucune logique métier Ansible, seulement l'exécution.
- Sans entrée dans `ansible_triggers` (ou si les fichiers référencés ne changent pas), Ansible ne
  se ré-exécute qu'à la création du bastion — comme n'importe quel `null_resource`.
