# Week 1 — Introduction to Computer Architecture and Concurrency

## Course Structure

The module is split into two halves:

**Part I — Computer Architecture:** overview of key components of computer architecture; MIPS32 architecture and
assembly language; block diagram of how a MIPS processor works; instruction-level parallelism (pipelining, superscalar
architecture); thread-level parallelism (multicore, memory coherence/consistency); operating systems topics (processes,
threads, running executables, multithreading, low-level concurrency primitives created from assembly instructions).

**Part II — Java Concurrent Programming:** concurrency abstraction and understanding concurrent systems; interference,
visibility issues, safety/liveness balance, deadlock; Java concurrency mechanisms (locks, mutexes, semaphores, monitor
design); the Java concurrency package (`java.util.concurrent`); coordinating threads to work together.

### Assessment

Three courseworks during Terms 1/2, each worth 10%:

1. Electran online system — testing fundamental architecture topics and MIPS assembly language programming.
2. Moodle quizzes on Java concurrency.
3. Multi-threaded Java programming exercise.

A comprehensive Term 3 open-book assessment is worth the remaining 70%.

### Textbooks

**Computer Architecture:**

- _Computer Organization and Design_ (4th Edition) by Patterson and Hennessy, 2009, ISBN 978-0-12-374493-7. The MIPS
  edition (not the more recent ARM or RISC-V editions). Key textbook about the MIPS processor architecture, written by
  the professors who designed the chip.
- _Digital Design and Computer Architecture_ by David Money Harris and Sarah L. Harris, 2013, ISBN 0123944244. Covers
  MIPS architecture and MIPS assembly (the course does not focus on the electronics/logic-gates aspects).

**Concurrency:**

- _Java Concurrency in Practice_ by Brian Goetz, Addison-Wesley, 2006. Advanced text on Java concurrency and key design
  principles.
- _Concurrency: State Models & Java Programs_ by J. Magee and J. Kramer, John Wiley & Sons, 2006. Covers key concurrency
  concepts with demos; also includes more formal material involving finite state machine analysis that the course does
  not cover.

## Motivation for Concurrency

### Sequential vs Concurrent Programs

A **sequential program** consists of instructions that are _totally ordered_. The instructions are carried out in a
precise sequence and the process is **deterministic**. In reality the compiler/processor may change the order of
instructions (out-of-order execution), but it guarantees the same deterministic results.

A **concurrent program** is a set of ordinary sequential programs executed at the "same time" (i.e. concurrently).

**Concurrency** is a key abstraction in computer science, relevant to hardware design, operating systems,
multiprocessors, distributed computing, programming, and design. It is _the ability to run multiple activities
simultaneously or in parallel_ (and reason correctly about these systems).

### The "Too Much Milk" Problem

Consider a morning routine expressed as pseudocode:

```
1. Enter Kitchen
2. Look into Fridge
3. If (milk < 0.1 litres) {
     1. Go to shop.
     2. Buy milk.
     3. Bring home.
     4. Put in Fridge.
   }
4. Eat porridge ...
```

When two people execute this program concurrently with a shared fridge, both may independently observe that milk is low,
both go out and buy milk, and the fridge ends up with too much milk. This is a classic illustration of a **race
condition** on shared state — the check-then-act sequence is not atomic.

### Historical Origins: Time-Sharing Operating Systems

Early batch machines loaded one program at a time, leading to very inefficient CPU utilisation — the CPU sat idle during
I/O operations. One of the first time-sharing (multi-tasking) operating systems was **CTSS** (Compatible Time Sharing
System), developed at MIT in 1961. It introduced the concept of the _background job_ or **process**, with the aim of
keeping the CPU busy by switching to another process when the current one blocks on I/O.

### Interleaved Concurrency vs True Parallelism

**Interleaved concurrency** occurs when there is only one execution engine (processor). The single processor switches
rapidly between different processes, giving the illusion of simultaneous execution, but there is no true parallel
processing.

**True parallelism** requires multiple execution engines. The milk example is an instance of true parallelism — two
people (execution engines) running the same program simultaneously on shared data.

### Why Combine Concurrency with Computer Architecture?

Modern CPUs are multicore — a quad-core processor has four execution engines. CPU architectures switched to multicore
around the 2000s because single-core performance scaling hit physical limits. Both designing and programming multicore
hardware requires understanding concurrency and hardware together.

GPUs push this further: the NVIDIA Tesla K80 GPU board has 4,992 cores and can deliver over 8.74 TFLOPS of peak
floating-point performance, programmed using CUDA (a C-based language).

### Flynn's Taxonomy (1972)

Flynn's taxonomy classifies processor architectures along two dimensions — the number of instruction streams and the
number of data streams:

|                          | Single Data | Multiple Data |
| ------------------------ | ----------- | ------------- |
| **Single Instruction**   | **SISD**    | **SIMD**      |
| **Multiple Instruction** | **MISD**    | **MIMD**      |

- **SISD** — Single Instruction, Single Data: traditional uniprocessor.
- **SIMD** — Single Instruction, Multiple Data: e.g. GPU cores executing the same instruction on different data.
- **MISD** — Multiple Instruction, Single Data: rare; sometimes used for fault tolerance.
- **MIMD** — Multiple Instruction, Multiple Data: multicore CPUs, distributed systems.

### Case Study: Therac-25

The Therac-25 was a radiation therapy machine controlled by an embedded computer handling many concurrent sensing and
actuation tasks (TV camera, beam on/off, door interlock, motion power, turntable position, display terminal, etc.).

Between 1985 and 1987, at least five people died from massive radiation overdoses on these machines. The root cause was
concurrency bugs — specifically **race conditions** — in the control software. The software passed formal testing, but
as operators became faster at entering commands, the timing-dependent bugs manifested: a metal target was not moved into
place before the beam fired, resulting in lethal overdoses. The software company initially blamed mechanical failure. It
took two years and five deaths before the concurrency bugs were found. Previous versions of the machine (Therac-20) had
hardware interlocks that masked the software bugs; the Therac-25 removed those interlocks, relying solely on software.

### Java Visibility Puzzles

**The Holder puzzle.** Consider:

```java
// ... some other class ...
public Holder holder;
public void initialize() {
    holder = new Holder(42);
}
// ...

public class Holder {
    private int n;

    public Holder(int n) {
        this.n = n;
    }

    public void my_test() {
        if (n != n) {
            throw new ExceptionError("This statement is false!");
        }
    }
}
```

The question: can `my_test()` throw the exception? Counter-intuitively, **yes** — in a concurrent context, due to the
Java Memory Model, another thread could see a partially constructed `Holder` object where `n` has not yet been written,
or the two reads of `n` in `n != n` could see different values. This motivates the need to understand what the hardware
is doing.

**The Terminator puzzle.** A `Thread` subclass with a `boolean crush` field:

```java
public class Terminator extends Thread {
    private boolean crush = false;

    public void run() {
        while (true) {
            if (crush) {
                System.out.println(
                    "I see crush == true ... I'll be back!");
                break;
            }
            System.out.print("I am just doing what I was " +
                "programmed to do ... \n");
        }
    }

    public void crush() {
        crush = true;
    }
}
```

A main method starts the thread, sleeps for 5 seconds, then calls `crush()`:

```java
public class Main {
    public static void main(String[] args)
            throws InterruptedException {
        Terminator robot = new Terminator();
        robot.start();

        Thread.sleep(5000);
        System.out.println("Crushing the robot ...\n");
        robot.crush();
    }
}
```

Despite only reading and writing a single boolean, this is **not guaranteed to work** — the `crush` field is not
declared `volatile`, so the running thread may never see the update made by the main thread due to caching and the Java
Memory Model. The thread could loop forever.

### Why Concurrent Programming Is Required

- **Performance gain** from multiprocessing hardware (parallelism).
- **Increased application throughput** — a blocking I/O call only blocks one thread.
- **Increased application responsiveness** — a high-priority thread can handle user requests.
- **More appropriate structure** for programs that control multiple activities and handle multiple events.
- **Embedded systems** for driving hardware (e.g. Therac-25) — equipment naturally consists of multiple
  sensors/actuators.
- **Distributed systems.**

## Motivation for Computer Architecture

### Early Computing Machines

**Antikythera mechanism** — the earliest known analogue mechanical computer. Its architecture used continuous
floating-point values stored as degrees of rotation of cogs, with operations limited to fixed multiplications and
divisions. It was programmable only by physically rebuilding the machine, and was not general-purpose (not Turing
complete, as it lacked branching instructions). Its organisation was a fixed layout of wheels and cogs.

**Babbage's Analytical Engine** (designed 1834–1871) — considered the first _digital_ computer design, running programs
from punched cards. Its architecture used discrete 40-digit decimal values stored in the discrete rotation of wheels,
with a memory of 1,000 such values. It supported +, −, ×, ÷, comparisons, and optionally square root. It was
programmable via punched cards (similar to modern assembly language) and was Turing complete (it had branching
instructions). Its organisation was still a fixed layout of wheels and cogs.

### Analogue vs Digital; Number Base Choices

The Antikythera mechanism and the Heathkit educational analogue computer used continuous values (angles, voltages).
Analogue computers can perform operations like differentiation directly, but continuous representations are susceptible
to noise.

Early electronic computers experimented with different number bases. ENIAC 1 used decimal calculations. The Russian
**Setun** (1958) used ternary (base 3), representing symbols with negative, zero, and positive voltages. Modern
computers settled on binary.

### Key Milestones in Computer Hardware

- **Colossus** (1943, Bletchley Park) — one of the first digital programmable electronic computers, used to decrypt the
  German Lorenz cipher. Programmed using switches and patched cables. Its organisation used thermionic valves (vacuum
  tubes) to carry out binary operations (Boolean algebra).
- **ENIAC 1** — one of the first electronic computers, using thermionic valves and decimal arithmetic.
- **IBM 7030** — one of the first transistor-based electronic computers, using individual transistors.
- **IBM 360** — used discrete chips with logic gates. Crucially, it introduced the idea of a single **computer
  architecture** (instruction set) with multiple different **implementations** (organisations) of that architecture at
  different price/performance points.

| Model                    | M30              | M40              | M50            | M65            |
| ------------------------ | ---------------- | ---------------- | -------------- | -------------- |
| Datapath width           | 8 bits           | 16 bits          | 32 bits        | 64 bits        |
| Control store size       | 4k × 50          | 4k × 52          | 2.75k × 85     | 2.75k × 87     |
| Clock rate               | 1.3 MHz (750 ns) | 1.6 MHz (625 ns) | 2 MHz (500 ns) | 5 MHz (200 ns) |
| Memory capacity          | 8–64 KiB         | 16–256 KiB       | 64–512 KiB     | 128–1,024 KiB  |
| Performance (commercial) | 29,000 IPS       | 75,000 IPS       | 169,000 IPS    | 567,000 IPS    |
| Performance (scientific) | 10,200 IPS       | 40,000 IPS       | 133,000 IPS    | 563,000 IPS    |
| Price (1964 $)           | $192,000         | $216,000         | $460,000       | $1,080,000     |

- **Intel 4004** — the first microprocessor on a single chip, used in the Busicom 141-PF calculator.
- **Intel 8088** — 16-bit processor used in the original IBM PC.

### The Von Neumann Architecture

Computers settled into a **stored-program von Neumann architecture** with three main components connected by an external
bus (or buses):

1. **Processor / CPU** (Central Processing Unit)
2. **Memory storage** — holding both instructions and data
3. **Input/Output (I/O) devices** — displays, keyboards, pointer devices

### CISC vs RISC

During the 1980s, Intel and other manufacturers drove ever more complex instruction sets (**CISC** — Complex Instruction
Set Computer), since programmers working in assembly wanted fancier instructions. This required writing complex
"microprograms" within the hardware chips to execute these instructions.

Hennessy and Patterson went for a radically different approach: **RISC** (Reduced Instruction Set Computer). The MIPS
R3000 (released 1988, 115,000 transistors) was used to render 3D scenes in 1990s films like _Jurassic Park_ and
_Terminator 2_. RISC architectures are now used in over 20 billion portable devices per year, as well as in
supercomputers (e.g. the Sunway TaihuLight, which uses custom 260-core 64-bit RISC chips made in China).

### Performance Scaling Eras

A graph of processor performance (relative to the VAX 11-780) over time shows distinct eras:

- **CISC era** (~1980–1986): performance doubling every ~2.5 years (22%/year).
- **RISC era** (~1986–2003): performance doubling every ~1.5 years (52%/year).
- **End of Dennard scaling → Multicore** (~2003–2011): performance doubling every ~3.5 years (23%/year).
- **Amdahl's Law limits** (~2011–2015): performance doubling every ~6 years (12%/year).
- **End of the line** (post-2015): performance doubling every ~20 years (3%/year).

### New Architectures

Computer architecture continues to evolve beyond traditional von Neumann designs:

- **Google Tensor Processing Unit (TPU)** — an application-specific architecture for machine learning. Its block diagram
  shows a PCIe/host interface, DDR3 memory interfaces, a unified buffer (local activation storage), a systolic array
  feeding a matrix multiply unit (64K operations per cycle), accumulators, activation and normalise/pool stages, with
  data bandwidths up to 165 GiB/s internally.
- **IBM TrueNorth** — a neuromorphic chip designed for deep neural networks.
- **D-Wave quantum computers** — using qubits for quantum computation.

### Abstraction Layers of a Modern Computer

A modern computer can be understood through a hierarchy of abstraction layers:

| Level | Name                               | Examples                                             |
| ----- | ---------------------------------- | ---------------------------------------------------- |
| 5     | Problem-Oriented Language          | `i = i + 1;` (C source)                              |
| 4     | Assembly Language                  | `add $s3,$s3,1` (MIPS assembly)                      |
| 3     | Operating System                   | System calls, process management                     |
| 2     | Instruction Set Architecture (ISA) | `001000 01011 01011 0000000000000001` (machine code) |
| 1     | Microprogramming                   | Not all computers have this level                    |
| 0.5   | Modular view (datapath)            | Datapaths, controllers                               |
| 0     | Digital Logic                      | AND gates, NOT gates, transistors                    |

The course covers: how C language constructs are compiled into MIPS assembly and executed (levels 5→4); MIPS assembly
language and how machine code works (level 4→2); computer arithmetic and memory layout, since the ISA level is entirely
numbers (level 2).

### Why Learn Assembly Language?

- Game development historically required assembly for performance (e.g. x86 assembly for games like _Lemmings 2_ in the
  1980s; 3D graphics engine optimisation in the 1990s).
- Low-level device driver development often requires examining or writing assembly.
- Compiler/tool-chain development for novel processor architectures.
- Fully understanding concurrency and multithreaded programming requires understanding the machine.
- Low-level debugging — when inserting print statements makes a bug disappear (a Heisenbug), assembly-level inspection
  is needed.

## Number Systems

### The Decimal System

The decimal system uses ten digits (0–9) in a **positional** notation. Each digit's value depends on its position:

$$193 = 1 \cdot 10^2 + 9 \cdot 10^1 + 3 \cdot 10^0$$

This is superior to older **additive** systems (e.g. Roman numerals: MDCCCCV = 1905).

The system extends naturally to fractions ($1.7 = 1 \cdot 10^0 + 7 \cdot 10^{-1}$) and rational numbers
($7/6 = 1.1\dot{6}$). Every rational number has a finite repeating decimal representation. Decimal numbers are often
denoted with a subscript: $176_{10}$.

The decimal system is not the only option — for example, 1,702,131 can be viewed as a base-1000 number:
$1 \cdot 1000^2 + 702 \cdot 1000^1 + 131 \cdot 1000^0$.

### The Binary System

Binary uses only two digits: 0 and 1. A digit in {0, 1} is called a **binary digit** (**bit**). The unary system, by
contrast, has a single digit (1).

$$1101_2 = 1 \cdot 2^3 + 1 \cdot 2^2 + 0 \cdot 2^1 + 1 \cdot 2^0 = 13_{10}$$

Multiplying by $10_2$ (i.e. 2) simply appends a "0" on the right: $1101_2 \cdot 10_2 = 11010_2$. Binary is commonly
denoted with the prefix `0b` and is the natural representation for computers.

### Binary Arithmetic

Binary addition and multiplication follow the same rules as decimal:

**Addition:** $1101_2 + 0110_2 = 10011_2$ (i.e. 13 + 6 = 19).

**Multiplication:** $1101_2 \times 0110_2 = 1001110_2$ (i.e. 13 × 6 = 78). Multiplication is performed by shifting and
adding partial products, where each partial product is either zero or the multiplicand shifted left.

### Converting Decimal to Binary

**Greedy algorithm:** find the largest power of two that does not exceed the number, subtract it, and repeat.

Example: $69_{10}$. The largest power of two ≤ 69 is $64 = 2^6$. Remainder: 5. Largest power ≤ 5 is $4 = 2^2$.
Remainder: 1. Largest power ≤ 1 is $1 = 2^0$. Remainder: 0. Result: $1000101_2$.

### Hexadecimal Representation

Binary numbers are hard for humans to read (e.g. $1010101001111011_2$ vs $43643_{10}$). **Hexadecimal** (base 16) uses
16 digits: 0123456789ABCDEF.

