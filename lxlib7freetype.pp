{--LX7------------------------------------------------------------------------------------PARADICE-SOFTWARE-\
|                                                                                                           |
|  lxlib7freetype                                                                                           |
|                                                                                                           |
|	This unit provides dynamic-link bindings to the FreeType font/glyph rendering library.                   |
|	Implementations for both Windows (32/64bit) and Linux are supported. Pure FPC; does not use Lazarus.     |
|	The code has no dependencies other than the appropriate link library (freetype.dll or libfreetype.so)		|
|	Recommended compiler is FPC version 3.3.1+ as uses advancedrecords. 													|
|                                                                                                           |
|	The documentation used to create the bindings below is here:                                             |
|  	https://freetype.org/freetype2/docs/reference/                                                        |
|                                                                                                           |
|	Downloadable Windows binaries for the FreeType DLL are here:															|
|		https://github.com/ubawurinna/freetype-windows-binaries/releases/tag/v2.14.1									|
|                                                                                                           |
\-----------------------------------------------------------------------------------------------------------/}
unit lxlib7freetype;

{$mode objfpc}
{$modeswitch advancedrecords}
{$define FT_USE_ALLOCATOR}			// Define a custom memory allocator
{.define FT_STDERR_ERROR}			// Write error messages to StdErr
{$define FT_EXCEPTION_SUPPORT}	// Enable a FreeType.ExceptionOnError value
{$warn 5029 off}						// Disable "private field not used" warnings - they are used within FreeType DLL
{$warn 5024 off}						// Disable "Parameter not used" hint

interface


const
{$ifdef WINDOWS}
  {$ifdef WIN64}
	FREETYPE_LIB	=	'freetype64.dll';
  {$else}
	FREETYPE_LIB	=	'freetype.dll';
  {$endif}
{$else}
	{$ifdef LINUX}
		FREETYPE_LIB	=	'libfreetype.so';
	{$else}
		{$fatal Error - lxlib7freetype only supports Windows or Linux targets}
	{$endif}
{$endif}

{-----------------------------------------------------------------------------------------------------------\
|  Typical application usage:
|
|	- Call FreeType_Load function to load and initialize freetype library (check return code for success)
|	- Create one or more faces, using TFreeTypeFace.Create() or TFreeTypeFace.CreateFromMemory()
|	- Use TFreeTypeFace methods to access glyph information and render glyphs
|	- In case any of the methods return FALSE (for failure), call FreeType.GetLastError to retrieve error code.
|	- When done, call FreeType_Unload
|
|	Example of using created face to retrieve glyph info:
|	MyFace := TFreeTypeFace.Create('Arial.ttf',0);
|	MyFace.SetPixelSizes(32,32);
|	MyFace.LoadGlyph(MyFace.GetCharIndex(Ord('A')));   // or MyFace.LoadChar(Ord('A'));
|	// bitmap data is now available in MyFace.GlyphBitmap.Buffer
|	MyFace.Free;
\-----------------------------------------------------------------------------------------------------------}

const
{-----------------------------------------------------------------------------------------------------------\
|	Constants used by methods with a LoadFlags parameter - can be combined
\-----------------------------------------------------------------------------------------------------------}
	FT_LOAD_DEFAULT					=	$0;			// Default glyph load operation
	FT_LOAD_NO_SCALE					=	$1;			// Do not scale loaded outline glyph, keep in font units
	FT_LOAD_NO_HINTING				=	$1 shl 1;	// Disable hinting (generally creates blurrier glyphs)
	FT_LOAD_RENDER 					= 	$1 shl 2;	// Call FT_Render_Glyph after the glyph is loaded
	FT_LOAD_NO_BITMAP					=	$1 shl 3;	// Ignore bitmap strikes when loading
	FT_LOAD_VERTICAL_LAYOUT			=	$1 shl 4;	// Load glyph for vertical text layout
	FT_LOAD_FORCE_AUTOHINT			=	$1 shl 5;	// Prefer the auto-hinter over the font's native hinter
	FT_LOAD_PEDANTIC					=	$1 shl 7;	// Make font driver perform pedantic verifications
	FT_LOAD_NO_RECURSE				=	$1 shl 10;	// Do not load composite glyphs recursively
	FT_LOAD_IGNORE_TRANSFORM		=	$1 shl 11;	// Ignore transform matrix set by FT_Set_Transform
	FT_LOAD_MONOCHROME				=	$1 shl 12;	// With FT_LOAD_RENDER: force 1-bit mono (8pixels per byte)
	FT_LOAD_LINEAR_DESIGN			=	$1 shl 13;	//	Keep linearHoriAdvance and linearVertAdvance in fonnt units
	FT_LOAD_SBITS_ONLY				=	$1 shl 14;	// Only load bitmap strikes (opposite of LOAD_NO_BITMAP)
	FT_LOAD_NO_AUTOHINT				=	$1 shl 15;	// Disable the auto hinter
	FT_LOAD_COLOR						=	$1 shl 20;	// Load embedded color bitmap images
	FT_LOAD_COMPUTE_METRICS			=	$1 shl 21;	//	Compute glyph metrics from glyph data.
	FT_LOAD_BITMAP_METRICS_ONLY	=	$1 shl 22;	// Load metrics and image info without loading bitmap
	FT_LOAD_NO_SVG						=	$1 shl 24;	// Ignore SVG glyph data when loading


