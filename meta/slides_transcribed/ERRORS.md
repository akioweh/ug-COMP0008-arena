# Known Source Errors and Content Issues

Errors, inconsistencies, and inaccuracies found **in the source slide material itself** (not transcription errors). Discovered during a systematic audit of all 10 weeks' transcriptions against their original PDFs.

Each entry records the severity, the source location, what's wrong, and whether it's flagged inline in the transcription with a `<!-- suspected-source-error -->` comment.

Severity scale:
- **HIGH** — factually wrong; would mislead a student relying on it.
- **MEDIUM** — imprecise, inconsistent, or partially wrong; could cause confusion.
- **LOW** — minor, debatable, or unlikely to cause real harm.

---

## Week 01

### MIPS instruction encoding mismatch — HIGH

**Source:** pre\_2 slide 22 (abstraction layers table)
**Transcription:** week\_01.md, "Abstraction Layers of a Modern Computer"
**Flagged inline:** yes

The slide pairs the mnemonic `add $s3,$s3,1` with the binary encoding `001000 01011 01011 0000000000000001`. Two errors:
1. Opcode `001000` = `addi` (I-type), not `add` (R-type, opcode `000000`).
2. Register field `01011` = register 11 (`$t3`), not `$s3` = register 19 (`10011`).

A student verifying this against the MIPS ISA would get contradictory results.

### Analytical Engine as "von Neumann architecture" — LOW

**Source:** pre\_2 slide 13
**Transcription:** week\_01.md, "Early Computing Machines"
**Flagged inline:** yes (audit comment)

Calling Babbage's Analytical Engine the first "von Neumann architecture" is anachronistic — the term originates from von Neumann's 1945 report. The structural similarities exist, but the label is historically debatable.

### `ExceptionError` in Holder puzzle code — LOW

**Source:** COMP0008\_01.pdf (Java visibility example)
**Transcription:** week\_01.md, "Java Visibility Puzzles"
**Flagged inline:** yes (audit comment)

`ExceptionError` is not a standard Java class. The code would not compile as written. The concept it demonstrates (visibility of partially-constructed objects) is correct regardless.

### "Therac-20" name not in source — LOW

**Source:** COMP0008\_01.pdf (Therac-25 case study)
**Transcription:** week\_01.md, "Case Study: Therac-25"
**Flagged inline:** no

The transcription adds the name "Therac-20" for the predecessor system. The slides only say "previous systems" without naming them. Factually correct addition, but not in the source.

---

## Week 02

### MIPS `add`/`addi` encoding mismatch (same as Week 01) — HIGH

**Source:** pre\_2 slide 11 (ISA abstraction table, reappears from Week 01)
**Transcription:** week\_02.md, "The ISA as an Abstraction Layer"
**Flagged inline:** yes

Same issue as Week 01. The table reappears in Week 02's slides with the same incorrect mnemonic-encoding pairing.

### R-type general form has reversed argument order — MEDIUM

**Source:** COMP0008\_02\_2.pdf (R-type instruction format)
**Transcription:** week\_02.md, "R-Type Instruction Format"
**Flagged inline:** yes

The slide writes `R[rd] = func(R[rt], R[rs])` with `rt` before `rs`. The standard MIPS convention is `func(R[rs], R[rt])`. For commutative operations like `add` this doesn't matter, but for `sub` (`R[rd] = R[rs] - R[rt]`) the order is significant. The transcription silently corrected to standard order and now flags the discrepancy.

### Abstraction-level ordering — LOW

**Source:** pre\_2 slide 11
**Transcription:** week\_02.md, "The ISA as an Abstraction Layer"
**Flagged inline:** no

The OS layer is placed between Assembly and ISA, which differs from standard textbook orderings (e.g., Tanenbaum). This is a pedagogical choice in the source, not strictly an error.

---

## Week 03

### `sbu`/`shu` listed as MIPS instructions — MEDIUM

**Source:** COMP0008\_03\_1.pdf slide 6 (byte/half-word load/store)
**Transcription:** week\_03.md, "Byte and half-word granularities"
**Flagged inline:** yes

MIPS has no `sbu` or `shu` instructions. Sign/zero extension is only meaningful when *loading* a smaller value into a 32-bit register. Stores (`sb`, `sh`) simply truncate — there is no signed/unsigned distinction. A student could write invalid assembly relying on these.

### Branch target diagram inconsistency — LOW

