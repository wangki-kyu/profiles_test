//================================================================================
// Copyright (c) 2013 ~ 2026. HyungKi Jeong(clonextop@gmail.com)
// Freely available under the terms of the 3-Clause BSD License
// (https://opensource.org/licenses/BSD-3-Clause)
//
// Redistribution and use in source and binary forms,
// with or without modification, are permitted provided
// that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
// BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
// OF SUCH DAMAGE.
//
// Title : Virtual FPGA Starter Kit
// Rev.  : 8/26/2026 Wed (rladn)
//================================================================================
`timescale 1ns/1ns
`include "template/StarterKit/includes.svh"

module dut_top (
	input						CLK,					// clock (10MHz)
	input						nRST,					// reset (active low)
	output						INTR,					// interrupt signal (active high, edged mode)

	//// APB slave bus (base address : 0x00020000 ~ 0x0002FFFF, search keywords on google : "APB protocol filetype:pdf")
	output						S_PCLK,					// slave clock output
	output						S_PRESETn,				// slave reset (active low)
	input						S_PSEL,					// select
	input						S_PENABLE,				// enable
	input						S_PWRITE,				// write enable
	input	[15:0]				S_PADDR,				// address
	input	[31:0]				S_PWDATA,				// write data
	output	[31:0]				S_PRDATA,				// read data
	output						S_PREADY,				// ready
	output						S_PSLVERR,				// slave error

	//// AXI4 master bus (128bit narrow transfer supports, search keywords on google : "axi4 protocol filetype:pdf")
	output						M_ACLK,					// master clock
	output						M_ARESETn,				// reset (active low)
	// write address
	output						M_AWID,					// The ID tag for the write address group of signals
	output	[31:0]				M_AWADDR,				// Write address
	output	[7:0]				M_AWLEN,				// Burst_Length = AxLEN + 1
	output	[2:0]				M_AWSIZE,				// bytes in transfer b000(1:8bit), b001(2:16bit), b010(4:32bit), b011(8:64bit), b100(16:128bit), b101(32:256bit), b110(64:512bit), b111(128:1024bit)
	output	[1:0]				M_AWBURST,				// b00(FIXED), b01(INCR), b10(WRAP), b11(Reserved)
	output						M_AWLOCK,				// b0(Normal), b1(Exclusive)
	output	[3:0]				M_AWCACHE,				// [0] Bufferable, [1] Cacheable, [2] Read Allocate, [3] Write Allocate
	output	[2:0]				M_AWPROT,				// Protection level : [0] privileged(1)/normal(0) access, [1] nonesecure(1)/secure(0) access, [2] instruction(1)/data(0) access
	output	[3:0]				M_AWREGION,				// Write region identifier (not defined in this)
	output	[3:0]				M_AWQOS,				// Write Quality of Service (not defined in this)
	output						M_AWVALID,				// Write address valid
	input 						M_AWREADY,				// Write address ready (1 = slave ready, 0 = slave not ready)
	// write data
	output 						M_WID,					// Write ID tag
	output	[127:0]				M_WDATA,				// Write data
	output	[15:0]				M_WSTRB,				// Write strobes (WSTRB[n] = WDATA[(8  n) + 7:(8  n)])
	output						M_WLAST,				// Write last
	output						M_WVALID,				// Write valid
	input 						M_WREADY,				// Write ready
	// bus
	input 						M_BID,					// The ID tag for the write response
	input 	[1:0]				M_BRESP,				// b00(OKAY), b01(EXOKAY), b10(SLVERR), b11(DECERR)
	input 						M_BVALID,				// Write response valid
	output						M_BREADY,				// Response ready
	// read address
	output						M_ARID,					// Read address ID tag
	output	[31:0]				M_ARADDR,				// Read address
	output	[7:0]				M_ARLEN,				// Burst_Length = AxLEN + 1
	output	[2:0]				M_ARSIZE,				// bytes in transfer b000(1:8bit), b001(2:16bit), b010(4:32bit), b011(8:64bit), b100(16:128bit), b101(32:256bit), b110(64:512bit), b111(128:1024bit)
	output	[1:0]				M_ARBURST,				// b00(FIXED), b01(INCR), b10(WRAP), b11(Reserved)
	output						M_ARLOCK,				// b0(Normal), b1(Exclusive)
	output	[3:0]				M_ARCACHE,				// [0] Bufferable, [1] Cacheable, [2] Read Allocate, [3] Write Allocate
	output	[2:0]				M_ARPROT,				// Protection level : [0] privileged(1)/normal(0) access, [1] nonesecure(1)/secure(0) access, [2] instruction(1)/data(0) access
	input 	[3:0]				M_ARREGION,				// Read region identifier (not defined in this)
	input	[3:0]				M_ARQOS,				// Read Quality of Service (not defined in this)
	output						M_ARVALID,				// Read address valid
	input						M_ARREADY,				// Read address ready (1 = slave ready, 0 = slave not ready)
	// read data
	input 						M_RID,					// Read ID tag
	input	[127:0]				M_RDATA,				// Read data
	input	[1:0]				M_RRESP,				// Read response. b00(OKAY), b01(EXOKAY), b10(SLVERR), b11(DECERR)
	input						M_RLAST,				// Read last. This signal indicates the last transfer in a read burst.
	input						M_RVALID,				// Read valid (1 = read data available, 0 = read data not available)
	output						M_RREADY,				// Read ready (1= master ready 0 = master not ready)

	//// GPIOs
	output	[7:0]				LED_pins,				// LED pins
	output	[13:0]				KW4_56NCWB_P_Y_pins,	// Quadruple Digit Numeric Displays (Model # : KW4_56NCWB_P_Y)
	input	[7:0]				SWITCH_pins,			// toggle switch pins
	input	[8:0]				BUTTON_pins,			// buttons (active low)

	//// Motor
	output						MOTOR_PWM,				// motor PWM control
	output						MOTOR_DIR,				// motor direction
	input						MOTOR_SENSOR,			// motor hole sensor

	//// TFT LCD display
	output						TFT_PCLK,				// pixel clock
	output						TFT_DISP,				// display enable
	output						TFT_HSYNC,				// horizontal sync input in RGB mode.
	output						TFT_VSYNC,				// vertical sync input in RGB mode.
	output						TFT_DE,					// data enable
	output	[23:0]				TFT_RGB					// red/green/blue data
);

