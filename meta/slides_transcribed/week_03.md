> Source: [COMP0008\_03\_pre\_1.pdf](../slides_original/COMP0008_03_pre_1.pdf), [COMP0008\_03\_1.pdf](../slides_original/COMP0008_03_1.pdf), [COMP0008\_03\_2.pdf](../slides_original/COMP0008_03_2.pdf)

# MIPS32 Processor — ISA and Instructions

Background reading: Patterson & Hennessey, Chapter 2 (especially Section 2.3). Chapter 2 is best read after covering high-level language compilation, as it synthesises many topics together.

## Roadmap for the MIPS Sequence

The MIPS32 processor architecture is built up over several weeks in this order:

1. **Instruction Set Architecture (ISA)** — hardware instructions and numeric register references.
2. **Assembly language** — pseudo-instructions, named registers, symbolic labels.
3. **High-level language compilation** — how high-level languages compile to assembly; use of the hardware stack for function calling.
4. **The gcc toolchain for MIPS** — compiler, assembler, linker, loader; real MIPS assembly code.

This week covers step 1, building on the binary number concepts from the previous lecture (signed/unsigned, big/little-endian, sign/zero-extension).

## MIPS32 in the Real World

The R3000 MIPS processor was released in 1988 with 115,000 transistors. It powered high-end workstations such as the Silicon Graphics SGI Personal IRIS 4D/20, used to render 3D scenes in films like *Jurassic Park* and *Terminator 2*. A radiation-hardened variant (Mongoose-V) flew aboard the New Horizons space probe to Pluto. The MIPS32 architecture also appears in microcontrollers (e.g. the PIC32-based Mikroelectronics "Clicker", analogous to an Arduino) and single-board computers (e.g. the Imagination Creative Ci40, analogous to a Raspberry Pi, featuring a cXT200 SoC with 2× MIPS interAptiv CPUs at 550 MHz and 512 KB L2 cache).

## Abstract View of a Computer

A processor's (or programmer's) abstract view of a computer consists of three components connected by three buses:

| Component | Role |
|---|---|
| **CPU** | Executes instructions |
| **Memory** | Stores instructions and data |
| **I/O Interfaces** | Connect to peripheral devices |

The buses are:

- **Data Bus** — carries data between components.
- **Address Bus** — carries the address being read/written.
- **Control & Status Bus** — carries read/write signals and status information.

Peripherals (input/output devices) connect through the I/O interfaces.

## MIPS32 CPU and Memory Model

The MIPS32 CPU contains:

- **Control Unit** (control logic) — decodes instructions and orchestrates execution.
- **Arithmetic/Logic Unit (ALU)** — performs arithmetic and logical operations.
- **Program Counter (PC)** — holds the address of the current instruction (e.g. `0x00400000`).
- **32 General-Purpose Registers** — `$0` through `$31`, each storing a 32-bit value. Register `$0` is hardwired to zero; writes to it are ignored.

Memory is **byte-addressable** with 32-bit addresses (range `0x00000000`–`0xFFFFFFFF`). Each address holds one byte. The address bus is 32 bits wide (sufficient to address the full 4 GB space). The data bus is also 32 bits wide — this matches the register width and allows a full word to be transferred in one bus cycle (an 8-bit data bus would require four cycles per word).

The CPU communicates with memory via read and write signals on the control bus.

## Fetch/Execute Cycle

Every instruction executes through a five-step cycle:

1. The processor places the PC value onto the **address bus**.
2. The processor asserts the **read signal**.
3. Memory returns the **32-bit instruction** at that address (4 consecutive bytes).
4. The processor **executes** the instruction.
5. The PC is incremented to **PC + 4** (advancing to the next instruction).

**Example:** With PC = `0x00400000`, memory bytes at that address are `0x00`, `0x22`, `0x40`, `0x20`, forming the 32-bit word `0x00224020`. This decodes to `add $8, $1, $2`. Execution reads `$1` = `0x0A0F1569` and `$2` = `0x00001003`, the ALU computes `0x0A0F1569 + 0x00001003 = 0x0A0F256C`, and the result is written to `$8`.

## RISC Load/Store Architecture

MIPS is a RISC-based **load/store architecture**: only `load` and `store` instructions access memory; **all other instructions operate on registers only**. Adding two values stored in memory and writing the result back therefore requires four instructions:

1. Load value 1 from memory into a register.
2. Load value 2 from memory into a register.
3. Add the two register values, placing the result in a register.
4. Store the result register back to memory.

## Instruction Types and Encoding

