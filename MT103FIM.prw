
// Programa...: MT103FIM
// Autor......: Maurício C. Dani - TOTVS RS
// Data.......: 15/05/2018
// Descricao..: P.E. - Operação após gravação da NFE
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Operação após gravação da NFE
// #PalavasChave      #ponto_de_entrada #gravacao_NFE 
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
// 25/08/2021 - Robert  - Nova versao de ciencia e manifesto da TRS (GLPI 10822)
// 30/08/2021 - Robert  - Passa a fazer manifesto somente se o usuario confirmou a tela.
//

// --------------------------------------------------------------------------
User Function MT103FIM()
	local _aAreaAnt := U_ML_SRArea ()
	Local _lConf    := PARAMIXB[2]==1

//	if _lConf  // Usuario confirmou a tela
	if alltrim (cEspecie) == 'SPED' .and. _lConf  // Usuario confirmou a tela
		//Realiza ciência
		U_FBTRS101({SF1->F1_CHVNFE}, 4, '')
		//Abre tela do manifesto
		U_FBTRS102(.T.)
	endif

	U_ML_SRArea (_aAreaAnt)
Return

/* Versao inicial quando fazia download pelo proprio importador
	//Local lRet:= .T.
	Local aArea         := GetArea()
    Local lImpXml       := SuperGetMV('VA_XMLIMP', .F., .F.)
	//Importador XML - Baixa automática.
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
// Função fConfManif
Static Function fConfManif()
	(_cTabXML)->(dbSetOrder(5))
	(_cTabMAN)->(dbSetOrder(1))

	// Posiciona na ZTB(Manifesto) para verificar se a nota foi baixada via manifesto eletrônico
	If !(_cTabMAN)->(MsSeek(xFilial(_cTabMAN) + SF1->F1_CHVNFE))
		// MsgInfo("Não foi possível localizar essa nota ou ela não foi teve download realizado via manifesto eletrônico!")
		Return
	ElseIf (_cTabXML)->(MsSeek(xFilial(_cTabXML) + SF1->F1_CHVNFE))
		// Aqui garante que se a nota foi baixada via manifesto a informação permaneça correta na ZA1010
		RecLock(_cTabXML, .F.)
		&(_cTabXML+"->" + _cTabXML + "_BXAUTO"):= 'S'
		MsUnlock()
	EndIf

	If &(_cTabMAN+"->" + _cTabMAN + "_STATUS") != '4'
		Return
	EndIf

	If nOpcao == 4 .And. nConfirma == 1 // Se confirmar a classificação, faz a manifestação automática de confirmação da operação
		// MsgInfo('Manifestação automática')
		lRet := U_FBMAN006({1, ''}, .F., .T.)
		// U_fManifest({ZA1->ZA1_CHVNFE}, 1) // Confirmação da Operação
	EndIf

Return
*/
