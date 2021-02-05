// Programa...: VA_RUSTk
// Autor......: Robert Koch
// Data.......: 21/12/2011
// Descricao..: Impressao de tickets referentes recebimento de uva.
//
// Historico de alteracoes:
// 16/01/2018 - Robert - Imprime tombador previsto na primeira pesagem.
// 18/01/2019 - Robert - Ajustes mensagens cargas segregadas e coleta de amostras.
// 13/12/2019 - Robert - Ajustes iniciais para safra 2020 (imprimir cod. barras com numero da carga).
// 20/01/2020 - Robert - Melhorias para integracao com portaria.
// 26/02/2020 - Robert - Campo ze_senhade passa a ser do tipo caracter.
// 15/01/2021 - Robert - Grava campo ze_imptk no final da impressao.
//

// --------------------------------------------------------------------------
User Function va_rusTk (_nQual, _sPorta, _nQtVias, _aFila, _sModelImp, _lPicote)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _nTamLin   := 41
	local _sTicket   := ""
	local _Enter     := chr (13) + chr (10)
	local _oSQL      := NIL
	local _aItens    := {}
	local _nItem     := 0
	local _nHdl      := 0
	local _sArq      := ""
	local _nVia      := 0
	local _nLinha    := 0
	local _aAmost    := {}
	local _sAvaliac  := ""
	local _nAmost	 := 0
	local _sCodBar   := ''

	_nQtVias := iif (_nQtVias == NIL, 1, _nQtVias)
	_sModelImp = upper (_sModelImp)
	
	u_Log2 ('info', 'Iniciando ' + procname ())
	u_log2 ('debug', '   Qual ticket......: ' + cvaltochar (_nQual))
	u_log2 ('debug', '   Porta............: ' + cvaltochar (_sPorta))
	u_log2 ('debug', '   Modelo impressora: ' + cvaltochar (_sModelImp))

	if type ("_lImpTick") == "L" .and. ! _lImpTick
		u_help ("Impressao disponivel somente em estacoes com impressora de ticket/cupom",, .t.)
		_lContinua = .F.
	endif
	
	// Busca os produtos da carga
	if _lContinua .and. (_nQual == 1 .or. _nQual == 2)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ZF_PRODUTO, B1_DESC, ZF_GRAU, ZF_PESO"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SZF") + " SZF, "
		_oSQL:_sQuery +=              RetSQLName ("SB1") + " SB1 "
		_oSQL:_sQuery +=  " WHERE SZF.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SZF.ZF_FILIAL  = '" + xfilial ("SZF") + "'"
		_oSQL:_sQuery +=    " AND SZF.ZF_SAFRA   = '" + sze -> ze_safra + "'"
		_oSQL:_sQuery +=    " AND SZF.ZF_CARGA   = '" + sze -> ze_carga + "'"
		_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=    " AND SB1.B1_COD     = SZF.ZF_PRODUTO"
		_oSQL:_sQuery +=  " ORDER BY SZF.ZF_PRODUTO"
		_aItens = _oSQL:Qry2Array ()
		if len (_aItens) == 0
			u_help ("Nao ha itens nesta carga.",, .t.)
			_lContinua = .F.
		endif
	endif


	if _lContinua .and. (_nQual == 1 .or. _nQual == 2)
		_sTicket := ""
		if _sModelImp == 'BEMATECH'
			_sTicket += chr(27) + '@' + _Enter
		endif
		_sTicket += padc (left (alltrim (sm0 -> m0_nomecom), _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += padc (left ('***  ENTRADA SAFRA ' + sze -> ze_safra + '  ***', _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += padc (left ('Local: ' + sze -> ze_local + '  (filial ' + alltrim (sm0 -> m0_filial) + ')', _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += _Enter
		_sTicket += 'Carga: ' + sze -> ze_carga + '   ' + dtoc (sze -> ze_data) + ' ' + sze -> ze_hora + '   ' + left (sze -> ze_placa, 3) + '-' + substr (sze -> ze_placa, 4, 4) + _Enter
	
		// Codigo de barras CODE128
		_sCodBar = alltrim (sze -> ze_filial + '-' + sze -> ze_carga)
		if _sModelImp == 'BEMATECH'
			_sTicket += '  ' + chr(29)  // Comando para codigo de barras
			_sTicket += 'H2'  // Habilita 'human readable information' no codigo de barras.
			_sTicket += chr(29) + 'h' + chr (60)  // Altura do codigo de barras (entre 1 e 255. Default = 162)
			_sTicket += chr(29) + 'kI'  // Seleciona CODE128
			_sTicket += chr(11) + _Enter // Seta o 'tamanho' do que vai constar nas barras. Teoricamente seriam 9 posicoes, mas ele cortava os dois digitos finais, entao somei 2. vai saber...
			_sTicket += _sCodBar + _Enter  // Conteudo do codigo de barras
		elseif _sModelImp == 'QUICKPRINTER'
			_sTicket += '<BARCODE128>' + _sCodBar + '<BR>' + _Enter
		endif
	
		_sTicket += padc (left (sze -> ze_assoc + '/' + sze -> ze_lojasso + ' - ' + alltrim (sze -> ze_nomasso), _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += _Enter

		// Pesquisei por 'ASCII ART CHARACERS e encontrei o site http://patorjk.com onde simulei usando a fonte 'small'
		if sze->ze_segreg == 'S'
			_sTicket += " ___ ___ ___ ___ ___ ___   _   ___ " + _Enter
			_sTicket += "/ __| __/ __| _ | __/ __| /_\ | _ \" + _Enter
			_sTicket += "\__ | _| (_ |   | _| (_ |/ _ \|   /" + _Enter
			_sTicket += "|___|___\___|_|_|___\___/_/ \_|_|_\" + _Enter
			_sTicket += _Enter
			_sTicket += "      ___   _   ___  ___   _   " + _Enter
			_sTicket += "     / __| /_\ | _ \/ __| /_\  " + _Enter
			_sTicket += "    | (__ / _ \|   | (_ |/ _ \ " + _Enter
			_sTicket += "     \___/_/ \_|_|_\\___/_/ \_\" + _Enter
			_sTicket += _Enter
		endif
		_sTicket += 'Peso bruto....: ' + transform (sze -> ze_pesobru, "@E 999,999") + ' Kg' + _Enter
		
		if _nQual == 2
			_sTicket += 'Peso tara.....: ' + transform (sze -> ze_pesotar, "@E 999,999") + ' Kg' + _Enter
			_sTicket += 'Peso liquido..: ' + transform (sze -> ze_pesobru - sze -> ze_pesotar, "@E 999,999") + ' Kg' + _Enter
		endif
		_sTicket += _Enter
		_sTicket += 'Variedade(s)                  Grau     Kg' + _Enter
		if _sModelImp == 'BEMATECH'
			_sTicket += replicate ('-', _nTamLin) + _Enter
		elseif _sModelImp == 'QUICKPRINTER'
			_sTicket += '<DLINE>' + _Enter
		endif
		for _nItem = 1 to len (_aItens)
			_sTicket += U_TamFixo (alltrim (_aItens [_nItem, 1]) + '-' + _aItens [_nItem, 2], _nTamLin - 12) + ' '
			_sTicket += iif (_nQual == 1, '    ', _aItens [_nItem, 3]) + ' '
			if _nQual == 2
				_sTicket += transform (_aItens [_nItem, 4], "@E 99,999")
			else
				_sTicket += '      '
			endif
			_sTicket += _Enter
		next


		// Monta trecho do ticket para avaliacoes da qualidade.
		if _nQual == 1  // Estou imprimindo a 1a.pesagem
			_sAvaliac = ""
			_aAmost = {}

			// Se for uma carga nao conforme, solicita amostra de todas as variedades.
			U_LOG2 ('debug', 'ZE_SEGREG: ' + sze->ze_segreg + '   ZE_AMOSTRA: ' + SZE -> ZE_AMOSTRA)
			if sze->ze_segreg == 'S' .or. SZE -> ZE_AMOSTRA == 'S'  //(type ("_lColAmCar") == 'L' .and. _lColAmCar)
				for _nItem = 1 to len (_aItens)
					if ascan (_aAmost, {|_aVal| _aVal [1] == _aItens [_nItem, 1]}) == 0
						aadd (_aAmost, {_aItens [_nItem, 1], _aItens [_nItem, 2]})
					endif
				next
			endif

			if len (_aAmost) > 0
				_sAvaliac += _Enter + _Enter
				_sAvaliac += '#########################################' + _Enter
				_sAvaliac += '########### COLETAR AMOSTRA #############' + _Enter
				for _nAmost = 1 to len (_aAmost)
					_sAvaliac += U_TamFixo (alltrim (_aAmost [_nAmost, 1]) + '-' + alltrim (_aAmost [_nAmost, 2]), 28, ' ') + 'SIM[ ] NAO[ ]' + _Enter
				next
				_sAvaliac += '#########################################' + _Enter
				_sAvaliac += '#########################################' + _Enter
				_sAvaliac += _Enter
			endif
			if ! empty (_sAvaliac)
				_sTicket += _Enter + _Enter
				_sTicket += _sAvaliac
			endif
		endif

		if _sModelImp == 'BEMATECH'
			_sTicket += replicate ('-', _nTamLin) + _Enter
		elseif _sModelImp == 'QUICKPRINTER'
			_sTicket += '<DLINE>' + _Enter
		endif
		if ! empty (sze -> ze_locdesc)
			_sTicket += "  TOMBADOR" + iif (sze -> ze_filial != '01', " PREVISTO: " + sze -> ze_locdesc, "") + "   EFETIVO: ____" + _ýEnter
			_sTicket += _Enter
		endif

		if _nQual == 1 .and. ! empty (sze -> ze_senhade)
			_sTicket += _Enter
			_sTicket += "***Senha descarga: " + sze -> ze_senhade
			_sTicket += _Enter
		endif
	endif

	if _lContinua .and. (_nQual == 4)  // Fila de descarga
		_sTicket := ""
		if _sModelImp == 'BEMATECH'
			_sTicket += chr(27) + '@' + _Enter
		endif
		_sTicket += padc (left (alltrim (sm0 -> m0_nomecom), _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += padc (left ('Fila descarga em ' + dtoc (date ()) + ' ' + time (), _nTamLin), _nTamLin, ' ') + _Enter
		_sTicket += _Enter
		for _nLinha = 1 to len (_aFila)
			_sTicket += left (_aFila [_nLinha, 6] + ' ' + alltrim (_aFila [_nLinha, 3]), _nTamLin) + _Enter
			_sTicket += left (_aFila [_nLinha, 2] + ' ' + transform (_aFila [_nLinha, 10], "@E 99,999") + ' Kg ' + alltrim (_aFila [_nLinha, 5]), _nTamLin) + _Enter
			_sTicket += _Enter
		next
	endif

	// Deixa linhas em branco para avancar papel ateh poder rasgar o ticket.
	if _lPicote
		_sTicket += _Enter
		_sTicket += _Enter
		_sTicket += _Enter
		
		// Matriz tem impressoras com corte de papel. As filiais provavelmente nao tenham, entao
		// precisa avancar papel ateh chegar na serrilha.
		if cFilAnt != '01'
			_sTicket += _Enter
			_sTicket += _Enter
			_sTicket += _Enter
			_sTicket += _Enter
			_sTicket += '.' + _Enter
		endif

		// Comando de corte parcial de papel
		if _sModelImp == 'BEMATECH'
			_sTicket += chr(27) + 'i' + _Enter
		endif
	endif

//	U_LOG2 ('info', _sTicket)

	// Grava ticket em arquivo e copia para a porta destino.
	if _lContinua .and. ! empty (_sTicket) .and. ! empty (_sPorta)
		_sArq := CriaTrab (NIL, .F.)
		_nHdl = fcreate (_sArq, 0)
		fwrite (_nHdl, _sTicket)
		fclose (_nHdl)
		u_log2 ('debug', '   Copiando ticket para a porta ' + alltrim (_sPorta))
		for _nVia = 1 to _nQtVias
			copy file (_sArq) to (alltrim (_sPorta))
		next
		delete file (_sArq)
	endif

	// Marca a carga como 'primeiro ticket jah impresso' por que este web service eh chamado em loop
	// por estacoes nas filiais, onde o servidor nao consegue enviar o ticket.
	if sze -> (fieldpos ("ZE_IMPTK")) > 0  // cpo ainda nao criado na base teste
		reclock ("SZE", .F.)
		sze -> ze_imptk = cvaltochar (_nQual)
		msunlock ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _sTicket
