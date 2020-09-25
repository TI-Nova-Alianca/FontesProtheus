// Programa:   ImpCheq
// Autor:      Robert Koch
// Data:       05/03/2008
// Cliente:    Alianca
// Descricao:  Impressao de cheques.
// 
// Historico de alteracoes:
// 10/03/2008 - Robert - Envia comandos de reinicializacao no final.
// 30/04/2008 - Robert - Implementada impressao em impressora PertoCheck.
//

// --------------------------------------------------------------------------
user function ImpCheq (_sCheque, _sBenef, _nValor, _dData, _sBanco, _sCidade, _sMoeda, _sImpress, _sCOMM)
	local _sDadChq   := ""
	local _nDllSer   := 0
	local _cPorta    := iif (_sCOMM == NIL, GetMV("MV_PORTCHE"), _sCOMM)
	local _aExt      := {}
	local _sMsgData  := ""
	local _sMsgBenef := ""
	local _sMsgCid   := ""
	local _sMsgValor := ""
	local _nPos		 := 0
	private _lRet    := .T.

	_sImpress = iif (_sImpress == NIL, "PERTO", _sImpress)
	_sCidade  = upper (alltrim (left (_sCidade, 20)))
	_sBenef   = upper (alltrim (_sBenef))

	if _sImpress == "BEMATECH"
		_sDadChq := ""
		_sDadChq += chr (Hex2Dec ("1B")) + chr (Hex2Dec ("77")) + chr (Hex2Dec ("01"))  // Controle
		_sDadChq += chr (27) + chr (Hex2Dec ("A0")) + alltrim (_sBenef) + chr (13)  // Beneficiario (favorecido)
		_sDadChq += chr (27) + chr (Hex2Dec ("A1")) + _sCidade + chr (13)  // Local
		_sDadChq += chr (27) + chr (Hex2Dec ("A2")) + _sBanco + chr (13)  // Codigo banco
		_sDadChq += chr (27) + chr (Hex2Dec ("A3")) + strtran (alltrim (str (_nValor, 18, 2)), ".", ",") + chr (13)  // Valor
		_sDadChq += chr (27) + chr (Hex2Dec ("A4")) + dtoc (_dData) + chr (13)  // Data
		_sDadChq += chr (27) + chr (Hex2Dec ("B0"))  // Imprime o cheque.
		//memowrite ("c:\temp\cheque.txt", _sdadchq)
		MsOpenPort(_nDllSer,_cPorta+":9600,n,8,1")
		MsWrite(_nDllSer,_sDadChq)
		MsClosePort(_nDllSer)
	
		if msgyesno ("Deseja imprimir a copia do cheque?")
	
			// Imprime em impressora Bematech (porta serial)
			_aExt := U_QuebraTxt (alltrim (Extenso (_nValor)), 78)
			_sDadChq := ""
			_sDadChq += chr (Hex2Dec ("1B")) + chr (Hex2Dec ("77")) + chr (Hex2Dec ("01"))  // Controle
			_sDadChq += chr (27) + "@"
			_sDadChq += chr (27) + "P"  // Seleciona modo 'Elite'
			_sDadChq += chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += "N" + chr (Hex2Dec ("A7"))  // Simbolo de numero
			_sDadChq += _sCheque + space (40) + alltrim (GetMv ("MV_SIMB" + _sMoeda)) + alltrim (transform (_nValor, "@E 999,999,999,999.99"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += _sBanco + " - " + fBuscaCpo ("SA6", 1, xfilial ("SA6") + _sBanco, "A6_NOME")
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			if len (_aExt) >= 1
				_sDadChq += _aExt [1]
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			endif
			if len (_aExt) >= 2
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
				_sDadChq += _aExt [2]
			endif
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += _sBenef
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += padl (_sCidade + ", " + strzero (day (_dData), 2) + " de " + MesExtenso (month (_dData)) + " de " + strzero (year (_dData), 4), 74, " ")
			_sDadChq += chr (Hex2Dec ("0D")) + chr (Hex2Dec ("0A")) + chr (Hex2Dec ("20")) + chr (Hex2Dec ("20"))
			_sDadChq += chr (Hex2Dec ("1B")) + chr (Hex2Dec ("77")) + "0"
			//memowrite ("c:\temp\CopiaCheque.txt", _sdadchq)
			MsOpenPort(_nDllSer,_cPorta+":9600,n,8,1")
			_sDadChq = alltrim (_sDadChq)
			do while len (_sDadChq) > 0
				MsWrite(_nDllSer, left (_sDadChq, 1))
				_sDadChq = substr (_sDadChq, 2)
			enddo
			MsClosePort(_nDllSer)
		endif

	elseif _sImpress == "PERTO"

		// Prepara dados para envio para a impressora. Jah gravo tudo em hexa
		// por que nao tenho funcao de conversao de decimal para binario.

		// Montagem da data
		_sData = dtos (_dData)
		_aDados = {}
		aadd (_aDados, Dec2Hex (asc ("!")))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 7, 1))))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 8, 1))))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 5, 1))))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 6, 1))))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 3, 1))))
		aadd (_aDados, Dec2Hex (asc (substr (_sData, 4, 1))))
		_sMsgData = _MontaMsg (_aDados)

		// Montagem da cidade
		_aDados = {}
		aadd (_aDados, Dec2Hex (asc ("#")))
		for _nPos = 1 to len (_sCidade)
			aadd (_aDados, Dec2Hex (asc (substr (_sCidade, _nPos, 1))))
		next
		_sMsgCid = _MontaMsg (_aDados)

		// Montagem do beneficiario
		_aDados = {}
		aadd (_aDados, Dec2Hex (asc ("%")))
		for _nPos = 1 to len (_sBenef)
			aadd (_aDados, Dec2Hex (asc (substr (_sBenef, _nPos, 1))))
		next
		_sMsgBenef = _MontaMsg (_aDados)

		// Montagem do valor
		_sValor = strzero (int (_nValor * 100), 12)
		_aDados = {}
		aadd (_aDados, Dec2Hex (asc ("$")))
		aadd (_aDados, "34")  // Modo de operacao
		for _nPos = 1 to len (_sValor)
			aadd (_aDados, Dec2Hex (asc (substr (_sValor, _nPos, 1))))
		next
		aadd (_aDados, Dec2Hex (asc (substr (_sBanco, 1, 1))))  // Codigo do banco.
		aadd (_aDados, Dec2Hex (asc (substr (_sBanco, 2, 1))))  // Codigo do banco.
		aadd (_aDados, Dec2Hex (asc (substr (_sBanco, 3, 1))))  // Codigo do banco.
		_sMsgValor = _MontaMsg (_aDados)

		// Montagem da copia do cheque
		_aDados = {}
		aadd (_aDados, Dec2Hex (asc ("&")))
		for _nPos = 1 to 78
			aadd (_aDados, Dec2Hex (32))  // 78 espacos (comentario 1)
		next
		aadd (_aDados, Dec2Hex (255))
		for _nPos = 1 to 78
			aadd (_aDados, Dec2Hex (32))  // 78 espacos (comentario 2)
		next
		sa6 -> (dbsetorder (1))
		if sa6 -> (dbseek (xfilial ("SA6") + _sBanco, .F.))
			_sNomeBco = padr (_sBanco + "-" + sa6 -> a6_nome, 20, " ")
		else
			_sNomeBco = _sBanco + "-" + space (20)
		endif
		aadd (_aDados, Dec2Hex (255))
		for _nPos = 1 to 20
			aadd (_aDados, Dec2Hex (asc (substr (_sNomeBco, _nPos, 1))))
		next
		aadd (_aDados, Dec2Hex (255))
		for _nPos = 1 to 6
			aadd (_aDados, Dec2Hex (asc (substr (padr (_sCheque, 6, " "), _nPos, 1))))
		next
		_sMsgCopia = _MontaMsg (_aDados)
		

		// Envio dos dados.
		do while .T.
			if MsOpenPort(_nDLLSer, _cPorta+":4800,n,8,1")
				MsgRun ("Comunicando com a impressora...", "Aguarde", {|| _lRet := _EnviaPert (_nDLLSer, _sMsgData)})
				if _lRet
					MsgRun ("Comunicando com a impressora...", "Aguarde", {|| _lRet := _EnviaPert (_nDLLSer, _sMsgCid)})
					if _lRet
						MsgRun ("Comunicando com a impressora...", "Aguarde", {|| _lRet := _EnviaPert (_nDLLSer, _sMsgBenef)})
						if _lRet
							MsgRun ("Comunicando com a impressora...", "Aguarde", {|| _lRet := _EnviaPert (_nDLLSer, _sMsgValor)})
							if _lRet
								if msgyesno ("Deseja imprimir a copia do cheque?")
									MsgRun ("Comunicando com a impressora...", "Aguarde", {|| _lRet := _EnviaPert (_nDLLSer, _sMsgCopia)})
								endif
							endif
						endif
					endif
				endif
				MsClosePort(_nDLLSer)
				exit
			else
				if msgyesno ("Nao foi possivel comunicar com a porta '" + _cPorta + "'. Tentar novamente?")
					loop
				else
					exit
				endif
			endif
		enddo
	else
		msgalert ("Funcao " + procname () + ": Modelo de impressora desconhecido: " + _sImpress)
	endif

