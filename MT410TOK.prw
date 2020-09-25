#include "protheus.ch"

// Programa...: MT410TOK
// Autor......: Bruno
// Data.......: 24/03/20194
// Descricao..: Função executa antes de confirmar a inclusão do Pedido de Venda
//
// --------------------------------------------------------------------------------------------------------------------
// Historico de alteracoes:
// 24/03/2014 - Bruno        - Verifica se o campo A1_SATIV1 da tabela do Cliente selecionado está preenchido
// 12/12/2018 - Andre/Sandra - Não Permite data fatura menor que a data atual no pedido de venda cond pagto tipo 9 
// 11/12/2019 - Claudia      - Incluída rotina _VerifTranfil() para validação de transferencia entre filiais, 
//							   Conforme GLPI 7164
// --------------------------------------------------------------------------------------------------------------------
//

User Function MT410TOK()
	Local _lRet := .T.
	
	If m->c5_tipo == 'N' .and. Empty(Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI, "A1_SATIV1"))
		u_help("Para finalizar o pedido, favor informar o Segmento(A1_SATIV1) do cliente "+C5_CLIENTE+" no seu cadastro.")
		_lRet := .F.
	EndIf
	
	// Não Permite data fatura menor que data atual pedido de venda
	if M->c5_data1 < DATE() .and. fBuscaCpo ("SE4", 1, xfilial ("SE4") + M->C5_CONDPAG, "E4_TIPO") = '9' 
		Alert (" Data da fatura menor que a data atual - MT410TOK")
		_lRet := .F.
	endif
	
	// verifica se a transferencia está sendo entre filiais
	_lRet := _VerifTranfil()
	
	 /*	//valida as linhas verificando se precisa fazer o calculo de descontos
recalculo:=0
	For i:=1 to len(aCols)
		if	GDFieldGet("C6_LINOK",i) ==.F.
			recalculo:=recalculo+1
			
			RecalcD(M->C5_DESCVIS,M->C5_DESCFOB,GDFieldGet("C6_QTDVEN",i),GDFieldGet("C6_BKPVLR",i),GDFieldGet("C6_DESCONT",i),i)
			
		endif
	Next
	if recalculo>0
		Alert("Uma ou mais linhas não foram calculadas manualmente. O sistema realizou o recalculo desses itens. Verifique!")
		_lRet := .T.
	endif  */

Return _lRet
// -----------------------------------------------------------------------------
// Verifica se a transferencia é entre filiais, conforme TES informada
Static Function _VerifTranfil()
	local lRet  := .T.
	local nXi	:= 0

	sTipo	 := M->C5_TIPO
	sCliente := M->C5_CLIENTE
	sLoja    := M->C5_LOJACLI
	
	If sTipo == 'D' .or. sTipo =='B' // fornecedor
		sCGC := Posicione("SA2",1,xFilial("SA2")+ sCliente + sLoja,"A2_CGC")
	Else
		sCGC := Posicione("SA1",1,xFilial("SA1")+ sCliente + sLoja,"A1_CGC")
	EndIf
	
	For nXi := 1 To Len(Acols)
		sTES    := GdFieldGet("C6_TES",nXi)
		sTranFil:= Posicione("SF4",1,xFilial("SF4")+alltrim(sTES),"F4_TRANFIL")
	
		If alltrim(sTranFil) == '1' .and. (sCGC <= '88612486000000' .or. sCGC >= '88612486999999') // não é filial		
			u_help("Cliente/fornecedor não é filial de transferência! Verifique cliente e/ou TES.")
			lRet := .F.
			Exit
		EndIf
	Next nXi 
Return lRet


/* *************************************************************************************************
*****       FUNÇÃO DE RECALCULO DE DESCONTOS EM CASCATA NA GRAVAÇÃO DO PEDIDO DE VENDA         *****
****************************************************************************************************
***** 20/06/2014 	********************************************************************************
***** nDescVista 	 % do desconto a vista (C5_DESCVIS)										   *****
***** nDescFOB 		 % do desconto frete tipo FOB (C5_DESCFOB)								   *****
***** nQnt 	 		 quantidade de produtos da linha (C6_QTDVEN)							   *****
***** nPrcVenda		 preço de venda do produto salvo no campo de BKP (sem descontos)(C6_BKPVLR)*****
***** nDescLin		 % de desconto na linha (C6_DESCONT)									   *****
***** lin 			 linha posicionada no aCols												   *****
****************************************************************************************************
**************************************************************************************************** */
/*
Static Function RecalcD(nDescVista,nDescFOB,nQnt,nPrcVenda,nDescLin,lin)

nValorTOT	:= 0
nPerc		:= 0

if nDescLin <> 0
	nPerc:=(nPrcVenda * nDescLin)/100
	nValorTOT:= nPrcVenda - nPerc
	
	GDFieldPut("C6_VALDESC ",nPerc,lin)
	GDFieldPut("C6_PRCVEN",nValorTOT,lin)
	GDFieldPut("C6_VAPRCVE",nValorTOT,lin)
	
endif

nPrcVenda	:=GDFieldGet("C6_BKPVLR",lin) - GDFieldGet("C6_VALDESC",lin)

//desconto FOB
if nDescFOB <> 0
	
	nPerc:=(nPrcVenda * nDescFOB)/100
	nValorTOT:= nPrcVenda - nPerc
	
	GDFieldPut("C6_DFOB ",nPerc,lin)
	GDFieldPut("C6_PRCVEN",nValorTOT,lin)
	GDFieldPut("C6_VAPRCVE",nValorTOT,lin)
	
endif

nPrcVenda	:=GDFieldGet("C6_BKPVLR",lin) - GDFieldGet("C6_VALDESC",lin) - GDFieldGet("C6_DFOB",lin)

//desconto à vista
if nDescVista <> 0
	nPerc:= (nPrcVenda*nDescVista)/100
	nValorTOT:= nPrcVenda - nPerc
	
	GDFieldPut("C6_DVISTA",nPerc,lin)
	GDFieldPut("C6_PRCVEN",nValorTOT,lin)
	GDFieldPut("C6_VAPRCVE",nValorTOT,lin)
endif

//calculo do total
nTotal:=ROUND(nQnt * GDFieldGet("C6_PRCVEN",lin),2)
GDFieldPut("C6_VALOR",nTotal,lin)

GDFieldPut("C6_LINOK",.T.,lin)
Return 
*/