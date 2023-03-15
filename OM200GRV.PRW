// Programa...: OM200GRV
// Autor......: Cláudia Lionço
// Data.......: 15/03/2022
// Descricao..: Montagem de Carga - Gravar os Dados dos Campos na Tabela Temporária
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Montagem de Carga - Gravar os Dados dos Campos na Tabela Temporária
// #PalavasChave      #montagem_de_carga #pedidos 
// #TabelasPrincipais #SC5
// #Modulos   		  #OMS 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#include 'protheus.ch'
 
User Function OM200GRV()
    Local _sTpFrete := ""
 
    TRBPED->(DbGoTop())
    Do While TRBPED->(!Eof())
        _sTpFrete := ""

        SC5->(DbSetOrder(1))
        If SC5->(DbSeek(FwxFilial("SC5") + TRBPED->PED_PEDIDO))
            _sTpFrete := SC5->C5_TPFRETE
            If !Empty(_sTpFrete)
                If RecLock("TRBPED", .F.)
                    TRBPED->PED_TPFRE := _sTpFrete
                    TRBPED->(MsUnlock())
                EndIf
            EndIf
        EndIf
        TRBPED->(DbSkip())
    EndDo
Return
