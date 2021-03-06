/* ***************************************************
 * testbench
 * ***************************************************/
`incude "FIR_unit.v"

module top;      
`include "generated/defines.v"
   reg            clk           =1'b0;
   integer 	  fh_in;
   integer 	  fh_out;
   wire 	  req_dataIn;
   initial begin
      $dumpvars(0, top);
      fh_in = $fopen("generated/inData.txt", "r");
      fh_out = $fopen("generated/outData.txt", "w");
      #1 while(1) begin
	 #1 clk=1'b1;
	 #1 clk=1'b0; 
      end
   end
   
   reg signed [WIDTH_IN-1:0] dataIn;
   wire signed [WIDTH_OUT-1:0] dataOut;

   /* ***************************************************
    * input data streaming
    * ***************************************************/   
   integer 			   n;
   integer 			   inInt;   
   reg [7:0] 			   count = 5; // testbench delay to separate cycles in waveform display
   integer 			   dCount = 15;
   reg 				   strobe_dataIn; // testbench to filter: input data ready
   wire 			   strobe_dataOut; // filter to testbench: output data ready
   wire 			   idle;           // filter to testbench: ready for new data
   
   always @(posedge clk) begin      
      if (idle) begin
	 count <= (count == 0) ? dCount : count-1;
	 if (count == 0) begin
	    strobe_dataIn <= 1;
	    n = $fscanf(fh_in, "%d", inInt);	 
	    if (n < 1) begin
	       $fclose(fh_in);      
	       $finish;
	    end	    
	    dataIn = inInt;
	 end else begin
	    strobe_dataIn <= 0;
	 end
      end
   end

   /* ***************************************************
    * output data streaming
    * ***************************************************/   
   always @(negedge clk) begin
      if (strobe_dataOut) begin
	 // http://www.lcdm-eng.com/assertiveX.pdf
	 // section 6.2.2
	 if ((^dataOut) !== 1'bx)
	   $fwrite(fh_out, "%d\n", dataOut);	 
	 else
	   $fwrite(fh_out, "nan\n");      
      end
   end
   
   /* ***************************************************
    * DUT
    * ***************************************************/
   FIR_unit myFir(
		  .clk_in(clk), 
		  .dataIn(dataIn),
		  .strobe_dataIn(strobe_dataIn),
		  .strobe_dataOut(strobe_dataOut),
		  .dataOut(dataOut),
		  .idle(idle));
endmodule
