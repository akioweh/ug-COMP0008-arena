> Source: [COMP0008\_02\_pre\_1.pdf](slides_original/COMP0008_02_pre_1.pdf), [COMP0008\_02\_pre\_2.pdf](slides_original/COMP0008_02_pre_2.pdf), [COMP0008\_02\_1.pdf](slides_original/COMP0008_02_1.pdf), [COMP0008\_02\_2.pdf](slides_original/COMP0008_02_2.pdf)

# Week 2: Abstracting the Machine and MIPS32 Fundamentals

## Von Neumann Architecture and the Stored-Program Model

The foundational model for modern computers is the **von Neumann architecture**, described in John von Neumann's 1945 *First Draft of a Report on the EDVAC* (Contract No. W-670-ORD-4926, between the United States Army Ordnance Department and the University of Pennsylvania). The report identifies five main subdivisions of a computing system:

1. **Central Arithmetic part (CA)** — performs arithmetic operations.
2. **Central Control part (CC)** — sequences and coordinates operations.
3. **Memory (M)** — stores both instructions and data (the "stored program" concept). Various forms of memory are required, including an outside recording medium (R).
4. **Input (I)** — receives data from the outside world.
5. **Output (O)** — sends results to the outside world.

CC, CA, and M together form the associative part of the machine; I and O are the afferent and efferent parts mediating contact with the outside.

### The Little Man Computer

The **Little Man Computer (LMC)**, created by Dr Stuart Madnick at MIT in 1965, provides a simple but still largely valid analogy for a real computer. It models the key components: CPU, RAM (main memory), buses, input/output, assembly language, and machine code. The LMC follows the stored-program von Neumann architecture.

The LMC simulator shows a CPU containing a **Program Counter**, **Instruction Register**, **Address Register**, **Accumulator**, and **Arithmetic Unit**, connected to a grid of 100 RAM locations (addresses 00–99). A simple program such as:

```
INP
STA 99
INP
ADD 99
OUT
HLT
```

is assembled into numeric opcodes (e.g. `901`, `399`, `901`, `199`, `902`) stored in consecutive RAM locations, demonstrating the stored-program concept.

### CPU–Memory Interaction

The abstract interaction between CPU and memory involves:

- **CPU components:** Control Unit (driven by a clock), Program Counter (PC), Instruction Register (IR), Memory Data Register (MDR), Memory Address Register (MAR), and General Purpose Registers.
- **Memory:** stores machine code instructions and data.
- **Connections:** an Address Bus (carries the location to read/write), a Data Bus (carries the data being transferred), and control signals (Read, Write).

In the original IBM PC, the external bus consisted of physical wires carrying binary signals (0 V = logic 0, +5 V = logic 1):

- **20 address lines** (A0–A19) — can address $2^{20} = 1\text{ MB}$ of locations.
- **8 data lines** (D0–D7) — transfer one byte at a time.
- **Control lines** — including $\overline{\text{MEMR}}$ (memory read), $\overline{\text{MEMW}}$ (memory write), CLK (clock), and GROUND.

## Bus Hierarchy in a Modern PC

A real PC has many different types of buses arranged in a hierarchy. The CPU connects via a **backside bus** to cache memory and via an **external CPU bus** to main memory. A **Host/PCI bridge** connects the CPU bus to the **PCI bus**, which in turn connects to peripherals such as USB ports, network interfaces, and disk controllers. Further bridges connect to the **AGP bus** (for the video card) and the legacy **ISA bus** (for parallel and serial ports). Each bus type has different bandwidth and latency characteristics.

### The Programmer's Abstract View

Despite this complexity, the programmer's abstract view of the architecture reduces to three components connected by three buses:

| Component | Role |
|---|---|
| **CPU** | Executes instructions |
| **Memory** | Stores instructions and data |
| **I/O Interfaces** | Connect to peripherals (input/output devices) |

These are interconnected by a **Data Bus**, an **Address Bus**, and a **Control & Status Bus**.

## Why MIPS32

The Intel Core i3/i5/i7 processors used in PCs are complex due to decades of backwards compatibility. The module instead studies the **MIPS processor**, which has a much more elegant design while embodying the same fundamental concepts that apply to all processors.

