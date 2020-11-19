// Programa:   ZZL
// Autor:      Robert Koch
// Data:       01/11/2017
// Descricao:  Tela de manutencao cadastro de cadernos de campo.
// 
// Historico de alteracoes:
// 21/01/2019 - Robert - Criada opcao de inclusao manual (antes tinhamos apenas importacao de planilha).
//

// --------------------------------------------------------------------------
user function ZZL (_sGrupoFam)
	private aRotina   := {}  // Opcoes do menu
	private cCadastro := "Manutencao de cadernos de campo"
	private _sGrpFam  := iif (_sGrupoFam == NIL, '', _sGrupoFam)

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

	aAdd (aRotina, {"Pesquisar",    "AxPesqui",   0, 1})
	aAdd (aRotina, {"Visualizar",   "AxVisual",   0, 2})
	aAdd (aRotina, {"Incluir",      "U_ZZLI ()",  0, 3})
	aAdd (aRotina, {"Alterar",      "U_ZZLA ()",  0, 4})
	aAdd (aRotina, {"Excluir",      "U_ZZLEX ()", 0, 5})
	aadd (aRotina, {"Vitic/varied", "U_ZZLVit()", 0, 4})

	if ! empty (_sGrpFam)
		_sFiltrTop := "ZZL_IDZAN='" + _sGrpFam + "'"
	endif
	mBrowse(,,,,"ZZL",,,,,2,,,,,,,,,_sFiltrTop)
return



// --------------------------------------------------------------------------
// Exclusao
User Function ZZLEX ()
	local _lContinua := .T.
	local _oSQL      := NIL
	private altera   := .F.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}

	if _lContinua

		// Cria variaveis M->... para a enchoice (a funcao nao cria sozinha)
		RegToMemory ("ZZL", inclui, inclui)

		if AxDeleta ("ZZL", zzl -> (recno ()), 5) == 2

			// Remove vinculos com cad. viticola X variedades
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := "UPDATE " + RetSQLName ("ZAS")
			_oSQL:_sQuery +=   " SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_"
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZAS_FILIAL = '" + xfilial ("ZAS") + "'"
			_oSQL:_sQuery +=   " AND ZAS_IDZAN  = '" + zzl -> zzl_idZAN + "'"
			_oSQL:_sQuery +=   " AND ZAS_SAFRA  = '" + zzl -> zzl_safra + "'"
			_oSQL:_sQuery +=   " AND ZAS_IDZZL  = '" + zzl -> zzl_cod + "'"
			_oSQL:Log ()
			if ! _oSQL:Exec ()
				reclock ("ZZL", .F.)
				zzl -> (dbrecall ())
				msunlock ()
			endif
		endif
	endif                                                                                                          
return



// --------------------------------------------------------------------------
// Alteracao
user function ZZLA ()
	//local _aArea     := {}
	//local _aBotAdic  := {}
	private altera   := .T.
	private inclui   := .F.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	// RegToMemory ("ZZL", inclui, inclui)

	if AxAltera ("ZZL", zzl->(Recno ()), 4, NIL, NIL, NIL, NIL, "U_ZZL_TOk ()") == 1
	endif

	u_logFim ()
return



// --------------------------------------------------------------------------
// Replica cadernos da safra anterior
user function ZZLCA ()
	u_help ("Funcionalidade ainda nao implementada")
return



