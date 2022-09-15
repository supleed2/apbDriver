# apbDriver

Basic APB-compatible module designed for use with Verilator, but should work with any DPI-C compatible simulator.

The module allows for transactions to be started and stopped from within the C++ testbench, and functions execute in 0 time. Transactions cannot be queued but the function return code indicates success, so time can be advanced and the transaction attempted again in the case of failure.
