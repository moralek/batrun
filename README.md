# batrun

Aplicacion Lazarus/Free Pascal para:

- cargar un archivo `.bat`
- detectar variables `set NOMBRE=valor`
- editar esos valores en pantalla
- ejecutar el `.bat` sin modificar el archivo original

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

## Estructura

- `batrun.lpi`: proyecto Lazarus
- `batrun.lpr`: punto de entrada
- `uMain.pas`: logica principal
- `uMain.lfm`: diseno del formulario
- `bat/`: carpeta para `.bat` de prueba
- `target/`: salida de compilacion

## Compilacion

Compilar desde Lazarus abriendo `batrun.lpi`, o por linea de comandos con:

```powershell
C:\lazarus\lazbuild.exe .\batrun.lpi
```

El ejecutable se genera en:

```text
target\batrun.exe
```

## Notas

- La aplicacion recuerda el ultimo `.bat` cargado usando `target\batrun.ini`.
- La ejecucion del script se hace en `cmd.exe` externo.
- Si un `.bat` no tiene variables marcadas con `::NOMBRE=valor`, igual puede
  ejecutarse, pero sin reemplazos desde la GUI.
