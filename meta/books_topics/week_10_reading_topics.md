# Week 10 — Reading Topics

## Essential readings

**GPBBHL 10 — Avoiding Liveness Hazards**

*10.1 — Deadlock*
- Deadlock definition: cyclic waiting dependency; is-waiting-for directed graph
- Dining philosophers as deadlock illustration
- Database deadlock detection/recovery vs JVM non-recoverability (deadlocked threads permanently lost)
- Deadlocks as latent bugs surfacing under load

*10.1.1 — Lock-ordering Deadlocks*
- Two threads acquiring same two locks in opposite order (worked example: `LeftRightDeadlock`)
- Fixed global lock-ordering as fundamental prevention rule
- Need for whole-program locking analysis

*10.1.2 — Dynamic Lock Order Deadlocks*
- Lock order determined by runtime arguments (worked example: `transferMoney`)
- Inducing consistent order via `System.identityHashCode` (detailed, with tie-breaking lock)
- Natural unique key as alternative ordering

*10.1.3 — Deadlocks Between Cooperating Objects*
- Implicit multi-lock acquisition across collaborating classes (worked example: `Taxi`/`Dispatcher`)
- Alien method calls while holding a lock

*10.1.4 — Open Calls*
- Open call definition: method invocation with no locks held
- Open calls as deadlock avoidance design principle (analogy to encapsulation)
- Refactoring synchronized methods into smaller blocks for open calls (worked example)
- Trade-off: loss of atomicity when shrinking synchronized regions

*10.1.5 — Resource Deadlocks*
- Deadlock on non-lock resources (e.g. database connection pools with cyclic acquisition)
- Thread-starvation deadlock: task waiting on result from another task in the same bounded pool

*10.2 — Avoiding and Diagnosing Deadlocks*
- Single-lock-at-a-time as simplest avoidance strategy
- Lock ordering as design-time discipline; document ordering protocols
- Two-part audit: identify multi-lock sites, verify global ordering consistency

*10.2.1 — Timed Lock Attempts*
- `tryLock` with timeout on explicit `Lock` classes for detection/recovery
- Timeout-and-retry with back-off for probabilistic avoidance
- Ambiguity of timeout failure cause

*10.2.2 — Deadlock Analysis with Thread Dumps*
- JVM thread dumps: stack traces + locking info per thread
- Automatic is-waiting-for graph cycle detection
- Triggering thread dumps (`SIGQUIT`/`kill -3`, `Ctrl-\`, `Ctrl-Break`)
- Java 5 vs 6 explicit `Lock` visibility in dumps

*10.3 — Other Liveness Hazards*

*10.3.1 — Starvation*
- Starvation definition: thread perpetually denied resources
- Thread priority API: ten levels, platform-specific mapping
- Advice against tweaking priorities

*10.3.2 — Poor Responsiveness*
- CPU-intensive background threads competing with event thread
- Long-held locks causing poor responsiveness

*10.3.3 — Livelock*
- Livelock definition: thread not blocked but unable to progress due to repeated failed retries
- Poison message problem in transactional messaging (detailed example)
- Cooperative livelock: threads repeatedly yielding to each other
- Solution: randomness and exponential back-off in retry mechanisms
