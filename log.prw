// Programa: Log
// Autor...: Robert Koch
// Data....: 13/06/2006
// Funcao..: Grava arquivo de log em texto para conferencia
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Grava arquivo de log em texto para conferencia
// #PalavasChave      #log #grava_log 
// #TabelasPrincipais #SX1
// #Modulos           #todos
//
// Historico de alteracoes:
// 22/03/2007 - Robert  - Pode receber array como parametro.
// 02/04/2007 - Robert  - Pode receber ateh 10 parametros e trata cada um separadamente cfe. seu tipo.
//                      - Funcao DumpArray passa a ser interna.
// 09/04/2007 - Robert  - Indenta arquivo de log cfe. tags recebidas no parametro 1 (semelhante a XML).
// 30/04/2007 - Robert  - Gera uma string inicial simulando XML, para enganar o editor no momento de visualizar o arquivo.
// 09/05/2007 - Robert  - Funcao _aDel passa a ser interna.
// 15/05/2007 - Robert  - Implementacao inicial de log de arquivos.
// 25/05/2007 - Robert  - Melhoria tamanhos log de arquivos.
// 26/07/2007 - Robert  - Criada funcao para exportacao da pilha de chamadas (LogPCham).
//                      - Criada funcao para exportacao da identificacao da sessao atual (LogID).
// 02/08/2007 - Robert  - Dump de array passa a ser formatado, quando for uma array 'perfeita'.
// 16/08/2007 - Robert  - Implementado log de parametros do SX1.
// 22/08/2007 - Robert  - Melhoria indentacao log de arrays.
// 19/10/2007 - Robert  - Implementadas funcoes LogIni, LogFim e LogXML.
// 10/01/2008 - Robert  - Melhorada formatacao para dump de arrays.
// 19/02/2008 - Robert  - Melhorada formatacao para dump de arrays unidimensionais.
// 17/03/2008 - Robert  - Aumentado numero de parametros de 10 para 20
//                      - Concatena automaticamente os parametros, quando possivel.
// 24/03/2008 - Robert  - Melhorada formatacao para dump de arrays.
// 07/04/2008 - Robert  - Lista retorno da FunName() no LogID().
// 23/04/2008 - Robert  - Funcoes LogIni e LogFim passam a ter suporte para contagem de tempo.
// 08/05/2008 - Robert  - Quando havia parametros do tipo array junto com outros tipos, tentava concatenar tudo e perdia as arrays.
// 07/07/2008 - Robert  - Quando uma string de mensagem fica grande demais, exporta-a parcialmente e reinicia.
// 16/02/2010 - Robert  - Funcao LogXML insere as quebras de linha, quando necessario.
//                      - Mostra msg. 'matriz vazia' em vez de tentar listar linha a linha.
// 14/06/2010 - Robert  - Nao gerava log do SX1 quando respostas do tipo combo eram guardadas em formato caracter.
// 10/09/2014 - Robert  - Funcao LogSX1 passa a retornar string com copia do que foi gravado no log.
// 17/03/2015 - Robert  - Criada funcao U_LogDH ().
// 15/04/2015 - Robert  - Criada funcao U_LogObj ().
// 28/06/2015 - Robert  - Melhorias na funcao U_LogObj ().
// 30/07/2015 - Robert  - Criada funcao LogAlinD ().
// 21/07/2015 - Robert  - Criado tratamento para evitar erro e mostrar *OBJETO* quando receber parametro tipo 'O'.
// 05/11/2015 - Robert  - Criada funcao LogACols().
// 11/01/2016 - Robert  - Melhorado tratamento para variaveis tipo N na funcao LogSX1().
// 21/07/2016 - Robert  - Funcao LogTrb nao exporta nada quando estiver em BOF ou EOF. Apenas gera aviso.
// 01/11/2016 - Robert  - Retorna string com o que foi gerado (util para pegar uma array formatada, por exemplo).
// 09/03/2017 - Robert  - Se nao especificado nome do arquivo de log, gera a partir da funcao FunName ().
// 04/04/2018 - Robert  - Na funcao LogTrb() verifica se o arquivo estah filtrado e, nesse caso, mostra a expressao do filtro.
// 17/07/2018 - Robert  - Criada funcao ShowLog ()
// 26/03/2020 - Robert  - Ajustes funcao LogACols () para quando variaveis aHeader e aCols nao estiverem definidas.
// 29/05/2020 - Robert  - Passa a gravar logs em diretorio especifico fora do SIGAADV.
// 09/06/2020 - Robert  - Funcao ShowLog() nao buscava no diretorio de logs.
// 11/05/2021 - Claudia - Ajustada a chamada para tabela SX1 devido a R27. GLPI: 8825
// 04/08/2021 - Robert  - Nao trazia o descritivo das perguntas no LogSX1().
// 08/09/2021 - Robert  - Nao trazia o significado de respostas tipo combo no LogSX1().
// 06/12/2021 - Robert  - LogPCham() passa a usar U_Log2() para gravar os dados.
// 30/03/2022 - Robert  - LogObj() passa a usar U_Log2() para gravar os dados.
// 19/05/2022 - Robert  - LogTrb() nao fazia dbgotop() quando exportacao completa (GLPI 12080)
//

