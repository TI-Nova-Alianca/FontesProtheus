// Programa:  NFDAdicC
// Autor:     Robert Koch
// Data:      18/09/2013
// Descricao: Consulta dados adicionais da NF
//
// Historico de alteracoes:
// 02/10/2013 - Leandro DWT - Alteração para pegar as informações das tabelas SF2 e SF1, e não mais da ZZ4
// 05/01/2016 - Robert      - Renomeada de Cons_ZZ4 para NFDAdicC.
//

// --------------------------------------------------------------------------
user function NFDAdicC (_sEntSai, _sDoc, _sSerie, _sFornece, _sLoja)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sMsgInf   := {} 
	local _Enter 	 := chr (13) + chr (10)
	local _msgfis 	 := ''
	local _msgctr	 := ''
    
	if _sEntSai == 'S'
		dbselectarea("SF2")
		dbsetorder(1)
		dbseek(xFilial("SF2") + _sDoc + _sSerie)
		if found()
			_msgctr := MSMM (SF2->F2_VACMEMC,,,,3)
			_msgfis := MSMM (SF2->F2_VACMEMF,,,,3)
		endif
	elseif _sEntSai == 'E'
		dbselectarea("SF1")
		dbsetorder(1)
		dbseek(xFilial("SF1") + _sDoc + _sSerie + _sFornece + _sLoja)
		if found()
			_msgctr := MSMM (SF1->F1_VACMEMC,,,,3)
			_msgfis := MSMM (SF1->F1_VACMEMF,,,,3)
		endif
	endif    
	
	_sMsgInf := "" + _Enter
	_sMsgInf += "Mensagem de interesse do fisco" + _Enter
	_sMsgInf += "------------------------------" + _Enter
	_sMsgInf += alltrim (_msgfis) + _Enter + _Enter + _Enter + _Enter
	_sMsgInf += "Mensagem de interesse do contribuinte" + _Enter
	_sMsgInf += "-------------------------------------" + _Enter
	_sMsgInf += alltrim (_msgctr) + _Enter + _Enter + _Enter + _Enter
	_sMsgInf += "Mensagem para mercado externo" + _Enter
	_sMsgInf += "-----------------------------" + _Enter

	u_help ("NF " + _sDoc, _sMsgInf)
	U_ML_SRArea (_aAreaAnt)
return
