> Source: [CW3.pdf](../exercise_sheets/CW3.pdf), [CW3\_answers.pdf](../exercise_sheets/CW3_answers.pdf)

# COMP0008 CW3 — MIPS Assembly: ISA, Conventions, and Recursion

*Formative coursework — not marked. Questions and model answers combined below.*

---

## Part 1: Scrutinizing MIPS's ISA

In the lecture, we discussed the difference between `addi` and `addiu`.

### Question 1a

Write a short MIPS assembly program that throws an exception when executing the following instruction:

```mips
addi $t0, $t0, -1
```

### Answer 1a

Set `$t0` to the smallest signed 32-bit integer (−2³¹), then add −1, which overflows and triggers an exception:

```mips
lui $t0, 0x8000    # set $t0 to be the smallest signed 32-bit integer: -2^31
addi $t0, $t0, -1
```

---

### Question 1b

Change the above to `addiu` and check that no exception is thrown. Can you give an example of a case where such an instruction is useful?

### Answer 1b

Consider the following C code:

```c
for (unsigned int x = (1<<31) + 5; x < (1<<31) - 5; --x) {  // x runs from 2^31 + 5 down to 2^31 - 5
    // do something
}
```

Notice that the **unsigned** representation of 2³¹ is `0x80000000`, the same as the **two's complement** representation of −2³¹.

The compiler's way of letting the CPU know that this is an unsigned integer is to use `addiu`, which doesn't throw an exception.

In practice, many compilers may opt not to throw an exception either way. For example, in C, a signed overflow is considered "undefined behaviour", which means that the compiler is free to ignore this possibility. In fact, in newer MIPS designs the `addi` instruction no longer exists (and its opcode serves a new instruction).

---

## Part 2: Theoretical Questions

Which of the following claims are correct?

---

**Claim:** It is better to write an assembly program that uses as few registers as possible (even if it means performing more instructions for the same task).

**Answer — Incorrect.** If we are talking about a complete program (as opposed to a function), there is no benefit in minimising the number of registers we use, and it is better to optimise the number of instructions.

---

**Claim:** Say that programs A and B each execute exactly 1000 instructions to perform a task, but A only uses `$t0` while B modifies many more registers. Then, A will be faster than B due to caching.

**Answer — Incorrect.** Caches are designed to speed up access to slower memories (e.g., main memory). Registers are the fastest memory that the CPU can use and therefore are not cached anywhere.

---

**Claim:** In a function, the callee is responsible for restoring the values of `$a0`–`$a3` before the function ends.

**Answer — Incorrect.** As shown in the MIPS reference card, `$a0`–`$a3` are not callee-saved registers.

---

**Claim:** If a function does not call another function, it is more efficient to avoid storing `$ra` on the stack.

**Answer — Correct.** `$ra` is not modified unless we call a different function, so there is no need to save it.

---

