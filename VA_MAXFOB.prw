/* **************************************************************************************
***** GATILHO C5_DESCFOB  ****************************************************************
***** Este gatilho verifica o desconto maximo FOB permitido pela matriz de desconto *
***************************************************************************************** */
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User Function VA_MAXFOB()
nDesconto   :=M->C5_DESCFOB
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
	aFOB	:= ZA2->ZA2_FOBMAX
else
	Alert("Não foi encontrado desconto máximo FOB em tabela!")
	nOk:=.T.
Endif

if nOK==.F.
	if nDesconto > aFOB
		Alert("Desconto não permitido! Desconto digitado maior que o definido na matriz de descontos!")
		nDesconto:=0
	endif
endif
Return nDesconto