# batrun

Aplicacion Lazarus/Free Pascal para:

- cargar un archivo `.bat`
- detectar variables `set NOMBRE=valor`
- editar esos valores en pantalla
- ejecutar el `.bat` sin modificar el archivo original

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
