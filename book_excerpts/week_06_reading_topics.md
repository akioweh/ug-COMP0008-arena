# Week 6 — Reading Topics

## Essential readings

**P&H 4.1 — Introduction**
- Performance factors recap: instruction count, clock cycle time, CPI (brief)
- Chapter roadmap: single-cycle implementation then pipelined implementation of MIPS
- MIPS instruction subset chosen for implementation: lw, sw, add, sub, AND, OR, slt, beq, j
- Overview of instruction execution steps common to all instruction classes (fetch, register read, ALU, memory access, write-back)
- Abstract high-level datapath view (functional units and interconnections)
- Role of multiplexors for data steering between shared resources
- Role of control lines in directing functional units
- Datapath with multiplexors and control unit (Figure 4.2 — detailed diagram)

**P&H 4.5 — An Overview of Pipelining**
- Pipelining definition and laundry analogy (detailed, with figures)
- Pipelining improves throughput, not individual instruction latency
- Speed-up formula: ideally equal to number of pipeline stages
- Imperfectly balanced stages reduce speed-up
- Five classic MIPS pipeline stages: IF, ID, EX, MEM, WB (with timing example)
- Single-cycle vs pipelined performance comparison (worked example with specific latencies)
- Designing instruction sets for pipelining: why MIPS is pipeline-friendly (fixed-length instructions, few formats, load/store architecture, aligned memory operands)
- Pipeline hazards — three types:
  - Structural hazards: definition, example (single shared memory)
  - Data hazards: definition, dependence between instructions
  - Control hazards (branch hazards): definition
- Forwarding (bypassing): concept, graphical representation, resolves most data hazards (detailed with worked example)
- Load-use data hazard: forwarding cannot fully resolve; requires one stall cycle (pipeline bubble)
- Reordering code to avoid pipeline stalls (worked example with C-to-MIPS code scheduling)
- Control hazard solutions:
  - Stall on branch (with CPI impact example)
  - Assume branch not taken (predict not taken)
  - Branch prediction: static and dynamic (introduction only)
  - Delayed branch (elaboration)
- Pipeline latency vs throughput distinction

**P&H 5.1 — Introduction**
- Principle of locality (temporal locality, spatial locality) — formal definitions
- Memory hierarchy concept and motivation
- Memory technology comparison: SRAM, DRAM, magnetic disk (access time, cost per GB)
- Hierarchy structure: upper/lower levels, blocks/lines
- Hit, miss, hit rate, miss rate — definitions
- Hit time, miss penalty — definitions
- Block (line) as the unit of transfer between levels
- Inclusion property (data at level i also present at level i+1)

**P&H 5.2 — The Basics of Caches**
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

**P&H 5.3 — Measuring and Improving Cache Performance**
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

## Further readings

**P&H 4.2 — Logic Design Conventions**
- Combinational elements vs state elements (definitions and distinction)
- Examples: ALU as combinational; registers, instruction/data memory as state elements
- D-type flip-flop as basic state element
- Sequential logic: outputs depend on inputs and internal state
- Signal assertion/deassertion conventions
- Clocking methodology: definition and purpose
- Edge-triggered clocking methodology (detailed): state updates only on clock edge
- Read-and-write same register in one cycle (edge-triggered allows it without race)
- Control signals vs data signals
- Bus conventions and notation in datapath diagrams

**P&H 4.3 — Building a Datapath**
- Datapath element: definition
- Instruction memory and program counter (PC) as state elements
- Adder for PC + 4 (incrementing PC)
- Instruction fetch datapath (combining instruction memory, PC, adder)
- Register file structure: two read ports, one write port, 5-bit register number inputs, 32-bit data buses, RegWrite control (detailed)
- ALU: two 32-bit inputs, 32-bit result, Zero output, 4-bit ALU operation control
- R-format instruction datapath requirements
- Load/store instruction datapath requirements: sign-extend unit (16-to-32 bit), data memory unit (MemRead, MemWrite controls)
- Branch (beq) datapath: branch target address computation (sign-extended offset, shift left 2, adder), equality test via ALU subtraction and Zero output
- Branch taken vs branch not taken
- Jump instruction: concatenation of PC+4 upper bits with shifted 26-bit immediate
- Delayed branch concept (brief mention in elaboration)
- Creating a single combined datapath: sharing resources via multiplexors and control signals (detailed, with worked example)

**P&H 4.4 — A Simple Implementation Scheme**
- Single-cycle implementation: definition and approach
- ALU control design (detailed with truth tables):
  - 4-bit ALU control input mapped from 2-bit ALUOp + 6-bit funct field
  - Multi-level decoding approach (ALUOp from main control, then ALU control unit)
  - Truth table with don't-care terms for ALU control (Figure 4.13)
