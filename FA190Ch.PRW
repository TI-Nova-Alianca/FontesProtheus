// Programa:   FA190Ch
// Autor:      Robert Koch
// Data:       05/03/2008
// Cliente:    Alianca
// Descricao:  P.E. apos juntagem de cheques.
//             Criado inicialmente para chamar impressao de cheques.
// 
// Historico de alteracoes:
// 22/03/2019 - Andre  - Grava usuário SE5

// --------------------------------------------------------------------------
user function fa190Ch ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if msgyesno ("Deseja imprimir o cheque agora?","Confirmar")
		U_ImpCheq (se5 -> e5_numcheq, se5 -> e5_Benef, se5 -> e5_Valor, se5 -> e5_data, se5 -> e5_Banco, alltrim (sm0 -> m0_cidcob), "1")
	endif

	// Grava SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return .t.


