> Source: [COMP0008\_05\_pre\_1.pdf](slides_original/COMP0008_05_pre_1.pdf), [COMP0008\_05\_pre\_2.pdf](slides_original/COMP0008_05_pre_2.pdf), [COMP0008\_05\_1.pdf](slides_original/COMP0008_05_1.pdf), [COMP0008\_05\_2.pdf](slides_original/COMP0008_05_2.pdf)

# Week 5 — GCC Toolchain, System Calls, and Basic Data Types

Recommended reading: Patterson & Hennessy Section 2.12, Appendix A.7, Appendix B. Acknowledgements: Harris & Harris book for C-code examples and figures.

## The GCC MIPS Toolchain

### Compilation Pipeline

The gcc toolchain transforms high-level C code into an executable through a sequence of stages. Each stage produces an intermediate file that resides on disk:

1. **Compiler** — translates high-level C source (`test.c`) into assembly language (`test.s`).
2. **Assembler** — converts assembly into an object file (`test.o`) containing machine code.
3. **Linker** — combines the object file with other object files and library files to produce an executable (`a.out`).
4. **Loader** — the OS calls a loader program to load the executable from disk into main memory (RAM) following the MIPS memory map, then execution begins.

### The Imagination Creative Ci40 Board

The Ci40 is a single-board computer (similar to a Raspberry Pi) but with a MIPS32 processor. Key specifications:

- **SoC:** cXT200
- **CPU:** 2× MIPS interAptiv at 550 MHz
- **L2 cache:** 512 KB
- **RPU:** Ensigma C4500
- **Storage:** Micro SD card
- **Memory:** NOR/NAND flash
- **Connectivity:** 802.11ac 2×2 antenna, Bluetooth 4.1, 6LoWPAN, Ethernet
- **I/O:** Raspberry Pi B+ I/O header, mikroBUS slots, USB power/OTG, JTAG, Digital Audio
- **Security:** TPM chip
- **Power:** 9V DC input

### Textbook Example: Compiling C to MIPS Assembly

Harris & Harris (Code Example 6.30) shows a simple C program with three global variables compiled to MIPS assembly:

**C source:**

```c
int f, g, y; // global variables

int main(void) {
    f = 2;
    g = 3;
    y = sum(f, g);
    return y;
}

int sum(int a, int b) {
    return (a + b);
}
```

**Textbook MIPS assembly (simplified):**

```mips
      .data
f:
g:
y:
      .text
main:
      addi  $sp, $sp, -4    # make stack frame
      sw    $ra, 0($sp)     # store $ra on stack
      addi  $a0, $0, 2      # $a0 = 2
      sw    $a0, f           # f = 2
      addi  $a1, $0, 3      # $a1 = 3
      sw    $a1, g           # g = 3
      jal   sum              # call sum procedure
      sw    $v0, y           # y = sum(f, g)
      lw    $ra, 0($sp)     # restore $ra from stack
      addi  $sp, $sp, 4     # restore stack pointer
      jr    $ra              # return to operating system

sum:
      add   $v0, $a0, $a1   # $v0 = a + b
      jr    $ra              # return to caller
```

### Binary Executable File on Disk

The executable file on disk contains a header followed by text and data segments:

| Section | Field | Value |
|---|---|---|
| **Executable file header** | Text Size | 0x34 (52 bytes) |
| | Data Size | 0xC (12 bytes) |

**Text segment** (starting at address 0x00400000):

| Address | Machine Code | Instruction |
|---|---|---|
| 0x00400000 | 0x23BDFFFC | `addi $sp, $sp, -4` |
| 0x00400004 | 0xAFBF0000 | `sw $ra, 0($sp)` |
| 0x00400008 | 0x20040002 | `addi $a0, $0, 2` |
| 0x0040000C | 0xAF848000 | `sw $a0, 0x8000($gp)` |
| 0x00400010 | 0x20050003 | `addi $a1, $0, 3` |
| 0x00400014 | 0xAF858004 | `sw $a1, 0x8004($gp)` |
| 0x00400018 | 0x0C10000B | `jal 0x0040002C` |
| 0x0040001C | 0xAF828008 | `sw $v0, 0x8008($gp)` |
| 0x00400020 | 0x8FBF0000 | `lw $ra, 0($sp)` |
| 0x00400024 | 0x23BD0004 | `addi $sp, $sp, 4` |
| 0x00400028 | 0x03E00008 | `jr $ra` |
| 0x0040002C | 0x00851020 | `add $v0, $a0, $a1` |
| 0x00400030 | 0x03E00008 | `jr $ra` |

