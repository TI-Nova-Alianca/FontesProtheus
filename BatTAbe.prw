// Programa:   BatTAbe
// Autor:      Robert Koch
// Data:       25/03/2011
// Cliente:    Alianca
// Descricao:  Envia e-mail com titulos em aberto de determinados clientes. Especifico
//             para uma pessoa que gerencia compras de diversos clientes.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 19/07/2011 - Robert - Incluidos novos clientes: '011741','013011','009985'.
// 20/11/2018 - Sandra - Alterado e-mail de aline.trentin@novaalianca.coop.br para financeiro@novaalianca.coop.br

// --------------------------------------------------------------------------
user function BatTAbe ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sMsg   := ""
	local _sQuery := ""
	local _sVend  := ""
	local _nLinha := 0
	local _aRet   := {}
	local _sDest  := ""
	local _nSeconds := seconds ()
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()
	u_log ("Iniciando as", time ())

	_sQuery := " SELECT E1_VEND1, E1_PREFIXO, E1_NUM, E1_PARCELA, A1_NOME, E1_EMISSAO, E1_VENCREA, E1_VALOR, E1_SALDO, E1_HIST"
	_sQuery += " FROM " + RetSQLName ("SE1") + " SE1, "
	_sQuery +=            RetSQLName ("SA1") + " SA1 "
	_sQuery += " WHERE E1_SALDO    >  0"
	_sQuery += " AND E1_TIPO        = 'NF'"
	_sQuery += " AND E1_FILIAL      = '01'"
	_sQuery += " AND SE1.D_E_L_E_T_ = ''"
	_sQuery += " AND SA1.A1_FILIAL  = '  '"
	_sQuery += " AND SA1.D_E_L_E_T_ = ''"
	_sQuery += " AND SA1.A1_COD     = SE1.E1_CLIENTE"
	_sQuery += " AND SA1.A1_LOJA    = SE1.E1_LOJA"
	_sQuery += " AND SE1.E1_CLIENTE IN ('011371','011752','010810','011771','011585','011363','011741','013011','009985','012943','013646','013273','008256')"
	_sQuery += " ORDER BY E1_CLIENTE, E1_LOJA, E1_VENCREA, E1_PREFIXO, E1_NUM, E1_PARCELA"
	u_log (_squery)
	_aRet = U_Qry2Array (_sQuery)

	if len (_aRet) > 0
	
		// Monta cabecalho da mensagem em formato de tabela.
		_sMsg = "Titulos com saldo clientes especificos" + chr (13) + chr (10)
		_sMsg += '<table border="1" width="100%" id="table9">'
		_sMsg += '	<tr>'
		_sMsg += '		<td><b>Prefixo</b></td>'
		_sMsg += '		<td><b>Numero</b></td>'
		_sMsg += '		<td><b>Parcela</b></td>'
		_sMsg += '		<td><b>Cliente</b></td>'
		_sMsg += '		<td><b>Emissao</b></td>'
		_sMsg += '		<td><b>Vencimento</b></td>'
		_sMsg += '		<td><b>Vl.original</b></td>'
		_sMsg += '		<td><b>Saldo</b></td>'
		_sMsg += '		<td><b>Historico</b></td>'
		_sMsg += '	</tr>'
		for _nLinha = 1 to len (_aRet)
			_sMsg += '	<tr>'
			_sMsg += '		<td>' + _aRet [_nLinha, 2] + '</td>'
			_sMsg += '		<td>' + _aRet [_nLinha, 3] + '</td>'
			_sMsg += '		<td>' + _aRet [_nLinha, 4] + '</td>'
			_sMsg += '		<td>' + alltrim (_aRet [_nLinha, 5]) + '</td>'
			_sMsg += '		<td>' + dtoc (_aRet [_nLinha, 6]) + '</td>'
			_sMsg += '		<td>' + dtoc (_aRet [_nLinha, 7]) + '</td>'
			_sMsg += '		<td align="right">' + alltrim (transform (_aRet [_nLinha, 8], "@E 999,999,999.99")) + '</td>'
			_sMsg += '		<td align="right">' + alltrim (transform (_aRet [_nLinha, 9], "@E 999,999,999.99")) + '</td>'
			_sMsg += '		<td>' + alltrim (_aRet [_nLinha, 10]) + '</td>'
			_sMsg += '	</tr>'
		next
		_sMsg += '</table>'

		// Financeiro recebe sempre uma copia.
		_sDest := ""
		_sDest += ";financeiro@novaalianca.coop.br"
		U_SendMail (_sDest, "Titulos com saldo clientes especificos", _sMsg, {}, "financeiro")
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log ("Executou em ", seconds () - _nSeconds, "segundos.")
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
