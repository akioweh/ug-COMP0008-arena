# GPBBHL Chapter 3 — Sharing Objects

## 3.1 — Visibility
- Memory visibility across threads (detailed, with code example: `NoVisibility`)
- Synchronization as a visibility mechanism, not just mutual exclusion
- Instruction reordering by compiler/processor/runtime and its effect on cross-thread observations
- Impossibility of reasoning about ordering in insufficiently synchronised programs

### 3.1.1 — Stale Data
- Stale data: definition and consequences (safety and liveness failures)
- Non-all-or-nothing staleness (one variable up-to-date, another stale)
- Need to synchronise both getter and setter (code examples: `MutableInteger` vs `SynchronizedInteger`)

### 3.1.2 — Non-atomic 64-bit Operations
- Out-of-thin-air safety guarantee (and its exception)
- Non-atomic reads/writes of `long` and `double` (word tearing across two 32-bit operations)
- Requirement to use `volatile` or a lock for shared mutable `long`/`double`

### 3.1.3 — Locking and Visibility
- Intrinsic locking as a visibility guarantee (happens-before from unlock to subsequent lock on same monitor)
- Locking is about both mutual exclusion and memory visibility
- Requirement for reader and writer to synchronise on the same lock

### 3.1.4 — Volatile Variables
- `volatile` keyword: semantics (no reordering, no caching in registers/processor caches)
- Volatile as a lighter-weight alternative to `synchronized` (visibility only, no atomicity)
- Memory visibility effects of volatile: writing ≈ exiting a `synchronized` block, reading ≈ entering one
- Limitations of `volatile` (e.g. `count++` is not atomic)
- Criteria for correct use of `volatile` (three conditions)
- Typical use case: status/completion/interruption flags (code example: counting sheep)
- JVM `-server` vs `-client` optimisation differences affecting volatile visibility (debugging tip)

## 3.2 — Publication and Escape
- Definition of publication and escape
- Ways an object can be published: public static field, returning from non-private method, passing to alien method, inner class instances
- Transitive publication (publishing one object indirectly publishes reachable objects)
- Alien methods: definition and risk when passing objects to them
- Encapsulation as defence against uncontrolled escape
- Implicit `this` escape via inner class instances (code example: `ThisEscape`)

### 3.2.1 — Safe Construction Practices
- `this` reference escaping during construction: risks of publishing an incompletely constructed object
- Starting a thread from a constructor (why it is dangerous; prefer a factory/`start` method)
- Calling overrideable methods from a constructor
- Private constructor + public factory method pattern to prevent `this` escape (code example: `SafeListener`)

## 3.3 — Thread Confinement
- Thread confinement as a strategy to avoid synchronisation entirely
- Swing event dispatch thread as a real-world example
- JDBC `Connection` pooling as a real-world example of implicit confinement
- Language provides no enforcement mechanism; confinement is a design discipline

### 3.3.1 — Ad-hoc Thread Confinement
- Ad-hoc confinement: definition and fragility
- Single-threaded subsystems (e.g. GUI) as a motivation
- Special case: single-writer volatile variables (read-modify-write safe when writes confined to one thread)

### 3.3.2 — Stack Confinement
- Stack confinement (within-thread / thread-local usage): definition
- Local variables are intrinsically confined to the executing thread's stack
- Primitive locals: confinement guaranteed by the language
- Object-reference locals: confinement requires programmer discipline to avoid letting the referent escape (code example: `loadTheArk`)

### 3.3.3 — ThreadLocal
- `ThreadLocal<T>`: API (`get`, `set`, `initialValue`), semantics (per-thread copy)
- Use case: per-thread JDBC connections (code example: `ConnectionHolder`)
- Use case: per-thread temporary buffers (e.g. `Integer.toString` pre-Java 5)
- Conceptual model (`Map<Thread,T>`); actual storage in the `Thread` object; GC on thread termination
- Use in application frameworks (e.g. J2EE transaction context)
- Abuse potential: hidden global state, reduced reusability

## 3.4 — Immutability
- Immutable objects are inherently thread-safe (no synchronisation needed)
- Definition of immutability (three conditions: unmodifiable state, all fields `final`, proper construction)
- `final` fields alone do not guarantee immutability (final reference to mutable object)
- Immutable objects built on top of mutable internals (code example: `ThreeStooges`)
- Difference between an immutable object and an immutable reference
- Replacing immutable objects to update program state

### 3.4.1 — Final Fields
- `final` keyword semantics (cannot reassign; referred-to object may still be mutable)
- Special JMM semantics of `final` fields: initialization safety guarantee
- Best practice: make fields `final` unless they need to be mutable

### 3.4.2 — Example: Using Volatile to Publish Immutable Objects
- Immutable holder class pattern for atomically related state (code example: `OneValueCache`)
- Combining `volatile` reference + immutable holder for lock-free thread safety (code example: `VolatileCachedFactorizer`)
- Defensive copying (`Arrays.copyOf`) to preserve immutability

## 3.5 — Safe Publication
- Unsafe publication: storing a reference in a public field without synchronisation (code example: `Holder`)
- Observing a partially constructed object due to improper publication

### 3.5.1 — Improper Publication: When Good Objects Go Bad
- Stale/inconsistent state from improper publication (detailed, with `assertSanity` example)
- Default-value writes by the `Object` constructor as a source of stale field values

### 3.5.2 — Immutable Objects and Initialization Safety
- JMM initialization safety guarantee for immutable objects
- Immutable objects can be safely accessed without synchronisation even when not safely published
- Guarantee extends to all `final` fields of properly constructed objects
- Caveat: `final` fields referring to mutable objects still need synchronisation for the referred-to object's state

### 3.5.3 — Safe Publication Idioms
- Four safe publication mechanisms (static initialiser; `volatile`/`AtomicReference`; `final` field; lock-guarded field)
- Thread-safe collections as safe publication vehicles (`Hashtable`, `synchronizedMap`, `ConcurrentMap`, `Vector`, `CopyOnWriteArrayList`, `BlockingQueue`, `ConcurrentLinkedQueue`, etc.)
- Other handoff mechanisms: `Future`, `Exchanger`
- Static initialisers and JVM class-loading synchronisation

### 3.5.4 — Effectively Immutable Objects
- Definition of effectively immutable objects (not technically immutable, but treated as immutable after publication)
- Safe publication is sufficient for effectively immutable objects (no further synchronisation needed)
- Example: `Date` values in a `synchronizedMap`

### 3.5.5 — Mutable Objects
- Publication requirements by mutability tier: immutable (any mechanism), effectively immutable (safe publication), mutable (safe publication + thread-safe or guarded)
- Ongoing synchronisation needed for every access to shared mutable objects

### 3.5.6 — Sharing Objects Safely
- Four policies for using and sharing objects in concurrent programs: thread-confined, shared read-only, shared thread-safe, guarded
- Documenting the "rules of engagement" for shared objects