// FreeType library initialization / finalization functions
function	FreeType_IsLoaded	:	Boolean;		// Is FreeType library currently loaded?
function	FreeType_Load		:	Boolean;		//	Load the FreeType library; returns success
function	FreeType_Unload	:	Boolean;		// Unload the FreeType library; returns success

type
{-----------------------------------------------------------------------------------------------------------\
|	Types defined with 'TFT' prefixes are for compatibility with FreeType library types, across 32 and 64bit
\-----------------------------------------------------------------------------------------------------------}
	TFTInt						=	integer;
	TFTUInt						=	longword;
	TFTInt32						=	longint;
	TFTUInt32					=	longword;
	TFTShort						=	smallint;
	TFTUShort					=	word;
	TFTLibrary					=	pointer;
	TFTError						=	TFTInt;
	TFTString					=	PAnsiChar;
	TFTLoadFlags				=	TFTInt32;	// See FT_LOAD_xxx constants above
	TFTBool						=	boolean;
	TFTByte						=	byte;
	TFTF26Dot6					=	longint;
{$if defined(cpu64) and not(defined(win64) and defined(cpux86_64))}
	TFTLong 						=	int64;
	TFTULong 					=	qword;
	TFTPos 						=	int64;
{$else}
	TFTLong 						= 	longint;
	TFTULong 					=	longword;
	TFTPos 						= 	longint;
{$endif}
	TFTFixed 					= 	TFTLong;

	TFTVector					=	record
		X,Y						:	TFTPos;
	end;

  TFTMatrix 					=	record
	  XX, XY, YX, YY			: 	TFTFixed;
  end;

	TFTGeneric					=	record
		Data						:	pointer;
		Finalizer				:	procedure	(aobject: pointer); cdecl;
	end;

	PFTVector					=	^TFTVector;
	PFTSize						=	^TFTSize;
	PFTFaceRec					=	^TFTFaceRec;		// Called "TFTFace" in freetype; renamed to clarify it's a pointer type
	PFTListNode 				= 	^TFTListNode;
	PFTGlyphSlot				=	^TFTGlyphSlot;
	PFTBitmapSize				=	^TFTBitmapSize;
	PFTMatrix 					=	^TFTMatrix;
	PFTCharmap					=	pointer;

   TFTGlyphFormat 			= 	(
		ftgfNone 				= 	$00000000	, 
		ftgfBitmap 				= 	$62697473	,	//	"bits"
		ftgfComposite 			= 	$636f6d70	,	// "comp" 
		ftgfOutline 			= 	$6f75746c	,	// "outl"
		ftgfPlotter 			= 	$706c6f74	);	// "plot"

   TFTRenderMode 				= 	(ftrmNormal=0, ftrmLight, ftrmMono, ftrmLcd, ftrmLcdV, ftrmSDF,ftrmMax=$7fffffff);

   TFTOutline					=	record
		NContours				:	TFTShort;
		NPoints					:	TFTShort;
		Points					:	PFTVector;
		Tags						:	pointer;
		ContourEndPoints		:	^TFTShort;
		Flags						:	TFTInt;
	end;

	TFTBitmap					=	record
		Rows						:	TFTUInt;
		Width						:	TFTUInt;
		Pitch						:	TFTInt;
		Buffer					:	pointer;
		Num_Grays				:	TFTUShort;
		Pixel_Mode				:	byte;
		Palette_Mode			:	byte;
		Palette					:	pointer;
	end;

	TFTBitmapSize				=	record
		Height					:	TFTShort;
		Width						:	TFTShort;
		Size						:	TFTPos;
		XPPem						:	TFTPos;
		YPPEM						:	TFTPos;
	end;

	TFTGlyphMetrics			=	record
		Width						:	TFTPos;
		Height					:	TFTPos;
		HoriBearingX			:	TFTPos;
		HoriBearingY			:	TFTPos;
		HoriAdvance				:	TFTPos;
		VertBearingX			:	TFTPos;
		VertBearingY			:	TFTPos;
		VertAdvance				:	TFTPos;
	end;

	TFTGlyphSlot				=	record
		_Library					:	TFTLibrary;
      Face						:  PFTFaceRec;
      Next						:	PFTGlyphSlot;
      GlyphIndex				:  TFTUInt;
      Generic					:	TFTGeneric;
      Metrics					:	TFTGlyphMetrics;
      LinearHorzAdvance		:	TFTFixed;
		LinearVertAdvance		:	TFTFixed;
      Advance					:  TFTVector;
      Format					:	TFTGlyphFormat;
      Bitmap					:	TFTBitmap;
      BitmapLeft				:	TFTInt;
		BitmapTop				:	TFTInt;
      Outline					:	TFTOutline;
      NumSubGlyphs			:	TFTUInt;
		SubGlyphs				:	pointer;
		ControlData				:	pointer;
		ControlLen				:	TFTInt;
		LsbDelta					:	TFTPos;
		RsbDelta					:	TFTPos;
		Other						:	pointer;
		Internal					:	pointer;
	end;

   TFTBBox 						= 	record
      XMin, YMin				:	TFTPos; 
		XMax, YMax				: 	TFTPos;
   End;

   TFTSizeMetrics 			= 	record
      XPpEM, YPpEM			: 	TFTUShort;
      XScale, YScale			: 	TFTFixed;
      Ascender					:	TFTPos;
		Descender				:	TFTPos;
		Height					:	TFTPos;
		MaxAdvance				:	TFTPos;
   End;

	TFTSize 						=	record
		Face						:	PFTFaceRec;
      Generic					: 	TFTGeneric;
      Metrics					:	TFTSizeMetrics;
   private
      Internal					:	pointer;
   end;

   TFTListNode 				=	record
      Prev, Next				:	PFTListNode;
      Data						:	pointer;
   End;

   TFTList						= 	record
		Head, Tail				:	PFTListNode;
   End;

	TFTFaceRec					=	record
		NumFaces					:	TFTLong;
		FaceIndex				:	TFTLong;
		FaceFlags				:	TFTLong;
		StyleFlags				:	TFTLong;
		NumGlyphs				:	TFTLong;
		FamilyName				:	TFTString;
		StyleName				:	TFTString;
		NumFixedSizes			:	TFTInt;
		AvailableSizes			:	PFTBitmapSize;	
		NumCharmaps				:	TFTInt;
		CharMaps					:	PFTCharmap;
		Generic					:	TFTGeneric;
		BBox						:	TFTBBox;		// Smallest rectangle that can enclose every glyph in the face
		UnitsPerEM				:	TFTUShort;
		Ascender					:	TFTShort;
		Descender				:	TFTShort;
		Height					:	TFTShort;
		MaxAdvanceWidth		:	TFTShort;
		MaxAdvanceHeight		:	TFTShort;
		UnderlinePosition		:	TFTShort;
		UnderlineThickness	:	TFTShort;
		Glyph						:	PFTGlyphSlot;
		Size						:	PFTSize;
		CharMap					:	PFTCharmap;
	private
		Driver					:	pointer;
		Memory					:	pointer;
		Stream					:	pointer;
		SizesList				:	TFTList;
		Autohint					:	TFTGeneric;
		Extensions				:	pointer;
		Internal					:	pointer;
	end;

	TFreeTypeFace				=	class
		constructor					Create				(const FilePathName: AnsiString; const FaceIndex: TFTInt; const NamedInstanceIndex: TFTInt=0);
		constructor					CreateFromMemory	(const Data: Pointer; const Size: PtrInt; const FaceIndex: TFTInt; const NamedInstanceIndex: TFTInt=0);
		function						LoadChar				(CharCode: TFTULong; ALoadFlags: TFTLoadFlags=FT_LOAD_RENDER): boolean;
		function						LoadGlyph			(AGlyphIndex: TFTUInt; ALoadFlags: TFTLoadFlags=FT_LOAD_RENDER): boolean;
		function						GetCharIndex		(CharCode: TFTULong): TFTUInt;
		function						GetFirstChar		(out AGlyphIndex: TFTUint): TFTUlong;
		function						GetNextChar			(CharCode: TFTULong; out AGlyphIndex: TFTUInt): TFTULong;
		function						RenderGlyph			(var Slot: TFTGlyphSlot; const RenderMode: TFTRenderMode): boolean;
		function						SetCharSize			(CharWidth,CharHeight: TFTF26Dot6; HorzResolution,VertResolution: TFTUInt): boolean;
		function						SetPixelSizes		(PixelWidth,PixelHeight: TFTUint): boolean;
		procedure					SetTransform		(Matrix: TFTMatrix);
		destructor					Destroy;				override;
	protected
		mFaceRec					:	PFTFaceRec;
		function						GetBaseline		:	Longint;
		function						GetFamilyName	:	ansistring;
		function						GetGlyph			:	TFTGlyphSlot;
		function						GetGlyphBitmap	:	TFTBitmap;
		function						GetMetrics		:	TFTSizeMetrics;
	public
		property						Data				:	PFTFaceRec read mFaceRec;			// Pointer to TFTFace
		property						Baseline			:	Longint read GetBaseline;			// Baseline offset (in pixels)
		property						Familyname		:	ansistring read GetFamilyName;	// Family name of the font face
		property						Glyph				:	TFTGlyphSlot read GetGlyph;		// Glyph information
		property						GlyphBitmap		:	TFTBitmap read GetGlyphBitmap;	// Glyph bitmap
		property						Metrics			:	TFTSizeMetrics read GetMetrics;	// Face metrics
	end;

