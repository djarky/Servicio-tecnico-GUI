' silent_launch.vbs
' Lanza launch.bat completamente oculto — sin ventana CMD visible.
'
' El acceso directo del Escritorio apunta a:
'   wscript.exe "C:\Program Files\ST-PRO\silent_launch.vbs"
'
' WindowStyle 0 = SW_HIDE (completamente invisible)
' False         = no esperar a que termine (no bloqueante)

Dim WshShell, strDir, strBat

Set WshShell = CreateObject("WScript.Shell")

' Obtener el directorio de este mismo script
strDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

' Ruta completa al launch.bat en el mismo directorio
strBat = strDir & "launch.bat"

' Ejecutar completamente oculto, sin ventana negra
WshShell.Run "cmd /c """ & strBat & """", 0, False

Set WshShell = Nothing
