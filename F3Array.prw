// Programa...: F3Array
// Autor......: Robert Koch
// Data.......: 19/03/2008
// Descricao..: Implementa tela para mostrar uma array onde o usuario pode selecionar uma das linhas.
//              Se nenhuma linha for selecionada (pressionado ESC ou fechado dialogo), retorna zero.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Mostra array em tela (grid) para selecao do usuario.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
// 08/05/2008 - Robert - Melhoria layout
//                     - Botao "Excel" nao eh mais selecionado como default.
// 29/05/2008 - Robert - Criada opcao de textos adicionais e mostrar ou nao o botao de exportacao para Excel.
// 18/10/2011 - Robert - Criada opcao de pesquisa (inicialmente apenas na coluna 1).
// 17/03/2015 - Robert - Criada funcao _Planilha para passar nomes de columas para o U_aColsXLS()
//                     - Aumentado tamanho default da tela.
// 21/09/2015 - Robert - Quando nao tiver interface com usuario, exporta a array via funcao u_log().
// 23/09/2015 - Robert - Tratamento para quando receber dado que nao eh array.
//                     - Quando receber um vetor (unidimensional) converte para array bidimensional.
// 25/11/2019 - Robert - Mensagem de aviso quando tenta-se exportar planilha sem ter a variavel _aCols.
// 24/11/2020 - Robert - Comentariados logs desnecessarios.
//                     - Inseridas tags para catalogo de fontes.
// 17/05/2023 - Robert - Mostra msg de erro quando nao receber a array de definicao de colunas.
// 14/07/2023 - Robert - Criado parametro para informar mensagem a mostrar quando a lista estiver vazia.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Parms.: 1 - Array a listar.
//         2 - Titulo da janela
//         3 - Array com as colunas a mostrar: 1 - Numero da coluna
//                                             2 - Titulo da coluna
//                                             3 - Tamanho da coluna (em pixels)
//                                             4 - Mascara da coluna
//         4 - Largura da janela (opcional)
//         5 - Altura da janela (opcional)
//         6 - Linha de texto a ser mostrada acima do browse (opcional)
//         7 - Linha de texto a ser mostrada abaixo do browse (opcional)
//         8 - Valor logico indicando se mostra botao de exportacao para Excel. Default = .F.
//         9 - Tipo de pesquisa (C=caracter, N=numerico)
//        10 - Msg a mostrar quando a array estiver vazia
user function F3Array (_aArray, _sTitulo, _aCols, _nLarg, _nAltur, _sMsgSup, _sMsgInf, _lExcel, _sTipoPesq, _oFonte, _sMsgVazio)
	local _oDlg      := NIL
	local _aOpcoes   := {}
	local _nLinha    := 0
	local _aLinha    := {}
	local _nCol      := 0
	local _aCabec    := {}
	local _aTamanhos := {}
//	local _lBotaoOK  := .F.
	local _lContinua := .T.
	local _bAcao     := {|| _nRet := _oLbx:nAt, _oDlg:End()}
	local _xPesq     := NIL
	local _aAux      := {}
	private _oLbx    := NIL
	private _nRet    := 0  // Deixar private para ser visto no bloco de codigo.
	
	if _lContinua .and. valtype (_aArray) != 'A'
		u_help ("Funcao " + procname () + " recebeu array invalida. Conteudo: " + cvaltochar (_aArray))
		_lContinua = .F.
	endif
	if _lContinua .and. len (_aArray) == 0
		if valtype (_sMsgVazio) == 'C' .and. ! empty (_sMsgVazio)
			u_help (_sMsgVazio)
		else
			u_help ("Funcao " + procname () + " recebeu lista vazia")
		endif
		_lContinua = .F.
	endif
	if _lContinua .and. valtype (_aCols) != 'A' .or. len (_aCols) == 0
		U_help ('Funcao ' + procname () + ' nao recebeu array de definicao de colunas.')
		_lContinua = .F.
	endif

//	u_log2 ('debug', 'Array recebida:')
//	u_log2 ('debug', _aArray)
	
	// Se recebeu uma array unidimensional, cria uma nova, "convertendo" para colunas.
	if _lContinua .and. len (_aArray) >= 1 .and. valtype (_aArray [1]) != 'A'
