// Programa:  VA_AdSaf
// Autor:     Robert Koch
// Data:      27/03/2020
// Descricao: Gera adiantamento de safra para associados.
//
// Historico de alteracoes:
// 29/04/2020 - Robert - Passa a gerar com base no ZZ9
//                     - Melhorias para gerar parcelas posteriores a primeira.
// 28/05/2020 - Robert - Geracao terceira parcela 2020
// 03/06/2020 - Robert - Estava gravando TM=07. Alterado para 31.
// 12/02/2021 - Robert - Novos parametros metodo ClsAssoc:FechSafra() - GLPI 9318
// 15/02/2021 - Robert - Mais parametros metodo ClsAssoc:FechSafra() - GLPI 9318
//

// --------------------------------------------------------------------------
User Function VA_AdSaf (_lAuto)
	Local cCadastro  := "Geracao adto. pagto. safra"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.

	u_logID ()
	Private cPerg   := "VA_ADSAF"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"  Este programa tem como objetivo gerar titulos PA para adiantamento")
		AADD(aSays,"  de pagamento de safra para associados. Usado para adiantar valores")
		AADD(aSays,"  enquanto nao eh gerada nota de compra.")
		AADD(aSays,"  Baseia-se nas pre-notas de compra (arquivo ZZ9).")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return