// -------------------------------------------------------------------------------------------------------------------------------
user function Log (_xDado1, _xDado2, _xDado3, _xDado4, _xDado5, _xDado6, _xDado7, _xDado8, _xDado9, _xDado10, _xDado11, _xDado12, _xDado13, _xDado14, _xDado15, _xDado16, _xDado17, _xDado18, _xDado19, _xDado20)
	local  _nHdl     := 0
	local _sTexto    := ""
	local _nParam    := 1
	local _nParam2   := 0
	local _xDado     := NIL
	local _nEspacos  := 0
	local _nMaxParam := 20
	local _lTemArray := .F.
	local _sRet      := ""
	local _sDirLogs  := ''
	static _aPilhaLog := {}
	private _xDad1  := iif (valtype (_xDado1)  == 'O', ' *OBJETO* ', _xDado1)    // Operador de macro nao reconhece variaveis locais.
	private _xDad2  := iif (valtype (_xDado2)  == 'O', ' *OBJETO* ', _xDado2)    // Operador de macro nao reconhece variaveis locais.
	private _xDad3  := iif (valtype (_xDado3)  == 'O', ' *OBJETO* ', _xDado3)    // Operador de macro nao reconhece variaveis locais.
	private _xDad4  := iif (valtype (_xDado4)  == 'O', ' *OBJETO* ', _xDado4)    // Operador de macro nao reconhece variaveis locais.
	private _xDad5  := iif (valtype (_xDado5)  == 'O', ' *OBJETO* ', _xDado5)    // Operador de macro nao reconhece variaveis locais.
	private _xDad6  := iif (valtype (_xDado6)  == 'O', ' *OBJETO* ', _xDado6)    // Operador de macro nao reconhece variaveis locais.
	private _xDad7  := iif (valtype (_xDado7)  == 'O', ' *OBJETO* ', _xDado7)    // Operador de macro nao reconhece variaveis locais.
	private _xDad8  := iif (valtype (_xDado8)  == 'O', ' *OBJETO* ', _xDado8)    // Operador de macro nao reconhece variaveis locais.
	private _xDad9  := iif (valtype (_xDado9)  == 'O', ' *OBJETO* ', _xDado9)    // Operador de macro nao reconhece variaveis locais.
	private _xDad10 := iif (valtype (_xDado10) == 'O', ' *OBJETO* ', _xDado10)   // Operador de macro nao reconhece variaveis locais.
	private _xDad11 := iif (valtype (_xDado11) == 'O', ' *OBJETO* ', _xDado11)   // Operador de macro nao reconhece variaveis locais.
	private _xDad12 := iif (valtype (_xDado12) == 'O', ' *OBJETO* ', _xDado12)   // Operador de macro nao reconhece variaveis locais.
	private _xDad13 := iif (valtype (_xDado13) == 'O', ' *OBJETO* ', _xDado13)   // Operador de macro nao reconhece variaveis locais.
	private _xDad14 := iif (valtype (_xDado14) == 'O', ' *OBJETO* ', _xDado14)   // Operador de macro nao reconhece variaveis locais.
	private _xDad15 := iif (valtype (_xDado15) == 'O', ' *OBJETO* ', _xDado15)   // Operador de macro nao reconhece variaveis locais.
	private _xDad16 := iif (valtype (_xDado16) == 'O', ' *OBJETO* ', _xDado16)   // Operador de macro nao reconhece variaveis locais.
	private _xDad17 := iif (valtype (_xDado17) == 'O', ' *OBJETO* ', _xDado17)   // Operador de macro nao reconhece variaveis locais.
	private _xDad18 := iif (valtype (_xDado18) == 'O', ' *OBJETO* ', _xDado18)   // Operador de macro nao reconhece variaveis locais.
	private _xDad19 := iif (valtype (_xDado19) == 'O', ' *OBJETO* ', _xDado19)   // Operador de macro nao reconhece variaveis locais.
	private _xDad20 := iif (valtype (_xDado20) == 'O', ' *OBJETO* ', _xDado20)   // Operador de macro nao reconhece variaveis locais.
	
	if type ("_sArqLog") != "C"
		_sArqLog = alltrim (funname (1)) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + "_" + dtos (date ()) + ".log"
	endif
		
	// Controla pilha de tags, para mostrar em um formato tosco de XML...
	if valtype (_xDado1) == "C" .and. left (_xDado1, 1) == "<" .and. right (_xDado1, 1) == ">"
		
		// Se for final de elemento, remove a tag da pilha
		if left (_xDado1, 2) == "</"
			_nPosPilha = ascan (_aPilhaLog, stuff (_xDado1, 2, 1, ""))
			if _nPosPilha > 0
				_aPilhaLog = aclone (_ADel (_aPilhaLog, _nPosPilha, len (_aPilhaLog)))
			endif
			_nEspacos = len (_aPilhaLog) * 3
		else
			_nEspacos = len (_aPilhaLog) * 3
			aadd (_aPilhaLog, _xDado1)
		endif
	else
		_nEspacos = len (_aPilhaLog) * 3
	endif

	// Verifica se os parametros podem ser concatenados em uma mesma linha. Soh nao concatena
	// arrays. Isso eh util, por exemplo, para casos em que o usuario quer logar um texto
	// seguindo de um valor (antigamente, precisaria converter o valor para caracter e
	// concatenar os dois na chamada da funcao). Agora passa-os normalmente e a rotina converte.
	_lTemArray = .F.
	for _nParam = 1 to _nMaxParam
		_xDado := &("_xDad" + cvaltochar (_nParam))
		if _xDado != NIL .and. valtype (_xDado) == "A"
			_lTemArray = .T.
		endif
	next
	if ! _lTemArray
		for _nParam = _nMaxParam to 2 step -1
			_xDado := &("_xDad" + cvaltochar (_nParam))
			_xDadoAnt := &("_xDad" + cvaltochar (_nParam - 1))
			if _xDado != NIL .and. valtype (_xDado) != "A" .and. _xDadoAnt != NIL .and. valtype (_xDadoAnt) != "A"
				&("_xDad" + cvaltochar (_nParam - 1)) = cvaltochar (_xDadoAnt) + " " + cvaltochar (_xDado)
				&("_xDad" + cvaltochar (_nParam)) = NIL
			endif
		next
	endif

	// Exporta os parametros recebidos para o arquivo de log.
	_nParam = 1
	do while _nParam <= _nMaxParam //.T.
		_xDado := &("_xDad" + cvaltochar (_nParam))
		if _xDado == NIL
			// Verifica se ainda tem dados em mais algum parametro. Se tiver, apresenta
			// o parametro atual como NIL. Senao, cai fora do loop.
			_nParam2 = _nParam + 1
			do while _nParam2 <= _nMaxParam
				if &("_xDad" + cvaltochar (_nParam2)) != NIL
					_xDado := '*NIL*'
				endif
				_nParam2 ++
			enddo
			if _xDado == NIL
				exit
			endif
		endif
		if valtype (_xDado) == "A"
			_sRet = _DumpArray (aclone (_xDado), space (_nEspacos))
		else
			_sTexto := space (_nEspacos) + cValToChar (_xDado)
			
			// Grava log em diretorio especifico. Se ainda nao existir, cria-o.
			_sDirLogs = '\logs\'
			makedir (_sDirLogs)

			if file (_sDirLogs + _sArqLog)
				_nHdl = fopen(_sDirLogs + _sArqLog, 1)
			else
				_nHdl = fcreate(_sDirLogs + _sArqLog, 0)
				fwrite (_nHdl, '<?xml version="1.0" encoding="utf-8"?>' + chr (13) + chr (10))  // Para dar uma 'enganada' nos editores de texto e facilitar a visualizacao...
				fwrite (_nHdl, '<!--Arquivo de log gerado por customizacoes Protheus-->' + chr (13) + chr (10))  // Comentario simples em XML
			endif
			fseek (_nHdl, 0, 2)  // Encontra final do arquivo
			fwrite (_nHdl, _sTexto + chr (13) + chr (10))
			fclose (_nHdl)
		endif
		_nParam ++
	enddo
