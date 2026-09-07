# AGENTS.md

## Purpose

This repository supports Kubernetes Cluster API (CAPI) training.

## Source Of Truth

- Treat `ref-labs/` as read-only unless explicitly requested otherwise.
- The active lab sequence is the eight numbered `*_gce.md` files in `ref-labs/`.
- Treat `ref-labs/_README.md` and `ref-labs/acknowledgements.md` as supporting references.
- Treat `ref-labs/k8s_lab_azure.md` and `ref-labs/k8s_lab_gce_deprecated.md` as legacy background only.
- Preserve the technical intent of active labs and keep wording practical and concise.
- Do not include secret values in documentation or tracking files.

## Protected Paths

- `docs/` and `Dockerfile` are user-managed. Do not modify them unless explicitly asked.
- Do not inspect or change `helm/` unless explicitly asked.

## Command Formatting

- Add a short comment immediately above each command block.
- Use one command block per command.
- Follow every command block with an expected-result admonition:

```md
??? example "Expected result"
    Expected output or verification notes.
```

- Keep commands and expected results paired.
- Use representative, concrete success output. Use `No output.` when applicable.

## Live Training

- Use an interactive workflow only when explicitly requested for live training.
- Present one instruction and one command at a time.
- Before each command, state the exact student-facing command and its purpose in one sentence.
- Wait for explicit approval before executing each command; treat `go` as approval.
- After execution, verify the result and explain its meaning before continuing.
- Do not update `commands.md` during live interactive training.

## Tracking Files

- `migration.md` tracks CAPI lab preparation and validation status.
- `playground.md` records approved internal lab context without credentials or secret values.
- Outside live training, record only successfully executed training commands in `commands.md` using the exact executed command string.
- Do not record failed, exploratory, or corrected commands.
- Mark a lab complete only after its commands have been validated and results documented.

## Delegation

- For discovery, use a read-only exploration agent when available.
- For bounded analysis or implementation, use an appropriate general agent when available and safe.
- Limit subagents to this repository root and prohibit remote or network access unless the user explicitly authorizes a named target and scope.
- Do not ask subagents to guess targets, credentials, commands, or infrastructure details.
- Keep delegation bounded to one level and request concise factual results.
