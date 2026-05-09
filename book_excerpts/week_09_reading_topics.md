# Week 9 — Reading Topics

## Essential readings

**GPBBHL 3.1 — Visibility**
- Memory visibility across threads (detailed, with code example: `NoVisibility`)
- Synchronization as a visibility mechanism, not just mutual exclusion
- Instruction reordering by compiler/processor/runtime and its effect on cross-thread observations
- Impossibility of reasoning about ordering in insufficiently synchronised programs

*3.1.1 — Stale Data*
- Stale data: definition and consequences (safety and liveness failures)
- Non-all-or-nothing staleness (one variable up-to-date, another stale)
- Need to synchronise both getter and setter (code examples: `MutableInteger` vs `SynchronizedInteger`)

*3.1.2 — Non-atomic 64-bit Operations*
- Out-of-thin-air safety guarantee (and its exception)
- Non-atomic reads/writes of `long` and `double` (word tearing across two 32-bit operations)
- Requirement to use `volatile` or a lock for shared mutable `long`/`double`

*3.1.3 — Locking and Visibility*
- Intrinsic locking as a visibility guarantee (happens-before from unlock to subsequent lock on same monitor)
- Locking is about both mutual exclusion and memory visibility
- Requirement for reader and writer to synchronise on the same lock

*3.1.4 — Volatile Variables*
- `volatile` keyword: semantics (no reordering, no caching in registers/processor caches)
- Volatile as a lighter-weight alternative to `synchronized` (visibility only, no atomicity)
- Memory visibility effects of volatile: writing ≈ exiting a `synchronized` block, reading ≈ entering one
- Limitations of `volatile` (e.g. `count++` is not atomic)
- Criteria for correct use of `volatile` (three conditions)
- Typical use case: status/completion/interruption flags (code example: counting sheep)
- JVM `-server` vs `-client` optimisation differences affecting volatile visibility (debugging tip)

**GPBBHL 3.2 — Publication and Escape**
- Definition of publication and escape
- Ways an object can be published: public static field, returning from non-private method, passing to alien method, inner class instances
- Transitive publication (publishing one object indirectly publishes reachable objects)
- Alien methods: definition and risk when passing objects to them
- Encapsulation as defence against uncontrolled escape
- Implicit `this` escape via inner class instances (code example: `ThisEscape`)

*3.2.1 — Safe Construction Practices*
- `this` reference escaping during construction: risks of publishing an incompletely constructed object
- Starting a thread from a constructor (why it is dangerous; prefer a factory/`start` method)
- Calling overrideable methods from a constructor
- Private constructor + public factory method pattern to prevent `this` escape (code example: `SafeListener`)

**GPBBHL 3.4 — Immutability**
- Immutable objects are inherently thread-safe (no synchronisation needed)
- Definition of immutability (three conditions: unmodifiable state, all fields `final`, proper construction)
- `final` fields alone do not guarantee immutability (final reference to mutable object)
- Immutable objects built on top of mutable internals (code example: `ThreeStooges`)
- Difference between an immutable object and an immutable reference
- Replacing immutable objects to update program state

*3.4.1 — Final Fields*
- `final` keyword semantics (cannot reassign; referred-to object may still be mutable)
- Special JMM semantics of `final` fields: initialization safety guarantee
- Best practice: make fields `final` unless they need to be mutable

*3.4.2 — Example: Using Volatile to Publish Immutable Objects*
- Immutable holder class pattern for atomically related state (code example: `OneValueCache`)
- Combining `volatile` reference + immutable holder for lock-free thread safety (code example: `VolatileCachedFactorizer`)
- Defensive copying (`Arrays.copyOf`) to preserve immutability

**GPBBHL 3.5 — Safe Publication**
- Unsafe publication: storing a reference in a public field without synchronisation (code example: `Holder`)
- Observing a partially constructed object due to improper publication

*3.5.1 — Improper Publication: When Good Objects Go Bad*
- Stale/inconsistent state from improper publication (detailed, with `assertSanity` example)
- Default-value writes by the `Object` constructor as a source of stale field values

