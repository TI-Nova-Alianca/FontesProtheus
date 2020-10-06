// Programa...: VA_SZ2
// Autor......: Robert Koch
// Data.......: 07/01/2011
// Descricao..: Tela de manutencao de cadastros viticolas.
//
// Historico de alteracoes:
// 27/12/2011 - Robert - Tabela SZ2 passou a guardar cadastros viticolas
//                       em lugar de propriedades, pois estava mal modelada.
// 08/02/2012 - Robert - Aceitava registros no ZZB sem conferir se eram patriarcas.
// 26/01/2014 - Robert - Verifica inclusao em duplicidade.
// 26/01/2016 - Robert - Rotina restrita ao grupo 045 do ZZU.
// 14/12/2016 - Robert - Limpa campo ZZC_AMOSTRA quando renovar o cadastro.
// 31/10/2019 - Robert - Altera campo ZZC_AMOSTRA de C para F quando renovar o cadastro.
// 19/11/2019 - Robert - Removidos tratamentos tabela ZZB (patriarcas) pois agora usamos conceito de grupo familiar.
//                     - Criada gravacao de eventos para historico de manutencao.
//

// --------------------------------------------------------------------------
User Function VA_SZ2 ()
	local _aCores     := U_SZ2LG (.T.)
	local _sAssoc     := ""
	local _sCadVit    := ""
	local _oSQL       := NIL
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Cadastros viticolas"
	u_logini ()
	
	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	_sAssoc = U_Get ("Associado (branco = todos)", "C", 6, "", "SA2_AS", space (6), .F., '.T.')

	if ! empty (_sAssoc)
		CursorWait ()
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " SELECT DISTINCT CAD_VITICOLA"
//		_oSQL:_sQuery +=   " FROM VA_VASSOC_CAD_VITIC V"
		_oSQL:_sQuery += " SELECT DISTINCT CAD_VITIC"
		_oSQL:_sQuery +=   " FROM VA_VASSOC_CAD_VITIC2 V"
		_oSQL:_sQuery +=  " WHERE ASSOCIADO  = '" + _sAssoc + "'"
		_oSQL:Log ()
		_sCadVit = _oSQL:Qry2Str (1, '/')
		u_log (_sCadVit)
		dbselectarea ("SZ2")
		set filter to &("Z2_CADVITI$'" + _sCadVit + "'")
		CursorArrow ()
	endif

	aAdd (aRotina, {"&Pesquisar" , "AxPesqui" , 0, 1})
	aAdd (aRotina, {"&Visualizar", "AxVisual",  0, 2})
	aAdd (aRotina, {"&Incluir"   , "U_VA_SZ2I",  0, 3})
	aAdd (aRotina, {"&Alterar"   , "U_VA_SZ2B",  0, 4})
	aAdd (aRotina, {"&Excluir"   , "U_VA_SZ2E", 0, 5})
	aAdd (aRotina, {"&Renovar"   , "U_VA_SZ2R", 0, 4})
	aAdd (aRotina, {"Varie&dades", "U_VA_SZ2A ('V')", 0, 4})
//	aAdd (aRotina, {"Pa&triarcas", "U_VA_SZ2A ('P')", 0, 4})
	aAdd (aRotina, {"Consulta even&tos",    "U_VA_SZNC ('CADASTROVITICOLA', sz2 -> z2_cadviti)", 0, 4})

	aadd (aRotina, {"&Legenda"   , "U_SZ2LG (.F.)", 0,5})
	
	dbSelectArea ("SZ2")
	dbSetOrder (1)
	mBrowse(0, 0, 100, 100, "SZ2",,,,, 2, _aCores)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function SZ2LG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0

	aadd (_aCores, {"z2_safrvit <  '" + U_IniSafra () + "'", 'BR_VERMELHO', 'Nao renovado'})
	aadd (_aCores, {"z2_safrvit == '" + U_IniSafra () + "'", 'BR_VERDE',    'Renovado'})
	
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
// Incluir
user function VA_SZ2I ()
	local _oEvento := NIL

	if axinclui ("SZ2", sz2 -> (recno ()), 3, NIL, NIL, NIL, "U_VA_SZ2IK ()") == 1
		
		// Grava evento para posterior consulta
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven = 'SZ2001'
		_oEvento:Alias   = 'SZ2'
		_oEvento:CodAlias = sz2 -> z2_cadviti
		_oEvento:Texto = 'Inclusao do cadastro viticola'
		_oEvento:Grava ()
		//_oEvento:AltCadast ("SZ2", sz2 -> z2_cadviti, sz2 -> (recno ()), '', .F.)

	endif
