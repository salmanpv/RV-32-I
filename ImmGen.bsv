package ImmGen;
import Types::*;

interface ImmGenIfc;
   method Word gen(Bit#(32) instr);
endinterface

module mkImmGen(ImmGenIfc);
   method Word gen(Bit#(32) instr);
      Opcode op = instr[6:0];
      Word imm = 0;

      // I-type (addi, loads, jalr)
      if (op == 7'b0010011 || op == 7'b0000011 || op == 7'b1100111) begin
         imm = signExtend(instr[31:20]);
      end
      // S-type (store)
      else if (op == 7'b0100011) begin
         Bit#(12) simm = {instr[31:25], instr[11:7]};
         imm = signExtend(simm);
      end
      // B-type (branch)
      else if (op == 7'b1100011) begin
         Bit#(13) bimm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
         imm = signExtend(bimm);
      end
      // U-type (LUI/AUIPC)
      else if (op == 7'b0110111 || op == 7'b0010111) begin
         imm = { instr[31:12], 12'b0 };
      end
      // J-type (JAL)
      else if (op == 7'b1101111) begin
         Bit#(21) jimm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
         imm = signExtend(jimm);
      end
      else imm = 0;
      return imm;
   endmethod
endmodule

endpackage