*3.5.2 — Immutable Objects and Initialization Safety*
- JMM initialization safety guarantee for immutable objects
- Immutable objects can be safely accessed without synchronisation even when not safely published
- Guarantee extends to all `final` fields of properly constructed objects
- Caveat: `final` fields referring to mutable objects still need synchronisation for the referred-to object's state

*3.5.3 — Safe Publication Idioms*
- Four safe publication mechanisms (static initialiser; `volatile`/`AtomicReference`; `final` field; lock-guarded field)
- Thread-safe collections as safe publication vehicles (`Hashtable`, `synchronizedMap`, `ConcurrentMap`, `Vector`, `CopyOnWriteArrayList`, `BlockingQueue`, `ConcurrentLinkedQueue`, etc.)
- Other handoff mechanisms: `Future`, `Exchanger`
- Static initialisers and JVM class-loading synchronisation

*3.5.4 — Effectively Immutable Objects*
- Definition of effectively immutable objects (not technically immutable, but treated as immutable after publication)
- Safe publication is sufficient for effectively immutable objects (no further synchronisation needed)
- Example: `Date` values in a `synchronizedMap`

*3.5.5 — Mutable Objects*
- Publication requirements by mutability tier: immutable (any mechanism), effectively immutable (safe publication), mutable (safe publication + thread-safe or guarded)
- Ongoing synchronisation needed for every access to shared mutable objects

*3.5.6 — Sharing Objects Safely*
- Four policies for using and sharing objects in concurrent programs: thread-confined, shared read-only, shared thread-safe, guarded
- Documenting the "rules of engagement" for shared objects

**GPBBHL 16 Preamble — The Java Memory Model**
- The Java Memory Model (JMM) as the foundation underlying safe publication and synchronization policies (motivation for the chapter)
- Relationship between high-level design rules (safe publication, synchronization policies) and low-level JMM guarantees

**GPBBHL 16.1 — What is a Memory Model, and Why would I Want One?**
- What a memory model is: the conditions under which a write by one thread becomes visible to a read by another thread
- Reasons a thread may not see another thread's write: compiler reordering, register allocation, processor out-of-order execution, cache write-back ordering, processor-local caches (enumerated)
- Within-thread as-if-serial semantics: the JVM/JLS guarantee that single-threaded execution appears sequential
- Hardware parallelism techniques that motivate reordering: pipelined superscalar execution, dynamic instruction scheduling, speculative execution, multilevel caches
- Why the JMM does not enforce sequential consistency: the performance cost of full inter-thread coordination
- The JMM's design goal: balance predictability with high-performance implementation across processor architectures

**GPBBHL 4.2 — Instance Confinement**
- Confining a non-thread-safe object to make it usable in a multithreaded program
- Three scopes of confinement: class instance (private field), lexical scope (local variable), thread
- Combining confinement with a locking discipline (worked example: `PersonSet` wrapping a `HashSet`)
- Thread-safety obligations for mutable objects retrieved from a confined collection
- Flexibility of confinement: any consistent lock will do; different state variables may use different locks
- Synchronized collection wrappers (`Collections.synchronizedList` etc.) as confinement via the Decorator pattern
- Violating confinement: publishing supposedly confined objects (directly or via iterators / inner classes)

*4.2.1 — The Java Monitor Pattern*
- Definition: encapsulate all mutable state and guard it with the object's own intrinsic lock
- Relationship to Hoare monitors (brief historical note; `monitorenter`/`monitorexit` bytecodes)
- Using a private lock object instead of the intrinsic lock: encapsulating the lock, preventing client interference (code example: `PrivateLock`)
- Library examples: `Vector`, `Hashtable`

*4.2.2 — Example: Tracking Fleet Vehicles*
- Monitor-based `VehicleTracker` design (detailed worked example with `MonitorVehicleTracker`, `MutablePoint`)
- Deep-copying mutable state on return to preserve thread safety
- Snapshot semantics vs. live-view semantics (trade-offs)
- Performance implications of copying under lock (responsiveness concern with large data sets)

**GPBBHL 14.1 — Managing State Dependence**
- State-dependent classes and state-based preconditions (definition and motivation)
- Difference between state dependence in sequential vs concurrent programs
- Structure of a blocking state-dependent action (acquire lock, test predicate in loop, release/reacquire pattern) (canonical pseudocode)
- Bounded buffer as running example (array-based circular buffer: `BaseBoundedBuffer`)

