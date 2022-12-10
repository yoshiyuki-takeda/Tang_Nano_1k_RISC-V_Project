// Tang Nano 1kに収めるRISC-Vプロセッサ
//
// うどん粉コア Version　01　
// RISC-VコアのABI : RV32I
//
// Copyright 2022 竹田 良之
//
// ライセンス
// ソースコード形式かバイナリ形式か、変更するかしないかを問わず、以下の条件を満たす場合に限り、再頒布および使用が許可されます。
// 1. ソースコードを再頒布する場合、上記の著作権表示、本条件一覧、および下記免責条項を含めること。
// 2. バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、上記の著作権表示、本条件一覧、および下記免責条項を含めること。
// 本ソフトウェアは、著作権者およびコントリビューターによって「現状のまま」提供されており、明示黙示を問わず、商業的な使用可能性、
// および特定の目的に対する適合性に関する暗黙の保証も含め、またそれに限定されない、いかなる保証もありません。
// 著作権者もコントリビューターも、事由のいかんを問わず、 損害発生の原因いかんを問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失その他の）不法行為であるかを問わず、
// 仮にそのような損害が発生する可能性を知らされていたとしても、本ソフトウェアの使用によって発生した（代替品または代用サービスの調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそれに限定されない）
// 直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、または結果損害について、一切責任を負わないものとします。
//

