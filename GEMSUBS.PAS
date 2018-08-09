CONST

{ Personal Pascal GEM library constant definitions. }

    No_Window	= -1 ;
    Root	= 0 ;            { Index of root w/in object tree }
    Max_Tree	= 100 ;
    Null_Index	= -1 ;           { Index of a non-existent item }
    Max_Depth	= 8 ;            { Max depth of search or draw }

    Max_Fn	= 12 ;           { Max length of individual file/path name }
    Max_Path	= 80 ;
    Max_WTitle	= 80 ;

    Desk_Title = 3 ;    { The index of the "desk" item in the menu bar }

  { Event values: }
    E_Keyboard	= $01 ;
    E_Button	= $02 ;
    E_MRect_1	= $04 ;
    E_MRect_2	= $08 ;
    E_Message	= $10 ;
    E_Timer	= $20 ;

  { Graphics command constants: }
    { Drawing modes: }
    Replace_Mode   = 1 ;
    Trans_Mode	   = 2 ;
    XOR_Mode	   = 3 ;
    Rev_Trans_Mode = 4 ;

  { Line styles: }
    Solid	= 1 ;
    LongDash	= 2 ;
    Dotted	= 3 ;
    DashDot	= 4 ;
    Dashed	= 5 ;
    DashDotDot	= 6 ;

  { Text effects: }
    Normal	= 0 ;
    Thickened	= 1 ;
    Lightened	= 2 ;
    Slanted	= 4 ;
    Underlined	= 8 ;
    Outlined	= 16 ;
    Shadowed	= 32 ;

  { Font types: }
    System_Font = 3 ;
    Small_Font  = 5 ;

  { Graphic types of obs: }
    G_Box	= 20 ;
    G_Text	= 21 ;
    G_BoxText	= 22 ;
    G_IBox	= 25 ;
    G_Button	= 26 ;
    G_String	= 28 ;
    G_FText	= 29 ;
    G_FBoxText	= 30 ;

  { Object flags: }
    None	= $000 ;    { Also used for fill pattern and text effects. }
    Selectable	= $001 ;
    Default	= $002 ;
    Exit_Btn	= $004 ;
    Editable	= $008 ;
    Radio_Btn	= $010 ;
    Last_Ob	= $020 ;
    Touch_Exit	= $040 ;
    Hide_Tree	= $080 ;

  { Object states: }
    { Use Normal for no special state }
    Selected	= $01 ;
    Crossed	= $02 ;
    Checked	= $04 ;
    Disabled	= $08 ;
    { Outlined and Shadowed are defined under text effects }

  { Window elements: }
    G_Name	= $001 ;
    G_Close	= $002 ;
    G_Full	= $004 ;
    G_Move	= $008 ;
    G_Info	= $010 ;
    G_Size	= $020 ;
    G_UpArrow	= $040 ;
    G_DnArrow 	= $080 ;
    G_VSlide	= $100 ;
    G_LArrow	= $200 ;
    G_RArrow	= $400 ;
    G_HSlide	= $800 ;
    G_All	= $FEF ;          { All elements, except info line }

  { Color register shorthands: }
    White	= 0 ;
    Black	= 1 ;
    Red		= 2 ;
    Green	= 3 ;
    Blue	= 4 ;
    Cyan	= 5 ;
    Yellow	= 6 ;
    Magenta	= 7 ;
    L_White	= 8 ;
    L_Black	= 9 ;
    L_Red	= 10 ;
    L_Green	= 11 ;
    L_Blue	= 12 ;
    L_Cyan	= 13 ;
    L_Yellow	= 14 ;
    L_Magenta	= 15 ;

  { Predefined GEM messages: }
    MN_Selected	= 10 ;
    WM_Redraw	= 20 ;
    WM_Topped	= 21 ;
    WM_Closed	= 22 ;
    WM_Fulled	= 23 ;
    WM_Arrowed	= 24 ;
    WM_HSlid	= 25 ;
    WM_VSlid	= 26 ;
    WM_Sized	= 27 ;
    WM_Moved	= 28 ;

  { Wind_Get/Set field values: }
    WF_PrevXYWH	= 6 ;
    WF_FullXYWH	= 7 ;
    WF_HSlide	= 8 ;
    WF_VSlide	= 9 ;
    WF_HSlSize	= 15 ;
    WF_VSlSize	= 16 ;

  { Desk-Accessory values: }
    AC_Close	= 41 ;

{ End of constants used in GEM interface }
{ ====================================================================== }

TYPE

