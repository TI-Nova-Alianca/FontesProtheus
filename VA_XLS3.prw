// Programa...: VA_XLS3
// Autor......: Robert Koch
// Data.......: 30/09/2009
// Descricao..: Exportacao de saldos em estoque para o Excel.
//
// Historico de alteracoes:
// 22/10/2009 - Robert - Criado parametro para filtrar pelo campo B1_MRP
// 01/04/2019 - Robert - Migrada tabela 88 do SX5 para 38 do ZX5 (linhas comerciais).
//

// --------------------------------------------------------------------------
User Function VA_XLS3 (_lAutomat)
	Local cCadastro := "Exportacao de saldos em estoque para o Excel"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	private _sArqLog := U_NomeLog ()
	u_logID ()

	Private cPerg   := "VAXLS3"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,"Este programa tem como objetivo exportar saldos em estoque")
		AADD(aSays,"por almoxarifado para planilha eletronica (Excel)")
		AADD(aSays,"")
		
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
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _nRecCount := 0
	local _aAlmox    := {}
	local _nAlmox    := 0
	local _lContinua := .T.

	procregua (10)
	incproc ("Buscando dados")
	

	// Monta clausula 'where' em separado para poder usar em duas queries diferentes.
	if _lContinua
		_sWhere := ""
		_sWhere +=   " from " + RetSQLName ("SB1") + " SB1, "
	//	_sWhere +=              RetSQLName ("SX5") + " SX5 "
		_sWhere +=              RetSQLName ("ZX5") + " ZX5_39 "
		_sWhere +=  " WHERE SB1.D_E_L_E_T_  != '*'"
		_sWhere +=    " and SB1.B1_FILIAL    = '" + xfilial ("SB1") + "'"
		_sWhere +=    " and SB1.B1_CODLIN    between '" + mv_par03 + "' and '" + mv_par04 + "'"
		_sWhere +=    " and SB1.B1_TIPO      between '" + mv_par01 + "' and '" + mv_par02 + "'"
		_sWhere +=    " and SB1.B1_COD       between '" + mv_par05 + "' and '" + mv_par06 + "'"
		if mv_par09 == 1
			_sWhere +=    " and SB1.B1_MRP       = 'S'"
		elseif mv_par09 == 2
			_sWhere +=    " and SB1.B1_MRP       = 'N'"
		endif
		_sWhere +=    " AND ZX5_39.D_E_L_E_T_ = ''"
		_sWhere +=    " AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_sWhere +=    " AND ZX5_39.ZX5_TABELA = '39'"
		_sWhere +=    " AND ZX5_39.ZX5_39COD  = SB1.B1_CODLIN"
	
	
		// Monta lista de todos os almoxarifados com estoque dos produtos envolvidos, para poder incluir na query
		_sQuery := ""
		_sQuery += " SELECT DISTINCT B2_LOCAL "
		_sQuery +=   " from " + RetSQLName ("SB2") + " SB2 "
		_sQuery +=  " where SB2.D_E_L_E_T_ != '*'"
		_sQuery +=    " and SB2.B2_FILIAL   = '" + xfilial ("SB2") + "'"
		_sQuery +=    " and SB2.B2_LOCAL   != ''"
		_sQuery +=    " and SB2.B2_LOCAL   between '" + mv_par07 + "' and '" + mv_par08 + "'"
		_sQuery +=    " and SB2.B2_QATU    != 0"
		_sQuery +=    " and SB2.B2_COD     IN "
		_sQuery +=    " (SELECT DISTINCT B1_COD"
		_sQuery += _sWhere
		_sQuery +=    " ) ORDER BY SB2.B2_LOCAL"
		u_log (_sQuery)
		_aAlmox = aclone (U_Qry2Array (_sQuery))
		if len (_aAlmox) == 0
			u_help ("Nao foi encontrado saldo em nenhum almoxarifado. Verifique parametros!")
			_lContinua = .F.
		endif
	endif

	// Monta query final para exportacao dos dados
	if _lContinua
		_sQuery := ""
		_sQuery += " select SB1.B1_TIPO   as TIPO,"
		_sQuery +=        " SB1.B1_COD    as CODIGO,"
		_sQuery +=        " SB1.B1_DESC   as DESCRICAO,"
		_sQuery +=        " SB1.B1_CODLIN as LINHA,"
//		_sQuery +=        " SX5.X5_DESCRI as DESCR_LIN,"
		_sQuery +=        " ZX5_39.ZX5_39DESC as DESCR_LIN,"
		_sQuery +=        " SB1.B1_UM     as UN_MEDIDA,"
		_sQuery +=        " SB1.B1_LITROS as LITROS,"
	
		for _nAlmox = 1 to len (_aAlmox)
			_sQuery += "(SELECT ISNULL (SUM (B2_QATU - B2_RESERVA), 0)"
			_sQuery +=   " FROM " + RetSQLName ("SB2") + " SB2 "
			_sQuery +=  " WHERE SB2.D_E_L_E_T_ != '*'"
			_sQuery +=    " AND SB2.B2_FILIAL   = '" + xfilial ("SB2") + "'"
			_sQuery +=    " AND SB2.B2_LOCAL    = '" + _aAlmox [_nAlmox, 1] + "'"
			_sQuery +=    " AND SB2.B2_COD      = SB1.B1_COD) AS ALMOX_" + _aAlmox [_nAlmox, 1] + iif (_nAlmox == len (_aAlmox), "", ", ")
		next
	
		_sQuery += _sWhere
		_sQuery += " ORDER BY SB1.B1_CODLIN, SB1.B1_COD"
		u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		count to _nRecCount
		if _nRecCount == 0
			u_help ("Nao ha dados gerados. Verifique parametros!")
		else
			procregua (_nRecCount)
			incproc ("Gerando arquivo de exportacao")
			DbGoTop()
			processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		endif
		(_sAliasQ) -> (dbclosearea ())
		dbselectarea ("SD2")
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                   Help
	aadd (_aRegsPerg, {01, "Tipo Produto Inicial         ?", "C", 2,  0,  "",   "02 ", {},                      ""})
	aadd (_aRegsPerg, {02, "Tipo Produto Final           ?", "C", 2,  0,  "",   "02 ", {},                      ""})
	aadd (_aRegsPerg, {03, "Linha Inicial                ?", "C", 2,  0,  "",   "ZX539", {},                      ""})
	aadd (_aRegsPerg, {04, "Linha Final                  ?", "C", 2,  0,  "",   "ZX539", {},                      ""})
	aadd (_aRegsPerg, {05, "Produto Inicial              ?", "C", 15, 0,  "",   "SB1", {},                      ""})
	aadd (_aRegsPerg, {06, "Produto Final                ?", "C", 15, 0,  "",   "SB1", {},                      ""})
	aadd (_aRegsPerg, {07, "Almoxarifado Inicial         ?", "C", 2,  0,  "",   "AL ", {},                      ""})
	aadd (_aRegsPerg, {08, "Almoxarifado Final           ?", "C", 2,  0,  "",   "AL ", {},                      ""})
	aadd (_aRegsPerg, {09, "Produtos que entram no MRP   ?", "N", 1,  0,  "",   "   ", {"Sim", "Nao", "Todos"}, ""})
	aadd (_aRegsPerg, {10, "Filiais                       ", "N", 1,  0,  "",   "   ", {"Atual", "Selecionar"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
