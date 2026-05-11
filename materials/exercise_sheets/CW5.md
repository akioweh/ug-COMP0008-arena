> Source: [CW5.pdf](../exercise_sheets/CW5.pdf), [CW5\_answers.pdf](../exercise_sheets/CW5_answers.pdf)

# CW5 — Exercises on Java Synchronization

**NOT ASSESSED**

**Instructions:** This exercise sheet is not assessed — it is to help you to understand the material, and to challenge what you think you know. Solutions for the following questions will be provided.

**Collaboration:** You are permitted to work with your classmates. However, you are likely to get more out of this if you attempt the answers first, before discussing them.

---

## The `Example` Class

All questions below refer to the following class.

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

    public synchronized void d() {
        System.out.println("The values of x and y are " + x + " and " + y);
    }
}
```

---

## Questions

**1.** Suppose that two threads T1 and T2 run concurrently, and T1 tries to execute method `a()` while T2 tries to execute method `b()` on the same instance of the `Example` class.

**(a)** Can `a()` and `b()` be executed concurrently by T1 and T2? Motivate your answer.

**(b)** What are the possible values of x and y after T1 and T2 terminate?

---

**2.** Consider now two threads T3 and T4 that run concurrently, and such that T3 tries to execute method `b()` while T4 tries to execute method `c()` on the same instance of the `Example` class.

**(a)** Can `b()` and `c()` be executed concurrently by T3 and T4? Motivate your answer.

**(b)** What are the possible values of x and y after T3 and T4 complete the execution of `b()` and `c()` respectively?

---

**3.** Can `b()` and `c()` be executed concurrently on different instances of the `Example` class? That is, can a thread T5 execute `b()` on one instance of the `Example` class, while another thread T6 executes `c()` on another `Example` instance? Justify your answer explicitly referring to the semantics of the `synchronized` keyword.

---

**4.** Is the `Example` class thread-safe? Motivate your answer.

---

## Answers

### Question 1(a) — Can `a()` and `b()` run concurrently on the same instance?

**Yes**, even on the same instance: `a()` is **not** `synchronized`. The `synchronized` keyword on `b()` only prevents two threads from holding the lock on the same object simultaneously. Because `a()` acquires no lock at all, T1 running `a()` is never blocked by T2 running `b()`, and they can execute concurrently.

### Question 1(b) — Possible values of x and y after `a()` and `b()` complete

Because `a()` is unsynchronized, there is effectively no mutual exclusion, and all possible interleavings of the individual atomic actions of `a()` and `b()` are observable. The possible outcomes include:

| Interleaving | Steps | Final [x, y] |
|---|---|---|
| #1 — `a()` completes first, then `b()` | `a()` sets y = 2\*2 = 4; `b()` sets x = 2+4 = 6 | [6, 4] |
| #2 — `b()` completes first, then `a()` | `b()` sets x = 2+3 = 5; `a()` sets y = 2\*5 = 10 | [5, 10] |
| #3 — interleaved at the instruction level | `a()` reads x = 2; `b()` sets x = 5; `a()` sets y = 2\*2 = 4 | [5, 4] |

The outcome **[5, 4]** arises from the interleaved execution: `a()` reads the old value of x (2) before `b()` updates it, then writes y = 4 after `b()` has already set x = 5. This outcome is impossible when both methods are synchronized, and its possibility here demonstrates the interference caused by the lack of synchronization on `a()`.

### Question 2(a) — Can `b()` and `c()` run concurrently on the same instance?

**No.** Both `b()` and `c()` are declared `synchronized`. In Java, a `synchronized` instance method acquires the intrinsic lock (monitor) of the object (`this`) before executing and releases it on return. Since both methods compete for the same lock on the same instance, only one thread can hold the lock at a time — the other must wait. Therefore `b()` and `c()` cannot execute concurrently on the same `Example` instance.

### Question 2(b) — Possible values of x and y after `b()` and `c()` complete

Because both methods are synchronized on the same instance, they execute atomically with respect to each other. There are exactly two possible serialization orders:

| Interleaving | Steps | Final [x, y] |
|---|---|---|
| #1 — `b()` first, then `c()` | `b()`: x = 2+3 = 5 → [5,3]; `c()`: y = 2\*5 = 10 → [5,10] | **[5, 10]** |
| #2 — `c()` first, then `b()` | `c()`: y = 2\*2 = 4 → [2,4]; `b()`: x = 2+4 = 6 → [6,4] | **[6, 4]** |

### Question 3 — Can `b()` and `c()` run concurrently on *different* instances?

**Yes.** The `synchronized` keyword on an instance method causes the thread to acquire the intrinsic lock of the specific object instance (`this`) on which the method is called. Each `Example` object has its own independent lock. Therefore, T5 executing `b()` on instance `e1` acquires `e1`'s lock, while T6 executing `c()` on a different instance `e2` acquires `e2`'s lock — these are distinct locks and do not interfere with each other. The two threads can proceed concurrently without any blocking.

### Question 4 — Is the `Example` class thread-safe?

Technically, the answer depends on the specification (i.e. what the class is supposed to do). However, in practice, the class is **not thread-safe**. The method `a()` is not synchronized, which means threads running `a()` can interfere with threads running any other method. As shown in Question 1(b), this interference can produce values of [x, y] (e.g. [5, 4]) that are impossible under any sequential execution of the methods — a clear violation of thread safety. To make the class thread-safe, `a()` would also need to be declared `synchronized`.

<!-- transcription-audit:
- Dropped: UCL/Department of Computer Science header boilerplate (appears on every page of CW5.pdf)
- Dropped: Page numbers from both documents
- Dropped: Slide numbers (37–46) from CW5_answers.pdf — these are lecture slide numbers, not meaningful in the transcript
- Dropped: UCL logo/branding from answer slides (decorative)
- Dropped: Slides 37, 39, 41, 43, 45 from CW5_answers.pdf — these are the "question" half of each build-up pair (same question repeated without the answer box); the answer is fully captured in the corresponding answer slide (38, 40, 42, 44, 46)
- Ambiguities: Q3 has no dedicated answer slide in CW5_answers.pdf. The answer is implied by slide 38 ("Not on the same instance, by def. of synchronized") and the general explanation of synchronized semantics. The answer for Q3 in this transcript is reconstructed from that implication and the standard Java semantics described across the answer slides.
- Ambiguities: The answer slides are extracted from a lecture deck (slides numbered 37–46 in the original deck). The "Let's test our understanding" heading is a slide section title, not a section of the exercise sheet — dropped as decorative/structural artefact of the slide format.
- Warnings: None — all content was faithfully representable in text/markdown.
- Suspected source errors: None.
-->
