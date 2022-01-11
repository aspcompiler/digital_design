module fsm(input  logic clk, reset,
           input  logic a,
           output logic q);
           
    // your code goes here
  typedef enum logic [1:0] {s0, s1, s2, s3} statetype;
  statetype state, nextstate;

  always @(posedge clk, posedge reset)
    begin
    	if (reset) 	state <= s0;
        else		state <= nextstate;
    end

  always_comb
    case (state)
    s0: if (a) nextstate = s2;
        else nextstate = s3;
    s1: if (a) nextstate = s2;
        else nextstate = s0;
    s2: if (a) nextstate = s3;
        else nextstate = s1;
    s3: if (a) nextstate = s0;
        else nextstate = s1;
    default: nextstate = s0;
    endcase

  //output logic
  assign q = state[0] ^ state [1];

endmodule


module testbench(); 
  logic        clk, reset;
  logic        a, q, qexpected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [1:0]  testvectors[10000:0];

  // instantiate device under test 
  fsm dut(clk, reset, a, q);

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("fsm.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0;
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {a, qexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) begin
    if (!reset) begin
//		if (q !== qexpected) begin // check result 
//		  $display("Error: a = %b", a);
//		  $display(" q = %b (%b expected)", q, qexpected);
//		  errors = errors + 1; 
//		end
		vectornum = vectornum + 1;
		hash = hash ^ q;
		hash = {hash[5:0], hash[6] ^ hash[5]};
	end
    if (testvectors[vectornum] === 2'bx) begin 
//      $display("%d tests completed with %d errors", vectornum, errors); 
      $display("Hash: %h", hash);
      $stop; 
    end 
  end 
endmodule 
 