// --------------------------------------------------------------------------
Static Function _TudoOk ()
	Local _aArea    := GetArea()
	Local _lRet     := .T.

	if mv_par07 < dDataBase
		u_help ("Data para pagamento nao pode ser retroativa.")
		_lRet = .F.
	endif

	RestArea(_aArea)
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _aFornec   := {}
	local _nFornec   := 0
	local _oAssoc    := NIL
	local _sTMNao    := ''
	local _aSaldos   := {}
	local _nIdxSaldo := 0
	local _nSldDeb   := 0
	local _sEhAssoc  := .F.
	local _cPerg     := ''
	local _aBkpSX1   := {}
	local _aAdtos    := {}
	local _sSafra    := mv_par05  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _dDtPagto  := mv_par07  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _sBcoPag   := mv_par08  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _sAgePag   := mv_par09  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _sCtaPag   := mv_par10  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _nParcSaf  := mv_par11  // Guarda em variavel local por que a chamada de rotinas automaticas muda o conteudo da variavel.
	local _nParcAnt  := 0
	local _nIdxAdto  := 0
	local _oCtaCorr  := NIL
	local _sOrigSZI  := 'VA_ADSAF'
	local _sParcela  := space (TamSX3 ("E2_PARCELA")[1])
	local _aRetParc  := {}
	local _aAutoSE2  := {}
	local _sPrefSE2  := 'ADT'
	local _sTitSE2   := ''
	local _sDescParc := ''
	local _nRegraPag := 0
	local _aPerGrpA  := {}
	local _aPerGrpB  := {}
	local _aPerGrpC  := {}
	local _nPercParc := 0
	local _nTotParc  := 0
	local _sAliasQ   := ''
	local _sFornec   := ''
	local _sLojaFor  := ''
	local _nVlrAntA  := 0
	local _nVlrAntB  := 0
	local _nVlrAntC  := 0
	local _nVlrGrpA  := 0
	local _nVlrGrpB  := 0
	local _nVlrGrpC  := 0
	local _nAcumParc := 0
	local _nAdtPAnt  := 0
	local _nAj2020P1 := 0
	local _sHistCalc := ''
	local _nPagar    := 0
	local _sError    := ''
	local _sWarning  := ''
	local _sXmlFech  := ''
	private _oXMLFech := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.
	private aHeader   := {}

	U_LogSX1 (cPerg)

	// Monta lista de tipos de movimento que nao devem ser considerados no momento de ler
	// os saldos em aberto na conta corrente:
	// - Movtos. a credito. Quero apenas 'nao pagar mais do que devo referente a safra'. Nao importa se devo outras coisas.
	// - Movtos. envolvendo cota capital.
	// - TM=31 (pagtos. de parcelas anteriores desta safra via PA): Como vou calcular pela 'safra cheia ate o momento', esses
	//   adtos.de parcelas seriam considerados como emprestimos ao associado, pois estarao ainda em aberto.
	// - TM=13 (notas de compra desta safra ja geradas): mesma situacao do movimento 31 acima.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT STRING_AGG (ZX5_10COD, '/')"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZX5")"
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5_TABELA = '10'"
		_oSQL:_sQuery +=    " AND (ZX5_10DC  != 'D' OR ZX5_10CAPI = 'S')"
	//	_oSQL:Log ()
		_sTMNao = alltrim (_oSQL:RetQry ())
		_sTMNao += '/31/13'
		u_log ('TM a ignorar na leitura de saldos:', _sTMNao)
	endif

	// Busca forma de pagamento no metodo 'dados do fechamento de safra' para ficar igual ao APP associados.
	if _lContinua
		_sDescParc = ''

		// Instancia um associado generico para buscar os percentuais de pagamento desta parcela.
		_oAssoc := ClsAssoc ():New ('000161', '01')

		//                              _sSafra, _lFSNFE, _lFSNFC, _lFSNFV, _lFSNFP, _lFSPrPg, _lFSRgPg, _lFSVlEf, _lFSResV, _lFSFrtS, _lFSLcCC
		_sXmlFech = _oAssoc:FechSafra (mv_par05, .t.,     .t.,     .t.,     .t.,     .t.,      .t.,      .t.,      .t.,      .t.,      .t.)
		u_log (_sXmlFech)
		if empty (_sXmlFech)
			u_help ("Erro ao ler formas de pagamento para esta safra.",, .t.)
			_lContinua = .F.
		else
			// Converte de texto para XML
			_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
			if ! empty (_sError) .or. ! empty (_sWarning)
				u_help ("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
				_lContinua = .F.
			else
				// Extrai as diferentes composicoes de parcelamento.
				// Vai precisar manutencao se tivermos mais grupos para pagamento, ou mais parcelas.
				for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
					if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'A'
						_sDescParc += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT + chr (13) + chr (10)
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT))
						aadd (_aPerGrpA, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT))
					endif
					if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'B'
						_sDescParc += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT + chr (13) + chr (10)
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT))
						aadd (_aPerGrpB, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT))
					endif
					if _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_grupo:TEXT == 'C'
						_sDescParc += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT + chr (13) + chr (10)
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc01:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc02:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc03:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc04:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc05:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc06:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc07:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc08:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc09:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc10:TEXT))
						aadd (_aPerGrpC, val (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_perc11:TEXT))
					endif
				next

				u_log (_aPerGrpA)
				u_log (_aPerGrpB)
				u_log (_aPerGrpC)

				// Conferencia basica dos percentuais das parcelas...
				_nTotParc = 0
				for _nPercParc = 1 to len (_aPerGrpA)
					_nTotParc += _aPerGrpA [_nPercParc]
				next
				if _nTotParc != 100
					u_help ("A soma dos percentuais das parcelas do grupo A deveria fechar em 100%, mas fechou em " + cValToChar (_nTotParc),, .t.)
					_lContinua = .F.
				endif

				_nTotParc = 0
				for _nPercParc = 1 to len (_aPerGrpB)
					_nTotParc += _aPerGrpB [_nPercParc]
				next
				if _nTotParc != 100
					u_help ("A soma dos percentuais das parcelas do grupo B deveria fechar em 100%, mas fechou em " + cValToChar (_nTotParc),, .t.)
					_lContinua = .F.
				endif

				_nTotParc = 0
				for _nPercParc = 1 to len (_aPerGrpC)
					_nTotParc += _aPerGrpC [_nPercParc]
				next
				if _nTotParc != 100
					u_help ("A soma dos percentuais das parcelas do grupo C deveria fechar em 100%, mas fechou em " + cValToChar (_nTotParc),, .t.)
					_lContinua = .F.
				endif
			endif
		endif
	endif

	// Leitura das pre-notas de compra e geracao de array de fornecedores, com valor bruto da parcela.
	if _lContinua
		procregua (10)
		incproc ('Verificando pre-notas de compra...')
		_oSQL := ClsSQL ():New ()
		/* Em marco/2020 simplesmente gerei 10% das notas de entrada. Mas da proxima vez vou querer ter as pre-notas prontas, pois assim poderei
		ter mais certeza dos dados, precos e grupos para pagamento, podendo assim aplicar o % de pagto. de cada variedade.
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ASSOCIADO, LOJA_ASSOC, ROUND (SUM (VALOR_TOTAL) * 0.1, 2) "  // Adiantar 10% da safra.
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE TIPO_NF = 'E'"
		_oSQL:_sQuery +=    " AND V.SAFRA = '" + mv_par05 + "'"
		_oSQL:_sQuery +=    " AND V.ASSOCIADO + V.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_oSQL:_sQuery +=  " GROUP BY V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:_sQuery +=  " ORDER BY V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:Log ()
		*/

		// A partir das pre-notas de compra da safra, onde as uvas jah encontram-se separadas por grupo de pagamento,
		// aplica o percentual referente a esta parcela. Gera array com o fornecedor e o valor da parcela.
		_aFornec = {}
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZZ9_FORNEC, ZZ9_LOJA, ZZ9_GRUPO,"
		_oSQL:_sQuery +=        " SUM (ZZ9_QUANT * " + iif (mv_par12 == 1, 'ZZ9_VUNIT', iif (mv_par12 == 2, 'ZZ9_VUNIT2', '0')) + ") AS VALOR"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZZ9_SAFRA = '" + mv_par05 + "'"
		_oSQL:_sQuery +=    " AND ZZ9_FORNEC + ZZ9_LOJA BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_oSQL:_sQuery +=  " GROUP BY ZZ9_FORNEC, ZZ9_LOJA, ZZ9_GRUPO"
		_oSQL:_sQuery +=  " ORDER BY ZZ9_FORNEC, ZZ9_LOJA, ZZ9_GRUPO"
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		do while ! (_sAliasQ) -> (eof ())

			// Controla quebra por fornecedor, por que posteriormente todos os 'grupos' devem ser pagos juntos.
			_sFornec    = (_sAliasQ) -> zz9_fornec
			_sLojaFor   = (_sAliasQ) -> zz9_loja
			_sHistCalc := ''
			_sHistCalc += 'Percentuais de parcelamento para esta safra:' + chr (13) + chr (10)
			_sHistCalc += _sDescParc
		//	U_LOG ('Calculando parcela bruta para forn.', _sFornec, _sLojaFor)
			_nVlrAntA = 0
			_nVlrAntB = 0
			_nVlrAntC = 0
			_nVlrGrpA = 0
			_nVlrGrpB = 0
			_nVlrGrpC = 0
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> zz9_fornec == _sFornec .and. (_sAliasQ) -> zz9_loja == _sLojaFor
		//		u_log ('grupo pagto:', (_sAliasQ) -> zz9_grupo)

				// Prepara historico de calculo
