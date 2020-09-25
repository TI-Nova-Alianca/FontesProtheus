// Programa:   FA100Can
// Autor:      André Alves
// Data:       05/11/2018
// Cliente:    Alianca
// Descricao:  P.E. gravar SE5 no cancelamento do movimento bancário.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA100Can ()
	local _aAreaAnt := U_ML_SRArea ()
	// grava tabela SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif
	U_ML_SRArea (_aAreaAnt)
return
