// Programa:  MTA242V
// Autor:     Robert Koch
// Data:      04/05/2018
// Descricao: P.E. valida 'Tudo OK' na tela da desmontagem de produtos.
//            Criado inicialmente para bloquear datas retroativas.
//
// Historico de alteracoes:
// 12/02/2021 - Robert - Chama MT242LOk ('linha ok') de todas as linhas (GLPI 9388)
// 16/02/2021 - Robert - Consiste litragem desmontada x gerada (GLPI 9388)
//

// --------------------------------------------------------------------------
User Function MTA242V ()
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _nLinha    := 0
	local _nAnt      := 0
	local _nLitrOrig := 0
	local _nLitrDest := 0
	local _sMsg      := ''

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
		_nLitrOrig = fBuscaCpo ("SB1", 1, xfilial ("SB1") + cProduto, "B1_LITROS") * nQtdOrig
		_nAnt := N
		for _nLinha = 1 to len (aCols)
			N = _nLinha
			if ! U_MT242LOk ()
				_lRet = .F.
				exit
			endif
			if ! GDDeleted ()
				_nLitrDest += fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("D3_COD"), "B1_LITROS") * GDFieldGet ("D3_QUANT")
			endif
		next
		N := _nAnt
	endif

	// Consiste litragem
	if _lRet
		if _nLitrDest != _nLitrOrig
			_sMsg := "Com base nos cadastros de produtos, a litragem total do(s) item(s) gerado(s) foi calculada em " + cvaltochar (_nLitrDest)
			_sMsg += " litros, enquando a litragem do item desmontado foi calculada em " + cvaltochar (_nLitrOrig)
			_sMsg += " litros. Esses valores deveriam ser iguais."
			if U_ZZUVL ('098', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg)
				_lRet = .F.
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
