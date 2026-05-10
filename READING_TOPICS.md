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
- Instruction-level parallelism: multiple issue (static/VLIW, dynamic/superscalar), speculation, loop unrolling,
  register renaming

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

- Risks of threads: safety hazards (race conditions), liveness hazards (deadlock, starvation, livelock), performance
  hazards (context-switch and synchronisation overhead)
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
- The Java Memory Model: happens-before partial order, the eight happens-before rules, data-race-free programs and
  sequential consistency
- Instance confinement and the Java Monitor Pattern
- State-dependent operations: blocking via polling/sleeping, condition queues (`wait`/`notify`/`notifyAll`), condition
  predicates, canonical wait-loop form, missed/hijacked signals

**Further:**

- Thread confinement strategies: ad-hoc, stack confinement, `ThreadLocal`
- JMM deep dive: platform memory models, memory barriers, reordering, piggybacking on synchronisation
- Safe initialisation idioms: eager init, lazy-init holder class, double-checked locking (anti-pattern)
- Initialization safety for immutable objects (`final` field freeze semantics)
- Designing thread-safe classes: identifying state/invariants/policies, delegating thread safety, extending thread-safe
  classes (subclassing, client-side locking, composition)

### Week 10 — Avoiding liveness hazards

**Essential:**

- Deadlock: definition (cyclic wait graph), lock-ordering deadlocks, dynamic lock-order deadlocks
  (`System.identityHashCode` ordering), cross-object deadlocks via alien method calls, resource and thread-starvation
  deadlocks
- Open calls as the primary design principle for deadlock avoidance
- Deadlock avoidance and diagnosis: consistent lock ordering, timed `tryLock` with back-off, JVM thread dumps with
  automatic cycle detection
- Other liveness hazards: starvation (thread priorities), poor responsiveness (long-held locks), livelock (poison
  messages, cooperative retry loops, randomised back-off)
