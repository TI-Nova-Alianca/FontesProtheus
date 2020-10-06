// Programa:   ZAN
// Autor:      Robert Koch
// Data:       16/09/2017
// Descricao:  Tela de manutencao cadastro de grupos familiares.
// 
// Historico de alteracoes:
// 01/11/2019 - Robert - Nao permitia salvar quando deletava todas as linhas do aCols de associados.
//                     - Valida se o associado vai ficar sem menhum grupo familiar.
//                     - Valida campo ZAK_GRPPRI.
//

// --------------------------------------------------------------------------
user function ZAN ()
	local _aCores     := U_ZANLG (.T.)
	local _aRotZZL    := {}
	local _aRotZA8    := {}
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Manutencao de grupos familiares"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	// Submenu de rotinas especificas para cadernos de campo.
	//aadd (_aRotZZL, {"Gerar novos cadernos",      "U_ZZLG (zan -> zan_cod)",  0, 2})
	aadd (_aRotZZL, {"Manut.cadernos existentes", "U_ZZL  (zan -> zan_cod)",  0, 4})
	aadd (_aRotZZL, {"Copiar safra anterior",     "U_ZZLCA (zan -> zan_cod)", 0, 2})

	aadd (_aRotZA8, {"Manut.propried.existentes", "U_ZA8 (zan -> zan_cod)",  0, 4})
	aadd (_aRotZA8, {"Vincular nova propriedade", "U_ZA8VPE (zan -> zan_cod)",  0, 2})

	aAdd (aRotina, {"Pesquisar",         "AxPesqui",   0, 1})
	aAdd (aRotina, {"Visualizar",        "AxVisual",   0, 2})
	aAdd (aRotina, {"Incluir",           "AxInclui",   0, 3})
	aAdd (aRotina, {"Alterar",           "AxAltera",   0, 4})
	aAdd (aRotina, {"Excluir",           "U_ZANEX ()", 0, 5})
	aAdd (aRotina, {"Associados",        "U_ZANAS ()", 0, 4})
	aAdd (aRotina, {"Propr.rurais",      _aRotZA8,     0, 4})
	aadd (aRotina, {"Cadernos de campo", _aRotZZL,     0, 4})
	aadd (aRotina, {"Importar KML",      "U_VA_KML('I', 'ZAN', 'ZAN_KML')", 0, 4})
	aadd (aRotina, {"Visualizar KML",    "U_VA_KML('V', 'ZAN', 'ZAN_KML', 'GrpFam_' + zan->zan_cod)", 0, 4})
	
	dbSelectArea ("ZAN")
	dbSetOrder (1)
	mBrowse(,,,,"ZAN",,,,, 2, _aCores)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZANLG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"!empty (zan_kml)",   'BR_VERDE',    'Com dados KML'})
	aadd (_aCores, {"empty (zan_kml)",    'BR_VERMELHO', 'Sem dados KML'})
	
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return



// --------------------------------------------------------------------------
// Exclusao
User Function ZANEX ()
	local _lContinua := .T.
	local _oSQL      := NIL
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT ZAL_IDZA8"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAL") + " ZAL "
		_oSQL:_sQuery += " WHERE ZAL.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZAL.ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
		_oSQL:_sQuery +=   " AND ZAL.ZAL_IDZAN  = '" + zan -> zan_cod + "'"
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Grupo familiar nao pode ser excluido, pois as seguintes propriedades rurais fazem referencia a ele: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere mudar o status do grupo para inativo.")
			_lContinua = .F.
		endif

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT ZAK_ASSOC + '/' + ZAK_LOJA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAK")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZAK_FILIAL = '" + xfilial ("ZAK") + "'"
		_oSQL:_sQuery +=   " AND ZAK_IDZAN  = '" + zan -> zan_cod + "'"
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Grupo familiar nao pode ser excluido, pois os seguintes associados fazem referencia a ele: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere mudar o status do grupo para inativo.")
			_lContinua = .F.
		endif

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT 'SAFRA ' + ZZL_SAFRA + ' / CADERNO ' + ZZL_COD"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZL") + " ZZL "
		_oSQL:_sQuery += " WHERE ZZL.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZL.ZZL_FILIAL = '" + xfilial ("ZZL") + "'"
		_oSQL:_sQuery +=   " AND ZZL.ZZL_IDZAN  = '" + zan -> zan_cod + "'"
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Grupo familiar nao pode ser excluido, pois os seguintes cadernos de campo fazem referencia a ele: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere mudar o status do grupo para inativo.")
			_lContinua = .F.
		endif
	endif

	if _lContinua

		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("ZAN", inclui, inclui)

		AxDeleta ("ZAN", zan -> (recno ()), 5)
	endif                                                                                                          
