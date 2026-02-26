# repo-agents

A collection of GitHub Copilot agents that automate repetitive engineering tasks.
Each workflow is self-contained: an orchestrator agent coordinates a set of specialised subagents
and supporting scripts. The repo is designed to grow — adding a new workflow does not touch
anything existing.

---

## Agent Catalogue

| Agent | Type | Purpose | Location |
|---|---|---|---|
| `report-generator` | Orchestrator | Drives the full soap delivery-report pipeline | `.github/agents/soap-report-generation/report-generator.agent.md` |
| `diff-collector` | Subagent | Fetches git diff between two delivery tags | `.github/agents/soap-report-generation/subagents/diff-collector.agent.md` |
| `diff-analyzer` | Subagent | Analyses the diff and writes `analysis.md` | `.github/agents/soap-report-generation/subagents/diff-analyzer.agent.md` |
| `diff-summarizer` | Subagent | Turns `analysis.md` into an executive `summary.md` | `.github/agents/soap-report-generation/subagents/diff-summarizer.agent.md` |
| `report-updater` | Subagent | Injects the summary into the Word delivery report | `.github/agents/soap-report-generation/subagents/report-updater.agent.md` |

> Add new agents here as they are created.

---

## How agents are structured

Agents live under `.github/agents/<workflow-name>/`.

```
.github/agents/
└── <workflow-name>/
    ├── <orchestrator>.agent.md   # entry point, delegates only
    └── subagents/
        ├── <subagent-a>.agent.md
        └── <subagent-b>.agent.md
```

Each `.agent.md` file has a YAML front-matter block followed by a Markdown prompt:

```yaml
---
name: <agent-id>          # unique identifier, used in run_subagent calls
description: <one-liner>  # shown in agent picker
tools: [ tool1, tool2 ]   # tools the agent is allowed to use
---
```

Supporting scripts (bash, Python, etc.) go under `scripts/<workflow-name>/`.
Not every agent needs a script — some agents express all their behaviour in the prompt alone.

---

## Adding a new agent

1. Create `.github/agents/<workflow-name>/` (new folder per workflow).
2. Add an orchestrator file: `<workflow-name>.agent.md` with correct front-matter (`name`, `description`, `tools`).
3. If the workflow has multiple steps, add subagents under `subagents/`.
4. If any agent needs to run a script, add it under `scripts/<workflow-name>/`.
5. Add the new agent(s) to the **Agent Catalogue** table above.

---

## Workflows

### soap-report-generation

Produces an updated Word delivery report for the SOAP API, covering the delta between two
deployment tags.

**Trigger:** Invoke the `report-generator` orchestrator with two delivery tags:

```
2026/02/delivery-2026-02-15  2026/02/delivery-2026-02-24
```

Tags must follow the format `yyyy/mm/delivery-yyyy-mm-dd`.

**Pipeline:**

| Step | Agent | Input | Output |
|---|---|---|---|
| 1 | `diff-collector` | two git tags | `tmp/collected_diff.patch` |
| 2 | `diff-analyzer` | `collected_diff.patch` | `tmp/analysis.md` |
| 3 | `diff-summarizer` | `analysis.md` | `tmp/summary.md` |
| 4 | `report-updater` | `summary.md` + old `.docx` | new `.docx` on OneDrive |

The `tmp/` directory is created automatically and deleted at the end of step 4.
It is git-ignored — do not commit it.

---

## Scripts

### `scripts/soap-report-generation/collect-diff.sh`

Fetches the git diff between two tags from the `Macys_Java` repo and writes it to
`tmp/collected_diff.patch`.

```
Usage: collect-diff.sh <old_tag> <new_tag>
```

- Tags must exist in the remote `Macys_Java` repo.
- Always does `git fetch --tags --force` before diffing to ensure tags are current.
- Diffs only `apps/wave2/soap` — adjust the path argument if scope changes.

### `scripts/soap-report-generation/update_report.py`

Copies the previous Word delivery report, replaces the **Summary** section with content from
`tmp/summary.docx`, updates the delivery-tag reference on the cover page, and saves the result
with the new date in the filename.

```
Usage: update_report.py <old_date> <new_date>
       Dates in YYYY-MM-DD or YYYY_MM_DD format.
```

- Reads source `.docx` from `tmp/`.
- Inserts `tmp/summary.docx` (generated from `summary.md` via `pandoc`) into the Summary section.
- Writes output `.docx` to `tmp/` (the `report-updater` agent then copies it to OneDrive).

---

## Prerequisites

| Requirement | Details |
|---|---|
| Git access to `Macys_Java` | Must be able to `git fetch` from the remote; SSH or HTTPS auth configured |
| OneDrive mounted | `~/OneDrive - Accenture/Documents/PROJECTS/AVANADE/delivery reports/` must be accessible |
| Python venv | `.venv/` at repo root; activate before running scripts manually |
| `python-docx` | `pip install python-docx` |
| `pandoc` | Must be on `$PATH`; used to convert `summary.md` → `summary.docx` |

