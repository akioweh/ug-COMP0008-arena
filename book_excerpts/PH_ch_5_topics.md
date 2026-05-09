# P&H Chapter 5 — Large and Fast: Exploiting Memory Hierarchy

## 5.1 — Introduction
- Principle of locality (temporal locality, spatial locality) — formal definitions
- Memory hierarchy concept and motivation
- Memory technology comparison: SRAM, DRAM, magnetic disk (access time, cost per GB)
- Hierarchy structure: upper/lower levels, blocks/lines
- Hit, miss, hit rate, miss rate — definitions
- Hit time, miss penalty — definitions
- Block (line) as the unit of transfer between levels
- Inclusion property (data at level i also present at level i+1)

## 5.2 — The Basics of Caches
- Cache concept and origin of the term
- Direct-mapped cache — definition and block placement via modulo
- Tag field, index field, valid bit — purpose and sizing
- Address decomposition for a direct-mapped cache (tag, index, byte offset, block offset)
- Calculating total cache bits (data + tag + valid overhead) — worked examples
- Mapping addresses to multiword cache blocks — worked example
- Block size vs. miss rate tradeoff (spatial locality benefit vs. increased miss penalty)
- Early restart and critical-word-first techniques (brief)
- Handling cache misses: steps for instruction cache miss (stall, fetch, write entry, restart)
- Handling writes: write-through vs. write-back — detailed comparison
- Write buffer — purpose and stall conditions
- Write-allocate vs. no-write-allocate policies (brief)
- Store buffer for write-back caches (brief)
- Example cache: Intrinsity FastMATH processor (16 KB I/D caches, 16-word blocks, direct-mapped, split I/D caches)
- Split cache (separate instruction and data caches) vs. unified cache — tradeoffs
- Designing the memory system to support caches: one-word-wide, wider memory, interleaved memory banks
- Miss penalty calculation for different memory organisations — worked examples
- DRAM burst mode and DDR (Double Data Rate)
- DRAM density, cost, access time trends (historical table 1980--2007)

## 5.3 — Measuring and Improving Cache Performance
- CPU time formula decomposed into execution cycles and memory-stall cycles
- Memory-stall cycles: read-stall cycles, write-stall cycles, write buffer stalls — formulas
- Calculating cache performance impact on CPI — detailed worked example
- Amdahl's law applied to memory stalls (faster processor amplifies memory bottleneck)
- Average memory access time (AMAT) — formula and worked example
- Reducing cache misses via flexible block placement:
  - Fully associative cache — definition, parallel tag comparison
  - Set-associative cache (n-way) — definition, index selects set, search within set
  - Direct-mapped as 1-way; fully associative as m-way — unifying view
- Miss rate vs. associativity (data for 64 KB cache, 1-way through 8-way) — quantitative
- Locating a block: address decomposition (tag, index, block offset) for set-associative caches
- Hardware for set-associative caches: comparators, multiplexor, Content Addressable Memory (CAM)
- Choosing which block to replace: Least Recently Used (LRU) — definition and implementation cost
- Tag bits vs. set associativity — worked example (4K blocks, 4-word blocks, 32-bit address)
- Reducing miss penalty via multilevel caches — detailed worked example (L1 + L2, local vs. global miss rate)
- Design considerations for primary vs. secondary cache (hit time vs. miss rate focus)
- Cache-awareness in algorithms: Quicksort vs. Radix Sort cache behaviour comparison — detailed with data
- Autotuning for cache-varying architectures (brief mention)

## 5.4 — Virtual Memory
- Virtual memory motivation: sharing/protection among multiple programs; removing size limitation
- Overlays (historical context)
- Pages, page faults — definitions
- Virtual address, physical address, address translation/mapping — definitions
- Page offset and virtual page number; mapping virtual to physical page number
- Why fully associative placement for pages (high miss penalty justifies software-managed flexibility)
- Large page sizes to amortise disk access time
- Write-back required (disk writes too slow for write-through)
- Page faults handled in software (OS)
- Segmentation vs. paging (brief comparison)
- Page table — definition, structure, indexing by virtual page number
- Page table register; process state and context switching
- Valid bit in page table entries
- Page faults: OS handling steps (find on disk, choose replacement, read from disk)
- Swap space — definition
- LRU page replacement and reference bit (use bit) approximation
- Dirty bit for tracking modified pages
- Page table size calculation and reduction techniques:
  - Limit register
  - Two-segment scheme (stack/heap)
  - Inverted page table
  - Multilevel page tables
  - Paging the page tables
- Translation-Lookaside Buffer (TLB) — definition, role as cache for page table entries
- TLB typical parameters (size, hit time, miss penalty, miss rate)
- TLB associativity choices (fully associative vs. set-associative)
- Intrinsity FastMATH TLB — detailed example (16 entries, fully associative, 4 KB pages, 32-bit address)
- Integrating TLB, page table, and cache — flowchart for read/write processing
- Possible combinations of TLB/page-table/cache hit/miss — worked example (7 combinations)
- Physically indexed/tagged vs. virtually indexed/tagged caches; aliasing problem
- Implementing protection with virtual memory:
  - User mode vs. supervisor (kernel) mode
  - System call (syscall), return from exception (ERET)
  - Page table in OS address space; write-access bits
  - Process isolation via separate page tables
  - Sharing pages between processes
- Context switch and TLB flushing; address space ID (ASID) — brief
- Handling TLB misses and page faults:
  - TLB miss handler (MIPS code — 5 instructions)
  - MIPS coprocessor 0 registers (EPC, Cause, BadVAddr, Index, Random, EntryLo, EntryHi, Context)
  - Exception handler: save/restore state (MIPS assembly — detailed code listing)
  - Restartable instructions
  - Enabling/disabling exceptions during handler
  - Unmapped memory region for exception code
