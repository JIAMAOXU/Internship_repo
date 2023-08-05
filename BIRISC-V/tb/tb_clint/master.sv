`timescale 1ns / 1ps
package master_package;

//事务，addr表示awaddr/araddr的值，we表示此次事务是写寄存器还是读寄存器
class bus_trans#(
    parameter MSIP0_ADDR = 32'h02000000,
    parameter MSIP1_ADDR = 32'h02000004,
    parameter SSIP0_ADDR = 32'h0200C000,
    parameter SSIP1_ADDR = 32'h0200C004
);
    rand bit [31:0] addr;
    rand bit we;
    function new(bit[31:0] addr,bit we);
        this.addr = addr;
        this.we = we;
    endfunction
    constraint cstr{
        addr inside {MSIP0_ADDR,MSIP1_ADDR,SSIP0_ADDR,SSIP1_ADDR};
    };
endclass

// 产生事务
class axi_generator#(
    parameter MSIP0_ADDR = 32'h02000000,
    parameter MSIP1_ADDR = 32'h02000004,
    parameter SSIP0_ADDR = 32'h0200C000,
    parameter SSIP1_ADDR = 32'h0200C004
);
    local bus_trans trans;
    int a;
    mailbox #(bus_trans) trans_req;
    mailbox rsp;
    function new();
        trans_req = new();
    endfunction
    task send_trans();
        forever begin    
              create_trans(MSIP0_ADDR,1);
              create_trans(MSIP1_ADDR,1);
              create_trans(SSIP0_ADDR,1);
              create_trans(SSIP1_ADDR,1);
              create_trans(MSIP0_ADDR,0); 
              create_trans(MSIP1_ADDR,0); 
              create_trans(SSIP0_ADDR,0); 
              create_trans(SSIP1_ADDR,0);  
        end
    endtask
    task create_trans(input bit[31:0] addr,input bit we);
        trans = new(addr,we);
        trans_req.put(trans);
        rsp.get(a);       
    endtask
endclass

// 根据相应的事务产生激励发给slave
class axi_master;
    local virtual wb_bus intf;
    local bus_trans trans;
    local bit [31:0] addr;
    local bit we;
    int a;

    mailbox #(bus_trans) trans_req;
    mailbox rsp;
    
    function new();
        rsp = new();
    endfunction
    
    function void set_interface(virtual wb_bus intf);
        this.intf = intf;
    endfunction
    // 复位
    task do_reset();
        intf.awaddr <= 'b0;
        intf.awvalid <= 'b0;
        intf.wdata <= 'b0;
        intf.wlast <= 'b0;
        intf.wvalid <= 'b0;
        intf.bready <= 'b0;
        intf.araddr <= 'b0;
        intf.arvalid <= 'b0;
        intf.rready <= 'b0;     
    endtask
    
    //awaddr_channel,araddr_channel
    task drive_ch();
         wait(!intf.rst);
         forever begin
            $display("get the trans");
            trans_req.get(trans);
            $display("already get the trans");
            if(trans.we) begin
                intf.ck.awvalid <= 1'b1;
                intf.ck.awaddr <= trans.addr;
                @(posedge intf.clk);
            end
            else begin
                intf.ck.arvalid <= 1'b1;     
                intf.ck.araddr <= trans.addr;
                @(posedge intf.clk);
            end
            //@e;
         end
    endtask
    
    //wdata channel
    task wdata_ch;
        forever begin
            if(intf.awready) begin
                intf.ck.awvalid <=1'b0;
                intf.ck.wvalid <= 1'b1;
                intf.ck.wdata <= 32'b1;
                intf.ck.bready <=1'b1;
                intf.ck.wlast <= 1'b1;
            end
            if(intf.wready) begin
                intf.ck.wvalid <=1'b0;
                intf.ck.wlast <= 1'b0;
            end
            @(posedge intf.clk);
        end
    endtask
    
    //wresp_channel
    task wresp_ch;
        forever begin
            if(intf.bvalid==1) begin
                intf.ck.bready <=1'b0;
                rsp.put(1);
            end
            @(posedge intf.clk);
        end
    endtask
    
    //rdata_channel
    task rdata_ch();
        forever begin
            if(intf.arready) begin
                intf.ck.arvalid <=1'b0;
                intf.ck.rready <= 1'b1;
            end
            if(intf.rvalid&intf.rlast) begin
                intf.ck.rready <=1'b0;
                rsp.put(1);
            end
            @(posedge intf.clk);
        end        
    endtask
    
    //各个channel在这里并行执行
    task run();
        do_reset();
        forever begin
            fork 
                this.drive_ch();
                this.wdata_ch();
                this.wresp_ch();
                this.rdata_ch();
            join
        end
    endtask
endclass

//在这里将axi_master和axi_generator连接起来
class agent;
    axi_master master;
    axi_generator generator;
    function new();
        master = new();
        generator = new();
    endfunction
    
    
    task run();
        master.trans_req = generator.trans_req;
        generator.rsp = master.rsp;
        fork
            generator.send_trans();
            master.run();
        join
    endtask
endclass


endpackage