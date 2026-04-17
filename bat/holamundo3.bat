@echo off
::variable1=hola
set variable1=hola

::variable2=mundo 2
set variable2=mundo II
set /a var=1+1

::variable3=nuevamente,
set variable3=nuevamente,

::variable4=variable4-2
set variable4=variable4-2
::variable5=variable5-2
set variable5=variable5-2
::variable6=variable6-2
set variable6=variable6-2
set variable7=variable7-2
set variable8=variable8-2
set variable9="variable9-2"
set variable10=variable10-2
set variable11=variable11-2
set variable12=variable12-2

echo.
echo %variable1% %variable2%
echo.
pause

echo.
echo %variable3% %variable1% %variable2%
echo.
pause

echo.
echo otras variables:
echo %variable3%
echo %variable4%
echo %variable5%
echo %variable6%
echo %variable7%
echo %variable8%
echo %variable9%
echo %variable10%
echo %variable11%
echo %variable12%
pause
