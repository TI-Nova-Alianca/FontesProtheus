// Programa...: VA_ATOPV
// Autor......: Robert Koch
// Data.......: 22/06/2017
// Descricao..: Altera observacao do pedido de venda sem precisar abrir o pedido (a partir de botao no browse).
//              Criado inicialmente para pedidos importados do Mercanet (a alteracao dos demais campos eh bloqueada) (GLPI 2729).
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Altera observacao do pedido de venda sem precisar abrir o pedido
// #PalavasChave      #obs #pedido_de_venda
// #TabelasPrincipais #SC5 
// #Modulos           #FAT
//
// Historico de alteracoes:
//
// 12/03/2021 - Claudia - Retirado caracteres especiais " e ' da gravação da OBS. GLPI: 9634
//
// ------------------------------------------------------------------------------------------------------

user function VA_ATOPV ()
	local _lContinua := .T.
	local _aAreaAnt  := U_ML_SRArea ()
	local _sObs      := ""
	local _sObsOld   := ""

//	u_logIni ()
	
	if ! empty (sc5 -> c5_nota)
		u_help ("Pedido ja faturado.")
		_lContinua = .F.
	endif
	if _lContinua .and. ! softlock ("SC5")
		u_help ('Pedido em uso por outra estacao. Tente novamente mais tarde.')
		_lContinua = .F.
	endif

	if _lContinua
		_sObs = sc5 -> c5_obs
		_sObsOld = _sObs
		_sObs = u_showmemo (_sObs)

		// retira caracteres " e '
		_sObs = StrTran( _sObs, "'", " " )
		_sObs = StrTran( _sObs, '"', ' ' )

		if alltrim (_sObs) != alltrim (_sObsOld)
			reclock ("SC5", .F.)
			sc5 -> c5_obs = _sObs 
			msunlock ()

			U_AtuMerc ('SC5', sc5 -> (recno ()))
			
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SC5005"
			_oEvento:Texto	   = "Alteracao manual observacoes pedido" 
			_oEvento:Filial	   = xfilial("SC5")
			_oEvento:PedVenda  = sc5 -> c5_num
			_oEvento:Cliente   = sc5 -> c5_cliente
			_oEvento:LojaCli   = sc5 -> c5_lojacli
			_oEvento:Grava ()  
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return