*14.1.1 — Example: Propagating Precondition Failure to Callers*
- "Balking" approach: throwing exceptions on precondition failure (`GrumpyBoundedBuffer`) (worked example with code)
- Why exceptions are inappropriate for expected state conditions
- Caller burden: catch-and-retry logic pushed to client
- Returning error values as a variant (brief mention; `Queue.poll` vs `Queue.remove`)
- Busy waiting / spin waiting vs sleeping: CPU usage vs responsiveness trade-off
- `Thread.yield` as a middle ground between spinning and sleeping (brief mention)

*14.1.2 — Example: Crude Blocking by Polling and Sleeping*
- Encapsulating poll-and-sleep retry inside `put`/`take` (`SleepyBoundedBuffer`) (worked example with code)
- Releasing the lock before sleeping, reacquiring after waking
- Sleep granularity trade-off: responsiveness vs CPU consumption
- Thread oversleeping problem (illustrated with timing diagram)
- `InterruptedException` and cancellation support for blocking methods

*14.1.3 — Condition Queues to the Rescue*
- Condition queue concept: wait set of threads waiting for a condition
- Intrinsic condition queues: every Java object as a condition queue (`wait`, `notify`, `notifyAll`)
- Relationship between intrinsic lock and intrinsic condition queue (must hold lock to call condition queue methods)
- `Object.wait` semantics: atomic release-and-suspend, reacquire-on-wake
- Bounded buffer using `wait`/`notifyAll` (`BoundedBuffer`) (worked example with code)
- Condition queues as an optimisation over polling/sleeping (CPU efficiency, context-switch overhead, responsiveness)

**GPBBHL 14.2 — Using Condition Queues**
- Difficulty of correct usage; preference for building on existing library classes (`LinkedBlockingQueue`, `CountDownLatch`, `Semaphore`, `FutureTask`)

*14.2.1 — The Condition Predicate*
- Condition predicate: definition and role in state-dependent operations (detailed)
- Three-way relationship: lock, `wait` method, and condition predicate
- Requirement that lock object and condition queue object be the same
- `wait` releases the lock, blocks, then reacquires before returning (detailed mechanics)
- No special priority for threads waking from `wait` in lock reacquisition

*14.2.2 — Waking Up Too Soon*
- Multiple condition predicates on a single intrinsic condition queue
- Spurious wakeups (`wait` returning without `notify`)
- Condition predicate may become false between notification and lock reacquisition
- "Hijacked signal": wakeup consumed by wrong waiter
- Canonical form: always call `wait` in a loop, re-testing the condition predicate (code listing)
- Checklist of rules for correct condition waits (6 rules, boxed)

*14.2.3 — Missed Signals*
- Missed signal as a liveness failure: waiting for an event that already occurred
- Notification is not "sticky"
- Prevention: always test predicate before calling `wait`

*14.2.4 — Notification*
- `notify` vs `notifyAll` semantics
- Ensuring every code path that could make a predicate true performs notification
- Danger of `notify` with multiple condition predicates on one queue (hijacked signal scenario, detailed example)
- Conditions for safe use of single `notify`: uniform waiters + one-in, one-out (formal criteria)
- `notifyAll` as the safe default; O(n^2) wakeup cost in worst case
- Conditional notification: notifying only on state transitions (e.g. empty-to-nonempty) (optimisation with code example)

*14.2.5 — Example: A Gate Class*
- Recloseable `ThreadGate` using `wait`/`notifyAll` (worked example with code)
- Generation counter to handle rapid open/close cycles
- Compound condition predicate: `isOpen || generation > arrivalGeneration`
- Why `notifyAll` is required (fails one-in, one-out test)

*14.2.6 — Subclass Safety Issues*
- Constraints that single/conditional notification place on subclassing
- Design for inheritance: expose and document waiting/notification protocols, or prohibit subclassing
- Example: unbounded blocking stack with subclass adding "pop two" — need to override to `notifyAll`

