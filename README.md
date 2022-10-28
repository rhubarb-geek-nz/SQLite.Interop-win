# SQLite.Interop Packaging

This project builds SQLite.Interop.dll as platform specific binaries for `win-arm`, `win-arm64`, `win-x86` and `win-x64`.

The `package.ps1` script will build from the versioned source for [System.Data.SQLite](https://system.data.sqlite.org). See script for URL and SHA256.

The `test.ps1` script will use both `sqlite3` and `dotnet` to perform a test of the binary dll. The `test.csproj` uses the [NuGet System.Data.SQLite.Core](https://www.nuget.org/packages/System.Data.SQLite.Core/) package.

The project requires

- [Visual Studio 2022](https://visualstudio.microsoft.com/vs/), Community Edition is sufficient
- [PowerShell](https://github.com/PowerShell/PowerShell), tested with 7.2.7
- [.NET 6.0](https://dotnet.microsoft.com/en-us/download/dotnet/6.0), full SDK required

These scripts are licensed using [GPLv3](http://www.gnu.org/licenses). [SQLite is public domain](https://www.sqlite.org/copyright.html).

See also [SQLite](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki) and [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).
