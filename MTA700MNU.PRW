// Programa...: MTA700MNU
// Autor......: Cláudia Lionço
// Data.......: 05/07/2023
// Descricao..: Insere novas opções no array aRotina
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Insere novas opções no array aRotina
// #PalavasChave      #vendas 
// #TabelasPrincipais #SC4
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MTA700MNU()

    aadd(aRotina,{"Imp.Vendas" ,'U_VA_M700I()', 0 , 3,0,NIL}) 
    aadd(aRotina,{"Deleta Doc.",'U_VA_M700D()', 0 , 3,0,NIL}) 
    aadd(aRotina,{"Exp.Vendas" ,'U_VA_M700E()', 0 , 6,0,NIL}) 
    aadd(aRotina,{"Exp.PCP"    ,'U_VA_M700P()', 0 , 6,0,NIL}) 

Return

