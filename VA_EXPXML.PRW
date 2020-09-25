// Programa...: VA_EXPXML
// Autor......: Catia Cardoso	
// Data.......: 29/11/2018
// Descricao..: Exporta XML de Notas de Saida
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Exportacao de XML de notas de saida para arquivo
// #PalavasChave      #XML #exporta_arquivo
// #TabelasPrincipais #SF2 #SPED050
// #Modulos           #FAT #FIS
//
// Historico de alteracoes:
// 06/08/2020 - Robert  - Inseridos alguns logs
//                      - Criadas tags para catalogar fontes.
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// ------------------------------------------------------------------------------------------------
User Function VA_EXPXML(_sDestino, _sTipo)
	local i	:= 0

	// _stipo = 1 = Notas de transferencias
	// _stipo = 2 = Notas com transportadora ou redespacho (E_Sales)
	// _stipo = 3 = Notas com titulos para o RED ASET
	// _stipo = 4 = Notas para a transportadora ODONE

	cURL     := PadR(GetNewPar("MV_SPEDURL","http://"),250)
	cDestino := _sDestino
	_wtipo   := _sTipo
	
	do case 
		case _wtipo = "1"
			// exporta notas fiscais de transfencias entre filiais
			_sQuery := ""
		    _sQuery += "SELECT DISTINCT ID_ENT"
		    _sQuery += "  FROM SPED050"
		    _sQuery += " WHERE DATE_NFE = '" + dtos(ddatabase) + "'"
		    _sQuery += "   AND CNPJDEST   BETWEEN '88612486000000' AND '88612486999999'"
		    _sQuery += "   AND D_E_L_E_T_ = ''"
		    //u_showmemo(_sQuery)
		    _aidentidade := U_Qry2Array(_sQuery)
		    //u_showarray(_aidentidade)
		    if len(_aidentidade) >0
		    	for i=1 to len(_aidentidade) 
					_sQuery := ""
				    _sQuery += "SELECT DOC_CHV, ID_ENT, DATE_NFE, NFE_ID"
				    _sQuery += "  FROM SPED050"
				    _sQuery += " WHERE ID_ENT    = '" + _aidentidade [i,1] +"'"
				    _sQuery += "  AND DATE_NFE   = '" + dtos(ddatabase) + "'"
				    _sQuery += "  AND CNPJDEST   BETWEEN '88612486000000' AND '88612486999999'"
				    _sQuery += "  AND D_E_L_E_T_ = ''" 
				    _sQuery += "  AND NOT EXISTS (SELECT ZZX.ZZX_CHAVE"
		            _sQuery += "           FROM ZZX010 AS ZZX"
		            _sQuery += "          WHERE ZZX.ZZX_CHAVE = DOC_CHV)" 
				    u_log2 ('debug', _sQuery)
				    _aNotas := U_Qry2Array(_sQuery)
				    //u_showarray(_aNotas)
				    if len(_aNotas) >0
				    	_exp_XMLS(_aNotas[1,2],_aNotas[1,4],_aNotas[len(_aNotas),4],stod(_aNotas[1,3]))
				    endif
				next
		    endif
		case _wtipo = "4"
			// exporta XML notas fiscais transportadora ODONE
			_sQuery := ""
		    _sQuery += "SELECT DISTINCT SPED.ID_ENT"
		    _sQuery += "  FROM SPED050 SPED"
		    _sQuery += " 	INNER JOIN SF2010 AS SF2"
		    _sQuery += "		ON (SF2.D_E_L_E_T_ = ''"
		    _sQuery += "			AND SF2.F2_EXML   != 'S'"
			_sQuery += "			AND SF2.F2_TRANSP = '364'"
			_sQuery += "			AND SF2.F2_CHVNFE = DOC_CHV)"
			_sQuery += " WHERE SPED.DATE_NFE >= '20190101'"
			_sQuery += "   AND SPED.D_E_L_E_T_ = ''"
		    //u_showmemo(_sQuery)
		    _aidentidade := U_Qry2Array(_sQuery)
		    //u_showarray(_aidentidade)
		    if len(_aidentidade) >0
		    	for i=1 to len(_aidentidade)
		    	 	_sQuery := ""
				    _sQuery += "SELECT SPED.DOC_CHV, SPED.ID_ENT, SPED.DATE_NFE, SPED.NFE_ID"
				    _sQuery += "  FROM SPED050 AS SPED"
				    _sQuery += " 	INNER JOIN SF2010 AS SF2"
				    _sQuery += "		ON (SF2.D_E_L_E_T_ = ''"
				    _sQuery += "			AND SF2.F2_EXML   != 'S'"
					_sQuery += "			AND SF2.F2_TRANSP = '364'"
					_sQuery += "			AND SF2.F2_CHVNFE = DOC_CHV)"
					_sQuery += " WHERE SPED.ID_ENT    = '" + _aidentidade [i,1] +"'"
					_sQuery += "   AND SPED.DATE_NFE   >= '20190101'"
					_sQuery += "   AND SPED.D_E_L_E_T_ = ''"
				    u_log2 ('debug', _sQuery)
				    _aNotas := U_Qry2Array(_sQuery)
				    //u_showarray(_aNotas)
				    if len(_aNotas) > 0
				    	_exp_XMLS(_aNotas[1,2],_aNotas[1,4],_aNotas[len(_aNotas),4],stod(_aNotas[1,3]))
				    endif
				next	
		    endif
		    
		OTHERWISE
		    u_help ("OPCAO AINDA NAO IMPLEMENTADA",, .t.)
	endcase    
