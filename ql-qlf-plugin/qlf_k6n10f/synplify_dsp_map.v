module QL_DSPV2 ( 
    input  wire [31:0] a,
    input  wire [17:0] b,
	input  wire [17:0] c,
	input  wire        load_acc,
    input  wire [2:0]  feedback,
	input  wire [2:0]  output_select,
    output wire [49:0] z,

    input  wire       clk,
    input  wire       reset,
	input  wire       acc_reset,
   
	input  wire [31:0] 	a_cin,
    input  wire [17:0] 	b_cin,
	input  wire [49:0] 	z_cin,
	output wire [49:0] 	z_cout,
	output wire [31:0] 	a_cout,
	output wire [17:0] 	b_cout
);

  parameter [71:0] MODE_BITS = 72'h000000000000000000;
  
  //parameter _TECHMAP_CONSTMSK_clk_ = 1'b0;
  //parameter _TECHMAP_CONSTVAL_clk_ = 1'b0;
  
  //parameter _TECHMAP_CONSTMSK_load_acc_ = 1'b0;
  //parameter _TECHMAP_CONSTVAL_load_acc_ = 1'b0;
  
  parameter _TECHMAP_CONSTMSK_output_select_ = 3'b000;
  parameter _TECHMAP_CONSTVAL_output_select_ = 3'b000;
  
  wire [37:0] z_int;
  wire UNSIGNED_A;
  wire UNSIGNED_B;
  wire rnd_en;
  
  assign z = {12'h0, z_int};
  assign UNSIGNED_A = 1'b1;
  assign UNSIGNED_A = 1'b1;
  assign rnd_en = (MODE_BITS[40:38] == 3'b000)? 1'b0: 1'b1;

generate
	if (MODE_BITS[61] == 1'b0 && MODE_BITS[63] == 1'b0 && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b000) begin
	
		QL_DSP2_MULT #(
				.MODE_BITS(80'd0)
			) mult (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.reset(),
		
				.f_mode(MODE_BITS[71]),
		
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
		
				.output_select(3'b000),      
				.register_inputs(1'b0) 
			);
			
   end else if ((MODE_BITS[61] == 1'b1 || MODE_BITS[63] == 1'b1) && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b000) begin

		QL_DSP2_MULT_REGIN  #(
				.MODE_BITS(80'd0)
			) mult_regin (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
		
				.output_select(3'b000),     
				.register_inputs(1'b1)  
			);
			
   end else if (MODE_BITS[61] == 1'b0 && MODE_BITS[63] == 1'b0 && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b100) begin

		QL_DSP2_MULT_REGOUT #(
				.MODE_BITS(80'd0)
			) mult_regout (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
		
				.output_select(3'b100), 
				.register_inputs(1'b0)   
			);
  
	end else if ((MODE_BITS[61] == 1'b1 || MODE_BITS[63] == 1'b1) && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b100) begin
	
		QL_DSP2_MULT_REGIN_REGOUT #(
				.MODE_BITS(80'd0)
			) mult_reginout (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
		
				.output_select(3'b100),     
				.register_inputs(1'b1)  
			);
   
   end else if (MODE_BITS[61] == 1'b0 && MODE_BITS[63] == 1'b0 && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b001) begin
	
		QL_DSP2_MULTACC  #(
				.MODE_BITS(80'd0)
			) multacc (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.load_acc(load_acc),
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
				
				.output_select(3'b001),      
				.saturate_enable(MODE_BITS[57]),
				.shift_right(MODE_BITS[56:51]),
				.round(rnd_en),
				.subtract(MODE_BITS[58]),
				.register_inputs(1'b0)  
			);
			
  	end else if ((MODE_BITS[61] == 1'b1 || MODE_BITS[63] == 1'b1) && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b001) begin
	
		QL_DSP2_MULTACC_REGIN #(
				.MODE_BITS(80'd0)
			) multacc_regin (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.load_acc(load_acc),
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
				
				.output_select(3'b001),      
				.saturate_enable(MODE_BITS[57]),
				.shift_right(MODE_BITS[56:51]),
				.round(rnd_en),
				.subtract(MODE_BITS[58]),
				.register_inputs(1'b1)   
			);		
    
	end else if (MODE_BITS[61] == 1'b0 && MODE_BITS[63] == 1'b0 && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b101) begin
	
		QL_DSP2_MULTACC_REGOUT #(
				.MODE_BITS(80'd0)
			) multacc_regout (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.load_acc(load_acc),
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
				
				.output_select(3'b110),     
				.saturate_enable(MODE_BITS[57]),
				.shift_right(MODE_BITS[56:51]),
				.round(rnd_en),
				.subtract(MODE_BITS[58]),
				.register_inputs(1'b0)  
			);

	end else if ((MODE_BITS[61] == 1'b1 || MODE_BITS[63] == 1'b1) && _TECHMAP_CONSTMSK_output_select_ == 3'b111 && _TECHMAP_CONSTVAL_output_select_ == 3'b101) begin
	
		QL_DSP2_MULTACC_REGIN_REGOUT #(
				.MODE_BITS(80'd0)
			) multacc_reginout (
				.a(a[19:0]),
				.b(b[17:0]),
				.z(z_int),
		
				.clk(clk),
				.reset(reset),
		
				.f_mode(MODE_BITS[71]),
		
				.load_acc(load_acc),
				.feedback(feedback),
				.unsigned_a(UNSIGNED_A),
				.unsigned_b(UNSIGNED_B),
				
				.output_select(3'b110),      
				.saturate_enable(MODE_BITS[57]),
				.shift_right(MODE_BITS[56:51]),
				.round(rnd_en),
				.subtract(MODE_BITS[58]),
				.register_inputs(1'b1)  
			);
   end else begin
   
        wire reg_input;
		assign reg_input = (MODE_BITS[61] | MODE_BITS[63]);
		
		QL_DSP2 #(
			.MODE_BITS(80'd0)
		) dsp (
			.a(a[19:0]),
			.b(b[17:0]),
			.acc_fir(MODE_BITS[37:32]),
			.z(z_int),
			.dly_b(),
	
			.f_mode(MODE_BITS[71]),
	
			.feedback(feedback),
			.load_acc(load_acc),
	
			.unsigned_a(UNSIGNED_A),
			.unsigned_b(UNSIGNED_B),
	
			.clk(clk),
			.reset(reset),
	
			.output_select(output_select),    
			.saturate_enable(MODE_BITS[57]),
			.shift_right(MODE_BITS[56:51]),
			.round(rnd_en),
			.subtract(MODE_BITS[58]),
			.register_inputs(reg_input)   
		);
   end
endgenerate

endmodule