- Main control unit design (detailed):
  - MIPS instruction formats reviewed: R-type, load/store (I-type), branch, jump
  - Opcode field (bits 31:26) as sole input to main control
  - Seven 1-bit control signals: RegDst, RegWrite, ALUSrc, PCSrc, MemRead, MemWrite, MemtoReg
  - Effect of each control signal when asserted/deasserted (Figure 4.16)
  - Control signal settings per instruction type (Figure 4.18 truth table)
- Operation of the datapath traced for R-type, load, store, and branch-on-equal (step-by-step with diagrams)
- Finalizing control: complete truth table (Figure 4.22)
- Implementing the jump instruction: additional multiplexor and Jump control signal (worked example)
- Why single-cycle implementation is not used today: clock cycle determined by slowest instruction (load), violates "make common case fast"

**P&H 4.6 — Pipelined Datapath and Control**
- Mapping single-cycle datapath to five pipeline stages (detailed)
- Pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB — purpose and widths
- Right-to-left data flow: write-back to register file, PC selection (sources of data/control hazards)
- Detailed walk-through of load instruction through all five stages (with datapath diagrams per stage)
- Detailed walk-through of store instruction through all five stages
- Bug discovery: write register number must be forwarded through pipeline registers to WB stage (corrected datapath)
- Graphical representations of pipelines:
  - Multiple-clock-cycle pipeline diagrams
  - Single-clock-cycle pipeline diagrams
- Pipelined control (detailed):
  - Control signals grouped by pipeline stage (EX, MEM, WB)
  - Control information generated in ID stage, stored in pipeline registers, forwarded through stages
  - Full pipelined datapath with control (Figure 4.51)

**P&H 4.7 — Data Hazards: Forwarding versus Stalling**
- Data dependences in instruction sequences (detailed example with sub/and/or/add/sw)
- Pipeline register field notation (e.g., EX/MEM.RegisterRd, ID/EX.RegisterRs)
- Hazard detection conditions:
  - EX hazard (1a, 1b): EX/MEM.RegisterRd vs ID/EX source registers
  - MEM hazard (2a, 2b): MEM/WB.RegisterRd vs ID/EX source registers
- Dependence detection worked example
- Forwarding unit design (detailed):
  - ForwardA / ForwardB mux control signals (3-input muxes: 00, 10, 01)
  - Conditions for EX hazard forwarding and MEM hazard forwarding (with $0 exclusion)
  - Double data hazard: priority to more recent (EX/MEM over MEM/WB)
  - Forwarding unit hardware (Figure 4.54, 4.56)
- Signed-immediate input mux for ALU (elaboration, Figure 4.57)
- Load-use data hazard detection and stalling (detailed):
  - Hazard detection unit: operates in ID stage
  - Condition: ID/EX.MemRead and destination matches source
  - Stall mechanism: freeze PC and IF/ID register, insert nop (bubble) by zeroing EX/MEM/WB control signals
  - Pipeline execution with stall (Figure 4.59)
- Combined forwarding unit and hazard detection unit (Figure 4.60)

**P&H 4.10 — Parallelism and Advanced Instruction-Level Parallelism**
- Instruction-level parallelism (ILP): definition
- Two methods to increase ILP: deeper pipelines, multiple issue
- Multiple issue: definition; CPI < 1, IPC metric
- Static multiple issue vs dynamic multiple issue (overview)
- Issue slots, issue packets
- Speculation: concept (compiler or hardware guesses instruction properties to enable more parallelism)
  - Recovery mechanisms: compiler fix-up routines vs hardware buffer flushing
  - Speculative exceptions
- Static multiple issue / VLIW (detailed):
  - Example: two-issue MIPS (one ALU/branch + one load/store per cycle)
  - Instruction pairing and alignment constraints
  - Additional hardware: extra register ports, separate adder for address calculation (Figure 4.69)
  - Use latency increase in multiple-issue context
  - Code scheduling for static two-issue (worked example)
  - Loop unrolling for multiple-issue pipelines (worked example with 4x unroll)
  - Register renaming by compiler: eliminating antidependences (name dependences) vs true dependences
- Dynamic multiple issue / superscalar processors (detailed):
  - Dynamic pipeline scheduling: in-order issue, out-of-order execute, in-order commit
  - Three-unit model: instruction fetch/decode, functional units with reservation stations, commit unit with reorder buffer (Figure 4.72)
  - Reservation stations and reorder buffer provide register renaming
  - Out-of-order execution: definition
  - Hardware-based speculation on branch outcomes and load addresses
- Why dynamic scheduling despite compilers: unpredictable cache misses, interaction with dynamic branch prediction, binary compatibility across implementations
- Performance limits of ILP: dependences, branch mispredictions, memory system stalls
- Power efficiency and advanced pipelining: deeper/wider pipelines less power-efficient; trend towards simpler cores in multicore designs (Figure 4.73 — historical data)
