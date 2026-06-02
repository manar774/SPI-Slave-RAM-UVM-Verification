vlib work
vlog -sv -f src_list.list -cover bcesf   
vsim -coverage -voptargs=+acc work.top -classdebug -uvmcontrol=all
coverage save top.ucdb -onexit
run -all
coverage exclude -src RAM.v -line 41 -code s
coverage exclude -src RAM.v -line 41 -code b