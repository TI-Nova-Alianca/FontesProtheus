// Programa:  RepMaq
// Autor:     Júlio Pedroni
// Data:      03/08/2017
// Descricao: Realiza a integração entre Ativos (1) e Recursos (10).
//            Desmembrado do AF010TOK
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function RepMaq ()
	Local _lRet     := .T.
	Local _oSQL     := NIL
	Local _aRecurso := {}
	Local _aSH1     := {}
	Local _sCodRec  := ""
	Local _sCalend  := ""
	Local Continua  := .T.
	
	//Não replica ativos que não foram configurados para utilização no Industrial.
	If Empty(M->N1_VAZX541) .and. Empty(M->N1_VAZX542) .and. Empty(M->N1_VAZX543) .and. Empty(M->N1_VAZX544)
		Continua = .F.
	EndIf
	
	If Continua .and. U_SN1INT(M->N1_GRUPO) //Se for um grupo utilizado pelo Industrial.
		_oSQL := ClsSQl():New()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select H1_CODIGO, H1_SN1COD"
		_oSQL:_sQuery += "   from " + RetSQLName("SH1")
		_oSQL:_sQuery += " where D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "   and H1_FILIAL  = '" + xFilial("SH1") + "'"
		_oSQL:_sQuery += "   and H1_SN1COD  = '" + M->N1_CBASE + "'"
		//_oSQL:_sQuery += "   and (H1_VAZX541 <> '' or H1_VAZX542 <> '' or H1_VAZX543 <> '' or H1_VAZX544 <> '')
		_aRecurso = _oSQL:Qry2Array()
		
		If Len(_aRecurso) > 1 //Se retornou mais de um registro, significa que está com problema.
			U_Help("Atenção: Integridade referencial Ativo x Recurso invalida! Verifique o ativo " + AllTrim(M->N1_CBASE) + " contra o recurso " + AllTrim(M->N1_SH1COD) + ".")
			_lRet = .F.
		EndIf
		
		_sCodRec = AllTrim(M->N1_CBASE)
		If Len(_sCodRec) > 6
			_sCodRec = SubStr(_sCodRec,(Len(_sCodRec)-5),Len(_sCodRec))
		EndIf
	
		If _lRet .and. Len(_aRecurso) == 1 //Se retornou 1 registro, deve ser alterado.
			AAdd(_aSH1,{"H1_FILIAL", AllTrim(xFilial("SH1"))})
			AAdd(_aSH1,{"H1_CODIGO", AllTrim(_sCodRec)})	
			AAdd(_aSH1,{"H1_DESCRI", AllTrim(M->N1_DESCRIC)})
			AAdd(_aSH1,{"H1_CCUSTO", AllTrim(U_SN1CCU(M->N1_CBASE))})
			AAdd(_aSH1,{"H1_SN1COD", AllTrim(M->N1_CBASE)})
			
			U_CADSH1(_aSH1,"A")
		Else //Se não retornou nenhum registro, deve ser incluído.
		
			_sCalend = "001"
		
			AAdd(_aSH1,{"H1_FILIAL" , "'" + AllTrim(xFilial("SH1")) + "'"})
			AAdd(_aSH1,{"H1_CODIGO" , "'" + AllTrim(_sCodRec) + "'"})	
			AAdd(_aSH1,{"H1_DESCRI" , "'" + left (AllTrim(M->N1_DESCRIC), 30) + "'"})
			AAdd(_aSH1,{"H1_LINHAPR", "''"})
			AAdd(_aSH1,{"H1_MAOOBRA", "''"})
			AAdd(_aSH1,{"H1_CCUSTO" , "'" + AllTrim(U_SN1CCU(M->N1_CBASE)) + "'"})
			AAdd(_aSH1,{"H1_ULTMANU", "''"})
			AAdd(_aSH1,{"H1_PERIODI", "0"})
			AAdd(_aSH1,{"H1_IDAPROV", "''"})
			AAdd(_aSH1,{"H1_CTRAB"  , "''"})
			AAdd(_aSH1,{"H1_CALEND" , "'" + AllTrim(_sCalend) + "'"})
			AAdd(_aSH1,{"H1_ILIMITA", "'N'"})
			AAdd(_aSH1,{"H1_CONF"   , "''"})
			AAdd(_aSH1,{"H1_INTERV" , "'0000'"})
			AAdd(_aSH1,{"H1_GCCUSTO", "''"})
			AAdd(_aSH1,{"H1_SN1COD" , "'" + AllTrim(M->N1_CBASE) + "'"})
			
			U_CADSH1(_aSH1,"I")
		EndIf
	EndIf
	
	
return _lRet

