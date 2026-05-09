# COMP0008 Arena

A study-aid project for the UCL module **COMP0008 — Computer Architecture and Concurrency**. The end goal is for an agent (you) to be able to answer questions and produce artefacts about the module by drawing on its full set of materials.

## About the module

COMP0008 provides a working knowledge of the hardware and architecture of a modern computer system, with particular focus on concurrency aspects and those that have an impact on writing multithreaded software.

The module is delivered over **10 weeks**, split 5/5 between **architecture** and **concurrency**:

- **Computer architecture** — micro-architecture of a pipelined processor, the memory hierarchy, cache structure / coherence / consistency, hardware multithreading, and **MIPS assembly** (used to ground the low-level discussion of concurrency, e.g. spin locks).
- **Concurrency** — the concurrency abstraction and how it shapes both architecture and software design; safety properties (interference, visibility) and liveness; the **Java Memory Model**; building correct multithreaded systems in Java, from low-level primitives up to the high-level patterns in the `java.util.concurrent` package.

Learning outcomes (paraphrased): understand modern computer architecture (pipelining, memory hierarchy, caches) as it pertains to concurrent programming; read and write MIPS assembly; reason about high-level concurrency safety and liveness; build safe, reliable multithreaded systems in Java with knowledge transferable to other languages.

## Layout

- `slides_original/` — source lecture slide decks as PDFs. Naming scheme:
  - `COMP0008_XX_YY.pdf` — week `XX`, part `YY` (a single week's main lecture material may be split across multiple parts).
  - `COMP0008_XX_pre_YY.pdf` — "pre-lecture" slides for week `XX`, part `YY`. **Functionally these are no different from the main lecture slides — they are simply additional material for the same week, separated for delivery reasons.** All `_pre_*` files for a given week belong together with that week's main `_YY` files.
  - `COMP0008_XX.pdf` (no part suffix) — used when a week has only one main deck.
  - `XX` is the (1-indexed, sometimes zero-padded) week number; `YY` is a part number within that grouping.
- `slides_transcribed/` — destination for token-efficient markdown transcripts of the slide decks, one file per week. Empty until populated.
- `.opencode/` — project-local agent and command definitions.

The grouping by week is unambiguous from the filename. **Ordering within a week:** `_pre_*` decks come **first** (in part-number order), followed by the main `_YY` decks (in part-number order). I.e. for week 1 the canonical reading order is `COMP0008_01_pre_1.pdf`, `COMP0008_01_pre_2.pdf`, then `COMP0008_01.pdf`.

## Why transcripts?

PDF slide decks are token-inefficient and perform poorly under both direct ingestion and retrieval. The plan is to pre-process all weeks into dense, lossless markdown transcripts so that the concatenation of all weeks fits comfortably in a single context window for downstream Q&A and artefact generation.

## Transcription workflow

Use the **transcriber** subagent to convert one week's slide set into one markdown file. It is generic — it takes an ordered list of source documents, an output path, and optional free-form context, and produces a single dense markdown transcript. See `.opencode/agents/transcriber.md` for the full contract.

To invoke it, use the `task` tool with `subagent_type: "transcriber"`. Each call's `prompt` must convey three pieces of information:

1. **Output path** for the markdown transcript (e.g. `slides_transcribed/week_NN.md`).
2. **Ordered list of source document paths**, with the order being authoritative — the subagent reads them in exactly that order and treats that as the canonical reading sequence.
3. **Free-form context** explaining anything the subagent needs to make sense of the inputs: module name, what each file is, why they're in that order (e.g. "the `_pre_*` decks are pre-reading and come before the main deck"), terminology conventions, style preferences, etc.

Example prompt for a single `task` call:

```
Output path: slides_transcribed/week_01.md

Source documents (read in this order):
1. slides_original/COMP0008_01_pre_1.pdf
2. slides_original/COMP0008_01_pre_2.pdf
3. slides_original/COMP0008_01.pdf

Context: Module COMP0008 (UCL), week 1. The _pre_* decks are pre-reading
material that comes before the main deck. Use British spelling.
```

To process multiple weeks in parallel, issue multiple `task` calls in a single assistant message — opencode will run them concurrently as independent sessions. The subagent is leaf-level (it does not spawn further subagents).

The subagent knows nothing about COMP0008, weeks, or this project's filename conventions. **It is the orchestrator's responsibility to spell out clearly in each prompt** which files belong together, in what order, and what they are.

(There is also a `/transcribe` slash command — `.opencode/commands/transcribe.md` — for humans to invoke a single transcription run directly from the CLI without going through a primary agent. Agents themselves do not use slash commands; they dispatch via the `task` tool as above.)

## Conventions (to be confirmed through use)

- Transcript filenames: `slides_transcribed/week_NN.md` (zero-padded).

