// Programa...: SZI_DS
// Autor......: Robert Koch
// Data.......: 19/04/2016
// Descricao..: Gera na cta.corrente de associados movimento de distribuicao de sobras do exercicio.
//
// Historico de alteracoes:
// 29/01/2019 - Robert - GLPI5254 - Movtos tipo 13 transferidos de outras filiais eram considerados duas vezes.
//                                - Desconsiderava associados desligados na data base.
//                                - Grava log de evento de geracao do calculo.
// 01/02/2019 - Robert - Desconsidera quem teve movimentos tipo 11, 17 e 27
//                     - Mostra todos os associados, com motivo pelo qual foram desconsiderados no calculo.
// 16/04/2024 - Robert - Melhorias gerais e tratamento para gravacao de distribuicao de perdas (GLPI 15192).
// 08/05/2024 - Robert - Chamada de parametros da tela de contas a pagar.
//

// --------------------------------------------------------------------------
User Function szi_ds ()
	local _lContinua   := .T.
	local cCadastro    := "Distribuicao de sobras / perdas do exercicio"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "SZI_DS"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
	endif

	// Somente uma estacao por vez.
	if _lContinua
		_nLock := U_Semaforo (procname (), .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		endif
	endif

	if _lContinua .and. cFilAnt != '01'
		u_help ("Distribuicao de sobras ou perdas deve ser rodada na matriz.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		u_help ("A seguir serao mostrados os parametros da rotina de inclusao de titulos a pagar. Verifique opcoes de contabilizacao.")
		Pergunte ("FIN050", .t.)
	endif

	if _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
		
		AADD(aSays,cCadastro)
		AADD(aSays,"Este programa gera movimentos na conta corrente de associados,")
		AADD(aSays,"rateando o total a distribuir com base no valor de cada um na safra base.")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
	 	FormBatch( cCadastro, aSays, aButtons )
	
		If nOpca == 1
			Processa( {|lEnd| _Calc ()})
		Endif
	
		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
//	Local _aArea    := GetArea()
	Local _lRet     := .T.
//	RestArea(_aArea)
Return(_lRet)



// --------------------------------------------------------------------------
Static Function _Calc ()
	local _lContinua  := .T.
	local _oSQL       := NIL
	local _nVlADist   := mv_par01
	local _sSafraBas  := mv_par02
	local _sQueFazer  := iif (mv_par03 == 1, 'S', iif (mv_par03 == 2, 'P', ''))
	local _oCtaCorr   := NIL
	local _aAssoc     := {}
	local _nAssoc     := 0
	local _nTotDist   := 0
	local _aCols      := {}
	local _sLinInf    := ""
	local _oEvento    := NIL
	local _sPrefixo   := ''
	local _sTMSobra   := '19'
	local _sTMPerda   := '41'
	local _sMemCalc   := ''
	local _sMesRef    := '12' + _sSafraBas
	local _nTGSafra   := 0

	u_logsx1 ()

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSqlName ("SZI")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZI_TM       IN ('" + _sTMSobra + "', '" + _sTMPerda + "')"
		_oSQL:_sQuery +=   " AND ZI_MESREF   = '" + _sMesRef + "'"
		if _oSQL:RetQry (1, .f.) > 0
			u_help ("Ja existe(m) lancamento(s) de distribuicao de sobras (ou de perdas) para este ano.", _oSQL:_sQuery, .T.)
			_lContinua = .F.
		endif
	endif

	// Busca valores dos associados que participaram da operacao de safra do ano base.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT V.ASSOCIADO, V.LOJA_ASSOC, V.NOME_ASSOC "
		_oSQL:_sQuery +=      ", SUM (V.VALOR_TOTAL) AS VLR_SAFRA"
		_oSQL:_sQuery +=      ", 0 AS VLR_DISTR"
		_oSQL:_sQuery +=   " FROM VA_VNOTAS_SAFRA V"
		_oSQL:_sQuery +=  " WHERE V.SAFRA = '" + _sSafraBas + "'"
		
		// Precisa ter emitido alguma contranota nessa safra com status de 'associado'.
		// Nao implementei esse teste na query principal por que existem casos em que
		// o mesmo fornecedor era 'associado' durante a safra, mas quando gerei nota de
		// complemento, ele ja era 'ex-associado' ou mesmo 'fornecedor de uva'. Nesse
		// caso, eu consideraria somente parte das notas dele.
		_oSQL:_sQuery +=    " AND EXISTS (SELECT * "
		_oSQL:_sQuery +=                  " FROM VA_VNOTAS_SAFRA A"
		_oSQL:_sQuery +=                 " WHERE A.SAFRA       = V.SAFRA"
		_oSQL:_sQuery +=                   " AND A.ASSOCIADO   = V.ASSOCIADO"
		_oSQL:_sQuery +=                   " AND A.LOJA_ASSOC  = V.LOJA_ASSOC"
		_oSQL:_sQuery +=                   " AND A.TIPO_FORNEC LIKE '1%'"  // ASSOCIADO
		_oSQL:_sQuery +=                ")"

		_oSQL:_sQuery +=  " GROUP BY ASSOCIADO, LOJA_ASSOC, NOME_ASSOC"
		_oSQL:Log ()
		_aAssoc = _oSQL:Qry2Array (.F., .F.)

		// Distribui o valor total proporcionalmente ao valor de safra de cada associado.
		_nTGSafra  = 0
		_nTotDist = 0
		for _nAssoc = 1 to len (_aAssoc)
			_nTGSafra += _aAssoc [_nAssoc, 4]
		next
		for _nAssoc = 1 to len (_aAssoc)
			_aAssoc [_nAssoc, 5] = round ((_aAssoc [_nAssoc, 4] * _nVlADist) / _nTGSafra, 2)
			_nTotDist += _aAssoc [_nAssoc, 5]
			if _aAssoc [_nAssoc, 5] < 0
				u_help ("Erro na distribuicao de valores. Associado '" + _aAssoc [_nAssoc, 1] + " ficou com valor negativo.",, .t.)
				_lContinua = .F.
			endif
		next
	endif

	// Se deu alguma diferenca por causa de arredondamentos, ajusta no associado de maior valor.
	if _lContinua
		if _nTotDist != _nVlADist
			if abs (_nVlADist - _nTotDist) > abs (_nVlADist * 0.1)
				u_help ("Houve algum problema no calculo de distribuicao! Eu deveria distribuir $ " + cvaltochar (_nVlADist) + " mas calculei uma distribuicao de $ " + cvaltochar (_nTotDist),, .t.)
				_lContinua = .F.
			endif
			_aAssoc = asort (_aAssoc,,, {|_x, _y| _x [4] < _y [4]})
			U_Log2 ('debug', '[' + procname () + ']Ajustando diferenca de ' + cvaltochar (_nVlADist - _nTotDist) + ' no associado ' + _aAssoc [len (_aAssoc), 1])
			_aAssoc [len (_aAssoc), 5] += (_nVlADist - _nTotDist)
		endif
	endif

	if _lContinua
		_aAssoc = asort (_aAssoc,,, {|_x, _y| _x [3] < _y [3]})  // Ordena por nome
		_nTotDist = 0
		for _nAssoc = 1 to len (_aAssoc)
			_nTotDist += _aAssoc [_nAssoc, 5]
		next
		if _nTotDist != _nVlADist
			u_help ("Erro na distribuicao de valores: Total previsto para distribuicao diferente do informado no parametro.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_aCols = {}
		aadd (_aCols, {1, 'Associado',         60, ''})
		aadd (_aCols, {2, 'Loja',              20, ''})
		aadd (_aCols, {3, 'Nome',             160, ''})
		aadd (_aCols, {4, 'Vlr.safra',         60, '@E 999,999,999.99'})
		aadd (_aCols, {5, 'Vlr.distribuido',   60, '@E 999,999,999.99'})
		_sLinInf := 'Total safra: ' + transform (_nTGSafra, "@E 999,999,999.99") + '  '
		_sLinInf += 'Soma distribuicoes previstas: ' + transform (_nTotDist, "@E 999,999,999.99")
		U_F3Array (_aAssoc, 'Distribuicao de valores', _aCols, NIL, NIL, 'Previa da geracao de dados:', _sLinInf, .T., 'C')
		_lContinua = U_MsgYesNo ("Confirma a geracao dos dados na conta corrente?")
	endif

	if _lContinua
		_sPrefixo = U_RetZX5 ('10', iif (_sQueFazer == 'S', _sTMSobra, _sTMPerda), 'ZX5_10PREF')
		
		// Grava evento para posterior consulta.
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SZI002"
		_oEvento:Texto     = "Iniciando distribuicao de sobras/perdas com os seguintes parametros:" + chr (13) + chr (10)
		_oEvento:Texto    += U_LogSX1 (cPerg) + chr (13) + chr (10)
		_oEvento:Texto    += "Numero de associados contemplados: " + cvaltochar (len (_aAssoc)) + chr (13) + chr (10)
		_oEvento:Texto    += 'Vl.tot.geral safra: ' + cvaltochar (_nTGSafra) + chr (13) + chr (10)
		_oEvento:Alias     = "SZI"
		_oEvento:Grava ()

		procregua (len (_aAssoc))
		for _nAssoc = 1 to len (_aAssoc)
			if _aAssoc [_nAssoc, 5] > 0  // Se tem valor gerado...
				incproc (_aAssoc [_nAssoc, 3])

				// Monta string com memoria de calculo, a ser gravada no campo de observacoes do lcto.
				_sMemCalc := 'Gerado em ' + dtoc (date ()) + ' c/data base ' + dtoc (dDataBase) + chr (13) + chr (10)
				_sMemCalc += 'Distribuindo um total geral de $' + cvaltochar (_nVlADist)
				_sMemCalc += ' sobre uma safra total de $' + cvaltochar (_nTGSafra)
				_sMemCalc += ' (safra deste assoc: $' + cvaltochar (_aAssoc [_nAssoc, 4]) + ')'
				_oCtaCorr = ClsCtaCorr():New ()
				_oCtaCorr:Assoc   = _aAssoc [_nAssoc, 1]
				_oCtaCorr:Loja    = _aAssoc [_nAssoc, 2]
				_oCtaCorr:TM      = iif (_sQueFazer == 'S', _sTMSobra, _sTMPerda)
				_oCtaCorr:DtMovto = dDataBase
				_oCtaCorr:Valor   = _aAssoc [_nAssoc, 5]
				_oCtaCorr:Histor  = 'DISTRIBUICAO ' + iif (_sQueFazer == 'S', 'SOBRA', iif (_sQueFazer == 'P', 'PERDA', '')) + ' EXERC. ' + _sSafraBas
				_oCtaCorr:MesRef  = _sMesRef
				_oCtaCorr:Doc     = strtran (dtoc (dDataBase), '/', '')
				_oCtaCorr:Serie   = _sPrefixo
				_oCtaCorr:Parcela = '1'
				_oCtaCorr:Origem  = 'SZI_DS'
				_oCtaCorr:Obs     = _sMemCalc
				_oCtaCorr:Safra   = _sSafraBas
				if ! _oCtaCorr:PodeIncl ()
					u_help ('Associado ' + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + chr (13) + chr (10) + _oCtaCorr:UltMsg)
					exit
				else
					if ! _oCtaCorr:Grava ()
						u_help (_oCtaCorr:UltMsg)
						exit
					endif
				endif
			endif
		next
		u_help ("Processo terminado com sucesso.")
	else
		u_help ("Processo cancelado.",, .t.)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                              Help
	aadd (_aRegsPerg, {01, "Valor a distribuir            ", "N", 15, 2,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {02, "Safra base                    ", "C", 4,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {03, "Sobras ou perdas?             ", "N", 1,  0,  "",   "      ", {'Sobras', 'Perdas'},               ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
