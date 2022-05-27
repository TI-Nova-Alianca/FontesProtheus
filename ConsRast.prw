// Programa:  ConsRast
// Autor:     Robert Koch
// Data:      03/06/2017
// Descricao: Consulta rastreabilidade lote produto.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #consulta
// #Descricao         #Consulta rastreabilidade lote produto.
// #PalavasChave      #rastreabilidade #produto #lote_produto 
// #Modulos           #EST
//
// Historico de alteracoes:
// 26/05/2022 - Robert - Novos parametros na chamada da funcao U_RastLt().
//

// --------------------------------------------------------------------------
User Function ConsRast ()
	private cPerg := "CONSRAST"
	_ValidPerg ()
	
	if Pergunte (cPerg, .T.)
		if empty (mv_par01) .or. empty (mv_par02)
			u_help ("Produto e lote devem ser informados.")
		else
			U_RastLt (cFilAnt, mv_par01, mv_par02, 0, {}, 1, 'A')
		endif
	endif
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},                       ""})
	aadd (_aRegsPerg, {02, "Lote                          ", "C", 10, 0,  "",   ""	 , {},                       ""})
//	aadd (_aRegsPerg, {03, "Apenas componentes com lote   ", "N", 1,  0,  "",   ""	 , {'So com lote', 'Todos'}, ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
