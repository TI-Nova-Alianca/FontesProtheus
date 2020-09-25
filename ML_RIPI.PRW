/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³  ML_RIPI ³ Autor ³     Jeferson Rech     ³ Data ³ Mai/2003 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Relatorio de Valor de IPI ref. a Cupom Fiscal              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Clientes Microsiga                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
// Historico de alteracoes:
// 05/01/2009 - Robert - Criada (e jah desfeita) versao especifica para buscar valores antigos de IPI
// 05/06/2010 - Robert - Perguntas ajustadas para versao 10
// 02/12/2015 - Robert - Tratamento para IPI por aliquota e por valor absoluto.
// 08/01/2016 - Catia  - Mudado layout, incluido novos campos, calculo IPI por aliquota
// 08/01/2020 - Andre  - Removido tipo de produto MR.

User Function ml_RIPI()
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis obrigatorias dos programas de relatorio            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cString := "SD2"
	cDesc1  := "Este programa tem como objetivo, Imprimir o Relatorio"
	cDesc2  := "Com o Valor do IPI geracao atraves dos ECF."
	cDesc3  := ""
	tamanho := "G"
	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha  := {}
	nLastKey:= 0
	cPerg   := "MLRIPI"
	titulo  := "NF - Valor do IPI"
	wnrel   := "ML_RIPI"
	nTipo   := 0
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Perguntas no Arquivo SX1                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Envia controle para a funcao SETPRINT                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	If nLastKey == 27
		Return
	Endif
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	
	RptStatus({|| RptDetail()})
Return


Static Function RptDetail()
	
	SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
	
	cabec1:="Data     Documento  Serie  Produto                                            Quantidade      Valor Unitario   Vlr Abs     Aliquota       Valor do IPI "
	cabec2:="                                                                                "
	
	_xTVLRIPI := 0
	DbSelectArea("SD2")
	DbSetOrder(5)
	DbSeek(xFilial()+Dtos(mv_par01),.T.)
	Do While !Eof() .And. xFilial()==SD2->D2_FILIAL .And. SD2->D2_EMISSAO <= mv_par02
		IncRegua()              // Termometro de Impressao
		If Empty(SD2->D2_PDV)
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial()+SD2->D2_COD,.F.)
		If !Found()
			MsgAlert("Problemas!!! Nao localizado o Produto "+SD2->D2_COD,"Verifique!!!")
		Endif
		If SB1->B1_VLR_IPI <= 0 .and. SB1 -> B1_IPI <= 0
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		If SB1 -> B1_TIPO = 'MR'
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		If li>65
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif
		@ li, 000 PSAY SD2->D2_EMISSAO
		@ li, 012 PSAY SD2->D2_DOC
		@ li, 020 PSAY SD2->D2_SERIE
		@ li, 027 PSAY Left(SD2->D2_COD,6)
		@ li, 032 PSAY fBuscaCpo ('SB1', 1, xfilial('SB1') + SD2->D2_COD, "B1_DESC")
		@ li, 080 PSAY SD2->D2_QUANT    Picture "@E 9,999,999"
		@ li, 095 PSAY SD2->D2_PRCVEN   Picture "@E 999,999,999.99"
		@ li, 109 PSAY SB1->B1_VLR_IPI  Picture "@E 999,999.99"
		_xVLRIPI := (SB1->B1_VLR_IPI * SD2->D2_QUANT)
		IF _xVLRIPI = 0 
			_xVLRIPI := ((SD2->D2_PRCVEN*SD2->D2_QUANT)*SB1->B1_IPI/100)
		ENDIF
		@ li, 126 PSAY SB1->B1_IPI Picture "@E 999.99"
		@ li, 137 PSAY _xVLRIPI    Picture "@E 999,999,999.99"
		li:=li + 1
		_xTVLRIPI += _xVLRIPI
		
		DbSelectArea("SD2")
		DbSkip()
	Enddo
	
	If _xTVLRIPI > 0
		If li>63
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif
		li:=li + 2
		@ li, 000 PSAY "Total IPI -> "
		@ li, 136 PSAY _xTVLRIPI   Picture "@E 999,999,999.99"
		li:=li + 2
	Endif
	
	U_ImpParam (65)
	
	Set Device To Screen
	
	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH()   //Libera fila de relatorios em spool (Tipo Rede Netware)
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Emissao de                    ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Emissao ate                   ", "D", 8,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
