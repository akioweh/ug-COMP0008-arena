> Source: [COMP0008\_01\_pre\_1.pdf](slides_original/COMP0008_01_pre_1.pdf), [COMP0008\_01\_pre\_2.pdf](slides_original/COMP0008_01_pre_2.pdf), [COMP0008\_01.pdf](slides_original/COMP0008_01.pdf)

# Week 1 — Introduction to Computer Architecture and Concurrency

## Course Structure

The module is split into two halves:

**Part I — Computer Architecture:** overview of key components of computer architecture; MIPS32 architecture and assembly language; block diagram of how a MIPS processor works; instruction-level parallelism (pipelining, superscalar architecture); thread-level parallelism (multicore, memory coherence/consistency); operating systems topics (processes, threads, running executables, multithreading, low-level concurrency primitives created from assembly instructions).

**Part II — Java Concurrent Programming:** concurrency abstraction and understanding concurrent systems; interference, visibility issues, safety/liveness balance, deadlock; Java concurrency mechanisms (locks, mutexes, semaphores, monitor design); the Java concurrency package (`java.util.concurrent`); coordinating threads to work together.

### Assessment

Three courseworks during Terms 1/2, each worth 10%:

1. Electran online system — testing fundamental architecture topics and MIPS assembly language programming.
2. Moodle quizzes on Java concurrency.
3. Multi-threaded Java programming exercise.

A comprehensive Term 3 open-book assessment is worth the remaining 70%.

### Textbooks

**Computer Architecture:**

- *Computer Organization and Design* (4th Edition) by Patterson and Hennessy, 2009, ISBN 978-0-12-374493-7. The MIPS edition (not the more recent ARM or RISC-V editions). Key textbook about the MIPS processor architecture, written by the professors who designed the chip.
- *Digital Design and Computer Architecture* by David Money Harris and Sarah L. Harris, 2013, ISBN 0123944244. Covers MIPS architecture and MIPS assembly (the course does not focus on the electronics/logic-gates aspects).

**Concurrency:**

- *Java Concurrency in Practice* by Brian Goetz, Addison-Wesley, 2006. Advanced text on Java concurrency and key design principles.
- *Concurrency: State Models & Java Programs* by J. Magee and J. Kramer, John Wiley & Sons, 2006. Covers key concurrency concepts with demos; also includes more formal material involving finite state machine analysis that the course does not cover.

## Motivation for Concurrency

### Sequential vs Concurrent Programs

A **sequential program** consists of instructions that are *totally ordered*. The instructions are carried out in a precise sequence and the process is **deterministic**. In reality the compiler/processor may change the order of instructions (out-of-order execution), but it guarantees the same deterministic results.

A **concurrent program** is a set of ordinary sequential programs executed at the "same time" (i.e. concurrently).

**Concurrency** is a key abstraction in computer science, relevant to hardware design, operating systems, multiprocessors, distributed computing, programming, and design. It is *the ability to run multiple activities simultaneously or in parallel* (and reason correctly about these systems).

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

When two people execute this program concurrently with a shared fridge, both may independently observe that milk is low, both go out and buy milk, and the fridge ends up with too much milk. This is a classic illustration of a **race condition** on shared state — the check-then-act sequence is not atomic.

### Historical Origins: Time-Sharing Operating Systems

Early batch machines loaded one program at a time, leading to very inefficient CPU utilisation — the CPU sat idle during I/O operations. One of the first time-sharing (multi-tasking) operating systems was **CTSS** (Compatible Time Sharing System), developed at MIT in 1961. It introduced the concept of the *background job* or **process**, with the aim of keeping the CPU busy by switching to another process when the current one blocks on I/O.

### Interleaved Concurrency vs True Parallelism

**Interleaved concurrency** occurs when there is only one execution engine (processor). The single processor switches rapidly between different processes, giving the illusion of simultaneous execution, but there is no true parallel processing.

**True parallelism** requires multiple execution engines. The milk example is an instance of true parallelism — two people (execution engines) running the same program simultaneously on shared data.

### Why Combine Concurrency with Computer Architecture?

Modern CPUs are multicore — a quad-core processor has four execution engines. CPU architectures switched to multicore around the 2000s because single-core performance scaling hit physical limits. Both designing and programming multicore hardware requires understanding concurrency and hardware together.

GPUs push this further: the NVIDIA Tesla K80 GPU board has 4,992 cores and can deliver over 8.74 TFLOPS of peak floating-point performance, programmed using CUDA (a C-based language).

### Flynn's Taxonomy (1972)

Flynn's taxonomy classifies processor architectures along two dimensions — the number of instruction streams and the number of data streams:

|                        | Single Data | Multiple Data |
|------------------------|-------------|---------------|
| **Single Instruction** | **SISD**    | **SIMD**      |
| **Multiple Instruction** | **MISD**  | **MIMD**      |

