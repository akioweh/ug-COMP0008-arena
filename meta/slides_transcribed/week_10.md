> Source: [COMP0008\_10.pdf](../slides_original/COMP0008_10.pdf)

# Week 10 — Liveness

References: GPBBHL chapter 10.

## Concurrency Recap: Safety Is Not Enough

Concurrency enables superior performance through use of multiple processors, responsiveness, and other benefits. Threads are the minimal units that operating systems schedule to run concurrently; their atomic actions can be arbitrarily interleaved, reordered, and have effects that are not universally visible. Multi-threaded applications are therefore prone to interference and visibility problems.

**General rule:** if multiple threads access the same mutable state variable without appropriate synchronisation, your program is broken.

Synchronisation restricts the set of possible interleavings of a concurrent program. Locks ensure mutual exclusion of code blocks and visibility; safe publication avoids sharing partially constructed objects. Appropriate synchronisation avoids interference and visibility problems, at the cost of some performance.

However, synchronisation alone is not enough to ensure application correctness. Correctness entails two properties:

- **Safety** — nothing bad happens (the focus of earlier weeks).
- **Liveness** — something good eventually happens.

A fully synchronised, thread-safe program does *not* guarantee liveness. Worse, safety is generally at odds with liveness: locking can prevent anything good from happening.

## Liveness Issues

### Deadlock

**Definition:** all threads are permanently blocked. The common case is threads waiting forever for each other due to cyclic dependencies in resource acquisition. A real-life analogue is traffic gridlock.

#### The `transferMoney` Example

```java
public class Bank {
    ...
    public void transferMoney(Account fromAcc,
                              Account toAcc,
                              Double amount) {
        synchronized (fromAcc){
            synchronized (toAcc){
                if (fromAcc.getBalance() < amount){
                    throw new Exception("Insufficient funds");
                }
                fromAcc.debit(amount);
                toAcc.credit(amount);
            }
        }
    }
}
```

Whether a deadlock occurs depends on how the method is called by threads. A deadlock arises with the following interleaving:

1. `[T1]` calls `transferMoney(A, B, 1)` — acquires lock on A.
2. `[T2]` calls `transferMoney(B, A, 1)` — acquires lock on B.
3. T1 now needs lock B (held by T2); T2 now needs lock A (held by T1). Neither can proceed.

#### Fixing `transferMoney` with Lock Ordering

A possible fix is to enforce a **lock ordering discipline** — constraining all threads to acquire locks in the same order, thereby avoiding cyclic dependencies.

First, extract the transfer logic into a helper:

```java
public class Bank {
    ...
    private void doTransfer(Account fromAcc,
                            Account toAcc,
                            Double amount) {
        if (fromAcc.getBalance() < amount){
            throw new Exception("Insufficient funds");
        }
        fromAcc.debit(amount);
        toAcc.credit(amount);
    }
    ...
```

Then order lock acquisition by each account's immutable unique ID:

```java
    ...
    public void transferMoneyOrdered(Account fromAcc,
                                     Account toAcc,
                                     Double amount) {
        int fromId = fromAcc.getAccountId(); // returns immutable unique id
        int toId = toAcc.getAccountId();

        if (fromId < toId){
            synchronized (fromAcc){
                synchronized (toAcc){
                    doTransfer(fromAcc, toAcc, amount);
                }
            }
        }
        // otherwise, if toId < fromId, first acquire the toAcc
        // lock and then the fromAcc lock
        ...
    }
}
```

#### Dining Philosophers

The Dining Philosophers problem is a classic concurrency problem formulated by Dijkstra in 1965 and employed as a test case by many synchronisation algorithms.

**Problem statement:** 5 philosophers sit around a table, each modelled as a thread. Each philosopher alternates between thinking and eating. To eat, a philosopher needs access to 2 forks. There are only 5 forks on the table; each fork lies between two adjacent philosophers (on the left of one and the right of another). If every philosopher picks up their left fork simultaneously, all block waiting for their right fork — a deadlock.

