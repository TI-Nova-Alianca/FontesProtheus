// Programa:   BatPFret
// Autor:      Robert Koch
// Data:       26/10/2017
// Descricao:  Atualiza campos de percentual medio de frete por cliente e municipio.
//             Criado, inicialmente, para ser executado em batch via agendamento na tabela ZZ6.
//
// Historico de alteracoes:
// 30/10/2017 - Robert - Chama rotina de selecao de frete somente para frete tipo CIF.
// 18/07/2018 - Robert - Parametro de 'Com tela'.
//

// --------------------------------------------------------------------------
user function BatPFret (_sCliIni, _sCliFim, _lComTela)
	local _oSQL      := NIL
	local _sMun      := ""
	local _dIni6M    := date () - 180
	local _dIni12M   := date () - 360
	local _nMediaCli := 0
	local _sAliasQ   := ""
	local _sMsg      := ""
	local _sArqLog2  := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)

	u_logIni ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT SA1.A1_EST, SA1.A1_COD_MUN, D2_CLIENTE, D2_LOJA," 
	_oSQL:_sQuery +=        " SUM (CASE WHEN SD2.D2_EMISSAO >= '" + dtos (_dIni6M) + "' THEN D2_TOTAL + SD2.D2_VALIPI + SD2.D2_ICMSRET ELSE 0 END) AS VL_NF_6M,"
	_oSQL:_sQuery +=        " SUM (CASE WHEN SD2.D2_EMISSAO >= '" + dtos (_dIni6M) + "' THEN D2_FRETCIF ELSE 0 END) AS VL_FR_6M,"
	_oSQL:_sQuery +=        " SUM (D2_TOTAL + SD2.D2_VALIPI + SD2.D2_ICMSRET) AS VL_NF_12M," 
	_oSQL:_sQuery +=        " SUM (D2_FRETCIF) AS VL_FR_12M"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SD2") + " SD2, "
	_oSQL:_sQuery +=            RetSQLName ("SF2") + " SF2, "
	_oSQL:_sQuery +=            RetSQLName ("SF4") + " SF4, "
	_oSQL:_sQuery +=            RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
	// quero todas as filiais --> _oSQL:_sQuery += " AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
	_oSQL:_sQuery += " AND SD2.D2_EMISSAO  >= '" + dtos (_dIni12M) + "'"
	_oSQL:_sQuery += " AND SD2.D2_TIPO      = 'N'"
	_oSQL:_sQuery += " AND SD2.D2_TOTAL    > 0"
	_oSQL:_sQuery += " AND SD2.D2_FRETCIF  > 0"
	if _sCliIni != NIL .and. _sCliFim != NIL
		_oSQL:_sQuery += " AND SD2.D2_CLIENTE BETWEEN '" + _sCliIni + "' AND '" + _sCliFim + "'"
	endif
	_oSQL:_sQuery += " AND SF2.D_E_L_E_T_   = ''"
	_oSQL:_sQuery += " AND SF2.F2_FILIAL    = SD2.D2_FILIAL"
	_oSQL:_sQuery += " AND SF2.F2_DOC       = SD2.D2_DOC"
	_oSQL:_sQuery += " AND SF2.F2_SERIE     = SD2.D2_SERIE"
	_oSQL:_sQuery += " AND SF2.F2_TPFRETE   = 'C'"
	_oSQL:_sQuery += " AND SF4.D_E_L_E_T_   = ''"
	_oSQL:_sQuery += " AND SF4.F4_FILIAL    = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery += " AND SF4.F4_CODIGO    = SD2.D2_TES
	_oSQL:_sQuery += " AND SF4.F4_MARGEM   IN ('1', '3')"  // 1=Margem;2=Devolucao;3=Bonificacao;4=Comodato;5=Ret.comodato;9=Nao se aplica
	_oSQL:_sQuery += " AND SA1.D_E_L_E_T_   = ''"
	_oSQL:_sQuery += " AND SA1.A1_FILIAL    = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery += " AND SA1.A1_COD       = SD2.D2_CLIENTE"
	_oSQL:_sQuery += " AND SA1.A1_LOJA      = SD2.D2_LOJA"
	_oSQL:_sQuery += " GROUP BY D2_CLIENTE, D2_LOJA, SA1.A1_EST, SA1.A1_COD_MUN"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *,"
	_oSQL:_sQuery +=        " ROUND (CASE WHEN VL_NF_6M > 0 THEN VL_FR_6M * 100 / VL_NF_6M ELSE 0 END, 2) AS P_CLI_6M,"
	_oSQL:_sQuery +=        " ROUND (VL_FR_12M * 100 / VL_NF_12M, 2) AS P_CLI_12M,"
	_oSQL:_sQuery +=        " ROUND (AVG (VL_FR_12M * 100 / VL_NF_12M) OVER (PARTITION BY A1_COD_MUN), 2) AS P_MUN_12M"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery += " ORDER BY D2_CLIENTE, D2_LOJA, A1_EST, A1_COD_MUN"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	
	sa1 -> (dbsetorder (1))
	cc2 -> (dbsetorder (1))  // CC2_FILIAL+CC2_EST+CC2_CODMUN

	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		_sMun = (_sAliasQ) -> a1_cod_mun

		// So atualiza o municipio se processar todos os clientes.
		if _sCliIni != NIL .and. _sCliFim != NIL
			if cc2 -> (dbseek (xfilial ("CC2") + (_sAliasQ) -> a1_est + (_sAliasQ) -> a1_cod_mun, .F.))
				if cc2 -> cc2_vapfre != (_sAliasQ) -> P_MUN_12M
					reclock ("CC2", .F.)
					cc2 -> cc2_vapfre = (_sAliasQ) -> P_MUN_12M
					msunlock ()

					// Nao manda atualizacao para o Mercanet neste momento, pois este campo eh usado apenas
					// na geracao da tabela MER_PERCOMP.
					// U_AtuMerc ("CC2", cc2 -> (recno ()))
				endif
			endif
		endif

		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> a1_cod_mun == _sMun
			if sa1 -> (dbseek (xfilial ("SA1") + (_sAliasQ) -> d2_cliente + (_sAliasQ) -> d2_loja, .F.))

				// Preferencialmente pela media mais recente.
				if (_sAliasQ) -> P_CLI_6M > 0
					_nMediaCli = (_sAliasQ) -> P_CLI_6M
				else
					_nMediaCli = (_sAliasQ) -> P_CLI_12M
				endif

