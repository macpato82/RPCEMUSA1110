; Inno Setup script for the RPCEmu SA-1110 fork (Windows).
; Builds a self-contained installer from the staged dist\rpcemu-windows folder,
; which already includes the executable, all required DLLs and Qt plugins, the
; redistributable RISC OS 5 ROM (roms\RISCPC.ROM), and the support data.
;
; Compile from the repository root:
;   iscc packaging\windows-installer.iss

#define AppName "RPCEmu (SA-1110 fork)"
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=RISCOS Technologies
DefaultDirName={autopf}\RPCEmu
DefaultGroupName=RPCEmu
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=RPCEmu-SA1110-Setup
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
; Everything that was staged for the portable build (exe, DLLs, plugins,
; roms\RISCPC.ROM, configs, poduleroms, resources, docs).
; Path is relative to this .iss file (in packaging/), so go up to the repo root.
Source: "..\dist\rpcemu-windows\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\RPCEmu"; Filename: "{app}\RPCEmu-Interpreter.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall RPCEmu"; Filename: "{uninstallexe}"
Name: "{autodesktop}\RPCEmu"; Filename: "{app}\RPCEmu-Interpreter.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\RPCEmu-Interpreter.exe"; WorkingDir: "{app}"; Description: "Launch RPCEmu now"; Flags: nowait postinstall skipifsilent
