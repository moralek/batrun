# batrun

Aplicacion Lazarus/Free Pascal para:

- cargar un archivo `.bat`
- detectar variables `set NOMBRE=valor`
- editar esos valores en pantalla
- ejecutar el `.bat`

## Variables editables desde la GUI

La aplicacion solo muestra en la GUI aquellas variables que esten marcadas con
un comentario inmediatamente anterior en este formato:

```bat
::variable1=hola
set variable1=hola
```

Ejemplo:

```bat
@echo off

::variable1=hola
set variable1=hola

set variable2=mundo
```

En este caso:

- `variable1` aparecera en la GUI
- `variable2` no aparecera en la GUI

Si cambias `variable1` en la GUI a `chao`, el archivo `.bat` original quedara:

```bat
::variable1=hola
set variable1=chao
```

La linea `::variable1=hola` funciona como marca para indicar que esa variable
puede editarse desde la interfaz.

## Comportamiento actual de la GUI

- `Restablecer` vuelve la variable a su valor por defecto y actualiza el `.bat`.
- `Restablecer todas` vuelve todas las variables a sus valores por defecto y actualiza el `.bat`.
- La GUI muestra como maximo 10 variables editables.
- Si el `.bat` tiene mas de 10 variables editables, aparece la advertencia `hay mas de 10 variables`.
- El boton `Ejecutar` se ubica debajo de la ultima variable, alineado a la derecha.

## Estructura

- `batrun.lpi`: proyecto Lazarus
- `batrun.lpr`: punto de entrada
- `uMain.pas`: logica principal
- `uMain.lfm`: diseno del formulario
- `build.sh`: entrypoint rapido para generar `target/batrun.exe`
- `tools/ppc386-win32-wrapper.sh`: wrapper del compilador Win32/i386
- `tools/write-fpc-win32-cfg.sh`: genera `target/fpc-win32.cfg`
- `tools/build-win32.sh`: build reproducible de `Win32/i386`
- `bat/`: carpeta para `.bat` de prueba
- `target/`: salida de compilacion

## Compilacion

Compilar desde Lazarus abriendo `batrun.lpi`, o por linea de comandos.

### Windows desde Lazarus

```powershell
C:\lazarus\lazbuild.exe .\batrun.lpi
```

### Win32 desde Linux con cross-compiler

Flujo reproducible validado en este repo:

```bash
bash build.sh
```

El ejecutable se genera en:

```text
target\batrun.exe
```

Ese script:

- delega en `tools/build-win32.sh`
- genera `target/fpc-win32.cfg`
- usa `tools/ppc386-win32-wrapper.sh`
- usa `target/lazarus-pcp-win32` como configuracion local de Lazarus
- genera `target/batrun.exe`

Prerequisitos esperados por defecto para el build Win32 desde Linux:

- compilador `ppc386` en `/tmp/fpc-i386-root/usr/lib/i386-linux-gnu/fpc/3.2.2/ppc386`
- unidades Win32 de FPC en `/tmp/fpc-win32-manual/app/units/i386-win32`
- Lazarus en `/usr/lib/lazarus/default`

En el caso normal no hace falta configurar nada mas:

```bash
bash build.sh
```

Solo si esas rutas cambian en otra maquina o en otra instancia de Codex, se
pueden sobrescribir temporalmente con variables de entorno:

```bash
BATRUN_PPC386=/ruta/al/ppc386 \
BATRUN_FPC_WIN32_UNITS_ROOT=/ruta/a/app/units/i386-win32 \
BATRUN_LAZARUS_DIR=/ruta/a/lazarus \
bash build.sh
```

## Notas

- La aplicacion recuerda el ultimo `.bat` cargado usando `target\batrun.ini`.
- La ejecucion del script se hace en `cmd.exe` externo.
- Si un `.bat` no tiene variables marcadas con `::NOMBRE=valor`, igual puede
  ejecutarse, pero sin reemplazos desde la GUI.