{-----------------------------------------------------------------------------------------------------------\
|	The following types are the definitions of functions in the freetype library. They must be declared cdecl!
|	During the FreeType_Load function call, these are dynamically loaded and stored in the FreeType global rec
\-----------------------------------------------------------------------------------------------------------}
	TFT_Init_FreeType			=	function				(out ALibrary: TFTLibrary): TFTError; cdecl;
	TFT_Done_FreeType			=	function 			(ALibrary: TFTLibrary): TFTError; cdecl; 
	TFT_Library_Version		=	procedure			(ALibrary: TFTLibrary; out OMajor,OMinor,OPatch: TFTInt); cdecl;
	TFT_New_Face				=	function				(ALibrary: TFTLibrary; const AFilePathName: TFTString; const AFaceIndex: TFTLong; var AFace: PFTFaceRec): TFTError; cdecl; 
	TFT_New_Memory_Face		=	function				(ALibrary: TFTLibrary; AFileBase: PByte; AFileSize,AFaceIndex: Longint; var OFace: PFTFaceRec): TFTError; cdecl; 
	TFT_Done_Face				=	function 			(Face: PFTFaceRec): TFTError; cdecl;
	TFT_Set_Pixel_Sizes		=	function				(Face: PFTFaceRec; Pixel_Width,Pixel_Height: TFTUInt): TFTError; cdecl; 
	TFT_Set_Char_Size			=	function				(Face: PFTFaceRec; const Char_Width,Char_Height: TFTF26Dot6; const Horz_Resolution,Vert_Resolution: TFTUInt): TFTError; cdecl;
	TFT_Get_Char_Index		=	function				(Face: PFTFaceRec; Charcode: TFTULong): TFTUInt; cdecl;
	TFT_Load_Char				=	function				(Face: PFTFaceRec; ACharCode: TFTULong; ALoadFlags: TFTLoadFlags): TFTError; cdecl;
	TFT_Load_Glyph				=	function				(Face: PFTFaceRec; AGlyphIndex: TFTUInt; ALoadFlags: TFTLoadFlags): TFTError; cdecl;
	TFT_Render_Glyph			=	function				(var Slot: TFTGlyphSlot; const RenderMode: TFTRenderMode): TFTError; cdecl;
	TFT_Get_First_Char		=	function				(Face: PFTFaceRec; out AGlyphIndex: TFTUInt): TFTULong; cdecl;
	TFT_Get_Next_Char			=	function				(Face: PFTFaceRec; ACharCode: TFTULong; out AGlyphIndex: TFTUInt): TFTULong; cdecl;
	TFT_Set_Transform			=	procedure			(Face: PFTFaceRec; AMatrix: PFTMatrix; ADelta: PFTVector); cdecl;
	TFT_Get_Transform			=	procedure			(Face: PFTFaceREc; OMatrix: PFTMatrix; ODelta: PFTVector); cdecl;

	TFT_Done_Library			=	function				(ALibrary: TFTLibrary): TFTError; cdecl;
	TFT_Add_Default_Modules	=	procedure			(ALibrary: TFTLibrary); cdecl;
	TFT_Set_Default_Properties=procedure			(ALibrary: TFTLibrary); cdecl;

