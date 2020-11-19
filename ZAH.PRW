// Programa...: ZAH
// Autor......: Júlio Pedroni
// Data.......: 21/03/2017
// Descricao..: Tela de manutencao de Células de Produção.
//
// Historico de alteracoes:
// 20/06/2017 - Incluído campo para informar caledário da célula.
//

// --------------------------------------------------------------------------
User Function ZAH ()
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Células de Produção"
	private _wFiltro  := "" 

	aAdd(aRotina, {"Pesquisar",  "AxPesqui" , 0, 1})
	aAdd(aRotina, {"Visualizar", "U_ZAHA", 0, 2})
	aAdd(aRotina, {"Incluir"  ,  "U_ZAHA", 0, 3})
	aAdd(aRotina, {"Alterar"  ,  "U_ZAHA", 0, 4})
	aAdd(aRotina, {"Excluir"  ,  "U_ZAHE", 0, 5})

	_wfiltro := U_FILZAH() 
	dbSelectArea ("ZAH")
	dbSetOrder (1)
	mBrowse(,,,,"ZAH",,,,,2,,,,,,,,,_wfiltro)
	//MBrowse(,,,,"SA2",,,,, ,,,,,,,,,cExprFilTop)
return

// --------------------------------------------------------------------------
// Tela de manutencao
user function ZAHA ()
	//local   _aUser   := {}
	Local   _aRotAdic := {}
	private _sCelula := ""
	private _sDescri := ""
	private _nProNom := 0
	private _sCenCus := ""
	private _sCenDes := ""
	private _sCalCod := ""
	private _sCalDes := ""
	private _dPeoIni := CtoD("")
	private _dPeoFim := CtoD("")
	private aHeader  := {}
	private aCols    := {}
	private N        := 1
	private aGets    := {}
	private aTela    := {}
	private nLinha   := 0
	private nBorda   := 0
	private nCampo   := 0
	private nAltCpo  := 0

	nOpc := 2
	if inclui .or. altera
		nOpc = 4
		aAdd(_aRotAdic, {"FORM", {|| U_ZAHB() }, "Selecionar Maquinas", "Selecionar Maquinas"})
	endif

	if inclui
		_sCelula = CriaVar ("ZAH_CELCOD")
		_sDescri = CriaVar ("ZAH_CELDES")
		_nProNom = CriaVar ("ZAH_PRONOM")
		_sCenCus = CriaVar ("ZAH_CENCUS")
		_sCalCod = CriaVar ("ZAH_SH7COD")
		_dPeoIni = CriaVar ("ZAH_PEOINI")
		_dPeoFim = CriaVar ("ZAH_PEOFIM")
	else
		_sCelula = ZAH -> ZAH_CELCOD
		_sDescri = ZAH -> ZAH_CELDES
		_nProNom = ZAH -> ZAH_PRONOM
		_sCenCus = ZAH -> ZAH_CENCUS
		_sCalCod = ZAH -> ZAH_SH7COD
		_dPeoIni = ZAH -> ZAH_PEOINI
		_dPeoFim = ZAH -> ZAH_PEOFIM
	endif
	U_ZAHDCC()
	U_ZAHDCA()

	// Gera aHeader e aCols.
	aHeader := U_GeraHead ("ZAH", .F., {"ZAH_CELCOD", "ZAH_CELDES", "ZAH_PRONOM", "ZAH_CENCUS", "ZAH_CENDES", "ZAH_SH7COD", "ZAH_SH7DES", "ZAH_PEOINI", "ZAH_PEOFIM"})
	aCols   := {}
	if ! inclui
		ZAH -> (dbseek (xFilial("ZAH") + _sCelula, .T.))
		do while ! ZAH -> (eof ()) .and. ZAH->ZAH_FILIAL == xFilial("ZAH") .and. ZAH->ZAH_CELCOD == _sCelula
			aadd (aCols, aclone (U_LinVazia (aHeader)))
			N := Len(aCols)
			GDFieldPut ("ZAH_SEQMAQ", ZAH->ZAH_SEQMAQ)
			GDFieldPut ("ZAH_BEMCOD", ZAH->ZAH_BEMCOD)
			GDFieldPut ("ZAH_BEMDES", FBuscaCPO("SN1",1,XFilial("SN1")+GDFieldGet("ZAH_BEMCOD"),"N1_DESCRIC"))
			GDFieldPut ("ZAH_RECNO" , ZAH->(recno()))
			ZAH -> (dbskip ())
		enddo
		ASort(aCols,,,{|_x,_y|_x[GDFieldPos("ZAH_SEQMAQ")]<_y[GDFieldPos("ZAH_SEQMAQ")]})
	else
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif
	
	N := 1


	// Variaveis do cabecalho da tela:
	aC:={}
	
	//===Controle de Campos e Tela===//
	nLinha   = 0
	nBorda   = 2
	nAltCpo  = 15
	nLinha  += 1
	//===//
	
	nCampo  = nBorda + (nLinha * nAltCpo)
	aadd (aC, {"_sCelula", {nCampo, 5},  "Celula",           "@!", "!Vazio() .and. ExistChav('ZAH')", "", inclui})
	aadd (aC, {"_sDescri", {nCampo, 55}, "Descricao",        "@!", "!Vazio()", "", .T.})
	nLinha += 1
	nCampo  = nBorda + (nLinha * nAltCpo)
	aadd (aC, {"_nProNom", {nCampo, 5},  "Prod. Nominal (h)","@E 999,999,999", "", "", .T.})
	aadd (aC, {"_sCenCus", {nCampo, 105},"Centro de Custo",  "@!", "!Vazio() .and. (Ctb105CC() .and. U_ZAHDCC())", "CTT", .T.})
	aadd (aC, {"_sCenDes", {nCampo, 200}, "", "@!", "","", .F.})
	nLinha += 1
	nCampo  = nBorda + (nLinha * nAltCpo)
	aadd (aC, {"_sCalCod", {nCampo, 5},"Calendario", "@!", "!Vazio() .and. U_ZAHDCA()", "SH7", .T.})
	aadd (aC, {"_sCalDes", {nCampo, 60}, "", "@!", "", "", .F.})
	aadd (aC, {"_dPeoIni", {nCampo, 255},"Periodo de Operacao", "@D", "", "", .T.})
	aadd (aC, {"_dPeoFim", {nCampo, 355},"ate ", "@D", "", "", .T.})
	
	//===Altura do Cabecalho===//
	nCampo = (nBorda * nLinha * 3) + (nLinha * nAltCpo * 2)
	//===//
	
	aR := {}
	_aJanela := {200, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}  // Janela (dialog) do modelo2
	aCGD := {nCampo,20,118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		aC, ;  // Cabecalho
		aR, ;  // Rodape
		aCGD, ;  // Coordenadas da getdados
		nOpc, ;  // nOPC
		'U_ZAHLK ()', ;  // Linha OK
		'U_ZAHTK ()', ;  // Tudo OK
		, ;  // Gets editaveis
		, ;  // bloco codigo para tecla F4
		, ;  // Campos inicializados
		9999, ;  // Numero maximo de linhas
		_aJanela, ;
		, ;
		.T., ;
		_aRotAdic)
		
		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZAH_FILIAL", xfilial ("ZAH")})
		aadd (_aCposFora, {"ZAH_CELCOD", _sCelula})
		aadd (_aCposFora, {"ZAH_CELDES", _sDescri})
		aadd (_aCposFora, {"ZAH_PRONOM", _nProNom})
		aadd (_aCposFora, {"ZAH_CENCUS", _sCenCus})
		aadd (_aCposFora, {"ZAH_SH7COD", _sCalCod})
		aadd (_aCposFora, {"ZAH_PEOINI", _dPeoIni})
		aadd (_aCposFora, {"ZAH_PEOFIM", _dPeoFim})

		// Grava dados do aCols.
		ZAH -> (dbsetorder (1))  // ZAH_FILIAL + ZAH_CELCOD + ZAH_USER
		for N = 1 to len (aCols)
			if !Empty(GDFieldGet("ZAH_BEMCOD"))
				if GDFieldGet("ZAH_RECNO") > 0
					ZAH -> (dbgoto (GDFieldGet ("ZAH_RECNO")))
					// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
					// Se estah deletado em aCols, preciso excluir do arquivo tambem.
					if GDDeleted ()
						reclock ("ZAH", .F.)
						ZAH -> (dbdelete ())
						msunlock ("ZAH")
					else  // Alteracao
						reclock ("ZAH", .F.)
						U_GrvACols ("ZAH", N, _aCposFora)
						msunlock ("ZAH")
					endif
	
				else  // A linha ainda nao existe no arquivo
					if GDDeleted ()
						loop
					else
						reclock ("ZAH", .T.)
						U_GrvACols ("ZAH", N, _aCposFora)
						msunlock ("ZAH")
					endif
				endif
			endif
		next
	endif
