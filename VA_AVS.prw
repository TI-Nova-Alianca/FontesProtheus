// Programa:  VA_AVS
// Autor:     Robert Koch
// Data:      12/01/2010
// Descricao: Altera data de vencimento das parcelas pendentes de pagamento da safra.
//            Com isso facilita para o setor financeiro encontra-las no momento de 
//            fazer o atendimento ao associado.
//
// Historico de alteracoes:
// 17/09/2012 - Robert - Passa a validar titulos com a view VA_VNOTAS_SAFRA.
// 18/06/2015 - Robert - View VA_NOTAS_SAFRA renomeada para VA_VNOTAS_SAFRA
// 15/06/2016 - Robert - Passa a buscar dados direto do SE2 + SZI.
//                     - Passa a usar browse com marcacao para selacao do usuario.
//

// --------------------------------------------------------------------------
User Function VA_AVS (_lAuto)
	Local cCadastro  := "Altera data de vencimento das parcelas pendentes de pagamento da safra"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
//	private _sArqLog := U_NomeLog ()
	Private cPerg    := "VA_AVS"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays, "Este programa tem como objetivo alterar a data de vencimento das")
		AADD(aSays, "parcelas pendentes de pagamento da safra.")

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
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _lContinua := .T.
	local _oEvento   := NIL
	local _nAlter    := 0
	local _oSQL      := NIL
	local _aTit := {}
	local _nTit := 0
	local _aCols := {}

	procregua (10)
	incproc ('Lendo dados...')

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SE2.R_E_C_N_O_, '' AS OK, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_NOMFOR, E2_VALOR, E2_SALDO, E2_EMISSAO, E2_VENCTO, "
	_oSQL:_sQuery +=        " A2_BANCO, A2_AGENCIA, A2_NUMCON"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SE2") + " SE2, "
	_oSQL:_sQuery +=              RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL  = '" + xfilial ("SA2")   + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COD     = E2_FORNECE"
	_oSQL:_sQuery +=    " AND SA2.A2_LOJA    = E2_LOJA"
	_oSQL:_sQuery +=    " AND SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2")   + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + SE2.E2_LOJA >= '" + mv_par01 + mv_par02 + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_FORNECE + SE2.E2_LOJA <= '" + mv_par03 + mv_par04 + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_VENCTO  BETWEEN '" + dtos (mv_par05) + "' AND '" + dtos (mv_par06) + "'"
	_oSQL:_sQuery +=    " AND SE2.E2_SALDO   > 0"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                 " WHERE SZI.ZI_FILIAL  = SE2.E2_FILIAL"
	_oSQL:_sQuery +=                   " AND SZI.ZI_ASSOC   = SE2.E2_FORNECE"
	_oSQL:_sQuery +=                   " AND SZI.ZI_LOJASSO = SE2.E2_LOJA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_DOC     = SE2.E2_NUM"
	_oSQL:_sQuery +=                   " AND SZI.ZI_SERIE   = SE2.E2_PREFIXO"
	_oSQL:_sQuery +=                   " AND SZI.ZI_PARCELA = SE2.E2_PARCELA"
	_oSQL:_sQuery +=                   " AND SZI.ZI_TM      = '13')"
	_oSQL:_sQuery +=  " ORDER BY E2_NOMFOR, E2_NUM"
	_oSQL:Log ()
	_aTit := _oSQL:Qry2Array ()
	if len (_aTit) == 0
		u_help ("Nao foram encontrados titulos dentro dos parametros informados.")
	else
		for _nTit = 1 to len (_aTit)
			_aTit [_nTit, 2] = .F.
		next
	
		_aCols = {}
		aadd (_aCols, {3,  'Numero',  50, ''})
		aadd (_aCols, {4,  'Pref',    30, ''})
		aadd (_aCols, {5,  'Parc',    15, ''})
		aadd (_aCols, {6,  'Nome',   120, ''})
		aadd (_aCols, {7,  'Valor',   70, '@E 999,999,999.99'})
		aadd (_aCols, {8,  'Saldo',   70, '@E 999,999,999.99'})
		aadd (_aCols, {9,  'Emissao', 40, '@D'})
		aadd (_aCols, {10, 'Vencto',  40, '@D'})
		aadd (_aCols, {11, 'Banco',   30, ''})
		aadd (_aCols, {12, 'Agencia', 40, ''})
		aadd (_aCols, {13, 'Conta',   50, ''})
		U_MbArray (@_aTit, 'Selecione titulos', _aCols, 2, NIL, NIL, '.T.')
		u_log (_aTit)
		procregua (len (_aTit))
		for _nTit = 1 to len (_aTit)
			if _aTit [_nTit, 2]
				incproc (_aTit [_nTit, 6])
				se2 -> (dbgoto (_aTit [_nTit, 1]))
				u_logtrb ('se2')
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "SE2001"
				_oEvento:Texto     = "Pg.safra parc.'" + se2 -> e2_parcela + "' vcto.alterado de " + dtoc (se2 -> e2_vencrea) + " para " + dtoc (mv_par07)
				_oEvento:NFEntrada = se2 -> e2_num
				_oEvento:SerieEntr = se2 -> e2_prefixo
				_oEvento:Fornece   = se2 -> e2_fornece
				_oEvento:LojaFor   = se2 -> e2_loja
				_oEvento:Grava ()
	
				reclock ("SE2", .F.)
				se2 -> e2_vencto  = mv_par07
				se2 -> e2_vencrea = DataValida (mv_par07)
				msunlock ()
				_nAlter ++
			endif
		next
	endif
	u_help ("Processo concluido. " + cvaltochar (_nAlter) + " titulos alterados.")
return




// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM                    DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", tamsx3 ("A2_COD")[1],  0,  "",   "SA2_AS", {},    "Codigo associado inicial para filtragem de registros"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", tamsx3 ("A2_LOJA")[1], 0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", tamsx3 ("A2_COD")[1],  0,  "",   "SA2_AS", {},    "Codigo associado final para filtragem de registros"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", tamsx3 ("A2_LOJA")[1], 0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {05, "Vencto (atual) inicial        ", "D", 8,                     0,  "",   "      ", {},    "Data vencto inicial para filtragem de registros"})
	aadd (_aRegsPerg, {06, "Vencto (atual) final          ", "D", 8,                     0,  "",   "      ", {},    "Data vencto final para filtragem de registros"})
	aadd (_aRegsPerg, {07, "Nova data de vencimento       ", "D", 8,                     0,  "",   "      ", {},    "Nova data de vencto"})

	aadd (_aDefaults, {"03", 'zzzzzz'})
	aadd (_aDefaults, {"04", 'zz'})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