{$ifdef FT_USE_ALLOCATOR}
{-----------------------------------------------------------------------------------------------------------\
|	TFTMemManager - FreeType allows the application to define it's own memory allocation routines. These are
|	defined here to enable the Pascal-native allocator to perform the operation (useful for heaptrace etc)
\-----------------------------------------------------------------------------------------------------------}
	TFTMemory 					=	record
		User						:	pointer;
		AllocFunc				: 	function				(constref AMemory: TFTMemory; const ASize: longint): pointer; cdecl;
		FreeFunc					: 	procedure			(constref AMemory: TFTMemory; const ABlock: pointer); cdecl;
		ReallocFunc				: 	function				(constref AMemory: TFTMemory; const ACurSize, ANewSize: longint; const ABlock: pointer): pointer; cdecl;
	end;

	TFTMemManager				=	record
		User						:	pointer;
		AllocFunc				:	function				(constref AMemory: TFTMemManager; const ASize: longint): pointer; cdecl;
		FreeFunc					:	procedure			(constref AMemory: TFTMemManager; const ABlock: pointer); cdecl;
		ReallocFunc				:	function				(constref AMemory: TFTMemManager; const ACurSize,ANewSize: longint; const ABlock: pointer): pointer; cdecl;
	end;

	TFT_New_Library			=	function				(constref AMemory: TFTMemory; out OLibrary: TFTLibrary): TFTError; cdecl;
{$endif}

	TFreeType					=	record
	public							// Raw library function accessor references
		Init_FreeType			:	TFT_Init_FreeType;
		Done_FreeType			:	TFT_Done_FreeType;
		New_Face					:	TFT_New_Face;
		New_Memory_Face		:	TFT_New_Memory_Face; 
		Done_Face				:	TFT_Done_Face;
		Library_Version		:	TFT_Library_Version;
		Set_Char_Size			:	TFT_Set_Char_Size;
		Set_Pixel_Sizes		:	TFT_Set_Pixel_Sizes;
		Get_Char_Index			:	TFT_Get_Char_Index;
		Load_Char				:	TFT_Load_Char;
		Load_Glyph				:	TFT_Load_Glyph;
		Get_First_Char			:	TFT_Get_First_Char;
		Get_Next_Char			:	TFT_Get_Next_Char;
		Get_Transform			:	TFT_Get_Transform;
		Set_Transform			:	TFT_Set_Transform;
		Render_Glyph			:	TFT_Render_Glyph;
		Done_Library			:	TFT_Done_Library;
		Add_Default_Modules	:	TFT_Add_Default_Modules;
		Set_Default_Properties:	TFT_Set_Default_Properties;
	public							// DLL/Library handles
		DLLHandle				:	TLibHandle;
		FTLibrary				:	TFTLibrary;
		LastError				:	TFTError;
	{$ifdef FT_USE_ALLOCATOR}	// Define a custom memory allocator
		New_Library				:	TFT_New_Library;
		MemManager				:	TFTMemory;
	{$endif}
	{$ifdef FT_EXCEPTION_SUPPORT}
		ExceptionOnError		:	Boolean;
	{$endif}
		function						CheckOK				(const ErrorCode: TFTError): boolean; // Returns TRUE if errorcode is success
		function						GetLastError	:	TFTError;	// Returns the error code from last CheckOK() that returned FALSE
		function						Version			:	AnsiString;	// Output the loaded FreeType version as a readable string
	end;

