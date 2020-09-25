// Programa:   ZA8
// Autor:      Robert Koch
// Data:       16/09/2017
// Descricao:  Tela de manutencao cadastro de propriedades rurais (de associados).
// 
// Historico de alteracoes:
// 20/02/2020 - Robert - Nao valida mais talhao X carga safra (cadastros estao desatualizados, nao ajuda em nada. Vai ser passado para NaWeb)
//

// --------------------------------------------------------------------------
user function ZA8 (_sCodZAN)
	local _aCores     := U_ZA8LG (.T.)
	local _sFiltrTop  := ""
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Manutencao de propriedades rurais"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

	_sCodZAN := iif (_sCodZAN == NIL, '', _sCodZAN)

	aAdd (aRotina, {"Pesquisar"   , "AxPesqui", 0, 1})
	aAdd (aRotina, {"Visualizar"  , "AxVisual", 0, 2})
	aAdd (aRotina, {"Incluir"     , "U_ZA8IN ('" + _sCodZAN + "')", 0, 3})
	aAdd (aRotina, {"Alterar"     , "AxAltera", 0, 4})
	aAdd (aRotina, {"Excluir"     , "U_ZA8EX ()", 0, 5})
	aAdd (aRotina, {"Talhoes"     , "U_ZA8TL ()", 0, 5})
	aadd (aRotina, {"Importar KML",   "U_VA_KML('I', 'ZA8', 'ZA8_KML')", 0, 4})
	aadd (aRotina, {"Visualizar KML", "U_VA_KML('V', 'ZA8', 'ZA8_KML', 'Propr_' + za8->za8_cod)", 0, 4})
	if ! empty (_sCodZAN)
		aAdd (aRotina, {"Desvincular do grp.fam.", "U_ZA8DV ('" + _sCodZAN + "')", 0, 5})
	endif
	
	dbSelectArea ("ZA8")
	dbSetOrder (1)
	if ! empty (_sCodZAN)
		_sFiltrTop := " ZA8_COD IN (SELECT DISTINCT ZAL_IDZA8"
		_sFiltrTop +=              " FROM " + RetSQLName ("ZAL")
		_sFiltrTop +=             " WHERE D_E_L_E_T_ = ''"
		_sFiltrTop +=               " AND ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
		_sFiltrTop +=               " AND ZAL_IDZAN  = '" + _sCodZAN + "')"
		u_log (_sFiltrTop)
	endif
	mBrowse(,,,,"ZA8",,,,,2,_aCores,,,,,,,,_sFiltrTop)
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZA8LG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0
	aadd (_aCores, {"!empty (za8_kml)",   'BR_VERDE',    'Com dados KML'})
	aadd (_aCores, {"empty (za8_kml)",    'BR_VERMELHO', 'Sem dados KML'})
	
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
// Inclusao
user function ZA8IN (_sCodZAN)
	local _aArea     := {}
	private altera   := .F.
	private inclui   := .T.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	RegToMemory ("ZA8", inclui, inclui)

	// Apos a inclusao do registro, faz os tratamentos necessarios.
	if axinclui ("ZA8", za8 -> (recno ()), 3) == 1
		
		// Se foi chamado a partir do cadastro de grupos familiares, jah cria o vinculo com o mesmo
		if ! empty (_sCodZAN)
			_aArea := GetArea ()
			reclock ('ZAL', .T.)
			zal -> zal_filial = xfilial ("ZAL")
			zal -> zal_IdZAN  = _sCodZAN
			zal -> zal_IdZA8  = za8 -> za8_cod
			msunlock ()
			u_logtrb ('ZAL')
			RestArea (_aArea)
		endif
	endif
	u_logFim ()
return



// --------------------------------------------------------------------------
// Desvincula esta propriedade do grupo familiar informado.
user function ZA8DV (_sCodZAN)
	local _oSQL    := NIL
	if U_MsgNoYes ("Deseja desvincular esta propriedade rural do grupo familiar " + _sCodZAN + " ?")
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := "UPDATE " + RetSQLName ("ZAL")
		_oSQL:_sQuery +=   " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
		_oSQL:_sQuery +=   " AND ZAL_IDZAN  = '" + _sCodZAN + "'"
		_oSQL:_sQuery +=   " AND ZAL_IDZA8  = '" + za8 -> za8_cod + "'"
		_oSQL:Log ()
		_oSQL:Exec ()
	endif
return



