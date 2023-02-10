// Programa.:  F70GRSE1
// Autor....:  Cláudia Lionço
// Data.....:  07/10/2020
// Descricao:  P.E. após a baixa do título a receber. Neste momento o SE1 
//             está posicionado e recebe como primeiro parâmetro o código da ocorrência,
//             caso, seja uma baixa proveniente do CNAB.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. após a baixa do título a receber
// #PalavasChave      #baixa_de_titulos #contas_a_receber #P.E.
// #TabelasPrincipais #SE5 #ZA5 #ZA4
// #Modulos           #FIN 
//
// Historico de alteracoes:
// 07/10/2020 - Cláudia - P.E. gerado a partir do P.E. F070ACont
// 05/04/2021 - Robert  - Tratamento do SE5 eh especifico para verbas de clientes 
//                        (desabilitado quando cupons das lojas). GLPI 9573.
// 07/04/2021 - Sandra  - Tratamento do SE5 eh especifico para verbas de clientes 
//                        (habilitado quando cupons das lojas)
// 24/05/2022 - Claudia - Incluido a gravação do rapel. GLPI: 8916
// 28/09/2022 - Claudia - Incluida validação de saldo da verba na gravação da baixa ZA5. GLPI: 12654
// 07/10/2022 - Claudia - Atualização de rapel apenas para serie 10. GLPI: 8916
// 10/02/2023 - CLaudia - Ajustada a baixa de rapel. GLPI: 13176
//
// ---------------------------------------------------------------------------------------------------
User Function F70GRSE1()
	local _aAreaAnt := U_ML_SRArea ()
	u_logIni ()

	// Atualiza campos de descontos no SE5, e tambem verbas 
	// (nos casos de clientes que cobram as verbas em forma de desconto nos titulos de nossas NF de venda).
	_AtuSE5 ()
	
	// Clientes que nao fazem desconto em nota fiscal (emitem boleto ou exigem deposito na conta deles) sao controlados via NCC
	if se1 -> e1_tipo = "NCC" .and. se1 -> e1_naturez = "VERBAS" .and. se1 -> e1_prefixo = "CV"  
		_AtuZA5()
	endif

	// Grava rapel
	if GetMV('VA_RAPEL')
		_AtuZC0()
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Atualiza campos do SE5 ref. desmembramento do desconto.
Static Function _AtuSE5 ()
	local _oSQL    := ClsSQL():New ()
	local _sSeqSE5 := ""
	local i        := 0
	
	// Busca a maior sequencia no SE5 (obrigatoriamente vai ser esta que acabou de gerar)
	_oSQL:_sQuery  = ""
	_oSQL:_sQuery += " SELECT TOP 1 E5_SEQ"
	_oSQL:_sQuery += "   FROM "+ RetSQLName ("SE5")
	_oSQL:_sQuery += "  WHERE D_E_L_E_T_  = ''"
	_oSQL:_sQuery += "    AND E5_FILIAL   = '" + xfilial ("SE5") + "'"
	_oSQL:_sQuery += "    AND E5_NUMERO   = '" + se1 -> e1_num + "'"
	_oSQL:_sQuery += "    AND E5_PREFIXO  = '" + se1 -> e1_prefixo + "'"
	_oSQL:_sQuery += "    AND E5_PARCELA  = '" + se1 -> e1_parcela + "'"
	_oSQL:_sQuery += "    AND E5_CLIFOR   = '" + se1 -> e1_cliente + "'"
	_oSQL:_sQuery += "    AND E5_LOJA     = '" + se1 -> e1_loja    + "'"
	_oSQL:_sQuery += "  ORDER BY E5_SEQ DESC"
	_oSQL:Log ()
	_sSeqSE5 = _oSQL:RetQry (1, .F.)
	U_log ('seqSE5:', _sSeqSE5)
	
	// Se tem SE5 gerado (quando baixa NCC, por exemplo, ele nao gera)
	if ! empty (_sSeqSE5)	
		// Prepara comando para atualizar SE5
		_oSQL:_sQuery  = ""
		_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE5")
		_oSQL:_sQuery +=    " SET E5_VAUSER  = '"+ left(cUserName,tamSX3('E5_VAUSER')[1]) + "'"
		_oSQL:_sQuery +=        ",E5_VARAPEL = " + iif (type ("_E5VARapel") == "N", cValToChar (_E5VARApel), '0')
		_oSQL:_sQuery +=        ",E5_VAENCAR = " + iif (type ("_E5VAEncar") == "N", cValToChar (_E5VAEncar), '0')
		_oSQL:_sQuery +=        ",E5_VAFEIRA = " + iif (type ("_E5VAFeira") == "N", cValToChar (_E5VAFeira), '0')
		_oSQL:_sQuery +=        ",E5_VADOUTR = " + iif (type ("_E5VADOutr") == "N", cValToChar (_E5VADOutr), '0')
		_oSQL:_sQuery +=        ",E5_VADFRET = " + iif (type ("_E5VADFret") == "N", cValToChar (_E5VADFret), '0')
		_oSQL:_sQuery +=        ",E5_VADDESC = " + iif (type ("_E5VADDesc") == "N", cValToChar (_E5VADDesc), '0')
		_oSQL:_sQuery +=        ",E5_VADDEVO = " + iif (type ("_E5VADDevo") == "N", cValToChar (_E5VADDevo), '0')
		_oSQL:_sQuery +=        ",E5_VADCMPV = " + iif (type ("_E5VADCmpV") == "N", cValToChar (_E5VADCmpV), '0')
		_oSQL:_sQuery +=        ",E5_VADAREI = " + iif (type ("_E5VADARei") == "N", cValToChar (_E5VADARei), '0')
		_oSQL:_sQuery +=        ",E5_VADMULC = " + iif (type ("_E5VADMulC") == "N", cValToChar (_E5VADMulC), '0')
		_oSQL:_sQuery +=  " Where D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " And E5_FILIAL  = '" + xfilial ("SE5") + "'"
		_oSQL:_sQuery +=    " And E5_NUMERO  = '" + se1 -> e1_num + "'"
		_oSQL:_sQuery +=    " And E5_PREFIXO = '" + se1 -> e1_prefixo + "'"
		_oSQL:_sQuery +=    " And E5_PARCELA = '" + se1 -> e1_parcela + "'"
		_oSQL:_sQuery +=    " And E5_CLIFOR  = '" + se1 -> e1_cliente + "'"
		_oSQL:_sQuery +=    " And E5_LOJA    = '" + se1 -> e1_loja    + "'"
		_oSQL:_sQuery +=    " And E5_SEQ     = '" + _sSeqSE5 + "'"
		_oSQL:_sQuery +=    " And E5_SITUACA != 'C'"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ("Erro no SQL de gravacao da composicao de desconto.")
		endif
	else
		u_log ("Nao tem SE5 gravado para esta movimentacao.")
	endif				
		
	_wmatriz = fBuscaCpo ('SA1', 1, xfilial('SA1') + se1 -> e1_cliente + se1 -> e1_loja, "A1_VACBASE")
	_wverbas = fBuscaCpo ('SA1', 1, xfilial('SA1') + _wmatriz + '01', "A1_VERBA")
	
	if _wverbas = '1' 
		
		// Faz em loop para processar todos os tipos de verbas.
		_TPE5VerEncar := type ("_E5VerEncar") 
		_TPE5VAEncar  := type ("_E5VAEncar")
		_TPE5VerFeira := type ("_E5VerFeira")
		_TPE5VAFeira  := type ("_E5VAFeira") 
		_TPE5VerFret  := type ("_E5VerFret")
		_TPE5VADFret  := type ("_E5VADFret") 
		_TPE5VerCmpV  := type ("_E5VerCmpV")
		_TPE5VADCmpV  := type ("_E5VADCmpV")
		_TPE5VerARei  := type ("_E5VerARei")
		_TPE5VADARei  := type ("_E5VADARei")
		_TPE5VerMulC  := type ("_E5VerMulC")
		_TPE5VADMulC  := type ("_E5VADMulC")
		
		for i=1 to 6
			do case 
				case i=1
					_wnumverba = iif (_TPE5VerEncar == "C", _E5VerEncar, '')
					_wvalor    = iif (_TPE5VAEncar  == "N", _E5VAEncar, 0)
				case i=2
					_wnumverba = iif (_TPE5VerFeira == "C", _E5VerFeira, '')
					_wvalor    = iif (_TPE5VAFeira  == "N", _E5VAFeira, 0)
				case i=3					
					_wnumverba = iif (_TPE5VerFret  == "C", _E5VerFret, '')
					_wvalor    = iif (_TPE5VADFret  == "N", _E5VADFret, 0)
				case i=4					
					_wnumverba = iif (_TPE5VerCmpV  == "C", _E5VerCmpV, '')
					_wvalor    = iif (_TPE5VADCmpV  == "N", _E5VADCmpV, 0)
				case i=5					
					_wnumverba = iif (_TPE5VerARei  == "C", _E5VerARei, '')
					_wvalor    = iif (_TPE5VADARei  == "N", _E5VADARei, 0)
				case i=6					
					_wnumverba = iif (_TPE5VerMulC  == "C", _E5VerMulC, '')
					_wvalor    = iif (_TPE5VADMulC  == "N", _E5VADMulC, 0)
			endcase		

			if !empty(@(_wnumverba))
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT MAX(ZA5.ZA5_SEQ)"
				_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA5") + " AS ZA5 "
				_oSQL:_sQuery += "   WHERE D_E_L_E_T_     = ''"
				_oSQL:_sQuery += "     AND ZA5.ZA5_FILIAL = '" + xfilial ("ZA5") + "'"
				_oSQL:_sQuery += "     AND ZA5.ZA5_NUM    = '" + @(_wnumverba) + "'"
				_oSQL:Log ()
				_aDados := _oSQL:Qry2Array ()
				_wseq := 0
				if len(_aDados) > 0
					_wseq = _aDados[1,1]
				endif

				// Verifica saldo da verba para baixa (casos de baixas duplicadas)
				_lContinua := _SaldoZA5(@(_wnumverba) ,  @(_wvalor))

				If _lContinua
					// grava tabela ZA5
					RecLock("ZA5",.T.)
						za5 -> za5_num     = @(_wnumverba)
						za5 -> za5_seq     = _wseq+1
						za5 -> za5_vlr     = @(_wvalor)
						za5 -> za5_prefix  = se1 -> e1_prefixo
						za5 -> za5_doc     = se1 -> e1_num
						za5 -> za5_parc    = se1 -> e1_parcela
						za5 -> za5_tipo    = se1 -> e1_tipo
						za5 -> za5_cli	   = se1 -> e1_cliente
						za5 -> za5_loja    = se1 -> e1_loja
						za5 -> za5_tlib    = fBuscaCpo ('ZA4', 1, xfilial('ZA4') + @(_wnumverba), "ZA4_TLIB")
						za5 -> za5_usu     = alltrim (cUserName)
						za5 -> za5_dta     = ddatabase
						za5 -> za5_filial  = xFilial("ZA5")
						za5 -> za5_seqSE5  = _sSeqSE5
						za5 -> za5_venver  = fBuscaCpo ('ZA4', 1, xfilial('ZA4') + @(_wnumverba), "ZA4_VEND")
						za5 -> za5_vennf   = se1 -> e1_vend1
					MsUnLock()
					
					// Atualiza status de utilizacao da verba.
					U_AtuZA4 (_wnumverba)
					
				else
					u_log(" Verba " + se1 -> e1_num + " sem saldo para baixa!")
				EndIf

			endif
		next
	endif

	// Zera variaveis para que nao sejam acumuladas ao proximo titulo, pois sao publicas.
	_E5VARApel = 0
	_E5VAEncar = 0
	_E5VAFeira = 0
	_E5VADFret = 0
	_E5VADDesc = 0
	_E5VADDevo = 0
	_E5VADCmpV = 0
	_E5VADARei = 0
	_E5VADMulC = 0
	_E5VADOutr = 0
	_E5VerEncar = "      "
	_E5VerFeira = "      "
	_E5VerFret  = "      "
	_E5VerCmpV  = "      "
	_E5VerARei  = "      "
	_E5VerMulC  = "      "
	u_logFim ()
