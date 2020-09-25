// Programa:   FA100Rec
// Autor:      Robert Koch
// Data:       07/04/2008
// Cliente:    Alianca
// Descricao:  P.E. apos inclusao manual de movimento bancario a receber.
//             Criado inicialmente para chamar impressao de cheques.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function FA100Rec ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if ! empty (se5 -> e5_numCheq) .and. msgyesno ("Deseja imprimir o cheque agora?")
		U_ImpCheq (se5 -> e5_numcheq, se5 -> e5_Benef, se5 -> e5_Valor, se5 -> e5_data, se5 -> e5_Banco, alltrim (sm0 -> m0_cidcob), "1")
	endif
	
	//Grava SE5
	if empty (se5 -> e5_vaUser)
		RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
		MsUnLock()
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return .t.
