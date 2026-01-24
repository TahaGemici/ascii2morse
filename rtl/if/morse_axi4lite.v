module morse_axi4lite (
    input aclk,
    input aresetn,

    input awvalid,
    output reg awready,
    input[31:0] awaddr,
    input[2:0] awprot,

    input wvalid,
    output reg wready,
    input[31:0] wdata,
    input[3:0] wstrb,

    output reg bvalid,
    input bready,
    output reg[1:0] bresp,

    input arvalid,
    output reg arready,
    input[31:0] araddr,
    input[2:0] arprot,

    output reg rvalid,
    input rready,
    output reg[31:0] rdata,
    output reg[1:0] rresp,

    output morse_out
);
    localparam OKAY = 2'b00, SLVERR = 2'b10;

    reg wait_bresp, wait_bresp_nxt;
    
    // memory-mapped registers
    reg[31:0] mem[0:2], mem_nxt[0:2]; // 0: prescaler, 1: status, 2: ascii_in
    reg write_en;
    wire full, empty;
    always @(posedge aclk or negedge aresetn) begin
        mem[0] <= mem_nxt[0];
        mem[1] <= {30'b0, full, empty};
        mem[2] <= mem_nxt[2];
        if(~aresetn) begin
            mem[0] <= 0;
            mem[2] <= 0;
        end
    end
    always @* begin
        mem_nxt[0] = mem[0];
        mem_nxt[2] = mem[2];
        write_en = 1'b0;
        if(wvalid & wready) begin
            case(awaddr[3:2])
                2'd0: begin
                    if(wstrb[0]) mem_nxt[0][7:0] = wdata[7:0];
                    if(wstrb[1]) mem_nxt[0][15:8] = wdata[15:8];
                    if(wstrb[2]) mem_nxt[0][23:16] = wdata[23:16];
                    if(wstrb[3]) mem_nxt[0][31:24] = wdata[31:24];
                end
                2'd2: begin
                    if(wstrb[0]) begin
                        mem_nxt[2][7:0] = wdata[7:0];
                        write_en = 1'b1;
                    end
                end
            endcase
        end
    end

    morse morse_inst (
        .clk(aclk),
        .arst_n(aresetn),

        .write_en(write_en),
        .ascii_in(mem[2][7:0]),
        .prescaler(mem[0]),
        .full(full),
        .empty(empty),

        .morse_out(morse_out)
    );

    // Write Address Channel
    reg awready_nxt;
    always @(posedge aclk or negedge aresetn) begin
        awready <= awready_nxt;
        if(~aresetn) begin
            awready <= 1'b0;
        end
    end
    always @* begin
        awready_nxt = awready;
        if(awvalid) begin
            awready_nxt = 1'b1;
            if(awaddr[3:2] == 2'd2) begin
                awready_nxt = ~full;
            end
        end
        if((~wvalid)|awready|wait_bresp) awready_nxt = 1'b0;
    end

    // Write Data Channel
    reg wready_nxt;
    always @(posedge aclk or negedge aresetn) begin
        wready <= wready_nxt;
        if(~aresetn) begin
            wready <= 1'b0;
        end
    end

    always @* begin
        wready_nxt = wready;
        if(wvalid) wready_nxt = 1'b1;
        if((~awvalid)|wready|wait_bresp) wready_nxt = 1'b0;
    end

    // Write Response Channel
    reg bvalid_nxt;
    reg[1:0] bresp_nxt;
    always @(posedge aclk or negedge aresetn) begin
        bvalid <= bvalid_nxt;
        bresp <= bresp_nxt;
        wait_bresp <= wait_bresp_nxt;
        if(~aresetn) begin
            bvalid <= 1'b0;
            bresp <= OKAY;
            wait_bresp <= 1'b0;
        end
    end

    always @* begin
        bvalid_nxt = bvalid;
        bresp_nxt = bresp;
        wait_bresp_nxt = wait_bresp;

        if(wready & wvalid) begin
            bvalid_nxt = 1'b1;
            bresp_nxt = awaddr[1:0] ? SLVERR : OKAY;
            wait_bresp_nxt = 1'b1;
        end
        if(bready & bvalid) begin
            bvalid_nxt = 1'b0;
            wait_bresp_nxt = 1'b0;
        end
    end

    // Read Address Channel
    always @(posedge aclk or negedge aresetn) begin
        arready <= 1'b1;
        if(~aresetn) begin
            arready <= 1'b0;
        end
    end

    // Read Data Channel
    reg rvalid_nxt;
    reg[31:0] rdata_nxt;
    reg[1:0] rresp_nxt;
    always @(posedge aclk or negedge aresetn) begin
        rvalid <= rvalid_nxt;
        rdata <= rdata_nxt;
        rresp <= rresp_nxt;
        if(~aresetn) begin
            rvalid <= 1'b0;
            rdata <= 32'b0;
            rresp <= OKAY;
        end
    end
    always @* begin
        rvalid_nxt = rvalid;
        rdata_nxt = rdata;
        rresp_nxt = rresp;

        if(rready & rvalid) rvalid_nxt = 1'b0;
        if(arready & arvalid) begin
            rvalid_nxt = 1'b1;
            rdata_nxt = mem[araddr[3:2]];
            rresp_nxt = araddr[1:0] ? SLVERR : OKAY;
        end
    end

endmodule