Return
//
// -------------------------------------------------
// Atualiza campos do ZA5 e ZA4 - Controle de Verbas
Static Function _AtuZA5 ()
	local _oSQL := ClsSQL():New ()
	
	u_logIni ()
	
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT MAX(ZA5.ZA5_SEQ)"
	_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA5") + " AS ZA5 "
	_oSQL:_sQuery += "   WHERE D_E_L_E_T_     = ''"
	_oSQL:_sQuery += "     AND ZA5.ZA5_FILIAL = '" + xfilial ("ZA5") + "'"
	_oSQL:_sQuery += "     AND ZA5.ZA5_NUM    = '" + se1 -> e1_num + "'"
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array () //U_Qry2Array(_sQuery)
	_wseq := 0
	
	if len(_aDados) > 0
		_wseq = _aDados[1,1]
	endif	
			
	// Verifica saldo da verba para baixa (casos de baixas duplicadas)
	_lContinua := _SaldoZA5(se1 -> e1_num, se1 -> e1_valor)

	If _lContinua
		// grava tabela ZA5
		RecLock("ZA5",.T.)
			za5 -> za5_num     = se1 -> e1_num  // a verba tem o mesmo nro da NCC
			za5 -> za5_seq     = _wseq+1
			za5 -> za5_vlr     = se1 -> e1_valor
			za5 -> za5_prefix  = se1 -> e1_prefixo
			za5 -> za5_doc     = se1 -> e1_num
			za5 -> za5_parc    = se1 -> e1_parcela
			za5 -> za5_tipo    = se1 -> e1_tipo
			za5 -> za5_cli	   = se1 -> e1_cliente
			za5 -> za5_loja    = se1 -> e1_loja
			za5 -> za5_tlib    = fBuscaCpo ('ZA4', 1, xfilial('ZA4') + se1 -> e1_num, "ZA4_TLIB")
			za5 -> za5_usu     = alltrim (cUserName)
			za5 -> za5_dta     = ddatabase
			za5 -> za5_filial  = xFilial("ZA5") 
			za5 -> za5_venver  = fBuscaCpo ('ZA4', 1, xfilial('ZA4') + se1 -> e1_num, "ZA4_VEND")
			za5 -> za5_vennf   = se1 -> e1_vend1
		MsUnLock()

		// grava status de utilizacao
		DbSelectArea("ZA4")
		DbSetOrder(1)
		DbSeek(xFilial("ZA4") + se1 -> e1_num,.F.)

		RecLock("ZA4",.F.)
			za4 -> za4_sutl = '2'
		MsUnLock()
	else
		u_log(" Verba " + se1 -> e1_num + " sem saldo para baixa!")
	EndIf

	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Grava Rapel
