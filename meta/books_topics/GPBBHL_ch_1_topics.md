# GPBBHL Chapter 1 — Introduction

## 1.1 — A (Very) Brief History of Concurrency
- Evolution from single-program computers to multiprogramming operating systems (brief historical sketch)
- Processes: definition, isolation, OS-allocated resources (memory, file handles, security credentials)
- Inter-process communication mechanisms: sockets, signal handlers, shared memory, semaphores, files (enumerated, not detailed)
- Motivations for concurrency: resource utilisation, fairness, convenience
- Sequential programming model and the von Neumann process abstraction
- Threads: definition, relationship to processes, shared vs. per-thread state (program counter, stack, local variables)
- Threads as lightweight processes; threads as the OS scheduling unit
- Shared memory between threads and the need for explicit synchronisation (introduction only)

## 1.2 — Benefits of Threads

### 1.2.1 — Exploiting Multiple Processors
- Multi-core / multiprocessor trend and its implications for software
- Throughput improvement via parallel execution on multiple CPUs
- Throughput improvement on single-processor systems by overlapping computation with blocking I/O

### 1.2.2 — Simplicity of Modeling
- Thread-per-task decomposition: turning asynchronous workflows into simpler sequential ones
- Frameworks that exploit this pattern: servlets, RMI (brief examples)

### 1.2.3 — Simplified Handling of Asynchronous Events
- Thread-per-connection model for server applications using synchronous I/O
- Non-blocking I/O as the alternative for single-threaded servers (mentioned as more complex)
- Multiplexed I/O facilities: Unix `select`/`poll`, Java NIO (`java.nio`) (mentioned, not detailed)
- OS thread-count limits and their historical impact; improving OS support (NPTL)

### 1.2.4 — More Responsive User Interfaces
- Problem of UI freezing in single-threaded GUI applications (main event loop)
- Event dispatch thread (EDT) in AWT/Swing
- Offloading long-running tasks to background threads to keep the EDT responsive

## 1.3 — Risks of Threads
- Java's cross-platform memory model as enabler of portable concurrent code (mentioned)
- Thread safety as a mainstream (not "advanced") concern

### 1.3.1 — Safety Hazards
- Race conditions (introduced with a worked example: `UnsafeSequence`)
- Non-atomicity of `value++` (read-modify-write): three separate operations
- Thread interleaving diagrams as a reasoning tool
- `synchronized` methods as a fix (shown with `Sequence` example)
- Thread-safety annotations: `@NotThreadSafe`, `@ThreadSafe`, `@Immutable`, `@GuardedBy` (introduced)
- Compiler/hardware reordering and caching optimisations that affect visibility (brief mention, deferred to Chapters 2, 3, 16)

### 1.3.2 — Liveness Hazards
- Safety vs. liveness: "nothing bad ever happens" vs. "something good eventually happens" (informal definitions)
- Liveness failure: permanent inability to make forward progress
- Deadlock, starvation, livelock (enumerated, not detailed; deferred to Chapter 10)
- Non-deterministic manifestation of liveness bugs

### 1.3.3 — Performance Hazards
- Performance dimensions: service time, responsiveness, throughput, resource consumption, scalability
- Context-switch overhead: saving/restoring execution context, loss of locality, scheduling CPU cost
- Synchronisation overhead: inhibited compiler optimisations, cache flushing/invalidation, shared-memory-bus traffic (brief; deferred to Chapter 11)

## 1.4 — Threads are Everywhere
- Implicit threading: frameworks create threads on the application's behalf
- JVM-internal threads: garbage collection, finalisation, `main` thread
- Thread-safety as a "contagious" property — ripples from framework code into application state
- Timer / `TimerTask`: scheduled execution in a Timer-managed thread; thread-safety implications
- Servlets and JSPs: concurrent request handling; shared state via `ServletContext` and `HttpSession`
- Remote Method Invocation (RMI): calls arrive on RMI-managed threads; need for thread-safe remote objects
- Swing and AWT: event dispatch thread, thread confinement of GUI components, accessing shared application state from event handlers
