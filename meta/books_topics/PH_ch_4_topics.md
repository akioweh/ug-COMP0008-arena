# P&H Chapter 4 — The Processor

## 4.1 — Introduction
- Performance factors recap: instruction count, clock cycle time, CPI (brief)
- Chapter roadmap: single-cycle implementation then pipelined implementation of MIPS
- MIPS instruction subset chosen for implementation: lw, sw, add, sub, AND, OR, slt, beq, j
- Overview of instruction execution steps common to all instruction classes (fetch, register read, ALU, memory access, write-back)
- Abstract high-level datapath view (functional units and interconnections)
- Role of multiplexors for data steering between shared resources
- Role of control lines in directing functional units
- Datapath with multiplexors and control unit (Figure 4.2 — detailed diagram)

## 4.2 — Logic Design Conventions
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

## 4.3 — Building a Datapath
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

## 4.4 — A Simple Implementation Scheme
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

## 4.5 — An Overview of Pipelining
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

## 4.6 — Pipelined Datapath and Control
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

## 4.7 — Data Hazards: Forwarding versus Stalling
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

## 4.8 — Control Hazards
- Branch hazard: branch decision not known until MEM stage (3 wasted cycles in base design)
- Assume branch not taken: flush if wrong; discard by zeroing control signals
- Reducing branch delay: move branch resolution to ID stage
  - Branch address calculation moved to ID (adder in ID)
  - Equality test via XOR + OR in ID stage (not full ALU)
  - Additional forwarding to ID-stage comparator
  - Additional stall conditions when branch depends on immediately prior ALU or load result
  - IF.Flush control signal to zero IF/ID register on taken branch
  - Reduces branch penalty to 1 cycle (worked example, Figure 4.62)
- Dynamic branch prediction (detailed):
  - Branch prediction buffer / branch history table: indexed by lower address bits
  - 1-bit predictor: shortcoming with loop branches (worked example — 80% accuracy for 90%-taken branch)
  - 2-bit predictor: finite-state machine with four states (Figure 4.63), must mispredict twice before changing
- Delayed branch: elaboration on scheduling strategies (from before, from target, from fall-through — Figure 4.64)
- Branch delay slot: definition
- Advanced predictors (brief elaboration): correlating predictors, tournament predictors, branch target buffer

## 4.9 — Exceptions
- Exceptions vs interrupts: MIPS terminology (exception = internal, interrupt = external)
- Five example exception types: I/O device request, syscall, arithmetic overflow, undefined instruction, hardware malfunction
- Exception handling in MIPS architecture:
  - EPC register (32-bit, stores address of offending instruction)
  - Cause register (records reason; 5-bit exception code field)
  - Vectored interrupts: different handler addresses per exception type (alternative approach)
  - Non-vectored: single entry point (8000 0180hex in MIPS), OS decodes Cause register
- Exceptions in pipelined implementation (detailed):
  - Treat as another control hazard
  - Flush instructions in IF, ID, EX stages (IF.Flush, ID.Flush, EX.Flush signals)
  - Additional PC mux input for exception handler address (8000 0180hex)
  - EPC and Cause register writes
  - Preventing offending instruction from writing results (EX.Flush zeros WB control)
  - Worked example: arithmetic overflow in add instruction (Figure 4.67, step-by-step pipeline diagrams)
- Multiple simultaneous exceptions: prioritise by earliest instruction
- Precise vs imprecise exceptions: definition; MIPS supports precise exceptions
- Hardware/software contract for exception handling

## 4.10 — Parallelism and Advanced Instruction-Level Parallelism
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

## 4.11 — Real Stuff: the AMD Opteron X4 (Barcelona) Pipeline
- x86 instruction translation to RISC operations (Rops) / micro-operations
- Opteron X4 microarchitecture overview (Figure 4.74):
  - Instruction prefetch, decode, branch prediction
  - RISC-operation queue
  - Dispatch and register renaming (72 physical registers vs 16 architectural)
  - Integer and floating-point operation queues
  - Functional units: 3 integer ALUs (one with multiplier), 3 FP/SSE units
  - Load/store queue, data cache
  - Commit unit
- 12-stage pipeline structure (Figure 4.75): stage breakdown with clock cycle counts
- Register renaming for antidependence elimination and speculation recovery (elaboration)
- Performance bottlenecks: complex x86 instructions, branch mispredictions, long dependences/cache misses, memory access delays

## 4.12 — Advanced Topic: an Introduction to Digital Design Using a Hardware Design Language to Describe and Model a Pipeline and More Pipelining Illustrations
- Hardware description languages for pipeline design (Verilog) — overview only (content on CD)
- Behavioural models of MIPS five-stage pipeline in Verilog
- Additions for forwarding, data hazards, branch hazards
- Additional single-cycle pipeline diagram illustrations

## 4.13 — Fallacies and Pitfalls
- Fallacy: Pipelining is easy (complexity of correct implementation)
- Fallacy: Pipelining ideas can be implemented independent of technology (delayed branches, dynamic scheduling relevance changes with technology)
- Pitfall: Failure to consider instruction set design can adversely impact pipelining (variable-length instructions, complex addressing modes; DEC Alpha vs VAX comparison)

## 4.14 — Concluding Remarks
- Summary: datapath and control design from ISA + technology
- Pipelining improves throughput not latency; multiple issue reduces CPI
- Data and control dependences as fundamental limits
- Historical performance trend: 60%/year from pipelining innovations; power wall leading to multicore and simpler pipelines
