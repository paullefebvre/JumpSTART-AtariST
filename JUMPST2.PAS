{$S45}
PROGRAM JumpSTART_2;

{  Version 2.73a for Geneva
   by Paul R. Lefebvre      (c) 1991, 1992, 1993

   JumpSTART provides the user with a quick and easy way to start
   commonly used programs.  All of your programs can be assigned a
   20 character description and can be started with a single mouse
   click.

   Up to 63 file descriptions can be stored in one file list.  New
   file lists can be loaded at any time.

   Works in ST Low, ST Medium, ST High, TT Medium, and
   TT High resolutions.

}

{ Include files : }

{$I d:\pascal\source\jmpst273\jumpst2.i}
{$I d:\pascal\include\auxsubs.pas}
{$I d:\pascal\include\gemsubs.pas}
{$I d:\pascal\include\gemdos.pas}
{$I d:\pascal\include\xbios.pas}

CONST
   MAX_LIST_SIZE = 63;        { Maximum number of file descriptions }
   MAX_ONSCREEN  = 21;        { Maximum file descriptions per page }
   BLANKLINE     = '                    '; { 20 spaces }
   LA_Intin      = 8;         { Used for LineA show mouse }
   MAX_STACK_SIZE= 10;        { Maximum number of JMP files stored on stack }
TYPE
   record_type                    = RECORD  { Stucture for file descriptions }
                                       description : STRING[80];
                                       file_path    : Str255;
                                    END;
   record_array                   = ARRAY[1..max_list_size] OF record_type;
   ext_type                       = STRING[3];
   average_array                  = ARRAY[0..500] of INTEGER;
   aver_array_ptr                 = ^average_array;

VAR
   old_colors                                  : ARRAY[0..15] OF INTEGER;
   load_dir, title, jump_filename, ftitle,
   temp, prg_name                              : Str255;
   main_dg_ptr                                 : Dialog_Ptr;
   first, last, list_size, ivoid, pushed, id,
   load_drv, rez, xres, yres, first_file,
   last_file, pages, current_page, x, y, w, h,
   main_dialog, lp, error, stack_cnt, dmy      : INTEGER;
   stack                                       : ARRAY[1..MAX_STACK_SIZE] OF Str255;
   keystate                                    : BYTE;
   changes, redraw, bvoid, autoload, sort      : BOOLEAN;
   file_list                                   : record_array;
   c_load_dir, c_parameter                     : C_String;
   Intin                                       : aver_array_ptr;
   Table                                       : LONG_INTEGER;
   da_menu                                     : Menu_Ptr;
   env                                         : environment;
{ ===================================================================== }

PROCEDURE P_To_CPath( VAR P_Path : Path_Name ; VAR C_Path : C_String ) ;
{ convert Pascal string to C string, the built-in routines only work for
  long string }
VAR
  len, i   : INTEGER;
BEGIN
  len := length( p_path ) ;
  FOR i := 0 TO len-1 DO c_path[i] := p_path[i+1];
  c_path[ len ] := chr(0)
END; { P_To_CPath }

{ ---------------------------------------------------------------------- }

FUNCTION tos_version : LONG_INTEGER;
{ Returns the TOS version number :
  Format : $0205 = TOS 2.05 }
VAR
   tosloc, tosver : LONG_INTEGER;

BEGIN
   super( TRUE );               { Activate supervisor mode }
   tosloc := lpeek( $4f2 );     { Get the address pointer }
   tosloc := tosloc + $2;       { Add the offset }
   tosver := lpeek( tosloc );   { Get the TOS version }
   super( FALSE );              { Deactivate supervisor mode }
   tosver := shr( tosver, 16 ); { Shift off unnecessary bits }
   tos_version := tosver
END;

PROCEDURE shell_write( doex, isgr, aes : INTEGER;
                       VAR pcmd : C_String;
                       VAR ptail : C_string );

VAR
   int_in : int_in_parms;
   int_out : int_out_parms;
   addr_in : addr_in_parms;
   addr_out : addr_out_parms;

BEGIN
   int_in[ 0 ] := doex;
   int_in[ 1 ] := isgr;
   int_in[ 2 ] := aes;
   new( addr_in[0] );             { Reserve space for strings to send }
   new( addr_in[1] );             { to AES call. }
   addr_in[ 0 ]^ := pcmd;
   addr_in[ 1 ]^ := ptail;
   AES_Call( 121, int_in, int_out, addr_in, addr_out );
   dispose( addr_in[0] );
   dispose( addr_in[1] )
   
END;

PROCEDURE wind_new;
VAR
   int_in : int_in_parms;
   int_out : int_out_parms;
   addr_in : addr_in_parms;
   addr_out : addr_out_parms;

BEGIN
   IF tos_version >= 260 THEN BEGIN { We are using TOS 1.04 or better }
      int_in[ 1 ] := 0;              { so the newdesk call will work. }
      int_in[ 2 ] := 0;
      int_in[ 3 ] := 0;
      int_in[ 4 ] := 0;
      AES_Call( 109, int_in, int_out, addr_in, addr_out )
   END
END;

{ ---------------------------------------------------------------------- }

PROCEDURE Form_Dial(flag, x_sm, y_sm, w_sm, h_sm, x_lg, y_lg, w_lg,
                    h_lg : INTEGER );
   External;

{ ---------------------------------------------------------------------- }

FUNCTION Ptr( where : LONG_INTEGER ) : aver_array_ptr;
   External;

{ ---------------------------------------------------------------------- }

FUNCTION Linea_init : LONG_INTEGER;
   External;

{ ---------------------------------------------------------------------- }

PROCEDURE Redraw_Screen;
{ Redraw screen by forcing a redraw message to GEM }
VAR
   x, y, w, h : INTEGER;
BEGIN
   IF ( main_dialog = MAIN_DG2 ) THEN
      clear_screen
   ELSE BEGIN
      Work_Rect( 0, x, y, w, h );
      Form_Dial( 3, 0, 0, 0, 0, x, y, w, h )
   END
END; { Redraw_Screen }

