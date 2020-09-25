// Programa...: VA_QtCx
// Autor......: Robert Koch - TCX021
// Data.......: 14/03/2008
// Cliente....: Alianca
// Descricao..: Calcula a quantidade do produto em caixas. Util para converter
//              venda em garrafas, pois eh muito comum a empresa trabalhar com
//              as quantidades em caixas a nivel gerencial.
//
// Historico de alteracoes:
// 19/03/2008 - Robert - Retorna o produto pai na terceira posicao do array.
//                       Se nao for 'avulso', retorna o proprio codigo como pai.
//

// --------------------------------------------------------------------------
User Function VA_QtCx (_sProduto, _nQtOri)
	local _aAreaAnt := U_ML_SRArea ()
	local _nRet     := _nQtOri
	local _sErro    := ""
	local _nQtdEmb  := 0
	local _sProdPai := ""

	// Codigos 'avulsos' devem ser divididos pela quantidade que teria em uma caixa.
	if left (_sProduto, 1) == "8"
		sb1 -> (dbsetorder (1))
		if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			if empty (sb1 -> b1_codpai)
				_sErro = "campo '" + alltrim (RetTitle ("B1_CODPAI")) + "' nao informado."
			else
				_sProdPai = sb1 -> b1_codPai
				_nQtdEmb = 0
				if sb1 -> (dbseek (xfilial ("SB1") + sb1 -> b1_codpai, .F.))
					_nQtdEmb = sb1 -> b1_qtdemb
				endif
				if _nQtdEmb <= 0
					_sErro = "campo '" + alltrim (RetTitle ("B1_QTDEMB")) + "' nao informado ou negativo no cadastro do pai " + _sProdPai
				else
					_nRet /= _nQtdEmb
				endif
			endif
		endif
	else
		_sProdPai = _sProduto
	endif

	U_ML_SRArea (_aAreaAnt)
return {_nRet, _sErro, _sProdPai}
