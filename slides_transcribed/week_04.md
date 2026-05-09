> Source: [COMP0008\_04.pdf](slides_original/COMP0008_04.pdf)

# High-Level Language Constructs in MIPS Assembly

Previous weeks covered all key R-format and I-format MIPS instructions at a low level: their representation as 32-bit machine code words, and how the machine executes them by manipulating bits and bytes in registers and memory. This week examines how high-level language constructs (arrays, conditionals, loops, functions) are compiled into MIPS assembly, and introduces the final instruction format — J-type — used for jumps and function calling.

Background reading: Patterson & Hennessy, Chapter 2.

## MIPS Register Usage Convention

MIPS has 32 registers, each with a conventional name and role:

| Name | Register Number | Usage |
|---|---|---|
| `$zero` | 0 | The constant value 0 |
| `$at` | 1 | Assembler temporary (reserved for pseudo-instructions) |
| `$v0`–`$v1` | 2–3 | Function return values |
| `$a0`–`$a3` | 4–7 | Function arguments |
| `$t0`–`$t7` | 8–15 | Temporaries (caller-saved; need **not** be preserved across function calls) |
| `$s0`–`$s7` | 16–23 | Saved variables (callee-saved; the function **must** save and restore these if it uses them) |
| `$t8`–`$t9` | 24–25 | More temporaries (caller-saved) |
| `$k0`–`$k1` | 26–27 | Reserved for operating system kernel |
| `$gp` | 28 | Global pointer (points into the global static data segment, set to `0x10008000`) |
| `$sp` | 29 | Stack pointer |
| `$fp` | 30 | Frame pointer |
| `$ra` | 31 | Function return address |

`$gp`, `$sp`, `$fp`, and `$ra` must also be saved and restored if changed by a function.

## Arrays in MIPS

Array elements are accessed using a base address register and byte offsets. Each `int` (word) is 4 bytes, so `array[i]` is at offset `4*i` from the base.

High-level code:

```c
int array[5];
array[0] = array[0] * 2;
array[1] = array[1] * 2;
```

MIPS assembly (array base address in `$s0`, e.g. at `0x12348000`):

```mips
# Load base address into $s0
lui  $s0, 0x1234          # put 0x1234 in upper half of $s0
ori  $s0, $s0, 0x8000     # put 0x8000 in lower half of $s0

lw   $t1, 0($s0)          # $t1 = array[0]
sll  $t1, $t1, 1          # $t1 = $t1 * 2
sw   $t1, 0($s0)          # array[0] = $t1

lw   $t1, 4($s0)          # $t1 = array[1]
sll  $t1, $t1, 1          # $t1 = $t1 * 2
sw   $t1, 4($s0)          # array[1] = $t1
```

The offset in `lw`/`sw` is in bytes: `0($s0)` for element 0, `4($s0)` for element 1, etc.

## J-Type Instructions

### J-format encoding and address calculation

The J-type (jump) format uses a 6-bit opcode and a 26-bit address field:

```
| opcode (6 bits) | address (26 bits) |
```

The `j` (jump) instruction has opcode `000010` ($2_{\text{hex}}$). Since addresses are 32 bits but the field is only 26 bits, the full target address is constructed as:

$$\text{NewPC} = (\text{PC}+4)[31{:}28] \;\|\; \text{JA} \;\|\; 00$$

That is, the 26-bit field is shifted left by 2 (word-aligned instructions are always multiples of 4), and the top 4 bits are taken from the current PC+4. The jump address (JA) stored in the instruction is therefore:

$$JA = \frac{\text{target address}}{4}$$

**Example:** to jump to `0x00400010`, the stored JA is `0x00400010 / 4 = 0x00100004`. The encoded instruction is:

```
000010 00000100000000000000000100
```

A small code example:

```mips
      li   $8, 10
      j    target
      addi $8, $8, 1    # skipped
      addi $8, $8, 1    # skipped
target:
```

The assembler/simulator table for this shows:

| Address | Code | Basic |
|---|---|---|
| `0x00400000` | `0x2408000a` | `addiu $8,$0,0x0000000a` |
| `0x00400004` | `0x08100004` | `j 0x00400010` |
| `0x00400008` | `0x21080001` | `addi $8,$8,0x00000001` |
| `0x0040000c` | `0x21080001` | `addi $8,$8,0x00000001` |

