/* **************************************************************************************
***** GATILHO C6_QTDVEN - C6_DESCONT ****************************************************
***** Este gatilho verifica se há desconto no cabeçalho e insere o desconto em linha*****
***************************************************************************************** */
#Include "Protheus.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

User Function VA_DESLIN()
nDesconto   :=M->C5_MDESC1
nPrcVenda	:=GDFieldGet("C6_PRCVEN")
nQnt		:=GDFieldGet("C6_QTDVEN")
nValorTOT	:= 0
nPerc		:= 0
nTotal		:= 0

//desconto total
if nDesconto <> 0
	//	GDFieldPut("C6_DESCONT",nDesconto)
	nPerc:=(nPrcVenda * nDesconto)/100
	nValorTOT:= nPrcVenda - nPerc
	
	GDFieldPut("C6_VALDESC",nPerc)
	GDFieldPut("C6_PRCVEN",nValorTOT)
	GDFieldPut("C6_VAPRCVE",nValorTOT)
	
	nTotal:=ROUND(nQnt * GDFieldGet("C6_PRCVEN"),2)
	GDFieldPut("C6_VALOR",nTotal)
	
	
endif

Return nDesconto
