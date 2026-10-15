@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"
title Hospital universitario
echo Hospital universitario - Aplicacion de escritorio
echo.
if exist ".venv_app\Scripts\python.exe" goto comprobar
py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
if not errorlevel 1 goto crear_py
python -c "import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)" >nul 2>&1
if not errorlevel 1 goto crear_python
echo No se encontro Python 3.10 o posterior.
echo Instala Python para Windows desde https://www.python.org/downloads/windows/
echo Cierra esta ventana y vuelve a abrir ABRIR_HOSPITAL.bat despues de instalarlo.
pause
exit /b 1
:crear_py
echo Preparando el programa por primera vez...
py -3 -m venv .venv_app
if errorlevel 1 goto fallo
goto comprobar
:crear_python
echo Preparando el programa por primera vez...
python -m venv .venv_app
if errorlevel 1 goto fallo
:comprobar
".venv_app\Scripts\python.exe" -c "import tkinter, pymysql, cryptography; from importlib.metadata import version; assert version('PyMySQL')=='1.2.3'" >nul 2>&1
if not errorlevel 1 goto abrir
echo Instalando el conector de MySQL. Esta primera vez necesita Internet.
".venv_app\Scripts\python.exe" -m pip install --disable-pip-version-check -r requirements.txt
if errorlevel 1 goto fallo
:abrir
echo Abriendo ventanas del hospital. MySQL debe estar instalado e iniciado.
".venv_app\Scripts\python.exe" -m app_hospital.main
if errorlevel 1 goto fallo
exit /b 0
:fallo
echo.
echo No se pudo iniciar el programa. Conserva el mensaje que aparece arriba.
echo Revisa tutorial_interfaz\TUTORIAL.md y confirma que extrajiste TODA la carpeta.
pause
exit /b 1
