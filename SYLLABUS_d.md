# COMP0008 — Computer Architecture and Concurrency: Syllabus

## Overview

The module is split 5/5 between **Computer Architecture** (weeks 1–5) and **Concurrency** (weeks 6–10).

**Assessment:** 3 courseworks (10% each), final open-book assessment (70%).

**Textbooks:**
- Architecture: Patterson & Hennessy — *Computer Organization and Design* (MIPS ed., 4th ed.) [**P&H**]
- Concurrency: Goetz et al. — *Java Concurrency in Practice* [**GPBBHL**]
- Optional architecture: Harris & Harris — *Digital Design and Computer Architecture*

---

## Part I — Computer Architecture

### Week 1 — Foundations: Number Systems, von Neumann, and Concurrency Motivation

- **Course structure.** Architecture half: MIPS32 ISA, pipelining, memory hierarchy, OS/processes. Concurrency half: Java concurrency, JMM, locks, monitors, `java.util.concurrent`.

- **Number systems.** Binary, decimal, hexadecimal. Positional notation. Prefixes: `0b`, `0`, `0x`. Conversion between bases (greedy algorithm for decimal→binary).

- **Two's complement.** For N bits: $x = -x_{N-1} \cdot 2^{N-1} + \sum_{i=0}^{N-2} x_i 2^i$. Single zero representation, arithmetic works for signed/unsigned transparently. Sign extension preserves value.

- **Unsigned/signed ranges.** Unsigned $n$-bit: $[0, 2^n-1]$. Signed $n$-bit: $[-2^{n-1}, 2^{n-1}-1]$.

- **Overflow detection.** In two's complement: (pos)+(neg) never overflows. (pos)+(pos) → result negative = overflow. (neg)+(neg) → result positive = overflow.

- **Memory organisation.** Bit → Byte (8 bits) → KB ($2^{10}$) → MB ($2^{20}$) → … Word = 32 bits on MIPS32. Endianness: big-endian (MSB at lowest addr) vs little-endian (LSB at lowest addr).

- **Von Neumann architecture.** CPU, memory (instructions + data stored together), I/O devices connected by address/data/control buses.

- **CISC vs RISC.** CISC: complex instructions, microprograms, variable-length. RISC: simple, uniform, fixed-width, load/store architecture. MIPS is RISC.

- **Abstraction layers.** 5: High-level language → 4: Assembly → 3: OS → 2: ISA → 1: Microprogram → 0: Digital logic.

- **Flynn's taxonomy.** SISD, SIMD (GPUs), MISD (rare), MIMD (multicore, distributed).

- **Motivation for concurrency.** Sequential vs concurrent programs. "Too Much Milk" problem (race condition on shared state). Therac-25 case study (concurrency bugs killed patients). Java visibility puzzles: Holder (`n != n` can be true), Terminator (non-`volatile` boolean never seen by other thread). Interleaved concurrency vs true parallelism.

---

### Week 2 — MIPS32 ISA: R-Type Instructions, Machine Code, and Memory

- **Little Man Computer (LMC).** Simplified von Neumann model: PC, IR, MAR, accumulator, RAM. Illustrates fetch-execute and stored-program concepts.

- **CPU–Memory interaction.** MAR, MDR, PC, IR, Control Unit. Address bus, data bus, control signals (MEMR, MEMW).

- **Bus hierarchy.** Backside bus (CPU↔cache), external CPU bus, PCI bridge, AGP, ISA. Programmer sees a simpler abstract view: CPU + Memory + I/O via address/data/control buses.

- **MIPS32 basics.** 32 general-purpose registers ($0–$31), $0 hardwired to 0. Load/store architecture: all ALU ops on registers only; memory access only via `lw`/`sw`. Fixed 32-bit instructions. 6-bit opcode, 26-bit arguments.

- **R-type format.** `opcode(6) | rs(5) | rt(5) | rd(5) | shamt(5) | funct(6)`. `R[rd] = func(R[rs], R[rt])`. Opcode = `000000`. Examples: `add` (funct=0x20), `sub` (0x22), `and` (0x24), `or` (0x25), `xor` (0x26), `nor` (0x27), `slt` (0x2A), `sltu` (0x2B).

- **Shift instructions.** R-type with rs=0, shamt = shift amount. `sll` (funct=0x00): multiply by $2^k$. `srl` (0x02): logical right shift (fill 0s). `sra` (0x03): arithmetic right shift (replicate sign bit = divide by $2^k$ for signed).