return



// --------------------------------------------------------------------------
// Alterar
user function VA_SZ2B ()
	If axaltera ("SZ2", sz2 -> (recno ()), 4, NIL, NIL, NIL, NIL, "U_VA_SZ2IK ()") == 1
	EndIf
return



// --------------------------------------------------------------------------
// Valida 'Tudo OK' da inclusao e alteracao.
user function VA_SZ2IK ()
	local _lRet     := .T.
	
	u_logIni ()
	
	if inclui
		sz2 -> (dbsetorder (1))  // Z2_FILIAL+Z2_CADVITI
		if sz2 -> (dbseek (xfilial ("SZ2") + m->z2_cadviti, .F.))
			u_help ("Cadastro viticola ja existe.")
			_lRet = .F.
		endif
	endif

	if altera .and. _lRet
		// Grava evento para posterior consulta
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven = 'SZ2001'
		_oEvento:Alias   = 'SZ2'
		_oEvento:CodAlias = sz2 -> z2_cadviti
		_oEvento:AltCadast ("SZ2", sz2 -> z2_cadviti, sz2 -> (recno ()), '', .F.)
	endif
	u_logFim ()
return _lRet	



// --------------------------------------------------------------------------
// Exclusao total.
user function VA_SZ2E ()
	local _oSQL := ClsSQL():New ()
	local _lContinua := .T.

	_lContinua = msgyesno ("Confirma a exclusao das amarracoes deste cadastro viticola com variedades e patriarcas?")

//	if _lContinua
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += "UPDATE " + RetSQLName ("ZZB")
//		_oSQL:_sQuery += "   SET D_E_L_E_T_ = '*'"
//		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//		_oSQL:_sQuery +=   " AND ZZB_FILIAL = '" + xfilial ("ZZB") + "'"
//		_oSQL:_sQuery +=   " AND ZZB_CADVIT = '" + sz2 -> z2_cadviti + "'"
//		_lContinua = _oSQL:Exec ()
//	endif
	if _lContinua
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE " + RetSQLName ("ZZC")
		_oSQL:_sQuery += "   SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZZC_FILIAL = '" + xfilial ("ZZC") + "'"
		_oSQL:_sQuery +=   " AND ZZC_CADVIT = '" + sz2 -> z2_cadviti + "'"
		_lContinua = _oSQL:Exec ()
	endif
	if _lContinua

		// Grava evento para posterior consulta
		_oEvento := ClsEvent():new ()
		_oEvento:Texto = 'Exclusao total do cadastro viticola'
		_oEvento:CodEven = 'SZ2001'
		_oEvento:Alias   = 'SZ2'
		_oEvento:CodAlias = sz2 -> z2_cadviti
		_oEvento:Grava ()

		reclock ("SZ2", .F.)
		sz2 -> (dbdelete ())
		msunlock ()
		msginfo ("Dados excluidos.")
	endif
return



// --------------------------------------------------------------------------
// Marca o cadastro viticola como 'renovado para esta safra'.
user function VA_SZ2R ()
	local _oSQL := NIL
	reclock ("SZ2", .F.)
	sz2 -> z2_safrvit = U_IniSafra ()
	msunlock ()

	// Muda o campo de amostra para 'F' onde estava 'C' por que presumo que vai ser coletada a mesma variedade do ano passado.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSQLName ("ZZC")
	//_oSQL:_sQuery +=    " SET ZZC_AMOSTR = ' '"
	_oSQL:_sQuery +=    " SET ZZC_AMOSTR = 'F'"
	_oSQL:_sQuery +=  " WHERE ZZC_CADVIT = '" + sz2 -> z2_cadviti + "'"
	_oSQL:_sQuery +=    " and ZZC_AMOSTR = 'C'"
	if _oSQL:Exec ()
		// Grava evento para posterior consulta
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven = 'SZ2001'
		_oEvento:Alias   = 'SZ2'
		_oEvento:CodAlias = sz2 -> z2_cadviti
		_oEvento:Texto = 'Revalidacao do cadastro viticola (OK para ' + U_IniSafra () + ')'
		_oEvento:Grava ()
	endif
