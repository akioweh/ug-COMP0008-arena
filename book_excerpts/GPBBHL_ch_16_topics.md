# GPBBHL Chapter 16 — The Java Memory Model

## Preamble
- The Java Memory Model (JMM) as the foundation underlying safe publication and synchronization policies (motivation for the chapter)
- Relationship between high-level design rules (safe publication, synchronization policies) and low-level JMM guarantees

## 16.1 — What is a Memory Model, and Why would I Want One?
- What a memory model is: the conditions under which a write by one thread becomes visible to a read by another thread
- Reasons a thread may not see another thread's write: compiler reordering, register allocation, processor out-of-order execution, cache write-back ordering, processor-local caches (enumerated)
- Within-thread as-if-serial semantics: the JVM/JLS guarantee that single-threaded execution appears sequential
- Hardware parallelism techniques that motivate reordering: pipelined superscalar execution, dynamic instruction scheduling, speculative execution, multilevel caches
- Why the JMM does not enforce sequential consistency: the performance cost of full inter-thread coordination
- The JMM's design goal: balance predictability with high-performance implementation across processor architectures

### 16.1.1 — Platform Memory Models
- Shared-memory multiprocessor caches and periodic reconciliation with main memory
- Varying degrees of hardware cache coherence across processor architectures
- Memory barriers / fences: special instructions that enforce additional memory-ordering guarantees (concept-level introduction)
- Sequential consistency as an idealised mental model; why no modern multiprocessor (or the JMM) provides it
- The von Neumann model as only a vague approximation of modern multiprocessor behaviour
- Java's cross-platform approach: the JVM inserts memory barriers to bridge the gap between the JMM and the underlying platform memory model

### 16.1.2 — Reordering
- Reordering as an umbrella term for all causes of apparent out-of-order execution (compiler, runtime, hardware, caches)
- Worked example: `PossibleReordering` — a program that can print `(0, 0)` despite seemingly impossible interleavings (code listing + interleaving diagram)
- Dataflow independence enabling instruction reordering within a thread
- Why reasoning about ordering without synchronization is prohibitively difficult
- Synchronization as the mechanism that inhibits reordering that would violate JMM visibility guarantees
- Performance note: volatile reads on most architectures cost roughly the same as non-volatile reads

### 16.1.3 — The Java Memory Model in 500 Words or Less
- JMM actions: reads/writes to variables, lock/unlock of monitors, thread start/join
- Happens-before: a partial ordering over all program actions (formal definition of partial ordering given)
- Data race (definition): a variable read by >1 thread and written by ≥1 thread without happens-before ordering between the accesses
- Correctly synchronised program (definition): one with no data races; exhibits sequential consistency
- The complete set of happens-before rules (enumerated):
  - Program order rule
  - Monitor lock rule (+ note: explicit `Lock` objects have same semantics as intrinsic locks)
  - Volatile variable rule (+ note: atomic variables have same semantics as volatile)
  - Thread start rule
  - Thread termination rule (`Thread.join`, `Thread.isAlive`)
  - Interruption rule
  - Finalizer rule
  - Transitivity
- Synchronisation actions (lock acquire/release, volatile read/write) are totally ordered, even though general actions are only partially ordered
- Illustrated example: happens-before through a common lock between two threads (diagram)
- No happens-before relationship exists between threads synchronising on *different* locks

### 16.1.4 — Piggybacking on Synchronization
- Piggybacking: exploiting an existing happens-before ordering (created for another purpose) to ensure visibility of additional variables not directly guarded by a lock
- Combining the program order rule with the monitor lock or volatile variable rule to order accesses
- Fragility of the technique; recommended only for performance-critical code
- Worked example: `FutureTask` / `AbstractQueuedSynchronizer` — using a volatile state variable inside AQS to piggyback visibility of the non-volatile `result` field (code listing)
- Safe publication via `BlockingQueue` as a form of piggybacking
- Additional happens-before orderings guaranteed by the class library (enumerated):
  - Thread-safe collection put/get
  - `CountDownLatch` countDown / await
  - `Semaphore` release / acquire
  - `Future` task actions / `Future.get`
  - `Executor` submit / task execution
  - `CyclicBarrier` / `Exchanger` arrive / release (including barrier action ordering)

## 16.2 — Publication
- Safe publication and improper publication as consequences of the presence or absence of happens-before ordering

### 16.2.1 — Unsafe Publication
- How reordering can cause another thread to see a partially constructed object: the reference write can be reordered with the object's field writes
- Worked example: `UnsafeLazyInitialization` — unsafe lazy initialisation that can expose a partially constructed `Resource` (code listing, detailed walkthrough)
- Stale vs partially-constructed: a consuming thread may see a non-null reference but out-of-date field values
- Rule: except for immutable objects, an object initialised by another thread is not safe to use unless publication happens-before the consuming thread's use

### 16.2.2 — Safe Publication
- Safe-publication idioms ensure publication happens-before the consuming thread loads the reference
- Examples: `BlockingQueue` (put h-b take), lock-guarded variables, shared volatile variables
- Happens-before is strictly stronger than safe publication: it guarantees visibility of *all* prior actions, not just the published object's state
- Why the book favours `@GuardedBy` and safe publication over raw happens-before reasoning: the latter operates at the level of individual memory accesses ("concurrency assembly language")

### 16.2.3 — Safe Initialization Idioms
- Thread-safe lazy initialisation via `synchronized` method (code listing: `SafeLazyInitialization`)
- Static initializers and class-loading thread safety: the JVM acquires a lock during class initialisation; writes during static init are automatically visible to all threads (detailed explanation)
- Caveat: static-init safety applies only to as-constructed state; mutable objects still need synchronisation for subsequent modifications
- Eager initialisation idiom (code listing: `EagerInitialization`)
- Lazy initialization holder class idiom: combining JVM lazy class loading with static initialiser guarantees to achieve lazy init without synchronisation on the common path (code listing: `ResourceFactory` with inner `ResourceHolder`)

### 16.2.4 — Double-checked Locking
- Double-checked locking (DCL) as an anti-pattern (detailed treatment with code listing: `DoubleCheckedLocking`)
- Historical motivation: high cost of synchronisation in early JVMs
- How DCL works: check without synchronising, synchronise only on first init
- Why DCL is broken: the unsynchronised read can see a non-null reference to a partially constructed object (not merely a stale null)
- Fix available since Java 5: making the field `volatile` (but the idiom's utility has passed)
- Recommendation: prefer the lazy initialization holder class idiom instead

## 16.3 — Initialization Safety
- Initialization safety guarantee for properly constructed immutable objects: they can be safely shared without synchronisation regardless of publication mechanism (including data races)
- Security implication: without initialization safety, immutable objects like `String` could appear to change value, enabling security exploits
- `final` fields and the "freeze" at constructor completion: all writes to final fields (and objects reachable through them) become visible to any thread that obtains a reference
- Prohibition of reordering construction with the initial load of the reference (for objects with final fields)
- Worked example: `SafeStates` — a class with a `final` `HashMap` field that is safely published even without synchronisation (code listing)
- Conditions that would break initialization safety: non-final fields, post-construction mutation, constructor escape
- Scope limitation: initialization safety covers only values reachable through final fields as of constructor completion; non-final fields and post-construction changes require synchronisation

## Summary
- Recap: the JMM specifies visibility via the happens-before partial ordering over memory and synchronisation operations
- Higher-level rules (`@GuardedBy`, safe publication) suffice for most programs without reasoning at the happens-before level
