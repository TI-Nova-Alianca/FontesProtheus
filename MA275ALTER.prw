// Programa...: MT275Brw
// Autor......: Bruno (DWT)
// Data.......: 25/07/2014
// Descricao..: P.E. tela de liberacao de lotes.
//
// Historico de alteracoes:
//

#include 'totvs.ch'

User Function MA275ALTER()
Local aAlter := PARAMIXB[1] // Vetor original contendo os campos do sistema

// -- Adiciona campos criados por usuário no vetor aAlter
aAdd(aAlter, 'DD_VADPLIB')
aAdd(aAlter, 'DD_VADPLIB')

Return(aAlter)

