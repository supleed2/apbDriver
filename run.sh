#!/usr/bin/env bash
rm output/*
mkdir -p output
verilator --trace-fst -DUSE_FST -CFLAGS -DUSEFST --cc --exe --default-language 1800-2017 --trace-depth 5 -DN_CYCLES=25 -CFLAGS -DN_CYCLES=25 --Mdir output -Wall apbTest.cpp apbTest.sv
make -C output -f VapbTest.mk VapbTest
time output/VapbTest > output/verilator.log
! grep -q ERROR output/verilator.log