Static Function _AtuZC0()
	local _oSQL    := ClsSQL():New ()

	If alltrim(se1 -> e1_prefixo) == '10'
		_oSQL:_sQuery  = ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		E5_VARAPEL "
		_oSQL:_sQuery += " FROM "+ RetSQLName ("SE5")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND E5_FILIAL   = '" + xfilial ("SE5")   + "'"
		_oSQL:_sQuery += " AND E5_NUMERO   = '" + se1 -> e1_num     + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + se1 -> e1_prefixo + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + se1 -> e1_parcela + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + se1 -> e1_cliente + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + se1 -> e1_loja    + "'"
		_oSQL:_sQuery += " AND E5_RECPAG   = 'R' "
		_oSQL:_sQuery += " AND E5_TIPODOC  = 'DC'"
		_oSQL:_sQuery += " AND E5_SITUACA  = '' "
		_oSQL:_sQuery += " AND E5_VARAPEL  > 0 "
		_oSQL:_sQuery += " AND E5_DATA     = '" + dtos(ddatabase)+"'"
		_oSQL:Log ()
		_aRapel := aclone (_oSQL:Qry2Array ())

		If Len(_aRapel) > 0
			_oCtaRapel := ClsCtaRap():New ()
			_sRede := _oCtaRapel:RetCodRede(se1->e1_cliente, se1->e1_loja)

			_oCtaRapel:Filial  	 = se1->e1_filial
			_oCtaRapel:Rede      = _sRede	
			_oCtaRapel:LojaRed   = se1->e1_loja
			_oCtaRapel:Cliente 	 = se1->e1_cliente
			_oCtaRapel:LojaCli	 = se1->e1_loja
			_oCtaRapel:TM      	 = '04' 	
			_oCtaRapel:Data    	 = ddatabase// date()
			_oCtaRapel:Hora    	 = time()
			_oCtaRapel:Usuario 	 = cusername 
			_oCtaRapel:Histor  	 = 'Rapel por baixa de titulo' 
			_oCtaRapel:Documento = se1->e1_num
			_oCtaRapel:Serie 	 = se1->e1_prefixo
			_oCtaRapel:Parcela	 = se1->e1_parcela
			_oCtaRapel:Rapel	 = _aRapel[1,1]
			_oCtaRapel:Origem	 = 'F70GRSE1'
			_oCtaRapel:NfEmissao = se1->e1_emissao

			If _oCtaRapel:Grava (.F.)
				_oEvento := ClsEvent():New ()
				_oEvento:Alias     = 'ZC0'
				_oEvento:Texto     = "Baixa rapel "+ se1->e1_parcela + se1->e1_num + "/" + se1->e1_prefixo
				_oEvento:CodEven   = 'ZC0001'
				_oEvento:Cliente   = se1->e1_cliente
				_oEvento:LojaCli   = se1->e1_loja
				_oEvento:NFSaida   = se1->e1_num
				_oEvento:SerieSaid = se1->e1_prefixo
				_oEvento:Grava()
			EndIf
		EndIf
	EndIf
