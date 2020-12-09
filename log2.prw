// Programa: Log2
// Autor...: Robert Koch
// Data....: 03/06/2020
// Funcao..: Grava arquivo de log em texto para conferencia
//
// Historico de alteracoes:
// 15/06/2020 - Robert - Verifica existencia da variavel cFilAnt antes de usa-la.
// 15/10/2020 - Robert - TRatamento para dado tipo NIL.
//

// --------------------------------------------------------------------------
user function Log2 (_sTipo, _xDado, _xExtra)
	local _sTextoLog := ''
	local _i         := 0
	local _sPCham    := ""
	local _lUmaLinha := .T.
	local _sDirLogs  := ''
	local _nHdl      := ''
	local _sDataLog  := dtos (date ())

	if type ("_sArqLog") != "C"
		_sArqLog = alltrim (funname (1)) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + "_" + dtos (date ()) + ".log"
	endif

	if _xExtra != NIL
		U_Log2 ('AVISO', '[' + procname () + '] Parametro extra ignorado: ' + cvaltochar (_xExtra))
	endif

	_sPCham = procname (1)
	_i = 2
	do while procname (_i) != "" .and. _i <= 5
		_sPCham += " => " + procname (_i)
		_i++
	enddo

	_sTipo = upper (cvaltochar (_sTipo))
	if ! 'ERRO' $ _sTipo
		_sTipo = Capital (_sTipo)
	endif
	_sTextoLog += '[' + padc (_sTipo, 5, ' ') + ']'  // + ' ; '
	//_sTextoLog += dtoc (date ()) + ' ' + time () + ' '  // + ' ; '
	_sTextoLog += '[' + substr (_sDataLog, 1, 4) + '' + substr (_sDataLog, 5, 2) + '' + substr (_sDataLog, 7, 2) + ' ' + strtran (TimeFull (), '.', ',') + ']'
	_sTextoLog += '[' + GetEnvServer () + ']'
	_sTextoLog += '[F' + iif (type ('cFilAnt') == 'C', cFilAnt, '  ') + ']'  // + ' ; '
	_xTextoLog = padc (_sTextoLog, 30, ' ')

	// Verifica se consegue gravar tudo em uma linha apenas
/*	if ! valtype (_xDado) $ 'A/O'
		_xDado = alltrim (cValToChar (_xDado))
		_sTextoLog += padr (_xDado, max (len (_xDado), 100))
	else
		_sTextoLog += padr (' variavel tipo ' + valtype (_xDado), 100)
		_lUmaLinha = .F.
	endif
*/
	if valtype (_xDado) $ 'A/O'
		_sTextoLog += padr (' variavel tipo ' + valtype (_xDado), 100)
		_lUmaLinha = .F.
	else
		if valtype (_xDado) == 'U'
			_xDado = '*NIL*'
		else
			_xDado = alltrim (cValToChar (_xDado))
		endif
		_sTextoLog += padr (_xDado, max (len (_xDado), 100))
	endif

	if _sTipo == 'DEBUG'
		_sTextoLog += ' ; '
		_sTextoLog += 'Usr:' + padr (iif (type ("cUserName") == "C", cUserName, ''), 10) + ' ; '
		_sTextoLog += 'Comp:' + GetComputerName () + ' ; '
		_sTextoLog += 'Pilha:' + _sPCham + ' ; '
	endif

	// Grava log em diretorio especifico. Se ainda nao existir, cria-o.
	_sDirLogs = '\logs\'
	makedir (_sDirLogs)
	if file (_sDirLogs + _sArqLog)
		_nHdl = fopen(_sDirLogs + _sArqLog, 1)
		fseek (_nHdl, 0, 2)  // Encontra final do arquivo
	else
		_nHdl = fcreate(_sDirLogs + _sArqLog, 0)
	endif
	fwrite (_nHdl, _sTextoLog + chr (13) + chr (10))
	_sTextoLog = ''

	// Continua na linha seguinte, se precisar.
	if ! _lUmaLinha
		if valtype (_xDado) == "A"
			_sTextoLog = _DumpArray (aclone (_xDado), space (8))
		elseif valtype (_xDado) == "O"
			_sTextoLog = _DumpObj (_xDado)
		else
			_sTextoLog = space (46) + cvaltochar (_xDado)
		endif
		fwrite (_nHdl, _sTextoLog + chr (13) + chr (10))
	endif

	fclose (_nHdl)