$$\text{0xAA7B} = 10 \cdot 16^3 + 10 \cdot 16^2 + 7 \cdot 16^1 + 11 \cdot 16^0 = 43643_{10}$$

Conversion between binary and hex is trivial: group binary digits into blocks of four from the right, and map each group
to a hex digit.

$$1010\;1010\;0111\;1011_2 \rightarrow A\;A\;7\;B_{16} = \text{0xAA7B}$$

### Notation in Programming Languages

In code (e.g. Python, Java), bases are indicated by prefixes rather than subscripts:

| Base             | Prefix | Example          |
| ---------------- | ------ | ---------------- |
| Binary (2)       | `0b`   | `0b110000011111` |
| Octal (8)        | `0`    | `06037`          |
| Decimal (10)     | (none) | `3103`           |
| Hexadecimal (16) | `0x`   | `0xC1F`          |

### Comparing Numbers Across Bases

Ordering exercise — which is largest among `010000000` (7 zeros, octal), `0x100000` (5 zeros, hex),
`0b11111111111111111111` (20 ones, binary), and `1000000` (6 zeros, decimal)?

True order (largest first):

1. $010000000_8 = 8^7 = (2^3)^7 = 2^{21}$
2. $\text{0x100000}_{16} = 2^{20} = 1024^2 > 1000000$
3. $0b\underbrace{1\ldots1}_{20} = 2^{20} - 1 > 1000000$
4. $1000000_{10}$

### Representing Negative Numbers

#### Sign-Magnitude

In mathematics, $-173 = (-1) \cdot 173$. This **sign-magnitude** representation is not ideal for hardware: zero has two
representations (+0 and −0), and arithmetic is complicated by the need to handle signs separately.

#### Two's Complement

The **two's complement** of an $N$-bit number is defined as its complement with respect to $2^N$. For an $N$-bit two's
complement number $x = (x_{N-1}\, x_{N-2}\, \ldots\, x_0)_2$:

$$x = -x_{N-1} \cdot 2^{N-1} + \sum_{i=0}^{N-2} x_i \cdot 2^i$$

The most significant bit (MSB) acts as the sign bit: 0 for non-negative, 1 for negative.