Because the top 4 bits of the PC are copied, a J-type jump can only reach addresses within the same 256 MB region (same upper 4 bits).

### Jump Register (`jr`) and Jump-and-Link Register (`jalr`)

To jump to an address with different most-significant bits, or one known only at runtime, use the R-type instruction `jr`:

**Jump Register:** `jr rs` — sets `PC = R[rs]`. Opcode/funct = `0/08` hex. It is an R-type instruction.

Example: `jr $ra` (return from function). Encoding:

```
000000 11111 00000 00000 00000 001000  =  0x03e00008
```

`$ra` is register 31.

There is also `jalr $rs` which performs `$ra ← PC + 4; PC ← R[rs]` — a jump-and-link using a register operand, useful when the target address is computed at runtime.

## Control Flow

### If/Else Branching

High-level code:

```c
if (i == j)
    f = g + h;
else
    f = f - i;
```

MIPS assembly (`$s0` = f, `$s1` = g, `$s2` = h, `$s3` = i, `$s4` = j):

```mips
      bne  $s3, $s4, L1     # if i != j, go to else
      addu $s0, $s1, $s2    # f = g + h
      j    done
L1:   subu $s0, $s0, $s3    # f = f - i
done:
```

The pattern is: branch on the *negated* condition to the else label, fall through to the if-body, then jump past the else-body.

### While Loops

High-level code (find x such that $2^x = 128$):

```c
int pow = 1;
int x   = 0;
while (pow != 128) {
    pow = pow * 2;
    x   = x + 1;
}
```

MIPS assembly (`$s0` = pow, `$s1` = x):

```mips
       addi  $s0, $0, 1
       add   $s1, $0, $0
       addi  $t0, $0, 128
while: beq   $s0, $t0, done   # exit when pow == 128
       sll   $s0, $s0, 1      # pow = pow * 2
       addi  $s1, $s1, 1      # x = x + 1
       j     while
done:
```

### For Loops

High-level code (sum the numbers 0 to 9):

```c
int sum = 0;
int i;
for (i = 0; i != 10; i = i + 1) {
    sum = sum + i;
}
```

MIPS assembly (`$s0` = i, `$s1` = sum):

```mips
       addi $s1, $0, 0
       add  $s0, $0, $0
       addi $t0, $0, 10
for:   beq  $s0, $t0, done   # exit when i == 10
       add  $s1, $s1, $s0    # sum = sum + i
       addi $s0, $s0, 1      # i = i + 1
       j    for
done:
```

A `for` loop compiles to essentially the same structure as a `while` loop: initialisation, then a test-at-top loop with a backward jump.

## Functions in MIPS

Functions are more involved than other high-level constructs because they raise several questions: where do input arguments go? Where are local variables stored? Where does the return value go? How does the caller resume after the function returns? How do functions avoid overwriting each other's registers?

### Function Call Mechanism: `jal` and `jr`

`jal target` (jump and link) performs two actions simultaneously:

1. `$ra ← PC + 4` — saves the return address (the instruction after the `jal`).
2. `PC ← target` — jumps to the function.

The function returns with `jr $ra`, which sets `PC ← $ra`.

Example flow: the main program at address `0x0041AB3C` executes `jal 0x00445678`. This stores `0x0041AB40` into `$ra` and jumps to `0x00445678`. The function body executes, and its final instruction `jr $ra` sets `PC ← 0x0041AB40`, resuming the caller.

### Register Conventions for Functions

**Arguments and return values:**

| Register | Number | Usage |
|---|---|---|
| `$v0` | $2 | Result value |
| `$v1` | $3 | Result value (for 64-bit results or two 32-bit results) |
| `$a0` | $4 | Argument 1 |
| `$a1` | $5 | Argument 2 |
| `$a2` | $6 | Argument 3 |
| `$a3` | $7 | Argument 4 |
| `$ra` | $31 | Return address |

**Temporary vs saved registers:**

| Registers | Numbers | Convention |
|---|---|---|
| `$t0`–`$t7` | $8–$15 | Temporary; do **not** need to be preserved across function calls |
| `$s0`–`$s7` | $16–$23 | Saved; the function **must** save and restore these if it uses them |
| `$t8`–`$t9` | $24–$25 | More temporaries |

