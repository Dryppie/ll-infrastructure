# Infrastructure repository instructions

- Treat this repository as production-sensitive.
- Inspect and propose changes before modifying deployment files.
- Never run `kubectl apply`, `helm upgrade`, Terraform apply commands, or deployment commands unless explicitly instructed.
- Never read, print, copy, or commit secrets.
- Prefer minimal diffs.
- Explain rollout impact, rollback steps, and required application-version compatibility.
- Validate manifests locally when suitable tooling is available.
