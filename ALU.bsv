package ALU;
import Types::*;

typedef enum { ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU, ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND } ALUOp deriving (Bits,Eq,FShow);

interface ALUIfc;
   method Word exec(ALUOp op, Word a, Word b);
   method Bool zero(Word v);
   method Bool slt_signed(Word a, Word b);
   method Bool slt_u(Word a, Word b);
endinterface

module mkALU(ALUIfc);
   // helper: signed comparison
   function Bool signedLT(Word a, Word b);
      Int#(32) signedA = unpack(a);
      Int#(32) signedB = unpack(b);
      return (signedA < signedB);
   endfunction

   method Word exec(ALUOp op, Word a, Word b);
      Word r = 0;
      case (op)
         ALU_ADD:  r = a + b;
         ALU_SUB:  r = a - b;
         ALU_SLL:  r = a << b[4:0];
         ALU_SLT:  r = (signedLT(a,b)) ? 1 : 0;
         ALU_SLTU: r = (a < b) ? 1 : 0;
         ALU_XOR:  r = a ^ b;
         ALU_SRL:  r = a >> b[4:0];
         ALU_SRA:  begin
            Int#(32) signedA = unpack(a);
            r = pack(signedA >> b[4:0]);
         end
         ALU_OR:   r = a | b;
         ALU_AND:  r = a & b;
      endcase
      return r;
   endmethod

   method Bool zero(Word v);
      return (v == 0);
   endmethod

   method Bool slt_signed(Word a, Word b);
      return signedLT(a,b);
   endmethod

   method Bool slt_u(Word a, Word b);
      return (a < b);
   endmethod
endmodule

endpackage
