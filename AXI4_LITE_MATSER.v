`timescale 1ns / 1ps

module AXI4_LITE_MASTER
#(parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)
(
    input                           aclk,
    input                           aresetn,
    
    // user interface
    input      [ADDR_WIDTH - 1:0]   in_addr_write,
    input      [DATA_WIDTH - 1:0]   in_data,
    input      [DATA_WIDTH/8 - 1:0] in_data_strb,
    
    input      [ADDR_WIDTH - 1:0]   in_addr_read,
    output reg [DATA_WIDTH - 1:0]   out_data_read,
    output reg                      out_data_rresp,
    
    // aw channel
    output reg [ADDR_WIDTH - 1:0]   awaddr,
    output reg                      awvalid,
    input                           awready,
    
    // w channel
    output reg [DATA_WIDTH - 1:0]   wdata,
    output reg [DATA_WIDTH/8 - 1:0] wstrb,
    output reg                      wvalid,
    input                           wready,
    
    // b channel
    output reg                      bready,
    input                           bvalid,
    input       [1:0]               bresp,
    
    // ar channel
    output reg [ADDR_WIDTH - 1:0]  araddr,
    output reg                     arvalid,
    input                          arready,
    
    // r channel
    output reg                     rready,
    input      [DATA_WIDTH - 1:0]  rdata,
    input                          rvalid,
    input      [1:0]               rresp
);

// Internal registers

reg aw_done;
reg w_done;
reg ar_done;

///--- WRITE ADDR CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        awvalid <= 1'b0;
        awaddr  <= 32'h0000_0000;
        aw_done <= 1'b0;
    end
        
    else 
    begin 
        if(!aw_done && !awvalid)
        begin 
            awvalid <= 1'b1;
            awaddr  <= in_addr_write;
            aw_done <= 1'b0;
        end
        
        else if(awvalid && awready)
        begin 
            awvalid <= 1'b0;
            aw_done <= 1'b1;
        end
        
        else if(bready && bvalid)
        begin 
            aw_done <= 1'b0;
        end
    end
end


///--- WRITE CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        w_done <= 1'b0;
        wvalid <= 1'b0;
        wdata  <= 32'h0000_0000;
        wstrb  <= 4'b0000;
    end
    
    else 
    begin 
        if(!w_done && !wvalid)
        begin 
            wvalid <= 1'b1;
            w_done <= 1'b0;
            wdata  <= in_data;
            wstrb  <= in_data_strb;
        end
        
        else if(wvalid && wready)
        begin 
            wvalid <= 1'b0;
            w_done <= 1'b1;
        end
        
        else if(bvalid && bready)
        begin 
            w_done <= 1'b0;
        end
    end
end

///--- WRITE RESPONSE CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        bready <= 1'b0;
    end
    
    else 
    begin 
        if(aw_done && w_done)
        begin 
            bready <= 1'b1;
        end
        
        else if(bready && bvalid)
        begin 
            bready  <= 1'b0;
//            w_done  <= 1'b0;
//            aw_done <= 1'b0;
/*
    we cannot do things like this bcz this is not good, 
    if we drive 1 signals in the 2 different always blocks
    then its violation
*/
        end
    end
end



///--- READ ADDR CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        arvalid <= 1'b0;
        araddr  <= 32'h0000_0000;
        ar_done <= 1'b0;
    end
    
    else 
    begin 
        if(!ar_done && !arvalid)
        begin 
            arvalid <= 1'b1;
            araddr  <= in_addr_read;
            ar_done <= 1'b0;
        end
        
        else if(arready && arvalid)
        begin 
            arvalid <= 1'b0;
            ar_done <= 1'b1;
        end
        
        else if(rvalid && rready)
        begin 
            ar_done <= 1'b0;
        end
    end
end


///--- READ AND READ RESPONSE CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        rready         <= 1'b0;
        out_data_rresp <= 2'b11;
        out_data_read  <= 32'h0000_0000;
    end
    
    else 
    begin 
        if(ar_done)
        begin 
            rready <= 1'b1;
        end
        
        else if(rready && rvalid)
        begin 
            out_data_read <= rdata;
            out_data_rresp <= rresp;
            rready <= 1'b0;
//            ar_done <= 1'b0;
        end
    end
end
endmodule