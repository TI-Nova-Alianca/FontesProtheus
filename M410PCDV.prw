// Programa:   	M410PCDV
// Autor:      	Cl�udia Lion�o
// Data:       	09/01/2020
// Cliente:    	Alianca
// Descricao:  	Este ponto de entrada pertence � rotina de pedidos de venda, MATA410(). 
//				Est� localizado na rotina de devolu��o de compras A410ProcDv(). 
//				� executado ap�s io preenchimento do gride com os dados da nota de entrada.
//				https://tdn.totvs.com/display/public/PROT/M410PCDV+-+Preenchimento+do+gride
//				SER� EXECUTADO APENAS QUANDO FOR O PRODUTO GEN�RICO 7190
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'

User Function M410PCDV()
	//Local cAliasSD1 := PARAMIXB[1]
	Local aArea 	:= GetArea()
	Local nItem     := 0
	Local nProd 	:= 0
	Local nDescri	:= 0

	sDoc 	 := SF1->F1_DOC
	sSerie   := SF1->F1_SERIE
	sFornece := SF1->F1_FORNECE
	sLoja	 := SF1->F1_LOJA
	//
	nItem    := Ascan( aHeader, {|x| Alltrim(x[2]) == "C6_ITEM"})
	nProd    := Ascan( aHeader, {|x| Alltrim(x[2]) == "C6_PRODUTO"})
	nDescri  := Ascan( aHeader, {|x| Alltrim(x[2]) == "C6_DESCRI"})
	
	If !aCols[Len(aCols)][Len(aHeader)+1] // Se a Linha N�o Estiver Deletada Prossegue
		If  alltrim(aCols[Len(aCols),nProd]) == '7190'
			aCols[Len(aCols),nDescri] := QRYSD1->D1_DESCRI
		EndIf
	Endif
	
	RestArea(aArea)
Return