return _sRet
//
// --------------------------------------------------------------------------
// Gera log do conjunto aHeader / aCols.
user function LogACols (_aHeader, _aCols)
	local _aAux := 0
	local _nLin := 0
	local _nCol := 0

	if _aHeader == NIL
		if type ("aHeader") != 'A'
			u_log2 ('aviso', 'aHeader nao definido. Geracao de log nao vai ser possivel.')
			return
		else
			_aHeader = aclone (aHeader)
		endif
	endif
	if _aCols == NIL
		if type ("aCols") != 'A'
			u_log2 ('aviso', 'aCols nao definido. Geracao de log nao vai ser possivel.')
			return
		else
			_aCols = aclone (aCols)
		endif
	endif

	// Monta uma nova array, com os nomes de campos do aHeader na primeira linha e o conteudo do aCols nas linhas seguintes. Depois exporta-a.
	_aAux = {}
	aadd (_aAux, array (len (_aHeader) + 1))  // Coluna inicial para indicar se a linha estah deletada, etc
	aadd (_aAux, array (len (_aHeader) + 1))  // Coluna inicial para indicar se a linha estah deletada, etc
	_aAux [1, 1] = '  N'
	_aAux [2, 1] = '------'
	for _nCol = 1 to len (_aHeader)
		_aAux [1, _nCol + 1] = _aHeader [_nCol, 2]  // Nome do campo 
		_aAux [2, _nCol + 1] = _aHeader [_nCol, 1]  // Titulo do campo
	next
	for _nLin = 1 to len (_aCols)
		aadd (_aAux, array (len (_aHeader) + 1))
		for _nCol = 1 to len (_aHeader)
			_aAux [len (_aAux), _nCol + 1] = cvaltochar (_aCols [_nLin, _nCol])
			if _aCols [_nLin, len (_aCols [_nLin])]
				_aAux [len (_aAux), 1] = '*DEL*'
			else
				_aAux [len (_aAux), 1] = cvaltochar (_nLin)
			endif
		next 
	next
	u_log2 ('debug', _aAux)
