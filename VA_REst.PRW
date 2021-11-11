// Programa...: VA_REst
// Autor......: Robert Koch
// Data.......: 25/11/2013
// Descricao..: Reabre periodo fechado do estoque (SB9 e MV_ULMES)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Reabertura de periodo do estoque
// #PalavasChave      #reabertura_estoque
// #TabelasPrincipais #SB9 #SBJ #SBK
// #Modulos           #EST

// Historico de alteracoes:
// 17/09/2014 - Robert - Incluido tratamento para tabelas SBJ e SBK.
// 17/12/2014 - Robert - Passa a verificar o parametro MV_RASTRO.
// 26/08/2016 - Robert - Verifica status do calendario contabil antes de reabrir o estoque.
// 12/07/2017 - Robert - Verifica SBJ e SBK somente se tiverem dados validos (algumas filiais nao tem itens com rastreabilidade).
// 19/05/2020 - Robert - Avisa usuario se encontrar OPs com apontamento dentro do mes reaberto e em meses posteriores.
// 17/08/2020 - Robert - Backups passam a ser gerados em pasta \backups\
//                     - Incluidas tags para catalogo de fontes.
// 05/10/2020 - Robert - Implementado tratamento para reabertura de OP (por enquanto, apenas 1 parte e moeda 01) - GLPI 8599
//                     - Melhorados nomes dos arquivos de bkp.
// 05/05/2021 - Robert - Passa a exportar backups em formato CSV por que novas releases nao permitem mais uso de criver ISAM (GLPI 9973).
// 11/11/2021 - Robert - Quando ambiente de testes, permite pular a etapa de backup dos dados anteriores.
//

// --------------------------------------------------------------------------
User Function VA_REst ()
	local _nLock       := 0

	// Somente uma estacao por vez.
	_nLock := U_Semaforo (procname (), .T.)
	if _nLock == 0
		return
	endif

	if ! U_ZZUVL ('009')
		return
	endif

	Processa( {|lEnd| _AiQueMedo ()})

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return



