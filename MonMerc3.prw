// Programa...: MonMerc3
// Autor......: Robert Koch
// Data.......: 13/03/2017
// Descricao..: Tela de monitoramento de integracao (novos clientes) com sistema Mercanet

// #TipoDePrograma    #Consulta
// #Descricao         #Tela de monitoramento de integracao com sistema Mercanet (receber novos clientes)
// #PalavasChave      #Mercanet #integracao
// #TabelasPrincipais #SA1
// #Modulos           #FAT

// Historico de alteracoes:
// 28/07/2017 - Robert - Passa a usar a view VA_VMONITOR_MERCANET_CLIENTES.
// 04/08/2017 - Robert - Nao limpava o campo ZA1_PROCRT ao solicitar reprocessamento do cliente.
// 09/06/2020 - Claudia - Incluida validação de quantidade de linha, conforme GLPI:ID 8042 
// 30/07/2020 - Cláudia - Incluida nova coluna de minutos rodados. GLPI: 8222
// 25/03/2022 - Robert  - Passa a buscar caminho do banco de dados via funcao U_LkServer() - GLPI 11770
//                      - Nao usa mais a VA_VMONITOR_MERCANET_CLIENTES (internalizado nesta funcao).
//

// -------------------------------------------------------------------------------------------------
User Function MonMerc3 ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _sCNPJ      := space (14)
	local _dDataIni   := date ()

	do while .T.
		_sCNPJ    = U_Get ("CNPJ (vazio=todos)", "C", 14, "", "", _sCNPJ, .F., ".T.")
		_dDataIni = U_Get ("Data inclusao no Mercanet a partir de", "D", 8, "@D", "", _dDataIni, .F., ".T.")

		if empty (_dDataIni)
			u_help ("Informe data inicial")
		else
			processa ({|| _Tela (_sCNPJ, _dDataIni)})
		endif
		
		if ! u_msgyesno ("Deseja fazer nova consulta?")
			exit
		endif
	enddo

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)

Return
// --------------------------------------------------------------------------
//
Static Function _Tela (_sCNPJ, _dDataIni)
	local _oSQL     := NIL
	local _aCols    := {}
	local _aCli     := {}
	local _nCli     := 0
	local _lTemErro := .F.
	local _sLinkSrv := ""

	_sLinkSrv = U_LkServer ('MERCANET')
	if empty (_sLinkSrv)
		u_help ("Sem definicao para comunicacao com banco de dados do Mercanet.",, .t.)
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "WITH MONITOR AS ("
		_oSQL:_sQuery += " SELECT ' ' AS OK, dbo.VA_STOD(ZA1_DTINC) + ' ' + ZA1_HRINC AS GRAVACAO"
		_oSQL:_sQuery +=       ", CASE ZA1_STATUS"
		_oSQL:_sQuery +=             " WHEN 'INS' THEN 'AINDA NAO LIDO PELO PROTHEUS'"
		_oSQL:_sQuery +=             " WHEN 'PRO' THEN CASE WHEN ZA1_PROCRT = 'S' THEN 'PROTH.OK/MERC.OK'"
		_oSQL:_sQuery +=                        " ELSE 'PROTH.OK/AGUARDA MERC'"
		_oSQL:_sQuery +=                        " END "
		_oSQL:_sQuery +=             " WHEN 'ERR' THEN 'ERRO NO PROTHEUS'"
		_oSQL:_sQuery +=             " END AS RESULTADO"
		_oSQL:_sQuery +=       ", ZA1_CODMER AS COD_MERCANET"
		_oSQL:_sQuery +=       ", ISNULL(SA1.A1_COD, '') AS COD_PROTHEUS"
		_oSQL:_sQuery +=       ", ZA1_CGC as CNPJ"
		_oSQL:_sQuery +=       ", ZA1_NOME AS NOME"
		_oSQL:_sQuery +=       ", ZA1_ERRO AS MSG_ERRO"
		_oSQL:_sQuery += " FROM " + _sLinkSrv + ".ZA1010"
		_oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=      " ON (SA1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=      " AND SA1.A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_oSQL:_sQuery +=      " AND SA1.A1_CGC = ZA1_CGC COLLATE DATABASE_DEFAULT)"
		_oSQL:_sQuery += " WHERE ZA1_FILIAL = ''"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT ' ' AS OK"
		_oSQL:_sQuery +=       " ,GRAVACAO"
		_oSQL:_sQuery +=       " ,RESULTADO"
		_oSQL:_sQuery +=       " ,COD_MERCANET"
		_oSQL:_sQuery +=       " ,COD_PROTHEUS"
		_oSQL:_sQuery +=       " ,NOME"
		_oSQL:_sQuery +=       " ,MSG_ERRO"
		_oSQL:_sQuery +=       " ,CASE WHEN ZA1_STATUS = 'INS'"
		_oSQL:_sQuery +=                  " AND ZA1_DTINI != ''"
		_oSQL:_sQuery +=                  " AND ZA1_HRINI != ''"
		_oSQL:_sQuery +=             " THEN DATEDIFF(MINUTE, CAST(ZA1_DTINI + ' ' + ZA1_HRINI AS DATETIME), CURRENT_TIMESTAMP)"
		_oSQL:_sQuery +=             " ELSE 0"
		_oSQL:_sQuery +=             " END AS MINUTOS_RODANDO"
		_oSQL:_sQuery += " FROM MONITOR"
