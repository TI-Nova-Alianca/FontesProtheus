// Programa...: MT121BRW
// Autor......: Catia Cardoso
// Data.......: 27/06/2016
// Descricao..: P.E. adiciona botoes no aRotinas - Pedido Compra
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
user function MT121BRW ()
	local _aRotAdic := {}
	
	aadd (_aRotAdic, {"Data Entrega"  , "U_VA_ALTDT()", 0, 2}) 
	aadd (_aRotAdic, {"Condição Pag"  , "U_VA_ALTCP()", 0, 2})
	aadd (_aRotAdic, {"Descricao Item", "U_VA_DITEM()", 0, 2})

	aadd (aRotina, {"Altera Especificos", _aRotAdic, 0, 2})
return

user function VA_ALTDT()
	local _lRet := .T.
	// testa se o pedido esta pendente
	if sc7 -> c7_residuo = 'S' .or. sc7 -> c7_quje >=  sc7 -> c7_quant 
		u_help("Pedido não esta pendente. Não pode ser alterado.")
		_lRet = .F.		
	endif
	// solicita nova data entrega
	if _lRet
		_sOldEntr = sc7 -> c7_datprf
		_sNewEntr = U_Get ("Data Entrega", "D", 8, "@D", "", _sOldEntr, .F., '.T.')
		
		if dtos(_sNewEntr) < dtos(sc7->c7_emissao)
			u_help("Data do lançamento é anterior a data de emissão do pedido.Alteração não permitida.")
			_lRet = .F.
		endif
		if _lRet
			reclock ("SC7", .F.)
				sc7->c7_datprf = _sNewEntr
			msunlock ()      
		endif
	endif
return

user function VA_ALTCP()
	local _lRet := .T.
	// testa se o pedido esta pendente
	if sc7 -> c7_residuo = 'S' .or. sc7 -> c7_quje >=  sc7 -> c7_quant
		u_help("Pedido não esta pendente. Não pode ser alterado.")
		_lRet = .F.		
	endif
	// solicita nova condicao de pagamento
	if _lRet
		_sOldCond = sc7 -> c7_cond
		_sNewCond = U_Get ("Condição Pagamento", "C", 3, "@!", "SE4", _sOldCond, .F., '.T.')
		
		reclock ("SC7", .F.)
			sc7->c7_cond = _sNewCond
		msunlock ()      
	endif
return

user function VA_DITEM()
	local _lRet := .T.
	// testa se o pedido esta pendente
	if sc7 -> c7_residuo = 'S' .or. sc7 -> c7_quje >=  sc7 -> c7_quant
		u_help("Pedido não esta pendente. Não pode ser alterado.")
		_lRet = .F.		
	endif
	// solicita nova descricao do item
	if _lRet
		_sOldDescri = sc7 -> c7_descri
		_sNewDescri = U_Get ("Descricao Item", "C", 110, "@!", "", _sOldDescri, .F., '.T.')
		
		reclock ("SC7", .F.)
			sc7->c7_descri = _sNewDescri
		msunlock ()      
	endif
return