//				_sHistCalc += 'Grupo ' + (_sAliasQ) -> zz9_grupo + ' '
//				_sHistCalc += 'vlr.tot: ' + transform ((_sAliasQ) -> valor, '@E 999,999.99')

				// Calcula o valor desta parcela para cada grupo de pagamento. Vai precisar manutencao se forem criados novos grupos.
				if (_sAliasQ) -> zz9_grupo == 'A'
					for _nParcAnt = 1 to _nParcSaf - 1
						_nVlrAntA += (_sAliasQ) -> valor * _aPerGrpA [_nParcAnt] / 100
					next
					_nVlrGrpA = (_sAliasQ) -> valor * _aPerGrpA [_nParcSaf] / 100
					_sHistCalc += 'Valor ' + transform (_nParcSaf, "@E 9") + 'a.parc.grupo ' + (_sAliasQ) -> zz9_grupo + ': ' + transform ((_sAliasQ) -> valor, '@E 999,999.99') + ' x ' + transform (_aPerGrpA [_nParcSaf], '@E 99.99') + '% = ' + transform (_nVlrGrpA, '@E 999,999.99') + chr (13) + chr (10)
				elseif (_sAliasQ) -> zz9_grupo == 'B'
					for _nParcAnt = 1 to _nParcSaf - 1
						_nVlrAntB += (_sAliasQ) -> valor * _aPerGrpB [_nParcAnt] / 100
					next
					_nVlrGrpB = (_sAliasQ) -> valor * _aPerGrpB [_nParcSaf] / 100
					_sHistCalc += 'Valor ' + transform (_nParcSaf, "@E 9") + 'a.parc.grupo ' + (_sAliasQ) -> zz9_grupo + ': ' + transform ((_sAliasQ) -> valor, '@E 999,999.99') + ' x ' + transform (_aPerGrpB [_nParcSaf], '@E 99.99') + '% = ' + transform (_nVlrGrpB, '@E 999,999.99') + chr (13) + chr (10)
				elseif (_sAliasQ) -> zz9_grupo == 'C'
					for _nParcAnt = 1 to _nParcSaf - 1
						_nVlrAntC += (_sAliasQ) -> valor * _aPerGrpC [_nParcAnt] / 100
					next
					_nVlrGrpC = (_sAliasQ) -> valor * _aPerGrpC [_nParcSaf] / 100
					_sHistCalc += 'Valor ' + transform (_nParcSaf, "@E 9") + 'a.parc.grupo ' + (_sAliasQ) -> zz9_grupo + ': ' + transform ((_sAliasQ) -> valor, '@E 999,999.99') + ' x ' + transform (_aPerGrpC [_nParcSaf], '@E 99.99') + '% = ' + transform (_nVlrGrpC, '@E 999,999.99') + chr (13) + chr (10)
				else
					u_help ('Grupo de pagamento ' + (_sAliasQ) -> zz9_grupo + ' sem tratamento no calculo do valor da parcela bruta.',, .T.)
					_lContinua = .F.
				endif

				(_sAliasQ) -> (dbskip ())
			enddo

			if _nVlrAntA != 0
				_sHistCalc += 'Valor acumulado parcelas anteriores grupo A: ' + transform (_nVlrAntA, '@E 999,999.99') + chr (13) + chr (10)
			endif
			if _nVlrAntB != 0
				_sHistCalc += 'Valor acumulado parcelas anteriores grupo B: ' + transform (_nVlrAntB, '@E 999,999.99') + chr (13) + chr (10)
			endif
			if _nVlrAntC != 0
				_sHistCalc += 'Valor acumulado parcelas anteriores grupo C: ' + transform (_nVlrAntC, '@E 999,999.99') + chr (13) + chr (10)
			endif

			// Na primeira parcela de 2020, foram usados valores das notas de entrada, por que as pre-notas ainda nao
			// estavam geradas, e nessas notas havia varios casos em que os precos nao estavam corretos. Por isso, alguns
			// fornecedores receberam adiantamento a maior, outros a menor. Agora vou simular a primeira parcela com
			// base nas pre-notas e acertar essa diferenca.
			_nAj2020P1 = 0
			if mv_par05 == '2020' .and. _nParcSaf == 2
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "WITH ZZ9 AS ("
				_oSQL:_sQuery += " SELECT DISTINCT ZZ9.ZZ9_FILIAL, ZZ9.ZZ9_FORNEC, ZZ9.ZZ9_LOJA, ZZ9_PRODUT, ZZ9.ZZ9_GRAU, ZZ9.ZZ9_CLASSE, ZZ9.ZZ9_CLABD, ZZ9.ZZ9_VUNIT2, ZZ9.ZZ9_CONDUC"
				_oSQL:_sQuery += " FROM " + RetSQLName ("ZZ9") + " ZZ9"
				_oSQL:_sQuery += " WHERE ZZ9.D_E_L_E_T_ = '' AND ZZ9.ZZ9_SAFRA = '2020')"
				_oSQL:_sQuery += " SELECT round (SUM ((V.PESO_LIQ * ZZ9_VUNIT2) - V.VALOR_TOTAL), 2) AS FALTANTE"
				_oSQL:_sQuery += " FROM VA_VNOTAS_SAFRA V"
				_oSQL:_sQuery += " LEFT JOIN ZZ9 ON (V.FILIAL = ZZ9.ZZ9_FILIAL AND V.ASSOCIADO = ZZ9.ZZ9_FORNEC"
				_oSQL:_sQuery += " AND V.LOJA_ASSOC = ZZ9.ZZ9_LOJA AND V.PRODUTO = ZZ9.ZZ9_PRODUT AND V.GRAU = ZZ9.ZZ9_GRAU AND V.CLAS_FINAL = ZZ9.ZZ9_CLASSE"
				_oSQL:_sQuery += " AND V.CLAS_ABD = ZZ9.ZZ9_CLABD AND V.SIST_CONDUCAO = ZZ9.ZZ9_CONDUC)"
				_oSQL:_sQuery += " WHERE SAFRA = '2020' AND V.TIPO_NF = 'E'"
				_oSQL:_sQuery +=   " AND ASSOCIADO = '" + _sFornec + "'"
				_oSQL:_sQuery +=   " AND LOJA_ASSOC = '" + _sLojaFor + "'"
				_oSQL:_sQuery +=   " AND ZZ9_VUNIT2 != VALOR_UNIT"
				_oSQL:Log ()
				_nAj2020P1 = _oSQL:RetQry ()  // Este eh o valor faltante no total da safra do associado.
				_nAj2020P1 *= 0.1  // Primeira parcela eh 10%
				if _nAj2020P1 > 0
					_sHistCalc += "Vlr faltante 1a. parcela ref. precos indevidos nas notas de entrada: " + cvaltochar (abs (_nAj2020P1)) + chr (13) + chr (10)
				elseif _nAj2020P1 < 0
					_sHistCalc += "Vlr excedente 1a. parcela ref. precos indevidos nas notas de entrada: " + cvaltochar (abs (_nAj2020P1)) + chr (13) + chr (10)
				endif
			endif

		//	u_log ('Valor grupo A:', _nVlrGrpA)
		//	u_log ('Valor grupo B:', _nVlrGrpB)
		//	u_log ('Valor grupo C:', _nVlrGrpC)
		//	u_log ('Ajuste 1a.parc 2020:', _nAj2020P1)

			// Calcula o valor devido ate agora, somando todas as parcelas. Posteriormente vou descontar as jah adiantadas.
			_nAcumParc = _nVlrGrpA + _nVlrGrpB + _nVlrGrpC + _nVlrAntA + _nVlrAntB + _nVlrAntC

			_sHistCalc += 'Valor devido ate ' + dtoc (_dDtPagto) + ':                 ' + transform (_nAcumParc, '@E 999,999.99') + chr (13) + chr (10)