*14.2.7 — Encapsulating Condition Queues*
- Advice to encapsulate condition queue objects (prevent alien code from waiting on them)
- Tension with common idiom of using `this` as both lock and condition queue
- Private lock and condition queue as alternative (loses client-side locking)

*14.2.8 — Entry and Exit Protocols*
- Wellings' characterisation: entry protocol = condition predicate; exit protocol = check whether state change enables other predicates, then notify
- `AbstractQueuedSynchronizer` and the exit protocol pattern (brief forward reference)

## Further readings

**GPBBHL 3.3 — Thread Confinement**
- Thread confinement as a strategy to avoid synchronisation entirely
- Swing event dispatch thread as a real-world example
- JDBC `Connection` pooling as a real-world example of implicit confinement
- Language provides no enforcement mechanism; confinement is a design discipline

*3.3.1 — Ad-hoc Thread Confinement*
- Ad-hoc confinement: definition and fragility
- Single-threaded subsystems (e.g. GUI) as a motivation
- Special case: single-writer volatile variables (read-modify-write safe when writes confined to one thread)

*3.3.2 — Stack Confinement*
- Stack confinement (within-thread / thread-local usage): definition
- Local variables are intrinsically confined to the executing thread's stack
- Primitive locals: confinement guaranteed by the language
- Object-reference locals: confinement requires programmer discipline to avoid letting the referent escape (code example: `loadTheArk`)

*3.3.3 — ThreadLocal*
- `ThreadLocal<T>`: API (`get`, `set`, `initialValue`), semantics (per-thread copy)
- Use case: per-thread JDBC connections (code example: `ConnectionHolder`)
- Use case: per-thread temporary buffers (e.g. `Integer.toString` pre-Java 5)
- Conceptual model (`Map<Thread,T>`); actual storage in the `Thread` object; GC on thread termination
- Use in application frameworks (e.g. J2EE transaction context)
- Abuse potential: hidden global state, reduced reusability

**GPBBHL 16 — The Java Memory Model (full chapter)**

*Preamble*
- The Java Memory Model (JMM) as the foundation underlying safe publication and synchronization policies (motivation for the chapter)
- Relationship between high-level design rules (safe publication, synchronization policies) and low-level JMM guarantees

*16.1 — What is a Memory Model, and Why would I Want One?*
- What a memory model is: the conditions under which a write by one thread becomes visible to a read by another thread
- Reasons a thread may not see another thread's write: compiler reordering, register allocation, processor out-of-order execution, cache write-back ordering, processor-local caches (enumerated)
- Within-thread as-if-serial semantics: the JVM/JLS guarantee that single-threaded execution appears sequential
- Hardware parallelism techniques that motivate reordering: pipelined superscalar execution, dynamic instruction scheduling, speculative execution, multilevel caches
- Why the JMM does not enforce sequential consistency: the performance cost of full inter-thread coordination
- The JMM's design goal: balance predictability with high-performance implementation across processor architectures

*16.1.1 — Platform Memory Models*
- Shared-memory multiprocessor caches and periodic reconciliation with main memory
- Varying degrees of hardware cache coherence across processor architectures
- Memory barriers / fences: special instructions that enforce additional memory-ordering guarantees (concept-level introduction)
- Sequential consistency as an idealised mental model; why no modern multiprocessor (or the JMM) provides it
- The von Neumann model as only a vague approximation of modern multiprocessor behaviour
- Java's cross-platform approach: the JVM inserts memory barriers to bridge the gap between the JMM and the underlying platform memory model

*16.1.2 — Reordering*
- Reordering as an umbrella term for all causes of apparent out-of-order execution (compiler, runtime, hardware, caches)
- Worked example: `PossibleReordering` — a program that can print `(0, 0)` despite seemingly impossible interleavings (code listing + interleaving diagram)
- Dataflow independence enabling instruction reordering within a thread
- Why reasoning about ordering without synchronization is prohibitively difficult
- Synchronization as the mechanism that inhibits reordering that would violate JMM visibility guarantees
- Performance note: volatile reads on most architectures cost roughly the same as non-volatile reads

*16.1.3 — The Java Memory Model in 500 Words or Less*
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

*16.1.4 — Piggybacking on Synchronization*
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