return

// --------------------------------------------------------------------------
// Exclusao total.
user function ZAHE ()
	//local _aArea     := getarea ()
	local _sCelula   := ZAH -> ZAH_CELCOD
	local _oSQL      := NIL
	local _sRetSQL   := ""
	local _lContinua := .T.
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT B1_COD"
	_oSQL:_sQuery += "   FROM " + RetSQLName ("SB1")
	_oSQL:_sQuery += "   WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "   AND B1_CELCOD   = " + _sCelula
	_sRetSQL = _oSQL:Qry2Str (1, ',')
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	_sRetSQL = StrTran(_sRetSQL,"  "," ")
	if .not. Empty(_sRetSQL)
		U_Help ("Celula esta vinculada ao(s) produto(s): " + chr (13) + chr (10) + AllTrim(_sRetSQL))
		_lContinua = .F.
	endif

	if _lContinua .and. u_msgyesno ("Confirma a exclusao da celula e relacionamentos com maquinas?")
		ZAH -> (dbsetorder (1))  // ZAH_FILIAL + ZAH_CELCOD + ZAH_BEMCOD
		ZAH -> (dbseek (xfilial ("ZAH") + _sCelula, .T.))
		do while ! ZAH -> (eof ()) .and. ZAH -> ZAH_filial == xfilial ("ZAH") .and. ZAH -> ZAH_CELCOD == _sCelula
			reclock ("ZAH", .F.)
			ZAH -> (dbdelete ())
			msunlock ()
			ZAH -> (dbskip ())
		enddo
		u_help ("Dados excluidos.")
	endif
