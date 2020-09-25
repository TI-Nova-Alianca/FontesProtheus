// Programa:   FA100Pag
// Autor:      Robert Koch
// Data:       05/03/2008
// Cliente:    Alianca
// Descricao:  P.E. apos inclusao manual de movimento bancario a pagar.
//             Criado inicialmente para chamar impressao de cheques.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA100Pag ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if ! empty (se5 -> e5_numCheq) .and. msgyesno ("Deseja imprimir o cheque agora?")
		U_ImpCheq (se5 -> e5_numcheq, se5 -> e5_Benef, se5 -> e5_Valor, se5 -> e5_data, se5 -> e5_Banco, alltrim (sm0 -> m0_cidcob), "1")
	endif

	// grava tabela SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return .t.