- **SISD** — Single Instruction, Single Data: traditional uniprocessor.
- **SIMD** — Single Instruction, Multiple Data: e.g. GPU cores executing the same instruction on different data.
- **MISD** — Multiple Instruction, Single Data: rare; sometimes used for fault tolerance.
- **MIMD** — Multiple Instruction, Multiple Data: multicore CPUs, distributed systems.

### Case Study: Therac-25

The Therac-25 was a radiation therapy machine controlled by an embedded computer handling many concurrent sensing and actuation tasks (TV camera, beam on/off, door interlock, motion power, turntable position, display terminal, etc.).

Between 1985 and 1987, at least five people died from massive radiation overdoses on these machines. The root cause was concurrency bugs — specifically **race conditions** — in the control software. The software passed formal testing, but as operators became faster at entering commands, the timing-dependent bugs manifested: a metal target was not moved into place before the beam fired, resulting in lethal overdoses. The software company initially blamed mechanical failure. It took two years and five deaths before the concurrency bugs were found. Previous versions of the machine (Therac-20) had hardware interlocks that masked the software bugs; the Therac-25 removed those interlocks, relying solely on software.

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

The question: can `my_test()` throw the exception? Counter-intuitively, **yes** — in a concurrent context, due to the Java Memory Model, another thread could see a partially constructed `Holder` object where `n` has not yet been written, or the two reads of `n` in `n != n` could see different values. This motivates the need to understand what the hardware is doing.

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

Despite only reading and writing a single boolean, this is **not guaranteed to work** — the `crush` field is not declared `volatile`, so the running thread may never see the update made by the main thread due to caching and the Java Memory Model. The thread could loop forever.

### Why Concurrent Programming Is Required

- **Performance gain** from multiprocessing hardware (parallelism).
- **Increased application throughput** — a blocking I/O call only blocks one thread.
- **Increased application responsiveness** — a high-priority thread can handle user requests.
- **More appropriate structure** for programs that control multiple activities and handle multiple events.
- **Embedded systems** for driving hardware (e.g. Therac-25) — equipment naturally consists of multiple sensors/actuators.
- **Distributed systems.**

## Motivation for Computer Architecture

### Early Computing Machines

**Antikythera mechanism** — the earliest known analogue mechanical computer. Its architecture used continuous floating-point values stored as degrees of rotation of cogs, with operations limited to fixed multiplications and divisions. It was programmable only by physically rebuilding the machine, and was not general-purpose (not Turing complete, as it lacked branching instructions). Its organisation was a fixed layout of wheels and cogs.

**Babbage's Analytical Engine** (designed 1834–1871) — considered the first *digital* computer design, running programs from punched cards. Its architecture used discrete 40-digit decimal values stored in the discrete rotation of wheels, with a memory of 1,000 such values. It supported +, −, ×, ÷, comparisons, and optionally square root. It was programmable via punched cards (similar to modern assembly language) and was Turing complete (it had branching instructions). Its organisation was still a fixed layout of wheels and cogs.

### Analogue vs Digital; Number Base Choices

The Antikythera mechanism and the Heathkit educational analogue computer used continuous values (angles, voltages). Analogue computers can perform operations like differentiation directly, but continuous representations are susceptible to noise.

Early electronic computers experimented with different number bases. ENIAC 1 used decimal calculations. The Russian **Setun** (1958) used ternary (base 3), representing symbols with negative, zero, and positive voltages. Modern computers settled on binary.

### Key Milestones in Computer Hardware

- **Colossus** (1943, Bletchley Park) — one of the first digital programmable electronic computers, used to decrypt the German Lorenz cipher. Programmed using switches and patched cables. Its organisation used thermionic valves (vacuum tubes) to carry out binary operations (Boolean algebra).
- **ENIAC 1** — one of the first electronic computers, using thermionic valves and decimal arithmetic.
- **IBM 7030** — one of the first transistor-based electronic computers, using individual transistors.
- **IBM 360** — used discrete chips with logic gates. Crucially, it introduced the idea of a single **computer architecture** (instruction set) with multiple different **implementations** (organisations) of that architecture at different price/performance points.

| Model | M30 | M40 | M50 | M65 |
|-------|-----|-----|-----|-----|
| Datapath width | 8 bits | 16 bits | 32 bits | 64 bits |
| Control store size | 4k × 50 | 4k × 52 | 2.75k × 85 | 2.75k × 87 |
| Clock rate | 1.3 MHz (750 ns) | 1.6 MHz (625 ns) | 2 MHz (500 ns) | 5 MHz (200 ns) |
| Memory capacity | 8–64 KiB | 16–256 KiB | 64–512 KiB | 128–1,024 KiB |
| Performance (commercial) | 29,000 IPS | 75,000 IPS | 169,000 IPS | 567,000 IPS |
| Performance (scientific) | 10,200 IPS | 40,000 IPS | 133,000 IPS | 563,000 IPS |
| Price (1964 $) | $192,000 | $216,000 | $460,000 | $1,080,000 |

