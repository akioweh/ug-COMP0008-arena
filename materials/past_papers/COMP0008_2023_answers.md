> Reference answers for [COMP0008_2023.md](COMP0008_2023.md).
> Per-question source files: `materials/past_papers/answers/2023/Q*.md`.
> Generated 2026-05-12 by parallel subagents grounded in `materials/`.

# COMP0008 2023 — Reference Answers

# 2023 Q1 — Reachability of `j` and `beq`

## Background (slides: Week 4, "J-Type Instructions" and "Control Flow")

- `j` (J-type) — 26-bit immediate field. Target address:
  $$\text{PC}_{\text{new}} = (\text{PC}+4)[31{:}28] \;\|\; (\text{imm}_{26} \ll 2)$$
  The bottom 2 bits are zero (so the target is word-aligned), the middle 26 bits come from the instruction, and the top 4 bits are copied from PC+4. Hence `j` from address $A$ can reach any word-aligned address whose top 4 bits equal those of $A+4$ — i.e. the $2^{28}$-byte (256 MB) "region" containing $A+4$. That is exactly $2^{26}$ word-aligned addresses.
- `beq` (I-type) — 16-bit signed immediate, PC-relative. Target address (when taken):
  $$\text{PC}_{\text{new}} = (\text{PC}+4) + (\text{sext}(\text{imm}_{16}) \ll 2)$$
  Range: $A+4 + \delta$ where $\delta \in \{-2^{17}, -2^{17}+4, \ldots, 2^{17}-4\}$. That is $2^{16}$ distinct word-aligned addresses in a $\pm 128$ KB window around $A+4$. (If the branch is not taken, $\text{PC} = A+4$, which is also one of the taken targets, so it adds nothing new.)
- Both instructions produce only word-aligned PC values, and both can land on $A+4$ (jump with offset 0, or branch not taken / offset 0).

## Q1a

**Answer: A** — For *any* value of $A$, some word-aligned addresses are unreachable.

- The union of reachable addresses has size at most $2^{26} + 2^{16}$ (j's region plus beq's window). The set of all word-aligned addresses has size $2^{30}$. So for **every** $A$, the unreachable set is non-empty — in fact, the reachable set covers at most $\tfrac{1}{16}$ of word-aligned addresses (because `j` is confined to one 256 MB region out of sixteen, and `beq` only adds at most $2^{16}$ more, all near $A+4$).
- Concretely: pick any address $X$ whose top 4 bits differ from $(A+4)[31{:}28]$ and which is more than $2^{17}$ bytes away from $A+4$. Such $X$ exists for every $A$ (the address space is $2^{32}$ bytes, the reachable window is tiny). Then $X$ is unreachable.

Why not the other options:
- B is wrong because the reachable set is too small for *any* $A$, not just some.
- (C and D trivially wrong — D is a red herring; the previous instruction has no effect on what the current `j`/`beq` can address.)

## Q1b

**Answer: A** — For *any* value of $A$, there are addresses reachable by `j` but not by `beq`.

- `j` reaches $2^{26}$ word-aligned addresses spread across a 256 MB region; `beq` reaches only $2^{16}$ word-aligned addresses inside a $\pm 128$ KB window around $A+4$. Since $2^{26} \gg 2^{16}$, even when the `beq` window is entirely inside the `j` region, `j` reaches vastly more — so there exist `j`-reachable addresses outside the `beq` window for every $A$.
- Concrete witness: take any word-aligned $X$ in the same 256 MB region as $A+4$ but more than $2^{17}$ bytes away from $A+4$. Such $X$ always exists (the region is 256 MB wide and $A+4$ sits somewhere in it; even at the worst position, points $> 128$ KB away exist in the region). `j` can reach $X$ (matching top nibble), `beq` cannot ($|X - (A+4)| > 2^{17}$).

Why not the other options:
- B is wrong because the argument holds for *every* $A$, not just some.
- (C and D trivially wrong — D is a red herring.)

## Q1c

**Answer: B** — For *some* values of $A$ but not all.

- `beq` can cross the 256 MB region boundary (its $\pm 128$ KB window is PC-relative and not constrained by the top 4 bits of PC+4); `j` cannot. So when $A+4$ is **near** a region boundary (within $2^{17}$ bytes), `beq` reaches some addresses on the other side of the boundary that `j` cannot.
  - Example: $A+4 = \texttt{0x10000000}$. `beq` with offset $-1$ goes to $\texttt{0x0FFFFFFC}$ (top nibble `0x0`). `j` from this $A$ is locked to top nibble `0x1`, so it cannot reach $\texttt{0x0FFFFFFC}$. So for this $A$, the answer is "yes".
- However, when $A+4$ is **far** from every 256 MB boundary (more than $2^{17}$ bytes from the nearest), the entire `beq` $\pm 128$ KB window sits inside the single 256 MB region containing $A+4$. Every `beq` target then shares the top 4 bits with $A+4$, and `j` can reach any such word-aligned address. So `beq`-reachable $\subseteq$ `j`-reachable, and the answer is "no" for this $A$.
  - Example: $A+4 = \texttt{0x10080000}$. All `beq` targets lie in $[\texttt{0x10060000}, \texttt{0x100A0000})$, all with top nibble `0x1`, all reachable by `j`.
- Therefore the property holds for some $A$ but not all — **B**.

Why not the other options:
- A is wrong: the "far from boundary" case above is a counterexample.
- C is wrong: the "near boundary" case above is a counterexample.
- (D trivially wrong — red herring.)

