@echo off
echo [FILENAMES]> clearres.txt
echo Exe=%1>> clearres.txt
echo SaveAs=%1>> clearres.txt
echo Log=>> clearres.txt
echo.>> clearres.txt
echo [COMMANDS]>> clearres.txt
echo -delete RCDATA,CHARTABLE,>> clearres.txt
echo -delete RCDATA,DVCLAL,>> clearres.txt
echo -delete RCDATA,PACKAGEINFO,>> clearres.txt
echo -delete CURSORGROUP,32761,>> clearres.txt
echo -delete CURSORGROUP,32762,>> clearres.txt
echo -delete CURSORGROUP,32763,>> clearres.txt
echo -delete CURSORGROUP,32764,>> clearres.txt
echo -delete CURSORGROUP,32765,>> clearres.txt
echo -delete CURSORGROUP,32766,>> clearres.txt
echo -delete CURSORGROUP,32767,>> clearres.txt
"C:\Program Files\Resource Hacker\ResHacker.exe" -script clearres.txt
del clearres.txt
