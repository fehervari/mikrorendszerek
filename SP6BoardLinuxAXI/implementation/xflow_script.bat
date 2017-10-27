@ECHO OFF
@REM ###########################################
@REM # Script file to run the flow 
@REM # 
@REM ###########################################
@REM #
@REM # Command line for ngdbuild
@REM #
ngdbuild -p xc6slx9tqg144-2 -nt timestamp -bm system.bmm "F:/curr_ISE_proj/mikrorendszerek/SP6BoardLinuxAXI_14_7/SP6BoardLinuxAXI/implementation/system.ngc" -uc system.ucf system.ngd 

@REM #
@REM # Command line for map
@REM #
map -o system_map.ncd -w -pr b -ol high -timing -detail -logic_opt on -ignore_keep_hierarchy -lc area -mt 2 system.ngd system.pcf 

@REM #
@REM # Command line for par
@REM #
par -w -ol high -mt 3 system_map.ncd system.ncd system.pcf 

@REM #
@REM # Command line for post_par_trce
@REM #
trce -e 3 -xml system.twx system.ncd system.pcf 