User Function CADSH1(_aSH1, _sAcao)
	Local _oSQL   := NIL
	Local _nRecno := 0
	
	Do Case
		Case _sAcao = "I"
			_oSQL := ClsSQl():New()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select max(R_E_C_N_O_)+1 from " + RetSQLName("SH1") //+ " where H1_FILIAL  = '" + xFilial("SH1") + "'"
			_nRecno = _oSQL:RetQry()
		
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " insert into " + RetSQLName("SH1") + "("
			_oSQL:_sQuery += "    H1_FILIAL,  "
			_oSQL:_sQuery += "    H1_CODIGO,  "	
			_oSQL:_sQuery += "    H1_DESCRI , "
			_oSQL:_sQuery += "    H1_LINHAPR, "
			_oSQL:_sQuery += "    H1_MAOOBRA, "
			//_oSQL:_sQuery += "    H1_CCUSTO,  "
			_oSQL:_sQuery += "    H1_ULTMANU, "
			_oSQL:_sQuery += "    H1_PERIODI, "
			_oSQL:_sQuery += "    H1_IDAPROV, "
			_oSQL:_sQuery += "    H1_CTRAB,   "
			_oSQL:_sQuery += "    H1_CALEND , "
			_oSQL:_sQuery += "    H1_ILIMITA, "
			_oSQL:_sQuery += "    H1_CONF,    "
			_oSQL:_sQuery += "    H1_INTERV,  "
			_oSQL:_sQuery += "    H1_GCCUSTO, "
			_oSQL:_sQuery += "    H1_SN1COD,
			_oSQL:_sQuery += "    R_E_C_N_O_,
			_oSQL:_sQuery += "    D_E_L_E_T_ )  "
			_oSQL:_sQuery += " values ( "
			_oSQL:_sQuery += U_MATSH1("H1_FILIAL", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_CODIGO", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_DESCRI", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_LINHAPR", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_MAOOBRA", _aSH1) + " , "
			//_oSQL:_sQuery += U_MATSH1("H1_CCUSTO", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_ULTMANU", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_PERIODI", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_IDAPROV", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_CTRAB", _aSH1)   + " , "
			_oSQL:_sQuery += U_MATSH1("H1_CALEND", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_ILIMITA", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_CONF", _aSH1)    + " , "
			_oSQL:_sQuery += U_MATSH1("H1_INTERV", _aSH1)  + " , "
			_oSQL:_sQuery += U_MATSH1("H1_GCCUSTO", _aSH1) + " , "
			_oSQL:_sQuery += U_MATSH1("H1_SN1COD", _aSH1)  + " , "
			_oSQL:_sQuery += AllTrim(CValToChar(_nRecno))  + " , "
			_oSQL:_sQuery += "'' ) "
			U_Log(_oSQL:_sQuery)
			_oSQL:Exec()
			
		Case _sAcao = "A"
			DbSelectArea("SH1")
			SH1 -> (DBSetorder(1))
			If SH1 -> (DbSeek(U_MATSH1("H1_FILIAL", _aSH1) + U_MATSH1("H1_CODIGO", _aSH1), .F.))
				ReClock("SH1", .F.)
				SH1 -> H1_FILIAL := U_MATSH1("H1_FILIAL", _aSH1)
				SH1 -> H1_DESCRI := U_MATSH1("H1_DESCRI", _aSH1)
				//SH1 -> H1_CCUSTO := U_MATSH1("H1_CCUSTO", _aSH1)
				SH1 -> H1_SN1COD := U_MATSH1("H1_SN1COD", _aSH1)
				MSUnlock()
			EndIf

		Case _sAcao = "E"
			U_Help("E")
			DbSelectArea("SH1")
			SH1 -> (DBSetorder(1))
			If SH1 -> (DbSeek(U_MATSH1("H1_FILIAL", _aSH1) + U_MATSH1("H1_CODIGO", _aSH1), .F.))
				ReClock("SH1", .F.)
				SH1 -> (DBDelete())
				MSUnlock()
			EndIf
	EndCase
Return

User Function SN1CCU(_sN1_CBASE)
	//Local _lContinua := .T.
	Local _oSQL      := NIL
	//Local _sCCusto   := ""
	
	_oSQL := ClsSQl():New()
	_oSQL:_sQuery := ""
	
	_oSQL:_sQuery += " select" 
	_oSQL:_sQuery += "   (select top 1 N3_CCUSTO from " + RetSQLName("SN3") + " where N3_FILIAL = " + xFilial("SN3") + " and N3_CBASE = '" + _sN1_CBASE + "' order by N3_SEQ DESC) as CCUSTO"
	_oSQL:_sQuery += "   FROM " + RetSQLName("SN1")
	_oSQL:_sQuery += " where N1_FILIAL = " + xFilial("SN1") + ' and '
	_oSQL:_sQuery += "   N1_ITEM = '   0' and "
	_oSQL:_sQuery += "   (select top 1 N3_CCUSTO from " + RetSQLName("SN3") + " where N3_FILIAL = " + xFilial("SN3") + " and N3_CBASE = '" + _sN1_CBASE + "' order by N3_SEQ DESC) > ''"
	
	_aCCusto = _oSQL:RetQry()
Return _aCCusto

User Function MATSH1(_sCampo, _aSH1)
	Local _nCont  := 0
	Local _sValor := ""
	
	For _nCont = 1 to Len(_aSH1)
		If _aSH1[_nCont, 1] = _sCampo
			_sValor = _aSH1[_nCont, 2]
			Exit 
		EndIf
	EndFor
Return _sValor

User Function SN1INT(_sN1_GRUPO)
	//Local _lContinua := .T.
	Local _oSQL      := NIL
	lOCAL _nGrupos   := 0
	
	_oSQL := ClsSQl():New()
	_oSQL:_sQuery := ""
	
	_oSQL:_sQuery += " select count(*)" 
	_oSQL:_sQuery += "   FROM " + RetSQLName("SNG")
	_oSQL:_sQuery += " where NG_FILIAL  = '" + xFilial("SNG") + "'"
	_oSQL:_sQuery += " and   NG_INDUSTR = 'S'"
	_oSQL:_sQuery += " and   NG_GRUPO   = '" + _sN1_GRUPO + "'" 
	
	_nGrupos = _oSQL:RetQry()
Return _nGrupos

/*
User Function ATFA012()
	//Local _lContinua := .T.
	If .not. inclui .and. .not. altera
		U_Help(ProcName())
		//_lContinua := .F.
	EndIf
Return
*/
