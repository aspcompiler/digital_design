module fsm(input  logic clk, reset,
           input  logic D,
           output logic L);
           
  // your code goes here
  typedef enum logic [3:0] {s0=4'b0001, s1=4'b0010, s2=4'b0100, s3=4'b1000} statetype;
  statetype state, nextstate;

  always @(posedge clk, posedge reset)
    begin
    	if (reset) 	state <= s0;
        else		state <= nextstate;
    end

  always_comb
    case (state)
      s0: if (D) nextstate = s0;
          else   nextstate = s1;
      s1: if (D) nextstate = s2;
          else nextstate = s0;
      s2: if (D) nextstate = s0;
	  else nextstate = s3;
      s3: nextstate = s3;
      default: nextstate = s0;
    endcase

    assign L = (state == s3);
  
endmodule

module testbench(); 
  logic        clk, reset;
  logic        D, L, Lexpected;
  logic [6:0]  hash;
  logic [31:0] vectornum, errors;
  logic [1:0]  testvectors[10000:0];

  // instantiate device under test 
  fsm dut(clk, reset, D, L);

  // generate clock 
  always 
    begin
      clk=1; #5; clk=0; #5; 
    end 

  // at start of test, load vectors and pulse reset
  initial 
    begin
      $readmemb("lock_fsm.tv", testvectors); 
      vectornum = 0; errors = 0; hash = 0; reset = 1; #22; reset = 0;
    end 

  // apply test vectors on rising edge of clk 
  always @(posedge clk) 
    begin
      #1; {D, Lexpected} = testvectors[vectornum]; 
    end 

  // check results on falling edge of clk 
  always @(negedge clk) begin
    if (!reset) begin
		if (L !== Lexpected) begin // check result 
		  $display("Error: L = %b", L);
		  $display(" L = %b (%b expected)", L, Lexpected);
		  errors = errors + 1; 
		end
		vectornum = vectornum + 1;
		hash = hash ^ {D, L};
		hash = {hash[5:0], hash[6] ^ hash[5]};
	end
    if (testvectors[vectornum] === 2'bx) begin 
      $display("%d tests completed with %d errors", vectornum, errors); 
      $display("Hash: %h", hash);
      $stop; 
    end 
  end 
endmodule 
 