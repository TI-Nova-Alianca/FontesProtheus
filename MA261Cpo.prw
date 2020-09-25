// Programa:   MA261Cpo
// Autor:      Robert Koch
// Data:       05/02/2015
// Descricao:  P.E. Inclui campos no aHeader da tela de transferencias mod.II
//             Deve ser usado em conjunto com os P.E. MA261IN e MA261D3.
//
// Historico de alteracoes:
// 07/05/2015 - Robert - Criada array para incluir campos.
//                     - Incluidos campos D3_VADTDIG e D3_VAHRDIG.
// 28/06/2015 - Robert - Incluido campo D3_IDZAB.
// 20/10/2016 - Robert - Incluido campo D3_VALAUDO.
// 03/05/2018 - Robert - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 30/07/2018 - Robert - Incluidos campos D3_VAETIQ e D3_VACHVEX.
//

// --------------------------------------------------------------------------
user function MA261Cpo ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aCampos   := {}
	local _nCampo    := 0

	// Lista de campos a apresentar na tela (incluir sempre com tamanho 10 para nao dar erro no seek do sx3).
	aadd (_aCampos, "D3_VAMOTIV")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.
	aadd (_aCampos, "D3_VADTINC")
	aadd (_aCampos, "D3_VAHRINC")
	//aadd (_aCampos, "D3_VALAUDO")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.
	aadd (_aCampos, "D3_VAETIQ ")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.
	aadd (_aCampos, "D3_VACHVEX")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.

	sx3 -> (dbsetorder (2))
	for _nCampo = 1 to len (_aCampos)
		if sx3 -> (dbseek (_aCampos [_nCampo], .F.))
			aadd (aHeader, {TRIM(sx3->X3_TITULO), sx3 -> x3_campo, sx3 -> x3_picture, sx3 -> x3_tamanho, sx3 -> x3_decimal, sx3 -> x3_valid, '', sx3->X3_TIPO, 'SD3', ''})
		endif
	next

	U_ML_SRArea (_aAreaAnt)
return
