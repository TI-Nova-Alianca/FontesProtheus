
// Programa...: Verdva1
// Autor......: Jeferson Carlos Rech 
// Data.......: 07/2000
// Descricao..: Verifica se a Inscricao Estadual e valida 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #validacao
// #Descricao         #Verifica se a Inscricao Estadual e valida 
// #PalavasChave      #inscricao_estadual #validação
// #TabelasPrincipais #SA2 
// #Modulos   		  #CON 
//
// Historico de alteracoes:
// 13/09/2021 - Claudia - Tratamento para A1_INSCR. GLPI: 10797
//
// -------------------------------------------------------------------------
#include "rwmake.ch"

User Function Verdva1()
    _lRet   := .T.
    cEstado := M->A1_EST
    cIsento := rtrim(M->A1_INSCR)

    Do Case
        Case alltrim(cIsento) == "ISENTO" .or. alltrim(cIsento) == "ISENTA"
            _lRet := .F.
        Case alltrim(cIsento) == "" 
            _lRet := .T.
        Otherwise
            _lRet := IE(cIsento,cEstado,.T.)
    EndCase
    // If alltrim(cIsento) == "ISENTO" .or. alltrim(cIsento) == "" .or. alltrim(cIsento) == "ISENTA" 
    //     Return(_lRet)
    // Else
    //     _lRet := IE(cIsento,cEstado,.T.)
    // Endif
Return(_lRet)
