@ECHO OFF
@REM ###########################################
@REM # Script file to run the flow 
@REM # 
@REM ###########################################
@REM #
@REM # Command line for ngdbuild
@REM #
<<<<<<< HEAD
ngdbuild -p xc6slx9tqg144-2 -nt timestamp -bm system.bmm "D:/git/mikrorendszerek/MB_System_full/MB_System/implementation/system.ngc" -uc system.ucf system.ngd 
=======
ngdbuild -p xc6slx9tqg144-2 -nt timestamp -bm system.bmm "F:/git/mikrorendszerek/MB_System_full/MB_System/implementation/system.ngc" -uc system.ucf system.ngd 
>>>>>>> remotes/origin/master

@REM #
@REM # Command line for map
@REM #
map -o system_map.ncd -w -pr b -ol high -timing -detail system.ngd system.pcf 

@REM #
@REM # Command line for par
@REM #
par -w -ol high system_map.ncd system.ncd system.pcf 

@REM #
@REM # Command line for post_par_trce
@REM #
trce -e 3 -xml system.twx system.ncd system.pcf 

