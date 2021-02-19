// Programa:   MT100Grv
// Autor:      Robert Koch
// Data:       18/02/2011
// Descricao:  P.E. para validacao da gravacao ou exclusao da NF de entrada, depois do MT100TOK.
//
// Historico de alteracoes:
// 19/02/2021 - Robert - Inclusao de chamadas da funcao U_PerfMon() para metricas de performance (GLPI 9409).
//

// --------------------------------------------------------------------------
user function mt100grv ()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()

	if _lRet .and. ! paramixb [1] .and. cFormul == "S"  // Inclusao com formulario proprio.
		_lRet = U_VerSqNf ("E", cSerie, cNFiscal, dDataBase, ca100For, cLoja, "", "", cTipo)
	endif
	if _lRet .and. paramixb [1]  // Exclusao
	endif

	if ! _lRet
		lMSErroAuto = .T.  // Em testes que fiz, esta variavel nao foi atualizada automaticamente. Robert, 18/02/2011.
	endif

	if _lRet
		U_PerfMon ('I', 'GravacaoMATA100')  // Deixa variavel pronta para posterior medicao de tempos de execucao
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
