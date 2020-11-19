// Programa...: VA_ATPV
// Autor......: Robert Koch
// Data.......: 27/09/2013
// Descricao..: Altera transportadora do pedido de venda sem precisar abrir o pedido.
//              Criado inicialmente para agilizar o setor de logistica.
//
// Historico de alteracoes:
// 14/05/2014 - ?       - Gravacao de evento quando usado essa opcao.
// 18/11/2016 - Robert  - Envia atualizacao para o sistema Mercanet.
//

// --------------------------------------------------------------------------
user function VA_ATPV ()
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _sTransp   := ""
	//local _lRet      := .T.
	//local _aLiber    := {.F.,,}

	u_logIni ()
	u_log ('pedido:', sc5 -> c5_num, 'transp.atual:', sc5 -> c5_transp)

	if ! empty (sc5 -> c5_nota)
		u_help ("Pedido ja faturado.")
		_lContinua = .F.
	endif
	
	if _lContinua
		_lContinua = U_ZZUVL ('002', __cUserId, .T.)
	endif

	sa4 -> (dbsetorder (1))
	do while _lContinua
		_sTransp = U_Get ("Informe a nova transportadora", "C", 6, "", "SA4", sc5 -> c5_transp, .F., '.t.')
		if _sTransp = NIL  // Usuario cancelou
			_lContinua = .F.
			exit
		endif
		if _lContinua .and. ! empty (_sTransp) .and. ! sa4 -> (dbseek (xfilial ("SA4") + _sTransp, .F.))
			u_help ("Transportadora '" + _sTransp + "' nao cadastrada.")
			loop
		else
			exit
		endif
	enddo

	if _lContinua
		reclock ("SC5", .F.)
		sc5 -> c5_transp = _sTransp 
		msunlock ()      

		U_AtuMerc ('SC5', sc5 -> (recno ()))
		
		_ntexto:= 'Definicao de transportadora sem tela de selecao de frete.'          
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SC5004"
		_oEvento:Texto	   = _ntexto
		_oEvento:Filial	   = xfilial("SC5")
		_oEvento:PedVenda  = sc5 -> c5_num
		_oEvento:Cliente   = sc5 -> c5_cliente
		_oEvento:LojaCli   = sc5 -> c5_lojacli
		_oEvento:Grava ()  
		
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
