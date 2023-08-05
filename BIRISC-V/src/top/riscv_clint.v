//-----------------------------------------------------------------
//                         AXI4_SLAVE_CLINT
//    
//      Description     :  Designed to handle software interrupts 
//                         while using AXI4                     
//      Last Modified On:  4th Aug 2023 
//-----------------------------------------------------------------

`define AXI_RESPONSE_OKAY     2'b00
`define AXI_RESPONSE_EXOKEY   2'b01
`define AXI_RESPONSE_SLVERR   2'b10
`define AXI_RESPONSE_DECERR   2'b11

module clint
//-----------------------------------------------------------------
//  Parameter
//-----------------------------------------------------------------
#(
    parameter MSIP0_ADDR = 32'h02000000,
    parameter MSIP1_ADDR = 32'h02000004,
    parameter SSIP0_ADDR = 32'h0200C000,
    parameter SSIP1_ADDR = 32'h0200C004
)
//-----------------------------------------------------------------
//  Ports
//-----------------------------------------------------------------
(

    input                        aclk,
    input                        areset,    // high level active

    output                       ipi0_m_o,
    output                       ipi1_m_o,
    output                       ipi0_s_o,
    output                       ipi1_s_o,

// axi write address channel
    input         [31:0]         awaddr,   //axi write address 
    input                        awvalid,  //axi write address valid
    output  reg                  awready,  //axi write address ready
// axi write data channel
    input         [31:0]         wdata,  //axi write data
    input                        wlast,  //axi write last data
    input                        wvalid,  //axi write data valid
    output  reg                  wready,  //axi write data ready
// axi write response channel
    input                        bready, // axi response ready
    output  reg    [1:0]         bresp,  // axi write response
    output  reg                  bvalid, // axi write response valid
// axi read address channel
    input          [31:0]        araddr, //axi read address
    input                        arvalid,  //axi read address valid
    output  reg                  arready,  //axi read address ready
// axi read data channel
    input                        rready, //axi read data ready
    output  reg    [31:0]        rdata, //axi read data
    output  reg                  rvalid, //axi read data valid
    output  reg    [1:0]         rresp,  //axi read data response 
    output  reg                  rlast  //axi read last data

);

//-----------------------------------------------------------------
//  Register /  Wires
//----------------------------------------------------------------- 

//msip 
    reg  [31:0]     msip0;
    reg  [31:0]     msip1;

//ssip
    reg  [31:0]     ssip0;
    reg  [31:0]     ssip1;

//read
    reg [31:0] read_address; 
    reg        arvalid_q;  
    reg        read_complete;

//write
    reg [31:0]      write_address;
    reg             awvalid_q; 
    reg [31:0]      write_data;
    reg             wvalid_q;
    reg             write_complete;

//IPI
    assign  ipi0_m_o = (msip0[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi1_m_o = (msip1[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi0_s_o = (ssip0[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi1_s_o = (ssip1[0] == 1'b1)? 1'b1:1'b0;

//-----------------------------------------------------------------
// read data
//----------------------------------------------------------------- 
    
//read address
    always @(posedge aclk)
        if (areset) begin       
            read_address <= 1'b0;  
            arvalid_q <= 1'b0; 
            end 
        else begin
            if (arvalid) begin
                read_address <= araddr;
                arvalid_q <= arvalid;           
                end     
            else begin
                read_address <= 1'b0;    
                arvalid_q   <= 1'b0;          
                end
        end 

    always @* 
        if (arvalid && arvalid_q)
            arready <= arvalid;
        else
            arready <= 1'b0;


// read data 
    always @(posedge aclk)
        if (areset) begin
            rdata <= 1'b0;
            rresp <= `AXI_RESPONSE_OKAY;   
            read_complete <= 1'b0       
            end 
        else begin
            if (rready) begin 
                case (read_address)
                    MSIP0_ADDR: rdata <= {31'b0, msip0[0]};
                    MSIP1_ADDR: ardata <= {31'b0, msip1[0]};
                    SSIP0_ADDR: rdata <= {31'b0, ssip0[0]};
                    SSIP1_ADDR: rdata <= {31'b0, ssip1[0]};
                    default: read_address <= 32'h00000000;
                endcase
                rresp  <= `AXI_RESPONSE_OKAY;
                read_complete <= 1'b1;           
                end 
            else begin
                rdata <= 1'b0;
                rresp  <= `AXI_RESPONSE_OKA;    
                read_complete <= 1'b0;                  
                end
        end
    
    always @* 
        if (areset) begin
            rvalid <= 1'b0;
            rlast  <= 1'b0;
            end 
        else begin 
            if(rready & read_complete) begin 
                rvalid <= 1'b1;
                rlast  <= 1'b1;
                end
            else begin 
                rvalid <= 1'b0;
                rlast  <= 1'b0;
                end
            end

//-----------------------------------------------------------------
// write data
//----------------------------------------------------------------- 

//write address
    always @(posedge aclk)begin 
        if(areset) 
            write_address <= 32'b0;
        else begin 
            if (awvalid)  
                write_address <= awaddr;
            else begin 
                if (write_complete) 
                    write_address <= 32'b0;
                else  
                    write_address <= write_address;
                end
            end
        end
            
    always @(posedge aclk)
        if (areset) 
            awvalid_q  <= 1'b0;
        else begin
            if (awvalid) 
                awvalid_q <= awvalid;
            else
                awvalid_q <= 32'b0;
            end 
            
    always @* begin
        if (awvalid && awvalid_q)
            awready <= awvalid;
        else
            awready <= 1'b0;
        end
            
// write data 
    always @(posedge aclk)
        if (areset) begin
            write_data <= 1'b0;
            wvalid_q   <= 1'b0;
            end 
        else begin
            if (wvalid) begin
                write_data <= wrdata;
                wvalid_q   <= wvalid;
                end 
            else begin
                write_data <= 32'b0; 
                wvalid_q   <= 1'b0;
                end
            end

    always @*
        if (wvalid && wvalid_q)
            wready = 1'b1;
        else
            wready=1'b0;

// write register 
    always @(posedge aclk)
        if (areset) begin 
            msip0         <= 32'b0;
            msip1         <= 32'b0;
            ssip0         <= 32'b0;
            ssip1         <= 32'b0;
            write_complete <= 1'b0;
            end
        else begin
            if (wready)begin
                case (write_address)
                    MSIP0_ADDR: msip_0 <= {31'b0, write_data[0]};
                    MSIP1_ADDR: msip_1 <= {31'b0, write_data[0]};
                    SSIP0_ADDR: ssip_0 <= {31'b0, write_data[0]};
                    SSIP1_ADDR: ssip_1 <= {31'b0, write_data[0]};
                    default: ;
                endcase
                    write_complete <= 1'b1;
                end
            else begin 
                write_complete <= 1'b0;
                end
            end        
    
// write response 
    always @(posedge aclk)
        if (areset) begin
            bvalid <= 1'b0; 
            bresp <= `AXI_RESPONSE_OKAY;        
            end 
        else begin
            if (bready && wready) begin
                bvalid <= 1'b1; 
                bresp <= `AXI_RESPONSE_OKAY;          
                end 
            else begin
                bvalid <= 1'b0;  
                bresp <= `AXI_RESPONSE_OKAY;       
                end
            end

endmodule

