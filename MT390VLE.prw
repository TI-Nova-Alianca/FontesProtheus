// Programa:  MT390VLE
// Autor:     Robert Koch
// Data:      15/10/2022
// Descricao: P.E. valida exclusao movto. manut.lotes estoque (MATA390)
//            Criado inicialmente para nao excluir se tiver etiqueta gerada.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_entrada
// #Descricao         #P.E. valida exclusao movto. manut.lotes estoque (MATA390)
// #PalavasChave      #etiqueta #lote
// #TabelasPrincipais #SD5 #ZA1
// #Modulos           #EST

// Historico de alteracoes:
// 10/02/2023 - Robert - Passa a aceitar mais de uma etiqueta para o mesmo lote - GLPI 13134.
//

// --------------------------------------------------------------------------
user function MT390VlE ()
	local _lRet39VlE := .T.
	local _sEtiq     := ''

	_sEtiq = U_ZA1SD5 ('B')
	if ! empty (_sEtiq)
		u_help ("Existem as etiquetas " + _sEtiq + " geradas para este produto/lote. Inutilize-as antes de excluir este lancamento.",, .t.)
		_lRet39VlE = .F.
	endif
return _lRet39VlE