var
	FreeType	:	TFreeType;		// Populated during Freetype_Load function

implementation


uses
{$ifdef FT_EXCEPTION_SUPPORT}
	SysUtils	,
{$endif}
	DynLibs	;


const
	NILHANDLE	=	$0;


{$ifdef FT_USE_ALLOCATOR}	
function	 	FreeType_MemAlloc(Constref AMemory: TFTMemory; Const ASize: Integer): Pointer; cdecl;
begin
	Result := GetMemory(ASize);
end;

procedure 	FreeType_MemFree(Constref AMemory: TFTMemory; Const ABlock: Pointer); cdecl;
begin
	FreeMemory(ABlock);
end;

function 	FreeType_MemRealloc(Constref AMemory: TFTMemory; Const ACurSize, ANewSize: Integer; Const ABlock: Pointer): Pointer; cdecl;
begin
	result := ReallocMemory(ABlock, ANewSize);
end;
{$endif}


procedure	FreeType_OnError	(const ErrorText: AnsiString);
begin
{$ifdef FT_STDERR_ERROR}
	writeln(StdErr,Errortext);
{$endif}
{$ifdef FT_EXCEPTION_SUPPORT}
	if FreeType.ExceptionOnError then
		raise Exception.Create(ErrorText);
{$endif}
end;