**Data segment:**

| Address | Data |
|---|---|
| 0x10000000 | f |
| 0x10000004 | g |
| 0x10000008 | y |

### MIPS Memory Map and the Loader

The OS loader places the executable into RAM following the MIPS memory map:

| Address Range | Region | Description |
|---|---|---|
| 0x00000000 | Reserved | OS-reserved memory |
| 0x00400000 | Text | Program instructions (PC starts here) |
| 0x10000000 | Static Data | Global variables (f, g, y); `$gp` = 0x10008000 |
| 0x10010000 | Heap (Dynamic Data) | Memory allocated with `malloc`/`calloc`; grows upward |
| 0x7FFFFFFC | Stack | Local variables, stack frames; `$sp` = 0x7FFFFFFC; grows downward |

An "image file" is a direct copy of the values making up this memory map layout for a particular process.

### Real GCC Output: `gcc -S` on the Ci40

Compiling the same C program on the Ci40 with `gcc -S test.c` produces a `test.s` file that is considerably more complex than the textbook version. Key differences include position-independent code (PIC) directives, use of the global pointer (`$gp`), frame pointer (`$fp`), and explicit `nop` instructions for pipeline hazards.

**Global variable allocation** uses `.comm` directives (similar to `.word` but for uninitialised common symbols):

```mips
.comm f,4,4    # allocate 4 bytes for f, aligned to 4
.comm g,4,4
.comm y,4,4
```

**The `main` function** (annotated):

```mips
      .text
      .globl main
main:
      addiu $sp,$sp,-32      # make space on stack (32 bytes)
      sw    $31,28($sp)      # store return address ($ra)
      sw    $fp,24($sp)      # store frame pointer
      move  $fp,$sp          # set new frame pointer
      lui   $28,%hi(__gnu_local_gp)
      addiu $28,$28,%lo(__gnu_local_gp)
      .cprestore 16          # save $gp at 16($sp)

      # f = 2
      lw    $2,%got(f)($28)  # get address of f via GOT
      li    $3,2
      sw    $3,0($2)

      # g = 3
      lw    $2,%got(g)($28)
      li    $3,3
      sw    $3,0($2)

      # y = sum(f, g)
      lw    $2,%got(f)($28)
      nop
      lw    $3,0($2)         # load f
      lw    $2,%got(g)($28)
      nop
      lw    $2,0($2)         # load g
      nop
      move  $5,$2            # $a1 = g
      move  $4,$3            # $a0 = f
      jal   sum              # call sum
      nop

      # store result in y
      lw    $28,16($fp)      # restore $gp
      move  $3,$2            # move result ($v0) to $3
      lw    $2,%got(y)($28)
      nop
      sw    $3,0($2)         # y = result

      # return y
      lw    $2,%got(y)($28)
      nop
      lw    $2,0($2)         # load y into $v0

      # epilogue
      move  $sp,$fp
      lw    $31,28($sp)      # restore $ra
      lw    $fp,24($sp)      # restore $fp
      addiu $sp,$sp,32       # restore $sp
      j     $31              # return from main
      nop
```

**The `sum` function:**

```mips
      .globl sum
sum:
      addiu $sp,$sp,-8       # make space on stack
      sw    $fp,4($sp)       # store old frame pointer
      move  $fp,$sp          # update frame pointer
      sw    $4,8($fp)        # push $a0 ("a") onto stack
      sw    $5,12($fp)       # push $a1 ("b") onto stack
      lw    $3,8($fp)        # load a
      lw    $2,12($fp)       # load b
      nop
      addu  $2,$3,$2         # a + b
      move  $sp,$fp
      lw    $fp,4($sp)       # restore frame pointer
      addiu $sp,$sp,8        # restore stack pointer
      j     $31              # return
      nop
```

### Disassembly with `objdump -S`

An alternative approach is to compile with debug information (`gcc -g test.c`) and then disassemble with `objdump -S a.out`, which interleaves the original C source with the generated assembly. In the disassembly output, register `$s8` is used as a synonym for `$fp` (frame pointer), and registers are generally referred to by name without the `$` prefix.

