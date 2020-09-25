// Programa:   MT685TOK
// Autor:      Robert Koch
// Data:       12/11/2014
// Descricao:  P.E. 'Tudo OK' na tela de apontamento de perda.
//
// Historico de alteracoes:
// 04/05/2018 - Robert - Bloqueada movimentacao com diferenca de data maior que 5 dias da atual.
// 13/05/2020 - Robert - Passa a consultar o parametro AL_DRDTPRO para limite de dias a retroagir.
//

// --------------------------------------------------------------------------
user function MT685TOK ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
   	local _aAmbAnt  := U_SalvaAmb ()
   	u_logIni ()

	if ! lParam // Variavel private do programa
		u_help ("Para apontar perdas pressione F12 ao entrar na tela e altere o parametro para 'Requisita produto origem = SIM'") 
		_lRet = .F.
	endif

	if _lRet
		_lRet = _VerData ()
	endif

   	U_SalvaAmb (_aAmbAnt)
   	U_ML_SRArea (_aAreaAnt)
   	u_logFim ()
return _lRet



// --------------------------------------------------------------------------
static function _VerData ()
	local _lRet     := .T.
	local _nLinha   := 0
	local _nMaxData := SUPERGETMV ('AL_DRDTPRO', .T., 5)  //5  // Diferenca maxima de dias para apontamento.
	
	for _nLinha = 1 to len (aCols)
		if abs (dDataBase - date ()) > _nMaxData .or. abs (GDFieldGet ("BC_DATA", _nLinha) - date ()) > _nMaxData
			_sMsg = "Linha " + cvaltochar (_nLinha) + ": alteracao de data da movimentacao ou data base do sistema nao pode exceder " + cvaltochar (_nMaxData) + " dias para esta rotina, conforme definido no parametro AL_DRDTPRO."
			if U_ZZUVL ('084', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg)
				_lRet = .F.
			endif
			if ! _lRet
				exit
			endif
		endif
	next
return _lRet