return

// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function ZAHLK ()
	local _lRet    := .T.
	//local _nLinha  := 0

	// Verifica campos obrigatorios
	if _lRet .and. ! GDDeleted ()
		_lRet = MaCheckCols (aHeader, aCols, N, {})
	endif

	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZAH_BEMCOD"}, 4)
	endif
return _lRet

// --------------------------------------------------------------------------
// Validacao de 'Tudo OK'
user function ZAHTK ()
	local _lRet    := .T.
	if empty (_sCelula) .or. empty (_sDescri)
		u_help ("Campos do cabecalho devem ser informados")
		_lRet = .F.
	endif
return _lRet
//

// --------------------------------------------------------------------------
// Selecionar maquinas.
user function ZAHB ()
	local _lContinua := .T.
	local _oSQL      := NIL
	local _aCCusto   := {}
	local _nCCusto   := 0
	local _aCols     := {}

	if _lContinua 
		if Empty(_sCenCus)
			u_help("Centro de Custo nao informado.")
		else
			_oSQL := ClsSQl ():New ()
			_oSQL:_sQuery := ""
			
			_oSQL:_sQuery += " SELECT" 
			_oSQL:_sQuery += "	 '' AS OK," 
			_oSQL:_sQuery += "	 N1_CBASE AS MAQUINA,"
			_oSQL:_sQuery += "	 N1_DESCRIC AS DESCRICAO,"
			_oSQL:_sQuery += "	 (SELECT TOP 1 N3_CCUSTO FROM " + RetSQLName ("SN3") + " WHERE N3_FILIAL = " + xFilial("SN3") + " AND N3_CBASE = N1_CBASE AND N3_CCUSTO = '" + _sCenCus + "' ORDER BY N3_SEQ DESC) AS CCUSTO"
			_oSQL:_sQuery += " FROM " + RetSQLName ("SN1")
			_oSQL:_sQuery += " WHERE N1_FILIAL = " + xFilial("SN1") + ' AND '
			_oSQL:_sQuery += " N1_ITEM = '   0' AND "
			_oSQL:_sQuery += "	 (SELECT TOP 1 N3_CCUSTO FROM " + RetSQLName ("SN3") + " WHERE N3_FILIAL = " + xFilial("SN3") + " AND N3_CBASE = N1_CBASE AND N3_CCUSTO = '" + _sCenCus + "' ORDER BY N3_SEQ DESC) > ''"
			
			U_Log(_oSQL:_sQuery)
			_aCCusto = aclone(_oSQL:Qry2Array())
			
			// Inicializa coluna de selecao com .F. ('nao selecionada').
			for _nCCusto = 1 to len (_aCCusto)
				_aCCusto[_nCCusto, 1] = .F.
			next	
			
			_aCols = {}
			aadd (_aCols, {2, 'Maquina'  , 20, ''})
			aadd (_aCols, {3, 'Descricao', 70, ''})
			aadd (_aCols, {4, 'C.Custo'  , 20, ''})
			
			U_MBArray (@_aCCusto, 'Selecione as maquinas da celula', _aCols, 1)
			U_Log(_aCCusto)
			
			for _nCCusto = 1 to len(_aCCusto)
				if _aCCusto[_nCCusto, 1] .and. AScan(aCols,{|_x|_x[GDFieldPos("ZAH_BEMCOD")]==_aCCusto[_nCCusto, 2]}) = 0
					if U_ZAHVAL(_aCCusto[_nCCusto, 2])
						N := Len(aCols)
						if .not. Empty(GDFieldGet("ZAH_SEQMAQ")) .or. .not. Empty(GDFieldGet("ZAH_BEMCOD"))
						 	_nSeq := GDFieldGet("ZAH_SEQMAQ")
							aadd (aCols, aclone (U_LinVazia (aHeader)))
						else
						 	_nSeq := 0
						endif
						N := Len(aCols)
						GDFieldPut ("ZAH_SEQMAQ", _nSeq+10)
						GDFieldPut ("ZAH_BEMCOD", _aCCusto[_nCCusto, 2])
						GDFieldPut ("ZAH_BEMDES", _aCCusto[_nCCusto, 3])
					endif
				endif
			next
			
			xObj := CallMod2Obj()
			xObj:oBrowse:Refresh()
		endif
	endif