//		u_log2 ('debug', '[' + procname () + '] Convertendo vetor para array bidimensional.')
		_aAux = aclone (_aArray)
		_aArray = {}
		for _nLinha = 1 to len (_aAux)
			aadd (_aArray, {_aAux [_nLinha]})
		next
	endif

	if _lContinua .and. type ("oMainWnd") != 'O'
		u_help ("Funcao " + procname () + " nao encontrou ambiente grafico (interface com usuario). Usando funcao U_Log para exportar a array recebida.")
		U_Log2 ('info', _aArray)
		_lContinua = .F.
	endif

	if _lContinua
		_aArray    = iif (_aArray    == NIL, {}, _aArray)
		_sTitulo   = iif (_sTitulo   == NIL, "", _sTitulo)
		_nLarg     = iif (_nLarg     == NIL, oMainWnd:nClientWidth / 1.1, _nLarg)
		_nAltur    = iif (_nAltur    == NIL, oMainWnd:nClientHeight / 1.2, _nAltur)
		_sMsgSup   = iif (_sMsgSup   == NIL, "", _sMsgSup)
		_sMsgInf   = iif (_sMsgInf   == NIL, "", _sMsgInf)
		_lExcel    = iif (_lExcel    == NIL, .T., _lExcel)
		_sTipoPesq = iif (_sTipoPesq == NIL, "", _sTipoPesq)
	endif

	// Monta array para a listbox
	if _lContinua
		_aOpcoes = {}
		for _nLinha = 1 to len (_aArray)
			
			// Monta cada linha da array
			_aLinha = {}
	
			// Adiciona as colunas selecionadas pelo parametro. Se nao informado, adiciona todas.
			if _aCols != NIL
				for _nCol = 1 to len (_aCols)
					aadd (_aLinha, transform (_aArray [_nLinha, _aCols [_nCol, 1]], _aCols [_nCol, 4]))
				next
			else
				for _nCol = 1 to len (_aArray [1])
					aadd (_aLinha, _aArray [_nLinha, _nCol])
				next
			endif
			
			// Adiciona na array a linha montada.
			aadd (_aOpcoes, aclone (_aLinha))
		next
	endif
	
	// Monta array de cabecalhos e tamanhos das colunas.
	if _lContinua
		_aCabec    = {}
		_aTamanhos = {}
		if _aCols != NIL
			for _nCol = 1 to len (_aCols)
				aadd (_aCabec, _aCols [_nCol, 2])
				aadd (_aTamanhos, _aCols [_nCol, 3])
			next
		else
			for _nCol = 1 to len (_aArray [1])
				aadd (_aCabec, "Col_" + alltrim (str (_nCol)))
			next
		endif
		
		define msdialog _oDlg title _sTitulo from 0, 0 to _nAltur, _nLarg of oMainWnd pixel
		@ 10, 10 say _sMsgSup

		if ! empty (_sTipoPesq)
			_xPesq := iif (_sTipoPesq == 'C', space (10), iif (_sTipoPesq == 'N', 0, NIL))
			@ 25, 10 say "Pesquisar:"
			@ 25, 60 get _xPesq valid _Pesquisa (_aOpcoes, _xPesq, _sTipoPesq) size 50, 10
		endif

		_oLbx := TWBrowse ():New (iif (empty (_sMsgSup), 15, iif (! empty (_sTipoPesq), 40, 30)),;     // Linha
		10, ;                               // Coluna
		_oDlg:nClientWidth / 2 - 20, ;      // Largura
		_oDlg:nClientHeight / 2 - (60 + iif (empty (_sMsgInf), 0, 15) + iif (empty (_sMsgSup), 0, 15)), ;     // Altura
		NIL, ;                              // Campos
		_aCabec, ;                          // Cabecalhos colunas
		_aTamanhos, ;                       // Larguras colunas
		_oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,)  // Etc. Veja pasta IXBPAD
		_oLbx:SetArray (_aOpcoes)
		_oLbx:bLine := {|| _aOpcoes [_oLbx:nAt]}
		_oLbx:bLDblClick := _bAcao
		
		if valtype (_oFonte) == 'O'
		endif

		@ _oDlg:nClientHeight / 2 - 40, 10 say _sMsgInf
		@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 35 bmpbutton type 1 action eval (_bAcao)
		if _lExcel
			@ _oDlg:nClientHeight / 2 - 30, 10 button "Planilha" action _Planilha (_aArray, _aCols)
		endif
		activate dialog _oDlg centered
		
	endif
return _nRet



// --------------------------------------------------------------------------
static function _Pesquisa (_aOpcoes, _xPesq, _sTipoPesq)
	local _nLinha := 0
	if ! empty (_xPesq)
		_nLinha = ascan (_aOpcoes, {|_aVal| _aVal [1] >= _xPesq})
		_oLbx:GoPosition (iif (_nLinha == 0, 1, _nLinha))
	endif
return



// --------------------------------------------------------------------------
static function _Planilha (_aArray, _aCols)
	local _nCampo := 0
	private aHeader := {}
	
	if valtype (_aArray) != 'A' .or. valtype (_aCols) != 'A'
		u_help ("Dados invalidos ou vazios (array de dados / definicao de colunas) para gerar planilha")
	else
		//u_log (_aCols)
		for _nCampo = 1 to len (_aCols)
			aadd (aHeader, {_aCols [_nCampo, 2], _aCols [_nCampo, 2], _aCols [_nCampo, 4], 15, 0, "", '', 'C', '', '', '', '', '.t.'})
		next
		//u_log (aHeader)
		U_aColsXLS (_aArray)
	endif
return
