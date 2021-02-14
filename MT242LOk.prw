// Programa:  MT242LOk
// Autor:     Robert Koch
// Data:      12/02/2021
// Descricao: Ponto de entrada 'linha ok' na tela de desmontagens de produtos

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada 'linha ok' na tela de desmontagens de produtos
// #PalavasChave      #desmontagem
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MT242LOk ()
	local _sMsg     := ''
	local _sRevisao := ''
	local _aEstrut  := {}
	local _lRet     := .T.
	local _lFilhoOk := .F.
	local _lCompOk  := .F.
	local _aAreaAnt := U_ML_SRArea ()

	if ! GDDeleted ()
		If ! fbuscacpo("SB1",1,xfilial("SB1")+GDFieldGet ("D3_COD"),"B1_CODPAI") == CProduto
			_lFilhoOK = .F.
		else
			_lFilhoOK = .T.
		endif
		if ! _lFilhoOK  // Se eh filho, nem preciso olhar a estrutura
			_sRevisao = fbuscacpo("SB1",1,xfilial("SB1") + CProduto, "B1_REVATU")
			U_Log2 ('debug', _srevisao)
			_aEstrut := aclone (U_ML_Comp2 (CProduto, 1, ".T.", dDataBase, .F., .F., .F., .F., .T., '', .F., '.t.', .T., .F., _sRevisao))
			u_log2 ('debug', _aEstrut)
			If ascan (_aEstrut, {|_aVal| _aVal [2] == GDFieldGet ("D3_COD")}) == 0
				_lCompOK = .F.
			else
				_lCompOK = .T.
			endif
		endif
	endif
	if ! _lFilhoOK .and. ! _lCompOK
		_sMsg = "O item '" + GDFieldGet ("D3_COD") + "' não é componente do produto origem, nem consta relacionamento do tipo 'caixa x unidade'."
		if U_ZZUVL ('098', __cUserId, .F.)
			_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _lRet
