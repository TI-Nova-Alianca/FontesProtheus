// Programa...: _MATA521
// Autor......: Robert Koch - TCX021
// Data.......: 11/01/2011
// Descricao..: Exclusao de NF de saida.
//
// Historico de alteracoes:
// 28/10/2014 - Robert - Chama transmissao dos cancelamentos para a SEFAZ no final da rotina.
// 12/02/2015 - Robert - Matodo ConsChv() trocado por ConsAutori() na consulta de autorizacao do SPED.
// 05/11/2015 - Robert - Passa a validar acesso do usuario pela rotina ZZU.
// ?          - Robert - Nao transmite mais os cancelamentos para a SEFAZ, pois agora temos o job de cancelamentos.
// 17/07/2020 - Robert - Eliminados parametros em desuso na chamada da funcao ZZUVL.
//                     - Inseridas tags para catalogacao de fontes

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #PalavasChave      #validacao_acesso #exclusao_nf_saida #cancelamento_nf_saida
// #TabelasPrincipais #SF2
// #Modulos           #FAT #FIS


// --------------------------------------------------------------------------
User Function _MATA521 ()

	// Verifica se o usuario tem liberacao para uso desta rotina.
//	if ! U_ZZUVL ('012', __cUserID, .T., cEmpAnt, cFilAnt, '13')  // O grupo serve tanto para liberacao como para notificacao.
	if ! U_ZZUVL ('012', __cUserID, .T.)
		return
	endif

	MATA521A ()

return