**Claim:** If a function does not call another function, we should not use the memory for efficiency (as we don't have to modify any of the stored registers).

**Answer — Incorrect.** There are cases where the computation required in the function needs more variables than the available registers, and we must store the remaining values in memory.

---

**Claim:** Using `jal label` is essentially the same as doing (1) `la $t0, label` and (2) `jalr $t0`.

**Answer — Incorrect.** `jal` is more efficient as it is encoded as a single instruction. Additionally, it does not modify `$t0`.

---

## Part 3: Recursion in MIPS

### Background

In the lecture, we discussed additive (e.g., the Roman) and positional (e.g., decimal) number systems. In some older additive systems (e.g., [the Egyptian](https://en.wikipedia.org/wiki/Egyptian_numerals)), there was no importance to the order of symbols.

### The Weird0008 Number System

The **Weird0008** number system is an additive number system that uses the digits 1–9 (i.e., without zero). It requires that digits be sorted in non-increasing order, and thus allows multiple representations of the same number.

### Question

Write a MIPS program that takes as input a number $n > 0$ and outputs all its Weird0008 representations.

For example, if $n = 5$, the output can be:

```
5
41
32
311
221
2111
11111
```

Follow the register usage convention: use `$t0`–`$t9` for temporary variables, `$s0`–`$s7` for saved variables, `$a0`–`$a3` for arguments, etc.

### Answer

The solution is not optimised. It uses a recursive function with three arguments:

1. `$a0` — the sum of the remaining digits (initially, the input number).
2. `$a1` — the number of digits in the current prefix (initially, 0).
3. `$a2` — the largest digit allowed to maintain non-increasing order (initially, 9).

In the recursion, we loop through all options for the next digit (between 1 and min(`$a0`, `$a2`)). For each possible digit, we:

1. Write it to `mem[$a1]` (where `mem` is an auxiliary array).
2. Set `$a0 ← $a0 − current digit`.
3. Increment `$a1`.
4. Set `$a2 ← min($a2, current digit)`.
5. Call the function recursively.

(But first, we save all the required registers!)

```mips
######### routine to print the numbers on one line.

        .data
space:  .asciiz " "                         # space to insert between numbers
newline:.asciiz "\n"
head:   .asciiz "\n--------------------------------\n"
mem:    .word 0 : 1000                      # An auxiliary array
        .text

li   $8, 15                # The number we wish to represent
la   $a0, head             # Load the address to print the heading
li   $v0, 4                # specify Print String service
syscall                    # print heading

move $a0, $8               # The sum of digits should equal $8
li   $a1, 0                # The number of digits in the current number
li   $a2, 9                # The largest allowed digit
jal  recursion             # call print routine.
li   $v0, 10               # system call for exit
syscall                    # we are out of here.


recursion:
    addi $sp, $sp, -16     # make room to store the registers
    sw   $ra, 0($sp)       # we're calling a function, must save $ra
    sw   $s0, 4($sp)       # by convention, must store $s0 to use it
    sw   $s1, 8($sp)       # by convention, must store $s1 to use it
    sw   $s2, 12($sp)      # by convention, must store $s2 to use it
    move $s1, $a1          # we need to remember the number of digits so far
    bnez $a0, non_zero     # a pseudo instruction, same as bne $a0, $0
    la   $t0, mem          # if we got here, we're done ($a0=0) time to print

print_loop:                # print $a1 digits from mem
    lw   $t1, ($t0)        # iterate over mem. $t0 is the pointer, $t1 is the value
    li   $v0, 1            # syscall 1 -- print int
    move $a0, $t1          # by convention, the argument goes to $a0
    syscall                # print $t1=mem[$t0/4]
    addi $t0, $t0, 4       # ++t0
    subi $s1, $s1, 1       # --$s1, that tracks how many digits are left
    bgtz $s1, print_loop   # if we haven't printed all digits, go to the next one
    la   $a0, newline      # load address of newline string, done with one representation
    li   $v0, 4            # specify Print String service
    syscall                # print newline
    j    end_recursion     # go restore values and then return to caller

non_zero:                  # We have ($a0 > 0), so we're not done
    move $s0, $a0          # We need to store $a0 before making rec. calls
    move $s2, $a2          # set $s2 = $a2 (we want $s2 = min($a0, $a2))
    bge  $s0, $s2, digit_loop  # If ($s0 >= $s2) then we are done computing the min
    move $s2, $s0          # otherwise fix $s2 to $s0

digit_loop:                # We loop through $s2, $s2-1, ..., 1 for the next digit
    sll  $t0, $s1, 2       # $t0 = $s1 * 4  (byte offset for writing the next digit)
    la   $t1, mem($t0)     # Get $t1 to point at that memory address
    sw   $s2, ($t1)        # Store the current digit in mem[$s1]
    sub  $a0, $s0, $s2     # The remaining digits need to sum up to $s0-$s2
    move $a2, $s2          # For the recursion, place the max allowed digit in $a2
    addi $a1, $s1, 1       # We have now one more digit
    jal  recursion         # Solve the problem for representing $a0 with the current prefix
    addi $s2, $s2, -1      # We're done with all options with digit $s2, decrement it
    bgtz $s2, digit_loop   # If $s2>0 we need to continue the loop

end_recursion:
    lw   $ra, 0($sp)       # read registers from stack
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    addi $sp, $sp, 16      # bring back stack pointer
    jr   $ra               # return
```

<!-- suspected-source-error: CW3_answers.pdf page 5, digit_loop comment on `sll $t0, $s1, 2` reads
"$t0 = $s1 * t" — the "t" is clearly a typo for "4" (sll by 2 = multiply by 4). Corrected in the
code listing above. -->

<!-- transcription-audit:
- Dropped: "Dear students" preamble letter (boilerplate intro) — kept only the formative/ungraded note inline.
- Dropped: Repeated question text in the answers PDF (Parts 1–3 question text is duplicated verbatim in CW3_answers.pdf; deduplicated).
- Dropped: Repeated example output listing (5, 41, 32, 311, 221, 2111, 11111) that appears again at the top of CW3_answers.pdf page 2 — already present under the question.
- Dropped: The coloured rendering of example output values (green in question PDF, green in answers PDF) — purely a visual presentation choice, no semantic meaning.
- Warnings: None — all content was faithfully representable in text/markdown.
- Ambiguities:
  - The answers PDF (page 3) says "use $s0-$s1 for saved variables" in the Part 3 preamble, whereas the question sheet says "$s0-$s7". The solution actually uses $s0, $s1, and $s2, so "$s0-$s1" in the answer sheet appears to be a slip. Transcribed the question sheet's wording ("$s0-$s7") as the authoritative convention statement.
  - The Egyptian numeral system link in the source is a hyperlink with display text "the Egyptian"; retained as a Wikipedia link inferred from context.
- Suspected source errors:
  - CW3_answers.pdf page 5: `sll $t0, $s1, 2` comment says "$t0 = $s1 * t" — "t" should be "4". Corrected in transcript with inline comment.
-->
