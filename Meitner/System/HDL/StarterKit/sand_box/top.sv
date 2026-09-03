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
// Rev.  : 9/3/2026 Thu (Woojun)
//================================================================================
`timescale 1ns/1ns
`include "template/StarterKit/includes.svh"
`include "library/SRAM_Dual_Distributed.sv"
`include "library/FiFo.sv"

module dut_top (
		input                  CLK,               // clock (10MHz)
		input                  nRST,               // reset (active low)
		output                  INTR,               // interrupt signal (active high, edged mode)

		//// APB slave bus (base address : 0x00020000 ~ 0x0002FFFF, search keywords on google : "APB protocol filetype:pdf")
		output                  S_PCLK,               // slave clock output
		output                  S_PRESETn,            // slave reset (active low)
		input                  S_PSEL,               // select
		input                  S_PENABLE,            // enable
		input                  S_PWRITE,            // write enable
		input   [15:0]            S_PADDR,            // address
		input   [31:0]            S_PWDATA,            // write data
		output   [31:0]            S_PRDATA,            // read data
		output                  S_PREADY,            // ready
		output                  S_PSLVERR,            // slave error

		//// AXI4 master bus (128bit narrow transfer supports, search keywords on google : "axi4 protocol filetype:pdf")
		output                  M_ACLK,               // master clock
		output                  M_ARESETn,            // reset (active low)
		// write address
		output                  M_AWID,               // The ID tag for the write address group of signals
		output   [31:0]            M_AWADDR,            // Write address
		output   [7:0]            M_AWLEN,            // Burst_Length = AxLEN + 1
		output   [2:0]            M_AWSIZE,            // bytes in transfer b000(1:8bit), b001(2:16bit), b010(4:32bit), b011(8:64bit), b100(16:128bit), b101(32:256bit), b110(64:512bit), b111(128:1024bit)
		output   [1:0]            M_AWBURST,            // b00(FIXED), b01(INCR), b10(WRAP), b11(Reserved)
		output                  M_AWLOCK,            // b0(Normal), b1(Exclusive)
		output   [3:0]            M_AWCACHE,            // [0] Bufferable, [1] Cacheable, [2] Read Allocate, [3] Write Allocate
		output   [2:0]            M_AWPROT,            // Protection level : [0] privileged(1)/normal(0) access, [1] nonesecure(1)/secure(0) access, [2] instruction(1)/data(0) access
		output   [3:0]            M_AWREGION,            // Write region identifier (not defined in this)
		output   [3:0]            M_AWQOS,            // Write Quality of Service (not defined in this)
		output                  M_AWVALID,            // Write address valid
		input                   M_AWREADY,            // Write address ready (1 = slave ready, 0 = slave not ready)
		// write data
		output                   M_WID,               // Write ID tag
		output   [127:0]            M_WDATA,            // Write data
		output   [15:0]            M_WSTRB,            // Write strobes (WSTRB[n] = WDATA[(8  n) + 7:(8  n)])
		output                  M_WLAST,            // Write last
		output                  M_WVALID,            // Write valid
		input                   M_WREADY,            // Write ready
		// bus
		input                   M_BID,               // The ID tag for the write response
		input    [1:0]            M_BRESP,            // b00(OKAY), b01(EXOKAY), b10(SLVERR), b11(DECERR)
		input                   M_BVALID,            // Write response valid
		output                  M_BREADY,            // Response ready
		// read address
		output                  M_ARID,               // Read address ID tag
		output   reg [31:0]         M_ARADDR,            // Read address
		output   [7:0]            M_ARLEN,            // Burst_Length = AxLEN + 1
		output   [2:0]            M_ARSIZE,            // bytes in transfer b000(1:8bit), b001(2:16bit), b010(4:32bit), b011(8:64bit), b100(16:128bit), b101(32:256bit), b110(64:512bit), b111(128:1024bit)
		output   [1:0]            M_ARBURST,            // b00(FIXED), b01(INCR), b10(WRAP), b11(Reserved)
		output                  M_ARLOCK,            // b0(Normal), b1(Exclusive)
		output   [3:0]            M_ARCACHE,            // [0] Bufferable, [1] Cacheable, [2] Read Allocate, [3] Write Allocate
		output   [2:0]            M_ARPROT,            // Protection level : [0] privileged(1)/normal(0) access, [1] nonesecure(1)/secure(0) access, [2] instruction(1)/data(0) access
		input    [3:0]            M_ARREGION,            // Read region identifier (not defined in this)
		input   [3:0]            M_ARQOS,            // Read Quality of Service (not defined in this)
		output   reg               M_ARVALID,            // Read address valid
		input                  M_ARREADY,            // Read address ready (1 = slave ready, 0 = slave not ready)
		// read data
		input                   M_RID,               // Read ID tag
		input   [127:0]            M_RDATA,            // Read data
		input   [1:0]            M_RRESP,            // Read response. b00(OKAY), b01(EXOKAY), b10(SLVERR), b11(DECERR)
		input                  M_RLAST,            // Read last. This signal indicates the last transfer in a read burst.
		input                  M_RVALID,            // Read valid (1 = read data available, 0 = read data not available)
		output                  M_RREADY,            // Read ready (1= master ready 0 = master not ready)

		//// GPIOs
		output   [7:0]            LED_pins,            // LED pins
		output   [13:0]            KW4_56NCWB_P_Y_pins,   // Quadruple Digit Numeric Displays (Model # : KW4_56NCWB_P_Y)
		input   [7:0]            SWITCH_pins,         // toggle switch pins
		input   [8:0]            BUTTON_pins,         // buttons (active low)

		//// Motor
		output                  MOTOR_PWM,            // motor PWM control
		output                  MOTOR_DIR,            // motor direction
		input                  MOTOR_SENSOR,         // motor hole sensor

		//// TFT LCD display
		output                  TFT_PCLK,            // pixel clock
		output                  TFT_DISP,            // display enable
		output   reg               TFT_HSYNC,            // horizontal sync input in RGB mode.
		output   reg               TFT_VSYNC,            // vertical sync input in RGB mode.
		output   reg               TFT_DE,               // data enable
		output   reg [23:0]         TFT_RGB               // red/green/blue data
		);

	// definition & assignment ---------------------------------------------------

	// ============== APB Slave Bus ================
	reg [63:0] base_addr;      // 0x00: DMA 물리 주소 Low
	reg [31:0] reg_ctrl;      // 0x0C: [0] Start Doorbell, [1] Read/Write 방향

	assign INTR   = 1'b0;

	// APB 응답 기본 설정 (항상 응답 준비 완료)
	assign S_PCLK = CLK;
	assign S_PRESETn = nRST;
	assign S_PREADY = 1'b1;   // wait state 없음
	assign S_PSLVERR = 1'b0;   // 에러 없음

	// AXI Master FSM으로 전달할 제어 신호
	wire   dma_start = reg_ctrl[0];      // Doorbel 펄스!
	wire    dma_dir = reg_ctrl[1];          // 0: Read, 1: Write

	reg      video_en;
	reg      frame_start;
	reg      line_end;


	// ============== SW -> HW (SW가 APB 주소로 쓴 데이터를 HW 레지스터에 받아 적기) =============
	// SW가 APB 버스를 통해 write  트랜잭션을 일으켰을 때 감지 (Access Phase)
	wire apb_write_strobe = S_PSEL & S_PENABLE & S_PWRITE;

	always @(posedge CLK or negedge nRST) begin
		if (!nRST) begin
			base_addr <= 'h0;
			reg_ctrl    <= 32'h0;
			video_en   <= 1'b0;
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
						base_addr[31:0]    <= S_PWDATA;
					8'h04:
						base_addr[63:32]    <= S_PWDATA;
					8'h08:
						video_en          <= S_PWDATA[0];
					8'h0C:
						reg_ctrl       <= S_PWDATA;   // bit[0]에 1이 들어오는 순간 Doorbell!
					default:
						;
				endcase
			end
		end
	end

	// ================== HW -> SW ( SW가 APB 주소를 읽으려고 할 때 내보내주는 읽기 데이터) =====================
	// ==============================================
	// 1. AXI4 Master FSM 상태 및 신호 정의
	// ==============================================
	localparam S_IDLE = 2'd0;
	localparam S_ADDR = 2'd1;
	localparam S_DATA = 2'd2;
	localparam S_DONE = 2'd3;

	reg [1:0] state;
	reg [7:0] xfer_cnt;   // 전송 카운트

	//==============================================================================
	// 3. AXI 버스 출력 신호 매핑 (Handshake 조건연산)
	//==============================================================================
	//---------------------------------------------------------------------
	// Write
	// AXI Master 고정 출력 포트 설정 (128-bit Narrow/Burst 설정)
	assign M_ACLK = CLK;
	assign M_ARESETn = nRST;

	// Write 주소 채널
	assign M_AWADDR  = 'd0;
	assign M_AWLEN   = 'd0;
	assign M_AWVALID = 1'b0;
	assign M_AWID    = 1'b0;
	assign M_AWSIZE  = 3'b100; // 128-bit (16 Bytes)
	assign M_AWBURST = 2'b01;  // INCR mode
	assign M_AWLOCK  = 1'b0;
	assign M_AWCACHE = 4'b0011;
	assign M_AWPROT  = 3'b000;
	assign M_AWREGION= 4'h0;
	assign M_AWQOS   = 4'h0;

	// Write 데이터 채널 (임시 테스트 데이터: 카운터 패턴 128비트)
	assign M_WVALID  = 1'b0;
	assign M_WDATA    = 'd0;
	assign M_WSTRB   = 16'hFFFF;
	assign M_WLAST   = 1'b0;

	// Write Response Always Ready
	assign M_BREADY = 1'b1;

	//---------------------------------------------------------------------
	// Read
	// AXI Read Ready 신호: FIFO가 Full이 아닐 때만 수신 가능
	assign M_RREADY  = 1'b1;

	// Read 주소 채널
	// AXI Read Ready 신호: FIFO가 Full이 아닐 때만 수신 가능
	assign M_RREADY  = 1'b1;

	// AXI 기본 속성 고정 (INCR 버스트, 128-bit = 16bytes = size 4)
	assign M_ARID    = 1'b0;
	assign M_ARSIZE  = 3'b100; // 128-bit (16 Bytes)
	assign M_ARBURST = 2'b01;  // INCR mode
	assign M_ARLOCK  = 1'b0;
	assign M_ARCACHE = 4'b0011;
	assign M_ARPROT  = 3'b000;
	assign M_ARLEN    = 'd119;   // 120 count - 1


	/*
reg [31:
    0]    awaddr_reg, araddr_reg;
 
always @(posedge CLK or negedge nRST) begin
   if (!nRST) begin
      state      <= S_IDLE;
      xfer_cnt   <= 8'd0;
      awaddr_reg <= 32'd0;
      araddr_reg <= 32'd0;
   end
   else begin
      case (state)
         // ---------------------------------------------
         // S_IDLE: Doorbell 대기
         // ---------------------------------------------
         S_IDLE: begin
            xfer_cnt <= 8'd0;
            if (dma_start) begin
               awaddr_reg <= base_addr[31:0];   // Target Address
               araddr_reg <= base_addr[31:0];   //
               state       <= S_ADDR;
            end
         end
         // ---------------------------------------------
         // S_ADDR: AXI 주소 채널 Handshake 대기
         // ---------------------------------------------
         S_ADDR: begin
            if (dma_dir) begin // write 데이터 전송
               if (M_AWVALID && M_AWREADY)
                  state <= S_DATA;
            end
            else begin
               if (M_ARVALID && M_ARREADY)
                  state <= S_DATA;
            end
         end
         // ---------------------------------------------
         // S_DATA: 128-bit 버스트 데이터 전송
         // ---------------------------------------------
         S_DATA: begin
            if (dma_dir) begin // Write
               if (M_WVALID && M_WREADY) begin
                  if (xfer_cnt == len_reg)
                     state <= S_DONE;
                  else
                     xfer_cnt <= xfer_cnt + 1'b1;
               end
            end
            else begin          // Read 데이터 수신
               if (M_RVALID && M_RREADY) begin
                  if (M_RVALID && M_RREADY) begin
                     if (M_RLAST)
                        state <= S_DONE;
                     else
                        xfer_cnt <= xfer_cnt + 1'b1;
                  end
               end
            end
         end
         // ---------------------------------------------
         // S_DONE: DMA 완료 및 인터럽트 펄스 발생
         // ---------------------------------------------
         S_DONE: begin
            state <= S_IDLE;
         end
         default:
            ;
 
      endcase
   end
end
	 */

	// =======================================================================================
	// FIFO 및 Pixel Buffer 관련 신호 정의
	// =======================================================================================

	wire [127:0]   fifo_data;
	reg            fifo_read;


	FiFo #(
			.FIFO_DEPTH(10),
			.DATA_WIDTH(128)
		) line_buffer (
			// system signals
			.CLK (CLK),         // clock
			.nCLR (nRST),         // clear (active low)

			// push interface
			.nWE(~(M_RVALID&M_RREADY)),         // write enable (active low)
			.DIN(M_RDATA),         // input data
			.FULL(),         // fifo is full
			// pop interface
			.nRE(~fifo_read),      // read enable (active low)
			.DOUT(fifo_data),   // output data
			.EMPTY()         // fifo is empty
		);

	// =======================================================================================
	// TFT Display 출력
	// =======================================================================================


	// 기본 출력 핀 제어
	assign TFT_PCLK = CLK;         // 10MHz 픽셀 클럭 전달
	assign TFT_DISP = video_en;    // LCD 화면 활성화 (Active High)

	// 타이밍 파라미터 정의
	localparam H_ACTIVE = 480;
	localparam H_FP     = 8;
	localparam H_SYNC   = 4;
	localparam H_BP     = 128;
	localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 535

	localparam V_ACTIVE = 272;
	localparam V_FP     = 4;
	localparam V_SYNC   = 4;
	localparam V_BP     = 32;
	localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 292

	// 가로/세로 위치 카운터
	reg [9:0] h_cnt, v_cnt;

	wire de_h = h_cnt < 480;
	wire de_v = (v_cnt >= 1) && (v_cnt <= 270);

	always @(posedge CLK or negedge nRST) begin   // clk이 0 -> 1로 올라가는 시점이나, 리셋 신호가 1 -> 0으로 떨어지는 시점에만 실행되는 로직
		if (!nRST) begin
			h_cnt      <= 10'd0;
			v_cnt      <= 10'd0;
			TFT_DE      <= 1'b0;
			TFT_HSYNC   <= 1'b0;
			TFT_VSYNC   <= 1'b0;
			TFT_RGB      <= 'd0;
			frame_start   <= 1'b0;
			line_end   <= 1'b0;
			fifo_read   <= 1'b0;
		end
		else begin
			TFT_DE       <= de_h & de_v;
			TFT_HSYNC   <= de_h;
			TFT_VSYNC   <= de_v;
			frame_start <= (h_cnt == 10'd0) & (v_cnt == 10'd0) & video_en;
			line_end   <= (h_cnt == 480) & (v_cnt >= 1) & (v_cnt < 270);
			fifo_read   <= (h_cnt[1:0] == 2'd3);

			TFT_RGB      <= (h_cnt[1:0] == 2'd0) ? fifo_data[23:0] :
				(h_cnt[1:0] == 2'd1) ? fifo_data[32+23:32] :
				(h_cnt[1:0] == 2'd2) ? fifo_data[64+23:64] : fifo_data[96+23:96];

			if (video_en & (h_cnt < (H_TOTAL-1))) begin
				h_cnt <= h_cnt + 1'b1;
			end
			else begin
				h_cnt <= 'd0;
			end

			if (video_en) begin
				if(h_cnt == (H_TOTAL-1)) begin
					if (v_cnt < V_TOTAL - 1)
						v_cnt <= v_cnt + 1'b1;
					else
						v_cnt <= 10'd0;
				end
			end
			else begin
				v_cnt <= 10'd0;
			end
		end
	end

	// fifo bus 채우기
	always @(posedge CLK or negedge nRST) begin
		if (!nRST) begin
			M_ARVALID   <= 1'b0;
			M_ARADDR   <= 'd0;
		end
		else begin
			if (frame_start) begin
				M_ARADDR   <= base_addr[31:0];
			end
			else if (line_end) begin
				M_ARADDR   <= M_ARADDR + 'd1920;
			end

			if (M_ARVALID) begin
				if(M_ARREADY)
					M_ARVALID <= 1'b0;
			end
			else begin
				M_ARVALID   <= frame_start | line_end;
			end

		end
	end


endmodule


/*
// pixel_fifo_128_to_32
module pixel_fifo_128_to_32 (
   input      clk,
   input      rst_n,
 
   // Write side (128-bit)
   input      wr_en,
   input   [127:0] din,
   output      full,
 
   // Read side (32-bit)
   input      rd_en,
   output   [31:0]   dout,
   output      empty
);
// Depth = 64개의 128-bit 슬롯 (총 256개 픽셀 저장 가능)
reg [127:
    0] mem [0:
          63];
reg [5:
    0]   wr_ptr;
reg [7:
    0]   rd_ptr;      // 32-bit 단위 인덱싱을 위한 Pointer
reg [8:
    0]   count;      // 32-bit 단위 잔여 데이터 개수
 
assign full = (count >= 9'd252);   // overflow 방지 safety margin
assign empty = (count == 9'd0);
 
 
// 32-bit 데이터 Muxing (Lower Byte / Pixel First)
wire [127:
     0] current_word = mem[rd_ptr[7:2]];
reg  [31:
     0]  dout_reg;
 
always @(*) begin
   case (rd_ptr[1:0])
      2'b00:
         dout_reg = current_word[31:0];
      2'b01:
         dout_reg = current_word[63:32];
      2'b10:
         dout_reg = current_word[95:64];
      2'b11:
         dout_reg = current_word[127:96];
   endcase
end
 
assign dout = dout_reg;
 
// Write & Read Pointer / Counter logic
always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
      wr_ptr <= 6'd0;
      rd_ptr <= 8'd0;
      count  <= 9'd0;
   end
   else begin
      // Write (128-bit = 4 Pixels 추가)
      if (wr_en && !full) begin
         mem[wr_ptr] <= din;
         wr_ptr      <= wr_ptr + 1'b1;
      end
 
      // Read (32-bit = 1 Pixel 소비)
      if (rd_en && !empty) begin
         rd_ptr <= rd_ptr + 1'b1;
      end
 
      // Counter Update
      case ({ (wr_en && !full), (rd_en && !empty) })
         2'b10:
            count <= count + 9'd4; // Write만 발생
         2'b01:
            count <= count - 9'd1; // Read만 발생
         2'b11:
            count <= count + 9'd3; // Write(+4) & Read(-1) 동시에 발생
         default:
            ;
      endcase
   end
end
endmodule
 */