Saved registers (`$s0`–`$s7`) are used for values that must survive across function calls. The caller can rely on them being unchanged after a `jal`. Temporary registers (`$t0`–`$t9`) may be freely clobbered by any called function.

### Example: `abs_diff`

High-level code:

```c
int abs_diff(int a, int b) {
    int result = (a - b);
    if (result < 0) {
        result = (b - a);
    }
    return result;
}
```

MIPS assembly (arguments in `$a0` = a, `$a1` = b; result in `$v0`):

```mips
abs_diff:
      sub  $v0, $a0, $a1    # result = a - b
      bgez $v0, return      # if result >= 0, skip
      sub  $v0, $a1, $a0    # result = b - a
return:
      jr   $ra              # return
```

Benefits of writing functions in assembly: code reuse and abstraction, cleaner and more compact programs, and the ability to create library routines (e.g. `sqrt`, `sin`).

### Using Saved Registers for Local Variables

When a caller needs values to survive a function call, it stores them in saved registers (`$s0`–`$s7`). Example:

```c
int a = 64;
int b = 305419896;   // 0x12345678
func();
int c = a + b;
```

```mips
# $s0 = a
addi $s0, $0, 0x0040

# $s1 = b
lui  $s1, 0x1234
ori  $s1, $s1, 0x5678
# Or pseudo-instruction: li $s1, 0x12345678

jal  func

# $s2 = c  (safe because $s0, $s1 are preserved by func)
add  $s2, $s0, $s1
```

### Putting It Together — A Complete Program (with a Bug)

A full program that calls `abs_diff`:

```mips
# Calculating absolute difference
      .data
vals: .word 180, 100, 0

      .text
      .globl main
main: jal my_program         # Run my program.
      li  $v0, 10            # Exit (syscall 10).
      syscall

my_program:
      la   $t1, vals         # Load address of data into $t1.
      lw   $a0, 0($t1)      # Load A from memory into $a0.
      lw   $a1, 4($t1)      # Load B from memory into $a1.
      jal  abs_diff          # Jump and link to abs_diff.
      sw   $v0, 8($t1)      # Write result.
      jr   $ra               # Return to main.
```

**This program has a bug.** When `main` calls `my_program` via `jal`, it sets `$ra` to the address after that `jal`. Then `my_program` calls `abs_diff` via another `jal`, which **overwrites** `$ra` with the address after the second `jal`. When `abs_diff` returns, `$ra` now points back into `my_program` (not into `main`), so `jr $ra` at the end of `my_program` jumps back to itself, creating an **infinite loop**.

Additionally, `$t1` is a temporary register and may be clobbered by `abs_diff`, so `sw $v0, 8($t1)` after the call may use a stale value. The corrected version reloads `$t1` after the call.

### Caller-Save vs Callee-Save

Functions must not interfere with each other's registers. Two strategies exist:

- **Caller-save:** the *caller* saves any register values it needs before making the call, and restores them afterwards. This is the convention for `$t` registers — the caller is responsible.
- **Callee-save:** the *callee* saves any registers it intends to modify at the start of the function and restores them before returning. This is the convention for `$s` registers — the callee is responsible.

Registers cannot simply be saved into other registers (those might also be in use). They must be saved to **memory** — but not to a fixed memory location, because nested function calls would overwrite previous saves. The solution is the **stack**.

## The Stack

### Memory Layout

The MIPS address space is divided into segments (from high to low addresses):

| Segment | Address Range |
|---|---|
| Stack | `0x7ffffffc` downward |
| Dynamic data (heap) | `0x10010000` upward |
| Static data | `0x10000000` – `0x1000ffff` |
| Text (code) | `0x00400000` upward |
| Reserved | `0x00000000` – `0x003fffff` |

The stack grows **downward** (toward lower addresses). The stack pointer register `$sp` always points to the top (lowest used address) of the stack. The dynamic data (heap) grows upward; the two grow toward each other.

### Stack Frames (Prologue and Epilogue)

Each function call creates a **stack frame** containing the function's saved registers, arguments, and local variables. A typical prologue and epilogue for a one-argument function `int f(int y)` that uses `$s0` and calls another function `g`:

**Prologue** (function entry):

```mips
addiu $sp, $sp, -20       # allocate 20 bytes (5 words) on the stack
sw    $ra, 16($sp)        # save return address
sw    $fp, 12($sp)        # save old frame pointer
sw    $a0,  8($sp)        # save input argument y
sw    $s0,  4($sp)        # save $s0 (callee-saved)
addiu $fp, $sp, 16        # set frame pointer to top of frame
```

