# COMP0008 — Computer Architecture and Concurrency: Syllabus

> Definitive topic list for exam revision. Covers all lecture content (weeks 1–10) and essential/further readings.
> Sources: lecture slides, P&H (Patterson & Hennessy), GPBBHL (Goetz et al.).

---

## Part I — Computer Architecture (Weeks 1–5)

### Week 1 — Foundations

**Concurrency motivation**
- Sequential vs concurrent programs; determinism vs non-determinism
- Interleaved concurrency (single core, time-sharing) vs true parallelism (multiple cores)
- Race conditions on shared state (the "too much milk" problem; Therac-25 case study)
- Why concurrent programming is required: performance, throughput, responsiveness, structure, embedded systems, distributed systems
- Flynn's taxonomy: SISD, SIMD, MISD, MIMD

**Architecture motivation**
- Von Neumann stored-program architecture: CPU, memory (instructions + data), I/O
- CISC vs RISC; MIPS as a RISC exemplar
- Performance scaling eras and the shift to multicore
- Abstraction layers: high-level language → assembly → ISA → microarchitecture → digital logic

**Number systems**
- Positional notation; binary, hexadecimal, octal; inter-base conversion
- Binary arithmetic: addition, multiplication, shifting
- Two's complement: representation, single zero, transparent arithmetic, sign extension
- Sign-magnitude (limitations) vs two's complement (advantages)
- Interpretation is context-dependent (same bits → different meaning)

### Week 2 — The Machine Model and MIPS32 Fundamentals

**Von Neumann architecture in detail**
- CPU components: control unit, ALU, PC, IR, MAR, MDR, general-purpose registers
- Address bus, data bus, control bus; bus hierarchy in a real PC
- Little Man Computer analogy

**Memory organisation**
- Byte-addressability; words (32-bit in MIPS32)
- Big-endian vs little-endian byte order and its implications
- Signed/unsigned integer ranges; overflow detection in two's complement
- Sign extension vs zero extension

**MIPS32 ISA — R-type instructions**
- 32 registers ($0–$31); $0 hardwired to zero; RISC load/store constraint
- Fixed 32-bit instruction width; 6-bit opcode + 26 bits of arguments
- R-type format: opcode | rs | rt | rd | shamt | funct
- Instructions: add, sub, and, or, xor, nor, slt, sltu, sll, srl, sra
- Shift operations as multiplication/division by powers of 2
- Pseudo-instructions: move, not (implemented via real instructions)
- Compilation is non-unique; assembly ↔ machine code is unique (disassembly)

### Week 3 — MIPS32 ISA: I-Type, Loads/Stores, Branching

**I-type instructions**
- Format: opcode | rs | rt | 16-bit immediate
- addi, addiu (sign-extended immediate; "unsigned" = no overflow exception)
- No subtract-immediate; negation via sign-extended immediate

**Memory access**
- Base + displacement addressing: `displacement($base)`
- lw, sw (word-aligned); lb/sb, lh/sh (byte/halfword); unsigned load variants (lbu, lhu)
- Loading 32-bit constants: lui + ori (pseudo: li)

**Branching**
- beq, bne: PC-relative addressing; BranchAddr = sign-extend(imm) << 2; target = PC+4 + BranchAddr
- Comparison with zero: bgez, bgtz, blez, bltz
- Pseudo-branch instructions (bgt, bge, ble, blt) expand to slt + bne/beq
- slti, sltiu for compare-and-branch patterns
- Loop efficiency: counting down to zero eliminates slt + register for limit

**Worked patterns**
- Bit-field extraction (mask + shift)
- Overflow-safe unsigned average via (x & y) + ((x ^ y) >> 1)

### Week 4 — High-Level Constructs and the Stack

**Register conventions**
- $a0–$a3 (arguments), $v0–$v1 (return values), $ra (return address)
- $t0–$t9 (caller-saved temporaries), $s0–$s7 (callee-saved)
- $gp, $sp, $fp, $k0–$k1, $at

