package wrapper_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import ram_config_pkg::*;
    import slave_config_pkg::*;
    import wrapper_config_obj_pkg::*;
    import ram_env_pkg::*;
    import slave_env_pkg::*;
    import wrapper_env_pkg::*;
    import wrapper_sequence_pkg::*;
    
    class wrapper_test extends uvm_test;
        `uvm_component_utils(wrapper_test)

        ram_config R_cfg;
        slave_config S_cfg;
        wrapper_config_obj W_cfg;

        ram_env R_env;
        slave_env S_env;
        wrapper_env W_env;
        
        wrapper_reset_sequence rst_seq;
        wrapper_write_only_sequence write_seq;
        wrapper_read_only_sequence read_seq;
        wrapper_write_read_sequence write_read_seq;

        function new(string name = "wrapper_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction 

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            R_cfg    = ram_config::type_id::create("R_cfg");
            S_cfg    = slave_config::type_id::create("S_cfg");
            W_cfg    = wrapper_config_obj::type_id::create("W_cfg");
            
            R_env    = ram_env::type_id::create("R_env", this);
            S_env    = slave_env::type_id::create("S_env", this);
            W_env    = wrapper_env::type_id::create("W_env", this);
            
            rst_seq    = wrapper_reset_sequence::type_id::create("rst_seq");
            write_seq  = wrapper_write_only_sequence::type_id::create("write_seq");
            read_seq   = wrapper_read_only_sequence::type_id::create("read_seq");
            write_read_seq = wrapper_write_read_sequence::type_id::create("write_read_seq");

            if (!uvm_config_db #(virtual ram_if )::get(this, "", "ram_vif", R_cfg.ram_vif))
                `uvm_fatal("build_phase", "Test-unable to get the virtual interface of RAM")
            R_cfg.active = UVM_PASSIVE;
            uvm_config_db #(ram_config)::set(this, "*", "CFG", R_cfg);

            if (!uvm_config_db #(virtual slave_if )::get(this, "", "slave_vif", S_cfg.slave_vif))
                `uvm_fatal("build_phase", "Test-unable to get the virtual interface of slave")
            S_cfg.active = UVM_PASSIVE;
            uvm_config_db #(slave_config)::set(this, "*", "CFG", S_cfg);

            if (!uvm_config_db #(virtual wrapper_if )::get(this, "", "wrapper_if", W_cfg.wrapper_config_if))
                `uvm_fatal("build_phase", "Test-unable to get the virtual interface of wrapper")
            W_cfg.active = UVM_ACTIVE;
            uvm_config_db #(wrapper_config_obj)::set(this, "*", "W_CFG", W_cfg);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this);
                `uvm_info("run_phase", "Reset Asserted", UVM_LOW)
                rst_seq.start(W_env.agt.sqr);
                `uvm_info("run_phase", "Reset Deasserted", UVM_LOW)

                `uvm_info("run_phase", "Write-Only Sequence Started", UVM_LOW)
                write_seq.start(W_env.agt.sqr);
                `uvm_info("run_phase", "Write-Only Sequence Ended", UVM_LOW)

                `uvm_info("run_phase", "Read-Only Sequence Started", UVM_LOW)
                read_seq.start(W_env.agt.sqr);
                `uvm_info("run_phase", "Read-Only Sequence Ended", UVM_LOW)

                `uvm_info("run_phase", "Write-Read Sequence Started", UVM_LOW)
                write_read_seq.start(W_env.agt.sqr);
                `uvm_info("run_phase", "Write-Read Sequence Ended", UVM_LOW)
            phase.drop_objection(this);
        endtask 
    endclass 
endpackage