function	FreeType_IsLoaded	:	Boolean;	// is FreeType library currently loaded?
begin
	result := (FreeType.DLLHandle <> NILHANDLE);
end;


function	FreeType_Load		:	Boolean;	//	Load the FreeType library; returns success
var
	FailedLoad	:	Boolean;
	ErrCode		:	TFTError;

	// Sub-function to perform GetProcAddress and record failure
	function	TestProcAddress	(const FuncName: String): Pointer;
	begin
		result := DynLibs.GetProcAddress(FreeType.DLLHandle,FuncName);
		if not Assigned(Result) then begin
			FailedLoad := true;
			FreeType_OnError('Failed to load function "' + FuncName + '" from FreeType library');
		end;
	end;

begin
	// If the library is already loaded, abort
	if FreeType.DLLHandle <> NILHANDLE then
		exit(false);

	// Initialize all the procedure values to nil
	FillChar(FreeType,SizeOf(FreeType),0);

	// Attempt to load the library, abort on failure
	FreeType.DLLHandle := DynLibs.LoadLibrary(FREETYPE_LIB);
	if FreeType.DLLHandle = DynLibs.NILHANDLE then begin
		FreeType_OnError('Failed to load library "' + FREETYPE_LIB + '"');
		exit(false);
	end;

	// Populate the functions!
	FailedLoad := false;	// Detect if any function fails to load

	with FreeType do begin
		Init_FreeType		:=	TFT_Init_FreeType			(TestProcAddress('FT_Init_FreeType'));
		Done_FreeType		:=	TFT_Done_FreeType			(TestProcAddress('FT_Done_FreeType'));
	{$ifdef FT_USE_ALLOCATOR}	// This function is only needed if defining our own memory manager
		New_Library			:=	TFT_New_Library			(TestProcAddress('FT_New_Library'));
	{$endif}
		Done_Library		:=	TFT_Done_Library			(TestProcAddress('FT_Done_Library'));
		New_Face				:=	TFT_New_Face				(TestProcAddress('FT_New_Face'));
		New_Memory_Face	:=	TFT_New_Memory_Face		(TestProcAddress('FT_New_Memory_Face'));
		Done_Face			:=	TFT_Done_Face				(TestProcAddress('FT_Done_Face'));
		Library_Version	:=	TFT_Library_Version		(TestProcAddress('FT_Library_Version'));
		Set_Char_Size		:= TFT_Set_Char_Size			(TestProcAddress('FT_Set_Char_Size'));
		Set_Pixel_Sizes	:=	TFT_Set_Pixel_Sizes		(TestProcAddress('FT_Set_Pixel_Sizes'));
		Get_Char_Index		:=	TFT_Get_Char_Index		(TestProcAddress('FT_Get_Char_Index'));
		Load_Char			:=	TFT_Load_Char				(TestProcAddress('FT_Load_Char'));
		Load_Glyph			:=	TFT_Load_Glyph				(TestProcAddress('FT_Load_Glyph'));
		Get_First_Char		:=	TFT_Get_First_Char		(TestProcAddress('FT_Get_First_Char'));
		Get_Next_Char		:=	TFT_Get_Next_Char			(TestProcAddress('FT_Get_Next_Char'));
		Set_Transform		:=	TFT_Set_Transform			(TestProcAddress('FT_Set_Transform'));
		Get_Transform		:=	TFT_Get_Transform			(TestProcAddress('FT_Get_Transform'));
		Render_Glyph		:=	TFT_Render_Glyph			(TestProcAddress('FT_Render_Glyph'));
		Add_Default_Modules		:= TFT_Add_Default_Modules		(TestProcAddress('FT_Add_Default_Modules'));
		Set_Default_Properties	:= TFT_Set_Default_Properties	(TestProcAddress('FT_Set_Default_Properties'));
	end;

	// On failure to load functions, about library load
	if FailedLoad then begin
		FreeType_Unload;	// Release handle
		exit(false);		// Report error
	end;

	// Finally, call FT_Init_FreeType (or New_Library - depending on the allocator)
{$ifdef FT_USE_ALLOCATOR}	
	FreeType.MemManager.User 			:= nil;
	FreeType.MemManager.AllocFunc 	:= @FreeType_MemAlloc;
	FreeType.MemManager.FreeFunc 		:= @FreeType_MemFree;
	FreeType.MemManager.ReallocFunc 	:= @FreeType_MemRealloc;
	ErrCode := FreeType.New_Library(FreeType.MemManager,FreeType.FTLibrary);
	if errCode <> 0 then begin
		FreeType_Unload;
		FreeType_OnError('FreeType - New_Library call failed');
		exit(false);
	end;
	FreeType.Add_Default_Modules(FreeType.FTLibrary);
	FreeType.Set_Default_Properties(FreeType.FTLibrary);
{$else}
	ErrCode := FreeType.Init_FreeType(FreeType.FTLibrary);
	if ErrCode <> 0 then begin
		FreeType_Unload;
		FreeType_OnError('FreeType - Init_FreeType call failed');
		exit(false);
	end;
{$endif}

	// Report success
	result := true;
