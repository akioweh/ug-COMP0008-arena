> Source: [CW2.pdf](../exercise_sheets/CW2.pdf), [CW2\_answers.pdf](../exercise_sheets/CW2_answers.pdf)

# COMP0008 CW2 — MIPS Assembly

This is a formative (ungraded) coursework exercise sheet. The questions are for self-assessment; solutions are provided below each part.

---

## Part 1: Instruction Encoding

*Without using MARS:*

**Question 1.** Write the 32-bit binary MIPS representation of `mult $13, $15`.

**Question 2.** Disassemble and understand the following binary code:

```
0x210affff
0x010a4824
0x0009582b
```

- Write the three instructions in assembly.
- *(Challenging!)* For which values of `$8` is `$11` going to be 1 after these instructions are executed?

> **Note:** One of these instructions is an I-type instruction, whose format will be discussed in week 3's lecture. Try inferring the structure from the MIPS reference card!

---

### Answer 1.1 — Encoding `mult $13, $15`

From the MIPS reference card:

```
Multiply    mult    R    {Hi,Lo} = R[rs] * R[rt]    0/--/--/18
```

The opcode is 0 (as in all R-type instructions) and the function code is `0x18` (decimal 24).

R-type instruction format:

| opcode (6 bits) | rs (5 bits) | rt (5 bits) | rd (5 bits) | shamt (5 bits) | funct (6 bits) |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 000000 | rs | rt | rd | shamt | funct |

`mult` does not use `rd` (set to 0) and is not a shift instruction (`shamt` = 0). Filling in `$13` = `01101` and `$15` = `01111`:

| 000000 | 01101 | 01111 | 00000 | 00000 | 011000 |

Result: `0b00000001101011110000000000011000` = **`0x01af0018`**

<!-- suspected-source-error: CW2_answers.pdf page 1 states the result as "0x1af0018" (missing leading zero), which is a display omission rather than a value error. The correct 8-digit hex representation is 0x01af0018. Transcribed with the corrected leading zero. -->

---

### Answer 1.2 — Disassembling the three instructions

First, convert to binary and identify the 6-bit opcode (bits 31–26):

```
0x210affff = 0b00100001000010101111111111111111   opcode = 001000 = 8
0x010a4824 = 0b00000001000010100100100000100100   opcode = 000000 = 0
0x0009582b = 0b00000000000010010101100000101011   opcode = 000000 = 0
```

**Instruction 1 — `0x210affff` (opcode = 8 → `addi`, I-type)**

I-type format: `opcode (6) | rs (5) | rt (5) | Immediate (16)`

