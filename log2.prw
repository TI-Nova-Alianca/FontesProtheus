// Programa: Log2
// Autor...: Robert Koch
// Data....: 03/06/2020
// Funcao..: Grava arquivo de log em texto para conferencia

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Exporta arquivo de log.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 15/06/2020 - Robert - Verifica existencia da variavel cFilAnt antes de usa-la.
// 15/10/2020 - Robert - Tratamento para dado tipo NIL.
// 14/12/2020 - Robert - Exporta arrays usando a mesma formatacao inicial de linha, para facilitar posterior filtragem.
// 15/12/2020 - Robert - Exportacao de array deu erro na importacao de pedidos!!! GLPI 9033
// 20/01/2021 - Robert - Melhorada exportacao: transforma tudo em array e lista todas as linhas num unico processo fopnen...fclose
// 01/02/2021 - Robert - Aumentado limite de log de texto, de 2000 para 20000 caracteres.
// 29/03/2021 - Robert - Iniciado tratamento para objetos JSON.
// 01/03/2022 - Robert - Renomeia o arquivo quando ficar muito grande (inicialmente 10 MB).
// 07/03/2022 - Robert - Acumula em memoria o tamanho estimado do arquivo, para evitar repetidos acessos a disco.
//

// --------------------------------------------------------------------------
user function Log2 (_sTipo, _xDadoOri, _xExtra)
	local _sTagsLog := ''
	local _sDirLogs  := ''
	local _nHdl      := ''
	local _sDataLog  := dtos (date ())
	local _aTxtLog   := {}
	local _nTxtLog   := 0
	local _nTamArq   := 0
	local _sSeqNome  := ''
	local _nLimTamLg := 1000000
	static _nAcumLog := 0

	// Prepara 'tags' para o inicio de linha
	_sTipo = cvaltochar (_sTipo)
	_sTipo = Capital (_sTipo)
	_sTagsLog += '[' + padc (_sTipo, 5, ' ') + ']'
//	_sTagsLog += '[' + cvaltochar (ThreadId ()) + ']'
	_sTagsLog += '[' + left (padl (cvaltochar (ThreadId ()), 6, ' '), 6) + ']'  // Jah vi casos de ThreadID() retornar menos que 6 caracteres.
	_sTagsLog += '[' + substr (_sDataLog, 1, 4) + '' + substr (_sDataLog, 5, 2) + '' + substr (_sDataLog, 7, 2) + ' ' + strtran (TimeFull (), '.', ',') + ']'
	_sTagsLog += '[' + GetEnvServer () + ']'
	_sTagsLog += '[F' + iif (type ('cFilAnt') == 'C', cFilAnt, '  ') + ']'
	_sTagsLog += '[' + padr (iif (type ("cUserName") == "C", cUserName, ''), 10) + ']'

	// Transforma o dado de origem em array, sendo cada elemento da array uma linha a ser gravada no log.
	if valtype (_xDadoOri) == 'A'
		_aTxtLog = ACLONE (_DumpArray (_xDadoOri))
	elseif valtype (_xDadoOri) == 'O'
		_aTxtLog = aclone (_DumpObj (_xDadoOri))
	elseif valtype (_xDadoOri) == 'J'  // JSON
		_aTxtLog = aclone (_DumpJSON (_xDadoOri))
	else
		if valtype (_xDadoOri) == 'U'
			_aTxtLog = {'*NIL*'}
		else
			_aTxtLog = _DumpTXT (rtrim (cValToChar (_xDadoOri)))
		endif
	endif

	if _xExtra != NIL
		U_Log2 ('AVISO', '[' + procname () + '] Parametro extra ignorado: ' + cvaltochar (_xExtra))
	endif

	// Grava log em diretorio especifico. Se ainda nao existir, cria-o.
	_sDirLogs = '\logs\'
	makedir (_sDirLogs)

	// O programa chamador pode especificar o nome para o arquivo, se quiser.
	if type ("_sArqLog") != "C"
	//	_sArqLog = alltrim (funname (1)) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + "_" + dtos (date ()) + ".log"
		_sArqLog = alltrim (funname (1)) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + ".log"
	endif

	// Se ainda nao tenho nada na variavel que acumula o tamanho do arquivo de log:
	// - Pode ser a primeira chamada de log (arquivo ainda nao existe e, portanto, eh zero mesmo)
	// - Pode estar sendo chamado um log para anexar a um arquivo que jah existia de execucoes anteriores.
	if _nAcumLog == 0
		if file (_sDirLogs + _sArqLog)
			_nAcumLog = directory (_sDirLogs + _sArqLog) [1, 2]
		endif
	endif

	// Se o arquivo jah existir e for muito grande, renomeia-o e gera um novo
	if _nAcumLog > _nLimTamLg
		U_Log ('debug', '[' + procname () + ']Hora de verificar o tamanho do arquivo de log')
		if file (_sDirLogs + _sArqLog)
			_nTamArq = directory (_sDirLogs + _sArqLog) [1, 2]
			if _nTamArq > _nLimTamLg  // Inicialmente acho que 10 mega tah bom...
				_sSeqNome = '001'
				do while file (_sDirLogs + _sArqLog + _sSeqNome)
					_sSeqNome = soma1 (_sSeqNome)
				enddo
				fRename (_sDirLogs + _sArqLog, _sDirLogs + _sArqLog + _sSeqNome, NIL, .f.)
				_nAcumLog = 0
			endif
		endif
	endif

	if file (_sDirLogs + _sArqLog)
		_nHdl = fopen(_sDirLogs + _sArqLog, 1)
		fseek (_nHdl, 0, 2)  // Encontra final do arquivo
	else
		_nHdl = fcreate(_sDirLogs + _sArqLog, 0)
	endif
	for _nTxtLog = 1 to len (_aTxtLog)
		fwrite (_nHdl, _sTagsLog + _aTxtLog [_nTxtLog] + chr (13) + chr (10))
		
		// Acumula o tamanho estimado jah gravado, para saber se precisa renomear o arquivo de log.
		_nAcumLog += len (_aTxtLog [_nTxtLog])
	next
	fclose (_nHdl)
