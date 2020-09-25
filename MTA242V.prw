// Programa:  MTA242V
// Autor:     Robert Koch
// Data:      04/05/2018
// Descricao: P.E. valida 'Tudo OK' na tela da desmontagem de produtos.
//            Criado inicialmente para bloquear datas retroativas.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MTA242V ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()

	if _lRet .and. (dDataBase != date () .or. dEmis260 != date ())
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
