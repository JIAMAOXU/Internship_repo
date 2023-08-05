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
        . clk_i(clk),      
        . rst_i(rst),          
        
        . mipi0_o(mip0),        
        . mipi1_o(mip1),  
        . sipi0_o(sip0),        
        . sipi1_o(sip1),     
    
        . awid(awid),    // Address Write ID (optional)
        . awaddr(awaddr),   // Write Address
        . awlen(awlen),   // Burst Length
        . awsize(awsize),  // Burst Size
        . awburst(awburst), // Burst Type
        . awlock(awlock),  // Lock Type
        . awcache(awcache), // Cache Type
        . awprot(awprot),  // Protection Type
        . awvalid(awvalid), // Write Address Valid
        . awready(awready), // Write Address Ready
     
        .wid(wid),     // Write ID
        .wrdata(wdata),  // Write Data
        .wstrb(wstrb),   // Write Strobes
        .wlast(wlast),   // Write Last
        .wvalid(wvalid),  // Write Valid
        .wready(wready),  // Write Ready
        
        
        .bid(bid),    // Response ID
        .bresp(bresp),  // Write Response
        .bvalid(bvalid), // Write Response Valid
        .bready(bready), // Response Ready
        
        
        .arid(arid),    // Read Address ID
        .araddr(araddr),  // Read Address
        .arlen(arlen),   // Burst Length  
        .arsize(arsize),  // Burst Size
        .arlock(arlock),  // Lock Type
        .arcache(arcache), // Cache Type
        .arprot(arprot),  // Protection Type
        .arvalid(arvalid), // Read Address Valid
        .arready(arready), // Read Address Ready
        
        
        .rid(rid),     // Read ID
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