#### Deadlock Examples Summary

| Type | Example | Reference |
|---|---|---|
| Single object, conflicting methods | LeftRightDeadlock | [GPBBHL 10.1.1] |
| Single object, conflicting methods | Multiple Databases | [GPBBHL 10.1.5] |
| Single object, conflicting external calls | transferMoney | [GPBBHL 10.1.2] |
| Single object, conflicting external calls | Dining Philosophers | [Moodle] |
| Cross objects | Taxi dispatcher | [GPBBHL 10.1.3] |

#### Open Calls

Deadlocks may also be caused by calling an external method while holding a lock. An **open call** is a call to an external method (possibly of another object) with no lock held. One should strive to be completely agnostic of and robust to the implementation of called methods. Using open calls makes it easier to ensure locks are acquired in a consistent order, since code paths acquiring locks become easier to follow (a similar role to encapsulation for thread safety). **Caveat:** open calls may induce loss of atomicity.

#### Avoiding Deadlocks: Summary

**Methodology:** identify where resources are acquired, then ensure no conflicting acquisition *or* break cycles.

| Technique | Example | Reference |
|---|---|---|
| Threads never acquire >1 resource at a time | — | [GPBBHL 10.2] |
| Order resource acquisition within individual methods | `transferMoneyOrdered` | [GPBBHL 10.1.2] |
| Use open calls across objects | ThreadSafe Taxi dispatcher | [GPBBHL 10.1.4] |
| Acquire with timeout | `transferMoney` w/ `tryLock` | [GPBBHL 10.2.1] |
| Detect-and-abort | DBMS | [GPBBHL 10.1] |

### Starvation

**Definition:** a thread is perpetually denied access to resources it needs in order to progress.

| Resource waited for | Example | Reference |
|---|---|---|
| CPU cycles | Low-priority threads starved by high-priority ones | [GPBBHL 10.3.1] |
| Object or Lock | Lock held by a thread running an infinite loop | [GPBBHL 10.3.1] |
| Object or Lock | Readers and Writers | [Moodle] |

A lighter version of starvation is unfair allocation of resources (e.g. CPU), possibly causing poor responsiveness.

#### Starvation Example: Readers–Writers

Inspired by Readers and Writers [Magee & Kramer ch. 7]. A shared database (DB) is accessed by two types of threads: Readers that read the DB, and Writers that update it. Writers must have exclusive access to the DB, while any number of Readers may simultaneously access it. If readers continuously arrive, writers may be starved indefinitely.

### Livelock

**Definition:** despite not being blocked, a thread does not make any useful work — e.g. it keeps retrying an operation that always fails.