return



// --------------------------------------------------------------------------
// Tela de manutencao das amarracoes com outras tabelas.
user function VA_SZ2a (_sQual)
	local _aBotAdic   := {}
	local _nLinha     := 0  
	private aHeader   := {}
	private aCols     := {}
	private N         := 1
	private aGets     := {}
	private aTela     := {}
	
	inclui = .F.
	altera = .T.
	nOpc = 4
	
	// Gera aHeader e aCols.
	CursorWait ()
//	if _sQual == 'P'  // Patriarcas
//		aHeader := U_GeraHead ("ZZB", .F., {"ZZB_CADVIT"})
//		aCols := aclone (U_GeraCols ("ZZB", ;  // Alias
//		                     1, ;  // Indice:  
//		                     xfilial ("ZZB") + sz2 -> z2_cadviti, ;  // Seek inicial
//		                     'xfilial ("ZZB") + zzb -> zzb_cadvit == "' + xfilial ("ZZB") + sz2 -> z2_cadviti + '"', ;  // While
//		                     aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
//		                     .F.))  // Executa ou nao os gatilhos.
//
//		// Preenche campos virtuais
//		for N = 1 to len (aCols)
//			GDFieldPut ("ZZB_NOME", FBUSCACPO ("SA2", 1, XFILIAL ("SA2") + GDFieldGet ("ZZB_CODPAT") + GDFieldGet ("ZZB_LOJPAT"), "A2_NOME"))
//		next
//
//	elseif _sQual == 'V'  // Variedades

		aHeader := U_GeraHead ("ZZC", .F., {"ZZC_CADVIT"})
		aCols := aclone (U_GeraCols ("ZZC", ;  // Alias
		                     1, ;  // Indice:  
		                     xfilial ("ZZC") + sz2 -> z2_cadviti, ;  // Seek inicial
		                     'xfilial ("ZZC") + zzc -> zzc_cadvit == "' + xfilial ("ZZC") + sz2 -> z2_cadviti + '"', ;  // While
		                     aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
		                     .F.))  // Executa ou nao os gatilhos.

		// Preenche campos virtuais
		for _nLinha = 1 to len (aCols)
			GDFieldPut ("ZZC_DESCRI", FBUSCACPO ("SB1", 1, XFILIAL ("SB1") + GDFieldGet ("ZZC_PRODUT", _nLinha), "B1_DESC"), _nLinha)
		next
//    endif
    
	// Se nao havia nenhum dado, gera aCols com uma linha vazia.
	if len (aCols) == 0
		aCols := {}
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif
	CursorArrow ()

	// Cria botao adicional para a Modelo2
	//aadd (_aBotAdic, {"WEB", {|| U_VA_SZ2I ()},"Importa"})
	
	// Variaveis do cabecalho da tela:
	aC:={}
	aadd (aC, {"sz2 -> z2_cadviti", {15, 5},   "Cad.viticola", "", ".F.", "", .F.})
	
	aR := {}
	N = 1
	_aJanela := {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}  // Janela (dialog) do modelo2
	aCGD := {55,20,118,315}
	if Modelo2 (cCadastro, ;  // Titulo
		        aC, ;  // Cabecalho
		        aR, ;  // Rodape
		        aCGD, ;  // Coordenadas da getdados
		        nOpc, ;  // nOPC
		        'U_VA_SZ2LK ("' + _sQual + '")', ;  // Linha OK
		        "allwaystrue ()", ;  // Tudo OK
		        , ;  // Gets editaveis
		        , ;  // bloco codigo para tecla F4
		        , ;  // Campos inicializados
		        999, ;  // Numero maximo de linhas
		        _aJanela, ;  // Coordenadas da janela
		        .T., ;  // Linhas podem ser deletadas.
		        .F., ;  // .T. = Janela deve ser maximizada
		        _aBotAdic)  // Botoes adicionais.
		
		// Gravacao
		// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
		_aCposFora := {}
