//  Programa...: CH_ETF
//  Autor......: Adelar D. Minuzzo
//  Data.......: abr/2006
//  Cliente....: Alianca
//  Descricao..: Chamada para impressao do programa de impressao etiqueta de volumes ml_etf.prw
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------------
#INCLUDE "rwmake.ch"

User Function CH_ETF()
	Private lfim := .T.
	
	Do While LFIM
	   U_ML_etf()
	   
	   If MSGYESNO("Continuar no programa?","Continuar")
	      nopc := "1"
	   Else
	      nopc := "2"
	   EndIf    
	   
	   If nopc == "2"
	      EXIT
	   EndIf
	EndDo
	
Return      
     