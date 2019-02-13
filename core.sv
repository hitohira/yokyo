`default_nettype none

interface instif;
  reg lui;
  reg auipc;
  reg jal;
  reg jalr;
  reg beq;
  reg bne;
  reg blt;
  reg bge;
  reg bltu;
  reg bgeu;
  reg lb;
  reg lh;
  reg lw;
  reg lbu;
  reg lhu;
  reg sb;
  reg sh;
  reg sw;
  reg addi;
  reg slti;
  reg sltiu;
  reg xori;
  reg ori;
  reg andi;
  reg slli;
  reg srli;
  reg srai;
  reg add;
  reg sub;
  reg sll;
  reg slt;
  reg sltu;
  reg xor_;
  reg srl;
  reg sra;
  reg or_;
  reg and_;
  
  reg fadd;
  reg fsub;
  reg fmul;
  reg fdiv;
  reg fsw;
  reg flw;
  reg feq;
  reg flt;
  reg fle;
  
  reg fsgnj;
  reg fsgnjn;

  reg mul;
	reg mulh;
	reg mulhsu;
	reg mulhu;
	reg div;
	reg divu;
	reg rem;
	reg remu;
								  
	reg csrrw;
	reg csrrs;
	reg csrrc;

	reg ecall;
	reg sret;
  
  wire inval;

  assign inval = ~(lui | auipc | jal | jalr | beq | bne | blt | bge | bltu | bgeu | lb |
	            lh | lw | lbu | lhu | sb | sh | sw | addi | slti | sltiu | xori | ori | 
	            andi | slli | srli | srai | add | sub | sll | slt | sltu | xor_ | srl |
	            sra | or_ | and_ | fadd | fsub | fmul | fdiv | fsw | flw | feq | flt | fle |
	            fsgnj | fsgnjn | mul | mulh | mulhsu | mulhu | div | divu | rem | remu |
	            csrrw | csrrs | csrrc | ecall | sret); 
endinterface

module decoder
 (
     input wire clk,
     input wire rstn,

     output reg [4:0] rd,
     output wire [4:0] rs1,
     output wire [4:0] rs2,
     output reg [31:0] imm,
		 output reg [11:0] csr,

     instif inst,
     
     input reg [31:0] inst_code
 );
    wire r_type;
    wire [6:0] opcode;
    assign opcode = inst_code[6:0];
    wire [2:0] funct3;
    assign funct3 = inst_code[14:12];
    wire [6:0] funct7;
    assign funct7 = inst_code[31:25];

    assign r_type = ((inst_code[6:5] == 2'b01) || inst_code[6:5] == 2'b10) && (inst_code[4:2] == 3'b100);
    wire i_type;
    assign i_type = ((inst_code[6:5] == 2'b00) &&
                        ((inst_code[4:2] == 3'b000) ||
                         (inst_code[4:2] == 3'b100) ||
                         (inst_code[4:2] == 3'b001)))||
                    ((inst_code[6:5] == 2'b11) && (inst_code[4:2] == 3'b001));
    wire s_type;
    assign s_type = (inst_code[6:5] == 2'b01) && ((inst_code[4:2] == 3'b000) || (inst_code[4:2] == 3'b001));
    wire b_type;
    assign b_type = (inst_code[6:5] == 2'b11) && (inst_code[4:2] == 3'b000);
    wire u_type;
    assign u_type = ((inst_code[6:5] == 2'b01) || (inst_code[6:5] == 2'b00)) && (inst_code[4:2] == 3'b101);
    wire j_type;
    assign j_type = ((inst_code[6:5] == 2'b11) && (inst_code[4:2] == 3'b011));

    assign rs1 = (r_type | i_type | s_type | b_type) ? inst_code[19:15] : 5'd0;
    assign rs2 = (r_type | s_type | b_type) ? inst_code[24:20] : 5'd0;

    always @(posedge clk) begin
        rd <= (r_type | i_type | u_type | j_type) ? inst_code[11:7] : 5'd0;
				csr <= inst_code[31:20];

        imm <= i_type ? {{21{inst_code[31]}}, inst_code[30:20]} :
             s_type ? {{21{inst_code[31]}}, inst_code[30:25], inst_code[11:7]} :
             b_type ? {{20{inst_code[31]}}, inst_code[7], inst_code[30:25], inst_code[11:8], 1'b0} :
             u_type ? {inst_code[31:12], 12'd0} :
             j_type ? {{12{inst_code[31]}}, inst_code[19:12], inst_code[20], inst_code[30:21], 1'b0} : 32'd0;

        inst.lui   <= opcode == 7'b0110111;
        inst.auipc <= opcode == 7'b0010111;
        inst.jal   <= opcode == 7'b1101111;
        inst.jalr  <= opcode == 7'b1100111;

        inst.beq   <= (opcode == 7'b1100011) && (funct3 == 3'b000);
        inst.bne   <= (opcode == 7'b1100011) && (funct3 == 3'b001);
        inst.blt   <= (opcode == 7'b1100011) && (funct3 == 3'b100);
        inst.bge   <= (opcode == 7'b1100011) && (funct3 == 3'b101);
        inst.bltu  <= (opcode == 7'b1100011) && (funct3 == 3'b110);
        inst.bgeu  <= (opcode == 7'b1100011) && (funct3 == 3'b111);

        inst.lb  <= (opcode == 7'b0000011) && (funct3 == 3'b000);
        inst.lh  <= (opcode == 7'b0000011) && (funct3 == 3'b001);
        inst.lw  <= (opcode == 7'b0000011) && (funct3 == 3'b010);
        inst.lbu <= (opcode == 7'b0000011) && (funct3 == 3'b100);
        inst.lhu <= (opcode == 7'b0000011) && (funct3 == 3'b101);

        inst.sb  <= (opcode == 7'b0100011) && (funct3 == 3'b000);
        inst.sh  <= (opcode == 7'b0100011) && (funct3 == 3'b001);
        inst.sw  <= (opcode == 7'b0100011) && (funct3 == 3'b010);

        inst.addi  <= (opcode == 7'b0010011) && (funct3 == 3'b000);
        inst.slti  <= (opcode == 7'b0010011) && (funct3 == 3'b010);
        inst.sltiu <= (opcode == 7'b0010011) && (funct3 == 3'b011);
        inst.xori  <= (opcode == 7'b0010011) && (funct3 == 3'b100);
        inst.ori   <= (opcode == 7'b0010011) && (funct3 == 3'b110);
        inst.andi  <= (opcode == 7'b0010011) && (funct3 == 3'b111);

        inst.slli <= (opcode == 7'b0010011) && (funct3 == 3'b001);
        inst.srli <= (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
        inst.srai <= (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);

        inst.add  <= (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
        inst.sub  <= (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
        inst.sll  <= (opcode == 7'b0110011) && (funct3 == 3'b001);
        inst.slt  <= (opcode == 7'b0110011) && (funct3 == 3'b010);
        inst.sltu <= (opcode == 7'b0110011) && (funct3 == 3'b011);
        inst.xor_ <= (opcode == 7'b0110011) && (funct3 == 3'b100);
        inst.srl  <= (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
        inst.sra  <= (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
        inst.or_  <= (opcode == 7'b0110011) && (funct3 == 3'b110);
        inst.and_ <= (opcode == 7'b0110011) && (funct3 == 3'b111);
        
        inst.fadd <= (opcode == 7'b1010011) && (funct7 == 7'b0000000);
        inst.fsub <= (opcode == 7'b1010011) && (funct7 == 7'b0000100);
        inst.fmul <= (opcode == 7'b1010011) && (funct7 == 7'b0001000);
        inst.fdiv <= (opcode == 7'b1010011) && (funct7 == 7'b0001100);
        inst.feq  <= (opcode == 7'b1010011) && (funct7 == 7'b1010000) && (funct3 == 3'b010);
        inst.flt  <= (opcode == 7'b1010011) && (funct7 == 7'b1010000) && (funct3 == 3'b001);
        inst.fle  <= (opcode == 7'b1010011) && (funct7 == 7'b1010000) && (funct3 == 3'b000);
        inst.fsgnj   <= (opcode == 7'b1010011) && (funct7 == 7'b0010000) && (funct3 == 3'b000);
        inst.fsgnjn  <= (opcode == 7'b1010011) && (funct7 == 7'b0010000) && (funct3 == 3'b001);
        
        inst.fsw <= opcode == 7'b0100111;
        inst.flw <= opcode == 7'b0000111;

				inst.mul    <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b000);
				inst.mulh   <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b001);
				inst.mulhsu <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b010);
				inst.mulhu  <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b011);
				inst.div    <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b100);
				inst.divu   <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b101);
				inst.rem    <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b110);
				inst.remu   <= (opcode == 7'b0110011) && (funct7 == 7'b1) && (funct3 == 3'b111);
																			        
				inst.csrrw <= (opcode == 7'b1110011) && (funct3 == 3'b001);
				inst.csrrs <= (opcode == 7'b1110011) && (funct3 == 3'b010);
				inst.csrrc <= (opcode == 7'b1110011) && (funct3 == 3'b011);

				inst.ecall <= inst_code == 32'b1110011;
				inst.sret <= inst_code == 32'b00010000001000000000000001110011;
    end
endmodule


typedef enum reg [2:0] {
    s_wait, s_inst_fetch, s_inst_decode, s_inst_write, s_inst_exec, s_inst_inval, s_inst_mem
} s_inst;

typedef enum reg [4:0] {
    s_alu_add, s_alu_sub, s_alu_xor, s_alu_shl, s_alu_shr, s_alu_eq, s_alu_lts, s_alu_ltu, s_alu_or, s_alu_and
} s_alu;


module register
    (
        input wire clk,
        input wire rstn,
        
        input wire [4:0] rd_idx,
        input wire rd_enable,
        input wire [31:0] data,
        
        input wire [4:0] rs1_idx,
        output reg [31:0] rs1,
        input wire [4:0] rs2_idx,
        output reg [31:0] rs2
    );
    reg [31:0] iregs[32];
    
		always @(posedge clk) begin
      rs1 <= rs1_idx == 0 ? 32'd0 : iregs[rs1_idx];
      rs2 <= rs2_idx == 0 ? 32'd0 : iregs[rs2_idx];
		end
    
    assign iregs[0] = 32'd0;
    
    generate
        genvar i;
        for (i = 1; i < 32; i = i + 1) begin
            always @(posedge clk) begin
                if (~rstn) begin
                    iregs[i] <= 32'd0;
                end else begin 
                    if (rd_enable && i == rd_idx) begin
                        iregs[i] <=  data;
                    end
                end
            end
        end
    endgenerate

endmodule

module fregister
    (
        input wire clk,
        input wire rstn,
        
        input wire [4:0] rd_idx,
        input wire rd_enable,
        input wire [31:0] data,
        
        input wire [4:0] rs1_idx,
        output reg [31:0] rs1,
        input wire [4:0] rs2_idx,
        output reg [31:0] rs2
    );
    reg [31:0] fregs[32];
    
		always @(posedge clk) begin
      rs1 <= fregs[rs1_idx];
      rs2 <= fregs[rs2_idx];
		end
    
    generate
        genvar i;
        for (i = 0; i < 32; i = i + 1) begin
            always @(posedge clk) begin
                if (~rstn) begin
                    fregs[i] <= 32'd0;
                end else begin 
                    if (rd_enable && i == rd_idx) begin
                        fregs[i] <=  data;
                    end
                end
            end
        end
    endgenerate

endmodule

module alu 
 (
    input wire clk,
    input wire rstn,
    input wire [31:0] src1,
    input wire [31:0] src2,
    output reg [31:0] result,
    instif inst
 );

		reg [31:0] d_add;
		reg [31:0] d_sub;
		reg [31:0] d_slt;
		reg [31:0] d_sltu;
		reg [31:0] d_xor_;
		reg [31:0] d_or_;
		reg [31:0] d_and_;
		reg [31:0] d_sll;
		reg [31:0] d_srl;
		reg [31:0] d_sra;
		reg [31:0] d_beq;
		reg [31:0] d_bne;
		reg [31:0] d_blt;
		reg [31:0] d_bge;
		reg [31:0] d_bltu;
		reg [31:0] d_bgeu;
		always @(posedge clk) begin
			d_add <= src1 + src2;
			d_sub <= src1 - src2;
			d_slt <= $signed(src1) < $signed(src2);
			d_sltu <= src1 < src2;
			d_xor_ <= src1 ^ src2;
			d_or_ <= src1 | src2;
			d_and_ <= src1 & src2;
			d_sll <= src1 << src2;
			d_srl <= src1 >> src2;
			d_sra <= $signed(src1) >>> $signed(src2);
			d_beq <= src1 == src2;
			d_bne <= src1 != src2;
			d_blt <= $signed(src1) < $signed(src2);
			d_bge <= $signed(src1) >= $signed(src2);
			d_bltu <= src1 < src2;
			d_bgeu <= src1 >= src2;
		end

    always @(posedge clk) begin
        if (~rstn) begin
            result <= 32'd0;
        end else begin
			//			result <= result_;
						
            result <= (inst.add | inst.addi) ? d_add : // src1 + src2 : 
                       (inst.sub)             ? d_sub : //src1 - src2 :
                       (inst.slti | inst.slt) ? d_slt : //$signed(src1) < $signed(src2) :
                       (inst.sltiu | inst.sltu) ? d_sltu : // src1 < src2 :
                       (inst.xori | inst.xor_) ? d_xor_ : //src1 ^ src2:
                       (inst.ori | inst.or_) ? d_or_ : //src1 | src2:
                       (inst.andi | inst.and_) ? d_and_ : // src1 & src2:
                       (inst.slli | inst.sll) ? d_sll : //src1 << src2:
                       (inst.srli | inst.srl) ? d_srl : //src1 >> src2:
                       (inst.srai | inst.sra) ? d_sra : //$signed(src1) >>> $signed(src2):
                       (inst.beq) ? d_beq ://src1 == src2:
                       (inst.bne) ? d_bne : //src1 != src2:
                       (inst.blt) ? d_blt : //$signed(src1) < $signed(src2):
                       (inst.bge) ? d_bge : //$signed(src1) >= $signed(src2):
                       (inst.bltu) ? d_bltu : //src1 < src2:
                       (inst.bgeu) ? d_bgeu : //src1 >= src2:
                       32'd0;
        end
    end 
endmodule

module core (
  input wire clk,
  input wire rstn,

	//mmu (big endian)
	output reg [31:0] m_axi_araddr,
	input wire m_axi_arready,
	output reg m_axi_arvalid,
			   
	output reg [31:0] m_axi_awaddr,
	input wire m_axi_awready,
	output reg m_axi_awvalid,
				   
	output reg m_axi_bready,
	input wire [1:0] m_axi_bresp,
	input wire m_axi_bvalid,

	input wire [31:0] m_axi_rdata,
	output reg m_axi_rready,
	input wire [1:0] m_axi_rresp,
	input wire m_axi_rvalid,

	output reg [31:0] m_axi_wdata,
	input wire m_axi_wready,
	output reg [3:0] m_axi_wstrb,
	output reg m_axi_wvalid,

  output reg [1:0] m_cpu_mode,
	output reg [31:0] m_satp,
	output reg m_is_instr,

	input wire m_throw_exception,
	input wire [2:0] m_exception_vec,

	input wire is_timer_intr,
	input wire is_ext_intr,

	// ex unit (mul div fpu)
	output wire [19:0] ex_sig,
	output wire [31:0] ex_src1,
	output wire [31:0] ex_src2,
	output wire ex_out_valid,
	input wire [31:0] ex_result,
	input wire [2:0] ex_exception,
	input wire ex_in_valid

  );

  localparam EXCEPTION_INSTR_PG_FAULT = 3'b001;
  localparam EXCEPTION_LOAD_PG_FAULT = 3'b010;
  localparam EXCEPTION_STORE_PG_FAULT = 3'b011;
  localparam EXCEPTION_UNDEFINED = 3'b111;
			
	(* mark_debug = "true" *) s_inst state = s_wait;
	(* mark_debug = "true" *) reg [5:0] sub_state;

	(* mark_debug = "true" *) reg [31:0] instr;
	(* mark_debug = "true" *) reg [31:0] pc;
	reg [1:0] cpu_mode; // 00->U, 01->S, 11->M

  wire is_load;
	wire is_store;
  wire [31:0] addr;

	reg [2:0] mem_exception_vec;
	reg [2:0] exu_exception_vec;

  (* mark_debug = "true" *) instif inst();
  wire [4:0] rd; // DEC
  wire rd_enable;
  wire frd_enable;
  wire [4:0] rs1; //DEC
  wire [4:0] rs2; //DEC
  wire [31:0] imm; // DEC
	wire [11:0] csr_addr; // DEC
  wire [31:0] src1; // REG
  wire [31:0] src2; // REG
  wire [31:0] fsrc1; // REG
  wire [31:0] fsrc2; // REG
	wire [31:0] result;
	wire [31:0] alu_result; // ALU
  reg [31:0] load_result;
  wire [31:0] fpu_result; // FPU
	reg [31:0] csr_result;
	reg [31:0] exu_result;
   
  wire [31:0] alu_src1;
  wire [31:0] alu_src2;
  decoder DECODER(.clk(clk), .rstn(rstn), .rd(rd), .rs1(rs1), .rs2(rs2), .imm(imm), .csr(csr_addr), .inst(inst), .inst_code(instr));
  register REGISTER(.clk(clk), .rstn(rstn), .rd_idx(rd), .rd_enable(rd_enable), .rs1_idx(rs1), .rs2_idx(rs2), .data(result), .rs1(src1), .rs2(src2));
  fregister FREGISTER(.clk(clk), .rstn(rstn), .rd_idx(rd), .rd_enable(frd_enable), .rs1_idx(rs1), .rs2_idx(rs2), .data(result), .rs1(fsrc1), .rs2(fsrc2));
   
  alu ALU(.clk(clk), .rstn(rstn), .src1(alu_src1), .src2(alu_src2), .result(alu_result), .inst(inst));
	//fpu FPU(.clk(clk), .rstn(rstn), .src1(fsrc1), .src2(fsrc2), .result(fpu_result), .inst(inst));


	//exu
	wire is_exu;
	assign is_exu = inst.mul | inst.mulh | inst.mulhsu | inst.mulhu |
	                inst.div | inst.divu | inst.rem | inst.remu |
	                inst.fadd | inst.fsub | inst.fmul | inst.fdiv |
	                inst.feq | inst.flt | inst.fle | inst.fsgnj | inst.fsgnjn;
	assign ex_sig = 
		{3'b0,inst.fsgnjn,inst.fsgnj,inst.fle,inst.flt,inst.feq,inst.fdiv,inst.fmul,inst.fsub,inst.fadd,
			inst.remu,inst.rem,inst.divu,inst.div,inst.mulhu,inst.mulhsu,inst.mulh,inst.mul };
	assign ex_src1 = src1;
	assign ex_src2 = src2;
	assign ex_out_valid = is_exu && state == s_inst_exec;

	// csr
	reg [31:0] sstatus; // 0x100 Trapのネスト関係 SIE[1]が今のenable、SPIE[5]は前のenable、SPP[8]が前のモード(0=user,1=super) see mstatus
	reg [31:0] sie; // 0x104 sipに対応するenable bit、これが立っていると割込みがenable
	reg [31:0] stvec; // 0x105 BASE[31:2]=trap時のジャンプのベースアドレス,MODE[1:0]=ジャンプアドレスの決め方(HWは書き換えない?)
	reg [31:0] sscratch; // 0x140 コンテキストの保存場所を指すように使われる(HWは書き換えない?)
	reg [31:0] sepc; // 0x141, trap時にtrapが起こった時のpcに書き換える
	reg [31:0] scause; // 0x142, trap時にその原因コードに書き換える see Table 4.2
	reg [31:0] stval; // 0x143 Trap時に例外の情報を書き込む
	reg [31:0] sip; // 0x144 SSIP[1]=これが1だとソフトウェア割込み発生,STIP[5]=これが1だとタイマー割込み,SEIP[9]=これが1だと外部割込み(HWも書き換えると思う)
	reg [31:0] satp; // 0x180 アドレス変換の情報(HWは書き換えない)

	reg csr_inval_addr;
	reg csr_unprivileged;
	
	always @(posedge clk) begin
		if(~rstn) begin
			sstatus <= 0;
			sie <= 0;
			stvec <= 0;
			sscratch <= 0;
			sepc <= 0;
			scause <= 0;
			stval <= 0;
			sip <= 0;
			satp <= 0;
			csr_inval_addr <= 0;
			csr_unprivileged <= 0;
		end else if (state == s_inst_decode) begin
			csr_inval_addr <= 0;
			csr_unprivileged <= 0;
		end else if (state == s_inst_exec) begin
			if(inst.csrrw && cpu_mode != 0) begin
				case(csr_addr) 
					12'h100 : sstatus <= src1;
					12'h104 : sie <= src1;
					12'h105 : stvec <= src1;
					12'h140 : sscratch <= src1;
					12'h141 : sepc <= src1;
					12'h142 : scause <= src1;
					12'h143 : stval <= src1;
					12'h144 : sip <= src1;
					12'h180 : satp <= src1;
					default : csr_inval_addr <= 1;
				endcase
			end else if (inst.csrrs && cpu_mode != 0) begin
				case(csr_addr) 
					12'h100 : sstatus <= sstatus | src1;
					12'h104 : sie <= sie | src1;
					12'h105 : stvec <= stvec | src1;
					12'h140 : sscratch <= sscratch | src1;
					12'h141 : sepc <= sepc | src1;
					12'h142 : scause <= scause | src1;
					12'h143 : stval <= stval | src1;
					12'h144 : sip <= sip | src1;
					12'h180 : satp <= satp | src1;
					default : csr_inval_addr <= 1;
				endcase
			end else if (inst.csrrc && cpu_mode != 0) begin
				case(csr_addr) 
					12'h100 : sstatus <= sstatus & ~src1;
					12'h104 : sie <= sie & ~src1;
					12'h105 : stvec <= stvec & ~src1;
					12'h140 : sscratch <= sscratch & ~src1;
					12'h141 : sepc <= sepc & ~src1;
					12'h142 : scause <= scause & ~src1;
					12'h143 : stval <= stval & ~src1;
					12'h144 : sip <= sip & ~src1;
					12'h180 : satp <= satp & ~src1;
					default : csr_inval_addr <= 1;
				endcase
			end else if (cpu_mode == 0 && (inst.csrrw | inst.csrrs | inst.csrrc)) begin
				csr_unprivileged <= 1;
			end else if (inst.sret) begin
				sstatus <= {23'b0,1'b0,2'b0,1'b1,3'b0,sstatus[5],1'b0};
			end
		end else if (state == s_inst_write) begin
			// 0 SEIP 0 STIP 0
			sip <= sip | {22'b0,is_ext_intr,3'b0,is_timer_intr,5'b0};
		end else if (state == s_inst_inval) begin // exception
			sepc <= pc;
			// 0 SPP 0 SPIE 0 SIE 0
			sstatus <= {23'b0,cpu_mode[0],2'b0,sstatus[1],3'b0,1'b0,1'b0};
			if(occur_intr) begin
				stval <= 0;
				if(sie[9] & sip[9]) begin // ext
					scause <= {1'b1,31'b0} | (1<<9);		
				end else if (sie[5] & sip[5]) begin // timer
					scause <= {1'b1,31'b0} | (1<<5);
				end else if (sie[1] & sie[1]) begin // software
					scause <= {1'b1,31'b0} | (1<<1);
				end else begin
					scause <= {1'b1,31'b0} | (1<<10);
				end
			if(inst.inval | csr_inval_addr | csr_unprivileged) begin // Illegal instruction
				scause <= 1 << 2;
				stval <= 0;
			end else if (inst.ecall && cpu_mode == 2'b0) begin // Environment call from U-mode
				scause <= 1 << 8;
				stval <= 0;
			end else if (inst.ecall && cpu_mode == 2'b01) begin // Environment call from S-mode
				scause <= 1 << 9;
				stval <= 0;
			end else if (mem_exception_vec != 0) begin
				case(mem_exception_vec) 
					EXCEPTION_INSTR_PG_FAULT : scause <= 1 << 1;
					EXCEPTION_LOAD_PG_FAULT  : scause <= 1 << 5;
					EXCEPTION_STORE_PG_FAULT : scause <= 1 << 15;
					default : scause <= 1 << 16; // ?????????????????????
				endcase
				stval <= addr;
			end else begin
				scause <= 1 << 16;
				stval <= 0;
			end
		end
	end // always

	always @(posedge clk) begin
		if(~rstn) begin
			csr_result <= 0;
		end else if (state == s_inst_decode) begin
			csr_result <= 0;
		end else if (state == s_inst_exec && (inst.csrrw | inst.csrrs | inst.csrrc)) begin
				case(csr_addr) 
					12'h104 : csr_result <= sie;
					12'h105 : csr_result <= stvec;
					12'h140 : csr_result <= sscratch;
					12'h141 : csr_result <= sepc;
					12'h142 : csr_result <= scause;
					12'h143 : csr_result <= stval;
					12'h144 : csr_result <= sip;
					12'h180 : csr_result <= satp;
					default : csr_result <= 0;
				endcase
		end
	end
	// end csr


	assign m_cpu_mode = cpu_mode;
	
	assign m_satp = satp;

	assign rd_enable = state == s_inst_write && 
			(inst.lui | inst.auipc |
			 inst.addi | inst.slti | inst.xori | inst.ori | inst.andi | inst.slli |
			 inst.srli | inst.srai | inst.add | inst.sub | inst.sll | inst.slt |
			 inst.sltu | inst.xor_ | inst.srl | inst.sra  | inst.or_  | inst.and_ |
			 inst.lb | inst.lh | inst.lw | inst.lbu | inst.lhu |
			 inst.jal | inst.jalr | 
			 inst.csrrw | inst.csrrs | inst.csrrc |
			 inst.mul | inst.mulh | inst.mulhsu | inst.mulhu |
			 inst.div | inst.divu | inst.rem | inst.remu);
	assign frd_enable = state == s_inst_write &&
			(inst.fadd | inst.fsub | inst.fmul | inst.fdiv | inst.fsgnj | inst.fsgnjn | inst.flw);
	assign result = 
			inst.lui ? imm :
			inst.auipc ? pc + imm :
			(inst.addi | inst.slti | inst.xori | inst.ori | inst.andi | inst.slli | 
			 inst.srli | inst.srai | inst.add | inst.sub | inst.sll | inst.slt | inst.sltu |
			 inst.xor_ | inst.srl | inst.sra  | inst.or_  | inst.and_) ? alu_result :
			(inst.lb | inst.lh | inst.lw | inst.lbu | inst.lhu | inst.flw) ? load_result :
			(inst.jal | inst.jalr) ? pc + 32'd4 :
			is_exu ? exu_result :
			 (inst.csrrw | inst.csrrs | inst.csrrc) ? csr_result :
			32'b0;


      
  assign alu_src1 = src1;
  assign alu_src2 = (inst.add | inst.sub | inst.sll | inst.slt | inst.sltu | inst.xor_ | inst.srl | inst.sra  | inst.or_  | inst.and_ |
                     inst.beq | inst.bne | inst.blt | inst.bge | inst.bltu | inst.bgeu) ? src2 :
                     imm;
                      
  assign is_load = inst.lb | inst.lh | inst.lw | inst.lbu | inst.lhu | inst.flw;
	assign is_store = inst.sb | inst.sh | inst.sw | inst.fsw;
  assign addr = src1 + imm;   

	wire occur_intr;	
	assign occur_intr = sstatus[1] &&	((sie[9] & sip[9]) || (sie[5] & sip[5]) || (sie[1] & sip[1]));
	
	always @(posedge clk) begin
		if (~rstn) begin 
			sub_state <= 0;
			instr <= 0;
			pc <= 0;
			cpu_mode <= 0;

			//mmu reg
			m_axi_araddr <= 0;
			m_axi_arvalid <= 0;
			m_axi_awaddr <= 0;
			m_axi_awvalid <= 0;
			m_axi_bready <= 0;
			m_axi_rready <= 0;
			m_axi_wdata <= 0;
			m_axi_wstrb <= 0;
			m_axi_wvalid <= 0;

			exu_result <= 0;
			exu_exception_vec <= 0;
			mem_exception_vec <= 0;
		end else if (state == s_wait) begin
			sub_state <= 0;
			state <= s_inst_fetch;
		end else if (state == s_inst_fetch) begin 
			if(sub_state == 0) begin
				if(occur_intr) begin // interrupt
					state <= s_inst_inval;
				end else begin
					mem_exception_vec <= 0;
					m_axi_araddr <= pc;
					m_axi_arvalid <= 1;
					m_is_instr <= 1;
					sub_state <= 1;
				end
			end else if (sub_state == 1) begin
				if(m_axi_arready) begin
					m_axi_arvalid <= 0;
					m_axi_rready <= 1;
					sub_state <= 2;
				end
			end else if (sub_state == 2) begin
				if(m_axi_rvalid) begin
					m_axi_rready <= 0;
					instr <= m_axi_rdata;
					sub_state <= 0;
					m_is_instr <= 0;
					if(m_throw_exception) begin
						mem_exception_vec <= m_exception_vec;
						state <= s_inst_inval; // instr page fault
					end else begin
						state <= s_inst_decode;
					end
				end
			end
		end else if (state == s_inst_decode) begin
			state <= s_inst_exec;
		end else if (state == s_inst_exec) begin 
				sub_state <= 0;
				exu_exception_vec <= 0;
				if(inst.inval | inst.ecall) begin
					state <= s_inst_inval;
				end else begin
					state <= s_inst_mem;
				end
		end else if (state == s_inst_mem) begin
			if(is_load) begin // lb,lh,lw, lbu,lhu,flw
				if(sub_state == 0) begin
					m_axi_araddr <= {addr[31:2],2'b00};
					m_axi_arvalid <= 1;
					sub_state <= 1;
				end else if (sub_state == 1) begin
					if(m_axi_arready) begin
						m_axi_arvalid <= 0;
						m_axi_rready <= 1;
						sub_state <= 2;
					end
				end else if (sub_state == 2) begin // page fault!!!!!!!!!!!
					if(m_axi_rvalid) begin
						m_axi_rready <= 0;
						if(m_throw_exception) begin
							mem_exception_vec <= m_exception_vec;
						end else if(inst.lb) begin
							case(addr[1:0])
								2'b00: load_result <= {{24{m_axi_rdata[31]}},m_axi_rdata[31:24]};
								2'b01: load_result <= {{24{m_axi_rdata[23]}},m_axi_rdata[23:16]};
								2'b10: load_result <= {{24{m_axi_rdata[15]}},m_axi_rdata[15:8]};
								2'b11: load_result <= {{24{m_axi_rdata[7]}},m_axi_rdata[7:0]};
								default: mem_exception_vec <= EXCEPTION_LOAD_PG_FAULT;
							endcase
						end else if (inst.lh) begin
							case(addr[1:0])
								2'b00 : load_result <= {{16{m_axi_rdata[31]}},m_axi_rdata[31:16]};
								2'b10 : load_result <= {{16{m_axi_rdata[15]}},m_axi_rdata[15:0]};
								default: mem_exception_vec <= EXCEPTION_LOAD_PG_FAULT;
							endcase
						end else if (inst.lw | inst.flw) begin
							if(addr[1:0] == 2'b0) begin
								load_result <= m_axi_rdata;
							end else begin
								 mem_exception_vec <= EXCEPTION_LOAD_PG_FAULT;
							end
						end else if (inst.lbu) begin
							case(addr[1:0])
								2'b00: load_result <= {24'b0,m_axi_rdata[31:24]};
								2'b01: load_result <= {24'b0,m_axi_rdata[23:16]};
								2'b10: load_result <= {24'b0,m_axi_rdata[15:8]};
								2'b11: load_result <= {24'b0,m_axi_rdata[7:0]};
								default: mem_exception_vec <= EXCEPTION_LOAD_PG_FAULT;
							endcase
						end else if (inst.lhu) begin
							case(addr[1:0])
								2'b00 : load_result <= {16'b0,m_axi_rdata[31:16]};
								2'b10 : load_result <= {16'b0,m_axi_rdata[15:0]};
								default: mem_exception_vec <= EXCEPTION_LOAD_PG_FAULT;
							endcase
						end
						sub_state <= 3;
					end
				end else if (sub_state == 3) begin
					sub_state <= 0;
					if(mem_exception_vec == 0) begin
						state <= s_inst_write;
					end else begin
						state <= s_inst_inval;
					end
				end
			end else if (is_store) begin // sb,sh,sw,fsw
				if (sub_state == 0) begin
					m_axi_awaddr <= {addr[31:2],2'b00};
					m_axi_awvalid <= 1;
					m_axi_wvalid <= 1;
					if(inst.sb) begin 
						case(addr[1:0])
							2'b00 : begin 
								m_axi_wstrb <= 4'b1000;
								m_axi_wdata <= {src2[7:0],24'b0};
								end
							2'b01 : begin
								m_axi_wstrb <= 4'b0100;
								m_axi_wdata <= {8'b0,src2[7:0],16'b0};
								end
							2'b10 : begin
								m_axi_wstrb <= 4'b0010;
								m_axi_wdata <= {16'b0,src2[7:0],8'b0};
								end
							2'b11 : begin
								m_axi_wstrb <= 4'b0001;
								m_axi_wdata <= {24'b0,src2[7:0]};
								end
							default : begin
								m_axi_wstrb <= 0;
								mem_exception_vec <= EXCEPTION_STORE_PG_FAULT;
								end
						endcase	
					end else if (inst.sh) begin
						case(addr[1:0])
							2'b00 : begin
								m_axi_wstrb <= 4'b1100;
								m_axi_wdata <= {src2[15:0],16'b0};
								end
							2'b10 : begin
								m_axi_wstrb <= 4'b0011;
								m_axi_wdata <= {16'b0,src2[15:0]};
								end
							default : begin
								m_axi_wstrb <= 0;
								mem_exception_vec <= EXCEPTION_STORE_PG_FAULT;
								end
						endcase
					end else if (inst.sw | inst.fsw) begin
						if(addr[1:0] == 0) begin
							m_axi_wstrb <= 4'b1111;
							m_axi_wdata <= src2;
						end else begin
							m_axi_wstrb <= 0; 
							mem_exception_vec <= EXCEPTION_STORE_PG_FAULT;
						end
					end
					sub_state <= 1;
				end else if (sub_state == 1) begin
					if(m_axi_awready) begin
						m_axi_awvalid <= 0;
					end
					if(m_axi_wready) begin
						m_axi_wvalid <= 0;
					end
					if(!m_axi_awvalid && !m_axi_wvalid) begin
						m_axi_bready <= 1;
						sub_state <= 2;
					end
				end else if (sub_state == 2) begin // page fault!!!!!!
					if(m_axi_bvalid) begin
						m_axi_bready <= 0;
						sub_state <= 0;
						if(m_throw_exception) begin
							state <= s_inst_inval;
							mem_exception_vec <= m_exception_vec;
						end else if (mem_exception_vec != 0) begin
							state <= s_inst_inval;
						end begin
							state <= s_inst_write;
						end
					end
				end
			end else if (is_exu) begin // exu ope
				if(ex_in_valid) begin
					exu_result <= ex_result;
					if(ex_exception != 0) begin
						state <= s_inst_inval;
						exu_exception_vec <= ex_exception;
					end else begin
						state <= s_inst_write;
					end
				end
			end else begin // not mem ope
				if(csr_inval_addr | csr_unprivileged) begin
					state <= s_inst_inval;
				end else begin
					state <= s_inst_write;
				end
			end
		end else if (state == s_inst_write) begin
			if(inst.jalr) begin
				pc <= src1 + imm;
			end else if(inst.jal) begin
				pc <= pc + imm;
			end else if (inst.beq | inst.bne | inst.blt | inst.bge | inst.bltu | inst.bgeu) begin
				if(alu_result == 32'b0) begin
					pc <= pc + 32'd4;
				end else begin
					pc <= pc + imm;
				end
			end else if (inst.sret) begin
				pc <= {sepc[31:2],2'b0};
				cpu_mode <= {1'b0,sstatus[8]};
			end else begin
				pc <= pc + 32'd4;
			end
			sub_state <= 0;
			state <= s_inst_fetch;
		end else if (state == s_inst_inval) begin
			cpu_mode <= 2'b01;
			pc <= stvec[31:2];
			sub_state <= 0;
			state <= s_inst_fetch;
		end
 	end // always
       
endmodule

`default_nettype wire
