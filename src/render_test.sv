`timescale 1ns/10ps
`define MATRIX 0
`define VRT 1
`define RSLT 2

// This testbench is not really useful without the supporting C++ programs 
// But, they do not work on blackhawk since they require other libraries

module render_test;

    logic clk, rst, rdy;
    logic[31:0] addr;
    logic[0:3][31:0] data_in, data_out;
    logic[0:15][31:0] result, expected_result;

	logic[31:0] vertex_data[0:100000]; // 100,000/3 verticies some of these files can get very large
	logic[31:0] num_vert;
	int fd;

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

		// this testbench is replicating the behavior of a simple stl renderer I created using OpenGL
		// same order of matricies, should produce nearly identical result

        // load composite projection and viewport matrix for orthographic projection to 600 x 600 window
        // glOrtho(-300,300,-300,300,0,10000);
        // glViewport(0,0,600,600);
        /*
            | 1 0  0       300 |
            | 0 1  0       300 |
            | 0 0 -1/10000 0   |
            | 0 0  0       1   |
        */
        load_matrix( { {16'd1, 16'd0}, 		32'd0, 				  32'd0, {16'd300,16'd0}, 
				 		 32'd0, {16'd1,16'd0}, 				  32'd0, {16'd300,16'd0}, 
				 		 32'd0, 		32'd0, {16'hffff, 16'hfffa}, 		   32'd0,
				 		 32'd0, 		32'd0, 				  32'd0, {16'd1, 16'd0} });


        // load_matrix transformations

		// Translate (0, 0, -1200)
        load_matrix( { {16'd1, 16'd0},  32'd0, 		32'd0,   		 32'd0, 
						32'd0, 	    {16'd1,16'd0},	32'd0,           32'd0, 
						32'd0, 		 32'd0, 	   {16'd1, 16'd0},  -{16'd1200,16'd0},
						32'd0, 		 32'd0, 		32'd0,          {16'd1, 16'd0}  }); 

		// RotateX (-60)
        load_matrix( { {16'd1, 16'd0},  32'd0, 	 	    32'd0, 		       32'd0, 
						32'd0, 		{16'd0, 16'h8000}, {16'd0, 16'hddb3},  32'd0, 
						32'd0, 	   -{16'd0, 16'hddb3}, {16'd0, 16'h8000},  32'd0,
						32'd0, 		 32'd0, 		    32'd0, 		      {16'd1, 16'd0} }); 

		// RotateZ (-60)
        load_matrix( { {16'd0,16'hb504},  {16'd0,16'hb504},  32'd0,         32'd0, 
					-{16'd0,16'hb504},  {16'd0,16'hb504},  32'd0, 	     32'd0, 
						32'd0,             32'd0, 	         {16'd1,16'd0},  32'd0,
						32'd0, 	        32'd0, 	          32'd0, 	    {16'd1, 16'd0} });

		// RotateX (45)
        //load_matrix( { {16'd1, 16'd0},  32'd0, 	 	    32'd0, 		      32'd0, 
		//		 32'd0, 		{16'd0,16'hb504}, -{16'd0,16'hb504},  32'd0, 
		//		 32'd0, 	    {16'd0,16'hb504},  {16'd0,16'hb504},  32'd0,
		//		 32'd0, 		 32'd0, 		    32'd0, 		     {16'd1, 16'd0} }, `MATRIX); 

		// Scale (5,5,5)
        load_matrix( { {16'd5, 16'd0},  32'd0, 	    32'd0, 	  	    32'd0, 
						32'd0,         {16'd5,16'd0},  32'd0, 		    32'd0, 
						32'd0, 		 32'd0, 	   {16'd5, 16'd0},  32'd0,
						32'd0, 		 32'd0, 	    32'd0, 		   {16'd1, 16'd0} });

		
		$readmemh("test.txt", vertex_data);
		fd = $fopen("output.txt", "w");

		num_vert = vertex_data[0];
		$fdisplayh(fd, num_vert);
		for(int i = 1; i <= num_vert*4; i+=16) begin
			load_vertex({vertex_data[i], vertex_data[i+1], vertex_data[i+2], vertex_data[i+3], 
						vertex_data[i+4], vertex_data[i+5], vertex_data[i+6], vertex_data[i+7], 
						vertex_data[i+8], vertex_data[i+9], vertex_data[i+10], vertex_data[i+11],
						vertex_data[i+12], vertex_data[i+13], vertex_data[i+14], vertex_data[i+15]});

			read_result();
			
			// print results to output file, only need x and y of each
			$fdisplayh(fd, result[0]);
			$fdisplayh(fd, result[4]);

			$fdisplayh(fd, result[1]);
			$fdisplayh(fd, result[5]);

			$fdisplayh(fd, result[2]);
			$fdisplayh(fd, result[6]);

			$fdisplayh(fd, result[3]);
			$fdisplayh(fd, result[7]);
		end

		$display("i: %d", num_vert);

		$fclose(fd);
		$finish;

	end

endmodule
