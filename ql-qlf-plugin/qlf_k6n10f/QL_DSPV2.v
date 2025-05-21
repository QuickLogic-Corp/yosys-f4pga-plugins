module VCC(output P);
  assign P = 1'b1;
endmodule

module GND(output G);
  assign G = 1'b0;
endmodule

module QL_DSPV2 #(parameter [71:0] MODE_BITS= 72'h000000000000000000)
( 
    input  wire [31:0] a,
    input  wire [17:0] b,
	input  wire [17:0] c,
	input  wire        load_acc,
    input  wire [2:0]  feedback,
	input  wire [2:0]  output_select,
    output wire [49:0] z,

    (* clkbuf_sink *)
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

    //parameter [71:0] MODE_BITS = 72'h000000000000000000;

    localparam [31:0] COEFF_0 	= MODE_BITS[31:0];
	localparam [5:0]  ACC_FIR   = MODE_BITS[37:32];
    localparam [2:0]  ROUND 	= MODE_BITS[40:38];
    localparam [4:0]  ZC_SHIFT	= MODE_BITS[45:41];
    localparam [4:0]  ZREG_SHIFT= MODE_BITS[50:46];
	localparam [5:0]  SHIFT_REG = MODE_BITS[56:51];
	localparam  SATURATE  = MODE_BITS[57];
	localparam  SUBTRACT  = MODE_BITS[58];
	localparam  PRE_ADD   = MODE_BITS[59];
	localparam  A_SEL     = MODE_BITS[60];
	localparam  A_REG     = MODE_BITS[61];
	localparam  B_SEL     = MODE_BITS[62];
	localparam  B_REG     = MODE_BITS[63];
	localparam  C_REG     = MODE_BITS[64];
	localparam  BC_REG    = MODE_BITS[65];
	localparam  M_REG     = MODE_BITS[66];
	localparam  ZCIN_REG  = MODE_BITS[67];
	localparam  FRAC_MODE = MODE_BITS[71];
	
    localparam NBITS_ACC = 64;
    localparam NBITS_A  = 32;
    localparam NBITS_BC = 18;
    localparam NBITS_Z  = 50;

    wire [NBITS_Z-1:0] dsp_full_z;
    wire [(NBITS_Z/2)-1:0] dsp_frac0_z;
    wire [(NBITS_Z/2)-1:0] dsp_frac1_z;
	
    wire [NBITS_Z-1:0] dsp_full_z_cout;
    wire [(NBITS_Z/2)-1:0] dsp_frac0_z_cout;
    wire [(NBITS_Z/2)-1:0] dsp_frac1_z_cout;

    wire [NBITS_A-1:0] dsp_full_a_cout;
    wire [(NBITS_A/2)-1:0] dsp_frac0_a_cout;
    wire [(NBITS_A/2)-1:0] dsp_frac1_a_cout;
	
    wire [NBITS_BC-1:0] dsp_full_b_cout;
    wire [(NBITS_BC/2)-1:0] dsp_frac0_b_cout;
    wire [(NBITS_BC/2)-1:0] dsp_frac1_b_cout;

    assign z = FRAC_MODE ? {dsp_frac1_z, dsp_frac0_z} : dsp_full_z;
	assign z_cout = FRAC_MODE ? {dsp_frac1_z_cout, dsp_frac0_z_cout} : dsp_full_z_cout;
    assign a_cout = FRAC_MODE ? {dsp_frac1_a_cout, dsp_frac0_a_cout} : dsp_full_a_cout;
	assign b_cout = FRAC_MODE ? {dsp_frac1_b_cout, dsp_frac0_b_cout} : dsp_full_b_cout;


generate
  if (FRAC_MODE == 1'b1 ) begin
    // Output used when fmode == 1
	// half DSP block #1
	dsp_type2_bw #(
		.NBITS_A        ( (NBITS_A/2)   ),
		.NBITS_BC       ( (NBITS_BC/2)  ),
		.NBITS_Z        ( (NBITS_Z/2)   ),
		.NBITS_ACC      ( (NBITS_ACC/2) )
	) dsp_frac0 (
		// active/fabric ports (connect to general/fabric routing)
		.clk_i          ( clk           ),
		.rst_i          ( reset           ),
		.a_i            ( a[(NBITS_A/2)-1:0]),
		.b_i            ( b[(NBITS_BC/2)-1:0]),
		.c_i            ( c[(NBITS_BC/2)-1:0]),
		.feedback_i     ( feedback    ),
		.out_sel_i      ( output_select ),
		.load_acc_i     ( load_acc      ),
		.rst_acc_i      ( acc_reset     ),
		.z_o            ( dsp_frac0_z       ),
	
		// cascade ports (connect to dedicated cascade routing)
		.a_cin_i        ( a_cin[(NBITS_A/2)-1:0]),
		.b_cin_i        ( b_cin[(NBITS_BC/2)-1:0]),
		.z_cin_i        ( z_cin[(NBITS_Z/2)-1:0]),
		.z_cout_o       ( dsp_frac0_z_cout  ),
		.a_cout_o       ( dsp_frac0_a_cout  ),
		.b_cout_o       ( dsp_frac0_b_cout  ),
	
		// configuration ports (tie-offs)
		.round_i        ( ROUND       ),
		.acc_fir_i      ( ACC_FIR     ),
		.coeff_i        ( COEFF_0[(NBITS_A/2)-1:0]),
		.zc_shift_i     ( ZC_SHIFT    ),
		.zreg_shift_i   ( ZREG_SHIFT  ),
		.acc_shift_i    ( SHIFT_REG   ),
		.saturate_i     ( SATURATE    ),
		.padd_sel_i     ( PRE_ADD    ),
		.a_sel_i        ( A_SEL       ),
		.a_reg_i        ( A_REG         ),
		.b_sel_i        ( B_SEL       ),
		.b_reg_i        ( B_REG         ),
		.c_reg_i        ( C_REG         ),
		.bc_reg_i       ( BC_REG        ),
		.m_reg_i        ( M_REG         ),
		.subtract_i     ( SUBTRACT    ),
		.z_cin_sel_i    ( ZCIN_REG   )
	); // dspf0 



    // Output used when fmode == 1        
	// half DSP block #2
	dsp_type2_bw #(
		.NBITS_A        ( (NBITS_A/2)   ),
		.NBITS_BC       ( (NBITS_BC/2)  ),
		.NBITS_Z        ( (NBITS_Z/2)   ),
		.NBITS_ACC      ( (NBITS_ACC/2) )
	) dspf1 (
		// active/fabric ports (connect to general/fabric routing)
		.clk_i          ( clk           ),
		.rst_i          ( reset           ),
		.a_i            ( a[NBITS_A-1:NBITS_A/2]),
		.b_i            ( b[NBITS_BC-1:NBITS_BC/2]),
		.c_i            ( c[NBITS_BC-1:NBITS_BC/2]),
		.feedback_i     ( feedback    ),
		.out_sel_i      ( output_select     ),
		.load_acc_i     ( load_acc    ),
		.rst_acc_i      ( acc_reset     ),
		.z_o            ( dsp_frac1_z       ),
	
		// cascade ports (connect to dedicated cascade routing)
		.a_cin_i        ( a_cin[NBITS_A-1:NBITS_A/2]),
		.b_cin_i        ( b_cin[NBITS_BC-1:NBITS_BC/2]),
		.z_cin_i        ( z_cin[NBITS_Z-1:NBITS_Z/2]),
		.z_cout_o       ( dsp_frac1_z_cout  ),
		.a_cout_o       ( dsp_frac1_a_cout  ),
		.b_cout_o       ( dsp_frac1_b_cout  ),
	
		// configuration ports (tie-offs)
		.round_i        ( ROUND       ),
		.acc_fir_i      ( ACC_FIR     ),
		.coeff_i        ( COEFF_0[NBITS_A-1:NBITS_A/2]),
		.zc_shift_i     ( ZC_SHIFT    ),
		.zreg_shift_i   ( ZREG_SHIFT  ),
		.acc_shift_i    ( SHIFT_REG   ),
		.saturate_i     ( SATURATE    ),
		.padd_sel_i     ( PRE_ADD    ),
		.a_sel_i        ( A_SEL       ),
		.a_reg_i        ( A_REG         ),
		.b_sel_i        ( B_SEL       ),
		.b_reg_i        ( B_REG         ),
		.c_reg_i        ( C_REG         ),
		.bc_reg_i       ( BC_REG        ),
		.m_reg_i        ( M_REG         ),
		.subtract_i     ( SUBTRACT    ),
		.z_cin_sel_i    ( ZCIN_REG   )
	); // dspf1 

  end else begin
    // Output used when fmode == 0
	dsp_type2_bw #(
		.NBITS_A        ( NBITS_A       ),
		.NBITS_BC       ( NBITS_BC      ),
		.NBITS_Z        ( NBITS_Z       ),
		.NBITS_ACC      ( NBITS_ACC     )
	) dsp0 (
		// active/fabric ports (connect to general/fabric routing)
		.clk_i          ( clk ),
		.rst_i          ( reset ),
		.a_i            ( a ),
		.b_i            ( b ),
		.c_i            ( c ),
		.feedback_i     ( feedback    ),
		.out_sel_i      ( output_select ),
		.load_acc_i     ( load_acc      ),
		.rst_acc_i      ( acc_reset     ),
		.z_o            ( dsp_full_z    ),
	
		// cascade ports (connect to dedicated cascade routing)
		.a_cin_i        ( a_cin    ),
		.b_cin_i        ( b_cin    ),
		.z_cin_i        ( z_cin    ),
		.z_cout_o       ( dsp_full_z_cout   ),
		.a_cout_o       ( dsp_full_a_cout   ),
		.b_cout_o       ( dsp_full_b_cout   ),
	
		// configuration ports (tie-offs)
		.round_i        ( ROUND       ),
		.acc_fir_i      ( ACC_FIR     ),
		.coeff_i        ( COEFF_0       ),
		.zc_shift_i     ( ZC_SHIFT    ),
		.zreg_shift_i   ( ZREG_SHIFT  ),
		.acc_shift_i    ( SHIFT_REG   ),
		.saturate_i     ( SATURATE    ),
		.padd_sel_i     ( PRE_ADD    ),
		.a_sel_i        ( A_SEL       ),
		.a_reg_i        ( A_REG         ),
		.b_sel_i        ( B_SEL       ),
		.b_reg_i        ( B_REG         ),
		.c_reg_i        ( C_REG         ),
		.bc_reg_i       ( BC_REG        ),
		.m_reg_i        ( M_REG         ),
		.subtract_i     ( SUBTRACT    ),
		.z_cin_sel_i    ( ZCIN_REG   )
	); // dsp0 
	
  end
