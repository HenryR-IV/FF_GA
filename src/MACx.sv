// fixed point multiply and acculumate cell, for parallel array
// 16.16 2's complement 32-bit fixed point format
// 2 data inputs, 1 result output

module MACx(input  logic clk, rst, en, 
            input  logic[15:-16] data_in1, data_in2, 
            output logic[15:-16] result);

    logic[31:-32] next_result;

    always_ff @ (posedge clk)
    begin
        if(rst)
            result <= 0;
        else if(en)
            result <= next_result[15:-16]; // inner 32 bits is result
    end
    
	always_comb
	begin
		next_result = ($signed(data_in1) * $signed(data_in2));
		next_result[15:-16] = next_result[15:-16] + result;
	end

endmodule
