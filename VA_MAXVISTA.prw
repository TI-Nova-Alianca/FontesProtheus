/* **************************************************************************************
***** GATILHO C5_DESCVIS ****************************************************************
***** Este gatilho verifica o desconto maximo À VISTA permitido pela matriz de desconto *
***************************************************************************************** */
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User Function VA_MAXVISTA()
nDesconto   :=M->C5_DESCVIS
cliente		:=M->C5_CLIENTE
loja 		:=M->C5_LOJACLI
nOK			:=.F.

DbSelectArea("SA1")
DbSetOrder(1)
DbSeek(xFilial()+cliente+loja)
If Found()
	canal	:=SA1->A1_VACANAL
	estado	:=SA1->A1_EST
else
	Alert("Cliente não encontrado!")
Endif

DbSelectArea("ZA2")
DbSetOrder(1)
DbSeek(xFilial()+canal+estado)
If Found()
	aVista	:= ZA2->ZA2_AVISTA
else
	Alert("Não foi encontrado desconto máximo em tabela!")
	nOk:=.T.
Endif

if nOK==.F.
	if nDesconto > aVista
		Alert("Desconto não permitido!Desconto digitado maior que o definido na matriz de descontos!")
		nDesconto:=0
	endif
endif
Return nDesconto