| Failing operation | Example | Reference |
|---|---|---|
| Change state (in response to other thread's state change) | Polite people in a hallway | [GPBBHL 10.3.3] |
| Faulty error recovery | Poison message problem | [GPBBHL 10.3.3] |
| Faulty error recovery | WifiLink | [Moodle] |

**Typical solution:** add randomness to the retry mechanism.

#### Livelock Example: WifiLink

A simulation of transmissions on a Wi-Fi link. Wi-Fi clients transmit messages to an access point (AP); messages simultaneously transmitted by multiple clients "collide" and are not received correctly (signals mix up).

**Problem formulation:** 1 AP and N clients. The AP waits for messages and confirms correct receptions. Each client sends one message to the AP, waits for confirmation, and resends if no confirmation is received. Messages and AP confirmations take time to reach their destinations. If all clients retransmit at the same fixed interval after a collision, they will collide again indefinitely — a livelock.

### Incorrect Conditional Synchronisation

**Missed signals:** a thread keeps waiting for a condition that is already true, or was true in the past. Incorrectness often stems from inappropriate use of conditional synchronisation and/or code bugs:

- The condition predicate is not checked before waiting.
- The thread is not woken up from a wait.

## Conditional Synchronisation (Reminder)

When a thread cannot work on the current state of a monitor (e.g. reading an empty buffer), there are two options: fail/raise an error (the only possibility for single-threaded applications), or wait for another thread to change the monitor's state. Conditional synchronisation supports the second possibility.

The pattern in pseudo-code and Java:

```
PSEUDO-CODE                         EXAMPLE (Java)
acquire lock                        public synchronized V read(){
while (predicate) {                     while(isEmpty()){
  release lock                              wait();
  wait to be notified                   }
  reacquire lock                        V val = doRead();
}                                       notifyAll();
perform action                          return val;
notify other threads                }
release lock
```

**Condition queues** give threads a way to subscribe to specific updates on a given condition. Waiting threads form a **wait set**. The available methods are:

- `wait()` — allows a thread to enter a condition queue (releases the lock, blocks until notified, then reacquires the lock).
- `notify()` — wakes up one thread in the wait set.
- `notifyAll()` — wakes up *all* threads in the wait set.

Notifications signal that "something has changed", **not *what*** has changed — threads must re-check the condition predicate when woken up.

In Java, each object can act as a condition queue: `this.wait()` makes a thread wait until `this.notifyAll()` is called. The rules for choosing which lock and condition queue to use are:

- The condition predicate is a condition on state variables.
- Before testing the condition predicate, the thread must hold the lock guarding the corresponding state variables.
- The same lock must be held when calling `wait` and notification methods on the condition queue.
- The lock object and the condition queue object must be the same object.

One should think in terms of **entry and exit protocols**.

<!-- transcription-audit:
- Dropped: slide 1 — title slide (boilerplate, reference to GPBBHL ch.10 preserved in body)
- Dropped: slide 2 — warmup/administrative (Mentimeter poll, CW6 reminder)
- Dropped: slide 30 — interactive Mentimeter poll slide
- Dropped: slides 4–5 — build-up duplicates of slides 3 and 6–7 (content merged into "Concurrency Recap" and "Even synchronisation is not enough" sections)
- Dropped: slides 9–11 — build-up versions of the transferMoney example (slide 9 = code only, slide 10 = adds question, slide 11 = adds "maybe" answer); final version on slide 12 used
- Dropped: slides 13–14 — partial build-up versions of the deadlock examples table; final version on slide 16 used
- Dropped: slide 17 — build-up of the fix (same code as slide 9, adds "how to avoid deadlocks?" question)
- Dropped: slide 28 ReadWriteSafe GUI screenshot — described in prose instead
- Warnings:
  - Slide 8: traffic gridlock diagram (cars at an intersection with labels "Needed by A / Locked by B" and vice versa) described in prose rather than reproduced visually. Spatial layout is not critical; the cyclic dependency concept is captured.
  - Slide 15: Dining Philosophers illustration (round table with 5 plates, forks, and philosopher portraits) described in prose. The image is illustrative of the problem statement already given in text.
  - Slide 24: WifiLink network diagram (AP with radio waves, 3 clients, "full duplex links over each tone" label) described in prose. Illustrative only.
  - Slide 28: ReadWriteSafe GUI applet screenshot (Magee/Kramer) showing "readers=1 writing=false" with Reader 1, Reader 2, Writer 1, Writer 2 pie-chart panels. Described in prose; the screenshot is a simulation visualisation, not essential content.
  - Slide 25: conditional sync pseudo-code and Java example shown side-by-side; reproduced as aligned text block. Some spatial correspondence is lost.
- Ambiguities:
  - Slides 3–7 form a multi-slide build-up sequence (concurrency recap → safety vs liveness → "no!"). Merged into two prose sections. The rhetorical reveal ("Unfortunately, no!" / "Again, no!") is a delivery artefact; the conclusion is stated directly.
  - The deadlock examples table was built up across slides 13, 14, and 16. Only the final (complete) version is transcribed.
  - Slide 28 references a GUI applet (©Magee/Kramer). The copyright attribution is noted but the screenshot itself is described rather than reproduced.
-->
