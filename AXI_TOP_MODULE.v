`timescale 1ns / 1ps

module AXI_TOP_MODULE
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input                           clk,
    input                           resetn,
    
    input  [ADDR_WIDTH-1:0]         in_addr_write,
    input  [DATA_WIDTH-1:0]         in_data,
    input  [DATA_WIDTH/8-1:0]       in_data_strb,
       
    input  [ADDR_WIDTH-1:0]         in_addr_read,
    output [DATA_WIDTH-1:0]         out_data_read,
    output [1:0]                    out_data_rresp
);


//  interconnect wires


// AW channel
wire [ADDR_WIDTH-1:0] awaddr;
wire                  awvalid;
wire                  awready;

// W channel
wire [DATA_WIDTH-1:0] wdata;
wire [DATA_WIDTH/8-1:0] wstrb;
wire                  wvalid;
wire                  wready;

// B channel
wire                  bready;
wire                  bvalid;
wire [1:0]            bresp;

// AR channel
wire [ADDR_WIDTH-1:0] araddr;
wire                  arvalid;
wire                  arready;

// R channel
wire                  rready;
wire [DATA_WIDTH-1:0] rdata;
wire                  rvalid;
wire [1:0]            rresp;

// AXI MASTER

AXI4_LITE_MASTER #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) MASTER (
    .aclk           (clk),
    .aresetn        (resetn),

    .in_addr_write  (in_addr_write),
    .in_data        (in_data),
    .in_data_strb   (in_data_strb),

    .in_addr_read   (in_addr_read),
    .out_data_read  (out_data_read),
    .out_data_rresp (out_data_rresp),

    .awaddr         (awaddr),
    .awvalid        (awvalid),
    .awready        (awready),

    .wdata          (wdata),
    .wstrb          (wstrb),
    .wvalid         (wvalid),
    .wready         (wready),

    .bready         (bready),
    .bvalid         (bvalid),
    .bresp          (bresp),

    .araddr         (araddr),
    .arvalid        (arvalid),
    .arready        (arready),

    .rready         (rready),
    .rdata          (rdata),
    .rvalid         (rvalid),
    .rresp          (rresp)
);

// AXI SLAVE

AXI_SLAVE #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) SLAVE (
    .aclk     (clk),
    .aresetn  (resetn),

    .awaddr   (awaddr),
    .awvalid  (awvalid),
    .awready  (awready),

    .wdata    (wdata),
    .wvalid   (wvalid),
    .wstrb    (wstrb),
    .wready   (wready),

    .bvalid   (bvalid),
    .bresp    (bresp),
    .bready   (bready),

    .araddr   (araddr),
    .arvalid  (arvalid),
    .arready  (arready),

    .rdata    (rdata),
    .rvalid   (rvalid),
    .rresp    (rresp),
    .rready   (rready)
);

endmodule
