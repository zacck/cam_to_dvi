import cocotb 
import os
import random 
import sys 
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge 
from cocotb.utils import get_sim_time as gst 
from cocotb.runner import get_runner
# get the name of current file for the runner
test_file = os.path.basename(__file__).replace(".py","")

@cocotb.test()
async def test_b2p(dut):
    """ Test b2p module"""
    dut._log.info("Starting B2P...")
    cocotb.start_soon(Clock(dut.camera_pclk, 40, units="ns").start())
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut._log.info("Holding reset")
    dut.rst.value = 1 
    # Sane Initial values
    await ClockCycles(dut.clk, 4)
    assert dut.pixel_valid.value == 0
    assert dut.pixel_h_count.value == 0
    assert dut.pixel_v_count.value == 0
    await ClockCycles(dut.clk, 1)
    dut.rst.value = 0
    # Half pixel gets ready
    await ClockCycles(dut.camera_pclk, 2)
    dut.camera_h_sync.value = 1
    dut.camera_v_sync.value = 1
    dut.camera_data.value = 0x9A
    assert dut.half_pixel_ready.value == 0
    await RisingEdge(dut.camera_pclk)
    await ClockCycles(dut.clk, 1)
    assert dut.camera_sample_valid.value == 1
    await FallingEdge(dut.camera_pclk)
    assert dut.half_pixel_ready.value == 1
    assert dut.last_sampled_data.value == 0x9A
    # Full Pixel gets ready
    # pixel valid is a single cycle signal 
    # Full pixel is arranged righjt
    # half ready pixel is not on
    dut.camera_data.value = 0x08
    await FallingEdge(dut.camera_pclk)
    assert dut.pixel_valid.value == 1
    assert dut.half_pixel_ready.value == 0
    assert dut.pixel_data.value == 0x9A08
    await ClockCycles(dut.clk, 1)
    assert dut.pixel_valid.value == 0
    # H count increments 
    current_h_count = dut.pixel_h_count.value
    current_v_count = dut.pixel_v_count.value
    await RisingEdge(dut.pixel_valid)
    await FallingEdge(dut.clk)
    assert current_h_count + 1 == dut.pixel_h_count.value
    assert current_v_count == dut.pixel_v_count.value
    # v count increments
    # h count resets
    current_h_count = dut.pixel_h_count.value
    current_v_count = dut.pixel_v_count.value
    dut.camera_h_sync.value = 0
    await ClockCycles(dut.clk,4)
    assert dut.trigger.value == 0
    dut.camera_h_sync.value = 0
    await ClockCycles(dut.camera_pclk, 2)
    dut.camera_h_sync.value = 1
    await ClockCycles(dut.clk, 4)
    assert current_v_count + 1 == dut.pixel_v_count.value
    assert dut.pixel_h_count.value == 0
    ## new frame resets v count
    dut.camera_h_sync.value = 0
    await ClockCycles(dut.clk, 4)
    dut.camera_v_sync.value = 0
    await ClockCycles(dut.clk, 4)
    assert dut.pixel_v_count.value == 0
    assert dut.pixel_h_count.value == 0


    #dut.camera_v_sync.value = 0
    await ClockCycles(dut.clk, 3000)



def b2p_runner():
    """ Simulate the counter using the python runner """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "pixel_reconstruct.sv"]
    hdl_toplevel = "pixel_reconstruct"
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
            sources = sources, 
            hdl_toplevel = hdl_toplevel, 
            always=True,
            build_args=build_test_args, 
            parameters=parameters, 
            timescale=('1ns','1ps'),
            waves=True
    )
    run_test_args =  []
    runner.test(
            hdl_toplevel=hdl_toplevel,
            test_module=test_file,
            test_args=run_test_args,
            waves=True
    )

if __name__ == "__main__":
    b2p_runner()