*16.2 — Publication*
- Safe publication and improper publication as consequences of the presence or absence of happens-before ordering

*16.2.1 — Unsafe Publication*
- How reordering can cause another thread to see a partially constructed object: the reference write can be reordered with the object's field writes
- Worked example: `UnsafeLazyInitialization` — unsafe lazy initialisation that can expose a partially constructed `Resource` (code listing, detailed walkthrough)
- Stale vs partially-constructed: a consuming thread may see a non-null reference but out-of-date field values
- Rule: except for immutable objects, an object initialised by another thread is not safe to use unless publication happens-before the consuming thread's use

*16.2.2 — Safe Publication*
- Safe-publication idioms ensure publication happens-before the consuming thread loads the reference
- Examples: `BlockingQueue` (put h-b take), lock-guarded variables, shared volatile variables
- Happens-before is strictly stronger than safe publication: it guarantees visibility of *all* prior actions, not just the published object's state
- Why the book favours `@GuardedBy` and safe publication over raw happens-before reasoning: the latter operates at the level of individual memory accesses ("concurrency assembly language")

*16.2.3 — Safe Initialization Idioms*
- Thread-safe lazy initialisation via `synchronized` method (code listing: `SafeLazyInitialization`)
- Static initializers and class-loading thread safety: the JVM acquires a lock during class initialisation; writes during static init are automatically visible to all threads (detailed explanation)
- Caveat: static-init safety applies only to as-constructed state; mutable objects still need synchronisation for subsequent modifications
- Eager initialisation idiom (code listing: `EagerInitialization`)
- Lazy initialization holder class idiom: combining JVM lazy class loading with static initialiser guarantees to achieve lazy init without synchronisation on the common path (code listing: `ResourceFactory` with inner `ResourceHolder`)

