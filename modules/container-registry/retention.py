"""Purge des anciens tags d'un namespace Scaleway Container Registry.

Exécuté par le Serverless Job créé par ce module (cf. retention.tf). Uniquement la bibliothèque
standard Python : l'image du job n'a besoin d'aucune dépendance.

Pour chaque image (dépôt) du namespace dont le nom matche IMAGE_REGEX :

1. Chaque tag est rattaché à la PREMIÈRE règle de RULES dont `tag_regex` le matche. Un tag qui ne
   matche aucune règle, ou qui matche PROTECTED_TAG_REGEX, est conservé.
2. Dans chaque règle, les tags de l'image sont triés du plus récent au plus ancien : les
   `keep_last` premiers sont conservés, les suivants sont supprimés s'ils ont plus de
   `older_than_days` jours.
3. Un tag qui partage son digest avec un tag conservé n'est jamais supprimé (le supprimer
   supprimerait le manifest, donc aussi l'autre tag). Les suppressions se font sans `force` :
   un refus de l'API laisse le tag en place.
4. Si EMPTY_IMAGE_OLDER_THAN_DAYS est renseigné, une image qui n'a plus aucun tag (après purge)
   et dont la dernière modification date de plus de N jours est supprimée.

Limite : l'API Scaleway n'expose pas les manifests sans tag (pas d'équivalent de
`docker image prune` côté registry), ils ne peuvent donc pas être ciblés ici.

Variables d'environnement : REGISTRY_CREDENTIALS (JSON {"secret_key": ...}, injecté depuis
Secret Manager), REGION, NAMESPACE_ID, RULES (JSON [{"tag_regex", "keep_last",
"older_than_days"}, ...]), PROTECTED_TAG_REGEX, IMAGE_REGEX, EMPTY_IMAGE_OLDER_THAN_DAYS
(vide = désactivé), DRY_RUN ("true"/"false").
"""

import datetime
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.scaleway.com/registry/v1/regions/{region}"
PAGE_SIZE = 100


def env(name, default=None):
    value = os.environ.get(name, default)
    if value is None:
        sys.exit(f"variable d'environnement manquante : {name}")
    return value


SECRET_KEY = json.loads(env("REGISTRY_CREDENTIALS"))["secret_key"]
BASE = API.format(region=env("REGION"))
NAMESPACE_ID = env("NAMESPACE_ID")
PROTECTED = re.compile(env("PROTECTED_TAG_REGEX", "^latest$"))
IMAGES = re.compile(env("IMAGE_REGEX", ".*"))
EMPTY_DAYS = env("EMPTY_IMAGE_OLDER_THAN_DAYS", "")
EMPTY_DAYS = int(EMPTY_DAYS) if EMPTY_DAYS else None
DRY_RUN = env("DRY_RUN", "false").lower() == "true"
RULES = [
    {
        "regex": re.compile(r["tag_regex"]),
        # Les valeurs par défaut (10 / 30) sont appliquées côté Terraform (variables.tf).
        "keep_last": int(r["keep_last"]),
        "older_than_days": int(r["older_than_days"]),
    }
    for r in json.loads(env("RULES"))
]
NOW = datetime.datetime.now(datetime.timezone.utc)


def call(method, path, params=None):
    url = BASE + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, method=method, headers={"X-Auth-Token": SECRET_KEY})
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read()
    return json.loads(body) if body else {}


def paginate(path, key, params):
    page = 1
    while True:
        data = call("GET", path, {**params, "page": page, "page_size": PAGE_SIZE})
        items = data.get(key, [])
        yield from items
        if len(items) < PAGE_SIZE:
            return
        page += 1


def age_days(value):
    date = datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    return (NOW - date).total_seconds() / 86400


def delete(path, label, stats):
    if DRY_RUN:
        print(label + " [dry-run]")
        stats["deleted"] += 1
        return True
    try:
        call("DELETE", path)
        print(label + " supprimé")
        stats["deleted"] += 1
        return True
    except urllib.error.HTTPError as err:
        print(label + f" ÉCHEC {err.code}: {err.read().decode(errors='replace')}")
        stats["failed"] += 1
        return False


def select_tags(tags):
    """Retourne (à conserver, à supprimer) selon PROTECTED_TAG_REGEX et RULES."""
    keep, by_rule = [], [[] for _ in RULES]
    for tag in tags:
        if PROTECTED.search(tag["name"]):
            keep.append(tag)
            continue
        index = next((i for i, r in enumerate(RULES) if r["regex"].search(tag["name"])), None)
        if index is None:
            keep.append(tag)
        else:
            by_rule[index].append(tag)

    candidates = []
    for rule, rule_tags in zip(RULES, by_rule):
        rule_tags.sort(key=lambda t: age_days(t["created_at"]))
        for position, tag in enumerate(rule_tags):
            if position < rule["keep_last"] or age_days(tag["created_at"]) < rule["older_than_days"]:
                keep.append(tag)
            else:
                candidates.append(tag)

    kept_digests = {t["digest"] for t in keep if t.get("digest")}
    return keep, [t for t in candidates if t.get("digest") not in kept_digests]


def main():
    stats = {"deleted": 0, "failed": 0}
    print(
        f"namespace={NAMESPACE_ID} images={IMAGES.pattern!r} protected={PROTECTED.pattern!r} "
        f"empty_image_older_than_days={EMPTY_DAYS} dry_run={DRY_RUN}"
    )
    for rule in RULES:
        print(
            f"  règle tag_regex={rule['regex'].pattern!r} keep_last={rule['keep_last']} "
            f"older_than_days={rule['older_than_days']}"
        )

    for image in list(paginate("/images", "images", {"namespace_id": NAMESPACE_ID})):
        if not IMAGES.search(image["name"]):
            continue

        tags = list(paginate(f"/images/{image['id']}/tags", "tags", {}))
        keep, to_delete = select_tags(tags)
        print(f"{image['name']}: {len(tags)} tags, {len(to_delete)} à supprimer")

        remaining = len(keep)
        for tag in sorted(to_delete, key=lambda t: -age_days(t["created_at"])):
            label = f"  {image['name']}:{tag['name']} ({tag['created_at']})"
            if not delete(f"/tags/{tag['id']}", label, stats):
                remaining += 1

        if (
            EMPTY_DAYS is not None
            and remaining == 0
            and age_days(image["updated_at"]) >= EMPTY_DAYS
        ):
            label = f"  {image['name']} (image sans tag, modifiée le {image['updated_at']})"
            delete(f"/images/{image['id']}", label, stats)

    verb = "à supprimer" if DRY_RUN else "supprimés"
    print(f"terminé : {stats['deleted']} {verb}, {stats['failed']} échecs")
    if stats["failed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
