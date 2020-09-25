// Programa:  CT105Chk
// Autor:     Robert Koch
// Data:      07/10/2011
// Descricao: P.E. 'Tudo OK' na tela de inclusao de lancamentos contabeis.
//
// Historico de alteracoes:
// 27/10/2014 - Robert - Nao permite mesma conta a debito e a credito quando partida dobrada.
// 03/11/2015 - Robert - Valida CC x conta (novos CC devem obrigatoriamente iniciar com mesmo codigo da filial).
//

// --------------------------------------------------------------------------
user function CT105Chk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _sMsg     := ""
	local _sMsgAux  := ""
	local _sErro    := ""

	ct1 -> (dbsetorder (1))  // CT1_FILIAL+CT1_CONTA
	
	// Varre arquivo temporario que contem os lctos em tela.
	tmp -> (dbgotop ())
	do while ! tmp -> (eof ())
		if ! tmp -> ct2_flag  // Nao deletado
			if left (tmp -> ct2_debito, 1) $ '4/7'
				if ct1 -> (dbseek (xfilial ("CT1") + tmp -> ct2_debito, .F.)) .and. ct1 -> ct1_normal == '2'
					_sMsgAux = "Conta '" + alltrim (tmp -> ct2_debito) + "' eh normalmente credora."
					_sMsg += iif (_sMsgAux $ _sMsg, "", _sMsgAux + chr (13) + chr (10))
				endif
			endif
			if left (tmp -> ct2_credit, 1) $ '4/7'
				if ct1 -> (dbseek (xfilial ("CT1") + tmp -> ct2_credit, .F.)) .and. ct1 -> ct1_normal == '1'
					_sMsgAux = "Conta '" + alltrim (tmp -> ct2_credit) + "' eh normalmente devedora."
					_sMsg += iif (_sMsgAux $ _sMsg, "", _sMsgAux + chr (13) + chr (10))
				endif
			endif

			if tmp -> ct2_debito == tmp -> ct2_credit .and. ! empty (tmp -> ct2_debito) .and. ! empty (tmp -> ct2_credit)
				_sErro += "Linha " + tmp -> ct2_linha + ": lancamento nao pode ser a debito e a credito na mesma conta (" + tmp -> ct2_credit + ")" + chr (13) + chr (10)
			endif

			// Centros de custo alterados a partir de nov/2015
			if dtos (dDataLanc) >= '20151101'
				if ! empty (tmp -> ct2_ccd) .and. left (tmp -> ct2_ccd, 2) != cFilAnt
					_sErro += "Linha " + tmp -> ct2_linha + ": centro de custo a debito nao pertence a esta filial." + chr (13) + chr (10)
				endif
				if ! empty (tmp -> ct2_ccc) .and. left (tmp -> ct2_ccc, 2) != cFilAnt
					_sErro += "Linha " + tmp -> ct2_linha + ": centro de custo a credito nao pertence a esta filial." + chr (13) + chr (10)
				endif
			endif

		endif
		tmp -> (dbskip ())
	enddo

	if ! empty (_sErro)
		u_help (_sErro)
		_lRet = .F.
	endif

	if _lRet .and. ! empty (_sMsg)
		_lRet = MsgNoYes (_sMsg + chr (13) + chr (10) + "Confirma os lancamentos mesmo assim?", procname ())
	endif

//	u_log (procname () + ' retornando ' + cvaltochar (_lRet))

	U_ML_SRArea (_aAreaAnt)
return _lRet
