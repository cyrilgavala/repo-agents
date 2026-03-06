# 🤖 repo-agents

> **⚠️ IDE only** — these agents run in the GitHub Copilot agent runner inside an IDE
> (IntelliJ, VS Code). They are **not compatible** with the `gh copilot` CLI. The tool system
> and orchestration model are fundamentally different.

A collection of self-contained GitHub Copilot agent workflows. Each workflow has an orchestrator
that coordinates a set of specialized subagents and supporting scripts. Adding a new workflow
**never touches** existing ones.

---

## 📋 Workflows

### 🗂️ SOAP Report Generation

Automates the full delivery report cycle — from collecting a git diff to updating the Word document.

```
report-generator
    ├── diff-collector   →  collected_diff.patch
    ├── diff-analyzer    →  tmp/analysis.md
    ├── diff-summarizer  →  tmp/summary.md
    └── report-updater   →  updated .docx
```

**Trigger:** `@report-generator` — it will ask for the two delivery tags, or resolve them
automatically from the latest git tag and the last existing report on disk.

---

### 🔍 ADO Code Reviewer

Conducts a thorough pull request review against an Azure DevOps repository.

**Trigger:** `@ado-code-reviewer` with phrases like:
- *"review this PR"*
- *"check PR #1234"*
- *"are there any issues with these changes?"*

---

## 🧩 Agents

| Agent | Role | Inputs | Output |
|---|---|---|---|
| [`report-generator`](.github/agents/report-generator.agent.md) | Orchestrator — coordinates the full report pipeline | old & new delivery tags | updated `.docx` |
| [`diff-collector`](.github/agents/diff-collector.agent.md) | Runs `collect-diff.sh` between two git tags | `old_tag`, `new_tag` | `tmp/collected_diff.patch` |
| [`diff-analyzer`](.github/agents/diff-analyzer.agent.md) | Analyses the patch as a senior engineer | `collected_diff.patch` | `tmp/analysis.md` |
| [`diff-summarizer`](.github/agents/diff-summarizer.agent.md) | Rewrites analysis into an executive summary | `analysis.md` | `tmp/summary.md` |
| [`report-updater`](.github/agents/report-updater.agent.md) | Copies, patches, and saves the Word report | `old_tag`, `new_tag`, `summary.md` | updated `.docx` in OneDrive |
| [`ado-code-reviewer`](.github/agents/ado-code-reviewer.agent.md) | Reviews a pull request in Azure DevOps | PR number or link | inline review comments |

---

## 📁 Structure

```
.github/
  agents/           # Agent definitions (.agent.md)
  copilot-instructions.md
scripts/
  soap-report-generation/
    collect-diff.sh        # Collects git diff between two tags
    update_report.py       # Patches the Word .docx with new summary
```

---

## ⚙️ Requirements

- GitHub Copilot with agent mode enabled in your IDE
- Azure DevOps MCP server (for `ado-code-reviewer`)
- `pandoc` installed locally (used by `report-updater`)
- Access to the `Macys_Java` git repo (for SOAP report generation)
