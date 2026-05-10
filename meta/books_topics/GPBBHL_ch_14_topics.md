# GPBBHL Chapter 14 — Building Custom Synchronizers

## 14.1 — Managing State Dependence
- State-dependent classes and state-based preconditions (definition and motivation)
- Difference between state dependence in sequential vs concurrent programs
- Structure of a blocking state-dependent action (acquire lock, test predicate in loop, release/reacquire pattern) (canonical pseudocode)
- Bounded buffer as running example (array-based circular buffer: `BaseBoundedBuffer`)

### 14.1.1 — Example: Propagating Precondition Failure to Callers
- "Balking" approach: throwing exceptions on precondition failure (`GrumpyBoundedBuffer`) (worked example with code)
- Why exceptions are inappropriate for expected state conditions
- Caller burden: catch-and-retry logic pushed to client
- Returning error values as a variant (brief mention; `Queue.poll` vs `Queue.remove`)
- Busy waiting / spin waiting vs sleeping: CPU usage vs responsiveness trade-off
- `Thread.yield` as a middle ground between spinning and sleeping (brief mention)

### 14.1.2 — Example: Crude Blocking by Polling and Sleeping
- Encapsulating poll-and-sleep retry inside `put`/`take` (`SleepyBoundedBuffer`) (worked example with code)
- Releasing the lock before sleeping, reacquiring after waking
- Sleep granularity trade-off: responsiveness vs CPU consumption
- Thread oversleeping problem (illustrated with timing diagram)
- `InterruptedException` and cancellation support for blocking methods

### 14.1.3 — Condition Queues to the Rescue
- Condition queue concept: wait set of threads waiting for a condition
- Intrinsic condition queues: every Java object as a condition queue (`wait`, `notify`, `notifyAll`)
- Relationship between intrinsic lock and intrinsic condition queue (must hold lock to call condition queue methods)
- `Object.wait` semantics: atomic release-and-suspend, reacquire-on-wake
- Bounded buffer using `wait`/`notifyAll` (`BoundedBuffer`) (worked example with code)
- Condition queues as an optimisation over polling/sleeping (CPU efficiency, context-switch overhead, responsiveness)

## 14.2 — Using Condition Queues
- Difficulty of correct usage; preference for building on existing library classes (`LinkedBlockingQueue`, `CountDownLatch`, `Semaphore`, `FutureTask`)

### 14.2.1 — The Condition Predicate
- Condition predicate: definition and role in state-dependent operations (detailed)
- Three-way relationship: lock, `wait` method, and condition predicate
- Requirement that lock object and condition queue object be the same
- `wait` releases the lock, blocks, then reacquires before returning (detailed mechanics)
- No special priority for threads waking from `wait` in lock reacquisition

### 14.2.2 — Waking Up Too Soon
- Multiple condition predicates on a single intrinsic condition queue
- Spurious wakeups (`wait` returning without `notify`)
- Condition predicate may become false between notification and lock reacquisition
- "Hijacked signal": wakeup consumed by wrong waiter
- Canonical form: always call `wait` in a loop, re-testing the condition predicate (code listing)
- Checklist of rules for correct condition waits (6 rules, boxed)

### 14.2.3 — Missed Signals
- Missed signal as a liveness failure: waiting for an event that already occurred
- Notification is not "sticky"
- Prevention: always test predicate before calling `wait`

### 14.2.4 — Notification
- `notify` vs `notifyAll` semantics
- Ensuring every code path that could make a predicate true performs notification
- Danger of `notify` with multiple condition predicates on one queue (hijacked signal scenario, detailed example)
- Conditions for safe use of single `notify`: uniform waiters + one-in, one-out (formal criteria)
- `notifyAll` as the safe default; O(n^2) wakeup cost in worst case
- Conditional notification: notifying only on state transitions (e.g. empty-to-nonempty) (optimisation with code example)

### 14.2.5 — Example: A Gate Class
- Recloseable `ThreadGate` using `wait`/`notifyAll` (worked example with code)
- Generation counter to handle rapid open/close cycles
- Compound condition predicate: `isOpen || generation > arrivalGeneration`
- Why `notifyAll` is required (fails one-in, one-out test)

### 14.2.6 — Subclass Safety Issues
- Constraints that single/conditional notification place on subclassing
- Design for inheritance: expose and document waiting/notification protocols, or prohibit subclassing
- Example: unbounded blocking stack with subclass adding "pop two" — need to override to `notifyAll`

### 14.2.7 — Encapsulating Condition Queues
- Advice to encapsulate condition queue objects (prevent alien code from waiting on them)
- Tension with common idiom of using `this` as both lock and condition queue
- Private lock and condition queue as alternative (loses client-side locking)

### 14.2.8 — Entry and Exit Protocols
- Wellings' characterisation: entry protocol = condition predicate; exit protocol = check whether state change enables other predicates, then notify
- `AbstractQueuedSynchronizer` and the exit protocol pattern (brief forward reference)

