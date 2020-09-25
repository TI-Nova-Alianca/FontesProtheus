// Programa:  SZI_Rcb
// Autor:     Robert Koch
// Data:      04/04/2011
// Descricao: Impressao de recibos com base no arquivo SZI (conta corrente de associados).
//
// Historico de alteracoes:
// 21/03/2016 - Robert - Valida se o usuario pertence ao grupo 059.
//

// --------------------------------------------------------------------------
User Function SZI_Rcb ()
	Local cCadastro := "Impressao de recibos C/C associados"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _sArqLog := U_NomeLog ()
	u_logID ()
	
	Private cPerg   := "SZI_RCB"
	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1

	// Verifica se o usuario tem acesso.
	if ! U_ZZUVL ('059')
		return
	endif

	AADD(aSays,"Este programa tem como objetivo gerar a impressao de recibos para associados")
	AADD(aSays,"baseando-se em suas contas correntes.")
	
	AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	
	FormBatch( cCadastro, aSays, aButtons )
	
	If nOpca == 1
		Processa( { |lEnd| _Gera() } )
	Endif
return
	
	
	
// --------------------------------------------------------------------------
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet
	
	
	
// --------------------------------------------------------------------------
Static Function _Gera()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _oPrn      := NIL
	local _aDados    := {}
	local _aRecibo   := {}
	local _nValor    := 0
	local _i		 := 0

	procregua (3)
	incproc ("Lendo dados...")
		
	// Busca dados
	_sQuery := ""
	_sQuery += " select ZI_ASSOC, ZI_LOJASSO, ZI_DATA, ZI_MESREF, ZI_HISTOR, ZI_TM, ZI_SALDO, SA2.A2_NOME "
	_sQuery +=   " from " + RETSQLNAME ("SZI") + " SZI, "
	_sQuery +=              RETSQLNAME ("SA2") + " SA2 "
	_sQuery += " where SZI.D_E_L_E_T_ != '*'"
	_sQuery +=   " AND SA2.D_E_L_E_T_ != '*'"
	_sQuery +=   " and SZI.ZI_FILIAL  = '" + xfilial ("SZI")  + "'"
	_sQuery +=   " and SA2.A2_FILIAL  = '" + xfilial ("SA2")  + "'"
	_sQuery +=   " and SA2.A2_COD     = SZI.ZI_ASSOC"
	_sQuery +=   " and SA2.A2_LOJA    = SZI.ZI_LOJASSO"
	_sQuery +=   " and SZI.ZI_ASSOC   + SZI.ZI_LOJASSO between '" + mv_par01+mv_par02 + "' and '" + mv_par03+mv_par04 + "'"
	_sQuery +=   " and SZI.ZI_MESREF  between '" + strtran (mv_par05, '/', '') + "' and '" + strtran (mv_par06, '/', '') + "'"
	_sQuery +=   " and SZI.ZI_TM      between '" + mv_par07 + "' and '" + mv_par08 + "'"
	_sQuery +=   " and SZI.ZI_SALDO   > 0"
	_sQuery += " ORDER BY A2_NOME, ZI_MESREF, ZI_TM"
	u_log (_squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	procregua ((_sAliasQ) -> (reccount ()))
	_aDados = {}
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		
		// Prepara dados para enviar ao programa de impressao de recibos genericos.
		_aRecibo = {}
		aadd (_aRecibo, (_sAliasQ) -> a2_nome)
		aadd (_aRecibo, (_sAliasQ) -> zi_saldo)                                                                             
		aadd (_aRecibo, substr ((_sAliasQ) -> zi_histor, 1, 36))
		aadd (_aRecibo, substr ((_sAliasQ) -> zi_histor, 37, 36))
		aadd (_aRecibo, '')
		aadd (_aRecibo, alltrim (sm0 -> m0_cidcob))
		aadd (_aRecibo, ctod (""))
		aadd (_aRecibo, 2)
		aadd (_aRecibo, 1)
		u_log (_arecibo)

		for _i = 1 to mv_par09
			aadd (_aDados, aclone (_aRecibo))
		next

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
    dbselectarea ("SZI")

	// Utiliza a rotina de impressao de recibos genericos.
	if len (_aDados) == 0
		msgalert ("Nao ha dados gerados.")
	else
		U_VA_RCB (_aDados)
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID                        F3       Opcoes Help
	aadd (_aRegsPerg, {01, "Produtor inicial              ", "C", 6,  0,  "",                          "SA2",   {},    "Codigo do associado inicial"})
	aadd (_aRegsPerg, {02, "Loja produtor inicial         ", "C", 2,  0,  "",                          "SA2",   {},    "Loja do associado inicial"})
	aadd (_aRegsPerg, {03, "Produtor final                ", "C", 6,  0,  "",                          "SA2",   {},    "Codigo do associado final"})
	aadd (_aRegsPerg, {04, "Loja produtor final           ", "C", 2,  0,  "",                          "SA2",   {},    "Loja do associado final"})
	aadd (_aRegsPerg, {05, "Mes referencia inicial        ", "C", 7,  0,  "substr(mv_par05,3,1)=='/'", "",      {},    "Mes de referencia inicial (formato MM/AAAA)"})
	aadd (_aRegsPerg, {06, "Mes referencia final          ", "C", 7,  0,  "substr(mv_par06,3,1)=='/'", "",      {},    "Mes de referencia final (formato MM/AAAA)"})
	aadd (_aRegsPerg, {07, "Tipo de movimento inicial     ", "C", 2,  0,  "",                          "ZX510", {},    ""})
	aadd (_aRegsPerg, {08, "Tipo de movimento final       ", "C", 2,  0,  "",                          "ZX510", {},    ""})
	aadd (_aRegsPerg, {09, "Qt. de vias                   ", "N", 1,  0,  "",                          "",      {},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