- **Bitwise operations.** AND, OR, XOR, NOR — independent per bit.

- **Pseudo-instructions.** Not real HW instructions; translated by assembler. `move $d, $s` → `add $d, $s, $0`. `not $d, $s` → `nor $d, $s, $0`.

- **Sign extension vs zero extension.** Sign-extend (replicate msb) for signed values. Zero-extend for unsigned/positive values.

- **Endianness in practice.** Affects type-casting multi-byte values.

---

### Week 3 — MIPS32 ISA: I-Type Instructions, Branches, and Memory Access

- **Fetch/execute cycle.** 1. PC→address bus. 2. Assert read. 3. Memory returns 32-bit instruction. 4. Execute. 5. PC ← PC+4.

- **I-type format.** `opcode(6) | rs(5) | rt(5) | immediate(16)`. General: `R[rt] = func(Imm, R[rs])`.

- **Arithmetic immediate.** `addi $rt, $rs, imm` — sign-extends the 16-bit immediate. `addiu` — also sign-extends, but no overflow exception. No `subi`; use negative immediate.

- **Memory addressing.** Single mode: `displacement(base)` → addr = `R[rs] + SignExtImm`. `lw` (op=0x23), `sw` (op=0x2B) — require word-aligned addresses. `lb`/`sb`, `lh`/`sh` (half-word aligned). Unsigned variants: `lbu`, `lhu`.

- **Loading large constants.** 16-bit immediate field is insufficient for 32-bit values. `lui $rt, imm` — load upper 16 bits (lower zeroed). `ori $rt, $rs, imm` — fill lower bits. Pseudo-instruction `li` expands to `lui` + `ori`.

- **Branch instructions.** PC-relative addressing. `beq $rs, $rt, label` (op=4), `bne $rs, $rt, label` (op=5). BranchAddr = SignExtImm << 2; NewPC = PC+4 + BranchAddr. Range: ±128 KB.

- **Set-and-branch pattern.** `slt $rt, $rs, $rt2` (signed), `sltu` (unsigned). `slti`/`sltiu` (immediate). Follow with `beq`/`bne` vs `$0`. Pseudo: `bgt`, `bge`, `ble`, `blt`.

- **Branch vs zero:** `bgez`, `bgtz`, `blez`, `bltz`. `bgez` and `bltz` share opcode=1, distinguished by `rt`.

- **Loop efficiency.** Counting down to zero is more efficient — `bgtz` compares directly against zero, avoiding a separate `slt` and limit register. Count-up: 6 instr/iter; count-down: 4 instr/iter.

- **Bit-field extraction.** Mask with `lui` + `and`, then `srl` by bit position to isolate a field.

- **Overflow-safe unsigned average.** $\frac{x+y}{2} = (x \mathbin{\&} y) + \frac{x \oplus y}{2}$. No overflow possible.

---

### Week 4 — High-Level Constructs in MIPS: Arrays, Control Flow, Functions, Stack

- **Register conventions.**
  - `$zero` (0): always 0.
  - `$at` (1): assembler temporary.
  - `$v0–$v1` (2–3): return values.
  - `$a0–$a3` (4–7): function arguments.
  - `$t0–$t7` (8–15): temporaries (caller-saved).
  - `$s0–$s7` (16–23): saved (callee-saved).
  - `$t8–$t9` (24–25): more temporaries.
  - `$k0–$k1` (26–27): OS kernel.
  - `$gp` (28): global pointer.
  - `$sp` (29): stack pointer (grows downward).
  - `$fp` (30): frame pointer.
  - `$ra` (31): return address.

- **Arrays.** Base address + byte offset: `lw $t, offset($base)`. Element i at offset `4*i` (word array). Use `sll` for multiplication by power of 2 (e.g. `x*2`).

- **J-type format.** `opcode(6) | address(26)`. `j target` (op=2): NewPC = `(PC+4)[31:28] || JA || 00`, where JA = target/4. Limited to same 256 MB region.

- **Jump register.** `jr $rs` (R-type, funct=0x08): PC ← R[rs]. `jalr $rs`: also saves PC+4 to `$ra`.

- **Control flow in MIPS.** `if/else`: branch on negated condition, fall through to if-body, jump past else-body. `while`: initialisation, test-at-top, body, backward jump. `for`: same structure as while.

- **Function calls.** `jal target`: `$ra ← PC+4; PC ← target`. Return via `jr $ra`. Nested calls: `$ra` is overwritten — must save to stack.

