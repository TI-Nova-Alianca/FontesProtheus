// Programa...: A140EXC
// Autor......: Catia Cardos
// Data.......: 05/01/2017
// Descricao..: P.E. - exclusao pré-nota
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function A140EXC()
	local _lRet := .T.
	local _aAreaAnt    := U_ML_SRArea ()
	
//	msgalert("Entrou no ponto de entrada")
	zzx -> (dbsetorder (4))
	if zzx -> (dbseek (SF1->F1_CHVNFE, .F.))
//		msgalert("Altera STATUS ZZX")
		If reclock ("ZZX", .F.)
			ZZX->ZZX_STATUS := '3'
			msunlock ()
		endif			
	Endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet