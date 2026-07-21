# flux

Bootstrap FluxCD sur un cluster Kubernetes déjà provisionné (typiquement par le module
[`kubernetes-cluster`](../kubernetes-cluster)) : namespace `flux-system`, clé de déploiement SSH,
clé sealed-secrets, installation des controllers via le CLI `flux`, et objets `GitRepository`
/ `Kustomization` pointant vers le repo Git GitOps du repo consommateur.

**Exception au périmètre général de ce repo** : ce module crée des ressources Kubernetes
(namespace, secrets, ConfigMap, `kubernetes_manifest` CRD Flux), alors que la règle des autres
modules de ce repo est justement de ne jamais en créer (cf README racine). Exception assumée ici
car le bootstrap Flux est indissociable de ces objets — un module "flux" sans eux n'aurait aucune
substance.

**Ce module ne modernise pas le bootstrap** : il reprend tel quel le motif observé dans `sweeek`
et `opentofu-ffspt` (CLI `flux install` en `local-exec`, pas le provider officiel
`fluxcd/flux`/`flux_bootstrap_git`, pas de provider `github`/`gitlab` pour la deploy key). Il
hérite donc des mêmes contraintes opérationnelles que les repos d'origine (voir "Remarques").

## Exemple

```hcl
module "flux" {
  source = "git::https://<repo-url>//modules/flux?ref=vX.Y.Z"

  git_repository_url = "ssh://git@github.com/<org>/<repo-gitops>"
  git_branch          = terraform.workspace == "prod" ? "main" : "staging"
  git_known_hosts     = file("${path.root}/known_hosts/github.com")
  kustomization_path  = "./clusters/${var.cluster_name}"

  # Optionnel : IPs/valeurs à substituer dans les manifests Flux (postBuild.substituteFrom).
  terraform_outputs_data = {
    nginx_ingress_controller_fr_par_1 = local.ingress_ip
  }

  providers = {
    kubernetes = kubernetes
    tls        = tls
    null       = null
  }
}
```

Le provider `kubernetes` doit être configuré (dans le repo consommateur, pas dans ce module) avec
les credentials du cluster cible, typiquement à partir des outputs du module `kubernetes-cluster`
(`apiserver_url`, `token`/`kubeconfig`, `cluster_ca_certificate`).

## Remarques

- **Bootstrap en deux `tofu apply`** : sur un cluster tout neuf, les CRD Flux
  (`GitRepository`/`Kustomization`) n'existent pas encore. Le premier apply installe uniquement
  les controllers Flux (`null_resource.flux_install`) ; les `kubernetes_manifest` GitRepository et
  Kustomization ne sont créés qu'au second apply, une fois les controllers détectés dans le
  cluster (via `data.kubernetes_resources.flux_deployment`). C'est le même motif "œuf et poule"
  que dans les repos d'origine, pas une régression introduite par ce module.
- **Le CLI `flux` doit être installé et un kubeconfig valide disponible** sur la machine qui
  exécute `tofu apply` (le `null_resource.flux_install` lance `flux install` en `local-exec`).
  `flux_install_kubectl_context` permet de préciser le contexte kubeconfig à utiliser (laisser
  `null` pour le contexte courant).
- **La deploy key n'est pas enregistrée automatiquement** côté GitHub/GitLab : après le premier
  apply, récupérer `output.deploy_key_public` et l'ajouter manuellement comme deploy key (lecture
  seule) sur le repo Git référencé par `git_repository_url`. Aucun provider `github`/`gitlab`
  n'est utilisé ici (comme dans les repos d'origine).
- `git_known_hosts` doit correspondre à l'hébergeur de `git_repository_url` (ex: sortie de
  `ssh-keyscan github.com` ou `ssh-keyscan gitlab.com`) — pas de valeur par défaut, car les deux
  repos d'origine référencent tous les deux `github.com` en dur (dont un cas qui semble être un
  copier-coller à vérifier côté repo consommateur).
- `enable_sealed_secrets = true` (défaut) crée la clé/certificat et le secret
  `sealed-secrets-key` attendus par le controller sealed-secrets. Mettre à `false` si non utilisé.
- `terraform_outputs_data` (vide par défaut) alimente la ConfigMap `terraform-outputs`
  (namespace `flux-system`), destinée aux `postBuild.substituteFrom` des Kustomization Flux du
  repo consommateur (ex: IPs de load-balancer à injecter dans des manifests). Contenu
  entièrement libre, propre à chaque consommateur.
- `tls_private_key.flux_system` (deploy key) et `tls_private_key.sealed_secrets` ont
  `prevent_destroy = true` : leur perte casserait respectivement l'accès Git de Flux et le
  déchiffrement des secrets scellés existants.