# 2023 Q2 — GB's Logarithmic Number System

## Setup

GB's system uses a 32-bit field $x \in \{0, \dots, 2^{32}-1\}$ to represent the real number $b^x$, where

$$
b = R^{1/(2^{32}-1)}, \qquad R \approx 3.4 \times 10^{38}.
$$

The representable values are $\{b^0, b^1, \dots, b^{2^{32}-1}\} = \{1, b, b^2, \dots, R\}$ — a geometric progression with common ratio $b$.

**How small is $b - 1$?** Since $R \approx 2^{128}$,

$$
b = R^{1/(2^{32}-1)} \approx 2^{128/(2^{32}-1)}
\;\Longrightarrow\;
\ln b \approx \frac{128 \ln 2}{2^{32}-1} \approx \frac{88.7}{2^{32}} \approx 2.07 \times 10^{-8}.
$$

So $b \approx 1 + 2.07 \times 10^{-8}$ and $\sqrt{b} - 1 \approx 1.03 \times 10^{-8}$. By comparison, IEEE 754 single-precision has a relative rounding error of roughly $2^{-24} \approx 5.96 \times 10^{-8}$ (worst case) / $2^{-23} \approx 1.19 \times 10^{-7}$ (ulp).

**Worst-case relative error in GB's system.** For any $r \in [1, R]$, $r$ lies in some interval $[b^x, b^{x+1}]$. Rounding to the closer endpoint gives relative error at most

$$
\max\!\left(1 - \frac{1}{\sqrt{b}},\; \sqrt{b} - 1\right) = \sqrt{b} - 1 \approx 1.03 \times 10^{-8}.
$$

This is *uniform* across the entire range $[1, R]$ — a direct consequence of geometric (log-uniform) spacing — and is **smaller than IEEE 754's relative error everywhere**.

---

## Q2a — Which statement is FALSE?

**Answer: C**
(Note: D is also widely considered an intended exam answer due to poor phrasing, but C is mathematically false.)

### Rigorous reasoning

**A) True.** For $r \in [1, R]$, taking $x = \lceil \log_b r \rceil$ ensures $b^{x-1} \leq r \leq b^x$. Multiplying by $b$ gives $b^x \leq r \cdot b$. Thus $b^x \in [r, r \cdot b]$. Since this interval maps to a length of exactly $1$ in log-space ($[\log_b r, \log_b r + 1]$), it is mathematically guaranteed to contain at least one integer.

**B) True.** By rounding $\log_b r$ to the closest integer $x$, the difference $|x - \log_b r| \leq 0.5$. In the exponent space, this translates to $\frac{1}{\sqrt{b}} \leq \frac{b^x}{r} \leq \sqrt{b}$. The relative error $\left|\frac{b^x}{r} - 1\right|$ is therefore bounded by $\max(\sqrt{b}-1, 1-\frac{1}{\sqrt{b}}) = \sqrt{b}-1$. Because $\sqrt{b}-1 < \sqrt{b}$, the relative error strictly falls within $[0, \sqrt{b}]$.

**C) False.** The interval $b^x \in [\frac{r}{\sqrt{b}}, r]$ translates in log-space to $x \in [\log_b r - 0.5, \log_b r]$. This interval has a length of exactly **0.5**. An interval of length 0.5 on the real number line does *not* always contain an integer. For example, if $r = b^{0.9}$, the valid range for $x$ is $[0.4, 0.9]$, which contains no integers. Therefore, there is no valid representation $x$ that satisfies this condition for all $r$.

**D) False (but likely intended).** If $r=1$, the claim "$b^x \leq 1$ for all $x \leq 2^{30}$" fails immediately, because $b > 1$, so for any $x \geq 1$, $b^x > 1$. However, this is a mangled phrasing of the property $x \le 2^{30} \implies b^x \le \sqrt{R}$ (since $b^{2^{30}} \approx R^{1/4} \ll R^{1/2}$).

<!-- Note: Both C and D are literally false. D's failure is trivial and immediate (counterexample r=1), which might make it the "intended" answer by a careless examiner. However, C fails on a structural, mathematical mechanism of logarithmic number systems, making C the rigorous mathematical falsehood. -->

---

## Q2b — Pros and cons vs IEEE 754

**Answer: C**

> "GB's system has lower error for large real numbers, but addition operations and rounding down to the closest integer are more complex as they cannot be implemented using simple CPU operations such as integer addition and bitwise instructions."

### Justification

**Lower error for large reals (true).** From the setup, GB's worst-case relative error is $\sqrt{b} - 1 \approx 1.03 \times 10^{-8}$, uniformly across $[1, R]$. IEEE 754 single-precision has relative error $\approx 2^{-24} \approx 5.96 \times 10^{-8}$. So GB is more accurate everywhere in its range — in particular, for large reals. (The clause is technically a *weaker* claim than what is true, but it is still true.)

**Addition is hard in GB.** Given $b^x$ and $b^y$, computing $b^x + b^y$ requires

$$
b^x + b^y = b^x(1 + b^{y-x}) \;\Longrightarrow\; \log_b(b^x + b^y) = x + \log_b(1 + b^{y-x}),
$$

which needs a transcendental $\log_b(1 + \cdot)$ evaluation — no integer-add / bitwise trick suffices. Contrast with IEEE 754, where addition is alignment + integer add of mantissas + renormalisation, all standard CPU ops. True.

