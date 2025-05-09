`timescale 1ns/10ps
`define MATRIX 0
`define VRT 1
`define RSLT 2

module FF_GA_tb;
    logic clk, rst, rdy;
    logic[31:0] addr;
    logic[0:3][31:0] data_in, data_out;
    logic[0:15][31:0] result, expected_result;

    int error_count = 0;

    FF_GA  UUT(clk, rst, addr, 
               data_in, data_out, rdy);

    always #110 clk = ~clk;
task load_matrix(input logic[0:15][31:0] m);
        addr = `MATRIX;
        @(posedge clk); #1; // wait for state switch
        if(rdy) @(posedge clk); // wait an additional cycle if idle 
        data_in = {m[0], m[1], m[2], m[3]};
        @(posedge clk); #1;
        data_in = {m[4], m[5], m[6], m[7]};
        @(posedge clk); #1;
        data_in = {m[8], m[9], m[10], m[11]};
        @(posedge clk); #1;
        data_in = {m[12], m[13], m[14], m[15]};
        @(posedge clk); #1;
        addr = 455; // set address to random value so it won't reenter state
    endtask

    task load_vertex(input logic[0:15][31:0] m);
        addr = `VRT;
        @(posedge clk); #1; // wait for state switch
        if(rdy) @(posedge clk); // wait an additional cycle if idle 
        data_in = {m[0], m[1], m[2], m[3]};
        @(posedge clk); #1;
        data_in = {m[4], m[5], m[6], m[7]};
        @(posedge clk); #1;
        data_in = {m[8], m[9], m[10], m[11]};
        @(posedge clk); #1;
        data_in = {m[12], m[13], m[14], m[15]};
        addr = 455; // set address to random value so it won't reenter state
    endtask

    // outputs by column
    task read_result();
        addr = `RSLT;

        @(posedge clk);   // wait for state switch

        @(negedge clk);
        result[0] = data_out[0];
        result[4] = data_out[1];
        result[8] = data_out[2];
        result[12] = data_out[3];

        @(negedge clk);
        result[1] = data_out[0];
        result[5] = data_out[1];
        result[9] = data_out[2];
        result[13] = data_out[3];

        @(negedge clk);
        result[2] = data_out[0];
        result[6] = data_out[1];
        result[10]= data_out[2];
        result[14] = data_out[3];

        @(negedge clk);
        result[3] = data_out[0];
        result[7] = data_out[1];
        result[11]= data_out[2];
        result[15] = data_out[3];

        @(posedge clk) #1;

        addr = 455; // set address to random value so it won't reenter state
    endtask

    task print_matrix(input logic[0:15][31:0] m);
        $display("%h       %h       %h       %h", m[0],  m[1],  m[2],  m[3]);
        $display("%h       %h       %h       %h", m[4],  m[5],  m[6],  m[7]);
        $display("%h       %h       %h       %h", m[8],  m[9],  m[10], m[11]);
        $display("%h       %h       %h       %h", m[12], m[13], m[14], m[15]);
    endtask

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk); #1;
        rst = 0;

        // load composite projection and viewport matrix for orthographic projection to 600 x 600 window
        // glOrtho(-300,300,-300,300,0,10000);
        // glViewport(0,0,600,600);
        /*
            | 1 0  0       300 |
            | 0 1  0       300 |
            | 0 0 -1/10000 0   |
            | 0 0  0       1   |
        */ 

        load_matrix({ {16'd1, 16'd0},  32'd0,         32'd0,               {16'd300,16'd0}, 
                       32'd0,         {16'd1,16'd0},  32'd0,               {16'd300,16'd0}, 
                       32'd0,          32'd0,        {16'hffff, 16'hfffa},  32'd0,
                       32'd0,          32'd0,         32'd0,               {16'd1, 16'd0} });

        expected_result = { {16'd1, 16'd0},  32'd0,         32'd0,               {16'd300,16'd0}, 
                             32'd0,         {16'd1,16'd0},  32'd0,               {16'd300,16'd0}, 
                             32'd0,          32'd0,        {16'hffff, 16'hfffa},  32'd0,
                             32'd0,          32'd0,         32'd0,               {16'd1, 16'd0} };

        read_result();

        $display("Expected: ");
        print_matrix(expected_result);
        $display("\nReceived: ");
        print_matrix(result);

        assert(result === expected_result)
        else begin
            $display("Result Failed\n");
            error_count++;
        end


        // transfomation matrix
        // glTranslate(1, 2, 3);
        /*
            | 1 0 0 1 |
            | 0 1 0 2 |
            | 0 0 1 3 |
            | 0 0 0 1 |
        */
        load_matrix( { {16'd1, 16'd0},  32'd0,          32'd0,         {16'd1, 16'd0}, 
                        32'd0,         {16'd1, 16'd0},  32'd0,         {16'd2, 16'd0}, 
                        32'd0,          32'd0,         {16'd1, 16'd0}, {16'd3, 16'd0}, 
                        32'd0,          32'd0,          32'd0,         {16'd1, 16'd0}});

        // check result is computed correctly and stored in composite
        /*
            | 1 0  0        301     |
            | 0 1  0        302     |
            | 0 0 -1/10000 -3/10000 |
            | 0 0  0        1       |
        */

        expected_result = {{16'd1, 16'd0},  32'd0,           32'd0,               {16'd301,16'd0},  
                            32'd0,         {16'd1,16'd0},    32'd0,               {16'd302,16'd0}, 
                            32'd0,          32'd0,          {16'hffff, 16'hfffa}, {16'hffff, 16'hffee}, 
                            32'd0,          32'd0,           32'd0,               {16'd1, 16'd0}};

        read_result();

        $display("\nExpected: ");
        print_matrix(expected_result);
        $display("\nReceived: ");
        print_matrix(result);

        assert(result === expected_result)
        else begin
            $display("Result Failed\n");
            error_count++;
        end

        // load vertex
        // can do 4 simulataneously, only doing 1 here in first column
        /*
            | 1 0 0 0 |
            | 2 0 0 0 |
            | 3 0 0 0 |
            | 1 0 0 0 |
        */
        load_vertex( {{16'd1, 16'd0}, 32'd0, 32'd0, 32'd0,
                      {16'd2, 16'd0}, 32'd0, 32'd0, 32'd0,
                      {16'd3, 16'd0}, 32'd0, 32'd0, 32'd0,
                      {16'd1, 16'd0}, 32'd0, 32'd0, 32'd0 });

        /*
            |  302    0 0 0 |
            |  304    0 0 0 |
            | -3/5000 0 0 0 |
            |  1 0    0 0 0 |
        */
        expected_result = {{16'd302, 16'd0},     32'd0, 32'd0, 32'd0,     
                           {16'd304, 16'd0},     32'd0, 32'd0, 32'd0, 
                           {16'hffff, 16'hffdc}, 32'd0, 32'd0, 32'd0, 
                           {16'd1, 16'd0},       32'd0, 32'd0, 32'd0 };
                           // note that -3/5000 result was to account for some error when calculating expected result
                           // this was due to precision loss

        read_result();

        $display("\nExpected: ");
        print_matrix(expected_result);
        $display("\nReceived: ");
        print_matrix(result);

        assert(result === expected_result)
        else begin
            $display("Result Failed\n");
            error_count++;
        end

        if(error_count > 0)
            $display("Test Failed with %d Errors", error_count);
        else
            $display("All Tests Passed\n");

        @ (posedge clk);
        @ (posedge clk);
        $finish;
    end

endmodule