/* RV32I CPU コア */
module rv32core_udonkoA( input wire reset,clk,NMI_S,INT_S , input wire [31:0] inst_data , in_data , 
							 output wire [31:0] inst_addr , data_addr , out_data , output wire dwe , output wire [1:0] Awidth,
							 output wire [14:0] outcode );
	parameter RESET_VECTOR = 16'h0000;
	parameter NMI_VECTOR = 32'h0060_0230;
	parameter INT_VECTOR = 32'h0000_0040; /* 割り込み使用時は割り込みのエントリポイントのアドレスへ変更する */

	wire [31:0] inst;
	wire [4:0] rd,rs1,rs2;
	wire [4:0] code_sysb;
	wire [2:0] funct3;
	wire [6:0] op,funct7;

	wire CODE_LUI ,CODE_AUIPC,CODE_JAL  ,CODE_JALR   ,CODE_BRCH ,CODE_LOAD,CODE_STORE;
	wire CODE_ALUI,CODE_ALUR ,CODE_FENCE,CODE_FENCEI,CODE_ECALL,CODE_EBRK,CODE_MRET ,CODE_CSR;
	wire code_sys,compliment,Load_sub,sft,sft_lr,as,f7i,ALU_sub,csr_imac;
	wire [1:0] BRCH_sub,ACC_Width,CSR_sub;
	
	assign inst = inst_data;
	assign { funct7  , rs2  , rs1 , funct3  , rd , op } = inst;
	assign code_sys = ({inst[31:30],inst[27:23],inst[19:7],op}==27'b0000000000_0000000000_1110011);
	assign code_sysb= {inst[29:28],inst[22:20]};

	assign BRCH_sub[1:0] = funct3[2:1];		//分岐条件
	assign compliment = funct3[0];		//分岐補数
	assign ACC_Width[1:0] = funct3[1:0];		//メモリアクセス幅
	assign Load_sub = ~funct3[2];			//ロード符号拡張
	assign ALU_sub = funct7[5];									//0:加算、論理右シフト 1:減算、算術右シフト
	assign f7i = ( {funct7[6],funct7[4:0]} == 6'd0 );		//
	assign sft = ( funct3[1:0] == 2'b01 );						//シフト演算
	assign sft_lr = funct3[2];
	assign as = ( (funct3==3'b101) || (funct3==3'b000) );	//加減算と右シフト
	assign CSR_sub[1:0] = funct3[1:0];			//CSRアクセス方法
	assign csr_imac = funct3[2];			//0:レジスタ 1:即値

	assign CODE_LUI   = (op==7'b0110111);
	assign CODE_AUIPC = (op==7'b0010111);
	assign CODE_JAL   = (op==7'b1101111);
	assign CODE_JALR  = (op==7'b1100111) & (funct3 == 3'b000);
	assign CODE_BRCH  = (op==7'b1100011) & (funct3[2:1]!=2'b01); 
	assign CODE_LOAD  = (op==7'b0000011) & (funct3[1:0]!=2'b11);
	assign CODE_STORE = (op==7'b0100011) & (funct3[1:0]!=2'b11) & (~funct3[2]) ;
	assign CODE_ALUI  = (op==7'b0010011) & ( ~sft | ( sft & f7i & ( funct3[2] | (~(funct3[2]|ALU_sub)) ) ) );
	assign CODE_ALUR  = (op==7'b0110011) & (  f7i & ( as | (~(as|ALU_sub)) ) );
	assign CODE_FENCE = (op==7'b0001111) & (funct3==3'b000);
	assign CODE_FENCEI= (op==7'b0001111) & (funct3==3'b001);
	assign CODE_ECALL = code_sys & (code_sysb==5'b00000);
	assign CODE_EBRK  = code_sys & (code_sysb==5'b00001);
	assign CODE_MRET  = code_sys & (code_sysb==5'b11010);
	assign CODE_CSR   = (op==7'b1110011) & (funct3[1:0]!=2'b00);
	
	assign outcode = { CODE_CSR, /*CODE_WFI,*/ CODE_MRET, CODE_EBRK, CODE_ECALL, CODE_FENCEI ,CODE_FENCE, CODE_ALUR, CODE_ALUI,
									CODE_STORE, CODE_LOAD, CODE_BRCH, CODE_JALR, CODE_JAL ,CODE_AUIPC, CODE_LUI} ; //----------------------- no need

	wire [31:0] I_imm, B_imm, U_imm, J_imm, csr_imm;
	wire [4:0] S_imm;
	wire [11:0] csr_addr;

	assign I_imm = { { 21{inst[31]} } , { inst[30:20] } };
	assign S_imm = inst[11:7] ;
	assign B_imm = { { 20{inst[31]} } , {inst[7]} , {inst[30:25]} , {inst[11:8]} , {1'b0} };
	assign U_imm = { inst[31:12] , 12'h000 };
//	assign J_imm = { { 12{inst[31]} } , {inst[19:12]} , {inst[20]} , { inst[30:21] } , {1'b0} };
	assign J_imm = { { 14{inst[31]} }  , {inst[31]} , {inst[16:12]} , {inst[20]} , { inst[30:21] } , {1'b0} };
	assign csr_imm		= { 27'd0 , inst[19:15] };
	assign csr_addr	= inst[31:20];

	reg [31:0] x1,x2;
	reg [31:0] shiftr;
	reg [15:0] pc;
	reg [2:0]  stg; // 0:pc set 1:
	wire [31:0] xd,logic_op,ALU_out,s2,lms[3:0],xd_sel[3:0],alu_sel[3:0];
	wire [31:0] sel_p[7:0];
	wire [4:0] x2xd,x1xd;
	wire we_reg,stillshift,except_en;
	wire [1:0] xd_sn;

	reg MIE_bit,MPIE_bit,MEIE_bit,NMIE_bit;
	reg [31:0] csr_value;
	wire [31:0] csr_nn;
	wire [31:0] csr_sel;
	wire san = (csr_addr[11:8] == 4'd3) ;
	wire yon = (csr_addr[7:4] == 4'd4);
	wire we_csr = CODE_CSR&(stg==3'd4);
	wire int_en = MIE_bit & MEIE_bit & INT_S ;
	wire NMI_int_en = NMIE_bit & NMI_S ;
	wire Jump_e = (NMI_int_en|except_en|int_en);
	wire e_DataAddrMiss = (CODE_LOAD|CODE_STORE)&(stg>=3'd2)&( (Awidth[0]&data_addr[0]) | (Awidth[1]&(data_addr[0]|data_addr[1])) );
	wire e_Inst = ~(|outcode) ;
	wire [4:0] Ecode = ((reset==1'b0)|NMI_int_en)? 5'd31 : (int_en|CODE_ECALL)? 5'd11 : (e_Inst)? 5'd2 : 
							 (CODE_EBRK)? 5'd3: (e_DataAddrMiss)? ( (CODE_LOAD)? 5'd4 : 5'd6) : 5'd0  ;

	//汎用レジスタの処理
	assign lms[2'd0] = { {24{Load_sub&in_data[7]}} ,{in_data[7:0]}  };
	assign lms[2'd1] = { {16{Load_sub&in_data[15]}},{in_data[15:0]} };
	assign lms[2'd2] = in_data;
	assign lms[2'd3] = in_data;

	assign alu_sel[2'h0] = (ALU_sub&CODE_ALUR) ? x1-s2 : x1+s2;
	assign alu_sel[2'h1] = shiftr;
	assign alu_sel[2'h2] = $signed(x1)<$signed(s2);
	assign alu_sel[2'h3] = x1<s2;

	reg [4:0] q;
	assign stillshift = ( q > 0 );
	always @( posedge clk or negedge sft ) begin
		if( sft == 1'b0 ) begin
				shiftr <= 0;
				q <= 5'd0;
		end
		else begin
			if( (CODE_ALUR|CODE_ALUI)&sft&(stg==3'd2) ) begin
				shiftr <= x1;
				q <= s2[4:0];
			end
			if( stillshift ) begin
				shiftr <= (sft_lr)? { ALU_sub&shiftr[31] , shiftr[31:1] } : { shiftr[30:0] , 1'b0 } ;
				q <= q - 5'd1;
			end
		end
	end
	
	generate
		genvar i;
		for( i = 0 ; i <= 31 ; i = i + 1 )
		begin : gen_LUT4exec
			assign s2[i] = LUT_sel_or( CODE_ALUI , x2[i] , I_imm[i]  , 1'b0 );
			assign logic_op[i] = LUT_and_or_xor_z( funct3[1:0] , x1[i] , s2[i] );
			assign ALU_out[i]  = LUT_sel_or( funct3[2] , alu_sel[ funct3[1:0] ][i] , shiftr[i] , logic_op[i] );
			
			assign csr_sel[i] = LUT_sel_or( csr_imac , x1[i] , csr_imm[i] , 1'b0 ); //(csr_imac)? x1[i] : csr_imm[i];
			assign csr_nn[i]  = LUT_csr_v( CSR_sub , csr_sel[i] , csr_value[i] );
		end
	endgenerate
	
	function LUT_sel_or( input sel12 , sel1 , sel2a , sel2b );
		casex( {sel12 , sel1 , sel2a , sel2b} )
			4'b0_0_xx : LUT_sel_or = 1'b0 ;
			4'b0_1_xx : LUT_sel_or = 1'b1 ;

			4'b1_x_00 : LUT_sel_or = 1'b0 ;
			4'b1_x_01 : LUT_sel_or = 1'b1 ;
			4'b1_x_10 : LUT_sel_or = 1'b1 ;
			4'b1_x_11 : LUT_sel_or = 1'b1 ;
			
			  default : LUT_sel_or = 1'b0 ;
		endcase
	endfunction
	
	function LUT_and_or_xor_z( input [1:0]opa ,input in1 ,input in2 );
		case( { opa[1:0] , in1 , in2 } )
			/* 排他的論理和 */
			4'b00_00 : LUT_and_or_xor_z = 1'd0 ;
			4'b00_01 : LUT_and_or_xor_z = 1'd1 ;
			4'b00_10 : LUT_and_or_xor_z = 1'd1 ;
			4'b00_11 : LUT_and_or_xor_z = 1'd0 ;
			/* 論理和 */
			4'b10_00 : LUT_and_or_xor_z = 1'd0 ;
			4'b10_01 : LUT_and_or_xor_z = 1'd1 ;
			4'b10_10 : LUT_and_or_xor_z = 1'd1 ;
			4'b10_11 : LUT_and_or_xor_z = 1'd1 ;
			/* 論理積 */
			4'b11_00 : LUT_and_or_xor_z = 1'd0 ;
			4'b11_01 : LUT_and_or_xor_z = 1'd0 ;
			4'b11_10 : LUT_and_or_xor_z = 1'd0 ;
			4'b11_11 : LUT_and_or_xor_z = 1'd1 ;
			/* その他 */
			 default : LUT_and_or_xor_z = 1'd0 ;
		endcase
	endfunction
	
	assign xd_sel[2'd3] = lms[ACC_Width];
	assign xd_sel[2'd2] = ALU_out;
	assign xd_sel[2'd1] = csr_nn;
	assign xd_sel[2'd0] = ( (stg==3'd7)? { NMI_S|INT_S , 26'd0, Ecode} : ((stg!=3'd6)&CODE_LUI)? 0 : {14'd0,pc,2'd0}) + ((stg>=3'd6) ? 0 : (CODE_AUIPC|CODE_LUI) ? U_imm : 4 ) ;
	
	assign xd_sn = ((stg==3'd6)|(stg==3'd7))? 2'd0 : (CODE_LOAD)? 2'd3 : (CODE_ALUR|CODE_ALUI)? 2'd2 : (CODE_CSR)? 2'd1 :  2'd0;
	assign xd = xd_sel[xd_sn];

	assign x2xd = ( stg <= 3'd3 ) ? rs2 : rd ;
	assign we_reg = ( stg == 3'd4 )&(CODE_LOAD|CODE_ALUR|CODE_ALUI|CODE_AUIPC|CODE_LUI|CODE_JALR|CODE_JAL) ;
	wire [5:0] reg2addr =  (stg==3'd7)? 6'h22  : (stg==3'd6) ? 6'h21 : { CODE_CSR , (CODE_CSR) ? {1'd0,csr_addr[3:0]} : x2xd };
	wire reg2en = (we_reg&(x2xd!=5'd0)) || ( we_csr&san&yon&(csr_addr[3:0]<=4'd2) ) || (stg>=3'd6) ;

	assign x1xd = ( we_csr ) ? rd : rs1 ;
	wire [5:0] reg1addr = { CODE_MRET , (CODE_MRET)? 5'd1:x1xd };
	wire reg1en = we_csr&(x1xd!=5'd0);
	
    	reg [31:0] greg[0:35];

    	always @(posedge clk) begin
            x1 <= greg[reg1addr];
            if(reg1en)
                greg[reg1addr] <= csr_value;
    	end
    	always @(posedge clk) begin
            x2 <= greg[reg2addr];
            if(reg2en)
                greg[reg2addr] <= xd;
	    end

	integer k; //レジスタ初期化
	initial begin
	    for( k=0 ; k<36 ; k=k+1 )
		greg[k] = 32'd0;
	end
	
	//メモリアクセスの処理
	assign data_addr = x1 + { { I_imm[31:5] } , { (CODE_LOAD) ? I_imm[4:0] : S_imm[4:0] } } ;
	assign Awidth = ACC_Width;
	assign out_data = x2;
	assign dwe = CODE_STORE & (stg==3'd4);
	
	//プログラムカウンタの処理
	wire cndtn[3:0];
	assign cndtn[2'b00] = x1 == x2;
	assign cndtn[2'b01] = compliment;
	assign cndtn[2'b10] = alu_sel[2'd2][0];
	assign cndtn[2'b11] = alu_sel[2'd3][0];
	wire BRANCH_T = CODE_BRCH&(cndtn[BRCH_sub] != compliment ) ;

	wire [2:0] sel_pc =	(stg==3'd7) ? ( (NMI_int_en)? 3'd7 : //NMI
																		3'd6): //interrupt/except
								(CODE_MRET) ? 3'd5: //MRET
								(CODE_JALR) ? 3'd1: //x + i
								(CODE_JAL)  ? 3'd2: //jump
								(BRANCH_T)  ? 3'd0: //branch
												  3'd4; //pc+4
	assign sel_p[3'd0] = B_imm[31:0];
	assign sel_p[3'd1] = I_imm[31:0];
	assign sel_p[3'd2] = J_imm[31:0];
	assign sel_p[3'd3] = 32'dx;
	assign sel_p[3'd4] = 32'd4;
	assign sel_p[3'd5] = 32'd0;
	assign sel_p[3'd6] = INT_VECTOR;
	assign sel_p[3'd7] = NMI_VECTOR;

	assign inst_addr = {14'd0,pc,2'd0};
	wire [31:0] pc_calc = ( (stg==3'd7) ? 32'd0 : ((CODE_JALR|CODE_MRET) ? x1[31:0] : {14'd0,pc,2'd0})) + sel_p[sel_pc];
	always @( posedge clk or negedge reset ) begin
		if( ~reset )
			pc <= RESET_VECTOR;
		else
		begin
			if( (stg == 3'd4) || stg == 3'd7 )
				pc <= pc_calc[17:2];
		end
	end

	//パイプラインのステージ処理
	always @( posedge clk or negedge reset ) begin
		if( ~reset )
			stg <= 3'd0;
		else begin
			if( stg == 3'd4 )
				stg <= 3'd0;
			else
				stg <= ( (Jump_e&((stg==3'd1)|(stg==3'd2)|(stg==3'd3)))? 3'd5 : stg ) + ( ( (~Jump_e)&stillshift ) ? 3'd0 : 3'd1 );
		end
	end

	/*CSR処理*/
	//reg [31:0] mscratch;
	//reg  [7:0] Ecode;
	wire zero= (csr_addr[7:4] == 4'd0);

	assign except_en = e_Inst | e_DataAddrMiss | CODE_ECALL | CODE_EBRK;
	
	function LUT_csr_v( input [1:0] sf , input  chg , org );
		case( {sf , chg , org} )
			// 元の値のまま
			4'b00_00 : LUT_csr_v = 1'b0;
			4'b00_01 : LUT_csr_v = 1'b1;
			4'b00_10 : LUT_csr_v = 1'b0;
			4'b00_11 : LUT_csr_v = 1'b1;
			// 上書き
			4'b01_00 : LUT_csr_v = 1'b0;
			4'b01_01 : LUT_csr_v = 1'b0;
			4'b01_10 : LUT_csr_v = 1'b1;
			4'b01_11 : LUT_csr_v = 1'b1;
			// ビットセット
			4'b10_00 : LUT_csr_v = 1'b0;
			4'b10_01 : LUT_csr_v = 1'b1;
			4'b10_10 : LUT_csr_v = 1'b1;
			4'b10_11 : LUT_csr_v = 1'b1;
			// ビットクリア
			4'b11_00 : LUT_csr_v = 1'b0;
			4'b11_01 : LUT_csr_v = 1'b1;
			4'b11_10 : LUT_csr_v = 1'b0;
			4'b11_11 : LUT_csr_v = 1'b0;
		endcase
	endfunction

	always @(*) begin
		if( san ) begin
			case( csr_addr[7:0] )
				8'h00 : csr_value = { 19'd0,2'b11,3'd0,MPIE_bit,3'd0,MIE_bit,3'd0 }; // mstatus		Machine status register.
				8'h01 : csr_value = { 2'b01 , 4'b0000 , 26'b00_0000_0000_0000_0001_0000_0000 };  // misa		ISA and extensions
				8'h04 : csr_value = { 20'd0 , MEIE_bit , 11'd0 }; // mie			Machine interrupt-enable register.
				8'h05 : csr_value = INT_VECTOR; // mtvec			Machine trap-handler base address.
				8'h40 : csr_value = x2;//mscratch; // mscratch		Scratch register for machine trap handlers.
				8'h41 : csr_value = x2;//{mepc , 2'b00 }; // mepc			Machine exception program counter.
				8'h42 : csr_value = x2;//{ mc_Int , 23'd0 , Ecode } ; // mcause		Machine trap cause.
			//	8'h44 : csr_value = { 20'd0 , MEIP_bit , 11'd0 }; // mip Machine interrupt pending.
				8'h44 : csr_value = { 20'd0 , INT_S , 11'd0 }; // mip Machine interrupt pending.
				default : csr_value = 32'd0;
			endcase
		end
		else
			csr_value = 32'd0;
	end

	always @(posedge clk or negedge reset) begin
		if( reset == 1'b0 ) begin
			MIE_bit <= 1'd0;
			MPIE_bit <= 1'd0;
			MEIE_bit <= 1'd0;
			NMIE_bit <= 1'd1;
		end
		else begin
			if( stg == 3'd7 ) begin
				if(NMI_int_en) NMIE_bit <=1'd0;
				if(Jump_e) MPIE_bit <= MIE_bit;
				if(Jump_e) MIE_bit <= 1'd0;
			end
			if( CODE_MRET&(stg==3'd4) ) begin
				NMIE_bit <= 1'd1;
				MIE_bit <= MPIE_bit;
				MPIE_bit <= 1'd1;
			end
			if( we_csr&san&zero & ( csr_addr[3:0] == 4'd0 ) ) { MPIE_bit , MIE_bit } <= { csr_nn[7], csr_nn[3] }; // mstatus		Machine status register.
			if( we_csr&san&zero & ( csr_addr[3:0] == 4'h4 ) ) MEIE_bit <= csr_nn[11]; // mie			Machine interrupt-enable register.
		end
	end

endmodule


/* メインメモリ */
module EXT_RAM( input wire [31:0] d2, addr1 , addr2 , input wire clk, we, reset , 
                output wire [31:0] q1 , q2 );
	reg [31:0] md1,md2;
	wire [31:0] din2;
	wire we2;
	wire [9:0] ad1,ad2;
	reg [31:0] mem[0:1023];

	assign q1 = md1;
	assign q2 = md2;
	assign we2 = we;
	assign din2 = d2;
	assign ad1 = addr1[11:2];
	assign ad2 = addr2[11:2];
	
	always @(posedge clk) begin
		md1 <= mem[ ad1 ];
		md2 <= mem[ ad2 ];
		if( we2 )begin
			mem[ ad2 ] <= din2;
		end
	end

	//初期化 	
	initial begin	
		$readmemh("mem.hex", mem); /* mem.hexを入れ替えて、様々なサンプルをご利用ください。 */
	end

endmodule

/* 複合ペリフェラル */
module Super_IO ( input wire clk,reset ,  input wire we , input wire [31:0] addr,
						input wire [31:0] indata , output reg [31:0] outdata , 
						output wire timer_out , timer_int ,
						input wire sw1,sw2,
						output wire [2:0] RGB_LED,
						output wire [20:0] LCD
						);
parameter WIDTH = 16;
parameter PRIOD_WIDTH = 15;
//parameter PRIOD_WIDTH = 5;
// tang nano 1k = 27MHz
	reg [WIDTH-1:0] tmr_reg;
	reg [WIDTH-1:0] rld_reg;
	reg tmr_en,tmr_IE,tmr_int,tmr_tgl;
	wire tmr_int_rst = we&(~addr[4])&addr[3]&(~addr[2])&indata[2];
	wire tmr_reload = tmr_reg == { WIDTH{1'b0} };
	
	reg [17:0] LCD_bit;
	wire [2:0] LCD_com = 3'd0;
	reg [PRIOD_WIDTH-1:0] LCD_tgl_period;
	reg [2:0] LED_out;

	/* LCDドライバ */
	always @(posedge clk or negedge reset ) begin
		if( ~reset ) begin
			LCD_tgl_period <= {(PRIOD_WIDTH){1'b0}};
		end
		else begin
			LCD_tgl_period <= LCD_tgl_period + { {(PRIOD_WIDTH-1){1'b0}}, {1'b1} };
		end
	end
	assign LCD = { LCD_com , LCD_bit } ^ { 21{LCD_tgl_period[PRIOD_WIDTH-1]} };

	assign RGB_LED = LED_out;// LED output

	/* コントロール・ステータスレジスタ読み書き */
	always @(*) begin
		case( addr[4:2] )
			3'd0 : outdata <= { {(32-WIDTH){1'bx}} , rld_reg };  //  タイマリロードレジスタ
			3'd1 : outdata <= { {(32-WIDTH){1'bx}} , tmr_reg };  //　タイマカウントレジスタ
			3'd2 : outdata <= { {(32-2){1'bx}} , {  tmr_IE , tmr_en  } }; // タイマ割込み許可ビット、タイマ動作許可ビット
			3'd3 : outdata <= { {(32-2){1'bx}} , { tmr_tgl , tmr_int } }; // 

			3'd4 : outdata <= { {(32-18){1'bx}} , { LCD_bit } };  // LCDドライバ出力
			3'd5 : outdata <= { {(32-2){1'bx}} , { sw2 , sw1 } }; // GPIO スイッチ入力
			3'd6 : outdata <= { {(32-3){1'bx}} , { LED_out } };   // GPIO ３色LED
			default : outdata <= 32'dx;
		endcase
	end
	
	always @( posedge clk or negedge reset ) begin
		if( ~reset ) begin
			rld_reg <= { WIDTH{1'b1} };
			tmr_en <= 1'b0;
			tmr_IE <= 1'b0;
			LCD_bit <= 18'd0;
			LED_out <= 3'b111;
		end
		else begin
			if( we ) begin
				case ( addr[4:2] )
					3'd0 : rld_reg <= indata[WIDTH-1:0];
					3'd2 : {tmr_IE , tmr_en} <= indata[1:0];
					3'd4 : LCD_bit <= indata[17:0];
					3'd6 : LED_out <= indata[2:0];
				endcase
			end
		end
	end

	/* タイマ操作 */
	assign timer_out = tmr_tgl;
	assign timer_int = tmr_int;

	always @( posedge clk or negedge reset ) begin
		if( ~reset ) begin
			tmr_reg <= { WIDTH{1'b1} };
		end
		else begin
			if( ~tmr_en | tmr_reload  ) 
				tmr_reg <= rld_reg ;
			else
				tmr_reg <= tmr_reg - { { (WIDTH-1){1'b0} } , {1'b01} } ;
		end
	end

	always @( posedge clk or negedge reset ) begin
		if( ~reset ) begin
			tmr_tgl <= 1'b0;
		end
		else begin
			if( tmr_reload ) tmr_tgl <= ~tmr_tgl;
		end
	end

	always @( posedge clk or negedge reset ) begin
		if( ~reset ) begin
			tmr_int <= 1'b0;
		end
		else if( tmr_IE & tmr_reload ) begin 
			tmr_int <= 1'b1;
		end
		else if(tmr_int_rst) begin
			tmr_int <= 1'b0;
		end 
	end

endmodule


module bus_master( input wire [31:0] dataFp1,dataFp2 ,addrbus, dataFromCpu ,
						 output wire [31:0] data2cpu , data2pri ,
						 input wire [1:0] bw  ,input wire we, output wire cs1,cs2 );
// addr : 32'h0000_0000 - 32'h0000_0fff as RAM
// addr : 32'h0001_0000 - 32'h0001_001f as Super_IO

	reg  [31:0] data_choice;
	wire [7:0] qq2[3:0];
	wire [7:0] dd2[3:0];

	wire chk1 = (addrbus[31:12] == 20'd0); // メインメモリ
	wire chk2 = (addrbus[31:5]  == 27'h000_0800); // 複合ペリフェラル

	assign {qq2[3],qq2[2],qq2[1],qq2[0]} = data_choice;
	assign data2cpu[7:0] = qq2[addrbus[1:0]];
	assign data2cpu[15:8] = addrbus[1] ? qq2[3] : qq2[1];
	assign data2cpu[31:16] = {qq2[3],qq2[2]};
 	
	assign { dd2[3],dd2[2],dd2[1],dd2[0] } = dataFromCpu;
	assign data2pri = wdata( bw , addrbus[1:0] , dd2[0],dd2[1],dd2[2],dd2[3], qq2[0],qq2[1],qq2[2],qq2[3] );

	function [31:0] wdata ( input [1:0] acc_width , addr10 , input [7:0] idd0,idd1,idd2,idd3 , iqq0,iqq1,iqq2,iqq3 );
		case( acc_width )
			2'd0 : begin
					case(addr10)
						2'd0 : wdata = { iqq3,iqq2,iqq1,idd0 } ;
						2'd1 : wdata = { iqq3,iqq2,idd0,iqq0 } ;
						2'd2 : wdata = { iqq3,idd0,iqq1,iqq0 } ;
						2'd3 : wdata = { idd0,iqq2,iqq1,iqq0 } ;
					endcase
				end
			2'd1 : begin 
				case(addr10[1])
						1'd0 : wdata = { iqq3,iqq2,idd1,idd0 } ;
						1'd1 : wdata = { idd1,idd0,iqq1,iqq0 } ;
					endcase
				end
			2'd2 : wdata = { idd3,idd2,idd1,idd0 };
			2'd3 : wdata = { iqq3,iqq2,iqq1,iqq0 };
		endcase
	endfunction

	assign cs1 = we & chk1;
	assign cs2 = we & chk2;
	
	always @(*) begin
		case( { chk2,chk1 } )
			2'b01 : data_choice <= dataFp1;
			2'b10 : data_choice <= dataFp2;
			default : data_choice <= 32'dx;
		endcase
	end
endmodule


module Soc( input wire clock , reset , sw1 ,
				output wire [2:0] FullColor_LED );

	wire	[31:0]	read_data1,read_data2;
	wire				we1,we2,INT_S;
	wire	[31:0]	inst_addr,inst_data;
	wire	[31:0]	data_addr,read_data,write_data,pri_data;
	wire				write_enable;
	wire	[1:0]		data_width;
	wire	[14:0]	opecode;

    wire    tgl_out;
    wire    [2:0] LED_wrapper;

    assign  FullColor_LED[2:0] = LED_wrapper[2:0];
				
	rv32core_udonkoA cpu1( .reset(reset), .clk(clock) , .NMI_S(1'b0) , .INT_S(INT_S) , 
			  .inst_addr(inst_addr) , .inst_data(inst_data) ,  
			   .data_addr(data_addr) , .in_data(read_data) , .out_data(write_data) ,
			  .dwe(write_enable) , .Awidth(data_width),
			  .outcode(opecode) );
			  
	bus_master bm1( .addrbus(data_addr) , .data2pri(pri_data) , .dataFromCpu( write_data ) ,
						 .data2cpu(read_data), .dataFp1(read_data1), .dataFp2(read_data2), 
						 .bw(data_width), .we(write_enable), .cs1(we1), .cs2(we2) );
						 
	EXT_RAM ram1(	.clk(clock) , .reset(reset) ,
						.addr1(inst_addr) ,
						.q1(inst_data) ,
						.addr2(data_addr) , 
						.d2(pri_data),
						.q2(read_data1),
						.we(we1)  );

	Super_IO pripheral1(	.clk(clock),
								.reset(reset) ,
								.addr(data_addr) ,
								.indata(pri_data) ,
								.outdata(read_data2) , 
								.we(we2) ,
								.timer_out(tgl_out) , .timer_int(INT_S) ,
								.sw1(sw1),.sw2(1'b0),
								.RGB_LED(LED_wrapper),
								.LCD()	);
endmodule