*16.2.4 — Double-checked Locking*
- Double-checked locking (DCL) as an anti-pattern (detailed treatment with code listing: `DoubleCheckedLocking`)
- Historical motivation: high cost of synchronisation in early JVMs
- How DCL works: check without synchronising, synchronise only on first init
- Why DCL is broken: the unsynchronised read can see a non-null reference to a partially constructed object (not merely a stale null)
- Fix available since Java 5: making the field `volatile` (but the idiom's utility has passed)
- Recommendation: prefer the lazy initialization holder class idiom instead

*16.3 — Initialization Safety*
- Initialization safety guarantee for properly constructed immutable objects: they can be safely shared without synchronisation regardless of publication mechanism (including data races)
- Security implication: without initialization safety, immutable objects like `String` could appear to change value, enabling security exploits
- `final` fields and the "freeze" at constructor completion: all writes to final fields (and objects reachable through them) become visible to any thread that obtains a reference
- Prohibition of reordering construction with the initial load of the reference (for objects with final fields)
- Worked example: `SafeStates` — a class with a `final` `HashMap` field that is safely published even without synchronisation (code listing)
- Conditions that would break initialization safety: non-final fields, post-construction mutation, constructor escape
- Scope limitation: initialization safety covers only values reachable through final fields as of constructor completion; non-final fields and post-construction changes require synchronisation

*Summary*
- Recap: the JMM specifies visibility via the happens-before partial ordering over memory and synchronisation operations
- Higher-level rules (`@GuardedBy`, safe publication) suffice for most programs without reasoning at the happens-before level

**GPBBHL 4.1 — Designing a Thread-safe Class**
- Three-element design process for thread-safe classes: identify state, identify invariants, establish concurrent-access policy
- Object state as the n-tuple of its fields (including transitively referenced objects)
- Synchronization policy: definition and role (combination of immutability, confinement, and locking)
- Importance of documenting the synchronization policy

*4.1.1 — Gathering Synchronization Requirements*
- State space of an object and how `final` fields / immutability reduce it
- Class invariants constraining valid states (worked example: `Counter` disallowing negative values)
- Post-conditions constraining valid state transitions (e.g. counter can only go from 17 to 18)
- How invariants and post-conditions create atomicity and encapsulation requirements
- Multivariable invariants and the need to hold a single lock across all related variable accesses (worked example: `NumberRange` lower/upper)

*4.1.2 — State-dependent Operations*
- State-based preconditions (e.g. "queue must be non-empty to remove")
- Difference between single-threaded failure and concurrent waiting-for-precondition
- `wait`/`notify` and intrinsic locking (brief mention; deferred to Ch. 14)
- Using library classes (`BlockingQueue`, `Semaphore`) for state-dependent behaviour (brief mention; deferred to Ch. 5)

*4.1.3 — State Ownership*
- Ownership as a class-design concept (not enforced by the language)
- Logical state of a composite object spanning its internal sub-objects (e.g. `HashMap` owns its `Map.Entry` objects)
- Relationship between ownership and encapsulation; the owner chooses the locking protocol
- Publishing a mutable reference as loss of exclusive ownership ("shared ownership")
- Split ownership in collections: collection infrastructure vs. stored elements (worked example: `ServletContext` / `HttpSession`)

**GPBBHL 4.3 — Delegating Thread Safety**
- Concept of delegating thread-safety responsibility to an already-thread-safe component
- When delegation alone is sufficient vs. when additional synchronization is needed

*4.3.1 — Example: Vehicle Tracker Using Delegation*
- `DelegatingVehicleTracker` using `ConcurrentHashMap` and immutable `Point` (detailed worked example)
- Eliminating explicit synchronization and defensive copying via immutability
- Returning an unmodifiable live view vs. a shallow-copy snapshot (code for both)
- Behavioural difference from the monitor-based version (live view vs. snapshot)

*4.3.2 — Independent State Variables*
- Delegating to multiple underlying thread-safe state variables when they are independent (no cross-variable invariants)
- `VisualComponent` example: two independent `CopyOnWriteArrayList` listener lists (detailed worked example)

*4.3.3 — When Delegation Fails*
- Dependent state variables with a multivariable invariant break delegation (`NumberRange` with two `AtomicInteger`s — detailed worked example)
- Check-then-act race in `setLower`/`setUpper` despite individually thread-safe components
- Remediation: guard related variables with a common lock; avoid publishing them
- Rule: delegation works only when state variables are independent and no compound actions exist
- Analogy to the volatile-variable rule (variable must not participate in invariants with other variables)

*4.3.4 — Publishing Underlying State Variables*
- Conditions under which an underlying thread-safe state variable can be safely published to clients
- Rule: safe to publish if the variable is thread-safe, has no constraining invariants, and no prohibited state transitions
- Example: `mouseListeners`/`keyListeners` in `VisualComponent` can be published

*4.3.5 — Example: Vehicle Tracker that Publishes Its State*
- `SafePoint`: a thread-safe mutable point class returning both coordinates atomically (detailed code example)
- Private constructor capture idiom to avoid race condition in copy constructor
- `PublishingVehicleTracker`: delegates to `ConcurrentHashMap` of `SafePoint`s, safely publishes mutable state (detailed code example)
- Limitations: not suitable if the class needs to veto or react to changes

**GPBBHL 4.4 — Adding Functionality to Existing Thread-safe Classes**
- Motivation: extending a thread-safe class with a new atomic operation (running example: atomic put-if-absent on a `List`)
- Approach 1 — modify the original class (safest; keeps synchronization policy in one place; not always possible)
- Approach 2 — extend the class (e.g. `BetterVector extends Vector`; fragile if base class changes its locking strategy) (code example)
- Fragility of distributing synchronization policy across class hierarchy

*4.4.1 — Client-side Locking*
- Helper-class approach and why synchronizing on the wrong lock fails (`ListHelper` anti-pattern — detailed worked example)
- Client-side / external locking: synchronize on the same lock the object uses internally
- Correct client-side locking for `Collections.synchronizedList` wrappers (code example)
- Fragility: couples to the object's undocumented locking strategy; violates encapsulation of synchronization policy

*4.4.2 — Composition*
- Wrapping with a new class that provides its own consistent locking (`ImprovedList implements List<T>` — detailed code example)
- Independence from the underlying list's thread-safety or locking implementation
- Trade-off: slight performance overhead from extra synchronisation layer, but much less fragile
- Effectively the Java monitor pattern applied to an existing object
