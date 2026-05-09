# GPBBHL Chapter 2 — Thread Safety

## Chapter intro (unnumbered)
- Thread safety as managing access to shared, mutable state
- Object state: instance fields, static fields, dependent objects
- Shared vs mutable: definitions
- Three strategies to fix unsynchronised shared mutable state (don't share; make immutable; synchronise)
- Synchronisation mechanisms in Java: `synchronized`, `volatile`, explicit locks, atomic variables (brief enumeration)
- Role of encapsulation and data hiding in thread safety
- Thread-safe class vs thread-safe program — composability caveat (introduction only; deferred to Ch 4)
- Correctness before performance in concurrent code

## 2.1 — What is Thread Safety?
- Difficulty of defining thread safety; circularity of informal definitions
- Correctness as the foundation: invariants, post-conditions, specifications
- Formal definition: a class is thread-safe if it behaves correctly under arbitrary scheduling/interleaving with no additional synchronisation from callers
- Thread-safe classes encapsulate their own synchronisation

### 2.1.1 — Example: A Stateless Servlet
- Stateless objects are always thread-safe (key rule, with code example)
- Servlet framework as a motivating context for thread safety
- Local (stack-confined) variables and thread isolation
- Running example introduced: `StatelessFactorizer` servlet

## 2.2 — Atomicity
- Adding state to a stateless object and the resulting safety problem
- Non-atomicity of `++count` (read-modify-write as three discrete operations, with code example)
- Lost updates due to interleaving
- Race conditions: definition (correctness depends on relative timing/interleaving)

### 2.2.1 — Race Conditions
- Race condition vs data race: distinction (detailed note)
- Check-then-act pattern as the most common race condition type (detailed with real-world analogy)
- Stale observations and their invalidation between check and act

### 2.2.2 — Example: Race Conditions in Lazy Initialization
- Lazy initialisation as a check-then-act instance (code example: `LazyInitRace`)
- Read-modify-write as a distinct race condition pattern
- Consequences of race conditions: duplicate instances, lost registrations, duplicate IDs

### 2.2.3 — Compound Actions
- Atomic operations: definition (formal)
- Compound actions: check-then-act and read-modify-write sequences that must execute atomically
- `java.util.concurrent.atomic` package: `AtomicLong`, `AtomicReference` (introduction)
- Using existing thread-safe objects to manage state (code example: `CountingFactorizer` with `AtomicLong`)
- Single thread-safe state variable on a stateless class preserves thread safety
- Limitation: multiple independent atomic variables do not compose into an atomic compound action

## 2.3 — Locking
- Insufficiency of multiple independent `AtomicReference` fields for multi-variable invariants (code example: `UnsafeCachingFactorizer`)
- Invariants spanning multiple state variables: must update all atomically
- Rule: to preserve state consistency, update related state variables in a single atomic operation

### 2.3.1 — Intrinsic Locks
- `synchronized` block syntax and semantics (detailed)
- `synchronized` methods as shorthand; static `synchronized` methods use the `Class` object
- Intrinsic locks / monitor locks: every Java object as an implicit lock
- Mutual exclusion (mutex) semantics: automatic acquire/release, blocking on contention
- Atomicity via `synchronized`: blocks guarded by the same lock execute atomically w.r.t. each other
- Over-synchronisation problem: synchronising entire `service` method is correct but kills concurrency (code example: `SynchronizedFactorizer`)

### 2.3.2 — Reentrancy
- Reentrant (recursive) locking: per-thread rather than per-invocation acquisition
- Implementation: acquisition count + owning thread
- Why reentrancy matters: subclass calling `super.doSomething()` on a `synchronized` method would deadlock without it (code example: `Widget` / `LoggingWidget`)
- Contrast with POSIX threads default (non-reentrant) mutex behaviour

## 2.4 — Guarding State with Locks
- Serialised access via locks (note: not object serialisation)
- Rule: every access to a variable must use the same lock; variable is "guarded by" that lock
- `@GuardedBy` annotation
- No inherent relationship between an object's intrinsic lock and its fields
- Acquiring a lock does not prevent access to the object — only prevents acquiring the same lock
- Rule: every shared mutable variable should be guarded by exactly one lock
- Common convention: encapsulate all mutable state, protect with the object's intrinsic lock (e.g. `Vector`, synchronised collections)
- Multi-variable invariants: all participating variables must be guarded by the same lock
- Rule: for every invariant involving more than one variable, all variables must share one lock
- Pitfall: synchronising every method is neither sufficient (compound actions still racy) nor desirable (liveness/performance)
- Put-if-absent on `Vector` as a compound-action race condition despite individually atomic methods
- How adding a `TimerTask` can introduce unexpected sharing and synchronisation requirements throughout a program

## 2.5 — Liveness and Performance
- Coarse-grained locking (synchronising entire method) as a performance anti-pattern (detailed, with diagram of sequential request queueing)
- Poor concurrency: throughput limited by application structure, not hardware
- Narrowing `synchronized` block scope to improve concurrency while preserving safety (detailed code example: `CachedFactorizer`)
- Excluding long-running operations (e.g. factorisation) from `synchronized` blocks
- Trade-off: simplicity vs performance vs safety when sizing `synchronized` blocks
- Lock overhead: don't split blocks too finely
- Choosing between `AtomicLong` and `synchronized` — avoid mixing synchronisation mechanisms unnecessarily
- Rule: avoid holding locks during lengthy computations or blocking I/O
- Rule: resist sacrificing simplicity for premature performance optimisation