All MIPS32 instructions are exactly **32 bits** (one word). The top 6 bits are the **opcode**; the remaining 26 bits encode the arguments. There are three instruction formats:

- **R-type** (register) — operations between registers. Examples: `add $8, $1, $2`; `sub $12, $6, $3`.
- **I-type** (immediate) — operations involving a fixed numeric value. Examples: `addi $15, $15, -1`; `beq $10, $14, 0x00000002`.
- **J-type** (jump) — unconditional jumps. Examples: `j 0x00400050`; `jal 0x0040007c`.

## I-Type (Immediate) Instructions

The I-type format is:

| opcode | rs | rt | Immediate |
|---|---|---|---|
| 6 bits | 5 bits | 5 bits | 16 bits |

General semantics: `R[rt] = func(Imm, R[rs])`.

### Arithmetic Immediate

**Add Immediate (`addi`)** — opcode `8`₁₆, I-type.

$$R[rt] = R[rs] + \text{SignExtImm}$$

The 16-bit immediate is **sign-extended** to 32 bits before the addition.

Example: `addi $8, $8, -1` encodes as `0x2108ffff`:

```
001000  01000  01000  1111111111111111
opcode   rs     rt       immediate (-1 in two's complement)
```

**Add Immediate Unsigned (`addiu`)** — opcode `9`₁₆, I-type.

$$R[rt] = R[rs] + \text{SignExtImm}$$

where $\text{SignExtImm} = \{16\{\text{immediate}[15]\},\ \text{immediate}\}$ (i.e. the immediate is still **sign-extended**, despite the name "unsigned").

Despite its name, `addiu` is used to add constants to signed integers when overflow exceptions are not desired. MIPS has **no subtract-immediate instruction**; negative numbers are handled via sign extension of the immediate field. The "unsigned" designation means only that arithmetic overflow does not trigger an exception.

**Exercise:** What is the value of `$8` after executing:

```mips
addiu $0, $0, 5      # no effect — $0 is hardwired to 0
addiu $8, $0, 5      # $8 = 0 + 5 = 5
addiu $8, $8, 0xFFFF # depends on assembler interpretation
```

The correct answer is **4**. However, the result depends on how the assembler interprets the literal `0xFFFF`:

- The MARS assembler treats `0xFFFF` as the unsigned value 65535 and expands the instruction into three instructions (`lui`, `ori`, `addu`) that add 65535 to `$8`, giving `$8` = 65540.
- Writing `addiu $8, $8, -1` instead causes MARS to emit a single `addiu` instruction with the immediate field set to `0xffff` (the sign-extended representation of −1), giving `$8` = 4.

The hardware instruction always sign-extends the 16-bit immediate. The discrepancy arises from the assembler's handling of out-of-range or ambiguous literals.

### Memory Addressing

Memory addresses are 32 bits long (matching register width). MIPS uses a single addressing mode: **base + displacement**.

Syntax: `displacement(base_register)`, e.g. `0x20($8)`.

The effective address is: $\text{addr} = R[rs] + \text{SignExtImm}$.

Example: if `$8` = `0x10010000`, then `0x20($8)` = `0x10010000 + 0x20` = `0x10010020`.

### Load and Store Instructions

**Store Word (`sw`)** — opcode `2b`₁₆, I-type.

$$M[R[rs] + \text{SignExtImm}] = R[rt]$$

**Load Word (`lw`)** — opcode `23`₁₆, I-type.

$$R[rt] = M[R[rs] + \text{SignExtImm}]$$

Both require the effective address to be **word-aligned** (divisible by 4).

**Example — working with integer arrays:** Suppose `$8` stores the base address of array `A` and `$9` stores `y`.

- `A[8] = y` → `sw $9, 0x20($8)` (offset 0x20 = 32 = 8 × 4 bytes per word).
  Encoding: `0xad090020` = `101011 01000 01001 0000000000100000`.
- `z = A[10]` → `lw $10, 0x28($8)` (offset 0x28 = 40 = 10 × 4).
  Encoding: `0x8d0a0028` = `100011 01000 01010 0000000000101000`.

**Byte and half-word granularities:**

- `lb`/`sb` — load/store byte.
- `lh`/`sh` — load/store half-word (must be **half-word aligned**, i.e. address divisible by 2).
- These are **sign-extended** when loaded into a register.
- Unsigned (zero-extended) variants: `lbu`, `lhu`, `sbu`, `shu`.

### Loading Large Constants

Since the immediate field is only 16 bits, loading a full 32-bit constant requires two instructions. The pseudo-instruction `li` (load immediate) handles this automatically.