//				// Tive um caso de media6M = 120% e media12M = 37% o que deu a entender que o frete dos
//				// primeiros 6 meses caiu nos 6 meses posteriores. Farei este testa para evitar esse
//				// tipo de situacao.
//				if (_sAliasQ) -> P_CLI_6M > 0 .and. (_sAliasQ) -> P_CLI_12M > 0  // Tem as duas medias
//					if (_sAliasQ) -> P_CLI_6M > (_sAliasQ) -> P_CLI_12M * 2  // Se deu mais que o dobro, prefiro
//					endif
//				endif

				if sa1 -> a1_vapfre != (_sAliasQ) -> P_CLI_12M
					_sMsg = 'Atualizando media frete cliente ' + (_sAliasQ) -> d2_cliente + '/' + (_sAliasQ) -> d2_loja + ' de ' + cvaltochar (sa1 -> a1_vapfre) + ' para ' + cvaltochar (_nMediaCli) + '  (media 6 meses = ' + cvaltochar ((_sAliasQ) -> P_CLI_6M) + '   media 12 meses = ' + cvaltochar ((_sAliasQ) -> P_CLI_12M) + ')'
					u_log (_sMsg)
					if _lComTela
						u_help (_sMsg)
					endif
					reclock ("SA1", .F.)
					sa1 -> a1_vapfre = min (_nMediaCli, 999)  // usa MIN para evitar percentuais maiores que 999
					msunlock ()
					
					// Nao manda atualizacao para o Mercanet neste momento, pois este campo eh usado apenas
					// na geracao da tabela MER_PERCOMP.
					// U_AtuMerc ("SA1", sa1 -> (recno ()))
				endif
			endif

			(_sAliasQ) -> (dbskip ())
		enddo
	enddo
	(_sAliasQ) -> (dbclosearea ())
	u_logFim ()
	_sArqLog = _sArqLog2
return
