# Routage des alertes dans `cockpit-alerting` : matchers, `continue` et plages horaires

Source : `modules/cockpit-alerting/main.tf`, ressource `mimir_alertmanager_config.this`
(bloc `route`, lignes ~451-509).

![Arbre de routage Alertmanager](grafana-route-matcher.png)

Schéma généré avec le module Python [`diagrams`](https://diagrams.mingrammer.com/) (rendu Graphviz) :

```sh
cd /tmp/doc
uv run --with diagrams python grafana-route-macher.py
```

## 1. Les matchers d'une route sont un ET logique

```hcl
child_route {
  matchers = [
    "severity=\"critical\"",
    "service_level=\"7/5\"",
  ]
  ...
}
```

Une route ne matche que si l'alerte satisfait **tous** les matchers de la liste. Ici il faut donc
`severity="critical"` **et** `service_level="7/5"`. Une alerte `critical` sans label
`service_level` (ou avec `service_level="24/7"`) ne matche pas cette route.

Pour faire un **OU** :

- sur les valeurs d'un même label : utiliser une regex, par exemple `severity=~"critical|warning"` ;
- sur des labels différents : Alertmanager n'a pas de OU entre matchers, il faut plusieurs
  `child_route`.

## 2. Ordre d'évaluation et `continue`

Les `child_route` sont évaluées **dans l'ordre**, de haut en bas :

- à la première route qui matche, l'évaluation **s'arrête**,
- sauf si cette route a `continue = true` : dans ce cas, Alertmanager évalue aussi les routes
  suivantes ;
- si aucune route ne matche, l'alerte part vers le receiver de la route racine (`info`).

## 3. Les quatre routes du module

| # | Ligne | Matchers (ET) | Contact point | Plage horaire | `continue` |
|---|---|---|---|---|---|
| 1 | l.461 | `severity="warning"` | `warning` | toujours | non |
| 2 | l.500 | `severity="critical"` | `critical` | toujours | non |
| - | racine | (aucun match) | `info` | toujours | - |

## 4. Pourquoi Grafana affiche deux policies identiques

Dans Grafana, `/alerting/routes?contactPoint=critical` et `/alerting/routes?contactPoint=warning`
affichent chacune une policy `severity = critical` + `service_level = 7/5`. Ce n'est pas un doublon :
ce sont les **routes 2 et 3**, qui ont les mêmes matchers mais :

- des **contact points** différents (`critical` pour l'une, `warning` pour l'autre) ;
