// Programa:  _Matr730
// Autor:     Robert Koch
// Data:      03/08/2010
// Cliente:   Alianca
// Descricao: Chama relatorio e refaz filtro do arquivo SC5, que o relatorio limpa.
//            O representante deve ter a formula 'sc5->c5_num' cadastrada como
//            formula nas perguntas MTR730 (configuracoes do usuario no SigaCFG)
//
// Historico de alteracoes:
// 28/12/2010 - Robert - Se o usuario nao fosse representante, saia do programa sem fazer nada.
//

// --------------------------------------------------------------------------
USER FUNCTION _MATR730 ()
	if type ("_sCodRep") == "C" .and. ! empty (_sCodRep)
		MATR730 ()
		dbselectarea ("SC5")
		SET FILTER TO C5_VEND1 == _sCodRep
	else
		MATR730 ()
	endif
Return