Example: `li $8, 7654321` where $7654321_{10} = \texttt{0x74cbb1}$.

The assembler expands this to:

```mips
lui $1, 0x00000074    # Load upper immediate: $1 = 0x00740000
ori $8, $1, 0x0000cbb1 # Or immediate: $8 = 0x00740000 | 0x0000cbb1 = 0x0074cbb1
```

**Load Upper Immediate (`lui`)** sets the most significant 16 bits of the destination register and **zeros** the lower 16 bits. **Or Immediate (`ori`)** performs a bitwise OR with the immediate value, filling in the lower 16 bits.

### Branching Instructions

Branch instructions are essential for implementing loops and conditionals. They use **PC-relative addressing**.

**Branch on Not Equal (`bne`)** — opcode `5`₁₆, I-type.

$$\text{if}(R[rs] \neq R[rt])\ \text{then}\ PC = PC + 4 + \text{BranchAddr}$$

**Branch on Equal (`beq`)** — opcode `4`₁₆, I-type.

$$\text{if}(R[rs] = R[rt])\ \text{then}\ PC = PC + 4 + \text{BranchAddr}$$

The branch address is computed as:

$$\text{BranchAddr} = \{14\{\text{immediate}[15]\},\ \text{immediate},\ 2'b0\}$$

That is, the 16-bit immediate is sign-extended to 30 bits and then left-shifted by 2 (appending two zero bits), yielding a byte offset relative to PC + 4. This allows branches to reach ±128 KB from the current instruction.

**Example:** `bne $9, $0, -3` encodes as `0x1520fffd`:

```
000101  01001  00000  1111111111111101
opcode   rs     rt     immediate (-3)
```

With PC at `0x0040001c`, the branch target is `PC + 4 + (-3 × 4) = 0x00400020 - 12 = 0x00400014`.
<!-- suspected-source-error: The slide shows PC at 0x0040001c and the branch target calculation with immediate=-3 should give PC+4+BranchAddr = 0x00400020 + (-3<<2) = 0x00400020 - 12 = 0x00400014, which would jump back to 0x00400014. The memory layout shown on the slide (0x00400010 containing 0x3c011001) is consistent with jumping back into the loop body. The slide's visual arrows suggest the target is 0x00400010, but the arithmetic gives 0x00400014. Transcribed the encoding and formula faithfully; the exact target depends on interpretation of the memory layout shown. -->

**Branch on comparison with zero:** `bgez` (≥ 0), `bgtz` (> 0), `blez` (≤ 0), `bltz` (< 0). Trivia: `bgez` and `bltz` both have opcode = 1; they are distinguished by the `rt` field.

**Pseudo-instructions for general comparisons:** `bgt` (branch if greater than), `bge`, `ble`, `blt`. These expand into a `slt` (set less than) followed by a `bne` or `beq`. For example, `bgt $10, $11, loop` expands to:

```mips
slt $1, $11, $10       # $1 = ($11 < $10) ? 1 : 0
bne $1, $0, loop       # branch if $1 ≠ 0
```

### Loop Efficiency: Counting Down vs. Up

Counting down to zero is more efficient in MIPS because `bgtz` can compare directly against zero, eliminating the need for a separate comparison value and `slt` instruction.

**Counting up** (`for (int i=0; i<10; ++i)`):

| Basic | Source |
|---|---|
| `addiu $13,$0,0x00000000` | `li $13, 0` |
| `addiu $14,$0,0x0000000a` | `li $14, 10` |
| `jal 0x00400024` | `jal func` |
| `addi $13,$13,0x00000001` | `addi $13, $13, 1` |
| `slt $1,$13,$14` | `blt $13, $14, loop` |
| `bne $1,$0,0xfffffffc` | |

**Counting down** (`for (int i=10; i>0; --i)`):

| Basic | Source |
|---|---|
| `addiu $13,$0,0x0000000a` | `li $13, 10` |
| `jal 0x00400024` | `jal func` |
| `addi $13,$13,0xffffffff` | `addi $13, $13, -1` |
| `bgtz $13,0xfffffffd` | `bgtz $13, loop` |

The count-down version uses 4 instructions per iteration versus 6 for count-up, because `bgtz` directly tests against zero without needing a separate register holding the limit or an `slt` instruction.

## Combining Instructions: Worked Examples

### Bit Field Extraction

**Task:** Given a 32-bit instruction stored in `$4`, extract the `rs` field (bits 25–21).

Example: `$4` = `10101101111010001000000000000000` (the instruction `sw $8, 0x8000($15)`). The `rs` field is `01111` (= 15, i.e. `$15`).

**Solution using mask and shift:**

```mips
lui $5, 0x03e0     # $5 = 00000011111000000000000000000000 (mask for bits 25-21)
and $6, $4, $5     # $6 = 00000001111000000000000000000000 (isolated rs bits)
srl $6, $6, 21     # $6 = 00000000000000000000000000001111 (= 15)
```

The mask `0x03e00000` has ones in exactly bit positions 25–21. The `and` isolates those bits, and the right shift by 21 moves them to the least significant position.

### Set-and-Branch Pattern

To compare a register against a fixed number (e.g. is `$4 < 10`?), use a **set comparison** instruction followed by a branch:

```mips
slti  rt, rs, value    # Set less than immediate (signed)
                        # if (R[rs] < value) then rt = 1 else rt = 0

sltiu rt, rs, value    # Set less than immediate (unsigned)
                        # if (R[rs] < value) then rt = 1 else rt = 0
```

Then test the result with `beq` or `bne` against `$0`:

```mips
slti $1, $4, 10        # $1 = ($4 < 10) ? 1 : 0
bne  $1, $0, target    # branch to target if $4 < 10
```

### Overflow-Safe Unsigned Average

**Version 1 (naive):** Add then shift right by 1.

```mips
li   $8, 173
li   $9, 191
addu $10, $8, $9    # $10 = 173 + 191 = 364
srl  $10, $10, 1    # $10 = 364 >> 1 = 182
```

This works for small values but **fails for large unsigned values** whose sum exceeds 2³² − 1. For example, with `$8` = 3,501,006,752 and `$9` = 794,337,423, the sum overflows 32 bits, and the subsequent right shift produces an incorrect result.

**Version 2 (overflow-safe):** Exploits the bitwise identity:

$$x + y = 2 \cdot (x \mathbin{\&} y) + (x \oplus y)$$

Therefore:

$$\frac{x + y}{2} = (x \mathbin{\&} y) + \frac{x \oplus y}{2}$$

Neither `(x & y)` nor `(x ^ y) >> 1` can overflow, and their sum also cannot overflow (since each is at most half the maximum value).

```mips
li   $8, 3501006752
li   $9, 794337423
and  $10, $8, $9       # $10 = x & y  (common set bits)
xor  $11, $8, $9       # $11 = x ^ y  (differing bits)
srl  $11, $11, 1       # $11 = (x ^ y) / 2
addu $10, $10, $11     # $10 = (x & y) + (x ^ y) / 2 = average
```

<!-- transcription-audit:
- Dropped: pre_1 p1 — title slide / boilerplate
- Dropped: pre_1 p4 photos — decorative (R3000 die shot, Mongoose-V chip, New Horizons probe)
- Dropped: pre_1 p5 photo — decorative (PIC32MX Clicker board)
- Dropped: pre_1 p6 photo — decorative (Ci40 board); retained key specs in text
- Dropped: 03_1 p1 — title slide / decorative images
- Dropped: 03_1 p8 QR code — decorative
- Dropped: 03_1 p14 — administrative announcements (CW1/CW2 deadlines, Pulse survey)
- Dropped: 03_2 p1 — title slide / decorative images
- Dropped: 03_2 p2 — overview slide (content captured in structure)
- Dropped: 03_2 p10 — lecture summary slide (content captured in structure)
- Dropped: pre_1 p2-3 overview/roadmap slides — content integrated into "Roadmap" section
- Warnings: The branching instruction example (03_1 p11) involves a memory layout diagram with PC-relative addressing. The spatial relationships of the memory table and arrows are approximated in prose. The original slide's colour-coded bit-field breakdowns (red opcode, green rs/rt, yellow immediate) throughout 03_1 are flattened to labelled text fields.
- Suspected source errors: The branch target calculation on 03_1 p11 may be inconsistent with the memory layout shown — see inline comment.
- Ambiguities: (1) The pre_1 slides (from Kevin Bryson) and the 03_1/03_2 slides (different visual style, likely a different lecturer) overlap in content; the recap on 03_1 p2 summarises material from pre_1. Merged without duplication. (2) The "addiu $8, $8, 0xFFFF" exercise answer of 4 is presented as correct on the slide, but the explanation acknowledges that MARS would give 65540 for the literal 0xFFFF — transcribed both interpretations faithfully. (3) 03_2 slides have non-sequential page numbers (p3,4 then p5=slide 8, p6=slide 12, etc.) — these are slide numbers from the original deck; transcribed by content not by number.
-->