end;


function	FreeType_Unload	:	Boolean;	// Unload the FreeType library; returns success
begin
	if FreeType.DLLHandle <> NILHANDLE then begin
		// Call the FT Done procedure
		if Assigned(FreeType.FTLibrary) then begin
		{$ifdef FT_USE_ALLOCATOR}
			FreeType.Done_Library(FreeType.FTLibrary);
		{$else}
			FreeType.Done_FreeType(FreeType.FTLibrary);
		{$endif}
			FreeType.FTLibrary := nil;
		end;

		// Unload the primary library handle
		result := DynLibs.UnloadLibrary(FreeType.DLLHandle);
		FreeType.DLLHandle := NILHANDLE;
		result := true;
	end else
		// Library wasn't loaded!
		result := false;
end;


constructor	TFreeTypeFace.Create					(const FilePathName: AnsiString; const FaceIndex: TFTInt; const NamedInstanceIndex: TFTInt=0);
begin
	inherited Create;
	mFaceRec := nil;
	if not FreeType.CheckOK(
		FreeType.New_Face(FreeType.FTLibrary,PAnsiChar(FilePathName),
		FaceIndex or (NamedInstanceIndex shl 16),mFaceRec)) then begin
			FreeType_OnError('Failed to create FreeType face "' + FilePathName + '"');
			fail;
	end;
end;


constructor	TFreeTypeFace.CreateFromMemory	(const Data: Pointer; const Size: PtrInt; const FaceIndex: TFTInt; const NamedInstanceIndex: TFTInt=0);
begin
	inherited Create;
	mFaceRec := nil;
	if not FreeType.CheckOK(
		FreeType.New_Memory_Face(FreeType.FTLibrary,Data,Size,FaceIndex or (NamedInstanceIndex shl 16),mFaceRec)) then
			fail;
end;


function		TFreeTypeFace.LoadChar				(CharCode: TFTULong; ALoadFlags: TFTLoadFlags=FT_LOAD_RENDER): boolean;
begin
	result := FreeType.CheckOK(FreeType.Load_Char(mFaceRec,CharCode,ALoadFlags));
end;


function		TFreeTypeFace.LoadGlyph				(AGlyphIndex: TFTUInt; ALoadFlags: TFTLoadFlags=FT_LOAD_RENDER): boolean;
begin
	result := FreeType.CheckOK(FreeType.Load_Glyph(mFaceRec,AGlyphIndex,ALoadFlags));
