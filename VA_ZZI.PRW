// Programa:   VA_ZZI
// Autor:      Robert Koch
// Data:       06/11/2012
// Descricao:  Tela de manutencao de comprovacoes de leiloes CONAB.
// 
// Historico de alteracoes:
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 26/01/2016 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
//

// --------------------------------------------------------------------------
user function VA_ZZI ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Manutencao de previsoes de notas de compra de uva"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

   aAdd(aRotina, {"Pesquisar",      "AxPesqui", 0, 1})
   aAdd(aRotina, {"Visualizar",     "AxVisual", 0, 2})
   aAdd(aRotina, {"Incluir",        "AxInclui", 0, 3})
   aAdd(aRotina, {"Alterar",        "AxAltera", 0, 4})
   aAdd(aRotina, {"Excluir",        "AxDeleta", 0, 5})
   aAdd(aRotina, {"Procura pgtos",  "U_VA_ZZIP ()", 0, 5})
   aAdd(aRotina, {"Imprime DANFes", "U_VA_ZZID ()", 0, 5})

   dbSelectArea ("ZZI")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "ZZI",,,,, 2)
return



// --------------------------------------------------------------------------
user function VA_ZZIP (_sPacote)
	local _oSQL    := NIL
	local _aNotas  := {}
	local _nNota   := 0
	local _aPag    := {}
	local _nPag    := 0
	local _oPag    := NIL
	local _sAno    := ""
	local _nVlrNF  := 0
	local _aRet    := {}
	local _aRetNF  := {}
	local _nVlrCompr := 0
	private _sArqLog := iif (type ("_sArqLog") == "C", _sArqLog, U_NomeLog ())

	aadd (_aRet, {'Associado', 'Loja', 'Nome', 'NF Filial', 'NF Numero', 'NF Serie', 'NF Valor', 'Pgt.Filial', 'Pgt.banco', 'Pgt.data', 'Pgt.Valor'})

	_sAno    = zzi -> zzi_ano
	_sPacote = iif (_sPacote == NIL, zzi -> zzi_pacote, _sPacote)

	if ! msgyesno ("Esta rotina procura combinacoes de valores de notas X pagamentos. Deseja executa-la para o pacote " + _sPacote + "?")
		return
	endif

	CursorWait()

	zzi -> (dbsetorder (1))
	zzi -> (dbseek (xfilial ("ZZI") + _sAno + _sPacote, .T.))
	u_log ('pacote:', zzi -> zzi_pacote)
	do while ! zzi -> (eof ()) .and. zzi -> zzi_filial == xfilial ("ZZI") .and. zzi -> zzi_ano == _sAno .and. zzi -> zzi_pacote == _sPacote
//		if zzi -> zzi_assoc != '000160'
//			zzi -> (dbskip ())
//			loop
//		endif
		U_VA_ZZIP2 (zzi -> zzi_ano, zzi -> zzi_assoc, zzi -> zzi_loja, zzi -> zzi_filori, zzi -> zzi_doc, zzi -> zzi_serie, zzi -> zzi_pacote, .t.)