{ ---------------------------------------------------------------------- }

PROCEDURE bconout( dev, c : INTEGER );
   BIOS( 3 );

{ ---------------------------------------------------------------------- }

PROCEDURE out_esc( c : CHAR );
{ For TOS VT-52 screen control }
BEGIN
   bconout( 2, 27 );
   bconout( 2, ord(c) )
END; { out_esc }

{ ---------------------------------------------------------------------- }

PROCEDURE tos_screen;
{ Clear screen, hide mouse, and show cursor before running TOS progs }

BEGIN
   Init_Mouse;
   Hide_Mouse;
   Clear_Screen;   { Clear screen }
   Curs_On         { and cursor on }
END; { tos_screen }

{ ---------------------------------------------------------------------- }

PROCEDURE gem_screen;
{ Turn off cursor, and show mouse for GEM }

BEGIN
   Curs_Off        { Cursor off }
END; { tos_screen }

{ ---------------------------------------------------------------------- }

PROCEDURE Linea_Showms;

{  LineA Show Mouse Routine  }

  External;

{ ---------------------------------------------------------------------- }

PROCEDURE chdir( path : Str255; drv : INTEGER );

{ Changes the current directory and drive. }

VAR
  c_path : C_String;
BEGIN
   P_To_Cstr( path, c_path );
   ivoid := dsetdrv( drv );            { Change drive }
   ivoid := dsetpath( c_path )         { Change directory }
END; { chdir }

{ --------------------------------------------------------------------- }

PROCEDURE init_screen;

{ Clears the screen and sets the mouse form to an arrow.
  Gets the screen resolution. }

VAR
   x, y, w : INTEGER;

BEGIN
   IF ( main_dialog <> MAIN_DG2 ) THEN BEGIN
      da_menu := New_Menu( 9, ' Return to JumpSTART' );
      Draw_Menu( da_menu )
   END;
   CASE rez OF       { Determine how many colors need to be restored. }
      0 : x := 15;
      1 : x := 3;
      2 : x := 1
   END;
   FOR y := 0 TO x DO                     { Set colors back to what they were }
      w := setcolor( y, old_colors[y] );  { before the program was run. }
   redraw_screen;
   Set_Mouse( M_ARROW );
END; { init_screen }

{ ---------------------------------------------------------------------- }

PROCEDURE set_up_everything;

{ Program initialization. }

BEGIN
   Find_Dialog( main_dialog, main_dg_ptr );
   Center_Dialog( main_dg_ptr )
END; { set_up_everything }

{ --------------------------------------------------------------------- }

PROCEDURE show_help_dialog;

{ Put the help dialog box on the screen }

VAR
   help_dg_ptr : Dialog_Ptr;

BEGIN
   Find_Dialog( HELP_DG,help_dg_ptr );
   Center_Dialog( help_dg_ptr );
   Show_Dialog( help_dg_ptr, 0 );
   ivoid := Redo_Dialog( help_dg_ptr,0 );
   dmy := Obj_State( help_dg_ptr, ivoid );
   Obj_SetState( help_dg_ptr, ivoid, (dmy-SELECTED)&dmy, TRUE )
END; { show_help_dialog }

{ --------------------------------------------------------------------- }

PROCEDURE change_title( VAR title : Str255; change : BOOLEAN );

{ This procedure allows the user to enter a new title if 'change' is TRUE.
  If 'change' is FALSE, it puts the title in the dialog box. }

VAR
   title_dg_ptr : Dialog_Ptr;
   clicked : INTEGER;

BEGIN
   IF change THEN BEGIN       { Enter a new title }
      Find_Dialog( TITLE_DG, title_dg_ptr );
      Set_DText( title_dg_ptr, TITLE_ED, title, System_Font, TE_Left );
      Center_Dialog( title_dg_ptr );
      Show_Dialog( title_dg_ptr, 0 );
      clicked := Redo_Dialog( title_dg_ptr, TITLE_ED );
      IF ( clicked = OK_TITLE ) THEN BEGIN
         Get_DEdit( title_dg_ptr, TITLE_ED, title );
         changes := TRUE;
         change_title( title, FALSE )
      END;
      dmy := Obj_State( title_dg_ptr, clicked );
      Obj_SetState( title_dg_ptr, clicked, (dmy-SELECTED)&dmy, FALSE );
      redraw := TRUE
   END
   ELSE BEGIN { Display title }
      Set_DText( main_dg_ptr, JUMPNAME, title, System_Font, TE_Center );
      redraw := FALSE
   END
END; { change_title }

{ --------------------------------------------------------------------- }

PROCEDURE bubble_sort( VAR file_list : record_array; list_size : INTEGER );

{  Sorts the file_list record.  Since it contains at most 63 entries, a
   bubble sort is fast enough. }

VAR
   sorted : BOOLEAN;
   i : INTEGER;
   temp : record_type;

BEGIN
   REPEAT
      sorted := TRUE;
      FOR i := 1 TO ( list_size-1 ) DO
         IF file_list[i].description > file_list[i+1].description THEN BEGIN
            temp := file_list[i];
            file_list[i] := file_list[i+1];
            file_list[i+1] := temp;
            sorted := FALSE
         END
   UNTIL sorted
END; { bubble_sort }

{ ---------------------------------------------------------------------- }

PROCEDURE show_files( VAR file_list : record_array; first_file, list_size,
                      current_page, pages : INTEGER );

{ Puts the list of files into the main dialog box. }

VAR
   lp : INTEGER;
   current_page_str : STRING[11];

BEGIN
   Begin_Update;
   FOR lp := 0 TO ( MAX_ONSCREEN-1 ) DO
      Set_DText( main_dg_ptr, ( NAME_1+lp ), file_list[lp+first_file].description,
                 System_Font, TE_Center );
   current_page_str := 'Page 1 of 1';
   current_page_str[6] := chr( current_page+48 );
   current_page_str[11] := chr( pages+48 );
   Set_DText( main_dg_ptr, PAGE_NO, current_page_str, System_Font, TE_Center );
   End_Update
