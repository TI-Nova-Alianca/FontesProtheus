// Programa...: _MTA450
// Autor......: Robert Koch
// Data.......: 01/12/2015
// Descricao..: Valida usuario e chama tela padrao MATA450 (an.credito ped.venda)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Tela #Atualizacao
// #Descricao         #Valida usuario e chama tela padrao MATA450 (an.credito ped.venda)
// #PalavasChave      #validacao_usuario #analise_de_credito #pedido_de_venda 
// #TabelasPrincipais #
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 03/05/2023 - Claudia - Alterado o grupo de 055 para 149. GLPI: 13519
//
// -----------------------------------------------------------------------------------------
user function _MTA450()
 
	if u_zzuvl('149', __cUserId, .T.)
		MATA450()
	endif

return