Example (3-bit two's complement):

| Decimal | Two's comp. |
| ------- | ----------- |
| −4      | 100         |
| −3      | 101         |
| −2      | 110         |
| −1      | 111         |
| 0       | 000         |
| 1       | 001         |
| 2       | 010         |
| 3       | 011         |

Example: $2^3 - 3 = 1000_2 - 011_2 = 101_2$, which represents −3.

**Exercises:**

- 5-bit two's complement $10101_2$: $-2^4 + 2^2 + 2^0 = -16 + 4 + 1 = -11$.
- 6-bit two's complement $110101_2$: $-2^5 + 2^4 + 2^2 + 2^0 = -32 + 16 + 4 + 1 = -11$.

Note that sign-extending a negative number (prepending 1s) preserves its value.

#### Why Two's Complement?

- **Single zero representation** simplifies equality checking.
- **Arithmetic is transparent** — addition and multiplication work identically for signed and unsigned numbers; the
  hardware does not need separate circuits.

Addition examples (4-bit):

- $0011_2 + 1001_2 = 1100_2$ (3 + (−7) = −4).
- $0110_2 + 1101_2 = \cancel{1}0011_2$ (6 + (−3) = 3; carry out is discarded).

Multiplication example (4-bit):

- $1110_2 \times 0011_2 = \cancel{10}1010_2$ (−2 × 3 = −6; upper bits beyond the word size are discarded).

### Interpretation Is Context-Dependent

The same bit pattern can represent different things depending on interpretation:

$0b\,0100\,1000\,0110\,1001$:

- As an unsigned decimal integer: $2^{14} + 2^{11} + 2^6 + 2^5 + 2^3 + 2^0 = 18537_{10}$.
- In hexadecimal: `0x4869`.
- As ASCII text: 'Hi' (0x48 = 'H', 0x69 = 'i').

<!-- transcription-audit:
- Dropped: pre_1 slide 1 — title slide (boilerplate: module name, lecturer contact)
- Dropped: pre_1 slide 3 — course organisation (purely administrative: lecture schedule, office hours)
- Dropped: pre_1 slide 20 — decorative Terminator movie screenshots
- Dropped: pre_2 slide 1 — title slide (duplicate boilerplate)
- Dropped: pre_2 slide 2 — near-duplicate of pre_1 slide 25 transition slide
- Dropped: pre_2 slide 9 — "Anyone know what this is?" slide showing Heathkit analogue computer photo (content folded into analogue vs digital discussion)
- Dropped: pre_2 slide 20 — screenshots of news articles about IBM TrueNorth and D-Wave (content summarised in text)
- Dropped: main deck slide 1 — title slide with decorative images
- Dropped: main deck slide 9 — interactive Mentimeter poll slide (no substantive content)
- Warnings:
  - pre_1 slides 10–11: timing diagrams showing CPU/IO/process activity over time. Described in prose; spatial timing relationships are approximated.
  - pre_2 slide 15: IBM 360 slide contains both a comparison table (transcribed) and a layered abstraction diagram (transcribed as table). The abstraction diagram appears again on slides 21–23 and is fully captured.
  - pre_2 slide 17: Sunway TaihuLight supercomputer architecture diagram showing master core, slave cores, memory controllers, and network-on-chip. Described briefly in prose; full spatial layout not preserved.
  - pre_2 slide 18: Performance scaling graph (performance vs. VAX 11-780 over time). Key data points and eras transcribed; exact curve shape not preserved.
  - pre_2 slide 19: Google TPU block diagram with data flow rates. Key components and bandwidths transcribed in prose; spatial layout not preserved.
  - pre_2 slides 21–23: Intel 4004 block diagram and abstraction layers diagram. Transcribed as a table; block diagram spatial relationships not preserved.
  - main deck slide 5: Binary arithmetic worked examples with carry bits shown spatially. Transcribed as inline examples.
  - main deck slide 6: Decimal-to-binary conversion shown as a tree/waterfall diagram. Described as a step-by-step algorithm.
  - main deck slide 10: Comparison exercise with ordering shown as a vertical ranked list with colour coding. Transcribed as numbered list.
  - main deck slides 12–13: Two's complement arithmetic examples with carry-out bits shown. Transcribed inline with strikethrough notation for discarded carries.
- Ambiguities:
  - pre_1 slide 19: The code uses "ExceptionError" which is not a standard Java class. Transcribed verbatim as it appears in the source.
  - pre_2 slide 13: The slide labels the Analytical Engine as the first "von Neumann architecture" — this is historically debatable (von Neumann's report was 1945), but the slide appears to mean it was the first design with the key structural elements. Transcribed faithfully.
  - The three source files present material in an unusual order: concurrency motivation first (pre_1), then architecture motivation (pre_2), then number systems (main deck). This order is preserved in the transcript as it represents the intended reading sequence.
- Suspected source errors:
  - pre_1 slide 2: "parallism" appears twice (should be "parallelism"). Corrected in transcript as this is clearly a typo.
  - pre_2 slide 16: "Jurrasic" (should be "Jurassic"). Corrected in transcript.
  - pre_2 slide 22: The MIPS instruction shown is `add $s3,$s3,1` but the opcode in the binary encoding is `001000` which is actually the `addi` (add immediate) opcode, not `add` (which is `000000` with funct `100000`). The assembly mnemonic and the binary encoding are inconsistent.
-->

# Week 2: Abstracting the Machine and MIPS32 Fundamentals

## Von Neumann Architecture and the Stored-Program Model

The foundational model for modern computers is the **von Neumann architecture**, described in John von Neumann's 1945
_First Draft of a Report on the EDVAC_ (Contract No. W-670-ORD-4926, between the United States Army Ordnance Department
and the University of Pennsylvania). The report identifies five main subdivisions of a computing system:

1. **Central Arithmetic part (CA)** — performs arithmetic operations.
2. **Central Control part (CC)** — sequences and coordinates operations.
3. **Memory (M)** — stores both instructions and data (the "stored program" concept). Various forms of memory are
   required, including an outside recording medium (R).
4. **Input (I)** — receives data from the outside world.
5. **Output (O)** — sends results to the outside world.

CC, CA, and M together form the associative part of the machine; I and O are the afferent and efferent parts mediating
contact with the outside.

### The Little Man Computer

The **Little Man Computer (LMC)**, created by Dr Stuart Madnick at MIT in 1965, provides a simple but still largely
valid analogy for a real computer. It models the key components: CPU, RAM (main memory), buses, input/output, assembly
language, and machine code. The LMC follows the stored-program von Neumann architecture.

The LMC simulator shows a CPU containing a **Program Counter**, **Instruction Register**, **Address Register**,
**Accumulator**, and **Arithmetic Unit**, connected to a grid of 100 RAM locations (addresses 00–99). A simple program
such as:

```
INP
STA 99
INP
ADD 99
OUT
HLT
```

is assembled into numeric opcodes (e.g. `901`, `399`, `901`, `199`, `902`) stored in consecutive RAM locations,
demonstrating the stored-program concept.

### CPU–Memory Interaction

The abstract interaction between CPU and memory involves:

- **CPU components:** Control Unit (driven by a clock), Program Counter (PC), Instruction Register (IR), Memory Data
  Register (MDR), Memory Address Register (MAR), and General Purpose Registers.
- **Memory:** stores machine code instructions and data.
- **Connections:** an Address Bus (carries the location to read/write), a Data Bus (carries the data being transferred),
  and control signals (Read, Write).

In the original IBM PC, the external bus consisted of physical wires carrying binary signals (0 V = logic 0, +5 V =
logic 1):

- **20 address lines** (A0–A19) — can address $2^{20} = 1\text{ MB}$ of locations.
- **8 data lines** (D0–D7) — transfer one byte at a time.
- **Control lines** — including $\overline{\text{MEMR}}$ (memory read), $\overline{\text{MEMW}}$ (memory write), CLK
  (clock), and GROUND.

## Bus Hierarchy in a Modern PC

A real PC has many different types of buses arranged in a hierarchy. The CPU connects via a **backside bus** to cache
memory and via an **external CPU bus** to main memory. A **Host/PCI bridge** connects the CPU bus to the **PCI bus**,
which in turn connects to peripherals such as USB ports, network interfaces, and disk controllers. Further bridges
connect to the **AGP bus** (for the video card) and the legacy **ISA bus** (for parallel and serial ports). Each bus
type has different bandwidth and latency characteristics.

### The Programmer's Abstract View

Despite this complexity, the programmer's abstract view of the architecture reduces to three components connected by
three buses:

| Component          | Role                                          |
| ------------------ | --------------------------------------------- |
| **CPU**            | Executes instructions                         |
| **Memory**         | Stores instructions and data                  |
| **I/O Interfaces** | Connect to peripherals (input/output devices) |

These are interconnected by a **Data Bus**, an **Address Bus**, and a **Control & Status Bus**.

## Why MIPS32

The Intel Core i3/i5/i7 processors used in PCs are complex due to decades of backwards compatibility. The module instead
studies the **MIPS processor**, which has a much more elegant design while embodying the same fundamental concepts that
apply to all processors.

### The R3000 Processor

The **R3000** (MIPS32) was released in 1988 with 115,000 transistors. It was used in high-end workstations such as the
Silicon Graphics SGI Personal IRIS 4D/20, which rendered 3D scenes for 1990s films like _Jurassic Park_ and _Terminator
2_. A radiation-hardened variant, the **Mongoose-V**, was used in the New Horizons space probe that flew to Pluto.

### MIPS32 in Embedded Systems

MIPS32 processors appear in modern embedded devices:

- **Imagination Creative Ci40** — a single-board computer (like a Raspberry Pi) built around the **cXT200 SoC**, which
  contains a dual-core MIPS interAptiv CPU at 550 MHz with 32 kB L1 data cache and 32 kB L1 instruction cache per core,
  a Coherency Manager with 512 kB L2 cache, an FPU, and an Ensigma C4500 RPU. The SoC integrates Wi-Fi, Bluetooth,
  Ethernet, USB, I2C, UART, SPI, and other peripherals on a single chip, connected via a SoC Fabric bus.
- **Mikroelectronics PIC32MX Clicker** — a microcontroller board (like an Arduino) based on the **PIC32MX534F064H**,
  which uses a 32-bit MIPS M4K Core running at 80 MHz / 105 DMIPS with a 5-stage pipeline and 32-bit ALU. It has 64 KB
  Flash (plus 12 K boot Flash), 16 KB RAM, 53 I/O pins, and peripherals including SPI, I2C, A/D converters, CAN, UARTs,
  and timers. Microcontrollers generally do not run operating systems — the processor directly executes application code
  ("programming to the bare metal").

### The ISA as an Abstraction Layer

The **Instruction Set Architecture (ISA)** hides the hardware from the software. A high-level statement like
`i = i + 1;` in C compiles to MIPS assembly (`add $s3,$s3,1`) which in turn corresponds to a 32-bit machine code word
(`001000 01011 01011 0000000000000001`). The ISA sits at the boundary between software and hardware in a layered
abstraction:

| Level | Name                                 | Examples                |
| ----- | ------------------------------------ | ----------------------- |
| 5     | Problem-Oriented Language            | Programs (C, Java)      |
| 4     | Assembly Language                    | MIPS assembly           |
| 3     | Operating System                     | Device drivers          |
| 2     | Instruction Set Architecture (ISA)   | Instructions, registers |
| 1     | Microprogramming (not all computers) | Datapaths, controllers  |
| 0.5   | Modular view (datapath)              | Adders, memories        |
| 0     | Digital Logic                        | AND gates, NOT gates    |

Below the digital logic level lie analog circuits (amplifiers, filters), devices (transistors, diodes), and ultimately
physics (electrons). The ISA level is entirely numeric, which motivates the study of computer arithmetic and memory
layout.

### The MARS Simulator

**MARS** (MIPS Assembler and Runtime Simulator) is a MIPS32 virtual machine used for writing and testing MIPS assembly
programs. It provides an editor, assembler, and execution environment with a register display panel showing all 32
registers and their values. An example Fibonacci program in MARS uses `.data` and `.text` sections with instructions
such as `la`, `lw`, `li`, `add`, `sw`, `addi`, and `bne`.

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

A **signed** $n$-bit integer (two's complement) can represent $-2^{n-1}, \ldots, 2^{n-1} - 1$. For example, an 8-bit
signed integer ranges from $-128$ to $127$.

An **unsigned** $n$-bit integer can represent $0, \ldots, 2^n - 1$. For example, an 8-bit unsigned integer ranges from
$0$ to $255$.

The same bit pattern can have different interpretations depending on whether it is treated as signed or unsigned. For
example, adding $11001011_2$ and $01010000_2$:

- **Signed:** $-53 + 80 = 27$. The result $00011011_2 = 27$ with a carry out of 1 (which is discarded in signed
  arithmetic).
- **Unsigned:** $203 + 80 = 283$. The 8-bit result is $00011011_2 = 27$ with a carry out of 1, indicating the true
  result ($283$) exceeds the 8-bit range.

### Overflow Detection in Two's Complement

- **(pos) + (neg)** and **(pos) − (pos)**: **cannot overflow** (the result is always representable).
- **(neg) + (neg)**: the result should be negative. Overflow occurs if the result is positive.
- **(pos) + (pos)**: the result should be positive. Overflow occurs if the result is negative.

Examples (8-bit):

- $-53 + (-48)$: $11001011_2 + 11010000_2 = 10011011_2 = -101_{10}$ with carry out 1. The result is negative as expected
  — **no overflow**.
- $75 + 80$: $01001011_2 + 01010000_2 = 10011011_2 = -101_{10}$ with carry out 0. The result is negative when it should
  be positive — **overflow**.

### Extending Numbers (Sign Extension and Zero Extension)

To extend an $n$-bit number to a wider representation:

- **Positive / unsigned values** — pad with zeros on the left (**zero extension**). E.g. $01001011_2$ (8-bit) becomes
  $00000000\,01001011_2$ (16-bit).
- **Unsigned negative-looking values** — also zero-extend. E.g. $11001011_2$ unsigned becomes $00000000\,11001011_2$.
- **Signed (two's complement) values** — replicate the sign bit on the left (**sign extension**). E.g.
  $11001011_2 = -53$ becomes $11111111\,11001011_2 = -2^{15} + 2^{14} + \cdots + 2^7 + 2^6 + 2^3 + 2^1 + 2^0 = -53$.

## Memory Organisation

### Memory Units

- A **binary digit (bit)** is a single 0 or 1.
- A **byte** is 8 bits.
- A **kilobyte (KB)** is $2^{10} = 1024$ bytes (not 1000, because powers of 2 are natural in binary systems).
- A **megabyte (MB)** is $2^{20} = 1024$ KB.
- Larger units follow the same pattern: gigabyte (GB), terabyte (TB), petabyte (PB), exabyte (EB), zettabyte (ZB),
  yottabyte (YB).

### Words

A **word** is the natural unit of data used by a given processor. For MIPS32, a word is 32 bits. The word size typically
determines the sizes of registers, memory addresses, instructions, and floating-point variables. MIPS16 and MIPS64
variants also exist.

The terminology for data sizes differs between MIPS32 and Intel x86:

| Size (bits) | MIPS32 Name | Intel x86 Name |
| ----------- | ----------- | -------------- |
| 8           | Byte        | Byte           |
| 16          | Half word   | Word           |
| 32          | Word        | Double word    |
| 64          | Double word | Quad word      |

### Memory as an Array

Memory can be viewed as an array of bytes (each address holds 8 bits, addresses increment by 1: 0, 1, 2, 3, 4, …) or as
an array of words (each address holds 32 bits, addresses increment by 4: 0x0, 0x4, 0x8, 0xC, 0x10, …).

### Byte Order (Endianness)

When storing a multi-byte value in memory, the **byte order** matters. Consider storing the word `0xBABACAFE` at address
8:

|                   | Offset 0 | Offset 1 | Offset 2 | Offset 3 |
| ----------------- | -------- | -------- | -------- | -------- |
| **Big Endian**    | BA       | BA       | CA       | FE       |
| **Little Endian** | FE       | CA       | BA       | BA       |

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

MIPS32 instructions are fixed-width **32-bit** binary words stored in memory. A sequence of such words constitutes a
machine-language program. For example, the machine code for a routine to compute and print the sum of the squares of
integers from 0 to 100 is a column of 32-bit binary values — completely opaque without knowledge of the instruction
encoding.

### Registers

The MIPS32 CPU has **32 general-purpose registers**: `$0` through `$31`, each 32 bits wide. Register `$0` is hardwired
to the value **0** and cannot be changed. Unlike x86 and other complex ISAs, MIPS arithmetic and logic instructions
operate **only on registers** — they cannot directly access memory. This simplifies the ISA but increases the number of
instructions needed for a given task.

For example, the operation `Mem[0x1001000] += Mem[0x1001004]` requires four MIPS instructions:

1. Load `Mem[0x1001000]` into a register.
2. Load `Mem[0x1001004]` into a register.
3. Add the two registers.
4. Store the result back to `Mem[0x1001000]`.

### MIPS as a RISC Processor

MIPS is a **Reduced Instruction Set Computer (RISC)**: it has simple, uniform instructions with a fixed 32-bit width.
Each instruction is divided into a **6-bit opcode** and **26 bits of arguments**. The Program Counter (PC) points to the
address of the current instruction in memory. Instructions and data coexist in the same address space (stored-program
model).

Example: the instruction at address `0x00400000` has the value `0x3c011001`. In binary:
`0b00111100000000010001000000000001`. The first 6 bits (`001111`) identify this as `lui` (Load Upper Immediate).

### The Address-Encoding Problem

In MIPS32, both addresses and instructions are 32 bits long, but 6 bits of each instruction are consumed by the opcode,
leaving only 26 bits for arguments. This means a single instruction cannot encode a full 32-bit address or immediate
value. Solutions include splitting the value across two instructions (e.g. `lui` to load the upper 16 bits, then `ori`
to set the lower 16 bits) and using relative addressing for branches.

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
| ----- | -------- | ---- | ---- | ---- | ------- | ------- |
| Bits  | 6        | 5    | 5    | 5    | 5       | 6       |

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

Shift instructions are R-type with `rs = 0`. The operation is `R[rd] = shift(R[rt])`, with the shift amount in the
`shamt` field.

**Example — `srl $11, $7, 4`:**

```
srl $11, $7, 4
  000000  00000  00111  01011  00100  000010
= 0x00075842
```

Shift operations and their arithmetic meaning:

- **Left shift** by $k$: equivalent to multiplication by $2^k$. E.g. $100_{10} \ll 4 = 1600$;
  $1100100_2 \ll 4 = 11001000000_2$.
- **Logical right shift** (`>>>` or `srl`): shifts right and fills with zeros. E.g.
  $100_{10} \gg 4 = \lfloor 100 / 16 \rfloor = 6$; $1100100_2 \gg 4 = 110_2$. For the 32-bit representation of $-100$
  (`0xffffff9c`): `0xffffff9c >>> 4 = 0x0ffffff9 = 268435449`.
- **Arithmetic right shift** (`>>` or `sra`): shifts right and replicates the sign bit. E.g.
  $-100_{10} \gg 4 = \lfloor -100 / 16 \rfloor = -7$; `0xffffff9c >> 4 = 0xffffff9c` shifted with sign extension.

### Bitwise Operations

Bitwise operations apply independently to each bit position. MIPS32 provides AND, OR, XOR, and NOR:

| A   | B   | AND | OR  | XOR | NOR |
| --- | --- | --- | --- | --- | --- |
| 0   | 0   | 0   | 0   | 0   | 1   |
| 0   | 1   | 0   | 1   | 1   | 0   |
| 1   | 0   | 0   | 1   | 1   | 0   |
| 1   | 1   | 1   | 1   | 0   | 0   |

**Example — `and $9, $4, $5`:**

```
$4 = 11010000101011010001111110100000
$5 = 00101111010100001010000010001111
$9 = 00000000000000000000000010000000
```

### Pseudo Instructions

Pseudo instructions are **not real MIPS32 instructions** — they have no opcodes and are not recognised by the CPU. The
assembler translates them into one or more real instructions.

**`move $8, $9`** — copies the value of `$9` into `$8`. Translated to `add $8, $9, $0` (adding zero via `$0`).

**`not $8, $9`** (bitwise NOT, i.e. `$8 ← ~$9`) — several candidate implementations:

- `sub $8, $0, $9` — **wrong**: this computes $-$9$ (arithmetic negation), not $\sim$9$ (bitwise complement). E.g.
  $\sim 0 = -1$ but $-0 = 0$.
- `nor $8, $9, $9` — **correct**: since `$9 | $9 = $9`, `NOR($9, $9) = ~$9`.
- `nand $8, $9, $9` — **wrong**: there is no `nand` instruction in MIPS32.
- `nor $9, $0, $8` — **wrong**: the parameter order is incorrect (writes to `$9` instead of `$8`, and uses `$8` as
  source instead of `$9`).
- `nor $8, $9, $0` — **correct** (MARS's implementation): since `$9 | 0 = $9`, `NOR($9, $0) = ~$9`.

### From High-Level Language to Machine Code

The translation from a high-level expression to assembly is **not unique** — different compilers (or humans) may produce
different but equivalent instruction sequences. However, the translation from assembly to machine code **is unique**
(each mnemonic maps to exactly one binary encoding). **Disassembly** reverses machine code back to assembly.

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

| Instruction            | Mnemonic | op  | funct (hex) | Description                      |
| ---------------------- | -------- | --- | ----------- | -------------------------------- |
| Add                    | `add`    | 0   | 0x20        | Addition with signed overflow    |
| Subtract               | `sub`    | 0   | 0x22        | Subtraction with signed overflow |
| And                    | `and`    | 0   | 0x24        | Logical AND                      |
| Or                     | `or`     | 0   | 0x25        | Logical OR                       |
| Xor                    | `xor`    | 0   | 0x26        | Logical XOR                      |
| Nor                    | `nor`    | 0   | 0x27        | Logical NOR                      |
| Set Less Than          | `slt`    | 0   | 0x2A        | Set on less than (signed)        |
| Set Less Than Unsigned | `sltu`   | 0   | 0x2B        | Set on less than (unsigned)      |
| Shift Right Logical    | `srl`    | 0   | 0x02        | Logical right shift              |
| Shift Right Arithmetic | `sra`    | 0   | 0x03        | Arithmetic right shift           |
| Shift Left Logical     | `sll`    | 0   | 0x00        | Logical left shift               |

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

# MIPS32 Processor — ISA and Instructions

Background reading: Patterson & Hennessey, Chapter 2 (especially Section 2.3). Chapter 2 is best read after covering
high-level language compilation, as it synthesises many topics together.

## Roadmap for the MIPS Sequence

The MIPS32 processor architecture is built up over several weeks in this order:

1. **Instruction Set Architecture (ISA)** — hardware instructions and numeric register references.
2. **Assembly language** — pseudo-instructions, named registers, symbolic labels.
3. **High-level language compilation** — how high-level languages compile to assembly; use of the hardware stack for
   function calling.
4. **The gcc toolchain for MIPS** — compiler, assembler, linker, loader; real MIPS assembly code.

This week covers step 1, building on the binary number concepts from the previous lecture (signed/unsigned,
big/little-endian, sign/zero-extension).

## MIPS32 in the Real World

The R3000 MIPS processor was released in 1988 with 115,000 transistors. It powered high-end workstations such as the
Silicon Graphics SGI Personal IRIS 4D/20, used to render 3D scenes in films like _Jurassic Park_ and _Terminator 2_. A
radiation-hardened variant (Mongoose-V) flew aboard the New Horizons space probe to Pluto. The MIPS32 architecture also
appears in microcontrollers (e.g. the PIC32-based Mikroelectronics "Clicker", analogous to an Arduino) and single-board
computers (e.g. the Imagination Creative Ci40, analogous to a Raspberry Pi, featuring a cXT200 SoC with 2× MIPS
interAptiv CPUs at 550 MHz and 512 KB L2 cache).

## Abstract View of a Computer

A processor's (or programmer's) abstract view of a computer consists of three components connected by three buses:

| Component          | Role                          |
| ------------------ | ----------------------------- |
| **CPU**            | Executes instructions         |
| **Memory**         | Stores instructions and data  |
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
- **32 General-Purpose Registers** — `$0` through `$31`, each storing a 32-bit value. Register `$0` is hardwired to
  zero; writes to it are ignored.

Memory is **byte-addressable** with 32-bit addresses (range `0x00000000`–`0xFFFFFFFF`). Each address holds one byte. The
address bus is 32 bits wide (sufficient to address the full 4 GB space). The data bus is also 32 bits wide — this
matches the register width and allows a full word to be transferred in one bus cycle (an 8-bit data bus would require
four cycles per word).

The CPU communicates with memory via read and write signals on the control bus.

## Fetch/Execute Cycle

Every instruction executes through a five-step cycle:

1. The processor places the PC value onto the **address bus**.
2. The processor asserts the **read signal**.
3. Memory returns the **32-bit instruction** at that address (4 consecutive bytes).
4. The processor **executes** the instruction.
5. The PC is incremented to **PC + 4** (advancing to the next instruction).

**Example:** With PC = `0x00400000`, memory bytes at that address are `0x00`, `0x22`, `0x40`, `0x20`, forming the 32-bit
word `0x00224020`. This decodes to `add $8, $1, $2`. Execution reads `$1` = `0x0A0F1569` and `$2` = `0x00001003`, the
ALU computes `0x0A0F1569 + 0x00001003 = 0x0A0F256C`, and the result is written to `$8`.

## RISC Load/Store Architecture

MIPS is a RISC-based **load/store architecture**: only `load` and `store` instructions access memory; **all other
instructions operate on registers only**. Adding two values stored in memory and writing the result back therefore
requires four instructions:

1. Load value 1 from memory into a register.
2. Load value 2 from memory into a register.
3. Add the two register values, placing the result in a register.
4. Store the result register back to memory.

## Instruction Types and Encoding

All MIPS32 instructions are exactly **32 bits** (one word). The top 6 bits are the **opcode**; the remaining 26 bits
encode the arguments. There are three instruction formats:

- **R-type** (register) — operations between registers. Examples: `add $8, $1, $2`; `sub $12, $6, $3`.
- **I-type** (immediate) — operations involving a fixed numeric value. Examples: `addi $15, $15, -1`;
  `beq $10, $14, 0x00000002`.
- **J-type** (jump) — unconditional jumps. Examples: `j 0x00400050`; `jal 0x0040007c`.

## I-Type (Immediate) Instructions

The I-type format is:

| opcode | rs     | rt     | Immediate |
| ------ | ------ | ------ | --------- |
| 6 bits | 5 bits | 5 bits | 16 bits   |

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

where $\text{SignExtImm} = \{16\{\text{immediate}[15]\},\ \text{immediate}\}$ (i.e. the immediate is still
**sign-extended**, despite the name "unsigned").

Despite its name, `addiu` is used to add constants to signed integers when overflow exceptions are not desired. MIPS has
**no subtract-immediate instruction**; negative numbers are handled via sign extension of the immediate field. The
"unsigned" designation means only that arithmetic overflow does not trigger an exception.

**Exercise:** What is the value of `$8` after executing:

```mips
addiu $0, $0, 5      # no effect — $0 is hardwired to 0
addiu $8, $0, 5      # $8 = 0 + 5 = 5
addiu $8, $8, 0xFFFF # depends on assembler interpretation
```

The correct answer is **4**. However, the result depends on how the assembler interprets the literal `0xFFFF`:

- The MARS assembler treats `0xFFFF` as the unsigned value 65535 and expands the instruction into three instructions
  (`lui`, `ori`, `addu`) that add 65535 to `$8`, giving `$8` = 65540.
- Writing `addiu $8, $8, -1` instead causes MARS to emit a single `addiu` instruction with the immediate field set to
  `0xffff` (the sign-extended representation of −1), giving `$8` = 4.

The hardware instruction always sign-extends the 16-bit immediate. The discrepancy arises from the assembler's handling
of out-of-range or ambiguous literals.

### Memory Addressing

Memory addresses are 32 bits long (matching register width). MIPS uses a single addressing mode: **base +
displacement**.

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

- `A[8] = y` → `sw $9, 0x20($8)` (offset 0x20 = 32 = 8 × 4 bytes per word). Encoding: `0xad090020` =
  `101011 01000 01001 0000000000100000`.
- `z = A[10]` → `lw $10, 0x28($8)` (offset 0x28 = 40 = 10 × 4). Encoding: `0x8d0a0028` =
  `100011 01000 01010 0000000000101000`.

**Byte and half-word granularities:**

- `lb`/`sb` — load/store byte.
- `lh`/`sh` — load/store half-word (must be **half-word aligned**, i.e. address divisible by 2).
- These are **sign-extended** when loaded into a register.
- Unsigned (zero-extended) variants: `lbu`, `lhu`, `sbu`, `shu`.

### Loading Large Constants

Since the immediate field is only 16 bits, loading a full 32-bit constant requires two instructions. The
pseudo-instruction `li` (load immediate) handles this automatically.

Example: `li $8, 7654321` where $7654321_{10} = \texttt{0x74cbb1}$.

The assembler expands this to:

```mips
lui $1, 0x00000074    # Load upper immediate: $1 = 0x00740000
ori $8, $1, 0x0000cbb1 # Or immediate: $8 = 0x00740000 | 0x0000cbb1 = 0x0074cbb1
```

**Load Upper Immediate (`lui`)** sets the most significant 16 bits of the destination register and **zeros** the lower
16 bits. **Or Immediate (`ori`)** performs a bitwise OR with the immediate value, filling in the lower 16 bits.

### Branching Instructions

Branch instructions are essential for implementing loops and conditionals. They use **PC-relative addressing**.

**Branch on Not Equal (`bne`)** — opcode `5`₁₆, I-type.

$$\text{if}(R[rs] \neq R[rt])\ \text{then}\ PC = PC + 4 + \text{BranchAddr}$$

**Branch on Equal (`beq`)** — opcode `4`₁₆, I-type.

$$\text{if}(R[rs] = R[rt])\ \text{then}\ PC = PC + 4 + \text{BranchAddr}$$

The branch address is computed as:

$$\text{BranchAddr} = \{14\{\text{immediate}[15]\},\ \text{immediate},\ 2'b0\}$$

That is, the 16-bit immediate is sign-extended to 30 bits and then left-shifted by 2 (appending two zero bits), yielding
a byte offset relative to PC + 4. This allows branches to reach ±128 KB from the current instruction.

**Example:** `bne $9, $0, -3` encodes as `0x1520fffd`:

```
000101  01001  00000  1111111111111101
opcode   rs     rt     immediate (-3)
```

With PC at `0x0040001c`, the branch target is `PC + 4 + (-3 × 4) = 0x00400020 - 12 = 0x00400014`.

<!-- suspected-source-error: The slide shows PC at 0x0040001c and the branch target calculation with immediate=-3 should give PC+4+BranchAddr = 0x00400020 + (-3<<2) = 0x00400020 - 12 = 0x00400014, which would jump back to 0x00400014. The memory layout shown on the slide (0x00400010 containing 0x3c011001) is consistent with jumping back into the loop body. The slide's visual arrows suggest the target is 0x00400010, but the arithmetic gives 0x00400014. Transcribed the encoding and formula faithfully; the exact target depends on interpretation of the memory layout shown. -->

**Branch on comparison with zero:** `bgez` (≥ 0), `bgtz` (> 0), `blez` (≤ 0), `bltz` (< 0). Trivia: `bgez` and `bltz`
both have opcode = 1; they are distinguished by the `rt` field.

**Pseudo-instructions for general comparisons:** `bgt` (branch if greater than), `bge`, `ble`, `blt`. These expand into
a `slt` (set less than) followed by a `bne` or `beq`. For example, `bgt $10, $11, loop` expands to:

```mips
slt $1, $11, $10       # $1 = ($11 < $10) ? 1 : 0
bne $1, $0, loop       # branch if $1 ≠ 0
```

### Loop Efficiency: Counting Down vs. Up

Counting down to zero is more efficient in MIPS because `bgtz` can compare directly against zero, eliminating the need
for a separate comparison value and `slt` instruction.

**Counting up** (`for (int i=0; i<10; ++i)`):

| Basic                     | Source               |
| ------------------------- | -------------------- |
| `addiu $13,$0,0x00000000` | `li $13, 0`          |
| `addiu $14,$0,0x0000000a` | `li $14, 10`         |
| `jal 0x00400024`          | `jal func`           |
| `addi $13,$13,0x00000001` | `addi $13, $13, 1`   |
| `slt $1,$13,$14`          | `blt $13, $14, loop` |
| `bne $1,$0,0xfffffffc`    |                      |

**Counting down** (`for (int i=10; i>0; --i)`):

| Basic                     | Source              |
| ------------------------- | ------------------- |
| `addiu $13,$0,0x0000000a` | `li $13, 10`        |
| `jal 0x00400024`          | `jal func`          |
| `addi $13,$13,0xffffffff` | `addi $13, $13, -1` |
| `bgtz $13,0xfffffffd`     | `bgtz $13, loop`    |

The count-down version uses 4 instructions per iteration versus 6 for count-up, because `bgtz` directly tests against
zero without needing a separate register holding the limit or an `slt` instruction.

## Combining Instructions: Worked Examples

### Bit Field Extraction

**Task:** Given a 32-bit instruction stored in `$4`, extract the `rs` field (bits 25–21).

Example: `$4` = `10101101111010001000000000000000` (the instruction `sw $8, 0x8000($15)`). The `rs` field is `01111` (=
15, i.e. `$15`).

**Solution using mask and shift:**

```mips
lui $5, 0x03e0     # $5 = 00000011111000000000000000000000 (mask for bits 25-21)
and $6, $4, $5     # $6 = 00000001111000000000000000000000 (isolated rs bits)
srl $6, $6, 21     # $6 = 00000000000000000000000000001111 (= 15)
```

The mask `0x03e00000` has ones in exactly bit positions 25–21. The `and` isolates those bits, and the right shift by 21
moves them to the least significant position.

### Set-and-Branch Pattern

To compare a register against a fixed number (e.g. is `$4 < 10`?), use a **set comparison** instruction followed by a
branch:

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

This works for small values but **fails for large unsigned values** whose sum exceeds 2³² − 1. For example, with `$8` =
3,501,006,752 and `$9` = 794,337,423, the sum overflows 32 bits, and the subsequent right shift produces an incorrect
result.

**Version 2 (overflow-safe):** Exploits the bitwise identity:

$$x + y = 2 \cdot (x \mathbin{\&} y) + (x \oplus y)$$

Therefore:

$$\frac{x + y}{2} = (x \mathbin{\&} y) + \frac{x \oplus y}{2}$$

Neither `(x & y)` nor `(x ^ y) >> 1` can overflow, and their sum also cannot overflow (since each is at most half the
maximum value).

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

# High-Level Language Constructs in MIPS Assembly

Previous weeks covered all key R-format and I-format MIPS instructions at a low level: their representation as 32-bit
machine code words, and how the machine executes them by manipulating bits and bytes in registers and memory. This week
examines how high-level language constructs (arrays, conditionals, loops, functions) are compiled into MIPS assembly,
and introduces the final instruction format — J-type — used for jumps and function calling.

Background reading: Patterson & Hennessy, Chapter 2.

## MIPS Register Usage Convention

MIPS has 32 registers, each with a conventional name and role:

| Name        | Register Number | Usage                                                                                        |
| ----------- | --------------- | -------------------------------------------------------------------------------------------- |
| `$zero`     | 0               | The constant value 0                                                                         |
| `$at`       | 1               | Assembler temporary (reserved for pseudo-instructions)                                       |
| `$v0`–`$v1` | 2–3             | Function return values                                                                       |
| `$a0`–`$a3` | 4–7             | Function arguments                                                                           |
| `$t0`–`$t7` | 8–15            | Temporaries (caller-saved; need **not** be preserved across function calls)                  |
| `$s0`–`$s7` | 16–23           | Saved variables (callee-saved; the function **must** save and restore these if it uses them) |
| `$t8`–`$t9` | 24–25           | More temporaries (caller-saved)                                                              |
| `$k0`–`$k1` | 26–27           | Reserved for operating system kernel                                                         |
| `$gp`       | 28              | Global pointer (points into the global static data segment, set to `0x10008000`)             |
| `$sp`       | 29              | Stack pointer                                                                                |
| `$fp`       | 30              | Frame pointer                                                                                |
| `$ra`       | 31              | Function return address                                                                      |

`$gp`, `$sp`, `$fp`, and `$ra` must also be saved and restored if changed by a function.

## Arrays in MIPS

Array elements are accessed using a base address register and byte offsets. Each `int` (word) is 4 bytes, so `array[i]`
is at offset `4*i` from the base.

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

The `j` (jump) instruction has opcode `000010` ($2_{\text{hex}}$). Since addresses are 32 bits but the field is only 26
bits, the full target address is constructed as:

$$\text{NewPC} = (\text{PC}+4)[31{:}28] \;\|\; \text{JA} \;\|\; 00$$

That is, the 26-bit field is shifted left by 2 (word-aligned instructions are always multiples of 4), and the top 4 bits
are taken from the current PC+4. The jump address (JA) stored in the instruction is therefore:

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

| Address      | Code         | Basic                    |
| ------------ | ------------ | ------------------------ |
| `0x00400000` | `0x2408000a` | `addiu $8,$0,0x0000000a` |
| `0x00400004` | `0x08100004` | `j 0x00400010`           |
| `0x00400008` | `0x21080001` | `addi $8,$8,0x00000001`  |
| `0x0040000c` | `0x21080001` | `addi $8,$8,0x00000001`  |

Because the top 4 bits of the PC are copied, a J-type jump can only reach addresses within the same 256 MB region (same
upper 4 bits).

### Jump Register (`jr`) and Jump-and-Link Register (`jalr`)

To jump to an address with different most-significant bits, or one known only at runtime, use the R-type instruction
`jr`:

**Jump Register:** `jr rs` — sets `PC = R[rs]`. Opcode/funct = `0/08` hex. It is an R-type instruction.

Example: `jr $ra` (return from function). Encoding:

```
000000 11111 00000 00000 00000 001000  =  0x03e00008
```

`$ra` is register 31.

There is also `jalr $rs` which performs `$ra ← PC + 4; PC ← R[rs]` — a jump-and-link using a register operand, useful
when the target address is computed at runtime.

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

The pattern is: branch on the _negated_ condition to the else label, fall through to the if-body, then jump past the
else-body.

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

A `for` loop compiles to essentially the same structure as a `while` loop: initialisation, then a test-at-top loop with
a backward jump.

## Functions in MIPS

Functions are more involved than other high-level constructs because they raise several questions: where do input
arguments go? Where are local variables stored? Where does the return value go? How does the caller resume after the
function returns? How do functions avoid overwriting each other's registers?

### Function Call Mechanism: `jal` and `jr`

`jal target` (jump and link) performs two actions simultaneously:

1. `$ra ← PC + 4` — saves the return address (the instruction after the `jal`).
2. `PC ← target` — jumps to the function.

The function returns with `jr $ra`, which sets `PC ← $ra`.

Example flow: the main program at address `0x0041AB3C` executes `jal 0x00445678`. This stores `0x0041AB40` into `$ra`
and jumps to `0x00445678`. The function body executes, and its final instruction `jr $ra` sets `PC ← 0x0041AB40`,
resuming the caller.

### Register Conventions for Functions

**Arguments and return values:**

| Register | Number | Usage                                                   |
| -------- | ------ | ------------------------------------------------------- |
| `$v0`    | $2     | Result value                                            |
| `$v1`    | $3     | Result value (for 64-bit results or two 32-bit results) |
| `$a0`    | $4     | Argument 1                                              |
| `$a1`    | $5     | Argument 2                                              |
| `$a2`    | $6     | Argument 3                                              |
| `$a3`    | $7     | Argument 4                                              |
| `$ra`    | $31    | Return address                                          |

**Temporary vs saved registers:**

| Registers   | Numbers | Convention                                                          |
| ----------- | ------- | ------------------------------------------------------------------- |
| `$t0`–`$t7` | $8–$15  | Temporary; do **not** need to be preserved across function calls    |
| `$s0`–`$s7` | $16–$23 | Saved; the function **must** save and restore these if it uses them |
| `$t8`–`$t9` | $24–$25 | More temporaries                                                    |

Saved registers (`$s0`–`$s7`) are used for values that must survive across function calls. The caller can rely on them
being unchanged after a `jal`. Temporary registers (`$t0`–`$t9`) may be freely clobbered by any called function.

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

Benefits of writing functions in assembly: code reuse and abstraction, cleaner and more compact programs, and the
ability to create library routines (e.g. `sqrt`, `sin`).

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

**This program has a bug.** When `main` calls `my_program` via `jal`, it sets `$ra` to the address after that `jal`.
Then `my_program` calls `abs_diff` via another `jal`, which **overwrites** `$ra` with the address after the second
`jal`. When `abs_diff` returns, `$ra` now points back into `my_program` (not into `main`), so `jr $ra` at the end of
`my_program` jumps back to itself, creating an **infinite loop**.

Additionally, `$t1` is a temporary register and may be clobbered by `abs_diff`, so `sw $v0, 8($t1)` after the call may
use a stale value. The corrected version reloads `$t1` after the call.

### Caller-Save vs Callee-Save

Functions must not interfere with each other's registers. Two strategies exist:

- **Caller-save:** the _caller_ saves any register values it needs before making the call, and restores them afterwards.
  This is the convention for `$t` registers — the caller is responsible.
- **Callee-save:** the _callee_ saves any registers it intends to modify at the start of the function and restores them
  before returning. This is the convention for `$s` registers — the callee is responsible.

Registers cannot simply be saved into other registers (those might also be in use). They must be saved to **memory** —
but not to a fixed memory location, because nested function calls would overwrite previous saves. The solution is the
**stack**.

## The Stack

### Memory Layout

The MIPS address space is divided into segments (from high to low addresses):

| Segment             | Address Range               |
| ------------------- | --------------------------- |
| Stack               | `0x7ffffffc` downward       |
| Dynamic data (heap) | `0x10010000` upward         |
| Static data         | `0x10000000` – `0x1000ffff` |
| Text (code)         | `0x00400000` upward         |
| Reserved            | `0x00000000` – `0x003fffff` |

The stack grows **downward** (toward lower addresses). The stack pointer register `$sp` always points to the top (lowest
used address) of the stack. The dynamic data (heap) grows upward; the two grow toward each other.

### Stack Frames (Prologue and Epilogue)

Each function call creates a **stack frame** containing the function's saved registers, arguments, and local variables.
A typical prologue and epilogue for a one-argument function `int f(int y)` that uses `$s0` and calls another function
`g`:

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

Within the function body, `$s0` and `y` can be used freely. The argument `y` is accessed via `-8($fp)` (not `$a0`, which
may be overwritten by a nested call). Local variables (e.g. `z`) are stored below the saved registers. If the function
calls `g(2y+z)`, `g` creates its own frame below, and `$fp` and `$sp` shift accordingly. When `g` returns, `$fp` and
`$sp` are restored.

**Epilogue** (before return):

```mips
lw    $ra, 16($sp)        # restore return address
lw    $fp, 12($sp)        # restore old frame pointer
lw    $s0,  4($sp)        # restore $s0
addiu $sp, $sp, 20        # deallocate stack frame
jr    $ra                 # return
```

The frame pointer `$fp` provides a stable reference into the frame even as `$sp` changes (e.g. when pushing additional
data for a nested call). Arguments are accessed relative to `$fp` rather than `$sp`.

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

The key fix: `$ra` is saved to the stack before the nested `jal abs_diff` and restored afterwards, so `jr $ra` at the
end correctly returns to `main`. The `$t1` register is also reloaded after the call since temporaries are not preserved.

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

# Week 5 — GCC Toolchain, System Calls, and Basic Data Types

Recommended reading: Patterson & Hennessy Section 2.12, Appendix A.7, Appendix B. Acknowledgements: Harris & Harris book
for C-code examples and figures.

## The GCC MIPS Toolchain

### Compilation Pipeline

The gcc toolchain transforms high-level C code into an executable through a sequence of stages. Each stage produces an
intermediate file that resides on disk:

1. **Compiler** — translates high-level C source (`test.c`) into assembly language (`test.s`).
2. **Assembler** — converts assembly into an object file (`test.o`) containing machine code.
3. **Linker** — combines the object file with other object files and library files to produce an executable (`a.out`).
4. **Loader** — the OS calls a loader program to load the executable from disk into main memory (RAM) following the MIPS
   memory map, then execution begins.

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

| Section                    | Field     | Value           |
| -------------------------- | --------- | --------------- |
| **Executable file header** | Text Size | 0x34 (52 bytes) |
|                            | Data Size | 0xC (12 bytes)  |

**Text segment** (starting at address 0x00400000):

| Address    | Machine Code | Instruction           |
| ---------- | ------------ | --------------------- |
| 0x00400000 | 0x23BDFFFC   | `addi $sp, $sp, -4`   |
| 0x00400004 | 0xAFBF0000   | `sw $ra, 0($sp)`      |
| 0x00400008 | 0x20040002   | `addi $a0, $0, 2`     |
| 0x0040000C | 0xAF848000   | `sw $a0, 0x8000($gp)` |
| 0x00400010 | 0x20050003   | `addi $a1, $0, 3`     |
| 0x00400014 | 0xAF858004   | `sw $a1, 0x8004($gp)` |
| 0x00400018 | 0x0C10000B   | `jal 0x0040002C`      |
| 0x0040001C | 0xAF828008   | `sw $v0, 0x8008($gp)` |
| 0x00400020 | 0x8FBF0000   | `lw $ra, 0($sp)`      |
| 0x00400024 | 0x23BD0004   | `addi $sp, $sp, 4`    |
| 0x00400028 | 0x03E00008   | `jr $ra`              |
| 0x0040002C | 0x00851020   | `add $v0, $a0, $a1`   |
| 0x00400030 | 0x03E00008   | `jr $ra`              |

**Data segment:**

| Address    | Data |
| ---------- | ---- |
| 0x10000000 | f    |
| 0x10000004 | g    |
| 0x10000008 | y    |

### MIPS Memory Map and the Loader

The OS loader places the executable into RAM following the MIPS memory map:

| Address Range | Region              | Description                                                       |
| ------------- | ------------------- | ----------------------------------------------------------------- |
| 0x00000000    | Reserved            | OS-reserved memory                                                |
| 0x00400000    | Text                | Program instructions (PC starts here)                             |
| 0x10000000    | Static Data         | Global variables (f, g, y); `$gp` = 0x10008000                    |
| 0x10010000    | Heap (Dynamic Data) | Memory allocated with `malloc`/`calloc`; grows upward             |
| 0x7FFFFFFC    | Stack               | Local variables, stack frames; `$sp` = 0x7FFFFFFC; grows downward |

An "image file" is a direct copy of the values making up this memory map layout for a particular process.

### Real GCC Output: `gcc -S` on the Ci40

Compiling the same C program on the Ci40 with `gcc -S test.c` produces a `test.s` file that is considerably more complex
than the textbook version. Key differences include position-independent code (PIC) directives, use of the global pointer
(`$gp`), frame pointer (`$fp`), and explicit `nop` instructions for pipeline hazards.

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

An alternative approach is to compile with debug information (`gcc -g test.c`) and then disassemble with
`objdump -S a.out`, which interleaves the original C source with the generated assembly. In the disassembly output,
register `$s8` is used as a synonym for `$fp` (frame pointer), and registers are generally referred to by name without
the `$` prefix.

The disassembly shows the same structure as the `gcc -S` output but with resolved addresses and machine code. Key
observations:

- `main` is located at address 0x00400690.
- `sum` is located at address 0x00400728.
- The global pointer setup uses `lui gp,0x42` / `addiu gp,gp,-30672` to compute the `$gp` value.
- Global variables are accessed via offsets from `$gp` (e.g., `lw v0,-32744(gp)` for `f`).
- The executable format is `elf32-tradlittlemips` (little-endian MIPS ELF).

The resulting assembly is more complex than the Harris & Harris textbook suggests, but the overall key structure is the
same: stack frame setup, global variable access, function call via `jal`, result storage, and stack frame teardown.

**Optional reference:** _See MIPS Run: Linux_ by Dominic Sweetman (Second Edition, Morgan Kaufmann) — covers the full
MIPS32 assembly language including assembly directives, and how the MIPS32 processor works under Linux. Available from
the UCL library.

## MIPS Coprocessors and the Memory Map

### The MIPS R2000 Coprocessor Architecture

The MIPS architecture includes multiple coprocessors alongside the main CPU:

- **CPU (main processor):** 32 general-purpose registers ($0–$31), an arithmetic unit, a multiply/divide unit (with Hi
  and Lo registers), and the program counter (PC).
- **Coprocessor 0 (traps and memory):** handles exceptions and memory management. Contains special registers:
  - **BadVAddr** — the address that caused an address exception
  - **Cause** — the exception code
  - **Status** — processor status bits
  - **EPC** (Exception Program Counter) — the PC value at the time of the exception
- **Coprocessor 1 (FPU):** the floating-point unit, with its own 32 registers ($f0–$f31) and arithmetic unit.

### Memory Map with Kernel Space

The full MIPS memory map includes a kernel space region above user space:

| Address               | Region                                      |
| --------------------- | ------------------------------------------- |
| 0xFFFFFFFC            | Top of kernel space                         |
| 0x80000000–0xFFFFFFFC | Kernel space (privileged)                   |
| 0x7FFFFFFC            | Stack (`$sp`), grows downward               |
| 0x10010000            | Dynamic data (heap), grows upward           |
| 0x10000000            | Static data (`$gp` points into this region) |
| 0x00400000            | Text segment (instructions)                 |
| 0x00000000            | Reserved                                    |

Variables are allocated in different memory regions based on their scope:

- **Local variables** within a function → stored in the stack frame of that function.
- **Dynamically allocated memory** (`malloc`/`calloc`) → stored in the dynamic data (heap) segment.
- **Global variables** (outside any function) → stored in the static data segment.

## Exception Handling

### The Kernel and Exceptions

The kernel handles all exceptions. When an exception occurs, the PC changes to an address in kernel space. The kernel
can store the processor state to return to the program if needed, and can run privileged instructions not allowed in
user space (e.g., accessing kernel memory addresses or halting the machine).

### Exception Mechanism

When an exception occurs:

1. The **exception code** is loaded into coprocessor 0's `cause` register.
2. The current **PC value** is stored in coprocessor 0's `epc` register.
3. The **PC is set to 0x80000080**, the fixed location of the exception handler code.
4. Registers `$k0` and `$k1` may be used as scratch registers by the handler without being saved/restored.

### Exception Types

| Number | Name | Cause                                               |
| ------ | ---- | --------------------------------------------------- |
| 0      | Int  | Interrupt (hardware)                                |
| 4      | AdEL | Address error exception (load or instruction fetch) |
| 5      | AdES | Address error exception (store)                     |
| 6      | IBE  | Bus error on instruction fetch                      |
| 7      | DBE  | Bus error on data load or store                     |
| 8      | Sys  | Syscall exception                                   |
| 9      | Bp   | Breakpoint exception                                |
| 10     | RI   | Reserved instruction exception                      |
| 11     | CpU  | Coprocessor unimplemented                           |
| 12     | Ov   | Arithmetic overflow exception                       |
| 13     | Tr   | Trap                                                |
| 15     | FPE  | Floating point exception                            |

## System Calls

### The `syscall` Instruction

`syscall` is a native CPU instruction with machine code encoding `0x0000000c`. Technically it is an R-type instruction
where opcode, rs, rt, and rd are all zero. It triggers exception code 8 (Sys), transferring control to the kernel to
perform an operating system service.

The system call number is placed in `$v0` before executing `syscall`. Input parameters follow the standard convention of
using `$a0`–`$a3`.

### MIPS/MARS System Call Table

| Service      | $v0 | Arguments                      | Results          |
| ------------ | --- | ------------------------------ | ---------------- |
| print_int    | 1   | `$a0` = integer                |                  |
| print_float  | 2   | `$f12` = float                 |                  |
| print_double | 3   | `$f12` = double                |                  |
| print_string | 4   | `$a0` = string address         |                  |
| read_int     | 5   |                                | integer in `$v0` |
| read_float   | 6   |                                | float in `$f0`   |
| read_double  | 7   |                                | double in `$f0`  |
| read_string  | 8   | `$a0` = buffer, `$a1` = length |                  |
| exit         | 10  |                                |                  |
| read_char    | 12  |                                | char in `$v0`    |

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

In the 1950s, computers used varying "byte" lengths (6, 7, or 8 bits) depending on the character set. In 1963, the
American Standard Association proposed the 7-bit **American Standard Code for Information Interchange (ASCII)**
encoding, defining 128 characters. IBM System/360 (1964) standardised the 8-bit byte, as character processing became
more important than digit processing.

The printable ASCII characters occupy codes 32–127. Codes 0–31 are **control (non-printable) characters** such as NUL
(0), HT/horizontal tab (9), LF/line feed (10), CR/carriage return (13), and ESC (27).

Useful bit-manipulation tricks for ASCII letters:

- **Force uppercase:** `x &= ~0b100000` (clears bit 5)
- **Toggle case:** `x ^= 0b100000` (flips bit 5)
- **Get numeric value of a digit character:** `y - '0'` = `y - 48`

### Extended ASCII and ISO Variants

Standard ASCII has no support for many common characters (e.g., the £ sign). The UK ISO 646 variant (1967) replaced `#`
with `£`. **Extended ASCII** uses 8 bits to encode additional characters within a single byte, with different code pages
for different regions (e.g., ISO Latin-1 for Western European languages, ISO Latin-2 for Central European languages).

### Unicode

Unicode is a global solution using up to 4 bytes per character (code points 0–0x10FFFF), currently including
approximately 145,000 characters covering all world languages, symbols (including emoji), and maintaining backward
compatibility with Extended ASCII Latin-1.

Unicode has multiple encodings:

- **UTF-32** — the simplest: exactly 32 bits per character. Raises endianness issues (resolved by a byte-order mark
  character preceding the text).
- **UTF-8** — a variable-length encoding (Thompson and Pike, 1992) that is efficient and backward-compatible with ASCII:
  - `0xxxxxxx` (1 byte) — ASCII character `xxxxxxx`
  - `110yyyyy 10yyyyyy` (2 bytes) — encodes Unicode character `0byyyyyyyyyyy`. Covers most Latin-script alphabets plus
    Greek, Cyrillic, Coptic, Armenian, Hebrew, Arabic.
  - `1110zzzz 10zzzzzz 10zzzzzz` (3 bytes) — gives 16 bits, enough for the Basic Multilingual Plane.
  - `11110aaa 10aaaaaa 10aaaaaa 10aaaaaa` (4 bytes) — encodes the remaining characters.

### Strings in C

Python `str` and Java `String` classes are internally complex and use Unicode characters. The C representation of a
string is much simpler: a null-terminated sequence of bytes. Assuming ASCII encoding, the string `"Hello !"` is stored
as:

`0x48 0x65 0x6c 0x6c 0x6f 0x20 0x21 0x00`

The final `0x00` is the null terminator.

## Floating-Point Representation

### Representing Real Numbers

Binary point notation works analogously to decimal: $27.3_{10} = 2 \cdot 10^1 + 7 \cdot 10^0 + 3 \cdot 10^{-1}$, and
$10.11_2 = 1 \cdot 2^1 + 0 \cdot 2^0 + 1 \cdot 2^{-1} + 1 \cdot 2^{-2} = 2.75_{10}$. The key questions are: how does the
computer know where the point is, and how are negative real numbers represented?

### Fixed-Point Representation

When the scale (number of fractional digits) is known in advance, a fixed-point representation can be used. For example,
prices with two decimal places: £86.73 can be stored as the integer 8673. Negative numbers follow seamlessly using two's
complement (e.g., −86.73 stored as the two's complement of −8673).

### IEEE 754 Floating-Point Format

When the scale is not known, it must be encoded as part of the number. The number is expressed in normalised scientific
notation in binary: $1101.11_2 = 1.10111_2 \times 2^3$, where `10111` is the **mantissa** (fraction) and `3` is the
**exponent**.

#### Single Precision (32-bit)

The IEEE 754 single-precision format uses 32 bits:

| Field                  | Bits | Description                                  |
| ---------------------- | ---- | -------------------------------------------- |
| Sign                   | 1    | 0 = positive, 1 = negative                   |
| Exponent argument (EA) | 8    | Biased exponent                              |
| Fraction (mantissa)    | 23   | Fractional part after the implicit leading 1 |

The value of a **normal** number is:

$$\text{Value} = (-1)^{\text{sign}} \times 2^{EA - B} \times 1.\text{fraction}$$

where $B = 127$ is the bias. The exponent argument for normal numbers is in the range $\{1, \ldots, 254\}$, giving a
true exponent range of $[-126, 127]$.

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

| Operation             | Result    |
| --------------------- | --------- |
| n ÷ ±Infinity         | 0         |
| ±Infinity × ±Infinity | ±Infinity |
| ±nonZero ÷ ±0         | ±Infinity |
| ±finite × ±Infinity   | ±Infinity |
| Infinity + Infinity   | +Infinity |
| −Infinity − Infinity  | −Infinity |
| ±0 ÷ ±0               | NaN       |
| ±Infinity ÷ ±Infinity | NaN       |
| ±Infinity × 0         | NaN       |
| NaN == NaN            | False     |

#### Worked Example: Representing π as a Single-Precision Float

$$\pi \approx 3.14159\,26535\,89793_{10}$$

Converting to binary: $\pi \approx 11.00100100001111110110101\ldots_2$

Normalising: $= 1.10010010000111111011011_2 \times 2^1$ (with rounding of the last bit)

Encoding:

- Sign = 0 (positive)
- EA = 1 + 127 = 128 = `10000000`₂
- Fraction = `10010010000111111011011`

Bit pattern: `0 10000000 10010010000111111011011`

Accuracy: the actual value represented is 3.1415927410125732421875, while π starts with 3.1415926535897932384626 — a
relative error of approximately $3 \times 10^{-8} < 2^{-24}$.

#### Double Precision (64-bit)

IEEE 754 double precision uses 64 bits with the same structure:

| Field             | Bits |
| ----------------- | ---- |
| Sign              | 1    |
| Exponent argument | 11   |
| Fraction          | 52   |

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

| Instruction           | Description                    |
| --------------------- | ------------------------------ |
| `add.s $f2, $f4, $f6` | FP add (single precision)      |
| `sub.s $f2, $f4, $f6` | FP subtract (single precision) |
| `mul.s $f2, $f4, $f6` | FP multiply (single precision) |
| `div.s $f2, $f4, $f6` | FP divide (single precision)   |
| `add.d $f2, $f4, $f6` | FP add (double precision)      |
| `sub.d $f2, $f4, $f6` | FP subtract (double precision) |
| `mul.d $f2, $f4, $f6` | FP multiply (double precision) |
| `div.d $f2, $f4, $f6` | FP divide (double precision)   |

Floating-point registers range from `$f0` to `$f31`. Double precision is 64-bit and uses two adjacent registers, so only
even-numbered registers (`$f0`, `$f2`, `$f4`, …) are allowed for doubles.

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

The following MIPS assembly computes an approximation of π using 10,000 terms of this series with single-precision
floating-point arithmetic:

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

# Week 6: Introduction to Concurrency — Executing MIPS Code in a Single-Core Processor

This is the first week of the concurrency half of the module. The overarching theme is **opportunities and perils of
modern hardware from the programmer's perspective**. Week 6 focuses on concurrency at the hardware level: how MIPS code
executes in a pipelined single-core processor, how memory interaction (especially caching) creates subtle issues, and
why these hardware realities matter for software correctness.

**References:** Patterson & Hennessy (P&H) chapters 4–5.

## Module Roadmap (Weeks 6–10)

| Week | Topic                                                       | Abstraction level                  |
| ---- | ----------------------------------------------------------- | ---------------------------------- |
| 6    | Executing MIPS code in a single-core processor              | Concurrency in hardware            |
| 7    | Multi-core processors, threads and concurrency abstraction  | Concurrency in software            |
| 8    | Threads and thread synchronisation in Java                  | Concurrency in Java                |
| 9    | Java memory model, monitors and conditional synchronisation | Concurrency in Java                |
| 10   | Reasoning on correctness of multi-threaded systems          | Concurrency in larger applications |

## Course Delivery and Readings

The concurrency half relies on three tiers of material, ordered from deepest/most complete to highest-level/broadest:

1. **Textbooks and essential readings** — the main references for technical content. Essential readings are specified
   before each week and are required reading before office hours (and recommended before live sessions). "Essential"
   does not mean "exclusive": students are encouraged to read beyond the essentials. Further readings are posted on
   Moodle as supplements but are _not_ examinable.
2. **Additional material** — extra slides, code, and references to deepen understanding. Non-assessed courseworks
   provide exercises for exam preparation; students should attempt them independently before solutions are discussed in
   live sessions.
3. **Live sessions** — review core concepts and offer the lecturer's perspective. Students may request specific topics
   via the Moodle forum.

All content from essential readings, in-person sessions, and additional material is examinable, with the focus on the
ability to _apply_ and _build upon_ concepts rather than recall specific sentences.

### Textbooks

The main textbook is **Java Concurrency in Practice** by Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David
Holmes, and Doug Lea — referred to as **[GPBBHL]** on Moodle and in slides. It is available through the UCL library.
Although it references an older version of Java, it covers the core concurrency problems and solutions thoroughly for
Java and other object-oriented languages. The Magee–Kramer book is optional (useful for additional code examples).

### Learning Outcomes

The primary goals are to cover the fundamentals of software concurrency and provide future-proof knowledge. All
primitives, patterns, idioms, and code examples use Java, but the underpinning principles have broader validity. The
module focuses on basic concurrency primitives (e.g. locks); understanding these enables students to learn other
constructs and libraries independently in the future.

## From C to MIPS Execution in a Pipelined Processor

### Translating C to MIPS Instructions

Consider the C code:

```c
a = b + e;
c = b + f;
```

Assume all variables reside in memory, addressable as offsets from `$t0`: `b` at `0($t0)`, `e` at `4($t0)`, `f` at
`8($t0)`, `a` at `12($t0)`, `c` at `16($t0)`.

To compute `a = b + e` in MIPS: load the two operands into registers, add them, then store the result back to memory.
The same procedure applies to `c = b + f`. The full MIPS translation is:

```mips
lw    $t1, 0($t0)      # load b
lw    $t2, 4($t0)      # load e
add   $t3, $t1, $t2    # a = b + e
sw    $t3, 12($t0)     # store a
lw    $t4, 8($t0)      # load f
add   $t5, $t1, $t4    # c = b + f
sw    $t5, 16($t0)     # store c
```

### Pipelined Execution and the Five-Stage Pipeline

Each MIPS instruction passes through five pipeline stages, each taking one clock cycle:

1. **Fetch (IM)** — read the instruction from instruction memory.
2. **Decode (RF)** — read source registers from the register file; decode the operation and immediate values.
3. **Execute (ALU)** — perform the arithmetic/logic operation or compute the memory address.
4. **Memory (DM)** — access data memory (read for `lw`, write for `sw`; no-op for arithmetic instructions).
5. **Write-back (RF)** — write the result back to the register file.

**Without pipelining**, the next instruction cannot begin until the previous one has completed all five stages — so each
instruction takes 5 cycles and instructions execute sequentially.

**With pipelining**, a new instruction enters the pipeline every clock cycle. While instruction 1 is in its decode
stage, instruction 2 is being fetched, and so on. For $n$ instructions, a non-pipelined processor takes $5n$ cycles
whereas a pipelined processor takes approximately $n + 4$ cycles (5 cycles for the first instruction, then one
additional cycle per subsequent instruction).

### Data Hazards

Pipelining introduces **data hazards** when an instruction depends on the result of a preceding instruction that has not
yet completed its write-back.

**Hazard 1 — register dependency resolvable by forwarding:** In the sequence `lw $t1, 0($t0)` → `lw $t2, 4($t0)` →
`add $t3, $t1, $t2`, the `add` needs `$t1` in its execute stage (clock cycle 4). At that point, `lw $t1` has just
completed its memory stage and the value of `$t1` is available at the output of the DM stage — but it has not yet been
written back to the register file. **Forwarding** (also called bypassing) solves this by routing the value directly from
the DM output of the first `lw` to the ALU input of the `add`, without waiting for the write-back stage.

**Hazard 2 — load-use hazard requiring a stall:** The `add` also needs `$t2`, which is produced by `lw $t2, 4($t0)`.
When the `add` reaches its execute stage, the second `lw` is only in its memory stage — the data has not yet been read
from memory. Forwarding cannot help because the value does not exist anywhere in the pipeline yet. The solution is to
**stall** the pipeline by inserting a **NOP** (bubble) for one cycle, delaying the `add` so that `$t2` becomes available
via forwarding from the DM stage of the second `lw`.

### Executable Sequence with Stalls

After inserting the necessary NOPs to resolve load-use hazards, the actually executable instruction sequence becomes:

```mips
lw    $t1, 0($t0)
lw    $t2, 4($t0)
nop
add   $t3, $t1, $t2
sw    $t3, 12($t0)
lw    $t4, 8($t0)
nop
add   $t5, $t1, $t4
sw    $t5, 16($t0)
```

### Instruction Reordering

Compilers and processors can **reorder instructions** to improve performance — for example, by moving an independent
instruction into a NOP slot. In the sequence above, the `lw $t4, 8($t0)` (which loads `f`) does not depend on the result
of the `add` or `sw` that precede it, so it could potentially be moved earlier to fill the NOP slot, eliminating the
stall. This is a key optimisation technique, but it means the order of instructions as executed may differ from the
order written in the source code.

## Interaction with Memory

### The Memory Bottleneck

Pipelining increases instruction throughput, but the bottleneck shifts to **memory access**. Accessing main memory takes
on the order of **100 clock cycles** — far too slow for the pipeline, which ideally processes one instruction per cycle.
Instructions like `lw` and `sw` that access data memory are particularly affected.

### Caches

The workaround is **caching**: placing a small, fast memory (the cache) between the processor and main memory. Cache
access takes approximately **1 clock cycle**, compared to ~100 for main memory.

Caches are fast but expensive and small — they hold only a small subset of main memory. Caching works well because of
**locality**:

- **Temporal locality** — recently accessed data is likely to be accessed again soon, so the cache retains copies of
  recently used data.
- **Spatial locality** — data near recently accessed addresses is likely to be needed soon, so the cache also loads
  nearby memory locations (a full cache block) on a miss.

**Cache operation:** When the processor needs to load a word, it checks the cache first. On a **cache hit**, the data is
returned directly from the cache. On a **cache miss**, the data is fetched from main memory, the cache is updated (with
both the missed data and nearby locations), and then the data is returned.

### Cache Internals

A cache is organised into **sets**, each containing one or more **ways** (also called blocks or lines). Each way stores
a contiguous block of data from main memory along with metadata.

Each way in a set contains three fields:

- **V (valid bit)** — indicates whether the entry contains valid data.
- **Tag** — the upper bits of the memory address, used to identify which memory block is stored.
- **Data** — the actual cached data (a block of contiguous bytes from memory).

**Address decomposition:** A memory address is split into three fields:

| Tag (upper bits)       | Set index (middle bits) | Byte offset (lower bits)          |
| ---------------------- | ----------------------- | --------------------------------- |
| Identifies which block | Selects the cache set   | Selects the byte within the block |

For example, with a 4-set, 2-way cache and the address `110 00 01`: the set index `00` selects Set 0, the tag `110` is
compared against the tags stored in both ways of Set 0, and the byte offset `01` selects the specific byte within the
matched block.

**Hit detection hardware:** For each way in the selected set, the stored tag is compared with the address tag using a
comparator, and the result is ANDed with the valid bit. If either way produces a hit, the corresponding data is selected
via a multiplexer and output. The overall hit signal is the OR of the individual way hits.

### Cache Design Decisions

Several design parameters affect cache performance:

- **Dimensioning** — number of sets, number of ways per set (associativity), and block size (data per way).
- **Replacement strategy** — when a new block must be stored in a fully occupied set: Least Recently Used (LRU) vs
  random, among others.
- **Writing strategy** — when a cached entry is modified: **write-through** (immediately propagate to main memory) vs
  **write-back** (defer propagation until the cache line is evicted).
- **Number of cache levels** — modern systems typically use three levels (L1, L2, L3), progressively larger and slower
  as they are farther from the processor.

### Multi-Processor Caches and the Coherence Problem

In a multi-processor system, each processor has its own private cache(s), and all processors share a common shared cache
and main memory. This creates a **cache coherence** problem.

Consider four processors with private caches, a shared cache, and main memory. Suppose memory location X initially
stores the value 1:

1. At time $t_0$: main memory has $X = 1$.
2. At $t_1$: Processor 1 reads X — its private cache and the shared cache now both hold $X = 1$.
3. At $t_2$: Processor 4 reads X — its private cache also holds $X = 1$.
4. At $t_3$: Processor 1 modifies X to 0 in its private cache.

Now Processor 1's private cache has $X = 0$, but Processor 4's private cache, the shared cache, and main memory all
still hold $X = 1$. Processor 4 would read a **stale value** — this is the cache coherence problem.

## Key Lessons

These hardware mechanisms — pipelining, instruction reordering, and caching — yield several fundamental lessons that
carry forward into the software concurrency topics of weeks 7–10:

1. **Compilers and processors can re-order operations** to improve execution speed. The programmer cannot assume
   instructions execute in the order written.
2. **Caching introduces uncertainty** about where the most up-to-date value of a variable is stored at any given time,
   and hence whether updated values are _visible_ to all parts of the system.
3. **Programmers can assume very little** about the actual execution of instructions in hardware.
4. **Hardware concurrency improves performance** (instruction throughput) **but risks affecting correctness** — e.g.
   reading stale values from registers or caches.
5. **Sometimes performance must be sacrificed for correctness** — by restricting which operations run in parallel.
6. **Synchronisation points** are a general tool for ensuring correctness of concurrent actions — e.g. waiting for an
   operation to finish (such as writing a register) before performing another that depends on it (such as reading that
   register).

## Additional Content and References

Essential additional reading for this week:

- Other types of pipelining hazards — structural and control hazards [P&H 4.5]
- Memory hierarchy — details and role of caches [P&H 5.1–5.3, Moodle]

Optional further reading:

- Internals of MIPS processors — hardware components and step-by-step instruction execution [P&H 4, Moodle]
- Advanced pipelining techniques — superscalar processors and dynamic scheduling [P&H 4, Moodle]

<!-- transcription-audit:
- Dropped: 06_1 slide 1 — title slide (boilerplate)
- Dropped: 06_1 slides 3–5 — build-up animation duplicates of slide 6 (the complete week-by-week table); consolidated into one table
- Dropped: 06_1 slide 9 — partial build-up of slide 10; consolidated
- Dropped: 06_2 slide 1 — title slide (boilerplate)
- Dropped: 06_2 slides 2–4 — build-up duplicates of the "From C to execution" problem statement; consolidated with slides 5–9
- Dropped: 06_2 slides 5–7 — build-up of the C-to-MIPS translation; consolidated into final result on slide 8–9
- Dropped: 06_2 slide 10 — recap slide re-stating the two-step approach (already covered)
- Dropped: 06_2 slides 13–14 — partial pipeline build-up; consolidated with slides 15–16
- Dropped: 06_2 slide 23 — partial build-up of slide 24 (just the question without the answer)
- Dropped: 06_2 slides 28–35 — step-by-step cache internals build-up animation; consolidated into final description based on slides 31–36
- Dropped: 06_2 slides 38–41 — multi-processor cache coherence build-up; consolidated with slide 42

- Warnings:
  - 06_2 slides 11–20: Pipeline timing diagrams are inherently spatial/temporal. Described in structured prose; the exact cycle-by-cycle alignment of stages across instructions is approximated. The original slides show box-and-arrow diagrams with forwarding paths (blue lines) and hazard indicators (red arrows/boxes). Spatial relationships are partially lost. Consider retaining original slides 17–20 as visual reference if precise pipeline timing is needed.
  - 06_2 slide 36: Detailed hardware circuit diagram of cache hit-detection logic (comparators, AND gates, OR gate, multiplexer, bus widths of 28 and 32 bits). Described in prose; the exact circuit layout is lost. Consider retaining original slide if circuit-level detail is needed.
  - 06_2 slides 38–42: Multi-processor memory hierarchy diagram with four processors, private caches, shared cache, and main memory, with highlighted X values at different cache levels. Described in prose; spatial layout partially lost.

- Ambiguities:
  - 06_1 slide 7 includes a large green-to-blue arrow graphic indicating textbooks are "deeper and more complete" while live sessions are "higher-level and broader". Captured as prose description of the three tiers.
  - 06_2 slide 22 shows a curved arrow indicating the nop being replaced/moved, with a strikethrough on "nop". Described as instruction reordering optimisation.
  - The "processor 2" vs "processor 4" labelling in the cache coherence example: slide 41 shows X:1 appearing in the rightmost (4th) processor's cache, which I labelled as "Processor 4". The slide text says "processor 2 caches X = 1" but the diagram shows it in the 4th position. Transcribed the text as stated ("processor 2") in the slide narration but used the visual position (4th processor) in the description. This may be a deliberate numbering choice or a minor inconsistency.

- Suspected source errors: none
-->

# Week 7: Introduction to Concurrency and Threads

## Recap: From Architecture to Concurrency

Program execution speed is important. Modern hardware uses multiple techniques to support faster execution: pipelining
and instruction reordering, memory hierarchy and caching, superscalars, speculation, and out-of-order execution. These
techniques do not come for free — they require more complex hardware (and potentially compilers) and introduce
data/control hazards. The course now shifts to a programmer's perspective on these issues.

## Motivating Example: Designing a Web Service

Consider implementing a server supporting web-accessible functionalities where many clients can simultaneously request
different services (e.g. mathematical computations). Processing client messages requires resources: some functionalities
are CPU intensive (long calculations), others are I/O intensive (many memory reads/writes) or network intensive. The
question is how to design the server-side application.

### Design 1: Single Process

A monolithic program can be written and executed by the operating system as a single **process**. Behind the scenes, the
OS allocates resources (code, data, files, registers, stack) to run the process separately from others on the server.

**Problem:** In production, users complain the application is very slow and blocks at times — yet the network is not the
bottleneck, there is no server crash, and no major bug in the code. A minimal reproduction confirms high computation
times:

```
$ java SimulateServer
INFO: starting to serve clients
[Client 1] factorized 10 numbers
[Client 2] factorized 10 numbers
...
[Client 10] factorized 10 numbers
INFO: completed client requests in 15801 ms
```

The root cause is that the program uses only 1 of the 64 cores on the server machine. The server process runs on one
processor core while the other cores remain idle. A long computation serving one client prevents the server from working
for other clients.

### Design 2: Multiple Processes

The program can be structured so the OS runs multiple processes, e.g. one for each client. Behind the scenes, the OS
tries to balance the load across cores. Each process gets its own resources (code, data, files, registers, stack).

**Problem:** In production, system administrators complain the application over-utilises servers. Monitoring with `top`
reveals each process requires its own resources:

| USER | PID   | %CPU | %MEM | TIME    | COMMAND             |
| ---- | ----- | ---- | ---- | ------- | ------------------- |
| name | 61754 | 78.1 | 0.4  | 0:01.33 | java SimulateServer |
| name | 61755 | 78.1 | 0.4  | 0:01.33 | java SimulateServer |
| name | 61758 | 78.1 | 0.5  | 0:01.33 | java SimulateServer |
| ...  |       |      |      |         |                     |
| name | 61745 | 0.0  | 0.4  | 0:00.10 | java SimulateServer |

Processes are heavy in terms of resource consumption: the OS allocates separate resources to each process, so too many
processes make resources scarce. Inter-process communication is expensive too. In the worst case, the OS spends more
time managing processes and allocated resources than doing useful work.

### Design 3: Multiple Threads

The program can be refactored so the OS runs a single process that spawns one **thread** per client. A thread is a part
of the program (a sequence of instructions) that the programmer flags as runnable in parallel to other threads.

Behind the scenes, the OS reserves only a few resources to each thread. Threads are lightweight processes that share
most resources (code, data, files) but each has its own registers and stack. Threads are also the minimal scheduling
units: they run simultaneously, independently, and possibly on different cores.

**Problem:** In production, clients complain the application has bugs. Writing multi-threaded software is much harder
than single-threaded software because:

- Multi-threaded software can have unexpected interactions with the underlying performance-optimised hardware. For
  example, if two threads running on different cores want to modify the same variable nearly at the same time:

```mips
        Core 1                  Core 2
lw      $t1,0($t0)      lw      $t1,0($t0)
addi    $t2,$t1,1        addi    $t2,$t1,1
sw      $t2,0($t0)      sw      $t2,0($t0)
```

- In general, sharing resources (e.g. variables) creates risks of incorrectness (analogous to data hazards in ILP).
- For programmers, it is much more challenging to reason about code executed in parallel.

**Solution:** Synchronisation and design patterns — the topic of the coming weeks.

### Design Tradeoffs

The multi-threaded design is not always the best one. Designs 1 and 2 may be better for applications that are not CPU
intensive or not time-sensitive. There is a fundamental tradeoff between simplicity, correctness, and performance. Rule
of thumb: target the easiest design that accommodates your requirements. Additional designs also exist, e.g.
multi-process with multiple threads per process.

### Multithreading and True Parallelism

Support for multithreading depends on the programming language. For example, Python (CPython) does not support true
parallelism by default due to the **Global Interpreter Lock (GIL)**: only one thread can execute Python code at once.
The `threading` module operates within a single process where all threads share the same memory space, but the GIL
limits performance gains for CPU-bound tasks. For CPU-bound parallelism, Python programmers are advised to use
`multiprocessing` or `concurrent.futures.ProcessPoolExecutor`. Threading remains appropriate for I/O-bound tasks. As of
Python 3.13, free-threaded builds can disable the GIL (see PEP 703), but this is not available by default.

## The Concurrency Abstraction

### Definition of Interleaving

From the programmer's viewpoint, the hardware can unpredictably interleave actions from all threads. Each thread
corresponds to a totally ordered sequence of **atomic actions** — actions that are indivisible in terms of processing.

An **interleaving** is defined as a totally ordered sequence of executed actions across all threads, with three
properties:

1. Only one action at a time is executed.
2. Actions from the same thread are executed in order.
3. The overall sequence of executed actions can arbitrarily mix actions from different threads.

Given two threads — Thread 1 with two actions (light-green, dark-green) and Thread 2 with two actions (light-blue,
dark-blue) — the possible interleavings include all sequences that preserve within-thread ordering while freely mixing
actions across threads. All such interleavings can happen in different runs.

### Correctness of the Abstraction

The abstraction's scope is to model problems arising from actions from different threads (e.g. executed on different
cores). Potential concerns are that it assumes a total order across actions, does not model time, and does not model
hardware details (instruction reordering, caching, thread-to-core allocation, etc.).

Reassuring observations:

- Only one processor at a time can access shared resources, so hardware effectively imposes a total order — especially
  regarding when actions finish.
- Hardware also guarantees correctness per thread.
- No bad interleaving means no misbehaviour for any duration of individual actions. One cannot make assumptions about
  the duration of any specific action. Importantly, `sleep` instructions do **not** solve problematic interleavings.

### Building on the Abstraction

The concurrency abstraction is useful to understand and solve concurrency problems and bugs. Solutions rely on
primitives of programming languages. Programming languages have constructs to:

- Define code blocks executed atomically (**critical sections**).
- Restrict the set of possible interleavings.

Programming languages precisely define the guarantees those constructs provide, irrespective of the underlying hardware.
These aspects will be studied in Java.

## Counting Interleavings

### Two Threads

**Example 1:** Thread A = {A1, A2}, Thread B = {B1}. In the concurrency abstraction, actions within threads are never
reordered (A2 always follows A1). The answer is **3** interleavings: [A1,A2,B1], [A1,B1,A2], [B1,A1,A2].

**Example 2:** Thread A = {A1, A2}, Thread B = {B1, B2}. Enumerating: if A1 is first → [A1,A2,B1,B2], [A1,B1,A2,B2],
[A1,B1,B2,A2]; if B1 is first → [B1,A1,A2,B2], [B1,A1,B2,A2], [B1,B2,A1,A2]. No interleaving starts with A2 or B2. The
answer is **6**. One more action doubles the number of interleavings.

### General Formula for Two Threads

For two threads A and B where A has $X$ atomic actions and B has $Y$ actions, the number of interleavings is a
stars-and-bars calculation. With $n$ stars and $m$ bars, the number of possible sequences (including those with
consecutive bars) is the binomial coefficient $\binom{n+m}{n}$.

$$\text{Number of interleavings} = \frac{(X+Y)!}{X!\,Y!}$$

### Three Threads

**Example 1:** Thread A = {A1}, Thread B = {B1}, Thread C = {C1}. Enumerating: A1 first → [A1,B1,C1], [A1,C1,B1]; B1
first → [B1,A1,C1], [B1,C1,A1]; C1 first → [C1,B1,A1], [C1,A1,B1]. The answer is **6**.

**Example 2:** Thread A = {A1, A2}, Thread B = {B1}, Thread C = {C1}. Enumerating: A1 first → [A1,A2,B1,C1],
[A1,A2,C1,B1], [A1,B1,A2,C1], [A1,B1,C1,A2], [A1,C1,A2,B1], [A1,C1,B1,A2]; B1 first → [B1,A1,A2,C1], [B1,A1,C1,A2],
[B1,C1,A1,A2]; C1 first → [C1,B1,A1,A2], [C1,A1,B1,A2], [C1,A1,A2,B1]. The answer is **12** — twice as many as two
threads with two actions each.

## Interleaving Analysis: A Simple Program

Given T1 = {x=5; x=2\*x} and T2 = {x=x+2}, what are the possible values of x after both threads terminate?

**Naïve analysis** (treating each statement as atomic):

- Interleaving 1: x=5; x=2\*x; x=x+2 → x=12
- Interleaving 2: x=5; x=x+2; x=2\*x → x=14
- Interleaving 3: x=x+2; x=5; x=2\*x → x=10

**But are all those instructions truly atomic?** The statement `x=2*x` entails both a read and a write and can be
decomposed as `t=x; x=2*t`. Similarly, `x=x+2` can be decomposed as `s=x; x=s+2`. With finer-grained atomic actions,
additional values become possible:

- Interleaving 4: s=0; (all of T1); x=s+2 → x=2
- Interleaving 5: s=0; x=5; x=s+2; x=2\*x → x=4
- Interleaving 6: x=5; s=5; ...; x=s+2 → x=7

## Lessons Learned

There is a **combinatorial explosion** of possible interleavings. With just two threads, the count follows a binomial
coefficient; more threads introduce more degrees of freedom and even more combinations. Real concurrent programs may
have many threads, each performing many actions.

Key consequences:

- The combinatorial explosion leads to **unpredictability** and **non-determinism**: many possible results that are hard
  to enumerate for large programs.
- Some interleavings may be much more likely than others, so concurrency bugs are **hard to uncover** even with testing.
- Other interleavings can happen very rarely, so concurrency bugs are **latent**.
- It is hard to statically analyse real concurrent programs; they need to be **designed well**. Manual analyses and
  formal tools do not scale.

For this reason, the module focuses on reading and reasoning about concurrent code.

## Essential Reading

- Additional information on threads: **GPBBHL sections 1.1–1.2**, Java documentation — includes brief history and other
  use cases for threads.
- Support for multithreading at the hardware and OS level (e.g. context switch): **Moodle materials**.
- _Optionally:_ Cache coherence — **P&H section 5.8** — follow-up on cache coherence in multicore processors from the
  previous week.

<!-- transcription-audit:
- Dropped: slide 1 — title slide, boilerplate
- Dropped: slide 2 — warmup/classroom logistics (Mentimeter self-assessment, pacing feedback)
- Dropped: slides 6–8 — animation build-up of Design 1 diagram (merged into single description)
- Dropped: slides 12–14 — animation build-up of Design 2 diagram (merged into single description)
- Dropped: slide 27 — greyed-out recap of Design 3 content, redundant with slides 22–24
- Dropped: slides 28–30 — animation build-up of concurrency abstraction definition (merged into slide 30 final version)
- Dropped: slides 31–34 — animation build-up of interleaving diagram (described in prose)
- Dropped: slide 38 — Mentimeter logistics for CW4 exercise
- Dropped: slide 39 — question-only version of two-threads exercise (answer on slide 40)
- Dropped: slide 41 — question-only version of two-threads variant (answer on slide 42)
- Dropped: slide 43 — question-only version of general formula exercise (answer on slide 44)
- Dropped: slide 45 — question-only version of three-threads exercise (answer on slide 46)
- Dropped: slide 47 — question-only version of three-threads variant (answer on slide 48)
- Dropped: slide 49 — question-only version of simple program exercise (answer on slides 50–52)
- Warnings: Slides 31–34 use colour-coded blocks (light-green, dark-green for Thread 1; light-blue, dark-blue for Thread 2) to illustrate interleaving visually. The spatial/colour semantics have been described in prose but the visual immediacy is lost. The original asset may be worth retaining if the visual is pedagogically important.
- Ambiguities: Slide 26 shows a screenshot of the Python `threading` documentation page including GIL details and PEP 703 reference. Transcribed the substantive content rather than describing the screenshot. The slide's intent appears to be showing that Python's threading docs themselves warn about the GIL limitation.
- Ambiguities: Slide 52 shows interleaving results x=2, x=4, x=7 with abbreviated interleaving descriptions (e.g. "s=0; T1; x=s+2"). Transcribed faithfully as presented; the initial value of x before T1 and T2 start is implicitly 0 (used in s=0 derivation).
-->

# Week 8 — Thread Safety, Synchronisation, and Locking in Java

Essential reading: GPBBHL chapter 2.

## Concurrency Recap

Modern hardware supports true parallelism, enabling better performance — threads can execute simultaneously on different
cores. However, threads' interactions can non-deterministically lead to unwanted results, depending on hardware, OS,
workload, interrupts, etc. These interactions can be modelled by the concurrency abstraction. We generally need to
forbid some interleavings to guarantee correctness.

## A Factorising Web Service

Consider a server that factorises input numbers: each client request contains an integer X, and the server responds with
a list of factors that multiply to X. We want to assign one thread per client request for performance and reactiveness.

The server process has shared code, data, and heap segments, while each thread has its own registers and stack.

### Java Servlets

Servlets are a framework for implementing Java programs that run within a web server, providing native support for
request-response applications. To define an application, one implements new servlet classes — each servlet defines a
component of the server application, created by implementing methods specified by the `Servlet` interface.

The servlet concurrency model:

- Each client request is served by one thread.
- Each servlet can be called from multiple threads.
- Threads accessing the same servlet share the servlet's state.

**Servlets in this module** are used to demonstrate that concurrency is crucial even "just" to use existing frameworks
or libraries, and to provide background for examples in [GPBBHL]. In-depth study of servlets or the full servlet package
is _not_ required. Additional resources:
[Java EE 5 Servlet Tutorial](https://docs.oracle.com/javaee/5/tutorial/doc/bnafe.html).

## Thread Safety and Race Conditions

**Thread safety** means correctness (never being in an invalid state) irrespective of the interactions between threads.
Correctness can be formalised as pre-conditions, post-conditions, and invariants.

Thread safety implies **no race condition**. A race condition is an incorrect computation that occurs only in specific
interleavings (e.g., unlucky timings).

**Practical definition** used in this module: an application (resp. class) is thread safe if it allows the same set of
outputs (resp. states) regardless of the number and timings of threads.

## Iterative Development of the Factoriser

### Iteration 1: SimpleFactorizer (stateless — thread safe)

```java
public class SimpleFactorizer implements Servlet {
    public void service(ServletRequest req,
                        ServletResponse resp) {
        BigInteger i = extract(req);
        BigInteger[] factors = factorize(i);
        encodeInResponse(resp, factors);
    }
    ...
}
```

This servlet is **stateless** — no information is carried from one request to the next. It is **thread safe** because
when calling `service()`, each thread stores method-local variables in its own stack, which is not accessible by other
threads.

### Iteration 2: CachingFactorizer (shared state — not thread safe)

To improve performance (factorising is expensive), we cache the last factorisation by adding instance fields:

```java
public class CachingFactorizer implements Servlet {
    private BigInteger lastNumber;
    private BigInteger[] lastFactors;

    public void service(ServletRequest req,
                        ServletResponse resp) {
        BigInteger i = extract(req);
        BigInteger[] factors = null;
        if (i.equals(lastNumber)) {
            factors = lastFactors.clone();
        }
        if (factors == null) {
            factors = factorize(i);
            lastNumber = i;
            lastFactors = factors;
        }
        encodeInResponse(resp, factors);
    }
}
```

This is **not thread safe**. Two post-conditions must hold:

1. The product of `lastFactors` equals `lastNumber`.
2. Each response encodes the factors for the number in the corresponding request.

Both can be violated by race conditions.

**Race condition #1 — inconsistent cache state (violates post-condition #1):**

| Step | Thread | Action                       |
| ---- | ------ | ---------------------------- |
| 1    | A      | `lastNumber = X`             |
| 2    | B      | `lastNumber = Y`             |
| 3    | B      | `lastFactors = factorize(Y)` |
| 4    | A      | `lastFactors = factorize(X)` |

Outcome: `lastNumber = Y`, `lastFactors = factorize(X)` — mismatch.

**Race condition #2 — wrong response (violates post-condition #2):**

| Step | Thread | Action                        |
| ---- | ------ | ----------------------------- |
| 1    | A      | `lastNumber.equals(X)` → true |
| 2    | B      | `lastFactors = factorize(Y)`  |
| 3    | A      | `factors = lastFactors`       |

Outcome: thread A sends back the factors of Y instead of X.

### Analysis: the Need for Synchronisation

Multiple threads have access to the same variables — `lastNumber` and `lastFactors` are instance fields, hence shared
across threads. The problem is that shared variables are modified by different threads running concurrently, leading to
inconsistent modifications.

The solution is to coordinate threads by enforcing **atomicity** of actions on shared variables. This restricts the set
of possible interleavings by synchronising access to shared variables. Sequences of operations that must be atomic to
ensure thread safety are called **compound actions**.

### Iteration 3: Synchronised Method (thread safe but slow)

```java
public synchronized void service(ServletRequest req,
                                 ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = null;
    if (i.equals(lastNumber)) {
        factors = lastFactors.clone();
    }
    if (factors == null) {
        factors = factorize(i);
        lastNumber = i;
        lastFactors = factors;
    }
    encodeInResponse(resp, factors);
}
```

Only one thread at a time can execute this method. Technically, one thread acquires a lock (linked to `this` object)
before executing the method; other threads trying to execute it are forced to wait for the lock to be released.

This is **thread safe but slow**: only one thread at a time performs the expensive factorisation. Despite using
multi-threading and caching, performance is very close to a single-threaded application.

### Iteration 4: Fine-Grained Locking (thread safe and faster)

```java
public void service(ServletRequest req,
                    ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = null;
    synchronized (this) {
        if (i.equals(lastNumber))
            factors = lastFactors.clone();
    }
    if (factors == null) {
        factors = factorize(i);
        synchronized (this) {
            lastNumber = i;
            lastFactors = factors;
        }
    }
    encodeInResponse(resp, factors);
}
```

Only reads and updates to `lastNumber` and `lastFactors` are serialised. Multiple threads can factorise integers in
parallel.

### Iteration 5: Refactoring with Synchronised Helper Methods

The critical sections can be isolated into synchronised methods:

```java
public void service(ServletRequest req,
                    ServletResponse resp) {
    BigInteger i = extract(req);
    BigInteger[] factors = getSavedFactors(i);
    if (factors == null) {
        factors = factorize(i);
        saveState(i, factors);
    }
    encodeInResponse(resp, factors);
}

private synchronized BigInteger[] getSavedFactors(BigInteger i) {
    if (i.equals(lastNumber)) {
        return lastFactors.clone();
    }
    return null;
}

private synchronized void saveState(BigInteger i,
                                    BigInteger[] factors) {
    lastNumber = i;
    lastFactors = factors;
}
```

## Lessons Learned

### Centrality of State

An object's **state** is its internal data that affects externally visible behaviour — typically instance and static
fields, but can also include fields from dependent objects.

Threads that share and arbitrarily modify state can cause concurrency problems called **interference** (e.g., state
inconsistently mixes updates from two threads).

**General rule:** whenever multiple threads access a given mutable state variable, we **must** coordinate their access
to it using synchronisation. Otherwise, the program is broken.

### Importance of Design

Retrofitting thread safety is hard — it entails evaluating _all possible accesses_ to any shared resources by any set of
spawned threads, typically requiring checking very many code paths and interleavings.

The solution is to **design with thread safety in mind**. For each state variable, consider: (i) does it need to be
shared? (ii) must it be mutable? (iii) must access to it be synchronised?

There is often a **tradeoff between correctness, simplicity, and performance**. Using synchronisation everywhere makes
it simpler to write multi-threaded code but can hurt performance — and even correctness (covered in week 10).

### Available Tools

**Locking:** the `synchronized` keyword enables use of Java implicit locks that enforce mutual exclusion. Blocks of
instructions guarded by the same lock cannot be executed by more than one thread at any time. This is the basis for
supporting synchronisation policies.

**Good software engineering practices** are also useful:

- **Encapsulation and data hiding:** internal state of an object is directly accessible only by the object itself.
- **Immutability:** make variables immutable when their value should not change over time.
- **Documentation**, especially of invariants.

## The Big Garden Application

Inspired by the Ornamental Garden problem (Magee & Kramer, ch. 4). A garden is open to the public, with people entering
through either of two turnstiles. Visitors are counted at each turnstile and for the entire garden.

The "Big Garden" is a generalisation for N turnstiles, with simplified and updated code.

The garden has a shared `Count` variable, with a West Turnstile and an East Turnstile each incrementing it — a classic
shared-mutable-state scenario.

## Exercises: Synchronised Methods

Given the following class:

```java
public class Example {
    private int x = 2;
    private int y = 3;

    public void a() {
        y = 2 * x;
    }

    public synchronized void b() {
        x = x + y;
    }

    public synchronized void c() {
        y = 2 * x;
    }
    ...
}
```

**Q1: Can two threads run `b()` and `c()` concurrently on the same `Example` instance?** No — both are `synchronized`,
so they acquire the same implicit lock on `this`. By definition of `synchronized`, only one can execute at a time on the
same instance.

**Q2: What are the possible values of `[x, y]` if `b()` and `c()` are run on the same instance?** Only two possible
interleavings:

- Interleaving #1: first `b()` → `[5, 3]`, then `c()` → `[5, 10]`.
- Interleaving #2: first `c()` → `[2, 4]`, then `b()` → `[6, 4]`.

**Q3: Can two threads run `a()` and `b()` concurrently on the same instance?** Yes — `a()` is not `synchronized`, so it
does not acquire the lock. It can run concurrently with `b()` even on the same instance.

**Q4: What are the possible values of `[x, y]` if `a()` and `b()` are run concurrently on the same instance?**
Effectively no synchronisation, so all possible interleavings of atomic actions are permitted. Beyond the two sequential
outcomes (`[6, 4]` from a-then-b and `[5, 10]` from b-then-a), the value `[5, 4]` is also possible via interleaving:

1. `a()` reads `x = 2`
2. `b()` sets `x = 5`
3. `a()` sets `y = 2 * 2 = 4`

**Q5: Is the `Example` class thread safe?** Technically it depends on the specification, but threads can interfere when
running `a()`, generating values of `[x, y]` that would be impossible with proper synchronisation. In practice, the
class is **not** thread safe.

## Additional Content and References

The following topics are covered in supplementary materials:

- **Java thread specifics** [Moodle] — including Java syntax and threads' lifecycle.
- **Standalone Java code** [Moodle] — examples not relying on external frameworks like Servlets.
- **Use of thread-safe libraries** [GPBBHL ch. 2] — e.g., those in `java.util.concurrent`. Main takeaway: thread-safe
  libraries are useful but do **not** solve all concurrency problems in your application.
- **Lock reentrancy** [GPBBHL 2.3.2] — threads can re-acquire locks they already hold.

<!-- transcription-audit:
- Dropped: slide 1 — title slide (boilerplate; reference preserved at top)
- Dropped: slide 2 — warmup/logistics (Mentimeter self-assessment, interaction encouragement)
- Dropped: slides 3–4 — build-up animation duplicates of slide 5 ("concurrency story so far")
- Dropped: slide 7 — build-up animation duplicate of slide 8 ("Java Servlets")
- Dropped: slide 11 — near-duplicate of slide 10 with added question, content merged
- Dropped: slides 12–13 — build-up animation duplicates of slide 14 ("Defining correctness")
- Dropped: slide 22 — build-up animation duplicate of slide 23 ("Analysis: synchronisation")
- Dropped: slide 25 — near-duplicate of slide 24/26 (same code, transition slide)
- Dropped: slides 30, 32 — build-up animation duplicates of slides 31, 33
- Dropped: slide 36 — Mentimeter poll logistics
- Dropped: slides 37, 39, 41, 43, 45 — question-only slides (merged with their answer slides 38, 40, 42, 44, 46)
- Warnings: none
- Ambiguities:
  - Q4 answer on slide 44: the two sequential outcomes are [6,4] (a then b) and [5,10] (b then a). The interleaved outcome [5,4] is genuinely new — a() reads x=2 before b() updates it, but b() finishes first, leaving x=5 while a() writes y=4. Transcribed faithfully.
-->

# Week 9 — Visibility, Publication, and the Monitor Pattern

References: GPBBHL chapters 3, 4, and 14.

## Recap: Interference and Synchronisation

Operating systems run threads concurrently, possibly on different processors. **Interference** occurs when threads
update shared data simultaneously, leading to inconsistent state (e.g., mixed-up servlet cache entries) or incorrect
behaviour (e.g., returning the output for a different input). To ensure correctness, programmers must prevent multiple
threads from simultaneously accessing the same shared data. The basic mechanism in Java is **synchronisation** with
implicit locking, enforcing **mutual exclusion** for the execution of **critical sections**.

## Visibility Problems

### The Reader Example

Consider the following program:

```java
public class Example {
    private static boolean ready;
    private static int number;

    private static class Reader extends Thread {
        public void run() {
            while (!ready)
                Thread.sleep(1000);
            System.out.println(number);
        }
    }

    public static void main(String[] args) {
        new Reader().start();
        number = 42;
        ready = true;
    }
}
```

**Intention:** The main thread creates a Reader thread, sets `number` to 42, then sets `ready` to `true` to allow the
Reader to print and exit. The Reader spins until `ready` is `true`, then prints `number`. The expected output is `42`.

**Is it thread-safe?** The fields `ready` and `number` are shared between the main and Reader threads. However, the
Reader thread only _reads_ the shared variables — the two threads do not interfere, nor do they induce spurious state
changes. Despite this, the program is **not** safe.

**Problem 1 — can loop forever:** There is no guarantee that state changes made by one thread are propagated to other
threads. Consequence: the Reader may **never** see `ready` set to `true`, and the loop may never terminate.

**Problem 2 — zero may be printed:** There is no guarantee that consecutive assignments are executed in the order
written, nor that all caches are coherent at any moment in time. The JVM or hardware may reorder `number = 42` and
`ready = true`, so the Reader could see `ready == true` while `number` is still `0`.

### Visibility vs Interference

A **visibility problem** arises when one thread changes the state but another thread does not see the (entire) new
state. In the Reader example, the Reader sees a partial change when it prints zero, and sees no change at all when it
fails to terminate.

Visibility is fundamentally different from interference. Interference is about "too much interaction" between threads;
visibility is about "too little". The solution is the same in both cases: some form of **synchronisation** is needed
whenever a thread accesses data shared with other threads — both reads _and_ writes must be synchronised.

### The Concurrency Abstraction and Reordering

The interleaving model defines concurrency by constraining actions within each thread to execute in program order,
because hardware guarantees per-thread correctness. However, actions of one thread can be **seen by other threads as
reordered** when the reordering does not affect per-thread correctness.

Observations about the concurrency abstraction:

- It is a model, and therefore abstracts from reality (as all models do).
- It is still useful for reasoning about interference problems, e.g., when we are sure there are no other problems.
- _Sometimes_ it can be extended to account for reordering by modelling independent instructions as separate "threads" —
  e.g., in the Reader example, treating `T1:{number=42}` and `T2:{ready=true}` as independent threads.

## Synchronisation and the Java Memory Model

Synchronisation solves visibility because the Java specification states that all threads must "synchronise their working
memories" with main memory at the **entry and exit** of `synchronized` segments. Concretely: everything a thread writes
before unlocking a monitor **M** is visible to everything another thread reads after locking the same monitor **M**.

<!-- Diagram description (slide 10): Two vertical timelines, Thread A and Thread B.
Thread A executes: y = 1 → Lock M → x = 1 → Unlock M.
Thread B executes: Lock M → i = x.
An arrow from Thread A's Unlock M to Thread B's Lock M indicates the visibility guarantee:
everything before the unlock in Thread A is visible to everything after the lock in Thread B. -->

For any given shared object, there are two high-level goals:

- **G1:** No thread sees a partially constructed object.
- **G2:** All threads see changes to the object's state.

To achieve these goals, we need to understand the **Java Memory Model (JMM)**. The JMM spells out the guarantees the JVM
provides about the visibility of one thread's writes to other threads. Synchronisation prevents any instruction
reordering that would violate JMM guarantees. The concepts of **publication** and **safe publication** stem directly
from the JMM.

## Publication and Safe Publication

An object is **published** when it is made available to code outside its current context — e.g., storing it in a public
field, returning it from a public method, or passing it as a parameter.

**Hazard:** Publishing an object in a constructor can make a **partially constructed** object available to external code
(including other threads).

An object is **safely published** if both the reference to the object and its state are made visible to other threads at
the same time.

### Safe Publication Idioms

The JMM guarantees that any of the following idioms is sufficient for safe publication:

1. Initialise the object reference from a **static initialiser**.
2. Store a reference to it in a **`volatile`** field or `AtomicReference`.
3. Store a reference to it into a **`final`** field of a properly constructed object.
4. Store a reference to it into a field that is properly guarded by a **lock**.

## Avoiding Visibility Problems by Object Type

Whether goals G1 and G2 are automatically satisfied depends on the object's type:

| Object type                                                              | Goal G1 (no partial construction) | Goal G2 (see state changes)              |
| ------------------------------------------------------------------------ | --------------------------------- | ---------------------------------------- |
| Local to thread                                                          | Satisfied (not shared)            | Satisfied (not shared)                   |
| Immutable (unmodifiable state, all fields `final`, properly constructed) | Satisfied                         | Satisfied                                |
| Effectively immutable (state doesn't change after publication)           | Must be safely published          | Satisfied                                |
| Mutable (state changes over time, multiple threads may read/write)       | Must be safely published          | Must be thread-safe or guarded by a lock |

## Fixing the Holder Example

### The Problem

```java
public class ConfigSettings {
    public Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}

public class Holder {
    private int n;

    public Holder(int n) { this.n = n; }

    public void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```

The `Holder` object is **effectively immutable** (its state does not change after construction), but it is **not safely
published** — the `holder` field is `public` and non-volatile.

**Atomic actions involved:** two reads of `n` in `MyTest()`, plus several actions in the constructor (instantiating the
object, initialising fields, publishing the reference). If the constructor and `MyTest()` are run by different threads,
these atomic actions can be interleaved arbitrarily.

**Possible interleaving with two threads A and B:**

1. [A] calls `new Holder(42)`
2. [B] gets a reference to `holder`
3. [B] calls `MyTest()`
4. [B] reads `n = 0` in `MyTest()` (first read)
5. [A] sets `this.n = 42`
6. [B] reads `n = 42` in `MyTest()` (second read)

**Outcome:** `AssertionError` is raised because B sees a **partially constructed** `Holder` object — the two reads of
`n` in `n != n` return different values.

### Option 1: Make Holder Immutable

Declare `n` as `final`:

```java
public class Holder {
    private final int n;

    public Holder(int n) { this.n = n; }

    public void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```

The `final` keyword on `n` means its value cannot be changed after construction. The JMM guarantees that `final` fields
are fully visible to all threads once the constructor completes (provided the object is properly constructed).

### Option 2a: Safely Publish via Static Initialiser

```java
public class ConfigSettings {
    public static Holder holder = new Holder(42);
}
```

The `holder` reference is initialised in a static initialiser, which the JVM guarantees is executed safely before any
thread can access the class.

### Option 2b: Safely Publish via `volatile`

```java
public class ConfigSettings {
    public volatile Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}
```

The `volatile` keyword ensures that reads of `holder` always return the most recent write by any thread (a form of weak
synchronisation).

### Option 2c: Safely Publish via `final` Field

```java
public class ConfigSettings {
    public final Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }
}
```

The reference to the `Holder` object cannot be changed after construction. The JMM guarantees visibility of `final`
fields once the enclosing object's constructor completes.

### Option 2d: Safely Publish via Lock

```java
public class ConfigSettings {
    private Holder holder;

    public ConfigSettings() {
        holder = new Holder(42);
    }

    public synchronized Holder GetHolder() {
        return holder;
    }
}
```

Locking ensures visibility but has an impact on performance and interface design.

## Design Patterns for Concurrency

Reasoning about interference and visibility problems for each object and piece of state is complex and error-prone, yet
correctness must be ensured in all concurrent applications. **Design patterns** — general, repeatable solutions to
common problems in software engineering — encode good practices built from experience.

### The Java Monitor Pattern

To make an object thread-safe using the Java monitor pattern: **encapsulate all its mutable state and guard the state
with the object's intrinsic lock**. All methods that access the state are `synchronized`. There is a possible
simplicity–performance tradeoff.

Ways to use the pattern:

- Wrap non-thread-safe objects.
- Model data as classes implementing the monitor pattern, so they can be safely accessed by multiple threads.

### Example: A Mutable and Safe Holder

```java
public class MutableHolder {
    private int n = 0;

    public synchronized void SetValue(int x) {
        n = x;
    }

    public synchronized int GetValue() {
        return n;
    }

    public synchronized void MyTest() {
        if (n != n)
            throw new AssertionError("error!");
    }
}
```

## Conditional Synchronisation

When a thread cannot work on the current state of a monitor (e.g., reading from an empty buffer), there are two options:
fail/raise an error (the only possibility in single-threaded applications), or **wait for another thread to change the
monitor's state**. Conditional synchronisation supports the second possibility.

### Pseudocode Pattern

```
acquire lock
while (predicate) {
    release lock
    wait to be notified
    reacquire lock
}
perform action
notify other threads
release lock
```

### Java Example

```java
public synchronized V read() {
    while (isEmpty()) {
        wait();
    }
    V val = doRead();
    notifyAll();
    return val;
}
```

### Condition Queues

**Condition queues** give threads a way to subscribe to specific updates on a given condition. Waiting threads form a
**wait set**. Every Java object behaves as a condition queue.

Methods:

- `wait()` — makes the calling thread enter the condition queue (releases the lock, waits for notification, reacquires
  the lock).
- `notify()` — wakes up one thread in the wait set.
- `notifyAll()` — wakes up _all_ threads in the wait set.

**Important:** Notifications signal that "something has changed", **not what** has changed. Threads must re-check the
condition predicate when woken up.

### Which Lock and Condition Queue to Use?

- The **condition predicate** is a condition on state variables.
- Before testing the condition predicate, the thread must hold the **lock guarding the corresponding state variables**.
  The same lock must be held when calling `wait()` and notification methods.
- Additionally, the **lock object must be the same as the condition queue object** (i.e., `this.wait()` makes a thread
  wait until `this.notifyAll()` is called).
- Think in terms of **entry and exit protocols**.

## Essential Reading

The slides for this week are not self-contained. The following essential reading supplements the lecture material:

- Additional examples of monitors and conditional synchronisation — available on Moodle.
- Proper use of conditional synchronisation — GPBBHL 14.2.
- The `volatile` keyword (semantics: updates to a volatile variable are propagated predictably to other threads, and how
  to use them) — GPBBHL 3.1.4.
- Additional guidelines for thread safety — GPBBHL 4.
- The actual Java Memory Model (low-level guarantees, and why they translate into the discussed safe publication rules)
  — GPBBHL 16.

<!-- transcription-audit:
- Dropped: slide 1 — title slide (boilerplate, UCL branding)
- Dropped: slide 2 — warmup/housekeeping (Mentimeter poll, no technical content)
- Dropped: slides 17–23 — intermediate build-up states of the object-type table (final state on slide 24 captured in full)
- Dropped: slide 32 — image of "Design Patterns" book cover (decorative; the textual content is preserved)
- Dropped: slides 11, 13 — intermediate build-up of the Holder example (content merged into the unified Holder section)
- Dropped: angry-face emoji icons on slides 6, 7, 11, 12, 13, 26 — decorative
- Warnings:
  - Slide 10: Synchronisation visibility diagram rendered as prose description in an HTML comment. The diagram shows two thread timelines with lock/unlock of monitor M and an arrow indicating the visibility guarantee. Spatial layout is approximated; recommend retaining original slide if precise visual is needed.
- Ambiguities:
  - "AssertionError" appears on the slides as written and matches Java's standard `java.lang.AssertionError` class. No error.
  - Slides 17–24 are a progressive build-up of a single table. Only the final completed table (slide 24) is transcribed; intermediate annotations (e.g., "not shared", "unmodifiable state, all fields are final, properly constructed", "state doesn't change after publication", "state changes over time, and multiple threads may read or write it") are incorporated into the table as clarifying text.
  - The ordering of sections was reorganised for logical flow: the Holder example (slides 11–13) is presented after the publication/safe-publication definitions rather than before, since the definitions provide necessary context. The fixes (slides 26–31) follow immediately.
- Suspected source errors: none confirmed. "AssertionError" matches Java's standard class name.
-->

# Week 10 — Liveness

Essential reading: GPBBHL chapter 10.

## Concurrency Recap: Safety Is Not Enough

Concurrency enables superior performance through use of multiple processors, responsiveness, and other benefits. Threads
are the minimal units that operating systems schedule to run concurrently; their atomic actions can be arbitrarily
interleaved, reordered, and have effects that are not universally visible. Multi-threaded applications are therefore
prone to interference and visibility problems.

**General rule:** if multiple threads access the same mutable state variable without appropriate synchronisation, your
program is broken.

Synchronisation restricts the set of possible interleavings of a concurrent program. Locks ensure mutual exclusion of
code blocks and visibility; safe publication avoids sharing partially constructed objects. Appropriate synchronisation
avoids interference and visibility problems, at the cost of some performance.

However, synchronisation alone is not enough to ensure application correctness. Correctness entails two properties:

- **Safety** — nothing bad happens (the focus of earlier weeks).
- **Liveness** — something good eventually happens.

A fully synchronised, thread-safe program does _not_ guarantee liveness. Worse, safety is generally at odds with
liveness: locking can prevent anything good from happening.

## Liveness Issues

### Deadlock

**Definition:** all threads are permanently blocked. The common case is threads waiting forever for each other due to
cyclic dependencies in resource acquisition. A real-life analogue is traffic gridlock.

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

Whether a deadlock occurs depends on how the method is called by threads. A deadlock arises with the following
interleaving:

1. `[T1]` calls `transferMoney(A, B, 1)` — acquires lock on A.
2. `[T2]` calls `transferMoney(B, A, 1)` — acquires lock on B.
3. T1 now needs lock B (held by T2); T2 now needs lock A (held by T1). Neither can proceed.

#### Fixing `transferMoney` with Lock Ordering

A possible fix is to enforce a **lock ordering discipline** — constraining all threads to acquire locks in the same
order, thereby avoiding cyclic dependencies.

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

The Dining Philosophers problem is a classic concurrency problem formulated by Dijkstra in 1965 and employed as a test
case by many synchronisation algorithms.

**Problem statement:** 5 philosophers sit around a table, each modelled as a thread. Each philosopher alternates between
thinking and eating. To eat, a philosopher needs access to 2 forks. There are only 5 forks on the table; each fork lies
between two adjacent philosophers (on the left of one and the right of another). If every philosopher picks up their
left fork simultaneously, all block waiting for their right fork — a deadlock.

#### Deadlock Examples Summary

| Type                                      | Example             | Reference       |
| ----------------------------------------- | ------------------- | --------------- |
| Single object, conflicting methods        | LeftRightDeadlock   | [GPBBHL 10.1.1] |
| Single object, conflicting methods        | Multiple Databases  | [GPBBHL 10.1.5] |
| Single object, conflicting external calls | transferMoney       | [GPBBHL 10.1.2] |
| Single object, conflicting external calls | Dining Philosophers | [Moodle]        |
| Cross objects                             | Taxi dispatcher     | [GPBBHL 10.1.3] |

#### Open Calls

Deadlocks may also be caused by calling an external method while holding a lock. An **open call** is a call to an
external method (possibly of another object) with no lock held. One should strive to be completely agnostic of and
robust to the implementation of called methods. Using open calls makes it easier to ensure locks are acquired in a
consistent order, since code paths acquiring locks become easier to follow (a similar role to encapsulation for thread
safety). **Caveat:** open calls may induce loss of atomicity.

#### Avoiding Deadlocks: Summary

**Methodology:** identify where resources are acquired, then ensure no conflicting acquisition _or_ break cycles.

| Technique                                            | Example                      | Reference       |
| ---------------------------------------------------- | ---------------------------- | --------------- |
| Threads never acquire >1 resource at a time          | —                            | [GPBBHL 10.2]   |
| Order resource acquisition within individual methods | `transferMoneyOrdered`       | [GPBBHL 10.1.2] |
| Use open calls across objects                        | ThreadSafe Taxi dispatcher   | [GPBBHL 10.1.4] |
| Acquire with timeout                                 | `transferMoney` w/ `tryLock` | [GPBBHL 10.2.1] |
| Detect-and-abort                                     | DBMS                         | [GPBBHL 10.1]   |

### Starvation

**Definition:** a thread is perpetually denied access to resources it needs in order to progress.

| Resource waited for | Example                                            | Reference       |
| ------------------- | -------------------------------------------------- | --------------- |
| CPU cycles          | Low-priority threads starved by high-priority ones | [GPBBHL 10.3.1] |
| Object or Lock      | Lock held by a thread running an infinite loop     | [GPBBHL 10.3.1] |
| Object or Lock      | Readers and Writers                                | [Moodle]        |

A lighter version of starvation is unfair allocation of resources (e.g. CPU), possibly causing poor responsiveness.

#### Starvation Example: Readers–Writers

Inspired by Readers and Writers [Magee & Kramer ch. 7]. A shared database (DB) is accessed by two types of threads:
Readers that read the DB, and Writers that update it. Writers must have exclusive access to the DB, while any number of
Readers may simultaneously access it. If readers continuously arrive, writers may be starved indefinitely.

### Livelock

**Definition:** despite not being blocked, a thread does not make any useful work — e.g. it keeps retrying an operation
that always fails.

| Failing operation                                         | Example                    | Reference       |
| --------------------------------------------------------- | -------------------------- | --------------- |
| Change state (in response to other thread's state change) | Polite people in a hallway | [GPBBHL 10.3.3] |
| Faulty error recovery                                     | Poison message problem     | [GPBBHL 10.3.3] |
| Faulty error recovery                                     | WifiLink                   | [Moodle]        |

**Typical solution:** add randomness to the retry mechanism.

#### Livelock Example: WifiLink

A simulation of transmissions on a Wi-Fi link. Wi-Fi clients transmit messages to an access point (AP); messages
simultaneously transmitted by multiple clients "collide" and are not received correctly (signals mix up).

**Problem formulation:** 1 AP and N clients. The AP waits for messages and confirms correct receptions. Each client
sends one message to the AP, waits for confirmation, and resends if no confirmation is received. Messages and AP
confirmations take time to reach their destinations. If all clients retransmit at the same fixed interval after a
collision, they will collide again indefinitely — a livelock.

### Incorrect Conditional Synchronisation

**Missed signals:** a thread keeps waiting for a condition that is already true, or was true in the past. Incorrectness
often stems from inappropriate use of conditional synchronisation and/or code bugs:

- The condition predicate is not checked before waiting.
- The thread is not woken up from a wait.

## Conditional Synchronisation (Reminder)

When a thread cannot work on the current state of a monitor (e.g. reading an empty buffer), there are two options:
fail/raise an error (the only possibility for single-threaded applications), or wait for another thread to change the
monitor's state. Conditional synchronisation supports the second possibility.

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

**Condition queues** give threads a way to subscribe to specific updates on a given condition. Waiting threads form a
**wait set**. The available methods are:

- `wait()` — allows a thread to enter a condition queue (releases the lock, blocks until notified, then reacquires the
  lock).
- `notify()` — wakes up one thread in the wait set.
- `notifyAll()` — wakes up _all_ threads in the wait set.

Notifications signal that "something has changed", **not _what_** has changed — threads must re-check the condition
predicate when woken up.

In Java, each object can act as a condition queue: `this.wait()` makes a thread wait until `this.notifyAll()` is called.
The rules for choosing which lock and condition queue to use are:

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
