/*
    AXI have 5 independent channels 
    each have its own handshake mechanism 
    and after the valid is asserted data should be stable
    
    another main condition is that 
    in write resp channel bvalid depends on the complition 
    of capturing the valid addr as well as valid data.
*/

module AXI_SLAVE
#(parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)
(
input aclk,
input aresetn,

//aw addr channel
input [ADDR_WIDTH-1:0] awaddr,
input awvalid,
output reg awready,

//wr data channel
input [DATA_WIDTH-1:0]wdata,
input  wvalid,
input [DATA_WIDTH/8 - 1:0] wstrb,
output reg wready,

//ar addr channel
input [ADDR_WIDTH-1:0]araddr,
input arvalid,
output reg arready,

//rd data channel
output reg [DATA_WIDTH-1:0]rdata,
output reg rvalid,
output reg [1:0]rresp,
input  rready,

//b response channel
output reg bvalid,
output reg [1:0] bresp,
input bready

);

// mem

reg [DATA_WIDTH - 1:0] mem [0:255];

// Internal registers

reg aw_done;
reg [ADDR_WIDTH - 1:0] reg_awaddr;

reg [DATA_WIDTH - 1:0] reg_wdata;
reg [DATA_WIDTH/8 - 1:0] reg_wstrb;
reg w_done;

reg [ADDR_WIDTH - 1:0] reg_araddr;
reg ar_done;

///--- WRITE ADDR CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        awready  <= 1'b1;
        aw_done  <= 1'b0;
    end
    
    else 
    begin 
        if(awready && awvalid)
        begin 
            awready    <= 1'b0;
            aw_done    <= 1'b1;
            reg_awaddr <= awaddr;
        end
        
        /* only make arready 1 after the 1st trasaction is done , 
        if we donot put that condition then it may happen that new addr will be latched and the 
        data will be written on the wrong addr*/
        
        else if(bready && bvalid) 
        begin 
            awready <= 1'b1;
            aw_done <= 1'b0;
        end
    end
end

///--- WRITE CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        wready    <= 1'b1;
        w_done    <= 1'b0;
        reg_wdata <= 32'h0000_0000;
        reg_wstrb <= 4'h00;
    end
    
    else 
    begin 
        /*
        in this channel we will only latch the wdata and we will rigth that data 
        in the mem after fulfulliing both condition of having valid data as well 
        as valid addr.
        */
        if(wready && wvalid)
        begin 
            wready    <= 1'b0;
            w_done    <= 1'b1;
            reg_wdata <= wdata;
            reg_wstrb <= wstrb; 
        end
        
        else if(bvalid && bready)
        begin 
            wready <= 1'b1;
            w_done <= 1'b0;
        end
    end
end

///--- WRITE RESPONSE AS WELL AS MEM WRITEBACK ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        bvalid <= 1'b0;
        bresp <= 2'b00;
    end
    
    else 
    begin 
        if(aw_done && w_done && !bvalid) 
        begin
        /* 
        this condition check that if we have the successfully latched the correct 
        data as well as the addr only then write data to memory
        */ 
        
            // write data to the memory first 
        
            if (reg_wstrb[0]) mem[reg_awaddr[9:2]][7:0]   <= reg_wdata[7:0];
            if (reg_wstrb[1]) mem[reg_awaddr[9:2]][15:8]  <= reg_wdata[15:8];
            if (reg_wstrb[2]) mem[reg_awaddr[9:2]][23:16] <= reg_wdata[23:16];
            if (reg_wstrb[3]) mem[reg_awaddr[9:2]][31:24] <= reg_wdata[31:24];
            
            // now assert the remaning signals
            
            bvalid <= 1'b1;
            bresp <= 2'b00;    
        end
        
        else if(bvalid && bready)
        begin 
            bvalid <= 1'b0;
        end
    end
end


///--- READ ADDR CHANNEL ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
        arready <= 1'b1;
        ar_done <= 1'b0;
    end
    
    else 
    begin 
        if(arready && arvalid)
        begin 
            arready    <= 1'b0;
            ar_done    <= 1'b1;
            reg_araddr <= araddr;
        end
        
        else if(rvalid && rready)
        begin 
            arready <= 1'b1;
            ar_done <= 1'b0;
        end
    end
end


///--- READ DATA AND READ RESPONSE ---///

always @(posedge aclk)
begin 
    if(!aresetn)
    begin 
       rdata  <= 32'h0000_0000;
       rvalid <= 1'b0;
       rresp  <= 2'b00; 
    end
    
    else 
    begin 
        /*
            we will send data only when we have recived valid addr 
            and when rvalid is not 1, so that it would not violate the 
            axi rules
        */
        if(ar_done && !rvalid)
        begin 
            rvalid <= 1'b1;
            rdata <= mem[reg_araddr[9:2]];
            rresp <= 2'b00; // okay
        end
        else if(rvalid && rready)
        begin 
            rvalid <= 1'b0;
        end
    end
end
endmodule

/*
    also this code only supports 1 outstanding write and read 
*/