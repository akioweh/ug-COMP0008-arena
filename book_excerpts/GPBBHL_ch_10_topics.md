# GPBBHL Chapter 10 — Avoiding Liveness Hazards

## 10.1 — Deadlock
- Tension between safety (locking) and liveness
- Dining philosophers problem as deadlock illustration
- Deadlock definition: cyclic waiting dependency among threads
- Deadlock modelled as a cycle in the is-waiting-for directed graph
- Database deadlock detection and recovery (victim selection, transaction abort/retry) — contrast with JVM
- JVM non-recoverability of deadlock: deadlocked threads are permanently lost; only remedy is application restart
- Deadlocks as latent bugs that surface under heavy load

### 10.1.1 — Lock-ordering Deadlocks
- Lock-ordering deadlock: two threads acquiring the same two locks in opposite orders (worked code example: `LeftRightDeadlock`)
- Fixed global lock-ordering as the fundamental prevention rule
- Need for global (whole-program) analysis of locking behaviour, not just per-method inspection

### 10.1.2 — Dynamic Lock Order Deadlocks
- Lock order determined by runtime arguments rather than static code structure (worked code example: `transferMoney`)
- Inducing a consistent lock order via `System.identityHashCode` (detailed technique with code)
- Tie-breaking lock for the rare case of hash-code collision
- Using a natural unique comparable key (e.g. account number) as an alternative ordering
- `DemonstrateDeadlock` driver showing how quickly deadlock manifests under moderate concurrency (code example)

### 10.1.3 — Deadlocks Between Cooperating Objects
- Deadlock from implicit multi-lock acquisition across collaborating classes (worked code example: `Taxi` / `Dispatcher`)
- Alien method calls: calling a method on another object while holding a lock, where the callee may acquire further locks
- Difficulty of spotting cross-object lock ordering compared to single-method nested locks

### 10.1.4 — Open Calls
- Open call definition: a method invocation made with no locks held
- Open calls as a design principle for deadlock avoidance (analogy to encapsulation for thread safety)
- Refactoring synchronized methods into smaller synchronized blocks to enable open calls (worked code example: refactored `Taxi` / `Dispatcher`)
- Trade-off: loss of atomicity when shrinking synchronized regions; when this is acceptable vs. when it is not
- Protocol-based exclusion as an alternative to lock-based exclusion (e.g. service shutdown pattern — setting state to "shutting down" then releasing the lock)

### 10.1.5 — Resource Deadlocks
- Deadlock on non-lock resources (e.g. two database connection pools with cyclic acquisition order)
- Thread-starvation deadlock: a task waiting on the result of another task submitted to the same bounded thread pool
- Bounded pools and interdependent tasks as a dangerous combination

## 10.2 — Avoiding and Diagnosing Deadlocks
- Single-lock-at-a-time as the simplest deadlock avoidance strategy
- Lock ordering as a design-time discipline: minimise potential locking interactions, document ordering protocols
- Two-part audit strategy: (1) identify all multi-lock acquisition sites, (2) verify global ordering consistency
- Open calls as a simplifier for the audit

### 10.2.1 — Timed Lock Attempts
- `tryLock` with timeout on explicit `Lock` classes as a deadlock detection/recovery mechanism
- Timeout-and-retry (back off, release locks, retry) for probabilistic deadlock avoidance
- Limitation: only works when both locks are acquired together (not across nested method calls)
- Ambiguity of timeout failure cause (deadlock vs. slow holder vs. infinite loop)

### 10.2.2 — Deadlock Analysis with Thread Dumps
- JVM thread dumps: stack traces plus locking information per thread
- Automatic is-waiting-for graph cycle detection performed by the JVM before emitting the dump
- How to trigger a thread dump: `SIGQUIT` / `kill -3`, `Ctrl-\` (Unix), `Ctrl-Break` (Windows), IDE integration
- Java 5 limitation: explicit `Lock` objects not visible in thread dumps; Java 6 adds support (with less precise acquisition location)
- Real-world deadlock diagnosis walkthrough: multi-vendor J2EE + JDBC driver interaction (worked thread-dump example)

## 10.3 — Other Liveness Hazards
- Enumeration of non-deadlock liveness hazards: starvation, missed signals, livelock
- Missed signals deferred to Section 14.2.3 (mention only)

### 10.3.1 — Starvation
- Starvation definition: thread perpetually denied resources (typically CPU cycles)
- Causes in Java: inappropriate thread priorities; holding a lock during nonterminating operations
- Thread priority API: ten levels, mapped platform-specifically to OS scheduling priorities; mapping is many-to-fewer
- Advice against tweaking thread priorities (platform dependence, risk of starvation)
- `Thread.yield` and `Thread.sleep(0)` semantics are undefined by JLS

### 10.3.2 — Poor Responsiveness
- Poor responsiveness as a liveness-adjacent problem, especially in GUI applications
- CPU-intensive background threads competing with the event thread
- Legitimate use case for lowering thread priority: background computation behind a responsive UI
- Long-held locks (e.g. iterating large collections) causing poor responsiveness for other threads

### 10.3.3 — Livelock
- Livelock definition: thread not blocked but unable to make progress due to repeated failed retries
- Poison message problem in transactional messaging (detailed example)
- Livelock from overeager error-recovery treating unrecoverable errors as recoverable
- Cooperative livelock: multiple threads repeatedly yielding to each other (hallway analogy)
- Solution: introduce randomness and exponential back-off into retry mechanisms (Ethernet collision protocol as analogy)

## Summary
- Liveness failures are unrecoverable without application restart
- Lock-ordering deadlock is the most common form; prevented by consistent global lock ordering
- Open calls are the primary design tool for achieving consistent lock ordering