- **Caller-save vs callee-save.** Caller-save (`$t` regs): caller saves before call. Callee-save (`$s` regs): callee saves and restores in prologue/epilogue.

- **Stack frames.** MIPS memory layout: Reserved (low) → Text (`0x00400000`) → Static data (`0x10000000`, `$gp` = `0x10008000`) → Heap (↑) … Stack (↓, `$sp` = `0x7ffffffc`).

- **Prologue:** `addiu $sp, $sp, -N; sw $ra, (N-4)($sp); sw $fp, (N-8)($sp); sw saved regs; addiu $fp, $sp, N-4`.

- **Epilogue:** `lw saved regs; lw $ra; lw $fp; addiu $sp, $sp, N; jr $ra`.

- **$ra overwrite bug.** Nested `jal` overwrites `$ra` before old value is saved → infinite loop on return. Fix: save `$ra` to stack before nested call, restore after.

---

### Week 5 — GCC Toolchain, Exceptions, Characters, and Floating-Point

- **MIPS toolchain.** Compiler (`.c` → `.s`) → Assembler (`.s` → `.o`) → Linker (`.o` + libs → `a.out`) → Loader (OS loads into RAM per memory map).

- **MIPS memory map (full).** Kernel space (`0x80000000`–`0xFFFFFFFF`) above user space. `$sp` at `0x7FFFFFFC`. Heap grows upward from `0x10010000`. Static data from `0x10000000`. Text from `0x00400000`.

- **Coprocessor architecture.** CP0 (traps/memory): BadVAddr, Cause, Status, EPC registers. CP1 (FPU): 32 FP registers `$f0`–`$f31`.

- **Exception handling.** Exception code → Cause register. PC → EPC. PC set to `0x80000080` (handler). Exception types: Int(0), AdEL(4), AdES(5), Sys(8), Bp(9), RI(10), Ov(12), Tr(13), FPE(15) etc.

- **System calls.** `syscall` instruction (machine code `0x0000000c`). Service code in `$v0`. Arguments in `$a0`–`$a3`. Key codes: print_int(1), print_string(4), read_int(5), exit(10).

- **Character encoding.** ASCII: 7-bit, codes 0–31 control, 32–127 printable. Extended ASCII: 8-bit, code pages. Unicode: up to 4 bytes, ~145K chars. UTF-8: variable-length, backward-compatible with ASCII. C strings: null-terminated byte sequence.

- **IEEE 754 floating-point.** Single precision: 1 sign, 8 exponent, 23 fraction. Bias = 127. Value (normal) = $(-1)^S \times 2^{E-B} \times 1.F$. Subnormal (E=0): $(-1)^S \times 2^{-126} \times 0.F$. Special (E=255): ±∞ (F=0), NaN (F≠0).

- **Double precision.** 1 sign, 11 exponent, 23+29 fraction. Bias = 1023.

- **MIPS FPU instructions.** `lwc1`/`swc1` for FP load/store. `add.s`, `sub.s`, `mul.s`, `div.s` (single). `add.d`, `mul.d` etc. (double, use even register pairs). `cvt.s.w` etc. for type conversion. `mtc1`/`mfc1` for CPU↔FPU register transfer.

---

## Part II — Concurrency

### Week 6 — Hardware Concurrency: Pipelining and Caches

*Slides: week_06. Reading: P&H 4.1, 4.5, 5.1–5.3. Further: P&H 4.2–4.4, 4.6–4.7, 4.10.*

- **C-to-MIPS execution.** Load operands into registers, compute, store result. Each high-level statement typically maps to 2–4 MIPS instructions.

- **Five-stage pipeline.** IF (instruction fetch) → ID (decode/register read) → EX (ALU execute) → MEM (data memory) → WB (write-back). Throughput ≈ 1 instruction/cycle after pipeline fill. Non-pipelined: $5n$ cycles. Pipelined: $n+4$ cycles.

- **Data hazards.** Dependence between instructions where result not yet available. **Forwarding (bypassing):** route result directly from pipeline register output to ALU input, bypassing WB. **Load-use hazard:** forwarding can't help (data not yet read from memory) → stall with 1 NOP bubble.

- **Instruction reordering.** Compiler/program can move independent instructions into NOP slots to eliminate stalls. Compiler/CPU can reorder — programmer cannot assume in-order execution.

