// Programa...: VendaCC
// Autor......: ?
// Data.......: ?
// Descricao..: Retorna centro de custo em lancamentos padrao.
//
// Historico de alteracoes:
// 24/09/2014 - Robert - Desabilitados testes do campo B1_LOCPROD.
// 05/08/2015 - Robert - Passa a retornar CC apenas pelo vendedor e nao mais pela filial / tipo produto.
//

User Function VENDACC()        // incluido pelo assistente de conversao do AP5 IDE em 25/01/01
	local _aAreaAnt := U_ML_SRArea ()
/* Versao ateh 06/08/2015

	_cAlias :=Alias()
	DbselectArea("SD2")
	ccusto :=space(09)
	_cVend := ALLTRIM(POSICIONE("SA1",1,XFILIAL("SA1")+SD2->D2_CLIENTE+SD2->D2_LOJA,"A1_VEND"))
	POSICIONE("SB1",1,XFILIAL("SB1")+SD2->D2_COD,"B1_COD")
	_ctpvend := POSICIONE("SA3",1,XFILIAL("SA3")+_cvend,"A3_TIPVEND")
	_cCod :=  SD2->D2_COD

	IF SD2->D2_FILIAL $ "01/03" .AND. SA3->A3_TIPVEND="1" .AND. SB1->B1_TIPO == "PA"
		CCUSTO :="50121003"
	ELSEIF  SD2->D2_FILIAL $ "01/03" .AND. SA3->A3_TIPVEND=="2".AND.SB1->B1_TIPO=="PA"
		CCUSTO :="50121001"
	ELSEIF  SD2->D2_FILIAL $ "01/03" .AND. SA3->A3_TIPVEND=="2" .AND.SB1->B1_TIPO=="PA"
		CCUSTO :="50221001"
	ENDIF
*/

	ccusto := IIF(alltrim(SF2->F2_VEND1)$'186/135/060/000001','50121003',IIF(alltrim(SF2->F2_VEND1)$'001/170/176/177/178/179','50121002','50121001'))

//	DbselectArea(_cAlias)

	U_ML_SRArea (_aAreaAnt)
Return CCUSTO
