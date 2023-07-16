// Programa:  MNT453PC
// Autor:     Robert Koch
// Data:      03/10/2022
// Descricao: Consulta pedidos de compra relacionados a uma OS
//            Chamado inicialmente pelo botao no programa MNTA4351
//            Criado por solicitacao via GLPI 12645.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta pedidos de compra relacionados a uma OS
// #PalavasChave      #consulta_pedidos_compras #OS #ordem
// #TabelasPrincipais #STJ #SC7
// #Modulos           #MNT

// Historico de alteracoes:
// 14/07/2023 - Robert - Alimentar atributo ClsSQL:MsgF3Vazio
//

// --------------------------------------------------------------------------
user function MNT453PC ()
	local _oSQL      := NIL
	local _aAreaAnt := U_ML_SRArea ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT SC7.C7_NUM AS PEDIDO"
	_oSQL:_sQuery +=     " , SC7.C7_PRODUTO AS PRODUTO"
	_oSQL:_sQuery +=     " , SC7.C7_DESCRI AS DESCRICAO"
	_oSQL:_sQuery +=     " , SC7.C7_QUANT - SC7.C7_QUJE AS SALDO"
	_oSQL:_sQuery +=     " , SC7.C7_UM AS UM"
	_oSQL:_sQuery +=     " , SC7.C7_FORNECE AS FORNECEDOR"
	_oSQL:_sQuery +=     " , SC7.C7_LOJA AS LOJA"
	_oSQL:_sQuery +=     " , SA2.A2_NOME AS NOME_FORNECEDOR"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SC7") + " SC7, "
	_oSQL:_sQuery +=             RetSQLName ("SA2") + " SA2"
	_oSQL:_sQuery += " WHERE SC7.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SC7.C7_FILIAL  = '" + xfilial ("SC7") + "'"
	_oSQL:_sQuery +=   " AND SC7.C7_OP      like '" + STJ->TJ_ORDEM + "%'"
	_oSQL:_sQuery +=   " AND SC7.C7_QUANT   > SC7.C7_QUJE"
	_oSQL:_sQuery +=   " AND SC7.C7_RESIDUO != 'S'"
	_oSQL:_sQuery +=   " AND SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA7") + "'"
	_oSQL:_sQuery +=   " AND SA2.A2_COD     = SC7.C7_FORNECE"
	_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = SC7.C7_LOJA"
	_oSQL:_sQuery += " ORDER BY C7_NUM, C7_PRODUTO"
//	_oSQL:Log ('[' + procname () + ']')
	_oSQL:MsgF3Vazio = "Nao encontrei nenhum pedido de compra relacionado a esta O.S."
	_oSQL:F3Array ("Pedidos de compra relacionados com a OS " + STJ->TJ_ORDEM, .t.)

	U_ML_SRArea (_aAreaAnt)
return
