// Programa:   BatTAtr
// Autor:      Robert Koch
// Data:       25/03/2011 (baseado no VA_ZZ6 de 18/08/2009)
// Cliente:    Alianca
// Descricao:  Envia e-mail aos representantes e gerentes com os titulos atrasados de seus clientes.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 
// 12/09/2014 - Catia   - Alterado para que busque os titulos com vencimento real menor do que a data que esta gerando o email
// 16/07/2018 - Robert  - Passa a enviar para o grupo 085 e nao mais fixo para aline.trentin@...
// 20/11/2018 - Sandra  - Alterado e-mail de aline.trentin@novaalianca.coop.br para financeiro@novaalianca.coop.br
// 07/04/2020 - Claudia - Alterada a busca do SX5 conforme R25. GLPI: 7339
//
// --------------------------------------------------------------------------
user function BatTAtr ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _sMsg   	:= ""
	local _sQuery 	:= ""
	local _sVend  	:= ""
	local _nLinha 	:= 0
	local _aRet   	:= {}
	local _sDest  	:= ""
	local _nSeconds := seconds ()
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	local _nEMail	:= 0
	local i         := 0
	
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()
	u_log ("Iniciando as", time ())

	sa3 -> (dbsetorder (1))

	_sQuery := " SELECT E1_VEND1, E1_PREFIXO, E1_NUM, E1_PARCELA, A1_NOME, E1_EMISSAO, E1_VENCREA, E1_VALOR, E1_SALDO, E1_HIST"
	_sQuery += " FROM " + RetSQLName ("SE1") + " SE1, "
	_sQuery +=            RetSQLName ("SA1") + " SA1 "
	_sQuery += " WHERE E1_SALDO    >  0"
	_sQuery += " AND E1_VENCREA    < '" + dtos (date ()) + "'"
	_sQuery += " AND E1_EMISSAO    >= '" + dtos (date () - 547) + "'"  // Mais velhos que 1 ano e meio, nem adianta mais cobrar...
	_sQuery += " AND E1_TIPO        = 'NF'"
	_sQuery += " AND E1_FILIAL      = '01'"
	_sQuery += " AND SE1.D_E_L_E_T_ = ''"
	_sQuery += " AND SA1.A1_FILIAL  = '  '"
	_sQuery += " AND SA1.D_E_L_E_T_ = ''"
	_sQuery += " AND SA1.A1_COD     = SE1.E1_CLIENTE"
	_sQuery += " AND SA1.A1_LOJA    = SE1.E1_LOJA"
	_sQuery += " ORDER BY E1_VEND1, E1_VENCREA"
	u_log (_squery)
	_aRet = U_Qry2Array (_sQuery)

	_nLinha = 1
	do while _nLinha <= len (_aRet)
		_lTemErro = .T.

		// Controla quebra por vendedor
		_sVend = _aRet [_nLinha, 1]
		if sa3 -> (dbseek (xfilial ("SA3") + _sVend, .F.)) .and. sa3 -> a3_ativo == "S"
			u_logIni ("Vendedor", _svend)

			// Monta cabecalho da mensagem em formato de tabela.
			_sMsg = "Titulos a receber vencidos ref. vendedor '" + _sVend + "' - " + fBuscaCpo ("SA3", 1, xfilial ("SA3") + _sVend, "A3_NOME") + chr (13) + chr (10)
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
	
			do while _nLinha <= len (_aRet) .and. _aRet [_nLinha, 1] == _sVend
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
				_nLinha ++
			enddo
			_sMsg += '</table>'
			u_log (_sMsg)

			// Financeiro recebe sempre uma copia.
			_sDest := ""
			//_sDest += "financeiro@novaalianca.coop.br"
			_aEMails = U_ZZULD ('085') [2]
			for _nEMail = 1 to len (_aEMails)
				_sDest += _aEMails [_nEMail] + iif (_nEMail < len (_aEMails), ';', '')
			next
			u_log ('_sdest ficou com', _sDest)


			// Envia copia para o representante
			if ! empty (sa3 -> a3_email) .and. alltrim (_sVend) != "001/136"  // Para a matriz não precisa enviar.
				_sDest += ";" + alltrim (sa3 -> a3_email)
			else
				U_AvisaTI ("Vendedor " + _sVend + " nao tem e-mail cadastrado no sistema.")
			endif

			if ! empty (sa3 -> a3_vageren)
				aSX580  := {}
				cQry 	:= ""
				i		:= 0
				
				// Envia copia ao gerente do representante.
				cQry := " SELECT X5_DESCSPA "
				cQry += " FROM SX5010 "
				cQry += " WHERE D_E_L_E_T_='' "
				cQry += " AND X5_TABELA  = '80'"
				cQry += " AND X5_CHAVE = '" + sa3 -> a3_vageren + "'"
				aSX580 :=  U_Qry2Array(cQry)
				
				If len(aSX580) > 0
					For i:= 1 to len(aSX580)
						If empty (aSX580[i,1]) .or. ! U_MailOk (aSX580[i,1])
							u_help ("E-mail vazio ou invalido no campo x5_descspa para o gerente " + sa3 -> a3_vageren)
						Else
							_sDest += ";" + alltrim (aSX580[i,1])
						Endif
					Next
				Else
					u_AvisaTI ("Gerente do vendedor '" + sa3 -> a3_cod + "' nao encontrado na tabela 80")
				EndIf
			else
				U_AvisaTI ("Vendedor " + _sVend + " sem gerente cadastrado no sistema.")
			endif
			
					
//			if ! empty (sa3 -> a3_vageren)
//				sx5 -> (dbsetorder (1))
//				if ! sx5 -> (dbseek (xfilial ("SX5") + "80" + sa3 -> a3_vageren, .F.))
//					u_AvisaTI ("Gerente do vendedor '" + sa3 -> a3_cod + "' nao encontrado na tabela 80")
//				else
//					if empty (sx5 -> x5_descspa) .or. ! U_MailOk (sx5 -> x5_descspa)
//						u_help ("E-mail vazio ou invalido no campo x5_descspa para o gerente " + sa3 -> a3_vageren)
//					else
//						_sDest += ";" + alltrim (sx5 -> x5_descspa)
//					endif
//				endif
//			else
//				U_AvisaTI ("Vendedor " + _sVend + " sem gerente cadastrado no sistema.")
//			endif

			// Envia com a conta da Aline para que respondam a ela.
			u_log ("destinatarios:", _sDest)

			U_SendMail (_sDest, "Verif.diaria - Ctas. receber atrasadas ", _sMsg, {}, "financeiro")


			// Dorme por um minuto por que configuramos o servidor de e-mail para nao permitir
			// envio de muitos e-mails repetidamente, buscando bloquear spams.
			sleep (1000)
			
			u_logFim ("Vendedor", _svend)
		else
			_nLinha ++
		endif
	enddo

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log ("Executou em ", seconds () - _nSeconds, "segundos.")
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
