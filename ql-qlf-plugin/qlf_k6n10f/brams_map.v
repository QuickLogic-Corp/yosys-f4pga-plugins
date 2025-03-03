module RAM_36K_BLK (
    WEN_i,
    REN_i,
    WR_CLK_i,
    RD_CLK_i,
    WR_BE_i,
    WR_ADDR_i,
    RD_ADDR_i,
    WDATA_i,
    RDATA_o
);

parameter WR_ADDR_WIDTH = 10;
parameter RD_ADDR_WIDTH = 10;
parameter WR_DATA_WIDTH = 36;
parameter RD_DATA_WIDTH = 36;
parameter BE_WIDTH = 4;

parameter [1024*36-1:0] INIT = 36864'b0;

input wire WEN_i;
input wire REN_i;
input wire WR_CLK_i;
input wire RD_CLK_i;
input wire [BE_WIDTH-1:0] WR_BE_i;
input wire [WR_ADDR_WIDTH-1 :0] WR_ADDR_i;
input wire [RD_ADDR_WIDTH-1 :0] RD_ADDR_i;
input wire [WR_DATA_WIDTH-1 :0] WDATA_i;
output wire [RD_DATA_WIDTH-1 :0] RDATA_o;

// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
localparam [ 0:0] FMODE1_i      = 1'd0;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = 12'd10;
localparam [11:0] UPAF1_i       = 12'd10;

localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
localparam [ 0:0] FMODE2_i      = 1'd0;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input integer width;
	case (width)
		1: mode = 3'b101;
		2: mode = 3'b110;
		4: mode = 3'b100;
		8,9: mode = 3'b001;
		16, 18: mode = 3'b010;
		32, 36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction

function integer rwmode;
input integer rwwidth;
	case (rwwidth)
		1: rwmode = 1;
		2: rwmode = 2;
		4: rwmode = 4;
		8,9: rwmode = 9;
		16, 18: rwmode = 18;
		32, 36: rwmode = 36;
		default: rwmode = 36;
	endcase
endfunction

function [36863:0] pack_init;
input enable;
	integer i;
	reg [35:0] ri;
	for (i = 0; i <  1024; i = i + 1) begin
		ri = (enable)? INIT[i*36 +: 36] : 36'h0;
		pack_init[i*36 +: 36] = {ri[35], ri[26], ri[34:27], ri[25:18],
								 ri[17], ri[8], ri[16:9], ri[7:0]};
	end
endfunction

wire REN_A1_i;
wire REN_A2_i;

wire REN_B1_i;
wire REN_B2_i;

wire WEN_A1_i;
wire WEN_A2_i;

wire WEN_B1_i;
wire WEN_B2_i;

wire [1:0] BE_A1_i;
wire [1:0] BE_A2_i;

wire [1:0] BE_B1_i;
wire [1:0] BE_B2_i;

wire [14:0] ADDR_A1_i;
wire [13:0] ADDR_A2_i;

wire [14:0] ADDR_B1_i;
wire [13:0] ADDR_B2_i;

wire [17:0] WDATA_A1_i;
wire [17:0] WDATA_A2_i;

wire [17:0] WDATA_B1_i;
wire [17:0] WDATA_B2_i;

wire [17:0] RDATA_A1_o;
wire [17:0] RDATA_A2_o;

wire [17:0] RDATA_B1_o;
wire [17:0] RDATA_B2_o;

wire [3:0] WR_BE;

wire [35:0] PORT_B_RDATA;
wire [35:0] PORT_A_WDATA;

wire [14:0] WR_ADDR_INT;
wire [14:0] RD_ADDR_INT; 

wire [14:0] PORT_A_ADDR;
wire [14:0] PORT_B_ADDR;

wire PORT_A_CLK;
wire PORT_B_CLK;

// Set port width mode (In non-split mode A2/B2 is not active. Set same values anyway to match previous behavior.)
localparam [ 2:0] RMODE_A1_i    = mode(WR_DATA_WIDTH);
localparam [ 2:0] WMODE_A1_i    = mode(WR_DATA_WIDTH);
localparam [ 2:0] RMODE_A2_i    = mode(WR_DATA_WIDTH);
localparam [ 2:0] WMODE_A2_i    = mode(WR_DATA_WIDTH);

localparam [ 2:0] RMODE_B1_i    = mode(RD_DATA_WIDTH);
localparam [ 2:0] WMODE_B1_i    = mode(RD_DATA_WIDTH);
localparam [ 2:0] RMODE_B2_i    = mode(RD_DATA_WIDTH);
localparam [ 2:0] WMODE_B2_i    = mode(RD_DATA_WIDTH);

localparam PORT_A_WRWIDTH = rwmode(WR_DATA_WIDTH);
localparam PORT_B_WRWIDTH = rwmode(RD_DATA_WIDTH);

assign PORT_A_CLK = WR_CLK_i;
assign PORT_B_CLK = RD_CLK_i;

generate
  if (WR_ADDR_WIDTH == 15) begin
    assign WR_ADDR_INT = WR_ADDR_i;
  end else begin
    assign WR_ADDR_INT[14:WR_ADDR_WIDTH] = 0;
    assign WR_ADDR_INT[WR_ADDR_WIDTH-1:0] = WR_ADDR_i;
  end
endgenerate

case (WR_DATA_WIDTH)
	1: begin
		assign PORT_A_ADDR = WR_ADDR_INT;
	end
	2: begin
		assign PORT_A_ADDR = WR_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A_ADDR = WR_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A_ADDR = WR_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A_ADDR = WR_ADDR_INT << 4;
	end
	32, 36: begin
		assign PORT_A_ADDR = WR_ADDR_INT << 5;
	end
	default: begin
		assign PORT_A_ADDR = WR_ADDR_INT;
	end
endcase

generate
  if (RD_ADDR_WIDTH == 15) begin
    assign RD_ADDR_INT = RD_ADDR_i;
  end else begin
    assign RD_ADDR_INT[14:RD_ADDR_WIDTH] = 0;
    assign RD_ADDR_INT[RD_ADDR_WIDTH-1:0] = RD_ADDR_i;
  end
endgenerate

case (RD_DATA_WIDTH)
	1: begin
		assign PORT_B_ADDR = RD_ADDR_INT;
	end
	2: begin
		assign PORT_B_ADDR = RD_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B_ADDR = RD_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B_ADDR = RD_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B_ADDR = RD_ADDR_INT << 4;
	end
	32, 36: begin
		assign PORT_B_ADDR = RD_ADDR_INT << 5;
	end
	default: begin
		assign PORT_B_ADDR = RD_ADDR_INT;
	end
endcase

case (BE_WIDTH)
	4: begin
		assign WR_BE = WR_BE_i[BE_WIDTH-1 :0];
	end
	default: begin
		assign WR_BE[3:BE_WIDTH] = 0;
		assign WR_BE[BE_WIDTH-1 :0] = WR_BE_i[BE_WIDTH-1 :0];
	end
endcase

assign REN_A1_i = 1'b0;
assign WEN_A1_i = WEN_i;
assign {BE_A2_i, BE_A1_i} = WR_BE;

assign REN_B1_i = REN_i;
assign WEN_B1_i = 1'b0;
assign {BE_B2_i, BE_B1_i} = 4'h0;

