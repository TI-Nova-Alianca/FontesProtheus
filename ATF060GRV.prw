// Programa:   AF060TOK
// Autor:      Andre Alves
// Data:       22/08/2019
// Descricao:  Criado ponto de entrada AF060TOK que valida os dados inseridos antes 
//             da gravação na rotina Transferência de Ativos (ATFA060).
// 
// Historico de alteracoes:
// 
//
// --------------------------------------------------------------------------

#include "rwmake.ch" 
#Include "PROTHEUS.CH" 

USER FUNCTION ATF060GRV()

Local aArea := GetArea()
//Local cFilialOri := cFilOrig
//Local cChave := cFilDest+SN4->(N4_CBASE+N4_ITEM)

dbSelectArea("FN9")
dbSetOrder(1)
MSGALERT ( FN9 -> FN9_IDMOV )
MSGALERT ( 'Ponto de entrada AF060TOK')
FN9->(dbSkip())




RestArea(aArea)

Return