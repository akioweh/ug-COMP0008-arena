---
name: transcription
description: Decision framework for when and how to pre-process token-inefficient files (e.g., slide decks, rasterized text) into purely-textual transcripts for efficient reuse. Load this skill when you have to read a file but it is large, non-textual, and likely to be referenced multiple times.
---

# Transcription skill

This skill helps you decide **whether** to transcribe a document into a token-efficient markdown form, and **how** to orchestrate the transcription if you decide to proceed.

## When to transcribe

Transcription is _necessary_ if the collection of sources will not fit in your context window in their original form.

Transcription is worthwhile when **all three** conditions hold:

1. **The source is non-textual or token-inefficient.** PDFs, slide decks, scanned documents, and image-heavy formats consume far more tokens than their information content warrants. A 50-page PDF slide deck might cost ~500 tokens/page as a multimodal attachment but compress to ~100 tokens/page as markdown — a 5–10x saving.

2. **The content will be referenced multiple times**, especially across sessions. If you're reading a document once to answer a one-off question, just read it directly — the overhead of transcription isn't justified. But if the material will be consulted repeatedly (e.g. course notes, reference documentation, a spec), the upfront cost pays for itself quickly. Cross-session reuse is the strongest signal, since token caching doesn't persist across sessions.

3. **The source is large enough to matter.** A 3-page PDF is not worth transcribing — just read it. A 200-slide lecture series absolutely is.

### When NOT to transcribe

- One-off reads of small/medium documents.
- Content that is already text-efficient (markdown, plain text, well-structured HTML).
- Content where visual fidelity is essential and cannot be adequately represented in text (e.g. fine art, detailed medical imaging) — transcription would be lossy in ways that matter.
- When the user needs an answer _now_ and the transcription overhead would delay them unacceptably.

## How to transcribe

A **transcriber** subagent is available. Read its definition file for full calling contract. Briefly:

- Invoke via the `task` tool with `subagent_type: "transcriber"`.
- Each call's prompt must provide: an **ordered list of source document paths**, an **output path**, and **optional free-form context**.
- The subagent reads sources multimodally, reasons through the content in multiple passes, and writes a single dense markdown file that is lossless on information but lossy on presentation.
- For multiple independent transcription jobs (e.g. one per week of a lecture series), dispatch multiple `task` calls in a single message — they run concurrently.

### Orchestration checklist

Before dispatching:

1. **Determine grouping.** What should become one transcript? Often a 1:1 mapping to source files is fine; a grouping into logical units may be appropriate if e.g. a presentation deck is split across two files. Don't merge unrelated material into one transcript.
2. **Determine ordering within each group.** The subagent reads inputs in exactly the order you give. Make sure the order is pedagogically / logically correct.
3. **Choose an output location.** _Ask_ the user if no obviously appropriate location exists. Use a consistent naming convention. The location must be accessible for future retrieval.
4. **Prepare context.** Tell the subagent what the documents are, what domain they're in, any terminology conventions, and why the files are in that order. Also forward style preferences, if you were given them.

## After transcription

Once transcripts exist, **always prefer reading the transcript over the original source** for information retrieval, Q&A, and artefact generation. The originals remain available for cases where visual fidelity matters (verifying a diagram, checking exact formatting), but the transcripts are the working copy.

1. **Persist this instruction** Document the fact that files were transcribed so future agents know the transcripts exist and should be preferred over the raw sources. _Ask_ the user if no obviously appropriate place exists.