return

user function ZAHDCC()
	_sCenDes = fBuscaCpo ("CTT", 1, xfilial ("CTT") + _sCenCus, "CTT_DESC01")
return .T.

user function ZAHDCA()
	_sCalDes = fBuscaCpo ("SH7", 1, xfilial ("SH7") + _sCalCod, "H7_DESCRI")
return .T.

user function FILZAH()
	local _oSQL := NIL
	local _aFil := NIL
	local _nFil := 0
	local _cFil := ""

	_oSQL := ClsSQl ():New ()
	_oSQL:_sQuery := ""
	
	_oSQL:_sQuery += "SELECT MIN(R_E_C_N_O_) FROM " + RetSQLName ("ZAH") + " WHERE D_E_L_E_T_ = '' GROUP BY ZAH_CELCOD" 
	_aFil = aclone(_oSQL:Qry2Array ())
	
	//Monta Filtro
	_cFil := "R_E_C_N_O_ IN (-1"
	for _nFil = 1 to len (_aFil)
		_cFil += ", " + alltrim(cvaltochar(_aFil[_nFil, 1]))  
	next
	_cFil += ")"  
return _cFil

user function ZAHVAL(_cBemCod)
	local _lRet := .T.
	
	//SN1 -> (dbsetorder (1))
	//SN1 -> (dbseek (xfilial ("SN1") + _cBemCod, .F.))
	//if Empty(SN1->N1_VAZX541) .or.Empty(SN1->N1_VAZX542) .or. Empty(SN1->N1_VAZX543) .or. Empty(SN1->N1_VAZX544)
	//	U_Help ("Ativo/Maquina " + AllTrim(_cBemCod) + " nao configurada.")
	//	_lRet = .F.
	//else
		if ! SNG -> (dbseek (xfilial ("SNG") + SN1->N1_GRUPO, .F.)) 
			U_Help ("Grupo de Bens " + AllTrim(SN1->N1_GRUPO) + " nao cadastrado.")
			_lRet = .F.
		endif
	//endif	
return _lRet
