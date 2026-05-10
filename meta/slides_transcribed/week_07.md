> Source: [COMP0008\_07.pdf](slides_original/COMP0008_07.pdf)

# Week 7: Introduction to Concurrency and Threads

## Recap: From Architecture to Concurrency

Program execution speed is important. Modern hardware uses multiple techniques to support faster execution: pipelining and instruction reordering, memory hierarchy and caching, superscalars, speculation, and out-of-order execution. These techniques do not come for free — they require more complex hardware (and potentially compilers) and introduce data/control hazards. The course now shifts to a programmer's perspective on these issues.

## Motivating Example: Designing a Web Service

Consider implementing a server supporting web-accessible functionalities where many clients can simultaneously request different services (e.g. mathematical computations). Processing client messages requires resources: some functionalities are CPU intensive (long calculations), others are I/O intensive (many memory reads/writes) or network intensive. The question is how to design the server-side application.

### Design 1: Single Process

A monolithic program can be written and executed by the operating system as a single **process**. Behind the scenes, the OS allocates resources (code, data, files, registers, stack) to run the process separately from others on the server.

**Problem:** In production, users complain the application is very slow and blocks at times — yet the network is not the bottleneck, there is no server crash, and no major bug in the code. A minimal reproduction confirms high computation times:

```
$ java SimulateServer
INFO: starting to serve clients
[Client 1] factorized 10 numbers
[Client 2] factorized 10 numbers
...
[Client 10] factorized 10 numbers
INFO: completed client requests in 15801 ms
```

The root cause is that the program uses only 1 of the 64 cores on the server machine. The server process runs on one processor core while the other cores remain idle. A long computation serving one client prevents the server from working for other clients.

### Design 2: Multiple Processes

The program can be structured so the OS runs multiple processes, e.g. one for each client. Behind the scenes, the OS tries to balance the load across cores. Each process gets its own resources (code, data, files, registers, stack).

**Problem:** In production, system administrators complain the application over-utilises servers. Monitoring with `top` reveals each process requires its own resources:

| USER | PID   | %CPU | %MEM | TIME    | COMMAND              |
|------|-------|------|------|---------|----------------------|
| name | 61754 | 78.1 | 0.4  | 0:01.33 | java SimulateServer  |
| name | 61755 | 78.1 | 0.4  | 0:01.33 | java SimulateServer  |
| name | 61758 | 78.1 | 0.5  | 0:01.33 | java SimulateServer  |
| ...  |       |      |      |         |                      |
| name | 61745 | 0.0  | 0.4  | 0:00.10 | java SimulateServer  |

Processes are heavy in terms of resource consumption: the OS allocates separate resources to each process, so too many processes make resources scarce. Inter-process communication is expensive too. In the worst case, the OS spends more time managing processes and allocated resources than doing useful work.

### Design 3: Multiple Threads

The program can be refactored so the OS runs a single process that spawns one **thread** per client. A thread is a part of the program (a sequence of instructions) that the programmer flags as runnable in parallel to other threads.

Behind the scenes, the OS reserves only a few resources to each thread. Threads are lightweight processes that share most resources (code, data, files) but each has its own registers and stack. Threads are also the minimal scheduling units: they run simultaneously, independently, and possibly on different cores.

**Problem:** In production, clients complain the application has bugs. Writing multi-threaded software is much harder than single-threaded software because:

- Multi-threaded software can have unexpected interactions with the underlying performance-optimised hardware. For example, if two threads running on different cores want to modify the same variable nearly at the same time:

```mips
        Core 1                  Core 2
lw      $t1,0($t0)      lw      $t1,0($t0)
addi    $t2,$t1,1        addi    $t2,$t1,1
sw      $t2,0($t0)      sw      $t2,0($t0)
```

- In general, sharing resources (e.g. variables) creates risks of incorrectness (analogous to data hazards in ILP).
- For programmers, it is much more challenging to reason about code executed in parallel.

**Solution:** Synchronisation and design patterns — the topic of the coming weeks.

### Design Tradeoffs

The multi-threaded design is not always the best one. Designs 1 and 2 may be better for applications that are not CPU intensive or not time-sensitive. There is a fundamental tradeoff between simplicity, correctness, and performance. Rule of thumb: target the easiest design that accommodates your requirements. Additional designs also exist, e.g. multi-process with multiple threads per process.