end;


function		TFreeTypeFace.GetCharIndex			(CharCode: TFTULong): TFTUInt;
begin
	result := FreeType.Get_Char_Index(mFaceRec, CharCode);
end;


function		TFreeTypeFace.GetFirstChar		(out AGlyphIndex: TFTUint): TFTUlong;
begin
	result := FreeType.Get_First_Char(mFaceRec,AGlyphIndex);
end;


function		TFreeTypeFace.GetNextChar			(CharCode: TFTULong; out AGlyphIndex: TFTUInt): TFTULong;
begin
	result := FreeType.Get_Next_Char(mFaceRec,CharCode,AGlyphIndex);
end;


function		TFreeTypeFace.RenderGlyph			(var Slot: TFTGlyphSlot; const RenderMode: TFTRenderMode): boolean;
begin
	result := FreeType.CheckOK(FreeType.Render_Glyph(Slot,RenderMode));
end;


function		TFreeTypeFace.SetCharSize			(CharWidth,CharHeight: TFTF26Dot6; HorzResolution,VertResolution: TFTUInt): boolean;
begin
	result := FreeType.CheckOK(FreeType.Set_Char_Size(mFaceRec,CharWidth,CharHeight,HorzResolution,VertResolution));
end;


function		TFreeTypeFace.SetPixelSizes		(PixelWidth,PixelHeight: TFTUint): boolean;
begin
	result := FreeType.CheckOK(FreeType.Set_Pixel_Sizes(mFaceRec,PixelWidth,PixelHeight));
end;


procedure	TFreeTypeFace.SetTransform			(Matrix: TFTMatrix);
begin
	FreeType.Set_Transform(mFaceRec,@matrix,nil);
end;


function		TFreeTypeFace.GetBaseline		:	Longint;
begin
	result := (mFaceRec^.Size^.Metrics.Ascender) div 64;
end;


function		TFreeTypeFace.GetFamilyName	:	ansistring;
begin
	result := mFaceRec^.FamilyName;
end;


function		TFreeTypeFace.GetGlyph			:	TFTGlyphSlot;
begin
	result := mFaceRec^.Glyph^;
end;


function		TFreeTypeFace.GetGlyphBitmap	:	TFTBitmap;
begin
	result := mFaceRec^.Glyph^.Bitmap;
end;


function		TFreeTypeFace.GetMetrics		:	TFTSizeMetrics;
begin
	result := mFaceRec^.Size^.Metrics;
end;


destructor	TFreeTypeFace.Destroy;
begin
	if Assigned(mFaceRec) then begin
		FreeType.CheckOK(FreeType.Done_Face(mFaceRec));
		mFaceRec := nil;
	end;
	inherited;
end;


function		TFreeType.CheckOK				(const ErrorCode: TFTError): Boolean;
begin
	result := (ErrorCode = 0);
	if not result then begin
		LastError := ErrorCode;
		FreeType_OnError('ErrorCode 0x' + HexStr(ErrorCode,2) + ' occured in FreeType function');
	end;
end;


function		TFreeType.GetLastError	:	TFTError;
begin
	result := LastError;
	LastError := 0;
end;


function		TFreeType.Version		:	AnsiString;
var
	OMajor,OMinor,OPatch: TFTInt;
	Substr	:	String;
begin
	if not FreeType_IsLoaded then
		exit('?');
	FreeType.Library_Version(FTLibrary,OMajor,OMinor,OPatch);

	// Convert the version information into a simple formatted string
	Str(Omajor,Substr);
	result := Substr + '.';
	Str(Ominor,Substr);
	result := result + Substr + '.';
	Str(Opatch,Substr);
	result := result + Substr;
end;

initialization
	FreeType.DLLHandle 			:= NILHandle;
{$ifdef FT_EXCEPTION_SUPPORT}
	FreeType.ExceptionOnError 	:= false;
{$endif}
finalization
	if FreeType_IsLoaded then
		FreeType_Unload;
end.


{-] Change History [----------------------------------------------------------------------PARADICE-SOFTWARE-\
|                                                                                                           
|	2026-02-22	-	Implemented unit - Windows/Linux, non-Lazarus required bindings to recent FreeType 2.14.1
|                                                                                                           
\-----------------------------------------------------------------------------------------------------------}
