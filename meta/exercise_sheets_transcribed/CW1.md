> Source: [CW1.pdf](../exercise_sheets/CW1.pdf), [CW1\_answers.pdf](../exercise_sheets/CW1_answers.pdf)

# COMP0008 — CW1: Number Representation

> These questions are formative (ungraded) and are for self-assessment.

---

## Questions

**1.** Let $x = 13_4$ and $y = 11_{16}$. How many digits $(x \times y)$ has in base 64?

**2.** Let $x, y$ be 32-bit integers. How many bits are guaranteed to be enough for representing $(x \times y)$ for any values of $x, y$?

**3.** Suppose that $x$ and $y$ both have $d$ digits (without leading zeros) in base $b$. How many digits will $(x \times y)$ have in base $b^2$? Give the smallest feasible interval $[l, h]$ (i.e., at least $l$ and at most $h$).

**4.** What is the 2's complement of `0xBADC0C0A`? Calculate it without going through binary.

---

## Model Answers

### Answer 1

Let $x = 13_4$ and $y = 11_{16}$. How many digits $(x \times y)$ has in base 64?

We have that $y = 11_{16} = 101_4$. Thus $x \times y = 303_4 + 1010_4 = 1313_4$. We have that $(10^3)_4 < 1313_4 < (10^6)_4 = 10_{64}$, and thus $x \times y$ has two base-64 digits. This uses the fact that $4^3 = 64$ and thus every base-64 digit is equivalent to three base-four digits.

An alternative solution is to convert to decimal: $x = 1 \cdot 4^1 + 3 \cdot 4^0 = 7_{10}$ and $y = 10 \cdot 16^1 + 1 \cdot 16^0 = 17_{10}$, which gives $(x \times y) = 119_{10}$. Since $64 < 119 < 64^2$, the product requires two digits.

**The takeaway:** it is sometimes easier to do computation in bases other than 10.

---

### Answer 2

Let $x, y$ be 32-bit integers. How many bits are guaranteed to be enough for representing $(x \times y)$ for any values of $x, y$?

**64 bits.** This is because $x, y$ take values that can be at most $2^{32} - 1$, and thus $2^{63} < (2^{31} - 1)^2 < 2^{64}$, which means that 64 bits are enough but 63 are not.

**The takeaway:** *the product of numbers may require more bits. Trivia: What does it mean for multiplication in MIPS32 (where all registers are 32-bit long)?*

---

### Answer 3

Suppose that $x$ and $y$ both have $d$ digits (without leading zeros) in base $b$. How many digits will $(x \times y)$ have in base $b^2$?

We have that $x < b^d$, $y < b^d$, and thus $(x \times y) < b^{2d}$, which means the product needs no more than $2d$ digits in base $b$ and thus $d$ digits in base $b^2$.

Similarly, if both are non-zero, $x \geq b^{d-1}$ and $y \geq b^{d-1}$, which means $(x \times y) \geq b^{2d-2}$, and thus it requires at least $2d - 1$ digits in base $b$ and then at least $\left\lceil \frac{2d-1}{2} \right\rceil = d$ digits in base $b^2$. Finally, if $(x \times y) = 0$ then a single digit is needed.

To conclude, **exactly $d$ digits** will be required to represent the product in base $b^2$.

The interval is $[d, d]$ — i.e., the number of digits is always exactly $d$.

**The takeaway:** *the product of numbers may require more bits. Trivia: What does it mean for multiplication in MIPS32 (where all registers are 32-bit long)?*

---

### Answer 4

What is the 2's complement of `0xBADC0C0A`? Calculate it without going through binary.

Complement each hex digit (replace each digit $z$ by $15 - z$):

$$\texttt{0xBADC0C0A} \xrightarrow{\text{bitwise NOT}} \texttt{0x4523F3F5}$$

Then add 1:

$$\texttt{0x4523F3F5} + 1 = \texttt{0x4523F3F6}$$

**The trick in full:** If we take the bitwise-NOT of an $N$-bit (here $N = 32$) binary number $x$ and denote it by $x'$, then $(x + x' + 1) = 2^N$ (i.e., $x + x'$ is the largest number representable using $N$ bits). This means that the 2's complement of $x$ is $(x' + 1)$, i.e., we can simply "flip" each bit in $x$ and then add 1. Moving to hexadecimal, we replace each digit $z$ by $(15 - z)$ and add 1 at the end.

**The takeaway:** *find your preferred way of calculating 2's complement of numbers quickly — it will appear in more modules (and depending on what you do, in your future work) than you currently imagine!*

<!-- transcription-audit:
- Dropped: CW1.pdf p.1 preamble ("Dear students, The questions below will not be marked...") — boilerplate
- Dropped: CW1_answers.pdf p.1 preamble ("Dear students, These are the solutions...") — boilerplate
- Dropped: Repeated "COMP0008: Computer Architecture & Concurrency – CW1" headers — boilerplate
- Ambiguities: Q3 asks for interval [l, h] but the answer concludes the count is exactly d in all non-trivial cases (and 1 for the zero case). The answer document does not explicitly state l and h as a pair; the transcript adds the clarifying note "[d, d]" to make the answer to the question explicit.
- Warnings: none — document is purely typeset text and math; no figures or diagrams.
- Suspected source errors: none
-->