// --------------------------------------------------------------------------
// Busca os cadastros viticolas X variedades ligados ao grupo familiar
// juntamente com o numero do caderno de campo que atende a essa relacao.
user function ZZLAten (_sCodZAN, _sSafra)
	local _aRet := {}
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "WITH VITIC_VARIED AS ("
	_oSQL:_sQuery += " SELECT ZA8_COD, ZA8_DESCRI, ZZC.ZZC_PRODUT, SB1.B1_DESC"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA8") +  " ZA8, "
	_oSQL:_sQuery +=            + RetSQLName ("ZAL") +  " ZAL, "
	_oSQL:_sQuery +=            + RetSQLName ("ZZC") +  " ZZC, "
	_oSQL:_sQuery +=            + RetSQLName ("SB1") +  " SB1 "
	_oSQL:_sQuery +=  " WHERE ZA8.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZA8.ZA8_FILIAL = '" + xfilial ("ZA8") + "'"
	_oSQL:_sQuery +=    " AND ZAL.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZAL.ZAL_FILIAL = '" + xfilial ("ZAL") + "'"
	_oSQL:_sQuery +=    " AND ZAL.ZAL_IDZAN  = '" + _sCodZAN + "'"
	_oSQL:_sQuery +=    " AND ZAL.ZAL_IDZA8  = ZA8.ZA8_COD"
	_oSQL:_sQuery +=    " AND ZZC.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZZC.ZZC_FILIAL = '" + xfilial ("ZZC") + "'"
	_oSQL:_sQuery +=    " AND ZZC.ZZC_CADVIT = ZA8.ZA8_COD"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = ZZC.ZZC_PRODUT"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += "SELECT VITIC_VARIED.*, ISNULL (ZAS_IDZZL, '') AS CADERNO"
	_oSQL:_sQuery +=  " FROM VITIC_VARIED"
	_oSQL:_sQuery +=     " LEFT JOIN " + RetSQLName ("ZAS") + " ZAS "
	_oSQL:_sQuery += " ON (ZAS.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZAS.ZAS_FILIAL = '" + xfilial ("ZAS") + "'"
	_oSQL:_sQuery += " AND ZAS.ZAS_IDZAN  = '" + _sCodZAN + "'"
	_oSQL:_sQuery += " AND ZAS.ZAS_SAFRA  = '" + _sSafra + "'"
	_oSQL:_sQuery += " AND ZAS.ZAS_IDZA8  = VITIC_VARIED.ZA8_COD"
	_oSQL:_sQuery += " AND ZAS.ZAS_PRODUT = VITIC_VARIED.ZZC_PRODUT)"
	_oSQL:Log ()
	_aRet := aclone (_oSQL:Qry2Array ())
return _aRet



// --------------------------------------------------------------------------
// Inclusao
user function ZZLI ()
	//local _aArea     := {}
	local _aBotAdic  := {}
	private altera   := .F.
	private inclui   := .T.
	private aGets    := {}
	private aTela    := {}
	u_logIni ()

	// Cria variaveis 'M->' aqui para serem vistas depois da inclusao (gravacao do campo memo)
	// RegToMemory ("ZZL", inclui, inclui)

	// Apos a inclusao do registro, faz os tratamentos necessarios.
	if axinclui ("ZZL", zzl -> (recno ()), 3, NIL, NIL, NIL, "U_ZZL_TOk ()",,,_aBotAdic) == 1
	endif

	u_logFim ()
return



