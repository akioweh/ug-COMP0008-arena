> Source: [COMP0008\_09.pdf](../slides_original/COMP0008_09.pdf)

# Week 9 — Visibility, Publication, and the Monitor Pattern

References: GPBBHL chapters 3, 4, and 14.

## Recap: Interference and Synchronisation

Operating systems run threads concurrently, possibly on different processors. **Interference** occurs when threads update shared data simultaneously, leading to inconsistent state (e.g., mixed-up servlet cache entries) or incorrect behaviour (e.g., returning the output for a different input). To ensure correctness, programmers must prevent multiple threads from simultaneously accessing the same shared data. The basic mechanism in Java is **synchronisation** with implicit locking, enforcing **mutual exclusion** for the execution of **critical sections**.

## Visibility Problems

### The Reader Example

Consider the following program:

```java
public class Example {
    private static boolean ready;
    private static int number;

    private static class Reader extends Thread {
        public void run() {
            while (!ready)
                Thread.sleep(1000);
            System.out.println(number);
        }
    }

    public static void main(String[] args) {
        new Reader().start();
        number = 42;
        ready = true;
    }
}
```

**Intention:** The main thread creates a Reader thread, sets `number` to 42, then sets `ready` to `true` to allow the Reader to print and exit. The Reader spins until `ready` is `true`, then prints `number`. The expected output is `42`.

**Is it thread-safe?** The fields `ready` and `number` are shared between the main and Reader threads. However, the Reader thread only *reads* the shared variables — the two threads do not interfere, nor do they induce spurious state changes. Despite this, the program is **not** safe.

**Problem 1 — can loop forever:** There is no guarantee that state changes made by one thread are propagated to other threads. Consequence: the Reader may **never** see `ready` set to `true`, and the loop may never terminate.

**Problem 2 — zero may be printed:** There is no guarantee that consecutive assignments are executed in the order written, nor that all caches are coherent at any moment in time. The JVM or hardware may reorder `number = 42` and `ready = true`, so the Reader could see `ready == true` while `number` is still `0`.

### Visibility vs Interference

A **visibility problem** arises when one thread changes the state but another thread does not see the (entire) new state. In the Reader example, the Reader sees a partial change when it prints zero, and sees no change at all when it fails to terminate.

Visibility is fundamentally different from interference. Interference is about "too much interaction" between threads; visibility is about "too little". The solution is the same in both cases: some form of **synchronisation** is needed whenever a thread accesses data shared with other threads — both reads *and* writes must be synchronised.

### The Concurrency Abstraction and Reordering

The interleaving model defines concurrency by constraining actions within each thread to execute in program order, because hardware guarantees per-thread correctness. However, actions of one thread can be **seen by other threads as reordered** when the reordering does not affect per-thread correctness.

Observations about the concurrency abstraction:

- It is a model, and therefore abstracts from reality (as all models do).
- It is still useful for reasoning about interference problems, e.g., when we are sure there are no other problems.
- *Sometimes* it can be extended to account for reordering by modelling independent instructions as separate "threads" — e.g., in the Reader example, treating `T1:{number=42}` and `T2:{ready=true}` as independent threads.

## Synchronisation and the Java Memory Model

Synchronisation solves visibility because the Java specification states that all threads must "synchronise their working memories" with main memory at the **entry and exit** of `synchronized` segments. Concretely: everything a thread writes before unlocking a monitor **M** is visible to everything another thread reads after locking the same monitor **M**.

<!-- Diagram description (slide 10): Two vertical timelines, Thread A and Thread B.
Thread A executes: y = 1 → Lock M → x = 1 → Unlock M.
Thread B executes: Lock M → i = x.
An arrow from Thread A's Unlock M to Thread B's Lock M indicates the visibility guarantee:
everything before the unlock in Thread A is visible to everything after the lock in Thread B. -->

For any given shared object, there are two high-level goals:

- **G1:** No thread sees a partially constructed object.
- **G2:** All threads see changes to the object's state.

To achieve these goals, we need to understand the **Java Memory Model (JMM)**. The JMM spells out the guarantees the JVM provides about the visibility of one thread's writes to other threads. Synchronisation prevents any instruction reordering that would violate JMM guarantees. The concepts of **publication** and **safe publication** stem directly from the JMM.

