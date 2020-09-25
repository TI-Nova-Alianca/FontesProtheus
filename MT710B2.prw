// Programa...: MT710B2
// Autor......: Robert Koch
// Data.......: 14/05/2015
// Descricao..: P.E. para filtrar a tabela SB2 no calculo do MRP (MATA710).
//
// Historico de alteracoes:
//
// 07/07/2017 - desconsiderar tambem o almox 93 - criado para devoluções que nao retornam fisicamente pra empresa
// --------------------------------------------------------------------------
user function MT710B2 ()
	local _sRet := ""
	_sRet = 'B2_FILIAL == "'+xFilial("SB2")+'".And.B2_LOCAL >= "'+cAlmoxd+'" .and. B2_LOCAL <= "'+cAlmoxa+'" .and. ! B2_LOCAL $ "66/90/91/93"'
return _sRet