The disassembly shows the same structure as the `gcc -S` output but with resolved addresses and machine code. Key observations:

- `main` is located at address 0x00400690.
- `sum` is located at address 0x00400728.
- The global pointer setup uses `lui gp,0x42` / `addiu gp,gp,-30672` to compute the `$gp` value.
- Global variables are accessed via offsets from `$gp` (e.g., `lw v0,-32744(gp)` for `f`).
- The executable format is `elf32-tradlittlemips` (little-endian MIPS ELF).

The resulting assembly is more complex than the Harris & Harris textbook suggests, but the overall key structure is the same: stack frame setup, global variable access, function call via `jal`, result storage, and stack frame teardown.

**Optional reference:** *See MIPS Run: Linux* by Dominic Sweetman (Second Edition, Morgan Kaufmann) — covers the full MIPS32 assembly language including assembly directives, and how the MIPS32 processor works under Linux. Available from the UCL library.

## MIPS Coprocessors and the Memory Map

### The MIPS R2000 Coprocessor Architecture

The MIPS architecture includes multiple coprocessors alongside the main CPU:

- **CPU (main processor):** 32 general-purpose registers ($0–$31), an arithmetic unit, a multiply/divide unit (with Hi and Lo registers), and the program counter (PC).
- **Coprocessor 0 (traps and memory):** handles exceptions and memory management. Contains special registers:
  - **BadVAddr** — the address that caused an address exception
  - **Cause** — the exception code
  - **Status** — processor status bits
  - **EPC** (Exception Program Counter) — the PC value at the time of the exception
- **Coprocessor 1 (FPU):** the floating-point unit, with its own 32 registers ($f0–$f31) and arithmetic unit.

### Memory Map with Kernel Space

The full MIPS memory map includes a kernel space region above user space:

| Address | Region |
|---|---|
| 0xFFFFFFFC | Top of kernel space |
| 0x80000000–0xFFFFFFFC | Kernel space (privileged) |
| 0x7FFFFFFC | Stack (`$sp`), grows downward |
| 0x10010000 | Dynamic data (heap), grows upward |
| 0x10000000 | Static data (`$gp` points into this region) |
| 0x00400000 | Text segment (instructions) |
| 0x00000000 | Reserved |

Variables are allocated in different memory regions based on their scope:

- **Local variables** within a function → stored in the stack frame of that function.
- **Dynamically allocated memory** (`malloc`/`calloc`) → stored in the dynamic data (heap) segment.
- **Global variables** (outside any function) → stored in the static data segment.

## Exception Handling

### The Kernel and Exceptions

The kernel handles all exceptions. When an exception occurs, the PC changes to an address in kernel space. The kernel can store the processor state to return to the program if needed, and can run privileged instructions not allowed in user space (e.g., accessing kernel memory addresses or halting the machine).

### Exception Mechanism

When an exception occurs:

1. The **exception code** is loaded into coprocessor 0's `cause` register.
2. The current **PC value** is stored in coprocessor 0's `epc` register.
3. The **PC is set to 0x80000080**, the fixed location of the exception handler code.
4. Registers `$k0` and `$k1` may be used as scratch registers by the handler without being saved/restored.

### Exception Types

| Number | Name | Cause |
|---|---|---|
| 0 | Int | Interrupt (hardware) |
| 4 | AdEL | Address error exception (load or instruction fetch) |
| 5 | AdES | Address error exception (store) |
| 6 | IBE | Bus error on instruction fetch |
| 7 | DBE | Bus error on data load or store |
| 8 | Sys | Syscall exception |
| 9 | Bp | Breakpoint exception |
| 10 | RI | Reserved instruction exception |
| 11 | CpU | Coprocessor unimplemented |
| 12 | Ov | Arithmetic overflow exception |
| 13 | Tr | Trap |
| 15 | FPE | Floating point exception |

## System Calls

### The `syscall` Instruction

`syscall` is a native CPU instruction with machine code encoding `0x0000000c`. Technically it is an R-type instruction where opcode, rs, rt, and rd are all zero. It triggers exception code 8 (Sys), transferring control to the kernel to perform an operating system service.

The system call number is placed in `$v0` before executing `syscall`. Input parameters follow the standard convention of using `$a0`–`$a3`.

