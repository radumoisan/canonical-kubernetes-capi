# AGENTS.md

## Purpose

This repository is for the Ubuntu Server Advanced documentation site. 

`ubuntu_advanced_lab.md` is the source reference. Keep it unchanged.

## Source Of Truth

- Treat `ubuntu_advanced_lab.md` as read-only.
- Preserve the technical meaning of the source material.
- Improve wording, structure, and consistency where useful.
- Keep the tone professional and minimal.

## Site Structure

- Split the content into one file per top-level chapter only, placing each chapter file in the `docs/` directory alongside the existing chapter files.
- Include all 11 top-level chapters from the reference file.
- Do not create separate files for subsections unless explicitly requested.
- Keep `migration.md` at the repository root as the internal migration tracker.
- Keep `playground.md` at the repository root as the internal lab machine inventory.
- Keep `commands.md` at the repository root as the internal record of successfully executed training commands.

## Writing Rules

- Keep explanations concise.
- Do not over-explain unless explicitly asked.
- Prefer direct, task-focused wording.
- Normalize inconsistent formatting from the source.
- Keep command examples close to the original intent, but rewrite for clarity when needed.

## Command Formatting

- Add a short comment immediately above each command block.
- Use one command block per command.
- Do not group multiple commands under one shared comment or one shared expected-result block.
- Each command must be followed by an admonition in this form:

```md
??? example "Expected result"
    Expected output or verification notes.
```

- Commands and expected results must remain in pairs.
- Use expected results to show the actual command output or a close representative example of what the output looks like.
- Prefer concrete output over description or interpretation.
- If a command produces no output, use a placeholder such as `No output.`
- If exact output may vary, keep the example realistic and focus on the visible success signals in the command output.

## Lab Flow

- Use an interactive workflow only when the user explicitly asks for one during live training.
- Present one instruction at a time when running the lab with the user.
- Before every lab command in interactive mode, state the exact command you recommend next and explain its intent in one short sentence.
- Show the student-facing command exactly as the student should see and run it, even if the actual executed command uses SSH wrappers or other environment-specific prefixes. The student-facing form is display-only; `commands.md`, where logging applies, records the actual executed command string.
- Do not skip the intent explanation, even for obvious or repetitive commands.
- In an interactive session, run one command at a time only.
- In an interactive session, wait for explicit user approval before running each command.
- In an interactive session, after any non-interactive command is run, double-check the result before moving on.
- In an interactive session, do not update `commands.md`; the live session already covers the command flow and duplicating it adds no value.
- In an interactive session, after each command, report the result and explain what it means before moving on.
- In an interactive session, if the user says `go`, treat that as approval to proceed with the recommended next step.

## Editing Rules

- Prefer the smallest correct change.
- Keep existing deployment artifacts such as `helm/` and `Dockerfile` unless explicitly asked to change them.
- Do not remove source material that belongs to the training.
- Do not run `mkdocs build` or otherwise attempt to build the MkDocs site unless the user explicitly asks for it.

## Tracking Files

- Update `migration.md` when a chapter or subchapter is migrated.
- Track subchapters in `migration.md`, not just top-level chapters.
- Mark a chapter as `Complete` only after all commands in that chapter have been run and their results have been documented. In a live interactive session where `commands.md` is not updated, the documented expected-result admonitions in the chapter file satisfy the results-documentation requirement.
- Update `playground.md` whenever a lab machine is added, changed, or reassigned.
- Use `playground.md` for internal execution context only; it is not part of the training content.
- Update `commands.md` only outside live interactive training sessions.
- Record only commands from the training material that actually succeeded.
- Record the exact command string that was actually executed successfully, including any required SSH wrappers or environment-specific prefixes.
- Do not replace the executed command with a simplified or student-facing form in `commands.md`.
- Do not record failed commands, exploratory commands, or commands that were corrected before a successful run.

## Agent Routing

### Required Routing Rules

- For discovery tasks, the main agent must delegate the first pass to `explore` when available.
- For analysis tasks, the main agent must gather evidence with `explore` first when available and then delegate bounded reasoning to `general` when available.
- For active-change tasks, the main agent must delegate edit and implementation work to `general` when available, the context is clear, and the instructions are not risky.
- Direct main-agent edits are allowed only for trivial, urgent, or cases where delegation would increase risk.
- Direct main-agent inspection is allowed only for narrow follow-up reads tied to a known file/path, an edit already in progress, or a verification step.

### Agent Roles and Selection

- **Read-Only Discovery (`explore`):** Use the `explore` agent to gather evidence: searching the repository, reading files, inspecting documentation, understanding existing patterns, summarizing findings, and running read-only commands. `explore` must never perform changes or side-effecting operations. Read-only diagnostics against lab machines or other remote environments are allowed only when the user has explicitly approved that remote target under the delegation rules below; the role itself does not grant remote access.
- **Analysis And Active Work (`general`):** Use the `general` agent for bounded analysis and reasoning over evidence gathered by `explore`, and for bounded active work: edit and implementation when the context is clear and instructions are not risky, actions that interact with systems in a non-read-only way, commands with side effects, or external operations with side effects.
- **Fallback:** If `explore` is unavailable, the main agent may perform read-only discovery directly. If `general` is unavailable, the main agent may perform bounded reasoning directly and handle local active work only under the direct-edit exceptions above. The main agent must not perform side-effecting or risky external changes as a fallback; external active work waits for an appropriate delegation boundary.
- **Keep Context Small:** Use the smallest relevant files, snippets, or command outputs needed to answer the question. Avoid loading large files or broad documentation into the main context unless necessary.

### Delegation Rules

- Every subagent prompt must explicitly restrict filesystem access to the current repository root (the root of this repository). Subagents must not inspect, read, write, or otherwise access paths outside it.
- Subagent prompts must prohibit remote-system and network access by default. This default applies equally to read-only remote diagnostics. Permit such access only when the user explicitly requests it, and name the exact target and allowed scope.
- Do not ask subagents to guess missing targets, credentials, command syntax, deployment details, or environment assumptions.
- When delegating, provide the exact target, task objective, known constraints, commands or files involved, safety limits, and expected behavior.
- Ask subagents to return concise factual results: what was inspected or changed, commands run, files touched, important output, errors, and current state.
- Split work into the smallest practical independent pieces. Each delegation must cover one precise, bounded task; avoid large, broad, or open-ended delegations.
- Delegation is exactly one level: only the main agent (the calling agent) may delegate. Subagents must not create, request, or coordinate further delegation, and must return their results to the main agent.
- When tasks are independent and do not rely on each other, prefer parallel delegation. Keep dependent work sequential.

### Main-Agent Restrictions

- The main agent must not perform broad repository discovery directly when `explore` fits the task.
- The main agent must not perform direct edit or implementation work when it can be safely delegated to `general` with clear context and non-risky instructions.
- The main agent must not perform active external-system work directly when `general` is the appropriate isolation boundary.
- The main agent remains responsible for orchestration, deciding whether evidence is sufficient, choosing follow-up actions, and producing the final user-facing answer.
