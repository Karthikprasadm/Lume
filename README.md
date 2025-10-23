# File Converter

## Description

**File Converter** is a very simple tool which allows you to convert and compress one or several file(s) using the context menu of windows explorer.

![File Converter Usage](Resources/FileConverterUsage.gif)

You can download it here: [file-converter.io](https://file-converter.io/?from=readme.md).

You can find more information about what's in File converter and how to use it on the [wiki](https://github.com/Tichau/FileConverter/wiki).

## Donate

File Converter is a personal open source project started in 2014. I have put hundreds of hours adding, refining and tuning File Converter with the goal of making the conversion and compression of files an easy task for everyone.

You can help me by [contributing to the project](https://github.com/Tichau/FileConverter/wiki#contribute), by [making a donation](https://www.paypal.com/donate/?cmd=_donations&business=3BDWQTYTTA3D8&item_name=File+Converter+Donations&currency_code=EUR&Z3JncnB0=) or just by [saying thanks​](https://saythanks.io/to/Tichau) :).

## Troubleshooting

If you encounter any problem with File Converter, you can:

* See the already known problems in the [troubleshooting section of the documentation](https://github.com/Tichau/FileConverter/wiki/Troubleshooting).
* Or report an issue on the [bug tracker](https://github.com/Tichau/FileConverter/issues).

## Setup development environment

### Requirements

For File Converter and its explorer extension:

* Visual Studio 2022

For the installer:

* [Wix 5](http://wixtoolset.org/) (will be installed by nuget)
  * [Community Visual Studio Extension](https://marketplace.visualstudio.com/items?itemName=FireGiant.FireGiantHeatWaveDev17)
* [Windows SDK Signing Tools for Desktop Apps](https://developer.microsoft.com/fr-fr/windows/downloads/windows-10-sdk)

### Quick start (build and run from source)

1. Install Visual Studio 2022 Build Tools (MSBuild workload).
2. Install the .NET Framework 4.8.1 Developer Pack (reference assemblies).
3. Build (x64 Release):

   ```bash
   msbuild FileConverter.sln /m /restore /p:Configuration=Release /p:Platform=x64
   ```

4. Run the application:

   ```bash
   Application\FileConverter\bin\x64\Release\FileConverter.exe
   ```

Note: Building the solution (not only the project) also builds the Explorer shell extension and copies required middlewares next to the executable.

### Register the Explorer shell extension (developer setup)

The app integrates into Windows Explorer’s context menu via a COM shell extension. For a developer build:

1. Ensure the app path is discoverable (normally handled by the installer). For dev runs, the shell extension reads `HKCU\Software\FileConverter` value `Path` to locate the executable.
2. Register the extension using the app itself (requires elevation):

   ```bash
   Application\FileConverter\bin\x64\Release\FileConverter.exe --register-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
   ```

3. To unregister:

   ```bash
   Application\FileConverter\bin\x64\Release\FileConverter.exe --unregister-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
   ```

4. Reload Explorer to pick up changes (Windows 11/10): restart the “Windows Explorer” process from Task Manager, or sign out/in.

Tip (Windows 11): the entry lives under “Show more options” in the right‑click menu.

### Command‑line usage (advanced)

The GUI can be driven from the command line for automation:

- Show settings window

  ```bash
  FileConverter.exe --settings
  ```

- Convert using a preset and explicit files

  ```bash
  FileConverter.exe --conversion-preset "To Webm" "C:\path\to\input.mp4"
  ```

- Convert a list of files via a text file (one path per line)

  ```bash
  FileConverter.exe --conversion-preset "To Mp3" --input-files "C:\temp\inputs.txt"
  ```

- Misc utilities

  ```bash
  FileConverter.exe --version
  FileConverter.exe --verbose
  FileConverter.exe --post-install-init
  ```

## Troubleshooting for developers

- MSBuild not found

  ```bash
  winget install --id Microsoft.VisualStudio.2022.BuildTools --source winget \
    --accept-package-agreements --accept-source-agreements
  # Locate MSBuild
  "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find "MSBuild\\**\\Bin\\MSBuild.exe"
  ```

- .NETFramework v4.8 reference assemblies missing (MSB3644)

  Install the developer pack and/or retarget to 4.8.1:

  ```bash
  winget install --id Microsoft.DotNet.Framework.DeveloperPack_4 --source winget \
    --accept-package-agreements --accept-source-agreements
  # Or edit csproj: <TargetFrameworkVersion>v4.8.1</TargetFrameworkVersion>
  ```

- Post‑build copy shows "*Undefined*Middleware" when building only the project

  Build the solution `FileConverter.sln` (so `$(SolutionDir)` is set) or copy required middleware next to the exe:

  ```bash
  copy /Y Middleware\ffmpeg\ffmpeg.exe Application\FileConverter\bin\x64\Release\ffmpeg.exe
  copy /Y Middleware\gs\gsdll64.dll Application\FileConverter\bin\x64\Release\gsdll64.dll
  copy /Y Middleware\gs\gswin64c.exe Application\FileConverter\bin\x64\Release\gswin64c.exe
  ```

- Shell extension doesn’t appear

  1) Register it (elevated):

  ```bash
  Application\FileConverter\bin\x64\Release\FileConverter.exe \
    --register-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
  ```

  2) Ensure the app path is discoverable (dev builds): set `HKCU\Software\FileConverter` string value `Path` to the full `FileConverter.exe` path.

  3) Restart Explorer (Task Manager → restart "Windows Explorer"). On Windows 11, use “Show more options” in the right‑click menu.

- WiX/installer build issues

  If `Installer.sign` is missing or WiX is not set up, build the application projects only. The installer is optional for development.

- Office interop version conflict warnings (MSB3277)

  These are benign for development builds. If you automate Office conversions, ensure Office is installed or reference the version you target.

- Logs and diagnostics

  Run with `--verbose`. Logs are written under `C:\Users\<User>\AppData\Local\FileConverter\Diagnostics-*`.

- Unregister extension (elevated)

  ```bash
  Application\FileConverter\bin\x64\Release\FileConverter.exe \
    --unregister-shell-extension "Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll"
  ```

## Thanks

Thanks to all the contributors of File Converter project.

### Localization

* Thanks to **Khidreal** and **hugok79** for the Portuguese localization.
* Thanks to **Marhc** for the Brazilian localization.
* Thanks to **Chachak** for the Spanish localization.
* Thanks to **Davide** for the Italian localization.
* Thanks to **nikotschierske** for the German localization.
* Thanks to **Snoopy1866** for the Simplified Chinese localization.
* Thanks to **MayaC0re** for the Turkish localization.
* Thanks to **vishveshjain** for the Hindi localization.
* Thanks to **Mahmoud0Sultan** for the Arabic localization.
* Thanks to **Sedimentary-Rock**, **NeKoOuO** and **PeterDaveHello** for the Traditional Chinese localization.
* Thanks to **CrisBalGreece** for the Greek localization.
* Thanks to **AshiVered** for the Hebrew localization.
* Thanks to **MrHero118** and **Mehrdad32** for the Persian localization.
* Thanks to **crnobog69** for the Serbian localizations.
* Thanks to **oogamiyuta** for the Japanese localization.
* Thanks to **AidyTheWeird** for the Czech localization.
* Thanks to **Alanimdeo** for the Korean localization.
* Thanks to **vrykolakas166** for the Vietnamese localization.
* Thanks to **iliamak** for the Russian localization.

## Middlewares

File converter uses the following middlewares:

**ffmpeg** (v7.1) as file conversion software.
Thanks to ffmpeg devs for this awesome open source file conversion tool. [Web site link](https://ffmpeg.org)

**ImageMagick** (v14.4) as image edition and conversion software.
Thanks to image magick devs for this awesome open source image edition software suite.  [Web site link](http://imagemagick.net)
And thanks to dlemstra for the C# wrapper of this software. [Github link](https://github.com/ImageMagick/ImageMagick)

**Ghostscript** (10.02.1) as pdf edition software.
Thanks to ghostscript devs. [Download link](https://www.ghostscript.com/download/gsdnld.html)

**SharpShell** to easily create windows context menu extensions.
Thanks to Dave Kerr for his work on SharpShell. [GitHub link](https://github.com/dwmkerr/sharpshell)

**Ripper** and **yeti.mmedia** for CD Audio extraction.
Thanks to Idael Cardoso for his work on CD Audio ripper. [Code project link](https://www.codeproject.com/Articles/5458/C-Sharp-Ripper)

**Markdown.XAML** for markdown rendering in the wpf application.
Thanks to Bevan Arps for his work on Markdown.XAML. [GitHub link](https://github.com/theunrepentantgeek/Markdown.XAML)

**WpfAnimatedGif** for animated gif rendering in the wpf application.
Thanks to Thomas Levesque for his work on WpfAnimatedGif. [GitHub link](https://github.com/XamlAnimatedGif/WpfAnimatedGif)

## License

File Converter is licensed under the GPL version 3 License.
For more information check the LICENSE.md file in your installation folder or the [gnu website](https://www.gnu.org/licenses/gpl.html).