**Rounding down to an integer is hard in GB.** Given $b^x$, computing $\lfloor b^x \rfloor$ requires actually evaluating $b^x$ (a real exponential), then truncating — no purely-integer-on-$x$ shortcut exists. In IEEE 754, $\lfloor \cdot \rfloor$ on a normalised float is a shift / mask on the mantissa using the exponent. True.

### Why the others are wrong

**A) "Lower for small, higher for large."** False. Spacing is geometric, so the *relative* error is uniform — it is lower than IEEE 754 across the **entire** range $[1, R]$, not just at one end. (In IEEE 754, *relative* error is also roughly uniform across normals, $\sim 2^{-24}$, but is consistently *larger* than GB's $\sqrt{b} - 1$.)

**B) "Higher relative error for all values."** False — GB's relative error is *lower* for all values (as computed above). The multiplication claim is on its own correct: $b^x \cdot b^y = b^{x+y}$, so multiplication is exact integer addition of the $x$-fields (modulo overflow). But the first clause is wrong, so B as a whole is false.

**D) "More efficient for arithmetic because it has one field, but loses precision on additions."** False. Having "one field" only helps for *multiplication* (integer addition of $x$). For *addition*, GB is dramatically *less* efficient than IEEE 754 — it needs $\log_b(1 + b^{y-x})$ (a transcendental), whereas IEEE 754 adds mantissas with shifts and an integer add. So GB is **not** more efficient for arithmetic in general. The "loses precision on additions" clause is true (each add introduces a rounding to the nearest $b^x$), but the headline claim of overall arithmetic efficiency is false.

---

## Key takeaway

GB's logarithmic representation:

- **Wins** on uniform relative precision (better than IEEE 754 everywhere in $[1, R]$) and on **multiplication / division / powers**, which become integer add / subtract / multiply on the $x$ field.
- **Loses** on **addition / subtraction** and on operations that need the actual magnitude (floor, integer conversion, comparison with non-representable thresholds), all of which require evaluating $b^x$ — a transcendental.
- Cannot represent values in $[0, 1)$ or negatives at all (a further con not directly tested here).

This is the classic trade-off of a **logarithmic number system (LNS)** versus a floating-point representation. (external: LNS terminology, beyond module slides.)



# 2023 Q3 — Count trailing zeros of `$t0`

## Problem

Given a 32-bit value in `$t0`, compute the number of consecutive least-significant zero bits and print it as a decimal integer. The code must begin with `li $t0, 0xBABA0000` (for which the answer is 17) and run efficiently on any input, including the edge case `$t0 = 0` (32 trailing zeros). Marked by MARS's instruction *execution* counter.

## Approach

