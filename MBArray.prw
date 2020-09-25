// Programa...: MBArray
// Autor......: Robert Koch
// Data.......: 07/12/2004
// Descricao..: MarkBrowse para arrays
// Cliente....: Generico
//
// Historico de alteracoes:
// 23/04/2005 - Robert - Melhorias gerais
// 24/10/2006 - Robert - Ajustes posicionamento botoes para versao 'Flat'
// 21/05/2008 - Robert - Mesmo se o usuario clicasse em 'cancelar', retornava itens marcados.
// 08/07/2008 - Robert - Melhorado posicionamento em tela.
//                     - Criado botao de 'inverte selecao'.
// 17/04/2009 - Robert - Criado parametro de validacao de 'Linha OK'
// 29/11/2010 - Robert - Nao usa mais a tela cheia por default.
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
user function MbArray (_aArray, _sTitulo, _aCols, _nColMarca, _nLarg, _nAltur, _sLinhaOK)
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

	// Se nao foi informada funcao para validacao, assume .T.
	_sLinhaOK := iif (_sLinhaOK == NIL, "AllwaysTrue()", _sLinhaOK)

	// Define tamanho da tela.
	if _nAltur == NIL .or. _nLarg == NIL
		_aSize := MsAdvSize()
		_nAltur = _aSize [6] * .9
		_nLarg  = _aSize [5] * .9
	endif
	
	if valtype (_aArray) != "A"
		msgalert ("Funcao " + procname () + " recebeu parametro incorreto")
		return {}
	endif
	if len (_aArray) == 0
		msgalert ("Funcao " + procname () + " recebeu array de opcoes vazia")
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
	//_oLbx:bLDblClick := {|| _aMBArrayV [1] := aclone (_aArray), _aMBArrayV [2] := _oLbx:nAt, _aMBArrayV [3] := (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk), iif (&(_sLinhaOK), (_aOpcoes [_oLbx:nAt, 1] := iif (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk, _oBmpNo, _oBmpOk), _oLbx:Refresh()), NIL)}
	_oLbx:bLDblClick := {|| _aMBArrayV [2] := _oLbx:nAt, _aMBArrayV [3] := (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk), iif (&(_sLinhaOK), (_aOpcoes [_oLbx:nAt, 1] := iif (_aOpcoes [_oLbx:nAt, 1] == _oBmpOk, _oBmpNo, _oBmpOk), _oLbx:Refresh()), NIL)}
	@ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 90 bmpbutton type 1 action (_lBotaoOK  := .T., _oDlgMbA:End ())
	@ _oDlgMbA:nClientHeight / 2 - 40, _oDlgMbA:nClientWidth / 2 - 40 bmpbutton type 2 action (_oDlgMbA:End ())
	@ _oDlgMbA:nClientHeight / 2 - 40, 10 button "Inverte selecao" action (_aMBArrayV [1] := aclone (_aArray), _Inverte (@_aOpcoes, _oBmpOk, _oBmpNo, _sLinhaOK), _oLbx:Refresh())
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
