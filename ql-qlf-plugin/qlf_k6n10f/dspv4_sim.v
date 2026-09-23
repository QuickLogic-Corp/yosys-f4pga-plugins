
// ===========================================================================
// BEGIN ../rtl/DFFE_SNR_ANR.v
//----------------------------------------------------------------------------
//   R         : global asynchronous reset, active low   (highest priority)
//   LR        : local  synchronous  reset, active low   (disabled in scan)
//   E         : clock enable (recirculates Q when low)
//   D         : data in
//   SI / SE   : scan-in / scan-enable (only used under SCAN_VERIFICATION)
//   SCAN_MODE : holds the sync reset off during scan shift
//----------------------------------------------------------------------------
module DFFE_SNR_ANR (
    input  D,
    SI,
    SE,
    R,
    E,
    LR,
    CLK,
    SCAN_MODE,
    output Q
);
  reg q_reg;
  assign Q = q_reg;

  // Local sync reset, disabled in scan so it doesn't disturb the chain.
  wire sync_rst = !LR & !SCAN_MODE;

  // Clock enable: recirculate Q when not enabled.
  wire func_d = E ? D : q_reg;

  // Scan mux (behavioral; real mux comes from the mapped cell).
`ifdef SCAN_VERIFICATION
  wire d_in = SE ? SI : func_d;
`else
  wire d_in = func_d;
