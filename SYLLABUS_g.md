# COMP0008: Computer Architecture and Concurrency — Syllabus

*A definitive, information-efficient reference guide for exam revision, synthesising all lecture material and essential textbook readings.*

---

## Part I: Computer Architecture

### 1. Introduction, Number Systems, and Fundamentals (Weeks 1 & 2)
- **Motivation:** Sequential vs. Concurrent execution. True parallelism (multicore/GPU) vs. interleaved execution (time-sharing). Flynn’s Taxonomy (SISD, SIMD, MISD, MIMD).
- **Architecture History:** Babbage (Analytical Engine), Colossus, ENIAC, IBM 360 (ISA vs. implementation distinction), CISC vs. RISC processors.
- **Von Neumann Architecture:** Stored-program model (instructions and data share memory). CPU (Datapath + Control Unit), Memory, I/O, interconnected by Address, Data, and Control buses.
- **Number Representation:**
  - Binary, Decimal, Hexadecimal conversions.
  - **Two’s Complement:** Unified arithmetic for signed integers; single zero representation.
  - **Extension:** Zero-extension (unsigned) vs. Sign-extension (signed) when widening bit width.
  - **Overflow Detection:** Occurs when adding two numbers of the same sign produces a result of the opposite sign.
- **Memory Organisation:** Byte-addressable, 32-bit word. **Endianness:** Big-endian (MSB at lowest address) vs. Little-endian (LSB at lowest address).

### 2. MIPS32 Instruction Set Architecture (Weeks 3 & 4)
- **CPU Model:** Load/store architecture. 32 general-purpose registers (`$0` is hardwired to 0). PC (Program Counter).
- **Instruction Formats (Fixed 32-bit width):**
  - **R-type (Register):** `opcode` (6), `rs` (5), `rt` (5), `rd` (5), `shamt` (5), `funct` (6). Used for ALU ops (`add`, `sub`, `and`, `or`, `slt`, logical/arithmetic shifts).
  - **I-type (Immediate):** `opcode` (6), `rs` (5), `rt` (5), `imm` (16). Used for `addi`, memory access (`lw`, `sw` using base+displacement), branches (`beq`, `bne`). `lui` and `ori` to load 32-bit constants.
  - **J-type (Jump):** `opcode` (6), `target` (26). Target is shifted left by 2 and combined with upper 4 bits of PC+4.
- **Control Flow:** PC-relative branching for conditional loops (`beq`, `bne`). `bgtz` vs `slt`/`beq` combinations.
- **Function Calls:**
  - `jal target`: stores PC+4 in `$ra` and jumps. `jr $ra`: returns to caller.
  - **Register Conventions:** `$a0-$a3` (arguments), `$v0-$v1` (returns), `$t0-$t9` (caller-saved temporaries), `$s0-$s7` (callee-saved).
  - **The Stack:** Grows downward. `$sp` (stack pointer), `$fp` (frame pointer). Used for saving registers (prologue/epilogue) and local variables.

### 3. Toolchain, Memory Map, and Basic Data Types (Week 5)
- **Compilation Pipeline:** Compiler (`.c` → `.s`) → Assembler (`.s` → `.o`) → Linker (`.o` → `a.out`) → OS Loader.
- **Memory Map:** Kernel space (`0x80000000+`), Stack (grows down from `0x7FFFFFFC`), Heap (grows up from `0x10010000`), Static Data (`0x10000000`), Text/Code (`0x00400000`).
- **Exceptions & System Calls:** Handled by Coprocessor 0. `syscall` instruction transfers control to the kernel based on `$v0` value.
- **Data Types:** ASCII, Unicode (UTF-8). Strings as null-terminated byte arrays.
- **IEEE 754 Floating-Point:** 32-bit single precision. 1 sign bit, 8-bit biased exponent (bias 127), 23-bit fraction. Implicit leading `1.` for normal numbers. Subnormals (exponent=0), NaN/Infinity (exponent=255). Handled by Coprocessor 1 (FPU).

### 4. Processor Implementation, Pipelining & Memory Hierarchy (Week 6)
- **Datapath & Control:** Combinational vs. Sequential logic. Edge-triggered clocking. Single-cycle implementation is inefficient (clock cycle limited by longest instruction).
- **The Five-Stage Pipeline:** Fetch (IF), Decode (ID), Execute (EX), Memory (MEM), Write-back (WB). Improves throughput, not individual latency.
- **Hazards & Solutions:**
  - **Structural Hazards:** Resource conflicts (e.g., unified memory).
  - **Data Hazards:** Instruction depends on preceding result. Solved by **Forwarding (Bypassing)**. **Load-use hazards** require a 1-cycle **Stall** (pipeline bubble).
  - **Control Hazards:** Branch delays. Solved by stalling, branch prediction (static/dynamic), or delayed branches.
- **Advanced ILP:** Multiple issue (VLIW / superscalar), dynamic scheduling (out-of-order execution, reservation stations), speculation, loop unrolling, register renaming.
- **Memory Hierarchy & Caches:**
  - **Locality:** Temporal (reuse) and Spatial (nearby access).
  - **Cache Geometry:** Address divided into Tag, Index, Block/Byte Offset. Direct-mapped (1-way), Set-associative (N-way), Fully-associative.
  - **Write Policies:** Write-through vs. Write-back.
  - **Performance:** AMAT (Average Memory Access Time) = Hit Time + (Miss Rate × Miss Penalty). Reducing misses via associativity and multi-level caches.

