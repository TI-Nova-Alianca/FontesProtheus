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
//

// --------------------------------------------------------------------------
User Function VA_REst ()
//	local cCadastro    := "Reabertura periodo fechado estoque"
//	local aSays        := {}
//	local aButtons     := {}
//	local nOpca        := 0
//	local lPerg        := .F.
	local _nLock       := 0



	u_logId ()

	// Somente uma estacao por vez.
	_nLock := U_Semaforo (procname (), .T.)
	if _nLock == 0
	//	u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
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
	
	
	/*
// --------------------------------------------------------------------------
Static Function _TudoOk()
//	Local _aArea    := GetArea()
	Local _lRet     := .T.
//	RestArea(_aArea)
Return(_lRet)
*/


// --------------------------------------------------------------------------
Static Function _AiQueMedo ()
	local _lContinua  := .T.
	local _oEvento    := NIL
	local _oSQL       := NIL
	local _oSQLSB9    := NIL
	local _oSQLSBJ    := NIL
	local _oSQLSBK    := NIL
	local _oSQLSC2    := NIL
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
			u_help ("Inconsistencia entre a maior data da tabela SB9 (" + dtoc (_dDataSB9) + ") e o parametro MV_ULMES (" + dtoc (GetMv ("MV_ULMES")) + "). Verifique!")
			_lContinua = .F.
		endif
	
		if ! empty (_dDataSBJ)
			if _dDataSB9 != _dDataSBJ
				u_help ("Inconsistencia entre a maior data das tabelas SB9 (" + dtoc (_dDataSB9) + "), SBJ (" + dtoc (_dDataSBJ) + ") e SBK (" + dtoc (_dDataSBK) + "). Verifique!")
				_lContinua = .F.
			endif
		endif
		if ! empty (_dDataSBK)
			if _dDataSB9 != _dDataSBK
				u_help ("Inconsistencia entre a maior data das tabelas SB9 (" + dtoc (_dDataSB9) + "), SBJ (" + dtoc (_dDataSBJ) + ") e SBK (" + dtoc (_dDataSBK) + "). Verifique!")
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		_lContinua = U_msgnoyes ("O ultimo fechamento de estoques da filial atual foi feito em " + dtoc (_dDataSB9) + ". Confirma reabertura deste mes?")
	endif

	if _lContinua
		_dMesAnt = lastday (firstday (_dDataSB9) - 1)
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
			u_help ("Processo nao pode ser realizado neste momento por que o periodo solicitado nao se encontra 'aberto' no calendario contabil.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		procregua (10)
		incproc ("Gerando backup SB9")
		
		// Monta filtros separadamente, para posterior uso na delecao dos registros.
		_sWhereSB9 := " WHERE D_E_L_E_T_ = '' AND B9_FILIAL  = '" + xfilial ("SB9") + "' AND B9_DATA = '" + dtos (_dDataSB9) + "'"
		_sWhereSBJ := " WHERE D_E_L_E_T_ = '' AND BJ_FILIAL  = '" + xfilial ("SBJ") + "' AND BJ_DATA = '" + dtos (_dDataSBJ) + "'"
		_sWhereSBK := " WHERE D_E_L_E_T_ = '' AND BK_FILIAL  = '" + xfilial ("SBK") + "' AND BK_DATA = '" + dtos (_dDataSBK) + "'"
		
		// Exporta backup para DBF
		_oSQLSB9 := ClsSQL ():New ()
		_oSQLSBJ := ClsSQL ():New ()
		_oSQLSBK := ClsSQL ():New ()
		_oSQLSB9:_sQuery := " SELECT * FROM " + RetSQLName ("SB9") + _sWhereSB9
		_oSQLSBJ:_sQuery := " SELECT * FROM " + RetSQLName ("SBJ") + _sWhereSBJ
		_oSQLSBK:_sQuery := " SELECT * FROM " + RetSQLName ("SBK") + _sWhereSBK

		_sBkpSB9 = "\backups\Bkp_reab_SB9_filial_" + xfilial ("SB9") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")
		_sBkpSBJ = "\backups\Bkp_reab_SBJ_filial_" + xfilial ("SBJ") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")
		_sBkpSBK = "\backups\Bkp_reab_SBK_filial_" + xfilial ("SBK") + "_em_" + dtos (date ()) + "_" + strtran (time (), ":", "")

		// Cria diretorio para os arquivos de backup
		_sDirLogs = '\backups\'
		makedir (_sDirLogs)
		
		incproc ("Gerando backup SB9")
		_sAliasQ := _oSQLSB9:Qry2Trb (.T.)
		copy to (_sBkpSB9)
		if GetMV ("MV_RASTRO") == "S"
			incproc ("Gerando backup SBJ")
			_sAliasQ := _oSQLSBJ:Qry2Trb (.T.)
			copy to (_sBkpSBJ)
			incproc ("Gerando backup SBK")
			_sAliasQ := _oSQLSBK:Qry2Trb (.T.)
			copy to (_sBkpSBK)
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
		U_LOG (_oSQLSB9:_sQuery)
		U_LOG (_oSQLSBJ:_sQuery)
		U_LOG (_oSQLSBK:_sQuery)

		if GetMV ("MV_RASTRO") == "S"
			_lContinua = _oSQLSBK:Exec () .and. _oSQLSBJ:Exec () .and. _oSQLSB9:Exec ()
		else
			_lContinua = _oSQLSB9:Exec ()
		endif
		if _lContinua
			// Ajusta parametro no configurador.
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

		// Verifica existencia de OPs com apontamento dentro do mes reaberto e em meses posteriores.
		// Seria possivel ajustar o SC2 jah no nomento da reabertura? Campos C2_APRATU, C2_APRINI, C2_APRFIM ?
		_oSQLSC2 := ClsSQL ():New ()
		_oSQLSC2:_sQuery := "SELECT rtrim (STRING_AGG (rtrim (D3_OP), ','))"
		_oSQLSC2:_sQuery +=  " FROM " + RetSQLName ("SD3") + " SD3 "
		_oSQLSC2:_sQuery += " WHERE SD3.D_E_L_E_T_ = ''"
		_oSQLSC2:_sQuery +=   " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
		_oSQLSC2:_sQuery +=   " AND SD3.D3_ESTORNO != 'S'"
		_oSQLSC2:_sQuery +=   " AND SD3.D3_EMISSAO <= '" + DTOS (_dDataSB9) + "'"
		_oSQLSC2:_sQuery +=   " AND SD3.D3_EMISSAO >= '" + DTOS (_dDataSB9 - 180) + "'"  // Por questao de performance, vou assumir que nao temos OP com muito tempo em aberto
		_oSQLSC2:_sQuery +=   " AND SD3.D3_OP      != ''"
		_oSQLSC2:_sQuery +=   " AND EXISTS (SELECT *"
		_oSQLSC2:_sQuery +=                 " FROM " + RetSQLName ("SD3") + " PROXIMO "
		_oSQLSC2:_sQuery +=                " WHERE PROXIMO.D_E_L_E_T_  = ''"
		_oSQLSC2:_sQuery +=                  " AND PROXIMO.D3_FILIAL   = SD3.D3_FILIAL"
		_oSQLSC2:_sQuery +=                  " AND PROXIMO.D3_OP       = SD3.D3_OP"
		_oSQLSC2:_sQuery +=                  " AND PROXIMO.D3_ESTORNO != 'S'"
		_oSQLSC2:_sQuery +=                  " AND PROXIMO.D3_EMISSAO  > '" + DTOS (_dDataSB9) + "'"
		_oSQLSC2:_sQuery +=               ")"
		_oSQLSC2:Log ()
		_sOP2Meses := alltrim (_oSQLSC2:RetQry ())
		if ! empty (_sOP2Meses)
			u_help ("A T E N C A O: As OPs a seguir tem movimentacao no mes reaberto e posteriores. A rotina de virada de saldos (ponto de entrada A280OK) ja deve ter deixado pronto um backup dessas OPs. Verifique necessidade de voltar backup da tabela SC2 para estes casos: " + _sOP2Meses)
		endif

		u_help ("Processo concluido. Nova data de fechamento: " + dtoc (_dMesAnt))
	endif
return