//		_oSQL:_sQuery += " LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.ZA1010 AS ZA1 "
		_oSQL:_sQuery += " LEFT JOIN " + _sLinkSrv + ".ZA1010 AS ZA1 "
		_oSQL:_sQuery +=      " ON (ZA1.ZA1_COD = COD_PROTHEUS COLLATE Latin1_General_CI_AI"
		_oSQL:_sQuery +=      " AND ZA1.ZA1_CGC = CNPJ COLLATE Latin1_General_CI_AI)"
		_oSQL:_sQuery += " WHERE 1 = 1"
		if ! empty (_dDataIni)
			_oSQL:_sQuery += " AND GRAVACAO >= '" + dtos (_dDataIni) + " 00:00'"
		endif
		if ! empty (_sCNPJ)
			_oSQL:_sQuery += " AND CNPJ like '%" + _sCNPJ + "%'"
		endif
		_oSQL:_sQuery += " ORDER BY GRAVACAO"
		_oSQL:Log ()
		_aCli := aclone (_oSQL:Qry2Array ())

		if len (_aCli) == 0
			u_help ("Nao foi encontrado nenhum registro dentro dos parametros informados.")
		else
			if len (_aCli) >= 5000
				u_help ("Período com mais de 5000 registros. Selecione um período menor")
			else

				// Prepara dados para a funcao U_MBArray.
				for _nCli = 1 to len (_aCli)
					_aCli [_nCli, 1] = .F.
				next
				_aCols = {}
				aadd (_aCols, {2, "Incl.Mercanet"		,  70, ""})
				aadd (_aCols, {3, "Situacao"			, 100, ""})
				aadd (_aCols, {4, "Cod.Mercanet"		,  40, ""})
				aadd (_aCols, {5, "Cod.Protheus"		,  40, ""})
				aadd (_aCols, {6, "Nome"				, 140, ""})
				aadd (_aCols, {7, "Msg Protheus"		, 170, ""})
				aadd (_aCols, {8, "Minutos rodando"		,  30, ""})
				U_MbArray (@_aCli, "Leitura de novos clientes do sistema Mercanet", _aCols, 1,,,)
				
				// Verifica se tem pedidos 'reprocessaveis'.
				_lTemErro = .F.
				for _nCli = 1 to len (_aCli)
					if _aCli [_nCli, 1] .and. ! empty (_aCli [_nCli, 7])
						_lTemErro = .T.
						exit
					endif
				next
				if _lTemErro .and. U_MsgNoYes ("Deseja solicitar reprocessamento dos registros selecionados?")
					for _nCli = 1 to len (_aCli)
						if _aCli [_nCli, 1] .and. ! empty (_aCli [_nCli, 7])
							_oSQL := ClsSQL ():New ()
					//		_oSQL:_sQuery := "UPDATE LKSRV_MERCANETPRD.MercanetPRD.dbo.ZA1010"
							_oSQL:_sQuery := "UPDATE " + _sLinkSrv + ".ZA1010"
							_oSQL:_sQuery +=   " SET ZA1_DTINI  = '', ZA1_HRINI  = '', ZA1_STATUS = 'INS', ZA1_PROCRT = ' '"
							_oSQL:_sQuery += " WHERE ZA1_FILIAL = '' AND ZA1_CODMER = '" + _aCli [_nCli, 4] + "'"
							_oSQL:Log ()
							_oSQL:Exec ()
						endif
					next
				endif
			endif
		endif
	endif
return