---

## Part II: Java Concurrent Programming

### 5. Concurrency Fundamentals & Threads (Week 7)
- **Threads vs. Processes:** Processes isolate resources; threads are lightweight OS scheduling units sharing memory (code, data, heap) but retaining private PC, registers, and stacks.
- **Benefits:** Throughput via multi-core CPUs, overlapping I/O and computation, simplified modelling (thread-per-task), responsive UIs (e.g., AWT Event Dispatch Thread).
- **Concurrency Abstraction:** Execution as unpredictable interleaving of atomic actions. Combinatorial explosion of states prevents exhaustive testing.
- **Cache Coherence:** Multiprocessors maintain coherent shared memory via snooping or write-invalidate protocols. Mitigating **false sharing** (unrelated variables in the same cache block).

### 6. Thread Safety & Atomicity (Week 8)
- **Risks of Threads:** Safety (race conditions), Liveness (deadlock, starvation), Performance (context switching, synchronization overhead).
- **Implicit Threading:** Frameworks (Servlets, RMI, Swing, Timers) spawn threads, injecting concurrency requirements into user code.
- **Thread Safety Definition:** Behaving correctly under arbitrary interleaving without caller-side synchronization. Stateless objects are intrinsically thread-safe.
- **Race Conditions:** Occur when correctness depends on timing.
  - **Check-then-act:** e.g., lazy initialisation.
  - **Read-modify-write:** e.g., `count++`.
- **Atomicity & Locking:**
  - **Intrinsic Locks:** `synchronized` blocks/methods provide mutual exclusion. They act as reentrant monitor locks.
  - **Guarding State:** Every shared mutable variable must be guarded by exactly *one* lock. Multi-variable invariants require updating all related variables atomically under the *same* lock.
- **Performance Trade-offs:** Avoid coarse-grained locks (synchronizing entire methods) over lengthy computations. Shrink critical sections while keeping compound actions atomic.

### 7. Visibility, Publication & Immutability (Week 9)
- **Visibility:** Compiler/hardware reordering and CPU caches mean writes in one thread may not be visible to others. Synchronization forces visibility (flushes/invalidates caches).
- **The Java Memory Model (JMM):** Defines visibility via the **happens-before** partial order. Includes program order, monitor lock, `volatile`, and thread start/join rules.
  - **Piggybacking:** Using existing happens-before edges (e.g., in concurrent collections) to publish variables.
- **`volatile` Variables:** Ensure visibility and prevent reordering. They do *not* provide atomicity (e.g., `volatile count++` is unsafe).
- **Publication & Escape:**
  - **Escape:** Allowing an object to be referenced outside its intended scope (e.g., leaking `this` during construction).
  - **Safe Publication Idioms:** Ensures an object is fully constructed before visibility. Use static initializers, `volatile`/`AtomicReference` fields, `final` fields, or lock-guarded fields.
  - **Initialization Safety:** Objects with `final` fields are guaranteed visible and fully initialized across threads without explicit synchronization.
- **Immutability:** Unmodifiable state, all `final` fields, and `this` does not escape. Immutable objects are inherently thread-safe. **Effectively immutable** objects (not technically immutable but never modified after creation) only require safe publication.

### 8. Designing Thread-Safe Classes (Week 9)
- **Design Process:** 1. Identify state. 2. Identify invariants/post-conditions. 3. Establish a synchronization policy.
- **Thread Confinement:** Avoiding sharing entirely. Ad-hoc, Stack confinement (local primitives/references), and `ThreadLocal`.
- **Instance Confinement & Java Monitor Pattern:** Encapsulating all mutable state and guarding it with the object’s intrinsic lock (or a private lock object).
- **Delegating Thread Safety:** Passing safety responsibilities to underlying thread-safe components (e.g., `ConcurrentHashMap`). Fails if underlying components have interdependent multi-variable invariants.
- **Extending Thread-Safe Classes:**
  - **Client-side locking:** Synchronizing externally on the wrapped object's intrinsic lock (fragile).
  - **Composition:** Wrapping the object and applying the Monitor Pattern (robust).

### 9. State-Dependent Operations & Liveness (Weeks 9 & 10)
- **State-Dependent Operations:** Actions requiring a precondition (e.g., reading an empty buffer).
  - **Condition Queues:** Allows a thread to release a lock and sleep until notified.
  - **Wait/Notify Protocol:** Must be wrapped in a `while(predicate)` loop to handle spurious wakeups, missed signals, and hijacked signals.
  - **Rules:** The lock, the `wait()` invocation, and the condition predicate must all align. The lock and condition queue object must be the same instance. Prefer `notifyAll()` to avoid dropped signals unless specific criteria are met.
- **Deadlock:** Cyclic waiting for locks.
  - **Types:** Lock-ordering (inconsistent acquisition order), Dynamic lock-ordering (args dictate order), Cooperating objects, Resource deadlocks.
  - **Prevention/Diagnosis:** Enforce a strict global lock acquisition order. Use **open calls** (calling alien methods with no locks held). Detect via JVM thread dumps (is-waiting-for graphs) or use timed `tryLock`.
- **Other Liveness Hazards:**
  - **Starvation:** Perpetual denial of resources (e.g., CPU time, read/write lock biases). Do not tweak thread priorities.
  - **Livelock:** Threads actively failing and retrying in unison (e.g., poison messages, network collisions). Prevent via randomized exponential back-off.