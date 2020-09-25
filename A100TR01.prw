// Programa:   A100TR01
// Autor:      Andr� Alves
// Data:       05/11/2018
// Cliente:    Alianca
// Descricao:  P.E. gravar SE5 na transferencia do movimento banc�rio.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function A100TR01 ()
local _aAreaAnt := U_ML_SRArea ()

	// grava tabela SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
		U_ML_SRArea (_aAreaAnt)
	endif
	
return
