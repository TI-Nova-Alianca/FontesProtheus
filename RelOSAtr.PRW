// Programa...: RelOSAtr
// Autor......: Andre Alves
// Data.......: 18/03/2020
// Cliente....: Nova Alianca
// Descricao..: Exportacao de O.S em atraso 
//
// Historico de alteracoes:
// Criado para exportar relatorio da Manutenção 
//
// --------------------------------------------------------------------------
User Function RelOSAtr 
	Local cCadastro := "Exportacao de ordens em atraso"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "RelOSAtr"
	_ValidPerg()
	Pergunte(cPerg,.F.)

		AADD(aSays,"Gera excel")
		
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		
		FormBatch( cCadastro, aSays, aButtons )
		
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	
return

// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet

// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL
	local _sAliasQ   := NIL
	private aHeader  := {}  // Para simular a exportacao de um GetDados.
	private aCols    := {}  // Para simular a exportacao de um GetDados.

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "  SELECT DISTINCT "
	_oSQL:_sQuery += "		TJ_ORDEM AS ORDEM "
    _oSQL:_sQuery += "	   ,T9_CODBEM AS COD_BEM "
    _oSQL:_sQuery += "     ,T9_NOME AS DESCRICAO "
    _oSQL:_sQuery += "     ,ISNULL (T1_NOME,'NAO TEM') AS MANUTENTOR "
    _oSQL:_sQuery += "     ,TPL.TPL_CODMOT AS COD_MOT "
    _oSQL:_sQuery += "     ,TPJ.TPJ_DESMOT AS MOTIVO_ATRASO " 
    _oSQL:_sQuery += "     ,SUBSTRING(TPL.TPL_DTINIC,7,2) + '/' + SUBSTRING (TPL.TPL_DTINIC,5,2) + '/' + SUBSTRING (TPL.TPL_DTINIC,1,4) AS DATA_INI "
    _oSQL:_sQuery += "     ,TPL.TPL_HOINIC AS HORA_INI "
    _oSQL:_sQuery += "     ,SUBSTRING(TPL.TPL_DTFIM,7,2) + '/' + SUBSTRING (TPL.TPL_DTFIM,5,2) + '/' + SUBSTRING (TPL.TPL_DTFIM,1,4) AS DATA_FIM "
    _oSQL:_sQuery += "     ,TPL.TPL_HOFIM AS HORA_FIM "
    _oSQL:_sQuery += "	FROM " + RetSQLName ("STJ") + " STJ "
    _oSQL:_sQuery += "		LEFT JOIN  " + RetSQLName ("STL") + " STL "
    _oSQL:_sQuery += "			LEFT JOIN  " + RetSQLName ("ST1") + " ST1 "
	_oSQL:_sQuery += "				ON (ST1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "				AND ST1.T1_FILIAL = '' "
	_oSQL:_sQuery += "		        AND ST1.T1_CODFUNC = STL.TL_CODIGO) "
	_oSQL:_sQuery += "			ON (STL.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "    		AND STL.TL_FILIAL = STJ.TJ_FILIAL "
    _oSQL:_sQuery += "			AND STL.TL_ORDEM = STJ.TJ_ORDEM) "
    _oSQL:_sQuery += "		LEFT JOIN  " + RetSQLName ("ST9") + " ST9 "
	_oSQL:_sQuery += "			ON (ST9.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "			AND ST9.T9_FILIAL = STJ.TJ_FILIAL "
	_oSQL:_sQuery += "			AND ST9.T9_CODBEM = STJ.TJ_CODBEM) "
	_oSQL:_sQuery += "		LEFT JOIN  " + RetSQLName ("TPL") + " TPL "
	_oSQL:_sQuery += "			ON (TPL.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "			AND TPL.TPL_FILIAL = STJ.TJ_FILIAL "
	_oSQL:_sQuery += "			AND TPL.TPL_ORDEM = STJ.TJ_ORDEM) "
	_oSQL:_sQuery += "		LEFT JOIN  " + RetSQLName ("TPJ") + " TPJ "
	_oSQL:_sQuery += "			ON (TPJ.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "			AND TPJ.TPJ_FILIAL = TPL.TPL_FILIAL "
	_oSQL:_sQuery += "			AND TPJ.TPJ_CODMOT = TPL.TPL_CODMOT) "
	_oSQL:_sQuery += "	WHERE STJ.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "	AND STJ.TJ_FILIAL = '" + xfilial ("STJ") + "'"
	_oSQL:_sQuery += "	AND STJ.TJ_ORDEM BETWEEN  '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += "	AND ST9.T9_CODBEM BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	
	if .not. Empty(mv_par05)
		_oSQL:_sQuery += "  AND ST1.T1_CODFUNC = '" + ALLTRIM(mv_par05) + "'"
	endif
	
	_oSQL:_sQuery += "	AND TPL.TPL_CODMOT BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
	_oSQL:_sQuery += "	AND TPL.TPL_DTINIC BETWEEN '" + DTOS(mv_par08) + "' AND '" + DTOS(mv_par09) + "'"
	_oSQL:_sQuery += "	AND STJ.TJ_CODBEM = ST9.T9_CODBEM "
	
	do case
	case (mv_par10) == 1
		_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'C' "
	case (mv_par10) == 2
		_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'L' "
		_oSQL:_sQuery += "  AND STJ.TJ_TERMINO = 'N' "
	case (mv_par10) == 3
		_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'P' "
	otherwise
		_oSQL:_sQuery += "  AND STJ.TJ_TERMINO != 'N' "
	endcase
	
	_oSQL:_sQuery += "ORDER BY ORDEM "

	//u_showmemo (_oSQL:_squery)
    
    u_log (_oSQL:_squery)
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("STJ")
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                          Help
	aadd (_aRegsPerg, {01, "Ordem de			          ", "C", 06, 0,  "",   "STJ",    {},                             ""})
	aadd (_aRegsPerg, {02, "Ordem ate                     ", "C", 06, 0,  "",   "STJ",    {},                             ""})
	aadd (_aRegsPerg, {03, "Codigo Bem         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {04, "Codigo Ate         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {05, "Codigo Funcionario			  ", "C", 06, 0,  "",   "ST1",    {},                             ""})
	aadd (_aRegsPerg, {06, "Codigo Motivo De  			  ", "C", 03, 0,  "",   "TPJ",    {},                             ""})
	aadd (_aRegsPerg, {07, "Codigo Motivo Ate  			  ", "C", 03, 0,  "",   "TPJ",    {},                             ""})
	aadd (_aRegsPerg, {08, "Data de            			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
	aadd (_aRegsPerg, {09, "Data ate           			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
	aadd (_aRegsPerg, {10, "Situacao da ordem  			  ", "C", 01, 0,  "",   "   ",    {"Cancelado","Liberado","Pendende","Encerradas"},                             ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
	
Return