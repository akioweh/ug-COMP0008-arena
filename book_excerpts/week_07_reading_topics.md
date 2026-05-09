# Week 7 — Reading Topics

## Essential readings

**GPBBHL 1.1 — A (Very) Brief History of Concurrency**
- Evolution from single-program computers to multiprogramming operating systems (brief historical sketch)
- Processes: definition, isolation, OS-allocated resources (memory, file handles, security credentials)
- Inter-process communication mechanisms: sockets, signal handlers, shared memory, semaphores, files (enumerated, not detailed)
- Motivations for concurrency: resource utilisation, fairness, convenience
- Sequential programming model and the von Neumann process abstraction
- Threads: definition, relationship to processes, shared vs. per-thread state (program counter, stack, local variables)
- Threads as lightweight processes; threads as the OS scheduling unit
- Shared memory between threads and the need for explicit synchronisation (introduction only)

**GPBBHL 1.2 — Benefits of Threads**

*1.2.1 — Exploiting Multiple Processors*
- Multi-core / multiprocessor trend and its implications for software
- Throughput improvement via parallel execution on multiple CPUs
- Throughput improvement on single-processor systems by overlapping computation with blocking I/O

*1.2.2 — Simplicity of Modeling*
- Thread-per-task decomposition: turning asynchronous workflows into simpler sequential ones
- Frameworks that exploit this pattern: servlets, RMI (brief examples)

*1.2.3 — Simplified Handling of Asynchronous Events*
- Thread-per-connection model for server applications using synchronous I/O
- Non-blocking I/O as the alternative for single-threaded servers (mentioned as more complex)
- Multiplexed I/O facilities: Unix `select`/`poll`, Java NIO (`java.nio`) (mentioned, not detailed)
- OS thread-count limits and their historical impact; improving OS support (NPTL)

*1.2.4 — More Responsive User Interfaces*
- Problem of UI freezing in single-threaded GUI applications (main event loop)
- Event dispatch thread (EDT) in AWT/Swing
- Offloading long-running tasks to background threads to keep the EDT responsive

## Further readings

**P&H 5.8 — Parallelism and Memory Hierarchies: Cache Coherence**
- Cache coherence problem in multiprocessors sharing physical address space
- Coherence definition (three properties): program order, visibility of writes, write serialisation
- Consistency vs. coherence distinction
- Migration and replication of shared data — definitions
- Cache coherence protocols — concept
- Snooping protocol — concept (broadcast medium, all caches monitor bus)
- Write-invalidate protocol — mechanism and example (detailed table: two CPUs, read/write sequence)
- False sharing — definition and impact of block size
- Memory consistency model (brief): write completion visibility, write ordering assumptions
- Directory-based coherence (brief mention as alternative to snooping)

> **OO "Processes and Threads"** — Oracle Java Tutorial on concurrency fundamentals (online reference, not extracted from PDF)
