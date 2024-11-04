#!/usr/bin/env pwsh
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLite.Interop.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

param(
	$CertificateThumbprint = '601A8B683F791E51F647D34AD102C38DA4DDB65F'
)

$VERSION = "1.0.119.0"
$SHA256 = "258BD0A766FC9DC678398CA366868354B2BBE22BDA90A4BD2FD505489D1A5D83"
$ZIPNAME = "sqlite-netFx-source-$VERSION.zip"
$INTEROP_RC_VERSION = $VERSION.Replace('.',',')

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

foreach ($EDITION in 'Community', 'Professional')
{
	$VCVARSDIR = "${Env:ProgramFiles}\Microsoft Visual Studio\2022\$EDITION\VC\Auxiliary\Build"

	if ( Test-Path -LiteralPath $VCVARSDIR -PathType Container )
	{
		break
	}
}

$VCVARSARM = 'vcvarsarm.bat'
$VCVARSARM64 = 'vcvarsarm64.bat'
$VCVARSAMD64 = 'vcvars64.bat'
$VCVARSX86 = 'vcvars32.bat'
$VCVARSHOST = 'vcvars32.bat'

switch ($Env:PROCESSOR_ARCHITECTURE)
{
	'AMD64' {
		$VCVARSX86 = 'vcvarsamd64_x86.bat'
		$VCVARSARM = 'vcvarsamd64_arm.bat'
		$VCVARSARM64 = 'vcvarsamd64_arm64.bat'
		$VCVARSHOST = $VCVARSAMD64
	}
	'ARM64' {
		$VCVARSX86 = 'vcvarsarm64_x86.bat'
		$VCVARSARM = 'vcvarsarm64_arm.bat'
		$VCVARSAMD64 = 'vcvarsarm64_amd64.bat'
		$VCVARSHOST = $VCVARSARM64
	}
	'X86' {
		$VCVARSXARM64 = 'vcvarsx86_arm64.bat'
		$VCVARSARM = 'vcvarsx86_arm.bat'
		$VCVARSAMD64 = 'vcvarsx86_amd64.bat'
	}
	Default {
		throw "Unknown architecture $Env:PROCESSOR_ARCHITECTURE"
	}
}

$VCVARSARCH = @{'arm' = $VCVARSARM; 'arm64' = $VCVARSARM64; 'x86' = $VCVARSX86; 'x64' = $VCVARSAMD64}

$ARCHLIST = ( $VCVARSARCH.Keys | ForEach-Object {
	$VCVARS = $VCVARSARCH[$_];
	if ( Test-Path -LiteralPath "$VCVARSDIR/$VCVARS" -PathType Leaf )
	{
		$_
	}
} | Sort-Object )

$ARCHLIST | ForEach-Object {
	New-Object PSObject -Property @{
			Architecture=$_;
			Environment=$VCVARSARCH[$_]
	}
} | Format-Table -Property Architecture,'Environment'

foreach ($Name in "bin", "obj", "runtimes", "SQLite.Interop-$VERSION-win.zip")
{
	if (Test-Path "$Name")
	{
		Remove-Item "$Name" -Force -Recurse
	} 
}

if (-not(Test-Path -Path "src"))
{
	if (-not(Test-Path -Path $ZIPNAME))
	{
		Invoke-WebRequest -Uri "https://system.data.sqlite.org/blobs/$VERSION/$ZIPNAME" -OutFile $ZIPNAME
	}

	if ((Get-FileHash -LiteralPath $ZIPNAME -Algorithm "SHA256").Hash -ne $SHA256)
	{
		throw "SHA256 mismatch for $ZIPNAME"
	}

	Expand-Archive -Path $ZIPNAME -DestinationPath "src"
}

$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

Get-ChildItem -Path "src\SQLite.Interop\src\contrib" -Filter *.c -Recurse | foreach {
	[string]$FileName = $_

	Write-Host "Reading $FileName"

	[string]$Content = [System.IO.File]::ReadAllText($FileName)

	$Changed = $False

	(
		( 'typedef signed int int16_t;', 'typedef signed short int16_t;' ),
		( 'typedef unsigned int uint16_t;', 'typedef unsigned short uint16_t;' ),
		( 'typedef signed long int int32_t;', 'typedef signed int int32_t;' ),
		( 'typedef unsigned long int uint32_t;', 'typedef unsigned int uint32_t;' )
	) | foreach {
		if ($Content.Contains($_[0])) {
			$Content = $Content.Replace($_[0], $_[1])
			$Changed = $True
		}
	}

	if ($Changed) {
		Write-Host "Writing $FileName"
		[System.IO.File]::WriteAllText($FileName, $Content, $Utf8NoBomEncoding)
	}
}

foreach ( $ARCH in $ARCHLIST )
{
	$VCVARS = $VCVARSARCH[$ARCH]

	@"
CALL "$VCVARSDIR\$VCVARS"
IF ERRORLEVEL 1 EXIT %ERRORLEVEL%
NMAKE /NOLOGO -f SQLite.Interop.mak INTEROP_RC_VERSION="$INTEROP_RC_VERSION" SRCROOT="src"
IF ERRORLEVEL 1 EXIT %ERRORLEVEL%
signtool sign /a /sha1 "$CertificateThumbprint" /fd SHA256 /t http://timestamp.digicert.com "bin\$ARCH\SQLite.Interop.dll"
EXIT %ERRORLEVEL%
"@ | & "$env:COMSPEC"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	$RID = "win-$ARCH"
	$RIDDIR = "runtimes\$RID\native"

	$null = New-Item -Path "." -Name "$RIDDIR" -ItemType "directory"

	$null = Move-Item -Path "bin\$ARCH\SQLite.Interop.dll" -Destination "$RIDDIR"
}

Compress-Archive -DestinationPath "SQLite.Interop-$VERSION-win.zip" -LiteralPath "runtimes"

$ARCHLIST | ForEach-Object {
	$ARCH = $_
	$VCVARS = ( '{0}\{1}' -f $VCVARSDIR, $VCVARSARCH[$ARCH] )
	$EXE = "runtimes\win-$ARCH\native\SQLite.Interop.dll"

	$MACHINE = ( @"
@CALL "$VCVARS" > NUL:
IF ERRORLEVEL 1 EXIT %ERRORLEVEL%
dumpbin /headers $EXE
IF ERRORLEVEL 1 EXIT %ERRORLEVEL%
EXIT %ERRORLEVEL%
"@ | & "$env:COMSPEC" /nologo /Q | Select-String -Pattern " machine " )

	$MACHINE = $MACHINE.ToString().Trim()

	$MACHINE = $MACHINE.Substring($MACHINE.LastIndexOf(' ')+1)

	New-Object PSObject -Property @{
			Architecture=$ARCH;
			Executable=$EXE;
			Machine=$MACHINE
	}
} | Format-Table -Property Architecture, Executable, Machine

Write-Host "Build complete"
