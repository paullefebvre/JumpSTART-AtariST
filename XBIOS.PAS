FUNCTION getrez : SHORT_INTEGER;
{ 0 = low, 1 = medium, 2 = high }
   XBIOS(4);
   
FUNCTION setcolor( color_register, new_color : SHORT_INTEGER ) : SHORT_INTEGER;
{  If new_color = -1 then function returns the current color value. }
   XBIOS(7);