### MIPS/MARS System Call Table

| Service | $v0 | Arguments | Results |
|---|---|---|---|
| print_int | 1 | `$a0` = integer | |
| print_float | 2 | `$f12` = float | |
| print_double | 3 | `$f12` = double | |
| print_string | 4 | `$a0` = string address | |
| read_int | 5 | | integer in `$v0` |
| read_float | 6 | | float in `$f0` |
| read_double | 7 | | double in `$f0` |
| read_string | 8 | `$a0` = buffer, `$a1` = length | |
| exit | 10 | | |
| read_char | 12 | | char in `$v0` |

### Example: Interactive Calculator (Add Two Numbers)

```mips
# Interactive calculator – add 2 numbers together
      .data
str1: .asciiz "\nEnter first value: "
str2: .asciiz "Enter second value: "
str3: .asciiz "Sum is equal to "

      .text
      .globl main
main: addi $v0, $0, 4       # syscall 4: print_string
      la   $a0, str1        # load address of str1
      syscall               # print "Enter first value: "

      addi $v0, $0, 5       # syscall 5: read_int
      syscall               # read integer into $v0
      add  $t1, $0, $v0     # store first integer in $t1

      addi $v0, $0, 4       # syscall 4: print_string
      la   $a0, str2        # load address of str2
      syscall               # print "Enter second value: "

      addi $v0, $0, 5       # syscall 5: read_int
      syscall               # read integer into $v0
      add  $t1, $t1, $v0    # add second integer to first

      addi $v0, $0, 4       # syscall 4: print_string
      la   $a0, str3        # load address of str3
      syscall               # print "Sum is equal to "

      addi $v0, $0, 1       # syscall 1: print_int
      add  $a0, $0, $t1     # move sum to $a0
      syscall               # print the result

      li   $v0, 10          # syscall 10: exit
      syscall
```

## Character and String Representation

### ASCII

In the 1950s, computers used varying "byte" lengths (6, 7, or 8 bits) depending on the character set. In 1963, the American Standard Association proposed the 7-bit **American Standard Code for Information Interchange (ASCII)** encoding, defining 128 characters. IBM System/360 (1964) standardised the 8-bit byte, as character processing became more important than digit processing.

The printable ASCII characters occupy codes 32–127. Codes 0–31 are **control (non-printable) characters** such as NUL (0), HT/horizontal tab (9), LF/line feed (10), CR/carriage return (13), and ESC (27).

Useful bit-manipulation tricks for ASCII letters:

- **Force uppercase:** `x &= ~0b100000` (clears bit 5)
- **Toggle case:** `x ^= 0b100000` (flips bit 5)
- **Get numeric value of a digit character:** `y - '0'` = `y - 48`

### Extended ASCII and ISO Variants

Standard ASCII has no support for many common characters (e.g., the £ sign). The UK ISO 646 variant (1967) replaced `#` with `£`. **Extended ASCII** uses 8 bits to encode additional characters within a single byte, with different code pages for different regions (e.g., ISO Latin-1 for Western European languages, ISO Latin-2 for Central European languages).

### Unicode

Unicode is a global solution using up to 4 bytes per character (code points 0–0x10FFFF), currently including approximately 145,000 characters covering all world languages, symbols (including emoji), and maintaining backward compatibility with Extended ASCII Latin-1.

Unicode has multiple encodings:

- **UTF-32** — the simplest: exactly 32 bits per character. Raises endianness issues (resolved by a byte-order mark character preceding the text).
- **UTF-8** — a variable-length encoding (Thompson and Pike, 1992) that is efficient and backward-compatible with ASCII:
  - `0xxxxxxx` (1 byte) — ASCII character `xxxxxxx`
  - `110yyyyy 10yyyyyy` (2 bytes) — encodes Unicode character `0byyyyyyyyyyy`. Covers most Latin-script alphabets plus Greek, Cyrillic, Coptic, Armenian, Hebrew, Arabic.
  - `1110zzzz 10zzzzzz 10zzzzzz` (3 bytes) — gives 16 bits, enough for the Basic Multilingual Plane.
  - `11110aaa 10aaaaaa 10aaaaaa 10aaaaaa` (4 bytes) — encodes the remaining characters.

### Strings in C