### Multithreading and True Parallelism

Support for multithreading depends on the programming language. For example, Python (CPython) does not support true parallelism by default due to the **Global Interpreter Lock (GIL)**: only one thread can execute Python code at once. The `threading` module operates within a single process where all threads share the same memory space, but the GIL limits performance gains for CPU-bound tasks. For CPU-bound parallelism, Python programmers are advised to use `multiprocessing` or `concurrent.futures.ProcessPoolExecutor`. Threading remains appropriate for I/O-bound tasks. As of Python 3.13, free-threaded builds can disable the GIL (see PEP 703), but this is not available by default.

## The Concurrency Abstraction

### Definition of Interleaving

From the programmer's viewpoint, the hardware can unpredictably interleave actions from all threads. Each thread corresponds to a totally ordered sequence of **atomic actions** — actions that are indivisible in terms of processing.

An **interleaving** is defined as a totally ordered sequence of executed actions across all threads, with three properties:

1. Only one action at a time is executed.
2. Actions from the same thread are executed in order.
3. The overall sequence of executed actions can arbitrarily mix actions from different threads.

Given two threads — Thread 1 with two actions (light-green, dark-green) and Thread 2 with two actions (light-blue, dark-blue) — the possible interleavings include all sequences that preserve within-thread ordering while freely mixing actions across threads. All such interleavings can happen in different runs.

### Correctness of the Abstraction

The abstraction's scope is to model problems arising from actions from different threads (e.g. executed on different cores). Potential concerns are that it assumes a total order across actions, does not model time, and does not model hardware details (instruction reordering, caching, thread-to-core allocation, etc.).

Reassuring observations:

- Only one processor at a time can access shared resources, so hardware effectively imposes a total order — especially regarding when actions finish.
- Hardware also guarantees correctness per thread.
- No bad interleaving means no misbehaviour for any duration of individual actions. One cannot make assumptions about the duration of any specific action. Importantly, `sleep` instructions do **not** solve problematic interleavings.

### Building on the Abstraction

The concurrency abstraction is useful to understand and solve concurrency problems and bugs. Solutions rely on primitives of programming languages. Programming languages have constructs to:

- Define code blocks executed atomically (**critical sections**).
- Restrict the set of possible interleavings.

Programming languages precisely define the guarantees those constructs provide, irrespective of the underlying hardware. These aspects will be studied in Java.

## Counting Interleavings

### Two Threads

**Example 1:** Thread A = {A1, A2}, Thread B = {B1}. In the concurrency abstraction, actions within threads are never reordered (A2 always follows A1). The answer is **3** interleavings: [A1,A2,B1], [A1,B1,A2], [B1,A1,A2].

**Example 2:** Thread A = {A1, A2}, Thread B = {B1, B2}. Enumerating: if A1 is first → [A1,A2,B1,B2], [A1,B1,A2,B2], [A1,B1,B2,A2]; if B1 is first → [B1,A1,A2,B2], [B1,A1,B2,A2], [B1,B2,A1,A2]. No interleaving starts with A2 or B2. The answer is **6**. One more action doubles the number of interleavings.

### General Formula for Two Threads

For two threads A and B where A has $X$ atomic actions and B has $Y$ actions, the number of interleavings is a stars-and-bars calculation. With $n$ stars and $m$ bars, the number of possible sequences (including those with consecutive bars) is the binomial coefficient $\binom{n+m}{n}$.

$$\text{Number of interleavings} = \frac{(X+Y)!}{X!\,Y!}$$

### Three Threads

**Example 1:** Thread A = {A1}, Thread B = {B1}, Thread C = {C1}. Enumerating: A1 first → [A1,B1,C1], [A1,C1,B1]; B1 first → [B1,A1,C1], [B1,C1,A1]; C1 first → [C1,B1,A1], [C1,A1,B1]. The answer is **6**.

**Example 2:** Thread A = {A1, A2}, Thread B = {B1}, Thread C = {C1}. Enumerating: A1 first → [A1,A2,B1,C1], [A1,A2,C1,B1], [A1,B1,A2,C1], [A1,B1,C1,A2], [A1,C1,A2,B1], [A1,C1,B1,A2]; B1 first → [B1,A1,A2,C1], [B1,A1,C1,A2], [B1,C1,A1,A2]; C1 first → [C1,B1,A1,A2], [C1,A1,B1,A2], [C1,A1,A2,B1]. The answer is **12** — twice as many as two threads with two actions each.

