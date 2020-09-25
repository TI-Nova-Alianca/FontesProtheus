#INCLUDE "PROTHEUS.CH"

//Fábio Andr'Michelon - Microsiga Serra Gaúcha - 09/10/2006
//Objetivo:	inicializador padrão do campo ZM_ITEM
User Function MLSZMIT()

Local	_xItem	:=	"0001"
Local	_xPosItem	:=	Ascan(aHeader,{|xCpo| Alltrim(xCpo[2]) == "ZM_ITEM"})
Local	_nLinha  
If aCols <> nil
	For _nLinha := 1 To Len( aCols )
		If !Empty(aCols[_nLinha,_xPosItem])
			_xItem	:=	aCols[_nLinha,_xPosItem]
		Endif
	Next
Endif

Return SOMA1(_xItem)