return
//
// --------------------------------------------------------------------------
// Insere data e hora no inicio da mensagem de log.
user function LogDH (_xDado1, _xDado2, _xDado3, _xDado4, _xDado5, _xDado6, _xDado7, _xDado8, _xDado9, _xDado10, _xDado11, _xDado12, _xDado13, _xDado14, _xDado15, _xDado16, _xDado17, _xDado18, _xDado19, _xDado20)
	U_Log ('[' + dtoc (date ()) + ' ' + time () + ']', _xDado1, _xDado2, _xDado3, _xDado4, _xDado5, _xDado6, _xDado7, _xDado8, _xDado9, _xDado10, _xDado11, _xDado12, _xDado13, _xDado14, _xDado15, _xDado16, _xDado17, _xDado18, _xDado19)
return
//
// --------------------------------------------------------------------------
// Recebe uma string com dados XML e formata-a para o log.
user function LogXML (_sTexto, _lQuebrar)
	local _nLinha  := 0

	_lQuebrar := iif (_lQuebrar == NIL, .F., _lQuebrar)
	if _lQuebrar
		_sTexto = strtran (_sTexto, "><", ">" + chr (13) + chr (10) + "<")
	endif

	for _nLinha = 1 to mlcount (_sTexto)
		u_log (alltrim (memoline (_sTexto,, _nLinha)))
	next
