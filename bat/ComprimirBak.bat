@echo off
@echo ===========================================================
@echo Comprime con 7z los archivos .bak de la carpeta actual
@echo - antes de comprimir, elimina el .7z
@echo - despues de comprimir, elimina el .bak
@echo ===========================================================

rem ruta del ejecutable
::RUTA7Z="C:\Program Files\7-Zip\7z.exe"
set RUTA7Z="C:\Program Files\7-Zip\7z.exe"
rem mc puede ser 0-9
rem set /a MC=9
::MC=9
set MC=9

rem =============================================
echo Nivel de compresi¢n: %MC% de 9

set /a i=0
for %%f in (*.bak) do (
	IF EXIST "%%~nf.7z" ( del "%%~nf.7z" )
   %RUTA7Z% a -t7z "%%~nf.7z" "%%f" -mx=%MC%
   del "%%f"
   set /a i=i+1
)
rem =============================================
echo.
echo.
if %i%==0 (echo No se encuentran archivos .bak)
echo ==================================
echo    %i% ARCHIVO(S) PROCESADO(S) 
echo ==================================
timeout /t 2 /nobreak