return _lRet



// --------------------------------------------------------------------------
// Envia mensagem para impressora PertoCheck e analisa retorno.
// A cada envio, aguarda um tempo para poder ler a resposta da impressora.
static function _EnviaPert (_nDLLSer, _sMensag)
	local _sResult := ""
	local _lRet    := .T.
	local _nTempo  := 0
	local _sErro   := ""

	MsWrite(_nDLLSer, _sMensag)
	
	do while .T.
		// Aguarda no maximo 10 segundos
		for _nTempo = 1 to 15
			sleep (200)  // Aguarda 200 milissegundos para o retorno da impressora
			msread (_nDLLSer, @_sResult)
			if len (_sResult) > 1  // ! empty (substr (_sResult, 4, 3))
				
				// Encontra o codigo do erro dentro da mensagem de retorno. Como a impressora
				// manda um ACK no primeiro pacote e o codigo de erro somente no final da
				// operacao (a impressao, por exemplo, demora alguns segundos e, enquanto
				// isso, varias comunicacoes jah foram feitas).
				// Como o primeiro caracter do erro sempre tem o mesmo primeiro caracter sa
				// mensagem enviada, uso-o para encontrar o erro dentro da msg. de retorno.
				_sErro = substr (_sResult, at (substr (_sMensag, 2, 1), _sResult) + 1, 3)
				
				if _sErro != "000"
					msgalert ("Impressora retornou erro " + _sErro + " - " + _ErrPerto (_sErro))
					_lRet = .F.
				endif
			endif
			if ! empty (_sErro)
				exit
			endif
			sleep (800)  // Aguarda o restante do tempo para completar 1 segundo.
		next
		if empty (_sErro)
			if msgyesno ("A impressora nao responde. Ela esta' imprimindo?")
				loop
			else
				msgalert ("Erro de comunicacao ou impressora sem papel.")
				_lRet = .F.
				exit
			endif
		else
			exit
		endif
	enddo
