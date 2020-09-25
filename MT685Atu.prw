// Programa:   MT685Atu
// Autor:      Robert Koch
// Data:       18/02/2015
// Descricao:  P.E. apos gravacao de apontamento de perdas em OP.
//
// Historico de alteracoes:
// 18/11/2016 - Robert  - Grava tambem os campos D3_VADTINC e D3_VAHRINC.
// 11/04/2017 - Robert  - Campos D3_VADTINC e D3_VAHRINC passam a ser alimentados via default do SQL.
// 23/01/2020 - Claudia - Incluida alteração de D3_CF para produtos com agregar custo igual a não
//
// --------------------------------------------------------------------------
user function MT685Atu ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _oSQL1    := NIL
	local _aItens   := {} 
	local _x 		:= 0

	// Atualiza campo identificador de perdas no SD3 para uso em relatorios.
	// Nao faz via AdvPl por que teria apenas o D3_NUMSEQ da ultima linha do aCols.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSqlName ("SD3")
	_oSQL:_sQuery +=  " SET D3_VAPEROP = 'S'" //,"
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND D3_FILIAL   = '" + xFilial ("SD3") + "'"
	_oSQL:_sQuery +=    " AND D3_OP       = '" + sbc -> bc_op + "'"
	_oSQL:_sQuery +=    " AND D3_CF      LIKE 'RE%'"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT * "
	_oSQL:_sQuery +=                  " FROM " + RetSqlName ("SBC") + " SBC "
	_oSQL:_sQuery +=                 " WHERE SBC.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                   " AND SBC.BC_FILIAL   = D3_FILIAL"
	_oSQL:_sQuery +=                   " AND SBC.BC_OP       = D3_OP"
	_oSQL:_sQuery +=                   " AND SBC.BC_PRODUTO  = D3_COD"
	_oSQL:_sQuery +=                   " AND SBC.BC_LOCORIG  = D3_LOCAL"
	_oSQL:_sQuery +=                   " AND SBC.BC_SEQSD3   = D3_NUMSEQ)"
	_oSQL:Exec ()
	
	// ----------- Atualiza produtos  
	_oSQL1 := ClsSQL ():New ()
	_oSQL1:_sQuery := " UPDATE " + RetSqlName ("SD3")
	_oSQL1:_sQuery += " SET D3_CF = 'RE9' " 
	_oSQL1:_sQuery += "	FROM " + RetSqlName ("SD3") + " SD3 "     
	_oSQL1:_sQuery += " INNER JOIN " + RetSqlName ("SB1") + " SB1 "   
	_oSQL1:_sQuery += " 	ON (SB1.D_E_L_E_T_ = '' "
	_oSQL1:_sQuery += "		AND SB1.B1_COD = SD3.D3_COD "
	_oSQL1:_sQuery += "		AND SB1.B1_AGREGCU = '1')"
	_oSQL1:_sQuery += " WHERE SD3.D_E_L_E_T_ = '' "
	_oSQL1:_sQuery += " AND SD3.D3_OP = '" + sbc -> bc_op + "'"
	_oSQL1:_sQuery += " AND SD3.D3_ESTORNO = ''"
	_oSQL1:Exec ()

	U_ML_SRArea (_aAreaAnt)
return