Python `str` and Java `String` classes are internally complex and use Unicode characters. The C representation of a string is much simpler: a null-terminated sequence of bytes. Assuming ASCII encoding, the string `"Hello !"` is stored as:

`0x48 0x65 0x6c 0x6c 0x6f 0x20 0x21 0x00`

The final `0x00` is the null terminator.

## Floating-Point Representation

### Representing Real Numbers

Binary point notation works analogously to decimal: $27.3_{10} = 2 \cdot 10^1 + 7 \cdot 10^0 + 3 \cdot 10^{-1}$, and $10.11_2 = 1 \cdot 2^1 + 0 \cdot 2^0 + 1 \cdot 2^{-1} + 1 \cdot 2^{-2} = 2.75_{10}$. The key questions are: how does the computer know where the point is, and how are negative real numbers represented?

### Fixed-Point Representation

When the scale (number of fractional digits) is known in advance, a fixed-point representation can be used. For example, prices with two decimal places: £86.73 can be stored as the integer 8673. Negative numbers follow seamlessly using two's complement (e.g., −86.73 stored as the two's complement of −8673).

### IEEE 754 Floating-Point Format

When the scale is not known, it must be encoded as part of the number. The number is expressed in normalised scientific notation in binary: $1101.11_2 = 1.10111_2 \times 2^3$, where `10111` is the **mantissa** (fraction) and `3` is the **exponent**.

#### Single Precision (32-bit)

The IEEE 754 single-precision format uses 32 bits:

| Field | Bits | Description |
|---|---|---|
| Sign | 1 | 0 = positive, 1 = negative |
| Exponent argument (EA) | 8 | Biased exponent |
| Fraction (mantissa) | 23 | Fractional part after the implicit leading 1 |

The value of a **normal** number is:

$$\text{Value} = (-1)^{\text{sign}} \times 2^{EA - B} \times 1.\text{fraction}$$

where $B = 127$ is the bias. The exponent argument for normal numbers is in the range $\{1, \ldots, 254\}$, giving a true exponent range of $[-126, 127]$.

**Worked example:** The bit pattern `1 10000011 01000000000000000000000` represents:
- Sign = 1 (negative)
- EA = 10000011₂ = 131
- True exponent = 131 − 127 = 4
- Fraction = .01₂, so 1.fraction = 1.01₂ = 1.25
- Value = $-2^4 \times 1.25 = -20_{10}$

**Range of single precision:**
- Largest representable number: $(2 - 2^{-23}) \times 2^{127} \approx 2^{128}$
- Smallest representable normal number: $2^{-126}$

#### Subnormal Numbers (Single Precision)

Subnormal (denormalised) numbers are represented with EA = 0. They use the formula:

$$\text{Value} = (-1)^{\text{sign}} \times 2^{-126} \times 0.\text{fraction}$$

Note the implicit leading digit is 0 (not 1) and the exponent is fixed at −126. Examples:

- `1 00000000 01000000000000000000000` → $-2^{-126} \times 0.01_2 = -2^{-128}$
- `0 00000000 11111111111111111111111` → $2^{-126} \times (1 - 2^{-23})$
- `0 00000000 00000000000000000000001` → $2^{-126} \times 2^{-23} = 2^{-149}$ (smallest positive subnormal)
- `0 00000000 00000000000000000000000` → +0 (there is also −0)

#### Special Values (EA = 255)

When EA = 255 (all exponent bits set):
- Fraction = 0 → $\pm\infty$ (sign bit determines the sign)
- Fraction ≠ 0 → **NaN** (Not a Number)

Arithmetic rules for special values:

| Operation | Result |
|---|---|
| n ÷ ±Infinity | 0 |
| ±Infinity × ±Infinity | ±Infinity |
| ±nonZero ÷ ±0 | ±Infinity |
| ±finite × ±Infinity | ±Infinity |
| Infinity + Infinity | +Infinity |
| −Infinity − Infinity | −Infinity |
| ±0 ÷ ±0 | NaN |
| ±Infinity ÷ ±Infinity | NaN |
| ±Infinity × 0 | NaN |
| NaN == NaN | False |

#### Worked Example: Representing π as a Single-Precision Float

$$\pi \approx 3.14159\,26535\,89793_{10}$$

Converting to binary: $\pi \approx 11.00100100001111110110101\ldots_2$