Naive loop (right-shift while LSB is 0, incrementing a counter) executes ~3 instructions per trailing zero, so worst-case ~96 instructions for input 0 and ~75 for `0xBABA0000`. The standard speedup is a **binary search** over the 32-bit word using power-of-two masks (cf. *Hacker's Delight* §5-4). Conceptually:

1. If the low 16 bits are all zero, add 16 to the count and shift `$t0` right by 16.
2. Else, leave `$t0` alone.
3. Repeat the same idea with masks of width 8, 4, 2, 1.

Each block is one mask-and-test plus (conditionally) one add-and-shift, so the algorithm always finishes in a constant ~10–15 executed instructions regardless of where the lowest set bit lies. The only off-by-one wrinkle is `$t0 = 0`, which the binary search would report as 31 (it never finds a "1" to stop at on the last level); we handle it with a single up-front `beq … $zero` shortcut.

## Code

```mips
        .text
        .globl  main
main:
        li      $t0, 0xBABA0000         # required first line; for this input answer = 17

        beq     $t0, $zero, all_zero    # edge case: 0 has 32 trailing zeros

        move    $t1, $zero              # $t1 = count = 0

        # --- binary search over mask widths 16, 8, 4, 2, 1 ---
        andi    $t2, $t0, 0xFFFF        # low 16 bits all zero?
        bne     $t2, $zero, skip16
        addiu   $t1, $t1, 16
        srl     $t0, $t0, 16
skip16:
        andi    $t2, $t0, 0xFF          # low 8 bits all zero?
        bne     $t2, $zero, skip8
        addiu   $t1, $t1, 8
        srl     $t0, $t0, 8
skip8:
        andi    $t2, $t0, 0xF           # low 4 bits all zero?
        bne     $t2, $zero, skip4
        addiu   $t1, $t1, 4
        srl     $t0, $t0, 4
skip4:
        andi    $t2, $t0, 0x3           # low 2 bits all zero?
        bne     $t2, $zero, skip2
        addiu   $t1, $t1, 2
        srl     $t0, $t0, 2
skip2:
        andi    $t2, $t0, 0x1           # low bit zero?
        bne     $t2, $zero, print       # if low bit is 1, count is final
        addiu   $t1, $t1, 1             # else add 1 (no further shift needed)
        j       print

all_zero:
        li      $t1, 32

print:
        move    $a0, $t1
        li      $v0, 1                  # syscall 1: print int
        syscall

        li      $v0, 10                 # syscall 10: exit
        syscall
```

Every mask used (`0xFFFF`, `0xFF`, `0xF`, `0x3`, `0x1`) fits in 16 bits, so each `andi` is a single hardware instruction (no `lui+ori` pseudo expansion).

## Walk-through for `0xBABA0000`

`0xBABA0000 = 1011_1010_1011_1010 0000_0000_0000_0000`, so the LSB-1 sits at bit 17 ⇒ 17 trailing zeros.

| Step | Instr | `$t0` after | `$t1` after |
|---|---|---|---|
| `beq` (not taken — non-zero) | 1 | `0xBABA0000` | — |
| `move $t1,$zero` | 1 | — | 0 |
| `andi 0xFFFF` → 0, `bne` not taken, `addiu`+`srl` | 4 | `0x0000BABA` | 16 |
| `andi 0xFF` → `0xBA`, `bne` taken | 2 | `0x0000BABA` | 16 |
| `andi 0xF` → `0xA`, `bne` taken | 2 | `0x0000BABA` | 16 |
| `andi 0x3` → `0x2`, `bne` taken | 2 | `0x0000BABA` | 16 |
| `andi 0x1` → `0`, `bne` not taken, `addiu`, `j print` | 4 | `0x0000BABA` | 17 |
| `move`, `li`, `syscall`, `li`, `syscall` | 5 | — | 17 |

Counting the leading `li $t0, 0xBABA0000` (which MARS expands to just `lui $t0, 0xBABA` because the low half is zero — 1 instruction): **22 instructions executed** for input `0xBABA0000`. The output is `17`.

## Instruction-count analysis

Let me denote the body as five "levels" of width $w \in \{16, 8, 4, 2, 1\}$. For each level, executed instructions are either:

- **2** (`andi`, `bne` taken) if the low $w$ bits already contain a 1, or
- **4** (`andi`, `bne` not taken, `addiu`, `srl`) if they are all zero — the last level instead executes `andi`, `bne` not taken, `addiu`, `j print` = 4.

The fixed framing is: `li $t0, …` (1), `beq … $zero` (1), `move $t1, $zero` (1), then after the body `move $a0, $t1` (1), `li $v0, 1` (1), `syscall` (1), `li $v0, 10` (1), `syscall` (1) = 8 framing instructions in the non-zero path.

- **Best case** — `$t0` odd (e.g. `…xxx1`): every `bne` is taken at the first level it tests. Body = 5 × 2 = 10. Total = 8 + 10 = **18 instructions**.
- **Worst case (non-zero)** — `$t0` has exactly 31 trailing zeros (only the MSB set, `0x80000000`): every `bne` falls through. Body = 5 × 4 = 20. Total = 8 + 20 = **28 instructions**.
- **Edge case** `$t0 = 0`: `beq` taken, then `li $t1, 32` (1), then 5 framing instructions to print and exit. Total = 1 (`li $t0`) + 1 (`beq`) + 1 (`li $t1, 32`) + 5 = **8 instructions**.
- **Average** — counts are uniform over 0..32, with the modal answer being 0. Across all 32 non-zero "trailing-zero count" buckets, the binary-search depth visited is roughly $\log_2 32 = 5$ levels, but typically only ~2 of them go down the "all zero" branch, giving an average body of $\approx 2 \times 4 + 3 \times 2 = 14$ and a total around **22 instructions** — matching the 22 we measured for `0xBABA0000`.

For comparison, the naive right-shift loop (`andi $t2,$t0,1 ; bne $t2,$zero,done ; srl $t0,$t0,1 ; addi $t1,$t1,1 ; j loop`) executes 5 instructions per zero plus framing: ~92 instructions for `0xBABA0000`, ~157 for input 0 (and only the binary-search version avoids the input-0 edge case naturally — the naive loop would also need a guard or it loops 32 times). The binary search is ~4× faster on this input and bounded above by a small constant on all inputs.

## Optimisations applied

1. **Binary search instead of linear loop.** Replaces an $O(n)$ shift-loop with five fixed mask-and-test stages, turning ~5n executed instructions into a tight $\le 20$-instruction body.
2. **Tight mask choice.** Masks `0xFFFF`, `0xFF`, `0xF`, `0x3`, `0x1` all fit in the 16-bit `andi` immediate, so each test is one instruction (no `lui`+`ori` materialisation of the mask).
3. **No conditional-shift duplication.** A taken `bne` skips both the `addiu` and the `srl` in one branch, so the "this level finds a 1" path costs only 2 instructions (vs 4 for the "all zero" path).
4. **Last level skips the shift.** Once we know the LSB after all prior shifts, we just add 1 to the count if it is zero — no further shift is needed, saving one `srl`.
5. **Up-front `beq $t0, $zero` shortcut for the all-zero input.** This both fixes the off-by-one that the binary search would otherwise produce on `$t0 = 0` (it would report 31) and short-circuits to an 8-instruction path. The cost on the common (non-zero) path is just one extra instruction.
6. **Cheap counter init.** `move $t1, $zero` (a single `addu`) instead of `li $t1, 0`. Equivalent in MARS but unambiguously one instruction.
7. **No memory traffic.** Everything is in registers — no loads or stores, so no chance of mis-aligned accesses or extra cycles.

## MARS-readiness notes

- All instructions are either real MIPS instructions or standard pseudo-instructions (`li`, `move`) that MARS expands deterministically. No `.data` section is needed.
- `li $t0, 0xBABA0000`: MARS recognises that the low 16 bits are zero and emits a single `lui $t0, 0xBABA` (so the required first source line costs **1** executed instruction, not 2). If a marker prefers the worst-case assumption of 2 instructions, the total rises by 1 — still well within the binary-search budget.
- Branch labels (`skip16`, `skip8`, `skip4`, `skip2`, `print`, `all_zero`) are forward references that MARS resolves before execution; no manual offset calculation is needed.
- Syscall 1 prints the integer in `$a0`; syscall 10 cleanly terminates, so the only thing printed is the number itself (no trailing newline from the program, matching the "just the number" requirement).

# 2023 Q4 — `Student` / `Module` / `Exam` concurrency

## Background

Safe-publication idioms (Week 9): a field/reference is safely published if it is initialised in a static initialiser, stored in a `volatile` field or `AtomicReference`, stored in a `final` field of a properly constructed object, or stored in a field properly guarded by a lock (i.e. **both** the write and every read are guarded by the **same** monitor — see slide 31's audit note).

The Java monitor pattern (Week 9): encapsulate mutable state and guard every access with the same intrinsic lock — and make sure the lock is actually held on **every** path that touches the state.

Deadlock definition (LORE.md): the exam takes deadlock to be "all threads permanently blocked", broader than the Coffman cycle. For lock-based deadlock the classic test is still a cycle in the lock-order graph.

Scheduler assumption (LORE.md): unfair scheduler, no spurious wakeups.

---

## Q4a — visibility of each instance field

The four `Student` instance fields are `id`, `name`, `active`, `exams`. (`Student` is the class under analysis; we discuss visibility of those four fields, not those of `Exam` or `Module`.)

```
Q4a Answer
```

```
Instance field: id
Method or methods where the field is published: constructor (assignment), register() (passed to module.addStudent(this.id)). Additionally, because the field is declared public, every other thread can read/write it directly without going through any method.
Is the field safely published? No.
Possible visibility problems for this field: id is a non-final, non-volatile public field whose write happens in the constructor with no synchronization, and whose reads (including the direct public read) take no lock and no volatile fence. A thread that obtains the Student reference can therefore see the default value null instead of the constructor-assigned id, and writes performed later by other threads are not guaranteed to be visible either.
```

```
Instance field: name
Method or methods where the field is published: constructor (assignment), getName() (return), printTranscript() (read inside synchronized(this)).
Is the field safely published? Yes — for reads via getName() / printTranscript(), provided the Student reference itself was safely published. After construction the field is only ever read while holding the Student's intrinsic lock, so the constructor's write is visible to those readers (the write happens-before any later synchronized-on-this read once the reference is safely published).
Possible visibility problems for this field: name is not final and the constructor's write is unsynchronized. If the Student reference itself is published unsafely (e.g. via the public id field's container or any non-volatile data race), a racing thread that gets the reference before construction completes could observe the default value null. After construction, lock-protected reads see the correct value.
```

```
Instance field: active
Method or methods where the field is published: constructor (assignment), register() (write this.active = true), printTranscript() (read this.active outside the synchronized block).
Is the field safely published? Yes.
Possible visibility problems for this field: active is volatile, so every read sees the most recent write (idiom 2 of safe publication). There is no torn-read or stale-cache visibility problem. The read in printTranscript() is performed outside the lock, but since the field is volatile that read still sees an up-to-date value (any "inconsistency" is logical, not a visibility violation — see Q4b/Q4d).
```

```
Instance field: exams
Method or methods where the field is published: constructor (assignment of a new ArrayList), addExam() (mutates the list via add()), getTranscript() (escapes a defensive copy, not the field itself), printTranscript() (iterates the list inside synchronized(this)).
Is the field safely published? Yes for the reference itself — every read of this.exams happens inside a method synchronized on the Student, matching the writes in the constructor/addExam under the same lock (idiom 4, with the usual caveat that the Student reference itself must be safely published). However, the referenced ArrayList is not a thread-safe object: only the wrapping accessors guard it.
Possible visibility problems for this field: as long as every read/write of the field and every mutation of the list goes through the Student's intrinsic lock (constructor, addExam, getTranscript, the synchronized block in printTranscript), no visibility problem arises. The danger is escape: the raw list reference is not exposed by any accessor (getTranscript returns a defensive copy), but if it ever were, external code touching the ArrayList without holding the Student's lock would see stale or partially-updated internal state of the list.
```

[8 marks]

---

## Q4b — can `printTranscript` print "(currently inactive)" *after* `module.addStudent(this.id)` ran?

```
Q4b Answer: yes
Q4b Explanation: register() is synchronized on the Student, but printTranscript()'s test if (!this.active) reads the volatile flag *before* entering the synchronized(this) block — and active is only set to true on the line *after* module.addStudent(this.id). So the interleaving "[T1] enters register(), executes module.addStudent(this.id), but has not yet executed this.active = true; [T2] reads this.active == false in printTranscript() and prints (currently inactive)" is legal: T2 never tries to acquire the Student's monitor for the volatile read, so T1's holding of that monitor does not block it.
```

Reasoning (step by step):

1. Thread T1 calls `S.register(module)`. `register` is `synchronized` on the `Student`, so T1 acquires `S`'s intrinsic lock.
2. T1 executes `module.addStudent(this.id)` — this takes the `Module`'s monitor briefly, then releases it.
3. Now T1 is between steps 2 and 3: it still holds `S`'s lock, and `active` is still `false`.
4. Thread T2 calls `S.printTranscript()`. The first instruction is `if (!this.active)`. **This read does not take any lock** — it is just a volatile read on `active`. So T2 is not blocked by T1 holding `S`'s monitor.
5. T2 sees `active == false` and prints `"(currently inactive)"`.
6. T1 then executes `this.active = true` and releases `S`'s lock; T2 enters its own `synchronized(this)` block afterwards and prints the rest of the transcript.

So `"(currently inactive)"` is printed *after* `module.addStudent(this.id)` already ran. Yes.

[6 marks]

---

## Q4c — `printTranscript` declared `synchronized`: deadlock-prone?

```
Q4c Answer: no
Q4c Explanation: After the change there are still only two intrinsic locks involved — the Student's and the Module's — and the only place that ever holds both is register(), which always acquires Student first and then Module (via module.addStudent). No method anywhere takes the Module lock first and then the Student lock, so there is no cycle in the lock-acquisition graph; no other code uses wait()/notify(), so no non-Coffman deadlock either.
```

Reasoning (step by step):

- Locks present: Student's monitor (used by `getName`, `register`, `addExam`, `getTranscript`, the `synchronized(this)` in `printTranscript`, and — after the change — the whole `printTranscript`) and Module's monitor (used by `addStudent`).
- Calls that hold the Student lock and then try to grab the Module lock: only `register()` (it calls `module.addStudent(this.id)` while still holding `this`'s monitor).
- Calls that hold the Module lock and try to grab a Student lock: none. `Module.addStudent` only calls `students.add(...)`; `Module.registerStudent` is **not** synchronized in this part of the question, so it doesn't hold the Module lock when it calls `newStud.register(this)`.
- So the lock-order graph has only one edge, `Student -> Module`, and is acyclic. No `wait()` anywhere either, so the broader LORE deadlock condition ("all threads blocked") cannot be entered.
- Making `printTranscript` synchronized only adds another method that takes the Student lock alone — it doesn't introduce any new nested acquisition order. Safe from deadlock.

[4 marks]

---

## Q4d — same change: is `Student` thread-safe?

```
Q4d Answer: no
Q4d Explanation: Even after making printTranscript fully synchronized, the class still leaks state through the public non-final field id (any thread can read/write it without synchronization, breaking encapsulation of state and giving stale or default reads) and still iterates this.exams over Exam objects whose toString() is unsynchronized while Exam.update() writes examId/mark under Exam's monitor — so printTranscript can observe a torn (newId, oldMark) or (oldId, newMark) combination during iteration.
```

Reasoning (step by step):

- **Public mutable field `id`.** `public String id;` is the textbook violation of the monitor pattern: external code can read or assign it without holding `Student`'s lock and without any volatile fence. This breaks both encapsulation and the JMM guarantee that other threads see the constructor's write — so `Student` is not thread safe by Week-8's definition (same set of possible states regardless of timing).
- **Unsynchronized read of `Exam` state during iteration.** Inside the `synchronized` `printTranscript`, the body does `for (Exam e : this.exams) System.out.println(e.toString())`. `Exam.toString()` reads `examId` and `mark` **without** holding `Exam`'s monitor, while `Exam.update(newId, newMark)` writes both fields under `Exam`'s monitor. The `Student` lock doesn't help — it doesn't guard `Exam`'s state. So a concurrent `e.update(...)` can produce a torn output where `examId` is the new value but `mark` is the old, or vice versa.
- **Logical TOCTOU in `printTranscript`.** The volatile read of `active` happens outside the lock, so the printout can be "(currently inactive)" followed by a non-empty transcript — internally consistent at the JMM level, but not a sensible class invariant. This is the same hazard Q4b exploited.
- (Note: the question only asks about `Student`, not the global program. The points above suffice.)

[4 marks]

---

## Q4e — instead, `registerStudent` declared `synchronized`: deadlock-prone?

```
Q4e Answer: yes
Q4e Explanation: With registerStudent synchronized, a call path through Module.registerStudent acquires Module first and then Student (because it then calls newStud.register(this), which is synchronized on the Student). The Student.register() path still acquires Student first and then Module (inside module.addStudent). So two threads taking opposite paths deadlock in the classic lock-order-cycle pattern.
```

Concrete deadlock interleaving:

1. `[T1]` calls `m.registerStudent(s)`. With the change, `registerStudent` is `synchronized`, so T1 acquires `m`'s monitor.
2. `[T2]` calls `s.register(m)` directly. `register` is `synchronized` on the `Student`, so T2 acquires `s`'s monitor.
3. T1 now executes `newStud.register(this)` (i.e. `s.register(m)`), which requires `s`'s monitor — **held by T2**. T1 blocks.
4. T2 now executes `module.addStudent(this.id)`, which requires `m`'s monitor — **held by T1**. T2 blocks.
5. Both threads are permanently blocked, each holding the lock the other needs. Coffman cycle: `T1 holds m, wants s; T2 holds s, wants m`. Deadlock.

Lock-order graph after the change has two edges: `Module -> Student` (via `registerStudent`) and `Student -> Module` (via `register`) — a cycle. The cycle is sufficient to make deadlock possible under an adversarial schedule.

[3 marks]

# 2023 Q5 — `WorkPlace` / `Worker` / `Checker`

## Background

This is a classic bounded-buffer monitor with two condition predicates ("buffer not full" and "buffer not empty") sharing a **single** condition queue (the `WorkPlace`'s own intrinsic monitor). A third unconditional waiter (`Checker.waitEvent`) parks on the *same* queue with no predicate at all. All of the standard Week-9/10 hazards (missed signal, hijacked signal, fairness) are reachable because of that single-queue design.

Exam conventions used throughout (LORE.md):

- The scheduler is **not fair** — any runnable thread can be starved.
- **No spurious wakeups** — a wait only returns on an explicit `notify`/`notifyAll`/`interrupt`.
- **Deadlock** is "all threads permanently blocked", broader than the Coffman cycle. In particular, "everyone parked on a queue with no one left to notify" is a deadlock.

---

## Q5a — Liveness properties

```
Liveness problem: deadlock
Is the above code prone to this liveness problem? yes
Explanation: With a finite, fixed set of Worker threads, if every Worker has its current item set to null and they all race into place.get() while the buffer is empty (or all of them hit a full buffer in place.put()), every Worker parks on the WorkPlace condition queue, and the Checker is also parked on that queue inside waitEvent(); no thread is left to call notifyAll(), so by the LORE deadlock definition the whole system is permanently blocked.
```

```
Liveness problem: starvation
Is the above code prone to this liveness problem? yes
Explanation: Two distinct starvation hazards. (1) The Checker only wakes when a Worker's put/get crosses the wasEmpty or wasFull edge; if the steady-state oscillates strictly between 1 and size-1 (e.g. one Worker producing, one consuming, buffer level fluctuating in the middle), no edge transition ever fires notifyAll(), so the Checker sits in waitEvent() forever even though Workers keep making progress. (2) Because Java's intrinsic monitor and the scheduler are not fair (LORE), a single Worker repeatedly re-entering put/get can keep re-acquiring the lock and starve another Worker that is already in the wait set.
```

```
Liveness problem: missed signal (hijacked signal)
Is the above code prone to this liveness problem? yes
Explanation: The single condition queue mixes three different waiter kinds — "buffer not full" predicate waiters in put(), "buffer not empty" predicate waiters in get(), and the Checker which waits with no predicate. notifyAll() fires only on the empty→non-empty or full→non-full edge, never in the middle. If the Checker happens not to be parked at the moment the edge fires (it is busy in print() or has not reached waitEvent() yet), the notification is lost from the Checker's point of view; it will only be woken on a *future* edge, which (per the starvation point above) may never happen. The same loss can hit a Worker if the only notifyAll happens before it enters the queue.
```

```
Liveness problem: livelock
Is the above code prone to this liveness problem? no
Explanation: No thread does a retry-then-yield / busy-wait / "polite-people-in-a-hallway" style state change. All waiters use wait() (blocked, not runnable), so the symptom of livelock — runnable threads doing no useful work — does not arise.
```

[8 marks]

---

## Q5b — replace `place.waitEvent()` with `wait()` inside `Checker.run()`

**Yes — behaviour changes drastically; the new code throws `IllegalMonitorStateException` on every iteration.**

Reasoning (step by step):

1. The body of `Checker.run()` is **not** inside a `synchronized` block on anything. The original call `place.waitEvent()` works because `waitEvent` is `synchronized`, so the Checker acquires `place`'s intrinsic lock when it enters the method and is allowed to call `wait()` on `place`.
2. Replacing it with a bare `wait()` is sugar for `this.wait()` — i.e. `Checker.this.wait()`. To legally call `this.wait()` the calling thread must hold `this`'s intrinsic lock. The Checker does not, so the JVM throws `IllegalMonitorStateException` immediately.
3. That exception is **not** an `InterruptedException`, so it is not caught by the existing `catch(InterruptedException e){ break; }` — it propagates out of `run()` and terminates the Checker thread.
4. Even ignoring the exception (e.g. if the call were wrapped in a `synchronized(this)` block), the semantics would still be wrong: the Checker would be parked on its **own** monitor's condition queue, but every `notifyAll()` in `WorkPlace` is on the `WorkPlace`'s monitor. Nothing ever notifies the Checker, so it would block forever on the first iteration — strictly worse than the original (which at least gets woken on edge transitions).

In short: the replacement either crashes the Checker immediately (the actual behaviour, given there is no enclosing `synchronized`) or, in the most charitable reading, parks it on a queue no one ever signals. Either way the Checker never makes progress, and the program-level invariant "the Checker periodically prints the buffer" is broken.

[4 marks]

---

## Q5c — Friend's claim: "the buffer is neither empty nor full when `print()` is called"

**The friend is wrong.** When `print()` is invoked, the buffer can be empty, full, or anything in between.

Reasoning (step by step):

1. The Checker only reaches `print()` after `waitEvent()` returns, which happens because some Worker called `notifyAll()` on the `WorkPlace`. Worker `notifyAll`s fire only on the **edge transitions**:
   - In `put()`, the edge is `wasEmpty` → just-non-empty (count went 0 → 1).
   - In `get()`, the edge is `wasFull` → just-non-full (count went size → size-1).
2. At the *instant of `notifyAll`*, the buffer is indeed neither empty nor full (count is 1 or size-1). But `notifyAll` does **not** transfer the lock to the Checker — it merely moves wait-set members to the entry set. The notifying Worker continues, finishes its `put`/`get`, and releases the lock.
3. Once the lock is released, every thread that was woken (the Checker plus any other parked Workers) competes with currently-running Workers for re-acquisition. Java's monitor is not fair (LORE), so an arbitrary number of Worker `put`/`get` calls can interleave between the notifying Worker releasing the lock and the Checker eventually winning it.
4. By the time the Checker actually executes `print()`, those intervening Workers can have moved the buffer to **any** state — including back to empty or all the way to full.

Concrete counter-example (buffer ends up *empty* at print time):

1. Buffer is empty (`count == 0`). Worker `G` enters `get()`, sees `count == 0`, waits. Checker also waits in `waitEvent()`.
2. Worker `P` calls `put(o)`. `wasEmpty == true`, writes the item, sets `count = 1`, calls `notifyAll()`, and exits `put` — releasing the lock.
3. `G` re-acquires the lock first, rechecks `while (count == 0)` — false, proceeds, reads the item, sets `count = 0`, `wasFull == false` so **no** notifyAll, returns.
4. Checker now acquires the lock and runs `print()`. `count == 0` — the buffer is empty.

The symmetric counter-example with the buffer **full** at print time: start with buffer full and Worker `P` waiting in `put`; a `get` wakes everyone; another Worker `P'` slips in and `put`s, filling the buffer back to `size`; only then does the Checker print.

So the buffer state at `print()` is, in general, unconstrained — the friend's invariant does not hold.

[6 marks]

---

## Q5d — Assuming `produceItem()` never returns `null`, can a single `Worker` thread enter the `WorkPlace` condition queue via `put()` and then enter the same queue again via `get()`?

**Yes.** Within a single iteration of the `while(!isItemFinished(o))` loop a `Worker` can wait inside `put(o)` (because the buffer was full), wake up, complete the `put`, and then immediately wait again inside `place.get()` (because by then the buffer has been drained empty).

Reasoning (step by step):

1. `produceItem()` is guaranteed non-null, so on the very first iteration the `if (o != null)` test is true and the Worker calls `place.put(o)`.
2. Inside `put()`, if `count == size`, the Worker executes `wait()` and joins the `WorkPlace`'s condition queue. This is the **first** entry into the queue.
3. Suppose now another Worker (or several) runs `get()`, dropping `count` below `size`; the `wasFull` transition fires `notifyAll()`, our Worker re-acquires the lock, the `while (count == size)` predicate is false, it stores its item, increments `count`, and returns from `put()`.
4. Still inside the same loop iteration, the Worker calls `place.get()`. The implementation of `get()` checks `while (count == 0) wait();`. There is no rule against `count` being zero at this point — other Workers could have consumed every item in the buffer between our Worker's `put` and `get`. In that case our Worker calls `wait()` inside `get()` and re-enters the **same** condition queue. This is the **second** entry, by the same Worker, on the same monitor.
5. Eventually some Worker `put`s, the `wasEmpty` edge fires `notifyAll()`, our Worker wakes up, takes an item, and exits `get()`.

The two waits are in two different methods with two different condition predicates, but the JVM has one condition queue per monitor, so it is literally the same queue. The Worker just visits it twice in a row.

> [Not] uncertain: nothing in the problem assumes that produceItem is the only source of work, nor that the number of Workers is bounded in a way that prevents step 3/4 — even with 2 Workers the interleaving is reachable.

[4 marks]

---

## Q5e — With only Workers (no Checker), can `notifyAll()` be safely replaced by `notify()` in `WorkPlace`?

**No, it is not safe.** Even without a Checker, replacing `notifyAll()` with `notify()` exposes the classic **hijacked-signal** bug (Goetz §14.2.4), because two different condition predicates — "buffer not full" (`put`-waiters) and "buffer not empty" (`get`-waiters) — share the **same** condition queue, and a single `notify()` wakes an arbitrary one of them.

Reasoning (step by step):

1. **Why the two waiter kinds can coexist in the queue.** The predicates `count == size` and `count == 0` cannot both hold at the same instant (`size > 0`), but the queue persists across moments. A `put`-waiter joined the queue at a time when the buffer was full; once items have been consumed, the buffer is no longer full but the waiter is still parked (it needs an explicit wakeup). If, later, the buffer drains all the way to empty, a `get`-waiter joins. Now the queue contains **both** kinds simultaneously, even though no single moment in time saw both predicates true.

2. **How a signal gets hijacked.** Suppose the queue contains one stale `put`-waiter `P` (parked back when the buffer was full) and one fresh `get`-waiter `G` (just parked because the buffer is now empty). Some Worker `E` then calls `put(o)`:
   - `wasEmpty == true` (it was empty), `E` stores the item, `count = 1`, and calls `notify()`.
   - The JVM picks one waiter to wake — say it picks `P` (arbitrary, not fair).
   - `P` re-acquires the lock, rechecks `while (count == size)` — false (`count == 1`), so the loop exits.
   - `P` proceeds to write its own item, sets `count = 2`, and the `wasEmpty` check inside `P`'s `put` is `false` (since `count` was 1 on entry, not 0), so `P` does **not** notify anyone.
   - `G` is still parked. No further notifications are pending; no edge will fire again unless the buffer goes empty or full again. If the remaining Workers just keep `put`ting until the buffer fills (or simply stop), `G` is stuck forever even though there are items available for it to consume.

3. **Why this matters with only Workers.** The Checker is irrelevant to this specific failure — the hijacking happens between two Workers with different predicates. So removing the Checker does **not** make `notify()` safe.

4. **The textbook fix.** The Goetz remedy is either (a) keep `notifyAll()`, or (b) split the queue into two separate `Condition` objects (one per predicate) using `ReentrantLock` / `newCondition()`, so a single `signal()` always goes to the *right* predicate's waiter. Neither is what the question proposes.

So the substitution is **unsafe**.

[3 marks]

---

## Status report

Wrote `/home/akioweh/projects/ugnotes/COMP0008-arena/materials/past_papers/answers/2023/Q5.md` with all five subparts in the requested formats. Key findings: (a) lists deadlock, starvation, and missed/hijacked signal as real hazards (livelock is not); (b) the substitution throws `IllegalMonitorStateException` because `Checker.run()` doesn't hold its own monitor; (c) the friend is wrong — concrete counter-examples show empty and full states at print time due to non-fair monitor re-acquisition; (d) yes, a single Worker can wait in `put` then immediately in `get` within one loop iteration; (e) `notify()` is unsafe even without the Checker because of the classic hijacked-signal interaction between `put`-waiters and `get`-waiters on the shared queue.