//			aadd (_aFornec, {_sFornec, _sLojaFor, _nVlrGrpA + _nVlrGrpB + _nVlrGrpC + _nAj2020P1, _sHistCalc})
			aadd (_aFornec, {_sFornec, _sLojaFor, _nAcumParc, _sHistCalc})
		enddo
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SA2")

		if len (_aFornec) == 0
			u_help ("Nao foi encontrada nenhuma pre-nota de compra. Verifique parametros.")
			_lContinua = .F.
		endif
	endif


	// Varre a lista de fornecedores X valores brutos, verificando se sao associados e tem valores em aberto.
	if _lContinua
	//	u_log (_aFornec)
		procregua (len (_aFornec))
		incproc ('Verificando conta corrente...')
		for _nFornec = 1 to len (_aFornec)
			u_log ('Verificando valores de ', _aFornec [_nFornec, 1], _aFornec [_nFornec, 2], fBuscaCpo ("SA2", 1, xfilial ("SA2") + _aFornec [_nFornec, 1] + _aFornec [_nFornec, 2], "A2_NOME"))
			incproc ('Fornec. ' + _aFornec [_nFornec, 1])
			_nAdtPAnt = 0
			_nSldDeb = 0
			_sHistCalc = _aFornec [_nFornec, 4]  // Para concatenar com o historico anterior.
			_oAssoc := ClsAssoc ():New (_aFornec [_nFornec, 1], _aFornec [_nFornec, 2])
			if empty (_oAssoc:DtEntrada (dDataBase)) .and. empty (_oAssoc:DtSaida (dDataBase))
				_sEhAssoc = 'N'
				u_log ('Nao associado:', _aFornec [_nFornec, 1], _aFornec [_nFornec, 2])

				// Busca pagamentos jah feitos para parcelas anteriores
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT E2_HIST, E2_VALOR"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SE2") + " SE2 "
				_oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_TIPO    = 'PA'"
				_oSQL:_sQuery +=   " AND SE2.E2_PREFIXO = 'ADT'"
				_oSQL:_sQuery +=   " AND SE2.E2_FORNECE = '" + _aFornec [_nFornec, 1] + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_LOJA    = '" + _aFornec [_nFornec, 2] + "'"
				_oSQL:_sQuery +=   " AND SE2.E2_EMISSAO >= '" + mv_par05 + "0201'"  // Pagamentos de safra iniciam em fevereiro (ateh janeiro estamos pagando o ano anterior)
				_oSQL:_sQuery += " ORDER BY SE2.E2_EMISSAO"
				_oSQL:Log ()
				_aSaldos = aclone (_oSQL:Qry2Array ())
				for _nIdxSaldo = 1 to len (_aSaldos)
					_nSldDeb += _aSaldos [_nIdxSaldo, 2]
					_sHistCalc += U_TamFixo (_aSaldos [_nIdxSaldo, 1], 45, ' ') + transform (_aSaldos [_nIdxSaldo, 2], '@E 999,999.99') + '(-)' + chr (13) + chr (10)
				next
			else
				_sEhAssoc = 'S'

				/*
				// Busca pagamentos jah feitos para parcelas anteriores
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT SUM (ZI_VALOR)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
				_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SZI.ZI_TM      = '31'"
				_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC   = '" + _aFornec [_nFornec, 1] + "'"
				_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO = '" + _aFornec [_nFornec, 2] + "'"
				_oSQL:_sQuery +=   " AND SZI.ZI_DATA   >= '" + mv_par05 + "0101'"
				_oSQL:_sQuery +=   " AND SZI.ZI_DATA   <  '" + dtos (dDataBase) + "'"  // Para o caso de estar sendo usada data retroativa.
			//	_oSQL:Log ()
				_nAdtPAnt = _oSQL:RetQry ()
				if _nAdtPAnt != 0
					_sHistCalc += 'Parcelas anteriores ja adiantadas:           ' + transform (_nAdtPAnt, '@E 999,999.99') + '(-)' + chr (13) + chr (10)
				endif
				*/

				// Busca lancamentos com saldo em aberto na conta corrente.
