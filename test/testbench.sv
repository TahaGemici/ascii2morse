`timescale 1ns / 1ps

module testbench();
    import axi_vip_pkg::*;
    import vip_test_system_axi_vip_0_0_pkg::*; 

    // -----------------------------------------------------------------------
    // Signal Declarations
    // -----------------------------------------------------------------------
    bit aclk = 0;
    bit aresetn = 0;
    
    // Response containers for the VIP
    xil_axi_resp_t resp;
    bit [31:0]     read_data;
    bit [31:0]     addr_base;
    
    // Test Data
    string message = "hello world :)"; // The "sentence" to transmit
    
    // -----------------------------------------------------------------------
    // Clock Generation (100 MHz)
    // -----------------------------------------------------------------------
    always #5 aclk = ~aclk;

    // -----------------------------------------------------------------------
    // DUT Instantiation
    // -----------------------------------------------------------------------
    vip_test_system_wrapper dut (
        .aclk_0(aclk),
        .aresetn_0(aresetn)
    );

    // -----------------------------------------------------------------------
    // VIP Agent Declaration
    // -----------------------------------------------------------------------
    vip_test_system_axi_vip_0_0_mst_t master_agent;

    // -----------------------------------------------------------------------
    // Helper Tasks to increase modularity
    // -----------------------------------------------------------------------
    
    // Task to write a character to the FIFO (Offset 0x08)
    task write_fifo(input byte char_to_send);
        begin
            $display("    -> Transmitting ASCII: '%s' (0x%h)", char_to_send, char_to_send);
            master_agent.AXI4LITE_WRITE_BURST(addr_base + 32'h08, 0, {24'h0, char_to_send}, resp);
            if (resp !== 0) $error("AXI Write Error response during FIFO write: %h", resp);
        end
    endtask

    // Task to check Status Register (Offset 0x04)
    // Bit 0 = Empty, Bit 1 = Full
    task check_status(output bit is_full, output bit is_empty);
        begin
            master_agent.AXI4LITE_READ_BURST(addr_base + 32'h04, 0, read_data, resp);
            is_empty = read_data[0];
            is_full  = read_data[1];
        end
    endtask

    // -----------------------------------------------------------------------
    // Main Test Sequence
    // -----------------------------------------------------------------------
    initial begin
        // 1. Initialize the Agent
        master_agent = new("master_vip_agent", dut.vip_test_system_i.axi_vip_0.inst.IF);
        
        // 2. Start the Driver
        master_agent.start_master();
        $display("--- AXI VIP Master Started ---");

        // 3. System Reset
        #2000 aresetn = 1;
        #50;

        // Base Address (Assumed 0x44A0_0000 based on previous context)
        addr_base = 32'h44A0_0000; 

        // -------------------------------------------------------------------
        // Test Case A: Configure Prescaler (Offset 0x00)
        // -------------------------------------------------------------------
        $display("--- [Step 1] Configuring Prescaler ---");
        master_agent.AXI4LITE_WRITE_BURST(addr_base + 32'h00, 0, 32'h0000BEEF, resp);
        
        // Verify Write
        master_agent.AXI4LITE_READ_BURST(addr_base + 32'h00, 0, read_data, resp);
        if (read_data == 32'h0000BEEF) 
            $display("PASS: Prescaler verified.");
        else 
            $error("FAIL: Prescaler mismatch! Got: %h", read_data);

        // -------------------------------------------------------------------
        // Test Case B: Write Sentence to FIFO (Offset 0x08) with Flow Control
        // -------------------------------------------------------------------
        $display("--- [Step 2] Sending Message: \"%s\" ---", message);
        
        foreach(message[i]) begin
            bit full, empty;
            
            // Polling: Check status register (Offset 0x04) before writing
            check_status(full, empty);
            
            // If full, wait (Simulation of blocking write)
            while(full) begin
                $display("WARNING: FIFO Full! Waiting...");
                #1000; 
                check_status(full, empty);
            end

            // Write the character using our task
            write_fifo(message[i]);
            
            // Small delay between keystrokes to simulate human typing speed relative to clock
            #200; 
        end
        
        $display("--- Transmission Complete ---");

        // -------------------------------------------------------------------
        // Test Case C: Post-Transmission Status Check
        // -------------------------------------------------------------------
        $display("--- [Step 3] Checking Final Status ---");
        // Check if FIFO is empty or processing
        master_agent.AXI4LITE_READ_BURST(addr_base + 32'h04, 0, read_data, resp);
        $display("Status Register: %b (Full: %b, Empty: %b)", read_data[1:0], read_data[1], read_data[0]);

        #100000000;
        $finish;
    end

endmodule