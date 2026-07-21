# CLAUDE.md

Guidance for Claude Code (or any AI assistant) working in this repo. See `README.md` for the
module list and user-facing conventions — this file only covers things specific to *working on*
the repo, not documented there.

## What this repo is

Terraform/OpenTofu modules for Scaleway infrastructure, extracted from real duplication between
two consumer repos:

- `opentofu-ffspt` — `git@github.com:coopTilleuls/opentofu-ffspt.git`
- `sweeek`'s `opentofu-scaleway-k8s` — `git@gitlab.com:alicesgarden/walisoft/les-tilleuls.coop/opentofu-scaleway-k8s.git`

Every module here is meant to be a faithful superset of what both repos actually do in
production, not a green-field redesign. That framing matters for how you validate changes (below).

## Validating a module change

Always, before considering a module change done:

```sh
cd modules/<module>
tofu init -backend=false
tofu validate
cd -
tofu fmt -recursive
```

`.terraform/`, `.terraform.lock.hcl`, `*.tfstate*` are gitignored — don't stage them (`git status`
after any broad `git add` to make sure none slipped in).

## Auditing for real bugs, not cosmetic ones

Several fixes in this repo's history (`vpc`, `iam-app-identity`, `object-bucket`,
`kubernetes-cluster`, `rdb-mysql`, `rdb-postgresql`) came from comparing a module against the
*actual* resource blocks in both source repos, not from reading Terraform docs in isolation. When
asked to find or fix bugs in a module:

1. Clone or locate both source repos and find the equivalent resource block(s) — there are often
   more than one occurrence per source repo (e.g. `iam-app-identity` covers 8 distinct call sites
   across Velero/Loki/ESO/CNPG/registry/CI). Check all of them; a module built as a "superset" can
   miss a variant that only one occurrence used.
2. Verify attribute names/behavior against the *actual* provider schema for the version this repo
   pins (`>= 2.79.0, < 3.0.0`), e.g. `tofu providers schema -json` on a throwaway config — not
   against documentation, which can lag or predate a renamed/removed attribute.
3. Distinguish a confirmed bug (proven divergence with a concrete failure mode) from "worth
   double-checking" — don't report speculation as a finding, and don't invent a problem if a
   thorough comparison turns up nothing. "No bug found" is a valid, useful audit result
   (`container-registry`'s audit found none).
4. Don't fabricate a fix just to have something to commit. If asked to force a release for a
   module with nothing to fix, say so plainly and let the human decide — see below.

## Releases (release-please)

Each `modules/<name>` is an independent release-please package (`release-please-config.json`,
tag format `<name>-vX.Y.Z`, changelog at `modules/<name>/CHANGELOG.md`). Two things must both be
true for a module to get a release PR:

- At least one commit since its last tag touched a file under `modules/<name>/` (path-based —
  an empty commit, or one touching only unrelated files, doesn't count for that module).
- That commit's conventional-commit type is `feat`, `fix`, `perf`, or has a breaking-change
  footer — `chore`/`docs`/`refactor`/etc. don't bump a version by default.

So there is no way to force a release for a module without at least one real commit of a
qualifying type touching that module's directory. If there's truly no bug or feature to justify
one, that module simply stays unreleased until there is — that's working as intended, not a gap
to route around.

## Git hygiene

- Never `git add -A`/`git add .` — stage the specific paths you touched. A broad add previously
  swept in a transient IDE temp file (`.claude/settings.local.json.tmp.*`) that had to be removed
  in a follow-up commit.
- One commit per module per logical change, conventional-commit style (`fix(vpc): ...`,
  `feat(bastion): ...`) — this is also what drives the per-module release-please versioning above.
- Always confirm before `git push`: this repo is consumed by other repos via tagged refs, so a
  push is a shared, visible action, not a local one.