//		if _sQual == 'P'
//			aadd (_aCposFora, {"ZZB_FILIAL", xfilial ("ZZB")})
//			aadd (_aCposFora, {"ZZB_CADVIT", sz2 -> z2_cadviti})
//		elseif _sQual == 'V'
			aadd (_aCposFora, {"ZZC_FILIAL", xfilial ("ZZC")})
			aadd (_aCposFora, {"ZZC_CADVIT", sz2 -> z2_cadviti})
//		endif
		
		// Grava dados do aCols.
//		if _sQual == 'P'
//			zzb -> (dbsetorder (1))  // 
//			for N = 1 to len (aCols)
//				
//				// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
//				if zzb -> (dbseek (xfilial ("ZZB") + sz2 -> z2_cadviti + GDFieldGet ("ZZB_CODPAT") + GDFieldGet ("ZZB_LOJPAT"), .F.))
//					if GDDeleted ()  // Se estah deletado em aCols, preciso excluir do arquivo tambem.
//						reclock ("ZZB", .F.)
//						ZZB -> (dbdelete ())
//						msunlock ("ZZB")
//					else  // Alteracao
//						reclock ("ZZB", .F.)
//						U_GrvACols ("ZZB", N, _aCposFora)
//						msunlock ("ZZB")
//					endif
//				else  // A linha ainda nao existe no arquivo
//					if ! GDDeleted ()
//						reclock ("ZZB", .T.)
//						U_GrvACols ("ZZB", N, _aCposFora)
//						msunlock ("ZZB")
//					endif
//				endif
//			next
//
//		elseif _sQual == 'V'
			zzc -> (dbsetorder (1))  // 
			for _nLinha = 1 to len (aCols)
				
				// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
				if zzc -> (dbseek (xfilial ("ZZC") + sz2 -> z2_cadviti + GDFieldGet ("ZZC_PRODUT", _nLinha), .F.))
					if GDDeleted (_nLinha)  // Se estah deletado em aCols, preciso excluir do arquivo tambem.
						_oEvento := ClsEvent ():New ()
						_oEvento:CodEven = 'SZ2001'
						_oEvento:Alias   = 'SZ2'
						_oEvento:CodAlias = sz2 -> z2_cadviti
						_oEvento:Texto   = "Removendo variedade do cadastro viticola"
						_oEvento:Produto = zzc -> zzc_produt
						_oEvento:Grava ()

						reclock ("ZZC", .F.)
						ZZC -> (dbdelete ())
						msunlock ("ZZC")

					else  // Alteracao

						_oEvento := ClsEvent ():New ()
						_oEvento:CodEven = 'SZ2001'
						_oEvento:Alias   = 'SZ2'
						_oEvento:CodAlias = sz2 -> z2_cadviti
						_oEvento:Texto   = "Alteracao variedades do cadastro viticola" + chr (13) + chr (10)
						
						// Por enquanto, um tratamento para cada campo...
						if zzc -> zzc_ok != GDFieldGet ("ZZC_OK", _nLinha)
							_oEvento:Texto  += '<cpo>ZZC_OK</cpo>' + chr (13) + chr (10)
							_oEvento:Texto  += '<de>' + zzc -> zzc_ok + '</de>' + chr (13) + chr (10)
							_oEvento:Texto  += '<para>' + GDFieldGet ("ZZC_OK", _nLinha) + '</para>' + chr (13) + chr (10)
						endif
						if zzc -> zzc_conduc != GDFieldGet ("ZZC_CONDUC", _nLinha)
							_oEvento:Texto  += '<cpo>ZZC_CONDUC</cpo>' + chr (13) + chr (10)
							_oEvento:Texto  += '<de>' + zzc -> zzc_conduc + '</de>' + chr (13) + chr (10)
							_oEvento:Texto  += '<para>' + GDFieldGet ("ZZC_CONDUC", _nLinha) + '</para>' + chr (13) + chr (10)
						endif
						if zzc -> zzc_amostr != GDFieldGet ("ZZC_AMOSTR", _nLinha)
							_oEvento:Texto  += '<cpo>ZZC_AMOSTR</cpo>' + chr (13) + chr (10)
							_oEvento:Texto  += '<de>' + zzc -> zzc_amostr + '</de>' + chr (13) + chr (10)
							_oEvento:Texto  += '<para>' + GDFieldGet ("ZZC_AMOSTR", _nLinha) + '</para>' + chr (13) + chr (10)
						endif

						_oEvento:Produto = zzc -> zzc_produt
						_oEvento:Grava ()

						reclock ("ZZC", .F.)
						U_GrvACols ("ZZC", _nLinha, _aCposFora)
						msunlock ("ZZC")
					endif
				else  // A linha ainda nao existe no arquivo
					if ! GDDeleted (_nLinha)

						_oEvento := ClsEvent ():New ()
						_oEvento:CodEven = 'SZ2001'
						_oEvento:Alias   = 'SZ2'
						_oEvento:CodAlias = sz2 -> z2_cadviti
						_oEvento:Texto   = "Incluindo variedades no cadastro viticola"
						_oEvento:Produto = zzc -> zzc_produt
						_oEvento:Grava ()

						reclock ("ZZC", .T.)
						U_GrvACols ("ZZC", _nLinha, _aCposFora)
						msunlock ("ZZC")
					endif
				endif
			next
