# rabbitmq-operator

Installe les operators [RabbitMQ Cluster Operator](https://github.com/rabbitmq/cluster-operator) et
[RabbitMQ Messaging Topology Operator](https://github.com/rabbitmq/messaging-topology-operator)
(cf [vue d'ensemble](https://www.rabbitmq.com/kubernetes/operator/operator-overview)) sur un
cluster Kubernetes déjà provisionné (typiquement par le module
[`kubernetes-cluster`](../kubernetes-cluster)) : CRD + operator (namespace `rabbitmq-system`, RBAC,
`Deployment`) pour le premier, puis CRD + operator (variante "with-certmanager", webhook de
validation) pour le second, téléchargés directement depuis les releases GitHub officielles pour les
versions indiquées.

**Exception au périmètre général de ce repo** : ce module crée des ressources Kubernetes
(`kubernetes_manifest` cluster operator + topology operator), alors que la règle des autres modules
de ce repo est justement de ne jamais en créer (cf README racine). Exception assumée ici pour la
même raison que les modules [`flux`](../flux) et
[`elasticsearch-operator`](../elasticsearch-operator) : un module d'installation d'operator sans ces
objets n'aurait aucune substance.

## Exemple

```hcl
module "rabbitmq_operator" {
  source = "git::https://<repo-url>//modules/rabbitmq-operator?ref=rabbitmq-operator-vX.Y.Z"

  cluster_operator_version  = "v2.19.2"
  topology_operator_version = "v1.19.0"
  patch_dir                 = "${path.root}/patches/rabbitmq-operator"

  providers = {
    kubernetes = kubernetes
  }
}
```

Le provider `kubernetes` doit être configuré (dans le repo consommateur, pas dans ce module) avec
les credentials du cluster cible, typiquement à partir des outputs du module `kubernetes-cluster`
(`apiserver_url`, `token`/`kubeconfig`, `cluster_ca_certificate`).

## Remarques

- Ce module ne fait qu'installer les deux operators eux-mêmes : la création des ressources
  applicatives (`RabbitmqCluster`, `Queue`, `Policy`, `User`...) reste, comme les autres objets
  Kubernetes applicatifs, à la charge de chaque repo consommateur.
- `cluster_operator_version` et `topology_operator_version` déterminent directement les URLs de
  téléchargement des manifests officiels (releases GitHub) : voir les listes de versions
  disponibles sur
  [cluster-operator/releases](https://github.com/rabbitmq/cluster-operator/releases) et
  [messaging-topology-operator/releases](https://github.com/rabbitmq/messaging-topology-operator/releases).
  Pas de valeur par défaut, pour que chaque repo consommateur maîtrise explicitement les versions
  installées (et leur montée de version).
- Le manifest `Namespace--rabbitmq-system` du topology operator est exclu automatiquement (déjà
  créé par le cluster operator) pour éviter un conflit de ressource entre les deux jeux de
  manifests.
- Les manifests du cluster operator sont appliqués avant ceux du topology operator (`depends_on`),
  comme pour l'operator ECK dans [`elasticsearch-operator`](../elasticsearch-operator) : les CRD
  et le namespace doivent exister avant que le topology operator ne démarre.
- `patch_dir` permet, comme pour [`elasticsearch-operator`](../elasticsearch-operator), de patcher
  un manifest (cluster ou topology operator) sans forker ce module : tout fichier
  `<Kind>--<name>.yml` du répertoire est appliqué en strategic merge patch (mêmes règles qu'un
  `kubectl patch --type=strategic`) sur le manifest correspondant. Le répertoire est fourni par le
  repo consommateur (ex: `patches/rabbitmq-operator` à sa racine) — ce module ne fait aucune
  hypothèse sur son contenu ni sur une éventuelle distinction prod/nonprod, à la charge de
  l'appelant s'il en a besoin.