**Source:** COMP0008\_03\_1.pdf (bne example)
**Transcription:** week\_03.md, "Branching Instructions"
**Flagged inline:** yes

The branch target arithmetic gives `0x00400014`, but the slide's visual arrows may suggest a different target. The transcription's arithmetic is correct.

### `addiu 0xFFFF` exercise ambiguity — LOW

**Source:** COMP0008\_03\_1.pdf (addiu exercise)
**Transcription:** week\_03.md, "Adding unsigned immediate"
**Flagged inline:** yes (audit ambiguities)

The "correct answer is 4" depends on whether you reason about hardware semantics (16-bit immediate `-1`, so `5 + (-1) = 4`) or assembler behavior (MARS treats `0xFFFF` as `65535`, producing `65540`). Both interpretations are captured in the transcription.

---

## Week 04

### `addi` vs `addiu` inconsistency for stack pointer — LOW

**Source:** COMP0008\_04.pdf (stack frame examples)
**Transcription:** week\_04.md, "Stack Frames (Prologue and Epilogue)"
**Flagged inline:** no

The corrected `my_program` example uses `addi` for stack pointer manipulation, while the generic function template correctly uses `addiu`. Using `addi` for address arithmetic can trigger overflow exceptions. This inconsistency is in the source.

---

## Week 05

No content errors found. The register numbering confusion in the gcc output annotations (`$a0 (register 5)` should be `$a0 (register 4)`) is flagged as a suspected source error in the transcription.

---

## Week 06

### Processor numbering text/diagram contradiction — LOW

**Source:** COMP0008\_06\_2.pdf slide 41 (cache coherence)
**Transcription:** week\_06.md, "Multi-Processor Caches and the Coherence Problem"
**Flagged inline:** partially (audit ambiguities, but not as a suspected source error)

The slide's narration text says "processor 2 caches X = 1" but the diagram visually places `X:1` in the rightmost (4th) processor's private cache. The transcription uses "Processor 4" based on visual evidence. The specific processor number doesn't affect the coherence lesson, but the text/diagram contradiction is a genuine source error.

---

## Week 07

No content errors found. "Server crush" (typo for "server crash") on slide 9 is flagged as a suspected source error in the transcription.

---

## Week 08

No content errors found. Two silently corrected trivial typos (`synchronize` → `synchronized`, `spawn` → `spawned`) are not individually flagged, which is defensible given their triviality.

---

## Week 09

### Option 2d: "safe publication via lock" is not actually safe — HIGH

**Source:** COMP0008\_09.pdf slide 31
**Transcription:** week\_09.md, "Option 2d: Safely Publish via Lock"
**Flagged inline:** yes

The slide presents this code as demonstrating safe publication idiom #4 ("store a reference into a field that is properly guarded by a lock"):

```java
public class ConfigSettings {
    private Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);   // NOT synchronized
    }

    public synchronized Holder GetHolder() {
        return holder;
    }
}
```

The field `holder` is **not** properly guarded — only the read (`GetHolder()`) is synchronized, not the write in the constructor. The JMM's monitor-lock rule requires a matched unlock→lock on the same monitor to establish a happens-before edge. Since the constructor never acquires the intrinsic lock, there is no happens-before from the constructor's write to a reader's `synchronized` read.

The code's actual safety depends entirely on how the `ConfigSettings` object itself is published to other threads (e.g., via `Thread.start()` or a volatile field), making the `synchronized` on `GetHolder()` redundant for publication. A correct lock-based safe publication would require the write to also be guarded by the same lock.

This is particularly damaging because it appears in the section explicitly teaching safe publication idioms — a student following this pattern would have an incorrectly guarded field.

---

## Week 10

### "Multiple Databases" categorization — LOW

**Source:** COMP0008\_10.pdf (deadlock examples summary table)
**Transcription:** week\_10.md, "Deadlock Examples Summary"
**Flagged inline:** no

"Multiple Databases" is categorized under "Single object, conflicting methods," but acquiring connections from two different database pools is conceptually a multi-resource problem. The categorization is faithfully reproduced from the source.

### Missing `throws Exception` declaration — LOW

**Source:** COMP0008\_10.pdf (`transferMoney` code)
**Transcription:** week\_10.md, `transferMoney` / `doTransfer` code
**Flagged inline:** no

`throw new Exception("Insufficient funds")` without a `throws Exception` on the method signature would not compile in Java (`Exception` is checked). Standard lecture-slide simplification; not misleading about the concurrency concepts.