// --------------------------------------------------------------------------
// Vincula uma propriedade ja existente ao grupo familiar informado.
user function ZA8VPE (_sCodZAN)
	local _aArea   := {}
	local _sCodZA8 := ''
	local _oSQL    := NIL

	_sCodZA8 = U_Get ('Informe codigo da propriedade a ser vinculada ao grupo familiar ' + _sCodZAN, 'C', 5, '', '', space (5), .f., '.T.')
	za8 -> (dbsetorder (1))
	if ! za8 -> (dbseek (xfilial ("ZA8") + _sCodZA8, .F.))
		u_help ("Propriedade rural nao cadastrada.")
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " SELECT count (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZAL") + " ZAL "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
		_oSQL:_sQuery +=    " AND ZAL_IDZA8  = '" + _sCodZA8 + "'"
		_oSQL:_sQuery +=    " AND ZAL_IDZAN  = '" + _sCodZAN + "'"
		if _oSQL:RetQry () > 0
			u_help ("Propriedade ja vinculada a este grupo familiar.")
		else
			_aArea := GetArea ()
			reclock ('ZAL', .T.)
			zal -> zal_filial = xfilial ("ZAL")
			zal -> zal_IdZAN  = _sCodZAN
			zal -> zal_IdZA8  = _sCodZA8
			msunlock ()
			u_logtrb ('ZAL')
			RestArea (_aArea)
		endif
	endif
return



// --------------------------------------------------------------------------
// Exclusao
User Function ZA8EX ()
	local _lContinua := .T.
	local _oSQL      := NIL
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT Z9_SEQ"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZ9")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND Z9_FILIAL  = '" + xfilial ("SZ9") + "'"
		_oSQL:_sQuery +=   " AND Z9_IDZA8   = '" + za8 -> za8_cod + "'"
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Propriedade nao pode ser excluida, pois contem os seguintes talhoes fazendo referencia a ela: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere a possibilidade de inativa-la.")
			_lContinua = .F.
		endif

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT ZF_SAFRA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZF")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZF_FILIAL  = '" + xfilial ("SZF") + "'"
		_oSQL:_sQuery +=   " AND ZF_IDZA8   = '" + za8 -> za8_cod + "'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SZE")
		_oSQL:_sQuery +=                    " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                      " AND ZE_FILIAL  = ZF_FILIAL"
		_oSQL:_sQuery +=                      " AND ZE_SAFRA   = ZF_SAFRA"
		_oSQL:_sQuery +=                      " AND ZE_CARGA   = ZF_CARGA"
		_oSQL:_sQuery +=                      " AND ZE_STATUS  IN ('C', 'D'))"  // 1=Primeira pesagem OK;2=Segunda pesagem OK;R=Recibo impresso;N=NF gerada;D=Redirecionada;C=Cancelada
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Propriedade nao pode ser excluida, pois ha cargas das seguintes safras fazendo referencia a ela: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere a possibilidade de inativa-la.")
			_lContinua = .F.
		endif
	endif

	if _lContinua

		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("ZA8", inclui, inclui)

		if AxDeleta ("ZA8", za8 -> (recno ()), 5) == 2  // Usuario confirmou

			// Elimina vinculos com grupos familiares.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "DELETE " + RetSQLName ("ZAL")
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
			_oSQL:_sQuery +=   " AND ZAL_IDZA8  = '" + M->za8_cod + "'"
			_Osql:lOG ()
			_oSQL:Exec ()
		endif
	endif                                                                                                          
return