endgenerate

endmodule

module dsp_type2_bw #(
    parameter NBITS_A   = 32    ,
    parameter NBITS_BC  = 18    ,
    parameter NBITS_Z   = 50    ,
    parameter NBITS_ACC = 64
) (
    // active/fabric ports (connect to general/fabric routing)
    input   wire                       clk_i       , // Clk_i
    input   wire                       rst_i       , // Rstn_i
    input   wire   [(NBITS_A-1):0]     a_i         , // A_i[31:0]
    input   wire   [(NBITS_BC-1):0]    b_i         , // B_i[17:0]
    input   wire   [(NBITS_BC-1):0]    c_i         , // C_i[17:0]
    input   wire   [2:0]               feedback_i  , // Feedback_i[2:0]
    input   wire   [2:0]               out_sel_i   , // Out_sel_i[2:0]
    input   wire                       load_acc_i  , // Load_acc_i
    input   wire                       rst_acc_i   ,
    output  reg   [(NBITS_Z-1):0]     z_o         , // Z_o[49:0]

    // cascade ports (connect to dedicated cascade routing)
    input   wire   [(NBITS_A-1):0]     a_cin_i     , // ACIN_i[31:0]
    input   wire   [(NBITS_BC-1):0]    b_cin_i     , // BCIN_i[17:0]
    input   wire   [(NBITS_Z-1):0]     z_cin_i     , // ZCIN_i[49:0]
    output  wire   [(NBITS_Z-1):0]     z_cout_o    , // ZCOUT_o[49:0]
    output  wire   [(NBITS_A-1):0]     a_cout_o    , // ACOUT_o[31:0]
    output  wire   [(NBITS_BC-1):0]    b_cout_o    , // BCOUT_o[31:0]

    // configuration ports (tie-offs)
    input   wire   [2:0]               round_i     , // round[2:0]
    input   wire   [5:0]               acc_fir_i   , // acc_fir[5:0]
    input   wire   [(NBITS_A-1):0]     coeff_i     , // coeff[31:0]
    input   wire   [5:0]               zc_shift_i  , // zc_shift[4:0]
    input   wire   [5:0]               zreg_shift_i, // zreg_shift[4:0]
    input   wire   [5:0]               acc_shift_i , // shift_reg[5:0]
    input   wire                       saturate_i  , // saturate
    input   wire                       padd_sel_i  , // PADD_sel
    input   wire                       a_sel_i     , // A_sel
    input   wire                       a_reg_i     , // A_reg
    input   wire                       b_sel_i     , // B_sel
    input   wire                       b_reg_i     , // B_reg
    input   wire                       c_reg_i     , // C_reg
    input   wire                       bc_reg_i    , // BC_reg
    input   wire                       m_reg_i     , // M_reg
    input   wire                       subtract_i  , // subtract
    input   wire                       z_cin_sel_i
);


