// Programa:  MTA242V
// Autor:     Robert Koch
// Data:      04/05/2018
// Descricao: P.E. valida 'Tudo OK' na tela da desmontagem de produtos.
//            Criado inicialmente para bloquear datas retroativas.
//
// Historico de alteracoes:
// 12/02/2021 - Robert - Chama MT242LOk ('linha ok') de todas as linhas (GLPI 9388)
//

// --------------------------------------------------------------------------
User Function MTA242V ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _nLinha   := 0
	local _nAnt     := 0

	if _lRet .and. (dDataBase != date () .or. dEmis260 != date ())
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif

	// Valida todas as linhas para evitar que o usuario altere a parte de cima da tela, gerando inconsistencia
	// com alguma das linhas.
	if _lRet
		_nAnt := N
		for _nLinha = 1 to len (aCols)
			N = _nLinha
			if ! U_MT242LOk ()
				_lRet = .F.
				exit
			endif
		next
		N := _nAnt
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
