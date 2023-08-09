module axi_master(
    input                   clk,
    //input [1:0]             wr_ctrl,
    //input [1:0]             state_ctrl,
    input                   rstn,
    output wire [3:0]        leds
  //  output reg              read_data
    );

    reg [31:0]              awaddr;
    reg                     awvalid;
    wire                    awready;

    reg [31:0]              wdata;
    reg                     wlast;
    reg                     wvalid;
    wire                    wready;

    reg                     bready;
    wire [1:0]              bresp;
    wire                    bvalid;

    reg [31:0]              araddr;
    reg                     arvalid;
    wire                    arready;

    reg                     rready;
    wire [31:0]             rdata;
    wire                    rvalid;
    wire [1:0]              rresp;
    wire                    rlast;

    reg                     write_q;
    reg                     read_q;
    reg                     clear_q;
    reg [31:0]              write_address;
    reg [31:0]              write_data;
    reg [31:0]              read_address;
    reg                     read_data;
    
        wire [1:0]             wr_ctrl;
    wire [1:0]             state_ctrl;
vio_1 u_vio_1 (
  .clk(clk),                // input wire clk
  .probe_in0(read_data),    // input wire [0 : 0] probe_in0
  .probe_out0(wr_ctrl),  // output wire [1 : 0] probe_out0
  .probe_out1(state_ctrl)  // output wire [1 : 0] probe_out1
);
wire rst;
assign rst = ~rstn;
    //state
    always @(posedge clk)begin
        if (rst)begin
            write_q<=1'b0;
            read_q<=1'b0;
            clear_q<=1'b0;   
        end     
        else if(state_ctrl[1])begin
            write_q<=1'b0;
            read_q<=1'b0;
            clear_q<=1'b1;
        end
        else if(state_ctrl==2'b00)begin
            write_q<=1'b1;
            read_q<=1'b0;
            clear_q<=1'b0;
        end
        else if(state_ctrl==2'b01)begin
            write_q<=1'b0;
            read_q<=1'b1;
            clear_q<=1'b0;
        end
        else begin
            write_q<=1'b0;
            read_q<=1'b0;
            clear_q<=1'b0; 
        end
    end

    //read or write address/data
    always @(posedge clk)begin
        if(rst)begin
            write_address<=32'b0;
            write_data<=32'b0;
            read_address<=32'b0;
        end
        else if(write_q)begin
            if(wr_ctrl==2'b00)begin
                write_address<=32'h02000000;
                write_data<=32'b1;
            end
            else if(wr_ctrl==2'b01)begin
                write_address<=32'h02000004;
                write_data<=32'b1;
            end
            else if(wr_ctrl==2'b10)begin
                write_address<=32'h0200C000;
                write_data<=32'b1;
            end
            else if(wr_ctrl==2'b11)begin
                write_address<=32'h0200C004;
                write_data<=32'b1;
            end
        end
        else if (clear_q)begin
            if(wr_ctrl==2'b00)begin
                write_address<=32'h02000000;
                write_data<=32'b0;
            end
            else if(wr_ctrl==2'b01)begin
                write_address<=32'h02000004;
                write_data<=32'b0;
            end
            else if(wr_ctrl==2'b10)begin
                write_address<=32'h0200C000;
                write_data<=32'b0;
            end
            else if(wr_ctrl==2'b11)begin
                write_address<=32'h0200C004;
                write_data<=32'b0;
            end

        end
        else if(read_q)begin
            if(wr_ctrl==2'b00)
                read_address<=32'h02000000;
            else if(wr_ctrl==2'b01)
                read_address<=32'h02000004;
            else if(wr_ctrl==2'b10)
                read_address<=32'h0200C000;
            else if(wr_ctrl==2'b11)
                read_address<=32'h0200C004;
        end
        else begin
            write_address<=32'b0;
            write_data<=32'b0;
            read_address<=32'b0;
        end
    end

///------------------------------------------------
///write data
///------------------------------------------------
    //load write address to clint
    always @(posedge clk)begin
        if(rst)begin
            awaddr<=32'b0;
            awvalid<=1'b0;
        end
        else if (write_q |clear_q)begin
            awaddr<=write_address;
            awvalid<=1'b1;
        end
        else begin
            awaddr<=32'b0;
            awvalid<=1'b0;
        end
    end

    //load write data to clint
    always @(posedge clk)begin
        if(rst)begin
            wdata<=32'b0;
            wvalid<=1'b0;
        end
        else if (write_q |clear_q)begin
            wdata<=write_data;
            wvalid<=1'b1;
        end
        else begin
            wdata<=32'b0;
            wvalid<=1'b0;
        end
    end

    //write response
    always @(posedge clk)begin
        if(rst)
            bready<=1'b0;
        else if(wvalid)
            bready<=1'b1;
        else
            bready<=1'b0;
    end

///------------------------------------------------
///read data
///------------------------------------------------
    //load read address to clint
    always @(posedge clk)begin
        if(rst)begin
            araddr<=32'b0;
            arvalid<=1'b0;
        end
        else if(read_q)begin
            araddr<=read_address;
            arvalid<=1'b1;
        end
        else begin
            araddr<=32'b0;
            arvalid<=1'b0;
        end
    end
    //read ready
    always @(posedge clk)begin
        if(rst)begin
            rready<=1'b0;
        end
        else if(read_q)begin
            rready<=1'b1;
        end
    end
    //read data from module
    always @*
        if(rst)
            read_data<=1'b0;
        else if(rready&&rvalid)
            read_data<=|rdata;
        else
            read_data<=1'b0;

    clint clint (
        .aclk(clk),
        .areset(rst),    // high level active
        .ipi0_m_o(leds[0]),
        .ipi1_m_o(leds[1]),
        .ipi0_s_o(leds[2]),
        .ipi1_s_o(leds[3]),
        // axi write address channel
        .awaddr(awaddr),   //axi write address 
        .awvalid(awvalid),  //axi write address valid
        .awready(awready),  //axi write address ready
        // axi write data channel
        .wdata(wdata),  //axi write data
        .wlast(wlast),  //axi write last data
        .wvalid(wvalid),  //axi write data valid
        .wready(wready),  //axi write data ready
        // axi write response channel
        .bready(bready), // axi response ready
        .bresp(bresp),  // axi write response
        .bvalid(bvalid), // axi write response valid
        // axi read address channel
        .araddr(araddr), //axi read address
        .arvalid(arvalid),  //axi read address valid
        .arready(arready),  //axi read address ready
        // axi read data channel
        .rready(rready), //axi read data ready
        .rdata(rdata), //axi read data
        .rvalid(rvalid), //axi read data valid
        .rresp(rresp),  //axi read data response 
        .rlast(rlast)  //axi read last data
    );
endmodule