return
//
// --------------------------------------------------------------------------
// Gera uma linha com um tag de inicio. Se nao informado nenhum parametro, assume o nome da funcao chamadora.
user function LogIni (_sTexto)

	if _sTexto == NIL
		_sTexto = procname (1)
	endif

	_sTexto = cvaltochar (_sTexto)
	u_log ("<" + _sTexto + ">")
return seconds ()
//
// --------------------------------------------------------------------------
// Gera uma linha com um tag de fim. Se nao informado nenhum parametro, assume o nome da funcao chamadora.
user function LogFim (_sTexto)

	if _sTexto == NIL
		_sTexto = procname (1)
	endif

	_sTexto = cvaltochar (_sTexto)
	u_log ("</" + _sTexto + ">")
return
//
// --------------------------------------------------------------------------
// Faz exportacao da pilha de chamadas para o arquivo de log.
user function LogPCham ()
	local _i      := 0
	local _sPilha := ""

	do while procname (_i) != ""
		_sPilha += "   =>   " + procname (_i)
		_i++
	enddo
	//u_log ("Pilha de chamadas: " + _sPilha)
	U_Log2 ('info', 'Pilha de chamadas: ' + _sPilha)

return _sPilha
//
// --------------------------------------------------------------------------
// Faz exportacao dos parametros do grupo de perguntas informado.
user function LogSX1 (_sPerg)
	local _aAreaSX1    := U_ML_SRArea ()
	local _sVar        := ""
	local _sMsg        := ""
	local _uVar        := NIL
	local _sRet        := ""
	local cPicture     := ""
	local _x           := ""
	local _sX1_GRUPO   := ''
	local _sX1_ORDEM   := ''
	local _sX1_GSC     := ''
	local _nX1_TAMANHO := ''
	local _nX1_DECIMAL := ''
	local _nX1_TIPO    := ''
	local _sX1_PERG    := ''

	if _sPerg == NIL
		if type ("cPerg") == "C"
			_sPerg = cPerg
		endif
	endif

	// Monta array com cada pergunta e sua resposta em uma linha.
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   X1_GRUPO"
	_oSQL:_sQuery += "    ,X1_ORDEM"
	_oSQL:_sQuery += "    ,X1_GSC"
	_oSQL:_sQuery += "    ,X1_TAMANHO"
	_oSQL:_sQuery += "    ,X1_DECIMAL"
	_oSQL:_sQuery += "    ,X1_TIPO"
	_oSQL:_sQuery += "    ,X1_PERGUNT"
	_oSQL:_sQuery += "    ,X1_DEF01"
	_oSQL:_sQuery += "    ,X1_DEF02"
	_oSQL:_sQuery += "    ,X1_DEF03"
	_oSQL:_sQuery += "    ,X1_DEF04"
	_oSQL:_sQuery += "    ,X1_DEF05"
	_oSQL:_sQuery += " FROM SX1010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sPerg) +"'"
//	_oSQL:Log ()
	_aSX1  = aclone (_oSQL:Qry2Array ())	
//	U_Log2 ('debug', _aSX1)
	For _x:= 1 to Len(_aSX1)
		_sX1_GRUPO	 := _aSX1[_x, 1]
		_sX1_ORDEM   := _aSX1[_x, 2]
		_sX1_GSC	 := _aSX1[_x, 3]
		_nX1_TAMANHO := _aSX1[_x, 4]
		_nX1_DECIMAL := _aSX1[_x, 5]
		_nX1_TIPO    := _aSX1[_x, 6]
		_sX1_PERG    := _aSX1[_x, 7]

		_sVar := "MV_PAR"+StrZero(Val(_sX1_ORDEM),2,0)