return



// --------------------------------------------------------------------------
// Manutencao de associados ligados ao grupo familiar
user function ZANAS ()
	local _lContinua  := .T.
	local _nLinha     := 0
	private aHeader   := {}
	private aCols     := {}
	private N         := 1
	private inclui    := .F.
	private altera    := .T.
	private nOpc      := 4
	private _sGrpFam  := ""
	private _sNomeGrp := ""

	u_logIni ()

	if _lContinua
		_sGrpFam  = zan -> zan_cod
		_sNomeGrp = zan -> zan_descri
		aHeader := aclone (U_GeraHead ("ZAK", ;     // Arquivo
		                               .F., ;       // Para MSNewGetDados, informar .T.
		                               {}, ;        // Campos a nao incluir
		                               {'ZAK_ASSOC', 'ZAK_LOJA', 'ZAK_NASSOC', 'ZAK_TIPORE', 'ZAK_GRPPRI'}, ;  // Campos a incluir
		                               .T.))        // Apenas os campos informados.
		
		aCols := aclone (U_GeraCols ("ZAK", ;      // Alias
		                             1, ;          // Indice
		                             xfilial ("ZAK") + _sGrpFam, ;  // Seek inicial
		                             "zak_filial == '" + xfilial ("ZAK") + "' .and. zak_idzan == '" + _sGrpFam + "'", ;  // While
		                             aHeader, ;    // aHeader
		                             .F., ;        // Nao executa gatilhos
		                             altera, ;     // Gera linha vazia, se nao encontrar dados.
		                             .T., ;        // Trava registros
		                             '.T.'))       // Expressao para filtro adicional
		
		// Alimenta campos virtuais
		for _nLinha = 1 to len (aCols)
			GDFieldPut ("ZAK_NASSOC", fBuscaCpo ("SA2", 1, xfilial ("SA2") + GDFieldGet ("ZAK_ASSOC", _nLinha) + GDFieldGet ("ZAK_LOJA", _nLinha), "A2_NOME"), _nLinha)
		next

		// Variaveis para o Modelo2
		aC   := {}
		aadd (aC, {"_sGrpFam",  {15, 5},   "Grupo fam",  "", "", "", .f.})
		aadd (aC, {"_sNomeGrp", {15, 100}, "Descricao",  "", "", "", .F.})
	
		aR   := {}
		aCGD := {80, 5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		N = 1
		_lContinua = Modelo2 ("Associados ligados ao grupo familiar " + _sGrpFam, ;  // Titulo
		                 aC, ;     // Cabecalho
		                 aR, ;     // Rodape
		                 aCGD, ;   // Coordenadas da getdados
		                 nOpc, ;   // nOPC
		                 "U_ZANASLK ()", ;  // Linha OK
		                 "U_ZANASTK ()", ;  // Tudo OK
		                 , ;       // Gets editaveis
		                 , ;       // bloco codigo para tecla F4
		                 , ;       // Campos inicializados
		                 999, ;    // Numero maximo de linhas
		                 {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}, ;  // Coordenadas da janela
		                 .T.)      // Linhas podem ser deletadas.
	
	endif

	if _lContinua

		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
		aadd (_aCposFora, {"ZAK_FILIAL", xfilial ("ZAK")})
		aadd (_aCposFora, {"ZAK_IDZAN", _sGrpFam})
		
		// Grava dados do aCols.
		zak -> (dbsetorder (1))
		for _nLinha = 1 to len (aCols)
			N = _nLinha

			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if ZAK -> (dbseek (xfilial ("ZAK") + _sGrpFam + GDFieldGet ("ZAK_ASSOC") + GDFieldGet ("ZAK_LOJA") , .F.))

				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted ()
					reclock ("ZAK", .F.)
					zak -> (dbdelete ())
					msunlock ("ZAK")
				else  // Alteracao
					reclock ("ZAK", .F.)
					U_GrvACols ("ZAK", N, _aCposFora)
					msunlock ("ZAK")
				endif

			else  // A linha ainda nao existe no arquivo
				if GDDeleted ()
					loop
				else
					reclock ("ZAK", .T.)
					U_GrvACols ("ZAK", N, _aCposFora)
					msunlock ("ZAK")
				endif
			endif
		next
	endif
	zak -> (dbgotop ())
	u_logFim ()
return



// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function ZANASLK ()
	local _lRet      := .T.
	local _oAssoc    := NIL
	local _oSQL      := NIL
	local _aGrpPrin  := {}

	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZAK_ASSOC", "ZAK_LOJA"}, 4, {}, "Campos repetidos", .t.)
	endif

	if _lRet .and. ! GDDeleted ()
		_oAssoc := ClsAssoc ():New (GDFieldGet ("ZAK_ASSOC"), GDFieldGet ("ZAK_LOJA"), .T.)
		if _oAssoc == NIL
			u_help ("Fornecedor " + GDFieldGet ("ZAK_ASSOC") + "/" + GDFieldGet ("ZAK_LOJA") + " nao consta como associado.")
			_lRet = .F.
		endif
		if _lRet .and. ! empty (_oAssoc:DtFalecim)
			u_help ("Associado falecido em " + dtoc (_oAssoc:DtFalecim))
			_lRet = .F.
		endif
		if _lRet .and. ! _oAssoc:Ativo ()
			_lRet = u_msgnoyes ("Associado " + GDFieldGet ("ZAK_ASSOC") + "/" + GDFieldGet ("ZAK_LOJA") + " encontra-se inativo. Confirma assim mesmo?")
		endif
	endif

	if _lRet .and. GDDeleted ()
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAK")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZAK_FILIAL = '" + xfilial ("ZAK") + "'"
		_oSQL:_sQuery +=   " AND ZAK_IDZAN != '" + _sGrpFam + "'"
		_oSQL:_sQuery +=   " AND ZAK_ASSOC  = '" + GDFieldGet ("ZAK_ASSOC") + "'"
		_oSQL:_sQuery +=   " AND ZAK_LOJA   = '" + GDFieldGet ("ZAK_LOJA") + "'"
		//_oSQL:Log ()
		if _oSQL:RetQry () == 0
			_lRet = U_MsgNoYes ("Associado " + GDFieldGet ("ZAK_ASSOC") + " - " + alltrim (GDFieldGet ("ZAK_NASSOC")) + " vai ficar sem nenhum grupo familiar. Confirma assim mesmo?")
		endif
	endif

	if _lRet .and. ! GDDeleted ()
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ISNULL (SUM (CASE WHEN ZAK_GRPPRI = 'S' THEN 1 ELSE 0 END), 0), "
		_oSQL:_sQuery +=       " ISNULL (SUM (CASE WHEN ZAK_GRPPRI != 'S' THEN 1 ELSE 0 END), 0) "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAK")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZAK_FILIAL = '" + xfilial ("ZAK") + "'"
		_oSQL:_sQuery +=   " AND ZAK_IDZAN != '" + _sGrpFam + "'"
		_oSQL:_sQuery +=   " AND ZAK_ASSOC  = '" + GDFieldGet ("ZAK_ASSOC") + "'"
		_oSQL:_sQuery +=   " AND ZAK_LOJA   = '" + GDFieldGet ("ZAK_LOJA") + "'"
		//_oSQL:Log ()
		_aGrpPrin = aclone (_oSQL:Qry2Array (.F., .F.) [1])
		if _aGrpPrin [1] > 0 .and. GDFieldGet ("ZAK_GRPPRI") == 'S'
			u_help ("Associado ja tem outro grupo familiar definido como 'grupo principal'.")
			_lRet = .F.
		elseif _aGrpPrin [2] > 0 .and. GDFieldGet ("ZAK_GRPPRI") != 'S'
			u_help ("Associado ja tem vinculo com outro(s) " + cvaltochar (_aGrpPrin [2]) + " grupo(s) familiar(es), mas nenhum foi selecionado como 'grupo principal'. Voce pode selecionar o grupo atual como principal, ou, antes de incluir o associado aqui, setar um dos outros grupos como principal.")
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Valida 'Tudo OK' da getdados
User Function ZANASTK ()
	local _lRet      := .T.
	local _nLinha    := 0
	local _nQtPrinc  := 0
	local _lTodosDel := .F.

	_nQtPrinc = 0
	for _nLinha = 1 to len (aCols)
		if ! GDDeleted (_nLinha) .and. GDFieldGet ("ZAK_TIPORE", _nLinha) == '1'
			_nQtPrinc ++
		endif
	next
	_lTodosDel = .T.
	for _nLinha = 1 to len (aCols)
		if ! GDDeleted (_nLinha)
			_lTodosDel = .F.
		endif
	next
	if ! _lTodosDel .and. _nQtPrinc != 1
		u_help ("Deve haver 1 e apenas 1 associado selecionado como contato principal.")
		_lRet = .F.
	endif
return _lRet

