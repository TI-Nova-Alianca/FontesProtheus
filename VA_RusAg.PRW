// Programa...: VA_RusaAg
// Autor......: Robert Koch
// Data.......: 05/02/2021 (criado com base num backup de 2018 onde constava dentro do VA_RUS2.PRW)
// Descricao..: Funcao de aglutinacao de cargas de safra. Utilizada quando tem mais de uma
//              variedade na mesma carga ou quando o produtor traz diversas cargas pequenas
//              e deseja junta-las no final do dia, emitindo uma so nota de produtor (GLPI 9336).
//
// Historico de alteracoes:
// 05/01/2022 - Robert - Eliminados campos ZF_NCONF03 e ZF_NCONF04.
//

// --------------------------------------------------------------------------
User Function va_rusAg ()
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _sFromAg   := ""
	local _aCargas   := {}
	local _nCarga    := 0
	local _sAliasQ   := ""
	local _sCargSel  := ""
	local _sItemDest := ""
	local _nLock     := 0
	local _nQtCarSel := 0
	local _nLinACols := 0

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. (empty (m->ze_assoc) .or. empty (m->ze_lojasso))
		u_help ("Associado / fornecedor deve estar informado.",, .t.)
		_lContinua = .F.
	endif

	// Nao permite duas sessoes aglutinando na mesma filial ao mesmo tempo.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .T.)
		if _nLock == 0
			u_log2 ('aviso', "Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif

	// Define criterio de busca de cargas aptas a aglutinar.
	if _lContinua
		_sFromAg := ""
		_sFromAg +=   " FROM " + RetSQLName ("SZE") + " SZE, "
		_sFromAg +=              RetSQLName ("SZF") + " SZF, "
		_sFromAg +=              RetSQLName ("SB1") + " SB1 "
		_sFromAg +=  " WHERE SZE.D_E_L_E_T_  = ''"
		_sFromAg +=    " AND SZE.ZE_FILIAL   = '" + xfilial ("SZE") + "'"
		_sFromAg +=    " AND SZE.ZE_SAFRA    = '" + M->ze_safra   + "'"
		_sFromAg +=    " AND SZE.ZE_ASSOC    = '" + m->ze_assoc   + "'"
		_sFromAg +=    " AND SZE.ZE_LOJASSO  = '" + m->ze_lojasso + "'"
		_sFromAg +=    " AND SZE.ZE_NFGER    = ''"
		_sFromAg +=    " AND SZE.ZE_SNFPROD  = ''"
		_sFromAg +=    " AND SZE.ZE_NFPROD   = ''"
		_sFromAg +=    " AND SZE.ZE_PESOTAR != 0"    // Deve ter 2a. pesagem
		_sFromAg +=    " AND SZE.ZE_AGLUTIN != 'O'"  // Nao pode ser aglutinada mais de uma vez.
		_sFromAg +=    " AND SZE.ZE_STATUS  != 'C'"  // Cancelada
		_sFromAg +=    " AND SZF.D_E_L_E_T_  = ''"
		_sFromAg +=    " AND SZF.ZF_FILIAL   = SZE.ZE_FILIAL"
		_sFromAg +=    " AND SZF.ZF_SAFRA    = SZE.ZE_SAFRA"
		_sFromAg +=    " AND SZF.ZF_CARGA    = SZE.ZE_CARGA"
		_sFromAg +=    " AND SZF.ZF_GRAU    != ''"
		_sFromAg +=    " AND SB1.D_E_L_E_T_  = ''"
		_sFromAg +=    " AND SB1.B1_FILIAL   = '" + xfilial ("SB1") + "'"
		_sFromAg +=    " AND SB1.B1_COD      = SZF.ZF_PRODUTO"

		// Busca cargas do associado sem contranota.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT '', SZE.ZE_CARGA, dbo.VA_DTOC (SZE.ZE_DATA), SZE.ZE_HORA, SZE.ZE_PESOTAR, SUM (ZF_PESO), ZF_IDZA8, ZF_IDSZ9 "
		_oSQL:_sQuery += _sFromAg
		_oSQL:_sQuery +=  " GROUP BY ZE_CARGA, ZE_DATA, ZE_HORA, SZE.ZE_PESOTAR, ZF_IDZA8, ZF_IDSZ9"
		_oSQL:_sQuery +=  " ORDER BY ZE_CARGA, ZE_DATA, ZE_HORA, ZF_IDZA8, ZF_IDSZ9"
		_oSQL:Log ()
		_aCargas = _oSQL:Qry2Array ()
		u_log2 ('info', 'Cargas aglutinaveis:')
		u_log2 ('info', _aCargas)
	endif

	if _lContinua .and. len (_aCargas) == 0
		u_help ("Nao ha cargas deste associado para aglutinar." + CHR (13) + CHR (10) + ;
		        "Para poderem ser aglutinadas, as cargas:" + CHR (13) + CHR (10) + ;
		        "- Devem ser desta mesma safra;" + CHR (13) + CHR (10) + ;
		        "- Devem ser do mesmo associado/loja;" + CHR (13) + CHR (10) + ;
		        "- Devem ter segunda pesagem realizada;" + CHR (13) + CHR (10) + ;
		        "- Nao podem ter nota de produtor/serie informada;" + CHR (13) + CHR (10) + ;
		        "- Nao podem ter contranota gerada;" + CHR (13) + CHR (10) + ;
		        "- Nao podem ter sido previamente aglutinadas.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua .and. len (_aCargas) == 1
		u_help ("Associado tem somente uma carga em condicoes de ser aglutinada (" + _aCargas [1, 2] + "). Nao ha razao para aglutinar. Gere contranota dessa mesma carga.",, .t.)
		_lContinua = .F.
	endif

	// Browse para o usuario marcar as cargas.
	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {2, "Carga",        60, ""})
		aadd (_aCampos, {3, "Data",         60, "@D"})
		aadd (_aCampos, {4, "Hora",         60, ""})
		aadd (_aCampos, {5, "Peso tara",    60, "@E 999,999.99"})
		aadd (_aCampos, {6, "Peso liquido", 60, "@E 999,999.99"})
		aadd (_aCampos, {7, "Propr.rural",  60, ""})
		aadd (_aCampos, {8, "Talhao",       60, ""})
		for _nCarga = 1 to len (_aCargas)
			_aCargas [_nCarga, 1] = .T.  // Por default, traz todas selecionadas.
		next
		U_MBArray (@_aCargas, "Selecione as cargas a aglutinar.", _aCampos, 1, NIL, 400, '.T.')
		u_log2 ('info', 'Cargas selecionadas para aglutinar:')
		u_log2 ('info', _aCargas)
	
		// Monta string com as cargas selecionadas.
		_sCargSel  = ""
		_nQtCarSel = 0
		for _nCarga = 1 to len (_aCargas)
			if _aCargas [_nCarga, 1]
				_sCargSel += _aCargas [_nCarga, 2] + iif (_nCarga < len (_aCargas), "/", "")
				_nQtCarSel ++
			endif
		next
		u_log2 ('debug', 'sel.:', _sCargSel)
		_lContinua = ! empty (_sCargSel)
		if _nQtCarSel < 2
			u_help ("Selecione pelo menos duas cargas",, .t.)
			_lContinua = .F.
		endif
	endif

	// Busca itens das cargas selecionadas.
	if _lContinua
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT SB1.B1_DESC, SZF.*"
		_oSQL:_sQuery += _sFromAg
		_oSQL:_sQuery += " AND ZE_CARGA IN " + FormatIn (_sCargSel, '/')
		_sAliasQ = _oSQL:Qry2Trb ()
		
		// Aglutina os itens, somando quantidades, quando possivel.
		_sItemDest = strzero (1, tamsx3 ("ZF_ITEM")[1])
		_aAglut = {}
		aCols = {}
		do while ! (_sAliasQ) -> (eof ())
			u_logIni ('trb')
			u_log2 ('debug', GDFieldPos ("ZF_PRODUTO"))
			u_log2 ('debug', GDFieldPos ("ZF_CADVITI"))
			u_log2 ('debug', GDFieldPos ("ZF_EMBALAG"))
			u_log2 ('debug', GDFieldPos ("ZF_GRAU") )
			u_log2 ('debug', GDFieldPos ("ZF_PRM02") )
			u_log2 ('debug', GDFieldPos ("ZF_PRM03") )
			u_log2 ('debug', GDFieldPos ("ZF_PRM04") )
			u_log2 ('debug', GDFieldPos ("ZF_PRM05") )
			u_log2 ('debug', GDFieldPos ("ZF_PRM99") )
			u_log2 ('debug', GDFieldPos ("ZF_CLASABD"))
			u_log2 ('debug', GDFieldPos ("ZF_NCONF01"))
			u_log2 ('debug', GDFieldPos ("ZF_NCONF02"))
			u_log2 ('debug', GDFieldPos ("ZF_IDZA8") )
			u_log2 ('debug', GDFieldPos ("ZF_IDSZ9") )
			u_log2 ('debug', GDFieldPos ("ZF_CONDUC"))
			u_log2 ('debug', GDFieldPos ("ZF_SIVIBE"))
			u_log2 ('debug', GDFieldPos ("ZF_OBS")   )


			N = ascan (aCols, {|_aVal| _aVal [GDFieldPos ("ZF_PRODUTO")] == (_sAliasQ) -> zf_produto ;
			                     .and. _aVal [GDFieldPos ("ZF_CADVITI")] == (_sAliasQ) -> zf_cadviti ;
			                     .and. _aVal [GDFieldPos ("ZF_EMBALAG")] == (_sAliasQ) -> zf_embalag ;
			                     .and. _aVal [GDFieldPos ("ZF_GRAU")]    == (_sAliasQ) -> zf_grau ;
			                     .and. _aVal [GDFieldPos ("ZF_PRM02")]   == (_sAliasQ) -> zf_prm02 ;
			                     .and. _aVal [GDFieldPos ("ZF_PRM03")]   == (_sAliasQ) -> zf_prm03 ;
			                     .and. _aVal [GDFieldPos ("ZF_PRM04")]   == (_sAliasQ) -> zf_prm04 ;
			                     .and. _aVal [GDFieldPos ("ZF_PRM05")]   == (_sAliasQ) -> zf_prm05 ;
			                     .and. _aVal [GDFieldPos ("ZF_PRM99")]   == (_sAliasQ) -> zf_prm99 ;
			                     .and. _aVal [GDFieldPos ("ZF_CLASABD")] == (_sAliasQ) -> zf_clasabd ;
			                     .and. _aVal [GDFieldPos ("ZF_IDZA8")]   == (_sAliasQ) -> zf_idZA8 ;
			                     .and. _aVal [GDFieldPos ("ZF_IDSZ9")]   == (_sAliasQ) -> zf_idSZ9 ;
			                     .and. _aVal [GDFieldPos ("ZF_CONDUC")]  == (_sAliasQ) -> zf_conduc ;
			                     .and. _aVal [GDFieldPos ("ZF_SIVIBE")]  == (_sAliasQ) -> zf_sivibe})
			if N == 0
				u_log ('criando linha no aCols')
				aadd (aCols, aclone (U_LinVazia (aHeader)))
				N = len (aCols)
				GDFieldPut ("ZF_ITEM",    _sItemDest)
				GDFieldPut ("ZF_PRODUTO", (_sAliasQ) -> zf_produto)
				GDFieldPut ("ZF_DESCRI",  (_sAliasQ) -> b1_desc)
				GDFieldPut ("ZF_CADVITI", (_sAliasQ) -> zf_cadviti)
				GDFieldPut ("ZF_EMBALAG", (_sAliasQ) -> zf_embalag)
				GDFieldPut ("ZF_GRAU",    (_sAliasQ) -> zf_grau)
				GDFieldPut ("ZF_PRM02",   (_sAliasQ) -> zf_prm02)
				GDFieldPut ("ZF_PRM03",   (_sAliasQ) -> zf_prm03)
				GDFieldPut ("ZF_PRM04",   (_sAliasQ) -> zf_prm04)
				GDFieldPut ("ZF_PRM05",   (_sAliasQ) -> zf_prm05)
				GDFieldPut ("ZF_PRM99",   (_sAliasQ) -> zf_prm99)
				GDFieldPut ("ZF_CLASABD", (_sAliasQ) -> zf_clasabd)
				GDFieldPut ("ZF_QTEMBAL", (_sAliasQ) -> zf_qtembal)
				GDFieldPut ("ZF_PESO",    (_sAliasQ) -> zf_peso)
				GDFieldPut ("ZF_IDZA8",   (_sAliasQ) -> zf_idZA8)
				GDFieldPut ("ZF_IDSZ9",   (_sAliasQ) -> zf_idSZ9)
				GDFieldPut ("ZF_CADCPO",  (_sAliasQ) -> zf_cadcpo)
				GDFieldPut ("ZF_CONDUC",  (_sAliasQ) -> zf_conduc)
				GDFieldPut ("ZF_SIVIBE",  (_sAliasQ) -> zf_sivibe)
				GDFieldPut ("ZF_OBS",     (_sAliasQ) -> zf_obs)

				// Grava relacionamento na previa da tabela ZZD.
				aadd (_aAglut, {GDFieldGet ("ZF_ITEM"), (_sAliasQ) -> zf_carga, (_sAliasQ) -> zf_item})

				_sItemDest = soma1 (_sItemDest)
			else
				u_log ('somando na linha', n)
				GDFieldPut ("ZF_QTEMBAL", GDFieldGet ("ZF_QTEMBAL") + (_sAliasQ) -> zf_qtembal)
				GDFieldPut ("ZF_PESO",    GDFieldGet ("ZF_PESO") + (_sAliasQ) -> zf_peso)

				// Grava relacionamento na previa da tabela ZZD.
				aadd (_aAglut, {GDFieldGet ("ZF_ITEM"), (_sAliasQ) -> zf_carga, (_sAliasQ) -> zf_item})
			endif

			(_sAliasQ) -> (dbskip ())
			u_logFim ('trb')
		enddo
	endif
	u_log2 ('info', "Aglutinei no aCols. _aAglut ficou assim:")
	u_log2 ('info', _aAglut)

	if _lContinua

		// Gera peso tara com a media das taras das cargas envolvidas e bruto somando-o com os itens.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT AVG (SZE.ZE_PESOTAR) "
		_oSQL:_sQuery += _sFromAg
		_oSQL:_sQuery += " AND ZE_CARGA IN " + FormatIn (_sCargSel, '/')

		// Faz arredondamento cfe. parametrizacao do usuario.
		m->ze_PesoTar = round (_oSQL:RetQry () / _nMultBal, 0)
		m->ze_PesoTar *= _nMultBal

		m->ze_PesoBru = m->ze_PesoTar
		for _nLinACols = 1 to len (aCols)
			m->ze_PesoBru += GDFieldGet ("ZF_PESO", _nLinACols)
		next

		// Marca carga como 'Destino de aglutinacao'.
		m->ze_aglutin = 'D'
		_oEnch1:Refresh ()
	endif

	// Se, por alguma razao, chegou aqui sem nenhuma linha no aCols, cria pelo menos uma linha vazia.
	if len (aCols) == 0
		aadd (aCols, aclone (U_LinVazia (aHeader)))
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	// Atualiza tela do usuario
	N = 1
	_oGetD:oBrowse:Refresh ()

	U_ML_SRArea (_aAreaAnt)
return