**Control flow compilation**
- if/else → branch-on-negated-condition + jump
- while/for → test-at-top loop with backward jump

**J-type instructions**
- j: 26-bit address, target = PC+4[31:28] | JA | 00; limited to same 256 MB region
- jal: $ra ← PC+4, then jump (function call)
- jr $ra: return from function (R-type)
- jalr: jump-and-link via register

**Functions and the stack**
- jal / jr $ra mechanism; $ra overwrite bug in nested calls
- Caller-save ($t) vs callee-save ($s) conventions
- MIPS memory layout: text (0x00400000), static data, heap (grows up), stack (grows down from 0x7FFFFFFC)
- Stack frame (prologue/epilogue): save $ra, $fp, callee-saved regs, arguments; allocate locals
- Frame pointer ($fp) as stable reference; access arguments/locals relative to $fp

### Week 5 — GCC Toolchain, System Calls, Data Types

**Toolchain**
- Compilation pipeline: C → assembly (.s) → object (.o) → executable (linker) → loaded into memory (loader)
- Real gcc output vs textbook MIPS: PIC, $gp, nop for pipeline hazards
- Disassembly with objdump -S

**Coprocessors and exceptions**
- Coprocessor 0 (exceptions/memory): BadVAddr, Cause, Status, EPC registers
- Coprocessor 1 (FPU): 32 FP registers ($f0–$f31)
- Kernel space (0x80000000+); exception handler at 0x80000080
- Exception mechanism: Cause ← code, EPC ← PC, PC ← 0x80000080
- Exception types: interrupt, address error, bus error, syscall, breakpoint, overflow, etc.

**System calls**
- syscall instruction (exception code 8); $v0 = call number, $a0–$a3 = arguments
- Common calls: print_int (1), print_string (4), read_int (5), exit (10)

**Character and string representation**
- ASCII (7-bit, 128 chars); control characters; bit-manipulation tricks (force uppercase, toggle case)
- Extended ASCII, ISO variants, Unicode (UTF-32, UTF-8 variable-length encoding)
- C strings: null-terminated byte arrays

**Floating-point representation (IEEE 754)**
- Single precision (32-bit): sign (1) | exponent argument (8, bias 127) | fraction (23)
- Value = (-1)^sign × 2^(EA-127) × 1.fraction (normal); range ≈ 2^-126 to 2^128
- Subnormals (EA=0): 0.fraction × 2^-126; smallest positive ≈ 2^-149
- Special values: ±∞ (EA=255, frac=0), NaN (EA=255, frac≠0); NaN ≠ NaN
- Double precision (64-bit): 11-bit exponent (bias 1023), 52-bit fraction
- FPU instructions: add.s/d, sub.s/d, mul.s/d, div.s/d; lwc1/swc1/mtc1; cvt conversions

---

## Part II — Concurrency (Weeks 6–10)

### Week 6 — Pipelining and Caches

**Pipelined execution** *(slides + P&H 4.1, 4.5)*
- Five-stage pipeline: IF (instruction fetch) → ID (decode/register read) → EX (ALU) → MEM (data memory) → WB (write-back)
- Throughput improvement: ~n+4 cycles for n instructions (vs 5n without pipelining)
- MIPS is pipeline-friendly: fixed-length instructions, few formats, load/store architecture

**Pipeline hazards** *(P&H 4.5)*
- **Structural hazards**: resource conflict (e.g. single shared memory for instructions and data)
- **Data hazards**: instruction depends on result of a prior instruction still in the pipeline
  - Forwarding/bypassing: route result from pipeline register output directly to ALU input
  - Load-use hazard: forwarding insufficient (data not yet read from memory); requires 1-cycle stall (NOP/bubble)
  - Instruction reordering to fill stall slots
- **Control hazards**: branch outcome not known until later stage
  - Assume branch not taken; flush if wrong
  - Branch prediction: static, dynamic (1-bit, 2-bit predictors)
  - Delayed branch

