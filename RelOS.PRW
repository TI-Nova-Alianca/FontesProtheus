// Programa...: RelOS
// Autor......: Andre Alves
// Data.......: 07/11/2018
// Cliente....: Nova Alianca
// Descricao..: Exportacao de O.S 
//
// Historico de alteracoes:
// Criado para exportar relatorio da Manutenção 
// 10/09/2019  - Andre - Foi criado um campo novo (TQB_PARADA) adicionado no relatório.
// 21/11/2019  - Andre - Ajustado relatório para filtrar pelo status a O.S (TJ_SITUACA).
//
// --------------------------------------------------------------------------
User Function RelOS 
	Local cCadastro := "Exportacao de ordens"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "RelOS"
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
	_oSQL:_sQuery += "  SELECT DISTINCT TJ_ORDEM AS ORDEM, TQB.TQB_SOLICI AS SOLICITACAO "
	_oSQL:_sQuery += " ,SUBSTRING(TQB.TQB_DTABER,7,2) + '/' + SUBSTRING (TQB.TQB_DTABER,5,2) + '/' + SUBSTRING (TQB.TQB_DTABER,1,4) AS DT_ABER_SS "
	_oSQL:_sQuery += " ,TQB.TQB_HOABER AS HR_ABER_SS "
	_oSQL:_sQuery += " ,CASE TQB.TQB_PARADA WHEN '1' THEN 'SIM' " 
	_oSQL:_sQuery += "						WHEN '2' THEN 'NAO' "
	_oSQL:_sQuery += "						ELSE '' "
	_oSQL:_sQuery += "						END AS BEM_PARADO "
	_oSQL:_sQuery += " ,TJ_TIPO AS TIPO, T9_CODBEM AS COD_BEM, T9_NOME AS NOME_BEM "
	_oSQL:_sQuery += " ,SUBSTRING(TJ_DTMRINI,7,2) + '/' + SUBSTRING (TJ_DTMRINI,5,2) + '/' + SUBSTRING (TJ_DTMRINI,1,4) AS DATA_I "
	_oSQL:_sQuery += " ,TJ_HOMRINI AS HORA_I "
	_oSQL:_sQuery += " ,SUBSTRING(TJ_DTMRFIM,7,2) + '/' + SUBSTRING (TJ_DTMRFIM,5,2) + '/' + SUBSTRING (TJ_DTMRFIM,1,4) AS DATA_F "
	_oSQL:_sQuery += " ,TJ_HOMRFIM AS HORA_F "
	_oSQL:_sQuery += " ,SUBSTRING(TJ_DTPRINI,7,2) + '/' + SUBSTRING (TJ_DTPRINI,5,2) + '/' + SUBSTRING (TJ_DTPRINI,1,4) AS DATA_I_REAL "
	_oSQL:_sQuery += " ,TJ_HOPRINI AS HORA_I_REAL "
	_oSQL:_sQuery += " ,SUBSTRING(TJ_DTPRFIM,7,2) + '/' + SUBSTRING (TJ_DTPRFIM,5,2) + '/' + SUBSTRING (TJ_DTPRFIM,1,4) AS DATA_F_REAL "
	_oSQL:_sQuery += " ,TJ_HOPRFIM AS HORA_F_REAL "
	_oSQL:_sQuery += " ,ISNULL(T1_NOME,'SEM MANUTENTOR') AS MANUTENTOR "
