# LxLib7FreeType

This contains Freepascal headers for FreeType2, compatible with Win32, Win64, and Linux 

Tested extensively with FPC version 3.3.1 (as-at March 2026)
Bindings tested with FreeType v2.14.1 (as-at March 2026)
The unit is entirely self-contained, with no other dependencies (including no Lazarus).

The FreeType unit uses dynamic, runtime (late) binding - enabling the application to recover if unavailable.


## Example

See example program "demo_freetype.pp" for loading a font face, obtaining a bitmap representation, and displaying.


## Included libraries

Includes tested Windows binaries of freetype.dll and freetype64.dll, version 2.14.1