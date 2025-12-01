//==============================================================================
// I2C Slave Module
// Protocol: I2C
// Language: Verilog
// Author: Variant 8
//==============================================================================

module i2c_slave (
    input  wire        clk,          // System clock signal
    input  wire        rst_n,        // Asynchronous reset
    input  wire [6:0]  my_addr,      // This slave device address
    input  wire        scl,          // I2C Clock from Master
    inout  wire        sda,          // I2C Data Line
    output reg  [7:0]  data_received,// Received data
    output reg         data_valid    // Data validity flag
);

    // FSM State Parameters
    localparam IDLE           = 3'd0;
    localparam RCV_ADDRESS    = 3'd1;
    localparam SEND_ACK_ADDR  = 3'd2;
    localparam RCV_DATA       = 3'd3;
    localparam SEND_ACK_DATA  = 3'd4;
    localparam WAIT_STOP      = 3'd5;

    // Internal registers
    reg [2:0]  state;
    reg [3:0]  bit_counter;
    reg [7:0]  shift_reg;
    reg        sda_out;
    reg        sda_enable;
    reg        prev_scl;
    reg        prev_sda;
    
    // SDA control
    assign sda = sda_enable ? sda_out : 1'bz;

    // START and STOP condition detection
    wire start_detected = prev_sda & ~sda & scl;
    wire stop_detected  = ~prev_sda & sda & scl;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            sda_enable    <= 1'b0;
            sda_out       <= 1'b1;
            bit_counter   <= 0;
            shift_reg     <= 8'd0;
            data_received <= 8'd0;
            data_valid    <= 1'b0;
            prev_scl      <= 1'b1;
            prev_sda      <= 1'b1;
        end else begin
            prev_scl <= scl;
            prev_sda <= sda;
            
            case (state)
                IDLE: begin
                    sda_enable <= 1'b0;
                    data_valid <= 1'b0;
                    
                    if (start_detected) begin
                        state       <= RCV_ADDRESS;
                        bit_counter <= 7;
                        shift_reg   <= 8'd0;
                    end
                end

                RCV_ADDRESS: begin
                    if (prev_scl & ~scl) begin  // Falling edge of SCL
                        shift_reg   <= {shift_reg[6:0], sda};
                        
                        if (bit_counter == 0) begin
                            // Check address
                            if (shift_reg[7:1] == my_addr) begin
                                state <= SEND_ACK_ADDR;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                end

                SEND_ACK_ADDR: begin
                    sda_enable <= 1'b1;
                    sda_out    <= 1'b0;  // ACK
                    
                    if (~prev_scl & scl) begin  // Rising edge of SCL
                        state       <= RCV_DATA;
                        bit_counter <= 7;
                        shift_reg   <= 8'd0;
                        sda_enable  <= 1'b0;
                    end
                end

                RCV_DATA: begin
                    if (prev_scl & ~scl) begin
                        shift_reg <= {shift_reg[6:0], sda};
                        
                        if (bit_counter == 0) begin
                            state <= SEND_ACK_DATA;
                        end else begin
                            bit_counter <= bit_counter - 1;
                        end
                    end
                end

                SEND_ACK_DATA: begin
                    sda_enable    <= 1'b1;
                    sda_out       <= 1'b0;  // ACK
                    data_received <= shift_reg;
                    data_valid    <= 1'b1;
                    
                    if (~prev_scl & scl) begin
                        state      <= WAIT_STOP;
                        sda_enable <= 1'b0;
                    end
                end

                WAIT_STOP: begin
                    if (stop_detected) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule