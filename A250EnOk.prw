// Programa:   A250EnOk
// Autor:      Robert Koch
// Data:       15/04/2017
// Descricao:  P.E. que verifica se pode ser feito o encerramento da OP.
//
// Historico de alteracoes:
// 28/04/2017 - Robert - Passa a verificar etiquetas pendentes usando a classe ClsVerif.
// 15/05/2017 - Robert - Passa a verificar etiquetas pendentes somente para filial 01 e a partir de 01/05/2017.
//

// --------------------------------------------------------------------------
user function A250EnOk ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.

	u_logIni ()

	// Verifica consistencia com etiquetas, quando usadas.
	if _lRet
		_lRet = _VerEtiq ()
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return _lRet



// --------------------------------------------------------------------------
// Consiste dados da etiqueta, quando informada.
static function _VerEtiq ()
	local _lRet     := .T.
	//local _oSQL     := NIL
	local _oVerif   := NIL
	local _sMsgSup  := ""
	local _oEtiq    := NIL
	local _nEtiq    := 0

	if cFilAnt == '01' .and. sd3 -> d3_emissao >= stod ('20170501')  // Antes dessa data temos muitos problemas.
		sb1 -> (dbsetorder (1))
		if sb1 -> (dbseek (xfilial ("SB1") + sd3 -> d3_cod, .F.)) .and. sb1 -> b1_vafullw == 'S'
			_oVerif := ClsVerif():New (24)
			_oVerif:SetParam ('01', SD3->D3_OP)
			_oVerif:SetParam ('02', SD3->D3_OP)
			_oVerif:SetParam ('03', SD3->D3_COD)
			_oVerif:SetParam ('04', SD3->D3_COD)
			_oVerif:Executa ()
			u_log (_oVerif:Result)
			_oEtiq := ClsAUtil ():New (_oVerif:Result)
			u_log (_oEtiq:_aArray)
			
			// Ignora etiquetas cuja transferencia tenha sido canelada manualmente.
			for _nEtiq = len (_oEtiq:_aArray) to 1 step -1
				if 'CANCELADO' $ upper (_oEtiq:_aArray [_nEtiq, 11])
					_oEtiq:Del (_nEtiq)
				endif
			next
			u_log (_oEtiq:_aArray)
			if len (_oEtiq:_aArray) > 1  // Primeira linha contem os cabecalhos de colunas.
				_lRet = .F.
				_sMsgSup = "As seguintes etiquetas geraram apontamentos para esta OP, mas ainda nao foram guardadas (transferidas do almoxarifado " + sd3 -> d3_local + "):"
				U_F3Array (_oEtiq:_aArray, "Etiquetas nao guardadas", , , , _sMsgSup, '', .T., 'C')
			endif
		endif
	endif
return _lRet
