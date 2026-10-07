# Humanized Rewrites — Research Paper Sections

> [!IMPORTANT]
> Each section below is a drop-in replacement for the corresponding section in your paper. The technical content, terminology, and factual claims are unchanged — only the sentence structure, flow, and voice have been reworked to read as naturally human-written academic prose.

---

## Section 1 — III.A Overall Architecture + III.B Processor Datapath and RTL Modules

### A. Overall Architecture

We designed the proposed processor as a custom, modular 8-bit RISC architecture written entirely in Verilog HDL. It is aimed at embedded and educational use cases, but more broadly it serves to demonstrate a full hardware development methodology — from RTL design and functional verification through to FPGA and ASIC implementation. The processor adopts a single-cycle execution model: every instruction goes through fetch, decode, execute, and write-back within a single clock cycle, which keeps both the control structure and overall hardware complexity manageable.

Eight functional modules form the processor datapath — a Program Counter (PC), Instruction Memory, Instruction Decoder, Control Unit, Register File, ALU, Execute Unit, and Data Memory. During operation, the PC generates sequential addresses that index into the Instruction Memory. Once an instruction is fetched, the Instruction Decoder separates out the opcode, source and destination register fields, and the immediate operand. From there, the Control Unit uses the decoded opcode to assert the appropriate control signals for arithmetic, logical, memory, and branch operations. The Register File feeds operands into the ALU, while the Execute Unit ties together the computation, memory access, and write-back stages. Load and store operations are handled through the Data Memory. Organizing the design this way means that each module can be verified on its own, and future enhancements — such as adding new instructions or a pipeline — can be introduced with relatively localized changes.

Beyond the core datapath, the architecture also includes a runtime workload monitoring (RWM) module paired with an adaptive clock management (ACM) mechanism. The RWM module watches the stream of executed instructions and, over a predefined observation window, categorizes processor activity into one of three classes: arithmetic-intensive, memory-intensive, or branch-intensive. This classification feeds into an adaptive clock divider that adjusts the clock division ratio accordingly, and a companion clock gating controller selectively enables or disables hardware blocks to cut down on unnecessary switching. Together, these two additions bring workload-aware adaptation into the design without meaningfully increasing its architectural complexity.

### B. Processor Datapath and RTL Modules

The datapath is structured so that each functional block handles a specific aspect of instruction execution. This separation improves code readability, makes verification more straightforward, and allows individual modules to be developed in parallel. Collectively, the datapath covers arithmetic, logical, immediate, memory-access, branch, and shift operations, all while keeping hardware utilization low. Because the design is modular, future extensions — pipelining, peripheral integration, support for additional instructions — can be incorporated without requiring sweeping changes to the existing RTL.

**1) Instruction Set Architecture:** A custom 16-bit fixed-width ISA was devised to suit a lightweight single-cycle RISC processor. The fixed instruction width was a deliberate choice, as it simplifies the fetch and decode stages and reduces the complexity of control-signal generation. The datapath itself operates on 8-bit data, and the processor provides eight general-purpose registers, each addressed by a 3-bit field. Register R0 is hardwired to zero — a common convention that streamlines certain instruction encodings. As listed in Table I, the ISA includes arithmetic instructions (ADD, SUB), logical instructions (AND, OR, XOR), immediate-type instructions (ADDI, SUBI, LI), memory instructions (LOAD, STORE), a conditional branch (BEQ), and shift instructions (SLL, SRL). This instruction mix was selected to offer adequate computational capability without compromising architectural simplicity.

**2) Program Counter:** The PC is realized as an 8-bit synchronous register that holds the address of the current instruction. Under normal execution it simply increments to point to the next instruction; when a branch is taken, it loads the computed target address instead. On reset, the PC is initialized to zero so that startup behavior is deterministic.

**3) Instruction Memory:** Instruction Memory takes the form of a 16-entry array, where each entry holds a 16-bit instruction word addressed by the current PC value. Because the instruction format is fixed, the decoder logic can be kept simple and the control path remains compact.

**4) Instruction Decoder:** The Instruction Decoder is responsible for pulling apart the fetched instruction into its constituent fields — opcode, source and destination register addresses, and the immediate operand. These fields are then routed to the Control Unit, the Register File, and the RWM module. Keeping the decoding logic separate from the control logic was an intentional design decision: it improves modularity and makes it easier to extend the instruction set in the future without disturbing the rest of the pipeline.

---

## Section 2 — V. ASIC Implementation (A through E)

### A. ASIC Design Flow

To assess the processor beyond its FPGA realization, we carried the same RTL through a standard-cell ASIC flow. Cadence Genus handled RTL synthesis, and Cadence Innovus was used for the subsequent physical implementation [8]. The flow progressed through RTL synthesis, technology mapping, floorplanning, power-network construction, cell placement, Clock Tree Synthesis (CTS), routing, and post-route timing analysis. Each stage produced quantitative metrics — area, timing margins, cell utilization, and power estimates — that together characterize the processor's physical realization in silicon.

### B. RTL Synthesis

