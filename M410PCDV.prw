// Programa:   	M410PCDV
// Autor:      	Cláudia Lionço
// Data:       	09/01/2020
// Cliente:    	Alianca
// Descricao:  	Este ponto de entrada pertence à rotina de pedidos de venda, MATA410(). 
//				Está localizado na rotina de devolução de compras A410ProcDv(). 
//				É executado após io preenchimento do gride com os dados da nota de entrada.
//				https://tdn.totvs.com/display/public/PROT/M410PCDV+-+Preenchimento+do+gride
//				SERÁ EXECUTADO APENAS QUANDO FOR O PRODUTO GENÉRICO 7190
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
	
	If !aCols[Len(aCols)][Len(aHeader)+1] // Se a Linha Não Estiver Deletada Prossegue
		If  alltrim(aCols[Len(aCols),nProd]) == '7190'
			aCols[Len(aCols),nDescri] := QRYSD1->D1_DESCRI
		EndIf
	Endif
	
	RestArea(aArea)
Return
