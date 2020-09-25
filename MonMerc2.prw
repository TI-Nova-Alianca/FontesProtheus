// Programa...: MonMerc2
// Autor......: Robert Koch
// Data.......: 13/03/2017
// Descricao..: Tela de monitoramento de integracao (recebimento de pedidos) com sistema Mercanet
//
// Historico de alteracoes:
// 05/12/2019 - Robert - Nao funcionava informando apenas a data.
// 06/05/2020 - Robert - Nao limpava o campo ZC5_ERRO ao solicitar reprocessamento do pedido.
// 12/05/2020 - Robert - Criada coluna calculando ha quantos minutos iniciou a importacao
//                     - Pedidos com importacao iniciada ha mais de alguns minutos sao reprocessaveis
//                     - Melhorada mensagem de 'ainda nao lido' para 'Importacao iniciada as ...'
//                     - Valida pedido a pedido se vai aceitar o reprocessamento.
// 14/05/2020 - Robert - Criado tratamento para mostrar status CAN.
//

// --------------------------------------------------------------------------
user function MonMerc2 ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _sPedMerc   := space (9)
	local _dDataIni   := date ()
	local _sSituacao  := 'P'

	u_logId ()
	u_logIni ()

	do while .T.
		_sPedMerc  = U_Get ("Pedido no Mercanet (vazio=todos)", "C", 9, "9999/9999", "", _sPedMerc, .F., ".T.")
		_dDataIni  = U_Get ("Data inclusao no Mercanet a partir de", "D", 8, "@D", "", _dDataIni, .F., ".T.")
		_sSituacao = U_Get ("Situacao dos pedidos: P=pendentes;T=todos", "C", 1, "@!", "", _sSituacao, .F., ".T.")

		if empty (_dDataIni)
			u_help ("Informe data inicial")
		else
			processa ({|| _Tela (_sPedMerc, _dDataIni, _sSituacao)})
		endif
		
		if ! u_msgyesno ("Deseja fazer nova consulta?")
			exit
		endif
	enddo

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return



// --------------------------------------------------------------------------
static function _Tela (_sPedMerc, _dDataIni, _sSituacao)
	local _oSQL     := NIL
	local _aCols    := {}
	local _aPed     := {}
	local _lTemErro := .F.
	local _nPed     := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ' ' AS OK,"
	_oSQL:_sQuery +=        " dbo.VA_STOD(ZC5_DTINC) + ' ' + ZC5_HRINC AS GRAVACAO,"
