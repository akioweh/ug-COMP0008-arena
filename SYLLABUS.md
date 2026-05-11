# COMP0008: Computer Architecture and Concurrency — Conceptual Syllabus

This syllabus outlines a conceptually linked, 12-part learning progression. It bridges hardware physics to high-level
software safety, moving bottom-up from bits and processors to pipelines, memory, and ultimately thread coordination and
liveness in Java.

**How to use this for exam prep:**

1. The final assessment is the Term 3 exam (100% of the mark; no summatively assessed coursework).
2. The MIPS reference sheet (`materials/MIPS_cheat_sheet.pdf`) is the only additional material permitted in the exam.
   Topics on it (instruction list, register conventions, exception codes, IEEE 754, memory map, ASCII table) require
   application, not memorization. _(Note: Items marked with **(F)** are "Further" topics; they extend core knowledge but
   may be less central than unmarked "Essential" items.)_

---

## Part I: The Machine Layer (Computer Architecture)

_This section builds the computer from the ground up, starting with raw data and ending with processor optimization._

### 1. Information Representation

- **Number Systems:** Binary, Hexadecimal, and Base conversions.
- **Signed Numbers:** Two's Complement arithmetic and overflow detection.
- **Extension:** Sign extension vs. zero extension.
- **Data Types:** Floating-Point (IEEE 754: normal, subnormal, ±∞, NaN; bias and exponent encoding), Character & string
  encodings (ASCII, Unicode, UTF-8; null-terminated C strings), and Endianness.

### 2. The Von Neumann Model & Execution

- **Architecture History:** CISC vs. RISC philosophies, performance scaling eras; Flynn's taxonomy
  (SISD/SIMD/MISD/MIMD).
- **Von Neumann Architecture:** CPU, Memory, I/O, and Bus hierarchies.
- **Execution:** The Fetch-Execute cycle and the Stored-Program concept.
- **Abstraction Layers:** From digital logic up to high-level programming.

### 3. MIPS32 Instruction Set Architecture (ISA)

- **CPU Model:** 32 general-purpose registers, Program Counter (PC), Load/Store architecture.
- **Instruction Formats:** R-type (Register), I-type (Immediate), and J-type (Jump).
- **Operations:** ALU operations, memory addressing (base + displacement), and branching logic (PC-relative addressing
  for branches; pseudo-direct addressing for J-type).
  - Multiply/divide unit and Hi/Lo registers (mult, div, mfhi, mflo).
- **Bitwise & Shift Operations:** Logical vs. arithmetic shifts, masking.

### 4. Software-to-Hardware Translation

- **Control Flow:** Mapping high-level `if/else`, `while`, and `for` loops to assembly.
- **Memory Iteration:** Array and pointer arithmetic in MIPS.
- **The Call Stack:** Function calls, prologue/epilogue, and strict register conventions (`$a0-$a3`, `$t0-$t9`,
  `$s0-$s7`, `$sp`, `$ra`).
- **Pseudo-instructions:** Assembler translations (e.g., `li`, `move`, `bgt`) vs. native machine code.
- **Systems Level:**
  - The GCC Toolchain (compiler → assembler → linker → loader).
  - Memory map: text / static / heap / stack segments and their canonical addresses.
  - Exceptions: Coprocessor 0 (`Cause`, `EPC`, `BadVAddr`, `Status`) and the exception code table.
  - System Calls: `syscall` instruction; service number in `$v0`; common services (`print_int`, `read_int`,
    `print_string`, `exit`).
- **Floating-point execution:** Coprocessor 1 (FPU):
  - Registers `$f0`–`$f31`.
  - Arithmetic: `add.s`/`.d`, `sub`, `mul`, `div`.
  - Conversions: `cvt.*`.
  - Memory ops: `lwc1`, `swc1`, `mtc1`.

### 5. Processor Pipelining

- **Performance metrics:** CPU time, clock cycles per instruction (CPI), throughput vs. individual-instruction latency.
- **Datapath & Control:** Single-cycle limitations vs. the 5-stage pipeline (IF, ID, EX, MEM, WB).
- **Pipeline Hazards:** Structural, Data, and Control hazards.
- **Hazard Solutions:** Forwarding/bypassing, pipeline stalls (bubbles), and branch prediction.
- **Advanced ILP:** Instruction-Level Parallelism (Multiple issue, Superscalar, Loop Unrolling). **(F)**

### 6. Memory Hierarchy & Caching

