@echo off
::variable1=hola
set variable1=hola

::variable2=mundo
set variable2=mundo
set /a var=1+1
::variable3=variable3
set variable3=variable3
set variable4=variable4
set variable5=variable5
set variable6=variable6
set variable7=variable7
set variable8=variable8
set variable9="variable9"
set variable10=variable10
set variable11=variable11
set variable12=variable12

echo.
echo %variable1% %variable2%
pause

echo.
echo nuevamente %variable1% %variable2%
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
