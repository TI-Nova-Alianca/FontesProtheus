// Programa:  VA_wHEN
// Autor:     ?
// Data:      07/09/2006
// Descricao: Valida edicao de campos (usar no X3_WHEN)
//
// Historico de alteracoes:
// 22/01/2013 - Robert - Tornado generico (servia apenas para campos do SA1).
//

// --------------------------------------------------------------------------
User Function VA_WHEN (xTipo)
/*
	local _lRet      := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	private _sArqLog := U_NomeLog ()
	u_logId ()
	u_logIni ()
	u_log (readvar ())
	u_log (funname ())
	u_logPCham ()
	u_logtrb ('sx3')
*/
//           tipo 1: a1_risco, a1_lc, a1_venlc
//Return(upper(alltrim(cUserName)) $ GetMv('VA_WHEN'+ str(xTipo,1)))
	_lRet = upper(alltrim(cUserName)) $ GetMv('VA_WHEN'+ str(xTipo,1))

//FBUSCACPO("SB1",1,XFILIAL("SB1")+GDFIELDGET("ZF_PRODUTO"),"B
/*
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
*/
return _lRet