generate
  if (WR_DATA_WIDTH == 36) begin
    assign PORT_A_WDATA[WR_DATA_WIDTH-1:0] = WDATA_i[WR_DATA_WIDTH-1:0];
  end else if (WR_DATA_WIDTH > 18 && WR_DATA_WIDTH < 36) begin
    assign PORT_A_WDATA[WR_DATA_WIDTH+1:18]  = WDATA_i[WR_DATA_WIDTH-1:16];
    assign PORT_A_WDATA[17:0] = {2'b00,WDATA_i[15:0]};
  end else if (WR_DATA_WIDTH == 9) begin
    assign PORT_A_WDATA = {19'h0, WDATA_i[8], 8'h0, WDATA_i[7:0]};
  end else begin
    assign PORT_A_WDATA[35:WR_DATA_WIDTH] = 0;
    assign PORT_A_WDATA[WR_DATA_WIDTH-1:0] = WDATA_i[WR_DATA_WIDTH-1:0];
  end
endgenerate

assign WDATA_A1_i = PORT_A_WDATA[17:0];
assign WDATA_A2_i = PORT_A_WDATA[35:18];

assign WDATA_B1_i = 18'h0;
assign WDATA_B2_i = 18'h0;

generate
  if (RD_DATA_WIDTH == 36) begin
    assign PORT_B_RDATA = {RDATA_B2_o, RDATA_B1_o};
  end else if (RD_DATA_WIDTH > 18 && RD_DATA_WIDTH < 36) begin
    assign PORT_B_RDATA  = {2'b00,RDATA_B2_o[17:0],RDATA_B1_o[15:0]};
  end else if (RD_DATA_WIDTH == 9) begin
    assign PORT_B_RDATA = { 27'h0, RDATA_B1_o[16], RDATA_B1_o[7:0]};
  end else begin
    assign PORT_B_RDATA = {18'h0, RDATA_B1_o};
  end
endgenerate

assign RDATA_o = PORT_B_RDATA[RD_DATA_WIDTH-1:0];

defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};


(* is_inferred = 0 *)
(* is_split = 0 *)
(* is_fifo = 0 *)
(* port_a_dwidth = PORT_A_WRWIDTH *)
(* port_b_dwidth = PORT_B_WRWIDTH *)
TDP36K #(.RAM_INIT(pack_init(1))
		) 
_TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),

	.CLK_A1_i(PORT_A_CLK),
	.ADDR_A1_i(PORT_A_ADDR),
	.WEN_A1_i(WEN_A1_i),
	.BE_A1_i(BE_A1_i),
	.WDATA_A1_i(WDATA_A1_i),
	.REN_A1_i(REN_A1_i),
	.RDATA_A1_o(RDATA_A1_o),

	.CLK_A2_i(PORT_A_CLK),
	.ADDR_A2_i(14'h0),
	.WEN_A2_i(1'b0),
	.BE_A2_i(BE_A2_i),
	.WDATA_A2_i(WDATA_A2_i),
	.REN_A2_i(1'b0),
	.RDATA_A2_o(RDATA_A2_o),

	.CLK_B1_i(PORT_B_CLK),
	.ADDR_B1_i(PORT_B_ADDR),
	.WEN_B1_i(WEN_B1_i),
	.BE_B1_i(BE_B1_i),
	.WDATA_B1_i(WDATA_B1_i),
	.REN_B1_i(REN_B1_i),
	.RDATA_B1_o(RDATA_B1_o),

	.CLK_B2_i(PORT_B_CLK),
	.ADDR_B2_i(14'h0),
	.WEN_B2_i(1'b0),
	.BE_B2_i(BE_B2_i),
	.WDATA_B2_i(WDATA_B2_i),
	.REN_B2_i(1'b0),
	.RDATA_B2_o(RDATA_B2_o),

	.FLUSH1_i(1'b0),
	.FLUSH2_i(1'b0)
);

endmodule

module RAM_18K_BLK (
    WEN_i,
    REN_i,
    WR_CLK_i,
    RD_CLK_i,
    WR_BE_i,
    WR_ADDR_i,
    RD_ADDR_i,
    WDATA_i,
    RDATA_o
);

parameter WR_ADDR_WIDTH = 10;
parameter RD_ADDR_WIDTH = 10;
parameter WR_DATA_WIDTH = 18;
parameter RD_DATA_WIDTH = 18;
parameter BE_WIDTH = 2;

parameter [1024*18-1:0] INIT = 18432'b0;

input wire WEN_i;
input wire REN_i;
input wire WR_CLK_i;
input wire RD_CLK_i;
input wire [BE_WIDTH-1:0] WR_BE_i;
input wire [WR_ADDR_WIDTH-1 :0] WR_ADDR_i;
input wire [RD_ADDR_WIDTH-1 :0] RD_ADDR_i;
input wire [WR_DATA_WIDTH-1 :0] WDATA_i;
output wire [RD_DATA_WIDTH-1 :0] RDATA_o;

  (* is_inferred = 0 *)
  (* is_split = 0 *)
  (* is_fifo = 0 *)
  BRAM2x18_SP  #(
      .INIT1(INIT),
      .WR1_ADDR_WIDTH(WR_ADDR_WIDTH), 
      .RD1_ADDR_WIDTH(RD_ADDR_WIDTH),
      .WR1_DATA_WIDTH(WR_DATA_WIDTH), 
      .RD1_DATA_WIDTH(RD_DATA_WIDTH),
      .BE1_WIDTH(BE_WIDTH),
	  .INIT2(),
      .WR2_ADDR_WIDTH(), 
      .RD2_ADDR_WIDTH(),
      .WR2_DATA_WIDTH(), 
      .RD2_DATA_WIDTH(),
      .BE2_WIDTH()
       ) U1
      (
      .RESET_ni(1'b1),
      
      .WEN1_i(WEN_i),
      .REN1_i(REN_i),
      .WR1_CLK_i(WR_CLK_i),
      .RD1_CLK_i(RD_CLK_i),
      .WR1_BE_i(WR_BE_i),
      .WR1_ADDR_i(WR_ADDR_i),
      .RD1_ADDR_i(RD_ADDR_i),
      .WDATA1_i(WDATA_i),
      .RDATA1_o(RDATA_o),
      
      .WEN2_i(1'b0),
      .REN2_i(1'b0),
      .WR2_CLK_i(1'b0),
      .RD2_CLK_i(1'b0),
      .WR2_BE_i(2'b00),
      .WR2_ADDR_i(14'h0),
      .RD2_ADDR_i(14'h0),
      .WDATA2_i(18'h0),
      .RDATA2_o()
      );
    
endmodule

module RAM_18K_X2_BLK (
    RESET_ni,
    
    WEN1_i,
    REN1_i,
    WR1_CLK_i,
    RD1_CLK_i,
    WR1_BE_i,
    WR1_ADDR_i,
    RD1_ADDR_i,
    WDATA1_i,
    RDATA1_o,
    
    WEN2_i,
    REN2_i,
    WR2_CLK_i,
    RD2_CLK_i,
    WR2_BE_i,
    WR2_ADDR_i,
    RD2_ADDR_i,
    WDATA2_i,
    RDATA2_o
);

parameter WR1_ADDR_WIDTH = 10;
parameter RD1_ADDR_WIDTH = 10;
parameter WR1_DATA_WIDTH = 18;
parameter RD1_DATA_WIDTH = 18;
parameter BE1_WIDTH = 2;

parameter WR2_ADDR_WIDTH = 10;
parameter RD2_ADDR_WIDTH = 10;
parameter WR2_DATA_WIDTH = 18;
parameter RD2_DATA_WIDTH = 18;
parameter BE2_WIDTH = 2;

parameter [1024*18-1:0] INIT1 = 18432'b0;
parameter [1024*18-1:0] INIT2 = 18432'b0;

input wire RESET_ni;

input wire WEN1_i;
input wire REN1_i;
input wire WR1_CLK_i;
input wire RD1_CLK_i;
input wire [BE1_WIDTH-1:0] WR1_BE_i;
input wire [WR1_ADDR_WIDTH-1 :0] WR1_ADDR_i;
input wire [RD1_ADDR_WIDTH-1 :0] RD1_ADDR_i;
input wire [WR1_DATA_WIDTH-1 :0] WDATA1_i;
output wire [RD1_DATA_WIDTH-1 :0] RDATA1_o;

input wire WEN2_i;
input wire REN2_i;
input wire WR2_CLK_i;
input wire RD2_CLK_i;
input wire [BE2_WIDTH-1:0] WR2_BE_i;
input wire [WR2_ADDR_WIDTH-1 :0] WR2_ADDR_i;
input wire [RD2_ADDR_WIDTH-1 :0] RD2_ADDR_i;
input wire [WR2_DATA_WIDTH-1 :0] WDATA2_i;
output wire [RD2_DATA_WIDTH-1 :0] RDATA2_o;

// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
localparam [ 0:0] FMODE1_i      = 1'd0;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = 12'd10;
localparam [11:0] UPAF1_i       = 12'd10;

localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
localparam [ 0:0] FMODE2_i      = 1'd0;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input integer width;
	case (width)
		1: mode = 3'b101;
		2: mode = 3'b110;
		4: mode = 3'b100;
		8,9: mode = 3'b001;
		16, 18: mode = 3'b010;
		32, 36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction

function integer rwmode;
input integer rwwidth;
	case (rwwidth)
		1: rwmode = 1;
		2: rwmode = 2;
		4: rwmode = 4;
		8,9: rwmode = 9;
		16, 18: rwmode = 18;
		default: rwmode = 18;
	endcase
endfunction

function [36863:0] pack_init;
input enable;
	integer i;
	reg [35:0] ri;
	for (i = 0; i < 1024; i = i + 1) begin
		ri = (enable)? {INIT2[i*18 +: 18], INIT1[i*18 +: 18]} : 36'h0;
		pack_init[i*36 +: 36] = {ri[35], ri[26], ri[34:27], ri[25:18], ri[17], ri[8], ri[16:9], ri[7:0]};
	end
endfunction

wire REN_A1_i;
wire REN_A2_i;

wire REN_B1_i;
wire REN_B2_i;

wire WEN_A1_i;
wire WEN_A2_i;

wire WEN_B1_i;
wire WEN_B2_i;

wire [1:0] BE_A1_i;
wire [1:0] BE_A2_i;

wire [1:0] BE_B1_i;
wire [1:0] BE_B2_i;

wire [14:0] ADDR_A1_i;
wire [13:0] ADDR_A2_i;

wire [14:0] ADDR_B1_i;
wire [13:0] ADDR_B2_i;

wire [17:0] WDATA_A1_i;
wire [17:0] WDATA_A2_i;

wire [17:0] WDATA_B1_i;
wire [17:0] WDATA_B2_i;

wire [17:0] RDATA_A1_o;
wire [17:0] RDATA_A2_o;

wire [17:0] RDATA_B1_o;
wire [17:0] RDATA_B2_o;

wire [1:0] WR1_BE;
wire [1:0] WR2_BE;

wire [17:0] PORT_B1_RDATA;
wire [17:0] PORT_A1_WDATA;

wire [17:0] PORT_B2_RDATA;
wire [17:0] PORT_A2_WDATA;

wire [13:0] WR1_ADDR_INT;
wire [13:0] RD1_ADDR_INT; 

wire [13:0] WR2_ADDR_INT;
wire [13:0] RD2_ADDR_INT; 

wire [13:0] PORT_A1_ADDR;
wire [13:0] PORT_B1_ADDR;

wire [13:0] PORT_A2_ADDR;
wire [13:0] PORT_B2_ADDR;


// Set port width mode (In non-split mode A2/B2 is not active. Set same values anyway to match previous behavior.)
localparam [ 2:0] RMODE_A1_i    = mode(WR1_DATA_WIDTH);
localparam [ 2:0] WMODE_A1_i    = mode(WR1_DATA_WIDTH);
localparam [ 2:0] RMODE_A2_i    = mode(WR2_DATA_WIDTH);
localparam [ 2:0] WMODE_A2_i    = mode(WR2_DATA_WIDTH);

localparam [ 2:0] RMODE_B1_i    = mode(RD1_DATA_WIDTH);
localparam [ 2:0] WMODE_B1_i    = mode(RD1_DATA_WIDTH);
localparam [ 2:0] RMODE_B2_i    = mode(RD2_DATA_WIDTH);
localparam [ 2:0] WMODE_B2_i    = mode(RD2_DATA_WIDTH);

localparam PORT_A1_WRWIDTH = rwmode(WR1_DATA_WIDTH);
localparam PORT_B1_WRWIDTH = rwmode(RD1_DATA_WIDTH);
localparam PORT_A2_WRWIDTH = rwmode(WR2_DATA_WIDTH);
localparam PORT_B2_WRWIDTH = rwmode(RD2_DATA_WIDTH);

generate
  if (WR1_ADDR_WIDTH == 14) begin
    assign WR1_ADDR_INT = WR1_ADDR_i;
  end else begin
    assign WR1_ADDR_INT[13:WR1_ADDR_WIDTH] = 0;
    assign WR1_ADDR_INT[WR1_ADDR_WIDTH-1:0] = WR1_ADDR_i;
  end
endgenerate

case (WR1_DATA_WIDTH)
	1: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT;
	end
	2: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT << 4;
	end
	default: begin
		assign PORT_A1_ADDR = WR1_ADDR_INT;
	end
endcase

generate
  if (RD1_ADDR_WIDTH == 14) begin
    assign RD1_ADDR_INT = RD1_ADDR_i;
  end else begin
    assign RD1_ADDR_INT[13:RD1_ADDR_WIDTH] = 0;
    assign RD1_ADDR_INT[RD1_ADDR_WIDTH-1:0] = RD1_ADDR_i;
  end
endgenerate

case (RD1_DATA_WIDTH)
	1: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT;
	end
	2: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT << 4;
	end
	default: begin
		assign PORT_B1_ADDR = RD1_ADDR_INT;
	end
endcase

generate
  if (WR2_ADDR_WIDTH == 14) begin
    assign WR2_ADDR_INT = WR2_ADDR_i;
  end else begin
    assign WR2_ADDR_INT[13:WR2_ADDR_WIDTH] = 0;
    assign WR2_ADDR_INT[WR2_ADDR_WIDTH-1:0] = WR2_ADDR_i;
  end
endgenerate

case (WR2_DATA_WIDTH)
	1: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT;
	end
	2: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT << 4;
	end
	default: begin
		assign PORT_A2_ADDR = WR2_ADDR_INT;
	end
endcase

generate
  if (RD2_ADDR_WIDTH == 14) begin
    assign RD2_ADDR_INT = RD2_ADDR_i;
  end else begin
    assign RD2_ADDR_INT[13:RD2_ADDR_WIDTH] = 0;
    assign RD2_ADDR_INT[RD2_ADDR_WIDTH-1:0] = RD2_ADDR_i;
  end
endgenerate

case (RD2_DATA_WIDTH)
	1: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT;
	end
	2: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT << 4;
	end
	default: begin
		assign PORT_B2_ADDR = RD2_ADDR_INT;
	end
endcase

case (BE1_WIDTH)
	2: begin
		assign WR1_BE = WR1_BE_i[BE1_WIDTH-1 :0];
	end
	default: begin
		assign WR1_BE[1:BE1_WIDTH] = 0;
		assign WR1_BE[BE1_WIDTH-1 :0] = WR1_BE_i[BE1_WIDTH-1 :0];
	end
endcase

case (BE2_WIDTH)
	2: begin
		assign WR2_BE = WR2_BE_i[BE2_WIDTH-1 :0];
	end
	default: begin
		assign WR2_BE[1:BE2_WIDTH] = 0;
		assign WR2_BE[BE2_WIDTH-1 :0] = WR2_BE_i[BE2_WIDTH-1 :0];
	end
endcase

assign REN_A1_i = 1'b0;
assign WEN_A1_i = WEN1_i;
assign BE_A1_i = WR1_BE;
assign REN_A2_i = 1'b0;
assign WEN_A2_i = WEN2_i;
assign BE_A2_i = WR2_BE;

assign REN_B1_i = REN1_i;
assign WEN_B1_i = 1'b0;
assign BE_B1_i = 4'h0;
assign REN_B2_i = REN2_i;
assign WEN_B2_i = 1'b0;
assign BE_B2_i = 4'h0;

generate
  if (WR1_DATA_WIDTH == 18) begin
    assign PORT_A1_WDATA[WR1_DATA_WIDTH-1:0] = WDATA1_i[WR1_DATA_WIDTH-1:0];
  end else if (WR1_DATA_WIDTH == 9) begin
    assign PORT_A1_WDATA = {1'b0, WDATA1_i[8], 8'h0, WDATA1_i[7:0]};
  end else begin
    assign PORT_A1_WDATA[17:WR1_DATA_WIDTH] = 0;
    assign PORT_A1_WDATA[WR1_DATA_WIDTH-1:0] = WDATA1_i[WR1_DATA_WIDTH-1:0];
  end
endgenerate

assign WDATA_A1_i = PORT_A1_WDATA[17:0];
assign WDATA_B1_i = 18'h0;

generate
  if (RD1_DATA_WIDTH == 9) begin
    assign PORT_B1_RDATA = { 9'h0, RDATA_B1_o[16], RDATA_B1_o[7:0]};
  end else begin
    assign PORT_B1_RDATA = RDATA_B1_o;
  end
endgenerate

assign RDATA1_o = PORT_B1_RDATA[RD1_DATA_WIDTH-1:0];

generate
  if (WR2_DATA_WIDTH == 18) begin
    assign PORT_A2_WDATA[WR2_DATA_WIDTH-1:0] = WDATA2_i[WR2_DATA_WIDTH-1:0];
  end else if (WR2_DATA_WIDTH == 9) begin
    assign PORT_A2_WDATA = {1'b0, WDATA2_i[8], 8'h0, WDATA2_i[7:0]};
  end else begin
    assign PORT_A2_WDATA[17:WR2_DATA_WIDTH] = 0;
    assign PORT_A2_WDATA[WR2_DATA_WIDTH-1:0] = WDATA2_i[WR2_DATA_WIDTH-1:0];
  end
endgenerate

assign WDATA_A2_i = PORT_A2_WDATA[17:0];
assign WDATA_B2_i = 18'h0;

generate
  if (RD2_DATA_WIDTH == 9) begin
    assign PORT_B2_RDATA = { 9'h0, RDATA_B2_o[16], RDATA_B2_o[7:0]};
  end else begin
    assign PORT_B2_RDATA = RDATA_B2_o;
  end
endgenerate

assign RDATA2_o = PORT_B2_RDATA[RD2_DATA_WIDTH-1:0];

defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b1,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

(* is_inferred = 0 *)
(* is_split = 1 *)
(* is_fifo = 0 *)
(* port_a1_dwidth = PORT_A1_WRWIDTH *)
(* port_a2_dwidth = PORT_A2_WRWIDTH *)
(* port_b1_dwidth = PORT_B1_WRWIDTH *)
(* port_b2_dwidth = PORT_B2_WRWIDTH *)
TDP36K #(
	.RAM_INIT(pack_init(1))
        ) _TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),

	.CLK_A1_i(WR1_CLK_i),
	.ADDR_A1_i({1'b0,PORT_A1_ADDR}),
	.WEN_A1_i(WEN_A1_i),
	.BE_A1_i(BE_A1_i),
	.WDATA_A1_i(WDATA_A1_i),
	.REN_A1_i(REN_A1_i),
	.RDATA_A1_o(RDATA_A1_o),

	.CLK_A2_i(WR2_CLK_i),
	.ADDR_A2_i(PORT_A2_ADDR),
	.WEN_A2_i(WEN_A2_i),
	.BE_A2_i(BE_A2_i),
	.WDATA_A2_i(WDATA_A2_i),
	.REN_A2_i(REN_A2_i),
	.RDATA_A2_o(RDATA_A2_o),

	.CLK_B1_i(RD1_CLK_i),
	.ADDR_B1_i({1'b0,PORT_B1_ADDR}),
	.WEN_B1_i(WEN_B1_i),
	.BE_B1_i(BE_B1_i),
	.WDATA_B1_i(WDATA_B1_i),
	.REN_B1_i(REN_B1_i),
	.RDATA_B1_o(RDATA_B1_o),

	.CLK_B2_i(RD2_CLK_i),
	.ADDR_B2_i(PORT_B2_ADDR),
	.WEN_B2_i(WEN_B2_i),
	.BE_B2_i(BE_B2_i),
	.WDATA_B2_i(WDATA_B2_i),
	.REN_B2_i(REN_B2_i),
	.RDATA_B2_o(RDATA_B2_o),

	.FLUSH1_i(1'b0),
	.FLUSH2_i(1'b0)
);

endmodule

module DPRAM_36K_BLK (   
    PORT_A_CLK_i,
    PORT_A_WEN_i,
    PORT_A_WR_BE_i,
    PORT_A_REN_i,
    PORT_A_ADDR_i,
    PORT_A_WR_DATA_i,
    PORT_A_RD_DATA_o,
    
    PORT_B_CLK_i,
    PORT_B_WEN_i,
    PORT_B_WR_BE_i,
    PORT_B_REN_i,
    PORT_B_ADDR_i,
    PORT_B_WR_DATA_i,
    PORT_B_RD_DATA_o
);

parameter PORT_A_AWIDTH = 10;
parameter PORT_A_DWIDTH = 36;
parameter PORT_A_WR_BE_WIDTH = 4;

parameter PORT_B_AWIDTH = 10;
parameter PORT_B_DWIDTH = 36;
parameter PORT_B_WR_BE_WIDTH = 4;

parameter [1024*36-1:0] INIT = 36864'b0;
parameter OPTION_SPLIT = 0;

input wire PORT_A_CLK_i;
input wire [PORT_A_AWIDTH-1:0] PORT_A_ADDR_i;
input wire [PORT_A_DWIDTH-1:0] PORT_A_WR_DATA_i;
input wire PORT_A_WEN_i;
input wire [PORT_A_WR_BE_WIDTH-1:0] PORT_A_WR_BE_i;
input wire PORT_A_REN_i;
output wire [PORT_A_DWIDTH-1:0] PORT_A_RD_DATA_o;

input wire PORT_B_CLK_i;
input wire [PORT_B_AWIDTH-1:0] PORT_B_ADDR_i;
input wire [PORT_B_DWIDTH-1:0] PORT_B_WR_DATA_i;
input wire PORT_B_WEN_i;
input wire [PORT_B_WR_BE_WIDTH-1:0] PORT_B_WR_BE_i;
input wire PORT_B_REN_i;
output wire [PORT_B_DWIDTH-1:0] PORT_B_RD_DATA_o;


// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
localparam [ 0:0] FMODE1_i      = 1'd0;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = 12'd10;
localparam [11:0] UPAF1_i       = 12'd10;

localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
localparam [ 0:0] FMODE2_i      = 1'd0;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input integer width;
	case (width)
		1: mode = 3'b101;
		2: mode = 3'b110;
		4: mode = 3'b100;
		8,9: mode = 3'b001;
		16, 18: mode = 3'b010;
		32, 36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction

function integer rwmode;
input integer rwwidth;
	case (rwwidth)
		1: rwmode = 1;
		2: rwmode = 2;
		4: rwmode = 4;
		8,9: rwmode = 9;
		16, 18: rwmode = 18;
		32, 36: rwmode = 36;
		default: rwmode = 36;
	endcase
endfunction

function [36863:0] pack_init;
input enable; 
	integer i;
	reg [35:0] ri;
	for (i = 0; i < 1024; i = i + 1) begin
		ri = (enable)? INIT[i*36 +: 36] : 36'h0;
		pack_init[i*36 +: 36] = {ri[35], ri[26], ri[34:27], ri[25:18],
								 ri[17], ri[8], ri[16:9], ri[7:0]};
	end
endfunction

wire REN_A1_i;
wire REN_A2_i;

wire REN_B1_i;
wire REN_B2_i;

wire WEN_A1_i;
wire WEN_A2_i;

wire WEN_B1_i;
wire WEN_B2_i;

wire [1:0] BE_A1_i;
wire [1:0] BE_A2_i;

wire [1:0] BE_B1_i;
wire [1:0] BE_B2_i;

wire [14:0] ADDR_A1_i;
wire [13:0] ADDR_A2_i;

wire [14:0] ADDR_B1_i;
wire [13:0] ADDR_B2_i;

wire [17:0] WDATA_A1_i;
wire [17:0] WDATA_A2_i;

wire [17:0] WDATA_B1_i;
wire [17:0] WDATA_B2_i;

wire [17:0] RDATA_A1_o;
wire [17:0] RDATA_A2_o;

wire [17:0] RDATA_B1_o;
wire [17:0] RDATA_B2_o;

wire [3:0] PORT_A_WR_BE;
wire [3:0] PORT_B_WR_BE;

wire [35:0] PORT_B_WDATA;
wire [35:0] PORT_B_RDATA;
wire [35:0] PORT_A_WDATA;
wire [35:0] PORT_A_RDATA;

wire [14:0] PORT_A_ADDR_INT;
wire [14:0] PORT_B_ADDR_INT; 

wire [14:0] PORT_A_ADDR;
wire [14:0] PORT_B_ADDR;

wire PORT_A_CLK;
wire PORT_B_CLK;

// Set port width mode (In non-split mode A2/B2 is not active. Set same values anyway to match previous behavior.)
localparam [ 2:0] RMODE_A1_i    = mode(PORT_A_DWIDTH);
localparam [ 2:0] WMODE_A1_i    = mode(PORT_A_DWIDTH);
localparam [ 2:0] RMODE_A2_i    = mode(PORT_A_DWIDTH);
localparam [ 2:0] WMODE_A2_i    = mode(PORT_A_DWIDTH);

localparam [ 2:0] RMODE_B1_i    = mode(PORT_B_DWIDTH);
localparam [ 2:0] WMODE_B1_i    = mode(PORT_B_DWIDTH);
localparam [ 2:0] RMODE_B2_i    = mode(PORT_B_DWIDTH);
localparam [ 2:0] WMODE_B2_i    = mode(PORT_B_DWIDTH);

localparam PORT_A_WRWIDTH = rwmode(PORT_A_DWIDTH);
localparam PORT_B_WRWIDTH = rwmode(PORT_B_DWIDTH);

assign PORT_A_CLK = PORT_A_CLK_i;
assign PORT_B_CLK = PORT_B_CLK_i;

generate
  if (PORT_A_AWIDTH == 15) begin
    assign PORT_A_ADDR_INT = PORT_A_ADDR_i;
  end else begin
    assign PORT_A_ADDR_INT[14:PORT_A_AWIDTH] = 0;
    assign PORT_A_ADDR_INT[PORT_A_AWIDTH-1:0] = PORT_A_ADDR_i;
  end
endgenerate

case (PORT_A_DWIDTH)
	1: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT;
	end
	2: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT << 4;
	end
	32, 36: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT << 5;
	end
	default: begin
		assign PORT_A_ADDR = PORT_A_ADDR_INT;
	end
endcase

generate
  if (PORT_B_AWIDTH == 15) begin
    assign PORT_B_ADDR_INT = PORT_B_ADDR_i;
  end else begin
    assign PORT_B_ADDR_INT[14:PORT_B_AWIDTH] = 0;
    assign PORT_B_ADDR_INT[PORT_B_AWIDTH-1:0] = PORT_B_ADDR_i;
  end
endgenerate

case (PORT_B_DWIDTH)
	1: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT;
	end
	2: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT << 4;
	end
	32, 36: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT << 5;
	end
	default: begin
		assign PORT_B_ADDR = PORT_B_ADDR_INT;
	end
endcase

case (PORT_A_WR_BE_WIDTH)
	4: begin
		assign PORT_A_WR_BE = PORT_A_WR_BE_i[PORT_A_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_A_WR_BE[3:PORT_A_WR_BE_WIDTH] = 0;
		assign PORT_A_WR_BE[PORT_A_WR_BE_WIDTH-1 :0] = PORT_A_WR_BE_i[PORT_A_WR_BE_WIDTH-1 :0];
	end
endcase

case (PORT_B_WR_BE_WIDTH)
	4: begin
		assign PORT_B_WR_BE = PORT_B_WR_BE_i[PORT_B_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_B_WR_BE[3:PORT_B_WR_BE_WIDTH] = 0;
		assign PORT_B_WR_BE[PORT_B_WR_BE_WIDTH-1 :0] = PORT_B_WR_BE_i[PORT_B_WR_BE_WIDTH-1 :0];
	end
endcase

assign REN_A1_i = PORT_A_REN_i;
assign WEN_A1_i = PORT_A_WEN_i;
assign {BE_A2_i, BE_A1_i} = PORT_A_WR_BE;

assign REN_B1_i = PORT_B_REN_i;
assign WEN_B1_i = PORT_B_WEN_i;
assign {BE_B2_i, BE_B1_i} = PORT_B_WR_BE;

generate
  if (PORT_A_DWIDTH == 36) begin
    assign PORT_A_WDATA[PORT_A_DWIDTH-1:0] = PORT_A_WR_DATA_i[PORT_A_DWIDTH-1:0];
  end else if (PORT_A_DWIDTH > 18 && PORT_A_DWIDTH < 36) begin
    assign PORT_A_WDATA[PORT_A_DWIDTH+1:18]  = PORT_A_WR_DATA_i[PORT_A_DWIDTH-1:16];
    assign PORT_A_WDATA[17:0] = {2'b00,PORT_A_WR_DATA_i[15:0]};
  end else if (PORT_A_DWIDTH == 9) begin
    assign PORT_A_WDATA = {19'h0, PORT_A_WR_DATA_i[8], 8'h0, PORT_A_WR_DATA_i[7:0]};
  end else begin
    assign PORT_A_WDATA[35:PORT_A_DWIDTH] = 0;
    assign PORT_A_WDATA[PORT_A_DWIDTH-1:0] = PORT_A_WR_DATA_i[PORT_A_DWIDTH-1:0];
  end
endgenerate

assign WDATA_A1_i = PORT_A_WDATA[17:0];
assign WDATA_A2_i = PORT_A_WDATA[35:18];

generate
  if (PORT_A_DWIDTH == 36) begin
    assign PORT_A_RDATA = {RDATA_A2_o, RDATA_A1_o};
  end else if (PORT_A_DWIDTH > 18 && PORT_A_DWIDTH < 36) begin
    assign PORT_A_RDATA  = {2'b00,RDATA_A2_o[17:0],RDATA_A1_o[15:0]};
  end else if (PORT_A_DWIDTH == 9) begin
    assign PORT_A_RDATA = { 27'h0, RDATA_A1_o[16], RDATA_A1_o[7:0]};
  end else begin
    assign PORT_A_RDATA = {18'h0, RDATA_A1_o};
  end
endgenerate

assign PORT_A_RD_DATA_o = PORT_A_RDATA[PORT_A_DWIDTH-1:0];

generate
  if (PORT_B_DWIDTH == 36) begin
    assign PORT_B_WDATA[PORT_B_DWIDTH-1:0] = PORT_B_WR_DATA_i[PORT_B_DWIDTH-1:0];
  end else if (PORT_B_DWIDTH > 18 && PORT_B_DWIDTH < 36) begin
    assign PORT_B_WDATA[PORT_B_DWIDTH+1:18]  = PORT_B_WR_DATA_i[PORT_B_DWIDTH-1:16];
    assign PORT_B_WDATA[17:0] = {2'b00,PORT_B_WR_DATA_i[15:0]};
  end else if (PORT_B_DWIDTH == 9) begin
    assign PORT_B_WDATA = {19'h0, PORT_B_WR_DATA_i[8], 8'h0, PORT_B_WR_DATA_i[7:0]};
  end else begin
    assign PORT_B_WDATA[35:PORT_B_DWIDTH] = 0;
    assign PORT_B_WDATA[PORT_B_DWIDTH-1:0] = PORT_B_WR_DATA_i[PORT_B_DWIDTH-1:0];
  end
endgenerate

assign WDATA_B1_i = PORT_B_WDATA[17:0];
assign WDATA_B2_i = PORT_B_WDATA[35:18];

generate
  if (PORT_B_DWIDTH == 36) begin
    assign PORT_B_RDATA = {RDATA_B2_o, RDATA_B1_o};
  end else if (PORT_B_DWIDTH > 18 && PORT_B_DWIDTH < 36) begin
    assign PORT_B_RDATA  = {2'b00,RDATA_B2_o[17:0],RDATA_B1_o[15:0]};
  end else if (PORT_B_DWIDTH == 9) begin
    assign PORT_B_RDATA = { 27'h0, RDATA_B1_o[16], RDATA_B1_o[7:0]};
  end else begin
    assign PORT_B_RDATA = {18'h0, RDATA_B1_o};
  end
endgenerate

assign PORT_B_RD_DATA_o = PORT_B_RDATA[PORT_B_DWIDTH-1:0];

defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

(* is_inferred = 0 *)
(* is_split = 0 *)
(* is_fifo = 0 *)
(* port_a_dwidth = PORT_A_WRWIDTH *)
(* port_b_dwidth = PORT_B_WRWIDTH *)
TDP36K #(
	.RAM_INIT(pack_init(1))
		) _TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),

	.CLK_A1_i(PORT_A_CLK),
	.ADDR_A1_i(PORT_A_ADDR),
	.WEN_A1_i(WEN_A1_i),
	.BE_A1_i(BE_A1_i),
	.WDATA_A1_i(WDATA_A1_i),
	.REN_A1_i(REN_A1_i),
	.RDATA_A1_o(RDATA_A1_o),

	.CLK_A2_i(PORT_A_CLK),
	.ADDR_A2_i(14'h0),
	.WEN_A2_i(1'b0),
	.BE_A2_i(BE_A2_i),
	.WDATA_A2_i(WDATA_A2_i),
	.REN_A2_i(1'b0),
	.RDATA_A2_o(RDATA_A2_o),

	.CLK_B1_i(PORT_B_CLK),
	.ADDR_B1_i(PORT_B_ADDR),
	.WEN_B1_i(WEN_B1_i),
	.BE_B1_i(BE_B1_i),
	.WDATA_B1_i(WDATA_B1_i),
	.REN_B1_i(REN_B1_i),
	.RDATA_B1_o(RDATA_B1_o),

	.CLK_B2_i(PORT_B_CLK),
	.ADDR_B2_i(14'h0),
	.WEN_B2_i(1'b0),
	.BE_B2_i(BE_B2_i),
	.WDATA_B2_i(WDATA_B2_i),
	.REN_B2_i(1'b0),
	.RDATA_B2_o(RDATA_B2_o),

	.FLUSH1_i(1'b0),
	.FLUSH2_i(1'b0)
);

endmodule

module DPRAM_18K_BLK (   
    PORT_A_CLK_i,
    PORT_A_WEN_i,
    PORT_A_WR_BE_i,
    PORT_A_REN_i,
    PORT_A_ADDR_i,
    PORT_A_WR_DATA_i,
    PORT_A_RD_DATA_o,
    
    PORT_B_CLK_i,
    PORT_B_WEN_i,
    PORT_B_WR_BE_i,
    PORT_B_REN_i,
    PORT_B_ADDR_i,
    PORT_B_WR_DATA_i,
    PORT_B_RD_DATA_o
);

parameter PORT_A_AWIDTH = 10;
parameter PORT_A_DWIDTH = 36;
parameter PORT_A_WR_BE_WIDTH = 4;

parameter PORT_B_AWIDTH = 10;
parameter PORT_B_DWIDTH = 36;
parameter PORT_B_WR_BE_WIDTH = 4;

parameter [1024*18-1:0] INIT = 18432'b0;

input wire PORT_A_CLK_i;
input wire [PORT_A_AWIDTH-1:0] PORT_A_ADDR_i;
input wire [PORT_A_DWIDTH-1:0] PORT_A_WR_DATA_i;
input wire PORT_A_WEN_i;
input wire [PORT_A_WR_BE_WIDTH-1:0] PORT_A_WR_BE_i;
input wire PORT_A_REN_i;
output wire [PORT_A_DWIDTH-1:0] PORT_A_RD_DATA_o;

input wire PORT_B_CLK_i;
input wire [PORT_B_AWIDTH-1:0] PORT_B_ADDR_i;
input wire [PORT_B_DWIDTH-1:0] PORT_B_WR_DATA_i;
input wire PORT_B_WEN_i;
input wire [PORT_B_WR_BE_WIDTH-1:0] PORT_B_WR_BE_i;
input wire PORT_B_REN_i;
output wire [PORT_B_DWIDTH-1:0] PORT_B_RD_DATA_o;


(* is_inferred = 0 *)
(* is_split = 0 *)
(* is_fifo = 0 *)
BRAM2x18_dP #(
    .INIT1(INIT),
	.PORT_A1_AWIDTH(PORT_A_AWIDTH),
	.PORT_A1_DWIDTH(PORT_A_DWIDTH),
	.PORT_A1_WR_BE_WIDTH(PORT_A_WR_BE_WIDTH),
	.PORT_B1_AWIDTH(PORT_B_AWIDTH),
	.PORT_B1_DWIDTH(PORT_B_DWIDTH),
	.PORT_B1_WR_BE_WIDTH(PORT_B_WR_BE_WIDTH),
	.INIT2(),
	.PORT_A2_AWIDTH(),
	.PORT_A2_DWIDTH(),
	.PORT_A2_WR_BE_WIDTH(),
	.PORT_B2_AWIDTH(),
	.PORT_B2_DWIDTH(),
	.PORT_B2_WR_BE_WIDTH()
) U1 (
    .PORT_A1_CLK_i(PORT_A_CLK_i),
    .PORT_A1_WEN_i(PORT_A_WEN_i),
    .PORT_A1_WR_BE_i(PORT_A_WR_BE_i),
    .PORT_A1_REN_i(PORT_A_REN_i),
    .PORT_A1_ADDR_i(PORT_A_ADDR_i),
    .PORT_A1_WR_DATA_i(PORT_A_WR_DATA_i),
    .PORT_A1_RD_DATA_o(PORT_A_RD_DATA_o),
    
    .PORT_B1_CLK_i(PORT_B_CLK_i),
    .PORT_B1_WEN_i(PORT_B_WEN_i),
    .PORT_B1_WR_BE_i(PORT_B_WR_BE_i),
    .PORT_B1_REN_i(PORT_B_REN_i),
    .PORT_B1_ADDR_i(PORT_B_ADDR_i),
    .PORT_B1_WR_DATA_i(PORT_B_WR_DATA_i),
    .PORT_B1_RD_DATA_o(PORT_B_RD_DATA_o),
	
    .PORT_A2_CLK_i(1'b0),
    .PORT_A2_WEN_i(1'b0),
    .PORT_A2_WR_BE_i(2'b00),
    .PORT_A2_REN_i(1'b0),
    .PORT_A2_ADDR_i(14'h0),
    .PORT_A2_WR_DATA_i(18'h0),
    .PORT_A2_RD_DATA_o(),
    
    .PORT_B2_CLK_i(1'b0),
    .PORT_B2_WEN_i(1'b0),
    .PORT_B2_WR_BE_i(2'b00),
    .PORT_B2_REN_i(1'b0),
    .PORT_B2_ADDR_i(14'h0),
    .PORT_B2_WR_DATA_i(18'h0),
    .PORT_B2_RD_DATA_o()
);

endmodule


module DPRAM_18K_X2_BLK (   
    PORT_A1_CLK_i,
    PORT_A1_WEN_i,
    PORT_A1_WR_BE_i,
    PORT_A1_REN_i,
    PORT_A1_ADDR_i,
    PORT_A1_WR_DATA_i,
    PORT_A1_RD_DATA_o,
    
    PORT_B1_CLK_i,
    PORT_B1_WEN_i,
    PORT_B1_WR_BE_i,
    PORT_B1_REN_i,
    PORT_B1_ADDR_i,
    PORT_B1_WR_DATA_i,
    PORT_B1_RD_DATA_o,
	
    PORT_A2_CLK_i,
    PORT_A2_WEN_i,
    PORT_A2_WR_BE_i,
    PORT_A2_REN_i,
    PORT_A2_ADDR_i,
    PORT_A2_WR_DATA_i,
    PORT_A2_RD_DATA_o,
    
    PORT_B2_CLK_i,
    PORT_B2_WEN_i,
    PORT_B2_WR_BE_i,
    PORT_B2_REN_i,
    PORT_B2_ADDR_i,
    PORT_B2_WR_DATA_i,
    PORT_B2_RD_DATA_o
);

parameter PORT_A1_AWIDTH = 10;
parameter PORT_A1_DWIDTH = 18;
parameter PORT_A1_WR_BE_WIDTH = 2;
				
parameter PORT_B1_AWIDTH = 10;
parameter PORT_B1_DWIDTH = 18;
parameter PORT_B1_WR_BE_WIDTH = 2;

parameter PORT_A2_AWIDTH = 10;
parameter PORT_A2_DWIDTH = 18;
parameter PORT_A2_WR_BE_WIDTH = 2;
				
parameter PORT_B2_AWIDTH = 10;
parameter PORT_B2_DWIDTH = 18;
parameter PORT_B2_WR_BE_WIDTH = 2;

parameter [1024*18-1:0] INIT1 = 18432'b0;
parameter [1024*18-1:0] INIT2 = 18432'b0;

input wire PORT_A1_CLK_i;
input wire [PORT_A1_AWIDTH-1:0] PORT_A1_ADDR_i;
input wire [PORT_A1_DWIDTH-1:0] PORT_A1_WR_DATA_i;
input wire PORT_A1_WEN_i;
input wire [PORT_A1_WR_BE_WIDTH-1:0] PORT_A1_WR_BE_i;
input wire PORT_A1_REN_i;
output wire [PORT_A1_DWIDTH-1:0] PORT_A1_RD_DATA_o;

input wire PORT_B1_CLK_i;
input wire [PORT_B1_AWIDTH-1:0] PORT_B1_ADDR_i;
input wire [PORT_B1_DWIDTH-1:0] PORT_B1_WR_DATA_i;
input wire PORT_B1_WEN_i;
input wire [PORT_B1_WR_BE_WIDTH-1:0] PORT_B1_WR_BE_i;
input wire PORT_B1_REN_i;
output wire [PORT_B1_DWIDTH-1:0] PORT_B1_RD_DATA_o;

input wire PORT_A2_CLK_i;
input wire [PORT_A2_AWIDTH-1:0] PORT_A2_ADDR_i;
input wire [PORT_A2_DWIDTH-1:0] PORT_A2_WR_DATA_i;
input wire PORT_A2_WEN_i;
input wire [PORT_A2_WR_BE_WIDTH-1:0] PORT_A2_WR_BE_i;
input wire PORT_A2_REN_i;
output wire [PORT_A2_DWIDTH-1:0] PORT_A2_RD_DATA_o;

input wire PORT_B2_CLK_i;
input wire [PORT_B2_AWIDTH-1:0] PORT_B2_ADDR_i;
input wire [PORT_B2_DWIDTH-1:0] PORT_B2_WR_DATA_i;
input wire PORT_B2_WEN_i;
input wire [PORT_B2_WR_BE_WIDTH-1:0] PORT_B2_WR_BE_i;
input wire PORT_B2_REN_i;
output wire [PORT_B2_DWIDTH-1:0] PORT_B2_RD_DATA_o;


// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
localparam [ 0:0] FMODE1_i      = 1'd0;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = 12'd10;
localparam [11:0] UPAF1_i       = 12'd10;

localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
localparam [ 0:0] FMODE2_i      = 1'd0;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input integer width;
	case (width)
		1: mode = 3'b101;
		2: mode = 3'b110;
		4: mode = 3'b100;
		8,9: mode = 3'b001;
		16, 18: mode = 3'b010;
		32, 36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction

function integer rwmode;
input integer rwwidth;
	case (rwwidth)
		1: rwmode = 1;
		2: rwmode = 2;
		4: rwmode = 4;
		8,9: rwmode = 9;
		16, 18: rwmode = 18;
		default: rwmode = 18;
	endcase
endfunction

function [36863:0] pack_init;
input enable;
	integer i;
	reg [35:0] ri;
	for (i = 0; i < 1024; i = i + 1) begin
		ri = (enable)? {INIT2[i*18 +: 18], INIT1[i*18 +: 18]} : 36'h0;
		pack_init[i*36 +: 36] = {ri[35], ri[26], ri[34:27], ri[25:18], ri[17], ri[8], ri[16:9], ri[7:0]};
	end
endfunction

wire REN_A1_i;
wire REN_A2_i;

wire REN_B1_i;
wire REN_B2_i;

wire WEN_A1_i;
wire WEN_A2_i;

wire WEN_B1_i;
wire WEN_B2_i;

wire [1:0] BE_A1_i;
wire [1:0] BE_A2_i;

wire [1:0] BE_B1_i;
wire [1:0] BE_B2_i;

wire [14:0] ADDR_A1_i;
wire [13:0] ADDR_A2_i;

wire [14:0] ADDR_B1_i;
wire [13:0] ADDR_B2_i;

wire [17:0] WDATA_A1_i;
wire [17:0] WDATA_A2_i;

wire [17:0] WDATA_B1_i;
wire [17:0] WDATA_B2_i;

wire [17:0] RDATA_A1_o;
wire [17:0] RDATA_A2_o;

wire [17:0] RDATA_B1_o;
wire [17:0] RDATA_B2_o;

wire [1:0] PORT_A1_WR_BE;
wire [1:0] PORT_B1_WR_BE;

wire [1:0] PORT_A2_WR_BE;
wire [1:0] PORT_B2_WR_BE;

wire [17:0] PORT_B1_WDATA;
wire [17:0] PORT_B1_RDATA;
wire [17:0] PORT_A1_WDATA;
wire [17:0] PORT_A1_RDATA;

wire [17:0] PORT_B2_WDATA;
wire [17:0] PORT_B2_RDATA;
wire [17:0] PORT_A2_WDATA;
wire [17:0] PORT_A2_RDATA;

wire [13:0] PORT_A1_ADDR_INT;
wire [13:0] PORT_B1_ADDR_INT; 

wire [13:0] PORT_A2_ADDR_INT;
wire [13:0] PORT_B2_ADDR_INT; 
	   
wire [13:0] PORT_A1_ADDR;
wire [13:0] PORT_B1_ADDR;

wire [13:0] PORT_A2_ADDR;
wire [13:0] PORT_B2_ADDR;

wire PORT_A1_CLK;
wire PORT_B1_CLK;

wire PORT_A2_CLK;
wire PORT_B2_CLK;

// Set port width mode (In non-split mode A2/B2 is not active. Set same values anyway to match previous behavior.)
localparam [ 2:0] RMODE_A1_i    = mode(PORT_A1_DWIDTH);
localparam [ 2:0] WMODE_A1_i    = mode(PORT_A1_DWIDTH);
localparam [ 2:0] RMODE_A2_i    = mode(PORT_A2_DWIDTH);
localparam [ 2:0] WMODE_A2_i    = mode(PORT_A2_DWIDTH);

localparam [ 2:0] RMODE_B1_i    = mode(PORT_B1_DWIDTH);
localparam [ 2:0] WMODE_B1_i    = mode(PORT_B1_DWIDTH);
localparam [ 2:0] RMODE_B2_i    = mode(PORT_B2_DWIDTH);
localparam [ 2:0] WMODE_B2_i    = mode(PORT_B2_DWIDTH);

localparam PORT_A1_WRWIDTH = rwmode(PORT_A1_DWIDTH);
localparam PORT_B1_WRWIDTH = rwmode(PORT_B1_DWIDTH);
localparam PORT_A2_WRWIDTH = rwmode(PORT_A2_DWIDTH);
localparam PORT_B2_WRWIDTH = rwmode(PORT_B2_DWIDTH);

assign PORT_A1_CLK = PORT_A1_CLK_i;
assign PORT_B1_CLK = PORT_B1_CLK_i;

assign PORT_A2_CLK = PORT_A2_CLK_i;
assign PORT_B2_CLK = PORT_B2_CLK_i;

generate
  if (PORT_A1_AWIDTH == 14) begin
    assign PORT_A1_ADDR_INT = PORT_A1_ADDR_i;
  end else begin
    assign PORT_A1_ADDR_INT[13:PORT_A1_AWIDTH] = 0;
    assign PORT_A1_ADDR_INT[PORT_A1_AWIDTH-1:0] = PORT_A1_ADDR_i;
  end
endgenerate

case (PORT_A1_DWIDTH)
	1: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT;
	end
	2: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT << 4;
	end
	default: begin
		assign PORT_A1_ADDR = PORT_A1_ADDR_INT;
	end
endcase

generate
  if (PORT_B1_AWIDTH == 14) begin
    assign PORT_B1_ADDR_INT = PORT_B1_ADDR_i;
  end else begin
    assign PORT_B1_ADDR_INT[13:PORT_B1_AWIDTH] = 0;
    assign PORT_B1_ADDR_INT[PORT_B1_AWIDTH-1:0] = PORT_B1_ADDR_i;
  end
endgenerate

case (PORT_B1_DWIDTH)
	1: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT;
	end
	2: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT << 4;
	end
	default: begin
		assign PORT_B1_ADDR = PORT_B1_ADDR_INT;
	end
endcase

generate
  if (PORT_A2_AWIDTH == 14) begin
    assign PORT_A2_ADDR_INT = PORT_A2_ADDR_i;
  end else begin
    assign PORT_A2_ADDR_INT[13:PORT_A2_AWIDTH] = 0;
    assign PORT_A2_ADDR_INT[PORT_A2_AWIDTH-1:0] = PORT_A2_ADDR_i;
  end
endgenerate

case (PORT_A2_DWIDTH)
	1: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT;
	end
	2: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT << 1;
	end
	4: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT << 4;
	end
	default: begin
		assign PORT_A2_ADDR = PORT_A2_ADDR_INT;
	end
endcase

generate
  if (PORT_B2_AWIDTH == 14) begin
    assign PORT_B2_ADDR_INT = PORT_B2_ADDR_i;
  end else begin
    assign PORT_B2_ADDR_INT[13:PORT_B2_AWIDTH] = 0;
    assign PORT_B2_ADDR_INT[PORT_B2_AWIDTH-1:0] = PORT_B2_ADDR_i;
  end
endgenerate

case (PORT_B2_DWIDTH)
	1: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT;
	end
	2: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT << 1;
	end
	4: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT << 2;
	end
	8, 9: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT << 3;
	end
	16, 18: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT << 4;
	end
	default: begin
		assign PORT_B2_ADDR = PORT_B2_ADDR_INT;
	end
endcase

case (PORT_A1_WR_BE_WIDTH)
	2: begin
		assign PORT_A1_WR_BE = PORT_A1_WR_BE_i[PORT_A1_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_A1_WR_BE[1:PORT_A1_WR_BE_WIDTH] = 0;
		assign PORT_A1_WR_BE[PORT_A1_WR_BE_WIDTH-1 :0] = PORT_A1_WR_BE_i[PORT_A1_WR_BE_WIDTH-1 :0];
	end
endcase

case (PORT_B1_WR_BE_WIDTH)
	2: begin
		assign PORT_B1_WR_BE = PORT_B1_WR_BE_i[PORT_B1_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_B1_WR_BE[1:PORT_B1_WR_BE_WIDTH] = 0;
		assign PORT_B1_WR_BE[PORT_B1_WR_BE_WIDTH-1 :0] = PORT_B1_WR_BE_i[PORT_B1_WR_BE_WIDTH-1 :0];
	end
endcase

case (PORT_A2_WR_BE_WIDTH)
	2: begin
		assign PORT_A2_WR_BE = PORT_A2_WR_BE_i[PORT_A2_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_A2_WR_BE[1:PORT_A2_WR_BE_WIDTH] = 0;
		assign PORT_A2_WR_BE[PORT_A2_WR_BE_WIDTH-1 :0] = PORT_A2_WR_BE_i[PORT_A2_WR_BE_WIDTH-1 :0];
	end
endcase

case (PORT_B2_WR_BE_WIDTH)
	2: begin
		assign PORT_B2_WR_BE = PORT_B2_WR_BE_i[PORT_B2_WR_BE_WIDTH-1 :0];
	end
	default: begin
		assign PORT_B2_WR_BE[1:PORT_B2_WR_BE_WIDTH] = 0;
		assign PORT_B2_WR_BE[PORT_B2_WR_BE_WIDTH-1 :0] = PORT_B2_WR_BE_i[PORT_B2_WR_BE_WIDTH-1 :0];
	end
endcase

assign REN_A1_i = PORT_A1_REN_i;
assign WEN_A1_i = PORT_A1_WEN_i;
assign BE_A1_i  = PORT_A1_WR_BE;

assign REN_A2_i = PORT_A2_REN_i;
assign WEN_A2_i = PORT_A2_WEN_i;
assign BE_A2_i  = PORT_A2_WR_BE;

assign REN_B1_i = PORT_B1_REN_i;
assign WEN_B1_i = PORT_B1_WEN_i;
assign BE_B1_i  = PORT_B1_WR_BE;

assign REN_B2_i = PORT_B2_REN_i;
assign WEN_B2_i = PORT_B2_WEN_i;
assign BE_B2_i  = PORT_B2_WR_BE;

generate
  if (PORT_A1_DWIDTH == 18) begin
    assign PORT_A1_WDATA[PORT_A1_DWIDTH-1:0] = PORT_A1_WR_DATA_i[PORT_A1_DWIDTH-1:0];
  end else if (PORT_A1_DWIDTH == 9) begin
    assign PORT_A1_WDATA = {1'b0, PORT_A1_WR_DATA_i[8], 8'h0, PORT_A1_WR_DATA_i[7:0]};
  end else begin
    assign PORT_A1_WDATA[17:PORT_A1_DWIDTH] = 0;
    assign PORT_A1_WDATA[PORT_A1_DWIDTH-1:0] = PORT_A1_WR_DATA_i[PORT_A1_DWIDTH-1:0];
  end
endgenerate

assign WDATA_A1_i = PORT_A1_WDATA;

generate
  if (PORT_A2_DWIDTH == 18) begin
    assign PORT_A2_WDATA[PORT_A2_DWIDTH-1:0] = PORT_A2_WR_DATA_i[PORT_A2_DWIDTH-1:0];
  end else if (PORT_A2_DWIDTH == 9) begin
    assign PORT_A2_WDATA = {1'b0, PORT_A2_WR_DATA_i[8], 8'h0, PORT_A2_WR_DATA_i[7:0]};
  end else begin
    assign PORT_A2_WDATA[17:PORT_A2_DWIDTH] = 0;
    assign PORT_A2_WDATA[PORT_A2_DWIDTH-1:0] = PORT_A2_WR_DATA_i[PORT_A2_DWIDTH-1:0];
  end
endgenerate

assign WDATA_A2_i = PORT_A2_WDATA;

generate
  if (PORT_A1_DWIDTH == 9) begin
    assign PORT_A1_RDATA = { 9'h0, RDATA_A1_o[16], RDATA_A1_o[7:0]};
  end else begin
    assign PORT_A1_RDATA = RDATA_A1_o;
  end
endgenerate

assign PORT_A1_RD_DATA_o = PORT_A1_RDATA[PORT_A1_DWIDTH-1:0];

generate
  if (PORT_A2_DWIDTH == 9) begin
    assign PORT_A2_RDATA = { 9'h0, RDATA_A2_o[16], RDATA_A2_o[7:0]};
  end else begin
    assign PORT_A2_RDATA = RDATA_A2_o;
  end
endgenerate

assign PORT_A2_RD_DATA_o = PORT_A2_RDATA[PORT_A2_DWIDTH-1:0];

generate
  if (PORT_B1_DWIDTH == 18) begin
    assign PORT_B1_WDATA[PORT_B1_DWIDTH-1:0] = PORT_B1_WR_DATA_i[PORT_B1_DWIDTH-1:0];
  end else if (PORT_B1_DWIDTH == 9) begin
    assign PORT_B1_WDATA = {1'b0, PORT_B1_WR_DATA_i[8], 8'h0, PORT_B1_WR_DATA_i[7:0]};
  end else begin
    assign PORT_B1_WDATA[17:PORT_B1_DWIDTH] = 0;
    assign PORT_B1_WDATA[PORT_B1_DWIDTH-1:0] = PORT_B1_WR_DATA_i[PORT_B1_DWIDTH-1:0];
  end
endgenerate

assign WDATA_B1_i = PORT_B1_WDATA;

generate
  if (PORT_B2_DWIDTH == 18) begin
    assign PORT_B2_WDATA[PORT_B2_DWIDTH-1:0] = PORT_B2_WR_DATA_i[PORT_B2_DWIDTH-1:0];
  end else if (PORT_B2_DWIDTH == 9) begin
    assign PORT_B2_WDATA = {1'b0, PORT_B2_WR_DATA_i[8], 8'h0, PORT_B2_WR_DATA_i[7:0]};
  end else begin
    assign PORT_B2_WDATA[17:PORT_B2_DWIDTH] = 0;
    assign PORT_B2_WDATA[PORT_B2_DWIDTH-1:0] = PORT_B2_WR_DATA_i[PORT_B2_DWIDTH-1:0];
  end
endgenerate

assign WDATA_B2_i = PORT_B2_WDATA;

generate
  if (PORT_B1_DWIDTH == 9) begin
    assign PORT_B1_RDATA = { 9'h0, RDATA_B1_o[16], RDATA_B1_o[7:0]};
  end else begin
    assign PORT_B1_RDATA = RDATA_B1_o;
  end
endgenerate

assign PORT_B1_RD_DATA_o = PORT_B1_RDATA[PORT_B1_DWIDTH-1:0];

generate
  if (PORT_B2_DWIDTH == 9) begin
    assign PORT_B2_RDATA = { 9'h0, RDATA_B2_o[16], RDATA_B2_o[7:0]};
  end else begin
    assign PORT_B2_RDATA = RDATA_B2_o;
  end
endgenerate

assign PORT_B2_RD_DATA_o = PORT_B2_RDATA[PORT_B2_DWIDTH-1:0];

defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b1,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

(* is_inferred = 0 *)
(* is_split = 1 *)
(* is_fifo = 0 *)
(* port_a1_dwidth = PORT_A1_WRWIDTH *)
(* port_a2_dwidth = PORT_A2_WRWIDTH *)
(* port_b1_dwidth = PORT_B1_WRWIDTH *)
(* port_b2_dwidth = PORT_B2_WRWIDTH *)
TDP36K #(
	.RAM_INIT(pack_init(1))
		) _TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),

	.CLK_A1_i(PORT_A1_CLK),
	.ADDR_A1_i({1'b0,PORT_A1_ADDR}),
	.WEN_A1_i(WEN_A1_i),
	.BE_A1_i(BE_A1_i),
	.WDATA_A1_i(WDATA_A1_i),
	.REN_A1_i(REN_A1_i),
	.RDATA_A1_o(RDATA_A1_o),

	.CLK_A2_i(PORT_A2_CLK),
	.ADDR_A2_i(PORT_A2_ADDR),
	.WEN_A2_i(WEN_A2_i),
	.BE_A2_i(BE_A2_i),
	.WDATA_A2_i(WDATA_A2_i),
	.REN_A2_i(REN_A2_i),
	.RDATA_A2_o(RDATA_A2_o),

	.CLK_B1_i(PORT_B1_CLK),
	.ADDR_B1_i({1'b0,PORT_B1_ADDR}),
	.WEN_B1_i(WEN_B1_i),
	.BE_B1_i(BE_B1_i),
	.WDATA_B1_i(WDATA_B1_i),
	.REN_B1_i(REN_B1_i),
	.RDATA_B1_o(RDATA_B1_o),

	.CLK_B2_i(PORT_B2_CLK),
	.ADDR_B2_i(PORT_B2_ADDR),
	.WEN_B2_i(WEN_B2_i),
	.BE_B2_i(BE_B2_i),
	.WDATA_B2_i(WDATA_B2_i),
	.REN_B2_i(REN_B2_i),
	.RDATA_B2_o(RDATA_B2_o),

	.FLUSH1_i(1'b0),
	.FLUSH2_i(1'b0)
);

endmodule

module SFIFO_36K_BLK (
    DIN,
    PUSH,
    POP,
    CLK,
    Async_Flush,
    Overrun_Error,
    Full_Watermark,
    Almost_Full,
    Full,
    Underrun_Error,
    Empty_Watermark,
    Almost_Empty,
    Empty,
    DOUT
);

  parameter WR_DATA_WIDTH = 36;
  parameter RD_DATA_WIDTH = 36;
  parameter UPAE_DBITS = 12'd10;
  parameter UPAF_DBITS = 12'd10;

  input wire CLK;
  input wire PUSH, POP;
  input wire [WR_DATA_WIDTH-1:0] DIN;
  input wire Async_Flush;
  output wire [RD_DATA_WIDTH-1:0] DOUT;
  output wire Almost_Full, Almost_Empty;
  output wire Full, Empty;
  output wire Full_Watermark, Empty_Watermark;
  output wire Overrun_Error, Underrun_Error;
  
  // Fixed mode settings
  localparam [ 0:0] SYNC_FIFO1_i  = 1'd1;
  localparam [ 0:0] FMODE1_i      = 1'd1;
  localparam [ 0:0] POWERDN1_i    = 1'd0;
  localparam [ 0:0] SLEEP1_i      = 1'd0;
  localparam [ 0:0] PROTECT1_i    = 1'd0;
  localparam [11:0] UPAE1_i       = UPAE_DBITS;
  localparam [11:0] UPAF1_i       = UPAF_DBITS;
  
  localparam [ 0:0] SYNC_FIFO2_i  = 1'd1;
  localparam [ 0:0] FMODE2_i      = 1'd1;
  localparam [ 0:0] POWERDN2_i    = 1'd0;
  localparam [ 0:0] SLEEP2_i      = 1'd0;
  localparam [ 0:0] PROTECT2_i    = 1'd0;
  localparam [10:0] UPAE2_i       = 11'd10;
  localparam [10:0] UPAF2_i       = 11'd10;

  // Width mode function
  function [2:0] mode;
  input integer width;
  case (width)
  1: mode = 3'b101;
  2: mode = 3'b110;
  4: mode = 3'b100;
  8,9: mode = 3'b001;
  16, 18: mode = 3'b010;
  32, 36: mode = 3'b011;
  default: mode = 3'b000;
  endcase
  endfunction
  
  function integer rwmode;
  input integer rwwidth;
  case (rwwidth)
  1: rwmode = 1;
  2: rwmode = 2;
  4: rwmode = 4;
  8,9: rwmode = 9;
  16, 18: rwmode = 18;
  32, 36: rwmode = 36;
  default: rwmode = 36;
  endcase
  endfunction
  
  wire [35:0] in_reg;
  wire [35:0] out_reg;
  wire [17:0] fifo_flags;
  
  wire [35:0] RD_DATA_INT;
  
  wire Push_Clk, Pop_Clk;
  
  assign Push_Clk = CLK;
  assign Pop_Clk = CLK;
  
  assign Overrun_Error = fifo_flags[0];
  assign Full_Watermark = fifo_flags[1];
  assign Almost_Full = fifo_flags[2];
  assign Full = fifo_flags[3];
  assign Underrun_Error = fifo_flags[4];
  assign Empty_Watermark = fifo_flags[5];
  assign Almost_Empty = fifo_flags[6];
  assign Empty = fifo_flags[7];
  
  localparam [ 2:0] RMODE_A1_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] WMODE_A1_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] RMODE_A2_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] WMODE_A2_i    = mode(WR_DATA_WIDTH);
  
  localparam [ 2:0] RMODE_B1_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] WMODE_B1_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] RMODE_B2_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] WMODE_B2_i    = mode(RD_DATA_WIDTH);
  
  localparam PORT_A_WRWIDTH = rwmode(WR_DATA_WIDTH);
  localparam PORT_B_WRWIDTH = rwmode(RD_DATA_WIDTH);
   
  generate
    if (WR_DATA_WIDTH == 36) begin
      assign in_reg[WR_DATA_WIDTH-1:0] = DIN[WR_DATA_WIDTH-1:0];
    end else if (WR_DATA_WIDTH > 18 && WR_DATA_WIDTH < 36) begin
      assign in_reg[WR_DATA_WIDTH+1:18] = DIN[WR_DATA_WIDTH-1:16];
      assign in_reg[17:0] = {2'b00,DIN[15:0]};
    end else if (WR_DATA_WIDTH == 9) begin
      assign in_reg[35:0] = {19'h0, DIN[8], 8'h0, DIN[7:0]};
    end else begin
      assign in_reg[35:WR_DATA_WIDTH]  = 0;
      assign in_reg[WR_DATA_WIDTH-1:0] = DIN[WR_DATA_WIDTH-1:0];
    end
  endgenerate
  
  generate
    if (RD_DATA_WIDTH == 36) begin
      assign RD_DATA_INT = out_reg;
    end else if (RD_DATA_WIDTH > 18 && RD_DATA_WIDTH < 36) begin
      assign RD_DATA_INT  = {2'b00,out_reg[35:18],out_reg[15:0]};
    end else if (RD_DATA_WIDTH == 9) begin
      assign RD_DATA_INT = { 27'h0, out_reg[16], out_reg[7:0]};
    end else begin
      assign RD_DATA_INT = {18'h0, out_reg[17:0]};
    end
  endgenerate
  
  assign DOUT[RD_DATA_WIDTH-1 : 0] = RD_DATA_INT[RD_DATA_WIDTH-1 : 0];
  
  defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
	};
 
  (* is_fifo = 1 *)
  (* sync_fifo = 1 *)
  (* is_inferred = 0 *)
  (* is_split = 0 *)
  (* port_a_dwidth = PORT_A_WRWIDTH *)
  (* port_b_dwidth = PORT_B_WRWIDTH *)
   TDP36K _TECHMAP_REPLACE_ (
		.RESET_ni(1'b1),
		.WDATA_A1_i(in_reg[17:0]),
		.WDATA_A2_i(in_reg[35:18]),
		.RDATA_A1_o(fifo_flags),
		.RDATA_A2_o(),
		.ADDR_A1_i(15'h0),
		.ADDR_A2_i(15'h0),
		.CLK_A1_i(Push_Clk),
		.CLK_A2_i(1'b0),
		.REN_A1_i(1'b1),
		.REN_A2_i(1'b0),
		.WEN_A1_i(PUSH),
		.WEN_A2_i(1'b0),
		.BE_A1_i(2'b11),
		.BE_A2_i(2'b11),

		.WDATA_B1_i(18'h0),
		.WDATA_B2_i(18'h0),
		.RDATA_B1_o(out_reg[17:0]),
		.RDATA_B2_o(out_reg[35:18]),
		.ADDR_B1_i(14'h0),
		.ADDR_B2_i(14'h0),
		.CLK_B1_i(Pop_Clk),
		.CLK_B2_i(1'b0),
		.REN_B1_i(POP),
		.REN_B2_i(1'b0),
		.WEN_B1_i(1'b0),
		.WEN_B2_i(1'b0),
		.BE_B1_i(2'b11),
		.BE_B2_i(2'b11),

		.FLUSH1_i(Async_Flush),
		.FLUSH2_i(1'b0)
	);

  

endmodule 

module AFIFO_36K_BLK (
    DIN,
    PUSH,
    POP,
    Push_Clk,
    Pop_Clk,
    Async_Flush,
    Overrun_Error,
    Full_Watermark,
    Almost_Full,
    Full,
    Underrun_Error,
    Empty_Watermark,
    Almost_Empty,
    Empty,
    DOUT
);

  parameter WR_DATA_WIDTH = 36;
  parameter RD_DATA_WIDTH = 36;
  parameter UPAE_DBITS = 12'd10;
  parameter UPAF_DBITS = 12'd10;

  input wire Push_Clk, Pop_Clk;
  input wire PUSH, POP;
  input wire [WR_DATA_WIDTH-1:0] DIN;
  input wire Async_Flush;
  output wire [RD_DATA_WIDTH-1:0] DOUT;
  output wire Almost_Full, Almost_Empty;
  output wire Full, Empty;
  output wire Full_Watermark, Empty_Watermark;
  output wire Overrun_Error, Underrun_Error;
  
  // Fixed mode settings
  localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
  localparam [ 0:0] FMODE1_i      = 1'd1;
  localparam [ 0:0] POWERDN1_i    = 1'd0;
  localparam [ 0:0] SLEEP1_i      = 1'd0;
  localparam [ 0:0] PROTECT1_i    = 1'd0;
  localparam [11:0] UPAE1_i       = UPAE_DBITS;
  localparam [11:0] UPAF1_i       = UPAF_DBITS;
  
  localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
  localparam [ 0:0] FMODE2_i      = 1'd1;
  localparam [ 0:0] POWERDN2_i    = 1'd0;
  localparam [ 0:0] SLEEP2_i      = 1'd0;
  localparam [ 0:0] PROTECT2_i    = 1'd0;
  localparam [10:0] UPAE2_i       = 11'd10;
  localparam [10:0] UPAF2_i       = 11'd10;

  // Width mode function
  function [2:0] mode;
  input integer width;
  case (width)
  1: mode = 3'b101;
  2: mode = 3'b110;
  4: mode = 3'b100;
  8,9: mode = 3'b001;
  16, 18: mode = 3'b010;
  32, 36: mode = 3'b011;
  default: mode = 3'b000;
  endcase
  endfunction
  
  function integer rwmode;
  input integer rwwidth;
  case (rwwidth)
  1: rwmode = 1;
  2: rwmode = 2;
  4: rwmode = 4;
  8,9: rwmode = 9;
  16, 18: rwmode = 18;
  32, 36: rwmode = 36;
  default: rwmode = 36;
  endcase
  endfunction
  
  wire [35:0] in_reg;
  wire [35:0] out_reg;
  wire [17:0] fifo_flags;
  
  wire [35:0] RD_DATA_INT;
  wire [35:WR_DATA_WIDTH] WR_DATA_CMPL;
  
  assign Overrun_Error = fifo_flags[0];
  assign Full_Watermark = fifo_flags[1];
  assign Almost_Full = fifo_flags[2];
  assign Full = fifo_flags[3];
  assign Underrun_Error = fifo_flags[4];
  assign Empty_Watermark = fifo_flags[5];
  assign Almost_Empty = fifo_flags[6];
  assign Empty = fifo_flags[7];
  
  localparam [ 2:0] RMODE_A1_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] WMODE_A1_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] RMODE_A2_i    = mode(WR_DATA_WIDTH);
  localparam [ 2:0] WMODE_A2_i    = mode(WR_DATA_WIDTH);
  
  localparam [ 2:0] RMODE_B1_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] WMODE_B1_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] RMODE_B2_i    = mode(RD_DATA_WIDTH);
  localparam [ 2:0] WMODE_B2_i    = mode(RD_DATA_WIDTH);
  
  localparam PORT_A_WRWIDTH = rwmode(WR_DATA_WIDTH);
  localparam PORT_B_WRWIDTH = rwmode(RD_DATA_WIDTH);
   
  generate
    if (WR_DATA_WIDTH == 36) begin
      assign in_reg[WR_DATA_WIDTH-1:0] = DIN[WR_DATA_WIDTH-1:0];
    end else if (WR_DATA_WIDTH > 18 && WR_DATA_WIDTH < 36) begin
      assign in_reg[WR_DATA_WIDTH+1:18] = DIN[WR_DATA_WIDTH-1:16];
      assign in_reg[17:0] = {2'b00,DIN[15:0]};
    end else if (WR_DATA_WIDTH == 9) begin
      assign in_reg[35:0] = {19'h0, DIN[8], 8'h0, DIN[7:0]};
    end else begin
      assign in_reg[35:WR_DATA_WIDTH]  = 0;
      assign in_reg[WR_DATA_WIDTH-1:0] = DIN[WR_DATA_WIDTH-1:0];
    end
  endgenerate
  
  generate
    if (RD_DATA_WIDTH == 36) begin
      assign RD_DATA_INT = out_reg;
    end else if (RD_DATA_WIDTH > 18 && RD_DATA_WIDTH < 36) begin
      assign RD_DATA_INT  = {2'b00,out_reg[35:18],out_reg[15:0]};
    end else if (RD_DATA_WIDTH == 9) begin
      assign RD_DATA_INT = { 27'h0, out_reg[16], out_reg[7:0]};
    end else begin
      assign RD_DATA_INT = {18'h0, out_reg[17:0]};
    end
  endgenerate
  
  assign DOUT[RD_DATA_WIDTH-1 : 0] = RD_DATA_INT[RD_DATA_WIDTH-1 : 0];
  
  defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
	};
 
  (* is_fifo = 1 *)
  (* sync_fifo = 0 *)
  (* is_inferred = 0 *)
  (* is_split = 0 *)
  (* port_a_dwidth = PORT_A_WRWIDTH *)
  (* port_b_dwidth = PORT_B_WRWIDTH *)
 	TDP36K _TECHMAP_REPLACE_ (
		.RESET_ni(1'b1),
		.WDATA_A1_i(in_reg[17:0]),
		.WDATA_A2_i(in_reg[35:18]),
		.RDATA_A1_o(fifo_flags),
		.RDATA_A2_o(),
		.ADDR_A1_i(15'h0),
		.ADDR_A2_i(15'h0),
		.CLK_A1_i(Push_Clk),
		.CLK_A2_i(1'b0),
		.REN_A1_i(1'b1),
		.REN_A2_i(1'b0),
		.WEN_A1_i(PUSH),
		.WEN_A2_i(1'b0),
		.BE_A1_i(2'b11),
		.BE_A2_i(2'b11),

		.WDATA_B1_i(18'h0),
		.WDATA_B2_i(18'h0),
		.RDATA_B1_o(out_reg[17:0]),
		.RDATA_B2_o(out_reg[35:18]),
		.ADDR_B1_i(14'h0),
		.ADDR_B2_i(14'h0),
		.CLK_B1_i(Pop_Clk),
		.CLK_B2_i(1'b0),
		.REN_B1_i(POP),
		.REN_B2_i(1'b0),
		.WEN_B1_i(1'b0),
		.WEN_B2_i(1'b0),
		.BE_B1_i(2'b11),
		.BE_B2_i(2'b11),

		.FLUSH1_i(Async_Flush),
		.FLUSH2_i(1'b0)
	);

 

endmodule 

module SFIFO_18K_BLK (
    DIN,
    PUSH,
    POP,
    CLK,
    Async_Flush,
    Overrun_Error,
    Full_Watermark,
    Almost_Full,
    Full,
    Underrun_Error,
    Empty_Watermark,
    Almost_Empty,
    Empty,
    DOUT
);
  
  parameter WR_DATA_WIDTH = 18;
  parameter RD_DATA_WIDTH = 18;
  parameter UPAE_DBITS = 11'd10;
  parameter UPAF_DBITS = 11'd10;

  input wire CLK;
  input wire PUSH, POP;
  input wire [WR_DATA_WIDTH-1:0] DIN;
  input wire Async_Flush;
  output wire [RD_DATA_WIDTH-1:0] DOUT;
  output wire Almost_Full, Almost_Empty;
  output wire Full, Empty;
  output wire Full_Watermark, Empty_Watermark;
  output wire Overrun_Error, Underrun_Error;
 
 	BRAM2x18_SFIFO  #(
      .WR1_DATA_WIDTH(WR_DATA_WIDTH), 
      .RD1_DATA_WIDTH(RD_DATA_WIDTH),
      .UPAE_DBITS1(UPAE_DBITS),
      .UPAF_DBITS1(UPAF_DBITS),
      .WR2_DATA_WIDTH(), 
      .RD2_DATA_WIDTH(),
      .UPAE_DBITS2(),
      .UPAF_DBITS2()   
       ) U1
      (
      .DIN1(DIN),
      .PUSH1(PUSH),
      .POP1(POP),
      .CLK1(CLK),
      .Async_Flush1(Async_Flush),
      .Overrun_Error1(Overrun_Error),
      .Full_Watermark1(Full_Watermark),
      .Almost_Full1(Almost_Full),
      .Full1(Full),
      .Underrun_Error1(Underrun_Error),
      .Empty_Watermark1(Empty_Watermark),
      .Almost_Empty1(Almost_Empty),
      .Empty1(Empty),
      .DOUT1(DOUT),
      
      .DIN2(18'h0),
      .PUSH2(1'b0),
      .POP2(1'b0),
      .CLK2(1'b0),
      .Async_Flush2(1'b0),
      .Overrun_Error2(),
      .Full_Watermark2(),
      .Almost_Full2(),
      .Full2(),
      .Underrun_Error2(),
      .Empty_Watermark2(),
      .Almost_Empty2(),
      .Empty2(),
      .DOUT2()
	);

endmodule

module SFIFO_18K_X2_BLK (
    DIN1,
    PUSH1,
    POP1,
    CLK1,
    Async_Flush1,
    Overrun_Error1,
    Full_Watermark1,
    Almost_Full1,
    Full1,
    Underrun_Error1,
    Empty_Watermark1,
    Almost_Empty1,
    Empty1,
    DOUT1,
    
    DIN2,
    PUSH2,
    POP2,
    CLK2,
    Async_Flush2,
    Overrun_Error2,
    Full_Watermark2,
    Almost_Full2,
    Full2,
    Underrun_Error2,
    Empty_Watermark2,
    Almost_Empty2,
    Empty2,
    DOUT2
);

  parameter WR1_DATA_WIDTH = 18;
  parameter RD1_DATA_WIDTH = 18;
  
  parameter WR2_DATA_WIDTH = 18;
  parameter RD2_DATA_WIDTH = 18;
  
  parameter UPAE_DBITS1 = 12'd10;
  parameter UPAF_DBITS1 = 12'd10;
  
  parameter UPAE_DBITS2 = 11'd10;
  parameter UPAF_DBITS2 = 11'd10;

  input wire CLK1;
  input wire PUSH1, POP1;
  input wire [WR1_DATA_WIDTH-1:0] DIN1;
  input wire Async_Flush1;
  output wire [RD1_DATA_WIDTH-1:0] DOUT1;
  output wire Almost_Full1, Almost_Empty1;
  output wire Full1, Empty1;
  output wire Full_Watermark1, Empty_Watermark1;
  output wire Overrun_Error1, Underrun_Error1;
  
  input wire CLK2;
  input wire PUSH2, POP2;
  input wire [WR2_DATA_WIDTH-1:0] DIN2;
  input wire Async_Flush2;
  output wire [RD2_DATA_WIDTH-1:0] DOUT2;
  output wire Almost_Full2, Almost_Empty2;
  output wire Full2, Empty2;
  output wire Full_Watermark2, Empty_Watermark2;
  output wire Overrun_Error2, Underrun_Error2;
  
  // Fixed mode settings
  localparam [ 0:0] SYNC_FIFO1_i  = 1'd1;
  localparam [ 0:0] FMODE1_i      = 1'd1;
  localparam [ 0:0] POWERDN1_i    = 1'd0;
  localparam [ 0:0] SLEEP1_i      = 1'd0;
  localparam [ 0:0] PROTECT1_i    = 1'd0;
  localparam [11:0] UPAE1_i       = UPAE_DBITS1;
  localparam [11:0] UPAF1_i       = UPAF_DBITS1;
  
  localparam [ 0:0] SYNC_FIFO2_i  = 1'd1;
  localparam [ 0:0] FMODE2_i      = 1'd1;
  localparam [ 0:0] POWERDN2_i    = 1'd0;
  localparam [ 0:0] SLEEP2_i      = 1'd0;
  localparam [ 0:0] PROTECT2_i    = 1'd0;
  localparam [10:0] UPAE2_i       = UPAE_DBITS2;
  localparam [10:0] UPAF2_i       = UPAF_DBITS2;

  // Width mode function
  function [2:0] mode;
  input integer width;
  case (width)
  1: mode = 3'b101;
  2: mode = 3'b110;
  4: mode = 3'b100;
  8,9: mode = 3'b001;
  16, 18: mode = 3'b010;
  32, 36: mode = 3'b011;
  default: mode = 3'b000;
  endcase
  endfunction
  
  function integer rwmode;
  input integer rwwidth;
  case (rwwidth)
  1: rwmode = 1;
  2: rwmode = 2;
  4: rwmode = 4;
  8,9: rwmode = 9;
  16, 18: rwmode = 18;
  default: rwmode = 18;
  endcase
  endfunction
  
  wire [17:0] in_reg1;
  wire [17:0] out_reg1;
  wire [17:0] fifo1_flags;
  
  wire [17:0] in_reg2;
  wire [17:0] out_reg2;
  wire [17:0] fifo2_flags;
  
  wire Push_Clk1, Pop_Clk1;
  wire Push_Clk2, Pop_Clk2;
  assign Push_Clk1 = CLK1;
  assign Pop_Clk1 = CLK1;
  assign Push_Clk2 = CLK2;
  assign Pop_Clk2 = CLK2;
  
  assign Overrun_Error1 = fifo1_flags[0];
  assign Full_Watermark1 = fifo1_flags[1];
  assign Almost_Full1 = fifo1_flags[2];
  assign Full1 = fifo1_flags[3];
  assign Underrun_Error1 = fifo1_flags[4];
  assign Empty_Watermark1 = fifo1_flags[5];
  assign Almost_Empty1 = fifo1_flags[6];
  assign Empty1 = fifo1_flags[7];
  
  assign Overrun_Error2 = fifo2_flags[0];
  assign Full_Watermark2 = fifo2_flags[1];
  assign Almost_Full2 = fifo2_flags[2];
  assign Full2 = fifo2_flags[3];
  assign Underrun_Error2 = fifo2_flags[4];
  assign Empty_Watermark2 = fifo2_flags[5];
  assign Almost_Empty2 = fifo2_flags[6];
  assign Empty2 = fifo2_flags[7];
  
  localparam [ 2:0] RMODE_A1_i    = mode(WR1_DATA_WIDTH);
  localparam [ 2:0] WMODE_A1_i    = mode(WR1_DATA_WIDTH);
  localparam [ 2:0] RMODE_A2_i    = mode(WR2_DATA_WIDTH);
  localparam [ 2:0] WMODE_A2_i    = mode(WR2_DATA_WIDTH);
  
  localparam [ 2:0] RMODE_B1_i    = mode(RD1_DATA_WIDTH);
  localparam [ 2:0] WMODE_B1_i    = mode(RD1_DATA_WIDTH);
  localparam [ 2:0] RMODE_B2_i    = mode(RD2_DATA_WIDTH);
  localparam [ 2:0] WMODE_B2_i    = mode(RD2_DATA_WIDTH);
  
  localparam PORT_A1_WRWIDTH = rwmode(WR1_DATA_WIDTH);
  localparam PORT_B1_WRWIDTH = rwmode(RD1_DATA_WIDTH);
  localparam PORT_A2_WRWIDTH = rwmode(WR2_DATA_WIDTH);
  localparam PORT_B2_WRWIDTH = rwmode(RD2_DATA_WIDTH);
  
  generate
    if (WR1_DATA_WIDTH == 18) begin
      assign in_reg1[17:0] = DIN1[17:0];
    end else if (WR1_DATA_WIDTH == 9) begin
      assign in_reg1[17:0] = {1'b0, DIN1[8], 8'h0, DIN1[7:0]};
    end else begin
      assign in_reg1[17:WR1_DATA_WIDTH]  = 0;
      assign in_reg1[WR1_DATA_WIDTH-1:0] = DIN1[WR1_DATA_WIDTH-1:0];
    end
  endgenerate     
  
  generate
    if (RD1_DATA_WIDTH == 9) begin
      assign DOUT1[RD1_DATA_WIDTH-1:0] = {out_reg1[16], out_reg1[7:0]};
    end else begin
      assign DOUT1[RD1_DATA_WIDTH-1:0] = out_reg1[RD1_DATA_WIDTH-1:0];
    end
  endgenerate 
  
  generate
    if (WR2_DATA_WIDTH == 18) begin
      assign in_reg2[17:0] = DIN2[17:0];
    end else if (WR2_DATA_WIDTH == 9) begin
      assign in_reg2[17:0] = {1'b0, DIN2[8], 8'h0, DIN2[7:0]};
    end else begin
      assign in_reg2[17:WR2_DATA_WIDTH]  = 0;
      assign in_reg2[WR2_DATA_WIDTH-1:0] = DIN2[WR2_DATA_WIDTH-1:0];
    end
  endgenerate     
  
  generate
    if (RD2_DATA_WIDTH == 9) begin
      assign DOUT2[RD2_DATA_WIDTH-1:0] = {out_reg2[16], out_reg2[7:0]};
    end else begin
      assign DOUT2[RD2_DATA_WIDTH-1:0] = out_reg2[RD2_DATA_WIDTH-1:0];
    end
  endgenerate 
  
  defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b1,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
	};

  (* is_fifo = 1 *) 
  (* sync_fifo = 1 *) 
  (* is_split = 1 *)
  (* is_inferred = 0 *)
  (* port_a1_dwidth = PORT_A1_WRWIDTH *)
  (* port_a2_dwidth = PORT_A2_WRWIDTH *)
  (* port_b1_dwidth = PORT_B1_WRWIDTH *)
  (* port_b2_dwidth = PORT_B2_WRWIDTH *)
 	TDP36K _TECHMAP_REPLACE_ (
		.RESET_ni(1'b1),
		.WDATA_A1_i(in_reg1[17:0]),
		.WDATA_A2_i(in_reg2[17:0]),
		.RDATA_A1_o(fifo1_flags),
		.RDATA_A2_o(fifo2_flags),
		.ADDR_A1_i(15'h0),
		.ADDR_A2_i(15'h0),
		.CLK_A1_i(Push_Clk1),
		.CLK_A2_i(Push_Clk2),
		.REN_A1_i(1'b1),
		.REN_A2_i(1'b1),
		.WEN_A1_i(PUSH1),
		.WEN_A2_i(PUSH2),
		.BE_A1_i(2'b11),
		.BE_A2_i(2'b11),

		.WDATA_B1_i(18'h0),
		.WDATA_B2_i(18'h0),
		.RDATA_B1_o(out_reg1[17:0]),
		.RDATA_B2_o(out_reg2[17:0]),
		.ADDR_B1_i(14'h0),
		.ADDR_B2_i(14'h0),
		.CLK_B1_i(Pop_Clk1),
		.CLK_B2_i(Pop_Clk2),
		.REN_B1_i(POP1),
		.REN_B2_i(POP2),
		.WEN_B1_i(1'b0),
		.WEN_B2_i(1'b0),
		.BE_B1_i(2'b11),
		.BE_B2_i(2'b11),

		.FLUSH1_i(Async_Flush1),
		.FLUSH2_i(Async_Flush2)
	);

endmodule

module AFIFO_18K_BLK (
    DIN,
    PUSH,
    POP,
    Push_Clk,
    Pop_Clk,
    Async_Flush,
    Overrun_Error,
    Full_Watermark,
    Almost_Full,
    Full,
    Underrun_Error,
    Empty_Watermark,
    Almost_Empty,
    Empty,
    DOUT
);
  
  parameter WR_DATA_WIDTH = 18;
  parameter RD_DATA_WIDTH = 18;
  parameter UPAE_DBITS = 11'd10;
  parameter UPAF_DBITS = 11'd10;

  input wire Push_Clk, Pop_Clk;
  input wire PUSH, POP;
  input wire [WR_DATA_WIDTH-1:0] DIN;
  input wire Async_Flush;
  output wire [RD_DATA_WIDTH-1:0] DOUT;
  output wire Almost_Full, Almost_Empty;
  output wire Full, Empty;
  output wire Full_Watermark, Empty_Watermark;
  output wire Overrun_Error, Underrun_Error;
 
 	BRAM2x18_AFIFO  #(
      .WR1_DATA_WIDTH(WR_DATA_WIDTH), 
      .RD1_DATA_WIDTH(RD_DATA_WIDTH),
      .UPAE_DBITS1(UPAE_DBITS),
      .UPAF_DBITS1(UPAF_DBITS),
      .WR2_DATA_WIDTH(), 
      .RD2_DATA_WIDTH(),
      .UPAE_DBITS2(),
      .UPAF_DBITS2()
       ) U1
      (
      .DIN1(DIN),
      .PUSH1(PUSH),
      .POP1(POP),
      .Push_Clk1(Push_Clk),
      .Pop_Clk1(Pop_Clk),
      .Async_Flush1(Async_Flush),
      .Overrun_Error1(Overrun_Error),
      .Full_Watermark1(Full_Watermark),
      .Almost_Full1(Almost_Full),
      .Full1(Full),
      .Underrun_Error1(Underrun_Error),
      .Empty_Watermark1(Empty_Watermark),
      .Almost_Empty1(Almost_Empty),
      .Empty1(Empty),
      .DOUT1(DOUT),
      
      .DIN2(18'h0),
      .PUSH2(1'b0),
      .POP2(1'b0),
      .Push_Clk2(1'b0),
      .Pop_Clk2(1'b0),
      .Async_Flush2(1'b0),
      .Overrun_Error2(),
      .Full_Watermark2(),
      .Almost_Full2(),
      .Full2(),
      .Underrun_Error2(),
      .Empty_Watermark2(),
      .Almost_Empty2(),
      .Empty2(),
      .DOUT2()
	);

endmodule

module AFIFO_18K_X2_BLK (
    DIN1,
    PUSH1,
    POP1,
    Push_Clk1,
	Pop_Clk1,
    Async_Flush1,
    Overrun_Error1,
    Full_Watermark1,
    Almost_Full1,
    Full1,
    Underrun_Error1,
    Empty_Watermark1,
    Almost_Empty1,
    Empty1,
    DOUT1,
    
    DIN2,
    PUSH2,
    POP2,
    Push_Clk2,
	Pop_Clk2,
    Async_Flush2,
    Overrun_Error2,
    Full_Watermark2,
    Almost_Full2,
    Full2,
    Underrun_Error2,
    Empty_Watermark2,
    Almost_Empty2,
    Empty2,
    DOUT2
);

  parameter WR1_DATA_WIDTH = 18;
  parameter RD1_DATA_WIDTH = 18;
  
  parameter WR2_DATA_WIDTH = 18;
  parameter RD2_DATA_WIDTH = 18;
  
  parameter UPAE_DBITS1 = 12'd10;
  parameter UPAF_DBITS1 = 12'd10;
  
  parameter UPAE_DBITS2 = 11'd10;
  parameter UPAF_DBITS2 = 11'd10;

  input wire Push_Clk1, Pop_Clk1;
  input wire PUSH1, POP1;
  input wire [WR1_DATA_WIDTH-1:0] DIN1;
  input wire Async_Flush1;
  output wire [RD1_DATA_WIDTH-1:0] DOUT1;
  output wire Almost_Full1, Almost_Empty1;
  output wire Full1, Empty1;
  output wire Full_Watermark1, Empty_Watermark1;
  output wire Overrun_Error1, Underrun_Error1;
  
  input wire Push_Clk2, Pop_Clk2;
  input wire PUSH2, POP2;
  input wire [WR2_DATA_WIDTH-1:0] DIN2;
  input wire Async_Flush2;
  output wire [RD2_DATA_WIDTH-1:0] DOUT2;
  output wire Almost_Full2, Almost_Empty2;
  output wire Full2, Empty2;
  output wire Full_Watermark2, Empty_Watermark2;
  output wire Overrun_Error2, Underrun_Error2;
  
  // Fixed mode settings
  localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
  localparam [ 0:0] FMODE1_i      = 1'd1;
  localparam [ 0:0] POWERDN1_i    = 1'd0;
  localparam [ 0:0] SLEEP1_i      = 1'd0;
  localparam [ 0:0] PROTECT1_i    = 1'd0;
  localparam [11:0] UPAE1_i       = UPAE_DBITS1;
  localparam [11:0] UPAF1_i       = UPAF_DBITS1;
  
  localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
  localparam [ 0:0] FMODE2_i      = 1'd1;
  localparam [ 0:0] POWERDN2_i    = 1'd0;
  localparam [ 0:0] SLEEP2_i      = 1'd0;
  localparam [ 0:0] PROTECT2_i    = 1'd0;
  localparam [10:0] UPAE2_i       = UPAE_DBITS2;
  localparam [10:0] UPAF2_i       = UPAF_DBITS2;

  // Width mode function
  function [2:0] mode;
  input integer width;
  case (width)
  1: mode = 3'b101;
  2: mode = 3'b110;
  4: mode = 3'b100;
  8,9: mode = 3'b001;
  16, 18: mode = 3'b010;
  32, 36: mode = 3'b011;
  default: mode = 3'b000;
  endcase
  endfunction
  
  function integer rwmode;
  input integer rwwidth;
  case (rwwidth)
  1: rwmode = 1;
  2: rwmode = 2;
  4: rwmode = 4;
  8,9: rwmode = 9;
  16, 18: rwmode = 18;
  default: rwmode = 18;
  endcase
  endfunction
  
  wire [17:0] in_reg1;
  wire [17:0] out_reg1;
  wire [17:0] fifo1_flags;
  
  wire [17:0] in_reg2;
  wire [17:0] out_reg2;
  wire [17:0] fifo2_flags;
  
  wire Push_Clk1, Pop_Clk1;
  wire Push_Clk2, Pop_Clk2;
  
  assign Overrun_Error1 = fifo1_flags[0];
  assign Full_Watermark1 = fifo1_flags[1];
  assign Almost_Full1 = fifo1_flags[2];
  assign Full1 = fifo1_flags[3];
  assign Underrun_Error1 = fifo1_flags[4];
  assign Empty_Watermark1 = fifo1_flags[5];
  assign Almost_Empty1 = fifo1_flags[6];
  assign Empty1 = fifo1_flags[7];
  
  assign Overrun_Error2 = fifo2_flags[0];
  assign Full_Watermark2 = fifo2_flags[1];
  assign Almost_Full2 = fifo2_flags[2];
  assign Full2 = fifo2_flags[3];
  assign Underrun_Error2 = fifo2_flags[4];
  assign Empty_Watermark2 = fifo2_flags[5];
  assign Almost_Empty2 = fifo2_flags[6];
  assign Empty2 = fifo2_flags[7];
  
  localparam [ 2:0] RMODE_A1_i    = mode(WR1_DATA_WIDTH);
  localparam [ 2:0] WMODE_A1_i    = mode(WR1_DATA_WIDTH);
  localparam [ 2:0] RMODE_A2_i    = mode(WR2_DATA_WIDTH);
  localparam [ 2:0] WMODE_A2_i    = mode(WR2_DATA_WIDTH);
  
  localparam [ 2:0] RMODE_B1_i    = mode(RD1_DATA_WIDTH);
  localparam [ 2:0] WMODE_B1_i    = mode(RD1_DATA_WIDTH);
  localparam [ 2:0] RMODE_B2_i    = mode(RD2_DATA_WIDTH);
  localparam [ 2:0] WMODE_B2_i    = mode(RD2_DATA_WIDTH);
  
  localparam PORT_A1_WRWIDTH = rwmode(WR1_DATA_WIDTH);
  localparam PORT_B1_WRWIDTH = rwmode(RD1_DATA_WIDTH);
  localparam PORT_A2_WRWIDTH = rwmode(WR2_DATA_WIDTH);
  localparam PORT_B2_WRWIDTH = rwmode(RD2_DATA_WIDTH);
  
  generate
    if (WR1_DATA_WIDTH == 18) begin
      assign in_reg1[17:0] = DIN1[17:0];
    end else if (WR1_DATA_WIDTH == 9) begin
      assign in_reg1[17:0] = {1'b0, DIN1[8], 8'h0, DIN1[7:0]};
    end else begin
      assign in_reg1[17:WR1_DATA_WIDTH]  = 0;
      assign in_reg1[WR1_DATA_WIDTH-1:0] = DIN1[WR1_DATA_WIDTH-1:0];
    end
  endgenerate     
  
  generate
    if (RD1_DATA_WIDTH == 9) begin
      assign DOUT1[RD1_DATA_WIDTH-1:0] = {out_reg1[16], out_reg1[7:0]};
    end else begin
      assign DOUT1[RD1_DATA_WIDTH-1:0] = out_reg1[RD1_DATA_WIDTH-1:0];
    end
  endgenerate 
  
  generate
    if (WR2_DATA_WIDTH == 18) begin
      assign in_reg2[17:0] = DIN2[17:0];
    end else if (WR2_DATA_WIDTH == 9) begin
      assign in_reg2[17:0] = {1'b0, DIN2[8], 8'h0, DIN2[7:0]};
    end else begin
      assign in_reg2[17:WR2_DATA_WIDTH]  = 0;
      assign in_reg2[WR2_DATA_WIDTH-1:0] = DIN2[WR2_DATA_WIDTH-1:0];
    end
  endgenerate     
  
  generate
    if (RD2_DATA_WIDTH == 9) begin
      assign DOUT2[RD2_DATA_WIDTH-1:0] = {out_reg2[16], out_reg2[7:0]};
    end else begin
      assign DOUT2[RD2_DATA_WIDTH-1:0] = out_reg2[RD2_DATA_WIDTH-1:0];
    end
  endgenerate 
  
  defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b1,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
	};

  (* is_fifo = 1 *) 
  (* sync_fifo = 0 *) 
  (* is_split = 1 *)
  (* is_inferred = 0 *)
  (* port_a1_dwidth = PORT_A1_WRWIDTH *)
  (* port_a2_dwidth = PORT_A2_WRWIDTH *)
  (* port_b1_dwidth = PORT_B1_WRWIDTH *)
  (* port_b2_dwidth = PORT_B2_WRWIDTH *)
 	TDP36K _TECHMAP_REPLACE_ (
		.RESET_ni(1'b1),
		.WDATA_A1_i(in_reg1[17:0]),
		.WDATA_A2_i(in_reg2[17:0]),
		.RDATA_A1_o(fifo1_flags),
		.RDATA_A2_o(fifo2_flags),
		.ADDR_A1_i(15'h0),
		.ADDR_A2_i(15'h0),
		.CLK_A1_i(Push_Clk1),
		.CLK_A2_i(Push_Clk2),
		.REN_A1_i(1'b1),
		.REN_A2_i(1'b1),
		.WEN_A1_i(PUSH1),
		.WEN_A2_i(PUSH2),
		.BE_A1_i(2'b11),
		.BE_A2_i(2'b11),

		.WDATA_B1_i(18'h0),
		.WDATA_B2_i(18'h0),
		.RDATA_B1_o(out_reg1[17:0]),
		.RDATA_B2_o(out_reg2[17:0]),
		.ADDR_B1_i(14'h0),
		.ADDR_B2_i(14'h0),
		.CLK_B1_i(Pop_Clk1),
		.CLK_B2_i(Pop_Clk2),
		.REN_B1_i(POP1),
		.REN_B2_i(POP2),
		.WEN_B1_i(1'b0),
		.WEN_B2_i(1'b0),
		.BE_B1_i(2'b11),
		.BE_B2_i(2'b11),

		.FLUSH1_i(Async_Flush1),
		.FLUSH2_i(Async_Flush2)
	);

endmodule

module TDP_RAM36K (
    ADDR_A,
    ADDR_B,
    BE_A,
    BE_B,
	CLK_A,
	CLK_B,
	REN_A,
	REN_B,
	WDATA_A,
	WDATA_B,
	WEN_A,
	WEN_B,
	WPARITY_A, 
	WPARITY_B,
	RDATA_A,
	RDATA_B,
	RPARITY_A,
	RPARITY_B
	);

parameter [5:0] READ_WIDTH_A = 6'd36;
parameter [5:0] READ_WIDTH_B = 6'd36;
parameter [5:0] WRITE_WIDTH_A = 6'd36;
parameter [5:0] WRITE_WIDTH_B = 6'd36;

parameter [1024*32-1:0] INIT = 32768'b0;
parameter [1024*4-1:0] INIT_PARITY = 4096'b0;

input wire [14:0] ADDR_A;
input wire [14:0] ADDR_B;
input wire [3:0] BE_A;
input wire [3:0] BE_B;
input wire CLK_A;
input wire CLK_B;
input wire REN_A;
input wire REN_B;
input wire [31:0] WDATA_A;
input wire [3:0] WPARITY_A; 
input wire [31:0] WDATA_B;
input wire [3:0] WPARITY_B;
input wire WEN_A;
input wire WEN_B;
output wire [31:0] RDATA_A;
output wire [3:0] RPARITY_A;
output wire [31:0] RDATA_B;
output wire [3:0] RPARITY_B;

// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = 1'd0;
localparam [ 0:0] FMODE1_i      = 1'd0;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = 12'd10;
localparam [11:0] UPAF1_i       = 12'd10;

localparam [ 0:0] SYNC_FIFO2_i  = 1'd0;
localparam [ 0:0] FMODE2_i      = 1'd0;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input [5:0] width;
	case (width)
		6'd1: mode = 3'b101;
		6'd2: mode = 3'b110;
		6'd4: mode = 3'b100;
		6'd9: mode = 3'b001;
		6'd18: mode = 3'b010;
		6'd36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction

function integer rwmode;
input [5:0] rwwidth;
	case (rwwidth)
		6'd1: rwmode = 1;
		6'd2: rwmode = 2;
		6'd4: rwmode = 4;
		6'd9: rwmode = 9;
		6'd18: rwmode = 18;
		6'd36: rwmode = 36;
		default: rwmode = 36;
	endcase
endfunction

function [36863:0] pack_init;
input enable;
	integer i;
	reg [31:0] ri;
	reg [3:0] rip;
	for (i = 0; i <  1024; i = i + 1) begin
		ri = (enable)? INIT[i*32 +: 32] : 32'h0;
		rip = (enable)? INIT_PARITY[i*4 +: 4] : 4'h0;
		pack_init[i*36 +: 36] = {rip[3:2], ri[31:16],
								 rip[1:0], ri[15:0]};
	end
endfunction

wire REN_A1_i;
wire REN_B1_i;
wire WEN_A1_i;
wire WEN_B1_i;

wire [1:0] BE_A1_i;
wire [1:0] BE_A2_i;
wire [1:0] BE_B1_i;
wire [1:0] BE_B2_i;

wire [17:0] WDATA_A1_i;
wire [17:0] WDATA_A2_i;
wire [17:0] WDATA_B1_i;
wire [17:0] WDATA_B2_i;

wire [17:0] RDATA_A1_o;
wire [17:0] RDATA_A2_o;
wire [17:0] RDATA_B1_o;
wire [17:0] RDATA_B2_o;

wire [35:0] PORT_A_RDATA;
wire [35:0] PORT_B_RDATA;
wire [35:0] PORT_A_WDATA;
wire [35:0] PORT_B_WDATA;

wire [14:0] PORT_A_ADDR;
wire [14:0] PORT_B_ADDR;

wire PORT_A_CLK;
wire PORT_B_CLK;

// Set port width mode (In non-split mode A2/B2 is not active. Set same values anyway to match previous behavior.)
localparam [ 2:0] RMODE_A1_i    = mode(READ_WIDTH_A);
localparam [ 2:0] WMODE_A1_i    = mode(WRITE_WIDTH_A);
localparam [ 2:0] RMODE_A2_i    = mode(READ_WIDTH_A);
localparam [ 2:0] WMODE_A2_i    = mode(WRITE_WIDTH_A);

localparam [ 2:0] RMODE_B1_i    = mode(READ_WIDTH_B);
localparam [ 2:0] WMODE_B1_i    = mode(WRITE_WIDTH_B);
localparam [ 2:0] RMODE_B2_i    = mode(READ_WIDTH_B);
localparam [ 2:0] WMODE_B2_i    = mode(WRITE_WIDTH_B);

localparam PORT_A_WRWIDTH = rwmode(WRITE_WIDTH_A);
localparam PORT_B_WRWIDTH = rwmode(READ_WIDTH_B);

assign PORT_A_CLK = CLK_A;
assign PORT_B_CLK = CLK_B;

assign PORT_A_ADDR = ADDR_A;
assign PORT_B_ADDR = ADDR_B;

assign REN_A1_i = REN_A;
assign WEN_A1_i = WEN_A;
assign BE_A1_i  = BE_A[1:0];
assign BE_A2_i  = BE_A[3:2];

assign REN_B1_i = REN_B;
assign WEN_B1_i = WEN_B;
assign BE_B1_i  = BE_B[1:0];
assign BE_B2_i  = BE_B[3:2];

generate
  if (PORT_A_WRWIDTH == 9) begin
    assign PORT_A_WDATA = {19'h0, WPARITY_A[0], 8'h0, WDATA_A[7:0]};
  end else begin
    assign PORT_A_WDATA = {WPARITY_A[3], WDATA_A[31:24], WPARITY_A[2], WDATA_A[23:16], WPARITY_A[1], WDATA_A[15:8], WPARITY_A[0], WDATA_A[7:0]};
  end
endgenerate

assign WDATA_A1_i = PORT_A_WDATA[17:0];
assign WDATA_A2_i = PORT_A_WDATA[35:18];

generate
  if (PORT_B_WRWIDTH == 9) begin
    assign PORT_B_WDATA = {19'h0, WPARITY_B[0], 8'h0, WDATA_B[7:0]};
  end else begin
    assign PORT_B_WDATA = {WPARITY_B[3], WDATA_B[31:24], WPARITY_B[2], WDATA_B[23:16], WPARITY_B[1], WDATA_B[15:8], WPARITY_B[0], WDATA_B[7:0]};
  end
endgenerate

assign WDATA_B1_i = PORT_B_WDATA[17:0];
assign WDATA_B2_i = PORT_B_WDATA[35:18];

generate
  if (PORT_A_WRWIDTH == 9) begin
    assign PORT_A_RDATA = { 27'h0, RDATA_A1_o[16], RDATA_A1_o[7:0]};
  end else begin
    assign PORT_A_RDATA = {RDATA_A2_o, RDATA_A1_o};
  end
endgenerate

assign RDATA_A = {PORT_A_RDATA[34:27], PORT_A_RDATA[25:18], PORT_A_RDATA[16:9], PORT_A_RDATA[7:0]};
assign RPARITY_A = {PORT_A_RDATA[35], PORT_A_RDATA[26], PORT_A_RDATA[17], PORT_A_RDATA[8]};

generate
  if (PORT_B_WRWIDTH == 9) begin
    assign PORT_B_RDATA = { 27'h0, RDATA_B1_o[16], RDATA_B1_o[7:0]};
  end else begin
    assign PORT_B_RDATA = {RDATA_B2_o, RDATA_B1_o};
  end
endgenerate

assign RDATA_B = {PORT_B_RDATA[34:27], PORT_B_RDATA[25:18], PORT_B_RDATA[16:9], PORT_B_RDATA[7:0]};
assign RPARITY_B = {PORT_B_RDATA[35], PORT_B_RDATA[26], PORT_B_RDATA[17], PORT_B_RDATA[8]};

defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
	UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
	UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

(* is_inferred = 0 *)
(* is_split = 0 *)
(* is_fifo = 0 *)
(* port_a_dwidth = PORT_A_WRWIDTH *)
(* port_b_dwidth = PORT_B_WRWIDTH *)
TDP36K #(.RAM_INIT(pack_init(1))
		) 
_TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),

	.CLK_A1_i(PORT_A_CLK),
	.ADDR_A1_i(PORT_A_ADDR),
	.WEN_A1_i(WEN_A1_i),
	.BE_A1_i(BE_A1_i),
	.WDATA_A1_i(WDATA_A1_i),
	.REN_A1_i(REN_A1_i),
	.RDATA_A1_o(RDATA_A1_o),

	.CLK_A2_i(PORT_A_CLK),
	.ADDR_A2_i(14'h0),
	.WEN_A2_i(1'b0),
	.BE_A2_i(BE_A2_i),
	.WDATA_A2_i(WDATA_A2_i),
	.REN_A2_i(1'b0),
	.RDATA_A2_o(RDATA_A2_o),

	.CLK_B1_i(PORT_B_CLK),
	.ADDR_B1_i(PORT_B_ADDR),
	.WEN_B1_i(WEN_B1_i),
	.BE_B1_i(BE_B1_i),
	.WDATA_B1_i(WDATA_B1_i),
	.REN_B1_i(REN_B1_i),
	.RDATA_B1_o(RDATA_B1_o),

	.CLK_B2_i(PORT_B_CLK),
	.ADDR_B2_i(14'h0),
	.WEN_B2_i(1'b0),
	.BE_B2_i(BE_B2_i),
	.WDATA_B2_i(WDATA_B2_i),
	.REN_B2_i(1'b0),
	.RDATA_B2_o(RDATA_B2_o),

	.FLUSH1_i(1'b0),
	.FLUSH2_i(1'b0)
);

endmodule

module FIFO36K (
    RD_CLK,
    WR_CLK,
    RESET,
    RD_EN,
    WR_EN,
    WR_DATA,
    RD_DATA,
    ALMOST_FULL,
	ALMOST_EMPTY,
    FULL,
    EMPTY,
    PROG_FULL,
    PROG_EMPTY,
    OVERFLOW,
    UNDERFLOW
);
  
parameter [5:0] DATA_READ_WIDTH = 6'd36;
parameter [5:0] DATA_WRITE_WIDTH = 6'd36;
parameter [11:0] PROG_EMPTY_THRESH = 12'd20;
parameter [11:0] PROG_FULL_THRESH = 12'd24;

parameter FIFO_TYPE = "SYNCHRONOUS";

input wire RD_CLK, WR_CLK;
input wire RESET;
input wire RD_EN, WR_EN;
input wire [35:0] WR_DATA;

output wire [35:0] RD_DATA;
output wire ALMOST_FULL, ALMOST_EMPTY;
output wire FULL, EMPTY;
output wire PROG_FULL, PROG_EMPTY;
output wire OVERFLOW, UNDERFLOW;
  
// Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = (FIFO_TYPE == "SYNCHRONOUS"); 
localparam [ 0:0] FMODE1_i      = 1'd1;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = PROG_EMPTY_THRESH;
localparam [11:0] UPAF1_i       = PROG_FULL_THRESH;

localparam [ 0:0] SYNC_FIFO2_i  = (FIFO_TYPE == "SYNCHRONOUS");
localparam [ 0:0] FMODE2_i      = 1'd1;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = 11'd10;
localparam [10:0] UPAF2_i       = 11'd10;

// Width mode function
function [2:0] mode;
input [5:0] width;
	case (width)
		6'd1: mode = 3'b101;
		6'd2: mode = 3'b110;
		6'd4: mode = 3'b100;
		6'd9: mode = 3'b001;
		6'd18: mode = 3'b010;
		6'd36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction
  
function integer rwmode;
input [5:0] rwwidth;
	case (rwwidth)
		6'd1: rwmode = 1;
		6'd2: rwmode = 2;
		6'd4: rwmode = 4;
		6'd9: rwmode = 9;
		6'd18: rwmode = 18;
		6'd36: rwmode = 36;
		default: rwmode = 36;
	endcase
endfunction
  
wire [35:0] in_reg;
wire [35:0] out_reg;
wire [17:0] fifo_flags;

wire [35:0] RD_DATA_INT;

wire Push_Clk, Pop_Clk;
wire Push, Pop;

wire Async_Flush;

assign Push_Clk = WR_CLK;
assign Pop_Clk = RD_CLK;

assign Push = WR_EN;
assign Pop = RD_EN;

assign Async_Flush = RESET;

assign OVERFLOW = fifo_flags[0];
assign PROG_FULL = fifo_flags[1];
assign ALMOST_FULL = fifo_flags[2];
assign FULL = fifo_flags[3];
assign UNDERFLOW = fifo_flags[4];
assign PROG_EMPTY = fifo_flags[5];
assign ALMOST_EMPTY = fifo_flags[6];
assign EMPTY = fifo_flags[7];

localparam [ 2:0] RMODE_A1_i    = mode(DATA_WRITE_WIDTH);
localparam [ 2:0] WMODE_A1_i    = mode(DATA_WRITE_WIDTH);
localparam [ 2:0] RMODE_A2_i    = mode(DATA_WRITE_WIDTH);
localparam [ 2:0] WMODE_A2_i    = mode(DATA_WRITE_WIDTH);

localparam [ 2:0] RMODE_B1_i    = mode(DATA_READ_WIDTH);
localparam [ 2:0] WMODE_B1_i    = mode(DATA_READ_WIDTH);
localparam [ 2:0] RMODE_B2_i    = mode(DATA_READ_WIDTH);
localparam [ 2:0] WMODE_B2_i    = mode(DATA_READ_WIDTH);

localparam PORT_A_WRWIDTH = rwmode(DATA_WRITE_WIDTH);
localparam PORT_B_WRWIDTH = rwmode(DATA_READ_WIDTH);
 
generate
  if (PORT_A_WRWIDTH == 36) begin
    assign in_reg[PORT_A_WRWIDTH-1:0] = WR_DATA[PORT_A_WRWIDTH-1:0];
  end else if (PORT_A_WRWIDTH == 9) begin
    assign in_reg[35:0] = {19'h0, WR_DATA[8], 8'h0, WR_DATA[7:0]};
  end else begin
    assign in_reg[35:PORT_A_WRWIDTH]  = 0;
    assign in_reg[PORT_A_WRWIDTH-1:0] = WR_DATA[PORT_A_WRWIDTH-1:0];
  end
endgenerate
 
 generate
   if (PORT_B_WRWIDTH == 36) begin
     assign RD_DATA_INT = out_reg;
   end else if (PORT_B_WRWIDTH == 9) begin
     assign RD_DATA_INT = { 27'h0, out_reg[16], out_reg[7:0]};
   end else begin
     assign RD_DATA_INT[35:PORT_B_WRWIDTH]  = 0;
     assign RD_DATA_INT[PORT_B_WRWIDTH-1:0] = out_reg[PORT_B_WRWIDTH-1:0];
   end
 endgenerate
 
 assign RD_DATA = RD_DATA_INT;
 
 defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

 (* is_fifo = FMODE1_i *)
 (* sync_fifo = SYNC_FIFO1_i *) 
 (* is_inferred = 0 *)
 (* is_split = 0 *)
 (* port_a_dwidth = PORT_A_WRWIDTH *)
 (* port_b_dwidth = PORT_B_WRWIDTH *)
  TDP36K _TECHMAP_REPLACE_ (
	.RESET_ni(1'b1),
	.WDATA_A1_i(in_reg[17:0]),
	.WDATA_A2_i(in_reg[35:18]),
	.RDATA_A1_o(fifo_flags),
	.RDATA_A2_o(),
	.ADDR_A1_i(15'h0),
	.ADDR_A2_i(15'h0),
	.CLK_A1_i(Push_Clk),
	.CLK_A2_i(1'b0),
	.REN_A1_i(1'b1),
	.REN_A2_i(1'b0),
	.WEN_A1_i(Push),
	.WEN_A2_i(1'b0),
	.BE_A1_i(2'b11),
	.BE_A2_i(2'b11),

	.WDATA_B1_i(18'h0),
	.WDATA_B2_i(18'h0),
	.RDATA_B1_o(out_reg[17:0]),
	.RDATA_B2_o(out_reg[35:18]),
	.ADDR_B1_i(14'h0),
	.ADDR_B2_i(14'h0),
	.CLK_B1_i(Pop_Clk),
	.CLK_B2_i(1'b0),
	.REN_B1_i(Pop),
	.REN_B2_i(1'b0),
	.WEN_B1_i(1'b0),
	.WEN_B2_i(1'b0),
	.BE_B1_i(2'b11),
	.BE_B2_i(2'b11),

	.FLUSH1_i(Async_Flush),
	.FLUSH2_i(1'b0)
);

endmodule 


module FIFO18KX2 (
    RD_CLK1,
    WR_CLK1,
    RESET1,
    RD_EN1,
    WR_EN1,
    WR_DATA1,
    RD_DATA1,
    ALMOST_FULL1,
	ALMOST_EMPTY1,
    FULL1,
    EMPTY1,
    PROG_FULL1,
    PROG_EMPTY1,
    OVERFLOW1,
    UNDERFLOW1,
	
    RD_CLK2,
    WR_CLK2,
    RESET2,
    RD_EN2,
    WR_EN2,
    WR_DATA2,
    RD_DATA2,
    ALMOST_FULL2,
	ALMOST_EMPTY2,
    FULL2,
    EMPTY2,
    PROG_FULL2,
    PROG_EMPTY2,
    OVERFLOW2,
    UNDERFLOW2
);
  
parameter [4:0] DATA_READ_WIDTH1 = 5'd18;
parameter [4:0] DATA_READ_WIDTH2 = 5'd18;
parameter [4:0] DATA_WRITE_WIDTH1 = 5'd18;
parameter [4:0] DATA_WRITE_WIDTH2 = 5'd18;
parameter [11:0] PROG_EMPTY_THRESH1 = 12'd20;
parameter [10:0] PROG_EMPTY_THRESH2 = 11'd20;
parameter [11:0] PROG_FULL_THRESH1 = 12'd24;
parameter [10:0] PROG_FULL_THRESH2 = 11'd24;

parameter FIFO_TYPE1 = "SYNCHRONOUS";
parameter FIFO_TYPE2 = "SYNCHRONOUS";

input wire RD_CLK1, WR_CLK1, RD_CLK2, WR_CLK2;
input wire RESET1, RESET2;
input wire RD_EN1, WR_EN1, RD_EN2, WR_EN2;
input wire [17:0] WR_DATA1;
input wire [17:0] WR_DATA2;

output wire [17:0] RD_DATA1;
output wire [17:0] RD_DATA2;
output wire ALMOST_FULL1, ALMOST_EMPTY1, ALMOST_FULL2, ALMOST_EMPTY2;
output wire FULL1, EMPTY1, FULL2, EMPTY2;
output wire PROG_FULL1, PROG_EMPTY1, PROG_FULL2, PROG_EMPTY2;
output wire OVERFLOW1, UNDERFLOW1, OVERFLOW2, UNDERFLOW2;

 // Fixed mode settings
localparam [ 0:0] SYNC_FIFO1_i  = (FIFO_TYPE1 == "SYNCHRONOUS");
localparam [ 0:0] FMODE1_i      = 1'd1;
localparam [ 0:0] POWERDN1_i    = 1'd0;
localparam [ 0:0] SLEEP1_i      = 1'd0;
localparam [ 0:0] PROTECT1_i    = 1'd0;
localparam [11:0] UPAE1_i       = PROG_EMPTY_THRESH1;
localparam [11:0] UPAF1_i       = PROG_FULL_THRESH1;

localparam [ 0:0] SYNC_FIFO2_i  = (FIFO_TYPE2 == "SYNCHRONOUS");
localparam [ 0:0] FMODE2_i      = 1'd1;
localparam [ 0:0] POWERDN2_i    = 1'd0;
localparam [ 0:0] SLEEP2_i      = 1'd0;
localparam [ 0:0] PROTECT2_i    = 1'd0;
localparam [10:0] UPAE2_i       = PROG_EMPTY_THRESH2;
localparam [10:0] UPAF2_i       = PROG_FULL_THRESH2;

// Width mode function
function [2:0] mode;
input [4:0] width;
	case (width)
		5'd1: mode = 3'b101;
		5'd2: mode = 3'b110;
		5'd4: mode = 3'b100;
		5'd9: mode = 3'b001;
		5'd18: mode = 3'b010;
		5'd36: mode = 3'b011;
		default: mode = 3'b000;
	endcase
endfunction
  
function integer rwmode;
input [4:0] rwwidth;
	case (rwwidth)
		5'd1: rwmode = 1;
		5'd2: rwmode = 2;
		5'd4: rwmode = 4;
		5'd9: rwmode = 9;
		5'd18: rwmode = 18;
		5'd36: rwmode = 36;
		default: rwmode = 36;
	endcase
endfunction
  
wire [17:0] in_reg1;
wire [17:0] in_reg2;
wire [17:0] out_reg1;
wire [17:0] out_reg2;
wire [17:0] fifo_flags1;
wire [17:0] fifo_flags2;

wire [17:0] RD_DATA_INT1;
wire [17:0] RD_DATA_INT2;

wire Push_Clk1, Pop_Clk1;
wire Push_Clk2, Pop_Clk2;
wire Push1, Pop1;
wire Push2, Pop2;

wire Async_Flush1;
wire Async_Flush2;

assign Push_Clk1 = WR_CLK1;
assign Pop_Clk1 = RD_CLK1;

assign Push_Clk2 = WR_CLK2;
assign Pop_Clk2 = RD_CLK2;

assign Push1 = WR_EN1;
assign Pop1 = RD_EN1;

assign Push2 = WR_EN2; 
assign Pop2 = RD_EN2;

assign Async_Flush1 = RESET1;
assign Async_Flush2 = RESET2;

assign OVERFLOW1 = fifo_flags1[0];
assign PROG_FULL1 = fifo_flags1[1];
assign ALMOST_FULL1 = fifo_flags1[2];
assign FULL1 = fifo_flags1[3];
assign UNDERFLOW1 = fifo_flags1[4];
assign PROG_EMPTY1 = fifo_flags1[5];
assign ALMOST_EMPTY1 = fifo_flags1[6];
assign EMPTY1 = fifo_flags1[7];

assign OVERFLOW2 = fifo_flags2[0];
assign PROG_FULL2 = fifo_flags2[1];
assign ALMOST_FULL2 = fifo_flags2[2];
assign FULL2 = fifo_flags2[3];
assign UNDERFLOW2 = fifo_flags2[4];
assign PROG_EMPTY2 = fifo_flags2[5];
assign ALMOST_EMPTY2 = fifo_flags2[6];
assign EMPTY2 = fifo_flags2[7];

localparam [ 2:0] RMODE_A1_i    = mode(DATA_WRITE_WIDTH1);
localparam [ 2:0] WMODE_A1_i    = mode(DATA_WRITE_WIDTH1);
localparam [ 2:0] RMODE_A2_i    = mode(DATA_WRITE_WIDTH2);
localparam [ 2:0] WMODE_A2_i    = mode(DATA_WRITE_WIDTH2);

localparam [ 2:0] RMODE_B1_i    = mode(DATA_READ_WIDTH1);
localparam [ 2:0] WMODE_B1_i    = mode(DATA_READ_WIDTH1);
localparam [ 2:0] RMODE_B2_i    = mode(DATA_READ_WIDTH2);
localparam [ 2:0] WMODE_B2_i    = mode(DATA_READ_WIDTH2);

localparam PORT_A_WRWIDTH1 = rwmode(DATA_WRITE_WIDTH1);
localparam PORT_B_WRWIDTH1 = rwmode(DATA_READ_WIDTH1);
localparam PORT_A_WRWIDTH2 = rwmode(DATA_WRITE_WIDTH2);
localparam PORT_B_WRWIDTH2 = rwmode(DATA_READ_WIDTH2);
 
generate
  if (PORT_A_WRWIDTH1 == 18) begin
    assign in_reg1[PORT_A_WRWIDTH1-1:0] = WR_DATA1[PORT_A_WRWIDTH1-1:0];
  end else if (PORT_A_WRWIDTH1 == 9) begin
    assign in_reg1[17:0] = {1'b0, WR_DATA1[8], 8'h0, WR_DATA1[7:0]};
  end else begin
    assign in_reg1[17:PORT_A_WRWIDTH1]  = 0;
    assign in_reg1[PORT_A_WRWIDTH1-1:0] = WR_DATA1[PORT_A_WRWIDTH1-1:0];
  end
endgenerate
 
generate
  if (PORT_B_WRWIDTH1 == 18) begin
    assign RD_DATA_INT1 = out_reg1;
  end else if (PORT_B_WRWIDTH1 == 9) begin
    assign RD_DATA_INT1 = {1'b0, out_reg1[16], out_reg1[7:0]};
  end else begin
    assign RD_DATA_INT1[17:PORT_B_WRWIDTH1]  = 0;
    assign RD_DATA_INT1[PORT_B_WRWIDTH1-1:0] = out_reg1[PORT_B_WRWIDTH1-1:0];
  end
endgenerate
 
assign RD_DATA1 = RD_DATA_INT1;

generate
  if (PORT_A_WRWIDTH2 == 18) begin
    assign in_reg2[PORT_A_WRWIDTH2-1:0] = WR_DATA2[PORT_A_WRWIDTH2-1:0];
  end else if (PORT_A_WRWIDTH2 == 9) begin
    assign in_reg2[17:0] = {1'b0, WR_DATA2[8], 8'h0, WR_DATA2[7:0]};
  end else begin
    assign in_reg2[17:PORT_A_WRWIDTH2]  = 0;
    assign in_reg2[PORT_A_WRWIDTH2-1:0] = WR_DATA2[PORT_A_WRWIDTH2-1:0];
  end
endgenerate
 
generate
  if (PORT_B_WRWIDTH2 == 18) begin
    assign RD_DATA_INT2 = out_reg2;
  end else if (PORT_B_WRWIDTH2 == 9) begin
    assign RD_DATA_INT2 = {1'b0, out_reg2[16], out_reg2[7:0]};
  end else begin
    assign RD_DATA_INT2[17:PORT_B_WRWIDTH2]  = 0;
    assign RD_DATA_INT2[PORT_B_WRWIDTH2-1:0] = out_reg2[PORT_B_WRWIDTH2-1:0];
  end
endgenerate
 
assign RD_DATA2 = RD_DATA_INT2;
 
defparam _TECHMAP_REPLACE_.MODE_BITS = { 1'b0,
UPAF2_i, UPAE2_i, PROTECT2_i, SLEEP2_i, POWERDN2_i, FMODE2_i, WMODE_B2_i, WMODE_A2_i, RMODE_B2_i, RMODE_A2_i, SYNC_FIFO2_i,
UPAF1_i, UPAE1_i, PROTECT1_i, SLEEP1_i, POWERDN1_i, FMODE1_i, WMODE_B1_i, WMODE_A1_i, RMODE_B1_i, RMODE_A1_i, SYNC_FIFO1_i
};

  (* is_fifo = FMODE1_i *)
  (* sync_fifo = SYNC_FIFO1_i *) 
  (* is_split = 0 *)
  (* is_inferred = 0 *)
  (* port_a1_dwidth = PORT_A_WRWIDTH1 *)
  (* port_b1_dwidth = PORT_B_WRWIDTH1 *)
  (* port_a2_dwidth = PORT_A_WRWIDTH2 *)
  (* port_b2_dwidth = PORT_B_WRWIDTH2 *)
   TDP36K _TECHMAP_REPLACE_ (
      .RESET_ni(1'b1),
      .WDATA_A1_i(in_reg1[17:0]),
      .WDATA_A2_i(in_reg2[17:0]),
      .RDATA_A1_o(fifo_flags1),
      .RDATA_A2_o(fifo_flags2),
      .ADDR_A1_i(15'h0),
      .ADDR_A2_i(15'h0),
      .CLK_A1_i(Push_Clk1),
      .CLK_A2_i(Push_Clk2),
      .REN_A1_i(1'b1),
      .REN_A2_i(1'b0),
      .WEN_A1_i(Push1),
      .WEN_A2_i(Push2),
      .BE_A1_i(2'b11),
      .BE_A2_i(2'b11),
      
      .WDATA_B1_i(18'h0),
      .WDATA_B2_i(18'h0),
      .RDATA_B1_o(out_reg1[17:0]),
      .RDATA_B2_o(out_reg2[17:0]),
      .ADDR_B1_i(14'h0),
      .ADDR_B2_i(14'h0),
      .CLK_B1_i(Pop_Clk1),
      .CLK_B2_i(Pop_Clk2),
      .REN_B1_i(Pop1),
      .REN_B2_i(Pop2),
      .WEN_B1_i(1'b0),
      .WEN_B2_i(1'b0),
      .BE_B1_i(2'b11),
      .BE_B2_i(2'b11),
      
      .FLUSH1_i(Async_Flush1),
      .FLUSH2_i(Async_Flush2)
);

endmodule 