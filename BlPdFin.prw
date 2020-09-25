// Programa...: BlPdFin 
// Autor......: Robert Koch	
// Data.......: 02/08/2014
// Descricao..: Confirmacao (figurativa) de credito negado para pedido de venda.
//
// Historico de alteracoes:
//

// -------------------------------------------------------------------------- 
user function BlPdFin ()
//	local _aAreaAnt := U_ML_SRArea ()
//	local _aAmbAnt  := U_SalvaAmb ()
//	local _aDados   := {}
	local _sMsg := ""
	local _oEvento := NIL

	if U_MsgYesNo ("Deseja gerar evento de credito negado para o pedido '" + sc9 -> c9_pedido + "' ?")
		//aadd (_aDados, {"ZN_PEDVEND", sc9 -> c9_pedido})
		//aadd (_aDados, {"ZN_CLIENTE", sc9 -> c9_cliente})
		//aadd (_aDados, {"ZN_LOJACLI", sc9 -> c9_loja})
		//aadd (_aDados, {"ZN_CODEVEN", 'SC9002'})
		//aadd (_aDados, {"ZN_ALIAS",   'SC9'})
		//aadd (_aDados, {"ZN_TEXTO",   'Credito negado'})
		//U_VA_SZNI (_aDados)
		_sMsg = U_Get ('Dados adicionais', "C", tamsx3 ("ZN_TEXTO")[1], "@!", "", U_TamFixo ("Credito negado", tamsx3 ("ZN_TEXTO")[1], ' '), .F., '.T.')
		if _sMsg != NIL
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven  = "SC9002"
			_oEvento:Texto    = _sMsg
			_oEvento:Cliente  = sc9 -> c9_cliente
			_oEvento:LojaCli  = sc9 -> c9_loja
			_oEvento:PedVenda = sc9 -> c9_pedido
			_oEvento:Grava ()
		endif
	endif

//	U_SalvaAmb (_aAmbAnt)
//	U_ML_SRArea (_aAreaAnt)
return
