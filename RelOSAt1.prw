// Programa...: RelOSAt1
// Autor......: Sandra Sugari/Robert Koch
// Data.......: 14/08/2023
// Descricao..: Exportacao de O.S em Atraso 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Exportacao de O.S em Atraso
// #PalavasChave      #ordens_manutenção
// #TabelasPrincipais #STJ #ST9 #STL #ST1 #TPJ #TPL
// #Modulos   		  #MANUTENÇÃO ATIVOS
//
// --------------------------------------------------------------------------
User Function RelOSAt1
	Local cCadastro := "Exportacao de ordens em atraso"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "RelOSAt1"
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
_oSQL:_sQuery += " SELECT DISTINCT "
_oSQL:_sQuery += "      TJ_ORDEM AS ORDEM "
_oSQL:_sQuery += "     ,T9_CODBEM AS COD_BEM "
_oSQL:_sQuery += "     ,T9_NOME AS DESCRICAO "
_oSQL:_sQuery += "     ,SUBSTRING(STJ.TJ_DTMPINI, 7, 2) + '/' + SUBSTRING(STJ.TJ_DTMPINI, 5, 2) + '/' + SUBSTRING(STJ.TJ_DTMPINI, 1, 4) AS DATA_INI_PREV "
_oSQL:_sQuery += "     ,STJ.TJ_HOMPINI AS HORA_INI_PREV "
_oSQL:_sQuery += "     ,SUBSTRING(STJ.TJ_DTMPFIM, 7, 2) + '/' + SUBSTRING(STJ.TJ_DTMPFIM, 5, 2) + '/' + SUBSTRING(STJ.TJ_DTMPFIM, 1, 4) AS DATA_FIM_PREV "
_oSQL:_sQuery += "     ,STJ.TJ_HOMPFIM AS HORA_FIM_PREV "
_oSQL:_sQuery += "     ,SUBSTRING(TPL.TPL_DTINIC,7,2) + '/' + SUBSTRING (TPL.TPL_DTINIC,5,2) + '/' + SUBSTRING (TPL.TPL_DTINIC,1,4) AS DATA_INI_REAL "
_oSQL:_sQuery += "     ,TPL.TPL_HOINIC AS HORA_INI_REAL "
_oSQL:_sQuery += "     ,SUBSTRING(TPL.TPL_DTFIM,7,2) + '/' + SUBSTRING (TPL.TPL_DTFIM,5,2) + '/' + SUBSTRING (TPL.TPL_DTFIM,1,4) AS DATA_FIM_REAL "
_oSQL:_sQuery += "     ,TPL.TPL_HOFIM AS HORA_FIM_REAL " 
_oSQL:_sQuery += "     ,ISNULL(T1_NOME, '') AS MANUTENTOR "
_oSQL:_sQuery += "     ,ISNULL(TPL_CODMOT, 'Î') AS COD_MOT "
_oSQL:_sQuery += "     ,TPJ.TPJ_DESMOT AS MOTIVO_ATRASO "
_oSQL:_sQuery += "     ,STJ.TJ_SITUACA "
_oSQL:_sQuery += "     ,STJ.TJ_TIPO "
_oSQL:_sQuery += " FROM STJ010 AS STJ "
_oSQL:_sQuery += "     LEFT JOIN ST9010 AS ST9 "
_oSQL:_sQuery += " 	        ON (ST9.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "			    AND ST9.T9_FILIAL = STJ.TJ_FILIAL "
_oSQL:_sQuery += "			    AND ST9.T9_CODBEM = STJ.TJ_CODBEM) "
_oSQL:_sQuery += "     LEFT JOIN TPL010 AS TPL "
_oSQL:_sQuery += "          ON (TPL.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "			    AND TPL.TPL_FILIAL = STJ.TJ_FILIAL "
_oSQL:_sQuery += "			    AND TPL.TPL_ORDEM = STJ.TJ_ORDEM) "
_oSQL:_sQuery += "     LEFT JOIN TPJ010 AS TPJ "
_oSQL:_sQuery += "      	ON (TPJ.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "  			AND TPJ.TPJ_FILIAL = TPL.TPL_FILIAL "
_oSQL:_sQuery += "			    AND TPJ.TPJ_CODMOT = TPL.TPL_CODMOT) "
_oSQL:_sQuery += "     LEFT JOIN STL010 AS STL "
_oSQL:_sQuery += "      	ON (STL.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "  			AND STL.TL_FILIAL = STJ.TJ_FILIAL "
_oSQL:_sQuery += "  			AND STL.TL_ORDEM = STJ.TJ_ORDEM "
_oSQL:_sQuery += "  			AND STL.TL_PLANO = STJ.TJ_PLANO) "
_oSQL:_sQuery += "     LEFT JOIN ST1010 AS ST1 "
_oSQL:_sQuery += "      	ON (ST1.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "  			AND ST1.T1_FILIAL = '' "
_oSQL:_sQuery += "  			AND ST1.T1_CODFUNC = STL.TL_CODIGO) "
_oSQL:_sQuery += " WHERE STJ.D_E_L_E_T_ = '' "
_oSQL:_sQuery += " AND STJ.TJ_TERMINO != 'S' "
_oSQL:_sQuery += " AND STJ.TJ_ORDEM BETWEEN  '" + mv_par01 + "' AND '" + mv_par02 + "'" 
_oSQL:_sQuery += " AND ST9.T9_CODBEM BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
_oSQL:_sQuery += " AND ISNULL( ST1.T1_CODFUNC,'') BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
_oSQL:_sQuery += " AND ISNULL( TPL.TPL_CODMOT,'') BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
_oSQL:_sQuery += " AND STJ.TJ_DTMPINI BETWEEN '" + DTOS(mv_par09) + "' AND '" + DTOS(mv_par10) + "'"
_oSQL:_sQuery += " AND (STJ.TJ_DTMPINI < TJ_DTMRINI or TJ_DTMRINI = '') "


	IF  (mv_par11) == 4
		_oSQL:_sQuery += "  AND STJ.TJ_TERMINO = 'S' "
	ELSE 
		_oSQL:_sQuery += "  AND STJ.TJ_TERMINO != 'S' "
		do case
		case  (mv_par11) == 1
			_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'C' "
		case (mv_par11) == 2
			_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'L' "
		case (mv_par11) == 3
			_oSQL:_sQuery += "  AND STJ.TJ_SITUACA = 'P' "
		endcase
	
	Endif
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
	
	//                     PERGUNT                             TIPO TAM DEC VALID   F3       Opcoes                                           Help
	aadd (_aRegsPerg, {01, "Ordem de			             ", "C", 06, 0,  "",   "STJ",    {},                            						 ""})
	aadd (_aRegsPerg, {02, "Ordem ate                        ", "C", 06, 0,  "",   "STJ",    {},                         				 		     ""})
	aadd (_aRegsPerg, {03, "Codigo Bem         			     ", "C", 15, 0,  "",   "ST9",    {},                            						 ""})
	aadd (_aRegsPerg, {04, "Codigo Ate         			     ", "C", 15, 0,  "",   "ST9",    {},                           							 ""})
	aadd (_aRegsPerg, {05, "Codigo Funcionario de			 ", "C", 10, 0,  "",   "ST1",    {},                            						 ""})
	aadd (_aRegsPerg, {06, "Codigo Funcionario ate			 ", "C", 10, 0,  "",   "ST1",    {},                            						 ""})
	aadd (_aRegsPerg, {07, "Codigo Motivo De  			     ", "C", 03, 0,  "",   "TPJ",    {},                           							 ""})
	aadd (_aRegsPerg, {08, "Codigo Motivo Ate  			     ", "C", 03, 0,  "",   "TPJ",    {},                            						 ""})
	aadd (_aRegsPerg, {09, "Data Prev Inicio de            	 ", "D", 08, 0,  "",   "   ",    {},                           							 ""})
	aadd (_aRegsPerg, {10, "Data Prev Inicio ate          	 ", "D", 08, 0,  "",   "   ",    {},                            						 ""})
	aadd (_aRegsPerg, {11, "Situacao da ordem  			     ", "C", 01, 0,  "",   "   ",    {"Cancelado","Liberado","Pendende","Encerrado"},        ""})                    
	
	U_ValPerg (cPerg, _aRegsPerg)
	
Return
