// Programa...: DL200BRW
// Autor......: Cláudia Lionço
// Data.......: 27/01/2021
// Descricao..: Manipulação das Colunas do Browse de Pedidos da Montagem de Carga
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Manipulação das Colunas do Browse de Pedidos da Montagem de Carga
// #PalavasChave      #montagem_de_carga #pedidos 
// #TabelasPrincipais #SC5
// #Modulos   		  #OMS 
//
// Historico de alteracoes:
// 27/01/2021 - Claudia - Retirado os campos pois estavam repetidos no Browse
//
// --------------------------------------------------------------------------

#include "totvs.ch"
#include "protheus.ch"

User Function DL200BRW()
    Local aRet := PARAMIXB

    //Aadd(aRet,{"PED_MUN",,"Cidade"})
    //Aadd(aRet,{"PED_EST",,"Estado"})

Return aRet
