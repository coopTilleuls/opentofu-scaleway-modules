# elasticsearch-operator

Installe l'operator [ECK (Elastic Cloud on Kubernetes)](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/k8s-openshift-deploy-operator)
sur un cluster Kubernetes déjà provisionné (typiquement par le module
[`kubernetes-cluster`](../kubernetes-cluster)) : CRD puis manifests de l'operator (namespace
`elastic-system`, RBAC, webhook, `StatefulSet`), téléchargés directement depuis
`download.elastic.co` pour la version indiquée.

**Exception au périmètre général de ce repo** : ce module crée des ressources Kubernetes
(`kubernetes_manifest` CRD + operator), alors que la règle des autres modules de ce repo est
justement de ne jamais en créer (cf README racine). Exception assumée ici pour la même raison que
le module [`flux`](../flux) : un module d'installation d'operator sans ces objets n'aurait aucune
substance.

## Exemple

```hcl
module "elasticsearch_operator" {
  source = "git::https://<repo-url>//modules/elasticsearch-operator?ref=elasticsearch-operator-vX.Y.Z"

  eck_version = "3.5.0"
  patch_dir   = "${path.root}/patches/elasticsearch-operator"

  providers = {
    kubernetes = kubernetes
  }
}
```

Le provider `kubernetes` doit être configuré (dans le repo consommateur, pas dans ce module) avec
les credentials du cluster cible, typiquement à partir des outputs du module `kubernetes-cluster`
(`apiserver_url`, `token`/`kubeconfig`, `cluster_ca_certificate`).

## Remarques

- Ce module ne fait qu'installer l'operator lui-même (CRD + `StatefulSet` `elastic-operator`) :
  la création des ressources applicatives (`Elasticsearch`, `Kibana`...) reste, comme les autres
  objets Kubernetes applicatifs, à la charge de chaque repo consommateur.
- `eck_version` détermine directement les URLs de téléchargement
  (`https://download.elastic.co/downloads/eck/<version>/{crds,operator}.yaml`) : voir la liste des
  versions disponibles sur la
  [doc officielle](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/k8s-openshift-deploy-operator).
  Pas de valeur par défaut, pour que chaque repo consommateur maîtrise explicitement la version
  installée (et sa montée de version).
- Par défaut, l'operator ECK surveille tous les namespaces du cluster (pas de restriction
  `managed-namespaces` configurée par ce module) — cf la doc officielle pour restreindre ce
  périmètre si besoin.
- Les manifests CRD sont appliqués avant ceux de l'operator (`depends_on`), comme pour l'operator
  RabbitMQ dans les repos consommateurs (même contrainte d'ordre : les CRD doivent exister avant
  que le contrôleur ne démarre).
- `patch_dir` permet, comme pour l'operator RabbitMQ dans les repos consommateurs, de patcher un
  manifest (CRD ou operator) sans forker ce module : tout fichier `<Kind>--<name>.yml` du
  répertoire est appliqué en strategic merge patch (mêmes règles qu'un `kubectl patch
  --type=strategic`) sur le manifest correspondant. Le répertoire est fourni par le repo
  consommateur (ex: `patches/elasticsearch-operator` à sa racine) — ce module ne fait aucune
  hypothèse sur son contenu ni sur une éventuelle distinction prod/nonprod, à la charge de
  l'appelant s'il en a besoin.
