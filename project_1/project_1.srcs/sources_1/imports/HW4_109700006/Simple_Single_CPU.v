module Simple_Single_CPU( clk_i, rst_n );

//I/O port
input         clk_i;
input         rst_n;

//Internal Signles
wire [32-1:0] instr, PC_i, PC_o, ReadData1, ReadData2, WriteData;
wire [32-1:0] signextend, zerofilled, ALUinput2, ALUResult, ShifterResult;
wire [5-1:0] WriteReg_addr, Shifter_shamt;
wire [4-1:0] ALU_operation;
wire [3-1:0] ALUOP;
wire [2-1:0] FURslt;
//wire [2-1:0] RegDst, MemtoReg;
wire RegDst, MemtoReg;
wire RegWrite, ALUSrc, zero, overflow;
wire Jump, Branch, BranchType, MemWrite, MemRead;
wire [32-1:0] PC_add1, PC_add2, PC_no_jump, PC_t, Mux3_result, DM_ReadData;
wire Jr;
assign Jr = ((instr[31:26] == 6'b000000) && (instr[20:0] == 21'd8)) ? 1 : 0;
//modules
/*your code here*/

Program_Counter PC(
        .clk_i(clk_i),      
	    .rst_n(rst_n),     
	    .pc_in_i(PC_i) ,   
	    .pc_out_o(PC_o) 
	    );
	
Adder Adder1(
        .src1_i(PC_o),     
	    .src2_i(32'd4),
	    .sum_o(PC_add1)    
	    );
	
Instr_Memory IM(
        .pc_addr_i(PC_o),  
	    .instr_o(instr)    
	    );

Mux2to1 #(.size(5)) Mux_Write_Reg(
        .data0_i(instr[20:16]),
        .data1_i(instr[15:11]),
        .select_i(RegDst),
        .data_o(WriteReg_addr)
        );	

Decoder Decoder(
        .instr_op_i(instr[31:26]), 
	    .RegWrite_o(RegWrite), 
	    .ALUOp_o(ALUOP),   
	    .ALUSrc_o(ALUSrc),   
	    .RegDst_o(RegDst),
        .Jump_o(Jump),
        .Branch_o(Branch),
        .BranchType_o(BranchType),
        .MemWrite_o(MemWrite),
        .MemRead_o(MemRead),
        .MemtoReg_o(MemtoReg)
		); 

// For jump 等等做

wire [27:0] tmp;
assign tmp = instr[25:0] << 2;
assign PC_t = {PC_add1[31:28], tmp };

Reg_File RF(
        .clk_i(clk_i),      
	    .rst_n(rst_n) ,     
        .RSaddr_i(instr[25:21]) ,  
        .RTaddr_i(instr[20:16]) ,  
        .RDaddr_i(WriteReg_addr) ,  
        .RDdata_i(WriteData)  , 
        .RegWrite_i(RegWrite),
        .RSdata_o(ReadData1) ,  
        .RTdata_o(ReadData2)   
        );

Sign_Extend SE(
        .data_i(instr[15:0]),
        .data_o(signextend)
        );

Zero_Filled ZF(
        .data_i(instr[15:0]),
        .data_o(zerofilled)
        );

ALU_Ctrl AC(
        .funct_i(instr[5:0]),   
        .ALUOp_i(ALUOP),   
        .ALU_operation_o(ALU_operation),
		.FURslt_o(FURslt)
        );


		
Mux2to1 #(.size(32)) ALU_src2Src(
        .data0_i(ReadData2),
        .data1_i(signextend),
        .select_i(ALUSrc),
        .data_o(ALUinput2)
        );	
		

Shifter shifter( 
		.result(ShifterResult), 
		.leftRight(ALU_operation[0]),
		.shamt(instr[10:6]),
		.sftSrc(ALUinput2) 
		);

ALU ALU(
		.aluSrc1(ReadData1),
	    .aluSrc2(ALUinput2),
	    .ALU_operation_i(ALU_operation),
		.result(ALUResult),
		.zero(zero),
		.overflow(overflow)
	    );


Adder Adder2(
        .src1_i(PC_add1),     
	    .src2_i(signextend<<2),
	    .sum_o(PC_add2)    
	    );

Mux3to1 #(.size(32)) RDdata_Source(
        .data0_i(ALUResult),
        .data1_i(ShifterResult),
		.data2_i(zerofilled),
        .select_i(FURslt),
        .data_o(Mux3_result)
        );

wire beq_bne;

Mux2to1 #(.size(1)) bne_or_beq(
        .data0_i(zero),
        .data1_i(~zero),
        .select_i(BranchType),
        .data_o(beq_bne)
        );	
Data_Memory DM(
        .clk_i(clk_i),
        .addr_i(Mux3_result),
        .data_i(ReadData2),
        .MemRead_i(MemRead),
        .MemWrite_i(MemWrite),
        .data_o(DM_ReadData)
        );

wire PCSrc;
assign PCSrc = Branch && beq_bne;
Mux2to1 #(.size(32)) PC_Source(
        .data0_i(PC_add1),
        .data1_i(PC_add2),
        .select_i(PCSrc),
        .data_o(PC_no_jump)
        );	

Mux2to1 #(.size(32)) WriteData_Source(
        .data0_i(Mux3_result),
        .data1_i(DM_ReadData),
        .select_i(MemtoReg),
        .data_o(WriteData)
        );	

Mux2to1 #(.size(32)) jump_or_not(
        .data0_i(PC_no_jump),
        .data1_i(PC_t),
        .select_i(Jump),
        .data_o(PC_i)
        );	

			
endmodule



