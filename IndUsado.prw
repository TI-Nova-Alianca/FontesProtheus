// Programa:   IndUsado
// Autor:      Robert Koch
// Data:       29/05/2009
// Cliente:    Generico
// Descricao:  Verifica (ou pelo menos tenta) se determinado indice eh usado no sistema.
//
// Historico de alteracoes:

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function IndUsado ()
	_sAlias := _Get ("Alias cujo indice sera' verificado", "C", 3, "@!", NIL, space (3), .F., ".T.")
	_sIndice := _Get ("Indice a ser verificado", "C", 2, "@!", NIL, space (2), .F., ".T.")
	processa ({|| _Andalogo ()})
Return



// --------------------------------------------------------------------------
static function _AndaLogo ()
	local _sResult := ""
	procregua (4)

	// Converte para numerico, para poder comparar com o SX7
	_sIndAux = "1"
	_nIndice = 1
	do while _sIndAux < _sIndice
		_nIndice ++
		_sIndAux = soma1 (_sIndAux)
	enddo

	if ! six -> (dbseek (_sAlias + _sIndAux, .F.))
		_sResult += "Indice nao consta no arquivo SIX" + sx7 -> x7_campo + chr (13) + chr (10)
	else
		if six -> propri == "S"
			_sResult += "Indice e' padrao do sistema" + sx7 -> x7_campo + chr (13) + chr (10)
		endif
	endif

	// Verifica se consta em algum gatilho
	incproc ("Verificando SX7")
	sx7 -> (dbgotop ())
	do while ! sx7 -> (eof ())
		if sx7 -> x7_alias == _sAlias .and. sx7 -> x7_ordem == _nIndice
			_sResult += "Indice consta no gatilho " + sx7 -> x7_sequenc + " do campo " + sx7 -> x7_campo + chr (13) + chr (10)
		endif
		if "FBUSCACPO" $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic) ;
			.or. "POSICIONE" $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic) ;
			.or. "EXISTCPO" $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic) ;
			.or. "EXISTCHAV" $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic)
			if "'" + _sAlias + "'" $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic) ;
				.or. '"' + _sAlias + '"' $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic)
				if cvaltochar (_nIndice) $ upper (sx7 -> x7_regra + sx7 -> x7_chave + sx7 -> x7_condic)
					_sResult += "indice parece participar do gatilho " + sx7 -> x7_sequenc + " do campo " + sx7 -> x7_campo + chr (13) + chr (10)
				endif
			endif
		endif
		sx7 -> (dbskip ())
	enddo

	// Verifica se consta na configuracao de algum campo.
	incproc ("Verificando SX3")
	sx3 -> (dbgotop ())
	do while ! sx3 -> (eof ())
		if "FBUSCACPO" $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw) ;
			.or. "POSICIONE" $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw) ;
			.or. "EXISTCHAV" $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw) ;
			.or. "EXISTCPO" $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw)
			if "'" + _sAlias + "'" $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw) ;
				.or. '"' + _sAlias + '"' $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw)
				if cvaltochar (_nIndice) $ upper (sx3 -> x3_valid + sx3 -> x3_relacao + sx3 -> x3_vlduser + sx3 -> x3_when + sx3 -> x3_inibrw)
					_sResult += "Indice parece constar na configuracao do campo " + sx3 -> x3_campo + chr (13) + chr (10)
				endif
			endif
		endif
		sx3 -> (dbskip ())
	enddo

	// Verifica se consta em algum lancamento padrao.
	incproc ("Verificando CT5")
	procregua (ct5 -> (reccount ()))
	ct5 -> (dbgotop ())
	do while ! ct5 -> (eof ())
		if "FBUSCACPO" $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori) ;
			.or. "POSICIONE" $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori) ;
			.or. "EXISTCHAV" $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori) ;
			.or. "EXISTCPO" $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori)
			if "'" + _sAlias + "'" $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori) ;
				.or. '"' + _sAlias + '"' $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori)
				if cvaltochar (_nIndice) $ upper (ct5 -> ct5_debito + ct5 -> ct5_credit + ct5 -> ct5_vlr01 + ct5 -> ct5_vlr02 + ct5 -> ct5_vlr03 + ct5 -> ct5_vlr04 + ct5 -> ct5_vlr05 + ct5 -> ct5_hist + ct5 -> ct5_ccd + ct5 -> ct5_ccc + ct5 -> ct5_origem + ct5 -> ct5_itemd + ct5 -> ct5_itemc + ct5 -> ct5_clvlcr + ct5 -> ct5_clvldb + ct5 -> ct5_ativde + ct5 -> ct5_ativcr + ct5 -> ct5_tabori + ct5 -> ct5_recori)
					_sResult += "Indice parece constar no lancamento padrao " + ct5 -> ct5_lanpad + "/" + ct5 -> ct5_sequen + chr (13) + chr (10)
				endif
			endif
		endif
		ct5 -> (dbskip ())
	enddo

	if empty (_sResult)
		msginfo ("Nada encontrado.")
	else
		msginfo (_sResult, "Utilizacao do indice")
	endif
	msgalert ("Lembre-se de verificar, tambem, nos fontes de programas!")
Return



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
