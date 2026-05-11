> Source: [CW4.pdf](../exercise_sheets/CW4.pdf), [CW4\_answers.pdf](../exercise_sheets/CW4_answers.pdf)

# CW4: Exercises on the Concurrency Abstraction and Interleavings

**NOT ASSESSED**

**Instructions:** This exercise sheet is not assessed — it is to help you understand the material, and to challenge what you think you know. Solutions for the following questions will be provided.

**Collaboration:** You are permitted to work with your classmates. However, you are likely to get more out of the following exercises if you attempt to solve them on your own.

---

## Questions

An *interleaving* is defined as a totally ordered sequence of atomic actions such that each action is performed by one thread, and actions within the same thread are executed in order. Interleavings represent possible runtime executions of instructions from different threads running simultaneously.

### Question 1 — Two threads

Consider a concurrent system consisting of two threads A and B.

**(a)** Suppose that thread A includes two atomic actions A1 and A2, while B includes only one atomic action B1. How many different interleavings exist?

**(b)** Suppose now that both A and B include two atomic actions each. List the possible interleavings we have this time.

### Question 2 — Three threads

Consider now a different concurrent system with three threads A, B, C.

**(a)** Suppose that each thread includes one atomic action — i.e., A1, B1, and C1 respectively. List all the possible interleavings.

**(b)** Suppose that thread A includes two atomic actions A1 and A2, B includes one atomic action B1, and C includes one atomic action C1. Enumerate the different interleavings that exist in this case.

### Question 3 — Possible values under concurrency

Consider the case of a program that initializes an integer variable `x` to zero and then spawns two threads T1 and T2.

**(a)** If T1 executes the instructions `x=5; x=2*x` and T2 executes `x=x+2`, what values can `x` have after the two threads terminate?

---

## Answers

### Answer 1(a) — Two threads: A = {A1, A2}, B = {B1}

*Reminder:* in the concurrency abstraction, we don't reorder actions within threads — so A2 always follows A1. Other than that, we mix atomic actions in all possible ways.

**Answer: 3**

The interleavings are:

- [A1, A2, B1]
- [A1, B1, A2]
- [B1, A1, A2]

### Answer 1(b) — Two threads: A = {A1, A2}, B = {B1, B2}

Enumerating by which action goes first:

- If A1 is first: [A1, A2, B1, B2], [A1, B1, A2, B2], [A1, B1, B2, A2]
- If B1 is first: [B1, A1, A2, B2], [B1, A1, B2, A2], [B1, B2, A1, A2]
- No interleaving starts with A2 or B2.

**Answer: 6**

Note: one more action leads to double the number of interleavings.

#### General formula for two threads

For two threads A and B where A has X atomic actions and B has Y atomic actions, the number of interleavings is given by the binomial coefficient (a *stars-and-bars* calculation):

$$\frac{(X+Y)!}{X! \cdot Y!}$$

### Answer 2(a) — Three threads: A = {A1}, B = {B1}, C = {C1}

Enumerating by which action goes first:

- A1 first: [A1, B1, C1], [A1, C1, B1]
- B1 first: [B1, A1, C1], [B1, C1, A1]
- C1 first: [C1, B1, A1], [C1, A1, B1]

**Answer: 6**

### Answer 2(b) — Three threads: A = {A1, A2}, B = {B1}, C = {C1}

Enumerating by which action goes first:

- A1 first: [A1, A2, B1, C1], [A1, A2, C1, B1], [A1, B1, A2, C1], [A1, B1, C1, A2], [A1, C1, A2, B1], [A1, C1, B1, A2]
- B1 first: [B1, A1, A2, C1], [B1, A1, C1, A2], [B1, C1, A1, A2]
- C1 first: [C1, B1, A1, A2], [C1, A1, B1, A2], [C1, A1, A2, B1]

**Answer: 12** — twice as many as for two threads with two actions each.

### Answer 3(a) — Possible values of x

**T1:** `x=5; x=2*x` (two actions) — **T2:** `x=x+2` (one action). Initial value: `x=0`.

#### Assuming all instructions are atomic

There are 3 interleavings:

| Interleaving | Sequence | Final x |
|---|---|---|
| 1 | `x=5; x=2*x; x=x+2` | **12** |
| 2 | `x=5; x=x+2; x=2*x` | **14** |
| 3 | `x=x+2; x=5; x=2*x` | **10** |

#### Accounting for non-atomicity of read-modify-write operations

`x=2*x` is not truly atomic — it entails a read and a write, equivalent to `t=x; x=2*t`. Similarly, `x=x+2` can be written as `s=x; x=s+2`. When these sub-operations are treated as separate atomic actions, additional interleavings become possible, yielding further values:

| Interleaving | Key steps | Final x |
|---|---|---|
| 4 | `s=0` (read x into s); all of T1 runs; `x=s+2` | **2** |
| 5 | `s=0` (read x into s); `x=5`; `x=s+2`; `x=2*x` | **4** |
| 6 | `x=5`; `s=5` (read x into s); rest of T1; `x=s+2` | **7** |

So the full set of possible values for `x` is: **{2, 4, 7, 10, 12, 14}**.

<!-- transcription-audit:
- Dropped: UCL/Department of Computer Science header (boilerplate, appears on CW4.pdf page 1)
- Dropped: Slide numbers and UCL logo from CW4_answers.pdf (decorative/boilerplate)
- Dropped: Repeated question text on answer slides (deduplicated; question already appears in Questions section)
- Dropped: Slide titles "Training our intuition: ..." (delivery artefact; content preserved under answer headings)
- Warnings: none — all content was textual and faithfully representable in markdown
- Ambiguities:
  - The answers PDF (CW4_answers.pdf) is a lecture slide deck (slides 39–52), not a standalone answer sheet. The slide numbers suggest these are mid-lecture slides. This is noted but does not affect content fidelity.
  - The general formula question (slides 43–44) appears in the answers deck but has no corresponding question in CW4.pdf. It has been included under Answer 1(b) as a natural extension.
  - Interleaving 4 in the non-atomic section: the answers slide abbreviates the sequence as "s=0; T1; x=s+2" meaning T2 reads x=0 into s before T1 runs, then T1 completes fully, then T2 writes x=s+2=2. Transcribed faithfully with a brief clarifying note.
-->
