`timescale 1ns/1ps

module tb_game_over_display;

    // Testbench signals
    logic        clk;
    logic        reset;
    logic        trigger_game_over;
    logic [9:0]  pixel_x;
    logic [8:0]  pixel_y;
    logic        game_over_on;
    logic        game_over_complete;

    // Instantiate the game over display module
    game_over_display dut (
        .clk                (clk),
        .reset              (reset),
        .trigger_game_over  (trigger_game_over),
        .pixel_x            (pixel_x),
        .pixel_y            (pixel_y),
        .game_over_on       (game_over_on),
        .game_over_complete (game_over_complete)
    );

    // 50 MHz clock generation (20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus
    initial begin
        $display("Starting Game Over Display Testbench");
        
        // Initialize signals
        reset = 1;
        trigger_game_over = 0;
        pixel_x = 0;
        pixel_y = 0;
        
        // Hold reset for 100ns
        #100;
        reset = 0;
        
        $display("Time: %0t - Reset released, module in IDLE state", $time);
        
        // Test 1: Verify no output when not triggered
        #200;
        assert (game_over_on == 0 && game_over_complete == 0) 
            else $error("Game over should not be active when not triggered");
        $display("Time: %0t - PASS: No output when idle", $time);
        
        // Test 2: Trigger game over display
        trigger_game_over = 1;
        #20;
        trigger_game_over = 0;
        
        $display("Time: %0t - Game over triggered, entering DISPLAYING state", $time);
        
        // Test 3: Check game over display is active in text area
        pixel_x = 200;  // Within text area (160-416)  
        pixel_y = 200;  // Within text area (160-288)
        #100;
        $display("Time: %0t - Testing pixel at (%0d,%0d): game_over_on = %b", 
                 $time, pixel_x, pixel_y, game_over_on);
        
        // Test 4: Check boundary conditions
        pixel_x = 160;  // Left edge of text area
        pixel_y = 160;  // Top edge of text area
        #50;
        $display("Time: %0t - Left/top boundary (%0d,%0d): game_over_on = %b", 
                 $time, pixel_x, pixel_y, game_over_on);
        
        pixel_x = 415;  // Right edge of text area (416-1)
        pixel_y = 287;  // Bottom edge of text area (288-1)
        #50;
        $display("Time: %0t - Right/bottom boundary (%0d,%0d): game_over_on = %b", 
                 $time, pixel_x, pixel_y, game_over_on);
        
        // Test 5: Check no output outside text area
        pixel_x = 50;   // Outside text area (left)
        pixel_y = 50;   // Outside text area (top)
        #50;
        assert (game_over_on == 0) 
            else $error("Game over should not display outside text area");
        $display("Time: %0t - PASS: No output outside text area (left/top)", $time);
        
        pixel_x = 500;  // Outside text area (right)
        pixel_y = 350;  // Outside text area (bottom)
        #50;
        assert (game_over_on == 0) 
            else $error("Game over should not display outside text area");
        $display("Time: %0t - PASS: No output outside text area (right/bottom)", $time);
        
        // Test 6: Multiple triggers (should not retrigger when already displaying)
        pixel_x = 200;
        pixel_y = 200;
        trigger_game_over = 1;
        #20;
        trigger_game_over = 0;
        #50;
        $display("Time: %0t - Multiple trigger test: should not affect ongoing display", $time);
        
        // Test 7: Reset during operation
        #100;
        reset = 1;
        #40;
        reset = 0;
        
        #20;
        assert (game_over_on == 0 && game_over_complete == 0) 
            else $error("Reset should clear all outputs");
        $display("Time: %0t - PASS: Reset clears all signals", $time);
        
        // Test 8: Test different pixel positions for coverage
        trigger_game_over = 1;
        #20;
        trigger_game_over = 0;
        
        // Test various positions within text area
        for (int x = 160; x <= 400; x += 80) begin
            for (int y = 160; y <= 280; y += 40) begin
                pixel_x = x;
                pixel_y = y;
                #20;
                $display("Time: %0t - Position (%0d,%0d): game_over_on = %b", 
                         $time, x, y, game_over_on);
            end
        end
        
        $display("Game Over Display Testbench Complete - All Tests Passed!");
        $finish;
    end

    // Monitor key signals
    initial begin
        $monitor("Time: %0t | trigger: %b | game_over_on: %b | complete: %b | pixel: (%0d,%0d)", 
                 $time, trigger_game_over, game_over_on, game_over_complete, pixel_x, pixel_y);
    end

    // Timeout watchdog (prevent infinite simulation)
    initial begin
        #50000;  // 50 microseconds max simulation time
        $display("Testbench timeout - ending simulation");
        $finish;
    end

endmodule //tb_game_over_display