- **Memory hierarchy.** Main memory ~100 cycles. Caches ~1 cycle. Exploits **temporal locality** (re-access soon) and **spatial locality** (nearby data accessed soon).

- **Cache internals.** Address decomposed: tag | set index | byte offset. Each cache entry: V (valid bit), Tag, Data block. Hit: tag match AND V=1.

- **Cache design parameters.** Direct-mapped (1-way), set-associative (N-way), fully-associative. Block size. Write-through vs write-back. Write-allocate vs no-write-allocate. Replacement policy (LRU). Multi-level (L1, L2, L3).

- **Cache performance.** AMAT = hit time + miss rate × miss penalty. Three Cs: compulsory (cold), capacity, conflict misses.

- **Cache coherence problem.** Multi-processor: each CPU has private cache. Write by CPU1 in its cache → CPU2's cache has stale value. Requires coherence protocol (e.g. snooping, write-invalidate).

- **Key lessons for programmers.** (1) Operations can be reordered. (2) Caching introduces uncertainty about value location/visibility. (3) Programmers can assume very little about HW execution order. (4) HW concurrency improves performance but risks correctness. (5) Sometimes performance must be sacrificed for correctness. (6) Synchronisation points are the universal tool for correctness.

---

### Week 7 — Concurrency Abstraction and Threads

*Slides: week_07. Reading: GPBBHL 1.1–1.2. Further: P&H 5.8 (cache coherence).*

- **Design tradeoffs.** Single process (simple, slow — 1 core), multiple processes (heavier resource use, IPC overhead), multiple threads (lightweight, shared memory, but race conditions).

- **Threads.** Lightweight processes sharing code, data, files; each has own registers, stack. OS scheduling unit. Run simultaneously on different cores.

- **Concurrency abstraction.** Each thread is a totally ordered sequence of **atomic actions**. An **interleaving** is a total order across all threads' actions where: (1) only one action at a time; (2) within-thread order preserved; (3) threads' actions arbitrarily interleaved. All interleavings can happen in different runs.

- **Interleaving counting.** Two threads with $X$ and $Y$ actions: $\frac{(X+Y)!}{X!Y!}$ (binomial coefficient). More threads → combinatorial explosion.

- **Interleaving analysis.** Programs like `T1={x=5; x=2*x}` and `T2={x=x+2}` produce different final values depending on interleaving of compound actions (each high-level statement decomposes into read+write). Different granularity of atomic actions yields different possible outcomes.

- **Implications.** (1) Combinatorial explosion → unpredictability, non-determinism. (2) Some interleavings rare → concurrency bugs are **latent** and **hard to uncover** with testing. (3) Must design well; static analysis doesn't scale.

- **Python's GIL.** CPython's Global Interpreter Lock prevents true parallelism for CPU-bound threads (only I/O-bound benefit). Use `multiprocessing` for CPU parallelism.

---

### Week 8 — Thread Safety and Synchronisation in Java

*Slides: week_08. Reading: GPBBHL 1.3, Ch.2. Further: GPBBHL 1.4.*

- **Thread safety.** A class is thread-safe if it behaves correctly under arbitrary interleaving with no additional synchronisation from callers. Formalised as pre-conditions, post-conditions, invariants.

- **Race conditions.** Incorrect computation occurring only in specific interleavings. Patterns: **check-then-act** (stale observation between check and action), **read-modify-write** (lost update from interleaved reads). Race condition ≠ data race (the former is about correctness, the latter about JMM ordering).

- **State.** An object's state = its internal data affecting externally visible behaviour (instance fields, static fields, dependent objects). Threads sharing and arbitrarily modifying state → **interference**.

- **Three strategies for shared mutable state:** (1) Don't share (thread confinement). (2) Make immutable. (3) Synchronise access.

- **Stateless objects are always thread-safe** (no shared state). Local/stack variables are thread-confined by nature.

- **Atomicity and compound actions.** `++count` is read-modify-write (3 operations, not atomic). `AtomicLong`/`AtomicReference` from `java.util.concurrent.atomic` provide atomic single-variable operations. Independent atomic variables do not compose into atomic compound actions.

- **Intrinsic locks (`synchronized`).** Every Java object has an intrinsic lock. `synchronized` block/method: acquire lock → execute → release. Guarantees mutual exclusion between blocks guarded by the same lock. Static `synchronized` uses the `Class` object.

- **Lock reentrancy.** A thread can re-acquire a lock it already holds (acquisition count + owning thread). Essential for subclass calling `super.synchronizedMethod()`.

