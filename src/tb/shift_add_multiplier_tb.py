import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

async def multiply(dut, a_delay_range, b_delay_range, a_val_range, b_val_range):
    a_delay = random.randint(a_delay_range[0], a_delay_range[1])
    b_delay = random.randint(b_delay_range[0], b_delay_range[1])
    a_val = random.randint(a_val_range[0], a_val_range[1])
    b_val = random.randint(b_val_range[0], b_val_range[1])

    timeout = 0
    while timeout < max(a_delay_range[0], b_delay_range[1])+32:
        if timeout == a_delay:
            dut.tvalid_slave_1.value = 1
            dut.tdata_slave_1.value = a_val
        
        if timeout == b_delay:
            dut.tvalid_slave_2.value = 1
            dut.tdata_slave_2.value = b_val

        if dut.tvalid_slave_1.value == 1 and dut.tready_slave_1.value == 1:
            dut.tvalid_slave_1.value = 0

        if dut.tvalid_slave_2.value == 1 and dut.tready_slave_2.value == 1:
            dut.tvalid_slave_2.value = 0

        if dut.tvalid_master.value == 1 and dut.tready_master.value == 1:
            dut.tready_master.value = 0
            print(f'A: {a_val}, B: {b_val}, output: {dut.tdata_master.value.integer}')
            assert(dut.tdata_master.value.integer == a_val*b_val)
            await(ClockCycles(dut.clk, 1))
            return
        else:
            dut.tready_master.value = 1

        timeout = timeout + 1
        await(ClockCycles(dut.clk, 1))

    raise cocotb.TestFailure("Timed out.")

async def reset(dut):
    dut.tdata_slave_1.value = 0
    dut.tdata_slave_2.value = 0
    dut.tvalid_slave_1.value = 0
    dut.tvalid_slave_2.value = 0
    dut.tready_master.value = 0
    dut.reset_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 5)

@cocotb.test()
async def test_shift_add_multiplier(dut):
    random.seed()

    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())

    await reset(dut)

    # Run a few tests with random delays and values,
    # though keeping values such that the result is
    # within range
    i = 0
    while i < 10:
        await multiply(dut, (0, 10), (0, 10), (0, 255), (0, 255))
        i = i + 1

    # Run a few tests with zero delays and random values
    i = 0
    while i < 10:
        await multiply(dut, (0, 0), (0, 0), (0, 255), (0, 255))
        i = i + 1