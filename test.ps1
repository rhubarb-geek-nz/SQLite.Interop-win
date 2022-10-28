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

$VERSION = "1.0.113.0"
$TOOLS = "sqlite-tools-win32-x86-3390400"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

foreach ($Name in "bin", "obj") {
	if (Test-Path "$Name") {
		Remove-Item "$Name" -Force -Recurse
	} 
}

& "dotnet.exe" build "test.csproj" --configuration Release

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

If (-not(Test-Path "test.db"))
{
	Write-Host "Following should succeed and create a database"

	if (-not(Test-Path -Path "$TOOLS"))
	{
		if (-not(Test-Path -Path "$TOOLS.zip"))
		{
			Invoke-WebRequest -Uri "https://www.sqlite.org/2022/$TOOLS.zip" -OutFile "$TOOLS.zip"
		}

		Expand-Archive -Path "$TOOLS.zip" -DestinationPath .
	}

@"
CREATE TABLE MESSAGES (
	CONTENT VARCHAR(256)
);

INSERT INTO MESSAGES (CONTENT) VALUES ('Hello World');

SELECT * FROM MESSAGES;
"@ | & "$TOOLS\sqlite3.exe" test.db

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}

if (("$env:PROCESSOR_ARCHITECTURE" -eq "x86") -or ("$env:PROCESSOR_ARCHITECTURE" -eq "AMD64"))
{
	Write-Host "Following should succeed and read the database"

	& "dotnet.exe" "bin\Release\net6.0\test.dll"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}

Remove-Item "bin\Release\net6.0\runtimes" -Force -Recurse

Write-Host "Following should fail with missing SQLite.Interop.dll"

& "dotnet.exe" "bin\Release\net6.0\test.dll"

If ( $LastExitCode -eq 0 )
{
	throw "This should have failed with no SQLite.Interop.dll"
}

if (-not(Test-Path "runtimes"))
{
	Expand-Archive -Path SQLite.Interop-$VERSION-win.zip -DestinationPath "."
}

switch ( "$env:PROCESSOR_ARCHITECTURE" )
{
	"x86"   { Copy-Item -LiteralPath "runtimes\win-x86\native\netstandard2.0\SQLite.Interop.dll"   -Destination "bin\Release\net6.0" }
	"AMD64" { Copy-Item -LiteralPath "runtimes\win-x64\native\netstandard2.0\SQLite.Interop.dll"   -Destination "bin\Release\net6.0" }
	"ARM"   { Copy-Item -LiteralPath "runtimes\win-arm\native\netstandard2.0\SQLite.Interop.dll"   -Destination "bin\Release\net6.0" }
	"ARM64" { Copy-Item -LiteralPath "runtimes\win-arm64\native\netstandard2.0\SQLite.Interop.dll" -Destination "bin\Release\net6.0" }
	default { throw "Unknown architecure" }
}

Write-Host "Following should succeed and read the database"

& "dotnet.exe" "bin\Release\net6.0\test.dll"

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

Write-Host "Tests complete"