return



// --------------------------------------------------------------------------
static function _DumpTXT (_sDadoTXT)
	local _aRet     := {}
	local _nChar    := 1
	local _lCortei  := .F.
	local _nLimChar := 20000

	// Se for uma string muito grande, corta-a.
	if len (_sDadoTXT) > _nLimChar
		_sDadoTXT = left (_sDadoTXT, _nLimChar)
		_lCortei  = .T.
	endif
	do while _nChar <= len (_sDadoTXT)
		if substr (_sDadoTXT, _nChar, 2) == chr (13) + chr (10)  // 'ENTER' com 2 caracteres (formato Windows)
			aadd (_aRet, left (_sDadoTXT, _nChar - 1))
			_sDadoTXT = substr (_sDadoTXT, _nChar + 2)  // Para 'pular' o chr(13) e o chr(10)
			_nChar = 1
			loop
		elseif substr (_sDadoTXT, _nChar, 1) == chr (10)  // 'New line' em formato linux
			aadd (_aRet, left (_sDadoTXT, _nChar - 1))
			_sDadoTXT = substr (_sDadoTXT, _nChar + 1)  // Para 'pular' o chr(10)
			_nChar = 1
			loop
		endif
		_nChar ++
	enddo
	aadd (_aRet, _sDadoTXT)
	if _lCortei
		aadd (_aRet, "***VISUALIZACAO DO LOG CORTADA EM " + cvaltochar (_nLimChar) + " CARACTERES***")
	endif
return _aRet



// --------------------------------------------------------------------------
static function _DumpArray (_aMatriz)
	local _nLin      := 0
	local _nCol      := 0
	local _sDado     := ""
	local _aNovaLin  := {}
	local _aNovaMat  := {}
	local _lPerfeita := .F.
	local _nQtCol    := 0
	local _nLargCol  := 0
