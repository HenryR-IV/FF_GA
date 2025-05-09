// identity matrix
`define IDENTITY {{16'd1,16'd0}, 32'd0, 32'd0, 32'd0, 32'd0, {16'd1,16'd0}, 32'd0, 32'd0, 32'd0, 32'd0, {16'd1,16'd0}, 32'd0, 32'd0, 32'd0, 32'd0, {16'd1,16'd0}}

// address values, parameters aren't synthesizable
`define MATRIX_ADDR 0 // append matrix
`define VRT_ADDR 1    // process vertex
`define RSLT_ADDR 2   // read result address

// FF_GA - fixed function graphics accelerator

module FF_GA(input logic clk, rst,
             input logic[31:0] addr, 
			 input logic[0:3][31:0] data_in, // 4 32-bit inputs 
             output logic[0:3][31:0] data_out, // 4 32-bit outputs
             output logic rdy );

    enum logic[2:0] {IDLE, LD, VRT, READ} state, nextstate;
    // idle, load matrix, process vertex, and read result
    
    logic[2:0] cc; // clock cycle counter, max required value is 4,

    logic[1:0] rindex, lindex; // 2 bit selectors for result and matrix output,

    logic[0:15][31:0] matrix; // composite matrix register, 16x32-bit registers

	logic[0:15][31:0] result; // result connections, 16 x 32

    logic[0:3][31:0] left; // column of matrix currently selected, 4 x 32

	logic arry_en, arry_rst;

    // generate 4x4 array of MACx units
    // i is column, j is row
    genvar i, j;
    generate
        for(i = 0; i < 4; i++)
        begin
            for(j = 0; j < 4; j++)
            begin
                MACx c(clk, 
                       arry_rst,
					   arry_en,
                       left[j],
                       data_in[i],
                       result[4*i+j]); // column major
            end
        end
    endgenerate

    always_ff @ (posedge clk)
    begin
        if(rst)
        begin
            state <= IDLE;
            matrix <= `IDENTITY;
        end
        else
        begin
            state <= nextstate;
            case(state)
                IDLE: begin
					cc <= 0;
                end
                LD: begin
					if(cc < 4)
						cc <= cc+1;
					else begin
						matrix <= result;
                        cc <= 0;
                    end
                end
				READ, VRT: begin
                    if(cc < 3)
                        cc <= cc+1;
                    else cc <= 0;
				end
            endcase
        end
    end

    // data out control
    always_comb begin
		case(rindex)
			0: data_out = result[0:3];
			1: data_out = result[4:7];
			2: data_out = result[8:11];
			3: data_out = result[12:15];
		endcase
    end

    // left input control
    always_comb begin
		case(lindex)
			0: left = matrix[0:3];
			1: left = matrix[4:7];
			2: left = matrix[8:11];
			3: left = matrix[12:15];
		endcase
    end

    // control signals and nextstate logic
    always_comb
    begin
        case(state)
            IDLE: begin
				// select nextstate based on address input
                case(addr)
                    `MATRIX_ADDR:
						nextstate = LD;
					`VRT_ADDR:
						nextstate = VRT;
					`RSLT_ADDR:
						nextstate = READ;
                    default:
                        nextstate = IDLE;
                endcase
				// once operation starts it cannot be interrupted and will return to idle once complete
                rdy = 1; // ready flag only set in idle state
				arry_en = 0; // array disabled
                arry_rst = 1; // array reset
				rindex = 0; // index not used
				lindex = 0; // index not used
            end
            LD: begin
                rdy = 0;
				rindex = 0;
                arry_rst = 0; 

				if(cc < 4) begin
					arry_en = 1;
					lindex = cc;
					nextstate = state;
				end
				else begin
					arry_en = 0;
					lindex = 0;
					if(addr != `RSLT_ADDR) nextstate = IDLE;
                    else nextstate = READ;
				end
            end
            VRT: begin
                rdy = 0;
				rindex = 0;
                arry_rst = 0; 

				lindex = cc;

				if(cc < 3) begin
					arry_en = 1;
					nextstate = state;
				end
				else begin
					if(addr != `RSLT_ADDR) nextstate = IDLE; // here going to idle means the value will be lost
                    else nextstate = READ;
				end
            end
			READ: begin
                rdy = 0;
				arry_en = 0;
                arry_rst = 0; 
				lindex = 0;
			    
                rindex = cc;

				if(cc < 3) begin
					nextstate = state;
				end
				else begin
					arry_en = 0;
					nextstate = IDLE;
				end
			end
        endcase
    end

endmodule
