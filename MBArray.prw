// Programa...: MBArray
// Autor......: Robert Koch
// Data.......: 07/12/2004
// Descricao..: MarkBrowse para arrays

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Interface_usuario
// #Descricao         #Gera tela de marcacao com base em array, semelhante a funcao MarkBrowse do sistema.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 23/04/2005 - Robert  - Melhorias gerais
// 24/10/2006 - Robert  - Ajustes posicionamento botoes para versao 'Flat'
// 21/05/2008 - Robert  - Mesmo se o usuario clicasse em 'cancelar', retornava itens marcados.
// 08/07/2008 - Robert  - Melhorado posicionamento em tela.
//                      - Criado botao de 'inverte selecao'.
// 17/04/2009 - Robert  - Criado parametro de validacao de 'Linha OK'
// 29/11/2010 - Robert  - Nao usa mais a tela cheia por default.
// 22/10/2021 - Robert  - Criado botao de exportacao para planilha (melhoria para GLPI 11084)
// 25/10/2021 - Claudia - AJuste de posição e tamanho dos botões da tela. GLPI: 11140
// 18/05/2023 - Robert  - Criada opcao para incluir alguns botoes adicionais.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Monta tela semelhante a um markbrowse, mas com arrays, usando listbox.
// Parms.: 1 - Array de opcoes. Se informada a coluna da marca, deve ser
//             passada por referencia (com @ no inicio)
//         2 - Titulo da janela
//         3 - Array com as colunas a mostrar: 1 - Numero da coluna
//                                             2 - Titulo da coluna
//                                             3 - Tamanho da coluna (em pixels)
//                                             4 - Mascara da coluna
//         4 - Coluna da array original que deve receber .T. caso
//             o usuario tenha selecionado. Se informada, a array deve ser
//             passada por referencia (parametro 1). Se nao informado, a
//             funcao retorna um vetor com os numeros das linhas selecionadas.
//         5 - Largura da janela (se nao informado, usa toda a tela.
//         6 - Altura da janela (se nao informado, usa toda a tela.
//         7 - Nome de funcao de usuario para validar a selecao da linha. Estarah
//             disponivel para essa funcao uma array 'private' chamada _aMBArrayV
//             composta por: [1] = Array com um clone da array original.
//                           [2] = Linha em que o usuario estah posicionado.
//                           [3] = Conteudo (.F. ou .T.) atual desta linha (antes de permitir a inversao).
//         8 - Array contendo definicoes de botoes adicionais, no formato {label, largura (em pixels), action}
user function MbArray (_aArray, _sTitulo, _aCols, _nColMarca, _nLarg, _nAltur, _sLinhaOK, _aBotAdic)
	local _oDlgMbA   := NIL
	local _oLbx      := NIL
	local _aOpcoes   := {}
	local _oBmpOK    := LoadBitmap( GetResources(), "LBOK" )
	local _oBmpNo    := LoadBitmap( GetResources(), "LBNO" )
	local _nLinha    := 0
	local _aRet      := {}
	local _aLinha    := {}
	local _nCol      := 0
	local _aCabec    := {}
	local _aTamanhos := {}
	local _lBotaoOK  := .F.
	local _aSize     := {}
	private _aMBArrayV := {NIL, NIL, NIL}  // Deixar private para ser vista pela funcao de validacao.

	// A rotina chamadora pode, opcionalmente, me passar botoes adicionais.
	if valtype (_aBotAdic) != "A"
		_aBotAdic = {}
	endif

	// Se nao foi informada funcao para validacao, assume .T.
	_sLinhaOK := iif (_sLinhaOK == NIL, "AllwaysTrue()", _sLinhaOK)

	// Define tamanho da tela.
	if _nAltur == NIL .or. _nLarg == NIL
		_aSize := MsAdvSize()
		_nAltur = _aSize [6] * .9
		_nLarg  = _aSize [5] * .9
	endif
	
	if valtype (_aArray) != "A"
		u_help ("Funcao " + procname () + " recebeu parametro incorreto")
		return {}
	endif
	if len (_aArray) == 0
		u_help ("Funcao " + procname () + " recebeu array de opcoes vazia")
		return {}
	endif
	_aMBArrayV [1] := aclone (_aArray)
	
	// Monta array para a listbox
	_aOpcoes = {}
	for _nLinha = 1 to len (_aArray)
		
		// Monta cada linha da array
		_aLinha = {}
		//
		// Primeira coluna vai ter o bitmap indicando se estah selecionada.
		// Se foi informada a coluna que vai ter a indicacao de selecao,
		// inicializa conforme essa coluna. Senao, inicializa como nao marcada.
		if _nColMarca != NIL
			aadd (_aLinha, iif (_aArray [_nLinha, _nColMarca], _oBmpOk, _oBmpNo))
		else
			aadd (_aLinha, _oBmpNo)
		endif
		//
		// Adiciona as colunas selecionadas pelo parametro. Se nao informado,
		// adiciona todas.
		if _aCols != NIL
			for _nCol = 1 to len (_aCols)
				aadd (_aLinha, transform (_aArray [_nLinha, _aCols [_nCol, 1]], _aCols [_nCol, 4]))
			next
		else
			for _nCol = 1 to len (_aArray [1])
				aadd (_aLinha, _aArray [_nLinha, _nCol])
			next
		endif
		
		// Adiciona a linha montada aa array.
		aadd (_aOpcoes, aclone (_aLinha))
	next
	
	// Monta array de cabecalhos e tamanhos das colunas, sempre iniciando pela coluna de 'ok'.
	_aCabec    = {"OK"}
	_aTamanhos = {20}
	if _aCols != NIL
		for _nCol = 1 to len (_aCols)
			aadd (_aCabec, _aCols [_nCol, 2])
			aadd (_aTamanhos, _aCols [_nCol, 3])
		next
	else
		for _nCol = 1 to len (_aArray [1])
			aadd (_aCabec, "Col." + alltrim (str (_nCol)))
		next
	endif
