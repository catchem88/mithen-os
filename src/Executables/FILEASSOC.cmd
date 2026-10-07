@echo off
REM FILEASSOC.cmd [mithen|photos]
REM   mithen - points images at MithenView, documents at MithenPDF, archives at MithenZip, video at MithenPlayer
REM   photos - fallback used when Photos is removed but the Mithen apps are not installed
setlocal enabledelayedexpansion

set "MODE=%~1"
if "%MODE%"=="" set "MODE=photos"

set "MIT="
if exist "%ProgramFiles%\MithenView\mithen-view.exe" set "MIT=1"

if /I "%MODE%"=="mithen" (
	if not defined MIT exit /b 0
	copy /y "OEMDefaultAssociations-Mithen.xml" "%WINDIR%\System32\OEMDefaultAssociations.xml" >NUL 2>nul
	set "ARGS=.jpg:MithenView.Image .jpeg:MithenView.Image .jfif:MithenView.Image .jpe:MithenView.Image .png:MithenView.Image .gif:MithenView.Image .bmp:MithenView.Image .dib:MithenView.Image .webp:MithenView.Image .ico:MithenView.Image .tif:MithenView.Image .tiff:MithenView.Image .svg:MithenView.Image .avif:MithenView.Image .heic:MithenView.Image .heif:MithenView.Image .jxl:MithenView.Image .jxr:MithenView.Image .wdp:MithenView.Image .tga:MithenView.Image .jp2:MithenView.Image .pdf:MithenPDF.pdf .xps:MithenPDF.xps .oxps:MithenPDF.oxps .epub:MithenPDF.epub .mobi:MithenPDF.mobi .cbz:MithenPDF.cbz .cbr:MithenPDF.cbr .cb7:MithenPDF.cb7 .cbt:MithenPDF.cbt .djvu:MithenPDF.djvu .chm:MithenPDF.chm .fb2:MithenPDF.fb2 .azw:MithenPDF.azw .azw3:MithenPDF.azw3 .md:MithenPDF.md .markdown:MithenPDF.markdown .zip:MithenZip.Archive .7z:MithenZip.Archive .rar:MithenZip.Archive .tar:MithenZip.Archive .gz:MithenZip.Archive .bz2:MithenZip.Archive .xz:MithenZip.Archive .iso:MithenZip.Archive .cab:MithenZip.Archive .lzma:MithenZip.Archive .zst:MithenZip.Archive .tgz:MithenZip.Archive .mkv:mpc-be64.mkv .mp4:mpc-be64.mp4 .avi:mpc-be64.avi .mov:mpc-be64.mov .wmv:mpc-be64.wmv .webm:mpc-be64.webm .m4v:mpc-be64.m4v .flv:mpc-be64.flv .ts:mpc-be64.ts .m2ts:mpc-be64.m2ts .mpg:mpc-be64.mpg .mpeg:mpc-be64.mpeg .vob:mpc-be64.vob .rmvb:mpc-be64.rmvb .3gp:mpc-be64.3gp .ogv:mpc-be64.ogv .divx:mpc-be64.divx .asf:mpc-be64.asf .mts:mpc-be64.mts .m2t:mpc-be64.m2t"
) else (
	REM The Mithen pass already handles images when MithenView is installed
	if defined MIT exit /b 0
	copy /y "OEMDefaultAssociations.xml" "%WINDIR%\System32\OEMDefaultAssociations.xml" >NUL 2>nul
	set "ARGS=.bmp:PhotoViewer.FileAssoc.Bitmap .dib:PhotoViewer.FileAssoc.Bitmap .jfif:PhotoViewer.FileAssoc.JFIF .jpe:PhotoViewer.FileAssoc.Jpeg .jpeg:PhotoViewer.FileAssoc.Jpeg .jpg:PhotoViewer.FileAssoc.Jpeg .jxr:PhotoViewer.FileAssoc.Wdp .png:PhotoViewer.FileAssoc.Png .tif:PhotoViewer.FileAssoc.Tiff .tiff:PhotoViewer.FileAssoc.Tiff .wdp:PhotoViewer.FileAssoc.Wdp"
)

for /f "usebackq tokens=2 delims=\" %%A in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	REM If the "Volatile Environment" key exists, that means it is a proper user. Built in accounts/SIDs don't have this key.
	reg query "HKU\%%A" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" > NUL 2>&1
	if not errorlevel 1 (
		PowerShell -NoP -ExecutionPolicy Bypass -File assoc.ps1 "Placeholder" "%%A" !ARGS!
	)
)
