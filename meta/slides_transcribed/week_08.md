> Source: [COMP0008\_08.pdf](slides_original/COMP0008_08.pdf)

# Week 8 — Thread Safety, Synchronisation, and Locking in Java

Essential reading: GPBBHL chapter 2.

## Concurrency Recap

Modern hardware supports true parallelism, enabling better performance — threads can execute simultaneously on different cores. However, threads' interactions can non-deterministically lead to unwanted results, depending on hardware, OS, workload, interrupts, etc. These interactions can be modelled by the concurrency abstraction. We generally need to forbid some interleavings to guarantee correctness.

## A Factorising Web Service

Consider a server that factorises input numbers: each client request contains an integer X, and the server responds with a list of factors that multiply to X. We want to assign one thread per client request for performance and reactiveness.

The server process has shared code, data, and heap segments, while each thread has its own registers and stack.

### Java Servlets

Servlets are a framework for implementing Java programs that run within a web server, providing native support for request-response applications. To define an application, one implements new servlet classes — each servlet defines a component of the server application, created by implementing methods specified by the `Servlet` interface.

The servlet concurrency model:
- Each client request is served by one thread.
- Each servlet can be called from multiple threads.
- Threads accessing the same servlet share the servlet's state.

**Servlets in this module** are used to demonstrate that concurrency is crucial even "just" to use existing frameworks or libraries, and to provide background for examples in [GPBBHL]. In-depth study of servlets or the full servlet package is *not* required. Additional resources: [Java EE 5 Servlet Tutorial](https://docs.oracle.com/javaee/5/tutorial/doc/bnafe.html).

## Thread Safety and Race Conditions

**Thread safety** means correctness (never being in an invalid state) irrespective of the interactions between threads. Correctness can be formalised as pre-conditions, post-conditions, and invariants.

Thread safety implies **no race condition**. A race condition is an incorrect computation that occurs only in specific interleavings (e.g., unlucky timings).

**Practical definition** used in this module: an application (resp. class) is thread safe if it allows the same set of outputs (resp. states) regardless of the number and timings of threads.

## Iterative Development of the Factoriser

### Iteration 1: SimpleFactorizer (stateless — thread safe)

```java
public class SimpleFactorizer implements Servlet {
    public void service(ServletRequest req,
                        ServletResponse resp) {
        BigInteger i = extract(req);
        BigInteger[] factors = factorize(i);
        encodeInResponse(resp, factors);
    }
    ...
}
```

This servlet is **stateless** — no information is carried from one request to the next. It is **thread safe** because when calling `service()`, each thread stores method-local variables in its own stack, which is not accessible by other threads.

### Iteration 2: CachingFactorizer (shared state — not thread safe)

To improve performance (factorising is expensive), we cache the last factorisation by adding instance fields:

```java
public class CachingFactorizer implements Servlet {
    private BigInteger lastNumber;
    private BigInteger[] lastFactors;

    public void service(ServletRequest req,
                        ServletResponse resp) {
        BigInteger i = extract(req);
        BigInteger[] factors = null;
        if (i.equals(lastNumber)) {
            factors = lastFactors.clone();
        }
        if (factors == null) {
            factors = factorize(i);
            lastNumber = i;
            lastFactors = factors;
        }
        encodeInResponse(resp, factors);
    }
}
```

This is **not thread safe**. Two post-conditions must hold:
1. The product of `lastFactors` equals `lastNumber`.
2. Each response encodes the factors for the number in the corresponding request.

Both can be violated by race conditions.

**Race condition #1 — inconsistent cache state (violates post-condition #1):**

| Step | Thread | Action |
|------|--------|--------|
| 1 | A | `lastNumber = X` |
| 2 | B | `lastNumber = Y` |
| 3 | B | `lastFactors = factorize(Y)` |
| 4 | A | `lastFactors = factorize(X)` |

Outcome: `lastNumber = Y`, `lastFactors = factorize(X)` — mismatch.

**Race condition #2 — wrong response (violates post-condition #2):**

| Step | Thread | Action |
|------|--------|--------|
| 1 | A | `lastNumber.equals(X)` → true |
| 2 | B | `lastFactors = factorize(Y)` |
| 3 | A | `factors = lastFactors` |

Outcome: thread A sends back the factors of Y instead of X.

### Analysis: the Need for Synchronisation

Multiple threads have access to the same variables — `lastNumber` and `lastFactors` are instance fields, hence shared across threads. The problem is that shared variables are modified by different threads running concurrently, leading to inconsistent modifications.

The solution is to coordinate threads by enforcing **atomicity** of actions on shared variables. This restricts the set of possible interleavings by synchronising access to shared variables. Sequences of operations that must be atomic to ensure thread safety are called **compound actions**.

### Iteration 3: Synchronised Method (thread safe but slow)

```java
public synchronized void service(ServletRequest req,
                                 ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = null;
    if (i.equals(lastNumber)) {
        factors = lastFactors.clone();
    }
    if (factors == null) {
        factors = factorize(i);
        lastNumber = i;
        lastFactors = factors;
    }
    encodeInResponse(resp, factors);
}
```

Only one thread at a time can execute this method. Technically, one thread acquires a lock (linked to `this` object) before executing the method; other threads trying to execute it are forced to wait for the lock to be released.

This is **thread safe but slow**: only one thread at a time performs the expensive factorisation. Despite using multi-threading and caching, performance is very close to a single-threaded application.

### Iteration 4: Fine-Grained Locking (thread safe and faster)

```java
public void service(ServletRequest req,
                    ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = null;
    synchronized (this) {
        if (i.equals(lastNumber))
            factors = lastFactors.clone();
    }
    if (factors == null) {
        factors = factorize(i);
        synchronized (this) {
            lastNumber = i;
            lastFactors = factors;
        }
    }
    encodeInResponse(resp, factors);
}
```

Only reads and updates to `lastNumber` and `lastFactors` are serialised. Multiple threads can factorise integers in parallel.

### Iteration 5: Refactoring with Synchronised Helper Methods

The critical sections can be isolated into synchronised methods:

```java
public void service(ServletRequest req,
                    ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = getSavedFactors(i);
    if (factors == null) {
        factors = factorize(i);
        saveState(i, factors);
    }
    encodeInResponse(resp, factors);
}

private synchronized BigInteger[] getSavedFactors(BigInteger i) {
    if (i.equals(lastNumber)) {
        return lastFactors.clone();
    }
    return null;
}

private synchronized void saveState(BigInteger i,
                                    BigInteger[] factors) {
    lastNumber = i;
    lastFactors = factors;
}
```

## Lessons Learned

### Centrality of State

An object's **state** is its internal data that affects externally visible behaviour — typically instance and static fields, but can also include fields from dependent objects.

Threads that share and arbitrarily modify state can cause concurrency problems called **interference** (e.g., state inconsistently mixes updates from two threads).

**General rule:** whenever multiple threads access a given mutable state variable, we **must** coordinate their access to it using synchronisation. Otherwise, the program is broken.

### Importance of Design

Retrofitting thread safety is hard — it entails evaluating *all possible accesses* to any shared resources by any set of spawned threads, typically requiring checking very many code paths and interleavings.

The solution is to **design with thread safety in mind**. For each state variable, consider: (i) does it need to be shared? (ii) must it be mutable? (iii) must access to it be synchronised?

There is often a **tradeoff between correctness, simplicity, and performance**. Using synchronisation everywhere makes it simpler to write multi-threaded code but can hurt performance — and even correctness (covered in week 10).

### Available Tools

**Locking:** the `synchronized` keyword enables use of Java implicit locks that enforce mutual exclusion. Blocks of instructions guarded by the same lock cannot be executed by more than one thread at any time. This is the basis for supporting synchronisation policies.

**Good software engineering practices** are also useful:
- **Encapsulation and data hiding:** internal state of an object is directly accessible only by the object itself.
- **Immutability:** make variables immutable when their value should not change over time.
- **Documentation**, especially of invariants.

## The Big Garden Application

Inspired by the Ornamental Garden problem (Magee & Kramer, ch. 4). A garden is open to the public, with people entering through either of two turnstiles. Visitors are counted at each turnstile and for the entire garden.

The "Big Garden" is a generalisation for N turnstiles, with simplified and updated code.

The garden has a shared `Count` variable, with a West Turnstile and an East Turnstile each incrementing it — a classic shared-mutable-state scenario.

## Exercises: Synchronised Methods

Given the following class:

```java
public class Example {
    private int x = 2;
    private int y = 3;

    public void a() {
        y = 2 * x;
    }

    public synchronized void b() {
        x = x + y;
    }

    public synchronized void c() {
        y = 2 * x;
    }
    ...
}
```

**Q1: Can two threads run `b()` and `c()` concurrently on the same `Example` instance?**
No — both are `synchronized`, so they acquire the same implicit lock on `this`. By definition of `synchronized`, only one can execute at a time on the same instance.

**Q2: What are the possible values of `[x, y]` if `b()` and `c()` are run on the same instance?**
Only two possible interleavings:
- Interleaving #1: first `b()` → `[5, 3]`, then `c()` → `[5, 10]`.
- Interleaving #2: first `c()` → `[2, 4]`, then `b()` → `[6, 4]`.

**Q3: Can two threads run `a()` and `b()` concurrently on the same instance?**
Yes — `a()` is not `synchronized`, so it does not acquire the lock. It can run concurrently with `b()` even on the same instance.

**Q4: What are the possible values of `[x, y]` if `a()` and `b()` are run concurrently on the same instance?**
Effectively no synchronisation, so all possible interleavings of atomic actions are permitted. Beyond the two sequential outcomes (`[6, 4]` from a-then-b and `[5, 10]` from b-then-a), the value `[5, 4]` is also possible via interleaving:
1. `a()` reads `x = 2`
2. `b()` sets `x = 5`
3. `a()` sets `y = 2 * 2 = 4`

**Q5: Is the `Example` class thread safe?**
Technically it depends on the specification, but threads can interfere when running `a()`, generating values of `[x, y]` that would be impossible with proper synchronisation. In practice, the class is **not** thread safe.

## Additional Content and References

The following topics are covered in supplementary materials:
- **Java thread specifics** [Moodle] — including Java syntax and threads' lifecycle.
- **Standalone Java code** [Moodle] — examples not relying on external frameworks like Servlets.
- **Use of thread-safe libraries** [GPBBHL ch. 2] — e.g., those in `java.util.concurrent`. Main takeaway: thread-safe libraries are useful but do **not** solve all concurrency problems in your application.
- **Lock reentrancy** [GPBBHL 2.3.2] — threads can re-acquire locks they already hold.

<!-- transcription-audit:
- Dropped: slide 1 — title slide (boilerplate; reference preserved at top)
- Dropped: slide 2 — warmup/logistics (Mentimeter self-assessment, interaction encouragement)
- Dropped: slides 3–4 — build-up animation duplicates of slide 5 ("concurrency story so far")
- Dropped: slide 7 — build-up animation duplicate of slide 8 ("Java Servlets")
- Dropped: slide 11 — near-duplicate of slide 10 with added question, content merged
- Dropped: slides 12–13 — build-up animation duplicates of slide 14 ("Defining correctness")
- Dropped: slide 22 — build-up animation duplicate of slide 23 ("Analysis: synchronisation")
- Dropped: slide 25 — near-duplicate of slide 24/26 (same code, transition slide)
- Dropped: slides 30, 32 — build-up animation duplicates of slides 31, 33
- Dropped: slide 36 — Mentimeter poll logistics
- Dropped: slides 37, 39, 41, 43, 45 — question-only slides (merged with their answer slides 38, 40, 42, 44, 46)
- Warnings: none
- Ambiguities:
  - Q4 answer on slide 44: the two sequential outcomes are [6,4] (a then b) and [5,10] (b then a). The interleaved outcome [5,4] is genuinely new — a() reads x=2 before b() updates it, but b() finishes first, leaving x=5 while a() writes y=4. Transcribed faithfully.
-->
