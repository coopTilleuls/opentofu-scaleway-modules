#!/usr/bin/env bash
# data "external" program : recoit {"base": "<json manifest>", "patch": "<yaml patch>"} sur stdin,
# renvoie {"merged": "<json manifest patché>"} sur stdout.
# Le merge utilise "kubectl patch --local" pour une sémantique de strategic merge patch k8s
# (les listes comme spec.template.spec.containers sont fusionnées par clé "name", pas par index).
set -euo pipefail

query=$(cat)
base_json=$(jq -r '.base' <<<"$query")
patch_yaml=$(jq -r '.patch' <<<"$query")

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

base_file="$tmp_dir/base.json"
patch_file="$tmp_dir/patch.yml"

printf '%s' "$base_json" >"$base_file"
printf '%s' "$patch_yaml" >"$patch_file"

merged=$(kubectl patch --local -o json --type=strategic -f "$base_file" --patch-file "$patch_file")

jq -n --arg merged "$merged" '{merged: $merged}'
