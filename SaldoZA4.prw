// Programa:  SaldoZA4
// Autor:     Robert Koch
// Data:      10/10/2019
// Descricao: Retorna saldo da tabela ZA4 (verbas comerciais)
//
// Historico de alteracoes:
// 11/10/2019 - Robert - Acrescentado ISNULL para casos em que o ZA5 nao existia.
//

// --------------------------------------------------------------------------
user function SaldoZA4 (_sVerba)
	local _aAreaAnt  := U_ML_SRArea ()
	local _oSQL      := NIL
	local _nRet      := 0

	u_logIni ()
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ZA4_VLR - ISNULL ((SELECT SUM (ZA5_VLR)"
	_oSQL:_sQuery +=                     " FROM " + RetSQLName ("ZA5") + " ZA5 "
	_oSQL:_sQuery +=                    " WHERE ZA5.D_E_L_E_T_ = ''"
	// eu QUERO todas as filiais para compor o saldo da verba --> _oSQL:_sQuery +=    " AND ZA5.ZA5_FILIAL = '" + xfilial ("ZA5") + "'"
	_oSQL:_sQuery +=                      " AND ZA5.ZA5_NUM    = ZA4.ZA4_NUM), 0)"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZA4") + " ZA4 "
	_oSQL:_sQuery +=  " WHERE ZA4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZA4.ZA4_NUM    = '" + _sVerba + "'"
	_oSQL:Log ()
	_nRet = _oSQL:RetQry (1, .F.)

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _nRet
