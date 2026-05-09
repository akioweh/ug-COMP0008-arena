# GPBBHL Chapter 4 — Composing Objects

## 4.1 — Designing a Thread-safe Class
- Three-element design process for thread-safe classes: identify state, identify invariants, establish concurrent-access policy
- Object state as the n-tuple of its fields (including transitively referenced objects)
- Synchronization policy: definition and role (combination of immutability, confinement, and locking)
- Importance of documenting the synchronization policy

### 4.1.1 — Gathering Synchronization Requirements
- State space of an object and how `final` fields / immutability reduce it
- Class invariants constraining valid states (worked example: `Counter` disallowing negative values)
- Post-conditions constraining valid state transitions (e.g. counter can only go from 17 to 18)
- How invariants and post-conditions create atomicity and encapsulation requirements
- Multivariable invariants and the need to hold a single lock across all related variable accesses (worked example: `NumberRange` lower/upper)

### 4.1.2 — State-dependent Operations
- State-based preconditions (e.g. "queue must be non-empty to remove")
- Difference between single-threaded failure and concurrent waiting-for-precondition
- `wait`/`notify` and intrinsic locking (brief mention; deferred to Ch. 14)
- Using library classes (`BlockingQueue`, `Semaphore`) for state-dependent behaviour (brief mention; deferred to Ch. 5)

### 4.1.3 — State Ownership
- Ownership as a class-design concept (not enforced by the language)
- Logical state of a composite object spanning its internal sub-objects (e.g. `HashMap` owns its `Map.Entry` objects)
- Relationship between ownership and encapsulation; the owner chooses the locking protocol
- Publishing a mutable reference as loss of exclusive ownership ("shared ownership")
- Split ownership in collections: collection infrastructure vs. stored elements (worked example: `ServletContext` / `HttpSession`)

## 4.2 — Instance Confinement
- Confining a non-thread-safe object to make it usable in a multithreaded program
- Three scopes of confinement: class instance (private field), lexical scope (local variable), thread
- Combining confinement with a locking discipline (worked example: `PersonSet` wrapping a `HashSet`)
- Thread-safety obligations for mutable objects retrieved from a confined collection
- Flexibility of confinement: any consistent lock will do; different state variables may use different locks
- Synchronized collection wrappers (`Collections.synchronizedList` etc.) as confinement via the Decorator pattern
- Violating confinement: publishing supposedly confined objects (directly or via iterators / inner classes)

### 4.2.1 — The Java Monitor Pattern
- Definition: encapsulate all mutable state and guard it with the object's own intrinsic lock
- Relationship to Hoare monitors (brief historical note; `monitorenter`/`monitorexit` bytecodes)
- Using a private lock object instead of the intrinsic lock: encapsulating the lock, preventing client interference (code example: `PrivateLock`)
- Library examples: `Vector`, `Hashtable`

### 4.2.2 — Example: Tracking Fleet Vehicles
- Monitor-based `VehicleTracker` design (detailed worked example with `MonitorVehicleTracker`, `MutablePoint`)
- Deep-copying mutable state on return to preserve thread safety
- Snapshot semantics vs. live-view semantics (trade-offs)
- Performance implications of copying under lock (responsiveness concern with large data sets)

## 4.3 — Delegating Thread Safety
- Concept of delegating thread-safety responsibility to an already-thread-safe component
- When delegation alone is sufficient vs. when additional synchronization is needed

### 4.3.1 — Example: Vehicle Tracker Using Delegation
- `DelegatingVehicleTracker` using `ConcurrentHashMap` and immutable `Point` (detailed worked example)
- Eliminating explicit synchronization and defensive copying via immutability
- Returning an unmodifiable live view vs. a shallow-copy snapshot (code for both)
- Behavioural difference from the monitor-based version (live view vs. snapshot)

### 4.3.2 — Independent State Variables
- Delegating to multiple underlying thread-safe state variables when they are independent (no cross-variable invariants)
- `VisualComponent` example: two independent `CopyOnWriteArrayList` listener lists (detailed worked example)

### 4.3.3 — When Delegation Fails
- Dependent state variables with a multivariable invariant break delegation (`NumberRange` with two `AtomicInteger`s — detailed worked example)
- Check-then-act race in `setLower`/`setUpper` despite individually thread-safe components
- Remediation: guard related variables with a common lock; avoid publishing them
- Rule: delegation works only when state variables are independent and no compound actions exist
- Analogy to the volatile-variable rule (variable must not participate in invariants with other variables)

### 4.3.4 — Publishing Underlying State Variables
- Conditions under which an underlying thread-safe state variable can be safely published to clients
- Rule: safe to publish if the variable is thread-safe, has no constraining invariants, and no prohibited state transitions
- Example: `mouseListeners`/`keyListeners` in `VisualComponent` can be published

### 4.3.5 — Example: Vehicle Tracker that Publishes Its State
- `SafePoint`: a thread-safe mutable point class returning both coordinates atomically (detailed code example)
- Private constructor capture idiom to avoid race condition in copy constructor
- `PublishingVehicleTracker`: delegates to `ConcurrentHashMap` of `SafePoint`s, safely publishes mutable state (detailed code example)
- Limitations: not suitable if the class needs to veto or react to changes

## 4.4 — Adding Functionality to Existing Thread-safe Classes
- Motivation: extending a thread-safe class with a new atomic operation (running example: atomic put-if-absent on a `List`)
- Approach 1 — modify the original class (safest; keeps synchronization policy in one place; not always possible)
- Approach 2 — extend the class (e.g. `BetterVector extends Vector`; fragile if base class changes its locking strategy) (code example)
- Fragility of distributing synchronization policy across class hierarchy

### 4.4.1 — Client-side Locking
- Helper-class approach and why synchronizing on the wrong lock fails (`ListHelper` anti-pattern — detailed worked example)
- Client-side / external locking: synchronize on the same lock the object uses internally
- Correct client-side locking for `Collections.synchronizedList` wrappers (code example)
- Fragility: couples to the object's undocumented locking strategy; violates encapsulation of synchronization policy

### 4.4.2 — Composition
- Wrapping with a new class that provides its own consistent locking (`ImprovedList implements List<T>` — detailed code example)
- Independence from the underlying list's thread-safety or locking implementation
- Trade-off: slight performance overhead from extra synchronisation layer, but much less fragile
- Effectively the Java monitor pattern applied to an existing object

## 4.5 — Documenting Synchronization Policies
- Importance of documenting thread-safety guarantees (for clients) and synchronization policy (for maintainers)
- What a synchronization policy comprises: volatile vs. lock-guarded vs. immutable vs. thread-confined variables; which locks guard which variables; which operations are atomic
- `@GuardedBy` annotation as lightweight documentation
- Poor state of thread-safety documentation in the JDK and Java EE specifications (e.g. `SimpleDateFormat` not documented as non-thread-safe until JDK 1.4)

### 4.5.1 — Interpreting Vague Documentation
- Strategy for reasoning about under-documented APIs: interpret the spec from the implementor's perspective
- Inferring thread safety of `ServletContext`, `HttpSession`, `DataSource` from their intended usage patterns ("it would be absurd if it weren't" argument)
- Objects stored in `ServletContext`/`HttpSession` via `setAttribute`: owned by the application, must be made thread-safe by the application
- JDBC `Connection` objects: not assumed shared; confined to a thread in typical use
- General guidance: don't force clients to guess; don't rely on undocumented implementation details