//		endif
	
	endif
return



// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function VA_SZ2LK (_sQual)
	local _lRet    := .T.
	local _nLinha  := 0
	local _oAssoc  := NIL
	local _oSQL    := NIL

	// Verifica campos obrigatorios
	if _lRet .and. ! GDDeleted ()
		_lRet = MaCheckCols (aHeader, aCols, N, {})
	endif
	
	// Verifica linhas duplicadas
	if _lRet .and. ! GDDeleted ()
//		if _sQual == 'P'
//			_lRet = GDCheckKey ({"ZZB_CODPAT", "ZZB_LOJPAT"}, 4)
//		elseif _sQual == 'V'
			_lRet = GDCheckKey ({"ZZC_PRODUT"}, 4)
//		endif
	endif

/*
	if _lRet .and. ! GDDeleted ()
		if _sQual == 'P'
			
			// Fornecedor deve ser ou ter sido associado.
			_oAssoc := ClsAssoc():New (GDFieldGet ("ZZB_CODPAT"), GDFieldGet ("ZZB_LOJPAT"))
			if valtype (_oAssoc) != "O"
				_lRet = .F.
			else
				if ! _oAssoc:EhSocio () .and. empty (_oAssoc:DtSaida ())
					u_help ("Fornecedor deve ser ou ter sido associado.")
					_lRet = .F.
				endif
			endif
			if _lRet
				_oSQL := ClsSQL():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT COUNT (*)"
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZ8") + " SZ8"
				_oSQL:_sQuery +=  " WHERE SZ8.D_E_L_E_T_ = ''
				_oSQL:_sQuery +=    " AND SZ8.Z8_FILIAL  = '" + xfilial ("SZ8") + "'"
				_oSQL:_sQuery +=    " AND SZ8.Z8_SAFRA   = '" + U_IniSafra () + "'"
				_oSQL:_sQuery +=    " AND SZ8.Z8_CODPAT  = '" + GDFieldGet ("ZZB_CODPAT") + "'"
				_oSQL:_sQuery +=    " AND SZ8.Z8_LOJAPAT = '" + GDFieldGet ("ZZB_LOJPAT") + "'"
				if _oSQL:RetQry () == 0
					u_help ("O codigo informado nao consta como patriarca na safra '" + U_IniSafra () + "'")
					_lRet = .F.
				endif
			endif
		endif
	endif
*/
return _lRet