return



// --------------------------------------------------------------------------
static function _DumpArray (_aMatriz, _sEspacos)
	local _nLin      := 0
	local _nCol      := 0
	local _sDado     := ""
	local _sMensagem := ""
	local _aNovaLin  := {}
	local _aNovaMat  := {}
	local _lPerfeita := .F.
	local _nQtCol    := 0
	local _nLargCol  := 0
	local _lUniDim   := .T.
	
	if len (_aMatriz) == 0
		_sMensagem += _sEspacos + "*MATRIZ VAZIA*"
	else

		// Se recebi uma matriz unidimensional, 'converto-a' para uma bidimensional de uma
		// unica linha, para melhorar a visualizacao no arquivo de log.
		_lUniDim = .T.
		for _nLin = 1 to len (_aMatriz)
			if valtype (_aMatriz[_nLin]) == "A"
				_lUniDim = .F.
				exit
			endif
		next
		if _lUniDim
			_aNovaMat = {}
			for _nLin = 1 to len (_aMatriz)
				aadd (_aNovaMat, _aMatriz[_nLin])
			next
			_aMatriz := {aclone (_aNovaMat)}
		endif

		// Se recebi uma matriz "quadradinha" faco com que todas as linhas tenham a mesma largura.
		if valtype (_aMatriz) == "A" .and. len (_aMatriz) > 0
			_lPerfeita = .T.
			for _nLin = 1 to len (_aMatriz)
				if valtype (_aMatriz[_nLin]) != "A"
					_lPerfeita = .F.
					exit
				endif
			next
		endif
		if _lPerfeita
			_nQtCol = len (_aMatriz [1])
			for _nLin = 1 to len (_aMatriz)
				if len (_aMatriz [_nLin]) != _nQtCol
					_lPerfeita = .F.
					exit
				endif
			next
		endif
		if _lPerfeita
			//		u_log ("Eh perfeita")
			_aNovaMat = {}
			for _nLin = 1 to len (_aMatriz)
				// Passa dados para nova matriz, jah convertidos para caracter, para poder,
				// depois, deixar todas as colunas com a mesma largura.
				_aNovaLin = {}
				for _nCol = 1 to len (_aMatriz [_nLin])
					_sDado = _Arr2Char (_aMatriz [_nLin, _nCol])
					aadd (_aNovaLin, _sDado)
				next
				aadd (_aNovaMat, aclone (_aNovaLin))
			next
			for _nCol = 1 to _nQtCol
				_nLargCol = len (_aNovaMat [1, _nCol])
				for _nLin = 1 to len (_aNovaMat)
					_nLargCol = max (_nLargCol, len (_aNovaMat [_nLin, _nCol]))
				next
				for _nLin = 1 to len (_aNovaMat)
					_aNovaMat [_nLin, _nCol] = padr (_aNovaMat [_nLin, _nCol], _nLargCol, " ")
				next
			next
			
			// Clona a nova matriz para a matriz a ser mostrada.
			_aMatriz = aclone (_aNovaMat)
		endif
		
		if valtype (_aMatriz) != "A"
			_sMensagem += _sEspacos + procname () + ": nao recebi uma array"
		else
			
			// Se for uma matriz perfeita, posso gerar uma linha acima com os numeros das colunas.
			if _lPerfeita
				_nLargTot = 0
			//	_sMensagem += space (7)
				_sMensagem += space (7) + _sEspacos
				for _nCol = 1 to len (_aMatriz [1])
					_nLargCol = len (_Arr2Char (_aMatriz [1, _nCol])) + 3
					_sMensagem += padr (cvaltochar (_nCol), _nLargCol, " ")
					_nLargTot += _nLargCol
				next
				_sMensagem += chr (13) + chr (10)
				_sMensagem += _sEspacos + space (6) + replicate ("-", _nLargTot - 1) + chr (13) + chr (10)
			endif
			
			// Tratamento original
			for _nLin = 1 to len (_aMatriz)
				if len (_sMensagem) > 64000  // Antes que alcance o tamanho maximo de uma string, vou jogar para o log.
					u_log (_sMensagem)
					_sMensagem += "************ Exportando matriz por que alcancou tamanho maximo para uma string"
					_sMensagem = ""
				endif
				_sMensagem += _sEspacos
				if valtype (_aMatriz [_nLin]) != "A"
					_sMensagem += _sEspacos + "Linha " + cValToChar (_nLin) + " nao eh array. Contem o seguinte dado: " + cValToChar (_aMatriz [_nLin])
				else
					if len (_aMatriz [_nLin]) == 0
						_sMensagem += _sEspacos + "Linha " + cValToChar (_nLin) + " eh array, mas nao tem nenhum elemento."
					else
						if _lPerfeita
							_sMensagem += padr (cvaltochar (_nLin), 5, " ")
						endif
						_sMensagem += "| "
						for _nCol = 1 to len (_aMatriz [_nLin])
							_sDado = _Arr2Char (_aMatriz [_nLin, _nCol]) + " | "
							_sMensagem += _sDado
						next
					endif
				endif
				_sMensagem += _sEspacos + chr (13) + chr (10) // + _sEspacos
			next
			
			// 'Fecha' a matriz com uma linha na parte de baixo.
			if _lPerfeita
				_sMensagem += _sEspacos + space (6) + replicate ("-", _nLargTot - 1) + chr (13) + chr (10)
			endif
		endif
	endif
	U_Log (_sMensagem)
