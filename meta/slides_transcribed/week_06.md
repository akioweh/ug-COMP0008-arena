> Source: [COMP0008\_06\_1.pdf](../slides_original/COMP0008_06_1.pdf), [COMP0008\_06\_2.pdf](../slides_original/COMP0008_06_2.pdf)

# Week 6: Introduction to Concurrency — Executing MIPS Code in a Single-Core Processor

This is the first week of the concurrency half of the module. The overarching theme is **opportunities and perils of modern hardware from the programmer's perspective**. Week 6 focuses on concurrency at the hardware level: how MIPS code executes in a pipelined single-core processor, how memory interaction (especially caching) creates subtle issues, and why these hardware realities matter for software correctness.

**References:** Patterson & Hennessy (P&H) chapters 4–5.

## Module Roadmap (Weeks 6–10)

| Week | Topic | Abstraction level |
|------|-------|-------------------|
| 6 | Executing MIPS code in a single-core processor | Concurrency in hardware |
| 7 | Multi-core processors, threads and concurrency abstraction | Concurrency in software |
| 8 | Threads and thread synchronisation in Java | Concurrency in Java |
| 9 | Java memory model, monitors and conditional synchronisation | Concurrency in Java |
| 10 | Reasoning on correctness of multi-threaded systems | Concurrency in larger applications |

## Course Delivery and Readings

The concurrency half relies on three tiers of material, ordered from deepest/most complete to highest-level/broadest:

1. **Textbooks and essential readings** — the main references for technical content. Essential readings are specified before each week and are required reading before office hours (and recommended before live sessions). "Essential" does not mean "exclusive": students are encouraged to read beyond the essentials. Further readings are posted on Moodle as supplements but are *not* examinable.
2. **Additional material** — extra slides, code, and references to deepen understanding. Non-assessed courseworks provide exercises for exam preparation; students should attempt them independently before solutions are discussed in live sessions.
3. **Live sessions** — review core concepts and offer the lecturer's perspective. Students may request specific topics via the Moodle forum.

All content from essential readings, in-person sessions, and additional material is examinable, with the focus on the ability to *apply* and *build upon* concepts rather than recall specific sentences.

### Textbooks

The main textbook is **Java Concurrency in Practice** by Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David Holmes, and Doug Lea — referred to as **[GPBBHL]** on Moodle and in slides. It is available through the UCL library. Although it references an older version of Java, it covers the core concurrency problems and solutions thoroughly for Java and other object-oriented languages. The Magee–Kramer book is optional (useful for additional code examples).

### Learning Outcomes

The primary goals are to cover the fundamentals of software concurrency and provide future-proof knowledge. All primitives, patterns, idioms, and code examples use Java, but the underpinning principles have broader validity. The module focuses on basic concurrency primitives (e.g. locks); understanding these enables students to learn other constructs and libraries independently in the future.

## From C to MIPS Execution in a Pipelined Processor

### Translating C to MIPS Instructions

Consider the C code:

```c
a = b + e;
c = b + f;
```

Assume all variables reside in memory, addressable as offsets from `$t0`: `b` at `0($t0)`, `e` at `4($t0)`, `f` at `8($t0)`, `a` at `12($t0)`, `c` at `16($t0)`.

To compute `a = b + e` in MIPS: load the two operands into registers, add them, then store the result back to memory. The same procedure applies to `c = b + f`. The full MIPS translation is:

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

**Without pipelining**, the next instruction cannot begin until the previous one has completed all five stages — so each instruction takes 5 cycles and instructions execute sequentially.

**With pipelining**, a new instruction enters the pipeline every clock cycle. While instruction 1 is in its decode stage, instruction 2 is being fetched, and so on. For $n$ instructions, a non-pipelined processor takes $5n$ cycles whereas a pipelined processor takes approximately $n + 4$ cycles (5 cycles for the first instruction, then one additional cycle per subsequent instruction).

### Data Hazards

Pipelining introduces **data hazards** when an instruction depends on the result of a preceding instruction that has not yet completed its write-back.

**Hazard 1 — register dependency resolvable by forwarding:** In the sequence `lw $t1, 0($t0)` → `lw $t2, 4($t0)` → `add $t3, $t1, $t2`, the `add` needs `$t1` in its execute stage (clock cycle 5). At that point, `lw $t1` has just completed its memory stage and the value of `$t1` is available at the output of the DM stage — but it has not yet been written back to the register file. **Forwarding** (also called bypassing) solves this by routing the value directly from the DM output of the first `lw` to the ALU input of the `add`, without waiting for the write-back stage.

**Hazard 2 — load-use hazard requiring a stall:** The `add` also needs `$t2`, which is produced by `lw $t2, 4($t0)`. When the `add` reaches its execute stage, the second `lw` is only in its memory stage — the data has not yet been read from memory. Forwarding cannot help because the value does not exist anywhere in the pipeline yet. The solution is to **stall** the pipeline by inserting a **NOP** (bubble) for one cycle, delaying the `add` so that `$t2` becomes available via forwarding from the DM stage of the second `lw`.

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