## Interleaving Analysis: A Simple Program

Given T1 = {x=5; x=2*x} and T2 = {x=x+2}, what are the possible values of x after both threads terminate?

**Naïve analysis** (treating each statement as atomic):

- Interleaving 1: x=5; x=2\*x; x=x+2 → x=12
- Interleaving 2: x=5; x=x+2; x=2\*x → x=14
- Interleaving 3: x=x+2; x=5; x=2\*x → x=10

**But are all those instructions truly atomic?** The statement `x=2*x` entails both a read and a write and can be decomposed as `t=x; x=2*t`. Similarly, `x=x+2` can be decomposed as `s=x; x=s+2`. With finer-grained atomic actions, additional values become possible:

- Interleaving 4: s=0; (all of T1); x=s+2 → x=2
- Interleaving 5: s=0; x=5; x=s+2; x=2\*x → x=4
- Interleaving 6: x=5; s=5; ...; x=s+2 → x=7

## Lessons Learned

There is a **combinatorial explosion** of possible interleavings. With just two threads, the count follows a binomial coefficient; more threads introduce more degrees of freedom and even more combinations. Real concurrent programs may have many threads, each performing many actions.

Key consequences:

- The combinatorial explosion leads to **unpredictability** and **non-determinism**: many possible results that are hard to enumerate for large programs.
- Some interleavings may be much more likely than others, so concurrency bugs are **hard to uncover** even with testing.
- Other interleavings can happen very rarely, so concurrency bugs are **latent**.
- It is hard to statically analyse real concurrent programs; they need to be **designed well**. Manual analyses and formal tools do not scale.

For this reason, the module focuses on reading and reasoning about concurrent code.

## Essential Reading

- Additional information on threads: **GPBBHL sections 1.1–1.2**, Java documentation — includes brief history and other use cases for threads.
- Support for multithreading at the hardware and OS level (e.g. context switch): **Moodle materials**.
- *Optionally:* Cache coherence — **P&H section 5.8** — follow-up on cache coherence in multicore processors from the previous week.

<!-- transcription-audit:
- Dropped: slide 1 — title slide, boilerplate
- Dropped: slide 2 — warmup/classroom logistics (Mentimeter self-assessment, pacing feedback)
- Dropped: slides 6–8 — animation build-up of Design 1 diagram (merged into single description)
- Dropped: slides 12–14 — animation build-up of Design 2 diagram (merged into single description)
- Dropped: slide 27 — greyed-out recap of Design 3 content, redundant with slides 22–24
- Dropped: slides 28–30 — animation build-up of concurrency abstraction definition (merged into slide 30 final version)
- Dropped: slides 31–34 — animation build-up of interleaving diagram (described in prose)
- Dropped: slide 38 — Mentimeter logistics for CW4 exercise
- Dropped: slide 39 — question-only version of two-threads exercise (answer on slide 40)
- Dropped: slide 41 — question-only version of two-threads variant (answer on slide 42)
- Dropped: slide 43 — question-only version of general formula exercise (answer on slide 44)
- Dropped: slide 45 — question-only version of three-threads exercise (answer on slide 46)
- Dropped: slide 47 — question-only version of three-threads variant (answer on slide 48)
- Dropped: slide 49 — question-only version of simple program exercise (answer on slides 50–52)
- Warnings: Slides 31–34 use colour-coded blocks (light-green, dark-green for Thread 1; light-blue, dark-blue for Thread 2) to illustrate interleaving visually. The spatial/colour semantics have been described in prose but the visual immediacy is lost. The original asset may be worth retaining if the visual is pedagogically important.
- Ambiguities: Slide 26 shows a screenshot of the Python `threading` documentation page including GIL details and PEP 703 reference. Transcribed the substantive content rather than describing the screenshot. The slide's intent appears to be showing that Python's threading docs themselves warn about the GIL limitation.
- Ambiguities: Slide 52 shows interleaving results x=2, x=4, x=7 with abbreviated interleaving descriptions (e.g. "s=0; T1; x=s+2"). Transcribed faithfully as presented; the initial value of x before T1 and T2 start is implicitly 0 (used in s=0 derivation).
-->
