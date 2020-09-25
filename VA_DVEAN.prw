// Programa:   VA_DVEAN
// Autor:      Robert Koch
// Data:       08/09/2010
// Descricao:  Tela para calculo de digito verificador para codigo EAN.
//
// Historico de alteracoes:
// 05/08/2016 - Robert - Soh gera o DV se o usuario informar a 'base' com a quantidade correta de digitos.
// 22/10/2018 - Robert - Lista (informativo) o maior codigo valido.
// 03/09/2019 - Andre  - Campo B1_VAEANUN substituido pelo B5_2CODBAR.
//

// --------------------------------------------------------------------------
user function VA_DVEAN ()
	local _sBase     := space (17)  // Pelo que conheco, eh o maior tamanho de codigo EAN sem o digito.
	local _nQual     := 0
	local _nTamanho  := 0
	local _nPos      := 0
	local _lContinua := .T.
	local _sUltEAN   := ""
	private _sArqLog := iif (type ('_sArqLog') == 'C', _sArqLog, U_NomeLog ())

	u_logIni ()

	//_sUltEAN = U_RetSQL ("SELECT MAX (B1_VAEANUN) FROM SB1010 WHERE D_E_L_E_T_ = '' AND B1_VAEANUN LIKE '78961005%'")
	_sUltEAN = U_RetSQL ("SELECT MAX (B5_2CODBAR) FROM SB5010 WHERE D_E_L_E_T_ = '' AND B5_2CODBAR LIKE '78961005%'")

	do while .T.
		_lContinua = .T.
		_nQual = aviso ("Selecione tipo de codigo", ;
		                "Selecione tipo de codigo (ultimo codigo valido no cadastro: " + _sUltEAN + ")", ;
		                {"Garrafa(EAN)", "Caixa(DUN)", "Cancelar"}, ;
		                3, ;
		                "Tipo de codigo")
		u_log ('_nQual=', _nQual)
		if _nQual == 1
			_nTamanho = 12
		elseif _nQual == 2
			_nTamanho = 13
		elseif _nQual == 3
			_lContinua = .F.
			exit
		endif

		if _lContinua
			u_log ('_nTamanho =', _nTamanho)
			_sBase = U_Get ("Informe codigo 'base' para calculo do digito verificador", "C", _nTamanho, "", "", space (_nTamanho), .F., ".t.")
			if empty (_sBase)  // Retorna NIL se o usuario cancelar a digitacao.
				_lContinua = .F.
			endif
		endif
				
		if _lContinua
			_sBase = alltrim (_sBase)
			if len (_sBase) != _nTamanho
				u_help ("Codigo base deve ser informado com " + cvaltochar (_nTamanho) + " posicoes.")
				_lContinua = .F.
			endif
		endif
	
		if _lContinua
			for _nPos = 1 to len (_sBase)
				if ! IsDigit (substr (_sBase, _nPos, 1))
					u_help ("Posicao " + cvaltochar (_nPos) + " deve ser numerica.")
					_lContinua = .F.
					exit
				endif
			next
		endif
	
		if _lContinua
			u_help ("Codigo gerado: " + U_ML_DVEAN (_sBase, .T.))
		endif
	enddo
	u_logFim ()
return


/*
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
*/