return _lRet



// --------------------------------------------------------------------------
// Monta string com a mensagem para envio dos dados para impressora PertoCheck
static function _MontaMsg (_aMensag)
	local _aDados := {}
	local _nDado  := 0
	local _sDados := ""
	aadd (_aDados, "02")  // STX
	for _nDado = 1 to len (_aMensag)
		aadd (_aDados, _aMensag [_nDado])
	next
	aadd (_aDados, "03")  // ETX
	aadd (_aDados, _BCC (_aDados))  // BCC

	_sDados := ""
	for _nDado = 1 to len (_aDados)
		_sDados += chr (Hex2Dec (_aDados [_nDado]))
	next
return _sDados



// --------------------------------------------------------------------------
// Calcula do digito BCC (controle) para o pacote de dados.
// A formula eh um XOR bit a bit de todos os valores jah presentes.
static function _BCC (_aDados)
	local _sRet 	:= ""
	local _aBin 	:= {}
	local _nDado 	:= 0
	local _nBit		:= 0
	local _nChar	:= 0
	
	// Gera todos os dados em formato binario
	for _nDado = 1 to len (_aDados)
		aadd (_aBin, _Hex2Bin (_aDados [_nDado]))
	next
	
	// Gera nova string para representar os bits do caracter de controle
	_sRet = ""
	for _nChar = 1 to 8
		_sBit = substr (_aBin [1], _nChar, 1)
		for _nBit = 2 to len (_aBin)
			if substr (_aBin [_nBit], _nChar, 1) == _sBit
				_sBit = "0"
			else
				_sBit = "1"
			endif
		next
		_sRet += _sBit
	next
	
	_sRet = _Bin2Hex (_sRet)
return _sRet



// --------------------------------------------------------------------------
// Converte uma string de hexa para binario
// Autor: Fernando Machima - 25/11/03
Static Function _Hex2Bin( cHex )
	LOCAL nX, cChar, nPos
	LOCAL cRet := ''
	LOCAL cAux := '0123456789ABCDEF'
	LOCAL aHex := { '0000', '0001', '0010', '0011', '0100', '0101', '0110', '0111', ;
	                '1000', '1001', '1010', '1011', '1100', '1101', '1110', '1111' }
	For nX := 1 To Len( cHex )
		cChar := SubStr( cHex, nX, 1 )
		nPos  := At( cChar, cAux )
		If nPos <> 0
			cRet += aHex[nPos]
		EndIf
	Next
Return( cRet )



// --------------------------------------------------------------------------
// Converte uma string de binario para hexa
// Autor: Fernando Machima - 25/11/03
Static Function _Bin2Hex( cBin )
	LOCAL cChar, nPos
	LOCAL cRet := ''
	LOCAL cAux := '0123456789ABCDEF'
	LOCAL aBin := { '0000', '0001', '0010', '0011', '0100', '0101', '0110', '0111', ;
	                '1000', '1001', '1010', '1011', '1100', '1101', '1110', '1111' }
	While !Empty(cBin)
		cChar := SubStr( cBin,1,4)
		nPos:=Ascan(aBin,cChar)
		If nPos <> 0
			cRet += Subs(cAux,nPos,1)
		EndIf
		cBin:=Subs(cBin,5)
	End