{ Common GEM type definitions for Personal Pascal library. }

    Color_Reg  = 0..15 ;
    Draw_Modes = Replace_Mode..Rev_Trans_Mode ;
    Line_Types = Solid..DashDotDot ;

    Mouse_Type = ( M_Arrow, M_Text_Curs, M_Bee, M_Point_Hand, M_Flat_Hand,
                   M_Thin_Cross, M_Thick_Cross, M_Outln_Cross ) ;

    Dialog_Ptr	= ^CHAR ;  {arbitrary pointer type}
    Menu_Ptr	= ^CHAR ;  {arbitrary pointer type}
    Word16 	= ARRAY [ 0..15 ] OF Short_Integer ;
    Mouse_Form 	= RECORD
			hot_x	   : Short_Integer ;
			hot_y	   : Short_Integer ;
			res	   : Short_Integer ;
			mask_color : Short_Integer ;
			data_color : Short_Integer ;
			mask	   : Word16 ;
			data	   : Word16 ;
		  END ;

    File_Name	 = STRING [ Max_Fn ] ;
    Path_Name	 = STRING [ Max_Path ] ;
    Window_Title = STRING [ Max_WTitle ] ;

    Message_Buffer = ARRAY [ 0..15 ] OF Short_Integer ;

    Str255	= STRING [ 255 ] ;

  { Editable text justification: }
    TE_Just	= ( TE_Left, TE_Right, TE_Center ) ;

  { Possible indices into a tree: }
    Tree_Range = Root..Max_Tree ;
    Tree_Index = Null_Index..Max_Tree ;

  { AES- and VDI-Types}
{              ^CHAR }
     POINTER = ^C_String;  {Arbitrary pointer type...actual type situation dependent}

     INT_IN_parms    = ARRAY [0..16]   OF Short_Integer;
     INT_OUT_parms   = ARRAY [0..7]   OF Short_Integer;
     Addr_IN_parms   = ARRAY [0..2]    OF Pointer;
     Addr_Out_parms  = ARRAY [0..1]    OF Pointer;
     Ctrl_Parms      = ARRAY [ 0..11 ] OF Short_Integer ;
     Pts_In_Parms    = ARRAY [ 0..11 ] OF Short_Integer ;
     Pts_Out_Parms   = ARRAY [ 0..11 ] OF Short_Integer ;

{ End of TYPEs used in GEM library definitions }
{ ====================================================================== }

{ EXTERNAL declarations, etc.,  for Personal Pascal GEM library routines. }

FUNCTION Init_Gem 
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Exit_Gem ;
	EXTERNAL ;

FUNCTION Do_Alert( alert   : Str255 ;
		   def_btn : Short_Integer )
	: Short_Integer ;
	EXTERNAL ;

{ dialog-oriented subprograms }

FUNCTION New_Dialog( n_items, x, y, w, h : Short_Integer )
	: Dialog_Ptr ;
	EXTERNAL ;
PROCEDURE Delete_Dialog( dial : Dialog_Ptr ) ;
	EXTERNAL ;
FUNCTION Add_DItem( dial          : Dialog_Ptr ; 
		    i_type, flags : Short_Integer ;
		    x, y, w, h    : Short_Integer ;
		    border, color : Short_Integer )
	: Tree_Index ;
	EXTERNAL ;
FUNCTION D_Color( border, text   : Short_Integer ;
		  text_mode      : Boolean ;
		  pattern, fill  : Short_Integer )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Set_DText( dial : Dialog_Ptr ;
		     item : Tree_Index ;
		     s    : Str255 ;
		     font : Short_Integer ;
		     just : TE_Just ) ;
	EXTERNAL ;
PROCEDURE Set_DEdit( dial : Dialog_Ptr ;
		     item : Tree_Index ;
		     template, valid, initial : Str255 ;
		     font : Short_Integer ;
		     just : TE_Just ) ;
	EXTERNAL ;
PROCEDURE Obj_SetState( dial   : Dialog_Ptr ;
			index  : Tree_Index ;
			state  : Short_Integer ;
			redraw : boolean ) ;
	EXTERNAL ;
FUNCTION Obj_State( dial  : Dialog_Ptr ;
		    index : Tree_Index ) 
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Obj_SetFlags( dial : Dialog_Ptr ;
			index : Tree_Index ;
			flags : Short_Integer ) ;
	EXTERNAL ;
FUNCTION Obj_Flags( dial : Dialog_Ptr ;
		    index : Tree_Index ) 
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Center_Dialog( dial : Dialog_Ptr ) ;
	EXTERNAL ;
FUNCTION Do_Dialog( dial      : Dialog_Ptr ;
		    start_obj : Short_Integer )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Get_DEdit( dial  : Dialog_Ptr ;
		     item  : Tree_Index ;
		     VAR s : Str255 ) ;
	EXTERNAL ;
