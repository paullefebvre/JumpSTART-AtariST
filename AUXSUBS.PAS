{**************************************************************************
*
*	AUXSUBS.PAS - Declarations for PASAUX library
*
***************************************************************************}

{ Constants used by the auxilliary library }

CONST
	SCRLEN_B = 32000 ; { size of ST screen in bytes }
	SCRLEN_W = 16000 ; { size of ST screen in words }
	SCRLEN_L = 8000  ; { size of ST screen in long words }

	{ the various error codes }

	NO_ERROR = 0;
	SYS_ERROR = -1;
	DRIVE_ERROR = -2;
	UNKNOWN_ERROR = -3;
	CRC_ERROR = -4;
	BAD_REQUEST = -5;
	SEEK_ERROR = -6;
	UNKNOWN_MEDIA = -7;
	SECTOR_NOT_FOUND = -8;
	NO_PAPER = -9;
	WRITE_FAULT = -10;
	READ_FAULT = -11;
	GENERAL_ERROR = -12;
	WRITE_PROTECT = -13;
	MEDIA_CHANGE = -14;
	UNKNOWN_DEVICE = -15;
	BAD_SECTOR = -16;
	DISK_CHANGE = -17;
	INVALID_FUNCTION = -32;
	FILE_NOT_FOUND = -33;
	PATH_NOT_FOUND = -34;
	TOO_MANY_FILES = -35;
	ACCESS_DENIED = -36;
	INSUFFICIENT_MEM = -39;
	INVALID_MEM_ADDR = -40;
	INVALID_DRIVE = -46;

{ end of constants used by AUXPAS }

TYPE

{ types used by AUXPAS }

	C_String =  PACKED ARRAY [ 0..255 ] OF CHAR ;  { c-style string }

	Err_Code = Short_Integer ;		    { tos error code }

	{ the ST screen in 3 representations }
	Screen_B = PACKED ARRAY [ 0..31999 ] OF BYTE ;
	Screen_I = PACKED ARRAY [ 0..15999 ] OF Short_Integer ;
	Screen_L = PACKED ARRAY [ 0..7999 ]  OF Long_Integer ;

	B_Ptr = ^BYTE ;
	C_Ptr = ^CHAR ;
	I_Ptr = ^Short_Integer ;
	L_Ptr = ^Long_Integer ;

	Ptr_Screen = ^Screen_L	;   { pointer to the screen array }
	Palette = PACKED ARRAY [ 0..15 ] OF Short_Integer ;
	Resolution = Short_Integer ;

	Screen_Type = PACKED RECORD
		Res : Resolution ;
		Pal : Palette ;
		Pic : Screen_L ;
	    END ;

{ end of type used by PASAUX }

{ now the various external and other declarations }

{*************************************************************************
*
*	Peek/poke routines
*
*************************************************************************}

FUNCTION Peek( Address : Long_Integer )
	: BYTE ;
	EXTERNAL;
FUNCTION Wpeek( Address : Long_Integer )
	: Short_Integer ;
	EXTERNAL;
FUNCTION Lpeek( Address : Long_Integer )
	: Long_Integer ;
	EXTERNAL;

PROCEDURE Poke( Address: Long_Integer ;
		Value  : BYTE ) ;
	EXTERNAL;
PROCEDURE Wpoke( Address: Long_Integer ;
		 Value  : Short_Integer ) ;
	EXTERNAL;
PROCEDURE Lpoke( Address: Long_Integer ;
		 Value: Long_Integer );
	EXTERNAL;

{*************************************************************************
*
*	Supervisor status goodies.
*
*************************************************************************}

FUNCTION In_Super
	: Boolean;
	EXTERNAL;
PROCEDURE Super( YesNo : Boolean ); 
	EXTERNAL;


{*************************************************************************
*
*	Block memory move routines
*
*************************************************************************}

PROCEDURE Move_Long( Source, Dest, Count : Long_Integer );
	EXTERNAL;
PROCEDURE Move_Word( Source, Dest, Count : Long_Integer );
	EXTERNAL;
PROCEDURE Move_Byte( Source, Dest, Count : Long_Integer );
	EXTERNAL;

{*************************************************************************
*
*	Pascal to C routine interface routines
*
*************************************************************************}

PROCEDURE C_to_Pstr( Cstr : C_String ;
		   VAR Pstr : STRING );
	EXTERNAL;
PROCEDURE P_to_Cstr( Pstr : STRING ;
		   VAR Cstr : C_String );
	EXTERNAL;

{*************************************************************************
*
*	date stuff
*
*************************************************************************}

PROCEDURE Set_Date( Mon, Day, Yr : Short_Integer );
	EXTERNAL;
PROCEDURE Set_Time( Hour, Min, Sec : Short_Integer );
	EXTERNAL;
PROCEDURE Get_Date( VAR Mon, Day, Yr : Short_Integer );
	EXTERNAL;
PROCEDURE Get_Time( VAR Hour, Min, Sec : Short_Integer );
	EXTERNAL;

