// Programa:  Get
// Autor:     Robert Koch
// Data:      nov/2002
// Descricao: Monta uma janela com texto e uma linha de get na tela. Usada para solicitar
//            algum dado adicional ao usuario.
//
// Historico de alteracoes:
// 26/06/2003 - Robert - Implementada leitura de senha
// 19/01/2007 - Robert - Incluida opcao de informar funcao para validacao
//                     - Retorna NIL em caso de cancelamento
// 12/02/2023 - Robert - Quando o texto a mostrar for grande, quebra em 2 linhas.
// 18/09/2023 - Robert - Gera erro quando nao encontra interface com usuario.
//

// Parametros: _sTexto   = texto a ser mostrado antes do get
//             _sTipo    = tipo de dado (C, D, N)
//             _nTamanho = tamanho da variavel a ser lida
//             _sMasc    = mascara (picture) a ser usada
//             _sF3      = para consulta padrao, se tiver. Senao, informar ""
//             _xIni     = inicializador para a variavel
//             _lPass    = se .T. faz leitura de senha (mostra asteriscos)
//             _sValid   = funcao para validacao

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function Get (_sTexto, _sTipo, _nTamanho, _sMasc, _sF3, _xIni, _lPass, _sValid)
	local _xRet     := NIL
	local _oDlgGet  := NIL
	local _nLargura := 0
	private _xDado  // Deixar private para ser vista pela funcao de validacao

	if type ("oMainWnd") != "O"  // Se nao tem interface com o usuario
		u_help ("Sem interface com usuario na funcao " + procname () + " ao tentar ler a pergunta '" + cvaltochar (_sTexto) + "'",, .t.)
	else
		_nLargura := min (max (300, max (len (_sTexto) * 5, _nTamanho * 10)), oMainWnd:nClientwidth / 2)
		_sF3    = iif (_sF3    == NIL, "",    _sF3)
		_sMasc  = iif (_sMasc  == NIL, "",    _sMasc)
		_lPass  = iif (_lPass  == NIL, .F.,   _lPass)
		_sValid = iif (_sValid == NIL, ".T.", _sValid)

		if _xIni != NIL .and. valtype (_xIni) != _sTipo
			msgbox ("Funcao " + procname () + ": inicializador incompativel com tipo de dado!")
			return NIL
		endif

		do case
			case _sTipo == "N"
				_xDado := iif (_xIni == NIL, 0, _xIni)
			case _sTipo == "D"
				_xDado := iif (_xIni == NIL, ctod (""), _xIni)
			case _sTipo == "C" .or. _sTipo == "M"
				_xDado := iif (_xIni == NIL, space (_nTamanho), _xIni)
		endcase

		define MSDialog _oDlgGet from 0, 0 to 160, _nLargura of oMainWnd pixel title "Entrada de dados"
			if len (_sTexto) <= 100
				@ 20, 10 say _sTexto
			else
				@ 6, 10 say substr (_sTexto, 1, 100)
				@ 16, 10 say substr (_sTexto, 101, 100)
				@ 26, 10 say substr (_sTexto, 201, 100)
				@ 36, 10 say substr (_sTexto, 301, 100)
			endif
			if _lPass
				@ 50, 10 get _xDado picture _sMasc size (_nTamanho * 5), 11 F3 _sF3 PASSWORD
			else
				@ 50, 10 get _xDado picture _sMasc size (_nTamanho * 5), 11 F3 _sF3
			endif
			@ 65, 10 bmpbutton type 1 action (iif (&(_sValid), (_xRet := _xDado, _oDlgGet:End ()), NIL))
		activate MSDialog _oDlgGet centered
	endif
return _xRet
