// Programa:  VA_AdSaf
// Autor:     Robert Koch
// Data:      27/03/2020
// Descricao: Gera adiantamento de safra para associados.
//
// Historico de alteracoes:
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
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
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
	local _nIdxAdto  := 0
	local _oCtaCorr  := NIL
	local _sOrigSZI  := 'VA_ADSAF'
	local _sParcela  := space (TamSX3 ("E2_PARCELA")[1])
	local _aRetParc  := {}
	local _aAutoSE2  := {}
	local _sPrefSE2  := 'ADT'
	local _sTitSE2   := ''
	private aHeader  := {}

	U_LogSX1 (cPerg)

	// Monta lista de tipos de movimento que nao devem ser considerados no momento de ler os saldos em aberto na conta corrente.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT STRING_AGG (ZX5_10COD, '/')"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZX5")"
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=    " AND ZX5_TABELA = '10'"
		_oSQL:_sQuery +=    " AND (ZX5_10DC  != 'D' OR ZX5_10CAPI = 'S')"
		_oSQL:Log ()
		_sTMNao = _oSQL:RetQry ()
		u_log ('TM nao:', _sTMNao)
	endif

	// Leitura de notas de entrada de uva.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ASSOCIADO, LOJA_ASSOC, ROUND (SUM (VALOR_TOTAL) * 0.1, 2) "  // Adiantar 10% da safra.
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE TIPO_NF = 'E'"
		_oSQL:_sQuery +=    " AND V.SAFRA = '" + mv_par05 + "'"
		_oSQL:_sQuery +=    " AND V.ASSOCIADO + V.LOJA_ASSOC BETWEEN '" + mv_par01 + mv_par02 + "' AND '" + mv_par03 + mv_par04 + "'"
		_oSQL:_sQuery +=  " GROUP BY V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:_sQuery +=  " ORDER BY V.ASSOCIADO, V.LOJA_ASSOC"
		_oSQL:Log ()
		_aFornec = aclone (_oSQL:Qry2Array ())
		if len (_aFornec) == 0
			u_help ("Nao foi encontrada nenhuma NF de entrada de uva. Verifique parametros.")
			_lContinua = .F.
		endif

		procregua (len (_aFornec))
		incproc ('Calculando valores ...')
		for _nFornec = 1 to len (_aFornec)
			u_log (_aFornec [_nFornec, 1], _aFornec [_nFornec, 2])
			incproc ('Fornec. ' + _aFornec [_nFornec, 1])
			_nSldDeb = 0
			_oAssoc := ClsAssoc ():New (_aFornec [_nFornec, 1], _aFornec [_nFornec, 2])
			if empty (_oAssoc:DtEntrada (dDataBase)) .and. empty (_oAssoc:DtSaida (dDataBase))
				_sEhAssoc = 'N'
				u_log ('Nao associado:', _aFornec [_nFornec, 1], _aFornec [_nFornec, 2])
			else
				_sEhAssoc = 'S'

				// Alguns associados nao devo ler adtos por que nos avisaram que 'vao pagar em seguida'
				if _sSafra == '2020' .and. _aFornec [_nFornec, 1] $ '000245/000305/004935'  // Laurindo e Valmor Lisot, Adelia de Bortoli, 
					_nSldDeb = 0
				else
					_aSaldos = aclone (_oAssoc:LctComSald ('', 'zz', date (), '', 'zz', _sTMNao))
					u_log (_aSaldos)
					_nSldDeb = 0
					for _nIdxSaldo = 1 to len (_aSaldos)
						_nSldDeb += _aSaldos [_nIdxSaldo, 11]
					next
					if _sSafra == '2020' .and. _aFornec [_nFornec, 1] == '003621'  // Dejair Betlinski pediu para descontar o adto. em 3 vezes
						u_log ('Dejair Betlinski pediu para descontar o adto. de 7.000,00 em 3 vezes')
						_nSldDeb = 2335
					endif
				endif
				u_log ('saldo a debito:', _nSldDeb)
			endif

			// Adiciona este fornecedor na array de lctos a gerar
			aadd (_aAdtos, {_aFornec [_nFornec, 1],;
				_aFornec [_nFornec, 2],;
				fBuscaCpo ("SA2", 1, xfilial ("SA2") + _aFornec [_nFornec, 1] + _aFornec [_nFornec, 2], "A2_NOME"),;
				_aFornec [_nFornec, 3],;
				_nSldDeb,;
				max (0, _aFornec [_nFornec, 3] - _nSldDeb),;
				_sEhAssoc})
		next
		u_log (_aAdtos)
	endif


	if _lContinua .and. mv_par06 == 1  // Apenas simular
		aHeader = {}
		aadd (aHeader, {'Fornec'    , 'Fornec'   , ''                 , 6,  0, '', '', 'C', '', ''})
		aadd (aHeader, {'Loja'      , 'Loja'     , ''                 , 2,  0, '', '', 'C', '', ''})
		aadd (aHeader, {'Nome'      , 'Nome'     , ''                 , 60, 0, '', '', 'C', '', ''})
		aadd (aHeader, {'VlrCheio'  , 'VlrCheio' , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'Debitos'   , 'Debitos'  , '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'VlrAdiant' , 'VlrAdiant', '@E 999,999,999.99', 18, 2, '', '', 'N', '', ''})
		aadd (aHeader, {'Associado' , 'Associado', ''                 , 1,  0, '', '', 'C', '', ''})
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
				_oCtaCorr:TM       = '07'
				_oCtaCorr:DtMovto  = dDataBase
				_oCtaCorr:VctoSE2  = _dDtPagto
				_oCtaCorr:Valor    = _aAdtos [_nIdxAdto, 6]
				_oCtaCorr:SaldoAtu = _aAdtos [_nIdxAdto, 6]
				_oCtaCorr:Usuario  = cUserName
				_oCtaCorr:Histor   = 'ADTO 1a PARC SAFRA ' + _sSafra
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
						U_help ("Erro na atualizacao da conta corrente para o associado '" + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
						_lContinua = .F.
//					else
//						se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
//						if empty (se2 -> e2_vachvex)  // Soh pra garantir...
//							reclock ("SE2", .F.)
//							se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
//							msunlock ()
//						endif
					endif
				else
					U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
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
				aadd (_aAutoSE2, {"E2_HIST"   , 'ADTO 1a PARC SAFRA ' + _sSafra, Nil})
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
	U_ValPerg (cPerg, _aRegsPerg)
return
