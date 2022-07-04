// Programa...: MTA410T
// Autor......: ?
// Data.......: ?
// Descricao..: P.E. apos a gravacao do pedido de vendas.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada apos a gravacao do pedido de vendas
// #PalavasChave      #pedido_de_venda
// #TabelasPrincipais #SC5 SC6
// #Modulos           #FAT
//
// Historico de alteracoes:
// 17/04/2008 - Robert  - Chamada rotina U_FrtGrZZ1.
// 14/06/2013 - Leandro - Grava reservas automaticamente, quando solicitado
// 21/06/2013 - Leandro - Quando altera pedido, excluir reservas e faz todas novamente - mensagem para usuário
// 18/10/2013 - Robert  - Grava evento apos inclusao/alteracao do pedido.
// 18/11/2016 - Robert  - Envia atualizacao para o sistema Mercanet.
// 28/04/2017 - Robert  - Passa tambem o lote do produto e o pedido para a funcao VerEstq().
// 21/07/2020 - Robert  - Inseridas tags para catalogacao de fontes
// 24/10/2020 - Robert  - Desabilitada gravacao SC0 (reservas) cfe. campo C5_VARESER (nao usamos mais desde 2014).
// 28/06/2022 - Claudia - Incluido ajuste de campo de pedido de venda da bonificação. GLPI: 12274
//
// -----------------------------------------------------------------------------------------------------------------
User Function MTA410T()
	local _aAreaAnt := U_ML_SRArea ()
	
	_VerTransp()
	_EvtAlter()
	_VerBonif()

	U_AtuMerc ('SC5', sc5 -> (recno ()))
	
	U_ML_SRArea (_aAreaAnt)
return
//
// --------------------------------------------------------------------------
// Verifica se deixa ou nao a transportadora selecionada.
static function _VerTransp ()
	local _oSQL := NIL
	local _lDeixaTr := .F.

	// Verifica se deixa ou nao a transportadora selecionada. Isso por que apenas o pessoal de logistica
	// pode selecionar a transportadora, exceto casos de filial, nao mov.estoque, FOB, etc.
	_lDeixaTr = .F.
	//
	// Frete FOB ou de filiais, pode deixar.
	if sc5 -> c5_tpfrete == "F" .or. cEmpAnt + cFilAnt != '0101'
		_lDeixaTr = .T.
	else
		// Se o usuario tem liberacao, pode deixar.
		if U_ZZUVL ('002', __cUserId, .F.)
			_lDeixaTr = .T.
		else
			// Se nenhum TES do pedido vai movimentar estoque, pode deixar.
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SC6") + " SC6, "
			_oSQL:_sQuery +=              RetSQLName ("SF4") + " SF4 "
			_oSQL:_sQuery +=  " WHERE SC6.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SC6.C6_FILIAL  = '" + xfilial ("SC6") + "'"
			_oSQL:_sQuery +=    " AND SC6.C6_NUM     = '" + sc6 -> c6_num + "'"
			_oSQL:_sQuery +=    " AND SF4.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
			_oSQL:_sQuery +=    " AND SF4.F4_CODIGO  = SC6.C6_TES"
			_oSQL:_sQuery +=   " AND (SF4.F4_ESTOQUE = 'S' OR SF4.F4_VAFDEP = 'S')"
			if _oSQL:RetQry (1, .f.) == 0  // Nao vai movimentar estoque
				_lDeixaTr = .T.
			endif
		endif
	endif

	if _lDeixaTr
		U_FrtPv ("I")  // Grava previsao de frete na tabela ZZ1
	else
		reclock("SC5", .F.)
		Replace SC5->C5_TRANSP With ''
		msunlock()
	endif
return
//
// -------------------------------------------------------------------------
// Limpa campo de pedido de venda da bonificação quando o tipo não inserido 
Static Function _VerBonif()
	if SC5->C5_VABTPO != '1'
		reclock("SC5", .F.)
		Replace SC5->C5_VABREF With ''
		msunlock()
	endif
return
//
// --------------------------------------------------------------------------
// Grava evento quando houver alteracao do pedido.
static function _EvtAlter ()
	local _oEvento := NIL
	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SC5005"
	_oEvento:Texto     = iif (altera, "Alteracao ", iif (inclui, "Inclusao ", " Manutencao ")) + " manual do pedido"
	_oEvento:Cliente   = sc5 -> c5_cliente
	_oEvento:LojaCli   = sc5 -> c5_lojacli
	_oEvento:PedVenda  = sc5 -> c5_num
	_oEvento:Grava ()
return
