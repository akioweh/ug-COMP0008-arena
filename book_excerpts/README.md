# Textbook References

The concurrency half of the module (weeks 6–10) is designed around essential readings from two textbooks. The lecture slides for these weeks are **not self-contained** — they assume the student has completed the assigned reading. Week 6 draws on the architecture textbook (Patterson & Hennessey) for processor/cache foundations; weeks 7–10 draw on the concurrency textbook (Goetz et al.) for Java concurrency theory and practice.

---

The following refer to chapters from the following two books:
P&H: Patterson, Hennessey. "Computer organization and design: the hardware/software interface"
GPBBHL: Goetz, Peierls, Bloch, Bowbeer, Holmes, Lea. "Java concurrency in practice"

"OO" refers to the java docs: <https://docs.oracle.com/javase/tutorial/essential/concurrency/index.html>

### 6

Essential readings: P&H 4.1, 4.5, 5.1, 5.2, 5.3  
Further readings: P&H 4.2, 4.3, 4.4, 4.6, 4.7, 4.10

### 7

Essential readings: GPBBHL 1.1, 1.2  
Further readings: P&H 5.8, OO "Processes and Threads"

### 8

Essential readings: GPBBHL 1.3, 2  
Further readings: OO "Thread Objects", OO "Synchronization", GPBBHL 1.4

### 9

Essential readings: GPBBHL 3 except 3.3, preamble of 16 till 16.1.1 (excluded), 4.2, 14.1, 14.2  
Further readings: GPBBHL 3.3, 16, 4.1, 4.3, 4.4

### 10

Essential readings: GPBBHL 10

---

## Topic overview by week (from readings)

### Week 6 — Processor pipelines and cache fundamentals

**Essential:**

- Single-cycle vs pipelined processor implementation (MIPS datapath)
- The five-stage pipeline (IF/ID/EX/MEM/WB) — throughput vs latency
- Pipeline hazards: structural, data, and control hazards
- Forwarding/bypassing and stalling (load-use hazard)
- Branch prediction (static and dynamic, brief)
- Principle of locality (temporal, spatial) and the memory hierarchy
- Cache fundamentals: direct-mapped, set-associative, fully-associative placement
- Cache addressing: tag, index, offset decomposition
- Cache write policies: write-through vs write-back; write buffers
- Cache performance: AMAT, miss-rate analysis, multi-level caches (L1/L2)
- Block replacement policies (LRU)

**Further:**

- Combinational vs sequential logic; edge-triggered clocking
- Detailed MIPS single-cycle datapath and control unit design
- Pipelined datapath with pipeline registers and forwarding/hazard-detection hardware
- Instruction-level parallelism: multiple issue (static/VLIW, dynamic/superscalar), speculation, loop unrolling, register renaming

### Week 7 — Concurrency motivation and cache coherence

**Essential:**

- Processes vs threads; shared-memory threading model
- Benefits of threads: exploiting multiprocessors, modelling simplicity, asynchronous-event handling, responsive UIs

**Further:**

- Cache coherence in shared-memory multiprocessors (snooping protocols, write-invalidate, false sharing)
- Memory consistency models (brief)
- Java concurrency fundamentals (Oracle tutorial)

### Week 8 — Thread safety and Java synchronisation primitives

**Essential:**

- Risks of threads: safety hazards (race conditions), liveness hazards (deadlock, starvation, livelock), performance hazards (context-switch and synchronisation overhead)
- Thread safety: definition (correct behaviour under arbitrary interleaving without external synchronisation)
- Atomicity: race conditions (check-then-act, read-modify-write), compound actions
- `java.util.concurrent.atomic` classes (`AtomicLong`, `AtomicReference`)
- Intrinsic locks (`synchronized`): mutual exclusion, reentrancy
- Guarding state with locks; single-lock rule for multi-variable invariants
- Liveness and performance: lock granularity, narrowing synchronised blocks

**Further:**

- Implicit threading in frameworks (JVM threads, `TimerTask`, servlets, RMI, Swing EDT)
- Java thread creation and synchronisation (Oracle tutorial)

### Week 9 — Visibility, publication, the Java Memory Model, and condition-based synchronisation

**Essential:**

- Memory visibility: stale data, non-atomic 64-bit operations, locking as a visibility mechanism
- `volatile` variables: semantics, limitations, correct usage criteria
- Publication and escape; safe construction practices (`this`-escape prevention)
- Immutability as a thread-safety strategy; `final` field semantics
- Safe publication idioms (static initialisers, `volatile`, `final`, lock-guarded)
- Effectively immutable objects; sharing policies (thread-confined, read-only, thread-safe, guarded)
- The Java Memory Model: happens-before partial order, the eight happens-before rules, data-race-free programs and sequential consistency
- Instance confinement and the Java Monitor Pattern
- State-dependent operations: blocking via polling/sleeping, condition queues (`wait`/`notify`/`notifyAll`), condition predicates, canonical wait-loop form, missed/hijacked signals

**Further:**

- Thread confinement strategies: ad-hoc, stack confinement, `ThreadLocal`
- JMM deep dive: platform memory models, memory barriers, reordering, piggybacking on synchronisation
- Safe initialisation idioms: eager init, lazy-init holder class, double-checked locking (anti-pattern)
- Initialization safety for immutable objects (`final` field freeze semantics)
- Designing thread-safe classes: identifying state/invariants/policies, delegating thread safety, extending thread-safe classes (subclassing, client-side locking, composition)

### Week 10 — Avoiding liveness hazards

**Essential:**

- Deadlock: definition (cyclic wait graph), lock-ordering deadlocks, dynamic lock-order deadlocks (`System.identityHashCode` ordering), cross-object deadlocks via alien method calls, resource and thread-starvation deadlocks
- Open calls as the primary design principle for deadlock avoidance
- Deadlock avoidance and diagnosis: consistent lock ordering, timed `tryLock` with back-off, JVM thread dumps with automatic cycle detection
- Other liveness hazards: starvation (thread priorities), poor responsiveness (long-held locks), livelock (poison messages, cooperative retry loops, randomised back-off)

---

## Extracted topic lists (detailed)

Per-chapter topic extractions (from the PDFs in this directory):

- [PH\_ch\_4\_topics.md](PH_ch_4_topics.md), [PH\_ch\_5\_topics.md](PH_ch_5_topics.md)
- [GPBBHL\_ch\_1\_topics.md](GPBBHL_ch_1_topics.md), [GPBBHL\_ch\_2\_topics.md](GPBBHL_ch_2_topics.md), [GPBBHL\_ch\_3\_topics.md](GPBBHL_ch_3_topics.md), [GPBBHL\_ch\_4\_topics.md](GPBBHL_ch_4_topics.md), [GPBBHL\_ch\_10\_topics.md](GPBBHL_ch_10_topics.md), [GPBBHL\_ch\_14\_topics.md](GPBBHL_ch_14_topics.md), [GPBBHL\_ch\_16\_topics.md](GPBBHL_ch_16_topics.md)

Per-week reading topic lists (consolidated from the above by the week's assigned sections):

- [week\_06\_reading\_topics.md](week_06_reading_topics.md)
- [week\_07\_reading\_topics.md](week_07_reading_topics.md)
- [week\_08\_reading\_topics.md](week_08_reading_topics.md)
- [week\_09\_reading\_topics.md](week_09_reading_topics.md)
- [week\_10\_reading\_topics.md](week_10_reading_topics.md)
