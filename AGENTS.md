# COMP0008 Arena

A study-aid project for the UCL module **COMP0008 — Computer Architecture and Concurrency**. The end goal is for an agent (you) to be able to answer questions and produce artefacts about the module by drawing on its full set of materials.

## About the module

COMP0008 provides a working knowledge of the hardware and architecture of a modern computer system, with particular focus on concurrency aspects and those that have an impact on writing multithreaded software.

The module is delivered over **10 weeks**, split 5/5 between **architecture** and **concurrency**:

- **Computer architecture** — micro-architecture of a pipelined processor, the memory hierarchy, cache structure / coherence / consistency, hardware multithreading, and **MIPS assembly** (used to ground the low-level discussion of concurrency, e.g. spin locks).
- **Concurrency** — the concurrency abstraction and how it shapes both architecture and software design; safety properties (interference, visibility) and liveness; the **Java Memory Model**; building correct multithreaded systems in Java, from low-level primitives up to the high-level patterns in the `java.util.concurrent` package.

Learning outcomes (paraphrased): understand modern computer architecture (pipelining, memory hierarchy, caches) as it pertains to concurrent programming; read and write MIPS assembly; reason about high-level concurrency safety and liveness; build safe, reliable multithreaded systems in Java with knowledge transferable to other languages.

## Layout

- `slides_original/` — source lecture slide decks as PDFs (21 files across 10 weeks). **Do not read these directly** — use the transcripts instead (see below).
- `slides_transcribed/` — **primary knowledge base.** Token-efficient, lossless markdown transcripts of the slide decks, one file per week (`week_01.md` through `week_10.md`). The concatenation of all 10 weeks is ~45–50k tokens, fitting comfortably in a single context window.
- `book_excerpts/` — textbook chapter PDFs for weeks 6–10 essential/further readings, plus extracted topic lists. See `book_excerpts/README.md` for the per-week reading assignments and a condensed topic overview.
- `.opencode/` — project-local agent and command definitions.

### Preprocessed materials — how to use them

The original lecture slides (PDFs) have been **pre-processed into markdown transcripts** because PDFs are token-inefficient and perform poorly under both direct ingestion and retrieval. The transcripts in `slides_transcribed/` are faithful, lossless representations of the slide content — all technical detail, definitions, code, equations, and diagrams (described in prose) are preserved.

**When answering questions or producing artefacts about the module content, read the markdown transcripts in `slides_transcribed/`, not the original PDFs.** The transcripts are the authoritative working copy of the lecture material for agent use.

For the concurrency half (weeks 6–10), the lectures are supplemented by essential readings from two textbooks. The slides are **not self-contained** for these weeks. Topic overviews of the readings are in `book_excerpts/README.md`; detailed per-chapter topic extractions are in `book_excerpts/*_topics.md`.

### Source file naming (for reference only)

The original PDFs in `slides_original/` follow this naming scheme:

- `COMP0008_XX_YY.pdf` — week `XX`, part `YY`.
- `COMP0008_XX_pre_YY.pdf` — "pre-lecture" slides for week `XX`, part `YY` (functionally identical to main slides, just delivered separately).
- `COMP0008_XX.pdf` — used when a week has only one main deck.

Ordering within a week: `_pre_*` decks first (in part-number order), then main `_YY` decks (in part-number order).

## Transcription workflow

The transcripts were produced by a generic **transcriber** subagent (`.opencode/agents/transcriber.md`). It takes an ordered list of source documents, an output path, and optional context, and produces a single dense markdown transcript. See the agent file for the full contract. There is also a `/transcribe` slash command for human use.

This is a one-time preprocessing step — the transcripts are already populated. The workflow is documented here for reproducibility (e.g. if slides are updated or new weeks are added).

There is also a **transcription skill** (`.opencode/skills/transcription/SKILL.md`) that provides a decision framework for when and how to pre-process token-heavy documents. Load it when considering whether new material should be transcribed before use.
