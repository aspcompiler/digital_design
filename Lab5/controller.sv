// controller.sv
//
// This file is for HMC E85A Lab 5.
// Place controller.tv in same computer directory as this file to test your multicycle controller.
//
// Starter code last updated by Ben Bracker (bbracker@hmc.edu) 1/14/21
// - added opcodetype enum
// - updated testbench and hash generator to accomodate don't cares as expected outputs
// Solution code by ________ (________) ________

typedef enum logic[6:0] {r_type_op=7'b0110011, i_type_alu_op=7'b0010011, lw_op=7'b0000011, sw_op=7'b0100011, beq_op=7'b1100011, jal_op=7'b1101111} opcodetype;

module controller(input  logic       clk,
                  input  logic       reset,  
                  input  opcodetype  op,
                  input  logic [2:0] funct3,
                  input  logic       funct7b5,
                  input  logic       Zero,
                  output logic [1:0] ImmSrc,
                  output logic [1:0] ALUSrcA, ALUSrcB,
                  output logic [1:0] ResultSrc, 
                  output logic       AdrSrc,
                  output logic [2:0] ALUControl,
                  output logic       IRWrite, PCWrite, 
                  output logic       RegWrite, MemWrite);


logic [1:0] ALUOp;
logic Branch, PCUpdate, t1;

aludecoder alu_decoder(ALUOp, funct3, op[5], funct7b5, ALUControl);

immsrc instr_decorder(op, ImmSrc);

mainfsm main_fsm(clk, reset, op, Branch, PCUpdate, IRWrite, RegWrite, MemWrite, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUOp);
and g1(t1, Zero, Branch);
or g2(PCWrite, t1, PCUpdate);

endmodule


module mainfsm(input  logic       clk,
               input  logic       reset,
               input  opcodetype  op,
	       output logic Branch,
	       output logic PCUpdate,
               output logic       IRWrite, 
               output logic       RegWrite, MemWrite,
               output logic [1:0] ALUSrcA, ALUSrcB,
	       output logic [1:0] ResultSrc, 
               output logic       AdrSrc,
	       output logic [1:0] ALUOp);

