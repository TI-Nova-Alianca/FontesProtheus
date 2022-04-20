// Programa...: MT410TOK
// Autor......: Bruno
// Data.......: 24/03/20194
// Descricao..: Ponto de entrada que executa antes de confirmar a inclusão do Pedido de Venda.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada que executa antes de confirmar a inclusão do Pedido de Venda.
// #PalavasChave      #ponto_de_entrada #tudo_ok #pedido_de_venda
// #TabelasPrincipais #SC5 #SC6
// #Modulos           #FAT
//
// Historico de alteracoes:
// 24/03/2014 - Bruno        - Verifica se o campo A1_SATIV1 da tabela do Cliente selecionado está preenchido
// 12/12/2018 - Andre/Sandra - Não Permite data fatura menor que a data atual no pedido de venda cond pagto tipo 9 
// 11/12/2019 - Claudia      - Incluída rotina _VerifTranfil() para validação de transferencia entre filiais, 
//							   Conforme GLPI 7164
// 14/04/2022 - Claudia      - Criada validações de vendedor. GLPI: 10699
// 20/04/2022 - Claudia      - Ajustada a validação do vendedor. GLPI: 10699
//
// --------------------------------------------------------------------------------------------------------------------

#include "protheus.ch"

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

	// Verifica se vendedor é valido no cadastro de cliente
	If M->C5_TIPO == 'N'
		_lRet := _VerifVend()
	EndIf 


Return _lRet
//
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
//
// -----------------------------------------------------------------------------
// Valida se o vendedor inserido é do cadastro de cliente
Static Function _VerifVend()
	local lRet  := .T.

	_sVend1 := fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VEND")
	_sVend2 := fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VEND2")

	If !empty(_sVend1) .and. !empty(M->C5_VEND1)
		If alltrim(M->C5_VEND1) <> alltrim(_sVend1) .AND.  alltrim(M->C5_VEND1) <> alltrim(_sVend2)
			u_help("Vendedor " +  M->C5_VEND1 + " não cadastrado no cliente! Ele não pode ser utilizado.")
			lRet := .F.
		EndIf
	EndIf
	If !empty(_sVend2) .and. !empty(M->C5_VEND2)
		If alltrim(M->C5_VEND2) <> alltrim(_sVend1) .AND.  alltrim(M->C5_VEND2) <> alltrim(_sVend2)
			u_help("Vendedor " +  M->C5_VEND2 + " não cadastrado no cliente! Ele não pode ser utilizado.")
			lRet := .F.
		EndIf
	EndIf

Return lRet