Cadence Genus was used to synthesize the Verilog RTL into a gate-level netlist mapped to the target standard-cell library. During this step, the tool performed logic optimization to translate the arithmetic, control, and memory operations into technology-specific cells while respecting the applied timing constraints. The synthesis reports — covering standard-cell count, total area, slack, and estimated power — served as the starting point for the physical design stages that followed in Cadence Innovus.

### C. Floorplanning and Power Planning

Once the synthesized netlist was brought into Cadence Innovus, floorplanning was the first order of business. We defined the core area dimensions and placement boundaries, set a target utilization, and made sure enough routing resources were reserved to avoid congestion later on. Power planning followed: dedicated power and ground networks were laid out across the core to minimize IR drop and maintain stable supply voltages during operation. The final floorplan struck a balance between area efficiency and routing feasibility.

### D. Placement and Clock Tree Synthesis

With the floorplan established, standard-cell placement mapped each synthesized logic cell to a physical location inside the core region. The placement engine worked to minimize total wirelength while honoring timing constraints. After placement, Clock Tree Synthesis was run to distribute the clock signal evenly across the design. CTS automatically inserted clock buffers and routed the clock network in a way that controls skew and guarantees reliable clock delivery to every synchronous element.

### E. Routing and Physical Verification

The final physical step involved global and detailed routing, which created the metal interconnections between placed cells in compliance with the foundry's design rules. Post-route timing analysis then checked that all setup and hold requirements were satisfied. The Innovus-generated reports — covering routing quality, cell utilization, layout area, and timing margins — confirmed that the ASIC implementation was successful and provided the quantitative data used for comparison with the FPGA results in Section VI.

---

## Section 3 — Design Insights (partial) + VI.F Discussion

### (Design Insights — continued)

One notable outcome is that the RWM module can classify workloads at the instruction level using nothing more than the already-decoded opcode — no additional monitoring hardware is needed, yet the information it provides is sufficient to drive the adaptive clock management logic. Equally encouraging, the adaptive clock divider and clock gating circuitry integrated cleanly into the design without compromising functional correctness, which suggests that lightweight runtime adaptation is a realistic option even for small embedded processors carrying minimal architectural overhead.

Implementing the same RTL on both the PYNQ-Z2 FPGA and through the Cadence ASIC flow gave us confidence in the architecture's portability. The FPGA platform enabled fast functional verification and interactive debugging, while the ASIC flow yielded concrete numbers for silicon area, timing closure, and power consumption. Taken together, these two implementations establish a solid foundation for future work — whether that involves adding a pipeline, integrating a cache, incorporating interrupt handling, or connecting peripheral interfaces.

### F. Discussion

Across all three implementation stages, the architecture maintained functional correctness. RTL simulation confirmed that arithmetic, logical, memory, and branch instructions execute as intended; the FPGA implementation demonstrated that the design works in real hardware; and the Cadence Genus–Innovus ASIC flow showed that it is both synthesizable and physically realizable through an industry-standard backend process.

What sets this work apart from prior lightweight processor designs is that it brings runtime workload monitoring and adaptive clock management together within a single-cycle architecture. The opcode-based classification approach gives designers a straightforward, modular way to observe processor activity — there is no need for complex performance-monitoring units with extensive counter arrays. The workload information that the RWM produces is then directly consumed by the ACM module, enabling workload-aware clock behavior at very low implementation cost.

We chose the single-cycle model deliberately, as it simplifies both the hardware realization and the verification effort. This choice did mean setting aside more advanced features — pipelining, cache memory, interrupt support, peripheral interfaces, and fine-grained dynamic power management — but those were intentionally left out to keep the scope focused. That said, the modular nature of the architecture means it can readily accommodate these capabilities in future iterations of the processor.

---

## Section 4 — VII. Conclusion

### VII. Conclusion

In this paper, we presented the design, implementation, and evaluation of a custom 8-bit single-cycle RISC processor that incorporates both Runtime Workload Monitoring and Adaptive Clock Management. The processor was developed using a modular RTL approach in Verilog HDL and supports arithmetic, logical, memory, branch, and immediate instructions through a custom 16-bit ISA. Its RWM module classifies runtime instruction patterns based on the executed opcode, and the ACM unit uses that classification to adjust the processor's clock behavior in real time.

We verified the architecture through RTL simulation and then implemented it on a Xilinx PYNQ-Z2 FPGA using Vivado, where correct hardware operation was confirmed through onboard switches and an LED-based debugging interface. The same RTL was subsequently synthesized and physically implemented through the Cadence Genus and Cadence Innovus ASIC flow, where timing closure was achieved and quantitative area and power figures were obtained. Carrying the design through both an FPGA and an ASIC flow demonstrates the architecture's portability and validates the end-to-end RTL-to-hardware methodology we adopted.

Taken as a whole, this work delivers a compact yet extensible processor architecture that pairs modular RTL design with lightweight, workload-aware clock management. It provides a practical starting point for further research into adaptive embedded processors and shows that even simple runtime-adaptation techniques can be meaningfully applied in resource-constrained designs.
