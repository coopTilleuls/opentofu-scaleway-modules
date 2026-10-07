# Schéma de l'arbre de routage Alertmanager du module cockpit-alerting (main.tf, resource
# mimir_alertmanager_config.this).
#
# Rendu : uv run --with diagrams python grafana-route-matcher.py
from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.client import Users
from diagrams.onprem.monitoring import Mimir
from diagrams.programming.flowchart import Decision, Delay

graph_attr = {"fontsize": "20", "pad": "0.5", "nodesep": "0.9", "ranksep": "1.1", "splines": "spline"}

YES = {"color": "darkgreen", "fontcolor": "darkgreen"}
NO = {"color": "firebrick", "fontcolor": "firebrick", "style": "dashed"}
CONT = {"color": "darkorange", "fontcolor": "darkorange", "style": "bold"}

with Diagram(
    "Routage Alertmanager - cockpit-alerting",
    filename="grafana-route-matcher",
    outformat="png",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
):
    alert = Mimir("Alerte émise\n(labels : severity, service_level…)")

    with Cluster("Contact points (webhooks)"):
        cp_info = Users("info")
        cp_warning = Users("warning")
        cp_critical = Users("critical")

    with Cluster("Route racine (receiver = info)\nchild_route évaluées dans l'ordre, arrêt au 1er match sauf continue = true"):
        r1 = Decision("Route 1 (l.461)\nseverity=\"warning\"")
        r4 = Decision("Route 2 (l.500)\nseverity=\"critical\"")

    alert >> r1

    r1 >> Edge(label="match -> stop", **YES) >> cp_warning
    r1 >> Edge(label="non", **NO) >> r2

    t2 >> Edge(label="notifie seulement\nen heures ouvrées", **YES) >> cp_critical
    r2 >> Edge(label="match + continue = true\n(on évalue aussi la suivante)\nou non", **CONT) >> r3

    t3 >> Edge(label="notifie seulement\nhors heures ouvrées", **YES) >> cp_warning
    r3 >> Edge(label="non", **NO) >> r4

    r4 >> Edge(label="match -> stop", **YES) >> cp_critical
    r4 >> Edge(label="aucune route matchée\n-> receiver de la racine", **NO) >> cp_info
