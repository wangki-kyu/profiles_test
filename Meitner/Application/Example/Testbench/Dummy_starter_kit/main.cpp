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
// Rev.  : 8/30/2026 Sun (woojun)
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
	DDKMemory *m_pBuff;

public:
	virtual bool OnInitialize(void)
	{
		printf("Current system : %s\n", m_pDDK->GetSystemDescription());
		m_pBuff = CreateDDKMemoryEx(480 * 272 * 4, 32, 0x80000000); // 8KB, 256bit alignment
		return CheckSimulation("FPGA Starter Kit");
	}

	virtual void OnRelease(void)
	{
		printf("finish test OnRelease\n");
		SAFE_RELEASE(m_pBuff);
	}

	virtual bool OnTestBench(void)
	{
		printf("Press 'ESC' key to exit.\n");
		fflush(stdout);

		printf(
			"m_pBuffer virtual addr: 0x%p, physical addr: 0x%llX\n, byte size: %llu", m_pBuff->Virtual(), m_pBuff->Physical(),
			m_pBuff->ByteSize());

		// red pixel(24-bit) 480 * 272 * (4byte) 만큼 밀어넣을 수 있나? 522,240 byte = 510kb
		// 총 사이즈가 128바이트?
		// uint32_t *dram_buf = (uint32_t *)0x80000000;
		// fill_red_image(0x80000000, m_pDDK);
		uint32_t *pBuf = (uint32_t *)m_pBuff->Virtual();
		for (size_t i = 0; i < TOTAL_PIXELS; i++) {
			pBuf[i] = RED_XRGB8888;
		}
		m_pBuff->Flush();

		// 1. 프레임버퍼 시작 주소 설정 (LOW만 작성 가능)
		m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x00, m_pBuff->Physical());
		// 2. 길이 설정
		m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x08, TOTAL_PIXELS * 4);
		// 3. ctrl trigger
		m_pDDK->RegWrite(REG_APB_BASE_ADDR + 0x0C, 0x00000001);

		// m_pDDK->RegWrite(REG_APB_BASE_ADDR, 255);

		// 입력 버퍼 비우기
		fflush(stdin);

		// Enter 키를 누를 때까지 블로킹 대기
		getchar();

		printf("\n[System] Exiting testbench...\n");

		// while (GetKeyState(VK_ESCAPE) >= 0) Sleep(100);

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