Normalising: $= 1.10010010000111111011011_2 \times 2^1$ (with rounding of the last bit)

Encoding:
- Sign = 0 (positive)
- EA = 1 + 127 = 128 = `10000000`₂
- Fraction = `10010010000111111011011`

Bit pattern: `0 10000000 10010010000111111011011`

Accuracy: the actual value represented is 3.1415927410125732421875, while π starts with 3.1415926535897932384626 — a relative error of approximately $3 \times 10^{-8} < 2^{-24}$.

#### Double Precision (64-bit)

IEEE 754 double precision uses 64 bits with the same structure:

| Field | Bits |
|---|---|
| Sign | 1 |
| Exponent argument | 11 |
| Fraction | 52 |

- Bias $B = 1023$
- Normal numbers: $EA \in [1, 2046]$
- $EA = 0$: subnormals
- $EA = 2047$: NaN and $\pm\infty$

Other IEEE 754 precisions include quad precision (128 bits), half precision (16 bits), and emerging formats FP8/FP6/FP4.

## The MIPS Floating-Point Unit (Coprocessor 1)

### Instruction Formats

Floating-point instructions use coprocessor 1 (opcode `010001`). Two formats:

- **FR format** (register): `010001 | fmt (5) | ft (5) | fs (5) | fd (5) | funct (6)`
- **FI format** (immediate): `010001 | fmt (5) | ft (5) | Immediate (16)`

### Loading and Storing FP Registers

- **From/to memory:**
  - `lwc1 $f1, 100($s2)` — load word to coprocessor 1 register
  - `swc1 $f1, 100($s2)` — store word from coprocessor 1 register
- **From CPU registers:**
  - `mtc1 $t2, $f2` — move word from CPU register to FP register

### Arithmetic Instructions

| Instruction | Description |
|---|---|
| `add.s $f2, $f4, $f6` | FP add (single precision) |
| `sub.s $f2, $f4, $f6` | FP subtract (single precision) |
| `mul.s $f2, $f4, $f6` | FP multiply (single precision) |
| `div.s $f2, $f4, $f6` | FP divide (single precision) |
| `add.d $f2, $f4, $f6` | FP add (double precision) |
| `sub.d $f2, $f4, $f6` | FP subtract (double precision) |
| `mul.d $f2, $f4, $f6` | FP multiply (double precision) |
| `div.d $f2, $f4, $f6` | FP divide (double precision) |

Floating-point registers range from `$f0` to `$f31`. Double precision is 64-bit and uses two adjacent registers, so only even-numbered registers (`$f0`, `$f2`, `$f4`, …) are allowed for doubles.

### Conversion Instructions

The `cvt` (convert) instructions handle type conversions between integer and floating-point formats:

- `cvt.s.w` — convert word (integer) to single-precision float
- `cvt.d.w` — convert word to double-precision float
- `cvt.d.s` / `cvt.s.d` — convert between single and double precision
- `cvt.w.s` / `cvt.w.d` — convert float/double to word (integer)
- `cvt.l.*` / `cvt.*.l` — convert to/from long (MIPS64 only)

### Example: Computing π Using the Madhava–Leibniz Series

The Madhava–Leibniz series (attributed to Madhava of Sangamagrama, 1340–1425):

$$\pi = 4 \sum_{n=0}^{\infty} \frac{(-1)^n}{2n+1} = 4 \cdot \arctan(1)$$

The following MIPS assembly computes an approximation of π using 10,000 terms of this series with single-precision floating-point arithmetic:

