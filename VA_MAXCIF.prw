/* **************************************************************************************
***** GATILHO C5_MDESC1  - C5_MDESC1    quando par=1 ************************************
***** GATILHO C6_DESCONT  - C6_DESCONT    quando par=2 *********************************
***** Este gatilho verifica o desconto maximo CIF permitido pela matriz de desconto *****
***************************************************************************************** */
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User Function VA_MAXCIF(par)

if par==1
	nDesconto   :=M->C5_MDESC1
elseif par==2
    nDesconto	:=GDFieldGet("C6_DESCONT")
endif
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
	aCIF	:= ZA2->ZA2_CIFMAX
else
	Alert("Não foi encontrado desconto máximo em tabela!")
	nOk:=.T.
Endif

if nOK==.F.
	if nDesconto > aCIF
		Alert("Desconto não permitido! Desconto digitado maior que o definido na matriz de descontos!")
		nDesconto:=0 
		
		if par==2
	      	GDFieldPut("C6_PRCVEN",GDFieldGet("C6_VALDESC")+GDFieldGet("C6_PRCVEN")) //VOLTA O VALOR 
	      	GDFieldPut("C6_VAPRCVE",GDFieldGet("C6_PRCVEN"))//VOLTA O VALOR 
	 	    GDFieldPut("C6_VALDESC",nDesconto)

		endif
	endif
endif
Return nDesconto