wire   clk     ;
wire   rst     ;


reg   signed  [(NBITS_A-1):0]              a_r;
wire   signed  [(NBITS_A-1):0]             a_acin_sel, a;
reg   signed  [(NBITS_BC-1):0]             b_r;
wire   signed  [(NBITS_BC-1):0]            b_bcin_sel,b;
wire   signed  [(NBITS_BC-1):0]            c;
reg   signed  [(NBITS_BC-1):0]             c_r;
wire   signed  [(NBITS_Z-1):0]             zcin_0_sel;

wire   signed  [(NBITS_BC):0]              preadd_raw;   // 1 bit larger than B
reg   signed  [(NBITS_BC-1):0]            preadd_sat;
reg   signed  [(NBITS_BC-1):0]             preadd_sat_r;
wire   signed  [(NBITS_BC-1):0]            preadd;

reg   signed  [(NBITS_A-1):0]              mult_a;
wire   signed  [(NBITS_BC-1):0]            mult_bc;
wire   signed  [(NBITS_A+NBITS_BC-1):0]    mult;

reg   signed  [(NBITS_ACC-1):0]            mult_xtnd_r;
wire   signed  [(NBITS_ACC-1):0]           mult_xtnd, mult_xtnd_sel, mult_xtnd_sub;
wire   signed  [(NBITS_ACC-1):0]           ab_concat;
wire   signed  [(NBITS_ACC-1):0]           accadd_a, accadd_sum;
reg   signed  [(NBITS_ACC-1):0]            accadd_b;
wire   signed  [(NBITS_ACC-1):0]           zcin_xtnd, zcin_xtnd_rshift;
wire   signed  [(NBITS_ACC-1):0]           a_xtnd, a_acc_fir_lshft;