//	local _lUniDim   := .T.
	local _sLinha := ''
	local _aRet   := {}
	local _sLinFech := ''
	if len (_aMatriz) == 0
		aadd (_aRet, "*MATRIZ VAZIA*")
	else

		_lUniDim = .T.
		for _nLin = 1 to len (_aMatriz)
			if valtype (_aMatriz[_nLin]) == "A"
				_lUniDim = .F.
				exit
			endif
		next

		// Se recebi uma matriz "quadradinha" faco com que todas as linhas tenham a mesma largura.
		//
		// Se todos os elementos forem simples (nao array) entendo como perfeita.
		if ! _lUniDim
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
		//		u_log ("Eh perfeita (matriz MxN)")
			else
		//		u_log ("Nao eh perfeita (matriz MxN)")
			endif
		else
			_nQtCol = 1
			_lPerfeita = .T.
		//	u_log ("Eh perfeita (matriz unidimensional)")
		endif

		if _lPerfeita
			_aNovaMat = {}
			for _nLin = 1 to len (_aMatriz)
				// Passa dados para nova matriz, jah convertidos para caracter, para poder, depois, deixar todas as colunas com a mesma largura.
				_aNovaLin = {}
				if _lUniDim
					_sDado = _Arr2Char (_aMatriz [_nLin])
		//			u_log ('valtype (_sDado):', valtype (_sDado))
					aadd (_aNovaMat, _sDado)
				else
					for _nCol = 1 to len (_aMatriz [_nLin])
						_sDado = _Arr2Char (_aMatriz [_nLin, _nCol])
						aadd (_aNovaLin, _sDado)
					next
					aadd (_aNovaMat, aclone (_aNovaLin))
				endif
			next
		//	u_log ('_aNovaMat:', _aNovaMat)
		//	u_log ('valtype (_aNovaMat[1]):', valtype (_aNovaMat[1]))
			// Deixa todas as linhas do mesmo tamanho, para melhorar a visualizacao no log.
			for _nCol = 1 to _nQtCol
				// Largura da primeira linha
				if _lUniDim
					_nLargCol = len (_aNovaMat [1])
				else
					_nLargCol = len (_aNovaMat [1, _nCol])
				endif
		//		u_log ('Largura da coluna 1:', _nLargCol)
				// Verifica se tem alguma linha mais larga que a primeira
				for _nLin = 1 to len (_aNovaMat)
					if _lUniDim
						_nLargCol = max (_nLargCol, len (_aNovaMat [_nLin]))
					else
						_nLargCol = max (_nLargCol, len (_aNovaMat [_nLin, _nCol]))
					endif
				next
		//		u_log ('Maior Largura:', _nLargCol)
				// Ajusta todas as linhas para a maior largura
				for _nLin = 1 to len (_aNovaMat)
					if _lUniDim
						_aNovaMat [_nLin] = padr (_aNovaMat [_nLin], _nLargCol, " ")
					else
						_aNovaMat [_nLin, _nCol] = padr (_aNovaMat [_nLin, _nCol], _nLargCol, " ")
					endif
				next
		//		u_log ('_aNovaMat depois de ajustar larguras:', _aNovaMat)
			next
		else
			_aNovaMat = aclone (_aMatriz)
		endif
		
		// Se for uma matriz perfeita, posso gerar uma linha acima com os numeros das colunas.
		if _lPerfeita
			_sLinha   = '      '
			_sLinFech = '      '
			if _lUniDim
				_nLargCol = len (_Arr2Char (_aNovaMat [1])) + 3
				_sLinha += padc (cvaltochar (_nCol), _nLargCol, "-")
				_sLinFech += replicate ('-', _nLargCol)
			else
				for _nCol = 1 to len (_aNovaMat [1])
					_nLargCol = len (_Arr2Char (_aNovaMat [1, _nCol])) + 3
					_sLinha += padc (cvaltochar (_nCol), _nLargCol, "-")
					_sLinFech += replicate ('-', _nLargCol)
				next
			endif
		//	u_log ('Gerei linha acima:', _sLinha)
			aadd (_aRet, _sLinha)
		endif
		
		// Tratamento original
		for _nLin = 1 to len (_aNovaMat)
			_sLinha   = ''
			if valtype (_aNovaMat [_nLin]) != "A"
//				_sLinha = "Linha " + cValToChar (_nLin) + " nao eh array. Contem o seguinte dado: " + cValToChar (_aNovaMat [_nLin])
				_sLinha += '      | ' + cValToChar (_aNovaMat [_nLin]) + '|'
			else
				if len (_aNovaMat [_nLin]) == 0
					_sLinha = "Linha " + cValToChar (_nLin) + " eh array, mas nao tem nenhum elemento."
				else
					if _lPerfeita
						_sLinha = transform (_nLin, "99999")
					endif
					_sLinha += "| "
					for _nCol = 1 to len (_aNovaMat [_nLin])
						_sLinha += _Arr2Char (_aNovaMat [_nLin, _nCol]) + " | "
					next
				endif
			endif
			aadd (_aRet, _sLinha)
		next
		
		// 'Fecha' a matriz com uma linha na parte de baixo.
		if _lPerfeita
			aadd (_aRet, _sLinFech)
		endif
	endif