/*	_oSQL:_sQuery += "	, (SELECT dbo.VA_DTOC(MIN(TL_DTINICI)) "
    _oSQL:_sQuery += "     FROM " + RetSQLName ("STL") + " STL "
    _oSQL:_sQuery += "       WHERE STL.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "        AND STL.TL_FILIAL  = STJ.TJ_FILIAL "
    _oSQL:_sQuery += "        AND STL.TL_ORDEM   = STJ.TJ_ORDEM) AS DATA_I "
    _oSQL:_sQuery += "  , TL_HOINICI AS HORA_I "
    _oSQL:_sQuery += "	, (SELECT dbo.VA_DTOC(MAX(STL.TL_DTFIM)) "
    _oSQL:_sQuery += "     FROM " + RetSQLName ("STL") + " STL "
	_oSQL:_sQuery += "       WHERE STL.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "        AND STL.TL_FILIAL  = STJ.TJ_FILIAL "
    _oSQL:_sQuery += "        AND STL.TL_ORDEM   = STJ.TJ_ORDEM ) AS DATA_F "
    _oSQL:_sQuery += " ,TL_HOFIM AS HORA_F, T1_NOME AS MANUTENTOR "
    _oSQL:_sQuery += " , (SELECT TOP 1 ST8.T8_NOME "
    _oSQL:_sQuery += "     FROM " + RetSQLName ("ST8") + " ST8 "
    _oSQL:_sQuery += "	    WHERE ST8.T8_FILIAL = STN.TN_FILIAL "
	_oSQL:_sQuery += "       AND ST8.T8_CODOCOR = STN.TN_CODOCOR) AS PROBLEMA "
    _oSQL:_sQuery += " , (SELECT TOP 1 ST8.T8_NOME "
    _oSQL:_sQuery += "     FROM " + RetSQLName ("ST8") + " ST8 "
	_oSQL:_sQuery += "      WHERE ST8.T8_FILIAL = STN.TN_FILIAL "
    _oSQL:_sQuery += "       AND ST8.T8_CODOCOR = STN.TN_CAUSA) AS CAUSA "
	_oSQL:_sQuery += " , (SELECT TOP 1 ST8.T8_NOME "
    _oSQL:_sQuery += "     FROM " + RetSQLName ("ST8") + " ST8 "
    _oSQL:_sQuery += "	    WHERE ST8.T8_FILIAL = STN.TN_FILIAL "
    _oSQL:_sQuery += "       AND ST8.T8_CODOCOR = STN.TN_SOLUCAO) AS SOLUCAO "*/
 	_oSQL:_sQuery += " ,SB1.B1_DESC AS RECURSO "
	_oSQL:_sQuery += " ,REPLACE (REPLACE(REPLACE(REPLACE(CAST(RTRIM(CAST(STJ.TJ_OBSERVA AS VARBINARY (8000))) AS VARCHAR (8000)) , char(13), ''), char(10), ''), char(14), ''),',','') AS OBSERVACAO "
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("STJ") + " STJ "
	_oSQL:_sQuery +=  " left join " + RetSQLName ("STL") + " STL "
	_oSQL:_sQuery +=     " left join " + RetSQLName ("ST1") + " ST1 "
    _oSQL:_sQuery +=		" ON (ST1.T1_FILIAL = ''"
	_oSQL:_sQuery +=		" AND ST1.T1_CODFUNC = STL.TL_CODIGO)"
	_oSQL:_sQuery +=           " left join " + RetSQLName ("SB1") + " SB1 "
    _oSQL:_sQuery +=              " ON (SB1.B1_FILIAL = '' "
    _oSQL:_sQuery +=			  " AND SB1.B1_COD = STL.TL_CODIGO "
    _oSQL:_sQuery +=			  "	AND SB1.B1_COD >= '600000') "
	_oSQL:_sQuery +=  "    ON (STL.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=  "		    AND STL.TL_FILIAL = STJ.TJ_FILIAL "
    _oSQL:_sQuery +=  "		    AND STL.TL_ORDEM = STJ.TJ_ORDEM) "
    _oSQL:_sQuery +=   " left join " + RetSQLName ("STN") + " STN "
	_oSQL:_sQuery +=   		" ON (STJ.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=	      "  AND STN.TN_FILIAL   = STJ.TJ_FILIAL"
	_oSQL:_sQuery +=		  "  AND STN.TN_ORDEM    = STJ.TJ_ORDEM)"
	_oSQL:_sQuery +=   "  LEFT JOIN " + RetSQLName ("TQB") + " TQB "
    _oSQL:_sQuery +=   		" ON (TQB.D_E_L_E_T_ = ''"
    _oSQL:_sQuery +=        "     AND TQB.TQB_FILIAL = STJ.TJ_FILIAL"
    _oSQL:_sQuery +=        "     AND TQB.TQB_CODBEM = STJ.TJ_CODBEM"
    _oSQL:_sQuery +=        "     AND TQB.TQB_ORDEM = STJ.TJ_ORDEM)"
	_oSQL:_sQuery +=   " left join " + RetSQLName ("ST9") + " ST9 "
	_oSQL:_sQuery +=	" ON (ST9.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=		" AND ST9.T9_CODBEM =STJ.TJ_CODBEM)"
	_oSQL:_sQuery += " WHERE STJ.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "  AND STJ.TJ_FILIAL = '" + xfilial ("STJ") + "'"
    _oSQL:_sQuery += "  AND STJ.TJ_ORDEM BETWEEN   '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += "  AND STJ.TJ_DTORIGI BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "'"
	_oSQL:_sQuery += "  AND ST9.T9_CODBEM BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_oSQL:_sQuery += "  AND STJ.TJ_CCUSTO BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	if .not. Empty(mv_par09)
		_oSQL:_sQuery += "  AND ST1.T1_NOME LIKE '" + ALLTRIM(mv_par09) + "%'"
	else
		_oSQL:_sQuery += "  AND ST1.T1_NOME LIKE '" + "%'"
	endif
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
	_oSQL:_sQuery += " ORDER BY ORDEM"
	
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
	aadd (_aRegsPerg, {03, "Data de            			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
	aadd (_aRegsPerg, {04, "Data ate           			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
	aadd (_aRegsPerg, {05, "Codigo Bem         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {06, "Codigo Ate         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {07, "C\C de			 			  ", "C", 06, 0,  "",   "STJ_2",  {},                             ""})
	aadd (_aRegsPerg, {08, "C\C ate						  ", "C", 06, 0,  "",   "STJ_2",  {},                             ""})
	aadd (_aRegsPerg, {09, "Manutentor         			  ", "C", 40, 0,  "",   "ST1_2",  {},                             ""})
	aadd (_aRegsPerg, {10, "Situacao da ordem  			  ", "C", 01, 0,  "",   "   ",    {"Cancelado","Liberado","Pendende","Encerradas"},                             ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return