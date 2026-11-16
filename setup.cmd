@echo off
rem 9router-setup para Windows: setup.cmd <comando>   (ex.: setup.cmd install)
rem Funciona no PowerShell (.\setup.cmd install) e no Prompt de Comando.
rem Usa o Git Bash (vem com o Git for Windows) para rodar os mesmos scripts do macOS/Linux.
setlocal
chcp 65001 >nul

set "NR_BASH="
for %%P in ("%ProgramFiles%\Git\bin\bash.exe" "%LocalAppData%\Programs\Git\bin\bash.exe" "%ProgramW6432%\Git\bin\bash.exe") do (
  if not defined NR_BASH if exist "%%~P" set "NR_BASH=%%~P"
)
if not defined NR_BASH (
  for /f "delims=" %%G in ('where git 2^>nul') do (
    if not defined NR_BASH if exist "%%~dpG..\bin\bash.exe" set "NR_BASH=%%~dpG..\bin\bash.exe"
  )
)
if not defined NR_BASH (
  echo [erro] Git Bash nao encontrado.
  echo        Instale o Git for Windows e abra um terminal novo:
  echo          winget install --id Git.Git -e
  echo        ou baixe em https://git-scm.com/download/win
  exit /b 1
)

set "NR_CMD=setup.cmd"
"%NR_BASH%" "%~dp0setup.sh" %*
exit /b %ERRORLEVEL%
