#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"


User Function VA_SZQR(_cNumGuia)   
   	   
		IF MsgYesNo("Imprimir Guia de Livre Tr�nsito nova? ")
			U_VA_SZQR1(_cNumGuia)           
		Else
			U_VA_SZQR2(_cNumGuia)
		endif
return
