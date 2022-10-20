//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.07 
//Created Time: 2022-10-12 20:53:04
create_clock -name clk_in -period 37.037 -waveform {0 18.52} [get_ports {clock}]
report_timing -setup -max_paths 155 -max_common_paths 1
set_operating_conditions -grade c -model slow -speed 6 -setup -hold -max -min -max_min