//				_nSldDeb = 0
//				_aSaldos = aclone (_oAssoc:LctComSald ('', 'zz', date (), '', 'zz', _sTMNao))
//				for _nIdxSaldo = 1 to len (_aSaldos)
//					_nSldDeb += _aSaldos [_nIdxSaldo, 11]
//					_sHistCalc += U_TamFixo (_aSaldos [_nIdxSaldo, 9], 45, ' ') + transform (_aSaldos [_nIdxSaldo, 11], '@E 999,999.99') + '(-)' + chr (13) + chr (10)
//				next
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "SELECT ZI_HISTOR, ZI_VALOR"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI "
				_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND SZI.ZI_TM      IN ('07', '31')"
				_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC   = '" + _aFornec [_nFornec, 1] + "'"
				_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO = '" + _aFornec [_nFornec, 2] + "'"
				_oSQL:_sQuery +=   " AND SZI.ZI_DATA   >= '" + mv_par05 + "0201'"  // Pagamentos de safra iniciam em fevereiro (ateh janeiro estamos pagando o ano anterior)
				_oSQL:_sQuery += " ORDER BY SZI.ZI_DATA"
			//	_oSQL:Log ()
				_aSaldos = aclone (_oSQL:Qry2Array ())
				for _nIdxSaldo = 1 to len (_aSaldos)
					_nSldDeb += _aSaldos [_nIdxSaldo, 2]
					_sHistCalc += U_TamFixo (_aSaldos [_nIdxSaldo, 1], 45, ' ') + transform (_aSaldos [_nIdxSaldo, 2], '@E 999,999.99') + '(-)' + chr (13) + chr (10)
				next

				// Alguns associados nao devo ler adtos por que nos avisaram que 'vao pagar em seguida'
				if _sSafra == '2020' .and. _nParcSaf == 1 .and. _aFornec [_nFornec, 1] $ '000245/000305/004935'  // Laurindo e Valmor Lisot, Adelia de Bortoli, 
					_sHistCalc += 'Este associado pediu para nao abater UNIMED por que vai depositar esta semana.' + chr (13) + chr (10)
					_nSldDeb = 0
				elseif _sSafra == '2020' .and. alltrim (str (_nParcSaf)) $ '1/2' .and. _aFornec [_nFornec, 1] == '003621'  // Dejair Betlinski pediu para descontar o adto. em 3 vezes
					_sHistCalc += 'Dejair Betlinski pediu para descontar o adto. de 7.000,00 em 3 vezes' + chr (13) + chr (10)
					_nSldDeb = 2335
				endif

	//			u_log ('saldo a debito:', _nSldDeb)
			endif

			// Se tem mais debitos do que o valor a pagar, nao paga nada.
