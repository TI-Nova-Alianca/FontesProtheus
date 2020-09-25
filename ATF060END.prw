// Programa:   ATF060END
// Autor:      Andre Alves
// Data:       31/03/2020
// Descricao:  Criado ponto de entrada AF060END grava dados adicionais na rotina 
// transferencia de ativos.
// 
// Historico de alteracoes:
// 
//
// --------------------------------------------------------------------------

#Include 'Protheus.ch'

User Function ATF060END()

Local aArea := GetArea()

Alert("Ponto de Entrada ATF060END")

// Implementações do usuário...

RestArea(aArea)

Return