// Programa.:  FA100Rec
// Autor....:  Robert Koch
// Data.....:  07/04/2008
// Cliente..:  Alianca
// Descricao:  Utilizado apos a gravacao dos dados e da contabilizacao de contas 
//             a receber na movimentacao banc�ria
// 
// Historico de alteracoes:
// 20/03/2023 - Claudia - Grava��o do usu�rio logado ap�s a grava��o de registro. GLPI: 12971
//
// ---------------------------------------------------------------------------------------------------------

User Function FA100REC()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if !empty(se5 -> e5_numCheq) .and. msgyesno("Deseja imprimir o cheque agora?","Confirmar")
		U_ImpCheq(se5 -> e5_numcheq, se5 -> e5_Benef, se5 -> e5_Valor, se5 -> e5_data, se5 -> e5_Banco, alltrim (sm0 -> m0_cidcob), "1")
	endif
	
	//Grava SE5
	//if empty (se5 -> e5_vaUser)
	RecLock("SE5",.F.)
		SE5->E5_VAUSER   := alltrim(cUserName)
	MsUnLock()
	//endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return .t.
