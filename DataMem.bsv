package DataMem;
import Types::*;
import Vector::*;

interface DataMemIfc;
   method Word read(Word addr);
   method Action write(Word addr, Word data);
endinterface

module mkDataMem(DataMemIfc);
   Reg#(Vector#(256, Word)) dmem <- mkReg(replicate(0));

   method Word read(Word addr);
      return dmem[addr[9:2]];
   endmethod

   method Action write(Word addr, Word data);
      Vector#(256, Word) new_mem = dmem;
      new_mem[addr[9:2]] = data;
      dmem <= new_mem;
   endmethod
endmodule

endpackage
