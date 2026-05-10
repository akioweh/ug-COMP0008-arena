# Meta

Plumbing for **meta tasks** — workflows that maintain or extend the project itself rather than draw on the module content. Distinct from the project's actual purpose of equipping the agent with module knowledge.

## Layout

Each material type has a pair of folders: **originals → extracted/transcribed content** (token-inefficient PDFs → dense markdown).

- `slides_original/` — original lecture slide decks (PDFs).
- `slides_transcribed/` — faithful, lossless markdown transcripts of the slides.
- `books/` — original textbook chapters (PDFs).
- `books_topics/` — extracted per-chapter and per-week topic lists distilled from the readings.

The consolidated bundles in `materials/` are derived from these.

## Transcription workflow

Slide decks are transcribed by a generic **transcriber** subagent (`.opencode/agents/transcriber.md`); a `/transcribe` slash command is available for human use. A **transcription skill** (`.opencode/skills/transcription/SKILL.md`) provides a decision framework for when and how to pre-process token-heavy documents.

The transcripts are already populated; this workflow is documented for reproducibility (e.g. if slides are updated or new weeks are added).

## Source file naming

Original slide PDFs in `slides_original/` follow this scheme:

- `COMP0008_XX_YY.pdf` — week `XX`, part `YY`.
- `COMP0008_XX_pre_YY.pdf` — "pre-lecture" slides for week `XX`, part `YY`.
- `COMP0008_XX.pdf` — used when a week has only one main deck.

Ordering within a week: `_pre_*` decks first (in part-number order), then main `_YY` decks (in part-number order).
