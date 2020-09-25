// Programa...: VA_ALTBCO
// Autor......: Catia Cardoso
// Data.......: 04/05/2015
// Descricao..: Altera banco do pedido de venda sem precisar abrir o pedido.
//				Só para usuarios do financeiro
//
// Historico de alteracoes:
// 13/04/2016 - mandar parametro com o numero do pedido - usar nas rotinas MT410BRW e VA_LIBPED
// --------------------------------------------------------------------------------------------,
user function VA_ALTBCO (_wpedido)
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := .T.
	local _aLiber    := {.F.,,}

	// -- posiciona o pedido
	DbSelectArea("SC5")
	DbSetOrder(1)
	if dbseek (xfilial ("SC5") + _wpedido, .F.)
		if ! empty (sc5 -> c5_nota)
			u_help ("Pedido ja faturado.")
			_lContinua = .F.
		endif			
	endif
	
	if _lContinua .and. U_ZZUVL ('036', __cUserId, .T.)
	
		sa6 -> (dbsetorder (1))
		do while _lContinua
			_sBanco = U_Get ("Informe o novo banco: ", "C", 3, "", "SA6", sc5 -> c5_banco, .F., '.t.')
			if _sBanco = NIL  // Usuario cancelou
				_lContinua = .F.
				exit
			endif
			if _lContinua .and. ! empty (_sBanco) .and. ! sa6 -> (dbseek (xfilial ("SA6") + _sBanco, .F.))
				u_help ("Banco '" + _sBanco + "' nao cadastrado.")
				loop
			else
				exit
			endif
		enddo

		if _lContinua
			reclock ("SC5", .F.)
				sc5 -> c5_banco = _sBanco	 
			msunlock ()      
		
			_ntexto:= 'Alterado Banco - Função do Financeiro.'          
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SC5004"
			_oEvento:Texto	   = _ntexto
			_oEvento:Filial	   = xfilial("SC5")
			_oEvento:PedVenda  = sc5 -> c5_num
			_oEvento:Cliente   = sc5 -> c5_cliente
			_oEvento:LojaCli   = sc5 -> c5_lojacli
			_oEvento:Grava ()  
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