Return    
//
// ---------------------------------------------------------------------------
// Exporta XML
Static Function _exp_XMLS(cidentidade,cnotaini,cnotafim,cdataini)    
	local nX	:= 0
	local _sNomeArq := ''
	local _oSQL := NIL

	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := cidentidade
	oWS:_URL              := AllTrim(cURL)+"/NFeSBRA.apw"
	oWS:cIdInicial        := cnotaini
	oWS:cIdFinal          := cnotafim
	oWS:dDataDe           := cdataini
	oWS:dDataAte          := cdataini
	oWS:cCNPJDESTInicial  := '88612486000000'
	oWS:cCNPJDESTFinal    := '88612486999999'
	oWS:nDiasparaExclusao := 0
	lOk:= oWS:RETORNAFX()
	oRetorno := oWS:oWsRetornaFxResult
	lOk := iif( valtype(lOk) == "U", .F., lOk )

	If lOk
	
	    For nX := 1 To Len(oRetorno:OWSNOTAS:OWSNFES3)
	
	    	oXml    := oRetorno:OWSNOTAS:OWSNFES3[nX]
	    	oXmlExp := XmlParser(oRetorno:OWSNOTAS:OWSNFES3[nX]:OWSNFE:CXML,"","","")
			
			_ValCNPJ := _RetType("oXmlExp:_NFE:_INFNFE:_DEST:_CNPJ")
			_ValCPF  := _RetType("oXmlExp:_NFE:_INFNFE:_DEST:_CPF")
			
			If _ValCNPJ <> "U"
				cCNPJDEST := AllTrim(oXmlExp:_NFE:_INFNFE:_DEST:_CNPJ:TEXT)
			ElseIF _ValCPF <> "U"
				cCNPJDEST := AllTrim(oXmlExp:_NFE:_INFNFE:_DEST:_CPF:TEXT)
			Else
				cCNPJDEST := ""
			EndIf
			
			_ValTypeText := _RetType("oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT") 
			cVerNfe := IIf(_ValTypeText <> "U", oXmlExp:_NFE:_INFNFE:_VERSAO:TEXT, '')
			cPrefixo := "NFe"
			cChvNFe	:= NfeIdSPED(oXml:oWSNFe:cXML,"Id")
			
			if _wtipo = '4'
				_sNomeArq := cDestino+cChvNFe+"-"+cPrefixo+".xml"
			else
				_sNomeArq := cDestino+cChvNFe+"-"+cPrefixo+"INTPROTHEUS.xml"
			endif	
			nHandle := FCreate (_sNomeArq)
			
			If nHandle > 0
				cCab1 := '<?xml version="1.0" encoding="UTF-8"?>'
				cCab1 += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + cVerNfe + '">'
				cRodap := '</nfeProc>'
				FWrite(nHandle,AllTrim(cCab1))
	 			FWrite(nHandle,AllTrim(oXml:oWSNFe:cXML))
	 			FWrite(nHandle,AllTrim(oXml:oWSNFe:cXMLPROT))
				FWrite(nHandle,AllTrim(cRodap))
	 			FClose(nHandle)
				u_log2 ('info', 'Arq.gerado: ' + _sNomeArq)
	
				// Marca a nota como exportada.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "UPDATE " + RetSQLName ("SF2")
				_oSQL:_sQuery += " SET F2_EXML = 'S'"
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND F2_CHVNFE = '" + cChvNFe + "'"
				_oSQL:Exec ()
	 		EndIf
	 	Next
	EndIf	
Return
//
// --------------------------------------------------------------------------
// Retorno do type - type em looling nao é permitido da R25 
Static Function _RetType(_var)
	_type := type(_var)
Return _type