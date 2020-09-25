// Programa...: MT103TPC
// Autor......: Robert Koch
// Data.......: 05/02/2018
// Descricao..: P.E. que retorna a lista de TES que nao exigem pedido de compra. O seu retorno sobrepoe
//              o conteudo do parametro MV_TESPCNF.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function MT103TPC()
	local _aAreaAnt := U_ML_SRArea ()
	local _sRet     := Paramixb[1]    // Inicializa com o conteudo do parametro MV_TESPCNF
	local _oSQL     := NIL

	// Busca lista de TES que nao exigem pedido de compra.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT F4_CODIGO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SF4") + " SF4 "
	_oSQL:_sQuery += " WHERE SF4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND SF4.F4_FILIAL  = '" + xfilial ("SF4") + "'"
	_oSQL:_sQuery +=   " AND SF4.F4_VAEPCOM = 'N'"
	//_oSQL:Log ()
	_sRet = _oSQL:Qry2Str (1, '/')
	//u_log (_sRet)

	U_ML_SRArea (_aAreaAnt)
Return _sRet
