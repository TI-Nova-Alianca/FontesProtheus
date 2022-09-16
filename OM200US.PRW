// Programa...: OM200US
// Autor......: DWT
// Data.......: 2014
// Descricao..: P.E. na tela de montagem de carga, para inclusao de botoes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #P.E. na tela de montagem de carga, para inclusao de botoes.
// #PalavasChave      #carga #botoes
// #TabelasPrincipais #DAK #DAI
// #Modulos           #OMS

// Historico de alteracoes:
// 25/09/2014 - Robert - Portado para SQL
//                     - Chamada da rotina LtCarga
// 16/12/2014 - Robert - Criados botoes de integracao com FullWMS
// 30/30/2015 - Catia  - Criado botão para impressão de etiquetas de volumes
// 08/07/2015 - Robert - Criado botao para impressao de romaneio.
// 17/11/2015 - Robert - Eliminado botao que chamava U_LibCarg() em duplicidade.
//                     - Criado botao para alteracao de transportadora.
// 16/09/2022 - Robert - Eliminados logs desnecessarios.
//

// ----------------------------------------------------------------
User Function OM200US()
	aadd (aRotina, {'Alterar transp',       'iif(dak->dak_feznf=="1",U_Help("Carga ja faturada"),U_FrtSelPV())', 0,4})
	aadd (aRotina, {"&Envia p/ FullWMS",    "U_CargFull ('E')",         0,4})
	aadd (aRotina, {"&Cancelar no FullWMS", "U_CargFull ('C')",         0,4})
	aadd (aRotina, {"&Liberar p/ fatur",    "U_LibCarg (dak->dak_cod)", 0,4})
	aadd (aRotina, {"&Etiquetas Volumes",   "U_ETQVOL (dak->dak_cod)",  0,4})
	aadd (aRotina, {"&Romaneio carga",      "U_VA_RCARG (.F., dak -> dak_cod, dak -> dak_data, 'S', 2)", 0,4})
Return aRotina