- **Intel 4004** — the first microprocessor on a single chip, used in the Busicom 141-PF calculator.
- **Intel 8088** — 16-bit processor used in the original IBM PC.

### The Von Neumann Architecture

Computers settled into a **stored-program von Neumann architecture** with three main components connected by an external bus (or buses):

1. **Processor / CPU** (Central Processing Unit)
2. **Memory storage** — holding both instructions and data
3. **Input/Output (I/O) devices** — displays, keyboards, pointer devices

### CISC vs RISC

During the 1980s, Intel and other manufacturers drove ever more complex instruction sets (**CISC** — Complex Instruction Set Computer), since programmers working in assembly wanted fancier instructions. This required writing complex "microprograms" within the hardware chips to execute these instructions.

Hennessy and Patterson went for a radically different approach: **RISC** (Reduced Instruction Set Computer). The MIPS R3000 (released 1988, 115,000 transistors) was used to render 3D scenes in 1990s films like *Jurassic Park* and *Terminator 2*. RISC architectures are now used in over 20 billion portable devices per year, as well as in supercomputers (e.g. the Sunway TaihuLight, which uses custom 260-core 64-bit RISC chips made in China).

### Performance Scaling Eras

A graph of processor performance (relative to the VAX 11-780) over time shows distinct eras:

- **CISC era** (~1980–1986): performance doubling every ~2.5 years (22%/year).
- **RISC era** (~1986–2003): performance doubling every ~1.5 years (52%/year).
- **End of Dennard scaling → Multicore** (~2003–2011): performance doubling every ~3.5 years (23%/year).
- **Amdahl's Law limits** (~2011–2015): performance doubling every ~6 years (12%/year).
- **End of the line** (post-2015): performance doubling every ~20 years (3%/year).

### New Architectures

Computer architecture continues to evolve beyond traditional von Neumann designs:

- **Google Tensor Processing Unit (TPU)** — an application-specific architecture for machine learning. Its block diagram shows a PCIe/host interface, DDR3 memory interfaces, a unified buffer (local activation storage), a systolic array feeding a matrix multiply unit (64K operations per cycle), accumulators, activation and normalise/pool stages, with data bandwidths up to 165 GiB/s internally.
- **IBM TrueNorth** — a neuromorphic chip designed for deep neural networks.
- **D-Wave quantum computers** — using qubits for quantum computation.

### Abstraction Layers of a Modern Computer

A modern computer can be understood through a hierarchy of abstraction layers:

| Level | Name | Examples |
|-------|------|----------|
| 5 | Problem-Oriented Language | `i = i + 1;` (C source) |
| 4 | Assembly Language | `add $s3,$s3,1` (MIPS assembly) |
| 3 | Operating System | System calls, process management |
| 2 | Instruction Set Architecture (ISA) | `001000 01011 01011 0000000000000001` (machine code) |
| 1 | Microprogramming | Not all computers have this level |
| 0.5 | Modular view (datapath) | Datapaths, controllers |
| 0 | Digital Logic | AND gates, NOT gates, transistors |

The course covers: how C language constructs are compiled into MIPS assembly and executed (levels 5→4); MIPS assembly language and how machine code works (level 4→2); computer arithmetic and memory layout, since the ISA level is entirely numbers (level 2).

### Why Learn Assembly Language?

- Game development historically required assembly for performance (e.g. x86 assembly for games like *Lemmings 2* in the 1980s; 3D graphics engine optimisation in the 1990s).
- Low-level device driver development often requires examining or writing assembly.
- Compiler/tool-chain development for novel processor architectures.
- Fully understanding concurrency and multithreaded programming requires understanding the machine.
- Low-level debugging — when inserting print statements makes a bug disappear (a Heisenbug), assembly-level inspection is needed.

## Number Systems

### The Decimal System

The decimal system uses ten digits (0–9) in a **positional** notation. Each digit's value depends on its position:

$$193 = 1 \cdot 10^2 + 9 \cdot 10^1 + 3 \cdot 10^0$$

This is superior to older **additive** systems (e.g. Roman numerals: MDCCCCV = 1905).

The system extends naturally to fractions ($1.7 = 1 \cdot 10^0 + 7 \cdot 10^{-1}$) and rational numbers ($7/6 = 1.1\dot{6}$). Every rational number has a finite repeating decimal representation. Decimal numbers are often denoted with a subscript: $176_{10}$.

The decimal system is not the only option — for example, 1,702,131 can be viewed as a base-1000 number: $1 \cdot 1000^2 + 702 \cdot 1000^1 + 131 \cdot 1000^0$.

