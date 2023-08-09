`timescale 1ns / 1ps
import master_package::*;
interface wb_bus(input clk,input rst);
        logic [31:0] data;
        logic [31:0] addr;

        //write address channel
        logic [31:0] awaddr;
        logic [3:0] awlen;
        logic [2:0] awsize;
        logic awvalid;
        logic awready;

        //write data channel
        logic [31:0] wdata;
        logic [3:0] wstrb;
        logic wlast;
        logic wvalid;
        logic wready;

        //write response channel
        logic bvalid;
        logic bready;
        logic [1:0] bresp;

        //read address channel
        logic [31:0] araddr;
        logic [3:0] arlen;
        logic [2:0] arsize;
        logic arvalid;
        logic arready;

        //read data channel
        logic [31:0] rdata;
        logic [1:0] rresp;
        logic rlast;
        logic rvalid;
        logic rready;

   clocking ck @(posedge clk);
        default input #1ns output #1ns;
        output awaddr,awlen,awsize,awvalid,
                wdata,wstrb,wlast,wvalid,
                bready,
                araddr,arlen,arsize,arvalid,
                rready;
        input awready,wready,bvalid,bresp,arready,rdata,rresp,rlast,rvalid;
   endclocking
endinterface


module tb
#(
    parameter MSIP0_ADDR = 32'h02000000,
    parameter MSIP1_ADDR = 32'h02000004,
    parameter SSIP0_ADDR = 32'h0200C000,
    parameter SSIP1_ADDR = 32'h0200C004
);
    logic clk;
    logic rst;
    //write address channel
    logic [3:0] awid;
    logic [31:0] awaddr;
    logic [3:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic [1:0] awlock;
    logic [3:0] awcache;
    logic [2:0] awprot;
    logic awvalid;
    logic awready;
    
    //write data channel
    logic [3:0] wid;
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wlast;
    logic wvalid;
    logic wready;
    
    //write response channel
    logic [3:0] bid;
    logic bvalid;
    logic bready;
    logic [1:0] bresp;
    
    //read address channel
    logic [3:0] arid;
    logic [31:0] araddr;
    logic [3:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arlock;
    logic [3:0] arcache;
    logic [2:0] arprot;
    logic arvalid;
    logic arready;
    
    //read data channel
    logic [3:0] rid;
    logic [31:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic rvalid;
    logic rready;
    
    logic mip0,mip1,sip0,sip1;
    
    //Debug
    logic write_complete;
    
    initial begin
        clk <= 1;
        forever begin
            #5 clk <= !clk;
        end
    end
    
    
    initial begin  
        rst = 1'b1;   
        #21
        rst = 1'b0;    
    end
    
    clint  clint

(
        .aclk(clk),      
        .areset(rst),          
        
        .ipi0_m_o(mip0),        
        .ipi1_m_o(mip1),  
        .ipi0_s_o(sip0),        
        .ipi1_s_o(sip1),     
    
        .awaddr(awaddr),   // Write Address
        .awvalid(awvalid), // Write Address Valid
        .awready(awready), // Write Address Ready
     
        .wdata(wdata),  // Write Data
        .wlast(wlast),   // Write Last
        .wvalid(wvalid),  // Write Valid
        .wready(wready),  // Write Ready
        
        .bresp(bresp),  // Write Response
        .bvalid(bvalid), // Write Response Valid
        .bready(bready), // Response Ready
        
        
        .araddr(araddr),  // Read Address
        .arvalid(arvalid), // Read Address Valid
        .arready(arready), // Read Address Ready
        
        
        .rdata(rdata),   // Read Data
        .rresp(rresp),   // Read Response
        .rlast(rlast),   // Read Last
        .rvalid(rvalid),  // Read Valid
        .rready(rready), // Read Ready
        .write_complete(write_complete)
    ); 
    
     wb_bus intf(clk,rst);
     agent agent;
    
     //intf2slave
     assign awaddr = intf.awaddr;
     assign awvalid = intf.awvalid;
     assign wdata = intf.wdata;
     assign wlast = intf.wlast;
     assign wvalid = intf.wvalid;
     assign bready = intf.bready;
     assign araddr = intf.araddr;
     assign arvalid = intf.arvalid;
     assign rready = intf.rready;
     
     //slave2intf
     assign intf.awready = awready;
     assign intf.wready = wready;
     assign intf.bvalid = bvalid;
     assign intf.arready = arready;
     assign intf.rvalid = rvalid;
     assign intf.rlast = rlast;
              
    initial begin
        agent=new();
        agent.master.set_interface(intf);
        agent.run();
    end
       
endmodule

