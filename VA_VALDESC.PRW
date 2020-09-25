#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User function VA_VALDESC(_par)
desconto:= GDFIELDGET("C6_DESCONT",)

if _par==1
	desc	:= M->C5_DESC1
elseif _par==2 
	desc	:= M->C5_DESC2
elseif _par==3 
	desc	:= M->C5_DESC3
elseif _par==4
	desc	:= M->C5_DESC4
endif 
 
IF desconto<> 0
 	Alert("Desconto já inserido por linha.")
 	GDFieldPut("C5_DESC1",0) 
 	GDFieldPut("C5_DESC2",0)
 	GDFieldPut("C5_DESC3",0)
  	GDFieldPut("C5_DESC3",0) 
  	desc:=0	
ENDIF                                                      

Return desc