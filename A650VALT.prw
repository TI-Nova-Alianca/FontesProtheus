// Programa...: A650VALT
// Autor......: Catia Cardoso
// Data.......: 23/11/2016
// Descricao..: P.E. A650EmpAlt - que inclui produtos alternativos no aCols de empenhos. 
//			    Em que ponto: Durante a verifica��o do produto alternativo, permite validar se o produto deve ser utilizado. 
//              A tabela SB1 est� posicionada no produto alternativo avaliado. 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
user function A650VALT ()
//	local _aAreaAnt := U_ML_SRArea ()

	// Retorno Falso, pq n�o queremos que empenhe os produtos alternativos
	_lret = .F.

//	U_ML_SRArea (_aAreaAnt)
return _lret
