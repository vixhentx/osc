file delete -force work
file delete -force vsim_ipsxe_fft_onboard_top.log
vlib  work
vmap  work work
vlog -incr -sv \
D:/a/PDS_2022.2-SP6.4/ip/system_ip/ipsxe_fft/ipsxe_fft_eval/ipsxe_fft/../../../../../arch/vendor/pango/verilog/simulation/GTP_APM_E2.v \
D:/a/PDS_2022.2-SP6.4/ip/system_ip/ipsxe_fft/ipsxe_fft_eval/ipsxe_fft/../../../../../arch/vendor/pango/verilog/simulation/GTP_DRM18K_E1.v \
D:/a/PDS_2022.2-SP6.4/ip/system_ip/ipsxe_fft/ipsxe_fft_eval/ipsxe_fft/../../../../../arch/vendor/pango/verilog/simulation/GTP_DRM36K_E1.v \
D:/a/PDS_2022.2-SP6.4/ip/system_ip/ipsxe_fft/ipsxe_fft_eval/ipsxe_fft/../../../../../arch/vendor/pango/verilog/simulation/GTP_GRS.v \
-f ./ipsxe_fft_onboard_top_filelist.f -l vlog.log
vsim -novopt work.ipsxe_fft_onboard_top_tb -l vsim.log
do ipsxe_fft_onboard_top_wave.do
run -all
