# How to use Lume Converter (Windows)

This guide covers installing, running, and getting the most out of Lume Converter on Windows 10/11. You can either install a packaged build (when available) or run a local build from source.

## 1) Install or build

- Option A – Installer (recommended when available)
  - Download the installer from the official site or your release page.
  - Run the installer (accept UAC); follow the prompts.
  - The Explorer context menu entry will be added automatically.

- Option B – Build from source (portable)
  1. Requirements
     - Visual Studio 2022 (or VS Build Tools) with MSBuild
     - .NET Framework 4.8.1 Developer Pack
  2. Build (x64 Release)
     ```bat
     msbuild FileConverter.sln /m /restore /p:Configuration=Release /p:Platform=x64
     ```
  3. Runtime binaries (next to the app)
     - Ensure the following are present in `Application\FileConverter\bin\x64\Release`:
       - `ffmpeg.exe`
       - `gsdll64.dll`
       - `gswin64c.exe`
     - If missing, copy from `Middleware\ffmpeg\` and `Middleware\gs\`.

## 2) First launch

- Start the app (portable build)
  ```bat
  Application\FileConverter\bin\x64\Release\LumeConverter.exe
  ```
- With no arguments, the app opens a help window explaining it’s intended to be used from the Explorer right‑click menu.

## 3) Add to Explorer context menu (shell extension)

Installer usually does this automatically. For a local (portable) build:

1) Set the app path for the extension to find the executable (dev builds do this under HKCU):

- Launch Settings and click Save once to persist, or set the registry key manually.

2) Register the extension (requires elevation):

```bat
Application\FileConverter\bin\x64\Release\LumeConverter.exe --register-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
```

3) Restart Explorer (optional but recommended):
- Open Task Manager → restart “Windows Explorer”, or sign out/in.

Usage in Explorer:
- Windows 11: Right‑click a file → “Show more options” → “Lume Converter”.
- Windows 10: Right‑click a file → “Lume Converter”.

To uninstall the extension later:
```bat
Application\FileConverter\bin\x64\Release\LumeConverter.exe --unregister-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
```

## 4) Optional file associations (Open with Lume Converter)

Register per‑user “Open with Lume Converter” for common file types (portable builds):
```bat
LumeConverter.exe --register-associations
```
To remove:
```bat
LumeConverter.exe --unregister-associations
```

## 5) Everyday usage

- Explorer right‑click
  - Select one or many files → right‑click → Lume Converter → choose a preset (e.g., To Mp4, To Png, To Mp3).
- Drag-and-drop (portable or installed)
  - Open Lume Converter and drag files onto the window to enqueue them; click Start. (Uses the first/selected preset; adjust in Settings.)
- Watch folders (automatic conversions)
  - Open Settings → Application tab → “Watch folders” → add rows with Folder, Preset, Include subfolders.
  - New files appearing in those folders will be enqueued automatically.
- Clipboard after conversion (optional)
  - Settings → Application → “Copy files in clipboard after conversion”.

## 6) Developer auto‑reload (optional)

Enable one‑click auto‑rebuild and reload while editing code:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File DevTools\auto-reload.ps1
```

On save:
- Builds Release x64, ensures middleware, restarts the app, restarts Explorer when the extension DLL changes.

If msbuild is not found, install build tools or set the MSBUILD path:

```bat
winget install --id Microsoft.VisualStudio.2022.BuildTools --source winget --accept-package-agreements --accept-source-agreements --silent
set MSBUILD=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\MSBuild.exe
powershell -NoProfile -ExecutionPolicy Bypass -File DevTools\auto-reload.ps1
```

## 7) Command line (automation)

- Convert using a preset and explicit files
  ```bat
  LumeConverter.exe --conversion-preset "To Webm" "C:\path\to\input.mp4"
  ```
- Convert a list via a text file (one path per line)
  ```bat
  LumeConverter.exe --conversion-preset "To Mp3" --input-files "C:\temp\inputs.txt"
  ```
- Utilities
  ```bat
  LumeConverter.exe --settings
  LumeConverter.exe --version
  LumeConverter.exe --verbose
  LumeConverter.exe --post-install-init
  ```

## 8) Settings you may want to tweak

- Application language
- Maximum number of simultaneous conversions
- Exit behavior after conversions
- Hardware acceleration (CPU vs CUDA when available)
- Verify middleware integrity at startup (recommended)
- Watch folders (automatic conversions)
- Presets (quality, speed, scaling, rotation, audio bitrate, etc.)

## 9) Troubleshooting

- Context menu not visible
  - Windows 11: use “Show more options”.
  - Ensure shell extension is registered and Explorer has been restarted.
- Missing ffmpeg or Ghostscript (portable build)
  - Copy `ffmpeg.exe`, `gsdll64.dll`, and `gswin64c.exe` next to `LumeConverter.exe`.
- .NET Framework v4.8 reference assemblies error (MSB3644) when building
  - Install the .NET Framework 4.8/4.8.1 Developer Pack; retarget to 4.8.1 if needed.
- Magick.NET/ImageMagick warnings
  - Use the bundled versions or update both to compatible versions.
- Logs
  - Enable `--verbose`. Logs are under `C:\Users\<User>\AppData\Local\FileConverter\Diagnostics-*`.

## 10) Uninstall

- If installed via MSI/installer, remove from Apps & Features.
- If running portable, delete the folder.
- Unregister shell extension and file associations (if you added them) with the commands above.

---
If you need help, check the README and wiki, or open an issue in your repository.