FUNCTION Redo_Dialog( dial      : Dialog_Ptr ;
		      start_obj : Short_Integer )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE End_Dialog( dial : Dialog_Ptr ) ;
	EXTERNAL ;
PROCEDURE Show_Dialog( dial   : Dialog_Ptr ;
                       item   : Tree_Index ) ;
	EXTERNAL ;
PROCEDURE Obj_ReDraw(  dial   : Dialog_Ptr ;
                       item   : Tree_Index ) ;
        BEGIN
            Show_Dialog( dial, item ) ;
        END ;

{ predefined dialog routines }

FUNCTION Get_In_File( VAR path, name : Path_Name )
	: boolean ;
	EXTERNAL ;
FUNCTION Get_Out_File(	prompt : Str255 ;
			VAR name : Path_Name ) 
	: boolean ;
	EXTERNAL ;

{ menu-oriented subprograms }

FUNCTION New_Menu( n_items : Short_Integer ;
		   about   : Str255 )
	: Menu_Ptr ;
	EXTERNAL ;
PROCEDURE Delete_Menu( menu : Menu_Ptr ) ;
	EXTERNAL ;
FUNCTION Add_MTitle( menu : Menu_Ptr ;
		     item : Str255 )
	: Short_Integer ;
	EXTERNAL ;
FUNCTION Add_MItem( menu  : Menu_Ptr ;
		    title : Tree_Index ;
		    item  : Str255 )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Draw_Menu( menu : Menu_Ptr ) ;
	EXTERNAL ;
PROCEDURE Erase_Menu( menu : Menu_Ptr ) ;
	EXTERNAL ;
PROCEDURE Menu_Hilight( menu  : Menu_Ptr ;
			title : Tree_Index ) ;
	EXTERNAL ;
PROCEDURE Menu_Normal(	menu  : Menu_Ptr ;
			title : Tree_Index ) ;
	EXTERNAL ;
PROCEDURE Menu_Check( menu    : Menu_Ptr ;
		      item    : Tree_Index ;
		      checked : boolean );
	EXTERNAL ;
PROCEDURE Menu_Enable(  menu : Menu_Ptr ;
			item : Tree_Index ) ;
	EXTERNAL ;
PROCEDURE Menu_Disable( menu : Menu_Ptr ;
			item : Tree_Index ) ;
	EXTERNAL ;
PROCEDURE Menu_Text( menu  : Menu_Ptr ;
		     item  : Tree_Index ;
		     mtext : Str255 ) ;
	EXTERNAL ;
FUNCTION Menu_Register( id : Short_Integer ;      { for desk accessories, only }
			VAR name : Str255 )
	: Short_Integer ;
	EXTERNAL ;

{ window-oriented subprograms}