The stack frame layout (from `$fp` downward):

```
$fp →  old $ra       [0($fp)  = 16($sp)]
       old $fp       [-4($fp) = 12($sp)]
       input y       [-8($fp) =  8($sp)]
       old $s0       [-12($fp) = 4($sp)]
$sp →  local z       [-16($fp) = 0($sp)]
```

Within the function body, `$s0` and `y` can be used freely. The argument `y` is accessed via `-8($fp)` (not `$a0`, which may be overwritten by a nested call). Local variables (e.g. `z`) are stored below the saved registers. If the function calls `g(2y+z)`, `g` creates its own frame below, and `$fp` and `$sp` shift accordingly. When `g` returns, `$fp` and `$sp` are restored.

**Epilogue** (before return):

```mips
lw    $ra, 16($sp)        # restore return address
lw    $fp, 12($sp)        # restore old frame pointer
lw    $s0,  4($sp)        # restore $s0
addiu $sp, $sp, 20        # deallocate stack frame
jr    $ra                 # return
```

The frame pointer `$fp` provides a stable reference into the frame even as `$sp` changes (e.g. when pushing additional data for a nested call). Arguments are accessed relative to `$fp` rather than `$sp`.

### Corrected Program Using the Stack

The `my_program` function, corrected to save and restore `$ra` and `$fp` on the stack:

```mips
my_program:
      addi $sp, $sp, -8     # Allocate 8 bytes on the stack.
      sw   $ra, 4($sp)      # Save return address.
      sw   $fp, 0($sp)      # Save frame pointer.
      addi $fp, $sp, 4      # Set new frame pointer.

      la   $t1, vals        # Load address of data into $t1.
      lw   $a0, 0($t1)      # Load A from memory into $a0.
      lw   $a1, 4($t1)      # Load B from memory into $a1.
      jal  abs_diff          # Jump and link to abs_diff.
      la   $t1, vals        # Reload address (since $t1 may have been clobbered).

      sw   $v0, 8($t1)      # Write result.
      lw   $ra, 4($sp)      # Restore return address.
      lw   $fp, 0($sp)      # Restore frame pointer.
      addi $sp, $sp, 8      # Restore stack pointer.
      jr   $ra               # Return from program.
```

The key fix: `$ra` is saved to the stack before the nested `jal abs_diff` and restored afterwards, so `jr $ra` at the end correctly returns to `main`. The `$t1` register is also reloaded after the call since temporaries are not preserved.

<!-- transcription-audit:
- Dropped: slide 1 (p1) — title slide, decorative imagery and boilerplate
- Dropped: slide 2 (p2) — pulse survey, administrative content
- Dropped: slide 24 (p22) — duplicate of slide 23 (p21) with a QR code added; same code listing
- Dropped: slide 26 (p24) — simple diagram showing single-level jal/jr flow; content fully captured in prose
- Dropped: slide 31 (p31) — summary slide; content is the structure of the transcript itself
- Dropped: repeated footers ("Computer Architecture & Concurrency, Lecture 4: High-level Languages"), slide numbers, UCL logo, copyright notices
- Warnings: 
  - p29 (slide 33): Complex stack frame diagram with multiple $sp/$fp pointer positions shown at different stages of execution. The spatial relationships between pointer positions at different times are approximated in the ASCII layout. The original diagram shows three separate states (before prologue, after prologue, during nested call) side by side. Consider retaining the original slide for visual reference if the temporal staging is important.
  - p25 (slide 27): Diagram showing the infinite-loop problem with arrows between three boxes (main, my_program, abs_diff) at different call stages. Described in prose instead.
- Ambiguities:
  - Slides 13/16 (p13/p16) present the same abs_diff C code twice with progressive annotations. Merged into a single presentation.
  - Slides 18–19 (p18–p19) present function-calling register conventions in two separate tables. Merged and reorganised for clarity.
  - The slide numbering in the PDF is non-contiguous (jumps from slide 14 to 16, from 22 to 23, etc.) — likely due to removed/hidden slides. Transcribed all visible content.
  - p7 slide title uses stylised "J-ump" (italic J, hyphenated). Normalised to standard text.
-->