{*************************************************************************
*
*	Screen functions
*
*************************************************************************}


PROCEDURE Save_Scrn( VAR  Buf : Screen_Type );
	EXTERNAL;
PROCEDURE Restr_Scrn( VAR  Buf : Screen_Type );
	EXTERNAL;

FUNCTION Read_Scrn( Name : String ;
		    VAR  Buf : Screen_Type )
	: Err_Code ;
	EXTERNAL;
FUNCTION Write_Scrn( Name : String ;
		     VAR  Buf : Screen_Type )
	: Err_Code;
	EXTERNAL;

{*************************************************************************
*
*	Ptr/Adr routines
*
*************************************************************************}


FUNCTION Ptr_Byte( Addr : Long_Integer )
	: B_Ptr ;
	EXTERNAL ;
FUNCTION Ptr_Char( Addr : Long_Integer )
	: C_Ptr;
	EXTERNAL;
FUNCTION Ptr_Integer( Addr : Long_Integer )
	: I_Ptr;
	EXTERNAL;
FUNCTION Ptr_Long_Integer( Addr : Long_Integer )
	: L_Ptr;
	EXTERNAL;

FUNCTION Addr_Byte( VAR Bvar : BYTE )
	: Long_Integer;
	EXTERNAL;
FUNCTION Addr_Char( VAR Cvar : CHAR )
	: Long_Integer;
	EXTERNAL;
FUNCTION Addr_Integer( VAR Ivar : Short_Integer )
	: Long_Integer;
	EXTERNAL;
FUNCTION Addr_Long_Integer( VAR Lvar : Long_Integer )
	: Long_Integer;
	EXTERNAL;

FUNCTION IO_State
	: Boolean ;
	EXTERNAL ;
FUNCTION IO_Result
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE IO_Check( YesNo : Boolean ) ;
	EXTERNAL ;

{*************************************************************************
*
*	vt52 functions - use with write,writeln in non-gem programs
*
**************************************************************************}


{ Clear from the cursor to the end of the current line }
PROCEDURE ClrEol;
	EXTERNAL;

{ Clear the screen and move the cursor to the upper left position }
(* This is Turbo-Pascal compatible: *)
PROCEDURE ClrScr;
	EXTERNAL;
(* But the manual incorrectly gives this: *)
PROCEDURE ClrScrn; EXTERNAL;
(* Either one will work since it's in the library both ways! *)

{ Initialize the console device }
PROCEDURE CrtInit;
	EXTERNAL;

{ Reset the console device }
PROCEDURE CrtExit;
	EXTERNAL;

{ Delete the current line, moving all lines below up by one line }
PROCEDURE DelLine;
	EXTERNAL;

{ Insert a blank line at the current position, moving the current line and
  all lines below down by one line.  The bottom line on the screen is lost }
PROCEDURE InsLine;
	EXTERNAL;

{ Move to a specific screen coordinate.  Home is (1,1). }
PROCEDURE GotoXY( x, y : Short_Integer );      
   { make a local definition for the BIOS call }
   PROCEDURE cout ( dev, c : Short_Integer ) ;  BIOS( 3 ) ;
   BEGIN
        cout( 2,27   ) ;  cout( 2,ORD( 'Y' ) ) ;
        cout( 2,32+y ) ;  cout( 2,32+x ) ;
   END ;

{ Reverse foreground and background colors for text display }
PROCEDURE InverseVideo;
	EXTERNAL;

{ Restore normal colors }
PROCEDURE NormVideo;
	EXTERNAL;

{ Choose a foreground color index for text display }
PROCEDURE TextColor( color : Short_Integer );
	EXTERNAL;

{ Choose a background color index for text display }
PROCEDURE TextBackground( color : Short_Integer );
	EXTERNAL;

{ ---------------------------------------------------------------------------
  The following procedures and functions are not in the Turbo Pascal library:
  --------------------------------------------------------------------------- }

{ Move the cursor up one line }
PROCEDURE Curs_Up;
	EXTERNAL;

{ Move the cursor down one line }
PROCEDURE Curs_Down;
	EXTERNAL;

{ Move the cursor right one column }
PROCEDURE Curs_Right;
	EXTERNAL;

{ Move the cursor left one column }
PROCEDURE Curs_Left;
	EXTERNAL;

{ Move the cursor to the upper left corner of the screen }
PROCEDURE Curs_Home;
	EXTERNAL;

{ Same as CursUp, but inserts a blank line at the top of the screen }
PROCEDURE Curs_Up_2;
	EXTERNAL;

{ Clear from cursor to end of the screen }
(* This matches ClrScr: *)
PROCEDURE ClrEos;
	EXTERNAL;
(* The manual disagrees-- In the library it's both ways! *)
PROCEDURE Clr_Eos; EXTERNAL;

{ Turn on the flashing cursor }
PROCEDURE Curs_On;
	EXTERNAL;

{ Turn off the flashing cursor (i.e., no cursor is displayed) }
PROCEDURE Curs_Off;
	EXTERNAL;

{ end of AUXSUBS.PAS }


