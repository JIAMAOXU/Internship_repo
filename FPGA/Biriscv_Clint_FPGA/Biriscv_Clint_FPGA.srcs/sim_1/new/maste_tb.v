module clint_tb;
    reg             clk;
    reg [1:0]       wr_ctrl;
    reg [1:0]       state_ctrl;
    reg             rst;
    wire [3:0]      leds;
    wire            read_data;

    reg [3:0]       cntn;
    reg [3:0]       cnt;


    initial begin
        clk=1'b0;
        rst=1'b0;
        cntn=4'b0;
        cnt=4'b0;
    end

    always
    #10 clk=~clk;

    always @(posedge clk)begin
        if(cntn==10)begin
            cntn<=4'b0;
            cnt<=cnt+1'b1;
        end
        else begin
            cntn<=cntn+1'b1;
            cnt<=cnt;
        end
    end

    always @* begin
        state_ctrl<=cnt[1:0];
        wr_ctrl <=cnt[3:2];
    end


    axi_master axi_master(
    .clk(clk),
    .wr_ctrl(wr_ctrl),
    .state_ctrl(state_ctrl),
    .rst(rst),
    .leds(leds),
    .read_data(read_data)
    );
endmodule