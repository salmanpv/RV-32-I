package Top;
import Types::*;
import RegFile::*;
import ALU::*;
import ImmGen::*;
import Control::*;
import InstrMem::*;
import DataMem::*;

module mkTop(Empty);

   // Instantiate components
   RegFileIfc rf <- mkRegFile;
   ALUIfc     alu <- mkALU;
   ImmGenIfc  immgen <- mkImmGen;
   ControlIfc cu <- mkControl;
   InstrMemIfc imem <- mkInstrMem;
   DataMemIfc dmem <- mkDataMem;

   Reg#(Word) pc <- mkReg(0);

   // helper: decode fields
   function RegIdx get_rd(Bit#(32) instr); return instr[11:7]; endfunction
   function RegIdx get_rs1(Bit#(32) instr); return instr[19:15]; endfunction
   function RegIdx get_rs2(Bit#(32) instr); return instr[24:20]; endfunction
   function Funct3 get_f3(Bit#(32) instr);   return instr[14:12]; endfunction
   function Funct7 get_f7(Bit#(32) instr);   return instr[31:25]; endfunction
   function Bit#(1)  get_instr30(Bit#(32) instr); return instr[30]; endfunction

   // ALU-control generator
   function ALUOp alu_ctrl(Bit#(2) aluOpSel, Funct3 f3, Funct7 f7, Bit#(1) i30);
      ALUOp op = ALU_ADD;
      if (aluOpSel == 0) begin
         op = ALU_ADD; // for load/store
      end else if (aluOpSel == 1) begin
         op = ALU_SUB; // branches use subtract to set zero/lt
      end else if (aluOpSel == 2) begin // R-type
         case (f3)
            3'b000: op = (f7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
            3'b001: op = ALU_SLL;
            3'b010: op = ALU_SLT;
            3'b011: op = ALU_SLTU;
            3'b100: op = ALU_XOR;
            3'b101: op = (i30 == 1) ? ALU_SRA : ALU_SRL;
            3'b110: op = ALU_OR;
            3'b111: op = ALU_AND;
            default: op = ALU_ADD;
         endcase
      end else if (aluOpSel == 3) begin // I-type ALU immediate
         case (f3)
            3'b000: op = ALU_ADD;
            3'b001: op = ALU_SLL;
            3'b010: op = ALU_SLT;
            3'b011: op = ALU_SLTU;
            3'b100: op = ALU_XOR;
            3'b101: op = (i30 == 1) ? ALU_SRA : ALU_SRL;
            3'b110: op = ALU_OR;
            3'b111: op = ALU_AND;
            default: op = ALU_ADD;
         endcase
      end
      return op;
   endfunction

   // Store only the registers we need to monitor
   Reg#(Word) debug_x5 <- mkReg(0);
   Reg#(Word) debug_x6 <- mkReg(0);
   Reg#(Word) debug_x7 <- mkReg(0);

   // Counter to track number of instructions executed
   Reg#(Bit#(32)) instruction_count <- mkReg(0);

   rule step;
      Bit#(32) cur_pc = pc;
      Bit#(32) instr = imem.read(cur_pc);
      
      // Stop after executing 10 instructions (enough for our test + some buffer)
      if (instruction_count >= 25) begin
         $display("=== Test Complete ===");
         //$display("Executed %0d instructions", instruction_count);
         $display("Final values: x5=%0d, x6=%0d, x7=%0d", debug_x5, debug_x6, debug_x7);
         $finish;
      end
   
      instruction_count <= instruction_count + 1;
   
      Opcode opcode = instr[6:0];
      RegIdx rd = get_rd(instr);
      RegIdx rs1 = get_rs1(instr);
      RegIdx rs2 = get_rs2(instr);
      Funct3 f3 = get_f3(instr);
      Funct7 f7 = get_f7(instr);
      Bit#(1) i30 = get_instr30(instr);

      // control + immed
      Ctrl ctrl = cu.decode(opcode);
      Word imm = immgen.gen(instr);

      // read registers
      Word v1 = rf.read1(rs1);
      Word v2 = rf.read2(rs2);

      // ALU input B
      Word alu_b = ctrl.aluSrc ? imm : v2;

      // compute ALU op code
      ALUOp aop = alu_ctrl(ctrl.aluOp, f3, f7, i30);
      Word alu_out = alu.exec(aop, v1, alu_b);
      Bool zero = alu.zero(alu_out);
      Bool slt_s = alu.slt_signed(v1, alu_b);
      Bool slt_u = alu.slt_u(v1, alu_b);

      // branch condition
      Bool branch_taken = False;
      if (ctrl.branch) begin
         case (f3)
            3'b000: branch_taken = zero;          // BEQ
            3'b001: branch_taken = !zero;         // BNE
            3'b100: branch_taken = slt_s;         // BLT
            3'b101: branch_taken = !slt_s;        // BGE
            3'b110: branch_taken = slt_u;         // BLTU
            3'b111: branch_taken = !slt_u;        // BGEU
            default: branch_taken = False;
         endcase
      end

      // compute next PC
      Bit#(32) next_pc;
      if (ctrl.jump) begin
         if (opcode == 7'b1101111) begin // JAL
            next_pc = cur_pc + imm;
         end else begin // JALR
            next_pc = (v1 + imm) & ~1;
         end
      end else if (branch_taken) begin
         next_pc = cur_pc + imm;
      end else begin
         next_pc = cur_pc + 4;
      end

      // memory accesses
      Word mem_r = 0;
      if (ctrl.memRead) begin
         mem_r = dmem.read(alu_out);
      end
      if (ctrl.memWrite) begin
         dmem.write(alu_out, v2);
      end

      // write-back selection
      Word wb = ctrl.memToReg ? mem_r :
                (ctrl.jump ? (cur_pc + 4) : alu_out);

      // register write
      if (ctrl.regWrite) begin
         rf.write(rd, wb);
      end

      // update PC register
      pc <= next_pc;

      // Store only the debug values we need to monitor
      debug_x5 <= rf.read1(5);
      debug_x6 <= rf.read1(6);
      debug_x7 <= rf.read1(7);

      // --- Only display the 3 registers ---
      $display("  x5=%0d, x6=%0d, x7=%0d", debug_x5, debug_x6, debug_x7);
      $display(""); // Empty line for readability
   endrule

endmodule
endpackage
