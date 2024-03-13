// Programa...: LaudoEm
// Autor......: Robert Koch
// Data.......: 06/03/2017
// Descricao..: Busca o laudo produto/endereco(tanque)/lote em determinada data.
//
// Historico de alteracoes:
// 05/04/2017 - Robert - Valida tambem se o lote do SBF eh o mesmo do ZAF.
// 17/05/2017 - Robert - Laudo passa a referenciar apenas o lote e nao mais o endereco.
// 11/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------
user function LaudoEm (_sProduto, _sLote, _dDataRef)
	local _sRet     := ""
	local _oSQL     := NIL
	local _aAreaAnt := U_ML_SRArea ()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT TOP 1 ZAF_ENSAIO"
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZAF") + " ZAF "
	_oSQL:_sQuery += " WHERE ZAF.D_E_L_E_T_ = ''" 
	_oSQL:_sQuery += " AND ZAF.ZAF_FILIAL = '" + xfilial ("ZAF") + "'"
	_oSQL:_sQuery += " AND ZAF.ZAF_PRODUT = '" + _sProduto + "'"
	_oSQL:_sQuery += " AND ZAF.ZAF_LOTE   = '" + _sLote + "'"
	_oSQL:_sQuery += " AND ZAF.ZAF_DATA  <= '" + dtos (_dDataRef) + "'"
	_oSQL:_sQuery += " AND ZAF.ZAF_VALID >= '" + dtos (_dDataRef) + "'"
	_oSQL:_sQuery +=  " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                    " FROM " + RetSQLName ("ZAF") + " MAIS_RECENTE "
	_oSQL:_sQuery +=                   " WHERE MAIS_RECENTE.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                     " AND MAIS_RECENTE.ZAF_FILIAL = ZAF.ZAF_FILIAL"
	_oSQL:_sQuery +=                     " AND MAIS_RECENTE.ZAF_LOTE   = ZAF.ZAF_LOTE"
	_oSQL:_sQuery +=                     " AND MAIS_RECENTE.ZAF_ENSAIO > ZAF.ZAF_ENSAIO)"
	_oSQL:_sQuery += " ORDER BY ZAF.ZAF_ENSAIO DESC"
	//_oSQL:Log ()
	_sRet = _oSQL:RetQry (1, .f.)
	
	U_ML_SRArea (_aAreaAnt)
return _sRet
