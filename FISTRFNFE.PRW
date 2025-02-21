// Programa.:  FISTRFNFE
// Autor....:  Catia Cardoso
// Data.....:  25/02/20196
// Descricao:  P.E. no SPEDNFE para criar botoes 
//             o browse do SPEDNFE esta posicionado no SF2
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. no SPEDNFE para criar botoes 
// #PalavasChave      #danfe #xml 
// #TabelasPrincipais #SF1 #SF2 #SD1 #SD2
// #Modulos           #FAT
//
// Historico de alteracoes:
// 21/02/2025 - Claudia - Inclusao de botao para exportação de danfe/xml 
//                        por cliente/fornecedor. GLPI: 16930
//
// -----------------------------------------------------------------------------------------------
#include 'protheus.ch'
User Function FISTRFNFE ()

	aadd(aRotina,{"Exportacao - COMPL"  , "U_VA_DadosExport()"       ,0,2,0 ,NIL})
	aadd(aRotina,{"Danfe/Xml por Assoc" , "U_VA_DANFEFOR()"          ,0,2,0 ,NIL})

Return
//
// -----------------------------------------------------------------------------------------------
// Digta dados da exportacao
User Function VA_DadosExport() 
	// CHAMA A ROTINA DE COMPLEMENTO DO MATA920 - PARA DIGITAR OS DADOS DA EXPORTACAO”
	if ! u_zzuvl ('088', __cUserId, .T.)
		return .F.
	endif
	Mata926(SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_ESPECIE,SF2->F2_CLIENTE,SF2->F2_LOJA,"S",SF2->F2_TIPO)
Return .T. 
