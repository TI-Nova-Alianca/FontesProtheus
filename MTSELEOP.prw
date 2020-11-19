// Programa:   MTSELEOP
// Autor:      Catia Cardoso	
// Data:       27/09/2018
// Descricao:  P.E. para desabilitar o grupo de opicionais na tela de pedidos
//
// Historico de alteracoes:
// 05/10/2018 - Robert - Habilita tela apenas para o MATA650
//

// --------------------------------------------------------------------------
User function MTSELEOP()

	//Local cRet 	:= ParamIxb[1]
	//Local cProd := ParamIxb[2]
	Local cProg := ParamIxb[3]
	Local lRet  := .F.

//	lRet := msgyesno ("Desabilitar opcionais?")
	 if cProg == 'MATA650'
	 	lRet = .T.
	 else
	 	lRet = .F.
	 endif

Return lRet                                  