## Publication and Safe Publication

An object is **published** when it is made available to code outside its current context — e.g., storing it in a public field, returning it from a public method, or passing it as a parameter.

**Hazard:** Publishing an object in a constructor can make a **partially constructed** object available to external code (including other threads).

An object is **safely published** if both the reference to the object and its state are made visible to other threads at the same time.

### Safe Publication Idioms

The JMM guarantees that any of the following idioms is sufficient for safe publication:

1. Initialise the object reference from a **static initialiser**.
2. Store a reference to it in a **`volatile`** field or `AtomicReference`.
3. Store a reference to it into a **`final`** field of a properly constructed object.
4. Store a reference to it into a field that is properly guarded by a **lock**.

## Avoiding Visibility Problems by Object Type

Whether goals G1 and G2 are automatically satisfied depends on the object's type:

| Object type | Goal G1 (no partial construction) | Goal G2 (see state changes) |
|---|---|---|
| Local to thread | Satisfied (not shared) | Satisfied (not shared) |
| Immutable (unmodifiable state, all fields `final`, properly constructed) | Satisfied | Satisfied |
| Effectively immutable (state doesn't change after publication) | Must be safely published | Satisfied |
| Mutable (state changes over time, multiple threads may read/write) | Must be safely published | Must be thread-safe or guarded by a lock |

## Fixing the Holder Example

### The Problem

```java
public class ConfigSettings {
    public Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}

public class Holder {
    private int n;

    public Holder(int n) { this.n = n; }

    public void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```


The `Holder` object is **effectively immutable** (its state does not change after construction), but it is **not safely published** — the `holder` field is `public` and non-volatile.

**Atomic actions involved:** two reads of `n` in `MyTest()`, plus several actions in the constructor (instantiating the object, initialising fields, publishing the reference). If the constructor and `MyTest()` are run by different threads, these atomic actions can be interleaved arbitrarily.

**Possible interleaving with two threads A and B:**

1. [A] calls `new Holder(42)`
2. [B] gets a reference to `holder`
3. [B] calls `MyTest()`
4. [B] reads `n = 0` in `MyTest()` (first read)
5. [A] sets `this.n = 42`
6. [B] reads `n = 42` in `MyTest()` (second read)

**Outcome:** `AssertionError` is raised because B sees a **partially constructed** `Holder` object — the two reads of `n` in `n != n` return different values.

### Option 1: Make Holder Immutable

Declare `n` as `final`:

```java
public class Holder {
    private final int n;

    public Holder(int n) { this.n = n; }

    public void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```

The `final` keyword on `n` means its value cannot be changed after construction. The JMM guarantees that `final` fields are fully visible to all threads once the constructor completes (provided the object is properly constructed).

### Option 2a: Safely Publish via Static Initialiser

```java
public class ConfigSettings {
    public static Holder holder = new Holder(42);
}
```

The `holder` reference is initialised in a static initialiser, which the JVM guarantees is executed safely before any thread can access the class.

### Option 2b: Safely Publish via `volatile`

```java
public class ConfigSettings {
    public volatile Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}
```

The `volatile` keyword ensures that reads of `holder` always return the most recent write by any thread (a form of weak synchronisation).

### Option 2c: Safely Publish via `final` Field

```java
public class ConfigSettings {
    public final Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}
```

The reference to the `Holder` object cannot be changed after construction. The JMM guarantees visibility of `final` fields once the enclosing object's constructor completes.

### Option 2d: Safely Publish via Lock

```java
public class ConfigSettings {
    private Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }

    public synchronized Holder GetHolder() {
        return holder;
    }
}
```

Locking ensures visibility but has an impact on performance and interface design.

## Design Patterns for Concurrency

Reasoning about interference and visibility problems for each object and piece of state is complex and error-prone, yet correctness must be ensured in all concurrent applications. **Design patterns** — general, repeatable solutions to common problems in software engineering — encode good practices built from experience.

### The Java Monitor Pattern

To make an object thread-safe using the Java monitor pattern: **encapsulate all its mutable state and guard the state with the object's intrinsic lock**. All methods that access the state are `synchronized`. There is a possible simplicity–performance tradeoff.

Ways to use the pattern:

- Wrap non-thread-safe objects.
- Model data as classes implementing the monitor pattern, so they can be safely accessed by multiple threads.

### Example: A Mutable and Safe Holder

```java
public class MutableHolder {
    private int n = 0;

    public synchronized void SetValue(int x) {
        n = x;
    }

    public synchronized int GetValue() {
        return n;
    }

    public synchronized void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```

## Conditional Synchronisation

When a thread cannot work on the current state of a monitor (e.g., reading from an empty buffer), there are two options: fail/raise an error (the only possibility in single-threaded applications), or **wait for another thread to change the monitor's state**. Conditional synchronisation supports the second possibility.

### Pseudocode Pattern

```
acquire lock
while (predicate) {
    release lock
    wait to be notified
    reacquire lock
}
perform action
notify other threads
release lock
```

### Java Example

```java
public synchronized V read() {
    while (isEmpty()) {
        wait();
    }
    V val = doRead();
    notifyAll();
    return val;
}
```

### Condition Queues

**Condition queues** give threads a way to subscribe to specific updates on a given condition. Waiting threads form a **wait set**. Every Java object behaves as a condition queue.

Methods:

- `wait()` — makes the calling thread enter the condition queue (releases the lock, waits for notification, reacquires the lock).
- `notify()` — wakes up one thread in the wait set.
- `notifyAll()` — wakes up *all* threads in the wait set.

**Important:** Notifications signal that "something has changed", **not what** has changed. Threads must re-check the condition predicate when woken up.

### Which Lock and Condition Queue to Use?

- The **condition predicate** is a condition on state variables.
- Before testing the condition predicate, the thread must hold the **lock guarding the corresponding state variables**. The same lock must be held when calling `wait()` and notification methods.
- Additionally, the **lock object must be the same as the condition queue object** (i.e., `this.wait()` makes a thread wait until `this.notifyAll()` is called).
- Think in terms of **entry and exit protocols**.

## Essential Reading

The slides for this week are not self-contained. The following essential reading supplements the lecture material:

- Additional examples of monitors and conditional synchronisation — available on Moodle.
- Proper use of conditional synchronisation — GPBBHL 14.2.
- The `volatile` keyword (semantics: updates to a volatile variable are propagated predictably to other threads, and how to use them) — GPBBHL 3.1.4.
- Additional guidelines for thread safety — GPBBHL 4.
- The actual Java Memory Model (low-level guarantees, and why they translate into the discussed safe publication rules) — GPBBHL 16.

<!-- transcription-audit:
- Dropped: slide 1 — title slide (boilerplate, UCL branding)
- Dropped: slide 2 — warmup/housekeeping (Mentimeter poll, no technical content)
- Dropped: slides 17–23 — intermediate build-up states of the object-type table (final state on slide 24 captured in full)
- Dropped: slide 32 — image of "Design Patterns" book cover (decorative; the textual content is preserved)
- Dropped: slides 11, 13 — intermediate build-up of the Holder example (content merged into the unified Holder section)
- Dropped: angry-face emoji icons on slides 6, 7, 11, 12, 13, 26 — decorative
- Warnings:
  - Slide 10: Synchronisation visibility diagram rendered as prose description in an HTML comment. The diagram shows two thread timelines with lock/unlock of monitor M and an arrow indicating the visibility guarantee. Spatial layout is approximated; recommend retaining original slide if precise visual is needed.
- Ambiguities:
  - "AssertionError" appears on the slides as written and matches Java's standard `java.lang.AssertionError` class. No error.
  - Slides 17–24 are a progressive build-up of a single table. Only the final completed table (slide 24) is transcribed; intermediate annotations (e.g., "not shared", "unmodifiable state, all fields are final, properly constructed", "state doesn't change after publication", "state changes over time, and multiple threads may read or write it") are incorporated into the table as clarifying text.
  - The ordering of sections was reorganised for logical flow: the Holder example (slides 11–13) is presented after the publication/safe-publication definitions rather than before, since the definitions provide necessary context. The fixes (slides 26–31) follow immediately.
- Suspected source errors: none confirmed. "AssertionError" matches Java's standard class name.
-->
