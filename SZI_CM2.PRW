// Programa...: SZI_CM2
// Autor......: Robert Koch
// Data.......: 11/09/2011
// Descricao..: Calculo de correcao monetaria da conta corrente de associados.
//              Criado com base no SZI_CM de 13/09/2015.
//
// Historico de alteracoes:
// 13/01/2016 - Robert - Avisa, mas nao impede o calculo se jah existir correcao no mes. Isso por que o controle eh feito direto por associado.
//                     - Criados parametros de associado/loja inicial... final.
// 30/03/2017 - Robert - Correcao passa a ser calculada somente ma natriz.
// 24/11/2017 - Robert - Melhoria: mostrar mensagens de retorno do calculo.
// 14/08/2020 - Robert - Inseridas tags para catalogacao de fontes.
//                     - Melhorias geracao de logs.
// 24/04/2021 - Robert - Implementada opcao de execucao 'auto' (sem interface com usuario) para depuracao (GLPI 9814).
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Geracao de correcao monetaria / juros na conta corrente de associados.
// #PalavasChave      #correcao_monetaria #juros #associados #conta_corrente_associados
// #TabelasPrincipais #SZI #SE2
// #Modulos           #COOP

// --------------------------------------------------------------------------
User Function szi_cm2 (_lAuto)
	local _lContinua   := .T.
	local cCadastro    := "Calculo correcao monetaria conta corrente associados"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "SZI_CM2"

	u_log2 ('INFO', 'Iniciando processo de calculo de correcao monetaria associados.')

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if _lContinua
		_lContinua = U_ZZUVL ('051', __cUserID, .T.)//, cEmpAnt, cFilAnt)
	endif

	// Somente uma estacao por vez.
	if _lContinua
		_nLock := U_Semaforo (procname (), .F.)
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.",, .t.)
			return
		endif
	endif

	if _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
	endif

	if _lContinua
		if _lAuto == NIL .or. ! _lAuto
			AADD(aSays,"Este programa gera calculo correcao monetaria conta corrente associados")
			AADD(aSays,"")
			AADD(aSays,"")
			
			AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
			AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
			AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
			
			FormBatch( cCadastro, aSays, aButtons )
		
			If nOpca == 1
				u_logsx1 ()
				if mv_par01 == 1
					Processa( {|lEnd| _Calc ()})
				else
					Processa( {|lEnd| _Descalc ()})
				endif
			Endif
		else
			u_logsx1 ()
			if mv_par01 == 1
				Processa( {|lEnd| _Calc ()})
			else
				Processa( {|lEnd| _Descalc ()})
			endif
		endif

		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif
	u_log2 ('INFO', 'Processo de correcao monetaria finalizado')
return


// --------------------------------------------------------------------------
static function _TudoOk ()
	local _lRet     := .T.
	local _sPattern := ''

	// Cria objeto da classe 'expressao regular' para validar formato do parametro.
	_oRegex := tlpp.regex.Regex():new ('')
	_oRegex:setCaseSensitive (.F.)

	// Monta pattern (padrao) de pesquisa usando a sintaxe das expressoes regulares.
	_sPattern := '(0[1-9]|1[0|1|2])'  // Mes 01 a 09 ou 10 a 12
	_sPattern += '/'         // Precisa ter 1 barra separando mes e ano
	_sPattern += '[0-9]{4}'  // Precisa ter 4 posicoes para o ano.

	_oRegex:SetPattern (_sPattern)
	if ! _oRegex:PartialMatch (mv_par02)
		u_help ("Parametro '" + mv_par02 + "' invalido. Mes de referencia deve estar no formato MM/AAAA (mes e ano).",, .t.)
		_lRet = .F.
	endif
Return _lRet



// --------------------------------------------------------------------------
// Descalcula a correcao gerada para determinado mes.
Static Function _Descalc ()
	local _lContinua  := .T.
	local _sQuery     := ""
	local _sAliasQ    := ""
	local _nRecCount  := 0
	local _nExcluid   := 0
