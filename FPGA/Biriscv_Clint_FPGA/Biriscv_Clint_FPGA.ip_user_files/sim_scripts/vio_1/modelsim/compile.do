vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../Biriscv_Clint_FPGA.srcs/sources_1/ip/vio_1/hdl/verilog" "+incdir+../../../../Biriscv_Clint_FPGA.srcs/sources_1/ip/vio_1/hdl" \
"../../../../Biriscv_Clint_FPGA.srcs/sources_1/ip/vio_1/sim/vio_1.v" \


vlog -work xil_defaultlib \
"glbl.v"