Return
//
// -------------------------------------------------
// Verifica saldo para baixa
Static Function _SaldoZA5(_sVerba, _nValor)
	Local _lRet      := .T.
	Local _nVlrBaixa := 0
	Local _nVlrVerba := 0
	Local _x         := 0
	Local _y         := 0
	Local _nBxTotal  := 0
	local _oSQL      := ClsSQL():New ()

	// Busca total já baixado
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM(ZA5.ZA5_VLR)"
	_oSQL:_sQuery += "   	FROM " + RetSQLName ("ZA5") + " AS ZA5 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " AND ZA5.ZA5_NUM    = '" + _sVerba  + "'"
	_oSQL:Log ()
	_aBaixado := _oSQL:Qry2Array ()

	For _x := 1 to Len(_aBaixado)
		_nVlrBaixa += _aBaixado[_x,1]
	Next
	_nBxTotal :=  _nVlrBaixa + _nValor // baixa mais valor que pretende baixar

	// Busca total da verba já baixado
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM(ZA4.ZA4_VLR)"
	_oSQL:_sQuery += "   	FROM " + RetSQLName ("ZA4") + " AS ZA4 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " AND ZA4.ZA4_NUM    = '" + _sVerba  + "'"
	_oSQL:Log ()
	_aVerba := _oSQL:Qry2Array ()

	For _y :=1 to Len(_aVerba)
		_nVlrVerba += _aVerba[_y,1]
	Next 

	If _nVlrBaixa >= _nVlrVerba // se a baixa esta maior ou igual ao valor da verba, nao permite baixa
		_lRet := .F.
	EndIf
	If _nBxTotal > _nVlrVerba // se baixa + valor que pretende baixar ficar maior que o valor da verba, nao permite a baixa
		_lRet := .F.
	EndIf
Return _lRet