//	local _oDUtil     := NIL
//	local _sProxMes   := ""
	local _sMesRef    := mv_par02
	local _oCtaCorr   := ClsCtaCorr():New ()
//	local _sTMCorrC   := _oCtaCorr:TMCorrMonC
	local _sTMCorrD   := _oCtaCorr:TMCorrMonD
//	local _lGeraD     := .T.
//	local _lGeraC     := .F.

	// Busca movimentos a serem descalculados.
	if _lContinua
		_sQuery := ""
		_sQuery += "SELECT R_E_C_N_O_"
		_sQuery +=  " FROM " + RetSQLName ("SZI")
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery +=   " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"
		_sQuery +=   " AND ZI_TM      IN " + FormatIn (_sTMCorrD, '/')
		_sQuery +=   " AND ZI_MESREF  = '" + substr (_sMesRef, 1, 2) + substr (_sMesRef, 4, 4) + "'"
		_sQuery +=   " AND ZI_ORIGEM  = 'CALCCM3'"
		_sQuery +=   " AND ZI_ASSOC + ZI_LOJASSO BETWEEN '" + mv_par04 + mv_par05 + "' AND '" + mv_par06 + mv_par07 + "'"
		u_log2 ('debug', _sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
		count to _nRecCount
		if _nRecCount == 0
			u_help ("Nao existe correcao monetaria calculada dentro dos parametros informados.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (_nRecCount)
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
			_oCtaCorr = ClsCtaCorr():New ((_sAliasQ) -> R_E_C_N_O_)
			incproc (_oCtaCorr:Assoc + '/' + _oCtaCorr:Loja)
			u_log2 ('Iniciando associado ' + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja)
			if ! _oCtaCorr:Exclui ()
				u_help ("Nao foi possivel excluir movimentacao do associado '" + _oCtaCorr:Assoc + '/' + _oCtaCorr:Loja + "'.")
			else
				_nExcluid ++
			endif
			(_sAliasQ) -> (dbskip ())
		enddo

		
		if _nExcluid < _nRecCount
			u_help ("Alguns registros nao foram excluidos, provavelmente por que o titulo correspondente nao pode ser excluido do financeiro. Verifique!" + chr (13) + chr (10) + chr (13) + chr (10) + ;
			        "Total de registros encontrados: " + cvaltochar (_nRecCount) + chr (13) + chr (10) + ;
			        "Total de registros excluidos: " + cvaltochar (_nExcluid))
		endif

	endif
return _lContinua



// --------------------------------------------------------------------------
Static Function _Calc ()
	local _lContinua  := .T.
	local _oSQL       := NIL
	local _sMesRef    := mv_par02  // Guarda em variaveis locais por que as 'mv_par' serao usadas por rotinas automaticas.
	local _oCtaCorr   := ClsCtaCorr():New ()
//	local _sTMCorrC   := _oCtaCorr:TMCorrMonC
	local _sTMCorrD   := _oCtaCorr:TMCorrMonD
	local _aAssoc     := {}
	local _nAssoc     := 0
	local _nTaxa1     := mv_par03
//	local _lGeraD     := .T.
//	local _lGeraC     := .F.
	local _nJahTem    := 0

	// A correcao eh sempre gerada na matriz a partir de 30/03/2017.
	if _lContinua .and. cEmpAnt + cFilAnt != '0101'
		u_help ("A correcao deve ser gerada na matriz.")
		_lContinua = .F.
	endif

	if _lContinua
		_sQuery := ""
		_sQuery += "SELECT COUNT (*)"
		_sQuery +=  " FROM " + RetSQLName ("SZI") + " SZI"
		_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
		_sQuery +=   " AND SZI.ZI_FILIAL  = '" + xfilial ("SZI") + "'"
		_sQuery +=   " AND SZI.ZI_TM      IN " + FormatIn (_sTMCorrD, '/')
		_sQuery +=   " AND SZI.ZI_MESREF  = '" + substr (_sMesRef, 1, 2) + substr (_sMesRef, 4, 4) + "'"
		_sQuery +=   " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO BETWEEN '" + mv_par04 + mv_par05 + "' AND '" + mv_par06 + mv_par07 + "'"
		u_log2 ('debug', _sQuery)
		_nJahTem = U_RetSQL (_sQuery)
//		if ! IsInCallStack ("U_ROBERT")  // Me atrapalha muito durante testes
			if _nJahTem > 0
				_lContinua = U_MsgYesNo ("Ja' existe correcao monetaria neste mes para " + cvaltochar (_nJahTem) + " associados. Nao vai ser recalculada correcao para esses associados. Deseja continuar?")
			endif
//		endif
	endif


	// Busca os associados para os quais PODE ser calculada correcao monetaria.
	// A correcao eh gerada sempre no codigo/loja base do associado.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT ZI_ASSOC, ZI_LOJASSO"
		_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
		_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
/*		_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
		_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery +=                 " WHERE SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery +=                   " AND SA2.A2_COD     = SZI.ZI_ASSOC"
		_oSQL:_sQuery +=                   " AND SA2.A2_LOJA    = SZI.ZI_LOJASSO"
		_oSQL:_sQuery +=                   " AND SA2.A2_VACBASE = SA2.A2_COD"
		_oSQL:_sQuery +=                   " AND SA2.A2_VALBASE = SA2.A2_LOJA"  // Somente codigo/loja base
		_oSQL:_sQuery +=                   " AND SA2.A2_VALBASE = SA2.A2_LOJA"
		_oSQL:_sQuery +=  " ) "
*/
		// Cfe. GLPI 14548, somente calcularemos correcao para quem tiver feito
		// emprestimos (TM=07) entao acho interessante nem perder tempo olhando
		// outros associados.
		_oSQL:_sQuery +=    " AND SZI.ZI_TM = '07'"
		// Nao vou olhar coisa muito antiga para nao perder tempo de processamento.
		_oSQL:_sQuery +=    " AND SZI.ZI_DATA >= '" + dtos (stod (substr (mv_par02, 4, 4) + substr (mv_par02, 1, 2) + '01') - 360) + "'"

		_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC + SZI.ZI_LOJASSO BETWEEN '" + mv_par04 + mv_par05 + "' AND '" + mv_par06 + mv_par07 + "'"
		_oSQL:_sQuery +=  " ORDER BY ZI_ASSOC, ZI_LOJASSO"
		u_log2 ('debug', _sQuery)
		_aAssoc = _oSQL:Qry2Array ()
		procregua (len (_aAssoc))
		for _nAssoc = 1 to len (_aAssoc)
			_oAssoc := ClsAssoc():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2])
			incproc (_oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + _oAssoc:Nome)
			u_log2 ('info', 'Iniciando assoc: ' + _oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + _oAssoc:Nome)
			if ! _oAssoc:CalcCM3 (substr (mv_par02, 4, 4) + substr (mv_par02, 1, 2), _nTaxa1)
				u_help (_oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + alltrim (_oAssoc:Nome) + ' ' + _oAssoc:UltMsg,, .t.)
			endif
			u_log2 ('info', _oAssoc:UltMsg)
		next
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                            TIPO TAM DEC VALID F3        Opcoes                              Help
	aadd (_aRegsPerg, {01, "Calcular / descalcular         ", "N", 1,  0,  "",   "      ", {"Calcular", "Descalcular"},        ""})
	aadd (_aRegsPerg, {02, "Mes/ano de referencia (MM/AAAA)", "C", 7,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {03, "Taxa % correcao diaria         ", "N", 6,  4,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {04, "Associado inicial              ", "C", 6,  0,  "",   "SA2_AS", {},                                 ""})
	aadd (_aRegsPerg, {05, "Loja associado inicial         ", "C", 2,  0,  "",   "      ", {},                                 ""})
	aadd (_aRegsPerg, {06, "Associado final                ", "C", 6,  0,  "",   "SA2_AS", {},                                 ""})
	aadd (_aRegsPerg, {07, "Loja associado final           ", "C", 2,  0,  "",   "      ", {},                                 ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