- Page fault handling steps (OS: look up disk location, choose victim, initiate disk read, context switch)
- Thrashing and working set — definitions
- Variable page sizes (MIPS supports 4 KB to 256 MB)

## 5.5 — A Common Framework for Memory Hierarchies
- Quantitative comparison table: L1 cache, L2 cache, paged memory, TLB (size, block size, miss penalty, miss rate)
- Four key questions for any memory hierarchy level:
  1. Where can a block be placed? (direct-mapped, set-associative, fully associative — table)
  2. How is a block found? (indexing, limited search, full search, separate lookup table — table)
  3. Which block is replaced on a miss? (random vs. LRU; cost tradeoffs)
  4. What happens on a write? (write-through vs. write-back; advantages of each)
- Miss rate vs. associativity for various cache sizes — quantitative graph
- Three Cs model of cache misses:
  - Compulsory (cold-start) misses — definition; reduced by larger blocks
  - Capacity misses — definition; reduced by larger cache
  - Conflict (collision) misses — definition; reduced by higher associativity
- Miss rate decomposition graph (compulsory, capacity, conflict components vs. cache size)
- Design tradeoffs summary table (cache size, associativity, block size vs. miss rate and access time)

## 5.6 — Virtual Machines
- Virtual machine (VM) concept and motivation (isolation, security, reliability, sharing, hardware speed)
- System virtual machines — definition (same-ISA guest/host)
- Virtual machine monitor (VMM) / hypervisor — definition and role
- Host vs. guest terminology
- Benefits: managing software (legacy OS, testing); managing hardware (server consolidation, live migration)
- Virtualisation overhead: user-level vs. I/O-intensive vs. I/O-bound workloads
- Requirements of a VMM: guest transparency, resource protection
- Hardware support: dual privilege modes, privileged instruction trapping, system call mechanism
- ISA support for virtualisation (virtualizable architectures, e.g. IBM 370)
- Problems with non-virtualizable ISAs (x86, MIPS, ARM) — 18 problematic x86 instructions listed
- Intel VT-x and AMD Pacifica extensions (brief)
- Paravirtualisation (Xen) as software alternative
- Virtualising virtual memory: shadow page tables; nested/extended page tables (brief)
- Virtualising I/O (brief)

## 5.7 — Using a Finite-State Machine to Control a Simple Cache
- Simple cache specification: direct-mapped, write-back with write-allocate, 4-word blocks, 16 KB, 32-bit addresses
- Processor-to-cache interface signals; cache-to-memory interface signals (128-bit data width)
- Blocking cache concept
- Finite-state machine (FSM) review: states, next-state function, outputs; Moore vs. Mealy machines
- FSM implementation with state register and combinational logic
- Four-state cache controller FSM:
  - Idle
  - Compare Tag (hit/miss detection, read/write handling)
  - Write-Back (dirty block eviction to memory)
  - Allocate (fetch new block from memory)
- Possible extensions: split compare/access, write buffer optimisation

## 5.8 — Parallelism and Memory Hierarchies: Cache Coherence
- Cache coherence problem in multiprocessors sharing physical address space
- Coherence definition (three properties): program order, visibility of writes, write serialisation
- Consistency vs. coherence distinction
- Migration and replication of shared data — definitions
- Cache coherence protocols — concept
- Snooping protocol — concept (broadcast medium, all caches monitor bus)
- Write-invalidate protocol — mechanism and example (detailed table: two CPUs, read/write sequence)
- False sharing — definition and impact of block size
- Memory consistency model (brief): write completion visibility, write ordering assumptions
- Directory-based coherence (brief mention as alternative to snooping)

## 5.9 — Advanced Material: Implementing Cache Controllers
- (On CD) Cache controller implementation in hardware description language
- Cache coherence protocol implementation details

## 5.10 — Real Stuff: the AMD Opteron X4 (Barcelona) and Intel Nehalem Memory Hierarchies
- Intel Nehalem die photo and component layout (four cores, L1/L2/L3 caches, on-chip memory controller)
- AMD Opteron X4 die photo
- Address sizes and TLB organisation comparison table (Nehalem vs. Opteron X4): virtual/physical address bits, page sizes, TLB levels/associativity/entries
- Cache hierarchy comparison table (L1/L2/L3): size, associativity, block size, write policy, hit time, replacement policy
- CPI and miss rate data for Opteron X4 on SPECint2006 benchmarks (detailed table)
- Miss penalty reduction techniques:
  - Critical-word-first / early restart
  - Nonblocking cache (hit under miss, miss under miss)
  - Hardware prefetching (instruction and data)
  - Multiported / banked caches for multiple accesses per cycle
- Inclusion vs. exclusion policies (Nehalem inclusive; AMD exclusive with victim caches)

## 5.11 — Fallacies and Pitfalls
- Pitfall: forgetting byte addressing or block size when simulating caches — worked example
- Pitfall: ignoring memory system behaviour when writing programs (matrix multiply loop order; blocking optimisation)
- Pitfall: insufficient set associativity for shared cache relative to number of cores
- Pitfall: using AMAT to evaluate out-of-order processor memory hierarchy
- Pitfall: extending address space by adding segments on top of unsegmented space (x86 history)
- Pitfall: implementing VMM on non-virtualizable ISA (x86 problematic instructions — 18 listed; Intel VT-x / AMD Pacifica; paravirtualisation/Xen)

## 5.12 — Concluding Remarks
- Locality as the fundamental enabler of memory hierarchy performance
- Multilevel caches and their design flexibility
- Software optimisations: loop restructuring for locality, prefetching, cache-aware instructions
- Memory systems as central design issue for parallel processors