Return( cRet )



// --------------------------------------------------------------------------
// Retorna descricao do erro na PertoCheck
Static Function _ErrPerto (_sCod)
	local _aErros := {}
	local _nPos := 0
	aadd (_aErros, {"000", "Sucesso na execução do comando."})
	aadd (_aErros, {"001", "Mensagem com dados inválidos."})
	aadd (_aErros, {"002", "Tamanho de mensagem inválido."})
	aadd (_aErros, {"005", "Leitura dos caracteres magnéticos inválida."})
	aadd (_aErros, {"006", "Problemas no acionamento do motor 1."})
	aadd (_aErros, {"008", "Problemas no acionamento do motor 2."})
	aadd (_aErros, {"009", "Banco diferente do solicitado."})
	aadd (_aErros, {"011", "Sensor 1 obstruído."})
	aadd (_aErros, {"012", "Sensor 2 obstruído."})
	aadd (_aErros, {"013", "Sensor 4 obstruído."})
	aadd (_aErros, {"014", "Erro no posicionamento da cabeça de impressão (relativo a S4)."})
	aadd (_aErros, {"016", "Dígito verificador do cheque não confere."})
	aadd (_aErros, {"017", "Ausência de caracteres magnéticos ou cheque na posição errada."})
	aadd (_aErros, {"018", "Tempo esgotado."})
	aadd (_aErros, {"019", "Documento mal inserido."})
	aadd (_aErros, {"020", "Cheque preso durante o alinhamento (S1 e S2 desobstruídos)."})
	aadd (_aErros, {"021", "Cheque preso durante o alinhamento (S1 obstruído e S2 desobstruído)."})
	aadd (_aErros, {"022", "Cheque preso durante o alinhamento (S1 desobstruído e S2 obstruído)."})
	aadd (_aErros, {"023", "Cheque preso durante o alinhamento (S1 e S2 obstruídos)."})
	aadd (_aErros, {"024", "Cheque preso durante o preenchimento (S1 e S2 desobstruídos)."})
	aadd (_aErros, {"025", "Cheque preso durante o preenchimento (S1 obstruído e S2 desobstruído)."})
	aadd (_aErros, {"026", "Cheque preso durante o preenchimento (S1 desobstruído e S2 obstruído)."})
	aadd (_aErros, {"027", "Cheque preso durante o preenchimento (S1 e S2 obstruídos)."})
	aadd (_aErros, {"028", "Caractere inexistente."})
	aadd (_aErros, {"030", "Não há cheques na memória."})
	aadd (_aErros, {"031", "Lista negra interna cheia"})
	aadd (_aErros, {"042", "Cheque ausente."})
	aadd (_aErros, {"043", "PINPad ou teclado ausente."})
	aadd (_aErros, {"050", "Erro de transmissão."})
	aadd (_aErros, {"051", "Erro de transmissão: Impressora offline, desconectada ou ocupada."})
	aadd (_aErros, {"052", "Erro no pin pad."})
	aadd (_aErros, {"060", "Cheque na lista negra."})
	aadd (_aErros, {"073", "Cheque não encontrado na lista negra."})
	aadd (_aErros, {"074", "Comando cancelado."})
	aadd (_aErros, {"084", "Arquivo de layout´s cheio "})
	aadd (_aErros, {"085", "Layout inexistente na memória."})
	aadd (_aErros, {"091", "Leitura de cartão inválida."})
	aadd (_aErros, {"092", "Erro na leitura da trilha 1 (somente para leitora 2 trilhas)"})
	aadd (_aErros, {"093", "Erro na leitura da trilha 2 (somente para leitora 2 trilhas)"})
	aadd (_aErros, {"094", "Erro na leitura da trilha 3 (somente para leitora 2 trilhas)"})
	aadd (_aErros, {"097", "Cheque na posição errada."})
	aadd (_aErros, {"111", "PINPad não retornou EOT."})
	aadd (_aErros, {"150", "PINPad não retornou ACK."})
	aadd (_aErros, {"155", "PINPad não responder."})
	aadd (_aErros, {"171", "Tempo esgotado na resposta do PINPad."})
	aadd (_aErros, {"253", "Erro em equipamento fiscal (Sem cidade, Falta redução Z, etc....)"})
	aadd (_aErros, {"255", "Comando inexistente."})
	_nPos = ascan (_aErros, {|_aVal| _aVal [1] == _sCod})
return iif (_nPos > 0, _aErros [_nPos, 2], "Erro desconhecido")
