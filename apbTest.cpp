// Verilator testbench for testing the APB Driver
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0

#include "VerilatorTbFst.h"
#include <VapbTest.h>
#include <VapbTest__Dpi.h>
#include <iostream>
#include <stdlib.h>
#include <string>
#include <svdpi.h>
#include <verilated.h>

#ifndef N_CYCLES
#define N_CYCLES 100
#endif

int main(int argc, char **argv, char **env) {
	Verilated::commandArgs(argc, argv);
	VerilatorTbFst<VapbTest> *tb = new VerilatorTbFst<VapbTest>();
	tb->setScope("apbTest.u_apbDriver");

	// Get SystemVerilog Parameters
	const uint64_t CLOCK_PERIOD_PS = 10;

	tb->setClockPeriodPS(2 * (CLOCK_PERIOD_PS / 3));
	tb->opentrace("output/VapbTest.fst");

	tb->m_trace->dump(0); // Initialize waveform at beginning of time.
	printf("Starting!\n");

	tb->m_dut->i_rst = 1;
	tb->ticks(2);
	tb->m_dut->i_rst = 0;
	tb->ticks(2);

	uint32_t addr, data, strb, prot;
	int err = 0;
	uint8_t SlvErr = 0;
	uint32_t readData = 0;
	addr = 0x100u;
	data = 0x1234BEEFu;
	strb = 0b1111u;
	prot = 0b110u;
	err = tryStartApbWrite(&addr, &data, &strb, &prot);
	if (err != 0) {
		printf("tryStartApbWrite failed!\n");
	} else {
		printf("tryStartApbWrite succeeded!\n");
		tb->ticks(2);
		err = tryFinishApbWrite(&SlvErr);
		while (err != 0) {
			printf("tryFinishApbWrite failed!\n");
			tb->tick();
			err = tryFinishApbWrite(&SlvErr);
		}
		printf("tryFinishApbWrite succeeded!\n");
		if (SlvErr != 0) {
			printf("Apb Write failed!\n");
		} else {
			printf("Apb Write succeeded!\n");
		}
	}
	tb->tick();
	tb->tick();
	err = tryStartApbRead(&addr, &prot);
	if (err != 0) {
		printf("tryStartApbRead failed!\n");
	} else {
		printf("tryStartApbRead succeeded!\n");
		tb->ticks(2);
		err = tryFinishApbRead(&SlvErr, &readData);
		while (err != 0) {
			printf("tryFinishApbRead failed!\n");
			tb->tick();
			err = tryFinishApbRead(&SlvErr, &readData);
		}
		printf("tryFinishApbRead succeeded!\n");
		if (SlvErr != 0) {
			printf("Apb Read failed!\n");
		} else {
			printf("Apb Read succeeded!\nReceived Read Data: 0x%x\n", readData);
		}
	}
	tb->tick();
	tb->tick();
	data = 0xDEAD5678u;
	strb = 0b1100u;
	err = tryStartApbWrite(&addr, &data, &strb, &prot);
	if (err != 0) {
		printf("tryStartApbWrite failed!\n");
	} else {
		printf("tryStartApbWrite succeeded!\n");
		tb->ticks(2);
		err = tryFinishApbWrite(&SlvErr);
		while (err != 0) {
			printf("tryFinishApbWrite failed!\n");
			tb->tick();
			err = tryFinishApbWrite(&SlvErr);
		}
		printf("tryFinishApbWrite succeeded!\n");
		if (SlvErr != 0) {
			printf("Apb Write failed!\n");
		} else {
			printf("Apb Write succeeded!\n");
		}
	}
	tb->tick();
	tb->tick();
	err = tryStartApbRead(&addr, &prot);
	if (err != 0) {
		printf("tryStartApbRead failed!\n");
	} else {
		printf("tryStartApbRead succeeded!\n");
		tb->ticks(2);
		err = tryFinishApbRead(&SlvErr, &readData);
		while (err != 0) {
			printf("tryFinishApbRead failed!\n");
			tb->tick();
			err = tryFinishApbRead(&SlvErr, &readData);
		}
		printf("tryFinishApbRead succeeded!\n");
		if (SlvErr != 0) {
			printf("Apb Read failed!\n");
		} else {
			printf("Apb Read succeeded!\nExpected Read Data: 0x%x\nReceived Read Data: 0x%x\n", 0xDEADBEEFu, readData);
		}
	}
	tb->tick();
	tb->tick();

	while (tb->tickcount() < N_CYCLES * 2) {
		tb->ticks(2); // Run Tests
	}

	printf("Time: %ldns\n", tb->tickcount());
	printf("Stopped.\n");

	tb->closetrace();
	exit(EXIT_SUCCESS);
}