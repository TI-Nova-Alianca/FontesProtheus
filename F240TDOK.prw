// Programa.: F240TDOK
// Autor....: Cl�udia Lion�o
// Data.....: 11/10/2024
// Descricao: P.E. Valida��o dos t�tulos selecionados para o border�
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Valida��o dos t�tulos selecionados para o border�
// #PalavasChave      #bordero #associados
// #TabelasPrincipais #SE2
// #Modulos           #FIN

// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------
#include "protheus.ch"
User Function F240TDOK()
    local _lRet     := .T.
    Local _sMarca   := Paramixb[1]     // marca usada no t�tulo selecionado
    Local cAliasSE2P:= Paramixb[2]     // tabela tempor�ria com os t�tulos da tela
    local _dUltDiaMes := lastday(Date())

    If !Empty(_sMarca)
        (cAliasSE2P)->(DBGOTOP())       // posiciono no inicio da tabela tempor�ria
        While !(cAliasSE2P)->(Eof())
            If (cAliasSE2P)->E2_OK == _sMarca
                _oAssoc := ClsAssoc():New((cAliasSE2P)->E2_FORNECE,(cAliasSE2P)->E2_LOJA)
                if _oAssoc:EhSocio(_dUltDiaMes)
                    DbSelectArea('SZI')        
                    DbSetOrder(6)       // ZI_FILIAL + ZI_DOC + ZI_SERIE + ZI_PARCELA + ZI_ASSOC + ZI_LOJASSO                                                                                                 
                    if DbSeek(xFilial() + (cAliasSE2P)->E2_NUM + (cAliasSE2P)->E2_PREFIXO + (cAliasSE2P)->E2_PARCELA + (cAliasSE2P)->E2_FORNECE + (cAliasSE2P)->E2_LOJA)  
                        RecLock("SZI", .F.)
                            szi -> zi_bordero := (cAliasSE2P)->E2_FILIAL + cNumBor 
                        MsUnlock()   
                    endif   
                endif
                (cAliasSE2P)->(dbSkip())
            Else
                (cAliasSE2P)->(dbSkip())
            EndIf
        EndDo
    EndIf

Return _lRet
