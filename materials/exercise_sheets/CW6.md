> Source: [CW6.pdf](../exercise_sheets/CW6.pdf), [CW6\_answers.pdf](../exercise_sheets/CW6_answers.pdf)

# CW6 — Java Monitors and Conditional Synchronization

**NOT ASSESSED**

**Instructions:** This exercise sheet is not assessed — it is to help you to understand the material, and to challenge what you think you know. Solutions for the following questions will be provided.

**Collaboration:** You are permitted to work with your classmates. However, you are likely to get more out of this if you attempt the answers first, before discussing them.

---

## Questions

### Question 1

Consider the following class.

```java
public class SecretHolder {
    private int secret = 0;
    private final int MAX_VALUE = 5;
    // suspected-source-error: CW6.pdf omits `int` in the field declaration above,
    // writing `private final MAX_VALUE = 5;`. The answers PDF and all surrounding
    // context make clear the type is `int`. Transcribed with the correction.

    private synchronized void checkSecret() {
        if (secret < 0 || secret > MAX_VALUE) {
            throw new AssertionError("Secret out of bounds!");
        }
    }

    public synchronized void upOne() throws InterruptedException {
        if (secret == MAX_VALUE) {
            wait();
        }
        secret++;
        checkSecret();
        notify();
    }

    public synchronized void downOne() throws InterruptedException {
        if (secret == 0) {
            wait();
        }
        secret--;
        checkSecret();
        notify();
    }

    public synchronized void upTwo() throws InterruptedException {
        while (secret >= MAX_VALUE - 1) {
            wait();
        }
        secret = secret + 2;
        checkSecret();
        notifyAll();
    }

    public synchronized void downTwo() throws InterruptedException {
        while (secret <= 1) {
            wait();
        }
        secret = secret - 2;
        checkSecret();
        notifyAll();
    }
}
```

Answer the following questions about a concurrent system with several threads that call methods on the same `SecretHolder` instance `I`. We denote any state of the system such that no thread can make any more progress (i.e., it is terminated or indefinitely blocked) as a *final state*. Additionally, we write T={A₁,...,Aₙ} to indicate a thread T which starts, executes actions A₁,...,Aₙ and then terminates.

**(a)** Suppose that the system concurrently runs two threads A and B such that A = {I.downOne()}, and B = {I.upOne()}.

How many final states does the system admit? What are the values of `I.secret` in each final state of the system?

**(b)** As in the previous question, suppose that the system concurrently runs two threads A and B such that A = {I.downOne()}, and B = {I.upOne()}.

Can an `AssertionError` be thrown at runtime?

**(c)** Consider now the case in which the system concurrently runs four threads A, B, C and D, such that A = {I.downOne()}, B = {I.downOne()}, C = {I.downOne()} and D = {I.upTwo()}.

Can an `AssertionError` be thrown at runtime?

**(d)** Suppose that at a given time, `I.secret` is set to 5 and the last three threads to be executed are A = {I.downOne()}, B = {I.upOne()}, and C = {I.upTwo()}.

Is `I.secret = 4` in any final state of the system?

**(e)** Consider any number of threads, such that some of them call `I.upTwo()` once and then terminate, while the others call `I.downTwo()` once and then terminate.

Can an `AssertionError` be raised at runtime? If yes, describe a case where the `AssertionError` is raised. Otherwise, motivate why `I.secret` is always between 0 and `MAX_VALUE` every time `checkSecret()` is called.

---

## Model Answers

### Answer (a)

There are **two** possible interleavings, and both lead to the same final value `I.secret = 0`.

- **Interleaving 1:** `upOne()` runs first (secret becomes 1), then `downOne()` runs (secret becomes 0).
- **Interleaving 2:** `downOne()` starts and blocks on `wait()` (because secret == 0); then `upOne()` runs (secret becomes 1) and calls `notify()`, waking `downOne()`; `downOne()` then decrements (secret becomes 0).

The system admits **1 final state**: `I.secret = 0`.

### Answer (b)

**No**, an `AssertionError` cannot be thrown.

From the two interleavings enumerated in (a), `secret` only ever takes the values 0 and 1, both of which are within bounds [0, MAX\_VALUE]. `checkSecret()` never fires.