## 14.3 — Explicit Condition Objects
- `Condition` as a generalisation of intrinsic condition queues (parallel to `Lock` generalising intrinsic locks)
- Drawbacks of intrinsic condition queues: single condition queue per lock, exposed condition queue object
- `Condition` interface API: `await`, `signal`, `signalAll`, timed/uninterruptible variants, deadline-based waiting (interface listing)
- Multiple `Condition` objects per `Lock`; fairness inherited from associated `Lock`
- Hazard: `Condition` extends `Object`, so `wait`/`notify` also exist — must use `await`/`signal`
- Bounded buffer with two explicit `Condition`s (`notFull`, `notEmpty`) using `ReentrantLock` (`ConditionBoundedBuffer`) (worked example with code)
- Benefit: separating wait sets enables safe use of `signal` instead of `signalAll`
- Three-way relationship (lock, predicate, condition variable) still applies with explicit `Lock`/`Condition`
- When to choose explicit `Condition` vs intrinsic condition queues (decision guideline)

## 14.4 — Anatomy of a Synchronizer
- Commonality between `ReentrantLock` and `Semaphore` interfaces (gate metaphor: allow, block, turn away)
- Interruptible, uninterruptible, timed acquisition; fair vs nonfair queueing
- Mutual implementability of locks and semaphores (`SemaphoreOnLock`) (worked example with code)
- `AbstractQueuedSynchronizer` (AQS) as common base class for `ReentrantLock`, `Semaphore`, `CountDownLatch`, `ReentrantReadWriteLock`, `SynchronousQueue`, `FutureTask`
- Benefits of AQS: reduced implementation effort, single point of contention, scalability
- Double contention problem when layering one synchronizer on another (e.g. `SemaphoreOnLock`)

## 14.5 — AbstractQueuedSynchronizer
- AQS acquire and release: canonical pseudocode for both (listing)
- Exclusive vs shared (nonexclusive) acquisition modes
- Two parts of acquisition: (1) decide if state permits acquire; (2) update synchronizer state
- AQS state: single `int` managed via `getState`, `setState`, `compareAndSetState`
- How different synchronizers use the state integer (ReentrantLock: acquisition count; Semaphore: permits; FutureTask: task status)
- Protected methods to override: `tryAcquire`/`tryRelease`/`isHeldExclusively` (exclusive); `tryAcquireShared`/`tryReleaseShared` (shared)
- Return value semantics of `tryAcquireShared` (negative = fail, zero = exclusive, positive = nonexclusive)
- AQS support for condition variables associated with synchronizers

### 14.5.1 — A Simple Latch
- `OneShotLatch`: binary latch built on AQS (worked example with code)
- Delegation to private inner `Sync` class extending AQS (design pattern: prefer delegation over inheritance)
- `tryAcquireShared` / `tryReleaseShared` implementation for open/closed latch state
- Why `java.util.concurrent` synchronizers delegate to AQS rather than extending it

## 14.6 — AQS in java.util.concurrent Synchronizer Classes
- Overview: `ReentrantLock`, `Semaphore`, `ReentrantReadWriteLock`, `CountDownLatch`, `SynchronousQueue`, `FutureTask` all built on AQS

### 14.6.1 — ReentrantLock
- Exclusive acquisition: `tryAcquire`, `tryRelease`, `isHeldExclusively` (code for non-fair `tryAcquire`)
- AQS state = lock acquisition count; `owner` field for owning thread
- `compareAndSetState` for atomic state update; reentrant vs contended acquisition differentiation
- Memory semantics piggybacking on synchronization state (forward reference to 16.1.4)
- `Lock.newCondition` returning `ConditionObject` (AQS inner class)

### 14.6.2 — Semaphore and CountDownLatch
- Semaphore: AQS state = available permits; `tryAcquireShared`/`tryReleaseShared` with CAS retry loop (code listing)
- CountDownLatch: AQS state = current count; `countDown` calls `release`, `await` calls `acquire`

### 14.6.3 — FutureTask
- `Future.get` as latch-like semantics (brief)
- AQS state = task status (running, completed, cancelled); additional state for result/exception and runner thread reference

### 14.6.4 — ReentrantReadWriteLock
- Single AQS subclass managing both read and write locks
- State bit-packing: 16 bits for write-lock count, 16 bits for read-lock count
- Read lock uses shared acquire/release; write lock uses exclusive acquire/release
- AQS wait queue: FIFO, head-of-queue determines exclusive vs shared batch release
- No reader-preference / writer-preference policy in this implementation (brief note)

## Summary
- Strategy hierarchy for building state-dependent classes: (1) existing library classes, (2) intrinsic condition queues, (3) explicit `Condition` objects, (4) `AbstractQueuedSynchronizer`
- Intrinsic condition queues bound to intrinsic locks; explicit `Condition`s bound to explicit `Lock`s with extended features