// --------------------------------------------------------------------------
// Validacao 'Tudo OK' da inclusao/alteracao.
user function ZZL_TOk ()
	local _lRet      := .T.

	if _lRet .and. ! empty (_sGrpFam) .and. m->zzl_idzan != _sGrpFam
		u_help ("Grupo familiar deve ser '" + _sGrpFam + "' neste caso.")
		_lRet = .F.
	endif

	// GRUPO FAMILIAR DEVE EXISTIR
	if _lRet
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*) " 
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAN") + " ZAN "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''" 
		_oSQL:_sQuery +=  " AND ZAN_COD = '" + m->zzl_idzan + "'"
		if _oSQL:Retqry() = 0
			u_help ('Grupo Familiar ' + m->zzl_idzan + ' não encontrado')
			_lRet = .F.
		endif
	endif

	// CADASTRO VITICOLA DEVE EXISTIR
	if _lRet
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*) "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZ2") + " SZ2 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=  " AND Z2_CADVITI = '" + m->zzl_cadvit + "'"
		if _oSQL:Retqry() = 0
			u_help ('Cadastro Viticola ' + m->zzl_cadvit + ' não encontrado')
			_lRet = .F.
		endif
	endif
	 
	// PROPRIEDADE RURAL DEVE EXISTIR
	if _lRet
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*) "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZA8") + " ZA8 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''" 
		_oSQL:_sQuery +=  " AND ZA8_COD = '" + m->zzl_cadvit + "'"
		if _oSQL:Retqry() = 0
			u_help ('Propriedade Rural ' + m->zzl_cadvit + ' não encontrado')
			_lRet = .F.
		endif
	endif
	
	// PROPRIEDADE RURAL DEVE ESTAR VINCULADA AO GRUPO FAMILIAR
	if _lRet
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*) "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZAL") + " ZAL "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=  " AND ZAL_IDZAN = '" + m->zzl_idzan + "'"
		_oSQL:_sQuery +=  " AND ZAL_IDZA8 = '" + m->zzl_cadvit + "'"
		if _oSQL:Retqry() = 0
			u_help ('Propriedade Rural ' + m->zzl_cadvit + ' não vinculada ao grupo familiar ' + m->zzl_idzan + "'")
			_lRet = .F.
		endif
	endif
	
	// VARIEDADE DE UVA DEVE ESTAR VINCULADA AO CADASTRO VITICOLA
	if _lRet
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*) "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZC") + " ZZC "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=  " AND ZZC_CADVIT = '" + m->zzl_cadvit + "'"
		_oSQL:_sQuery +=  " AND ZZC_PRODUT = '" + m->zzl_produt + "'"
		if _oSQL:Retqry() = 0
			u_help ('Variedade ' + m->zzl_produt + ' não vinculada ao cadastro viticula ' + m->zzl_cadvit + "'")
			_lRet = .F.
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Amarracao com cadastros viticolas e variedades.
user function ZZLVit ()
	local _lContinua := .T.
	local _aAtend    := {}
	local _nAtend    := 0
	local _aCadVit   := {}
	local _nCadVit   := 0
	local _aCols     := {}
	local _lAlterZAS := .F.
	local _sVaried   := ''
	local _sCadVit   := ''
	local _oSQL      := NIL
	local _sAliasQ   := ''
	
	// Busca os cadastros viticolas X variedades ligados ao grupo familiar
	// juntamente com o numero do caderno de campo que os atendem.
	_aAtend := aclone (U_ZZLAten (zzl -> zzl_idZAN, zzl -> zzl_safra))
	//u_log (_aAtend)
	if len (_aAtend) == 0
		u_help ("Nao ha propriedades rurais ligadas a este grupo familiar (cada propriedade representa um cadastro viticola), ou os cadastros viticolas nao tem variedades ligadas a eles.")
		_lContinua = .F.
	else
		// Prepara array para uso em markbrowse, o que vai permir ao usuario selecionar
		// quais propriedades (cad.vitic.) X variedades serao atendidas por este caderno de campo.
		for _nAtend = 1 to len (_aAtend)
			aadd (_aCadVit, {(_aAtend [_nAtend, 5] == zzl -> zzl_cod), ;  // Traz selecionado se for o caderno atual
			                 _aAtend [_nAtend, 1], ;  // Cadastro viticola (propriedade rural)
			                 _aAtend [_nAtend, 2], ;  // Descricao propriedade 
			                 _aAtend [_nAtend, 3], ;  // Produto (variedade)
			                 _aAtend [_nAtend, 4], ;  // Descricao produto
			                 _aAtend [_nAtend, 5]})   // Caderno de campo que atende a esta dupla vitic X variedade
		next

		aadd (_aCols, {2, 'Propr/viticola',     60, ''})
		aadd (_aCols, {3, 'Descr.propriedade', 160, ''})
		aadd (_aCols, {4, 'Variedade',          60, ''})
		aadd (_aCols, {5, 'Descr.variedade',   160, ''})
		aadd (_aCols, {6, 'Caderno',            60, ''})
		U_MbArray (@_aCadVit, "Selecione propriedades rurais / cadastros viticolas", _aCols, 1, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight - 150, 'U_ZZLVSV()')
	endif
	if _lContinua
		//u_log ("_aCadVit depois da selecao:", _aCadVit)
		for _nCadVit = 1 to len (_aCadVit)
			
			// Se o usuario selecionou uma linha que nao era atendida por nenhum caderno,
			// significa que a mesma deverah ser atendida pelo caderno atual.
			if _aCadVit [_nCadVit, 1] .and. empty (_aCadVit [_nCadVit, 6])
				//u_log ('vinculou a linha', _nCadVit)
				reclock ("ZAS", .T.)
				zas -> zas_filial = xfilial ("ZAS")
				zas -> zas_idZAN  = zzl -> zzl_idZAN
				zas -> zas_safra  = zzl -> zzl_safra
				zas -> zas_idZA8  = _aCadVit [_nCadVit, 2]
				zas -> zas_idZZL  = zzl -> zzl_cod
				zas -> zas_produt = _aCadVit [_nCadVit, 4]
				msunlock ()
				_lAlterZAS = .T.
			endif

			// Se o usuario desmarcou uma linha que jah era atendida pelo caderno atual,
			// significa que o vinculo deve ser removido.
			if !_aCadVit [_nCadVit, 1] .and. _aCadVit [_nCadVit, 6] == zzl -> zzl_cod
				//u_log ('desvinculou a linha', _nCadVit)
				reclock ("ZAS", .F.)
				zas -> (dbdelete ())
				msunlock ()
				_lAlterZAS = .T.
			endif
		next
	endif

	// Se houve alteracoes na tabela de viticolas X variedades atendidas, gera nova descricao.
	if _lContinua .and. _lAlterZAS
		if U_MsgYesNo ("Deseja ajustar a descricao deste caderno de campo?")

			// Busca descricao abreviada das variedades no SB5
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT DISTINCT B5_CEME, ZAS_IDZA8"
			_oSQL:_sQuery += " FROM " + RetSQLName ("SB5") + " SB5, "
			_oSQL:_sQuery +=            RetSQLName ("ZAS") + " ZAS "
			_oSQL:_sQuery += " WHERE ZAS.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZAS.ZAS_FILIAL = '" + xfilial ("ZAS")  + "'"
			_oSQL:_sQuery +=   " AND ZAS.ZAS_IDZAN  = '" + zzl -> zzl_idZAN + "'"
			_oSQL:_sQuery +=   " AND ZAS.ZAS_SAFRA  = '" + zzl -> zzl_safra + "'"
			_oSQL:_sQuery +=   " AND ZAS.ZAS_IDZZL  = '" + zzl -> zzl_cod   + "'"
			_oSQL:_sQuery +=   " AND SB5.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND SB5.B5_FILIAL  = '" + xfilial ("SB5") + "'"
			_oSQL:_sQuery +=   " AND SB5.B5_COD     = ZAS.ZAS_PRODUT"
			_oSQL:Log ()
			_sAliasQ = _oSQL:Qry2Trb ()

			_sVaried = ''
			(_sAliasQ) -> (dbgotop ())
			do while ! (_sAliasQ) -> (eof ())
				if ! alltrim ((_sAliasQ) -> b5_ceme) $ _sVaried
					_sVaried += iif (empty (_sVaried), '', ', ') + alltrim ((_sAliasQ) -> b5_ceme)
				endif
				(_sAliasQ) -> (dbskip ())
			enddo

			_sCadVit = ' CV:'
			(_sAliasQ) -> (dbgotop ())
			do while ! (_sAliasQ) -> (eof ())
				if ! (_sAliasQ) -> zas_idZA8 $ _sCadVit
					_sCadVit += iif (len (_sCadVit) > 4, ', ', '') + zas_idZA8
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())

			reclock ("ZZL", .F.)
			zzl -> zzl_descri = _sVaried + _sCadVit
			msunlock ()
		endif
	endif