### The Binary System

Binary uses only two digits: 0 and 1. A digit in {0, 1} is called a **binary digit** (**bit**). The unary system, by contrast, has a single digit (1).

$$1101_2 = 1 \cdot 2^3 + 1 \cdot 2^2 + 0 \cdot 2^1 + 1 \cdot 2^0 = 13_{10}$$

Multiplying by $10_2$ (i.e. 2) simply appends a "0" on the right: $1101_2 \cdot 10_2 = 11010_2$. Binary is commonly denoted with the prefix `0b` and is the natural representation for computers.

### Binary Arithmetic

Binary addition and multiplication follow the same rules as decimal:

**Addition:** $1101_2 + 0110_2 = 10011_2$ (i.e. 13 + 6 = 19).

**Multiplication:** $1101_2 \times 0110_2 = 1001110_2$ (i.e. 13 × 6 = 78). Multiplication is performed by shifting and adding partial products, where each partial product is either zero or the multiplicand shifted left.

### Converting Decimal to Binary

**Greedy algorithm:** find the largest power of two that does not exceed the number, subtract it, and repeat.

Example: $69_{10}$. The largest power of two ≤ 69 is $64 = 2^6$. Remainder: 5. Largest power ≤ 5 is $4 = 2^2$. Remainder: 1. Largest power ≤ 1 is $1 = 2^0$. Remainder: 0. Result: $1000101_2$.

### Hexadecimal Representation

Binary numbers are hard for humans to read (e.g. $1010101001111011_2$ vs $43643_{10}$). **Hexadecimal** (base 16) uses 16 digits: 0123456789ABCDEF.

$$\text{0xAA7B} = 10 \cdot 16^3 + 10 \cdot 16^2 + 7 \cdot 16^1 + 11 \cdot 16^0 = 43643_{10}$$

Conversion between binary and hex is trivial: group binary digits into blocks of four from the right, and map each group to a hex digit.

$$1010\;1010\;0111\;1011_2 \rightarrow A\;A\;7\;B_{16} = \text{0xAA7B}$$

### Notation in Programming Languages

In code (e.g. Python, Java), bases are indicated by prefixes rather than subscripts:

| Base | Prefix | Example |
|------|--------|---------|
| Binary (2) | `0b` | `0b110000011111` |
| Octal (8) | `0` | `06037` |
| Decimal (10) | (none) | `3103` |
| Hexadecimal (16) | `0x` | `0xC1F` |

### Comparing Numbers Across Bases

Ordering exercise — which is largest among `010000000` (7 zeros, octal), `0x100000` (5 zeros, hex), `0b11111111111111111111` (20 ones, binary), and `1000000` (6 zeros, decimal)?

True order (largest first):

1. $010000000_8 = 8^7 = (2^3)^7 = 2^{21}$
2. $\text{0x100000}_{16} = 2^{20} = 1024^2 > 1000000$
3. $0b\underbrace{1\ldots1}_{20} = 2^{20} - 1 > 1000000$
4. $1000000_{10}$

### Representing Negative Numbers

#### Sign-Magnitude

In mathematics, $-173 = (-1) \cdot 173$. This **sign-magnitude** representation is not ideal for hardware: zero has two representations (+0 and −0), and arithmetic is complicated by the need to handle signs separately.

#### Two's Complement

The **two's complement** of an $N$-bit number is defined as its complement with respect to $2^N$. For an $N$-bit two's complement number $x = (x_{N-1}\, x_{N-2}\, \ldots\, x_0)_2$:

$$x = -x_{N-1} \cdot 2^{N-1} + \sum_{i=0}^{N-2} x_i \cdot 2^i$$

The most significant bit (MSB) acts as the sign bit: 0 for non-negative, 1 for negative.

Example (3-bit two's complement):

| Decimal | Two's comp. |
|---------|-------------|
| −4 | 100 |
| −3 | 101 |
| −2 | 110 |
| −1 | 111 |
| 0 | 000 |
| 1 | 001 |
| 2 | 010 |
| 3 | 011 |

Example: $2^3 - 3 = 1000_2 - 011_2 = 101_2$, which represents −3.

**Exercises:**
- 5-bit two's complement $10101_2$: $-2^4 + 2^2 + 2^0 = -16 + 4 + 1 = -11$.
- 6-bit two's complement $110101_2$: $-2^5 + 2^4 + 2^2 + 2^0 = -32 + 16 + 4 + 1 = -11$.

Note that sign-extending a negative number (prepending 1s) preserves its value.

#### Why Two's Complement?

- **Single zero representation** simplifies equality checking.
- **Arithmetic is transparent** — addition and multiplication work identically for signed and unsigned numbers; the hardware does not need separate circuits.

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
