SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES += $(PWD)/../rtl/shift_add_multiplier.v
TOPLEVEL = shift_add_multiplier
MODULE = shift_add_multiplier_tb

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
