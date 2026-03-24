{--LX7------------------------------------------------------------------------------------PARADICE-SOFTWARE-\
|                                                                                                           |
|  Demo_freetype                                                                                            |
|                                                                                                           |
|  This program provides a simple demo demonstrating how to use the lxlib7freetype unit to obtain font      |
|  face and glyph information. It outputs an example, ASCII-based rendering of the specified test string.   |
|                                                                                                           |
|  Requires the freetype library (freetype.dll, freetype64.dll, or libfreetype.so - based on platform)      |
|                                                                                                           |
\-----------------------------------------------------------------------------------------------------------/}
program Demo_freetype;

uses
	lxlib7freetype	;		// Uses the freetype library

const
	WRITE_STR			=	'Hello, world!';	// The string to output to the terminal
	WRITE_SIZE			=	14;					// Point size of string to be output
	FONT_FILENAME		=	'RussoOne.ttf';		// Name of font file to be loaded
 
var
	Face		:	TFreeTypeFace;		// Class instance representing the loaded font face
	Output	:	array of string;	// An array of strings, used to render characters to before printing
	OutputX	:	integer;				// The current X-coordinate to be printed to
	OutputY	:	integer;				// The baseline coordinate (used as an index into the Output string array)
 

{-----------------------------------------------------------------------------------------------------------\
|  PrintGlyph                                                                                               |
|	This procedure will load the specified character into the Face's glyphslot, then render it's bitmap to   |
|	the Output array-of-strings, using simple ASCII characters to represent the 8-bit alpha values.          |
\-----------------------------------------------------------------------------------------------------------/}
procedure	PrintGlyph		(const CharCode: integer);
var
	Bitmap	:	TFTBitmap;	// Handle to active glyph bitmap
	X,Y		:	integer;		// Coordinates of pixels within the bitmap
	Yoffset	:	integer;
	Pixel    : 	byte;
	Temp		:	string;
begin
	Face.LoadChar(CharCode);		// Retrieve the glyph
	Bitmap 	:= Face.GlyphBitmap;	// Retrieve handle to the glyph bitmap
	Yoffset 	:= OutputY - Face.Glyph.BitmapTop;	// Calculate the starting offset row for this bitmap

	// Loop through each string in the output array, adding the bitmap's contents to it
	for Y := Low(Output) to High(Output) do begin
		Temp := '';	// Default to empty string
		
		// Check whether current row is within the range of the bitmap's rows
		if (Y >= Yoffset) and (Y < Yoffset + Longint(Bitmap.Rows)) then begin

			// Retrieve the alpha-value of each pixel within the bitmap
			for X := 0 to Bitmap.Width - 1 do begin
				Pixel := PByte(Bitmap.Buffer+((Y - Yoffset) * Abs(Bitmap.Pitch) + X))^;

				// Print a simple ASCII representation
				if pixel > 128 then Temp := Temp + '#'
				else if pixel > 64 then Temp := Temp + ';'
				else if pixel > 0 then Temp := Temp + '.'
				else Temp := Temp + ' ';
			end;
	   end else
			// Just print empty spaces equivalent to bitmap width
			for X := 0 to Bitmap.Width - 1 do
				Temp := Temp + ' ';
		// Add additional padding until we reach the Advance number of characters
		while Length(Temp) <= (Face.Glyph.Advance.X div 64) do
			Temp := Temp + ' ';
		Output[Y] := Output[Y] + Temp;
	end;

	// Increase cursor X offset
	OutputX := OutputX + Longint(Face.Glyph.Advance.X div 64);
end; 

var
	Idx	:	integer;	//	Character index for printing glyphs


begin
	// Enable automatic exceptions on any errors, so can skip most error checking in this example
	FreeType.ExceptionOnError := true;

	// Load the FreeType library
	FreeType_Load;

	// Load font face
	Face := TFreeTypeFace.Create(FONT_FILENAME,0);
	if not Assigned(Face) then begin
		writeln('Failed to load font face ' + FONT_FILENAME);
		halt;
	end;

	// Set the requested character size (note, most freetype size operations use 64-subpixels per pixel)
	Face.SetCharSize(WRITE_SIZE * 64,WRITE_SIZE * 64,0,0); 

	writeln('File "',FONT_FILENAME,'", family "',Face.FamilyName,'", size ',WRITE_SIZE,'pt.');

	// Prepare an array of strings to store our bitmap output
	Output := nil;
	SetLength(Output,Face.Metrics.Height div 64); // Set output string to the height. 
	OutputX := 1;
	OutputY := Face.Baseline;	// 'Baseline' Y-coordinate.

	// Print each glyph to our output string
	for Idx := 1 to Length(WRITE_STR) do
		PrintGlyph(Ord(WRITE_STR[Idx]));

	// And finally, write the output string to screen
	for Idx := Low(Output) to High(Output) do
		writeln(Output[Idx]);

	// Release face object
	Face.Free;

	// All done - unload library
	Freetype_Unload;
end.


