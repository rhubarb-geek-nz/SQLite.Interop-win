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

SRCDIR=$(SRCROOT)\SQLite.Interop\src
RESDIR=$(SRCROOT)\System.Data.SQLite\Resources
OBJDIR=obj\$(VSCMD_ARG_TGT_ARCH)
BINDIR=bin\$(VSCMD_ARG_TGT_ARCH)

all: $(BINDIR)\SQLite.Interop.dll

CC_OPTIONS= /DWINVER=0x600 \
		/I$(SRCDIR)\core \
		/DINTEROP_PLACEHOLDER=1 \
		/DINTEROP_EXTENSION_FUNCTIONS=1 \
		/DINTEROP_VIRTUAL_TABLE=1 \
		/DINTEROP_FTS5_EXTENSION=1 \
		/DINTEROP_PERCENTILE_EXTENSION=1 \
		/DINTEROP_TOTYPE_EXTENSION=1 \
		/DINTEROP_REGEXP_EXTENSION=1 \
		/DINTEROP_JSON1_EXTENSION=1 \
		/DINTEROP_SHA1_EXTENSION=1 \
		/DINTEROP_SESSION_EXTENSION=1 \
		/D_CRT_SECURE_NO_DEPRECATE \
		/D_CRT_SECURE_NO_WARNINGS \
		/D_CRT_NONSTDC_NO_DEPRECATE \
		/D_CRT_NONSTDC_NO_WARNINGS \
		/DSQLITE_THREADSAFE=1 \
		/DSQLITE_USE_URI=1 \
		/DSQLITE_ENABLE_COLUMN_METADATA=1 \
		/DSQLITE_ENABLE_STAT4=1 \
		/DSQLITE_ENABLE_FTS3=1 \
		/DSQLITE_ENABLE_LOAD_EXTENSION=1 \
		/DSQLITE_ENABLE_RTREE=1 \
		/DSQLITE_SOUNDEX=1 \
		/DSQLITE_ENABLE_MEMORY_MANAGEMENT=1 \
		/DSQLITE_ENABLE_API_ARMOR=1 \
		/DSQLITE_ENABLE_DBSTAT_VTAB=1 \
		/DSQLITE_ENABLE_STMTVTAB=1 \
		/DSQLITE_WIN32_MALLOC=1 \
		/DSQLITE_HAS_CODEC=1 \
		/DSQLITE_OS_WIN=1 \
		/DNDEBUG=1 \
		/DUNICODE=1

clean:
	if exist "$(OBJDIR)" rmdir /q /s "$(OBJDIR)"
	if exist "$(BINDIR)" rmdir /q /s "$(BINDIR)"

$(OBJDIR) $(BINDIR):
	mkdir $@

$(OBJDIR)\SQLite.Interop.res: $(SRCDIR)\win\SQLite.Interop.rc $(OBJDIR)
	rc.exe $(RCFLAGS) /r /nologo /dINTEROP_RC_VERSION=$(INTEROP_RC_VERSION) /fo$@ $(SRCDIR)\win\SQLite.Interop.rc

$(OBJDIR)\interop.obj: $(OBJDIR) $(SRCDIR)\generic\interop.c
	cl.exe /MT /nologo /c /Fo$@ \
		$(CC_OPTIONS) \
		$(SRCDIR)\generic\interop.c

$(BINDIR)\SQLite.Interop.dll: $(OBJDIR)\SQLite.Interop.res $(OBJDIR)\interop.obj $(BINDIR)
	cl.exe /MT /nologo /LD /Fe$@ \
		$(CC_OPTIONS) \
		$(OBJDIR)\interop.obj \
		/link \
		/INCREMENTAL:NO \
		/NOLOGO \
		$(OBJDIR)\SQLite.Interop.res \
		/ASSEMBLYRESOURCE:$(RESDIR)\System.Data.SQLite\Resources\SQLiteCommand.bmp,System.Data.SQLite.SQLiteCommand.bmp \
		/ASSEMBLYRESOURCE:$(RESDIR)\System.Data.SQLite\Resources\SQLiteConnection.bmp,System.Data.SQLite.SQLiteConnection.bmp \
		/ASSEMBLYRESOURCE:$(RESDIR)\System.Data.SQLite\Resources\SQLiteDataAdapter.bmp,System.Data.SQLite.SQLiteDataAdapter.bmp \
		/VERSION:1.0