// --------------------------------------------------------------------------
Static Function _AiQueMedo ()
	local _lContinua  := .T.
	local _oEvento    := NIL
	local _oSQL       := NIL
	local _oSQLSB9    := NIL
	local _oSQLSBJ    := NIL
	local _oSQLSBK    := NIL
	local _dDataSB9   := ctod ("")
	local _dDataSBJ   := ctod ("")
	local _dDataSBK   := ctod ("")
	local _dMesAnt    := ctod ("")
	local _sAliasQ    := ""
	local _sBkpSB9    := ""
	local _sBkpSBJ    := ""
	local _sBkpSBK    := ""
	local _sWhereSB9  := ""
	local _sWhereSBJ  := ""
	local _sWhereSBK  := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT MAX (B9_DATA)"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB9") + " SB9 "
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND B9_FILIAL  = '" + xfilial ("SB9") + "'"
	_dDataSB9 = stod (_oSQL:RetQry ())
	
	if GetMV ("MV_RASTRO") == "S"
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX (BJ_DATA)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBJ")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND BJ_FILIAL  = '" + xfilial ("SBJ") + "'"
		_oSQL:_sQuery +=    " AND BJ_COD    != ''"
		_dDataSBJ = stod (_oSQL:RetQry ())
	
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX (BK_DATA)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBK")
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND BK_FILIAL  = '" + xfilial ("SBK") + "'"
		_oSQL:_sQuery +=    " AND BK_COD    != ''"
		_dDataSBK = stod (_oSQL:RetQry ())
	
		if _dDataSB9 != GetMv ("MV_ULMES")
			u_help ("Inconsistencia entre a maior data da tabela SB9 (" + dtoc (_dDataSB9) + ") e o parametro MV_ULMES (" + dtoc (GetMv ("MV_ULMES")) + "). Verifique!",, .t.)
			_lContinua = .F.
		endif
	
		if ! empty (_dDataSBJ)
			if _dDataSB9 != _dDataSBJ
				u_help ("Inconsistencia entre a maior data das tabelas SB9 (" + dtoc (_dDataSB9) + "), SBJ (" + dtoc (_dDataSBJ) + ") e SBK (" + dtoc (_dDataSBK) + "). Verifique!",, .t.)
				_lContinua = .F.
			endif
		endif
		if ! empty (_dDataSBK)
			if _dDataSB9 != _dDataSBK
				u_help ("Inconsistencia entre a maior data das tabelas SB9 (" + dtoc (_dDataSB9) + "), SBJ (" + dtoc (_dDataSBJ) + ") e SBK (" + dtoc (_dDataSBK) + "). Verifique!",, .t.)
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		_dMesAnt = lastday (firstday (_dDataSB9) - 1)
	endif

	if _lContinua
		if "TESTE" $ upper (GetEnvServer()) .and. IsInCallStack ("U_ROBERT")
			u_log2 ('debug', 'Ambiente de testes: Prosseguindo sem confirmacao do usuario.')
		else
			_lContinua = U_msgnoyes ("O ultimo fechamento de estoques da filial atual foi feito em " + dtoc (_dDataSB9) + ". Confirma reabertura deste mes?")
		endif
	endif

	// Verifica calendario contabil.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("CTG") + " CTG "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND CTG_FILIAL = '" + xfilial ("CTG") + "'"
		_oSQL:_sQuery +=    " AND CTG_EXERC  = '" + substr (dtos (_dDataSB9), 1, 4) + "'"
		_oSQL:_sQuery +=    " AND CTG_PERIOD = '" + substr (dtos (_dDataSB9), 5, 2) + "'"
		_oSQL:_sQuery +=    " AND CTG_STATUS = '1'"
		_oSQL:Log ()
		if _oSQL:RetQry () != 1
			u_help ("Processo nao pode ser realizado neste momento por que o periodo solicitado nao se encontra 'aberto' no calendario contabil.",, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (10)
		incproc ("")
		
		// Monta filtros separadamente, para posterior uso na delecao dos registros.
		_sWhereSB9 := " WHERE D_E_L_E_T_ = '' AND B9_FILIAL  = '" + xfilial ("SB9") + "' AND B9_DATA = '" + dtos (_dDataSB9) + "'"
		_sWhereSBJ := " WHERE D_E_L_E_T_ = '' AND BJ_FILIAL  = '" + xfilial ("SBJ") + "' AND BJ_DATA = '" + dtos (_dDataSBJ) + "'"
		_sWhereSBK := " WHERE D_E_L_E_T_ = '' AND BK_FILIAL  = '" + xfilial ("SBK") + "' AND BK_DATA = '" + dtos (_dDataSBK) + "'"
			
		// Exporta backup
		_oSQLSB9 := ClsSQL ():New ()
		_oSQLSBJ := ClsSQL ():New ()
		_oSQLSBK := ClsSQL ():New ()
		_oSQLSB9:_sQuery := " SELECT * FROM " + RetSQLName ("SB9") + _sWhereSB9
		_oSQLSBJ:_sQuery := " SELECT * FROM " + RetSQLName ("SBJ") + _sWhereSBJ
		_oSQLSBK:_sQuery := " SELECT * FROM " + RetSQLName ("SBK") + _sWhereSBK

		_sBkpSB9 = "\backups\Bkp_reab_SB9_mes_" + left (dtos (_dDataSB9), 6) + "_F" + xfilial ("SB9") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")
		_sBkpSBJ = "\backups\Bkp_reab_SBJ_mes_" + left (dtos (_dDataSB9), 6) + "_F" + xfilial ("SBJ") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")
		_sBkpSBK = "\backups\Bkp_reab_SBK_mes_" + left (dtos (_dDataSB9), 6) + "_F" + xfilial ("SBK") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")

		// Cria diretorio para os arquivos de backup
		_sDirLogs = '\backups\'
		makedir (_sDirLogs)
			
		if "TESTE" $ upper (GetEnvServer()) .and. U_MsgNoYes ('Parece que estamos em ambiente de testes. Deseja ignorar a etapa de backup dos dados?')
			U_Log2 ('aviso', 'Ignorando a etapa de backup dos dados anteriores')
		else
			u_log2 ('info', 'Gerando backup no arquivo ' + _sBkpSB9 + ' a partir de: ' + _oSQLSB9:_sQuery)
			_sAliasQ := _oSQLSB9:Qry2Trb (.T.)
			U_Trb2XLS (_sAliasQ, .F., .F., .F., _sBkpSB9 + '.csv')

			if GetMV ("MV_RASTRO") == "S"
				u_log2 ('info', 'Gerando backup no arquivo ' + _sBkpSBJ + ' a partir de: ' + _oSQLSBJ:_sQuery)
				_sAliasQ := _oSQLSBJ:Qry2Trb (.T.)
				U_Trb2XLS (_sAliasQ, .F., .F., .F., _sBkpSBJ + '.csv')
		
				u_log2 ('info', 'Gerando backup no arquivo ' + _sBkpSBK + ' a partir de: ' + _oSQLSBK:_sQuery)
				_sAliasQ := _oSQLSBK:Qry2Trb (.T.)
				U_Trb2XLS (_sAliasQ, .F., .F., .F., _sBkpSBK + '.csv')
			endif
		endif
	endif

	if _lContinua
		begin transaction
			_oSQLSB9 := ClsSQL ():New ()
			_oSQLSBJ := ClsSQL ():New ()
			_oSQLSBK := ClsSQL ():New ()
			_oSQLSB9:_sQuery := " UPDATE " + RetSQLName ("SB9") + " SET R_E_C_D_E_L_ = R_E_C_N_O_, D_E_L_E_T_ = '*' " + _sWhereSB9
			_oSQLSBJ:_sQuery := " UPDATE " + RetSQLName ("SBJ") + " SET R_E_C_D_E_L_ = R_E_C_N_O_, D_E_L_E_T_ = '*' " + _sWhereSBJ
			_oSQLSBK:_sQuery := " UPDATE " + RetSQLName ("SBK") + " SET R_E_C_D_E_L_ = R_E_C_N_O_, D_E_L_E_T_ = '*' " + _sWhereSBK

			// Se usa rastreabilidade, precisa voltar SBJ e SBK.
			if GetMV ("MV_RASTRO") == "S"
				if _lContinua
					_oSQLSBK:Log ()
					_lContinua = _oSQLSBK:Exec ()
				endif
				if _lContinua
					_oSQLSBJ:Log ()
					_lContinua = _oSQLSBJ:Exec ()
				endif
			endif
			
			// SB9 precisa voltar sempre.
			if _lContinua
				_oSQLSB9:Log ()
				_lContinua = _oSQLSB9:Exec ()
			endif

			// Verifica necessidade de ajuste em OPs com apontamento dentro do mes reaberto e em meses posteriores.
			if _lContinua
				_lContinua = _ReabreOP (_dDataSB9, _dMesAnt)
			endif

			if _lContinua
				// Ajusta parametro no configurador.
				u_log2 ('info', 'Alterando MV_ULMES de ' + cvaltochar (GetMv ("MV_ULMES")) + ' para ' + cvaltochar (_dMesAnt))
				PutMv ("MV_ULMES", _dMesAnt)

				// Grava evento para posterior consulta.
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "SB9001"
				_oEvento:Texto     = "Reab.periodo " + dtoc (_dDataSB9) + " estoque"
				_oEvento:Alias     = "SB9"
				_oEvento:MailToZZU = {'009'}
				_oEvento:Grava ()

			endif

		end transaction

		if _lContinua
			u_help ("Reabertura concluida. Nova data de fechamento: " + dtoc (_dMesAnt))
		else
			u_help ("Erros ocorreram durante o processo.",, .t.)
		endif
	endif
return



// --------------------------------------------------------------------------
// Verifica existencia de OPs com apontamento dentro do mes reaberto e em meses posteriores.
static function _ReabreOP (_dReabSB9, _dReabSC2)
	local _lRetROP   := .T.
	local _oSQLSC2   := NIL
	local _oSQLSD3   := NIL
	local _aOP2Meses := {}
	local _nOP2Meses := 0
	local _sOP2Meses := ''
	local _nC2VAtu   := 0
	local _nC2VIni   := 0
	local _nC2AprAtu := 0
	local _nC2AprIni := 0
	local _oEvtSC2   := NIL

	u_log2 ('info', 'Verificando necessidade de reabertura de OPs')

	/* Por enquanto parece que nao estah fazendo...
	// Documentacao sobre os nomes dos campos para cuto em partes: https://tdn.totvs.com/pages/releaseview.action?pageId=6087433
	// Sendo: CC – Numero do Custo Em Partes
	//        MM – Numero da Moeda (1 a 5)
	// B9_CP  + CC + MM (Custo em partes) – B9_VINI1
	// B9_CPM + CC + MM (Custo em partes Unitário) – B9_CM1
	// B2_CP  + CC + MM (Custo em partes Unitário) – B2_CM1
	// B2_CPF + CC + MM (Custo em partes Final) – B2_VFIM1
	// B6_CP  + CC + MM (Custo em partes) – B6_CUSTO1
	// C2_CPF + CC + MM (Custo em partes Final) – C2_VFIM1
	// C2_CPI + CC + MM (Custo em partes Inicial) – C2_VINI1
	// C2_API + CC + MM (Apropriação Inicial do Custo em partes) – C2_APRINI1
	// C2_APF + CC + MM (Apropriação Final do Custo em partes) – C2_APRFIM1
	// D1_CP  + CC + MM (Custo em partes) – D1_CUSTO
	// D2_CP  + CC + MM (Custo em partes) – D2_CUSTO1
	// D3_CP  + CC + MM (Custo em partes) – D2_CUSTO1
	*/

	sc2 -> (dbsetorder (1))

	// Verifica OPs a ajustar
	_oSQLSC2 := ClsSQL ():New ()
	_oSQLSC2:_sQuery := "SELECT DISTINCT D3_OP" // rtrim (STRING_AGG (rtrim (D3_OP), ','))"
	_oSQLSC2:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
	_oSQLSC2:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQLSC2:_sQuery +=   " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
	_oSQLSC2:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
	_oSQLSC2:_sQuery +=   " AND SD3.D3_EMISSAO <= '" + DTOS (_dReabSB9) + "'"
	_oSQLSC2:_sQuery +=   " AND SD3.D3_OP      != ''"
	_oSQLSC2:_sQuery +=   " AND EXISTS (SELECT *"
	_oSQLSC2:_sQuery +=                 " FROM " + RetSQLName ("SD3") + " POSTERIOR "
	_oSQLSC2:_sQuery +=                " WHERE POSTERIOR.D_E_L_E_T_  = ''"
	_oSQLSC2:_sQuery +=                  " AND POSTERIOR.D3_FILIAL   = SD3.D3_FILIAL"
	_oSQLSC2:_sQuery +=                  " AND POSTERIOR.D3_OP       = SD3.D3_OP"
	_oSQLSC2:_sQuery +=                  " AND POSTERIOR.D3_ESTORNO != 'S'"
	_oSQLSC2:_sQuery +=                  " AND POSTERIOR.D3_EMISSAO  > '" + DTOS (_dReabSB9) + "'"
	_oSQLSC2:_sQuery +=               ")"
	_oSQLSC2:Log ()
	_aOP2Meses := aclone (_oSQLSC2:Qry2Array (.F., .F.))
	for _nOP2Meses = 1 to len (_aOP2Meses)
		_sOP2Meses = _aOP2Meses [_nOP2Meses, 1]
		u_log2 ('info', 'Reabrindo OP ' + _sOP2Meses)

		if ! sc2 -> (dbseek (xfilial ("SC2") + _sOP2Meses, .F.))
			u_help ("OP '" + _sOP2Meses + "' nao localizada na tabela SC2!!!",, .t.)
			_lRetROP = .F.
			exit
		endif

		// Campo C2_VATU1 recebe o acumulado de requisicoes pendentes de serem apropriadas no proximo apontamento.
		// Deve acumular desde a abertura da OP ou ultimo apontamento, inclusive meses anteriores.
		_oSQLSD3 := ClsSQL ():New ()
		_oSQLSD3:_sQuery := "SELECT SUM (D3_CUSTO1)"
		_oSQLSD3:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQLSD3:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_OP       = '" + _sOP2Meses + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_EMISSAO <= '" + dtos (_dReabSC2) + "'
		_oSQLSD3:_sQuery +=   " AND SD3.D3_CF    LIKE 'RE%'"
		_oSQLSD3:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQLSD3:_sQuery +=                     " FROM " + RetSQLName ("SD3") + " APONTAMENTO_POSTERIOR "
		_oSQLSD3:_sQuery +=                    " WHERE APONTAMENTO_POSTERIOR.D_E_L_E_T_  = ''"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_FILIAL   = SD3.D3_FILIAL"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_OP       = SD3.D3_OP"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_ESTORNO != 'S'"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_CF    LIKE 'PR%'"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_NUMSEQ  >= SD3.D3_NUMSEQ"
		_oSQLSD3:_sQuery +=                      " AND APONTAMENTO_POSTERIOR.D3_EMISSAO <= '" + dtos (_dReabSC2) + "'
		_oSQLSD3:_sQuery +=                   ")"
		_oSQLSD3:Log ()
		_nC2VAtu = _oSQLSD3:RetQry (1, .F.)
		u_log2 ('debug', _sOP2Meses + 'C2_VATU1 = ' + cvaltochar (_nC2VAtu))

		// Em todas as minhas simulacoes, a partir do momento em que a OP teve algum apontamento
		// (seja neste mes ou anteriores), o campo C2_VINI1 nunca mais recebeu valor.
		_oSQLSD3 := ClsSQL ():New ()
		_oSQLSD3:_sQuery := "SELECT COUNT (*)"
		_oSQLSD3:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQLSD3:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_OP       = '" + _sOP2Meses + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_EMISSAO >= '" + dtos (firstday (_dReabSC2)) + "'
		_oSQLSD3:_sQuery +=   " AND SD3.D3_EMISSAO <= '" + dtos (_dReabSC2) + "'
		_oSQLSD3:_sQuery +=   " AND SD3.D3_CF    LIKE 'PR%'"
		_oSQLSD3:Log ()
		if _oSQLSD3:RetQry (1, .F.) > 0
			u_log2 ('info', 'OP teve apontamento(s) neste mes. Vou deixar o campo C2_VINI1 zerado.')
			_nC2VIni = 0
		else
			_nC2VIni = _nC2VAtu
		endif
		u_log2 ('debug', _sOP2Meses + 'C2_VINI1 = ' + cvaltochar (_nC2VIni))

		// Valor apropriado: a soma de todos os apontamentos jah efetuados.
		_oSQLSD3 := ClsSQL ():New ()
		_oSQLSD3:_sQuery := "SELECT SUM (D3_CUSTO1)"
		_oSQLSD3:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQLSD3:_sQuery += " WHERE SD3.D_E_L_E_T_  = ''"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_FILIAL   = '" + xfilial ("SD3") + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_OP       = '" + _sOP2Meses + "'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
		_oSQLSD3:_sQuery +=   " AND SD3.D3_EMISSAO <= '" + dtos (_dReabSC2) + "'
		_oSQLSD3:_sQuery +=   " AND SD3.D3_CF    LIKE 'PR%'"
		_oSQLSD3:Log ()
		_nC2AprAtu = _oSQLSD3:RetQry (1, .F.)
		u_log2 ('debug', _sOP2Meses + 'C2_APRATU = ' + cvaltochar (_nC2AprAtu))

		// Se tem valor em C2_APRATU, o campo C2_APRINI recebe o mesmo valor.
		if _nC2AprAtu > 0
			_nC2AprIni = _nC2AprAtu
		endif

		// Se encontrou valores diferentes, ajusta no SC2.
		if sc2 -> c2_vatu1 != _nC2VAtu .or. sc2 -> c2_vini1 != _nC2VIni .or. sc2 -> c2_apratu1 != _nC2AprAtu .or. sc2 -> c2_aprini1 != _nC2AprIni
			
			// Grava evento no historico da OP
			_oEvtSC2 = ClsEvent ():New ()
			_oEvtSC2:CodEven = 'SC2002'
			_oEvtSC2:OP      = sc2 -> c2_num + sc2 -> c2_item + sc2 -> c2_sequen + sc2 -> c2_itemgrd
			_oEvtSC2:Texto   = "Ajuste campos de custos da OP por motivo de reabertura de estoques "
			if sc2 -> c2_vini1   != _nC2VIni   ; _oEvtSC2:Texto += '<cpo>C2_VINI1</cpo><de>'   + cvaltochar (sc2 -> c2_vini1)   + '</de><para>' + cvaltochar (_nC2VIni) + '</para>' ; endif
			if sc2 -> c2_vfim1   != _nC2VIni   ; _oEvtSC2:Texto += '<cpo>C2_VFIM1</cpo><de>'   + cvaltochar (sc2 -> c2_vini1)   + '</de><para>' + cvaltochar (_nC2VIni) + '</para>' ; endif
			if sc2 -> c2_aprini1 != _nC2AprIni ; _oEvtSC2:Texto += '<cpo>C2_APRINI1</cpo><de>' + cvaltochar (sc2 -> c2_aprini1) + '</de><para>' + cvaltochar (_nC2AprIni) + '</para>' ; endif
			if sc2 -> c2_aprFim1 != _nC2AprIni ; _oEvtSC2:Texto += '<cpo>C2_APRFIM1</cpo><de>' + cvaltochar (sc2 -> c2_aprfim1) + '</de><para>' + cvaltochar (_nC2AprIni) + '</para>' ; endif
			_oEvtSC2:Grava ()

			reclock ("SC2", .F.)
			sc2 -> c2_vini1 = _nC2VIni
			sc2 -> c2_vfim1 = _nC2VIni  // Valor final vai ser recalculado pelo MATA330, mas vou deixar igual pra ficar mais bonito...
			sc2 -> c2_aprini1 = _nC2AprIni
			sc2 -> c2_aprFim1 = _nC2AprIni  // Valor final vai ser recalculado pelo MATA330, mas vou deixar igual pra ficar mais bonito...
			msunlock ()
		endif
	next
return _lRetROP
