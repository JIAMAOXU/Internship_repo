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

    // AXI write address channel
    input         [31:0]         awaddr,   //AXI write address 
    input                        awvalid,  //AXI write address valid
    output  reg                  awready,  //AXI write address ready

    // AXI write data channel
    input         [31:0]         wdata,    //AXI write data
    input                        wlast,    //AXI write last data
    input                        wvalid,   //AXI write data valid
    output  reg                  wready,   //AXI write data ready

    // AXI write response channel
    input                        bready,   //AXI response ready
    output  reg    [1:0]         bresp,    //AXI write response
    output  reg                  bvalid,   //AXI write response valid

    // AXI read address channel
    input          [31:0]        araddr,   //AXI read address
    input                        arvalid,  //AXI read address valid
    output  reg                  arready,  //AXI read address ready

    // AXI read data channel
    input                        rready,   //AXI read data ready
    output  reg    [31:0]        rdata,    //AXI read data
    output  reg                  rvalid,   //AXI read data valid
    output  reg    [1:0]         rresp,    //AXI read data response 
    output  reg                  rlast,     //AXI read last data
    output  reg                  write_complete
);

//-----------------------------------------------------------------
//  Register /  Wires
//----------------------------------------------------------------- 

    //msip 
    reg  [31:0]     msip_0;
    reg  [31:0]     msip_1;

    //ssip
    reg  [31:0]     ssip_0;
    reg  [31:0]     ssip_1;

    //read
    reg [31:0] read_address; 
    reg        arvalid_q;  
    reg        read_complete;

    //write
    reg [31:0]      write_address;
    reg             awvalid_q; 
    reg [31:0]      write_data;
    reg             wvalid_q;
    //reg             write_complete;

    //IPI
    assign  ipi0_m_o = (msip_0[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi1_m_o = (msip_1[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi0_s_o = (ssip_0[0] == 1'b1)? 1'b1:1'b0;
    assign  ipi1_s_o = (ssip_1[0] == 1'b1)? 1'b1:1'b0;

//-----------------------------------------------------------------
// Read Address Channel
//----------------------------------------------------------------- 
always @(posedge aclk) begin
    if (areset) begin       
        read_address <= 32'b0;  
        arvalid_q    <= 1'b0; 
    end 
    else begin
        if (arvalid)begin
            read_address <= araddr;
            arvalid_q    <= arvalid;  
        end          
        else begin
            read_address <= 32'b0;    
            arvalid_q    <= 1'b0;
        end       
    end 
end

always @* begin
    if (arvalid && arvalid_q)begin
        arready <= arvalid;
    end
    else begin
        arready <= 1'b0;
    end
end

//-----------------------------------------------------------------
// Read Data Channel
//----------------------------------------------------------------- 
always @(posedge aclk)begin
    if (areset) begin
        rdata <= 1'b0;
        rresp <= `AXI_RESPONSE_OKAY;   
        read_complete <= 1'b0;       
    end 
    
    else begin
        if (rready) begin 
            case (read_address)
                MSIP0_ADDR: rdata  <= {31'b0, msip_0[0]};
                MSIP1_ADDR: rdata  <= {31'b0, msip_1[0]};
                SSIP0_ADDR: rdata  <= {31'b0, ssip_0[0]};
                SSIP1_ADDR: rdata  <= {31'b0, ssip_1[0]};
                default: read_address <= 32'h00000000;
            endcase
            rresp         <= `AXI_RESPONSE_OKAY;
            read_complete <= 1'b1;           
        end 
        else begin
            rdata         <= 1'b0;
            rresp         <= `AXI_RESPONSE_OKAY;    
            read_complete <= 1'b0;                  
        end
    end
 end   
always @* begin
    if (areset) begin
        rvalid <= 1'b0;
        rlast  <= 1'b0;
    end 
    else begin 
        if(rready & read_complete)begin 
            rvalid <= 1'b1;
            rlast  <= 1'b1;
        end
        else begin
            rvalid <= 1'b0;
            rlast  <= 1'b0;
        end
    end
end
//-----------------------------------------------------------------
// Write Address Channel
//----------------------------------------------------------------- 
always @(posedge aclk) begin 
    if(areset) begin
        write_address <= 32'b0;
    end
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
            
always @(posedge aclk) begin
    if (areset)begin 
        awvalid_q     <= 1'b0;
    end
    else begin
        if (awvalid) 
            awvalid_q <= awvalid;
        else
            awvalid_q <= 32'b0;
    end 
end

always @* begin
    if (awvalid && awvalid_q)
        awready <= awvalid;
    else
        awready <= 1'b0;
end
            
//-----------------------------------------------------------------
// Write Data Channel
//----------------------------------------------------------------- 
always @(posedge aclk) begin
    if (areset) begin
        write_data <= 1'b0;
        wvalid_q   <= 1'b0;
        end 
    else begin
        if (wvalid) begin
            write_data <= wdata;
            wvalid_q   <= wvalid;
        end 
        else begin
            write_data <= 32'b0; 
            wvalid_q   <= 1'b0;
        end
    end
end

always @* begin
    if (wvalid && wvalid_q)
        wready = 1'b1;
    else
        wready=1'b0;
end

//-----------------------------------------------------------------
// Update Register
//-----------------------------------------------------------------
always @(posedge aclk) begin
    if (areset) begin 
        msip_0         <= 32'b0;
        msip_1         <= 32'b0;
        ssip_0         <= 32'b0;
        ssip_1         <= 32'b0;
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
end   

// write response 
always @(posedge aclk) begin
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
end

endmodule