Compilers and processors can **reorder instructions** to improve performance — for example, by moving an independent instruction into a NOP slot. In the sequence above, the `lw $t4, 8($t0)` (which loads `f`) does not depend on the result of the `add` or `sw` that precede it, so it could potentially be moved earlier to fill the NOP slot, eliminating the stall. This is a key optimisation technique, but it means the order of instructions as executed may differ from the order written in the source code.

## Interaction with Memory

### The Memory Bottleneck

Pipelining increases instruction throughput, but the bottleneck shifts to **memory access**. Accessing main memory takes on the order of **100 clock cycles** — far too slow for the pipeline, which ideally processes one instruction per cycle. Instructions like `lw` and `sw` that access data memory are particularly affected.

### Caches

The workaround is **caching**: placing a small, fast memory (the cache) between the processor and main memory. Cache access takes approximately **1 clock cycle**, compared to ~100 for main memory.

Caches are fast but expensive and small — they hold only a small subset of main memory. Caching works well because of **locality**:

- **Temporal locality** — recently accessed data is likely to be accessed again soon, so the cache retains copies of recently used data.
- **Spatial locality** — data near recently accessed addresses is likely to be needed soon, so the cache also loads nearby memory locations (a full cache block) on a miss.

**Cache operation:** When the processor needs to load a word, it checks the cache first. On a **cache hit**, the data is returned directly from the cache. On a **cache miss**, the data is fetched from main memory, the cache is updated (with both the missed data and nearby locations), and then the data is returned.

### Cache Internals

A cache is organised into **sets**, each containing one or more **ways** (also called blocks or lines). Each way stores a contiguous block of data from main memory along with metadata.

Each way in a set contains three fields:

- **V (valid bit)** — indicates whether the entry contains valid data.
- **Tag** — the upper bits of the memory address, used to identify which memory block is stored.
- **Data** — the actual cached data (a block of contiguous bytes from memory).

**Address decomposition:** A memory address is split into three fields:

| Tag (upper bits) | Set index (middle bits) | Byte offset (lower bits) |
|---|---|---|
| Identifies which block | Selects the cache set | Selects the byte within the block |

For example, with a 4-set, 2-way cache and the address `110 00 01`: the set index `00` selects Set 0, the tag `110` is compared against the tags stored in both ways of Set 0, and the byte offset `01` selects the specific byte within the matched block.

**Hit detection hardware:** For each way in the selected set, the stored tag is compared with the address tag using a comparator, and the result is ANDed with the valid bit. If either way produces a hit, the corresponding data is selected via a multiplexer and output. The overall hit signal is the OR of the individual way hits.

### Cache Design Decisions

Several design parameters affect cache performance:

- **Dimensioning** — number of sets, number of ways per set (associativity), and block size (data per way).
- **Replacement strategy** — when a new block must be stored in a fully occupied set: Least Recently Used (LRU) vs random, among others.
- **Writing strategy** — when a cached entry is modified: **write-through** (immediately propagate to main memory) vs **write-back** (defer propagation until the cache line is evicted).
- **Number of cache levels** — modern systems typically use three levels (L1, L2, L3), progressively larger and slower as they are farther from the processor.

### Multi-Processor Caches and the Coherence Problem

In a multi-processor system, each processor has its own private cache(s), and all processors share a common shared cache and main memory. This creates a **cache coherence** problem.

Consider four processors with private caches, a shared cache, and main memory. Suppose memory location X initially stores the value 1:

1. At time $t_0$: main memory has $X = 1$.
2. At $t_1$: Processor 1 reads X — its private cache and the shared cache now both hold $X = 1$.
3. At $t_2$: Processor 4 reads X — its private cache also holds $X = 1$.
4. At $t_3$: Processor 1 modifies X to 0 in its private cache.

Now Processor 1's private cache has $X = 0$, but Processor 4's private cache, the shared cache, and main memory all still hold $X = 1$. Processor 4 would read a **stale value** — this is the cache coherence problem.

## Key Lessons

These hardware mechanisms — pipelining, instruction reordering, and caching — yield several fundamental lessons that carry forward into the software concurrency topics of weeks 7–10:

1. **Compilers and processors can re-order operations** to improve execution speed. The programmer cannot assume instructions execute in the order written.
2. **Caching introduces uncertainty** about where the most up-to-date value of a variable is stored at any given time, and hence whether updated values are *visible* to all parts of the system.
3. **Programmers can assume very little** about the actual execution of instructions in hardware.
4. **Hardware concurrency improves performance** (instruction throughput) **but risks affecting correctness** — e.g. reading stale values from registers or caches.
5. **Sometimes performance must be sacrificed for correctness** — by restricting which operations run in parallel.
6. **Synchronisation points** are a general tool for ensuring correctness of concurrent actions — e.g. waiting for an operation to finish (such as writing a register) before performing another that depends on it (such as reading that register).

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