**Further: detailed pipeline hardware** *(P&H 4.2–4.4, 4.6, 4.7)*
- Single-cycle vs pipelined datapath design; pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
- Forwarding unit and hazard detection unit hardware
- Control signal propagation through pipeline stages
- ALU control design; main control unit (opcode → control signals)

**Further: instruction-level parallelism** *(P&H 4.10)*
- Multiple issue: static (VLIW) and dynamic (superscalar)
- Speculation; loop unrolling; register renaming (eliminating anti-dependences)
- Out-of-order execution: reservation stations, reorder buffer, in-order commit

**Memory hierarchy and caches** *(slides + P&H 5.1–5.3)*
- Principle of locality: temporal (recent data reused) and spatial (nearby data accessed soon)
- Memory hierarchy: registers → L1 cache → L2 → L3 → main memory → disk
- Cache operation: hit (fast, ~1 cycle) vs miss (fetch from lower level, ~100 cycles for main memory)
- Cache organisation: sets × ways; each way holds V (valid) + tag + data block
- Address decomposition: tag | set index | byte offset
- Cache types by associativity: direct-mapped (1-way), n-way set-associative, fully associative
- Replacement policy: LRU, random
- Write policy: write-through (immediate propagate) vs write-back (defer to eviction); write buffers
- Cache performance: AMAT = hit time + miss rate × miss penalty; multi-level caches (local vs global miss rate)
- Miss classification (3 Cs): compulsory, capacity, conflict

**Further: cache coherence** *(P&H 5.8)*
- Coherence problem in shared-memory multiprocessors: stale data in private caches
- Snooping protocols; write-invalidate mechanism
- False sharing
- Memory consistency models (brief)

### Week 7 — Concurrency Abstraction and Threads

**Processes vs threads** *(slides + GPBBHL 1.1–1.2)*
- Process: OS-allocated resources (code, data, files, registers, stack); heavyweight, expensive IPC
- Thread: lightweight; shares code/data/files with other threads in same process; own registers + stack; minimal scheduling unit
- Benefits of threads: exploit multiprocessors, simplicity of modelling (thread-per-task), async event handling, responsive UIs

**Risks of threads** *(GPBBHL 1.3)*
- Safety hazards: race conditions (read-modify-write, check-then-act)
- Liveness hazards: deadlock, starvation, livelock
- Performance hazards: context-switch overhead, synchronisation overhead (cache flushing, inhibited optimisations)

