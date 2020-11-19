// Programa...: MTA410V
// Autor......: Robert Koch
// Data.......: 02/10/2013
// Descricao..: Ponto de entrada após a visualização do pedido de venda
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MTA410V()
	local _oEvento := NIL

	if type ("_oClsFrtPV") == "O" // verifica se o frete foi alterado...senão, não faz nada
		if U_ZZUVL ('002', __cUserId, .F.)
			if MsgYesNo("Confirmar gravação das informações do frete ?","Confirmar")
	
				// O pedido assume a transportadora selecionada / informada.
				reclock("SC5", .F.)
				Replace SC5->C5_TRANSP With _oClsFrtPV:_C5TRANSP
				if _oClsFrtPV:_ZZ1VLCALC > 0
					sc5->c5_mvfre = _oClsFrtPV:_ZZ1VLCALC
				elseif _oClsFrtPV:_ZZ1VLNEGO > 0
					sc5->c5_mvfre = _oClsFrtPV:_ZZ1VLNEGO
				endif 
	            sc5->c5_vabloq = m->c5_vabloq
				msunlock ()  
	
				// Grava dados de fretes, com as informações do objeto _oClsFrtPV
				U_FrtPV ("I")
	
				// grava evento e manda e-mail para Jeferson
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   := "SC5004"
				_oEvento:Texto     := "SELECAO DE TRANSPORTADORA NO PEDIDO" + chr (13) + chr (10) + "Transp. selecionada:" + sc5 -> c5_transp
				_oEvento:PedVenda  := SC5->C5_NUM
				_oEvento:Cliente   := SC5->C5_CLIENTE
				_oEvento:LojaCli   := SC5->C5_LOJACLI
				_oEvento:Grava ()
	
			endif
		endif
		_oClsFrtPV := NIL
	endif
//	u_logFim ()
Return
