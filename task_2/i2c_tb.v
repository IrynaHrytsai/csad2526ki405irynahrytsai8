//==============================================================================
// I2C Testbench - ULTRA SIMPLE VERSION
//==============================================================================

`timescale 1ns / 1ps

module i2c_tb;

    parameter CLK_PERIOD = 20;          // 50 MHz
    parameter TEST_ADDR  = 7'b1010101;  // 0x55
    
    // Signals
    reg         clk;
    reg         rst_n;
    reg         start_cmd;
    reg  [6:0]  slave_addr;
    reg         rw_bit;
    reg  [7:0]  data_in;
    wire [7:0]  data_out_master;
    wire        busy;
    wire        scl;
    wire        sda;
    wire        done;
    wire [7:0]  data_received;
    wire        data_valid;

    pullup(sda);

    i2c_master master (
        .clk(clk),
        .rst_n(rst_n),
        .start_cmd(start_cmd),
        .slave_addr(slave_addr),
        .rw_bit(rw_bit),
        .data_in(data_in),
        .data_out(data_out_master),
        .busy(busy),
        .scl(scl),
        .sda(sda),
        .done(done)
    );

    i2c_slave slave (
        .clk(clk),
        .rst_n(rst_n),
        .my_addr(TEST_ADDR),
        .scl(scl),
        .sda(sda),
        .data_received(data_received),
        .data_valid(data_valid)
    );

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Main test
    initial begin
        $display("========================================");
        $display("  I2C Protocol Test");
        $display("========================================");

        // Init
        rst_n = 0;
        start_cmd = 0;
        slave_addr = 7'd0;
        rw_bit = 0;
        data_in = 8'd0;

        // Reset
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);
        
        $display("[%0t] Reset done", $time);

        // TEST 1
        repeat(20) @(posedge clk);
        $display("\n[%0t] TEST 1: Send 0xA5 to 0x55", $time);
        slave_addr = TEST_ADDR;
        rw_bit = 0;
        data_in = 8'hA5;
        
        @(posedge clk);
        start_cmd = 1;
        repeat(50) @(posedge clk);  // Hold start_cmd longer
        start_cmd = 0;
        
        $display("[%0t] Start command sent", $time);
        
        // Wait for done
        wait(done == 1);
        $display("[%0t] Transaction done", $time);
        
        // Wait a bit for slave to process
        repeat(10) @(posedge clk);
        
        // Check immediately while data_valid might still be high
        if (data_received == 8'hA5) begin
            $display("[%0t] PASS: Received 0x%h", $time, data_received);
        end else begin
            $display("[%0t] FAIL: Expected 0xA5, got 0x%h (valid=%b)", 
                     $time, data_received, data_valid);
        end

        // TEST 2
        repeat(50) @(posedge clk);
        $display("\n[%0t] TEST 2: Send 0x3C to 0x55", $time);
        data_in = 8'h3C;
        
        @(posedge clk);
        start_cmd = 1;
        repeat(50) @(posedge clk);
        start_cmd = 0;
        
        wait(done == 1);
        repeat(10) @(posedge clk);
        
        if (data_received == 8'h3C) begin
            $display("[%0t] PASS: Received 0x%h", $time, data_received);
        end else begin
            $display("[%0t] FAIL: Expected 0x3C, got 0x%h", $time, data_received);
        end

        // TEST 3 - Wrong address
        repeat(50) @(posedge clk);
        $display("\n[%0t] TEST 3: Send to wrong address 0x0F", $time);
        slave_addr = 7'b0001111;
        data_in = 8'hFF;
        
        @(posedge clk);
        start_cmd = 1;
        repeat(50) @(posedge clk);
        start_cmd = 0;
        
        wait(done == 1);
        repeat(10) @(posedge clk);
        
        if (data_received != 8'hFF) begin
            $display("[%0t] PASS: Slave ignored wrong address", $time);
        end else begin
            $display("[%0t] FAIL: Slave should not accept", $time);
        end

        repeat(100) @(posedge clk);
        $display("\n========================================");
        $display("  Tests Complete");
        $display("========================================");
        $finish;
    end

    // Debug monitor
    initial begin
        forever begin
            @(posedge clk);
            if (start_cmd && master.state == 0) begin
                $display("[%0t] DEBUG: start_cmd=1 state=IDLE busy=%b", $time, busy);
            end
        end
    end

    // State monitor
    always @(master.state) begin
        case (master.state)
            0: $display("[%0t] Master: IDLE", $time);
            1: $display("[%0t] Master: START", $time);
            2: $display("[%0t] Master: ADDRESS", $time);
            3: $display("[%0t] Master: ACK_ADDR", $time);
            4: $display("[%0t] Master: DATA", $time);
            5: $display("[%0t] Master: ACK_DATA", $time);
            6: $display("[%0t] Master: STOP", $time);
        endcase
    end

    always @(slave.state) begin
        case (slave.state)
            0: $display("[%0t] Slave: IDLE", $time);
            1: $display("[%0t] Slave: RCV_ADDRESS", $time);
            2: $display("[%0t] Slave: SEND_ACK_ADDR", $time);
            3: $display("[%0t] Slave: RCV_DATA", $time);
            4: $display("[%0t] Slave: SEND_ACK_DATA", $time);
            5: $display("[%0t] Slave: WAIT_STOP", $time);
        endcase
    end

    // Timeout
    initial begin
        #500000;
        $display("\nERROR: Timeout!");
        $finish;
    end

endmodule