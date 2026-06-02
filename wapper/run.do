
vlib work
vlog -sv -f src_list.list +define+SIM  +cover -covercells 
vsim -voptargs=+acc work.wrapper_top -cover
run 0
add wave *
add wave -position end sim:/wrapper_top/wrapperif/*
add wave -position end sim:/wrapper_top/ramif/*
add wave -position end sim:/wrapper_top/slaveif/*
coverage save wrapper_top.ucdb 
run -all

