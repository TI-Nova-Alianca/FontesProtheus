#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"               
#INCLUDE "TOPCONN.CH"
#include "rwmake.ch"
#include 'totvs.ch'
#include "msobject.ch"

User Function VA_TABZA2()

	Private aRotina :=   {}
	Private cCadastro := "Matriz Canal X Desconto"

	AADD( aRotina, { OemToAnsi("Pesquisar") ,"AxPesqui"  ,0,1})
	AADD( aRotina, { OemToAnsi("Visualizar"),"AxVisual"  ,0,2})
	AADD( aRotina, { OemToAnsi("Incluir")   ,"AxInclui"  ,0,3})
	AADD( aRotina, { OemToAnsi("Alterar")   ,"AxAltera"  ,0,4})
	AADD( aRotina, { OemToAnsi("Excluir")   ,"AxDeleta"  ,0,5})

	//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
	//쿐ndereca para a funcao MBrowse                                          �
	//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
	DbSelectArea("ZA2")
	DbSetOrder(1)
	DbSeek(xFilial("ZA2"))
	MBrowse( 06, 01, 22, 75,"ZA2",,,,,,)

Return