//	U_Log2 ('debug', '_aCabec:')
//	U_Log2 ('debug', _aCabec)
	
	define msdialog _oDlgMbA title _sTitulo from 0, 0 to _nAltur, _nLarg of oMainWnd pixel
	_oLbx := TWBrowse ():New (15, ;  // Linha
	                          10, ;  // Coluna
	                          _oDlgMbA:nClientWidth / 2 - 20, ;   // Largura
	                          _oDlgMbA:nClientHeight / 2 - 60, ;  // Altura
	                          NIL, ;                     // Campos
	                          _aCabec, ;  // Cabecalhos colunas
	                          _aTamanhos, ;          // Larguras colunas
	                          _oDlgMbA,,,,,,,,,,,,.F.,,.T.,,.F.,,,)             // Etc. Veja pasta IXBPAD
	                          _oLbx:SetArray (_aOpcoes)
	                          _oLbx:bLine := {|| _aOpcoes [_oLbx:nAt]}
	                          _oLbx:bLDblClick := {|| _aMBArrayV [2] := _oLbx:nAt, _aMBArrayV [3] := (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk), iif (&(_sLinhaOK), (_aOpcoes [_oLbx:nAt, 1] := iif (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk, _oBmpNo, _oBmpOk), _oLbx:Refresh()), NIL)}
	                          @ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 90 bmpbutton type 1 action (_lBotaoOK  := .T., _oDlgMbA:End ())
	                          @ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 40 bmpbutton type 2 action (_oDlgMbA:End ())
	                          @ _oDlgMbA:nClientHeight / 2 - 40,  10 button "Inverte selecao" SIZE 080, 010 action (_aMBArrayV [1] := aclone (_aArray), _Inverte (@_aOpcoes, _oBmpOk, _oBmpNo, _sLinhaOK), _oLbx:Refresh())
	                          @ _oDlgMbA:nClientHeight / 2 - 40,  100 button "Planilha" SIZE 050, 010 action (_ExpPlan (_aOpcoes, _oBmpOK, _aCabec))
	                          
	                          // Permite alguns botoes adicionais.
	                          if len (_aBotAdic) >= 1
	                          	@ _oDlgMbA:nClientHeight / 2 - 40,  160 button _aBotAdic [1, 1] SIZE 050, 010 action (&(_aBotAdic [1, 2]))
	                          endif
	                          if len (_aBotAdic) >= 2
	                          	@ _oDlgMbA:nClientHeight / 2 - 40,  220 button _aBotAdic [2, 1] SIZE 050, 010 action (&(_aBotAdic [2, 2]))
	                          endif
	                          if len (_aBotAdic) >= 3
	                          	@ _oDlgMbA:nClientHeight / 2 - 40,  220 button _aBotAdic [3, 1] SIZE 050, 010 action (&(_aBotAdic [3, 2]))
	                          endif
	                          activate dialog _oDlgMbA centered

	if _lBotaoOK
		// Verifica opcoes selecionadas conforme parametro
		_aRet = {}
		for _nLinha = 1 to len (_aOpcoes)
			if _nColMarca == NIL
				
				// Monta array com as linhas selecionadas
				if _aOpcoes [_nLinha, 1] == _oBmpOK
					aadd (_aRet, _nLinha)
				endif
			else
				_aArray [_nLinha, _nColMarca] = (_aOpcoes [_nLinha, 1] == _oBmpOK)
			endif
		next
		
	else  // Usuario clicou no botao 'cancelar'.
		
		_aRet = {}
		for _nLinha = 1 to len (_aOpcoes)
			if _nColMarca != NIL
				_aArray [_nLinha, _nColMarca] = .f.
			endif
		next
	endif
	
	DeleteObject(_oBmpOK)
	DeleteObject(_oBmpNo)