- **Guarding state with locks.** Every shared mutable variable should be guarded by exactly one lock. All variables in a multi-variable invariant must share the same lock. `@GuardedBy` annotation documents this.

- **Lock granularity.** Coarse (synchronise whole method) = safe but sequential. Fine (synchronise only critical sections) = better concurrency. Exclude long-running ops from `synchronized` blocks. Trade-off: simplicity, safety, performance.

- **Encapsulation, immutability, documentation** are general-purpose tools that help thread safety.

- **`@ThreadSafe`, `@NotThreadSafe`, `@Immutable`, `@GuardedBy`** annotations for documenting intent.

---

### Week 9 — Visibility, Publication, JMM, and the Monitor Pattern

*Slides: week_09. Reading: GPBBHL 3 (excl. 3.3), 16 preamble–16.1.1, 4.2, 14.1–14.2. Further: GPBBHL 3.3, 16, 4.1, 4.3–4.4.*

- **Visibility problems.** One thread writes a value, another thread never sees it (or sees a partial/stale state). Reordering by compiler/JVM/CPU can make writes appear out of order to other threads. Synchronisation solves visibility because threads "synchronise working memories" at lock acquire/release.

- **Stale data.** Non-all-or-nothing: one variable up-to-date, another stale. Both getter AND setter must be synchronised.

- **Non-atomic 64-bit ops.** `long` and `double` reads/writes are not guaranteed atomic (word tearing). Must use `volatile` or a lock.

- **`volatile` variables.** Visibility guarantee (weaker than `synchronized` — no atomicity). Writing ≈ exiting `synchronized`, reading ≈ entering. Criteria for use: (1) writes don't depend on current value; (2) variable doesn't participate in invariants with others; (3) no locking needed for other reasons.

- **Publication and escape.** An object is *published* when made available outside its context. *Escape* is unintended publication. Partially constructed object published = hazard. Safe construction: don't let `this` escape during construction (no starting threads, no calling overridable methods in constructor). Use factory method pattern.

- **Safe publication idioms.** (1) Static initialiser. (2) `volatile` field or `AtomicReference`. (3) `final` field of properly constructed object. (4) Lock-guarded field.

- **Immutability.** Three conditions: unmodifiable state, all fields `final`, proper construction (no `this` escape). Immutable objects are inherently thread-safe. They can be safely accessed even without safe publication (initialisation safety guarantee).

- **Effectively immutable objects.** Not technically immutable but state doesn't change after publication. Need safe publication, then no further synchronisation needed.

- **Object type safety table:**

| Type | G1 (no partial construction) | G2 (see state changes) |
|------|:---:|:---:|
| Thread-local | ✔ | ✔ |
| Immutable (all final, proper construction) | ✔ | ✔ |
| Effectively immutable | Must be safely published | ✔ |
| Mutable | Must be safely published | Must be thread-safe or guarded |

- **Sharing policies.** (1) Thread-confined. (2) Shared read-only. (3) Shared thread-safe. (4) Guarded (by lock).

- **Java Monitor Pattern.** Encapsulate all mutable state; guard with object's intrinsic lock. All state-accessing methods `synchronized`. Trade-off: simplicity vs performance.

- **Conditional synchronisation.** When a thread cannot proceed (e.g. empty buffer), release lock and wait. Canonical pattern:
  ```
  acquire lock
  while (condition not met) {
      wait()  // releases lock, blocks, reacquires on wake
  }
  // perform action
  notifyAll()  // or notify()
  release lock
  ```
  `wait()`, `notify()`, `notifyAll()` are methods on `Object`. Lock object must equal condition queue object (usually `this`). Always `wait()` in a `while` loop (spurious wakeups, hijacked signals).

- **Condition predicates.** Three-way relationship: lock, `wait` method, condition predicate must all agree. Notifications signal "something changed", not *what* changed — re-check predicate.

- **`notify` vs `notifyAll`.** `notifyAll` is safe default. Single `notify` only safe when: uniform waiters + one-in-one-out (same condition predicate, each wakeup makes progress for exactly one waiter).

- **Missed signals.** Liveness failure: thread waits for condition that is already true but was never notified. Prevention: always test predicate before `wait()`.

---

### Week 10 — Liveness: Deadlock, Starvation, and Livelock

*Slides: week_10. Reading: GPBBHL Ch.10.*

