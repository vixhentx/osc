`timescale 1ns / 1ps

module waveform_parameter_tb;

    // Testbench registers
    reg clk;
    reg reset;
    reg [11:0] adc_data;
    
    // Module outputs
    wire [11:0] amplitude;
    wire [31:0] frequency;
    wire [31:0] duty_cycle;

    // Instantiate the module under test (DUT)
    signal_analyzer dut (
        .clk(clk),
        .reset(reset),
        .adc_data(adc_data),
        .threshold(12'd2048), // Set a threshold at the midpoint (4096 / 2)
        .amplitude(amplitude),
        .frequency(frequency),
        .duty_cycle(duty_cycle)
    );

    // 1. Clock Generation (1MHz = 1000ns period)
    localparam CLK_PERIOD = 1000;
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2);
        clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // 2. Stimulus Generation (Main Test)
    integer i;
    initial begin
        // Initialize
        reset = 1'b1;
        adc_data = 12'd2048; // Start at DC offset
        
        // Setup waveform dumping
        $dumpfile("tb_signal_analyzer.vcd");
        $dumpvars(0, tb_signal_analyzer);

        // Apply reset
        #(CLK_PERIOD * 5);
        reset = 1'b0;
        #(CLK_PERIOD * 5);

        // Generate a 1kHz sine wave
        // ADC range is 0-4095. We'll make a sine wave:
        // Amplitude = 1500 (approx)
        // DC Offset = 2048
        // Frequency = 1kHz (f_signal)
        // Sample Freq = 1MHz (f_sample)
        //
        // Formula: 2048 + 1500 * sin(2 * PI * f_signal * t)
        // t = i * (1 / f_sample) = i * 1e-6
        //
        for (i = 0; i < 5000; i = i + 1) begin
            // $sin() takes radians. 2 * pi * 1000 * (i * 1e-6) = 0.006283 * i
            adc_data = 2048 + 1500 * $sin(0.00628318 * i);
            @(posedge clk);
        end

        // Run for a bit longer
        #(CLK_PERIOD * 10);
        
        // Display final results
        $display("Test Finished.");
        $display("Expected Frequency: ~1000 Hz, Calculated: %d Hz", frequency);
        $display("Expected Amplitude: ~1500, Calculated: %d", amplitude);
        $display("Expected Duty Cycle: ~5000 (50.00%%), Calculated: %d", duty_cycle);

        $finish;
    end

endmodule
