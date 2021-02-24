
// Programa...: MT103FIM
// Autor......: Maur�cio C. Dani - TOTVS RS
// Data.......: 15/05/2018
// Descricao..: P.E. - Opera��o ap�s grava��o da NFE
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Opera��o ap�s grava��o da NFE
// #PalavasChave      #ponto_de_entrada #gravacao_NFE 
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
//
// --------------------------------------------------------------------------

#Include 'Protheus.ch'

User Function MT103FIM()
	//Local lRet:= .T.
	Local aArea         := GetArea()
    Local lImpXml       := SuperGetMV('VA_XMLIMP', .F., .F.)
	//Importador XML - Baixa autom�tica.
	Private nOpcao 		:= ParamIxb[1]
	Private nConfirma	:= ParamIxb[2]
	Private _lAuto		:= .F.
	Private _CCGCSM0 	:= Nil
	Private _cTabXML  := AllTrim(SuperGetMv("006_TABXML"  ,.F.,"" ))
	Private _cTabMAN  := AllTrim(SuperGetMv("009_TABMAN"  ,.F.,"" ))
	
    If lImpXml 
        ConOut("INICIO_MT103FIM")
        ConOut(nOpcao)
        ConOut(nConfirma)
        
        If nOpcao != 4
            Return
        EndIf 

        If !SuperGetMV('009_USAMAN', .F., .F.)
            Return .T.
        EndIf	
        
        fConfManif()
        RestArea(aArea)
        ConOut("INICIO_MT103FIM")
    EndIf
Return
//
// ----------------------------------------------------------------------------------------------------------
// Fun��o fConfManif
Static Function fConfManif()
	(_cTabXML)->(dbSetOrder(5))
	(_cTabMAN)->(dbSetOrder(1))

	// Posiciona na ZTB(Manifesto) para verificar se a nota foi baixada via manifesto eletr�nico
	If !(_cTabMAN)->(MsSeek(xFilial(_cTabMAN) + SF1->F1_CHVNFE))
		// MsgInfo("N�o foi poss�vel localizar essa nota ou ela n�o foi teve download realizado via manifesto eletr�nico!")
		Return
	ElseIf (_cTabXML)->(MsSeek(xFilial(_cTabXML) + SF1->F1_CHVNFE))
		// Aqui garante que se a nota foi baixada via manifesto a informa��o permane�a correta na ZA1010
		RecLock(_cTabXML, .F.)
		&(_cTabXML+"->" + _cTabXML + "_BXAUTO"):= 'S'
		MsUnlock()
	EndIf

	If &(_cTabMAN+"->" + _cTabMAN + "_STATUS") != '4'
		Return
	EndIf

	If nOpcao == 4 .And. nConfirma == 1 // Se confirmar a classifica��o, faz a manifesta��o autom�tica de confirma��o da opera��o
		// MsgInfo('Manifesta��o autom�tica')
		lRet := U_FBMAN006({1, ''}, .F., .T.)
		// U_fManifest({ZA1->ZA1_CHVNFE}, 1) // Confirma��o da Opera��o
	EndIf

Return
