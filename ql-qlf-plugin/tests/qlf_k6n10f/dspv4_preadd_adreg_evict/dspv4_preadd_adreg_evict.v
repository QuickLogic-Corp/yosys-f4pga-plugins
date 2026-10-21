// The AD register and a B register reset differently, in the same cell.
//
// QL_DSP4_AD_DFFR_32's R pin is the cell-wide RSTN, shared with the operand
// banks. One cell has one RSTN, so the two registers cannot both go in.
//
// Rather than give up the pre-adder, the pass gives up the B register chain.
// Those flops go to fabric -- which is where they ended up anyway when we
// refused the pre-adder and the matcher re-offered the multiply without it.
// So the eviction costs no flops and saves 17 carry cells per block.
//
//   rb  resetless AD register, B resets on rstn
//   nr  AD resets on rstn, B has no reset: RSTN would clear it anyway
//   dr  AD resets on rstn, B on rst2n: a different signal
//   po  AD resets on rstn low, B on rstn high: same signal, other polarity
module dspv4_preadd_adreg_evict (input clk, rstn, rst2n,
                                   input signed [15:0] rb_d, rb_a, rb_b, output signed [32:0] rb_p,
                                   input signed [15:0] nr_d, nr_a, nr_b, output signed [32:0] nr_p,
                                   input signed [15:0] dr_d, dr_a, dr_b, output signed [32:0] dr_p,
                                   input signed [15:0] po_d, po_a, po_b, output signed [32:0] po_p);
  reg signed [16:0] rb_ad, nr_ad, dr_ad, po_ad;
  reg signed [15:0] rb_bq, nr_bq, dr_bq, po_bq;
  assign rb_p = rb_ad * rb_bq;
  assign nr_p = nr_ad * nr_bq;
  assign dr_p = dr_ad * dr_bq;
  assign po_p = po_ad * po_bq;
  always @(posedge clk) begin
    rb_ad <= rb_d + rb_a;
    if (!rstn) rb_bq <= 0;
    else       rb_bq <= rb_b;

    if (!rstn) nr_ad <= 0;
    else       nr_ad <= nr_d + nr_a;
    nr_bq <= nr_b;

    if (!rstn) dr_ad <= 0;
    else       dr_ad <= dr_d + dr_a;
    if (!rst2n) dr_bq <= 0;
    else        dr_bq <= dr_b;

    if (!rstn) po_ad <= 0;
    else       po_ad <= po_d + po_a;
    if (rstn)  po_bq <= 0;
    else       po_bq <= po_b;
  end
endmodule
