// Programa...: Verdva2
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

#include "rwmake.ch"

User Function Verdva2()
    _lRet   := .T.
    cEstado := M->A2_EST
    cIsento := rtrim(M->A2_INSCR)

    If cIsento == "ISENTO"
    Return(_lRet)
    Else
    _lRet := IE(cIsento,cEstado,.T.)
    Endif
Return(_lRet)