reg   signed  [(NBITS_ACC-1):0]           acc;
reg   signed  [(NBITS_ACC-1):0]           acc_saturate, zreg;
wire   signed  [(NBITS_ACC-1):0]          acc_accadd_sel, acc_shift, acc_round, zreg_rshift;

assign clk = clk_i;
assign rst = rst_i;

assign a_acin_sel = a_sel_i ? a_cin_i : a_i;
assign b_bcin_sel = b_sel_i ? b_cin_i : b_i;

always @(posedge rst or posedge clk)
    if (rst) begin
        a_r <= {NBITS_A{1'b0}};
        b_r <= {NBITS_BC{1'b0}};
        c_r <= {NBITS_BC{1'b0}};
    end else begin
        a_r <= a_acin_sel;
        b_r <= b_bcin_sel;
        c_r <= c_i;
    end

assign a = a_reg_i ? a_r : a_acin_sel;
assign b = b_reg_i ? b_r : b_bcin_sel;
assign c = c_reg_i ? c_r : c_i;
assign preadd_raw = b + c;

always @(*) begin
    if (!b[(NBITS_BC-1)] && !c[(NBITS_BC-1)]) begin         // pos+pos
        if (preadd_raw[(NBITS_BC-1)]) begin
            preadd_sat = {1'b0, {(NBITS_BC-1){1'b1}}};      // max pos #
        end else begin
            preadd_sat = preadd_raw[(NBITS_BC-1):0];
        end
    end else begin
        if (b[(NBITS_BC-1)] && c[(NBITS_BC-1)]) begin         // neg+neg
            if (!preadd_raw[(NBITS_BC-1)]) begin
                preadd_sat = {1'b1, {(NBITS_BC-1){1'b0}}};  // max neg #
            end else begin
                preadd_sat = preadd_raw[(NBITS_BC-1):0];
            end
        end else begin                                      // pos+neg or neg+pos
            preadd_sat = preadd_raw[(NBITS_BC-1):0];
        end
    end
end

always @(posedge rst or posedge clk)
    if (rst) begin
        preadd_sat_r <= {NBITS_BC{1'b0}};
    end else begin
        preadd_sat_r <= preadd_sat;
    end

assign preadd = bc_reg_i ? preadd_sat_r : preadd_sat;

always @(*) begin
    case(feedback_i[2:0])
        0,1,2,3,4,5:    mult_a = a;
        6:              mult_a = acc[(NBITS_A-1):0];
        7:              mult_a = coeff_i;
    endcase
end
assign mult_bc = padd_sel_i ? preadd : b;

// multiplier
wire    [NBITS_A:0]             mult_a_in   ;
wire    [NBITS_BC:0]            mult_b_in   ;
wire    [NBITS_A+NBITS_BC+1:0]  mult_out    ;

assign mult_a_in = {mult_a[NBITS_A-1],mult_a};
assign mult_b_in = {mult_bc[NBITS_BC-1],mult_bc};
assign mult = mult_out[(NBITS_A+NBITS_BC-1):0];

DW02_mult # (
    .A_width    ( NBITS_A+1     ),
    .B_width    ( NBITS_BC+1    )
) i_mult (
    .A          ( mult_a_in     ),
    .B          ( mult_b_in     ),
    .TC         ( 1'b1          ),
    .PRODUCT    ( mult_out      )
);

assign mult_xtnd = {{(NBITS_ACC-NBITS_A-NBITS_BC){mult[NBITS_A+NBITS_BC-1]}}, mult[NBITS_A+NBITS_BC-1:0]};

always @(posedge rst or posedge clk) begin
    if (rst) begin
        mult_xtnd_r <= {NBITS_ACC{1'b0}};
    end else begin
        mult_xtnd_r <= mult_xtnd;
    end
end

assign mult_xtnd_sel = m_reg_i ? mult_xtnd_r : mult_xtnd;
//assign mult_xtnd_sub = subtract_i ? (~mult_xtnd_sel + 1) : mult_xtnd_sel;
assign mult_xtnd_sub = subtract_i ? -mult_xtnd_sel : mult_xtnd_sel;

assign ab_concat = {a,b};
assign accadd_a = (feedback_i[2:0] == 2) ? ab_concat : mult_xtnd_sub;

assign zcin_0_sel = z_cin_sel_i ? z_cin_i : {NBITS_Z{1'b0}};
assign zcin_xtnd = {{(NBITS_ACC-NBITS_Z){zcin_0_sel[NBITS_Z-1]}}, zcin_0_sel};
assign zcin_xtnd_rshift = zcin_xtnd >>> zc_shift_i;

//assign zreg_xtnd = {{(NBITS_ACC-NBITS_Z){zreg[NBITS_Z-1]}}, zreg};
//assign zreg_xtnd_rshift = zreg_xtnd >>> zreg_shift_i;
assign zreg_rshift = zreg >>> zreg_shift_i;

assign a_xtnd = {{(NBITS_ACC-NBITS_A){a[NBITS_A-1]}}, a};
assign a_acc_fir_lshft = a_xtnd <<< acc_fir_i;

always @(*) begin
    case(feedback_i[2:0])
        0:      accadd_b = acc;                 // acc
        1:      accadd_b = zcin_xtnd_rshift;    // z_cin_i w/ signxtnd and rshift
        2,3:    accadd_b = zcin_xtnd;           // z_cin_i
        4:      accadd_b = zreg;                // zreg
        5:      accadd_b = zreg_rshift;         // zreg rshift
        6,7:    accadd_b = a_acc_fir_lshft;     // a/acin w/ acc_fir lshift
    endcase
end

assign accadd_sum = accadd_a + accadd_b;

always @(posedge rst or posedge clk) begin
    if (rst) begin
        acc <= {NBITS_ACC{1'b0}};
    end else begin
        if (rst_acc_i) begin
            acc <= {NBITS_ACC{1'b0}};
        end else begin
            acc <= load_acc_i ? accadd_sum : acc;
        end
    end
end

assign acc_accadd_sel = out_sel_i[1] ? accadd_sum : acc;


round #(
    .NBITS_A        ( NBITS_ACC         )
) round_i0 (
    .a_i            ( acc_accadd_sel    ),
    .round_mode_i   ( round_i           ),
    .frac_bits_i    ( acc_shift_i       ),
    .z_o            ( acc_round         )
);


assign acc_shift = (acc_round >>> acc_shift_i);

always @(*) begin
    if (!saturate_i) begin
        acc_saturate = acc_shift;
    end else begin
        if ((|acc_shift[NBITS_ACC-1:NBITS_Z-1] == 1'b0) ||
            (&acc_shift[NBITS_ACC-1:NBITS_Z-1] == 1'b1) ) begin
            acc_saturate = {{(NBITS_ACC-NBITS_Z){1'b0}},{acc_shift[NBITS_Z-1:0]}};
        end else begin
            acc_saturate = {{(NBITS_ACC-NBITS_Z){1'b0}},{acc_shift[NBITS_ACC-1],{NBITS_Z-1{~acc_shift[NBITS_ACC-1]}}}};
        end
    end
end

always @(posedge rst or posedge clk) begin
    if (rst) begin
        zreg <= {NBITS_ACC{1'b0}};
    end else begin
        zreg <= (out_sel_i[2:0] == 3'b100) ? mult_xtnd_sel : acc_saturate;
    end
end


always @(*) begin
    case(out_sel_i[2:0])
        0:          z_o = mult_xtnd_sel[(NBITS_Z-1):0];
        1,2,3:      z_o = acc_saturate[(NBITS_Z-1):0];
        4,5,6,7:    z_o = zreg[(NBITS_Z-1):0];
    endcase
end


assign z_cout_o = z_o;
assign a_cout_o = a_r;
assign b_cout_o = b_r;

endmodule // dsp_type2_bw

module DW02_mult (A, B, TC, PRODUCT);
  parameter A_width = 8, B_width = 8;
  input wire [A_width-1:0] A; 
  input wire[B_width-1:0] B; 
  input wire TC; 

  output wire [A_width+B_width-1:0] PRODUCT;
  wire signed [A_width+B_width-1:0] product_sig; 
  wire [A_width+B_width-1:0] product_usig;

  assign product_sig = $signed(A) * $signed(B); 
  assign product_usig = A * B;
  assign PRODUCT = (TC == 1'b1) ? $unsigned(product_sig) : product_usig;
endmodule

module round #(
    parameter NBITS_A       = 64
) (
    input   wire   [(NBITS_A-1):0]     a_i             ,
    input   wire   [2:0]               round_mode_i    ,
    input   wire   [5:0]               frac_bits_i     ,
    output  wire   [(NBITS_A-1):0]     z_o
);

localparam  [2:0]   RMODE_NONE  = 3'b000    ;   // no rounding
localparam  [2:0]   RMODE_RHUA  = 3'b001    ;   // round half up, asymmetrical
localparam  [2:0]   RMODE_RHUS  = 3'b010    ;   // round half up, symmetrical
localparam  [2:0]   RMODE_RHDS  = 3'b011    ;   // round half down, symmetrical
localparam  [2:0]   RMODE_RHE   = 3'b100    ;   // round half even
localparam  [2:0]   RMODE_RHO   = 3'b101    ;   // round half odd

localparam                     NEG = 1'b1  ;
localparam                     POS = 1'b0  ;


wire   signed  [(NBITS_A-1):0]     a_in        ;
wire                               a_sign      ;

wire   signed  [(NBITS_A-1):0]     onehalf     ;
wire           [(NBITS_A-1):0]     int_mask    ;
wire           [(NBITS_A-1):0]     frac_mask   ;
wire   signed  [(NBITS_A-1):0]     a_frac      ;
wire   signed  [(NBITS_A-1):0]     a_int       ;
wire                               a_onehalf   ;
reg   signed  [(NBITS_A-1):0]     z_out       ;

assign a_in = $signed(a_i);
assign a_sign = a_in[(NBITS_A-1)];

assign onehalf = (frac_bits_i == 6'b0) ? {NBITS_A{1'b0}} : ({{(NBITS_A-1){1'b0}},1'b1} << (frac_bits_i-1));
assign int_mask = ({NBITS_A{1'b1}} << frac_bits_i);
assign frac_mask = ~int_mask;
assign a_frac = a_i & frac_mask;
assign a_int = a_i >>> frac_bits_i;
assign a_onehalf = (frac_bits_i == 6'b0) ? 1'b0 : (a_frac == onehalf);

always @ (*) begin
    case(round_mode_i)
        RMODE_NONE  :   // no rounding
                        z_out = a_in;

        RMODE_RHUA  :   // round half up, asymmetrical
                            // add 1/2
                        z_out = a_in + onehalf;

        RMODE_RHUS  :   // round half up, symmetrical
                            // if a is neg and a_frac = 1/2, do nothing, else add 1/2
                        if ((a_sign == NEG) && (a_frac == onehalf))
                            z_out = a_in;
                        else
                            z_out = a_in + onehalf;

        RMODE_RHDS  :   // round half down, symmetrical
                            // if a is pos and a_frac = 1/2, do nothing, else add 1/2
                        if ((a_sign == POS) && (a_frac == onehalf))
                            z_out = a_in;
                        else
                            z_out = a_in + onehalf;

        RMODE_RHE   :   // round half even
                            // if a is even and a_frac = 1/2, do nothing, else add 1/2
                        if ((a_int[0] == 1'b0) && (a_frac == onehalf))
                            z_out = a_in;
                        else
                            z_out = a_in + onehalf;

        RMODE_RHO   :   // round half odd
                            // if a is odd and a_frac = 1/2, do nothing, else add 1/2
                        if ((a_int[0] == 1'b1) && (a_frac == onehalf))
                            z_out = a_in;
                        else
                            z_out = a_in + onehalf;

        default     :   // no rounding
                        z_out = a_in;

    endcase
end

assign z_o = z_out;

endmodule