return _aRet



// --------------------------------------------------------------------------
// Inverte a marcacao no browse.
static function _Inverte (_aOpcoes, _oBmpOk, _oBmpNo, _sLinhaOK)
	local _nLinha := 0
	CursorWait ()
	for _nLinha = 1 to len (_aOpcoes)
		_aMBArrayV [2] := _nLinha
		_aMBArrayV [3] := (_aOpcoes [_nLinha, 1] == _oBmpOk)
		if &(_sLinhaOK)
			_aOpcoes [_nLinha, 1] = iif (_aOpcoes [_nLinha, 1] == _oBmpOk, _oBmpNo, _oBmpOk)
		endif
	next
	CursorArrow ()
return



// --------------------------------------------------------------------------
// Inverte a marcacao no browse.
static function _ExpPlan (_aOpcoes, _oBmpOK, _aCabec)
	local _aArrExp := {}
	local _nOpcao  := 0
	local _nCabec  := 0
	private aHeader := {}

	// Gera um aHeader 'fake' apenas para levar os nomes das colunas
	for _nCabec = 1 to len (_aCabec)
		aadd (aHeader, {_aCabec [_nCabec], _aCabec [_nCabec]})
	next

	if aviso ("O que exportar", "Deseja exportar somente os selecionados ou todos os registros?", {"Selecionados", "Todos"}) == 1
		for _nOpcao = 1 to len (_aOpcoes)
			if _aOpcoes [_nOpcao, 1] == _oBmpOK
				aadd (_aArrExp, aclone (_aOpcoes [_nOpcao]))
				_aArrExp [len (_aArrExp), 1] = 'X'
			endif
		next
	else
		for _nOpcao = 1 to len (_aOpcoes)
			aadd (_aArrExp, aclone (_aOpcoes [_nOpcao]))
			_aArrExp [len (_aArrExp), 1] = iif (_aOpcoes [_nOpcao, 1] == _oBmpOK, 'X', '')
		next
	endif
	U_AColsXLS (_aArrExp, .T.)
return
