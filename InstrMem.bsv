package InstrMem;
import Types::*;
import Vector::*;

interface InstrMemIfc;
   method Word read(Word addr);
endinterface

module mkInstrMem(InstrMemIfc);
   // R-type instruction test program: x5=15, x6=3, test all R-type ops to x7
   function Vector#(256, Word) initMemory();
      Vector#(256, Word) mem = replicate(0);
      
      // Initialize test values
      mem[0]  = 'h00f00293; // addi x5, x0, 15    (x5 = 15)
      mem[1]  = 'h00300313; // addi x6, x0, 3     (x6 = 3)
      
      // Test all R-type instructions (x7 = x5 op x6)
      mem[2]  = 'h006283b3; // add  x7, x5, x6    (x7 = 15 + 3 = 18)
      mem[3]  = 'h406283b3; // sub  x7, x5, x6    (x7 = 15 - 3 = 12)
      mem[4]  = 'h0062c3b3; // xor  x7, x5, x6    (x7 = 15 ^ 3 = 12)
      mem[5]  = 'h0062e3b3; // or   x7, x5, x6    (x7 = 15 | 3 = 15)
      mem[6]  = 'h0062f3b3; // and  x7, x5, x6    (x7 = 15 & 3 = 3)
      mem[7]  = 'h006293b3; // sll  x7, x5, x6    (x7 = 15 << 3 = 120)
      mem[8]  = 'h0062d3b3; // srl  x7, x5, x6    (x7 = 15 >> 3 = 1)
      mem[9]  = 'h4062d3b3; // sra  x7, x5, x6    (x7 = 15 >>> 3 = 1)
      mem[10] = 'h0062a3b3; // slt  x7, x5, x6    (x7 = (15 < 3) ? 1 : 0 = 0)
      mem[11] = 'h0062b3b3; // sltu x7, x5, x6    (x7 = (15 < 3) ? 1 : 0 = 0)
      /*
      // Test with different values for better coverage
      mem[12] = 'hfff00293; // addi x5, x0, -1    (x5 = -1)
      mem[13] = 'h00100313; // addi x6, x0, 1     (x6 = 1)
      
      // Test signed operations with negative numbers
      mem[14] = 'h0062a3b3; // slt  x7, x5, x6    (x7 = (-1 < 1) ? 1 : 0 = 1)
      mem[15] = 'h0062b3b3; // sltu x7, x5, x6    (x7 = (MAX_UINT < 1) ? 1 : 0 = 0)
      mem[16] = 'h4062d3b3; // sra  x7, x5, x6    (x7 = -1 >>> 1 = -1)
      
      // End of test - infinite loop
      mem[17] = 'h00000013; // nop
      mem[18] = 'hffdff06f; // jal x0, -4         // Infinite loop (jump back to nop)
      */
      
      return mem;
   endfunction

   Reg#(Vector#(256, Word)) imem <- mkReg(initMemory());

   method Word read(Word addr);
      return imem[addr[9:2]];
   endmethod
endmodule
endpackage
