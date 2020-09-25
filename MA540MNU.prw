// Programa:  MA540MNU
// Autor:     Cl�udia Lion�o
// Data:      12/11/2019
// Descricao: P.E. para acrescentar opcoes no menu nas exce��es fiscais (MATA540)
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MA540MNU()
	
	//u_help(cFilAnt)
	If cFilAnt != '01'
		u_help(" Filial selecionada n�o � filial matriz! N�o ser� poss�vel realizar a atualiza��o entre filiais.")
	Else
		aadd(aRotina,{"Atualiza filiais", "U_MT540REP" , 0 , 6, 0, nil})
	EndIf
	
Return 