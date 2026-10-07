# MithenOS - Style

Style observed in the core files of this repo (`src/**`). Keep new code consistent with these.

## AME Wizard playbook YAML (`src/Configuration/Tasks/**/*.yml`)

- Every task file starts with the document marker and a header block:
  ```
  ---
  title: Short title
  description: What the task does
  privilege: TrustedInstaller
  actions:
  ```
- One action per line for simple actions, using an inline flow map:
  `- !registryValue: {path: 'HKCU\...', value: 'Name', type: REG_DWORD, data: '1'}`
- Long or multi-value actions use block form with 4-space indentation:
  ```
  - !powerShell:
    wait: true
    exeDir: true
    errorAction: Ignore
    weight: 10
    command: >-
      line one;
      line two
  ```
- Registry paths are single-quoted with literal backslashes; `HKU\.DEFAULT\...` is used alongside `HKCU\...` so settings apply to new users.
- Group related values with a comment header per group: `# === Multiplane Overlay - Enabled` or `# ======> Delivery Optimization`.
- Comments explain *why* and cite the source when the value is ported (`# ------> https://...`), and issue/PR references are written as `# <number>` notes.
- Declarative tasks keep the `title`/`description`/`privilege`/`actions` shape; a task that only configures one thing stays in its own file and is chained from `registry.yml`, `main.yml` or another task.
- Deletion is expressed with `operation: delete` on `!registryValue`/`!registryKey`.

## PowerShell (`src/Executables/*.ps1`)

- Functions use `PascalCase` (`Update-Feature`, `Install-MithenApp`); local variables use `camelCase`.
- 4-space indentation; one statement per line; semicolons only when folding into a single-line `>-` YAML command.
- Prefer `-ErrorAction SilentlyContinue` / `-ErrorAction Ignore` for best-effort cleanup.
- Never fail the deployment for a cosmetic step: wrap risky operations and log with `Write-Host`.
- Windows PowerShell 5.1 compatible only (no ternary operator, no `&&`/`||`, no `??`).

## cmd/batch (`src/Executables/*.cmd`)

- Existing scripts (`FINALIZE.cmd`) are plain ASCII, use `>NUL 2>nul` to silence output, and are tab-indented inside `if`/`else` blocks.
- Double-quote all paths; never assume a working directory (tasks pass `exeDir: true`).

## General rules for this repo

- **Do not add spaces after commas inside action argument lists** in YAML block maps (follow the existing compact `{path: '...', value: '...', type: ..., data: '...'}` shape).
- Avoid em dashes in comments; use `-`.
- Do not add comments that distinguish "original" from "changed" code.
- Keep filenames kebab-case for task files (`long-paths.yml`, `store-recommended-search.yml`).
