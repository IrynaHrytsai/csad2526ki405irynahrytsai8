//==============================================================================
// I2C Master Module
// Protocol: I2C
// Language: Verilog
// Speed: 100 kHz (Standard Mode)
// Author: Variant 8
//==============================================================================

module i2c_master (
    input  wire        clk,          // System clock signal (e.g., 50 MHz)
    input  wire        rst_n,        // Asynchronous reset (active low)
    input  wire        start_cmd,    // Command to start transmission
    input  wire [6:0]  slave_addr,   // 7-bit slave device address
    input  wire        rw_bit,       // 0 = Write, 1 = Read
    input  wire [7:0]  data_in,      // Data to transmit
    output reg  [7:0]  data_out,     // Received data (for read mode)
    output reg         busy,         // Busy flag
    output reg         scl,          // I2C Clock Line
    inout  wire        sda,          // I2C Data Line (bidirectional)
    output reg         done          // Transaction complete flag
);

    // FSM State Parameters
    localparam IDLE        = 4'd0;
    localparam START       = 4'd1;
    localparam ADDRESS     = 4'd2;
    localparam RW_BIT      = 4'd3;
    localparam ACK_ADDR    = 4'd4;
    localparam DATA        = 4'd5;
    localparam ACK_DATA    = 4'd6;
    localparam STOP        = 4'd7;

    // I2C clock generation (100 kHz from 50 MHz system clock)
    localparam DIVIDER = 250;  // 50 MHz / (2 * 100 kHz) = 250
    
    reg [8:0] clk_divider;
    reg       i2c_clk;
    
    // I2C clock generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_divider <= 0;
            i2c_clk <= 1'b1;
        end else begin
            if (clk_divider == DIVIDER - 1) begin
                clk_divider <= 0;
                i2c_clk <= ~i2c_clk;
            end else begin
                clk_divider <= clk_divider + 1;
            end
        end
    end

    // Internal registers
    reg [3:0]  state;
    reg [3:0]  bit_counter;
    reg [7:0]  shift_reg;
    reg        sda_out;
    reg        sda_enable;  // SDA direction control (0 = input, 1 = output)
    
    // Bidirectional SDA line control
    assign sda = sda_enable ? sda_out : 1'bz;

    // Main FSM
    always @(posedge i2c_clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            scl         <= 1'b1;
            sda_out     <= 1'b1;
            sda_enable  <= 1'b0;
            busy        <= 1'b0;
            done        <= 1'b0;
            bit_counter <= 0;
            shift_reg   <= 8'd0;
            data_out    <= 8'd0;
        end else begin
            case (state)
                // Idle state - waiting for command
                IDLE: begin
                    scl        <= 1'b1;
                    sda_out    <= 1'b1;
                    sda_enable <= 1'b0;
                    done       <= 1'b0;
                    
                    if (start_cmd) begin
                        busy       <= 1'b1;
                        state      <= START;
                        shift_reg  <= {slave_addr, rw_bit};
                    end else begin
                        busy <= 1'b0;
                    end
                end

                // Generate START condition
                START: begin
                    sda_enable <= 1'b1;
                    sda_out    <= 1'b0;  // SDA: 1→0 while SCL=1
                    scl        <= 1'b1;
                    bit_counter <= 7;
                    state      <= ADDRESS;
                end

                // Transmit 7-bit address + 1-bit R/W
                ADDRESS: begin
                    scl        <= 1'b0;
                    sda_out    <= shift_reg[7];
                    shift_reg  <= shift_reg << 1;
                    
                    if (bit_counter == 0) begin
                        state <= ACK_ADDR;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                end

                // Wait for ACK from slave
                ACK_ADDR: begin
                    scl        <= 1'b1;
                    sda_enable <= 1'b0;  // Slave controls SDA
                    
                    // Check ACK (SDA should be 0)
                    if (sda == 1'b0) begin
                        shift_reg   <= data_in;
                        bit_counter <= 7;
                        state       <= DATA;
                    end else begin
                        // NACK - return to IDLE
                        state <= STOP;
                    end
                end

                // Transmit 8 data bits
                DATA: begin
                    scl        <= 1'b0;
                    sda_enable <= 1'b1;
                    sda_out    <= shift_reg[7];
                    shift_reg  <= shift_reg << 1;
                    
                    if (bit_counter == 0) begin
                        state <= ACK_DATA;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                end

                // Wait for ACK after data
                ACK_DATA: begin
                    scl        <= 1'b1;
                    sda_enable <= 1'b0;  // Slave controls SDA
                    
                    if (sda == 1'b0) begin
                        state <= STOP;
                    end else begin
                        // NACK
                        state <= STOP;
                    end
                end

                // Generate STOP condition
                STOP: begin
                    scl        <= 1'b1;
                    sda_enable <= 1'b1;
                    sda_out    <= 1'b0;
                    
                    // Next cycle: SDA: 0→1 while SCL=1
                    done  <= 1'b1;
                    busy  <= 1'b0;
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule