// Programa.: MA261Cpo
// Autor....: Robert Koch
// Data.....: 05/02/2015
// Descricao: P.E. Inclui campos no aHeader da tela de transferencias mod.II
//            Deve ser usado em conjunto com os P.E. MA261IN e MA261D3.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Inclui campos no aHeader da tela de transferencias mod.II
// #PalavasChave      #ponto_de_entrada #transferencias_mod_II
// #TabelasPrincipais #SD3 
// #Modulos           #EST
//
// Historico de alteracoes:
// 07/05/2015 - Robert  - Criada array para incluir campos.
//                      - Incluidos campos D3_VADTDIG e D3_VAHRDIG.
// 28/06/2015 - Robert  - Incluido campo D3_IDZAB.
// 20/10/2016 - Robert  - Incluido campo D3_VALAUDO.
// 03/05/2018 - Robert  - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 30/07/2018 - Robert  - Incluidos campos D3_VAETIQ e D3_VACHVEX.
// 13/05/2021 - Claudia - Ajuste da tabela SX3 devido a R27. GLPI: 8825
//
// --------------------------------------------------------------------------
user function MA261Cpo ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _aCampos   := {}
	local _nCampo    := 0
	local _x         := 0

	// Lista de campos a apresentar na tela (incluir sempre com tamanho 10 para nao dar erro no seek do sx3).
	aadd (_aCampos, "D3_VAMOTIV")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.
	aadd (_aCampos, "D3_VADTINC")
	aadd (_aCampos, "D3_VAHRINC")
	aadd (_aCampos, "D3_VAETIQ ")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.
	aadd (_aCampos, "D3_VACHVEX")  // Deixar aqui para ser visivel por rotinas automaticas e outros pontos de entrada.

	for _nCampo = 1 to len (_aCampos)
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += "     X3_TITULO"	// 01
		_oSQL:_sQuery += "    ,X3_CAMPO"	// 02
		_oSQL:_sQuery += "    ,X3_PICTURE"	// 03
		_oSQL:_sQuery += "    ,X3_TAMANHO"	// 04
		_oSQL:_sQuery += "    ,X3_DECIMAL"	// 05
		_oSQL:_sQuery += "    ,X3_VALID"	// 06
		_oSQL:_sQuery += "    ,X3_TIPO"		// 07
		_oSQL:_sQuery += " FROM SX3010"
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND X3_CAMPO     = '" + _aCampos [_nCampo] + "'"
		_aSX3  = aclone (_oSQL:Qry2Array ())

		for _x := 1 to len(_aSX3)
			aadd (aHeader, {TRIM(_aSX3[_x,1]), _aSX3[_x,2], _aSX3[_x,3], _aSX3[_x,4], _aSX3[_x,5], _aSX3[_x,6], '', _aSX3[_x,7], 'SD3', ''})
		next
	next
	// sx3 -> (dbsetorder (2))
	// for _nCampo = 1 to len (_aCampos)
	// 	if sx3 -> (dbseek (_aCampos [_nCampo], .F.))
	// 		aadd (aHeader, {TRIM(sx3->X3_TITULO), sx3 -> x3_campo, sx3 -> x3_picture, sx3 -> x3_tamanho, sx3 -> x3_decimal, sx3 -> x3_valid, '', sx3->X3_TIPO, 'SD3', ''})
	// 	endif
	// next

	U_ML_SRArea (_aAreaAnt)
return