- **Safety vs liveness.** Safety = nothing bad happens. Liveness = something good eventually happens. Locking can prevent liveness — a fully synchronised program may deadlock.

- **Deadlock.** All threads permanently blocked. Model: cycle in "is-waiting-for" directed graph. JVM deadlocks are unrecoverable (threads permanently lost).

- **Lock-ordering deadlocks.** Two threads acquire same two locks in opposite order. Example: `transferMoney(A,B)` vs `transferMoney(B,A)` both acquiring locks on `fromAcc` then `toAcc`. Fix: enforce consistent global lock ordering (e.g. by account ID).

- **Dynamic lock-order deadlocks.** Lock order depends on runtime arguments. Fix: use `System.identityHashCode` to order, with tie-breaking lock for hash collisions.

- **Cross-object deadlocks.** Implicit multi-lock acquisition across collaborating classes (e.g. `Taxi` ↔ `Dispatcher`). Alien method calls (calling external method while holding a lock) are dangerous.

- **Open calls.** Method invocations with no locks held. Primary design principle for deadlock avoidance (analogous to encapsulation for thread safety). Trade-off: may lose atomicity.

- **Resource deadlocks.** Deadlock on non-lock resources (e.g. database connection pools). Thread-starvation deadlock: task waiting for result from another task in same bounded thread pool.

- **Deadlock avoidance techniques:**
  1. Threads never acquire >1 lock at a time.
  2. Consistent lock ordering (document global protocol).
  3. Open calls across objects.
  4. Timed `tryLock` with back-off (probabilistic recovery).
  5. Detect-and-abort (database-style).

- **Deadlock diagnosis.** JVM thread dumps (`kill -3`/`Ctrl-\`): stack traces + lock info. JVM auto-detects cycles in wait-for graph.

- **Starvation.** Thread perpetually denied resources (CPU, lock). Causes: thread priorities, long-held locks. Avoid tweaking thread priorities (platform-dependent).

- **Poor responsiveness.** Long-held locks or CPU-intensive background threads competing with UI thread.

- **Livelock.** Thread not blocked but makes no progress — repeated failed retries. Examples: poison messages in transactional messaging, cooperative "hallway" yielding. Solution: randomisation and exponential back-off in retry mechanisms.

- **Missed signals (from Week 9).** Thread keeps waiting for condition already true. Prevention: always test predicate before calling `wait()`.

---

## Cross-Reference Index

### By Topic

| Topic | Slides | Readings |
|-------|--------|----------|
| Number systems, two's complement | W1, W2 | — |
| MIPS R-type instructions | W2 | — |
| MIPS I-type, branches, lw/sw | W3 | P&H 2 |
| Functions, stack, control flow | W4 | P&H 2 |
| Toolchain, exceptions, IEEE 754 | W5 | P&H A.7, B |
| Pipeline, forwarding, hazards | W6 | P&H 4.1, 4.5 |
| Cache fundamentals | W6 | P&H 5.1–5.3 |
| Concurrency abstraction, threads | W7 | GPBBHL 1.1–1.2 |
| Thread safety, locks, `synchronized` | W8 | GPBBHL 1.3, 2 |
| Visibility, `volatile`, publication | W9 | GPBBHL 3, 16(preamble) |
| JMM, happens-before | W9 | GPBBHL 16 |
| Monitor pattern, condition queues | W9 | GPBBHL 4.2, 14.1–14.2 |
| Deadlock, liveness | W10 | GPBBHL 10 |

### Key Concepts That Span Multiple Weeks

- **Two's complement**: W1 (definition) → W2 (overflow, extension) → W3 (sign-extension in `addi`/`lw`)
- **Endianness**: W1 (definition) → W2 (type-casting effects) → W5 (UTF-8/Unicode BOM)
- **Memory layout**: W2 (byte/word addressable) → W4 (stack/heap/text) → W5 (full map with kernel space)
- **Registers**: W2 (GPR set) → W3 ($0 as zero) → W4 (convention: $t, $s, $a, $v, $ra, $sp, $fp)
- **Pipeline → cache → coherence → reordering**: W6 progression from HW to programmer implications
- **Safety vs liveness**: W8 (race conditions = safety) → W10 (deadlock/starvation/livelock = liveness)
- **Visibility**: W1 (Holder/Terminator puzzles preview) → W6 (hardware caching cause) → W9 (JMM formal solution)
- **Thread safety strategies**: W8 (`synchronized`) → W9 (immutability, confinement, safe publication) → W10 (open calls for liveness)
