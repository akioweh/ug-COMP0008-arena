# Reading List and Topics

This document is a companion to `ALL_SLIDES.md` for the concurrency half of the module. The lecture slides for weeks
6–10 are **not self-contained**; they assume the student has completed the essential readings from two textbooks.

- Week 6 draws on the architecture textbook (Patterson & Hennessey) for processor/cache foundations.
- Weeks 7–10 draw on the concurrency textbook (Goetz et al.) for Java concurrency theory and practice.
- The architecture half (weeks 1–5) is covered fully by the slides.

## Textbooks

- **P&H**: Patterson, Hennessey. _"Computer organization and design: the hardware/software interface"_
- **GPBBHL**: Goetz, Peierls, Bloch, Bowbeer, Holmes, Lea. _"Java concurrency in practice"_
- **OO**: Oracle Java Docs:
  [Lesson: Concurrency](https://docs.oracle.com/javase/tutorial/essential/concurrency/index.html)

---

## Reading List (Weeks 6–10)

### Week 6

- **Essential:** P&H 4.1, 4.5, 5.1, 5.2, 5.3
- **Further:** P&H 4.2, 4.3, 4.4, 4.6, 4.7, 4.10

### Week 7

- **Essential:** GPBBHL 1.1, 1.2
- **Further:** P&H 5.8, OO "Processes and Threads"

### Week 8

- **Essential:** GPBBHL 1.3, 2
- **Further:** OO "Thread Objects", OO "Synchronization", GPBBHL 1.4

### Week 9

- **Essential:** GPBBHL 3 (except 3.3), 16 preamble till 16.1.1 (excluded), 4.2, 14.1, 14.2
- **Further:** GPBBHL 3.3, 16, 4.1, 4.3, 4.4

### Week 10

- **Essential:** GPBBHL 10
- **Further:** None

---

## Topic Summary

The topics below are divided into **Essential** and **Further** study, and are abstracted to a level suitable for
independent research (e.g., "by googling") to attain the same depth of knowledge as reading the source materials.

### 🟢 Essential Topics

#### Computer Architecture (P&H)

_Focuses on the fundamentals of pipelining and memory hierarchies necessary for understanding the hardware impact on
concurrency performance._

- **Processor Performance & Execution:** CPU time, Clock cycles per instruction (CPI). The five basic steps of
  instruction execution (Fetch, Decode/Register Read, ALU operation, Memory Access, Write-Back).
- **Pipelining Fundamentals:** Concept of instruction pipelining, throughput vs. individual instruction latency. The
  classic 5-stage MIPS pipeline.
- **Pipeline Hazards:**
  - _Structural hazards:_ Resource conflicts.
  - _Data hazards:_ Data dependencies between instructions. Resolution mechanisms: data forwarding (bypassing) and
    pipeline stalls (bubbles) for load-use hazards.
  - _Control hazards:_ Branching delays. Resolution mechanisms: stalling, predicting branch not taken, and branch
    prediction.
- **Memory Hierarchy & Caches:** The Principle of Locality (temporal and spatial). Memory technologies (SRAM vs. DRAM).
  Cache hierarchy structures: blocks/lines, hit/miss rates, hit time, miss penalty.
- **Cache Organization:** Direct-mapped caches (address decomposition into tag, index, block offset). Write policies
  (write-through vs. write-back) and write buffers. Split instruction/data caches vs. unified caches.
- **Cache Performance:** Calculating Average Memory Access Time (AMAT). Set-associative caches (n-way) and fully
  associative caches. Cache replacement policies (Least Recently Used - LRU). The performance impact of multi-level
  caching.

#### Java Concurrency (GPBBHL)

_Focuses on the core concepts of thread safety, visibility, and liveness in concurrent programming._

- **Concurrency Fundamentals:** Processes vs. threads. Benefits of concurrency (exploiting multiprocessors, asynchronous
  I/O, responsive UIs) vs. risks (safety, liveness, and performance hazards).
- **Thread Safety & Atomicity:** Managing shared, mutable state. Race conditions (e.g., check-then-act,
  read-modify-write patterns). Compound actions.
- **Intrinsic Locking:** The `synchronized` keyword, mutual exclusion, and lock reentrancy. Guarding state and
  multi-variable invariants with a single lock. The trade-offs between locking granularity, liveness, and performance.
- **Memory Visibility:** The concept of stale data and non-atomic 64-bit operations. The role of locking in ensuring
  memory visibility. Semantics, use cases, and limitations of the `volatile` keyword.
- **Publication and Immutability:** Object publication and the dangers of reference escape (especially the `this`
  reference escaping during construction). Definition of immutability, the `final` keyword semantics, and effectively
  immutable objects. Safe publication idioms.
- **Instance Confinement:** The Java Monitor Pattern (encapsulating mutable state and guarding it entirely with the
  object's intrinsic lock).
- **Managing State Dependence:** Building blocking operations. Polling and sleeping vs. using condition queues.
- **Condition Queues:** Using `wait`, `notify`, and `notifyAll`. The three-way relationship between the lock, the
  condition queue, and the condition predicate. Handling spurious wakeups (always waiting in a loop) and missed signals.
- **Liveness Hazards:**
  - _Deadlock:_ Lock-ordering deadlocks, dynamic lock order deadlocks, and deadlocks between cooperating objects.
    Mitigation strategies, primarily open calls and ensuring global lock ordering.
  - _Other hazards:_ Thread starvation, poor responsiveness, and livelock.
- **Java Memory Model (JMM) Basics:** Why a memory model is necessary (compiler reordering, hardware out-of-order
  execution, caching). The concept of within-thread "as-if-serial" semantics.

### 🔵 Further Topics

#### Computer Architecture (P&H)

_Delves deeper into hardware implementation details, datapath design, and advanced parallelism._

- **Digital Logic & Datapath Construction:** Combinational vs. sequential logic, edge-triggered clocking methodology.
  Constructing the internal datapath elements (Program Counter, ALU, register files). Limitations of single-cycle
  implementations.
- **Pipelined Control & Hardware:** Mapping control signals to specific pipeline stages using pipeline registers.
  Hardware implementation of the Forwarding Unit and Hazard Detection Unit.
- **Instruction-Level Parallelism (ILP):** Increasing parallelism via multiple issue. Static multiple issue (VLIW) vs.
  dynamic multiple issue (superscalar). Loop unrolling, register renaming to eliminate anti-dependencies, speculation,
  and out-of-order execution.
- **Cache Coherence:** The multiprocessor cache coherence problem (program order, visibility of writes). Snooping and
  write-invalidate protocols. The concept of false sharing. Introduction to memory consistency.

#### Java Concurrency (GPBBHL & Oracle Docs)

_Explores advanced class design, JMM internals, and framework-level threading._

- **Pervasive Threading:** Implicit concurrency in standard frameworks (Swing/AWT event dispatch thread, Timers,
  Servlets, RMI) and why thread-safety is "contagious."
- **Thread Confinement:** Ad-hoc confinement, stack confinement (local variables), and the use of `ThreadLocal` for
  thread-isolated state.
- **Composing Thread-Safe Classes:** Strategies for gathering synchronization requirements. Delegating thread safety to
  existing concurrent objects. The limitations of delegation (when dependent state variables dictate the need for
  explicit locking).
- **Extending Thread-Safe Classes:** Modifying existing thread-safe behavior. Client-side locking (and its encapsulation
  fragility) vs. composition (building thread-safe wrapper classes).
- **Java Memory Model (JMM) Internals:**
  - The _Happens-Before_ partial ordering rules (program order, monitor lock, volatile, thread start/join).
  - Formal definition of data races.
  - Piggybacking on existing synchronization guarantees for visibility.
- **Safe Initialization at the JMM Level:** Why the Double-Checked Locking pattern is broken. The Lazy Initialization
  Holder Class idiom as a safe alternative. The strong initialization safety guarantee for immutable objects (final
  fields).
- **Basic Thread APIs (Oracle Docs):** The standard Java tutorial concepts: process and thread lifecycles, `Thread`
  objects, basic synchronization constructs, and standard thread communication (reinforcing core concepts established in
  GPBBHL).