//		_sMsg := "Grp.perg. " + _sPerg + " mv_par" + _sX1_ORDEM + ": "+ X1Pergunt() + " "
		_sMsg := "Grp.perg. " + _sPerg + " mv_par" + _sX1_ORDEM + ": "+ _sX1_PERG + ": "
		
		If _sX1_GSC == "C"
			/*
			_sMsg += cValToChar (&(_sVar)) + " (" 
			If ( cvaltochar (&(_sVar))=="1" )
				_sMsg += alltrim (X1Def01 ())
			ElseIf ( cvaltochar (&(_sVar))=="2" )
				_sMsg += alltrim (X1Def02 ())
			ElseIf ( cvaltochar (&(_sVar))=="3" )
				_sMsg += alltrim (X1Def03 ())
			ElseIf ( cvaltochar (&(_sVar))=="4" )
				_sMsg += alltrim (X1Def04 ())
			ElseIf ( cvaltochar (&(_sVar))=="5" )
				_sMsg += alltrim (X1Def05 ())
			EndIf
			_sMsg += ")"
			*/
			_sMsg += '(' + alltrim (_aSX1[_x, 7 + &(_sVar)]) + ')'
		Else
			_uVar := &(_sVar)
			if _nX1_TIPO == 'N'
				cPicture:= "@E "+Replicate("9",_nX1_TAMANHO-_nX1_DECIMAL-1)

				If(_nX1_DECIMAL>0 )
					cPicture+="."+Replicate("9",_nX1_DECIMAL)
				Else
					cPicture+="9"
				EndIf

				_sMsg += Transform(_uVar, cPicture)

			Elseif ValType(_uVar) == "D"
				_sMsg += DTOC(_uVar)
			Else
				_sMsg += _uVar
			EndIf
		EndIf

		u_log2 ('info', _sMsg)
		_sRet += _sMsg + chr (10) + chr (13)
	Next
	U_ML_SRArea (_aAreaSX1)
return _sRet

// user function LogSX1 (_sPerg)
// 	local _aAreaSX1 := sx1 -> (getarea ())
// 	local _sVar := ""
// 	local _sMsg := ""
// 	local _uVar := NIL
// 	local _sRet := ""
// 	local cPicture := ""

// 	if _sPerg == NIL
// 		if type ("cPerg") == "C"
// 			_sPerg = cPerg
// 		endif
// 	endif

// 	DbSelectArea("SX1")
// 	MsSeek(_sPerg)
// 	While !EOF() .AND. X1_GRUPO = _sPerg
// 		_sVar := "MV_PAR"+StrZero(Val(X1_ORDEM),2,0)
// //		_sMsg := "parametro " + X1_ORDEM + ": "+ X1Pergunt() + " "
// 		_sMsg := "Grp.perg. " + _sPerg + " - param. " + X1_ORDEM + ": "+ X1Pergunt() + " "
// 		If X1_GSC == "C"
// 			_sMsg += cValToChar (&(_sVar)) + " (" 
// 			If ( cvaltochar (&(_sVar))=="1" )
// 				_sMsg += alltrim (X1Def01 ())
// 			ElseIf ( cvaltochar (&(_sVar))=="2" )
// 				_sMsg += alltrim (X1Def02 ())
// 			ElseIf ( cvaltochar (&(_sVar))=="3" )
// 				_sMsg += alltrim (X1Def03 ())
// 			ElseIf ( cvaltochar (&(_sVar))=="4" )
// 				_sMsg += alltrim (X1Def04 ())
// 			ElseIf ( cvaltochar (&(_sVar))=="5" )
// 				_sMsg += alltrim (X1Def05 ())
// 			EndIf
// 			_sMsg += ")"
// 		Else
// 			_uVar := &(_sVar)
// 			if sx1 -> x1_tipo == 'N'
// 				cPicture:= "@E "+Replicate("9",X1_TAMANHO-X1_DECIMAL-1)
// 				If( X1_DECIMAL>0 )
// 					cPicture+="."+Replicate("9",X1_DECIMAL)
// 				Else
// 					cPicture+="9"
// 				EndIf
// 				_sMsg += Transform(_uVar, cPicture)
// 			Elseif ValType(_uVar) == "D"
// 				_sMsg += DTOC(_uVar)
// 			Else
// 				_sMsg += _uVar
// 			EndIf
// 		EndIf
// 		u_log2 ('info', _sMsg)
// 		_sRet += _sMsg + chr (10) + chr (13)
// 		DbSkip()
// 	Enddo
// 	sx1 -> (restarea (_aAreaSX1))
// return _sRet
//
// --------------------------------------------------------------------------
// Faz exportacao de dados da sessao atual para o arquivo de log.
user function LogID ()
	local _sMsg := ""

	_sMsg += " dDataBase=" + dtoc (dDataBase)
	_sMsg += " cEmpAnt=" + cEmpAnt
	_sMsg += " cFilAnt=" + cFilAnt
	_sMsg += " cUserName=" + cUserName
	_sMsg += " funname()=" + FunName ()
	_sMsg += " cModulo=" + cModulo
	_sMsg += " GetComputerName=" + getcomputername ()
	u_logDH ('[' + GetPvProfString ('Service', 'Name', '', GetAdv97()) + ':' + GetEnvServer () + '] ' + _sMsg)