### Answer (c)

**Yes**, an `AssertionError` can be thrown.

The problem is that `downOne()` uses `if` (not `while`) to check its condition predicate before `wait()`. This means a thread that wakes up from `wait()` does not re-check whether `secret > 0` before decrementing.

**Problematic interleaving:**

1. A, B, and C all call `downOne()`. Since `secret == 0`, all three block on `wait()`.
2. D calls `upTwo()`: `secret` becomes 2, then `notifyAll()` wakes A, B, and C.
3. A, B, and C each resume after `wait()` without re-checking the condition (because `if` was used). They each decrement `secret` in turn: 2 → 1 → 0 → **−1**.
4. The last thread to decrement sets `secret = -1`, and `checkSecret()` throws an `AssertionError`.

**Root cause:** `downOne()` does not re-check the condition predicate after returning from `wait()` — always use `while`, not `if`, around `wait()`.

### Answer (d)

**Yes**, `I.secret = 4` is a reachable final state, but it is a *deadlocked* state (not all threads have terminated).

**Interleaving leading to this final state:**

1. `I.secret = 5` initially. B (`upOne()`) checks `secret == MAX_VALUE` → true, blocks on `wait()`. C (`upTwo()`) checks `secret >= MAX_VALUE - 1` (i.e., `5 >= 4`) → true, blocks on `wait()`.
2. A (`downOne()`) runs: `secret` is not 0, so it decrements: `secret = 4`, calls `notify()`.
3. `notify()` wakes exactly one waiting thread — say it wakes C (`upTwo()`). C re-checks its `while` condition: `secret >= MAX_VALUE - 1` → `4 >= 4` → true, so C goes back to `wait()`.
4. B (`upOne()`) was never woken. B remains blocked on `wait()`.

The system is now in a final state with `I.secret = 4`, with both B and C indefinitely blocked (deadlocked).

**Root cause:** `downOne()` uses `notify()` (wakes only one thread), which can wake the "wrong" waiter. This is a missed-signal scenario. Using `notifyAll()` in `downOne()` would avoid it.

### Answer (e)

**No**, an `AssertionError` cannot be raised.

**Reason:** Both `upTwo()` and `downTwo()` use `while` loops around `wait()`, so every thread re-checks its condition predicate after being woken. Additionally, both methods call `notifyAll()` after modifying `secret`, ensuring all waiting threads are re-evaluated.

Concretely:

- A thread calling `upTwo()` only proceeds past the `while` loop when `secret < MAX_VALUE - 1` (i.e., `secret ≤ 3`). It then sets `secret += 2`, so `secret ≤ 5 = MAX_VALUE`. The upper bound is never exceeded.
- A thread calling `downTwo()` only proceeds past the `while` loop when `secret > 1` (i.e., `secret ≥ 2`). It then sets `secret -= 2`, so `secret ≥ 0`. The lower bound is never violated.
- Because `notifyAll()` is used, no thread can be permanently starved of a wake-up when the condition it needs becomes true.

Therefore, `checkSecret()` is always called with `secret` in [0, MAX\_VALUE], and no `AssertionError` is ever thrown.

<!-- transcription-audit:
- Dropped: UCL/Department of Computer Science header (boilerplate, both files)
- Dropped: Slide numbers (31–43) from CW6_answers.pdf
- Dropped: UCL logo and decorative slide chrome from CW6_answers.pdf
- Dropped: Repeated code listings in answer slides (already fully shown in the questions section)
- Dropped: Slide title "Conditional sync in action" repeated on every answer slide (structural boilerplate)
- Warnings: none — both PDFs are typeset text; no diagrams or figures carry information beyond what is captured in prose
- Suspected source errors:
    1. CW6.pdf p.1: `private final MAX_VALUE = 5;` is missing the `int` type keyword. The answers PDF (slide 31) correctly shows `private final int MAX_VALUE = 5;`. Transcribed with the correction and flagged inline.
- Ambiguities: The answers PDF is a lecture slide deck (slides 31–43), not a standalone answer document. Each question has a "question" slide followed by one or two "answer" slides. The answer content has been synthesised from the annotated answer slides into coherent prose answers.
-->
