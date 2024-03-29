// Programa...: Verdva2
// Autor......: Jeferson Carlos Rech 
// Data.......: 07/2000
// Descricao..: Verifica se a Inscricao Estadual e valida 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #validacao
// #Descricao         #Verifica se a Inscricao Estadual e valida 
// #PalavasChave      #inscricao_estadual #valida��o
// #TabelasPrincipais #SA2 
// #Modulos   		  #CON 
//
// Historico de alteracoes:
// 13/09/2021 - Claudia - Tratamento para A1_INSCR. GLPI: 10797
//
// -------------------------------------------------------------------------
#include "rwmake.ch"

User Function Verdva2()
    _lRet   := .T.
    cEstado := M->A2_EST
    cIsento := rtrim(M->A2_INSCR)

    Do Case
        Case alltrim(cIsento) == "ISENTO" .or. alltrim(cIsento) == "ISENTA"
            _lRet := .F.
            u_help("N�o deve ser preenchida a inscri��o estadual com ISENTO ou ISENTA. Deve-se deixar em branco.")
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