- **Memory Foundations:** The Principle of Locality (Temporal and Spatial).
- **Cache Geometries:** Tag/Index/Offset, Direct-mapped, Set-associative, Fully-associative.
- **Cache Policies:** Write-through vs. Write-back, LRU replacement.
- **Performance:** Calculating Average Memory Access Time (AMAT).

---

## Part II: The Concurrency Layer (Java & Multithreading)

_This section explores how to safely write software when multiple processors or threads access memory simultaneously._

### 7. Concurrency Foundations & Hardware Coherence

- **The Hardware Bridge:** Multiprocessor Cache Coherence (Snooping, Write-invalidate) and False Sharing. **(F)**
- **Server design tradeoffs:** single-process vs. multi-process vs. multi-threaded models; resource cost vs. throughput
  vs. correctness risk.
- **Threads vs. Processes:** OS scheduling, shared memory vs. isolated state.
- **Execution Models:** Interleaving analysis, non-deterministic execution, and combinatorial explosion.

### 8. Thread Safety & Atomicity

- **Hazards:** Race conditions (Check-then-act, Read-modify-write).
- **Mutual Exclusion:** Intrinsic locks (`synchronized`) and lock reentrancy.
- **Guarding State:** The single-lock rule for multi-variable invariants.
- **Performance:** Lock granularity trade-offs and atomic variables (`java.util.concurrent.atomic`).
- **Worked example:** the Caching Factoriser servlet's 5-iteration progression: stateless → broken cache → coarse
  `synchronized` method → fine-grained `synchronized` blocks → refactored helper methods.

### 9. Memory Visibility & The Java Memory Model (JMM)

- **Visibility Goals:** G1 (no thread observes a partially constructed object); G2 (all threads observe state changes).
- **The Problem:** Hardware/Compiler reordering, stale data, and visibility puzzles (_The Terminator_, _The Holder_).
- **The `volatile` Keyword:** Visibility guarantees without atomicity.
- **The JMM:** the rules governing inter-thread visibility and ordering:
  - Sequential consistency as the JMM's idealised baseline (and why it is relaxed in practice).
  - The _Happens-Before_ partial order across program order, monitor lock, `volatile`, and thread start/join. **(F)**
  - Formal definition of a data race. **(F)**
- **Piggybacking:** Using existing happens-before edges for visibility. **(F)**

### 10. State Management & Object Publication

- **Object Classification:** local, immutable, effectively immutable, mutable — and the publication & synchronization
  obligations of each.
- **Publication & Escape:** Escaping references and the dangers of partial construction (`this` escape).
- **Initialization Patterns:** Why _Double-Checked Locking_ is broken, and the safe _Lazy Initialization Holder Class_
  idiom. **(F)**
- **Immutability:** `final` field semantics and initialization safety guarantees.
- **Safe Publication Idioms:** four mechanisms that publish an object's reference together with its state:
  - Static initialiser.
  - `volatile` field or `AtomicReference`.
  - `final` field of a properly constructed object.
  - Field guarded by a lock.
- **Encapsulation Patterns:** confining mutable state to control how it is accessed:
  - The Java Monitor Pattern: state guarded entirely by the object's intrinsic lock.
  - Thread/Stack confinement (e.g., `ThreadLocal`). **(F)**
  - Ad-hoc confinement. **(F)**

### 11. Thread Cooperation & State Dependence

- **State-Dependent Operations:** Implementing blocking preconditions.
- **Condition Queues:** Utilizing `wait()`, `notify()`, and `notifyAll()`.
- **Wait/Notify Discipline:** two rules that all condition waits must obey:
  - The condition predicate is guarded by the same lock held when calling `wait`/`notify`.
  - The lock object and the condition-queue object must be the same object.
- **The Wait/Notify Protocol:** Handling spurious wakeups, missed signals, and hijacked signals.
- **Condition Predicates:** Proper looping structures for waiting.

### 12. Liveness Hazards & Robustness

- **Deadlock:** Cyclic waiting, Lock-ordering, Dynamic lock-ordering, and Cooperating object deadlocks.
- **Prevention Strategies:** Global lock hierarchies and the principle of _Open Calls_.
- **Other Hazards:** Thread starvation and Livelock.
- **Classic Problems:** _The Dining Philosophers_ (deadlock), _Readers-Writers_ (starvation), _transferMoney_ (dynamic
  lock-ordering), _WifiLink_ (livelock).

