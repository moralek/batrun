# batrun

Aplicación Lazarus/Free Pascal para:

- cargar un archivo `.bat`
- detectar variables `set NOMBRE=valor`
- editar esos valores en pantalla
- ejecutar el `.bat`

## Variables editables desde la GUI

Por defecto, la GUI muestra todas las líneas con este formato:

```bat
set variable1=hola
```

Opcionalmente, desde `Configuración -> Usar solo precomentadas con ::`, la app
puede limitar la GUI solo a variables marcadas con un comentario inmediatamente
anterior en este formato:

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

En ese modo:

- `variable1` aparecerá en la GUI
- `variable2` no aparecerá en la GUI

Si cambias `variable1` en la GUI a `chao`, el archivo `.bat` original quedará:

```bat
::variable1=hola
set variable1=chao
```

La línea `::variable1=hola` funciona como valor por defecto explícito para esa
variable.

## Comportamiento actual de la GUI

- Se puede cargar un `.bat` con `Abrir...` o arrastrándolo sobre la aplicación.
- `Restablecer` solo aparece en variables que ya tienen `::NOMBRE=valor`.
- `Restablecer todas` solo afecta variables que ya tienen `::NOMBRE=valor`.
- Cada variable tiene una acción `+` para definir el valor actual como default.
- `Definir todas como default` agrega o actualiza `::NOMBRE=valor` para todas las variables visibles.
- La GUI muestra como máximo 10 variables editables.
- Si el `.bat` tiene más de 10 variables editables, aparece la advertencia `hay más de 10 variables`.
- El boton `Ejecutar` se ubica debajo de la última variable, alineado a la derecha.
- La preferencia `Usar solo precomentadas con ::` se guarda en el `.ini`.

## Estructura

- `batrun.lpi`: proyecto Lazarus
- `batrun.lpr`: punto de entrada
- `uMain.pas`: lógica principal
- `uMain.lfm`: diseño del formulario
- `build.sh`: entrypoint rápido para generar `target/batrun.exe`
- `tools/ppc386-win32-wrapper.sh`: wrapper del compilador Win32/i386
- `tools/write-fpc-win32-cfg.sh`: genera `target/fpc-win32.cfg`
- `tools/build-win32.sh`: build reproducible de `Win32/i386`
- `bat/`: carpeta para `.bat` de prueba
- `target/`: salida de compilación

## Compilación

Compilar desde Lazarus abriendo `batrun.lpi`, o por línea de comandos.

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
- usa `target/lazarus-pcp-win32` como configuración local de Lazarus
- genera `target/batrun.exe`

Prerequisitos esperados por defecto para el build Win32 desde Linux:

- compilador `ppc386` en `/tmp/fpc-i386-root/usr/lib/i386-linux-gnu/fpc/3.2.2/ppc386`
- unidades Win32 de FPC en `/tmp/fpc-win32-manual/app/units/i386-win32`
- Lazarus en `/usr/lib/lazarus/default`

En el caso normal no hace falta configurar nada más:

```bash
bash build.sh
```

Solo si esas rutas cambian en otra máquina o en otra instancia de Codex, se
pueden sobrescribir temporalmente con variables de entorno:

```bash
BATRUN_PPC386=/ruta/al/ppc386 \
BATRUN_FPC_WIN32_UNITS_ROOT=/ruta/a/app/units/i386-win32 \
BATRUN_LAZARUS_DIR=/ruta/a/lazarus \
bash build.sh
```

## Notas

- La aplicación recuerda el último `.bat` cargado usando `target\batrun.ini`.
- La ejecución del script se hace en `cmd.exe` externo.
- Si `Usar solo precomentadas con ::` está desactivado, también se muestran en la GUI las variables `set NOMBRE=valor` sin comentario previo.
