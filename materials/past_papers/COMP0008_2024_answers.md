> Reference answers for [COMP0008_2024.md](COMP0008_2024.md).
> Per-question source files: `materials/past_papers/answers/2024/Q*.md`.
> Generated 2026-05-12 by parallel subagents grounded in `materials/`.

# COMP0008 2024 — Reference Answers

# 2024 Q1 — MIPS Control Transfer Instructions

Instruction `I` is located at address `0x00400000`. Each sub-question asks which single instruction `I` could be, given an observed effect.

Key semantics (from the MIPS Green Card / Week 4 slides):

- `j target` (J-type): `PC = JumpAddr` where `JumpAddr = { (PC+4)[31:28], address, 2'b00 }`. Only the low 26 bits of the target come from the instruction; the top 4 bits are inherited from `PC+4`. Reaches addresses in the same 256 MB region only.
- `jal target` (J-type): same target rule as `j`, **and** `$ra = PC + 4` (the return address is saved).
- `jr $rs` (R-type): `PC = R[$rs]`. Can jump to **any** 32-bit address. Does **not** write `$ra`.
- `jalr $rs` (or `jalr $rd, $rs`) (R-type): `PC = R[$rs]` **and** `$rd = PC + 4` (defaulting to `$ra`). Arbitrary target **and** writes `$ra`.
- `beq $rs, $rt, label` (I-type): if equal, `PC = (PC+4) + SignExtImm·4`. PC-relative branch range is ±2^17 bytes from `PC+4`.

`PC + 4 = 0x00400004`, so the top 4 bits of `PC+4` are `0x0`.

---

## Q1a — PC became `0x20400000`

**Answer: C**

The target `0x20400000` has top 4 bits `0x2`, but `PC+4 = 0x00400004` has top 4 bits `0x0`. So any J-type instruction (`j`, `jal`) executed from this address can only reach the region `0x00000000`–`0x0FFFFFFC` and **cannot** produce `0x20400000`. That eliminates A and B.

`beq` is PC-relative with a reach of only ±128 KB from `PC+4`; the displacement `0x20400000 − 0x00400004` is roughly 512 MB and is far out of range, so D is impossible.

`jr $rs` sets `PC = R[$rs]` directly, with no encoding restriction on the upper bits of the target — `$rs` can hold `0x20400000`. So `I` can be a `jr`.

## Q1b — `$ra` changed after executing `I`

**Answer: B**

Of the four instructions, only `jal` is defined to write `$ra` (`$ra = PC + 4`). `j`, `beq`, and `jr` do not modify any register that the architecture exposes as `$ra`:

