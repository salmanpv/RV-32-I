package Control;
import Types::*;

typedef struct {
   Bool regWrite;
   Bool memRead;
   Bool memWrite;
   Bool memToReg;
   Bool aluSrc;
   Bool branch;
   Bool jump;
   Bit#(2) aluOp;
} Ctrl deriving (Bits, Eq);

interface ControlIfc;
   method Ctrl decode(Opcode op);
endinterface

module mkControl(ControlIfc);
   method Ctrl decode(Opcode op);
      Ctrl c = Ctrl { regWrite: False, memRead: False, memWrite: False,
                      memToReg: False, aluSrc: False, branch: False, jump: False, aluOp: 0 };
      case (op)
         7'b0110011: begin // R-type
            c.regWrite = True; c.aluSrc = False; c.aluOp = 2;
         end
         7'b0010011: begin // I-type ALU
            c.regWrite = True; c.aluSrc = True; c.aluOp = 3;
         end
         7'b0000011: begin // load
            c.regWrite = True; c.memRead = True; c.memToReg = True; c.aluSrc = True; c.aluOp = 0;
         end
         7'b0100011: begin // store
            c.memWrite = True; c.aluSrc = True; c.aluOp = 0;
         end
         7'b1100011: begin // branch
            c.branch = True; c.aluOp = 1;
         end
         7'b1101111: begin // JAL
            c.jump = True; c.regWrite = True;
         end
         7'b1100111: begin // JALR
            c.jump = True; c.regWrite = True; c.aluSrc = True;
         end
         7'b0110111, 7'b0010111: begin // LUI / AUIPC
            c.regWrite = True; c.aluSrc = True; c.aluOp = 0;
         end
         default: begin end // Empty block for default case
      endcase
      return c;
   endmethod
endmodule

endpackage