Splitting `0b00100001000010101111111111111111`:
- opcode = `001000` = 8
- rs = `01000` = 8
- rt = `01010` = 10
- Imm = `1111111111111111` = `0xffff` = −1 (two's complement)

Assembly: **`addi $10, $8, -1`** (note: `rt` is the destination register in I-type)

**Instructions 2 & 3 — opcodes = 0 → R-type; identify by function code (bits 5–0)**

```
0x010a4824 = 0b00000001000010100100100000100100   funct = 100100 = 0x24
0x0009582b = 0b00000000000010010101100000101011   funct = 101011 = 0x2b
```

From the reference card:
```
And                  and    R    R[rd] = R[rs] & R[rt]              0 / 24hex
Set Less Than Unsig. sltu   R    R[rd] = (R[rs] < R[rt]) ? 1 : 0   0 / 2bhex
```

Extracting rs/rt/rd register fields:

```
0x010a4824 = 0b00000001000010100100100000100100
                      rs=01000=8  rt=01010=10  rd=01001=9
0x0009582b = 0b00000000000010010101100000101011
                      rs=00000=0  rt=01001=9   rd=01011=11
```

Assembly:
- **`and $9, $8, $10`**
- **`sltu $11, $0, $9`**

**Full sequence:**

```mips
addi $10, $8, -1
and  $9,  $8, $10
sltu $11, $0, $9
```

**Challenging — For which values of `$8` is `$11` = 1?**

Tracing the sequence:
1. `addi $10, $8, -1` → `$10 = $8 − 1`
2. `and $9, $8, $10` → `$9 = $8 & ($8 − 1)`
3. `sltu $11, $0, $9` → `$11 = 1` if `$0 < $9` (unsigned), i.e., if `$9 ≠ 0` (since `$0` is always 0 and is the smallest unsigned value)

So `$11 = 1` when `$8 & ($8 − 1) ≠ 0`.

Example: `$8 = 0b1010` → `$8 − 1 = 0b1001` → `$8 & ($8 − 1) = 0b1000` (non-zero → `$11 = 1`).

Example: `$8 = 0b1000` → `$8 − 1 = 0b0111` → `$8 & ($8 − 1) = 0` (zero → `$11 = 0`).

The pattern `$8 & ($8 − 1) = 0` holds if and only if `$8` is a power of two (consider the most significant 1 bit: subtracting 1 flips it and sets all lower bits, so the AND is zero exactly when there is only one 1 bit).

**Conclusion:** the three instructions test whether `$8` is a power of two. If it is, `$11 = 0`; otherwise `$11 = 1`.

---

## Part 2: The Collatz Conjecture

### Background

The [Collatz conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture) states that any Collatz sequence, defined by an input integer $a_0$, always reaches the value 1 after a finite number of steps.

Starting with $a_0$, the sequence is defined as:

$$a_{n+1} = \begin{cases} 3a_n + 1 & \text{if } (a_n \bmod 2) = 1 \\ a_n / 2 & \text{otherwise} \end{cases}$$

For example, if $a_0 = 7$, the sequence is 7, 22, 11, 34, 17, 52, 26, 13, 40, 20, 10, 5, 16, 8, 4, 2, 1, 4, 2, 1, …

It was announced (July 2021) that whoever solves the problem would win a prize larger than $1M.

### Task

Write a MIPS32 assembly program that:
- Takes an integer as input ($a_0$).
- Prints the Collatz sequence numbers until the first 1 (for up to 500 elements).

You may assume that none of the numbers exceed $2^{31} - 1$ and can thus be represented using 32-bit integers.

*Remember: when programming in MIPS, the reference card (link on the website) is your friend!*

---

### Answer 2 — Collatz Sequence in MIPS

> There are many ways of writing a correct solution. The code below is an example and is not optimised in any way. It is better to try it yourself first!

```mips
# Compute up to 500 numbers following the input number in its Collatz sequence

        .data
output: .word  0 : 500      # "array" of 500 values for the output
size:   .word  500          # size of "array"

        .text

        la   $t0, output    # load address of output array
        la   $t5, size      # load address of size variable
        lw   $t5, 0($t5)    # load array size
        li   $v0, 5         # MARS call number 5: read int
        syscall             # return value in $v0
        move $t1, $v0       # store initial value in $t1
        li   $t6, 1         # $t6 = 1
        li   $t7, 3         # $t7 = 3
        sw   $t1, 0($t0)    # a[0] = input number
        addi $t1, $t5, -1   # counter for loop, will execute (size-2) times

loop:
        lw   $t3, 0($t0)    # get value from array a[n] into $t3
        andi $t2, $t3, 1    # $t2 = t3 % 2
        beq  $t2, $t6, odd  # if (t2 == 1), i.e., if a[n] was odd
        # even:
        srl  $t2, $t3, 1    # $t2 = $t3 / 2 = a[n] / 2
        j    updated

odd:
        multu $t3, $t7      # compute t3 * 3 = a[n] * 3
        mflo  $t3           # move the result to $t3, i.e., $t3 = a[n] * 3
        addi  $t2, $t3, 1   # set $t2 = $t3 + 1 = a[n] * 3 + 1

updated:  # done computing ($t2 = a[n]/2) or ($t2 = a[n]*3+1) depending on parity
        sw   $t2, 4($t0)    # store a[n+1] in array
        addi $t0, $t0, 4    # increment address
        addi $t1, $t1, -1   # decrement loop counter
        beq  $t2, $t6, done
        bgtz $t1, loop      # repeat if not finished yet

done:
        la   $a0, output    # first argument for print (array)
        subu $a1, $t5, $t1  # compute the output size
        jal  print          # call print routine
        li   $v0, 10        # system call for exit
        syscall             # we are out of here

######### routine to print the numbers on one line

        .data
space:  .asciiz " "                     # space to insert between numbers
head:   .asciiz "The Collatz sequence is:\n"

        .text

print:
        add  $t0, $zero, $a0  # starting address of array
        add  $t1, $zero, $a1  # initialize loop counter to array size
        la   $a0, head        # load address of print heading
        li   $v0, 4           # specify Print String service
        syscall               # print heading

out:
        lw   $a0, 0($t0)      # load next Collatz number for syscall
        li   $v0, 1           # specify Print Integer service
        syscall               # print Collatz number
        la   $a0, space       # load address of spacer for syscall
        li   $v0, 4           # specify Print String service
        syscall               # output string
        addi $t0, $t0, 4      # increment address
        addi $t1, $t1, -1     # decrement loop counter
        bgtz $t1, out         # repeat if not finished
        jr   $ra              # return
```

---

## Part 3: Implementing Complex Pseudo-Instructions

### Background

MARS has an assembler that replaces pseudo-instructions with one or more hardware-supported instructions.

Out-of-order-execution (OOOE) CPUs suffer a great performance hit when a program contains many branches. Branch-less programming is therefore often essential for writing performant code.

### Task

Design branchless implementations of two new pseudo-instructions not currently supported on MARS:

- `min $t0, $t1, $t2` — set `$t0 = min($t1, $t2)`
- `med $t0, $t1, $t2` — set `$t0` to the median of `$t0`, `$t1`, `$t2`

Specifically:

1. Write a code that prints out the minimum of two registers `$t1`, `$t2` (set at the beginning of the code). **The code must be branchless.**
2. *(Challenging!)* Write a code that prints out the median of three registers `$t0`, `$t1`, `$t2` (set at the beginning of the code). **The code must be branchless.**

**Clarification:** In general (as discussed in week 4's lecture), a pseudo-instruction implementation may not modify registers other than the goal register (`$t0` here) and `$1`. While this is achievable for `min`, for `med` you may use all temporary registers (`$t0`–`$t7`) as if it were a function call.

**Clarification:** Only the `min`/`med` operation code itself must be branchless. It is fine to use a syscall for outputting the result.

**Note:** `$t0`–`$t7` are aliases for `$8`–`$15`, where *t* stands for *temporary*.

### Code Template (for `med`)

```mips
        .data
msg:    .asciiz "\nThe median is:\n"

        .text
main:
        li   $v0, 4         # syscall v0=4 --> print string
        la   $a0, msg       # call parameter --> pointer to the message
        syscall

        li   $t0, 31321     # example values; should work for any combination
        li   $t1, 2179      # a pseudo-instruction that sets $t1 = 2179
        li   $t2, 1178914

        ### Actual branchless code of computing $t0 <- median($t0, $t1, $t2)

        ### End of your code

        move $a0, $t0       # set $a0 <- $t0
        li   $v0, 1         # syscall 1 -- prints the integer $a0
        syscall
```

---

### Answer 3.1 — Branchless `min`

> Note: pseudo-instructions have only one scratch register: `$1` (a.k.a. `$at`). If these were actually implemented in an assembler, any other register modified would need to be saved and restored. The solutions below show progressively more register-efficient approaches.

**Naive attempt (incorrect):**

```mips
### Actual branchless code of computing $t0 <- min($t1, $t2)
slt  $1,  $t1, $t2
mult $1,  $t1
mflo $1              # $1 gets $t1 if ($t1 < $t2)
slt  $t0, $t2, $t1
mult $t0, $t2
mflo $t0             # $t0 gets $t2 if ($t2 < $t1)
add  $t0, $t0, $1
###
```

This is **incorrect** — when `$t1 = $t2`, both `slt` results are 0 and the final `add` yields 0 instead of the common value.

**Correct version using `slt` + `mult`:**

```mips
### Actual branchless code of computing $t0 <- min($t1, $t2)
slt  $1,  $t1, $t2   # $1 = 1 if ($t1 < $t2)
sub  $t0, $t1, $t2
mult $1,  $t0
mflo $1              # $1 = ($t1 - $t2) if ($t1 < $t2), else 0
add  $t0, $0,  $t2   # $t0 = $t2
add  $t0, $t0, $1    # $t0 = $t2 + $1 = min($t1, $t2)
###
```

**Efficient version using bitwise operations (uses `$1`):**

The key insight: arithmetic right-shift by 31 turns a negative number into `0xFFFFFFFF` (all ones) and a non-negative number into `0x00000000`. This acts as a mask.

```mips
### Actual branchless code of computing $t0 <- min($t1, $t2)
subu $1,  $t1, $t2
sra  $t0, $1,  31    # $t0 = 0xFFFFFFFF if ($t1 < $t2), else 0
and  $t0, $t0, $1    # $t0 = ($t1 - $t2) if ($t1 < $t2), else 0
add  $t0, $t0, $t2
###
```

**Version without `$1` (at the cost of one extra instruction):**

```mips
### Actual branchless code of computing $t0 <- min($t1, $t2)
subu $t1, $t1, $t2   # Don't worry, we'll correct that!
sra  $t0, $t1, 31    # $t0 = 0xFFFFFFFF if ($t1 < $t2), else 0
and  $t0, $t0, $t1   # $t0 = ($t1 - $t2) if ($t1 < $t2), else 0
addu $t0, $t0, $t2
addu $t1, $t1, $t2   # restore $t1 to its original value
###
```

> Bitwise operations can very often simplify code and make it faster — keep this in mind for the exam and in general.

---

### Answer 3.2 — Branchless `med` (Challenging)

#### Algorithm

The crux of the efficient median computation:

1. If **exactly one** of the following holds, then `$t1` is the median:
   - (a) `$t1 > $t0`
   - (b) `$t1 > $t2`
2. If **exactly one** of the following holds, then `$t2` is the median:
   - (a) `$t1 > $t2`
   - (b) `$t0 > $t2`
3. If neither (1) nor (2) holds, `$t0` is the median.

"Exactly one out of two" maps directly to **XOR**. "Neither (1) nor (2)" maps to **NOR**.

#### Solution A — Multi-register version

```mips
### Actual branchless code of computing $t0 <- med($t0, $t1, $t2)
subu $t3, $t1, $t0   # if ($t3 < 0) then ($t1 < $t0)
subu $t4, $t1, $t2   # if ($t4 < 0) then ($t1 < $t2)
xor  $t3, $t3, $t4   # if ($t3 < 0) then $t1 is the median by rule (1)
sra  $t3, $t3, 31    # if $t1 is the median: $t3 = 0xFFFFFFFF, else 0

subu $t5, $t0, $t2
xor  $t5, $t5, $t4   # if ($t5 < 0) then $t2 is the median by rule (2)
sra  $t5, $t5, 31    # if $t2 is the median: $t5 = 0xFFFFFFFF, else 0

nor  $t6, $t5, $t3   # if $t0 is the median (rule 3): $t6 = 0xFFFFFFFF, else 0
and  $t5, $t5, $t2   # if $t2 is the median: $t5 = $t2, else 0
and  $t3, $t3, $t1   # if $t1 is the median: $t3 = $t1, else 0
and  $t0, $t0, $t6   # if $t0 is NOT the median: $t0 = 0
addu $t0, $t0, $t3
addu $t0, $t0, $t5
###
```

#### Solution B — 7-instruction version using `movn`

`movn` is a conditional move instruction: `movn $t4, $t5, $t6` sets `$t4 = $t5` only if `$t6 ≠ 0` (hence "move non-zero"). It appears on the MIPS reference card and is documented in the textbook.

Reference card excerpt (partial) showing `movn`:

| MIPS opcode | (1) MIPS funct | (2) MIPS funct | Binary  | Decimal | Hex-decimal | ASCII Character |
|:-----------:|:--------------:|:--------------:|:-------:|:-------:|:-----------:|:---------------:|
| (1)         | sll            | add.*f*        | 00 0000 | 0       | 0           | NUL             |
|             |                | sub.*f*        | 00 0001 | 1       | 1           | SOH             |
| j           | srl            | mul.*f*        | 00 0010 | 2       | 2           | STX             |
| jal         | sra            | div.*f*        | 00 0011 | 3       | 3           | ETX             |
| beq         | sllv           | sqrt.*f*       | 00 0100 | 4       | 4           | EOT             |
| bne         |                | abs.*f*        | 00 0101 | 5       | 5           | ENQ             |
| blez        | srlv           | mov.*f*        | 00 0110 | 6       | 6           | ACK             |
| bgtz        | srav           | neg.*f*        | 00 0111 | 7       | 7           | BEL             |
| addi        | jr             |                | 00 1000 | 8       | 8           | BS              |
| addiu       | jalr           |                | 00 1001 | 9       | 9           | HT              |
| slti        | movz           |                | 00 1010 | 10      | a           | LF              |
| sltiu       | **movn**       |                | 00 1011 | 11      | b           | VT              |

```mips
### Actual branchless code of computing $t0 <- med($t0, $t1, $t2)
slt  $1,  $t0, $t1
slt  $t4, $t2, $t1
xor  $1,  $1,  $t4   # $1 = ($t0 < $t1) ^ ($t2 < $t1)
movn $t0, $t1, $1    # $t0 = $t1 if ($t0 < $t1) ^ ($t2 < $t1), else remains $t0

slt  $1,  $t2, $t0
xor  $1,  $1,  $t4   # $1 = ($t2 < $t0) ^ ($t2 < $t1)
movn $t0, $t2, $1    # $t0 = $t2 if ($t2 < $t0) ^ ($t2 < $t1), else remains $t0
###
```

This achieves 7 instructions, but modifies `$t4`, which is not permitted for a true pseudo-instruction implementation.

#### Solution C — Single scratch register (`$1` only)

```mips
### Actual branchless code of computing $t0 <- med($t0, $t1, $t2)
subu $1,  $t0, $t1   # if ($1 < 0) then ($t0 < $t1)
subu $t2, $t2, $t1   # $t2 = $t2 - $t1  [remember to fix it!]
xor  $1,  $1,  $t2   # if ($1 < 0) then ($t0 < $t1) ^ ($t0 < $t2)
sra  $1,  $1,  31    # if ($1 ≠ 0) then ($t0 < $t1) ^ ($t0 < $t2)
movn $t0, $t1, $1    # $t1 is the median!

subu $1,  $t2, $t0   # we want $1 = $t2 - $t0, but $t2 holds $t2 - $t1,
                     # so we get $1 = ($t2 - $t1) - $t0
addu $1,  $1,  $t1   # fix $1 to hold $t2 - $t0
xor  $1,  $1,  $t2   # $1 = ($t2 - $t0) ^ ($t2 - $t1); negative only if $t2 is the median
sra  $1,  $1,  31
add  $t2, $t2, $t1   # $t2 is restored
movn $t0, $t2, $1
###
```

> Note: several of the code pieces above assume that no overflow happens. In case `$t0`–`$t2` may be very large or small, this can be fixed using some additional logic.

<!-- transcription-audit:
- Dropped: CW2.pdf page 1 — introductory boilerplate ("Dear students, … COMP0008 staff."); informational content preserved in the preamble sentence.
- Dropped: CW2_answers.pdf pages 4 and 7 — verbatim repetition of Part 2 and Part 3 question text already present in the question sections.
- Dropped: CW2_answers.pdf page 3 — "Before we move to parts 2 and 3, a bit of context" note about exam grading criteria; this is meta-commentary about the CW itself and not module content. Retained only the substantive note that Part 2 provides a "correct" (not optimised) solution and Part 3 provides efficient register-convention-respecting solutions.
- Warnings: CW2_answers.pdf page 1 — R-type instruction format diagram and the filled-in encoding diagram are colour-coded visual tables. Reproduced as a plain markdown table and a bit-field row; spatial colour encoding (opcode=red, rs/rt=green, rd=orange, shamt=orange, funct=teal) is lost. The information content (field values) is fully preserved.
- Warnings: CW2_answers.pdf page 2 — I-type format diagram (colour-coded) reproduced as a plain markdown table; no information loss.
- Warnings: CW2_answers.pdf page 11 — partial MIPS reference card table (OPCODES, BASE CONVERSION, ASCII SYMBOLS) reproduced as a GFM table. The original uses a multi-column layout with merged cells; the GFM rendering is approximate but all values are preserved.
- Ambiguities: CW2_answers.pdf page 3 uses the instruction "and $9, $8, −1" in the prose summary, but the actual decoded instruction is "and $9, $8, $10" (bitwise AND of registers $8 and $10, where $10 = $8 − 1 after the addi). The prose is slightly misleading but not wrong in effect; transcribed as the register form "and $9, $8, $10" which matches the binary decoding.
- Suspected source errors: CW2_answers.pdf page 1 — encoding result written as "0x1af0018" (7 hex digits); correct 32-bit value is 0x01af0018. Flagged inline.
-->
