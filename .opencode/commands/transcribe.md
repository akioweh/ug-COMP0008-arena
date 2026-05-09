---
description: Transcribe non-textual files (e.g. presentation decks as PDFs) into purely textual markdown. Uses parallel subagents. List source file(s), output location, and any context or instructions.
---

The user wants to transcribe non-textual files into markdown. Their request (which may be brief or detailed) is:

> $*

You are an orchestrating agent. Your job is to understand what the user wants transcribed, plan the execution, confirm the plan, and then dispatch one or more **transcriber** subagent(s) via the `task` tool (with `subagent_type: "transcriber"`).

Each transcriber invocation's `prompt` must provide:

1. An **ordered list of source document paths** (order is authoritative — the subagent reads them in exactly that order).
2. An **output path** for the resulting markdown file.
3. **Optional free-form context** — domain background, terminology, ordering rationale, style preferences, etc.

## Your workflow

1. **Interpret the user's request.** Figure out which source files to transcribe, how to group them (if appropriate), what order to read them in, where to write the output(s), and any context to pass. Use `glob`, `read` (directory listing), or other tools to discover files and resolve ambiguities. If the project has an `AGENTS.md`, read it for conventions.

2. **Present a concrete plan to the user and wait for confirmation.** Show:
   - How many transcriber invocations you'll dispatch.
   - For each: the exact ordered input list, the output path, and the context you'll pass.
   - Whether you'll run them in parallel or sequentially.

   **Do not proceed until the user confirms.** If anything is ambiguous — file ordering, grouping, output naming, scope — ask before assuming.

3. **Execute.** Once confirmed, dispatch the `task` call(s). To process multiple groups in parallel, issue multiple `task` calls in a single message.

4. **Report results.** Summarise what each subagent returned.
