// Programa...: MT094CPC
// Autor......: Andre Alves
// Data.......: 09/04/2019
// Descricao..: Exibe informa��es de outros campos do pedido de compra no momento da libera��o do documento
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Exibe informa��es de outros campos do pedido de compra no momento da libera��o do documento
// #PalavasChave      #pedido_de_compra #liberacao_do_documento
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
// 15/01/2021 - Cl�udia - GLPI: 8286/8818. Acrescentados os campos C7_VADESTI|C7_VACCDES
// 04/05/2021 - Claudia - Acrescentado o campo C7_SOLICIT. GLPI:9814
// 20/02/2023 - Claudia - Acrescentado o campo C7_VAMSG. GLPI:13198.
// 15/03/2023 - Claudia - Retirado campo  C7_VAMSG   
// ------------------------------------------------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function MT094CPC()
    Local cCampos := "C7_OBS|C7_SOLICIT|C7_COMNOM|C7_VADESTI|C7_VACCDES" //  A separa��o dos campos devem ser feitos com uma barra vertical ( | ), igual � demonstrado no exemplo. 

Return (cCampos)