/*
		u_logIni ('Assoc: ' + zzi -> zzi_assoc + '/' + zzi -> zzi_loja + ' Fil/doc: ' + zzi -> zzi_filori + '/' + zzi -> zzi_doc)

		// Busca o valor da nota.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SUM (VALOR_TOTAL) "
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE V.SAFRA      = '2012'"
		_oSQL:_sQuery +=    " AND V.TIPO_NF    = 'C'"
		_oSQL:_sQuery +=    " AND V.ASSOCIADO  = '" + zzi -> zzi_assoc  + "'"
		_oSQL:_sQuery +=    " AND V.LOJA_ASSOC = '" + zzi -> zzi_loja   + "'"
		_oSQL:_sQuery +=    " AND V.FILIAL     = '" + zzi -> zzi_filori + "'"
		_oSQL:_sQuery +=    " AND V.DOC        = '" + zzi -> zzi_doc    + "'"
		_oSQL:_sQuery +=    " AND V.SERIE      = '" + zzi -> zzi_serie  + "'"
		_nVlrNF = _oSQL:RetQry ()
		//u_log (_nVlrNF)

		// Verifica se esta NF jah tem pagamento relacionado a ela.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SUM (ZZK_VALOR) "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZK") + " ZZK, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE ZZK.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_FILNF1 = '" + zzi -> zzi_filori + "'"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_DOC1   = '" + zzi -> zzi_doc    + "'"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_SERIE1 = '" + zzi -> zzi_serie  + "'"
		_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_ASSOC = SA2.A2_VACBASE"  // O pagamento foi digitado no cod/loja base
		_oSQL:_sQuery +=    " AND ZZK.ZZK_LOJA  = SA2.A2_VALBASE"
		_oSQL:_sQuery +=    " AND SA2.A2_COD    = '" + zzi -> zzi_assoc  + "'"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA   = '" + zzi -> zzi_loja   + "'"
		if _oSQL:RetQry () == _nVlrNF
			u_log ('Nota jah tem pagamentos relacionados.')
		else

			// Busca pagamentos disponiveis.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT '', ZZK_VALOR, ZZK_FILIAL, ZZK_BANCO, ZZK_DATA, ZZK.R_E_C_N_O_ "
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZK") + " ZZK, "
			_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
			_oSQL:_sQuery +=  " WHERE ZZK.D_E_L_E_T_  = ''"
	//		_oSQL:_sQuery +=    " AND ZZK.ZZK_VALOR  <= " + cvaltochar (_nVlrNF)
			_oSQL:_sQuery +=    " AND ZZK.ZZK_VALOR  <= " + cvaltochar (_nVlrNF) + " + 100"
			_oSQL:_sQuery +=    " AND ((ZZK.ZZK_FILNF1 = '" + zzi -> zzi_filori + "'"
			_oSQL:_sQuery +=    " AND   ZZK.ZZK_DOC1   = '" + zzi -> zzi_doc    + "'"
			_oSQL:_sQuery +=    " AND   ZZK.ZZK_SERIE1 = '" + zzi -> zzi_serie  + "')"
			_oSQL:_sQuery +=    "  OR  (ZZK.ZZK_FILNF1 = ''"
			_oSQL:_sQuery +=    " AND   ZZK.ZZK_DOC1   = ''"
			_oSQL:_sQuery +=    " AND   ZZK.ZZK_SERIE1 = ''))"
			_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_  = ''"
			_oSQL:_sQuery +=    " AND ZZK.ZZK_ASSOC = SA2.A2_VACBASE"  // O pagamento foi digitado no cod/loja base
			_oSQL:_sQuery +=    " AND ZZK.ZZK_LOJA  = SA2.A2_VALBASE"
			_oSQL:_sQuery +=    " AND SA2.A2_COD    = '" + zzi -> zzi_assoc  + "'"
			_oSQL:_sQuery +=    " AND SA2.A2_LOJA   = '" + zzi -> zzi_loja   + "'"
//			U_LOG (_oSQL:_sQuery)
			_oPag := ClsAUtil ():New ()
			_oPag:_aArray := aclone (_oSQL:Qry2Array (.f., .f.))
	
			// Tenta combinar valores dos pagamentos para fechar o valor da nota.
			if len (_oPag:_aArray) > 0
//				_aPag = aclone (_oPag:CombinaVlr (2, _nVlrNF, 0, .01))
				_aPag = aclone (_oPag:CombinaVlr (2, _nVlrNF, 100, .02))
				if len (_aPag) > 0
					for _nPag = 1 to len (_aPag)
						_oPag:_aArray [_aPag [_nPag], 1] = 'USAR ESTE'
						zzk -> (dbgoto (_oPag:_aArray [_aPag [_nPag], 6]))
						reclock ("ZZK", .F.)
						zzk -> zzk_pacote = zzi -> zzi_pacote
						zzk -> zzk_filnf1 = zzi -> zzi_filori
						zzk -> zzk_doc1   = zzi -> zzi_doc
						zzk -> zzk_serie1 = zzi -> zzi_serie
						msunlock ()
					next
				endif
				if len (_aPag) > 1
					U_LOG ('USEI MAIS QUE 1 para encontrar o valor de ' + cvaltochar (_nVlrNF) + ':', _oPag:_aArray)
				ENDIF
			endif
	
			u_log (_oPag:_aArray)
	
			// Prepara array com dados desta NF para exportacao para planilha.
			_aRetNF = {}
			aadd (_aRetNF, afill (array (11), ''))
			//
			// Dados da(s) nota(s)
			_aRetNF [1, 1] = zzi -> zzi_assoc
			_aRetNF [1, 2] = zzi -> zzi_loja
			_aRetNF [1, 3] = alltrim (fbuscacpo ("SA2", 1, xfilial ("SA2") + zzi -> zzi_assoc + zzi -> zzi_loja, "A2_NOME"))
			_aRetNF [1, 4] = zzi -> zzi_filori
			_aRetNF [1, 5] = zzi -> zzi_doc
			_aRetNF [1, 6] = zzi -> zzi_serie
			_aRetNF [1, 7] = _nVlrNF
			//
			// Dados do(s) pagamento(s)
	//		u_log ('vou percorrer:', _oPag:_aArray)
			_nContaPag = 0
			_nVlrCompr = 0
			for _nPag = 1 to len (_oPag:_aArray)
				if _oPag:_aArray [_nPag, 1] == 'USAR ESTE'
					u_log ('_nPag=', _nPag)
					_nContaPag ++
					_nVlrCompr += _oPag:_aArray [_nPag, 2]
					if _nContaPag > len (_aRetNF)
						aadd (_aRetNF, afill (array (11), ''))
	//					u_log ('adicionei linha em _aRetNF e ficou assim:', _aRetNF)
					endif
					_aRetNF [_nContaPag, 8]  = _oPag:_aArray [_nPag, 3]
					_aRetNF [_nContaPag, 9]  = _oPag:_aArray [_nPag, 4]
					_aRetNF [_nContaPag, 10] = stod (_oPag:_aArray [_nPag, 5])
					_aRetNF [_nContaPag, 11] = _oPag:_aArray [_nPag, 2]
				endif
			next
			// Gera uma linha em branco na planilha.
	  		aadd (_aRetNF, afill (array (11), ''))
	//		u_log ('Dados desta NF para retorno:', _aRetNF)
			
			for _nPag = 1 to len (_aRetNF)
				aadd (_aRet, aclone (_aRetNF [_nPag]))
			next
			
			if _nVlrCompr > _nVlrNF
				u_log ('Comprovado com valor maior de', _nVlrCompr - _nVlrNF)
			endif
		endif
		u_logFim ('Assoc: ' + zzi -> zzi_assoc + '/' + zzi -> zzi_loja + ' Fil/doc: ' + zzi -> zzi_filori + '/' + zzi -> zzi_doc)
*/
		zzi -> (dbskip ())
	enddo
	u_log (_aRet)
	//U_AcolsXLS (_aRet, .F.)
	CursorArrow()
