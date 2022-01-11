module twoscomp(input  logic clk,
                input  logic reset,
                input  logic a,
                output logic n);

logic ab, nexts, s;

not g1(ab, a);
and g2(nexts, ab, s);
flops g3(clk, reset, nexts, s);
//xno g4(a, s, n);

logic na, nb, i1, i2;
not gx1(na, a);
not gx2(nb, s);
and gx3(i1, na, nb);
and gx4(i2, a, s);
or gx5(n, i1, i2);

endmodule

/*
// xnor
module xno(input logic a, b,
	output logic c);

logic na, nb, i1, i2;
not g1(na, a);
not g2(nb, b);
and g3(i1, na, nb);
and g4(i2, a, b);
or g5(c, i1, i2);

endmodule
*/

// flip-flop
module flop(input  logic clk, d,
         output logic q);
            
  always_ff @(posedge clk)
    q <= d;
endmodule


// asynchronously resettable flip-flop
module flopr(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 0; // resets state to 0 on reset
    else       q <= d;
endmodule

// asynchronously settable flip-flop
module flops(input  logic clk, reset, d,
            output logic q);
            
  always_ff @(posedge clk or posedge reset)
    if (reset) q <= 1;  // sets state to 1 on reset
    else       q <= d;
endmodule

module testbench(); 
  logic        clk, reset;
  logic        a, n, nexpected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [1:0]  testvectors[10000:0];

  // instantiate device under test 
  twoscomp dut(clk, reset, a, n);

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("twoscomp.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0; 
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {a, nexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) 
    if (~reset) begin    // skip during reset
      if (n !== nexpected) begin // check result 
        $display("Error: input = %b", a);
        $display(" output = %b (%b expected)", n, nexpected); 
        errors = errors + 1; 
      end
      vectornum = vectornum + 1;
      hash = hash ^ n;
      hash = {hash[5:0], hash[6] ^ hash[5]};
      if (testvectors[vectornum] === 2'bx) begin 
        $display("%d tests completed with %d errors", vectornum, errors); 
        $display("Hash: %h", hash);
        $stop; 
      end 
    end 
endmodule 
 
