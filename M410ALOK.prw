// Programa:  M410ALOK
// Autor:     Leandro DWT
// Data:      04/12/2013
// Descricao: P.E. Executado antes de iniciar a alteracao do pedido de venda
//            Este P.E. eh chamado tambem na rotina de copia de pedidos.
//
// Historico de alteracoes:
// 23/03/2014 - Robert - Valida campo C5_VAPEMB.
// 27/05/2014 - Robert - Verifica se estah na rotina de copia de pedidos.
// 

// --------------------------------------------------------------------------------
User Function M410ALOK()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet := .T.

	if ! IsInCallStack ("A410COPIA")
		if _lRet .and. type("_sCodRep") == "C"
			If !Empty(SC5->C5_LIBEROK) .or. !Empty(SC5->C5_NOTA)
				_lRet := .F.
				u_help ("Pedido ja liberado ou com NF gerada. Nao pode ser alterado.")
			endif 
		endif

		// Esta validacao jah existe no padrao, mas apenas avisa e deixa alterar assim mesmo.
		if _lRet
			dai -> (dbsetorder (4))  // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
			if dai -> (dbseek (xfilial ("DAI") + sc5 -> c5_num, .T.))
				u_help ("Pedido foi encontrado na tabela DAI (consta na carga '" + dai -> dai_cod + "'). Não pode ser alterado.")
				_lRet = .F.
			endif
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