// --------------------------------------------------------------------------
// Manutencao de talhoes ligados a propriedade.
user function ZA8TL ()
	local _lContinua  := .T.
	LOCAL _nLinha     := 0
	private aHeader   := {}
	private aCols     := {}
	private N         := 1
	private inclui    := .F.
	private altera    := .T.
	private nOpc      := 4
	private _sPropr   := ""
	private _sDescPro := ""

	u_logIni ()

	if _lContinua
		_sPropr   = za8 -> za8_cod
		_sDescPro = za8 -> za8_descri
		aHeader := aclone (U_GeraHead ("SZ9", ;  // Arquivo
		                               .F., ;    // Para MSNewGetDados, informar .T.
		                               {}, ;     // Campos a nao incluir
		                               {}, ;     // Campos a incluir
		                               .F.))     // Apenas os campos informados.

		aCols := aclone (U_GeraCols ("SZ9", ;      // Alias
		                             1, ;          // Indice
		                             xfilial ("SZ9") + _sPropr, ;  // Seek inicial
		                             "z9_filial == '" + xfilial ("SZ9") + "' .and. z9_idza8 == '" + _sPropr + "'", ;  // While
		                             aHeader, ;    // aHeader
		                             .F., ;        // Nao executa gatilhos
		                             altera, ;     // Gera linha vazia, se nao encontrar dados.
		                             .T., ;        // Trava registros
		                             '.T.'))       // Expressao para filtro adicional
		
		// Alimenta campos virtuais
		for _nLinha = 1 to len (aCols)
			GDFieldPut ("Z9_NOMEVAR", fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("Z9_IDSB1"), "B1_DESC"), _nLinha)
		next

		// Variaveis para o Modelo2
		aC   := {}
		aadd (aC, {"_sPropr",   {15, 5},   "Propriedade", "", "", "", .f.})
		aadd (aC, {"_sDescPro", {15, 100}, "Descricao",   "", "", "", .F.})
	
		aR   := {}
		aCGD := {80, 5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		N = 1
		_lContinua = Modelo2 ("Talhoes da propriedade " + _sPropr, ;  // Titulo
		                 aC, ;     // Cabecalho
		                 aR, ;     // Rodape
		                 aCGD, ;   // Coordenadas da getdados
		                 nOpc, ;   // nOPC
		                 "U_ZA8TLLK ()", ;  // Linha OK
		                 "U_ZA8TLTK ()", ;  // Tudo OK
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
		aadd (_aCposFora, {"Z9_FILIAL", xfilial ("SZ9")})
		aadd (_aCposFora, {"Z9_IDZA8", _sPropr})
		
		// Grava dados do aCols.
		zak -> (dbsetorder (1))
		for _nLinha = 1 to len (aCols)
			N = _nLinha

			// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
			if SZ9 -> (dbseek (xfilial ("SZ9") + _sPropr + GDFieldGet ("Z9_SEQ"), .F.))

				// Se estah deletado em aCols, preciso excluir do arquivo tambem.
				if GDDeleted ()
					reclock ("SZ9", .F.)
					sz9 -> (dbdelete ())
					msunlock ("SZ9")
				else  // Alteracao
					reclock ("SZ9", .F.)
					U_GrvACols ("SZ9", N, _aCposFora)
					msunlock ("SZ9")
				endif

			else  // A linha ainda nao existe no arquivo
				if GDDeleted ()
					loop
				else
					reclock ("SZ9", .T.)
					U_GrvACols ("SZ9", N, _aCposFora)
					msunlock ("SZ9")
				endif
			endif
		next
	endif
	sz9 -> (dbgotop ())
	u_logFim ()
return



// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function ZA8TLLK ()
	local _lRet := .T.
	local _oSQL := NIL

	if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"Z9_SEQ"}, 4, {}, "Campos repetidos", .t.)
	endif

/*
	if _lRet .and. GDDeleted ()
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT DISTINCT ZF_SAFRA"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZF")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZF_FILIAL  = '" + xfilial ("SZF") + "'"
		_oSQL:_sQuery +=   " AND ZF_IDZA8   = '" + za8 -> za8_cod + "'"
		_oSQL:_sQuery +=   " AND ZF_IDSZ9   = '" + GDFieldGet ('Z9_SEQ') + "'"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM " + RetSQLName ("SZE")
		_oSQL:_sQuery +=                    " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                      " AND ZE_FILIAL  = ZF_FILIAL"
		_oSQL:_sQuery +=                      " AND ZE_SAFRA   = ZF_SAFRA"
		_oSQL:_sQuery +=                      " AND ZE_CARGA   = ZF_CARGA"
		_oSQL:_sQuery +=                      " AND ZE_STATUS  IN ('C', 'D'))"  // 1=Primeira pesagem OK;2=Segunda pesagem OK;R=Recibo impresso;N=NF gerada;D=Redirecionada;C=Cancelada
		_oSQL:Log ()
		if ! empty (_oSQL:Qry2Str (1, ', '))
			u_help ("Talhao nao pode ser excluido desta propriedade, pois ha cargas das seguintes safras fazendo referencia a ela: " + _oSQL:_xRetQry + chr (13) + chr (10) + "Considere a possibilidade de inativa-lo.")
			_lRet = .F.
		endif
	endif
*/
return _lRet



// --------------------------------------------------------------------------
// Valida 'Tudo OK' da getdados
User Function ZA8TLTK ()
	local _lRet   := .T.
return _lRet