return
//
// --------------------------------------------------------------------------
// Faz exportacao de registros de um arquivo para o arquivo de log.
user function LogTrb (_sAlias, _lCompleto, _lSemCabec)
	local _nCampo   := 0
	local _aTamCpo  := {}
	local _aEstrut  := {}
	local _nRegOri  := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _sFiltro  := ""

	_lCompleto := iif (_lCompleto == NIL, .F., _lCompleto)
	_lSemCabec := iif (_lSemCabec == NIL, .F., _lSemCabec)

	if ! empty (_sAlias) .and. valtype (_sAlias) == 'C' .and. select (_sAlias) != 0

		// Se foi solicitada exportacao completa, posiciona no inicio do arquivo.
		if _lCompleto
			dbgotop ()
		endif

		if (_sAlias) -> (BOF ())
			u_log ("[" + procname () + "] Alias '" + _sAlias + "' encontra-se em BOF")
		elseif (_sAlias) -> (EOF ())
			u_log ("[" + procname () + "] Alias '" + _sAlias + "' encontra-se em EOF")
		else

			_sFiltro = alltrim ((_sAlias) -> (dbfilter ()))
			u_log ("[" + procname () + "] Alias: " + _sAlias + iif (empty (_sFiltro), '  (sem filtro)', '  Expr.filtro: ' + _sFiltro))

			// Monta array com os tamanhos dos campos para exportar sempre formatado.
			_nRegOri = (_sAlias) -> (recno ())
			dbselectarea (_sAlias)
			_aEstrut = dbstruct ()
			aadd (_aTamCpo, 8)  // Para o RECNO
			for _nCampo = 1 to len (_aEstrut)
				aadd (_aTamCpo, max (12, _aEstrut [_nCampo, 3] + 2))
			next
	
			// Monta os titulos das colunas
			if ! _lSemCabec
				u_log ("[" + procname () + "] Registro atual: " + alltrim (cvaltochar (recno ())) + "   Indice atual: " + cvaltochar (indexord ()) + "  " + indexkey (indexord ()) + "  Deletado: " + cvaltochar (deleted ()))
				_sLinha = "Recno() "
				for _nCampo = 1 to len (_aEstrut)
					_sLinha += padr (_aEstrut [_nCampo, 1], _aTamCpo [_nCampo + 1], " ")
				next
				U_Log ("[" + procname () + "] " + _sLinha)
			endif
	
			// Exporta os dados dos campos.
