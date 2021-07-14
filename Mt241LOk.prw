// Programa...: Mt241Lin
// Autor......: Robert Koch
// Data.......: 09/07/2021
// Descricao..: P.E. 'Linha OK' na tela MATA241 (movimento de estoque mod.II)
//              Criado inicialmente para validar inconsistencias nos estoques (GLPI 10464).

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para validar movimentos internos mod.II
// #PalavasChave      #validacao #movimentos_estoque
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function MT241LOK ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _lRet     := .T.

	// Verifica se tem alguma mensagem de inconsistencia entre tabelas de estoque.
	if _lRet
		_lRet := U_ConsEstq (xfilial ("SD3"), GDFieldGet ("D3_COD"), GDFieldGet ("D3_LOCAL"))
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt )
return _lRet
