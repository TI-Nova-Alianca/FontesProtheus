// Programa...: LJ7053
// Autor......: Catia Cardoso
// Data.......: 13/06/2017
// Descricao..: Ponto de Entrada no Venda Assistida - Criando mais opcoes
//
// Historico de alteracoes:
// 27/03/2018 - Permitir alteracao todas as condicoe de pagamento para 997 ele so permitia a 07


User Function LJ7053()

	Local aArrayaRotinas	:= { {"Alt.Condição"  , "U_VA_LJCOND()", 0, 1, ,.F.} }
	
return	aArrayaRotinas


User function VA_LJCOND()
	local _lRet := .T.
	// solicita nova condicao de pagamento
	if _lRet
		_sDtvenda = SL1 -> L1_EMISSAO
		_sOldCond = SL1 -> L1_CONDPG
		
		
		if _sDtvenda < (date() -10) // permite alterar cupons emitidos ate 2 dias antes
			u_help("Data da Venda não permite mais a alteração da condição de pagamento.")
			return
		endif
		
		
		_sNewCond = U_Get ("Condição Pagamento", "C", 3, "@!", "SE4", _sOldCond, .F., '.T.')
		
		reclock ("SL1", .F.)
			SL1 -> L1_CONDPG = _sNewCond
		msunlock ()      
	endif
return
