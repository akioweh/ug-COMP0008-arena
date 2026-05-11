# Lore

Information from outside the lecture decks — lecturer Q&A, office hours, Moodle forum posts, and other communication
channels — that is not in `ALL_SLIDES.md` or `READING_TOPICS.md` but matters for the exam (or for reading the verbatim
materials correctly).

Two kinds of entries live here:

1. **Corrections** to information in the verbatim transcripts that has become outdated or was incorrect.
2. **Clarifications and conventions** that the lecturer has communicated outside the lecture decks but that the exam
   relies on.

Compare with the inline `<!-- transcription-audit: -->` blocks in the transcripts, which document
fidelity-of-transcription decisions only — _not_ the truth value of the underlying content.

## Format

Each entry: a heading, the substance, and (where applicable) what the verbatim materials say or imply about the same
topic.

---

## Module logistics

### Assessment weighting — Week 1, "Course Structure → Assessment"

**Slide states:** Three courseworks (10% each) during Terms 1/2 plus a 70% open-book Term 3 assessment.

**Currently correct:** The Term 3 exam is worth **100%** of the final mark; there is no summatively assessed coursework.
The MIPS reference sheet (`materials/MIPS_cheat_sheet.pdf`) is the only additional material permitted in the exam.

**Source:** moodle.

---

## Concurrency assumptions on the exam

Use the following assumptions when reasoning about concurrency on the exam, to help you retain some sanity.

### Scheduler is NOT Fair

A runnable thread may be starved indefinitely by other runnable threads. Liveness arguments must not rely on round-robin
or any other fair-scheduling discipline.

**Source:** trust me bro.

### No Spurious Wakeups

Wakeups from `wait()` are assumed to occur **only** in response to an explicit `notify()` / `notifyAll()` (or
`interrupt`). You do not need to defend against the JVM/OS spuriously waking a thread without reason.

(The standard Goetz advice — _always wait inside a loop testing the condition predicate_ — is still required for the
**missed-signal** and **hijacked-signal** reasons covered in lectures, just not for spurious wakeups.)

**Source:** Moodle announcement forum post / email.

### Realistic Timing

- Lock acquisition under no contention takes **much less than a second**.
- The scheduler and CPU run at "realistic" speeds (microseconds, not minutes).

You do not need to model arbitrary scheduling delays unless a question explicitly requires it.

**Source:** Moodle announcement forum post / email.

### Deadlock Definition — broader than Coffman

Lectures present the **Coffman conditions** (mutual exclusion, hold-and-wait, no preemption, circular wait) as the
canonical deadlock definition. For the exam, **deadlock is broader**: any situation where _all_ threads are blocked,
even when no cyclic dependency exists.

Canonical non-Coffman example: every thread calls `wait()` on a condition queue, but no thread ever reaches the
corresponding `notify()` / `notifyAll()`. There is no resource cycle, but the system is dead.

**Source:** Moodle announcement forum post / email. (With some personal extrapolation regarding the specific `wait()`
scenario.)