```mips
      li    $8, 0             # iteration number n
      li    $15, 10000        # number of summands
      mtc1  $0, $f0           # $f0 = 0.0 (running sum)
      li    $9, 1
      mtc1  $9, $f1
      cvt.s.w $f1, $f1        # $f1 = 1.0 (constant)
      j     loop

end:
      li    $13, 4
      mtc1  $13, $f4
      cvt.s.w $f4, $f4        # $f4 = 4.0
      mul.s $f0, $f0, $f4     # $f0 = 4 * sum ≈ π

      li    $v0, 2            # syscall 2: print_float
      mov.s $f12, $f0         # argument in $f12
      syscall

loop:
      sll   $12, $8, 1
      addi  $12, $12, 1       # $12 = 2n + 1
      mtc1  $12, $f2
      cvt.s.w $f2, $f2        # $f2 = (float)(2n + 1)

      div.s $f2, $f1, $f2     # $f2 = 1/(2n + 1)

      andi  $11, $8, 1        # $11 = n % 2
      sll   $11, $11, 1       # $11 = 2*(n % 2)
      sub   $11, $9, $11      # $11 = 1 - 2*(n%2) = (-1)^n
      mtc1  $11, $f3
      cvt.s.w $f3, $f3        # $f3 = (float)((-1)^n)

      mul.s $f2, $f2, $f3     # $f2 = (-1)^n / (2n+1)
      add.s $f0, $f0, $f2     # sum += term

      addi  $8, $8, 1         # n++
      bne   $8, $15, loop     # repeat if n < 10000
      j     end
```

<!-- transcription-audit:
- Dropped: pre_1 slide 1 — title/boilerplate (lecturer name, email, room number)
- Dropped: pre_1 slide 2 — overview/recap slide (content captured in context)
- Dropped: pre_1 slide 8 — repeated Ci40 board photo (same as slide 3, used as demo backdrop)
- Dropped: pre_1 slide 9 — optional book recommendation (preserved as inline text reference)
- Dropped: pre_1 slide 10 — summary slide (content already covered)
- Dropped: pre_2 pages 4-7 — _init, __start, __do_global_ctors_aux, _fini, .plt, __libc_start_main@plt sections of the objdump output (OS/runtime initialisation boilerplate, not relevant to the C→MIPS compilation concept being taught)
- Dropped: 05_1 slide 1 — decorative title slide
- Dropped: 05_1 slide 2 — recap slide (content noted inline)
- Dropped: 05_1 slide 13 — summary slide (content already covered)
- Dropped: 05_2 slide 1 — decorative title slide
- Dropped: 05_2 slide 2 — recap slide (content noted inline)
- Dropped: 05_2 slide 9 — QR code slide ("What did we learn about character encodings?")
- Dropped: 05_2 slide 14 — calculator screenshot (illustrative of mantissa/exponent concept already explained in text)
- Dropped: 05_2 slide 27 — summary slide (content already covered)
- Dropped: 05_2 slides 11-12 — slide numbers 11-12 do not exist (numbering jumps from 10 to 13 in the original)
- Warnings:
  - pre_1 slide 3: Ci40 board photograph with annotated callouts — described in prose; the photo itself is not reproducible in text but all labelled information is captured.
  - pre_1 slide 4: Photograph of Harris & Harris textbook page showing Code Example 6.30 — content fully transcribed from the visible text.
  - 05_2 slide 4: ASCII table — full table content is described; the exact visual grid layout is approximated.
  - 05_2 slide 5: Control characters table — content described in prose rather than reproducing the full 32-row table.
  - 05_2 slide 6: ISO Latin-1 and ISO Latin-2 character set images — mentioned by name; full tables not reproduced as they are reference material.
  - 05_2 slides 13, 15-17, 19: IEEE 754 bit-field diagrams with colour-coded sign/exponent/fraction regions — described structurally in tables and text; colour coding (sign=cyan, exponent=green, fraction=pink) flattened to labelled fields.
  - 05_2 slide 24: Portrait of Madhava of Sangamagrama — decorative, dropped.
- Ambiguities:
  - pre_2 page 2 comments state "Sets arguments $a0 (register 5) and $a1 (register 4)" — this appears to be a register-numbering vs. name confusion in the source annotations ($a0 is register 4, $a1 is register 5). The assembly code itself uses $4 and $5 correctly. Transcribed the code verbatim; the prose annotations are from the source.
  - The objdump disassembly in pre_2 is very lengthy; only the main and sum functions (the pedagogically relevant parts) are included in full. The runtime/OS boilerplate sections are dropped.
  - 05_1 slide 4 shows the memory map without kernel space; slide 5 adds kernel space. These are build-up slides merged into a single description.
- Suspected source errors:
  - pre_2 page 2: The annotation says "Sets arguments $a0 (register 5) and $a1 (register 4)" but $a0 is register $4 and $a1 is register $5. The register numbers and names are swapped in the comment. The actual assembly code (`move $5,$2` and `move $4,$3`) is correct. Transcribed verbatim.
-->
