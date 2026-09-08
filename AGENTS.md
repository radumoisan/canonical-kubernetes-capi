# AGENTS.md

## Purpose

This repository supports Kubernetes Cluster API (CAPI) training.

## Source Of Truth

- Treat `ref-labs/` as read-only unless explicitly requested otherwise.
- The active lab sequence is the eight numbered `*_gce.md` files in `ref-labs/`.
- Treat `ref-labs/_README.md` and `ref-labs/acknowledgements.md` as supporting references.
- Treat `ref-labs/k8s_lab_azure.md` and `ref-labs/k8s_lab_gce_deprecated.md` as legacy background only.
- Preserve the technical intent of active labs and keep wording practical and concise.
- Plaintext credentials, secret values, bearer tokens, private keys, and certificates are allowed in documentation and tracking files when they are intentional training examples or lab-created values used by an exercise.
- User-approved active lab credentials and assignment details may be stored in the selected ignored `students_*.json` inventory and used during lab execution.
- Do not include unrelated production credentials, guessed secrets, or unapproved sensitive data.

## Navigation Status Markers

Use these status markers consistently in `mkdocs.yml` navigation labels:

- `📋` for pages whose validation is confirmed, including approved documented exceptions.
- `⏳` for pages before validation begins or while validation is unconfirmed.
- `📄` for reference pages.

## Writing Rules

- Keep explanations concise.
- Do not over-explain unless explicitly asked.
- Prefer direct, task-focused wording.
- Normalize inconsistent formatting from the source.
- Keep command examples close to the original intent, but rewrite for clarity when needed.
- All second-level headings must use the prefix `:material-book-open-page-variant-outline:`, for example `## :material-book-open-page-variant-outline: Second level header`.
- All third-level headings must use the prefix `:material-application-edit-outline:`, for example `### :material-application-edit-outline: Third level header`.

## Admonitions

Use Material admonitions when they improve clarity:

- Use `!!! abstract` for page goals and short page-purpose callouts.
- Use `!!! note` for context.
- Use `!!! tip` for helpful shortcuts or best practices.
- Use `!!! warning` for risky actions.
- Use `!!! danger` for actions that can break the lab or destroy data.
- Use expandable admonitions such as `??? example "Expected result"` for bulky expected-result snapshots so the default reading path stays compact.

## Protected Paths

- `docs/` and `Dockerfile` are user-managed. Do not modify them unless explicitly asked.
- Do not inspect or change `helm/` unless explicitly asked.

## Command Formatting

- Add a short comment immediately above each command block.
- Use one command block per command.
- Follow every command block with an expected-result admonition:

````md
??? example "Expected result"
    ```text
    Expected output or verification notes.
    ```
````

- Format every expected-result body as an indented fenced code block.
- Use `text` as the default language, including for `No output.` and narrative verification.
- Use another language identifier only when it accurately represents structured output.
- Reserve `shell` for intentional transcripts that contain prompts, commands, and output.
- Do not repeat executable commands in expected-result admonitions; commands belong in the preceding command block.
- Keep commands and expected results paired.
- Use representative, concrete success output. Use `No output.` when applicable.

## Live Training

- Use an interactive workflow only when explicitly requested for live training.
- Always connect to student machines over SSH as the `ubuntu` user; do not derive the SSH username from student identity or inventory fields.
- Present one instruction and one command at a time.
- Before each command, state the exact student-facing command and its purpose in one sentence.
- Wait for explicit approval before executing each command; treat `go` as approval.
- After execution, verify the result and explain its meaning before continuing.
- Do not record commands executed by the user or student in `commands.md`.
- Record successful training commands executed by an agent, including during live interactive training.

## Tracking Files

- `migration.md` tracks CAPI lab preparation and validation status.
- Use `students_*.json` as the authoritative current lab-assignment source before lab execution. Keep these inventory files ignored and untracked.
- Exactly one `students_*.json` file must exist. If none exists, ask the user to provide one and do not infer lab context from another source.
- If more than one `students_*.json` file exists, ask the user which one is authoritative and wait for the human to resolve the extras so exactly one remains. Do not choose, use, or delete an inventory automatically.
- The selected inventory may contain plaintext active lab credentials, infrastructure details, and required student assignment fields supplied or approved by the user.
- Record only successfully executed training commands run by an agent in `commands.md`, including during live interactive training, using the exact executed command string.
- Preserve plaintext secret literals that are part of a training command. Do not copy external connection-wrapper or inventory credentials into `commands.md` unless the credential literal is itself part of the student-facing exercise.
- Do not record failed, exploratory, or corrected commands.
- Mark a lab complete only after its commands have been validated and results documented.

## Delegation

- For discovery, use a read-only exploration agent when available.
- For bounded analysis or implementation, use an appropriate general agent when available and safe.
- Limit subagents to this repository root and prohibit remote or network access unless the user explicitly authorizes a named target and scope.
- Do not ask subagents to guess targets, credentials, commands, or infrastructure details.
- Keep delegation bounded to one level and request concise factual results.