//			if _lCompleto
//				dbgotop ()
//			endif
			do while ! eof ()
				_sLinha = padr (left (cvaltochar (recno ()), _aTamCpo [1]), _aTamCpo [1], " ")
				for _nCampo = 1 to len (_aEstrut)
					_sLinha += padr (left (cvaltochar (fieldget (_nCampo)), _aTamCpo [_nCampo + 1]), _aTamCpo [_nCampo + 1], " ")
				next
				U_Log ("[" + procname () + "] " + _sLinha)
				if ! _lCompleto
					exit
				endif
				dbskip ()
			enddo
			(_sAlias) -> (dbgoto (_nRegOri))
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
//
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
				_sMensagem += space (7)
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
//
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
//
// --------------------------------------------------------------------------
static function _ADel (_aMatriz, _nPosIni, _nPosFim)
   local _aMatAux := {}
   local _nPos    := 0

   _nPosFim := iif (_nPosFim == NIL, _nPosIni, _nPosFim)
   for _nPos = 1 to len (_aMatriz)
      if _nPos < _nPosIni .or. _nPos > _nPosFim
         if valtype (_aMatriz [_nPos]) == "A"
            aadd (_aMatAux, aclone (_aMatriz [_nPos]))
         else
            aadd (_aMatAux, _aMatriz [_nPos])
         endif
      endif
   next
return _aMatAux
//
// --------------------------------------------------------------------------
// Gera listagem dos dados e metodos de um objeto.
user function LogObj (_oObj)
	local _aMetodos := aclone (ClassMethArr(_oObj))
	local _nMetodo  := 0
	local _aDet     := {}
	local _nDet     := 0
	local _sRet     := ''

	u_log2 ('debug', '')
	u_log2 ('debug', "Dados da classe " + GetClassName (_oObj) + ':')
	u_log2 ('debug', ClassDataArr (_oObj))
	u_log2 ('debug', "Metodos da classe " + GetClassName (_oObj) + ':')

	for _nMetodo = 1 to len (_aMetodos)
		_aDet = aclone (ClassMethArr(_oObj)[_nMetodo])
		_sRet += strtran (_aDet[1], chr (13) + chr (10), '') + ' ('
		for _nDet = 1 to len (_aDet [2])
			_sRet += alltrim (_aDet [2, _nDet]) + iif (_nDet < len (_aDet [2]), ', ', ')')
		next
		_sRet += iif (len (_aDet [2]) == 0, ')', '')
		u_log2 ('debug', _sRet)
		_sRet = ''
	next
return _sRet
//
// --------------------------------------------------------------------------
// Tenta fazer uma formatacao basicade uma query do SQL.
user function LogQry (_sQry)
	local _sRet     := chr (13) + chr (10) + _sQry
	local _nPos     := 0
	local _nPos2    := 0
	local _aQuebras := {'SELECT ', 'FROM ', 'WHERE ', 'CASE '}
	local _nQuebra  := 0
	
	// Insere quebras de linha antes de palavras chave.
	for _nQuebra = 1 to len (_aQuebras)
		_nPos = 0
		do while .t.
			_nPos2 = at (_aQuebras [_nQuebra], _sRet)
			if _nPos2 <= _nPos
				exit
			endif
			_sRet = substr (_sRet, 1, _nPos2) + chr (13) + chr (10) + substr (_sRet, _nPos2)
		enddo
	next
	u_log2 ('debug', _sRet)
return _sRet
//
// --------------------------------------------------------------------------
// Mostra em tela o log atual.
user function ShowLog ()
	local _sArqLog   := '\logs\' + alltrim (funname (1)) + "_" + iif (type ("cUserName") == "C", alltrim (cUserName), "") + "_" + dtos (date ()) + ".log"
	local _sConteudo := ""
	
	FT_FUSE(_sArqLog)
	FT_FGOTOP()
	While !FT_FEOF()
		if len (_sConteudo) > 64000  // Nao adianta querer mostrar log grande demais
			_sConteudo += "LOG TRUNCADO"
			exit
		endif
		_sConteudo += FT_FREADLN () + chr (13) + chr (10)
		FT_FSKIP()
	EndDo
	FT_FUSE()  // Fecha o arquivo
	U_ShowMemo (_sConteudo, _sArqLog)
return
