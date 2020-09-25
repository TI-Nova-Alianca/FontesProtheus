// Programa...: RELCONT														
// Autor......: Andre Alves													
// Data.......: 04/09/2019													
// Cliente....: Nova Alianca												
// Descricao..: Contador de BEM 											
//																				
// Historico de alteracoes:															
// Criado para exportar contador de bem. 									
//																			
// --------------------------------------------------------------------------
User Function RELCONT 
	Local cCadastro := "Exportacao Contador de Bem"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.

	Private cPerg   := "RELCONT"
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
	_oSQL:_sQuery += "  SELECT STP.TP_CODBEM AS CODIGO_BEM "
	_oSQL:_sQuery += "  	 , ST9.T9_NOME AS DESCRICAO "
	_oSQL:_sQuery += "  	 , STP.TP_DTLEITU AS DATA_LEITURA "
	_oSQL:_sQuery += "  	 , STP.TP_POSCONT AS CONTADOR "
	_oSQL:_sQuery += "  	 , STP.TP_VARDIA AS VAR_DIA "
	_oSQL:_sQuery += "  	 , STP.TP_VIRACON AS VIRADAS "
	_oSQL:_sQuery += "  	 , CASE STP.TP_TIPOLAN WHEN 'I' THEN 'Inclusao' "
	_oSQL:_sQuery += "  	 					   WHEN 'C' THEN 'Contador' "
    _oSQL:_sQuery += "  	    				   WHEN 'P' THEN 'Producao' "
    _oSQL:_sQuery += "  	 				  	   WHEN 'A' THEN 'Abastecimento' "				  
    _oSQL:_sQuery += "  	 				   	   WHEN 'V' THEN 'Virada' "
    _oSQL:_sQuery += "  	 				       WHEN 'M' THEN 'Movimentacao' "
    _oSQL:_sQuery += "  	 				       WHEN 'Q' THEN 'Quebra' "
    _oSQL:_sQuery += "  	 			           END AS LANCAMENTO "
	_oSQL:_sQuery += "  FROM " + RetSQLName ("STP") + " STP "
	_oSQL:_sQuery += " 		LEFT JOIN " + RetSQLName ("ST9") + " ST9 "
	_oSQL:_sQuery += "  		ON (ST9.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "  		AND ST9.T9_FILIAL = STP.TP_FILIAL " 
	_oSQL:_sQuery += "  		AND ST9.T9_CODBEM = STP.TP_CODBEM) "
	_oSQL:_sQuery += "  WHERE STP.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "  AND STP.TP_CODBEM BETWEEN  '" + mv_par01 + "' AND '" + mv_par02 + "'" 
	_oSQL:_sQuery += "  AND STP.TP_DTLEITU BETWEEN '" + DTOS(mv_par03) + "' AND '" + DTOS(mv_par04) + "'" 
	_oSQL:_sQuery += "  ORDER BY STP.TP_CODBEM, STP.TP_DTLEITU "
	
    //u_showmemo (_oSQL:_squery)
    
    u_log (_oSQL:_squery)
	_sAliasQ = _oSQL:Qry2Trb (.f.)
	incproc ("Gerando arquivo de exportacao")
	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("STP")
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                          Help
	aadd (_aRegsPerg, {01, "Codigo Bem         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {02, "Codigo Ate         			  ", "C", 15, 0,  "",   "ST9",    {},                             ""})
	aadd (_aRegsPerg, {03, "Data de            			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
	aadd (_aRegsPerg, {04, "Data ate           			  ", "D", 08, 0,  "",   "   ",    {},                             ""})
			
	U_ValPerg (cPerg, _aRegsPerg)
	
Return