`endif

  always @(posedge CLK or negedge R) begin
    if (!R) q_reg <= 1'b0;  // global async reset (active low)
    else if (sync_rst) q_reg <= 1'b0;  // local sync reset (active low)
    else q_reg <= d_in;
  end
endmodule


module dff_bank #(
    parameter WIDTH = 1
) (
    input              CLK,
    input              R,    // global async reset, active low
    input              LR,   // local  sync  reset, active low
    input              E,    // clock enable
    input  [WIDTH-1:0] D,
    output [WIDTH-1:0] Q
);
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : g_dff
      DFFE_SNR_ANR u_dff (
          .D        (D[i]),
          .SI       (1'b0),
          .SE       (1'b0),
          .R        (R),
          .E        (E),
          .LR       (LR),
          .CLK      (CLK),
          .SCAN_MODE(1'b0),
          .Q        (Q[i])
      );
    end
  endgenerate
endmodule
// END ../rtl/DFFE_SNR_ANR.v

// ===========================================================================
// BEGIN ../rtl/alu.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module alu #(
    parameter W_WIDTH = 50,
    parameter X_WIDTH = 50,
    parameter Y_WIDTH = 50,
    parameter Z_WIDTH = 50,
    parameter ALU_OUT_WIDTH = 50,
    parameter CARRYOUT_WIDTH = 4
) (
    input [W_WIDTH-1:0] W,
    input [X_WIDTH-1:0] X,
    input [Y_WIDTH-1:0] Y,
    input [Z_WIDTH-1:0] Z,
    input [3:0] ALUMODE,
    input CIN,
    input [1:0] USE_SIMD,
    output [ALU_OUT_WIDTH-1:0] ALU_OUT,
    output [CARRYOUT_WIDTH-1:0] CARRYOUT
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  // NOTE: The reason ALUMODE is still 4 bits rather than 2 is so
  // that the wire modes can be easily re enabled. I prefer this
  // to a define based method which would parameterize the ALUMODE
  // bitwdith due to simplicity.

  localparam MUX_WIDTH = X_WIDTH;

  // SIMD segment boundaries (within 48-bit ALU field)
  localparam SEG0_LO = 0;
  localparam SEG0_HI = 11;  // bits [11:0]
  localparam SEG1_LO = 12;
  localparam SEG1_HI = 23;  // bits [23:12]
  localparam SEG2_LO = 24;
  localparam SEG2_HI = 35;  // bits [35:24]
  localparam SEG3_LO = 36;
  localparam SEG3_HI = 47;  // bits [47:36]

  // --------------------------------------------------------------------
  // Arithmetic datapath
  // --------------------------------------------------------------------
  wire [MUX_WIDTH-1:0] z_eff_arith;
  wire [MUX_WIDTH:0] wxy, wxy_eff;  // needs extra bit for carry
  wire cin_eff;

  reg [MUX_WIDTH-1:0] arith_result;
  wire [MUX_WIDTH:0] full_sum;  // 52 bits: 50-bit result + 1 carry bit

  assign wxy         = W + X + Y;

  // Bitwise inversion is 1's comp (~x = -x-1) for multibit signal
  // We can do this instead of twos comp because of the CIN term (single bit)
  assign z_eff_arith = (ALUMODE[0] ^ ALUMODE[1]) ? ~Z : Z;
  assign wxy_eff     = ALUMODE[1] ? ~wxy : wxy;
  assign cin_eff     = ALUMODE[1] ? ~CIN : CIN;

  // --- Full-width addition (ONE50 path) ---
  // Bitwidths of signals are matched for consistency
  assign full_sum    = {1'b0, z_eff_arith} + wxy_eff + {{MUX_WIDTH{1'b0}}, cin_eff};

  // ------------------------------------------------------------------------
  // cascade_carry — the carry out of bit (CASC_BIT-1): the 50-bit / PCOUT
  // boundary used to chain spatial wide add/sub (slice0 CARRYOUT[3] -> slice1
  // CCIN).  Drives CARRYOUT[3] in the 1x50 path (0 in SIMD).
  // ------------------------------------------------------------------------
  localparam CASC_BIT = 50;  // multiplier-product / PCOUT width
  wire [MUX_WIDTH:0] z_addend;
  wire               cascade_carry;
  assign z_addend = {1'b0, z_eff_arith};
  assign cascade_carry = (USE_SIMD == 2'b00)
                       ? (full_sum[CASC_BIT] ^ z_addend[CASC_BIT] ^ wxy_eff[CASC_BIT])
                       : 1'b0;

  // --------------------------------------------------------------------
  // SIMD segmented arithmetic datapath (TWO24 / FOUR12)
  // --------------------------------------------------------------------
  // Each 12-bit segment performs independent addition. Carry propagation
  // between segments is blocked according to the SIMD mode:
  //   TWO24  — carry propagates within each 24-bit half
  //            (seg0 -> seg1, seg2 -> seg3), blocked at seg1 -> seg2.
  //   FOUR12 — carry blocked between all four 12-bit segments.
  //
  // Segment sums are 13 bits wide to capture the carry-out bit.

  wire [12:0] simd_s0, simd_s1, simd_s2, simd_s3;
  wire simd_c0, simd_c1, simd_c2, simd_c3;

  // Segment 0 (bits [11:0]) — always receives cin_eff
  assign simd_s0 = {1'b0, z_eff_arith[SEG0_HI:SEG0_LO]}
                 + {1'b0, wxy_eff[SEG0_HI:SEG0_LO]}
                 + {12'b0, cin_eff};
  assign simd_c0 = simd_s0[12];

  // Segment 1 (bits [23:12])
  //   FOUR12: carry blocked — inject cin_eff so each segment gets its
  //           own +1 for two's complement subtract (cin_eff=0 for add).
  //   TWO24:  carry propagates from seg0 (within the lower 24-bit half).
  wire simd_c1_in = (USE_SIMD == 2'b10) ? cin_eff : simd_c0;

  assign simd_s1 = {1'b0, z_eff_arith[SEG1_HI:SEG1_LO]}
                 + {1'b0, wxy_eff[SEG1_HI:SEG1_LO]}
                 + {12'b0, simd_c1_in};
  assign simd_c1 = simd_s1[12];

  // Segment 2 (bits [35:24])
  //   Both TWO24 and FOUR12 block carry from seg1 (24-bit boundary).
  //   Inject cin_eff so this segment gets its own +1 for subtract.
  assign simd_s2 = {1'b0, z_eff_arith[SEG2_HI:SEG2_LO]}
                 + {1'b0, wxy_eff[SEG2_HI:SEG2_LO]}
                 + {12'b0, cin_eff};
  assign simd_c2 = simd_s2[12];

  // Segment 3 (bits [47:36])
  //   FOUR12: carry blocked — inject cin_eff for independent subtract.
  //   TWO24:  carry propagates from seg2 (within the upper 24-bit half).
  wire simd_c3_in = (USE_SIMD == 2'b10) ? cin_eff : simd_c2;

  assign simd_s3 = {1'b0, z_eff_arith[SEG3_HI:SEG3_LO]}
                 + {1'b0, wxy_eff[SEG3_HI:SEG3_LO]}
                 + {12'b0, simd_c3_in};
  assign simd_c3 = simd_s3[12];


  // Concatenate segment results into 50-bit SIMD result
  wire [MUX_WIDTH-1:0] simd_arith_result;
  assign simd_arith_result = {2'b00, simd_s3[11:0], simd_s2[11:0], simd_s1[11:0], simd_s0[11:0]};

  // --- Result mux: ONE50 uses full_sum, SIMD uses segmented path ---
  always @* begin
    case (USE_SIMD)
      2'b00:   arith_result = full_sum[ALU_OUT_WIDTH-1:0];
      2'b01:   arith_result = simd_arith_result;  // TWO24
      2'b10:   arith_result = simd_arith_result;  // FOUR12
      default: arith_result = full_sum[ALU_OUT_WIDTH-1:0];
    endcase
  end

  reg [3:0] arith_carryout;

  // Assign carryout depending on mode of operation
  // ONE50:  only CARRYOUT[3] is meaningful (carry out of bit 49).
  // TWO24:  CARRYOUT[1] and [3] are the valid segment carries;
  //         [0] and [2] are driven 0.
  // FOUR12: all four CARRYOUT bits are valid segment carries.
  always @* begin
    if (!USE_SIMD) begin
      // ONE50: CARRYOUT[3] is the carry out of bit 49 (the 50-bit P
      // boundary) -- this is also the inter-slice cascade carry.
      arith_carryout[3]   = cascade_carry;
      arith_carryout[2:0] = 3'b0;
      // If in TWO24 Mode: we only carryout for the 2x 24 bit segments
    end else if (USE_SIMD == 2'b01) begin
      arith_carryout[0] = 1'b0;
      arith_carryout[1] = simd_c1;
      arith_carryout[2] = 1'b0;
      arith_carryout[3] = simd_c3;
    end else begin
      // FOUR12: all four segment carries are output
      arith_carryout[0] = simd_c0;
      arith_carryout[1] = simd_c1;
      arith_carryout[2] = simd_c2;
      arith_carryout[3] = simd_c3;
    end
  end

  assign ALU_OUT  = arith_result;
  assign CARRYOUT = arith_carryout;

endmodule
// END ../rtl/alu.v

// ===========================================================================
// BEGIN ../rtl/b_path.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module b_path #(
    parameter B_WIDTH = 18,
    parameter BCIN_WIDTH = 18,
    parameter AD_DATA_WIDTH = 18,
    parameter BCOUT_WIDTH = 18,
    parameter XMUX_WIDTH = 18,
    parameter BGATE_OUT_WIDTH = 18,
    parameter BMULT_WIDTH = 18
) (
    input CLK,
    input CEB,
    input ARSTN,
    input RSTN,
    input [B_WIDTH-1:0] B,
    input [BCIN_WIDTH-1:0] BCIN,
    input [AD_DATA_WIDTH-1:0] AD_DATA,
    input INMODE_1,
    input INMODE_4,
    input PREADDINSEL,
    input BMULTSEL,
    input B_SEL,
    input B_COUT_SEL,
    input BREG0,
    input BREG1,
    output [BCOUT_WIDTH-1:0] BCOUT,
    output [XMUX_WIDTH-1:0] XMUX,
    output [BGATE_OUT_WIDTH-1:0] BGATE_OUT,
    output [BMULT_WIDTH-1:0] BMULT
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  //------------------------------------------------------
  // TODO: Instantiate sub-modules / add RTL here.
  //------------------------------------------------------

  wire g_arst_n, l_rst_n, clk;
  wire inmode_1_b;

  wire [(B_WIDTH-1):0] b_n_gate;

  assign g_arst_n   = ARSTN;  // global asynchronous reset (active low)
  assign l_rst_n    = RSTN;  // local  synchronous reset (active low)
  assign clk        = CLK;

  // Gating is only performed if we select the A input to the preadder
  assign inmode_1_b = PREADDINSEL ? INMODE_1 : 1'b0;

  reg_path #(
      .DATA_WIDTH(B_WIDTH)
  ) u_reg_path (
      .CLK(clk),
      .ARSTN(g_arst_n),
      .RSTN(l_rst_n),
      .CE(CEB),
      .IN(B),
      .CIN(BCIN),
      .NGATE(inmode_1_b),
      .IN_SEL(B_SEL),
      .REG_PATH_SEL(INMODE_4),
      .COUT_SEL(B_COUT_SEL),
      .REG0(BREG0),
      .REG1(BREG1),
      .PATH_OUT(XMUX),
      .GATE_OUT(b_n_gate),
      .COUT(BCOUT)
  );

  assign BGATE_OUT = b_n_gate;
  assign BMULT = BMULTSEL ? AD_DATA : b_n_gate;


endmodule
// END ../rtl/b_path.v

// ===========================================================================
// BEGIN ../rtl/multiplier.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module multiplier #(
    parameter I0_WIDTH = 18,
    parameter I1_WIDTH = 32,
    parameter U_WIDTH  = 50,
    parameter V_WIDTH  = 50
) (
    input [I0_WIDTH-1:0] I0,
    input [I1_WIDTH-1:0] I1,
    output [U_WIDTH-1:0] U,
    output [V_WIDTH-1:0] V,
    output KN
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  // The internal partial-product multiplier (pmult) uses the OPPOSITE order
  // (its I0 is the 32-bit multiplicand 'a', its I1 the 18-bit multiplier 'b'),
  // so the operands are crossed over below.

  // pmult emits the product in carry-save form as two 50-bit vectors plus
  // the dropped-carry flag K; exported inverted: U + V == product + KN*2^50.
  wire k;

  pmult #(
      .I0_WIDTH(I1_WIDTH),  // pmult.I0 = 32-bit  <- multiplier.I1
      .I1_WIDTH(I0_WIDTH),  // pmult.I1 = 18-bit  <- multiplier.I0
      .U_WIDTH (U_WIDTH),
      .V_WIDTH (V_WIDTH)
  ) u_pmult (
      .I0(I1),  // 32-bit operand
      .I1(I0),  // 18-bit operand
      .U (U),
      .V (V),
      .K (k)
  );

  assign KN = ~k;

endmodule
// END ../rtl/multiplier.v

// ===========================================================================
// BEGIN ./modules/pmult.v
//----------------------------------------------------------------------------
// BEHAVIORAL model of the multiplier pmult primitive.
//
// Replaces the Baugh-Wooley array + Wallace/CSA tree with a verilog multiply
// operator ('*'), then re-encodes the exact product P into a (U, V, K) triple 
// that satisfies the SAME behaviour as the silicon pmult implementation:
//
//   (1) U + V == P + (1-K)*2^50                      (exact, as integers)
//   (2) K == 1 implies P >= 0; K == 0 implies P < 0
//   (3) V[6:0] == 0                                  (structural: the 19-row tree cannot
//       produce carries in the sparse low columns; this allows us to not
//       instantiate MREG flops for V[6:0])
//
//
// We mask the U and V vectors s.t. they only have live even and odd bits,
// respectively. This is so downstream consumers cannot make assumptions about 
// which bits are and are not live.
//
//   U = P[6:0] plus the even bits of P[49:8]
//   V = the odd bits of P[49:7]
//   K = ~P[49]
//
// The reason we set K to be the inverse of P is because the inverse of signedness of
// P is equal to the "was a carry dropped?" flag and reflects the value of K we will get 
// from the silicon implementation.
// 
// Explanation below:
//
// - P >= 0, then p = P (carry was dropped) and K must be 1
// - P < 0, then p = P + 2^50 (carry was not dropped) and K must be 0
//
// For cases with negative products: the carry cannot be dropped (its not
// possible for U + V < 0). 
//
// NOTE: When thinking about these operations, we should basically consider
// everything to be unsigned arithemetic and the signedness of it only is
// resolved once we do one of the following:
// 
// 1. truncate to 50 bits (adds the (1-K)*2^50 term for 50 bit case)
// 2. pad with KN (adds the (1-K)*2^50 term for 64 bit case)
//
//----------------------------------------------------------------------------
module pmult #(
    parameter I0_WIDTH = 32,
    parameter I1_WIDTH = 18,
    parameter U_WIDTH  = 50,  // must equal I0_WIDTH + I1_WIDTH
    parameter V_WIDTH  = 50   // must equal U_WIDTH
) (
    input      [I0_WIDTH-1:0] I0,  // 32-bit two's-complement multiplicand 'a'
    input      [I1_WIDTH-1:0] I1,  // 18-bit two's-complement multiplier  'b'
    output reg [ U_WIDTH-1:0] U,   // carry-save SUM vector
    output reg [ V_WIDTH-1:0] V,   // carry-save CARRY vector
    output                    K    // dropped-carry flag
);

  // Low V bits that are structurally zero in the hardware tree; must match
  // MULT_V_LSB_ZEROS in dsp4_top.v (a property of the 19-row 32x18 tree).
  localparam V_LSB_ZEROS = 7;

  wire signed [I0_WIDTH-1:0] I0_s = I0;
  wire signed [I1_WIDTH-1:0] I1_s = I1;

  // Exact signed product; the assign truncates to P mod 2^50, which is exact
  // when I0_WIDTH + I1_WIDTH == U_WIDTH.
  wire [U_WIDTH-1:0] p;
  assign p = I0_s * I1_s;

  // Disjoint even/odd mask of p across U and V (U + V = U | V = P mod 2^50).
  // The bottom bits of V which will always resolve to 0 due to structure of
  // 19-row 32x18 CSA tree
  integer i;
  always @* begin
    for (i = 0; i < U_WIDTH; i = i + 1) begin
      if (i < V_LSB_ZEROS || i % 2 == 0) begin
        U[i] = p[i];
        V[i] = 1'b0;
      end else begin
        U[i] = 1'b0;
        V[i] = p[i];
      end
    end
  end

  assign K = ~p[U_WIDTH-1];
endmodule
// END ./modules/pmult.v

// ===========================================================================
// BEGIN ../rtl/preadd_path.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module preadd_path #(
    parameter A_WIDTH = 32,
    parameter ACIN_WIDTH = 32,
    parameter B_WIDTH = 18,
    parameter D_WIDTH = 27,
    parameter ACOUT_WIDTH = 32,
    parameter AD_WIDTH = 32,
    parameter XMUX_WIDTH = 32
) (
    input [A_WIDTH-1:0] A,
    input [ACIN_WIDTH-1:0] ACIN,
    input [B_WIDTH-1:0] B,
    input [D_WIDTH-1:0] D,
    input [3:0] INMODE,
    input PREADDINSEL,
    input AMULTSEL,
    input A_SEL,
    input A_COUT_SEL,
    input AREG0,
    input AREG1,
    input DREG,
    input ADREG,
    input CLK,
    input CEA,
    input CED,
    input ARSTN,
    input RSTN,
    output [ACOUT_WIDTH-1:0] ACOUT,
    output [AD_WIDTH-1:0] AD,
    output [XMUX_WIDTH-1:0] XMUX
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  //------------------------------------------------------
  // TODO: Instantiate sub-modules / add RTL here.
  //------------------------------------------------------

  wire g_arst_n, l_rst_n, clk;

  wire inmode_1_a;

  wire [(A_WIDTH-1):0] a_acin_sel, a_r1_sel, a_r2_sel, a_r1, a_r2;
  wire [(D_WIDTH-1):0] d_r1_sel, d_r1;

  wire signed [(A_WIDTH-1):0] a_reg_path_sel, a_n_gate, preadd_ab;
  wire signed [(D_WIDTH-1):0] preadd_d;


  wire signed [A_WIDTH-1:0] preadd_sat, preadd_sat_r, preadd_r_sel;

  assign g_arst_n   = ARSTN;  // global asynchronous reset (active low)
  assign l_rst_n    = RSTN;  // local  synchronous reset (active low)
  assign clk        = CLK;

  // Gating is only performed if we select the A input to the preadder
  assign inmode_1_a = PREADDINSEL ? 1'b0 : INMODE[1];

  // Instantiate module for common reg / mux path
  reg_path #(
      .DATA_WIDTH(A_WIDTH)
  ) u_reg_path (
      .CLK(clk),
      .ARSTN(g_arst_n),
      .RSTN(l_rst_n),
      .CE(CEA),
      .IN(A),
      .CIN(ACIN),
      .NGATE(inmode_1_a),
      .IN_SEL(A_SEL),
      .REG_PATH_SEL(INMODE[0]),
      .COUT_SEL(A_COUT_SEL),
      .REG0(AREG0),
      .REG1(AREG1),
      .PATH_OUT(XMUX),
      .GATE_OUT(a_n_gate),
      .COUT(ACOUT)
  );


  assign d_r1_sel = DREG ? d_r1 : D;

  // D reg #0 — DFFE_SNR_ANR flop bank, gated by CED.
  dff_bank #(
      .WIDTH(D_WIDTH)
  ) u_d_r1 (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CED),
      .D  (D),
      .Q  (d_r1)
  );

  // Sign extend B signal and mux to input of preadder
  assign preadd_ab = PREADDINSEL ? {
    {(A_WIDTH - B_WIDTH) {B[B_WIDTH-1]}},
    B[B_WIDTH-1:0]
  } : a_n_gate ;

  // gate d input (can be zeroed based on INMODE[2])
  assign preadd_d = INMODE[2] ? d_r1_sel : {D_WIDTH{1'b0}};

  // Pre-adder core: AD = ( D +/- (A|B) )[AD_WIDTH-1:0],
  // wrapping (two's complement) on overflow.  INMODE[3] selects add/sub.
  preadder #(
      .I0_WIDTH(D_WIDTH),
      .I1_WIDTH(A_WIDTH),
      .AD_WIDTH(A_WIDTH)
  ) u_preadder (
      .I0     (preadd_d),
      .I1     (preadd_ab),
      .INMODE3(INMODE[3]),
      .AD     (preadd_sat)
  );

  // AD register — DFFE_SNR_ANR flop bank, always enabled (no clock gate).
  dff_bank #(
      .WIDTH(A_WIDTH)
  ) u_preadd_sat_r (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (1'b1),
      .D  (preadd_sat),
      .Q  (preadd_sat_r)
  );

  assign preadd_r_sel = ADREG ? preadd_sat_r : preadd_sat;

  // Outputs
  assign AD = preadd_r_sel;

endmodule
// END ../rtl/preadd_path.v

// ===========================================================================
// BEGIN ../rtl/preadder.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module preadder #(
    parameter I0_WIDTH = 27,
    parameter I1_WIDTH = 32,
    parameter AD_WIDTH = 32
) (
    input [I0_WIDTH-1:0] I0,
    input [I1_WIDTH-1:0] I1,
    input INMODE3,
    output [AD_WIDTH-1:0] AD
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  wire signed [I0_WIDTH-1:0] I0_s;
  wire signed [I1_WIDTH-1:0] I1_s;
  wire signed [  I1_WIDTH:0] raw;  // (I1_WIDTH+1)-bit signed sum/difference

  assign I0_s = I0;
  assign I1_s = I1;

  assign raw  = INMODE3 ? (I0_s - I1_s) : (I0_s + I1_s);
  assign AD   = raw[AD_WIDTH-1:0];

endmodule
// END ../rtl/preadder.v

// ===========================================================================
// BEGIN ../rtl/reg_path.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module reg_path #(
    parameter DATA_WIDTH = 18
) (
    input CLK,
    input ARSTN,
    input RSTN,
    input [DATA_WIDTH-1:0] IN,
    input [DATA_WIDTH-1:0] CIN,
    input NGATE,
    input IN_SEL,
    input REG_PATH_SEL,
    input COUT_SEL,
    input REG0,
    input REG1,
    input CE,
    output [DATA_WIDTH-1:0] PATH_OUT,
    output [DATA_WIDTH-1:0] GATE_OUT,
    output [DATA_WIDTH-1:0] COUT
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  //------------------------------------------------------
  // TODO: Instantiate sub-modules / add RTL here.
  //------------------------------------------------------

  wire g_arst_n, l_rst_n, clk;

  wire [(DATA_WIDTH-1):0] a_acin_sel, a_r1_sel, a_r2_sel, a_r1, a_r2;
  wire [(DATA_WIDTH-1):0] a_reg_path_sel, a_n_gate;

  assign g_arst_n   = ARSTN;  // global asynchronous reset (active low)
  assign l_rst_n    = RSTN;  // local  synchronous reset (active low)
  assign clk        = CLK;

  // MUX #0: Selects b/w general routing & cascade inputs
  assign a_acin_sel = IN_SEL ? CIN : IN;
  // MUX #1: Selects b/w registered & unregistered inputs
  assign a_r1_sel   = REG0 ? a_r1 : a_acin_sel;
  // MUX #2: Selects b/w 0-2 registered & unregistered inputs
  assign a_r2_sel   = REG1 ? a_r2 : a_acin_sel;

  // reg #0 / #1 — DFFE_SNR_ANR flop banks; CE gates both.
  dff_bank #(
      .WIDTH(DATA_WIDTH)
  ) u_a_r1 (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CE),
      .D  (a_acin_sel),
      .Q  (a_r1)
  );
  dff_bank #(
      .WIDTH(DATA_WIDTH)
  ) u_a_r2 (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CE),
      .D  (a_r1_sel),
      .Q  (a_r2)
  );

  // Select between a possible reg path ( 0 to 2 regs) and 1 reg path
  assign a_reg_path_sel = REG_PATH_SEL ? a_r1 : a_r2_sel;
  // Output of upper path (0 to 2 regs)
  assign PATH_OUT = a_r2_sel;
  // Gate a_reg_path_sel (can be zeroed based on ~INMODE[1])
  assign GATE_OUT = NGATE ? {DATA_WIDTH{1'b0}} : a_reg_path_sel;
  assign COUT = COUT_SEL ? a_r1 : a_r2_sel;

endmodule
// END ../rtl/reg_path.v

// ===========================================================================
// BEGIN ../rtl/round.v
/*-----------------------------------------------------------------------------
round.sv

This module rounds the input, so that the fractional bits may be truncated
later (truncation is not performed in this module). The rounding mode is
specified as an input bus, as is the number of fractional bits in the input bus.

Any fractional values that are not exactly 0.5 are rounded to the nearest
integer (after truncation). For example:
    2.49 -> 2, 2.51 -> 3, -2.49 -> -2, -2.51 -> -3
The rounding modes determine how frational values exactly equal to 0.5 are
rounded to one of the nearest integers.

Rounding modes:                 -1.5  -0.5   0.5   1.5
--------------------------------------------------------
no round                        -1.5  -0.5   0.5   1.5
round half up, asymmetrical     -1     0     1     2        // round towards pos infinity
round half up, symmetrical      -2    -1     1     2        // round away from zero
round half down, symmetrical    -1     0     0     1        // round towards zero
round half even                 -2     0     0     2        // round to nearest even
round half odd                  -1    -1     1     1        // round to nearest odd

-----------------------------------------------------------------------------*/

module round #(
    parameter NBITS_A = 64
) (
    input  [(NBITS_A-1):0] a_i,
    input  [          2:0] round_mode_i,
    input  [          5:0] frac_bits_i,
    output [(NBITS_A-1):0] z_o
);

  localparam [2:0] RMODE_NONE = 3'b000;  // no rounding
  localparam [2:0] RMODE_RHUA = 3'b001;  // round half up, asymmetrical
  localparam [2:0] RMODE_RHUS = 3'b010;  // round half up, symmetrical
  localparam [2:0] RMODE_RHDS = 3'b011;  // round half down, symmetrical
  localparam [2:0] RMODE_RHE = 3'b100;  // round half even
  localparam [2:0] RMODE_RHO = 3'b101;  // round half odd

  localparam NEG = 1'b1;
  localparam POS = 1'b0;


  wire signed [(NBITS_A-1):0] a_in;
  wire                        a_sign;

  wire signed [(NBITS_A-1):0] onehalf;
  wire        [(NBITS_A-1):0] int_mask;
  wire        [(NBITS_A-1):0] frac_mask;
  wire signed [(NBITS_A-1):0] a_frac;
  wire signed [(NBITS_A-1):0] a_int;
  wire                        a_onehalf;
  reg signed  [(NBITS_A-1):0] z_out;

  assign a_in = $signed(a_i);
  assign a_sign = a_in[(NBITS_A-1)];

  assign onehalf = (frac_bits_i == 6'b0) ? {NBITS_A{1'b0}} : ({{(NBITS_A-1){1'b0}},1'b1} << (frac_bits_i-1));
  assign int_mask = ({NBITS_A{1'b1}} << frac_bits_i);
  assign frac_mask = ~int_mask;
  assign a_frac = a_i & frac_mask;
  assign a_int = a_i >>> frac_bits_i;
  assign a_onehalf = (frac_bits_i == 6'b0) ? 1'b0 : (a_frac == onehalf);

  always @* begin
    case (round_mode_i)
      RMODE_NONE:  // no rounding
      z_out = a_in;

      RMODE_RHUA:  // round half up, asymmetrical
      // add 1/2
      z_out = a_in + onehalf;

      RMODE_RHUS:  // round half up, symmetrical
      // if a is neg and a_frac = 1/2, do nothing, else add 1/2
      if ((a_sign == NEG) && (a_frac == onehalf))
        z_out = a_in;
      else z_out = a_in + onehalf;

      RMODE_RHDS:  // round half down, symmetrical
      // if a is pos and a_frac = 1/2, do nothing, else add 1/2
      if ((a_sign == POS) && (a_frac == onehalf))
        z_out = a_in;
      else z_out = a_in + onehalf;

      RMODE_RHE:  // round half even
      // if a is even and a_frac = 1/2, do nothing, else add 1/2
      if ((a_int[0] == 1'b0) && (a_frac == onehalf))
        z_out = a_in;
      else z_out = a_in + onehalf;

      RMODE_RHO:  // round half odd
      // if a is odd and a_frac = 1/2, do nothing, else add 1/2
      if ((a_int[0] == 1'b1) && (a_frac == onehalf))
        z_out = a_in;
      else z_out = a_in + onehalf;

      default:  // no rounding
      z_out = a_in;

    endcase
  end

  assign z_o = z_out;

endmodule
// END ../rtl/round.v

// ===========================================================================
// BEGIN ../rtl/rss_block.v
// =============================================================================
// RSS (Round / Shift / Saturate) Block
// =============================================================================
module rss_block #(
    parameter Z_WIDTH   = 50,
    parameter ACC_WIDTH = 64
) (

    input  [ACC_WIDTH-1:0] acc_in,
    output [ACC_WIDTH-1:0] acc_out,

    // Configuration
    input [2:0] round_i,
    input [5:0] acc_shift_i,
    input       saturate_i
);

  wire signed [(ACC_WIDTH-1):0] round_in;
  wire signed [(ACC_WIDTH-1):0] acc_shift, acc_round;
  reg signed [(ACC_WIDTH-1):0] acc_saturate;


  assign round_in = acc_in;

  round #(
      .NBITS_A(ACC_WIDTH)
  ) round_i0 (
      .a_i         (round_in),
      .round_mode_i(round_i),
      .frac_bits_i (acc_shift_i),
      .z_o         (acc_round)
  );

  assign acc_shift = (acc_round >>> acc_shift_i);

  always @* begin
    if (!saturate_i) begin
      acc_saturate = acc_shift;
    end else begin
      if ((|acc_shift[ACC_WIDTH-1:Z_WIDTH-1] == 1'b0) ||
            (&acc_shift[ACC_WIDTH-1:Z_WIDTH-1] == 1'b1) ) begin
        acc_saturate = {{(ACC_WIDTH - Z_WIDTH) {1'b0}}, {acc_shift[Z_WIDTH-1:0]}};
      end else begin
        acc_saturate = {
          {(ACC_WIDTH - Z_WIDTH) {1'b0}},
          {acc_shift[ACC_WIDTH-1], {Z_WIDTH - 1{~acc_shift[ACC_WIDTH-1]}}}
        };
      end
    end
  end

  assign acc_out = acc_saturate;

endmodule
// END ../rtl/rss_block.v

// ===========================================================================
// BEGIN ../rtl/dsp4_top.v
// --- BEGIN AUTO-GENERATED PORT DEFINITION (do not edit) ---
module dsp4_top #(
    parameter A_WIDTH = 32,
    parameter B_WIDTH = 18,
    parameter C_WIDTH = 50,
    parameter D_WIDTH = 27,
    parameter ACIN_WIDTH = 32,
    parameter BCIN_WIDTH = 18,
    parameter PCIN_WIDTH = 50,
    parameter P_WIDTH = 50,
    parameter ACOUT_WIDTH = 32,
    parameter BCOUT_WIDTH = 18,
    parameter PCOUT_WIDTH = 50,
    parameter COUT_WIDTH = 4
) (
    input [A_WIDTH-1:0] A,
    input [B_WIDTH-1:0] B,
    input [C_WIDTH-1:0] C,
    input [D_WIDTH-1:0] D,
    input [ACIN_WIDTH-1:0] ACIN,
    input [BCIN_WIDTH-1:0] BCIN,
    input [PCIN_WIDTH-1:0] PCIN,
    input CCIN,
    input SIGNCIN,
    input CIN,
    output [P_WIDTH-1:0] P,
    output [ACOUT_WIDTH-1:0] ACOUT,
    output [BCOUT_WIDTH-1:0] BCOUT,
    output [PCOUT_WIDTH-1:0] PCOUT,
    output CCOUT,
    output SIGNCOUT,
    output [COUT_WIDTH-1:0] COUT,
    input [8:0] OPMODE,
    input [1:0] ALUMODE,
    input [4:0] INMODE,
    input [2:0] CARRYINSEL,
    input CLK,
    input CEA,
    input CEB,
    input CEC,
    input CED,
    input CEP,
    input ARSTN,
    input RSTN,
    input ACCRSTN,
    input AREG0,
    input AREG1,
    input BREG0,
    input BREG1,
    input A_COUT_SEL,
    input B_COUT_SEL,
    input CREG,
    input DREG,
    input ADREG,
    input MREG,
    input PREG,
    input COUTREG,
    input A_IN_SEL,
    input B_IN_SEL,
    input AMULTSEL,
    input BMULTSEL,
    input PREADDINSEL,
    input [1:0] USE_SIMD,
    input USE_RSS,
    input [2:0] ROUND,
    input [5:0] SHIFT,
    input SATURATE
);
  // --- END AUTO-GENERATED PORT DEFINITION ---

  // ========================================================================
  // Internal parameters
  // ========================================================================
  localparam MULT_A_WIDTH = 32;  // A/AD width to multiplier
  localparam MULT_B_WIDTH = 18;  // B/AD width to multiplier
  localparam MULT_P_WIDTH = MULT_A_WIDTH + MULT_B_WIDTH;  // 50 bits
  // Structurally-zero low bits of the multiplier carry vector V (property
  // of its 19-row reduction tree). Only V[49:7] is ever registered.
  localparam MULT_V_LSB_ZEROS = 7;
  localparam ACC_WIDTH = 64;  // wide internal accumulator (P_WIDTH=50 = external port width)
  localparam AB_WIDTH = A_WIDTH + B_WIDTH;  // 50 bits (A:B concatenation)

  wire clk, g_arst_n, l_rst_n, CE;
  assign clk = CLK;
  assign l_rst_n = RSTN;  // local  synchronous reset (active low)
  assign g_arst_n = ARSTN;  // global asynchronous reset (active low)


  // Global CE is tied to 1, if required we can bring this to IO ports
  assign CE = 1;

  // ========================================================================
  // Preadd path (A/D) — submodule  (pre-adder core is the `preadder` macro,
  // instantiated inside preadd_path; input/AD registers stay in preadd_path)
  // ========================================================================
  wire [A_WIDTH-1:0]  preadd_xmux;   // A path output for X mux (A:B concat)
  wire [A_WIDTH-1:0]  preadd_ad;     // Pre-adder output to multiplier
  wire [ACOUT_WIDTH-1:0] acout_int;

  wire [B_WIDTH-1:0]  b_gate;     // B gate out

  preadd_path #(
      .A_WIDTH    (A_WIDTH),
      .ACIN_WIDTH (ACIN_WIDTH),
      .B_WIDTH    (B_WIDTH),
      .D_WIDTH    (D_WIDTH),
      .ACOUT_WIDTH(ACOUT_WIDTH),
      .AD_WIDTH   (A_WIDTH),
      .XMUX_WIDTH (A_WIDTH)
  ) u_preadd_path (
      .A          (A),
      .ACIN       (ACIN),
      .B          (b_gate),
      .D          (D),
      .INMODE     (INMODE[3:0]),
      .PREADDINSEL(PREADDINSEL),
      .AMULTSEL   (AMULTSEL),
      .A_SEL      (A_IN_SEL),
      .A_COUT_SEL (A_COUT_SEL),
      .AREG0      (AREG0),
      .AREG1      (AREG1),
      .DREG       (DREG),
      .ADREG      (ADREG),
      .CLK        (clk),
      .CEA        (CEA),
      .CED        (CED),
      .ARSTN      (g_arst_n),
      .RSTN       (l_rst_n),
      .ACOUT      (acout_int),
      .AD         (preadd_ad),
      .XMUX       (preadd_xmux)
  );

  // ========================================================================
  // B path — submodule
  // ========================================================================
  wire [B_WIDTH-1:0]  b_xmux;     // B path output for X mux (A:B concat)
  wire [B_WIDTH-1:0]  b_mult;     // B path output to multiplier
  wire [BCOUT_WIDTH-1:0] bcout_int;

  b_path #(
      .B_WIDTH      (B_WIDTH),
      .BCIN_WIDTH   (BCIN_WIDTH),
      .AD_DATA_WIDTH(B_WIDTH),
      .BCOUT_WIDTH  (BCOUT_WIDTH),
      .XMUX_WIDTH   (B_WIDTH),
      .BMULT_WIDTH  (B_WIDTH)
  ) u_b_path (
      .CLK        (clk),
      .CEB        (CEB),
      .ARSTN      (g_arst_n),
      .RSTN       (l_rst_n),
      .B          (B),
      .BCIN       (BCIN),
      .AD_DATA    (preadd_ad[B_WIDTH-1:0]),
      .INMODE_1   (INMODE[1]),
      .INMODE_4   (INMODE[4]),
      .PREADDINSEL(PREADDINSEL),
      .BMULTSEL   (BMULTSEL),
      .B_SEL      (B_IN_SEL),
      .B_COUT_SEL (B_COUT_SEL),
      .BREG0      (BREG0),
      .BREG1      (BREG1),
      .BCOUT      (bcout_int),
      .XMUX       (b_xmux),
      .BGATE_OUT  (b_gate),
      .BMULT      (b_mult)
  );

  // ========================================================================
  // C register (optional 1-stage pipeline)
  // ========================================================================
  wire [C_WIDTH-1:0] c_reg, c_sel;

  // C register — DFFE_SNR_ANR flop bank, gated by CEC.
  dff_bank #(
      .WIDTH(C_WIDTH)
  ) u_c_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CEC),
      .D  (C),
      .Q  (c_reg)
  );

  assign c_sel = CREG ? c_reg : C;

  wire signed [MULT_A_WIDTH-1:0] mult_a;  // 32-bit MULT port (I1): AD or raw A

  assign mult_a = AMULTSEL ? preadd_ad : preadd_xmux;  // MULT_I1_SEL

  wire [MULT_P_WIDTH-1:0] mult_pp_U_out, mult_pp_V_out;
  wire [MULT_P_WIDTH-1:0] mult_pp_U_reg, mult_pp_U_sel, mult_pp_V_reg, mult_pp_V_sel;
  wire mult_pp_KN_out, mult_pp_KN_reg, mult_pp_KN_sel;

  // `multiplier` wraps the partial-product multiplier (pmult).  Convention
  // here: I0 = 18-bit B operand, I1 = 32-bit A operand.  It emits the product
  // in carry-save form (U = sum vector, V = carry vector) plus the inverted
  // dropped-carry flag KN:  U + V == product + KN*2^50 as integers.  U + V
  // is resolved by the ALU via the X/Y muxes below; KN pads the X-mux value
  // so the 64-bit resolution is exact.
  multiplier #(
      .I0_WIDTH(MULT_B_WIDTH),
      .I1_WIDTH(MULT_A_WIDTH),
      .U_WIDTH (MULT_P_WIDTH),
      .V_WIDTH (MULT_P_WIDTH)
  ) u_multiplier (
      .I0(b_mult),
      .I1(mult_a),
      .U (mult_pp_U_out),
      .V (mult_pp_V_out),
      .KN(mult_pp_KN_out)
  );

  // MREG (optional 1-stage pipeline on multiplier output) — DFFE_SNR_ANR banks.
  dff_bank #(
      .WIDTH(MULT_P_WIDTH)
  ) u_mult_pp_U_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CE),
      .D  (mult_pp_U_out),
      .Q  (mult_pp_U_reg)
  );
  // V[6:0] is structurally constant 0 (dead low bits of the carry vector),
  // so only the 43 live bits [49:7] get MREG flops; the low bits are tied
  // to 0 after the register so no flops are ever instantiated for them.
  dff_bank #(
      .WIDTH(MULT_P_WIDTH - MULT_V_LSB_ZEROS)
  ) u_mult_pp_V_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CE),
      .D  (mult_pp_V_out[MULT_P_WIDTH-1:MULT_V_LSB_ZEROS]),
      .Q  (mult_pp_V_reg[MULT_P_WIDTH-1:MULT_V_LSB_ZEROS])
  );
  assign mult_pp_V_reg[MULT_V_LSB_ZEROS-1:0] = {MULT_V_LSB_ZEROS{1'b0}};
  // KN pipelines in lockstep with U/V so the X-mux pad stays aligned.
  dff_bank #(
      .WIDTH(1)
  ) u_mult_pp_KN_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (CE),
      .D  (mult_pp_KN_out),
      .Q  (mult_pp_KN_reg)
  );

  assign mult_pp_U_sel  = MREG ? mult_pp_U_reg : mult_pp_U_out;
  assign mult_pp_V_sel  = MREG ? mult_pp_V_reg : mult_pp_V_out;
  assign mult_pp_KN_sel = MREG ? mult_pp_KN_reg : mult_pp_KN_out;

  // ========================================================================
  // W / X / Y / Z Muxes (selected by OPMODE)
  // ========================================================================
  reg [ACC_WIDTH-1:0] w_mux, x_mux, y_mux, z_mux;

  // ========================================================================
  // P accumulator register (64b) — captures the RAW ALU result and feeds it
  // back to ALU input muxes.
  // ========================================================================
  wire [ACC_WIDTH-1:0] p_reg;

  // Accumulator select output node (goes to RSS) and to output
  // Selects between registered and unregistered output of the ALU
  wire [ACC_WIDTH-1:0] p_acc;

  // -- W mux: OPMODE[8:7] --
  always @* begin
    case (OPMODE[8:7])
      2'b00:   w_mux = {ACC_WIDTH{1'b0}};  // 0 mode
      2'b01:   w_mux = p_reg;  // P feedback (full 64b)
      2'b10:   w_mux = {ACC_WIDTH{1'b0}};  // UNUSED
      2'b11:   w_mux = {{(ACC_WIDTH - C_WIDTH) {c_sel[C_WIDTH-1]}}, c_sel};  // C (sign-extended)
      default: w_mux = {ACC_WIDTH{1'b0}};
    endcase
  end

  // -- X mux: OPMODE[1:0] --
  always @* begin
    case (OPMODE[1:0])
      2'b00: x_mux = {ACC_WIDTH{1'b0}};
      2'b01:
      x_mux = {
        {(ACC_WIDTH - MULT_P_WIDTH) {mult_pp_KN_sel}}, mult_pp_U_sel
      };  // U padded with KN (NOT sign-extended: U is unsigned; the pad
      // repays the Baugh-Wooley +2^50 excess iff no CSA carry dropped).
      // Paired with the Y mux V value: X + Y == exact 64-bit product.
      2'b10: x_mux = p_reg;  // P feedback (full 64b)
      2'b11:
      x_mux = {
        {(ACC_WIDTH - AB_WIDTH) {preadd_xmux[A_WIDTH-1]}}, preadd_xmux, b_xmux
      };  // A:B (sign-extended)
      default: x_mux = {ACC_WIDTH{1'b0}};
    endcase
  end

  // -- Y mux: OPMODE[3:2] --
  always @* begin
    case (OPMODE[3:2])
      2'b00: y_mux = {ACC_WIDTH{1'b0}};
      2'b01:
      y_mux = {
        {(ACC_WIDTH - MULT_P_WIDTH) {1'b0}}, mult_pp_V_sel
      };  // V zero-extended (unsigned carry vector) paired with X mux U value.
      2'b10: y_mux = {ACC_WIDTH{1'b0}};  // UNUSED
      2'b11: y_mux = {{(ACC_WIDTH - C_WIDTH) {c_sel[C_WIDTH-1]}}, c_sel};  // C (sign-extended)
      default: y_mux = {ACC_WIDTH{1'b0}};
    endcase
  end

  // -- Z mux: OPMODE[6:4] --
  // The >>17 paths operate on the low-50 window of the accumulator
  // (P_WIDTH bits) and are sign-extended to ACC_WIDTH.

  // MACC_EXT (100): sign-extension word for the upper limb of a one-shot
  // signed multi-slice multiply accumulate.
  wire [ACC_WIDTH-1:0] macc_ext;
  assign macc_ext = {ACC_WIDTH{SIGNCIN}};

  // 17-bit right shift of PCIN (sign-extended)
  wire [ACC_WIDTH-1:0] pcin_shift17;
  assign pcin_shift17 = {
    {(ACC_WIDTH - P_WIDTH) {PCIN[PCIN_WIDTH-1]}}, {17{PCIN[PCIN_WIDTH-1]}}, PCIN[PCIN_WIDTH-1:17]
  };

  // 17-bit right shift of P (sign-extended)
  wire [ACC_WIDTH-1:0] p_shift17;
  assign p_shift17 = {
    {(ACC_WIDTH - P_WIDTH) {p_reg[P_WIDTH-1]}}, {17{p_reg[P_WIDTH-1]}}, p_reg[P_WIDTH-1:17]
  };


  always @* begin
    case (OPMODE[6:4])
      3'b000: z_mux = {ACC_WIDTH{1'b0}};
      3'b001:
      z_mux = {{(ACC_WIDTH - PCIN_WIDTH) {PCIN[PCIN_WIDTH-1]}}, PCIN};  // PCIN (sign-extended)
      3'b010: z_mux = p_reg;  // P feedback (direct from reg) (full 64b)
      3'b011: z_mux = {{(ACC_WIDTH - C_WIDTH) {c_sel[C_WIDTH-1]}}, c_sel};  // C (sign-extended)
      3'b100: z_mux = macc_ext;  // MACC_EXT
      3'b101: z_mux = pcin_shift17;  // PCIN >> 17
      3'b110: z_mux = p_shift17;  // P >> 17
      default: z_mux = {ACC_WIDTH{1'b0}};
    endcase
  end

  // ========================================================================
  // CARRYINSEL mux (resolves carry-in to ALU)
  //
  //   000 — CIN          : carry from fabric / general interconnect
  //   010 — CCIN      : cascaded carry from adjacent (lower) slice
  //   100 — carryout_reg[3] : this slice's own REGISTERED carry-out, fed
  //                           back for wide / multi-cycle add/sub/acc.
  // ========================================================================
  reg cin_resolved;
  wire [COUT_WIDTH-1:0] carryout_reg;

  always @* begin
    case (CARRYINSEL)
      3'b000: cin_resolved = CIN;  // general interconnect
      3'b010: cin_resolved = CCIN;  // cascaded carry from adjacent (lower) slice
      3'b100:
      cin_resolved = carryout_reg[COUT_WIDTH-1];  // registered carry feedback (wide add/sub/acc)
      default: cin_resolved = 1'b0;
    endcase
  end

  // ========================================================================
  // ALU — submodule
  // ========================================================================
  wire [ ACC_WIDTH-1:0] alu_result;
  wire [COUT_WIDTH-1:0] carryout_int;

  alu #(
      .W_WIDTH       (ACC_WIDTH),
      .X_WIDTH       (ACC_WIDTH),
      .Y_WIDTH       (ACC_WIDTH),
      .Z_WIDTH       (ACC_WIDTH),
      .ALU_OUT_WIDTH (ACC_WIDTH),
      .CARRYOUT_WIDTH(COUT_WIDTH)
  ) u_alu (
      .W       (w_mux),
      .X       (x_mux),
      .Y       (y_mux),
      .Z       (z_mux),
      .ALUMODE ({2'b00, ALUMODE}),  // top ALUMODE is 2-bit; ALU port is 4-bit
      .CIN     (cin_resolved),
      .USE_SIMD(USE_SIMD),
      .ALU_OUT (alu_result),
      .CARRYOUT(carryout_int)
  );


  // The accumulator's local sync reset folds in the dedicated ACCRSTN: the P
  // register clears on either the local sync reset (RSTN) or ACCRSTN.
  wire l_rst_n_acc;
  assign l_rst_n_acc = l_rst_n & ACCRSTN;

  // P accumulator register — DFFE_SNR_ANR flop bank, gated by CEP.
  dff_bank #(
      .WIDTH(ACC_WIDTH)
  ) u_p_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n_acc),
      .E  (CEP),
      .D  (alu_result),
      .Q  (p_reg)
  );

  // Accumulator feedback (64b): registered (PREG=1) or combinational bypass.
  assign p_acc = PREG ? p_reg : alu_result;

  // Cascade carry: CARRYOUT[3] is the ALU's carry out of bit 49 (the 50-bit P /
  // PCOUT boundary).  Valid for a 2-operand add; CCOUT is don't-care otherwise
  // (SIMD / >2-operand ops).  CCOUT is a tap of COUT[3], so the single
  // carry-out register bank (COUTREG) serves both outputs.

  // ========================================================================
  // RSS (Round / Shift / Saturate) on the accumulator OUTPUT: windows the 64b
  // accumulator down to the 50b P output (SHIFT selects which 50b slice).
  // ========================================================================
  wire [ACC_WIDTH-1:0] rss_out;

  rss_block #(
      .Z_WIDTH  (P_WIDTH),
      .ACC_WIDTH(ACC_WIDTH)
  ) u_rss (
      .acc_in(p_acc),
      .acc_out(rss_out),
      .round_i(ROUND),
      .acc_shift_i(SHIFT),
      .saturate_i(SATURATE)
  );

  wire [COUT_WIDTH-1:0] carryout_sel;

  // Carry-out register
  dff_bank #(
      .WIDTH(COUT_WIDTH)
  ) u_carryout_reg (
      .CLK(clk),
      .R  (g_arst_n),
      .LR (l_rst_n),
      .E  (1'b1),
      .D  (carryout_int),
      .Q  (carryout_reg)
  );

  assign carryout_sel = COUTREG ? carryout_reg : carryout_int;

  wire [P_WIDTH-1:0] pout_sel;

  assign pout_sel = USE_RSS ? rss_out[P_WIDTH-1:0] : p_acc[P_WIDTH-1:0];
  // ========================================================================
  // Output assignments
  // ========================================================================
  assign P        = pout_sel;
  assign PCOUT    = pout_sel;
  assign ACOUT    = acout_int;
  assign BCOUT    = bcout_int;
  assign COUT     = carryout_sel;
  assign CCOUT    = carryout_sel[COUT_WIDTH-1];

  assign SIGNCOUT = p_acc[MULT_P_WIDTH-1];

endmodule
// END ../rtl/dsp4_top.v
