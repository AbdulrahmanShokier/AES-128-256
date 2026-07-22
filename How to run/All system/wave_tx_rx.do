onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/clk
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/rst
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/sof
add wave -noupdate -expand -group Tx -radix hexadecimal /DVB_end_to_end_top_tb/dut/plaintext_in
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/tx_inst/u_data/aes_inst/valid
add wave -noupdate -expand -group Tx -radix hexadecimal /DVB_end_to_end_top_tb/dut/tx_inst/u_data/rs_mod_reg_inst/buf_A
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/tx_inst/preamble_en
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/tx_inst/control_en
add wave -noupdate -expand -group Tx /DVB_end_to_end_top_tb/dut/tx_inst/data_en
add wave -noupdate -expand -group Rx /DVB_end_to_end_top_tb/dut/Control_complete
add wave -noupdate -expand -group Rx -radix hexadecimal /DVB_end_to_end_top_tb/dut/rx_inst/u_aes_dec/IN
add wave -noupdate -expand -group Rx -radix hexadecimal /DVB_end_to_end_top_tb/dut/rx_inst/u_aes_dec/KEY
add wave -noupdate -expand -group Rx -radix hexadecimal /DVB_end_to_end_top_tb/dut/rx_inst/u_aes_dec/OUT
add wave -noupdate -expand -group Rx /DVB_end_to_end_top_tb/dut/rx_inst/u_aes_dec/valid_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22835000 ps} 1} {{Cursor 2} {48985954 ps} 1} {{Cursor 3} {22904880 ps} 1} {{Cursor 4} {21625000 ps} 0}
quietly wave cursor active 4
configure wave -namecolwidth 422
configure wave -valuecolwidth 223
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 20
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {21320271 ps} {21929730 ps}
