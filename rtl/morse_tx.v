module morse_tx #(parameter PRESCALER = 100000) (
    input clk,
    input arst,

    input[7:0] ascii_in,
    output full,
    
    output reg morse_out
);
    wire clk_morse;
    clk_div clk_div_inst (
        .clk_in(clk),
        .arst_n(arst_n),
        .clk_out(clk_morse)
    );

    wire empty;
    wire[7:0] fifo_out;
    reg rEn;
    async_fifo #(8, 1024) fifo(
        .rst(arst),
        .rClk(clk_morse),
        .rEn(rEn),
        .rData(fifo_out),
        .empty(empty),
        .wClk(clk),
        .wEn(|ascii_in),
        .wData(ascii_in),
        .full(full)
    );

    wire[23:0] conv_out;
    ascii2morse ascii2morse_inst (
        .ascii(fifo_out),
        .morse(conv_out)
    );

    reg morse_out_nxt;
    reg state_d, state_q;
    reg[1:0] counter_d, counter_q;
    reg[23:0] morse_code_q, morse_code_d;
    always @(posedge clk_morse or posedge arst) begin
        morse_code_q <= morse_code_d;

        state_q <= state_d;
        counter_q <= counter_d;
        morse_out <= morse_out_nxt;
        if(arst) begin
            state_q <= 0;
            counter_q <= 0;
            morse_out <= 0;
        end
    end

    localparam STATE_IDLE = 1'b0, STATE_SEND = 1'b1;
    
    always @* begin
        rEn = 0;
        state_d = state_q;
        morse_out_nxt = morse_out;
        counter_d = counter_q;
        morse_code_d = morse_code_q;

        case(state_q)
            STATE_IDLE: begin
                morse_out_nxt = 0;
                morse_code_d = conv_out;
                if(!empty) begin
                    rEn = 1;
                    state_d = STATE_SEND;
                end
            end
            STATE_SEND: begin
                counter_d = 2;
                morse_out_nxt = morse_code_q[22];
                case(morse_code_q[23-:3])
                    3'b000: begin // space
                        morse_code_d = morse_code_q << 3;
                    end
                    3'b010: begin // dot
                        morse_code_d[23-:3] = 3'b000;
                    end
                    3'b011: begin // dash
                        counter_d = counter_q - 1;
                        if(counter_q == 0) begin
                            morse_code_d[23-:3] = 3'b000;
                        end
                    end
                    3'b100: begin
                        state_d = STATE_IDLE;
                    end
                    3'b110: begin
                        morse_code_d[23-:3] = 3'b100;
                    end
                    default: begin // 3'b111
                        counter_d = counter_q - 1;
                        if(counter_q == 0) begin
                            morse_code_d[23-:3] = 3'b100;
                        end
                    end
                endcase
            end
        endcase
    end
endmodule