typedef enum logic[3:0] {s0=4'b0000, s1=4'b0001, s2=4'b0010, s3=4'b0011, s4=4'b0100, s5=4'b0101, s6=4'b0110, s7=4'b0111, s8=4'b1000, s9=4'b1001,  s10=4'b1010} statetype;

statetype state, nextstate;

  always @(posedge clk, posedge reset)
    begin
    	if (reset) 	state <= s0;
        else		state <= nextstate;
    end

  always_comb
    case (state)
    s0: nextstate = s1;
 
    s1: if (op == lw_op || op == sw_op) nextstate = s2;
        else if (op == r_type_op) nextstate = s6;
        else if (op == i_type_alu_op) nextstate = s8;
        else if (op == jal_op) nextstate = s9;
        else if (op == beq_op) nextstate = s10;
	else  nextstate = s1;
 
    s2: if (op == lw_op) nextstate = s3;
        else if (op == sw_op) nextstate = s5;
        else nextstate = s2;

    s3: nextstate = s4;
 
    s4: nextstate = s0;
 
    s5: nextstate = s0;
 
    s6: nextstate = s7;
 
    s7: nextstate = s0;
 
    s8: nextstate = s7;
 
    s9: nextstate = s7;
 
    s10: nextstate = s0;
 
    default: nextstate = s0;
 
    endcase

//output logic
  assign Branch = (state == s10);
  assign AdrSrc = (state == s3 || state == s5);
  assign IRWrite = (state == s0);
  assign PCUpdate = (state == s0 || state == s9);
  assign RegWrite = (state == s4 || state == s7);
  assign MemWrite = (state == s5);
  assign ALUSrcA[1] = (state == s2 || state == s6 || state == s8 || state == s10);
  assign ALUSrcA[0] = (state == s1 || state == s9);
  assign ALUSrcB[1] = (state == s0 || state == s9);
  assign ALUSrcB[0] = (state == s1 || state == s2  || state == s8);
  assign ALUOp[1] = (state == s6  || state == s8);
  assign ALUOp[0] = (state == s10);
  assign ResultSrc[1] = (state == s0);
  assign ResultSrc[0] = (state == s4);

endmodule


module immsrc(input opcodetype  op,
	      output logic [1:0] ImmSrc);
always_comb
    case (op)
    sw_op: ImmSrc = 2'b01;
    beq_op: ImmSrc = 2'b10;
    jal_op: ImmSrc = 2'b11;
    default: ImmSrc = 2'b00;
    endcase
	

endmodule 

module aludecoder(input  logic [1:0] ALUOp,
                  input  logic [2:0] funct3,
                  input  logic op_5, funct7_5,
                  output logic [2:0] ALUControl);
              
    // For Lab 2, write a structural Verilog model 
    // use and, or, not
    // do not use assign statements, always blocks, or other behavioral Verilog
    // Example syntax to access bits to make ALUControl[0] = ~funct3[0]
    //  not g1(ALUControl[0], funct3[0]);
    // This is just an example; replace this with correct logic!
    logic n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16, n17, n18;
    logic nx1, nx2, nx3;

    // op10 = ALUOp[1] * ~ALUOp[0];
    not g1(n1, ALUOp[0]);
    and g2(n2, ALUOp[1], n1);

    // ALUControl[0] = ~ALUOp[1] * ALUOp[0] + n2 * ~(~funct3[2] * ~funct3[1] * ~funct3[0] * ~(op_5, funct7_5) + funct3[2] * funct3[1] * funct3[0]);
    not g3(n3, ALUOp[1]);
    and g4(n4, n3, ALUOp[0]);

    not g5(n5, funct3[2]);
    not g6(n6, funct3[1]);
    not g7(n7, funct3[0]);
    and g8(n8, n5, n6);
    and g9(n9, n8, n7);

    and gx1(nx1, op_5, funct7_5);
    not gx2(nx2, nx1);
    and gx3(nx3, n9, nx2);

    and g10(n10, funct3[2], funct3[1]);
    and g11(n11, n10, funct3[0]);
    
    or g12(n12, nx3, n11);
    not g13(n13,n12);

    and g14(n14, n2, n13);
    or go1(ALUControl[0], n4, n14); 


    //ALUControl[1] = n2 * funct3[2] * funct3[1];
    and g16(n16, n2, funct3[2]);
    and go2(ALUControl[1], n16, funct3[1]);


    //ALUControl[2] = n2 * ~funct3[2] * funct3[1] * ~funct3[0]
    and g17(n17, n2, n5);
    and g18(n18, n17, funct3[1]);
    and go3(ALUControl[2], n18, n7);

endmodule


module testbench();

  logic        clk;
  logic        reset;
  
  opcodetype  op;
  logic [2:0] funct3;
  logic       funct7b5;
  logic       Zero;
  logic [1:0] ImmSrc;
  logic [1:0] ALUSrcA, ALUSrcB;
  logic [1:0] ResultSrc;
  logic       AdrSrc;
  logic [2:0] ALUControl;
  logic       IRWrite, PCWrite;
  logic       RegWrite, MemWrite;
  
  logic [31:0] vectornum, errors;
  logic [39:0] testvectors[10000:0];
  
  logic        new_error;
  logic [15:0] expected;
  logic [6:0]  hash;


  // instantiate device to be tested
  controller dut(clk, reset, op, funct3, funct7b5, Zero,
                 ImmSrc, ALUSrcA, ALUSrcB, ResultSrc, AdrSrc, ALUControl, IRWrite, PCWrite, RegWrite, MemWrite);
  
  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors and pulse reset
  initial
    begin
      $readmemb("controller.tv", testvectors);
      vectornum = 0; errors = 0; hash = 0;
      reset = 1; #22; reset = 0;
    end
	 
  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {op, funct3, funct7b5, Zero, expected} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      new_error=0; 

      if ((ImmSrc!==expected[15:14])&&(expected[15:14]!==2'bxx))  begin
        $display("   ImmSrc = %b      Expected %b", ImmSrc,     expected[15:14]);
        new_error=1;
      end
      if ((ALUSrcA!==expected[13:12])&&(expected[13:12]!==2'bxx)) begin
        $display("   ALUSrcA = %b     Expected %b", ALUSrcA,    expected[13:12]);
        new_error=1;
      end
      if ((ALUSrcB!==expected[11:10])&&(expected[11:10]!==2'bxx)) begin
        $display("   ALUSrcB = %b     Expected %b", ALUSrcB,    expected[11:10]);
        new_error=1;
      end
      if ((ResultSrc!==expected[9:8])&&(expected[9:8]!==2'bxx))   begin
        $display("   ResultSrc = %b   Expected %b", ResultSrc,  expected[9:8]);
        new_error=1;
      end
      if ((AdrSrc!==expected[7])&&(expected[7]!==1'bx))           begin
        $display("   AdrSrc = %b       Expected %b", AdrSrc,     expected[7]);
        new_error=1;
      end
      if ((ALUControl!==expected[6:4])&&(expected[6:4]!==3'bxxx)) begin
        $display("   ALUControl = %b Expected %b", ALUControl, expected[6:4]);
        new_error=1;
      end
      if ((IRWrite!==expected[3])&&(expected[3]!==1'bx))          begin
        $display("   IRWrite = %b      Expected %b", IRWrite,    expected[3]);
        new_error=1;
      end
      if ((PCWrite!==expected[2])&&(expected[2]!==1'bx))          begin
        $display("   PCWrite = %b      Expected %b", PCWrite,    expected[2]);
        new_error=1;
      end
      if ((RegWrite!==expected[1])&&(expected[1]!==1'bx))         begin
        $display("   RegWrite = %b     Expected %b", RegWrite,   expected[1]);
        new_error=1;
      end
      if ((MemWrite!==expected[0])&&(expected[0]!==1'bx))         begin
        $display("   MemWrite = %b     Expected %b", MemWrite,   expected[0]);
        new_error=1;
      end

      if (new_error) begin
        $display("Error on vector %d: inputs: op = %h funct3 = %h funct7b5 = %h", vectornum, op, funct3, funct7b5);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      hash = hash ^ {ImmSrc&{2{expected[15:14]!==2'bxx}}, ALUSrcA&{2{expected[13:12]!==2'bxx}}} ^ {ALUSrcB&{2{expected[11:10]!==2'bxx}}, ResultSrc&{2{expected[9:8]!==2'bxx}}} ^ {AdrSrc&{expected[7]!==1'bx}, ALUControl&{3{expected[6:4]!==3'bxxx}}} ^ {IRWrite&{expected[3]!==1'bx}, PCWrite&{expected[2]!==1'bx}, RegWrite&{expected[1]!==1'bx}, MemWrite&{expected[0]!==1'bx}};
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 40'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors);
	      $display("hash = %h", hash);
        $stop;
      end
    end
endmodule