// definition & assignment ---------------------------------------------------
reg		[16:0]	t_count;
reg		[7:0]	led_data;

assign	LED_pins	= led_data;


//// APB slave bus (base address : 0x00020000 ~ 0x0002FFFF, search keywords on google : "APB protocol filetype:pdf")
/*output						S_PCLK,					// slave clock output
output						S_PRESETn,				// slave reset (active low)
input						S_PSEL,					// select
input						S_PENABLE,				// enable
input						S_PWRITE,				// write enable
input	[15:0]				S_PADDR,				// address
input	[31:0]				S_PWDATA,				// write data
output	[31:0]				S_PRDATA,				// read data
output						S_PREADY,				// ready
output						S_PSLVERR,				// slave error
 */

// ============== APB Slave Bus ================
reg [31:0] reg_addr_low;	// 0x00: DMA 물리 주소 Low
reg [31:0] reg_addr_high; 	// 0x04: DMA 물리 주소 High
reg [31:0] reg_len;			// 0x08: 전송 크기
reg [31:0] reg_ctrl;		// 0x0C: [0] Start Doorbell, [1] Read/Write 방향

/*
 //// APB slave bus (base address : 0x00020000 ~ 0x0002FFFF, search keywords on google : "APB protocol filetype:pdf")
	output						S_PCLK,					// slave clock output
	output						S_PRESETn,				// slave reset (active low)
	input						S_PSEL,					// select
	input						S_PENABLE,				// enable
	input						S_PWRITE,				// write enable
	input	[15:0]				S_PADDR,				// address
	input	[31:0]				S_PWDATA,				// write data
	output	[31:0]				S_PRDATA,				// read data
	output						S_PREADY,				// ready
	output						S_PSLVERR,				// slave error
 */

// APB 응답 기본 설정 (항상 응답 준비 완료)
assign S_PCLK = CLK;
assign S_PRESETn = nRST;
assign S_PREADY = 1'b1;	// wait state 없음
assign S_PSLVERR = 1'b0;	// 에러 없음

// AXI Master FSM으로 전달할 제어 신호
wire	dma_start = reg_ctrl[0];		// Doorbel 펄스!
wire 	dma_dir = reg_ctrl[1]; 			// 0: Read, 1: Write
wire [63:0] dma_addr = {reg_addr_high, reg_addr_low}; 	// 64-bit 결합 주소


// ============== SW -> HW (SW가 APB 주소로 쓴 데이터를 HW 레지스터에 받아 적기) =============
// SW가 APB 버스를 통해 write  트랜잭션을 일으켰을 때 감지 (Access Phase)
wire apb_write_strobe = S_PSEL & S_PENABLE & S_PWRITE;