//	_oSQL:_sQuery +=        " CASE ZC5_STATUS WHEN 'INS' THEN 'AINDA NAO LIDO' WHEN 'PRO' THEN 'ACEITO' WHEN 'ERR' THEN 'ERRO' END AS RESULTADO,"
	_oSQL:_sQuery +=        " CASE ZC5_STATUS"
	_oSQL:_sQuery +=             " WHEN 'INS'"
	_oSQL:_sQuery +=                  " THEN CASE WHEN ZC5_DTINI = '' AND ZC5_HRINI = ''"
	_oSQL:_sQuery +=                       " THEN 'AINDA NAO LIDO' ELSE 'IMPORT.INICIADA EM ' + dbo.VA_DTOC (ZC5_DTINI) + ' ' + ZC5_HRINI END"
	_oSQL:_sQuery +=             " WHEN 'PRO' THEN 'ACEITO'"
	_oSQL:_sQuery +=             " WHEN 'ERR' THEN 'ERRO'"
	_oSQL:_sQuery +=             " WHEN 'CAN' THEN 'IMPORT.CANCELADA'"
	_oSQL:_sQuery +=        " END AS RESULTADO,"
	_oSQL:_sQuery +=        " ZC5_PEDMER AS PED_MERCANET, "
	_oSQL:_sQuery +=        " ISNULL (SC5.C5_NUM, '') AS PED_PROTHEUS, "
	_oSQL:_sQuery +=        " ZC5_PEDCLI AS ORDEM_COMPRA, "
	_oSQL:_sQuery +=        " ZC5_VEND1 AS REPRES, "
	_oSQL:_sQuery +=        " ZC5_VTOT AS VALOR, "
	_oSQL:_sQuery +=        " ZC5_CLIENT AS CLIENTE, "
	_oSQL:_sQuery +=        " ZC5_LOJACL AS LOJA, "
	_oSQL:_sQuery +=        " ZC5_TRANSP AS TRANSP, "
	_oSQL:_sQuery +=        " ZC5_CONDPA AS COND_PG, "
	_oSQL:_sQuery +=        " ZC5_TABELA AS TABELA, "
	_oSQL:_sQuery +=        " ZC5_ERRO AS MSG_ERRO,"
	_oSQL:_sQuery +=        " CASE WHEN ZC5_STATUS = 'INS' AND ZC5_DTINI != '' AND ZC5_HRINI != '' THEN datediff (minute, cast (ZC5_DTINI + ' ' + ZC5_HRINI as DATETIME), CURRENT_TIMESTAMP) ELSE 0 END AS MINUTOS_RODANDO"
	_oSQL:_sQuery +=  " FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.ZC5010"
	_oSQL:_sQuery +=  " LEFT JOIN " + RetSQLName ("SC5") + " SC5 "
	_oSQL:_sQuery +=         " ON (SC5.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=         " AND SC5.C5_FILIAL = '" + xfilial ("SC5") + "'"
	_oSQL:_sQuery +=         " AND SC5.C5_VAPDMER = ZC5_PEDMER COLLATE DATABASE_DEFAULT)"
	_oSQL:_sQuery += " WHERE ZC5_FILIAL = '1'"
	if ! empty (strtran (_sPedMerc, '/', ''))
		_oSQL:_sQuery += " AND ZC5_PEDMER = '" + _sPedMerc + "'"
	endif
	if ! empty (_dDataIni)
		_oSQL:_sQuery += " AND ZC5_DTINC >= '" + dtos (_dDataIni) + "'"
	endif
	if _sSituacao == 'P'
		_oSQL:_sQuery += " AND ZC5_STATUS IN ('INS', 'ERR')"
	endif
	_oSQL:_sQuery += " ORDER BY ZC5_DTINC + ZC5_HRINC"
	_oSQL:Log ()
	_aPed := aclone (_oSQL:Qry2Array ())
	u_log (_aPed)

	// Prepara dados para a funcao U_MBArray.
	for _nPed = 1 to len (_aPed)
		_aPed [_nPed, 1] = .F.
	next
	_aCols = {}
	aadd (_aCols, {2,  "Incl.Mercanet",   70, ""})
	aadd (_aCols, {3,  "Situacao",        50, ""})
	aadd (_aCols, {4,  "Ped.Mercanet",    40, ""})
	aadd (_aCols, {5,  "Ped.Protheus",    40, ""})
	aadd (_aCols, {6,  "Ped.cliente",     40, ""})
	aadd (_aCols, {7,  "Repres",          30, ""})
	aadd (_aCols, {8,  "Valor",           60, "@E 999,999,999.99"})
	aadd (_aCols, {9,  "Cliente",         50, ""})
	aadd (_aCols, {10, "Loja",            25, ""})
	aadd (_aCols, {11, "Transp",          30, ""})
	aadd (_aCols, {12, "Cond.",           30, ""})
	aadd (_aCols, {13, "Tabela",          30, ""})
	aadd (_aCols, {14, "Msg erro",       170, ""})
	aadd (_aCols, {15, "Minutos rodando", 50, ""})
	U_MbArray (@_aPed, "Leitura de pedidos do sistema Mercanet", _aCols, 1,,,)
	
	// Verifica se tem pedidos 'reprocessaveis'.
	_lTemErro = .F.
	for _nPed = 1 to len (_aPed)
		if _aPed [_nPed, 1]  // Usuario selecionou para reprocessar.
			if empty (_aPed [_nPed, 14]) .and. _aPed [_nPed, 15] < 5
				u_help ('Nao considero o pedido ' + _aPed [_nPed, 4] + ' numa situacao que precise reimportar (Nao ha mensagem de erro, nem importacao iniciada ha mais de 5 minutos).')
				_aPed [_nPed, 1] = .F.
			else
				u_log ('Concordo em reprocessar o pedido', _aPed [_nPed, 4])
				_lTemErro = .T.
			endif
		endif
	next
	if _lTemErro .and. U_MsgNoYes ("Deseja solicitar reprocessamento dos pedidos selecionados?")
		for _nPed = 1 to len (_aPed)
			if _aPed [_nPed, 1] // .and. ! empty (_aPed [_nPed, 14])
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := "UPDATE LKSRV_MERCANETPRD.MercanetPRD.dbo.ZC5010"
//				_oSQL:_sQuery +=   " SET ZC5_DTINI  = '', ZC5_HRINI  = '', ZC5_STATUS = 'INS'"
				_oSQL:_sQuery +=   " SET ZC5_DTINI  = '', ZC5_HRINI  = '', ZC5_STATUS = 'INS', ZC5_ERRO = ''"
				_oSQL:_sQuery += " where ZC5_FILIAL = '1' AND ZC5_PEDMER = '" + _aPed [_nPed, 4] + "'"
				_oSQL:Log ()
				_oSQL:Exec ()
			endif
		next
	endif
return
