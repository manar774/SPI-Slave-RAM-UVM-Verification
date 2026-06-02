vlib work
vlog -sv -f src_list.list +define+SIM -cover bcesft   
vsim -coverage -voptargs=+acc work.slave_top -classdebug -uvmcontrol=all
add wave -position end sim:/slave_top/slaveif/*
run -all
coverage exclude -src SPI_slave.v -scope /slave_top/dut -line 79
coverage exclude -src SPI_slave.v -scope /slave_top/dut -line 130
coverage save slave_top.ucdb -onexit