//			_nPagar = max (0, _aFornec [_nFornec, 3] - _nSldDeb)
			_nPagar = _aFornec [_nFornec, 3]
			_nPagar -= _nAdtPAnt
			_nPagar -= _nSldDeb
			if _nPagar < 0
				_nPagar = 0
			endif

			_sHistCalc += U_TamFixo ('Valor a depositar', 45, ' ') + transform (_nPagar, '@E 999,999.99') + chr (13) + chr (10)

//			u_log ('Historico de calculo:')
//			u_log ('')
			u_log (_sHistCalc)
			u_log ('')

			// Adiciona este fornecedor na array de lctos a gerar
			aadd (_aAdtos, {_aFornec [_nFornec, 1],;
				_aFornec [_nFornec, 2],;
				fBuscaCpo ("SA2", 1, xfilial ("SA2") + _aFornec [_nFornec, 1] + _aFornec [_nFornec, 2], "A2_NOME"),;
				_aFornec [_nFornec, 3],;
				_nSldDeb,;
				_nPagar,;
				_sEhAssoc,;
				_sHistCalc})
			//	_aFornec [_nFornec, 4],;
			//	_aFornec [_nFornec, 5],;
			//	_aFornec [_nFornec, 6],;
			//	_aFornec [_nFornec, 7],;
			//	_aFornec [_nFornec, 8]})
		next
	//	u_log (_aAdtos)
	endif


	if _lContinua .and. mv_par06 == 1  // Apenas simular
		aHeader = {}
		aadd (aHeader, {'Fornec'      , 'Fornec'        , ''                 , 6,  0, '', '', 'C', '', ''})
		aadd (aHeader, {'Loja'        , 'Loja'          , ''                 , 2,  0, '', '', 'C', '', ''})
		aadd (aHeader, {'Nome'        , 'Nome'          , ''                 , 60, 0, '', '', 'C', '', ''})
		aadd (aHeader, {'VlrCheio'    , 'VlrCheio'      , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'Debitos'     , 'Debitos'       , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'Vlr_adiantar', 'Vlr_adiantar'  , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'Associado'   , 'Assoc ou nao'  , ''                 , 1,  0, '', '', 'C', '', ''})
