// Programa:   MA261IN
// Autor:      Robert Koch
// Data:       05/02/2015
// Descricao:  P.E. preenche aCols para campos customizados criados pelo P.E. MA261Cpo.
//             Deve ser usado em conjunto com os P.E. MA261Cpo e MA261D3.
//
// Historico de alteracoes:
// 08/05/2015 - Robert - Leitura dos campos D3_VADTINC e D3_VAHRINC.
// 28/06/2015 - Robert - Leitura campo D3_IdZAB.
// 20/10/2016 - Robert - Incluido campo D3_VALAUDO.
// 03/05/2018 - Robert - Desabilitados tratamentos do ZAB (devolucoes de clientes).
// 30/07/2018 - Robert - Incluidos campos D3_VAETIQ e D3_VACHVEX.
//

// --------------------------------------------------------------------------
user function ma261IN ()
	local _nPosMotiv := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VAMOTIV'})
	local _nPosDtInc := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VADTINC'})
	local _nPosHrInc := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VAHRINC'})
	local _nPosRecno := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_REC_WT'})
//	local _nPosLaudo := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VALAUDO'})
	local _nPosEtiq  := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VAETIQ'})
	local _nPosChvEx := ascan (aHeader, {|_aVal| alltrim (upper (_aVal [2])) == 'D3_VACHVEX'})
	local _nLinha    := 0
	//local _aCols     := {}
	local _aAreaAnt  := U_ML_SRArea ()
	
	if _nPosRecno > 0 .and. ! inclui
		for _nLinha = 1 to len (aCols)
			sd3 -> (dbgoto (aCols [_nLinha, _nPosRecno]))
			aCols [_nLinha, _nPosMotiv] = sd3 -> d3_vamotiv
			aCols [_nLinha, _nPosDtInc] = sd3 -> d3_vaDtInc
			aCols [_nLinha, _nPosHrInc] = sd3 -> d3_vaHrInc
//			aCols [_nLinha, _nPosLaudo] = sd3 -> d3_VALaudo
			aCols [_nLinha, _nPosEtiq]  = sd3 -> d3_VAEtiq
			aCols [_nLinha, _nPosChvEx] = sd3 -> d3_VAChvEx
		next
	endif
	U_ML_SRArea (_aAreaAnt)
return
