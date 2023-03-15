// Programa...: DL200TRB
// Autor......: Cláudia Lionço
// Data.......: 15/03/2022
// Descricao..: Montagem de Carga - Criar Campos na Tabela Temporária
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Montagem de Carga - Criar Campos na Tabela Temporária
// #PalavasChave      #montagem_de_carga #pedidos 
// #TabelasPrincipais #SC5
// #Modulos   		  #OMS 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#include 'protheus.ch'
 
User Function DL200TRB()
    Local aRet  := PARAMIXB
 
    aAdd(aRet,{"PED_TPFRE", "C", 1, 0})
 
Return aRet
