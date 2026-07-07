@echo off
setlocal

set VBOX="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

del boot.bin 2>nul
del stage2.bin 2>nul
del disk.img 2>nul
del os.vdi 2>nul

nasm boot.asm -f bin -o boot.bin
if errorlevel 1 goto error

nasm stage2.asm -f bin -o stage2.bin
if errorlevel 1 goto error

fsutil file createnew disk.img 10485760

powershell -Command "$disk=[System.IO.File]::Open('disk.img','Open','ReadWrite'); $boot=[System.IO.File]::ReadAllBytes('boot.bin'); $stage2=[System.IO.File]::ReadAllBytes('stage2.bin'); $disk.Seek(0,[System.IO.SeekOrigin]::Begin) > $null; $disk.Write($boot,0,$boot.Length); $disk.Seek(512,[System.IO.SeekOrigin]::Begin) > $null; $disk.Write($stage2,0,$stage2.Length); $disk.Close()"

%VBOX% convertfromraw disk.img os.vdi --format VDI
if errorlevel 1 goto error

echo.
echo Build complete.
echo Output: os.vdi
goto end

:error
echo.
echo Build failed.

:end
pause