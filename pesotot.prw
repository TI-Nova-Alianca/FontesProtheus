#INCLUDE "rwmake.ch"

// Programa...: pesotot
// Autor......: Adelar D. Minuzzo 
// Data.......: 13/10/06
// Descricao..: Programa executado no campo c6_qtdven para calcular peso acumulado do pedido de venda.		
//
// Historico de alteracoes:
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
//

User Function pesotot()

Local _aArea    := GetArea()
Local _aAreaSA1 := SA1->(GetArea())
Local _lRet     := .T.
Local _xfim     := chr(13)+chr(10)
//Adelar D. Minuzzo - ARM SERRA GAÚCHA - 13/10/2006
//OBJETIVO:	INFORMAR AO USUÁRIO O PESO TOTAL DOS ITENS DO PEDIDO
Local _nPosPeso := 	aScan(aHeader, {|x| AllTrim(x[2])=="C6_QTDVEN"}) 
Local _nPosCodp := 	aScan(aHeader, {|x| AllTrim(x[2])=="C6_PRODUTO"}) 
Local _nTotPeso	:=	0
Local _nPesopro :=  0
_nPesopro := FBUSCACPO('SB1',1,	,'SB1->B1_PESBRU') 
_nTotPeso	+=	GDFIELDGET("C6_QTDVEN") * _nPesopro

RestArea(_aAreaSA1)
RestArea(_aArea)
Return(_nTotPeso)

