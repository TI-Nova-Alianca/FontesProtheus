// Programa:   PrcLoja
// Autor:      Robert Koch
// Data:       21/02/2011
// Cliente:    Alianca
// Descricao:  Usar na validacao padrao do campo LR_PRODUTO para alterar o 
//             preco no SB0 antes que a validacao padrao leia-o.
//             Fazer a chamada ANTES da validacao padrao.
//
// Historico de alteracoes:
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function PrcLoja ()
	local _aAreaAnt := U_ML_SRArea ()
	local _nPreco   := 0

	sb0 -> (dbsetorder (1))
	if sb0 -> (dbseek (xfilial ("SB0") + m->LR_produto, .f.))
		_nPreco = _Get ("Confirme preco", "N", 9, "@E 999,999.99", "", sb0 -> b0_vaprv1, .F., ".T.")
		if _nPreco > 0
			reclock ("SB0", .F.)
			sb0 -> b0_prv1 = _nPreco
			msunlock ()
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return .t.



// --------------------------------------------------------------------------
// Monta uma janela com texto e uma linha de get na tela. Usada para solicitar
// algum dado adicional ao usuario.
// Autor: Robert Koch - nov/2002
// Parametros: _sTexto   = texto a ser mostrado antes do get
//             _sTipo    = tipo de dado (C, D, N)
//             _nTamanho = tamanho da variavel a ser lida
//             _sMasc    = mascara (picture) a ser usada
//             _sF3      = para consulta padrao, se tiver. Senao, informar ""
//             _xIni     = inicializador para a variavel
//             _lPass    = se .T. faz leitura de senha (mostra asteriscos)
//             _sValid   = funcao para validacao
//
// Historico de alteracoes:
// 26/06/2003 - Robert - Implementada leitura de senha
// 19/01/2007 - Robert - Incluida opcao de informar funcao para validacao
//                     - Retorna NIL em caso de cancelamento
//
static function _Get (_sTexto, _sTipo, _nTamanho, _sMasc, _sF3, _xIni, _lPass, _sValid)
   local _xRet     := NIL
   local _oDlgGet  := NIL
   local _nLargura := min (max (300, max (len (_sTexto) * 5, _nTamanho * 10)), oMainWnd:nClientwidth / 2)
   private _xDado  // Deixar private para ser vista pela funcao de validacao

   _sF3    = iif (_sF3    == NIL, "",    _sF3)
   _sMasc  = iif (_sMasc  == NIL, "",    _sMasc)
   _lPass  = iif (_lPass  == NIL, .F.,   _lPass)
   _sValid = iif (_sValid == NIL, ".T.", _sValid)

   if _xIni != NIL .and. valtype (_xIni) != _sTipo
      msgbox ("Funcao _GET: inicializador incompativel com tipo de dado!")
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

   define MSDialog _oDlgGet from 0, 0 to 120, _nLargura of oMainWnd pixel title "Entrada de dados"
      @ 10, 10 say _sTexto
      if _lPass
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3 PASSWORD
      else
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3
      endif
      @ 45, 10 bmpbutton type 1 action (iif (&(_sValid), (_xRet := _xDado, _oDlgGet:End ()), NIL))
   activate MSDialog _oDlgGet centered
return _xRet