FUNCTION New_Window( w_type : Short_Integer ;
		     VAR title : Window_Title ;
		     x_max, y_max, w_max, h_max : Short_Integer )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Open_Window(  handle : Short_Integer ;
			x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Close_Window( handle : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Delete_Window( handle : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Set_WSize( handle, x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Set_WName( handle    : Short_Integer ;
		     VAR title : Window_Title ) ;
	EXTERNAL ;
PROCEDURE Set_WInfo( handle : Short_Integer ;
		     VAR info : Window_Title ) ;
	EXTERNAL ;
PROCEDURE Border_Rect(  wind : Short_Integer ;
			VAR x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Work_Rect(  wind : Short_Integer ;
		      VAR x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE First_Rect( wind : Short_Integer ;
		      VAR x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Next_Rect( wind : Short_Integer ;
		      VAR x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
FUNCTION Rect_Intersect( x, y, w, h : Short_Integer ;
			 VAR x1, y1, w1, h1 : Short_Integer )
	: boolean ;
	EXTERNAL ;
FUNCTION Front_Window : Short_Integer ;
	EXTERNAL ;
PROCEDURE Bring_To_Front( handle : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Set_Window( handle : Short_Integer ) ;
	EXTERNAL ;
FUNCTION Get_Window : Short_Integer ;
	EXTERNAL ;

{ window text and graphics subprograms }

PROCEDURE Set_Clip( x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Draw_Mode( mode : Draw_Modes ) ;
	EXTERNAL ;
PROCEDURE Set_Color( reg : Color_Reg ;
		     red, green, blue : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Line_Color( color : Color_Reg ) ;
	EXTERNAL ;
PROCEDURE Line_Style( style : Line_Types ) ;
	EXTERNAL ;
PROCEDURE Paint_Color( color : Color_Reg ) ;
	EXTERNAL ;
PROCEDURE Paint_Style( style : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Paint_Outline( on : boolean ) ;
	EXTERNAL ;
PROCEDURE Text_Color( color : Color_Reg ) ;
	EXTERNAL ;
PROCEDURE Text_Style( style : Short_Integer ) ;
	EXTERNAL ;

PROCEDURE Move_To( x, y : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Line( x1, y1, x2, y2 : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Line_To( newx, newy : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Plot( x, y : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Paint_Rect( x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Frame_Rect( x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Paint_Oval( x, y, x_rad, y_rad : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Frame_Oval( x, y, x_rad, y_rad : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Paint_Round_Rect( x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Frame_Round_Rect( x, y, w, h : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Paint_Arc( x, y, x_rad, y_rad : Short_Integer ;
		     beg_ang, end_ang   : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Frame_Arc( x, y, x_rad, y_rad : Short_Integer ;
		     beg_ang, end_ang   : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Draw_String( x, y : Short_Integer ;
		       s : Str255 ) ;
	EXTERNAL ;
PROCEDURE Text_Height( height : Short_Integer ) ;
	EXTERNAL ;

{ mouse-oriented subprograms }

PROCEDURE Set_MForm( VAR form : Mouse_Form ) ;
	EXTERNAL ;
PROCEDURE Set_Mouse( m_type : Mouse_Type ) ;
	EXTERNAL ;
PROCEDURE Hide_Mouse ;
	EXTERNAL ;
PROCEDURE Show_Mouse ;
	EXTERNAL ;
PROCEDURE Init_Mouse ;
	EXTERNAL ;
PROCEDURE Begin_Mouse ;
	EXTERNAL ;
PROCEDURE End_Mouse ;
	EXTERNAL ;

{ event management }

FUNCTION Get_Event(	event_mask : Short_Integer ;
			btn_mask   : Short_Integer ;
			btn_state  : Short_Integer ;
			n_clicks   : Short_Integer ;
			ticks      : Long_Integer ;
                        r1_flag    : boolean ;
				r1x, r1y, r1w, r1h : Short_Integer ;
                        r2_flag    : boolean ;
				r2x, r2y, r2w, r2h : Short_Integer ;
			VAR message : Message_Buffer ;
			VAR key     : Short_Integer ;
			VAR bstate,bcnt   : Short_Integer ;
			VAR mx, my : Short_Integer ;
			VAR kbd_state : Short_Integer  )
	: Short_Integer ;
	EXTERNAL ;
PROCEDURE Begin_Update ;
	EXTERNAL ;
PROCEDURE End_Update ;
	EXTERNAL ;

{ miscellany }

PROCEDURE Wind_Get( handle, request : Short_Integer ;
		    VAR v1, v2, v3, v4 : Short_Integer );
	EXTERNAL ;
PROCEDURE Wind_Set( handle, request : Short_Integer ;
		    v1, v2, v3, v4 : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Sys_Font_Size( VAR w_char, h_char, w_box, h_box : Short_Integer ) ;
	EXTERNAL ;
PROCEDURE Clear_Screen ;
	EXTERNAL ;

{ resource file subprograms }

FUNCTION Load_Resource( fn : Str255 ) : boolean ;
	EXTERNAL ;
PROCEDURE Find_Menu( index : Short_Integer ;
		     VAR menu : Menu_Ptr ) ;
	EXTERNAL ;
PROCEDURE Find_Dialog(  index : Short_Integer ;
			VAR dial : Dialog_Ptr ) ;
	EXTERNAL ;
PROCEDURE Find_Alert( index : Short_Integer ;
		      VAR alert : Str255 ) ;
	EXTERNAL ;
PROCEDURE Free_Resource ;
	EXTERNAL ;

{ the generic VDI and AES calls ! }

PROCEDURE VDI_Call( cmd, sub_cmd : Short_Integer ;
		    nints, npts  : Short_Integer ;
                    VAR ctrl     : Ctrl_Parms ;
                    VAR int_in   : Int_In_Parms ;
		    VAR int_out  : Int_Out_Parms ;
                    VAR pts_in   : Pts_In_Parms ;
		    VAR pts_out  : Pts_Out_Parms ;
                    translate    : boolean ) ;
	EXTERNAL ;

PROCEDURE AES_CALL( op           : Short_Integer ;
		    VAR Int_In   : Int_In_Parms;
		    VAR Int_Out  : Int_out_Parms;
		    VAR Addr_In  : Addr_In_Parms;
                    VAR Addr_Out : Addr_Out_Parms);
	EXTERNAL;

{ End of gemsubs.pas }

