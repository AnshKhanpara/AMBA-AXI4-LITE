`timescale 1ns/1ps

interface axi_inf #(parameter ADDR_WIDTH=32, DATA_WIDTH=32);

  logic aclk;
  logic aresetn;

  logic [ADDR_WIDTH-1:0] in_addr_write;
  logic [DATA_WIDTH-1:0] in_data;
  logic [DATA_WIDTH/8-1:0] in_data_strb;
  logic [ADDR_WIDTH-1:0] in_addr_read;

  logic [DATA_WIDTH-1:0] out_data_read;
  logic [1:0] out_data_rresp;

  logic [ADDR_WIDTH-1:0] awaddr;
  logic awvalid;
  logic awready;

  logic [DATA_WIDTH-1:0] wdata;
  logic wvalid;
  logic wready;

  logic [ADDR_WIDTH-1:0] araddr;
  logic arvalid;
  logic arready;

  logic [DATA_WIDTH-1:0] rdata;
  logic rvalid;
  logic rready;
  logic [1:0] rresp;

  clocking drv_cb @(posedge aclk);
    output in_addr_write;
    output in_data;
    output in_data_strb;
    output in_addr_read;
    input awready;
    input wready;
    input arready;
  endclocking

  clocking mon_cb @(posedge aclk);
    input awaddr;
    input awvalid;
    input awready;
    input wdata;
    input wvalid;
    input wready;
    input araddr;
    input arvalid;
    input arready;
    input rdata;
    input rvalid;
    input rready;
    input rresp;
  endclocking

endinterface



class packet;

  rand bit [31:0] in_addr_write;
  rand bit [31:0] in_data;
  rand bit [3:0]  in_data_strb;
  rand bit [31:0] in_addr_read;

  constraint write_addr { in_addr_write < 30; }
  constraint read_addr  { in_addr_read  < 30; }
  constraint full_strb  { in_data_strb == 4'hF; }
  constraint diff_addr  { in_addr_write == in_addr_read; }

endclass



class transaction;

  bit [31:0] read_addr;
  bit [31:0] read_data;
  bit [1:0]  rresp;

endclass



class generator;

  mailbox gen2drv;
  mailbox gen2sb;

  function new(mailbox g2d, mailbox g2s);
    gen2drv = g2d;
    gen2sb  = g2s;
  endfunction

  task run();
    repeat(10) begin
      packet p;
      p = new();
      assert(p.randomize());
      gen2drv.put(p);
      gen2sb.put(p);
    end
  endtask

endclass



class driver;

  virtual axi_inf inf;
  mailbox gen2drv;

  function new(virtual axi_inf inf, mailbox g2d);
    this.inf = inf;
    gen2drv  = g2d;
  endfunction

  task run();

    packet p;

    wait(inf.aresetn);

    forever begin
      gen2drv.get(p);

      @(inf.drv_cb);
      wait(inf.drv_cb.awready);

      inf.drv_cb.in_addr_write <= p.in_addr_write;

      wait(inf.drv_cb.wready);

      inf.drv_cb.in_data      <= p.in_data;
      inf.drv_cb.in_data_strb <= p.in_data_strb;

      @(inf.drv_cb);

      @(inf.drv_cb);
      wait(inf.drv_cb.arready);

      inf.drv_cb.in_addr_read <= p.in_addr_read;

    end

  endtask

endclass



class monitor;

  virtual axi_inf inf;
  mailbox mon2sb;

  bit [31:0] araddr_q[$];

  function new(virtual axi_inf inf, mailbox m2s);
    this.inf = inf;
    mon2sb   = m2s;
  endfunction

  task run();

    transaction tr;

    wait(inf.aresetn);

    forever begin
      @(posedge inf.aclk);

      if(inf.arvalid && inf.arready)
        araddr_q.push_back(inf.araddr);

      if(inf.rvalid && inf.rready) begin
        tr = new();
        tr.read_addr = araddr_q.pop_front();
        tr.read_data = inf.rdata;
        tr.rresp     = inf.rresp;
        mon2sb.put(tr);
      end
    end

  endtask

endclass



class scoreboard;

  mailbox gen2sb;
  mailbox mon2sb;

  bit [31:0] model_mem [0:255];

  bit [31:0] pending_addr[$];
  bit [31:0] pending_data[$];

  function new(mailbox g2s, mailbox m2s);

    gen2sb = g2s;
    mon2sb = m2s;

    foreach(model_mem[i])
      model_mem[i] = i;

  endfunction

  task run();

    packet p;
    transaction tr;

    forever begin

      gen2sb.get(p);

      pending_addr.push_back(p.in_addr_write);
      pending_data.push_back(p.in_data);

      mon2sb.get(tr);

      if(tr.read_data !== model_mem[tr.read_addr[7:0]]) begin
        $display("READ FAIL addr=%h expected=%h got=%h",
                  tr.read_addr,
                  model_mem[tr.read_addr[7:0]],
                  tr.read_data);
      end
      else begin
        $display("READ PASS addr=%h data=%h",
                  tr.read_addr,
                  tr.read_data);
      end

      if(pending_addr.size() > 0) begin
        bit [31:0] addr;
        bit [31:0] data;

        addr = pending_addr.pop_front();
        data = pending_data.pop_front();

        model_mem[addr[7:0]] = data;
      end

    end

  endtask

endclass



class environment;

  virtual axi_inf inf;

  mailbox gen2drv;
  mailbox gen2sb;
  mailbox mon2sb;

  generator g;
  driver d;
  monitor m;
  scoreboard s;

  function new(virtual axi_inf inf);
    this.inf = inf;
  endfunction

  function void build();

    gen2drv = new();
    gen2sb  = new();
    mon2sb  = new();

    g = new(gen2drv,gen2sb);
    d = new(inf,gen2drv);
    m = new(inf,mon2sb);
    s = new(gen2sb,mon2sb);

  endfunction

  task run();

    fork
      g.run();
      d.run();
      m.run();
      s.run();
    join_none

  endtask

endclass



module axi_protocol_checker(axi_inf inf);

  property awaddr_stable;
    @(posedge inf.aclk)
    disable iff(!inf.aresetn)
    inf.awvalid && !inf.awready |-> $stable(inf.awaddr);
  endproperty

assert property(awaddr_stable)
    $display("AXI check OK: AWADDR stable while waiting for handshake");
  else
    $error("AXI violation: AWADDR changed before handshake");

  property wdata_stable;
    @(posedge inf.aclk)
    disable iff(!inf.aresetn)
    inf.wvalid && !inf.wready |-> $stable(inf.wdata);
  endproperty

  assert property(wdata_stable)
    $display("AXI check OK: WDATA stable while waiting for handshake");
    else $error("AXI violation: WDATA changed before handshake");

  property araddr_stable;
    @(posedge inf.aclk)
    disable iff(!inf.aresetn)
    inf.arvalid && !inf.arready |-> $stable(inf.araddr);
  endproperty

  assert property(araddr_stable)
  $display("AXI check OK: ARADDR stable while waiting for handshake");
    else $error("AXI violation: ARADDR changed before handshake");

  property awvalid_hold;
    @(posedge inf.aclk)
    disable iff(!inf.aresetn)
    inf.awvalid && !inf.awready |=> inf.awvalid;
  endproperty

  assert property(awvalid_hold)
  $display("AXI check OK: AWVALID stable while waiting for handshake");
    else $error("AXI violation: AWVALID dropped early");

endmodule



module tb;

  axi_inf inf();

  AXI_TOP_MODULE DUT(
    .clk(inf.aclk),
    .resetn(inf.aresetn),

    .in_addr_write(inf.in_addr_write),
    .in_data(inf.in_data),
    .in_data_strb(inf.in_data_strb),

    .in_addr_read(inf.in_addr_read),
    .out_data_read(inf.out_data_read),
    .out_data_rresp(inf.out_data_rresp)
  );

  axi_protocol_checker Protocol_checker(inf);
  
  assign inf.awaddr  = DUT.awaddr;
  assign inf.awvalid = DUT.awvalid;
  assign inf.awready = DUT.awready;

  assign inf.wdata   = DUT.wdata;
  assign inf.wvalid  = DUT.wvalid;
  assign inf.wready  = DUT.wready;

  assign inf.araddr  = DUT.araddr;
  assign inf.arvalid = DUT.arvalid;
  assign inf.arready = DUT.arready;

  assign inf.rdata   = DUT.rdata;
  assign inf.rvalid  = DUT.rvalid;
  assign inf.rready  = DUT.rready;
  assign inf.rresp   = DUT.rresp;


  initial begin
    inf.aclk = 0;
    forever #5 inf.aclk = ~inf.aclk;
  end

  initial begin
    inf.aresetn = 0;
    repeat(5) @(posedge inf.aclk);
    inf.aresetn = 1;
  end

  initial begin

    environment e;

    e = new(inf);
    e.build();
    e.run();
    
    #4000;
    $finish;

  end

endmodule