# Define target clock period in nanoseconds
set clock_period 10.0
set clock_port [get_ports clk]
# Create main system clock
create_clock -name clk -period $clock_period $clock_port
# Set clock uncertainty (jitter, skew setup margin)
set_clock_uncertainty 0.25 [get_clocks clk]
 
# Set transition time on the clock net
set_clock_transition 0.15 [get_clocks clk]
# Build input port collection excluding the clock port
set all_inputs_no_clk {}
foreach port [get_ports *] {
    if {[get_property $port direction] == "input" && [get_property $port name] != "clk"} {
        lappend all_inputs_no_clk $port
    }
}
# Set Input Delays (50% of clock period budget)
if {[llength $all_inputs_no_clk] > 0} {
    set_input_delay -clock [get_clocks clk] 5.0 $all_inputs_no_clk
}
# Set Output Delays (50% of clock period budget)
set all_outputs [all_outputs]
if {[llength $all_outputs] > 0} {
    set_output_delay -clock [get_clocks clk] 5.0 $all_outputs
}
# Environmental / Driving Constraints
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_2 -pin X [all_inputs]
set_load 0.033 [all_outputs]
