> Reference answers for [COMP0008_2025.md](COMP0008_2025.md).
> Per-question source files: `materials/past_papers/answers/2025/Q*.md`.
> Generated 2026-05-12 by parallel subagents grounded in `materials/`.

# COMP0008 2025 — Reference Answers

# 2025 Q1 — Signed vs Unsigned Integer Representations

Setup: `x`, `y` are unsigned 32-bit; `a`, `b` are signed 32-bit (two's complement); the bit patterns match (`x ↔ a`, `y ↔ b`).

Key facts from Week 1/2:

- The **bit pattern** of two's-complement addition and subtraction is identical for signed and unsigned operands — the ALU does not need to know the interpretation. Whether the *numerical* result is "correct" depends on whether overflow/underflow occurs **under that interpretation**.
- For an unsigned word `x` and the same bits as signed `a`: if `x < 2^{31}` then `a = x`; if `x ≥ 2^{31}` then `a = x − 2^{32}` (i.e. `a < 0`).
- **Comparison** is *not* bitwise-uniform: signed `<`/`>` must look at the sign bit (or equivalently use `slt`), unsigned uses `sltu`. They give different answers in general.

---

## Q1a — Which is correct?

**Answer: C**

C asserts: subtraction hardware computes `a − b` correctly when `x ≥ 2^{32} − 2^{24}` AND `y ≤ 2^{20}`.

- `x ≥ 2^{32} − 2^{24}` ⇒ `x ∈ [0xFF000000, 0xFFFFFFFF]`, so the top bit of `x` is 1, hence `a` is negative with `a ∈ [−2^{24}, −1]`.
- `y ≤ 2^{20}` ⇒ `y ∈ [0, 2^{20}]`, and since the top bit of `y` is 0, `b = y ∈ [0, 2^{20}]`.

Check both interpretations of the subtraction performed by the same bitwise hardware:

- **Unsigned:** `x − y ≥ (2^{32} − 2^{24}) − 2^{20} > 0`. No borrow / no underflow, so the unsigned result is exact.
- **Signed:** `a − b ∈ [−2^{24} − 2^{20}, −1]`. This range lies inside `[−2^{31}, 2^{31} − 1]`, so no signed overflow.

Both interpretations of the result bit pattern are numerically correct: `x − y` (as an unsigned number) equals `2^{32} + (a − b)`, which is exactly how two's complement encodes the negative value `a − b`. The hardware works for both.

Why the others fail:

- **A** (comparison). Signed and unsigned compare hardware are different. Counter-example: `x = 0xFFFFFFFF`, `y = 1` gives `x > y` (unsigned), but `a = −1`, `b = 1` gives `a < b` (signed). Hence `slt` ≠ `sltu` in general.
- **B** (addition with `x + y < 2^{32}`). No unsigned overflow does **not** imply no signed overflow. Counter-example: `x = y = 0x7FFFFFFF` gives `x + y = 0xFFFFFFFE < 2^{32}` (unsigned ok), but `a = b = 2^{31} − 1`, so signed `a + b = 2^{32} − 2` overflows; the hardware produces `0xFFFFFFFE = −2` as signed, not `2^{32} − 2`. Simpler counter-example: `a = 2^{31} − 1`, `b = 1` ⇒ `x + y = 2^{31} < 2^{32}` but signed result is `0x80000000 = −2^{31}`, not `+2^{31}`.
- **D** (subtraction with `x ≥ 2^{24}` AND `y = 2^{16}`). The constraint `x ≥ 2^{24}` allows `x` anywhere in `[2^{24}, 2^{32} − 1]`, so `a` may be the most-negative signed value. Counter-example: `x = 0x80000000` (so `a = −2^{31}`), `y = 0x00010000` (so `b = 2^{16}`). Bitwise `x − y = 0x7FFF0000`, but signed `a − b = −2^{31} − 2^{16}` is below `−2^{31}` — signed underflow, and the hardware bit pattern `0x7FFF0000` is positive in signed view. Wrong.

---

## Q1b — `z = x XOR y` (unsigned)

**Answer: B**

XOR is purely bitwise, so `z`'s bit pattern is the same whether we think of the operands as signed or unsigned. In particular, **the top bit of `z` equals (top bit of `x`) XOR (top bit of `y`)**, i.e. `z ≥ 2^{31}` iff `a` and `b` have *opposite* sign bits.

**B.** If `a < 0` and `b > 0`, then `z × x > 2^{60}`.

- `a < 0` ⇒ top bit of `x` is 1 ⇒ `x ≥ 2^{31}`.
- `b > 0` ⇒ top bit of `y` is 0.
- Top bit of `z` = `1 XOR 0 = 1`, so `z ≥ 2^{31}`.
- Therefore `z × x ≥ 2^{31} · 2^{31} = 2^{62} > 2^{60}`. ✓

Why the others fail:

- **A.** "`z ≥ 2^{31}` only possible if `a × b < 0`." `z ≥ 2^{31}` means `a` and `b` have opposite sign bits, which includes the case `a = 0`, `b < 0` (or vice versa). Then `a × b = 0`, not strictly negative. Counter-example: `x = 0`, `y = 0xFFFFFFFF` ⇒ `a = 0`, `b = −1`, `z = 0xFFFFFFFF ≥ 2^{31}`, but `a × b = 0`. False.
- **C.** "If `a < 0` then `z × x > 2^{30}`." `a < 0` only constrains `x`; `z` can be tiny. Counter-example: `x = y` (so `a = b`, both negative), then `z = 0` and `z × x = 0`. False.
- **D.** "If `a, b > 0` then `z × x < 2^{60}`." Both being positive only bounds `x, y < 2^{31}`, but `z` can still approach `2^{31} − 1`. Counter-example: `x = 2^{31} − 1` (so `a = 2^{31} − 1 > 0`), `y = 1` (so `b = 1 > 0`). Then `z = x XOR y = 2^{31} − 2`, and `z × x = (2^{31} − 2)(2^{31} − 1) ≈ 2^{62} > 2^{60}`. False.


---

# Q2 — True/False (MIPS conventions, endianness, UTF-8)

## Q2a. Endianness determines the order of bytes inside registers in CPUs such as MIPS.

**Answer: False**

Endianness only determines the order of bytes in **memory** when a multi-byte value is loaded or stored; inside a register the value is held as a single 32-bit unit and the byte ordering is not architecturally visible.

## Q2b. A MIPS function that does not call any other function may use temporary registers (e.g. `$t0`) without restoring their values.

**Answer: True**

By the MIPS calling convention, `$t0`–`$t9` are **caller-saved** — they need not be preserved across calls. A leaf function (one that calls nothing) has no callees to worry about, so it can clobber them freely without save/restore.

## Q2c. After the pseudo-instruction `li $s1, 100`, we may assume that the value of temporary registers (e.g. `$t0`) is unchanged.

**Answer: True**

`li` expands to either a single `addiu $s1, $0, 100` (small immediate) or `lui` + `ori` on `$s1` itself; for any scratch needs the assembler uses `$at` (the assembler-temporary, `$1`), never any `$t` register. So `$t0` is guaranteed untouched.

## Q2d. After the pseudo-instruction `li $s1, 100`, we may assume that the kernel registers (e.g. `$k0`) are unchanged.

**Answer: False**

`$k0` and `$k1` are reserved for the OS kernel and can be overwritten at any moment by the kernel's exception/interrupt handler. Since an interrupt can fire between any two user-mode instructions, no user code can assume `$k0`/`$k1` are preserved across *any* instruction.

## Q2e. The UTF-8 encoding of any current character is at most three bytes long.

**Answer: False**

UTF-8 uses 1 byte for U+0000–U+007F, 2 bytes for U+0080–U+07FF, 3 bytes for U+0800–U+FFFF (the Basic Multilingual Plane), and **4 bytes** for U+10000–U+10FFFF. The current Unicode standard (~155,000 characters) includes many supplementary-plane characters (emoji, CJK Extension B+, etc.), which require 4 bytes.


---

# Q3 — MIPS short-answer

## Q3a. Functionality of the three-instruction sequence

- `sra $t0, 31` -> `$t1` = sign mask: 0 if `$t0 >= 0`, `-1` (0xFFFFFFFF) if `$t0 < 0`.
- `xor` with mask: leaves non-negative unchanged; bit-flips negative (i.e. `~$t0`).
- `sub $t1`: subtracts 0 (non-neg) or `-1` (neg, i.e. adds 1, completing two's-complement negation: `~x + 1 = -x`).
- **Result: `$t0 = |$t0|`** (branchless absolute value).
- Edge case: `INT_MIN` (0x80000000) overflows and stays itself.

(Week 5: MIPS arithmetic/logic; cheat sheet `sra`, `xor`, `sub`.)

## Q3b. Benefits of conditional assignment (e.g. `slt`) vs branches

- No branch -> no **control hazard**, no pipeline flush on misprediction (Week 6 — Control Hazards).
- Constant-time, data-independent timing (useful for crypto / side-channel resistance).
- Simpler, straight-line control flow exposes more **instruction-level parallelism**.
- Smaller, more predictable code paths; better I-cache behaviour.

(Week 5 slides 686-694, 1027-1058; Week 6 hazards.)

## Q3c. Benefits of reserving `$k0`, `$k1` for kernel use

- Excluded from the calling convention -> kernel needn't save/restore them on exception entry.
- Provides immediate scratch space for the exception handler before any user state is spilled.
- Avoids the cost of saving all 32 user registers just to begin handling an interrupt/trap.

(Week 5 slides 1840-1851: exception handling; register table line 1165.)


---

# Q4 — Caches

## Q4a. Role of hardware caches: why used, and what makes them effective?

- **Why:** to bridge the huge gap between fast CPU clock rates and slow DRAM — a cache is a small, fast SRAM buffer that holds recently/likely-used data so most loads/stores avoid the multi-hundred-cycle main-memory latency.
- **Why effective:** programs exhibit **locality of reference** — *temporal* (a word just used is likely to be used again soon) and *spatial* (words near a used one are likely to be used soon), so a small cache captures the vast majority of accesses.
- Combined with a multi-level hierarchy, this gives the *illusion* of memory that is simultaneously large (DRAM-sized) and fast (SRAM-speed).

## Q4b.i. Cache size in bytes

- Block size = 2 words × 4 B/word = **8 B/block**.
- Total lines = 16 sets × 2 ways = **32 lines**.
- Data capacity = 32 × 8 = **256 B** (excluding tag and valid-bit overhead).

## Q4b.ii. Operations when loading from address `1001011100101`

- **Address split** (13 b = tag | set | offset = 6 | 4 | 3): tag = `100101` (37), set index = `1100` (12), block offset = `101` (byte 5 within the 8-B block; the word lives in the upper half of the block).
- **Lookup:** index set 12, then in parallel compare tag `100101` against the tags of both ways while checking their valid bits.
- **On hit:** the matching way's data is selected by the offset and the requested word is returned to the CPU in one cache-access cycle.
- **On miss:** a victim way in set 12 is chosen by the replacement policy (e.g. LRU; if dirty in a write-back cache, write it back first); the whole 8-B block at memory address `1001011100000` is fetched from main memory, written into that way with tag = 37 and valid = 1, and the requested word is then forwarded to the CPU.

## Q4c. Implications of caches on concurrent software in multi-core architectures

- Each core has its own private cache(s), so a write by one core is not automatically visible to another — without intervention, threads can read **stale** values and races become silent correctness bugs.
- Hardware **cache-coherence protocols** (e.g. MESI with bus snooping / write-invalidate) restore a single-writer/multiple-reader view, but coherence traffic costs cycles and bandwidth; combined with store buffers and out-of-order execution it forces languages to expose a **memory model** (e.g. the JMM) and require programmers to use synchronisation (`volatile`, locks, fences) to obtain ordering and visibility guarantees.
- A practical pitfall is **false sharing** — unrelated variables that happen to lie in the same cache line cause the line to ping-pong between cores on every write, destroying performance even though the program is logically race-free; padding/alignment to cache-line boundaries is the standard fix.


---

# 2025 Q5 — PointMover, Synchronisation, and the JMM

Setup: `place`, `moveClose`, `getPosition` are `synchronized` instance methods (lock on
`this`). `moveFar` synchronises on a *different* monitor — the private `internalLock` object.
The fields `x`, `y` are shared mutable state of the `PointMover` instance.

---

## Q5a. Semantics of `synchronized(internalLock)` in `moveFar`

- A thread entering the block must acquire the intrinsic lock of the **`internalLock` object** (not `this`); on exit it releases that lock. So `moveFar` and the other three methods are guarded by **two different locks**, and mutual exclusion holds only *within each lock's group*.
- Consequence for **interference**: a `moveFar` call can run concurrently with `place` / `moveClose` / `getPosition`, so the compound updates to `x` and `y` interleave — `moveFar`'s read-modify-write of `x` (then `y`) can be torn apart by a `place` or `moveClose` running on `this`, producing inconsistent / lost updates and asymmetric (`x ≠ y`) states.
- Consequence for **visibility (JMM)**: monitor release-acquire only synchronises threads using the *same* monitor, so writes made by a thread holding `internalLock` have **no happens-before edge** to a later read by a thread holding only `this`; `getPosition` may therefore observe stale (and partial) `x`, `y` written by `moveFar`.

## Q5b. Reordering of lines 29 (`place(10,10)`) and 30 (`moveClose(4)`)

- **No.** Both calls are `synchronized` on the same monitor (`this`), so each pair is a release at the end of `place` followed by an acquire at the start of `moveClose` *in the same thread* — the JMM forbids reordering across these synchronisation actions, and even ordinary within-thread reorderings must preserve the program-order semantics that any observer (including the lock-protected fields themselves) can see.
- Even ignoring the lock, the JMM's "as-if-serial" rule means the JVM may only reorder two actions of the *same* thread when no in-thread or correctly-synchronised out-of-thread observer can tell — here `moveClose` reads `x`/`y` written by `place`, so swapping them changes the observable result and is therefore disallowed.

## Q5c. `java MoverApp --num-t1=2` — set of printable values

- Two `Type1` threads each run `place(10,10)` then `moveClose(4)`; *all four* calls take the same monitor on `this`, so they execute atomically and in some serial order respecting the per-thread program order (each thread's `place` before its own `moveClose`).
- Enumerating the legal orderings: whenever a `place` happens after the other thread's `moveClose` (e.g. `pA, cA, pB, cB`), the trailing `place` resets state to `(10,10)` and only the final `moveClose` adds 2, giving **`(12,12)`**; whenever both `place`s precede both `moveClose`s (e.g. `pA, pB, cA, cB`), state is `(10,10)` then both adds apply, giving **`(14,14)`**.
- Printable set = **`{(12,12), (14,14)}`** (always `x == y`, since every operation moves `x` and `y` by the same amount and there is no torn update under a single lock).

## Q5d. `java MoverApp --num-t1=1 --num-t2=1` — different set from Q5c?

- **Yes, strictly larger and qualitatively different.** `Type2.moveFar` uses `internalLock` while `Type1`'s calls use `this`, so by Q5a the two threads race on `x`, `y`: e.g. `moveFar` can read `x = 0`, then `place` runs to completion writing `(10,10)`, then `moveFar` writes `x = 2` (clobbering 10) before reading and writing `y = 12`, leaving an asymmetric state that `moveClose` further perturbs.
- The output set therefore includes the well-ordered cases that would arise under a single lock (`moveFar` happens entirely before / between / after the `Type1` calls → `(12,12)` or `(14,14)`) **plus** asymmetric values where `x ≠ y` and individual writes are lost; the additional outcomes are precisely the symptom that `internalLock` breaks both mutual exclusion and visibility for the shared fields.

## Q5e. Two separate JVMs (`--num-t1=1` in one CLI, `--num-t2=1` in another)

- **No, not the same.** Each JVM is a separate OS process with its own heap and its own freshly-constructed `PointMover` — no memory, monitor, or thread state is shared between them, so the two runs cannot race.
- JVM 1 runs one `Type1`: `place(10,10)` then `moveClose(4)` deterministically print **`(12,12)`**. JVM 2 runs one `Type2`: `moveFar(2)` on a fresh mover (`x = y = 0`) prints **`(2,2)`**.
- This two-process output set `{(12,12), (2,2)}` is disjoint from (and much smaller than) the single-JVM set in Q5d, which contains `(14,14)` and the asymmetric race outcomes that require shared state.


---

# 2025 Q6 — ReadWriteController, starvation & deadlock

Setup notes (apply to every subpart):

- **Exam convention (LORE):** the scheduler is **unfair** — any individual runnable thread may lose every contended lock-acquisition race indefinitely. "Deadlock" is the broader definition: **every thread blocked / no thread can ever make progress**, even without a Coffman cycle (e.g. everyone is `wait()`ing and no one will ever `notify`).
- **No spurious wakeups** — a thread leaves `wait()` only because some thread called `notify` / `notifyAll` (or interrupted it).
- **Safety bug already in the original code:** `acquireWrite` waits on `readersTurn || writing` and does **not** check `readers > 0`. So a Writer can enter while Readers are still active provided `readersTurn == false`. We carry this bug through the liveness analysis; we only care that no part of the question relies on Writers excluding Readers (they don't).
- **Mechanics of the original alternation:**
  - `releaseRead` always sets `readersTurn = false`, then `notifyAll` only when the last Reader leaves.
  - `releaseWrite` sets `writing = false` and `readersTurn = true`, then `notifyAll`.
  - After a Writer releases: `readersTurn=true`, `writing=false`. Readers' predicate `writing || (numWaitingWriters>0 && !readersTurn)` is `false || (… && false) = false` → all waiting Readers can enter together. Waiting Writers' predicate is `readersTurn || writing = true` → they re-wait.
  - After the last Reader releases (`readers==0`, `readersTurn=false`, `notifyAll`): Writers' predicate `false || false = false` → one Writer wins and proceeds.
  - This produces the **writer → reader-wave → writer → reader-wave** alternation.

---

## Q6a. 10 Readers + 10 Writers, original code

**Answer: E (More than one Writer can starve but no Reader will).**

> [uncertain] — depends on whether "starve" is read structurally or per-thread under the unfair-scheduler convention. Under a strict per-thread reading, F could also be defended.

Justification:

- **Readers cannot starve.** After every Writer release, *all* waiting Readers' predicate clears simultaneously; the `notifyAll` wakes all of them and there is no per-thread race among Readers — they all reacquire the monitor in some order and each one, on its turn, finds the predicate still false (Readers do not turn it back on; only a Writer flips `readersTurn` to `true`, and there are no Writers running while Readers hold the read-state in the well-behaved alternation). So every Reader that was waiting at the start of a reader-wave is admitted in that wave. Reader threads do **not** lose repeated races against each other — they share the read state.
- **Writers can starve (more than one).** Only one Writer can hold `writing=true` at a time. At the end of a reader-wave, `notifyAll` wakes all waiting Writers and exactly *one* wins the monitor with predicate false; the others see `writing=true` and re-wait. Under the unfair scheduler, the same lucky Writer can win the post-reader-wave race **every** round, leaving the other 9 Writers permanently re-waiting. There is no fairness guarantee that bounds how many Writers lose this race repeatedly, so more than one Writer can be starved.
- The class of Writers as a whole makes progress (so the system is not deadlocked, and there is always *some* Writer writing), but individual Writers can be left out forever.

Why not the others:

- **A** — No: individual Writers can starve as shown above.
- **B / D** — Readers do not starve.
- **C ("at most one Writer")** — too strong; nothing bounds losers to one. Several Writers can lose the post-wave race together.
- **F** — Only defensible under a hyper-pedantic reading where you also count Readers losing the wake-up race; but Readers do not actually have to compete for a *capacity-1* resource, so the standard course reading is E.

---

## Q6b. Replace `while(readersTurn || writing)` with `while(readers>0 || writing)` in `acquireWrite`

**Answer: D (More than one Reader can starve but no Writer will).**

> [uncertain] — same caveat as Q6a re: structural vs per-thread starvation, but D is the intended answer.

What changed: Writers now wait on the *correct* safety predicate (they wait while readers are reading or another writer is writing). This **fixes the original safety bug**. But it also removes the only mechanism that throttled Writers — the `readersTurn` flag.

Trace:

- After `releaseWrite`: `writing=false`, `readersTurn=true`. A new Writer's predicate is `readers>0 (no, =0) || writing (no) = false` → it **proceeds immediately**. Writers can now **chain back-to-back** without ever yielding to Readers, because `readersTurn` no longer gates them.
- Meanwhile Readers' predicate is unchanged: `writing || (numWaitingWriters>0 && !readersTurn)`. As soon as a Writer chains in and sets `writing=true`, Readers that try to enter wait. And at the instant of the post-Write notifyAll (where `readersTurn=true`), the Reader's predicate evaluates to `false || (… && !true)=false`, so a Reader *could* in principle proceed — but it must win the lock race against the freshly-woken Writers, and under unfair scheduling it doesn't have to.
- Even more sharply: once `numWaitingWriters>0` and the last Reader has done a `releaseRead` (which sets `readersTurn=false`), every new Reader's predicate is `false || (numWaitingWriters>0 && !false) = true` → wait. So whenever there's any waiting Writer and `readersTurn` is `false`, new Readers are blocked entirely.

So Writers form a self-sustaining chain (Writer → notify → Writer → notify → …) and Readers can be locked out indefinitely. Writers do not starve; **multiple Readers can starve** (nothing limits the count).

Why not the others:

- **A** — Readers starve, so not "no thread".
- **B** — More than one Reader can be locked out at once.
- **C / E** — Writers do not starve under this modification; they actually starve Readers.
- **F** — D is a clean structural match.

---

## Q6c. 1 Reader + 10 Writers, `while` → `if` in `acquireRead`

**Answer: E (Two or more of the above can occur).**

The `if` replaces guarded waiting with a single-shot test — after `wait()` returns, the Reader does **not** re-check `writing || (numWaitingWriters>0 && !readersTurn)` before doing `++readers`. This is the classic *missed/hijacked signal* bug from the Week-9 conditional-synchronisation slides.

(D) **A Writer can write and the Reader can read at the same time — TRUE.**

- Reader R calls `acquireRead`; some Writer `W1` is already writing, so R `wait()`s.
- `W1` calls `releaseWrite`: `writing=false`, `readersTurn=true`, `notifyAll`. R is moved to the runnable set but must reacquire the monitor.
- Before R wins the monitor, another Writer `W2` (also woken by the notifyAll) reacquires first. `W2`'s `while (readersTurn || writing)` is true (`readersTurn=true`) so `W2` `wait()`s again. *Or*, equivalently, a Writer that calls `acquireWrite` fresh and finds itself ahead — irrelevant; the key is that the state can flip while R is queued. To make D occur directly: any sequence where the monitor state becomes `writing=true` again between R waking and R running.
  - Easier path: when `W1` calls `releaseWrite` it does `notifyAll`, but before R runs, `W1` itself loops, calls `acquireWrite` again (`numWaitingWriters=1`, predicate `readersTurn(true) || writing(false) = true` → wait). That's not enough by itself; we need some Writer to actually re-set `writing=true`.
  - Sharper path: the Reader is woken by a `releaseRead`'s `notifyAll` while another Reader holds the read state — irrelevant here (only 1 Reader). Use instead: `releaseWrite` of `W1` notifies R; R is requeued; `W2` reacquires the monitor and inside `acquireWrite` finds predicate `readersTurn(true)|| writing(false)=true` and `wait()`s; some `releaseRead`... — actually with only 1 Reader, the standard hijacked-signal trace is: R wakes when a Writer releases, by the time R re-enters the monitor a fresh writer `W3` has acquired (e.g. via an `acquireWrite` call sandwiched in by the unfair scheduler before R) and set `writing=true`; with `if`, R does **not** retest and proceeds to `++readers`. State: `readers=1`, `writing=true` — concurrent read and write. (D) holds.
- The original safety bug also helps: `acquireWrite` doesn't check `readers>0`, so a symmetric trace works in the other direction too.

(B) **The only Reader can starve — TRUE.**

- Under the unfair scheduler, R may simply lose every monitor-acquisition race against the 10 Writers in `releaseWrite`'s post-`notifyAll` runnable set, indefinitely. R never executes its single `if`, so it never increments `readers`, so it never gets to read. (This is a per-thread starvation argument — but R is *the only* Reader, so there is no other reader to "cover" for it. Standard unfair-scheduling starvation.)

(C) **All Writers can starve — FALSE.** Writers progress (they keep alternating; the alternation is in fact stronger now because if R goes through it's only briefly).

(A) **Deadlock — FALSE.** There is always at least one Writer eligible to proceed at the start of each round (after `releaseWrite`/`releaseRead` events fire `notifyAll`). The system as a whole does not freeze.

Since both (B) and (D) can occur, the correct option is **E**.

---

## Q6d. Replace `notifyAll()` with `notify()` in `releaseWrite`

**Answer: C (A deadlock can occur if there are at least two Writers).**

`notify()` wakes exactly *one* arbitrary waiter. This is dangerous for *hijacked signals*: if `releaseWrite` notifies a Writer who then has to re-`wait()` (because `readersTurn=true`), the wake-up is wasted and no further `notify` fires.

Trace with **two Writers, zero Readers**:

1. W1 acquires: `numWaitingWriters` goes 0→1→0 inside `acquireWrite`, then `writing=true`.
2. W2 calls `acquireWrite`: `numWaitingWriters=1`, predicate `readersTurn(false) || writing(true) = true` → `wait()`.
3. W1 calls `releaseWrite`: `writing=false`, `readersTurn=true`, **`notify()`** → wakes W2.
4. W2 re-checks its `while`: `readersTurn(true) || writing(false) = true` → `wait()` again.
5. W1 loops, calls `acquireWrite`: `numWaitingWriters=2`, predicate `readersTurn(true) || writing(false) = true` → `wait()`.
6. Both Writers are now `wait()`ing on the monitor; no Reader exists to ever call `releaseRead` (which would flip `readersTurn` to `false` and `notifyAll`). **No further `notify` will ever fire.**
7. **Deadlock** in the LORE sense: every thread is blocked on the same condition with no remaining notifier.

Hence two Writers (and *any* number of Readers, including zero) suffice for a deadlock to be possible.

Why not the others:

- **A** — Deadlock can occur, as shown.
- **B ("at least one Writer or Reader")** — With 1 Writer and 0 Readers, the Writer just acquires-releases-acquires-releases; no one ever `wait()`s, no deadlock. With 0 Writers, `releaseWrite` is never called so the modification is inert. So 1 thread is insufficient.
- **D ("at least two Readers")** — Readers don't trigger the bug; only `releaseWrite`'s `notify` is the changed call, and the bug needs a Writer to be re-`wait()`ed after being singled out. With only Readers, `releaseWrite` is never invoked.
- **E ("regardless of number")** — overstated; needs at least 2 Writers as shown.
- **F** — C fits.


---