END; { show_files }

{ --------------------------------------------------------------------- }

PROCEDURE redraw_files;
{ Redraw the file descriptions without doing a complete dialog box redraw.
  In low res the complete dialog box will always be redrawn. }

VAR
   lp : INTEGER;
BEGIN
   Begin_Update;
   IF ( main_dialog = MAIN_DG2 ) THEN
      redraw := TRUE
   ELSE BEGIN
      FOR lp := 0 TO ( MAX_ONSCREEN-1 ) DO
         Show_Dialog( main_dg_ptr, NAME_1+lp );
      Show_Dialog( main_dg_ptr, PAGE_NO )
   END;
   End_Update
END; { redraw_files }

{ --------------------------------------------------------------------- }

PROCEDURE set_up_files( VAR pages : INTEGER;
                        list_size : INTEGER );

{ Determines how many pages of files there are. }

BEGIN
   IF list_size > 0 THEN BEGIN
      pages := MAX_LIST_SIZE DIV MAX_ONSCREEN;
      WHILE ( (pages-1)*MAX_ONSCREEN ) >= list_size DO
         pages := pages - 1
   END
   ELSE
      pages := 1
END; { set_up_files }

{ --------------------------------------------------------------------- }

PROCEDURE page_updown( VAR first_file, current_page : INTEGER;
                       pages : INTEGER; up : BOOLEAN );

{ Determines which page is to be displayed. }

VAR
   current_page_str : Str255;

BEGIN
   redraw := FALSE;
   IF ( pages <> 1 ) THEN BEGIN
      IF up THEN
         IF ( pages - current_page ) >= 1 THEN
            current_page := current_page + 1
         ELSE
            current_page := 1
      ELSE
         IF current_page <> 1 THEN
            current_page := current_page - 1
         ELSE
            current_page := pages;
      first_file := (MAX_ONSCREEN * (current_page-1))+1
   END
END; { page_updown }

{ --------------------------------------------------------------------- }

PROCEDURE enable_radio_buttons;

BEGIN
   Obj_SetState( main_dg_ptr, RUN_BUT, Selected, FALSE );
   Obj_SetState( main_dg_ptr, PATH_BUT, Normal, FALSE );
   Obj_SetState( main_dg_ptr, DESC_BUT, Normal, FALSE );
   Obj_SetState( main_dg_ptr, REMOVE, Normal, FALSE )
END; { enable_radio_buttons }

{ --------------------------------------------------------------------- }

PROCEDURE load_jmp_file( jump_filename : Str255; VAR title : Str255;
                         VAR file_list : record_array;
                         VAR list_size, first_file, pages,
                             current_page, error : INTEGER );

{ This procedure loads a JMP file and stores it in the record array.  }

VAR
   jump_file : TEXT;
   temp_title : Str255;
   dummy_line : Str255;
   eq, len, count : INTEGER;

BEGIN
   IO_Check( FALSE );
   reset( jump_file, jump_filename ); { Open the JMP file }
   error := IO_Result;
   IF ( error = NO_ERROR ) THEN BEGIN { If it exists, then process }
      Set_Mouse( M_Bee );
      count := 0;
      readln( jump_file, temp_title );    { Get JMP title line }
      IF temp_title = '' THEN
         temp_title := BLANKLINE;
      sort := TRUE;
      IF NOT eof( jump_file ) THEN BEGIN
         readln( jump_file, dummy_line );
         IF ( dummy_line = 'NOSORT' ) THEN BEGIN   { Unsorted list? }
            sort := FALSE;
            IF NOT eof( jump_file ) THEN
               readln( jump_file, dummy_line )
         END;
         { Start reading the file descriptions and paths }
         IF NOT eof( jump_file ) OR ( dummy_line <> 'NOSORT' ) THEN
            REPEAT
               IF count > 0 THEN
                  readln( jump_file, dummy_line );
               count := count + 1;
               eq := pos( '=', dummy_line );
               len := length( dummy_line );
               file_list[count].description := copy( dummy_line, 1, (eq - 1) );
               file_list[count].file_path := copy( dummy_line, (eq + 1), len )
            UNTIL ( eof( jump_file) ) OR ( count > MAX_LIST_SIZE-1 )
      END;
      close( jump_file );
      Set_Mouse( M_Arrow );
      changes := FALSE;
      list_size := count;
      FOR eq := (list_size+1) TO MAX_LIST_SIZE DO BEGIN
         file_list[eq].description := BLANKLINE; { Blank out remaining }
         file_list[eq].file_path := '';          { File descriptions }
      END;
      IF sort THEN BEGIN
         bubble_sort( file_list, list_size ); { Sort the filelist }
         IF main_dialog <> MAIN_DG2 THEN { No sort button in low-res }
            IF Obj_State( main_dg_ptr, SORT_BUT ) & Selected = 0 THEN BEGIN
               dmy := Obj_State( main_dg_ptr, SORT_BUT );
               Obj_SetState( main_dg_ptr, SORT_BUT, dmy|SELECTED, NOT autoload );
            END
      END
      ELSE
         IF main_dialog <> MAIN_DG2 THEN
            IF Obj_State( main_dg_ptr, SORT_BUT ) & Selected <> 0  THEN BEGIN
               dmy := Obj_State( main_dg_ptr, SORT_BUT );
               Obj_SetState( main_dg_ptr, SORT_BUT, (dmy-SELECTED)&dmy, TRUE );
            END;
      IF ( main_dialog = MAIN_DG2 ) AND (length( temp_title ) >17) THEN
         title := copy( temp_title, 1, 17 ) { Only 17 chars in low-res }
      ELSE
         title := temp_title;
      change_title( title, FALSE);
      IF title = BLANKLINE THEN
         title := '';
      first_file := 1;
      current_page := 1;
      set_up_files( pages, list_size );
      IF ( main_dialog <> MAIN_DG2 ) THEN BEGIN
         dmy := Obj_State( main_dg_ptr, SAVE_BUT );
         Obj_SetState( main_dg_ptr, SAVE_BUT, dmy|Disabled, TRUE );
      END;
      show_files( file_list, first_file, list_size, current_page, pages )
   END
   ELSE
      IF NOT autoload THEN
         error := Do_Alert( '[1][.JMP file not found.][ Ok ]', 1 )
