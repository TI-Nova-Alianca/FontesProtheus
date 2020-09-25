// Programa:   FA050Inc
// Autor:      Robert Koch
// Data:       07/04/2008
// Cliente:    Alianca
// Descricao:  P.E. 'Tudo OK' na inclusao de contas a pagar.
//             Criado inicialmente para chamar impressao de cheques.
// 
// Historico de alteracoes:
// 28/05/2012 - Robert - Validacao do campo A2_VAOBRA.
// 30/05/2012 - Robert - Validacao do campo A2_VACHVEX quando natureza = 'OBRA'.
// 

// --------------------------------------------------------------------------
user function FA050Inc ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _lRet     := .T.

	if _lRet .and. ! empty (cChequeAdt) .and. msgyesno ("Deseja imprimir o cheque agora?")
		U_ImpCheq (cChequeAdt, cBenef, m -> e2_Valor, dDataBase, cBancoAdt, alltrim (sm0 -> m0_cidcob), "1")
	endif

	if _lRet .and. fBuscaCpo ("SA2", 1, xfilial ("SA2") + m->e2_fornece + m->e2_Loja, "A2_VAOBRA") == "S" .and. alltrim (m->e2_naturez) != "OBRA"
		_lRet = msgyesno ("Este fornecedor costuma atender a compras para a obra da planta nova. Confirma natureza diferente de 'OBRA'?")
	endif

	if _lRet .and. alltrim (m->e2_naturez) == "OBRA" .and. empty (m->e2_vachvex)
		_lRet = msgyesno ("Pagamentos com natureza 'OBRA' deveriam ser ligados a um pedido de compras (botao 'Pd.compra'). Confirma assim mesmo?")
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet
