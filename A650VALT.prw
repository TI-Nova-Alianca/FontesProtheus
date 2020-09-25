// Programa...: A650VALT
// Autor......: Catia Cardoso
// Data.......: 23/11/2016
// Descricao..: P.E. A650EmpAlt - que inclui produtos alternativos no aCols de empenhos. 
//			    Em que ponto: Durante a verificação do produto alternativo, permite validar se o produto deve ser utilizado. 
//              A tabela SB1 está posicionada no produto alternativo avaliado. 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
user function A650VALT ()
//	local _aAreaAnt := U_ML_SRArea ()

	// Retorno Falso, pq não queremos que empenhe os produtos alternativos
	_lret = .F.

//	U_ML_SRArea (_aAreaAnt)
return _lret
