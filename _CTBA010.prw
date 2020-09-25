// Programa:  _CTBA010
// Autor:     Robert Koch
// Data:      01/10/2010
// Descricao: Filtra usuarios para acesso ao calendario contabil.
//            Criado para ser usado no menu em lugar do CTBA010.
//
// Historico de alteracoes:
// 14/10/2015 - Robert - Passa a validar usuario pela rotina ZZU (grupo 052).
// 17/07/2020 - Robert - Eliminados parametros em desuso na chamada da funcao ZZUVL.
//                     - Inseridas tags para catalogacao de fontes

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #PalavasChave      #validacao_acesso #calendario_contabil
// #TabelasPrincipais #CT2
// #Modulos           #CTB


// --------------------------------------------------------------------------
user function _CTBA010 ()
	if U_ZZUVL ("052", __cUserID, .T.)
		CTBA010 ()
	endif
Return
