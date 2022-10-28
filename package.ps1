#!/usr/bin/env pwsh
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb-geek-pi/SQLite.Interop.
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

$VERSION = "1.0.111.0"
$SHA256 = "C6C308CCB2718B18F543CF2E7E8490EC6284854B6397BF20D9EDE462F6FF2FFC"
$ZIPNAME = "sqlite-netFx-source-$VERSION.zip"
$INTEROP_RC_VERSION = $VERSION.Replace('.',',')

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

foreach ($Name in "bin", "obj", "runtimes", "SQLite.Interop-$VERSION-win.zip") {
	if (Test-Path "$Name") {
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


(
	( "x86","${Env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars32.bat"),
	( "x64","${Env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"),
	( "arm","${Env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsamd64_arm.bat"),
	( "arm64","${Env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsamd64_arm64.bat")
) | foreach {
	$ARCH = $_[0]
	$VCVARS = $_[1]

	@"
CALL "$VCVARS"
IF ERRORLEVEL 1 EXIT %ERRORLEVEL%
NMAKE /NOLOGO -f SQLite.Interop.mak INTEROP_RC_VERSION="$INTEROP_RC_VERSION" SRCROOT="src"
EXIT %ERRORLEVEL%
"@ | & "$env:COMSPEC"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	$RID = "win-$ARCH"
	$RIDDIR = "runtimes\$RID\native\netstandard2.0"

	$null = New-Item -Path "." -Name "$RIDDIR" -ItemType "directory"

	$null = Move-Item -Path "bin\$ARCH\SQLite.Interop.dll" -Destination "$RIDDIR"
}

Compress-Archive -DestinationPath "SQLite.Interop-$VERSION-win.zip" -LiteralPath "runtimes"

Write-Host "Build complete"