always @(posedge CLK or negedge nRST) begin
	if (!nRST) begin
		reg_addr_low <= 32'h0;
		reg_addr_high <= 32'h0;
		reg_len 	<= 32'h0;
		reg_ctrl 	<= 32'h0;
	end
	else begin
		// Doorbell(bit[0])은 SW가 1을 쓰면 1클럭 동안만 유지되고 자동으로 0으로 해제 (One-Shot)
		if (reg_ctrl[0]) begin
			reg_ctrl[0] <= 1'b0;
		end

		// APB 버스에 쓰기 요청이 들어오면 주소 (S_PADDR)를 확인하고 데이터(S_PWDAATA)를 저장
		if (apb_write_strobe) begin
			case (S_PADDR[7:0])
				8'h00:
					reg_addr_low 	<= S_PWDATA;
				8'h04:
					reg_addr_high 	<= S_PWDATA;
				8'h08:
					reg_len 			<= S_PWDATA;
				8'h0C:
					reg_ctrl 		<= S_PWDATA;	// bit[0]에 1이 들어오는 순간 Doorbell!
				default:
					;
			endcase
		end
	end
end

// ================== HW -> SW ( SW가 APB 주소를 읽으려고 할 때 내보내주는 읽기 데이터) =====================
reg [31:0] prdata_reg;

always @(*) begin
	case (S_PADDR[7:0])
		8'h00:
			prdata_reg = reg_addr_low;
		8'h04:
			prdata_reg = reg_addr_high;
		8'h08:
			prdata_reg = reg_len;
		8'h0C:
			prdata_reg = reg_ctrl;
		8'h10:
			prdata_reg = {INTR, 31'h0}; // bit[31]로 인터럽트 상태 알려줌
		default:
			prdata_reg = 32'h0;
	endcase
end

assign S_PRDATA = prdata_reg;


// 기본 출력 핀 제어
assign TFT_PCLK = CLK;     // 10MHz 픽셀 클럭 전달
assign TFT_DISP = 1'b1;    // LCD 화면 활성화 (Active High)

// 타이밍 파라미터 정의
localparam H_ACTIVE = 480;
localparam H_FP     = 8;
localparam H_SYNC   = 4;
localparam H_BP     = 43;
localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 535

localparam V_ACTIVE = 272;
localparam V_FP     = 4;
localparam V_SYNC   = 4;
localparam V_BP     = 12;
localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 292

// 가로/세로 위치 카운터
reg [9:
	 0] h_cnt;
reg [9:
	 0] v_cnt;

always @(posedge CLK or negedge nRST) begin   // clk이 0 -> 1로 올라가는 시점이나, 리셋 신호가 1 -> 0으로 떨어지는 시점에만 실행되는 로직
	if (!nRST) begin
		h_cnt <= 10'd0;
		v_cnt <= 10'd0;
	end
	else begin
		if (h_cnt < H_TOTAL - 1) begin
			h_cnt <= h_cnt + 1'b1;
		end
		else begin
			h_cnt <= 10'd0;
			if (v_cnt < V_TOTAL - 1)
				v_cnt <= v_cnt + 1'b1;
			else
				v_cnt <= 10'd0;
		end
	end
end

// 제어 신호 생성
assign TFT_DE    = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
assign TFT_HSYNC = ~((h_cnt >= H_ACTIVE + H_FP) && (h_cnt < H_ACTIVE + H_FP + H_SYNC));
assign TFT_VSYNC = ~((v_cnt >= V_ACTIVE + V_FP) && (v_cnt < V_ACTIVE + V_FP + V_SYNC));

// 테스트 패턴 (Red, Green, Blue 3색 컬러바)
assign TFT_RGB = (TFT_DE) ? (
	(h_cnt < 160) ? 24'hFF0000 : // 왼쪽: Red
	(h_cnt < 320) ? 24'h00FF00 : // 중간: Green
	24'h0000FF   // 오른쪽: Blue
) : 24'h000000;


// implementation ------------------------------------------------------------
/*always@(posedge CLK) begin
if(!nRST) begin
	t_count		<= 'd0;
	led_data	<= 'd0;
 
end
else begin
	t_count		<= t_count + 1'b1;
	if (t_count == 'd0) begin
		led_data	<= led_data + 1'b1;
	end
end
end*/

endmodule
