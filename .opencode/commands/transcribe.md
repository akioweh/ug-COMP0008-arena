---
description: Transcribe an ordered set of source documents into a single markdown file via the transcriber subagent. Args - $1=output_path, $2=ordered space-separated input paths, $3=optional context.
agent: transcriber
subtask: true
---

You are being invoked as the transcriber subagent. Follow your system prompt's contract and two-pass workflow.

**Output path:**
$1

**Source documents (ordered, space-separated; treat this order as authoritative):**
$2

**Optional context from the orchestrator:**
$3

Proceed: read every source in order via the `read` tool (native multimodal ingestion), build your outline, then write the final markdown file at the output path. Reply with the terse summary specified in your system prompt.