return



// --------------------------------------------------------------------------
user function VA_ZZIP2 (_sAno, _sAssoc, _sLoja, _sFilOri, _sDoc, _sSerie, _sPacote, _lGrvZZK)
	local _oSQL      := NIL
	local _aPag      := {}
	local _nPag      := 0
	local _oPag      := NIL
	local _nVlrNF    := 0
	local _nVlrCompr := 0
	private _sArqLog := iif (type ("_sArqLog") == "C", _sArqLog, U_NomeLog ())

	u_logIni ('Ano: ' + _sAno + ' Assoc: ' + _sAssoc + '/' + _sLoja + ' Fil/doc: ' + _sFilOri + '/' + _sDoc + '/' + _sSerie)

	// Busca o valor da nota.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM (VALOR_TOTAL) "
	_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
	_oSQL:_sQuery +=  " WHERE V.SAFRA      = '2012'"
	_oSQL:_sQuery +=    " AND V.TIPO_NF    = 'C'"
	_oSQL:_sQuery +=    " AND V.ASSOCIADO  = '" + _sAssoc  + "'"
	_oSQL:_sQuery +=    " AND V.LOJA_ASSOC = '" + _sLoja   + "'"
	_oSQL:_sQuery +=    " AND V.FILIAL     = '" + _sFilOri + "'"
	_oSQL:_sQuery +=    " AND V.DOC        = '" + _sDoc    + "'"
	_oSQL:_sQuery +=    " AND V.SERIE      = '" + _sSerie  + "'"
	_nVlrNF = _oSQL:RetQry ()
	//u_log (_nVlrNF)

	// Verifica se esta NF jah tem pagamento relacionado a ela.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SUM (ZZK_VALOR) "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZK") + " ZZK, "
	_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=  " WHERE ZZK.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=    " AND ZZK.ZZK_FILNF1 = '" + _sFilOri + "'"
	_oSQL:_sQuery +=    " AND ZZK.ZZK_DOC1   = '" + _sDoc    + "'"
	_oSQL:_sQuery +=    " AND ZZK.ZZK_SERIE1 = '" + _sSerie  + "'"
	_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=    " AND ZZK.ZZK_ASSOC = SA2.A2_VACBASE"  // O pagamento foi digitado no cod/loja base
	_oSQL:_sQuery +=    " AND ZZK.ZZK_LOJA  = SA2.A2_VALBASE"
	_oSQL:_sQuery +=    " AND SA2.A2_COD    = '" + _sAssoc  + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA   = '" + _sLoja   + "'"
	if _oSQL:RetQry () == _nVlrNF
		u_log ('Nota jah tem pagamentos relacionados.')
	else

		// Busca pagamentos disponiveis.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT '', ZZK_VALOR, ZZK_FILIAL, ZZK_BANCO, ZZK_DATA, ZZK.R_E_C_N_O_ "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZK") + " ZZK, "
		_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=  " WHERE ZZK.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_VALOR  <= " + cvaltochar (_nVlrNF) + " + 100"
		_oSQL:_sQuery +=    " AND ((ZZK.ZZK_FILNF1 = '" + _sFilOri + "'"
		_oSQL:_sQuery +=    " AND   ZZK.ZZK_DOC1   = '" + _sDoc    + "'"
		_oSQL:_sQuery +=    " AND   ZZK.ZZK_SERIE1 = '" + _sSerie  + "')"
		_oSQL:_sQuery +=    "  OR  (ZZK.ZZK_FILNF1 = ''"
		_oSQL:_sQuery +=    " AND   ZZK.ZZK_DOC1   = ''"
		_oSQL:_sQuery +=    " AND   ZZK.ZZK_SERIE1 = ''))"
		_oSQL:_sQuery +=    " AND SA2.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=    " AND ZZK.ZZK_ASSOC = SA2.A2_VACBASE"  // O pagamento foi digitado no cod/loja base
		_oSQL:_sQuery +=    " AND ZZK.ZZK_LOJA  = SA2.A2_VALBASE"
		_oSQL:_sQuery +=    " AND SA2.A2_COD    = '" + _sAssoc  + "'"
		_oSQL:_sQuery +=    " AND SA2.A2_LOJA   = '" + _sLoja   + "'"
