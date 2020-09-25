// Programa:  MA540MNU
// Autor:     Cláudia Lionço
// Data:      12/11/2019
// Descricao: P.E. para acrescentar opcoes no menu nas exceções fiscais (MATA540)
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MA540MNU()
	
	//u_help(cFilAnt)
	If cFilAnt != '01'
		u_help(" Filial selecionada não é filial matriz! Não será possível realizar a atualização entre filiais.")
	Else
		aadd(aRotina,{"Atualiza filiais", "U_MT540REP" , 0 , 6, 0, nil})
	EndIf
	
Return 