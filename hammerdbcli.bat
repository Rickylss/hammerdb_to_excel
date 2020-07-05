@echo off
set path=.\bin;%PATH%
START tclsh86t hammerdbcli %1 %2
exit