//		U_LOG (_oSQL:_sQuery)
		_oPag := ClsAUtil ():New ()
		_oPag:_aArray := aclone (_oSQL:Qry2Array (.f., .f.))

		// Tenta combinar valores dos pagamentos para fechar o valor da nota.
		if len (_oPag:_aArray) > 0
			_aPag = aclone (_oPag:CombinaVlr (2, _nVlrNF, 100, .02))
			if len (_aPag) > 0
				for _nPag = 1 to len (_aPag)
					_oPag:_aArray [_aPag [_nPag], 1] = 'USAR ESTE'  // Apenas para mostrar no log.
					_nVlrCompr += _oPag:_aArray [_aPag [_nPag], 2]
					if _lGrvZZK
						zzk -> (dbgoto (_oPag:_aArray [_aPag [_nPag], 6]))
						reclock ("ZZK", .F.)
						zzk -> zzk_pacote = _sPacote
						zzk -> zzk_filnf1 = _sFilOri
						zzk -> zzk_doc1   = _sDoc
						zzk -> zzk_serie1 = _sSerie
						msunlock ()
						U_LOG ('gravei ZZK pacote:', zzk -> zzk_pacote, ' doc:', zzk -> zzk_doc1)
					endif
				next
			endif
			if len (_aPag) > 1
				U_LOG ('USEI MAIS QUE 1 para encontrar o valor de ' + cvaltochar (_nVlrNF) + ':', _oPag:_aArray)
			ENDIF
		endif
		u_log (_oPag:_aArray)
		if _nVlrCompr > _nVlrNF
			u_log ('Comprovado com valor maior de', _nVlrCompr - _nVlrNF)
		endif
	endif
	u_log ('retornando',_nVlrCompr)
	u_logFim ('Ano: ' + _sAno + ' Assoc: ' + _sAssoc + '/' + _sLoja + ' Fil/doc: ' + _sFilOri + '/' + _sDoc + '/' + _sSerie)
return _nVlrCompr



// --------------------------------------------------------------------------
user function VA_ZZID ()
	local _oSQL    := NIL
	local _aNotas  := {}
	local _nNota   := 0

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT ZZI_DOC, ZZI_SERIE "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZI") + " ZZI "
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZZI_ANO    = '" + zzi -> zzi_ano  + "'"
	_oSQL:_sQuery +=    " AND ZZI_PACOTE = '" + zzi -> zzi_pacote   + "'"
	_oSQL:_sQuery +=    " AND ZZI_FILORI = '" + cFilAnt + "'"
	_oSQL:_sQuery +=  " ORDER BY ZZI_DOC"
	_aNotas := aclone (_oSQL:Qry2Array (.f., .f.))

	for _nNota = 1 to len (_aNotas)
		U_ImpDanfe ('E', _aNotas [_nNota, 1], _aNotas [_nNota, 1], _aNotas [_nNota, 2])
	next
return
