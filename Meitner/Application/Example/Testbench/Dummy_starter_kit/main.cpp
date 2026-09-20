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
// Title : Testbench
// Rev.  : 9/20/2026 Sun (woojun)
//================================================================================
#include "Testbench.h"
#include <conio.h>

#define WIDTH				  480
#define HEIGHT				  272
#define TOTAL_PIXELS		  (WIDTH * HEIGHT)

#define RED_XRGB8888		  0x00FF0000

#define REG_APB_BASE_ADDR	  0x20000
#define REG_APB_BUF_BASE_ADDR 0x20000

void fill_red_image(uint64_t fb_ptr, DDK *pDDK)
{
	for (int i = 0; i < TOTAL_PIXELS; i++) {
		pDDK->RegWrite(fb_ptr + (4 * i), RED_XRGB8888);
	}
}

// 시나리오
// 1. dram영역에 direct로 빨간색 픽셀을 전체 픽셀 개수만큼 채운다.
// 2. hw영역에서 dram -> TFT buffer로 옮기는 작업을 한다.
// 3. 화면에 빨간색으로 표시되는지 확인한다.

class Testbench : public TestbenchFramework
{
private:
	DDKMemory *m_pBuff[2];

public:
	virtual bool OnInitialize(void)
	{
		printf("Current system : %s\n", m_pDDK->GetSystemDescription());
		m_pBuff[0] = CreateDDKMemory(480 * 272 * 4, 4096 / 8);
		m_pBuff[1] = CreateDDKMemory(480 * 272 * 4, 4096 / 8);
		return CheckSimulation("FPGA Starter Kit");
	}

	virtual void OnRelease(void)
	{
		printf("finish test OnRelease\n");
		SAFE_RELEASE(m_pBuff[0]);
		SAFE_RELEASE(m_pBuff[1]);
	}

	virtual bool OnTestBench(void)
	{
		printf(
			"m_pBuffer virtual addr: 0x%p, physical addr: 0x%llX\n, byte size: %llu", m_pBuff[0]->Virtual(), m_pBuff[0]->Physical(),
			m_pBuff[0]->ByteSize());

		// red pixel(24-bit) 480 * 272 * (4byte) 만큼 밀어넣을 수 있나? 522,240 byte = 510kb
		// 총 사이즈가 128바이트?
		// uint32_t *dram_buf = (uint32_t *)0x80000000;
		// fill_red_image(0x80000000, m_pDDK);
		uint32_t *pBuf = (uint32_t *)m_pBuff[0]->Virtual();
		for (size_t i = 0; i < TOTAL_PIXELS; i++) {
			pBuf[i] = RED_XRGB8888;
		}

		// 대각선은 애니메이션 막대가 지나가며 지워버리므로 잠시 비활성화
		// for (size_t i = 0; i < 270; i++) {
		//    pBuf[i + (i * 480)] = 0xFFFFFFFF;
		// }

		m_pBuff[0]->Flush();

		// 1. 프레임버퍼 시작 주소 설정 (LOW만 작성 가능)
		m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x10, m_pBuff[0]->Physical());
		// m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x04, m_pBuff[0]->Physical() >> 32);
		//  2. 길이 설정
		m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x08, 1);
		// 3. ctrl trigger
		// m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x0C, 0x00000001);

		// m_pDDK->RegWrite(REG_APB_BASE_ADDR, 255);

		// 입력 버퍼 비우기
		fflush(stdin);

		// 애니메이션: 빨간 배경 위에서 흰 세로 막대가 오른쪽으로 흘러간다.
		// HW는 그대로 두고, SW가 프레임 사이에 DRAM 내용만 바꿔치기하면 화면이 움직인다.
		// (단일 버퍼 방식: 티어링 가능성은 있지만 변화량이 작아 데모로는 충분)
		const int BAR_W = 8; // 막대 폭 (픽셀)
		const int STEP	= 4; // 프레임당 이동량 (픽셀)
		int		  bar_x = 0;
		int		  back	= 0;

		printf("\n[System] Animating... Press ESC key to stop.\n");

		while (GetKeyState(VK_ESCAPE) >= 0) {
			uint32_t *pWhitebuf = (uint32_t *)m_pBuff[back]->Virtual();

			for (int y = 0; y < HEIGHT; y++) { // 272번 돌아간다. 0 ~ 271 까지
				uint32_t *pLine = pWhitebuf + y * WIDTH;
				for (int x = 0; x < WIDTH; x++) pLine[x] = RED_XRGB8888;
				for (int i = 0; i < BAR_W; i++) pLine[(bar_x + i) % WIDTH] = 0xFFFFFFFF;
			}

			m_pBuff[back]->Flush();
			m_pDDK->RegWrite(REG_APB_BUF_BASE_ADDR + 0x10, m_pBuff[back]->Physical());

			uint32_t frame_cnt = m_pDDK->RegRead(REG_APB_BUF_BASE_ADDR + 0x14);
			while (m_pDDK->RegRead(REG_APB_BUF_BASE_ADDR + 0x14) == frame_cnt) {
				/* spin */
			}

			back ^= 1;
			bar_x = (bar_x + STEP) % WIDTH;
		}

		return true;
	}
};

int main(int argc, char **argv)
{
	Testbench tb;

	if (tb.Initialize()) {
		if (!tb.DoTestbench())
			printf("Testbench is failed.\n");
	} else {
		printf("Initialization is failed.\n");
	}

	printf("finish test\n");

	tb.Release();
}