### The R3000 Processor

The **R3000** (MIPS32) was released in 1988 with 115,000 transistors. It was used in high-end workstations such as the Silicon Graphics SGI Personal IRIS 4D/20, which rendered 3D scenes for 1990s films like *Jurassic Park* and *Terminator 2*. A radiation-hardened variant, the **Mongoose-V**, was used in the New Horizons space probe that flew to Pluto.

### MIPS32 in Embedded Systems

MIPS32 processors appear in modern embedded devices:

- **Imagination Creative Ci40** — a single-board computer (like a Raspberry Pi) built around the **cXT200 SoC**, which contains a dual-core MIPS interAptiv CPU at 550 MHz with 32 kB L1 data cache and 32 kB L1 instruction cache per core, a Coherency Manager with 512 kB L2 cache, an FPU, and an Ensigma C4500 RPU. The SoC integrates Wi-Fi, Bluetooth, Ethernet, USB, I2C, UART, SPI, and other peripherals on a single chip, connected via a SoC Fabric bus.
- **Mikroelectronics PIC32MX Clicker** — a microcontroller board (like an Arduino) based on the **PIC32MX534F064H**, which uses a 32-bit MIPS M4K Core running at 80 MHz / 105 DMIPS with a 5-stage pipeline and 32-bit ALU. It has 64 KB Flash (plus 12 K boot Flash), 16 KB RAM, 53 I/O pins, and peripherals including SPI, I2C, A/D converters, CAN, UARTs, and timers. Microcontrollers generally do not run operating systems — the processor directly executes application code ("programming to the bare metal").

### The ISA as an Abstraction Layer

The **Instruction Set Architecture (ISA)** hides the hardware from the software. A high-level statement like `i = i + 1;` in C compiles to MIPS assembly (`add $s3,$s3,1`) which in turn corresponds to a 32-bit machine code word (`001000 01011 01011 0000000000000001`). The ISA sits at the boundary between software and hardware in a layered abstraction:

| Level | Name | Examples |
|---|---|---|
| 5 | Problem-Oriented Language | Programs (C, Java) |
| 4 | Assembly Language | MIPS assembly |
| 3 | Operating System | Device drivers |
| 2 | Instruction Set Architecture (ISA) | Instructions, registers |
| 1 | Microprogramming (not all computers) | Datapaths, controllers |
| 0.5 | Modular view (datapath) | Adders, memories |
| 0 | Digital Logic | AND gates, NOT gates |

Below the digital logic level lie analog circuits (amplifiers, filters), devices (transistors, diodes), and ultimately physics (electrons). The ISA level is entirely numeric, which motivates the study of computer arithmetic and memory layout.

### The MARS Simulator

**MARS** (MIPS Assembler and Runtime Simulator) is a MIPS32 virtual machine used for writing and testing MIPS assembly programs. It provides an editor, assembler, and execution environment with a register display panel showing all 32 registers and their values. An example Fibonacci program in MARS uses `.data` and `.text` sections with instructions such as `la`, `lw`, `li`, `add`, `sw`, `addi`, and `bne`.

## Number Representation (Recap)

### Hexadecimal, Binary, and Decimal

Each hexadecimal digit maps to exactly 4 binary digits. For example:

$$\texttt{0xCAFE} = 1100\ 1010\ 1111\ 1110_2 = 2^{15} + 2^{14} + 2^{11} + 2^{9} + 2^{7} + 2^{6} + 2^{5} + 2^{4} + 2^{3} + 2^{2} + 2^{1} = 51966_{10}$$

### Two's Complement

To represent negative numbers in $N$-bit two's complement, compute $2^N - |x|$. For example, with $N = 8$:

- $0b01001111$ represents $2^6 + 2^3 + 2^2 + 2^1 + 2^0 = 79$.
- Its two's complement is $2^8 - 79 = 177$.
- $177$ as an unsigned integer is $0b10110001$.
- Therefore $(-79)$ has the two's complement representation $0b10110001$.

Two's complement addition works directly: $0011_2\ (3) + 1001_2\ (-7) = 1100_2\ (-4)$.