return _sMensagem



// --------------------------------------------------------------------------
// Converte campos de array para caracter, para exportacao para log.
static function _Arr2Char (_xDado)
	local _sDado := ""
	do case
		case valtype (_xDado) == "N"
			_sDado = alltrim (str (_xDado, 18, 6))
		case valtype (_xDado) == "D"
			_sDado = dtoc (_xDado)
		case valtype (_xDado) == "L"
			_sDado = iif (_xDado, ".T.", ".F.")
		case valtype (_xDado) == "M"
			_sDado = "*MEMO*"
		case valtype (_xDado) == "A"
			_sDado = "*ARRAY [" + alltrim (str (len (_xDado))) + "]*"
		case _xDado == NIL
			_sDado = "*NIL*"
		case valtype (_xDado) == "U"
			_sDado = "*INDEF*"
		case valtype (_xDado) == "O"
			_sDado = "*OBJETO*"
		case valtype (_xDado) == "C"
			_sDado = _xDado
			if empty (_sDado)
				_sDado = "*STR.VAZIA*"
			endif
		otherwise
			_sDado = "*ERRO*"
	endcase
return _sDado



// --------------------------------------------------------------------------
// Gera listagem dos dados e metodos de um objeto.
static function _DumpObj (_oObj)
	local _aMetodos := aclone (ClassMethArr(_oObj))
	local _nMetodo  := 0
	local _aDet     := {}
	local _nDet     := 0
	local _sRet     := ''
	u_log ('')
	u_log ("Dados da classe " + GetClassName (_oObj) + ':')
	u_log (ClassDataArr (_oObj))
	u_log ("Metodos da classe " + GetClassName (_oObj) + ':')
	for _nMetodo = 1 to len (_aMetodos)
		_aDet = aclone (ClassMethArr(_oObj)[_nMetodo])
		_sRet += strtran (_aDet[1], chr (13) + chr (10), '') + ' ('
		for _nDet = 1 to len (_aDet [2])
			_sRet += alltrim (_aDet [2, _nDet]) + iif (_nDet < len (_aDet [2]), ', ', ')')
		next
		_sRet += iif (len (_aDet [2]) == 0, ')', '')
		u_log (_sRet)
		_sRet = ''
	next
return _sRet