- A (`j`) — pure jump, no register write.
- C (`jr`) — reads `R[$rs]` into PC; never writes any register (note: even `jr $ra` only *reads* `$ra`, it doesn't change its value).
- D (`beq`) — only updates PC on the equal case; no register write.

So only B is consistent with `$ra` changing.

## Q1c — PC became `0x20400000` **and** `$ra` changed

**Answer: D**

This combines both constraints: the target must be `0x20400000` (impossible for `j`, `jal`, `beq` from this PC, as in Q1a) **and** `$ra` must be written (impossible for `j`, `jr`, `beq`).

- A (`j`) — doesn't change `$ra`; also can't reach `0x20400000`.
- B (`jal`) — changes `$ra`, but can't reach `0x20400000` (top-4-bits constraint same as `j`).
- C (`jr`) — can reach `0x20400000` but doesn't write `$ra`.
- D (`jalr $rs`) — sets `PC = R[$rs]` (arbitrary 32-bit target, so `0x20400000` is reachable) **and** writes `$ra = PC + 4`. Both effects are produced by a single instruction.

Hence `jalr` is the only instruction that satisfies both conditions.


---

# 2024 Q2 — bfloat16 vs IEEE 754 half precision

Format recap:

- **bfloat16**: 1 sign | 8 exponent (bias 127) | 7 fraction.
- **IEEE 754 half**: 1 sign | 5 exponent (bias 15) | 10 fraction.

Both are 16-bit, so they trade exponent range against fraction precision. bfloat16 keeps the same exponent field as IEEE single (huge dynamic range) but slashes the mantissa; IEEE half keeps a longer mantissa but a small exponent.

Key derived numbers:

- IEEE half max normal: $(2 - 2^{-10}) \cdot 2^{15} \approx 65504$.
- bfloat16 max normal: $(2 - 2^{-7}) \cdot 2^{127} \approx 3.39 \times 10^{38}$ (matches IEEE single's range).
- Integers exactly representable: up to $2^{\text{frac}+1}$, i.e. 2048 for IEEE half, 256 for bfloat16.
- Values in $[1, 2]$: $1 + k / 2^{\text{frac}}$ for $k = 0, \ldots, 2^{\text{frac}} - 1$, i.e. 1024 for IEEE half, 128 for bfloat16.

---

## Q2a — what is bfloat16 (vs IEEE half) able to do?

**Answer: D**

- **A (fewer normals): FALSE.** Number of normals $= 2 \cdot (2^{\text{exp}} - 2) \cdot 2^{\text{frac}}$. IEEE half: $2 \cdot 30 \cdot 1024 = 61440$. bfloat16: $2 \cdot 254 \cdot 128 = 65024$. bfloat16 has *slightly more* normals, not fewer.
- **B (more integers exactly): FALSE.** Exact integer range is $2^{\text{frac}+1}$ — 256 for bfloat16 vs 2048 for IEEE half. IEEE half wins by a factor of 8.
- **C (more numbers in $[1, 2]$): FALSE.** The spacing in $[1, 2]$ is $2^{-\text{frac}}$: $2^{-10}$ (IEEE half, 1024 values) vs $2^{-7}$ (bfloat16, 128 values). IEEE half wins by a factor of 8.
- **D (more numbers in $[80000, 90000]$): TRUE.** IEEE half tops out at $\approx 65504$, so it cannot represent *any* finite value in $[80000, 90000]$ — anything above its max rounds to $+\infty$. bfloat16's range extends to $\sim 3.4 \times 10^{38}$, so many values in $[80000, 90000]$ are representable. "More" here means $\text{many} > 0$.

The single advantage bfloat16 has over IEEE half is dynamic range; (D) is the only option that picks a regime where bfloat16's wider exponent matters.

## Q2b — representing $\pi$ in both formats

**Answer: D** &nbsp; `> [uncertain]`

$\pi \approx 3.1415926535897932\ldots$, which lies in $[2, 4)$, so the unbiased exponent is 1 in both formats and the value to encode in the fraction is $\pi / 2 - 1 = 0.5707963267948966\ldots$.

Multiplying by $2^{\text{frac}}$ and rounding to nearest:

- **IEEE half** ($2^{10} = 1024$): $0.5707963\ldots \times 1024 = 584.4954\ldots \to 584$. Stored fraction = $584 / 1024 = 0.5703125$. Stored value $= 2 \cdot (1 + 0.5703125) = 3.140625$. Absolute error $\approx 9.68 \times 10^{-4}$, relative error $\approx 3.1 \times 10^{-4}$.
- **bfloat16** ($2^7 = 128$): $0.5707963\ldots \times 128 = 73.0619\ldots \to 73$. Stored fraction = $73 / 128 = 0.5703125$. Stored value $= 2 \cdot (1 + 0.5703125) = 3.140625$. Same absolute error $\approx 9.68 \times 10^{-4}$.

So neither A nor B holds — both formats have non-zero rounding error, because $\pi$ is irrational and certainly not a dyadic rational fitting in 7 or 10 fraction bits.

The interesting wrinkle: $584 = 73 \times 8$ and $1024 = 128 \times 8$, so $584/1024 \equiv 73/128$ exactly. Both formats *coincidentally* round $\pi$ to the same stored value, $3.140625$, and therefore to the same error. Strictly speaking, neither C ("bfloat16 lower") nor D ("bfloat16 higher") is literally correct: the two errors are equal.

> [uncertain] Going by the literal calculation the errors are equal and none of the four options strictly applies. The intended answer is almost certainly **D**: in general bfloat16 has 3 fewer mantissa bits than IEEE half, so worst-case and average rounding error is about $8\times$ worse, and the examiner likely expected that line of reasoning rather than a digit-by-digit comparison for $\pi$ specifically. The "tie at $3.140625$" only happens because $\pi$'s bit pattern $1.\mathbf{1001001000}\,\ldots_2$ ends in three zeros in IEEE half's tenth–twelfth bit positions, so truncating the last 3 mantissa bits costs nothing extra. A non-coincidental input (e.g. $e$, $\sqrt{2}$) would generally give bfloat16 a strictly higher error.

- **A — bfloat16 exact: FALSE.** $\pi$ is irrational; no finite binary fraction can equal it.
- **B — IEEE half exact: FALSE.** Same reason.
- **C — bfloat16 error strictly lower: FALSE.** bfloat16 has strictly less mantissa precision; it cannot do *better* than IEEE half on a generic real, and for $\pi$ specifically it ties (does not undercut).
- **D — bfloat16 error strictly higher: intended TRUE** (but literally a tie for $\pi$, see above).


---

# 2024 Q3 — Detect Power of 4 in MIPS

## Problem

Starting from `li $t0, 16384`, write efficient MIPS assembly that sets `$t1 = 1` if the value in `$t0` is an integer power of 4, and `$t1 = 0` otherwise. The note `4^7 = 16384` confirms the test value should answer "yes". Marked on correctness and efficiency.

## Key idea

A 32-bit integer `n > 0` is a power of 4 iff **both**:

1. `n` is a power of 2 — exactly one bit set — i.e. `n & (n - 1) == 0` and `n != 0`.
2. That single set bit sits at an **even** bit-position (bit 0, 2, 4, …, 30) — i.e. `n & 0x55555555 != 0`.

The largest power of 4 that fits in a signed 32-bit word is `4^15 = 2^30 = 0x40000000`; `4^16 = 2^32` overflows, and negative values / zero are never powers of 4. The zero case is handled by the leading `beq`, and any negative `$t0` (top bit set) automatically fails the even-bit-position mask test, so we don't need a separate sign check.

## MIPS code

```mips
        .text
        .globl  main
main:
        li      $t0, 16384          # input under test (= 4^7)

        li      $t1, 0              # default answer: not a power of 4
        beq     $t0, $zero, done    # 0 is not a power of 4

        addi    $t2, $t0, -1        # $t2 = n - 1
        and     $t2, $t0, $t2       # $t2 = n & (n - 1); == 0 iff n is power of 2
        bne     $t2, $zero, done    # more than one bit set -> not power of 4

        lui     $t3, 0x5555         # build mask 0x55555555 (bits at even positions)
        ori     $t3, $t3, 0x5555
        and     $t2, $t0, $t3       # is the lone set bit at an even position?
        beq     $t2, $zero, done    # no -> power of 2 but not power of 4

        li      $t1, 1              # all checks passed
done:
        nop                         # fall-through end of program
```

The program writes only to `$t0`, `$t1`, `$t2`, `$t3` and produces no output, as required. It runs unmodified in MARS.

## Trace for `$t0 = 16384 = 0x4000 = 2^14 = 4^7`

- `$t1 = 0`.
- `beq $t0,$zero,done` — not taken.
- `$t2 = 16384 - 1 = 0x3FFF`; `$t2 = 0x4000 & 0x3FFF = 0` — single bit confirmed.
- `bne $t2,$zero,done` — not taken.
- `$t3 = 0x55555555`; `$t2 = 0x4000 & 0x55555555 = 0x4000` (bit 14 is even) — non-zero.
- `beq $t2,$zero,done` — not taken.
- `$t1 = 1`.

Sanity checks: `$t0 = 8` (`2^3`) — bit 3 is odd, last mask gives 0, branches to `done` with `$t1 = 0`. `$t0 = 5` — not a power of 2, fails the second test. `$t0 = 0` — first `beq` skips to `done`. `$t0 = 0x40000000 = 4^15` — bit 30 is even, returns 1.

## Instruction-count discussion

Static program: **10** real instructions (the `li` initialiser, two `li`s for the answer, one `beq`, `addi`, `and`, `bne`, `lui`, `ori`, `and`, `beq`, and the final `li $t1, 1` — the trailing `nop` is just a landing pad).

Dynamic counts (executed instructions, excluding the input `li $t0, 16384`):

| Case | Path | Instructions executed |
|---|---|---|
| `$t0 = 0` | first `beq` taken | **2** (`li $t1, 0`, `beq`) |
| Power of 2 but not of 4 (e.g. 2, 8, 32 …) | second test passes, third fails | **8** |
| Not even a power of 2 (e.g. 5, 6, 7 …) | `bne` after first mask taken | **4** |
| Power of 4 (best case for a "yes") | falls through all branches | **9** |

So worst case ≈ 9 instructions, best case 2, both small constants independent of the magnitude of the input.

## Optimisation notes

- The two-mask trick beats the naïve "repeatedly divide by 4 and check remainder" loop, which would execute O(log₄ n) iterations of three or four instructions each.
- `addi $t2, $t0, -1` saves a register compared with `li $t4, 1; sub $t2, $t0, $t4`.
- The mask `0x55555555` cannot be materialised in a single instruction — `addi`/`ori` sign- or zero-extend a 16-bit immediate, and the MIPS `li` pseudo-op would also expand to `lui`+`ori` for this constant — so two instructions for the mask are unavoidable.
- An alternative test is "`n` is a power of 2 **and** `(n - 1)` is divisible by 3" (since `4^k - 1 = (4 - 1)(4^{k-1} + … + 1)`). Division by 3 on MIPS requires `div`/`mfhi` (and a 12-cycle stall on the classic R3000 `div`), so it is strictly slower than a single `and` against a precomputed mask.
- The leading `beq $t0,$zero,done` is required: without it, `addi $t2,$t0,-1` for `n = 0` produces `0xFFFFFFFF`, and `0 & 0xFFFFFFFF = 0`, which would spuriously pass the "single bit" test. The subsequent mask `and` would still give 0 and reject, so in this particular routine the early-out is more about clarity and shaving a few cycles than correctness — but it's cheap insurance.
- All branches are forward (target `done`), so on a simple predict-not-taken pipeline every branch in the "yes" path is correctly predicted, giving no mispredict bubbles for the marked test value.

## Status

Solution uses the standard `n & (n - 1)` power-of-two test combined with an even-bit-position mask `0x55555555`; verified by hand-trace for `$t0 = 16384` (returns 1) and for several negative cases (0, 5, 8, 0x40000000). Worst-case dynamic instruction count is 9, independent of input magnitude.


---

# 2024 Q4 — ValueHolder Concurrency

## Setup

`ValueHolder` has private `int` fields `x`, `y`, `z` (initialised to `0, 0, 20`) and a `volatile String description`. `set` and `add` are `synchronized` (lock = `this`); `print` (which calls private `transform()`) and `printDescription` are **not** synchronized. `Type1.run()` is:

```java
public void run() {
    h.set(3, 2, 1);   // synchronized call
    h.print();        // unsynchronized; reads x, y, z via transform()
}
```

`main` publishes `holder` via the `Type1` / `Type2` constructors, then calls `start()` on each thread before `join()`. `Thread.start()` provides a happens-before edge from `start()` to the first action of the started thread, so threads always see the fully-constructed `ValueHolder` (`x=0, y=0, z=20`, `description="Value Holder\nValues:"`) when they begin. The subsequent `setDescription("Coordinates Holder\nValues:")` happens-before all `start()` calls too.

---

## Q4a — Atomic actions of t1.run() and constraints

Using the concurrency-abstraction granularity from lectures (Week 7 / Week 8): synchronized method calls execute as a single externally-atomic action; each **unsynchronized** field access is its own atomic action.

Numbered atomic actions for `t1`:

| # | Action | Notes |
|---|---|---|
| A1 | `h.set(3, 2, 1)` | one atomic action externally (acquires the lock on `h`, writes `x`, `y`, `z`, releases the lock) |
| A2 | read `x` (inside `transform()`, no lock held) | unsynchronized field read |
| A3 | read `y` (inside `transform()`, no lock held) | unsynchronized field read |
| A4 | read `z` (inside `transform()`, no lock held) | unsynchronized field read |
| A5 | compute `x + y + z` and `System.out.println(...)` | local computation + I/O |

(Treating `h.print()` as a single atomic action would be incorrect here: `print` is not synchronized, and the three field reads inside `transform()` can be individually interleaved with synchronized updates from `t2`/`t3`, which is the whole point of the question.)

Constraints (program order within `t1`, as required by the abstraction):

- A1 → A2 → A3 → A4 → A5 (totally ordered within the thread).
- A1 must finish (release the lock) before A2 starts — A1 is one atomic action.
- Cross-thread constraint: `t1`'s run cannot begin until `main`'s `t1.start()` happens-before `t1`'s first action; similarly any state set by `main` before `start()` is visible to `t1`.

> [uncertain] The lectures sometimes lump a whole method call into "one atomic action" and sometimes break it down to individual unsynchronized reads/writes. The unsynchronized-read decomposition is the one that matches Week 8's `Example` exercise (`a()` vs `b()`) and is the only model under which the rest of this question (Q4b, Q4c) admits the values it does. So we use it here.

---

## Q4b — Can `t1` print 8?

**Yes — 8 is possible.**

Reasoning by exhibiting an interleaving. Initial state: `x=0, y=0, z=20`.

| Step | Thread | Action | State after |
|---|---|---|---|
| 1 | t1 | `h.set(3, 2, 1)` (A1) | `x=3, y=2, z=1` |
| 2 | t1 | read `x` (A2) → 3 | unchanged |
| 3 | t2 | `h.add(1, 1, 1)` (entire synchronized call) | `x=4, y=3, z=2` |
| 4 | t1 | read `y` (A3) → 3 | unchanged |
| 5 | t1 | read `z` (A4) → 2 | unchanged |
| 6 | t1 | print `3 + 3 + 2 = 8` (A5) | output `8` |

`t1` reads `x` before `t2`'s `add` runs (so it gets the pre-increment `3`), then `t2`'s entire `add` slips between `t1`'s read of `x` and read of `y` (so `t1` gets the post-increment `y=3` and `z=2`). Sum is `3 + 3 + 2 = 8`.

This is exactly the same kind of "torn read of a compound update" race condition shown in the Week 8 `Example` lecture: an unsynchronized reader interleaves with a synchronized writer mid-read.

---

## Q4c — Maximum value `t1` can print

**Maximum = 12.**

Only `set` (called once by `t1`) and `add` (called once each by `t2` and `t3`) modify the fields. After `t1.set(3, 2, 1)`, the fields are `x=3, y=2, z=1`. Each subsequent `add(1, 1, 1)` increments all three fields by 1 atomically (synchronized). After both `add`s have completed:

```
x = 5,  y = 4,  z = 3
```

`x + y + z = 12`. The only way `t1`'s `print` can read a value larger than these from any field is if some other thread writes a larger value, but no thread does — `set` writes constants and `add` increments by 1.

To actually observe the sum 12, choose the interleaving where `t1.set` runs first, then both `t2.add` and `t3.add` complete, and only then `t1`'s three reads run:

| Step | Thread | Action | State after |
|---|---|---|---|
| 1 | t1 | `h.set(3, 2, 1)` | `x=3, y=2, z=1` |
| 2 | t2 | `h.add(1, 1, 1)` | `x=4, y=3, z=2` |
| 3 | t3 | `h.add(1, 1, 1)` | `x=5, y=4, z=3` |
| 4 | t1 | read `x` → 5, read `y` → 4, read `z` → 3 | sum = 12 |

No interleaving can produce a larger sum:

- The reads of `x`, `y`, `z` are independent and unsynchronized, but each one can read at most the maximum value that field ever holds (`5`, `4`, `3` respectively).
- Achieving all three maxima simultaneously requires both `add`s to have completed before any of the three reads, which is exactly the interleaving above — and that gives 12.
- Reordering `t1.set` to happen after some `add`s only decreases the sum (e.g. both `add`s first → `x=2, y=2, z=22`; then `set` → `x=3, y=2, z=1`; sum = 6).

---

## Q4d — Swap `t1.join()` and `holder.print()`: does the set of values printable by `main` change?

**Yes, the set of printable values strictly grows.**

Original code (lines 66–67):

```java
t1.join();          // t1 has terminated → t1.set and t1.print have happened
holder.print();     // main reads x, y, z (unsynchronized via transform())
```

After the swap:

```java
holder.print();     // main reads x, y, z *before* waiting for t1
t1.join();
```

**Original.** When `main` reaches `holder.print()`, `t1` has terminated, so `t1.set(3, 2, 1)` has executed. `t2` and `t3` may or may not have run their `add`s. The fields each independently lie in:

- `x ∈ {3, 4, 5}` (initial 3, plus 0, 1 or 2 increments)
- `y ∈ {2, 3, 4}`
- `z ∈ {1, 2, 3}`

with the additional constraint that the reads can be torn (an `add` may slip between any two of `main`'s three unsynchronized reads). Possible sums range over `{6, 7, 8, 9, 10, 11, 12}` (sum = `6 + (increments visible to each read summed)`, where each read sees 0, 1 or 2 prior add-completions).

**Swapped.** `main`'s `holder.print()` runs concurrently with all three of `t1`, `t2`, `t3`. In particular it can now run **before `t1.set` executes**, so `x, y, z` may still be at their constructor values `0, 0, 20`. New cases reachable that were not reachable before:

- No thread has touched the fields yet: read `0 + 0 + 20 = 20`.
- One `add` has completed but `set` has not: `x=1, y=1, z=21` → 23.
- Both `add`s have completed but `set` has not: `x=2, y=2, z=22` → 26.
- Torn reads between these states give intermediate sums (e.g. read `x=0`, then `t2.add` runs and `t3.add` runs and `t1.set` runs, then read `y=2, z=1` → `0 + 2 + 1 = 3`).

The original code could not produce any of these "set has not yet run" outcomes, because `t1.join()` guaranteed `t1.set` had completed. So the swap admits strictly more printable values — for example, `20`, `23`, `26` (and indeed `0`-something through `26`) become possible. The set of printable values **changes** (grows).

A secondary, subtler change: the original gives a JMM happens-before edge from `t1`'s termination (everything `t1` did, including `set`'s write of `x, y, z`) to `main`'s subsequent reads (via `t1.join()`). Removing that edge means even if `t1.set` *has* run by wall-clock time, `main` is no longer guaranteed to see those writes — it might still read the constructor values for reasons of JMM visibility, not just interleaving. (`description` is `volatile` so it is unaffected.) This doesn't add new *values* beyond the interleaving analysis above, but it widens the runs in which "old" values appear.

---

## Q4e — Visibility of each instance field

For each non-`volatile`, non-`final` field, two questions to consider per the Week 9 rubric: is it safely published, and can reads see stale or partial-construction values?

In *this specific program*, `Thread.start()` provides the happens-before edge that lets started threads see the constructor's writes — so partial construction is not actually exhibited at runtime. But the questions are about each field's intrinsic properties: whether the **field itself** is published in a way that provides the JMM guarantees. Where the answer depends on this distinction, the Notes call it out.

### Instance field: x

```
Instance field: x
Method or methods where the field is published:
  - written: ValueHolder() constructor, set(...) (synchronized), add(...) (synchronized)
  - read:    print() / transform() (unsynchronized), set(...) and add(...) (synchronized)
Is the field safely published? No
Can the field cause threads to see partially constructed objects? Yes (in general)
Can threads see stale values for this field? Yes
Notes: x is private, non-volatile, non-final, and the constructor's write happens
without holding the lock. Reads via the unsynchronized print()/transform() path
provide no happens-before edge with the writers, so they can return stale values
even when synchronized writers have committed newer ones. In this specific
program partial-construction visibility is avoided only because the
ValueHolder is published via Thread.start() (start() has happens-before with
the thread's first action), not because the field itself is safely published.
```

### Instance field: y

```
Instance field: y
Method or methods where the field is published:
  - written: ValueHolder() constructor, set(...) (synchronized), add(...) (synchronized)
  - read:    print() / transform() (unsynchronized), set(...) and add(...) (synchronized)
Is the field safely published? No
Can the field cause threads to see partially constructed objects? Yes (in general)
Can threads see stale values for this field? Yes
Notes: Same analysis as x. Non-volatile, non-final, written under the lock but
read without the lock in print()/transform(). The Thread.start() publication
of the ValueHolder is what prevents the constructor's y = 0 from being read as
the default 0 by another thread before the constructor's write — but that
protection comes from start(), not from y's own publication discipline.
```

### Instance field: z

```
Instance field: z
Method or methods where the field is published:
  - written: ValueHolder() constructor, set(...) (synchronized), add(...) (synchronized)
  - read:    print() / transform() (unsynchronized), set(...) and add(...) (synchronized)
Is the field safely published? No
Can the field cause threads to see partially constructed objects? Yes (in general)
Can threads see stale values for this field? Yes
Notes: Same analysis as x and y. The fact that the constructor's z = 20 differs
from x's and y's defaults makes the partial-construction case noticeable in
principle — a reader that obtained the ValueHolder reference via an unsafe
publication could see z = 0 (default) instead of 20. That doesn't happen in
this program because of Thread.start()'s happens-before, but the field itself
is not safely published.
```

### Instance field: description

```
Instance field: description
Method or methods where the field is published:
  - written: ValueHolder() constructor, setDescription(...) (synchronized + volatile write)
  - read:    printDescription() (unsynchronized but volatile read)
Is the field safely published? Yes
Can the field cause threads to see partially constructed objects? No
Can threads see stale values for this field? No
Notes: description is volatile (safe-publication idiom #2 from Week 9). Every
read of description sees the most recent write, and a volatile write
establishes happens-before with subsequent volatile reads, so neither stale
reads nor partial-construction visibility apply. (The synchronized modifier on
setDescription is redundant for visibility of this field — volatile alone
suffices. Note also that volatile applies to the *reference*: the String
itself is immutable, so there is nothing further to worry about.)
```

---

## Status

All five subparts answered. Q4a uses the Week 7/8 atomic-action model where synchronized calls are externally atomic and unsynchronized field accesses are individually atomic — the only model consistent with Q4b/Q4c admitting torn-read values like 8. Q4b exhibits an explicit interleaving producing 8. Q4c bounds the maximum at 12 with a witness. Q4d argues the swap admits strictly more printed values (e.g. 20, 23, 26) because `t1.set` may not have run. Q4e analyses all four fields against the safe-publication / stale-read / partial-construction rubric from Week 9. The Q4a action-granularity choice is flagged `> [uncertain]` since the lecture model can be read either way, but the chosen reading is internally consistent with the rest of the answer and matches the Week 8 `Example` exercise treatment.


---

# 2024 Q5 — `Market` / `Buyer` / `Seller`

## Background

The `Market` is a bounded-buffer monitor with **one** condition queue (the `Market`'s own intrinsic monitor) shared by two condition predicates: "buffer not full" (`put`-waiters) and "buffer not empty" (`get`-waiters). The application instantiates *one* `Market` `M` and `X > 10` `Buyer`s + `X > 10` `Seller`s.

The **critical observation** that drives most of this question is the field declaration

```java
private int size = 1;
private Item[] buffer = new Item[size];
```

so the buffer has capacity **1**, and `count ∈ {0, 1}` at all times. Consequences:

- Every successful `put` was preceded by `count == 0`, so `wasEmpty == true` and `notifyAll()` always fires.
- Every successful `get` was preceded by `count == 1 == size`, so `wasFull == true` and `notifyAll()` always fires.
- Therefore every state-change in the monitor wakes the whole wait set. The `synchronized(market){ market.notifyAll(); }` block at line 55 of `Buyer.run()` is redundant (the preceding `put(o)` already fired).

Exam conventions used throughout (LORE.md):

- The scheduler is **not fair** — any runnable thread can be starved by other runnable threads.
- **No spurious wakeups** — `wait()` only returns on an explicit `notify`/`notifyAll`/`interrupt`.
- **Deadlock** is "all threads permanently blocked" (broader than the Coffman cycle): "every thread parked on a condition queue with no one left to notify" is a deadlock.

---

## Q5a — Liveness properties [8 marks]

```
Liveness problem: deadlock
Is the above code prone to this liveness problem? yes
Explanation: The Sellers' isInBusiness() and the Buyers' isWillingToBuy() are application-level predicates that may eventually become false, terminating those threads. If every Seller has already terminated while at least one Buyer is parked inside get() on count == 0 (symmetrically: every Buyer terminated while a Seller is parked inside put() on count == size), no thread is left alive to fire notifyAll(), and the parked thread waits forever — all surviving threads are permanently blocked, which is deadlock per the LORE definition.
```

```
Liveness problem: starvation
Is the above code prone to this liveness problem? yes
Explanation: Java's intrinsic monitor is unfair (LORE), so when notifyAll() wakes every waiter and they all race with currently-running threads to re-acquire the lock, an individual Buyer or Seller can lose the race arbitrarily many times in a row. With X > 10 producers and X > 10 consumers all churning on the same single-slot buffer, one specific thread can be re-passed over forever while the others make progress.
```

```
Liveness problem: livelock
Is the above code prone to this liveness problem? yes
Explanation: A Buyer that decides not to buy puts the item straight back into the market (line 54), and any other Buyer may then get it, also reject it, and put it back again. If the Buyers' decideToBuy() predicates keep returning false, the threads are perpetually runnable and the monitor operations all succeed, but the application makes no useful progress (no Buyer ever leaves the loop with a purchased item) — the textbook livelock symptom of "thread keeps retrying an operation that never advances the goal".
```

```
Liveness problem: missed signals
Is the above code prone to this liveness problem? no
Explanation: All three wait sites (the two in Market and any wait that happens implicitly via re-entry) sit inside while-loops on the actual condition predicate, and because size == 1 every successful put and every successful get crosses an edge and fires notifyAll(), so every wake-up reaches every parked thread on every state change. There is also no hijacked-signal hazard: a put-waiter that loses the race after notifyAll simply rechecks count == size and waits again, harming nobody.
```

[8 marks]

---

## Q5b — replace `while (count == 0)` with `if (count == 0)` in `get()` [4 marks]

**This is catastrophic for thread safety.** It breaks both the data-structure invariant and the published contract of `get()`.

Step by step:

1. With the `while`, a `Buyer` that is woken from `wait()` re-tests `count == 0` and only proceeds if there really is an item to consume. This is the standard Goetz pattern and is the only correct way to use `wait()` on a shared condition queue (LORE — no spurious wakeups, but the **hijacked-signal** / **stale-state** reasons from Week 10 still apply).
2. With `if`, the test is performed exactly once, *before* the wait. After the thread wakes and re-acquires the lock, it skips straight to the body of `get()`. There is no guarantee that `count > 0` at that point: between the `notifyAll` and the re-acquisition, another `Buyer` (or many) may have already drained the slot.
3. Concrete failing interleaving (size == 1, so this is easy to hit):
   - `count == 0`. Buyers G1 and G2 both enter `get()`, see `count == 0`, call `wait()`. Both park.
   - Seller S calls `put(o)`. The buffer fills (`count = 1`), `wasEmpty == true`, `notifyAll()` fires. S releases the lock.
   - G1 re-acquires the lock first. It does **not** re-check (`if` was already evaluated). It executes `Item o = buffer[out]`, `--count` → `count = 0`, `out = (out+1) % 1 = 0`. `wasFull == true` (count was 1), so it `notifyAll`s and returns `o`. OK so far.
   - G2 re-acquires the lock. Again no re-check. It reads `buffer[out]` — but `out == 0` and `buffer[0]` is the same reference G1 just took (the array slot was never cleared), so **G2 returns a duplicate of the item already consumed by G1**. Then `--count` → `count = -1`. The "count ∈ {0, 1}" invariant is now broken; `in == out == 0` is consistent with both "empty" and "full"; the next `put` will overwrite `buffer[0]` and `++count` makes `count == 0`, which `get()` will now treat as empty.
4. Beyond returning duplicate references and corrupting `count`, the broken invariant makes every subsequent caller's view of the buffer state wrong, so any reasoning about emptiness/fullness from outside (e.g. `print()`) is also invalidated.

In short: the `if` substitution makes `get()` lose the *predicate guarantee* that callers rely on, returning stale items and driving `count` negative. Thread safety is destroyed.

[4 marks]

---

## Q5c — One `Seller` + several `Buyer`s: can the `Seller` enter the queue and never be woken? [4 marks]

**Yes — it can.** The vulnerability is application-level termination of the surviving `Buyer`s, not a monitor bug.

Reasoning step by step:

1. The `Seller` waits inside `put()` only when `count == size == 1`, i.e. the slot already holds an unsold item.
2. The only way the `Seller` is woken from that wait is for some thread to execute `get()` and cross the `wasFull` edge (`count` going 1 → 0) — that's the only `notifyAll()` site that fires once the slot is full.
3. Each surviving `Buyer` runs the loop `while (isWillingToBuy()) { ... market.get(); if (!decideToBuy(o)) { market.put(o); ... } else { break; } }`. Two ways a `Buyer` exits:
   - `isWillingToBuy()` returns false at the top of the loop, so the `Buyer` terminates **without** calling `get()`.
   - `decideToBuy(o)` returns true, the `Buyer` `break`s and terminates **after** calling `get()` (this case actually drains the buffer first, which would have woken the `Seller`).
4. The dangerous scenario is the first one. Suppose:
   - The `Seller` puts an item (`count = 0 → 1`, `notifyAll`).
   - Then on its next iteration it calls `put` again; sees `count == 1`, calls `wait()`. It is now on the queue.
   - The remaining `Buyer`s are not currently inside `get()` — they are between iterations (sleeping, evaluating `isWillingToBuy()`, or running the omitted code). One by one their `isWillingToBuy()` returns false, and they each terminate **before reaching the next `market.get()` call**.
5. Once every surviving `Buyer` has exited, there is no thread left to call `get()`, so the `wasFull` edge will never be crossed, so `notifyAll()` will never be called on `M`, so the parked `Seller` will sleep forever. Per LORE this counts as the `Seller` being on the queue and never woken.

A weaker form of the same answer relying only on unfair scheduling does **not** quite work: while the `Buyer`s are still alive and `count == 1`, the next `Buyer` that calls `get()` will not wait (the predicate `count == 0` is false), so it consumes the item, fires `notifyAll`, and the `Seller` is woken. So lack-of-fairness alone is not sufficient — the question hinges on the `Buyer`s being free to terminate without consuming.

> [uncertain] If the question intends to fix `isWillingToBuy()` as always returning true (so `Buyer`s never voluntarily exit), then no — given infinitely persistent `Buyer`s, every full-buffer state is eventually drained and the `Seller` is always woken (a `Buyer` calling `get()` is the *only* operation that can be running concurrently with a full-buffer state). The answer above takes the stronger reading where `isWillingToBuy()` is genuinely application-controlled.

[4 marks]

---

## Q5d — One `Buyer` + several `Seller`s: can the `Buyer` enter the queue via `get()` and never exit? [4 marks]

**Yes — symmetrically to Q5c.** The risk is again that the surviving `Seller`s terminate (via `isInBusiness()` returning false) without ever producing the put that would wake the `Buyer`.

Reasoning step by step:

1. The `Buyer` waits inside `get()` only when `count == 0` (empty slot).
2. The only way the `Buyer` is woken from that wait is for some thread to execute `put()` and cross the `wasEmpty` edge (`count` going 0 → 1).
3. Each surviving `Seller` runs `while (isInBusiness()) { Item o = produceItem(); Thread.sleep(1000); if (o != null) market.put(o); }`. A `Seller` exits when `isInBusiness()` returns false, evaluated at the **top** of its loop.
4. Dangerous scenario:
   - The buffer is empty (`count == 0`). The single `Buyer` enters `get()`, sees `count == 0`, calls `wait()`. It is now on the queue.
   - Each remaining `Seller` is at the top of its loop or sleeping or executing `produceItem()`. One by one, when they next reach the top of the loop, `isInBusiness()` returns false and they terminate **without putting**. (`produceItem()` may also return `null`, which the `Seller` silently skips via `if (o != null)`.)
5. Once every surviving `Seller` has exited, there is no thread left to call `put()`, the `wasEmpty` edge will never be crossed, no `notifyAll` is ever issued on `M`, and the parked `Buyer` sleeps forever.

A second, weaker route: even with `Seller`s alive, a `Seller` might be perpetually stuck in `Thread.sleep(1000)` followed by `produceItem()` returning `null` followed by another iteration, never reaching the `put`. Combined with unfair scheduling that's not a "never woken" by itself, but it widens the window for case (5) to occur.

> [uncertain] As with Q5c, if the question intends `isInBusiness()` to be permanently true and `produceItem()` to never return `null`, then no — a `Seller` will eventually put and the `Buyer` is woken. The "yes" answer reads the question as application-controlled termination predicates being part of the model.

[4 marks]

---

## Q5e — Remove the `notifyAll()` at `Buyer.run()` line 55: can any `Buyer` call `market.get()` when there are exactly **ten** `Item`s in the `Market`'s buffer? [5 marks]

**No — independently of the change.** This is a trick question that rests on the buffer's capacity.

Step by step:

1. The `Market` field declarations fix the buffer to **size 1**:
   ```java
   private int size = 1;
   private Item[] buffer = new Item[size];
   ```
   `size` is `private` and never reassigned anywhere in the supplied code, and `buffer` is allocated exactly once with length 1. So the array has length 1 throughout the lifetime of the `Market`.
2. The `count` variable is bounded by the monitor invariant `0 ≤ count ≤ size == 1`: `put()` waits while `count == size`, increments to 1, returns; `get()` waits while `count == 0`, decrements to 0, returns. So `count ∈ {0, 1}` at every observable moment.
3. There is therefore **no reachable state** of the `Market` in which the buffer holds 10 `Item`s. The premise of the question ("exactly ten Items in Market's buffer") is unsatisfiable.
4. Removing the `synchronized(market){ market.notifyAll(); }` block at Buyer line 55 does not change this. That block was strictly redundant: the preceding `market.put(o)` already executed `notifyAll()` itself (since with `size == 1` every successful `put` has `wasEmpty == true`). Deleting it changes the number of wake-ups per buyer-rejection from 2 to 1, but it does not — and could not — change the capacity of the buffer.
5. Consequently, no `Buyer` (and no thread at all) can ever call `market.get()` in a state with 10 items present, before or after the modification. The answer is **no**.

If the question instead meant to ask about ten items having *passed through* the buffer over time (cumulative throughput rather than current contents), then trivially yes — the `Market` is reused indefinitely and many items flow through it; but the literal wording "ten Items in Market's buffer" refers to current contents, and the literal answer is no.

[5 marks]

---

## Status report

Wrote `/home/akioweh/projects/ugnotes/COMP0008-arena/materials/past_papers/answers/2024/Q5.md` covering all five subparts in the requested formats. Key findings: the whole question hinges on `size = 1`, which collapses `count` to `{0, 1}` and makes every put/get fire `notifyAll()` (so missed/hijacked signals are not in play here). (a) deadlock yes (all-producers-or-all-consumers-terminate scenario), starvation yes (unfair monitor), livelock yes (Buyers reject + put back forever), missed signals no. (b) `if` substitution lets Buyers return duplicate references and drive `count` negative — catastrophic. (c) yes, the Seller can be parked on a full buffer while all Buyers terminate without consuming (`isWillingToBuy() → false`). (d) yes, symmetric — the Buyer is parked on an empty buffer while all Sellers terminate without producing. (e) trick question — the buffer has capacity 1, so it can never hold 10 items; removing the redundant `notifyAll()` in `Buyer.run()` is irrelevant to the impossibility. Two `> [uncertain]` blocks flag ambiguity in (c) and (d) over whether the unspecified application predicates are allowed to become false.


---

