// Programa...: GrvAviso
// Autor......: Robert Koch
// Data.......: 10/10/2019
// Descricao..: Gravacao de avisos em geral para usuarios.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function GrvAviso (_sTipo, _sDestinat, _sMsg, _sOrigem, _nDiasVida)
	local _aAreaAnt  := U_ML_SRArea ()
	local _i      := 0
	local _sPilha := ""

	u_log ('[' + procname () + '] Aviso para', _sDestinat, ':', _sMsg)
	
	do while procname (_i) != ""
		_sPilha += '=>' + procname (_i)
		_i++
	enddo
	reclock ("ZAB", .T.)
	zab -> zab_tipo   = _sTipo
	zab -> zab_destin = _sDestinat
	zab -> zab_texto  = _sMsg
	zab -> zab_dtemis = date ()
	zab -> zab_hremis = time ()
	zab -> zab_origem = iif (_sOrigem == NIL .or. empty (_sOrigem), _sPilha, _sOrigem)
	zab -> zab_valid  = iif (_nDiasVida == NIL, iif (_sTipo == 'E', 0, 30), _nDiasVida)
	zab -> zab_lido   = 'N'
	msunlock ()
	U_ML_SRArea (_aAreaAnt)
return