return



// --------------------------------------------------------------------------
// Valida selecao de cad.vitic.Xproduto
user function ZZLVSV ()
	local _lRet := .T.
	local _aLinAtu := {}

	// Faz uma copia da linha atual do browse de selecao, para facilitar as validacoes.
	_aLinAtu := aclone (_aMBArrayV [1, _aMBArrayV [2]])  // Variavel _aMBArrayV eh disponibilizada pela funcao MBArray para validacoes.

	if ! empty (_aLinAtu [6]) .and. _aLinAtu [6] != zzl -> zzl_cod
		u_help ("Esta combinacao de cadastro viticola X variedade ja encontra-se vinculada ao caderno de campo " + _aLinAtu [6] + ' para esta safra.')
		_lRet = .F.
	endif  
return _lRet



// --------------------------------------------------------------------------
// Geracao automatica de cadernos.
user function ZZLG (_sGrpFam)
	local _nQtCad    := 0
	local _nCad      := 0
	local _sSafra    := ""
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _sProxCad  := ''

	if _lContinua .and. empty (_sGrpFam)
		u_help ("Grupo familiar nao informado.")
		_lContinua = .F.
	endif

	if _lContinua
		_nQtCad = U_Get ("Quantidade de cadernos a gerar", "N", 1, "9", "", 0, .F., ".T.")
		if _nQtCad == NIL .or. _nQtCad == 0
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_sSafra = U_Get ("Safra base", "C", 4, "9999", "", U_IniSafra (), .F., ".T.")
		if _sSafra == NIL .or. empty (_sSafra)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_sProxCad = ''
		zzl -> (dbsetorder (1))  // ZZL_FILIAL+ZZL_IDZAN+ZZL_SAFRA+ZZL_COD
		zzl -> (dbseek (xfilial ("ZZL") + _sGrpFam + _sSafra, .T.))
		do while ! zzl -> (eof ()) .and. zzl -> zzl_filial == xfilial ("ZZL") .and. zzl -> zzl_idZAN == _sGrpFam .and. zzl -> zzl_safra == _sSafra
			_sProxCad = zzl -> zzl_cod
			zzl -> (dbskip ())
		enddo
		if ! empty (_sProxCad)
			_lContinua = U_MsgNoYes ("Ja existe(m) caderno(s) para este grupo familiar / safra. Deseja gerar assim mesmo?")
		endif
	endif

	if _lContinua
		_sProxCad = iif (empty (_sProxCad), '00', _sProxCad)
		for _nCad = 1 to _nQtCad
			_sProxCad = soma1 (_sProxCad)
			reclock ("ZZL", .T.)
			zzl -> zzl_filial = xfilial ("ZZL")
			zzl -> zzl_idzan  = _sGrpFam
			zzl -> zzl_safra  = _sSafra
			zzl -> zzl_cod    = _sProxCad
			zzl -> zzl_descri = {'PRIMEIRO','SEGUNDO','TERCEIRO','QUARTO','QUINTO','SEXTO','SETIMO','OITAVO','NONO','DECIMO','DECIMO PRIMEIRO','DECIMO SEGUNDO','DECIMO TERCEIRO','DECIMO QUARTO','DECIMO QUINTO','DECIMO SEXTO','DECIMO SETIMO','DECIMO OITAVO','DECIMO NONO'} [val (_sProxCad)]  // Mais que isso eh pra judiar do peao...
			msunlock ()
		next
		u_help ("Cadernos gerados.")
	endif

	U_ML_SRArea (_aAreaAnt)
return
