`timescale 1ns/1ps

module ascii2morse_tb;
    reg clk;
    reg arst_n;
    reg[7:0] ascii_in;
    reg write_en;
    wire full;
    wire morse_out;

    // Instantiate the morse_tx module with a smaller prescaler for faster simulation
    ascii2morse #(.PRESCALER(100)) dut (
        .clk(clk),
        .arst_n(arst_n),
        .write_en(write_en),
        .ascii_in(ascii_in),
        .full(full),
        .morse_out(morse_out)
    );

    // Clock generation - 100MHz (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    integer i;
    initial begin
        // Initialize signals
        arst_n = 0;
        ascii_in = 0;
        write_en = 0;

        // Release reset after some time
        #100;
        arst_n = 1;
        #50;

        // Send several words with spaces between them
        // Example pattern: zeros - word - zeros - word - zeros
        
        // Initial zeros
        for(i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            ascii_in = 0;
        end
        
        write_en = 1;

        // Word 1: "CARS"
        @(negedge clk); ascii_in = "C";
        @(negedge clk); ascii_in = "A";
        @(negedge clk); ascii_in = "R";
        @(negedge clk); ascii_in = "S";
        
        // Zeros between words
        for(i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            ascii_in = 0;
            write_en = 0;
        end
        
        write_en = 1;
        // Space
        @(negedge clk); ascii_in = " ";
        
        // Word 2: "ARE"
        @(negedge clk); ascii_in = "A";
        @(negedge clk); ascii_in = "R";
        @(negedge clk); ascii_in = "E";
        
        // Space
        @(negedge clk); ascii_in = " ";
        
        // Word 3: "RED"
        @(negedge clk); ascii_in = "R";
        @(negedge clk); ascii_in = "E";
        @(negedge clk); ascii_in = "D";
        
        // Final zeros
        for(i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            ascii_in = 0;
            write_en = 0;
        end

        // Let the transmission complete
        #1000000;
        
        $display("Simulation completed");
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t arst_n=%b write_en=%b ascii_in=%c(%h) full=%b morse_out=%b", 
                 $time, arst_n, write_en, ascii_in, full, morse_out);
    end

endmodule