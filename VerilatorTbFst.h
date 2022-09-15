// Header file to be used in verilator C++ testbenches.
// SPDX-FileCopyrightText: © 2022 Aadi Desai <21363892+supleed2@users.noreply.github.com>
// SPDX-License-Identifier: Apache-2.0
//
// Intended usage / order:
// - VerilatorTbFst<Vtest_DUT> *tb = new VerilatorTbFst<Vtest_DUT>();
// - tb->setClockPeriodPS(clock_period_in_picoseconds);
//   - This value can be taken from within the SystemVerilog Testbench
// - tb->opentrace("output/test_DUT.verilator.fst");
// - tb->m_trace->dump(0);
//   - Followed by arst/rst and signals matching the intended testbench flow.

#ifndef _VERILATORTBFST_H
#define _VERILATORTBFST_H

#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <svdpi.h>
#include <verilated_fst_c.h>

typedef enum {
	ERROR,
	WARN,
	NOTE
} TbPrintLevel;

template <class VA>
class VerilatorTbFst {
  public:
	VA *m_dut;
	VerilatedFstC *m_trace;
	uint64_t m_tickcount;
	uint64_t m_clockperiod;
	bool m_dodump;

	VerilatorTbFst(void) : m_trace(NULL), m_tickcount(0l) {
		m_dut = new VA;
		Verilated::traceEverOn(true);
		m_dut->i_clk = 0;
		m_dut->i_rst = 1;
		m_dodump = true;
		eval(); // Get our initial values set properly.
	}

	virtual ~VerilatorTbFst(void) {
		closetrace();
		delete m_dut;
		m_dut = NULL;
	}

	virtual void setClockPeriodPS(const uint64_t ps) {
		m_clockperiod = ps;
	}

	virtual void opentrace(const char *fstname) {
		opentrace(fstname, 99);
	}

	virtual void opentrace(const char *fstname, int tracedepth) {
		if (!m_trace) {
			m_trace = new VerilatedFstC;
			m_dut->trace(m_trace, tracedepth);
			m_trace->open(fstname);
		}
	}

	virtual void closetrace(void) {
		if (m_trace) {
			m_trace->close();
			delete m_trace;
			m_trace = NULL;
		}
	}

	virtual void eval(void) {
		m_dut->eval();
	}

	// Call from loop {check, drive, tick}
	virtual void tick(void) {
		// check
		// drive
		// rise eval dump
		// fall eval dump

		m_dut->i_clk = 1;
		eval();
		if (m_dodump && m_trace) {
			m_trace->dump((uint64_t)(m_clockperiod * m_tickcount));
		}

		m_dut->i_clk = 0;
		eval();
		if (m_dodump && m_trace) {
			m_trace->dump((uint64_t)(m_clockperiod * m_tickcount + (m_clockperiod / 2)));
			m_trace->flush();
		}

		m_tickcount++;
	}

	virtual void ticks(int numTicks) {
		for (int i = 0; i < numTicks; i++)
			tick();
	}

	virtual void areset(void) {
		m_dut->i_arst = 0;
		tick();
		m_dut->i_arst = 1;
		ticks(4);
		m_dut->i_arst = 0;
	}

	virtual void reset(void) {
		m_dut->i_rst = 1;
		ticks(5);
		m_dut->i_rst = 0;
	}

	unsigned long tickcount(void) {
		return m_tickcount;
	}

	virtual bool done(void) {
		return Verilated::gotFinish();
	}

	virtual void setScope(const char *scopeName) {
		char fullScopeName[1024];
		svSetScope(svGetScopeFromName(strcat(strcpy(fullScopeName, "TOP."), scopeName)));
	}
};

#endif // _VERILATORTBFST_H