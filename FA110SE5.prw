// Programa:   FA110SE5
// Autor:      André Alves
// Data:       05/11/2018
// Cliente:    Alianca
// Descricao:  P.E. gravar SE5 na baixa automática
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA110SE5 ()
local _aAreaAnt := U_ML_SRArea ()
	
	// grava tabela SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif
	U_ML_SRArea (_aAreaAnt)
return
