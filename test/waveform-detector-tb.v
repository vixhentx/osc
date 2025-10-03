`timescale 1ns / 1ps

module tb_waveform_detector;

    // -- Parameters matching the DUT --
    localparam DATA_WIDTH = 12;
    localparam BUFFER_ADDR_WIDTH = 10;
    localparam BUFFER_SIZE = 2**(BUFFER_ADDR_WIDTH);

    // -- Testbench signals to connect to the DUT --
    reg                      clk;
    reg                      reset;
    reg                      start_analysis;
    reg  [DATA_WIDTH-1:0]    bram_data_in;

    wire [BUFFER_ADDR_WIDTH-1:0] bram_read_address;
    wire [1:0]                   waveform_type;
    wire                         done;
    
    // -- Testbench internal memory to model the BRAM --
    reg [DATA_WIDTH-1:0] test_bram [BUFFER_SIZE-1:0];

    // Instantiate the Device Under Test (DUT)
    waveform_detector #(
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_ADDR_WIDTH(BUFFER_ADDR_WIDTH)
    ) u_waveform_detector (
        .clk(clk),
        .reset(reset),
        .start_analysis(start_analysis),
        .bram_data_in(bram_data_in),
        .bram_read_address(bram_read_address),
        .waveform_type(waveform_type),
        .done(done)
    );

    // 1. Clock Generator
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // 2. BRAM Model
    // This always block makes our test_bram behave like a real memory,
    // providing data whenever the DUT requests an address.
    always @(posedge clk) begin
        bram_data_in <= test_bram[bram_read_address];
    end

    // 3. Main Test Sequence
    initial begin
        $dumpfile("waveform.vcd"); // Name of the output waveform file
        $dumpvars(0, tb_waveform_detector); // Dump all variables

        // -- Test Case 1: Sine Wave --
        $display("TEST 1: Generating Sine Wave...");
        generate_sine_wave();
        run_test(2'b00); // Expected output for Sine is 00

        // -- Test Case 2: Square Wave --
        $display("TEST 2: Generating Square Wave...");
        generate_square_wave();
        run_test(2'b01); // Expected output for Square is 01

        // -- Test Case 3: Triangle Wave --
        $display("TEST 3: Generating Triangle Wave...");
        generate_triangle_wave();
        run_test(2'b10); // Expected output for Triangle is 10

        $display("All tests completed.");
        $finish;
    end

    // -- Task to run a single test --
    task run_test(input [1:0] expected_type);
        // Apply reset
        reset = 1;
        start_analysis = 0;
        repeat(2) @(posedge clk);
        reset = 0;
        @(posedge clk);

        // Start the analysis
        start_analysis = 1;
        @(posedge clk);
        start_analysis = 0;

        // Wait for the done signal
        wait(done);
        @(posedge clk);

        // Check the result
        if (waveform_type == expected_type) begin
            $display("----> PASS: Waveform type matched: %b", waveform_type);
        end else begin
            $display("----> FAIL: Expected %b, but got %b", expected_type, waveform_type);
        end
        
        #100; // Wait a bit before the next test
    endtask

    // -- Waveform Generation Tasks --
    task generate_sine_wave;
        integer i;
        real sin_val;
        for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
            // Generate one full cycle of a sine wave
            sin_val = $sin(i * 2 * 3.14159 / BUFFER_SIZE);
            // Scale and offset to fit in 12 bits (amplitude ~1800, offset 2048)
            test_bram[i] = 2048 + 1800 * sin_val;
        end
    endtask
    
    task generate_square_wave;
        integer i;
        for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
            // High for the first half, low for the second
            if (i < BUFFER_SIZE / 2) begin
                test_bram[i] = 4000; // High value
            end else begin
                test_bram[i] = 100;  // Low value
            end
        end
    endtask
    
    task generate_triangle_wave;
        integer i;
        integer val;
        for (i = 0; i < BUFFER_SIZE; i = i + 1) begin
            // Ramp up for the first half, ramp down for the second
            if (i < BUFFER_SIZE / 2) begin
                val = 100 + (3900 * i) / (BUFFER_SIZE / 2);
            end else begin
                val = 4000 - (3900 * (i - BUFFER_SIZE/2)) / (BUFFER_SIZE / 2);
            end
            test_bram[i] = val;
        end
    endtask

endmodule