//		aadd (aHeader, {'GrupoA'      , 'Grupo pagto A' , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
//		aadd (aHeader, {'GrupoB'      , 'Grupo pagto B' , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
//		aadd (aHeader, {'GrupoC'      , 'Grupo pagto C' , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
//		aadd (aHeader, {'AJ2020P1'    , 'Ajuste P1 2020', '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
//		aadd (aHeader, {'HistCalc'    , 'Hist calculo'  , ''                 , 200, 0, '', '', 'C', '', ''})
		u_aColsXLS (_aAdtos)


	elseif _lContinua .and. mv_par06 == 2  // Gerar movimentos


		_sTitSE2 = substr (dtos (dDataBase), 7, 2) + substr (dtos (dDataBase), 5, 2) + substr (dtos (dDataBase), 1, 4)

		// Parametriza geracao de PA para que nao gere movimento bancario (o mesmo vai ser gerado quando processarmos o retorno do arquivo do CNAB).
		_cPerg = 'FIN050'
		_aBkpSX1 = U_SalvaSX1 (_cPerg)
		U_GravaSX1 (_cPerg, '05', 2)  // Gera cheque para adiantamento [S/N]
		U_GravaSX1 (_cPerg, '09', 2)  // Gera mov.bancario quando NAO gerar cheque para adiantamento [S/N]

		procregua (len (_aFornec))
		for _nIdxAdto = 1 to len (_aAdtos)
			incproc ('Gerando PA para ' + _aAdtos [_nIdxAdto, 1])

			// Pode ser que o fornecedor jah tenha adiantamentos acima do valor a pagar.
			if _aAdtos [_nIdxAdto, 6] <= 0
				u_log (_aAdtos [_nIdxAdto, 1], 'sem saldo a adiantar')
				loop
			endif

			// Se for associado, gera via conta corrente.
			if _aAdtos [_nIdxAdto, 7] == 'S'
				_oCtaCorr := ClsCtaCorr():New ()
				_oCtaCorr:Assoc    = _aAdtos [_nIdxAdto, 1]
				_oCtaCorr:Loja     = _aAdtos [_nIdxAdto, 2]
				_oCtaCorr:TM       = '31'  //'07'
				_oCtaCorr:DtMovto  = dDataBase
				_oCtaCorr:VctoSE2  = _dDtPagto
				_oCtaCorr:Valor    = _aAdtos [_nIdxAdto, 6]
				_oCtaCorr:SaldoAtu = _aAdtos [_nIdxAdto, 6]
				if ! empty (_aAdtos [_nIdxAdto, 8])
					_oCtaCorr:Obs      = _aAdtos [_nIdxAdto, 8]
				endif
				_oCtaCorr:Usuario  = cUserName
				_oCtaCorr:Histor   = 'ADTO ' + cvaltochar (_nParcSaf) + 'a PARC SAFRA ' + _sSafra
				_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
				_oCtaCorr:Doc      = _sTitSE2
				_oCtaCorr:Serie    = _sPrefSE2
				_oCtaCorr:Origem   = _sOrigSZI
				_oCtaCorr:FormPag  = '3'  // 1=Cheque;2=Dinheiro;3=Depos.conta do associado;4=Deposito conta terceiros
				_oCtaCorr:Banco    = _sBcoPag
				_oCtaCorr:Agencia  = _sAgePag
				_oCtaCorr:NumCon   = _sCtaPag
				if _oCtaCorr:PodeIncl ()
					if ! _oCtaCorr:Grava (.F., .F.)
						U_help ("Erro na atualizacao da conta corrente para o associado '" + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
						_lContinua = .F.
					endif
				else
					U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
					_lContinua = .F.
				endif

			// Se nao for associado, gera PA diretamente pelo financeiro.
			else

				// Se possivel, grava a parcela sugerida. Senao, encontra a maior parcela jah existente e gera a proxima.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""                                                                                            
				_oSQL:_sQuery += " select IsNull (max (E2_PARCELA), '1'),"  // Se nao encontrar nada, retorna 1
				_oSQL:_sQuery +=        " SUM (CASE E2_PARCELA WHEN '" + _sParcela + "' THEN 1 ELSE 0 END)"  // Contagem de ocorrencias da parcela desejada.
				_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
				_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
				_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
				_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + _aAdtos [_nIdxAdto, 1] + "'"
				_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '" + _aAdtos [_nIdxAdto, 2]  + "'"
				_oSQL:_sQuery +=    " and SE2.E2_NUM      = '" + _sTitSE2  + "'"
				_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + _sPrefSE2 + "'"
				_aRetParc = aclone (_oSQL:Qry2Array ())
				if _aRetParc [1, 2] > 0
					_sParcela = soma1 (_aRetParc [1, 1])
					u_log ('Alterando a parcela desejada por que jah existia.')
				endif

				// Gera titulo no contas a pagar.
				_aAutoSE2 := {}
				aadd (_aAutoSE2, {"E2_PREFIXO", _sPrefSE2,               NIL})
				aadd (_aAutoSE2, {"E2_NUM"    , _sTitSE2,                Nil})
				aadd (_aAutoSE2, {"E2_TIPO"   , 'PA',                    Nil})
				aadd (_aAutoSE2, {"E2_FORNECE", _aAdtos [_nIdxAdto, 1],  Nil})
				aadd (_aAutoSE2, {"E2_LOJA"   , _aAdtos [_nIdxAdto, 2],  Nil})
				aadd (_aAutoSE2, {"E2_EMISSAO", dDataBase,               Nil})
				aadd (_aAutoSE2, {"E2_VENCTO" , _dDtPagto,               Nil})
				aadd (_aAutoSE2, {"E2_VENCREA", DataValida (_dDtPagto),  Nil})
				aadd (_aAutoSE2, {"E2_VALOR"  , _aAdtos [_nIdxAdto, 6],  Nil})
				aadd (_aAutoSE2, {"E2_HIST"   , 'ADTO ' + cvaltochar (_nParcSaf) + 'a PARC SAFRA ' + _sSafra, Nil})
				aadd (_aAutoSE2, {"E2_PARCELA", _sParcela,               Nil})
				aadd (_aAutoSE2, {"E2_ORIGEM" , "FINA050" ,              Nil})
				_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
				u_log (_aAutoSE2)
				lMsErroAuto	:=	.f.
				lMsHelpAuto	:=	.f.
				dbselectarea ("SE2")
				dbsetorder (1)
				MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
				if lMsErroAuto

					// Verifica se o titulo foi gravado, pois casos de avisos na contabilizacao sao entendidos como erros, mas a gravacao ocorre normalmente.
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT COUNT (*)"
					_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2")
					_oSQL:_sQuery +=  " WHERE E2_FILIAL  = '" + xfilial ("SE5")        + "'"
					_oSQL:_sQuery +=    " AND E2_PREFIXO = '" + _sPrefSE2              + "'"
					_oSQL:_sQuery +=    " AND E2_NUM     = '" + _sTitSE2               + "'"
					_oSQL:_sQuery +=    " AND E2_PARCELA = '" + _sParcela              + "'"
					_oSQL:_sQuery +=    " AND E2_FORNECE = '" + _aAdtos [_nIdxAdto, 1] + "'"
					_oSQL:_sQuery +=    " AND E2_LOJA    = '" + _aAdtos [_nIdxAdto, 2] + "'"
					_oSQL:_sQuery +=    " AND D_E_L_E_T_ = ''"
					_oSQL:Log ()
					if _oSQL:RetQry () == 0
						u_help ("Erro na rotina automatica de inclusao de contas a pagar:" + U_LeErro (memoread (NomeAutoLog ())))
						_lContinua = .F.
						MostraErro()
					endif
				endif
			endif
			if ! _lContinua
				exit
			endif
		next

		// Restaura parametros da tela de contas a pagar.
		U_SalvaSX1 (_cPerg, _aBkpSX1)
	endif

	if _lContinua
		u_help ("Processo concluido.")
	else
		u_help ("Processo cancelado.")
	endif
Return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM                      DEC VALID   F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,                        0,  "",   "SA2",  {},    ""})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,                        0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,                        0,  "",   "SA2",  {},    ""})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,                        0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {05, "Safra referencia              ", "C", 4,                        0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {06, "Simular ou gerar?             ", "N", 1,                        0,  "",   "   ",  {'Simular', 'Gerar'},    ""})
	aadd (_aRegsPerg, {07, "Data para pagamento?          ", "D", 8,                        0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {08, "Banco para pagamento?         ", "C", TamSX3 ('E5_BANCO')[1],   0,  "",   "SE6",  {},    ""})
	aadd (_aRegsPerg, {09, "Agencia para pagamento?       ", "C", TamSX3 ('E5_AGENCIA')[1], 0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {10, "Conta para pagamento?         ", "C", TamSX3 ('E5_CONTA')[1],   0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {11, "Qual a parcela a gerar?       ", "N", 2,                        0,  "",   "   ",  {},    ""})
	aadd (_aRegsPerg, {12, "Qual preco da pre-nota usar?  ", "N", 1,                        0,  "",   "   ",  {'Preco 1', 'Preco 2'},  ""})
//	aadd (_aRegsPerg, {13, "Abater debitos CC a partir de?", "D", 8,                        0,  "",   "   ",  {},    "Ex. ao gerar a 2a parcela, considerar apenas debitos posteriores a 1a."})
	U_ValPerg (cPerg, _aRegsPerg)
return