### Signed and Unsigned Integer Ranges

A **signed** $n$-bit integer (two's complement) can represent $-2^{n-1}, \ldots, 2^{n-1} - 1$. For example, an 8-bit signed integer ranges from $-128$ to $127$.

An **unsigned** $n$-bit integer can represent $0, \ldots, 2^n - 1$. For example, an 8-bit unsigned integer ranges from $0$ to $255$.

The same bit pattern can have different interpretations depending on whether it is treated as signed or unsigned. For example, adding $11001011_2$ and $01010000_2$:

- **Signed:** $-53 + 80 = 27$. The result $00011011_2 = 27$ with a carry out of 1 (which is discarded in signed arithmetic).
- **Unsigned:** $203 + 80 = 283$. The 8-bit result is $00011011_2 = 27$ with a carry out of 1, indicating the true result ($283$) exceeds the 8-bit range.

### Overflow Detection in Two's Complement

- **(pos) + (neg)** and **(pos) − (pos)**: **cannot overflow** (the result is always representable).
- **(neg) + (neg)**: the result should be negative. Overflow occurs if the result is positive.
- **(pos) + (pos)**: the result should be positive. Overflow occurs if the result is negative.

Examples (8-bit):

- $-53 + (-48)$: $11001011_2 + 11010000_2 = 10011011_2 = -101_{10}$ with carry out 1. The result is negative as expected — **no overflow**.
- $75 + 80$: $01001011_2 + 01010000_2 = 10011011_2 = -101_{10}$ with carry out 0. The result is negative when it should be positive — **overflow**.

### Extending Numbers (Sign Extension and Zero Extension)

To extend an $n$-bit number to a wider representation:

- **Positive / unsigned values** — pad with zeros on the left (**zero extension**). E.g. $01001011_2$ (8-bit) becomes $00000000\,01001011_2$ (16-bit).
- **Unsigned negative-looking values** — also zero-extend. E.g. $11001011_2$ unsigned becomes $00000000\,11001011_2$.
- **Signed (two's complement) values** — replicate the sign bit on the left (**sign extension**). E.g. $11001011_2 = -53$ becomes $11111111\,11001011_2 = -2^{15} + 2^{14} + \cdots + 2^7 + 2^6 + 2^3 + 2^1 + 2^0 = -53$.

## Memory Organisation

### Memory Units

- A **binary digit (bit)** is a single 0 or 1.
- A **byte** is 8 bits.
- A **kilobyte (KB)** is $2^{10} = 1024$ bytes (not 1000, because powers of 2 are natural in binary systems).
- A **megabyte (MB)** is $2^{20} = 1024$ KB.
- Larger units follow the same pattern: gigabyte (GB), terabyte (TB), petabyte (PB), exabyte (EB), zettabyte (ZB), yottabyte (YB).

### Words

A **word** is the natural unit of data used by a given processor. For MIPS32, a word is 32 bits. The word size typically determines the sizes of registers, memory addresses, instructions, and floating-point variables. MIPS16 and MIPS64 variants also exist.

The terminology for data sizes differs between MIPS32 and Intel x86:

| Size (bits) | MIPS32 Name | Intel x86 Name |
|---|---|---|
| 8 | Byte | Byte |
| 16 | Half word | Word |
| 32 | Word | Double word |
| 64 | Double word | Quad word |

### Memory as an Array

Memory can be viewed as an array of bytes (each address holds 8 bits, addresses increment by 1: 0, 1, 2, 3, 4, …) or as an array of words (each address holds 32 bits, addresses increment by 4: 0x0, 0x4, 0x8, 0xC, 0x10, …).

### Byte Order (Endianness)

When storing a multi-byte value in memory, the **byte order** matters. Consider storing the word `0xBABACAFE` at address 8:

| | Offset 0 | Offset 1 | Offset 2 | Offset 3 |
|---|---|---|---|---|
| **Big Endian** | BA | BA | CA | FE |
| **Little Endian** | FE | CA | BA | BA |

- **Big endian** stores the most significant byte at the lowest address.
- **Little endian** stores the least significant byte at the lowest address.

Endianness affects type casting. If the 32-bit integer 9 (`0x00000009`) is stored at address 4:

- **Big endian** stores bytes as `00 00 00 09`. Casting to 16 bits by reading from address 4 yields `0x0000` = 0.
- **Little endian** stores bytes as `09 00 00 00`. Casting to 16 bits by reading from address 4 yields `0x0009` = 9.

### Setting Register Values (Extension in Practice)

When writing an 8-bit immediate value into a 32-bit register, the value must be extended:

- Writing **4** into register `$9`: zero-extend to `00000000 00000000 00000000 00000100`.
- Writing **−4** (`0b11111100`) into register `$9`: sign-extend to `11111111 11111111 11111111 11111100`.

## MIPS32 Instruction Set Architecture

### Machine Code

MIPS32 instructions are fixed-width **32-bit** binary words stored in memory. A sequence of such words constitutes a machine-language program. For example, the machine code for a routine to compute and print the sum of the squares of integers from 0 to 100 is a column of 32-bit binary values — completely opaque without knowledge of the instruction encoding.

### Registers

The MIPS32 CPU has **32 general-purpose registers**: `$0` through `$31`, each 32 bits wide. Register `$0` is hardwired to the value **0** and cannot be changed. Unlike x86 and other complex ISAs, MIPS arithmetic and logic instructions operate **only on registers** — they cannot directly access memory. This simplifies the ISA but increases the number of instructions needed for a given task.

For example, the operation `Mem[0x1001000] += Mem[0x1001004]` requires four MIPS instructions:

1. Load `Mem[0x1001000]` into a register.
2. Load `Mem[0x1001004]` into a register.
3. Add the two registers.
4. Store the result back to `Mem[0x1001000]`.

### MIPS as a RISC Processor

MIPS is a **Reduced Instruction Set Computer (RISC)**: it has simple, uniform instructions with a fixed 32-bit width. Each instruction is divided into a **6-bit opcode** and **26 bits of arguments**. The Program Counter (PC) points to the address of the current instruction in memory. Instructions and data coexist in the same address space (stored-program model).

Example: the instruction at address `0x00400000` has the value `0x3c011001`. In binary: `0b00111100000000010001000000000001`. The first 6 bits (`001111`) identify this as `lui` (Load Upper Immediate).

### The Address-Encoding Problem

In MIPS32, both addresses and instructions are 32 bits long, but 6 bits of each instruction are consumed by the opcode, leaving only 26 bits for arguments. This means a single instruction cannot encode a full 32-bit address or immediate value. Solutions include splitting the value across two instructions (e.g. `lui` to load the upper 16 bits, then `ori` to set the lower 16 bits) and using relative addressing for branches.

### Instruction Types

MIPS32 has three instruction formats:

- **R-type** (Register) — arithmetic/logic operations between registers.
  - Examples: `add $8, $1, $2` ; `sub $12, $6, $3`
- **I-type** (Immediate) — operations involving a fixed numeric constant.
  - Examples: `addi $15, $15, -1` ; `beq $10, $14, 0x00000002`
- **J-type** (Jump) — unconditional jumps.
  - Examples: `j 0x00400050` ; `jal 0x0040007c`

### R-Type Instruction Format

R-type instructions have opcode `000000`. The remaining 26 bits are divided into five fields:

| Field | `opcode` | `rs` | `rt` | `rd` | `shamt` | `funct` |
|---|---|---|---|---|---|---|
| Bits | 6 | 5 | 5 | 5 | 5 | 6 |

The operation is `R[rd] = func(R[rs], R[rt])`, where `funct` specifies the particular operation.

**Example — `add $8, $1, $2`:**

```
add $8, $1, $2
  opcode  rs     rt     rd     shamt  funct
  000000  00001  00010  01000  00000  100000
= 0x00224020
```

`R[$8] = R[$1] + R[$2]`. The `funct` field `100000` = `0x20` identifies the `add` operation.

**Example — `sub $5, $7, $6`:**

```
sub $5, $7, $6
  000000  00111  00110  00101  00000  100010
= 0x00e62822
```

**Example — `sltu $3, $22, $11`:**

```
sltu $3, $22, $11
  000000  10110  01011  00011  00000  101011
= 0x02cb182b
```

`sltu` (Set Less Than Unsigned): `R[$3] = (R[$22] < R[$11]) ? 1 : 0`.

### Shift Instructions

Shift instructions are R-type with `rs = 0`. The operation is `R[rd] = shift(R[rt])`, with the shift amount in the `shamt` field.

**Example — `srl $11, $7, 4`:**

```
srl $11, $7, 4
  000000  00000  00111  01011  00100  000010
= 0x00075842
```

Shift operations and their arithmetic meaning:

- **Left shift** by $k$: equivalent to multiplication by $2^k$. E.g. $100_{10} \ll 4 = 1600$; $1100100_2 \ll 4 = 11001000000_2$.
- **Logical right shift** (`>>>` or `srl`): shifts right and fills with zeros. E.g. $100_{10} \gg 4 = \lfloor 100 / 16 \rfloor = 6$; $1100100_2 \gg 4 = 110_2$. For the 32-bit representation of $-100$ (`0xffffff9c`): `0xffffff9c >>> 4 = 0x0ffffff9 = 268435449`.
- **Arithmetic right shift** (`>>` or `sra`): shifts right and replicates the sign bit. E.g. $-100_{10} \gg 4 = \lfloor -100 / 16 \rfloor = -7$; `0xffffff9c >> 4 = 0xffffff9c` shifted with sign extension.

### Bitwise Operations

Bitwise operations apply independently to each bit position. MIPS32 provides AND, OR, XOR, and NOR:

| A | B | AND | OR | XOR | NOR |
|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 1 |
| 0 | 1 | 0 | 1 | 1 | 0 |
| 1 | 0 | 0 | 1 | 1 | 0 |
| 1 | 1 | 1 | 1 | 0 | 0 |

**Example — `and $9, $4, $5`:**

```
$4 = 11010000101011010001111110100000
$5 = 00101111010100001010000010001111
$9 = 00000000000000000000000010000000
```

### Pseudo Instructions

Pseudo instructions are **not real MIPS32 instructions** — they have no opcodes and are not recognised by the CPU. The assembler translates them into one or more real instructions.

**`move $8, $9`** — copies the value of `$9` into `$8`. Translated to `add $8, $9, $0` (adding zero via `$0`).

**`not $8, $9`** (bitwise NOT, i.e. `$8 ← ~$9`) — several candidate implementations:

- `sub $8, $0, $9` — **wrong**: this computes $-$9$ (arithmetic negation), not $\sim$9$ (bitwise complement). E.g. $\sim 0 = -1$ but $-0 = 0$.
- `nor $8, $9, $9` — **correct**: since `$9 | $9 = $9`, `NOR($9, $9) = ~$9`.
- `nand $8, $9, $9` — **wrong**: there is no `nand` instruction in MIPS32.
- `nor $9, $0, $8` — **wrong**: the parameter order is incorrect (writes to `$9` instead of `$8`, and uses `$8` as source instead of `$9`).
- `nor $8, $9, $0` — **correct** (MARS's implementation): since `$9 | 0 = $9`, `NOR($9, $0) = ~$9`.

### From High-Level Language to Machine Code

The translation from a high-level expression to assembly is **not unique** — different compilers (or humans) may produce different but equivalent instruction sequences. However, the translation from assembly to machine code **is unique** (each mnemonic maps to exactly one binary encoding). **Disassembly** reverses machine code back to assembly.

Example: $x = a - b + c - d$

One possible translation:

```mips
sub  $10, $4, $5     # $10 = a - b
sub  $11, $6, $7     # $11 = c - d
add  $12, $10, $11   # $12 = (a-b) + (c-d)
```

An alternative:

```mips
sub  $10, $4, $5     # $10 = a - b
sub  $10, $10, $7    # $10 = (a-b) - d
add  $12, $10, $6    # $12 = (a-b-d) + c
```

Both produce the same result. The first sequence assembles to: `0x00855022`, `0x00C75822`, `0x014B6020`.

### R-Type Instruction Summary

| Instruction | Mnemonic | op | funct (hex) | Description |
|---|---|---|---|---|
| Add | `add` | 0 | 0x20 | Addition with signed overflow |
| Subtract | `sub` | 0 | 0x22 | Subtraction with signed overflow |
| And | `and` | 0 | 0x24 | Logical AND |
| Or | `or` | 0 | 0x25 | Logical OR |
| Xor | `xor` | 0 | 0x26 | Logical XOR |
| Nor | `nor` | 0 | 0x27 | Logical NOR |
| Set Less Than | `slt` | 0 | 0x2A | Set on less than (signed) |
| Set Less Than Unsigned | `sltu` | 0 | 0x2B | Set on less than (unsigned) |
| Shift Right Logical | `srl` | 0 | 0x02 | Logical right shift |
| Shift Right Arithmetic | `sra` | 0 | 0x03 | Arithmetic right shift |
| Shift Left Logical | `sll` | 0 | 0x00 | Logical left shift |

<!-- transcription-audit:
- Dropped: pre_1 slide 1 — title slide (boilerplate)
- Dropped: pre_1 slide 2 — overview/meta-narration
- Dropped: pre_1 slide 6 — decorative photo of Dell PC internals
- Dropped: pre_2 slide 1 — title slide (boilerplate)
- Dropped: pre_2 slide 2 — duplicate of pre_1 slide 11 (abstract architecture view)
- Dropped: 02_1 slide 1 — title slide with decorative images and check-in QR code
- Dropped: 02_1 slide 12 — summary slide (content already captured)
- Dropped: 02_1 slide 13 — Pulse Survey QR code
- Dropped: 02_2 slide 1 — title slide with decorative images
- Dropped: 02_2 slide 13 — QR code for NOT pseudo-instruction activity
- Dropped: pre_1 slide 7 — motherboard photo (illustrative; the questions it poses are addressed in the bus architecture section)
- Dropped: pre_2 slides 3, 4, 5, 7 — decorative photos of MIPS chips and boards (key specs preserved in prose)
- Dropped: 02_2 slide 7 — MIPS reference card image (too detailed to reproduce; key R-type entries captured in summary table)
- Warnings:
  - pre_2 slide 6 (cXT200 SoC block diagram): Complex block diagram with many interconnected components. Key architectural features (dual-core CPU, cache hierarchy, peripheral buses) described in prose. Full spatial layout not preserved; recommend retaining original slide if detailed SoC topology is needed.
  - pre_2 slide 8 (PIC32 SoC diagram): Similar complex SoC block diagram. Key specs captured in prose; spatial layout lost.
  - pre_1 slide 9 (CPU-Memory interaction diagram): Described in prose. The spatial relationships (which registers connect to which buses) are captured but the visual layout is approximated.
  - pre_1 slide 10 (PC bus hierarchy diagram): Complex multi-level bus hierarchy. Described in prose; full topology not preserved as ASCII diagram due to complexity.
  - pre_2 slide 9 (ISA abstraction layers): Rendered as a table. The original used a visual stack with images at each level; the table captures the information content.
  - 02_1 slide 10 (byte order diagrams): Memory layout diagrams with offsets. Rendered as tables; spatial arrangement preserved.
  - 02_2 slide 14 (NOT pseudo-instruction analysis): Complex multi-column comparison with check/cross marks. Rendered as prose with correct/wrong annotations.
- Ambiguities:
  - pre_1 slide 5 (LMC simulator screenshot): The assembly code shown is a simple "output the sum of two numbers" program. I transcribed the visible assembly mnemonics and described the CPU components visible in the simulator.
  - 02_2 slide 15 (high-level commands): The slide shows x = a - b + c - d with two alternative assembly translations. The second alternative uses a different computation order. Both are valid; I preserved both.
  - The MIPS reference card (02_2 slide 7) from Patterson and Hennessy contains extensive instruction listings. Only the R-type instructions discussed in the lecture are captured in the summary table.
- Suspected source errors:
  - pre_2 slide 4: "Jurrasic Park" appears to be a misspelling of "Jurassic Park". Corrected in transcript as it is clearly a typo.
-->