**The concurrency abstraction**
- Interleaving model: atomic actions from each thread; total order preserving per-thread order; arbitrary cross-thread mixing
- Not a perfect model (doesn't capture reordering, caching, timing) but useful for reasoning about interference
- Combinatorial explosion of interleavings; formula for 2 threads: C(X+Y, X) = (X+Y)! / (X! Y!)
- Non-determinism; latent bugs; testing is insufficient; design is essential

**Interleaving analysis**
- Decomposing compound statements into atomic actions (e.g. x=2*x → t=x; x=2*t)
- Possible outcomes depend on granularity of atomicity

**Further: threads everywhere** *(GPBBHL 1.4)*
- Implicit threading: JVM threads, TimerTask, servlets, RMI, Swing EDT
- Thread safety is "contagious" through frameworks

### Week 8 — Thread Safety and Locking

**Thread safety** *(slides + GPBBHL 2)*
- Definition: correct behaviour under arbitrary interleaving without external synchronisation
- Correctness = invariants + post-conditions never violated
- Stateless objects are always thread safe (stack-confined locals)

**Atomicity and race conditions** *(GPBBHL 2.2)*
- Race condition: correctness depends on timing/interleaving
- Patterns: check-then-act, read-modify-write (e.g. count++ = read + modify + write)
- Compound actions: sequences that must execute atomically
- java.util.concurrent.atomic: AtomicLong, AtomicReference (single-variable thread safety)
- Multiple independent atomics do not compose into atomic compound actions

**Intrinsic locking** *(GPBBHL 2.3)*
- `synchronized` keyword: blocks/methods guarded by an intrinsic (monitor) lock on an object
- Mutual exclusion: only one thread holds a given lock at a time
- Reentrancy: a thread can re-acquire a lock it already holds (per-thread acquisition count)
- Static synchronized methods lock the Class object

**Guarding state** *(GPBBHL 2.4)*
- Rule: every shared mutable variable must be guarded by exactly one lock; all accesses use that lock
- Multi-variable invariants: all participating variables must be guarded by the same lock
- @GuardedBy annotation
- Synchronising every method is neither sufficient (compound actions still racy) nor always desirable

**Liveness and performance** *(GPBBHL 2.5)*
- Coarse-grained locking (synchronised method) kills concurrency
- Narrow synchronized blocks: exclude long-running operations (factorisation, I/O)
- Tradeoff: simplicity vs performance vs safety
- Don't hold locks during lengthy computations or blocking I/O

**Iterative design example**
- SimpleFactorizer (stateless, safe) → CachingFactorizer (shared state, unsafe) → synchronized method (safe, slow) → fine-grained locking (safe, faster) → synchronised helper methods

### Week 9 — Visibility, Publication, and the JMM

**Visibility** *(slides + GPBBHL 3.1)*
- Visibility problem ≠ interference: one thread's writes may never be seen by another (too little interaction)
- Stale data; non-atomic 64-bit operations (long/double word tearing)
- Instruction reordering by compiler/hardware/JVM can make writes appear out of order to other threads
- Locking is a visibility mechanism: unlock of monitor M happens-before subsequent lock of M; all writes before unlock visible after lock

**Volatile variables** *(GPBBHL 3.1.4)*
- `volatile`: no reordering, no register/cache caching; write acts like exiting synchronized, read like entering
- Visibility without mutual exclusion; does not make compound operations (e.g. count++) atomic
- Correct use criteria: variable not in invariants with other variables, no locking needed for access, only used as a status/flag

**Publication and escape** *(GPBBHL 3.2)*
- Publication: making an object available to code outside its current scope
- Escape: unintended publication (e.g. `this` escape from constructor via inner class)
- Safe construction: don't publish `this` during construction; use private constructor + factory method

**Safe publication idioms** *(GPBBHL 3.5)*
- Four idioms: static initialiser; volatile/AtomicReference field; final field; lock-guarded field
- Unsafe publication can expose partially constructed objects (the Holder problem: n != n throws)

**Thread confinement** *(GPBBHL 3.3)*
- Ad-hoc, stack confinement (local variables), ThreadLocal
- Confined objects need no synchronisation

**Immutability** *(GPBBHL 3.4)*
- Immutable objects (unmodifiable state, all fields final, properly constructed) are inherently thread-safe
- final field semantics: JMM guarantees visibility of final fields once constructor completes (initialization safety)
- Effectively immutable objects: state doesn't change after publication; safe publication is sufficient

**Object sharing policy summary**

| Object type | G1: no partial construction | G2: state changes visible |
|---|---|---|
| Thread-local | Automatic | Automatic |
| Immutable (final fields, proper construction) | Guaranteed | Guaranteed |
| Effectively immutable | Requires safe publication | Guaranteed |
| Mutable | Requires safe publication | Requires synchronisation or thread-safe design |

**Java Memory Model** *(GPBBHL 16 preamble, up to 16.1.1 excluded)*
- JMM defines conditions under which writes by one thread are visible to reads by another
- Reasons writes may not be visible: compiler reordering, register allocation, out-of-order execution, cache write-back, processor-local caches
- Within-thread as-if-serial semantics; JMM does not enforce sequential consistency across threads
- Happens-before partial order over all program actions
  - Program order rule
  - Monitor lock rule (unlock h-b subsequent lock on same monitor)
  - Volatile variable rule (write h-b subsequent read)
  - Thread start rule, Thread termination rule (join)
  - Interruption rule, Finalizer rule
  - Transitivity
- Data race: variable accessed by multiple threads with ≥1 write and no happens-before between accesses
- A correctly synchronised program (no data races) exhibits sequential consistency

**The Java Monitor Pattern** *(GPBBHL 4.2)*
- Encapsulate all mutable state; guard with the object's intrinsic lock; all methods accessing state are synchronized
- Private lock object variant: encapsulates the lock, prevents client interference
- Instance confinement: wrap a non-thread-safe object in a thread-safe shell

**Conditional synchronisation** *(slides + GPBBHL 14.1, 14.2)*
- State-dependent operations: wait for a condition instead of failing
- Condition queues: every Java object is a condition queue
  - wait(): release lock, enter wait set, re-acquire lock on notification
  - notify(): wake one waiter; notifyAll(): wake all waiters
- Canonical form: `while (!predicate) { wait(); } ... notifyAll();`
- Lock object = condition queue object = object guarding the state variables
- Notifications signal "something changed", not what; waiters must re-check predicate
- Missed signals: waiting for an already-true condition; prevent by testing predicate before wait
- Waking too early: spurious wakeups, hijacked signals → always use while-loop, not if

**Further: designing thread-safe classes** *(GPBBHL 4.1, 4.3, 4.4)*
- Three-element design: identify state, identify invariants, establish synchronisation policy
- Delegating thread safety to thread-safe components; works only for independent state variables
- Adding functionality: modify original, extend, client-side locking (fragile), composition (robust)

**Further: JMM deep dive** *(GPBBHL 16.1.1+)*
- Platform memory models; memory barriers/fences
- Reordering examples (PossibleReordering)
- Piggybacking on synchronisation for visibility of additional variables
- Safe initialisation idioms: eager init, lazy-init holder class, double-checked locking (anti-pattern, broken without volatile)
- Initialization safety for final fields (freeze at constructor completion)

### Week 10 — Liveness Hazards

**Safety vs liveness**
- Safety: nothing bad happens (no invalid states)
- Liveness: something good eventually happens (progress is made)
- Synchronisation ensures safety but can compromise liveness

**Deadlock** *(slides + GPBBHL 10.1)*
- Definition: cyclic waiting dependency; all threads permanently blocked
- Lock-ordering deadlock: two threads acquire the same locks in opposite order (LeftRightDeadlock)
- Dynamic lock-order deadlock: order depends on runtime arguments (transferMoney); fix via System.identityHashCode ordering or natural keys
- Cross-object deadlock via alien method calls while holding a lock (Taxi/Dispatcher)
- Dining Philosophers as a classic deadlock scenario
- Resource deadlocks: cyclic acquisition of non-lock resources (e.g. two connection pools)
- Thread-starvation deadlock: task waiting for result of another task in same bounded pool

**Deadlock avoidance** *(GPBBHL 10.2)*
- Never acquire more than one lock at a time (simplest)
- Consistent global lock ordering
- Open calls: invoke external methods with no lock held; easier to verify ordering; caveat = possible loss of atomicity
- Timed tryLock with back-off (probabilistic avoidance)
- Thread dump analysis: JVM automatic cycle detection in is-waiting-for graph

**Starvation** *(GPBBHL 10.3.1)*
- Thread perpetually denied resources (CPU, locks)
- Causes: thread priorities, infinite-loop lock holders
- Readers–Writers problem: continuous readers can starve writers
- Poor responsiveness as lighter starvation (long-held locks)

**Livelock** *(GPBBHL 10.3.3)*
- Thread not blocked but cannot make progress (repeated failing retries)
- Poison message problem; cooperative mutual yielding (hallway analogy)
- Fix: randomised back-off in retry mechanism

**Incorrect conditional synchronisation**
- Missed signals: waiting for a condition that was already true
- Thread not woken up (no notify/notifyAll issued)
