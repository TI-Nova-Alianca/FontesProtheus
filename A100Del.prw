// Programa...: A100Del
// Autor......: Robert Koch
// Data.......: 11/12/2014
// Descricao..: P.E. para validar a exclusao de NF de entrada.
//              Criado inicialmente para integracao com Fullsoft.
//
// Historico de alteracoes:
// 11/05/2015 - Robert - Tratamento para devolucoes/cancelamentos (arquivo ZAB).
// 10/03/2017 - Júlio  - Incluída validação para impedir a exclusão de notas com etiquetas impressas.
// 03/05/2018 - Robert - Desabilitados tratamentos do ZAB (devolucoes de clientes).
//

// ----------------------------------------------------------------
user function A100Del ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
//	u_logIni ()

	if _lRet
		_lRet = _VerFull ()
	endif

	if _lRet
		_lRet = _VerEtiq ()
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return _lRet



// --------------------------------------------------------------------------
static function _VerFull ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _sMsg     := ""

	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select count (*)"
		_oSQL:_sQuery +=   " from tb_wms_entrada"
		_oSQL:_sQuery +=  " where nrodoc = '" + sf1 -> f1_doc + "'"
		_oSQL:_sQuery +=    " and serie  = '" + sf1 -> f1_serie + "'"
		_oSQL:_sQuery +=    " and codfor = '" + sf1 -> f1_fornece + sf1 -> f1_loja + "'"
		_oSQL:_sQuery +=    " and status != '9'"
		u_log (_oSQL:_sQuery)
		if _oSQL:RetQry () > 0
			_sMsg := "Esta entrada de estoque ja foi vista pelo Fullsoft. Para estornar esta nota exclua do Fullsoft, antes, a tarefa de recebimento." + chr (13) + chr (10) + chr (13) + chr (10)
			_sMsg += "Dados adicionais:" + chr (13) + chr (10)
			_sMsg += "Documento: " + sf1 -> f1_doc + chr (13) + chr (10)
			_sMsg += "Cod.fornecedor: " + sf1 -> f1_fornece + sf1 -> f1_loja
			if u_zzuvl ('029', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg)
				_lRet = .F.
			endif
		endif
	endif
return _lRet




// --------------------------------------------------------------------------
// Verifica a existencia de etiquetas geradas, impressas e coladas.
// Somente deverá permitir a exclusão se a nota não possuir etiquetas ou se todas as etiquetas 
// emitidas a partir da nota estiverem inutilizdas.
static function _VerEtiq ()
	local _lRet     := .T.
	local _oSQL     := NIL
	local _sMsg     := ""

	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select count (*)"
		_oSQL:_sQuery += " from ZA1010"
		_oSQL:_sQuery += " where ZA1_FILIAL = '" + xfilial ("SF1") + "'"
		_oSQL:_sQuery += " and ZA1_DOCE = '" + sf1 -> f1_doc + "'"
		_oSQL:_sQuery += " and ZA1_SERIEE  = '" + sf1 -> f1_serie + "'"
		_oSQL:_sQuery += " and ZA1_FORNEC = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery += " and ZA1_LOJAF = '" + sf1 -> f1_loja + "'"
		_oSQL:_sQuery += " and D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " and ZA1_APONT != 'I'"
		_oSQL:_sQuery += " and ZA1_IMPRES = 'S'
		u_log (_oSQL:_sQuery)
		if _oSQL:RetQry () > 0
			_sMsg := "Existem etiquetas emitidas e utilizadas a partir da nota fiscal." + chr (13) + chr (10) 
			_sMsg += "As etiquetas devem ser inutilizadas para que a nota possa ser excluida." + chr (13) + chr (10) + chr (13) + chr (10)
			_sMsg += "Dados adicionais:" + chr (13) + chr (10)
			_sMsg += "Documento: " + sf1 -> f1_doc + chr (13) + chr (10)
			_sMsg += "Cod.fornecedor: " + sf1 -> f1_fornece
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif
return _lRet

