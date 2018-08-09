{   GEMDOS.PAS              Often used GEMDOS routines.

    Make sure that this file is included AFTER AUXSUBS.PAS is included!

    by Paul Lefebvre 12-30-90
    Modified to include p_exec on 4-3-92
}

TYPE
{   disk_info_structure = ARRAY[1..4] OF LONG_INTEGER;}
   C_Path_Type = PACKED ARRAY [0..80] OF CHAR;
   environment                    = PACKED ARRAY[1..9] OF CHAR;
   
FUNCTION dsetpath( VAR name : C_String ) : SHORT_INTEGER;
{ Sets the directory of the current drive to 'name'. }
   GEMDOS(59);
   
FUNCTION dgetpath( VAR name : C_String; drive : SHORT_INTEGER ) : SHORT_INTEGER;
{ Gets the current directory from drive 'drive' and puts the name in
  'name'.  Drive current = 0, A = 1, B = 2, etc. }
   GEMDOS(71);
   
FUNCTION dgetdrv : SHORT_INTEGER;
{ Returns the active drive in 'dgetdrv'.  Drive A = 0, B = 1, etc. }
   GEMDOS(25);
   
FUNCTION dsetdrv( drive : SHORT_INTEGER ) : SHORT_INTEGER;
{ Make drive 'drive' the active drive.  Drive A = 0, B = 1, etc. }
   GEMDOS(14);
   
(* FUNCTION dfree( VAR disk_info : disk_info_structure;
                drive : SHORT_INTEGER ) : SHORT_INTEGER;
{ Gets the total and free space on drive 'drive'.  Drive current = 0,
  A = 1, B = 2, etc.
  free space := disk_info[1]*disk_info[3]*disk_info[4];
  total space := disk_info[2]*disk_info[3]*disk_info[4]; }
   GEMDOS(54); *)

PROCEDURE p_exec( load : INTEGER; VAR name : C_Path_Type;
                 VAR tail : C_String; VAR envp : environment );
   GEMDOS($4B);
   
