// Programa:  GatTab
// Autor:     Robert Koch
// Data:      18/08/2008
// Cliente:   Alianca
// Descricao: Gatilho para buscar campo tabela de precos nos pedidos e pre-pedidos.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function GatTab (_sCliente, _sLoja)
	local _sRet     := ""
	local _sQuery   := ""
	local _aAreaAnt := U_ML_SRArea ()

	// Procura tabela de precos do cliente.
	_sQuery := ""
	_sQuery += " select top 1 A1_TABELA "
	_sQuery += "   from " + RetSQLName ("SA1") + " SA1, "
	_sQuery +=              RetSQLName ("DA0") + " DA0  "
	_sQuery += "  where SA1.D_E_L_E_T_ =  ''"
	_sQuery += "    AND DA0.D_E_L_E_T_ =  ''"
	_sQuery += "    and A1_FILIAL      =  '" + xfilial ("SA1") + "'"
	_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0") + "'"
	_sQuery += "    and DA0_ATIVO      =  '1'"
	_sQuery += "    and DA0_DATDE     <=  '" + dtos (ddatabase) + "'"
	_sQuery += "    and DA0_DATATE    >=  '" + dtos (ddatabase) + "'"
	_sQuery += "    and DA0_CODTAB     =  A1_TABELA"
	_sQuery += "    and A1_COD         =  '"  + _sCliente + "'"
	_sQuery += "    and A1_LOJA        =  '"  + _sLoja + "'"
//	u_showmemo (_squery)
	_sRet := U_RetSQL (_sQuery)
	U_ML_SRArea (_aAreaAnt)
return _sRet