END; { load_jump_file }

{ ----------------------------------------------------------------------- }

PROCEDURE parse( VAR path, filename : Str255 );

{ Takes a complete pathname and separates the filename and the directory.
  path and filename will be modified. }

VAR
   bs : INTEGER;
   temp1, temp2 : Str255;

BEGIN
   temp2 := '';
   REPEAT
      bs := pos( '\', path );
      IF ( bs <> 0 ) THEN BEGIN
         temp1 := copy( path, 1, bs );
         temp2 := concat( temp2, temp1 );
         delete( path, 1, bs )
      END
   UNTIL ( bs = 0 );
   filename := path;
   path := temp2
END; { parse }

{ ---------------------------------------------------------------------- }

FUNCTION fsel_exinput( VAR fpath, fname, ftitle : Str255 ): BOOLEAN;
{ Implementation of the enhanced AES file selector routine (#91).  In
  versions of TOS greater than 1.4, ftitle will be displayed in the
  file selector as a prompt.   The variable fname will contain the complete
  pathname, the function returns TRUE if Ok was selected FALSE if cancel
  was selected.  ftitle must not be longer than 30 characters. }

VAR
   int_in : int_in_parms;
   int_out : int_out_parms;
   addr_in : addr_in_parms;
   addr_out : addr_out_parms;
   cfpath, cfname, cftitle : C_String;
   temp : Str255;

BEGIN
   int_in[0] := 0;
   int_in[1] := 0;
   int_in[2] := 0;
   int_in[3] := 0;
   P_To_CStr( fpath, cfpath );    { Convert Pascal strings to C format }
   P_To_CStr( fname, cfname );
   P_To_CPath( ftitle, cftitle );
   new( addr_in[0] );             { Reserve space for strings to send }
   new( addr_in[1] );             { to AES call. }
   new( addr_in[2] );
   addr_in[0]^ := cfpath;         { Set AES pointers to point to the }
   addr_in[1]^ := cfname;         { strings. }
   addr_in[2]^ := cftitle;
   IF tos_version >= 260 THEN
      AES_Call( 91, int_in, int_out, addr_in, addr_out ) { Make the call }
   ELSE
      AES_Call( 90, int_in, int_out, addr_in, addr_out ); { Make the call }
   cfpath := addr_in[0]^;         { Get the path }
   dispose( addr_in[0] );         { Free reserved space }
   C_To_PStr( cfpath, fpath );    { Convert back to Pascal string }
   cfname := addr_in[1]^;         { as above }
   dispose( addr_in[1] );
   C_To_PStr( cfname, fname );
   parse( fpath, temp );          { Remove wildcard from path }
   fname := concat( fpath, fname );  { fname will now contain the }
                                          { entire filepath }
   IF int_out[1] = 1 THEN
      fsel_exinput := TRUE       { OK was selected }
   ELSE
      fsel_exinput := FALSE      { Cancel was selected }
END;

{ ---------------------------------------------------------------------- }

FUNCTION get_filename( ext : ext_type; VAR filename, ftitle : Str255 )
                     : BOOLEAN;

{ Puts a file selector on screen with the current drive and directory.
  Returns TRUE if a OK is selected, FALSE if cancel is selected. }

VAR
   c_def_path : C_String;
   def_path : Str255;
   drive : INTEGER;

BEGIN
   drive := dgetdrv;
   ivoid := dgetpath( c_def_path, drive+1 );
   C_To_Pstr( c_def_path, def_path );
   def_path := concat( chr(drive+65), ':', def_path, '\*.', ext );
   IF ext = 'JMP' THEN BEGIN { JMP file accessed - use JumpSTART dir }
      def_path := filename;
      parse( def_path, filename );
      def_path := concat( def_path, '*.', ext )
   END;
   get_filename := fsel_exinput( def_path, filename, ftitle );
   redraw := TRUE
END; { get_filename }

{ --------------------------------------------------------------------- }

PROCEDURE get_extender( filename : Str255; VAR ext : ext_type );

{  Gets the extender from a TOS filename. }

VAR
   dot : INTEGER;
   temp : Str255;

BEGIN
   temp := filename;
   parse( temp, filename );
   dot := pos( '.', filename );
   IF ( dot = 0 ) THEN
      ext := ''
   ELSE
      ext := copy( filename, (dot+1), length( filename )-dot )
END; { get_extender }

{ --------------------------------------------------------------------- }

PROCEDURE save_file( jump_filename : Str255; file_list : record_array;
                     title : Str255; list_size : INTEGER );

{ Saves the file_list to disk.  Prompts for a filename. }
VAR
   jump_file : TEXT;
   count : INTEGER;
   ext : ext_type;

BEGIN
   redraw := TRUE;
   IF changes THEN BEGIN
      ftitle := 'Save JMP file list :';
      IF get_filename( 'JMP', jump_filename, ftitle ) THEN BEGIN
         get_extender( jump_filename, ext );
         IF ext = '' THEN
            jump_filename := concat( jump_filename, '.JMP');
         rewrite( jump_file, jump_filename );
         Set_Mouse( M_Bee );
         writeln( jump_file, title );
         IF Obj_State( main_dg_ptr, SORT_BUT ) & Selected = 0 THEN
            writeln( jump_file, 'NOSORT' );
         count := 0;
         WHILE ( count < list_size ) DO BEGIN
            count := count + 1;
            write( jump_file, file_list[count].description );
            write( jump_file, '=' );
            writeln( jump_file, file_list[count].file_path )
         END;
         close( jump_file );
         Set_Mouse( M_Arrow )
      END
   END
END; { save_file }

{ --------------------------------------------------------------------- }

PROCEDURE change_description( VAR file_list : record_array;
                              selected_file, first_file : INTEGER );

{  Change the description for a filename. }

VAR
   desc_dg_ptr : Dialog_Ptr;
   spc, bs, clicked : INTEGER;
   temp, filename : Str255;

BEGIN
   Find_Dialog( DESC_DG, desc_dg_ptr );
   temp := file_list[selected_file].file_path;
   spc := pos( ' ', temp );  { Check if there is a parameter }
   IF ( spc <> 0 )THEN          { There is, so show it, not the executable file }
      temp := copy( temp, (spc+1), length(temp) );
   parse( temp, filename );
   Set_DText( desc_dg_ptr, PATH_DSC, filename, System_Font, TE_Left );
   temp := file_list[selected_file].description;
   IF ( temp = BLANKLINE ) THEN
      temp := '';
   Set_DText( desc_dg_ptr, FILE_DSC, temp, System_Font, TE_Left );
   Center_Dialog( desc_dg_ptr );
   Show_Dialog( desc_dg_ptr, 0 );
   clicked := Redo_Dialog( desc_dg_ptr, FILE_DSC );
   IF ( clicked = OK_DESC ) THEN BEGIN
      changes := TRUE;
      Get_DEdit( desc_dg_ptr, FILE_DSC, temp );
      IF ( temp = '' ) THEN
         temp := filename;
      file_list[selected_file].description := temp
   END
   ELSE
      IF ( temp = '' ) THEN
         file_list[selected_file].description := filename;
   dmy := Obj_State( desc_dg_ptr, clicked );
   Obj_SetState( desc_dg_ptr, clicked, (dmy-SELECTED)&dmy, FALSE );
   redraw := TRUE;
END; { change_description }

{ ---------------------------------------------------------------------- }

PROCEDURE remove_file( VAR file_list : record_array; VAR list_size,
                       pages, first_file, current_page : INTEGER;
                       erased : INTEGER );

{  Removes a filename and adjust the file_list. }

VAR
   i : INTEGER;

BEGIN
   changes := TRUE;
   FOR i := erased TO ( list_size-1 ) DO
      file_list[i] := file_list[i+1];
   file_list[list_size].description := blankline;
   file_list[list_size].file_path := '' ;
   list_size := list_size-1;
   IF ( list_size = MAX_LIST_SIZE-1 ) AND ( main_dialog <> MAIN_DG2 ) THEN
   BEGIN
      dmy := Obj_State( main_dg_ptr, ADD_BUT );
      Obj_SetState( main_dg_ptr, ADD_BUT, (dmy|DISABLED-DISABLED)&dmy, FALSE );
      Show_Dialog( main_dg_ptr, ADD_BUT )
   END;
   set_up_files( pages, list_size );
   IF current_page > pages THEN BEGIN
      current_page := pages;
      first_file := ( MAX_ONSCREEN * (current_page-1))+1
   END
END; { remove_file }

{ --------------------------------------------------------------------- }

FUNCTION change_filepath( VAR file_list : record_array;
                           selected_file : INTEGER) : BOOLEAN;

{  Displays a file selector to allow the user to select a new filepath. }

VAR

   c_def_path : C_String;
   def_path, temp, filename, parameter : Str255;
   drive, spc : INTEGER;
   ext : ext_type;
   bvoid : BOOLEAN;

BEGIN
   change_filepath := FALSE;
   temp := file_list[selected_file].file_path;
   IF ( temp <> '') THEN BEGIN
      spc := pos( ' ', temp );
      IF ( spc <> 0 ) THEN
         temp := copy( temp, (spc+1), length(temp) );
      parse( temp, filename );
      temp := concat( temp, '*.*' );
      IF filename = '*.*' THEN
         filename := '';
   END
   ELSE BEGIN
      drive := dgetdrv;
      ivoid := dgetpath( c_def_path, drive+1 );
      C_To_Pstr( c_def_path, temp );
      temp := concat( chr(drive+65),':', temp,'\*.*' );
      filename := ''
   END;
   ftitle := 'Select file to install :';
   bvoid := fsel_exinput( temp, filename, ftitle );
   IF bvoid AND ( filename <> '' ) THEN BEGIN
      get_extender( filename, ext );
      IF ( ext = 'PRG' ) OR ( ext = 'APP' ) OR ( ext = 'TOS' ) OR
         ( ext = 'TTP' ) OR ( ext = 'JMP' ) THEN BEGIN
         file_list[selected_file].file_path := filename;
         drive := ord( filename[1] )-65;
         parse( filename, temp );
         chdir( filename, drive );
         change_filepath := TRUE;
         changes := TRUE
      END
      ELSE BEGIN { parameter was selected, so get program to pass it to }
         parameter := filename;
         temp := filename;
         parse( temp, filename );
         temp := concat( temp, '*.*' );
         ftitle := 'Select executable file :';
         bvoid := fsel_exinput( temp, filename, ftitle );
         IF bvoid AND ( filename <> '' ) THEN BEGIN
            get_extender( filename, ext );
            IF ( ext = 'PRG' ) OR ( ext = 'APP' ) OR
               ( ext = 'TOS' ) OR ( ext = 'TTP' ) THEN BEGIN
               file_list[selected_file].file_path :=
                             concat( filename, ' ',parameter );
               drive := ord( parameter[1] )-65;
               parse( parameter, filename );
               chdir( parameter, drive );
               change_filepath := TRUE;
               changes := TRUE
            END
         END
      END
   END
END; { change_filepath }

{ --------------------------------------------------------------------- }

PROCEDURE show_filepath( VAR file_list : record_array;
                           selected_file : INTEGER );

{  Displays a dialog box showing the complete filepath. }

VAR
   path_dg_ptr : Dialog_Ptr;
   temp : Str255;
   spc, clicked : INTEGER;
   bvoid : BOOLEAN;

BEGIN
   Find_Dialog( PATH_DG, path_dg_ptr );
   temp := file_list[selected_file].file_path;
   spc := pos( ' ', temp );  { Check if there is a parameter }
   IF ( spc <> 0 )THEN          { There is, so show it, not the executable file }
      temp := copy( temp, (spc+1), length(temp) );

   Set_DText( path_dg_ptr, PATHTEXT, temp, System_Font, TE_Center );
   Set_DText( path_dg_ptr, SHOWDESC, file_list[selected_file].description,
              System_Font, TE_Center );
   Center_Dialog( path_dg_ptr );
   Show_Dialog( path_dg_ptr, 0 );
   clicked := Redo_Dialog( path_dg_ptr, 0 );
   IF ( clicked = CHG_PATH ) THEN
      bvoid := change_filepath( file_list, selected_file );
   dmy := Obj_State( path_dg_ptr, clicked );
   Obj_SetState( path_dg_ptr, clicked, (dmy-SELECTED)&dmy, FALSE );
   redraw := TRUE
END; { show_filepath }

{ ---------------------------------------------------------------------- }

PROCEDURE add_file( VAR file_list : record_array;
                    VAR list_size, pages : INTEGER;
                    current_page, first_file : INTEGER );

{ Add file control routine.  Calls change_filepath and change_description. }

VAR
   return : BOOLEAN;
   current_page_str : Str255;

BEGIN
   REPEAT
      return := change_filepath( file_list, list_size+1 );
      IF return THEN BEGIN
         change_description( file_list, list_size+1, first_file );
         list_size := list_size + 1;
         IF list_size = 1 THEN
            enable_radio_buttons;
         changes := TRUE;
         IF list_size = MAX_LIST_SIZE THEN { List is full }
            return := FALSE
      END
   UNTIL NOT return;
   IF Obj_State( main_dg_ptr, SORT_BUT ) & Selected <> 0  THEN
      bubble_sort( file_list, list_size );
   set_up_files( pages, list_size );
   show_files( file_list, first_file, list_size, current_page, pages );
   redraw := TRUE
END; { add_file }

{ ---------------------------------------------------------------------- }

PROCEDURE run_file( VAR file_list : record_array;
                    VAR list_size : INTEGER;
                    filepath : Str255;
                    file_no : INTEGER );
{ This is the procedure that controls the loading of programs or
  instant-load JMP filelists.  It also executes the file viewer if one
  was installed. }

VAR
   readfile : TEXT;
   c_runpath : C_String;
   tos : BOOLEAN;
   spc, error, drv, i : INTEGER;
   parameter, runpath, textfile, filename : Str255;
   ext : ext_type;
   c : CHAR;

BEGIN
   spc := pos( ' ', filepath );
   IF ( spc <> 0 ) THEN BEGIN  { Parameter will need to be passed }
       parameter := copy( filepath, (spc+1), length( filepath ) );
       FOR i := 1 TO length( parameter ) DO
          c_parameter[i] := parameter[i];
       c_parameter[ length(parameter)+1 ] := chr(0);
       c_parameter[0] := chr( length(parameter) );
       runpath := copy(filepath, 1, (spc-1))
   END
   ELSE BEGIN
      c_parameter[0] := chr(0);
      c_parameter[1] := chr(0);
      runpath := filepath
   END;
   env := 'PATH=A:\ ';
   env[9] := chr(0);
   P_To_CStr( runpath, c_runpath );
   drv := ord( runpath[1] )-65;
   parse( runpath, filename );
   get_extender( filename, ext );
   IF ( ext = 'JMP' ) THEN BEGIN { instant-load JMP file }
      load_jmp_file( filepath, title, file_list, list_size,
                     first_file, pages, current_page, error );
      IF ( error = NO_ERROR ) THEN BEGIN
         IF ( stack_cnt = 0 ) AND ( main_dialog <> MAIN_DG2 )THEN
            enable_radio_buttons;
         stack_cnt := stack_cnt + 1;
         IF ( stack_cnt > MAX_STACK_SIZE ) THEN
            stack_cnt := MAX_STACK_SIZE;
         stack[stack_cnt] := filepath; { Put name on the stack }
         Show_Dialog( main_dg_ptr, JUMPNAME );
         IF file_no > 0 THEN
            redraw_files
      END
   END
   ELSE IF ( ext = 'PRG' ) OR ( ext = 'APP' ) OR
           ( ext = 'TOS' ) OR ( ext = 'TTP' ) THEN BEGIN { Run program }
      chdir( runpath, drv );       { Move to program's directory }
      End_Dialog( main_dg_ptr );   { Remove JumpSTART dialog box }
      IF ( main_dialog <> MAIN_DG2 ) THEN BEGIN  { Didn't put the menu }
         Erase_Menu( da_menu );                  { on the screen in low res. }
         Delete_Menu( da_menu );
         Draw_String( 0, 14 DIV yres, BLANKLINE )
      END;
      Set_Mouse( M_Bee );  { Set mouse to busy bee }
      IF ( ext = 'TOS' ) OR ( ext = 'TTP' ) THEN  { Is it a TOS program? }
         tos := TRUE
      ELSE
         tos := FALSE;
      Exit_Gem;     { Leave GEM }
      Redraw_Screen;
      IF tos THEN   { If TOS program, then clear the screen, show cursor }
         tos_screen;
{      p_exec( 0, c_runpath, c_parameter, env ); } { Run the program }
      shell_write( 1, 1, 0, c_runpath, c_parameter );
      IF ( Init_Gem < 0 ) THEN { Re-Install GEM }
         Halt;
      wind_new; { TOS 1.4 and up initialization call }
      IF tos THEN BEGIN { Wait for keypress if TOS program }
         write('Press any key to return to JumpSTART :');
         WHILE NOT keypress DO ;
            read( c );
         gem_screen
      END;
      init_screen;
      { Close any windows left open by messy applications }
      { NOTE THAT THIS DOESN'T APPEAR TO WORK IN ALL CASES! }
      i := Front_Window;
      WHILE ( i > 0 ) DO BEGIN
         Close_Window( i );
         Delete_Window( i );
         i := Front_Window
      END;
      { Show the mouse using LINEA }
      Intin^[0] := 0;
      Linea_Showms;
      redraw := TRUE
   END
   ELSE BEGIN { Load text file viewer }
      textfile := concat( load_dir, 'JUMPST2.DAT' );
      IO_Check( FALSE );
      reset( readfile, textfile );
      error := IO_Result;
      IF ( error = NO_ERROR ) THEN BEGIN
         readln( readfile, textfile );   { Get the pathname of the viewer }
         close( readfile );
         drv := ord( filepath[1] ) - ord( 'A' );  { Get drive of text file }
         runpath := concat( textfile, ' ', filepath ); { Create command line }
         run_file( file_list, list_size, runpath, 0 ); { Run viewer }
         parse( filepath, textfile );                  { Get path of text file }
         chdir( filepath, drv )                        { Move to text file dir }
      END
   END
END; { run_file }

{ ---------------------------------------------------------------------- }

PROCEDURE check_radio_buttons( VAR file_list : record_array;
                               VAR selected_file, list_size, first_file,
                                   current_page, pages : INTEGER );

{ When a filename is clicked on this procedure determines what to do.
  1.) Run the file
  2.) New Description
  3.) New filepath
  4.) Remove file  }

VAR
   i, file_number : INTEGER;
   c_parameter : C_String;

BEGIN
   redraw := FALSE;
   file_number := selected_file-NAME_1+first_file;
   IF ( Obj_State( main_dg_ptr, RUN_BUT ) & Selected <> 0 ) THEN
      IF ( file_number <= list_size ) THEN
         run_file( file_list, list_size,
                   file_list[file_number].file_path, file_number );
   IF ( Obj_State( main_dg_ptr, DESC_BUT ) & Selected <> 0 ) THEN
      IF ( file_number <= list_size ) THEN BEGIN
         change_description( file_list, file_number, first_file );
         show_files( file_list, first_file, list_size, current_page, pages )
      END;

   IF ( Obj_State( main_dg_ptr, REMOVE ) & Selected <> 0 ) THEN
      IF ( file_number <= list_size ) THEN BEGIN
         remove_file( file_list, list_size, pages, first_file,
                      current_page, file_number );
         show_files( file_list, first_file, list_size, current_page, pages );
         redraw_files;
         changes := TRUE
      END;

   IF ( Obj_State( main_dg_ptr, PATH_BUT ) & Selected <> 0 ) THEN
      IF ( file_number <= list_size ) THEN
         show_filepath( file_list, file_number )

END; { check_radio_buttons }

{ -------------------------------------------------------------------- }

PROCEDURE use_da;

{  Puts a menu bar on the screen to allow the user to access the Desk
   accessories. }

VAR
   i, dummy, which : INTEGER;
   msg : Message_Buffer;

BEGIN
   End_Dialog( main_dg_ptr );
   Redraw_Screen;
   redraw := TRUE;
   REPEAT
      which := Get_Event( E_Message, 0, 0, 0, 0,
               FALSE, 0, 0, 0, 0, FALSE, 0, 0, 0, 0, msg,
               dummy, dummy, dummy, dummy, dummy, dummy )
   UNTIL msg[3] = Desk_Title;
   Menu_Normal( da_menu, msg[3] );
   Draw_String( 132, 14 DIV yres, '                                               ' );
   { Close any desk accessory windows left open }
   i := Front_Window;
   WHILE i>0 DO BEGIN
      Close_Window( i );
      Delete_Window( i );
      i := Front_Window
   END
END;

{ --------------------------------------------------------------------- }

PROCEDURE clear_list;
VAR
   lp : INTEGER;

BEGIN
   list_size := 0;
   FOR lp := 0 TO (NAME_21-NAME_1) DO BEGIN
      Set_DText( main_dg_ptr, NAME_1+lp, BLANKLINE, System_Font, TE_Center );
      Obj_SetState( main_dg_ptr, NAME_1+lp, Normal, FALSE )
   END;
   FOR lp := 1 TO MAX_LIST_SIZE DO BEGIN
      file_list[lp].description := BLANKLINE;
      file_list[lp].file_path := ''
   END;
   pages := 1;
   current_page := 1;
   title := '';
   change_title( title, FALSE );
   IF main_dialog <> MAIN_DG2 THEN BEGIN
      dmy := Obj_State( main_dg_ptr, ADD_BUT );
      Obj_SetState( main_dg_ptr, ADD_BUT, (dmy|DISABLED-DISABLED)&dmy, TRUE );
   END;
   show_files( file_list, 1, 0, 1, 1 );
   changes := TRUE

END;

{ --------------------------------------------------------------------- }

PROCEDURE control_dialog;

VAR
   dmy : INTEGER;

BEGIN
   REPEAT
      IF ( main_dialog <> MAIN_DG2 ) AND ( NOT redraw ) THEN
         pushed := Redo_Dialog( main_dg_ptr, 0 ) & $7FFF
      ELSE
         pushed := Do_Dialog( main_dg_ptr, 0 ) & $7FFF;

      IF ( pushed >= NAME_1 ) AND ( pushed <= NAME_21 ) THEN
         check_radio_buttons( file_list, pushed, list_size, first_file,
                              current_page, pages )
      ELSE
         CASE pushed OF
            JUMPNAME : change_title( title, TRUE );

            UP_BUT   : BEGIN
                          page_updown( first_file, current_page, pages,
                                       TRUE );
                          IF ( pages > 1 ) THEN BEGIN
                             show_files( file_list, first_file, list_size,
                                      current_page, pages );
                             redraw_files
                          END
                       END;

            DOWN_BUT : IF ( pages <> 1 ) THEN BEGIN
                          page_updown ( first_file, current_page, pages,
                                        FALSE );
                          show_files( file_list, first_file, list_size,
                                      current_page, pages );
                          redraw_files
                       END;

            PREVJMP  : IF ( stack_cnt > 1 ) THEN BEGIN
                          load_jmp_file( stack[stack_cnt-1], title, file_list,
                                         list_size, first_file, pages,
                                         current_page, error );
                          Show_Dialog( main_dg_ptr, JUMPNAME );
                          stack[stack_cnt] := '';
                          stack_cnt := stack_cnt - 1;
                          redraw := FALSE;
                          redraw_files
                       END
                       ELSE
                          redraw := FALSE;

            HELP_BUT : BEGIN
                          show_help_dialog;
                          redraw := TRUE
                       END;

            LOAD_BUT : BEGIN
                          ftitle := 'Select file to load :';
                          temp := '';
                          IF get_filename( '*', temp, ftitle ) THEN
                          BEGIN
                             run_file( file_list, list_size, temp, 0 );
                             redraw := TRUE
                          END
                       END;

            SAVE_BUT : IF stack_cnt > 0 THEN
                          save_file( stack[stack_cnt], file_list, title,
                                     list_size )
                       ELSE
                          save_file( jump_filename, file_list, title,
                                     list_size );

            READ_A   : BEGIN
                          load_jmp_file( stack[1], title, file_list,
                                         list_size, first_file, pages,
                                         current_page, error );
                          IF ( error = NO_ERROR ) THEN BEGIN
                             stack_cnt := 1;
                             redraw_files;
                             Show_Dialog( main_dg_ptr, JUMPNAME );
                          END
                       END;

            ADD_BUT  : add_file( file_list, list_size, pages,
                                 current_page, first_file );

            CONF_BUT : BEGIN
                          clear_list;
                          redraw_files;
                          Show_Dialog( main_dg_ptr, JUMPNAME );
                          changes := TRUE
                       END;

            DA_BUT   : use_da;

            SORT_BUT : BEGIN
                          changes := TRUE;
                          redraw := FALSE;
                          IF Obj_State( main_dg_ptr, SORT_BUT ) & Selected <> 0
                             THEN BEGIN
                             bubble_sort( file_list, list_size );
                             show_files( file_list, first_file, list_size,
                                         current_page, pages );
                             redraw_files
                          END;
                       END;

            TITLEBOX : BEGIN
                          ivoid := Do_Alert
               ('[0][ GEnie : P.LEFEBVRE | Delphi : PLEFEBVRE ][ OK ]',1);
                          redraw := FALSE
                       END;

            OTHERWISE : redraw := FALSE

         END; { CASE, ELSE }
      IF pushed <> SORT_BUT THEN BEGIN
         dmy := Obj_State( main_dg_ptr, pushed );
         Obj_SetState( main_dg_ptr, pushed, (dmy-SELECTED), NOT redraw );
      END;
      IF changes AND ( main_dialog <> MAIN_DG2 ) THEN BEGIN
         dmy := Obj_State( main_dg_ptr, SAVE_BUT );
         if dmy & DISABLED <> 0 THEN BEGIN
            Obj_SetState( main_dg_ptr, SAVE_BUT, (dmy-DISABLED), TRUE );
         END
      END;
      IF list_size = MAX_LIST_SIZE THEN BEGIN
         dmy := Obj_State( main_dg_ptr, ADD_BUT );
         Obj_SetState( main_dg_ptr, ADD_BUT, dmy|Disabled, TRUE );
      END;

   UNTIL pushed = QUIT_BUT
END;

{ ===================================================================== }

BEGIN { main }
   id := Init_Gem;
   IF ( id >= 0 ) THEN BEGIN
      prg_name := '  JumpSTART';
      ivoid := Menu_Register( id, prg_name );
      rez := getrez;
      CASE rez OF
         0 : BEGIN
      jump_filename := 'STARTLOW.JMP';
                xres := 2;
                yres := 2;
                main_dialog := MAIN_DG2;
                FOR lp := 0 TO 15 DO
                   old_colors[lp] := setcolor( lp, -1 )
             END;
         1 : BEGIN
            jump_filename := 'STARTMED.JMP';
                xres := 1;
                yres := 2;
                main_dialog := MAIN_DG3;
                FOR lp := 0 TO 3 DO
                   old_colors[lp] := setcolor( lp, -1 )
             END;
         2 : BEGIN
            jump_filename := 'STARTHI.JMP';
                xres := 1;
                yres := 1;
                main_dialog := MAIN_DG;
                FOR lp := 0 TO 1 DO
                   old_colors[lp] := setcolor( lp, -1 )
             END
      END;
      IF ( cmd_args > 0 ) THEN { Parameter was passed }
         cmd_getarg( 1, jump_filename ); { Get it }
      IF Load_Resource( 'jumpst2.rsc' ) THEN BEGIN
         Table := Linea_init;      { Get table of linea variables }
         Intin  := ptr(lpeek(Table + LA_Intin));
         load_drv := dgetdrv;      { Startup drive }
         ivoid := dgetpath( c_load_dir, load_drv+1 ); { Startup path }
         C_To_Pstr( c_load_dir, load_dir );
         load_dir := concat( chr( load_drv+65 ), ':', load_dir, '\' );
         jump_filename := concat( load_dir, jump_filename );
         changes := FALSE;

         set_up_everything;
         init_screen;
         clear_list;
         list_size := 0;
         sort := FALSE;
         first_file := 1;
         current_page := 1;
         set_up_files( pages, list_size );
         autoload := TRUE;
         load_jmp_file( jump_filename, title, file_list, list_size,
                        first_file, pages, current_page, error );
         autoload := FALSE;
         IF ( error = NO_ERROR ) THEN BEGIN
            IF ( main_dialog <> MAIN_DG2 ) THEN
               enable_radio_buttons;
            stack_cnt := 1;
            stack[stack_cnt] := jump_filename
         END
         ELSE BEGIN
            stack_cnt := 0;
            IF main_dialog <> MAIN_DG2 THEN BEGIN
               dmy := Obj_State( main_dg_ptr, SAVE_BUT );
               Obj_SetState( main_dg_ptr, SAVE_BUT, dmy|Normal,
                             FALSE );
            END
         END;
         Work_Rect( 0, x, y, w, h ); { Get screen size }
         Set_Clip( x, y, w, h ); { Set clipping rect to screen size }
         redraw := TRUE;
         control_dialog
      END
      ELSE
         ivoid := Do_Alert( '[3][Can''t find JUMPST2.RSC!][ Abort ]', 1 );
      Exit_Gem
   END
END. { main }