return _aRet



// --------------------------------------------------------------------------
// Converte campos de array para caracter, para exportacao para log.
static function _Arr2Char (_xDadoA)
	local _sDadoA := ""
	do case
		case valtype (_xDadoA) == "N"
			_sDadoA = alltrim (str (_xDadoA, 18, 6))
		case valtype (_xDadoA) == "D"
			_sDadoA = dtoc (_xDadoA)
		case valtype (_xDadoA) == "L"
			_sDadoA = iif (_xDadoA, ".T.", ".F.")
		case valtype (_xDadoA) == "M"
			_sDadoA = "*MEMO*"
		case valtype (_xDadoA) == "A"
			_sDadoA = "*ARRAY [" + alltrim (str (len (_xDadoA))) + "]*"
		case _xDadoA == NIL
			_sDadoA = "*NIL*"
		case valtype (_xDadoA) == "U"
			_sDadoA = "*INDEF*"
		case valtype (_xDadoA) == "O"
			_sDadoA = "*OBJETO*"
		case valtype (_xDadoA) == "C"
			_sDadoA = _xDadoA
			if empty (_sDadoA)
				_sDadoA = "*STR.VAZIA*"
			endif
		otherwise
			_sDadoA = "*ERRO*"
	endcase
return _sDadoA



// --------------------------------------------------------------------------
// Gera listagem dos dados e metodos de um objeto.
static function _DumpObj (_oObj)
	local _aAtrib   := aclone (ClassDataArr (_oObj))
	local _nAtrib   := 0
	local _aMetodos := aclone (ClassMethArr(_oObj))
	local _nMetodo  := 0
	local _aDet     := {}
	local _nDet     := 0
	local _sLinha   := ''
	local _aRet     := {}
	aadd (_aRet, "Objeto da classe " + GetClassName (_oObj))
	aadd (_aRet, "   Atributos:")
	for _nAtrib = 1 to len (_aAtrib)
		aadd (_aRet, '      ' + _aAtrib [_nAtrib, 1] + ': ' + cvaltochar (_aAtrib [_nAtrib, 2]))
	next
	aadd (_aRet, "   Metodos:")
	for _nMetodo = 1 to len (_aMetodos)
		_sLinha = '      '
		_aDet = aclone (ClassMethArr(_oObj)[_nMetodo])
		_sLinha += strtran (_aDet[1], chr (13) + chr (10), '') + ' ('
		for _nDet = 1 to len (_aDet [2])
			_sLinha += alltrim (_aDet [2, _nDet]) + iif (_nDet < len (_aDet [2]), ', ', ')')
		next
		_sLinha += iif (len (_aDet [2]) == 0, ')', '')
		aadd (_aRet, _sLinha)
	next
return _aRet



// --------------------------------------------------------------------------
static function _DumpJSON (_oObjJS)
	local _nItemJS  := 0
	local _j        := 0
	local _aNomJSON := {}
	local _oItemJS  := NIL
	local _aRet     := {}
	local _sLinha   := ''

	aadd (_aRet, '{')
	if len(_oObjJS) > 0
		for _nItemJS := 1 to len(_oObjJS)
			_DumpJson(_oObjJS[_nItemJS])
		next
	else
		_aNomJSON := _oObjJS:GetNames()
		for _nItemJS := 1 to len(_aNomJSON)
			_sLinha = '   ' + _aNomJSON[_nItemJS]
			_oItemJS := _oObjJS[_aNomJSON[_nItemJS]]
			if ValType(_oItemJS) == "C"
				_sLinha += ' = ' + cvaltochar(_oObjJS[_aNomJSON[_nItemJS]])
			else
				if ValType(_oItemJS) == "A"
					aadd (_aRet, "Vetor[")
					for _j := 1 to len(_oItemJS)
						aadd (_aRet, "Indice " + cValtochar(_j))
						_DumpJSON (_oItemJS[j])
					next _j
					aadd (_aRet, "]Vetor")
				endif
			endif
			aadd (_aRet, _sLinha)
		next _nItemJS
	endif
	aadd (_aRet, '}')
return _aRet
