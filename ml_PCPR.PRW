// Programa...: ML_PCPR
// Autor......: Marcelo Minuzzo (DWT)
// Data.......: 10/08/2014
// Descricao..: Impressao pedido compra em PDF
//
// #TipoDePrograma    #relatorio
// #Descricao         #Impressao pedido compra em PDF
// #PalavasChave      #pedido_de_compra #pedido #compras 
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM
//
// Historico de alteracoes:
// 15/05/2015 - Robert  - Ajustes minimos de layout.
// 22/09/2016 - Catia   - Alterada horario de entrega de mercadorias
// 13/01/2017 - Julio   - Incluidos campos e alinhamentos efetuados.
// 12/01/2018 - Catia   - alterado o email que vai na ordem de compra para compras@novaalianca.coop.br
// 06/02/2018 - Robert  - Desabilitado campos C7_VAOBRA.
// 06/09/2018 - André   - Ajustado para mostrar TRANSPORTADORA na impressão
// 14/09/2018 - Andre   - Impressao C7_CODPRF e ajustado impressão 
// 28/01/2019 - Robert  - Ajustada mascara da quantidade para valores ate 9,999,999.99
// 11/02/2019 - Andre   - Campo A5_CODPRF foi aumentado para 25 caracteres. Feito tratamento para itens com 
//                        Cod Prod Forn maiores que 20 quebrar a linha.
// 04/04/2019 - Andre   - Adicionado linha com descbrição do TES logo abaixo do tipo de frete.
// 11/07/2019 - Andre   - Adicionado observação sobre notas vencidas na sexta feira.
// 24/07/2019 - Andre   - Alterado todo texto do campo de observação do pedido de compra conforme chamado 6306.
// 25/09/2019 - Cláudia - Incluída casas decimais no campo valor unitário
// 10/10/2019 - Andre   - Adicionado função xPulaPag() abaixo da assinatura.
// 25/11/2019 - Sandra  - Retirado observação do relatório que vai para os fornecedores. 
// 02/12/2019 - Robert  - Declaradas variaveis locais para for...next - tratamento para mensagem [For variable is not Local]
// 09/03/2020 - Claudia - Comentado include faltante conforme solicitação da release 12.1.25
// 28/09/2020 - Cláudia - Liberada a impressão dos dados adicionais para todos os tipos de produtos/serviços. GLPI: 8539
// 20/01/2021 - Sandra  - Alterado texto do campo Recebimento de Mercadorias do pedido de compra conforme chamado 9160.
// 25/02/2021 - Claudia - Observações para pedidos de serviço. GLPI: 7846
// 27/01/2022 - Sandra  - Alterado notas comforme chamado GLPI: 11541.
// 27/01/2022 - Sandra  - Incluso linhas conforme chamado GLPI: 11544.
// 21/03/2022 - Claudia - Ajustada a impressão duplicada das informações adicionais. GLPI: 11779
// 14/06/2022 - Claudia - Ajustada a impressão das observações. GLPI: 12112
// 26/06/2022 - Sandra  - Incluso novas moedas. GLPI: 12211
// 20/03/2023 - Claudia - Incluida nova obs. GLPI: 13324
// 04/04/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//
// ---------------------------------------------------------------------------------------------------------------------------
#include 'topconn.ch'
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"

User Function ML_PCPR()
	Private _cDescTran := ""
	Private lEnd       := .F.
	Private aAreaSC7   := SC7->(GetArea())
	Private aAreaSA2   := SA2->(GetArea())
	Private aAreaSA5   := SA5->(GetArea())
	Private aAreaSF4   := SF4->(GetArea())
	Private cPerg      := 'ML_PCPRXXX'
	Public  dEmissao
	Public  dDatPrf
	Public  _cMSG      := ""
	Public  _cNTRANSP  := ""
	
	sim := .f.
	_ncontato  := ""
	caminho := ""

   	Private	cNumPed  	:= sc7->c7_num		// Numero do Pedido de Compras
	Private	lImpPrc		:= .T. 				// Imprime os Precos ?
	Private	nTitulo 	:= "" 				// Titulo do Relatorio ?
	Private	cObserv2	:= ""		  	    // 1a Linha de Observacoes
	Private	cObserv3	:= ""		    	// 1a Linha de Observacoes
	Private	cObserv4	:= ""			    // 1a Linha de Observacoes
	Private _oSQL       := ClsSQL():New ()
	
	DbSelectArea('SC7')
	SC7->(DbSetOrder(1))
	If	( ! SC7->(DbSeek(xFilial('SC7') + cNumPed)) )
		Help('',1,'LC13R',,OemToAnsi('Pedido não encontrado.'),1)   //20110615
		Return .F.
	EndIf

	//Executa a rotina de impressao 
	Processa({ |lEnd| xPrintRel(),OemToAnsi('Gerando o relatório.')}, OemToAnsi('Aguarde...'))

	//Restaura a area anterior ao processamento. 
    //dbclosearea('TRA')
	dbclosearea()
	RestArea(aAreaSC7)
	RestArea(aAreaSA2)
	RestArea(aAreaSA5)

	RestArea(aAreaSF4)
Return (caminho)
//
// --------------------------------------------------------------------------
// Imprimir
Static Function xPrintRel()
	local i              := 0
	Private _cTransp     := ""
	Private _cNumNota    := ""
	Private oPrint       := TMSPrinter():New(OemToAnsi('Pedido de Compras'))
	Private oBrush       := TBrush():New(,4)
	Private oPen         := TPen():New(0,5,CLR_BLACK)
	lAdjustToLegacy      := .T.
	lDisableSetup        := .T.

	cDestino  := "\pedidos\"
	_cPathPDF := "C:\temp\" // local aonde ele vai gravar o arquivo. Tentar gravar direto no \protheus_data\
	_cFile    := "Ped_com_"+ALLTRIM(SC7->C7_NUM) //nome do arquivo padrão, deve ser alterado para não sobrescrever
	
	oPrint := FWMSPrinter():New(_cFile+".rel", IMP_PDF, lAdjustToLegacy, , lDisableSetup)

	Private oFont07      := TFont():New('Courier New',07,07,,.F.,,,,.T.,.F.)
	Private oFont08      := TFont():New('Courier New',08,08,,.F.,,,,.T.,.F.)
	Private oFont08n     := TFont():New('Courier New',08,08,,.T.,,,,.T.,.F.)
	Private oFont09      := TFont():New('Tahoma',09,09,,.F.,,,,.T.,.F.)
	Private oFont09nn    := TFont():New('Tahoma',09,09,,.T.,,,,.T.,.F.)
	Private oFont09n     := TFont():New('Courier New',09,09,,.T.,,,,.T.,.F.)
	Private oFont10      := TFont():New('Tahoma',10,10,,.F.,,,,.T.,.F.)
	Private oFont10n     := TFont():New('Courier New',10,10,,.T.,,,,.T.,.F.)
	Private oFont10nC    := TFont():New('Courier New',11,11,,.F.,,,,.F.,.F.)
	Private oFont11      := TFont():New('Tahoma',11,11,,.F.,,,,.T.,.F.)
	Private oFont11n     := TFont():New('Tahoma',11,11,,.T.,,,,.T.,.F.)
	Private oFont12n     := TFont():New('Tahoma',12,12,,.T.,,,,.T.,.F.)
	Private oFont13      := TFont():New('Tahoma',13,13,,.T.,,,,.T.,.F.)
	Private oFont14      := TFont():New('Tahoma',14,14,,.T.,,,,.T.,.F.)
	Private oFont14n     := TFont():New('Tahoma',14,14,,.F.,,,,.T.,.F.)
	Private oFont15      := TFont():New('Tahoma',15,15,,.T.,,,,.T.,.F.)
	Private oFont16      := TFont():New('Tahoma',16,16,,.T.,,,,.T.,.F.)
	Private oFont18      := TFont():New('Tahoma',18,18,,.T.,,,,.T.,.F.)
	Private oFont20      := TFont():New('Arial',20,20,,.F.,,,,.T.,.F.)
	Private oFont22      := TFont():New('Arial',22,22,,.T.,,,,.T.,.F.)
	Private oFont23      := TFont():New('Tahoma',14,14,,.T.,,,,.T.,.F.,.T.)
	Private nLinha       := 040 // Controla a linha por extenso
	Private nLinFim      := 0    // Linha final para montar a caixa dos itens
	Private lPrintDesTab := .F.  // Imprime a Descricao da tabela (a cada nova pagina)
	Private cRepres      := Space(80)
	Private _nQtdReg     := 0    // Numero de registros para intruir a regua
	Private _nValMerc 	 := 0    // Valor das mercadorias
	Private _nValIPI     := 0    // Valor do I.P.I.

	Private _nValDesc    := 0    // Valor de Desconto
	Private _nTotAcr     := 0    // Valor total de acrescimo
	Private _nTotSeg     := 0    // Valor de Seguro
	Private _nTotFre     := 0    // Valor de Frete
	_cDesCond:=""

	//Define que a impressao deve ser RETRATO

	// Ordem obrigátoria de configuração do relatório
	oPrint:SetResolution(72)
	oPrint:SetPortrait()
	
	oPrint:SetPaperSize(DMPAPER_A4)
	oPrint:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
	oPrint:cPathPDF := _cPathPDF // Caso seja utilizada impressão em IMP_PDF

	//Monta query 
	
	cSELECT := 'SC7.C7_FILIAL, SC7.C7_NUM, SC7.C7_EMISSAO, SC7.C7_FORNECE, SC7.C7_LOJA,SC7.C7_MOEDA, SC7.C7_CONTATO,'+;
	'SC7.C7_ITEM, SC7.C7_TPFRETE, SC7.C7_USER, SC7.C7_PRODUTO, SC7.C7_DESCRI, SC7.C7_QUANT, SC7.C7_MSG, SC7.C7_USER, SC7.C7_SEGUM, '+;
	'SC7.C7_PRECO, SC7.C7_IPI, SC7.C7_TOTAL, SC7.C7_VLDESC, SC7.C7_DESPESA, SC7.C7_OBS, SC7.C7_NUMSC, SC7.C7_CC,   '+; //	'SC7.C7_SEGURO, C7_CONAPRO, SC7.C7_VALFRE, SC7.C7_TES, SC7.C7_UM, SC7.C7_DATPRF,SC7.C7_COND, SC7.C7_QTSEGUM, SC7.C7_VAOBRA, SC7.C7_FILENT '
	'SC7.C7_SEGURO, SC7.C7_CONAPRO, SC7.C7_VALFRE, SC7.C7_NOMTRAN, SC7.C7_TES, SC7.C7_UM, SC7.C7_DATPRF,SC7.C7_COND, SC7.C7_QTSEGUM, SC7.C7_FILENT '
	cFROM   := RetSqlName('SC7') + ' SC7 '
	cWHERE  := 'SC7.D_E_L_E_T_ <>   '+CHR(39) + '*'            +CHR(39) + ' AND '+;
	'SC7.C7_FILIAL  =    '+CHR(39) + xFilial('SC7') +CHR(39) + ' AND '+;
	'SC7.C7_NUM     =    '+CHR(39) + cNumPed        +CHR(39)
	cORDER  := 'SC7.C7_FILIAL, SC7.C7_ITEM '
	cQuery  := ' SELECT '   + cSELECT + ;
	' FROM '     + cFROM   + ;
	' WHERE '    + cWHERE  + ;
	' ORDER BY ' + cORDER

	TCQUERY cQuery NEW ALIAS 'TRA'
	If	! USED()
		MsgBox(cQuery+'. Query errada','Erro!!!','STOP')
	EndIf
	
	DbSelectArea('TRA')
	Count to _nQtdReg
	
	ProcRegua(_nQtdReg)
	TRA->(DbGoTop())
	
	wmoeda := getMv("MV_SIMB1") 
	if C7_MOEDA > 1  // se moeda diferente de real
     // wmoeda := iif(C7_MOEDA=2,getMv("MV_SIMB2"),getMv("MV_SIMB3"))  
	  	Do CASE
		CASE C7_MOEDA == 2
		 	wmoeda := getmv("MV_SIMB2")
		CASE C7_MOEDA == 3
		 	wmoeda := getmv("MV_SIMB3")
		CASE C7_MOEDA == 4
		 	wmoeda := getmv("MV_SIMB4")	
		CASE C7_MOEDA == 5
		 	wmoeda := getmv("MV_SIMB5")	
		OTHERWISE
		 	wmoeda := ""
		ENDCASE

    endif
    
	xCabec()

	cComprador 	:= Posicione("SY1",3,xFilial("SY1")+alltrim(TRA->C7_USER),"Y1_NOME")
	cMailCompr 	:= Posicione("SY1",3,xFilial("SY1")+alltrim(TRA->C7_USER),"Y1_EMAIL")
	cDestMerc  	:= Posicione("SF4",1,xFilial("SF4")+alltrim(TRA->C7_TES),"F4_TEXTO")
	nCountReg  	:= 1
	_LibPed    	:= TRA->C7_CONAPRO
	_Tipofre   	:= TRA->C7_TPFRETE
	_CentroCusto:= ''
	tarja       := .t.
	_descCusto 	:= ''
	_cNumPed 	:= TRA->C7_NUM
	_cFilEnt 	:= TRA->C7_FILENT

	Do While TRA->(!Eof() )
		_aDescIt := {}
		_aDscObs := {}
		_dCorPrf := {}
		
		if tarja
	        tarja  := .F.
        else
	        tarja  := .T.
		endif

		oPrint:Say(nLinha,0045,TRA->C7_ITEM,oFont10n)
		oPrint:Say(nLinha,0140,SubStr(TRA->C7_PRODUTO,1,15),oFont10n)
		aadd(_dCorPrf,U_QuebraTxt(fbuscacpo("SA5",1,XFILIAL("SA5")+TRA->C7_FORNECE+TRA->C7_LOJA+TRA->C7_PRODUTO,"A5_CODPRF"),18))

		if len(_dCorPrf[1]) > 0
			oPrint:Say(nLinha,0270,_dCorPrf[1][1],oFont10n)
		endif

		aadd(_aDescIt,U_QuebraTxt(alltrim(TRA->C7_DESCRI),45))
		
		if len(_aDescIt[1]) > 0
			oPrint:Say(nLinha,0580,_aDescIt[1][1],oFont10n)
		endif
				
		oPrint:Say(nLinha,1280,SubStr(TRA->C7_UM,1,2),oFont10n)
		oPrint:Say(nLinha,1325,TransForm(TRA->C7_QUANT,'@E 9,999,999.99'),oFont10n)
		
		If ( lImpPrc )
			oPrint:Say(nLinha,1485,TransForm(TRA->C7_PRECO,'@E 999,999,999.9999'),oFont10n)
		EndIf

		If ( lImpPrc )
			oPrint:Say(nLinha,1685,TransForm(TRA->C7_TOTAL,'@E 999,999,999.99'),oFont10n)
		EndIf

		oPrint:Say(nLinha,1970,AllTrim(TransForm(TRA->C7_IPI,'@E 99')),oFont10n,,,,1)
		dDatPrf  := SubStr(TRA->C7_DATPRF,7,2)  + "/" + SubStr(TRA->C7_DATPRF,5,2)  + "/" + SubStr(TRA->C7_DATPRF,3,2)
		oPrint:Say(nLinha,2050,dDatPrf,oFont10n)
		
		if len(_dCorPrf[1]) > 1
				nLinha += 35
			oPrint:Say(nLinha,0270,_dCorPrf[1][2],oFont10n)
		endif

		aadd(_aDscObs,U_QuebraTxt(alltrim(TRA->C7_OBS),45))
		if len(_aDescIt[1]) > 1
				nLinha += 35
			oPrint:Say(nLinha,0580,_aDescIt[1][2],oFont10n)
		endif

		nLinha += 40
		_nValMerc += TRA->C7_TOTAL
		_nValIPI  += (TRA->C7_TOTAL * TRA->C7_IPI) / 100
		_nValDesc += TRA->C7_VLDESC
		_nTotAcr  += TRA->C7_DESPESA
		_nTotSeg  += TRA->C7_SEGURO
		_nTotFre  += TRA->C7_VALFRE
		_cNTRANSP += TRA->C7_NOMTRAN
		_cCond    := TRA->C7_COND
		_cUser    := TRA->C7_USER
		_NUMSC    := TRA->C7_NUMSC
		
		_ncontato  :=  TRA->C7_CONTATO
		SE4->(dbSetOrder(1))
		SE4->(DbSeek(xFilial("SE4")+_cCond))
		
		_cDesCond := SE4->E4_DESCRI
		IncProc()
		
		dbSelectArea("TRA")
		DbSkip()
		
		nCountReg := nCountReg + 1
		
		If nCountReg = 25
			xVerPag()
		EndIf
		
		oPrint:Line(nLinha-35,030,nLinha-35,2170)
		xPulaPag()
	EndDo
	oPrint:Line(nLinha-35,030,nLinha-35,2170)

	//Imprime TOTAL DE MERCADORIAS
	If ( lImpPrc )
		oPrint:Say(nLinha,1790,wmoeda,oFont15)
	    oPrint:Say(nLinha+10,1370,'Valor dos Itens ',oFont15)
		oPrint:Say(nLinha+10,1850,TransForm(_nValMerc,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()

	//Imprime TOTAL DE I.P.I. 
	If	( lImpPrc ) .and. ( _nValIpi > 0 )
		oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
		oPrint:Say(nLinha+10,1370,'Valor de IPI (+)',oFont15)
		oPrint:Say(nLinha+10,1850,TransForm(_nValIpi,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()

	//Imprime TOTAL DE DESCONTO
	If ( lImpPrc ) .and. ( _nValDesc > 0 )
		oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
		oPrint:Say(nLinha+10,1370,'Vlr de Desconto(-)',oFont15)
		oPrint:Say(nLinha+10,1850,TransForm(_nValDesc,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()
	
	//Imprime TOTAL DE ACRESCIMO 
	If ( lImpPrc ) .and. ( _nTotAcr > 0 )
		oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
		oPrint:Say(nLinha+10,1370,'Valor de Acresc. (+)',oFont15)
		oPrint:Say(nLinha+10,1850,TransForm(_nTotAcr,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()

	//Imprime TOTAL DE SEGURO 
	If	( lImpPrc ) .and. ( _nTotSeg > 0 )
		oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
		oPrint:Say(nLinha+10,1370,'Valor de Seguro (+)',oFont15)
		oPrint:Say(nLinha+10,1850,TransForm(_nTotSeg,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()

	//Imprime TOTAL DE FRETE 
	If	( lImpPrc ) .and. ( _nTotFre > 0 )
		oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
		oPrint:Say(nLinha+10,1370,'Valor de Frete (+)',oFont15)
	   	oPrint:Say(nLinha+10,1850,TransForm(_nTotFre,'@E 9,999,999.99'),oFont18)
		nLinha += 60
	EndIf
	xPulaPag()

	//Imprime o VALOR TOTAL !
	oPrint:Say(nLinha+10,1790,wmoeda,oFont15)
	oPrint:Say(nLinha+10,1370,'VALOR TOTAL ',oFont15)
	oPrint:Say(nLinha+10,1850,TransForm((( _nValMerc - _nValDesc ) +_nValIPI+ _nTotAcr	+ _nTotSeg + _nTotFre) ,'@E 9,999,999.99'),oFont18)
	nLinha += 080
	xPulaPag()

	//Imprime as observacoes dos parametros. 
	// Busca dados adicionais do pedido.
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT RTRIM (CAST (CAST (TEXTO AS VARBINARY (8000)) AS VARCHAR (8000))) AS TEXTO"
	_oSQL:_sQuery +=  " FROM VA_TEXTOS"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CHAVE = 'SC7" + cEmpAnt + cFilAnt + _cNumPed + "'"
//	_sDadAdic = alltrim (_oSQL:RetQry ())
	_sDadAdic = alltrim (_oSQL:RetQry (1, .f.))


	//Imprime as observacoes dos parametros. 
	// Busca dados adicionais do pedido.
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT RTRIM (CAST (CAST (TEXTO AS VARBINARY (8000)) AS VARCHAR (8000))) AS TEXTO"
	_oSQL:_sQuery += " FROM VA_TEXTOS"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CHAVE = 'OBS_SERVICO'
//	_sObsServico = alltrim (_oSQL:RetQry ())
	_sObsServico = alltrim (_oSQL:RetQry (1, .f.))

	If (SC7->C7_FILENT <> SC7->C7_FILIAL) .and. !Empty(SC7->C7_FILENT)
		SM0->(dbSeek(cEmpAnt+SC7->C7_FILENT))
	EndIf

	oPrint:Say(nLinha,0030,OemToAnsi('Local de Entrega:'),oFont13)
	
	oPrint:Say(nLinha,0380,alltrim(sm0 -> m0_EndEnt),oFont10)
	nLinha += 30
	oPrint:Say(nLinha,0380,alltrim(sm0 -> m0_CidEnt) + " - " + alltrim(sm0 -> m0_EstEnt),oFont10)
	nLinha += 30
	oPrint:Say(nLinha,0380,"Bairro: " + alltrim(sm0 -> m0_BairEnt) + "      CEP: " + alltrim(sm0 -> m0_CEPEnt),oFont10)
	nLinha += 30
	oPrint:Say(nLinha,0380,"Telefone: " + alltrim(SM0 -> M0_TEL),oFont10)
	nLinha += 30
	oPrint:Say(nLinha,0380,"CNPJ: " + TransForm(SM0 -> M0_CGC,'@R 99.999.999/9999-99') + "      IE: " + alltrim(SM0 -> M0_INSC),oFont10)
	nLinha += 50
	
	SM0->(dbSeek(cEmpAnt+cFilAnt))

	oPrint:Say(nLinha,0030,OemToAnsi('Observações:'),oFont13)
	_initxt  := 1
	_tamtxt  := 120
	_obsfull := {}
	
	aadd(_obsfull,U_QuebraTxt(alltrim(_sDadAdic),120))
	if len(_obsfull) > 0
		for i=1 to len(_obsfull[1])
			xVerPag()
			oPrint:Say(nLinha,0380,_obsfull[1][i],oFont10)
			nLinha += 40
			xPulaPag()
		next
	endif

	_obsfull := {}

	nLinha += 50

	_cQuery := " SELECT "
	_cQuery += " 	C7_VAPROSE "
	_cQuery += " FROM  " + RetSqlName("SC7") + " SC7 "
	_cQuery += " WHERE SC7.D_E_L_E_T_ = ''"
	_cQuery += " AND SC7.C7_FILIAL  = '"+ xFilial('SC7') +"'"
	_cQuery += " AND SC7.C7_NUM     = '" + cNumPed  +"'"
	_cQuery += " AND SC7.C7_VAPROSE = 'S'"
	_aServ := U_Qry2Array(_cQuery)

	if len(_aServ) > 0
		aadd(_obsfull,U_QuebraTxt(alltrim(_sObsServico),120))
		if len(_obsfull) > 0
			for i=1 to len(_obsfull[1])
				xVerPag()
				oPrint:Say(nLinha,0380,_obsfull[1][i],oFont10)
				nLinha += 40
				xPulaPag()
			next
		endif
	endif

	nLinha += 30
	xPulaPag()

	//Imprime MENSAGEM NO PEDIDO
	oPrint:Line(nLinha,0030,nLinha,2170)
	xPulaPag()
	nLinha += 30
	
	//Imprime a linha de prazo pagamento/entrega
	xPulaPag()
	oPrint:Say(nLinha,0030,OemToAnsi('Prazo Pagamento:'),oFont14)
	oPrint:Say(nLinha,0380,_cDesCond,oFont15)
	nLinha += 50
	xPulaPag()
	
	//Imprime a linha de transportadora 
	oPrint:Say(nLinha,0030,OemToAnsi('Transportadora :'),oFont14)
	If !Empty(_cNtransp)
		oPrint:Say(nLinha,0380,SubStr(_cNTRANSP,1,30),oFont15)
	Else
		oPrint:Say(nLinha,0380,'___________________________________________________',oFont14)
	EndIf
	
	//CENTRO DE CUSTO
	if !empty(_descCusto)
		nLinha += 50
		oPrint:Say(nLinha,0030,OemToAnsi('Centro de Custo: '),oFont14)
		oPrint:Say(nLinha,0380, _descCusto ,oFont14)
	ENDIF

	// TIPO DE FRETE
	nLinha += 50
	oPrint:Say(nLinha,0030,OemToAnsi('Tipo de Frete  : '),oFont14)
	
	IF _Tipofre == "F"
		oPrint:Say(nLinha,0380, "FOB" ,oFont14)
	ELSE
		oPrint:Say(nLinha,0380, "CIF" ,oFont14)
	ENDIF
	
	// DESTINO DA MERCADORIA
	nLinha += 50
	oPrint:Say(nLinha,0030,OemToAnsi('Dest Mercadoria: '),oFont14)
	oPrint:Say(nLinha,0380, cDestMerc ,oFont14)

	xPulaPag()

	DbSelectArea("SC1")
	DbSetOrder(1)
	DbSeek(xFilial("SC1") + _NUMSC)

	nLinha += 150
	oPrint:Say(nLinha,0500,SC1->C1_SOLICIT,oFont11n)
	oPrint:Say(nLinha,1350, alltrim(cComprador) ,oFont11n)
	nLinha += 30
	oPrint:Say(nLinha,1250, alltrim(cMailCompr) ,oFont10n)
	nLinha += 30
	oPrint:Say(nLinha,0030,          '                                  ______________________________                                     ______________________________',oFont09n)
	nLinha += 50
	oPrint:Say(nLinha,0160,OemToAnsi('                      Solicitante                                          Comprador'),oFont11n)

	xPulaPag()
	nLinha += 080
	// quadro das observções na parte inferior no final do pedido de compra
	oPrint:Line(nLinha,030,nLinha,2150) //linha superior
	oPrint:Line(nLinha,030,nLinha+420,030) //barra inicial
	oPrint:Line(nLinha,2150,nLinha+420,2150) //barra final
	oPrint:Line(nLinha+415,030,nLinha+415,2150)// linha inferior 

 	nLinha += 40
	oPrint:Say(nLinha,0060,'NOTAS: - Favor mencionar o número deste pedido de compras na nota fiscal, caso este não estiver',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'         expresso na nota fiscal a mesma será recusada.',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - Laudos dos produtos devem ser enviados para: laudos@novaalianca.coop.br',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - O nº do Pedido de Compra, Lote e data de Validade do Produto devem ser preenchidos',oFont14n) 
	nLinha += 40
	oPrint:Say(nLinha,0060,'          no campo Específico do XML, dúvidas contatar.',oFont14n)
	nLinha += 40                                 
	oPrint:Say(nLinha,0060,'       - Efetuamos pagamento somente via boleto bancário.',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - Não negociamos com Factoring.',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - Endereço de Cobrança: Estrada Gerardo Santin Guarese, s/n, Travessão Lagoa Bela',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'         Flores da Cunha/RS - CEP: 95.270-000 - Caixa Postal 21 - Telefone: + 55 54 3279 3400',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - E-mail: financeiro@novaalianca.coop.br ',oFont14n)
	nLinha += 40
	oPrint:Say(nLinha,0060,'       - Enviar NF para os emails: compras@novaalianca.coop.br e nfe@novaalianca.coop.br ',oFont14n)

    nLinha += 40
   
    xPulaPag() 
    oPrint:Line(nLinha,030,nLinha,2150) //linha superior
    oPrint:Line(nLinha,030,nLinha+100,030) //barra inicial
    oPrint:Line(nLinha,2150,nLinha+100,2150) //barra final
    oPrint:Line(nLinha+100,030,nLinha+100,2150)// linha inferior
   
    nLinha += 40
    oPrint:Say(nLinha,0060,'RECEBIMENTO DE MERCADORIAS - SEGUNDA A SEXTA: Manhã:  8:00hrs as 12:00hrs',oFont14)
    nLinha += 40
    oPrint:Say(nLinha,0060,'                                              Tarde:  13:00hrs as 16:00hrs',oFont14)
    nLinha += 40
   
	nLinha += 80
	xPulaPag()
	If !Empty(_cNumNota)
		oPrint:Say(nLinha,1630,OemToAnsi('Nota Fiscal:'),oFont12)
		oPrint:Say(nLinha,1930,_cNumNota,oFont14)
	EndIf

	oPrint:EndPage()

	//Imprime em Video, e finaliza a impressao.

	oPrint:Preview() //abre o PDF na tela
	dbSelectArea("TRA")
	dbCloseArea()
  	CpyT2S(_cPathPDF +_cFile+".PDF",cDestino)
	caminho := cDestino +_cFile+".pdf"

return .T.
//
//----------------------------------------------------------
// Cabeçalho
Static Function xCabec()
	oPrint:StartPage()

	DbSelectArea('SA2')
	SA2->(DbSetOrder(1))
	If	! SA2->(DbSeek(xFilial('SA2')+SC7->(C7_FORNECE+C7_LOJA)))
		Help('',1,'REGNOIS')
		Return .F.
	EndIf
	dbSelectArea("TRA")

	//Imprime o cabecalho da empresa.

	SM0->(dbSeek(cEmpAnt+cFilAnt))

	oPrint:SayBitmap(200,100,'logo.jpg',720,170)
	oPrint:Say(100,0930,AllTrim(Upper(SM0->M0_NOMECOM)),oFont15)
	oPrint:Say(145,0930,AllTrim(SM0->M0_ENDCOB),oFont14)
	oPrint:Say(190,0930,Capital(AllTrim(SM0->M0_CIDCOB))+'/'+AllTrim(SM0->M0_ESTCOB)+ '  -  ' + AllTrim(TransForm(SM0->M0_CEPCOB,'@R 99.999-999')) + '  -  ' + AllTrim(SM0->M0_TEL),oFont14)
	oPrint:Say(235,0930,AllTrim('www.novaalianca.coop.br'),oFont14)

	oPrint:Line(265,920,265,2170)
	oPrint:Say(300,0930,'CNPJ:',oFont14)
	oPrint:Say(300,1080,TransForm(SM0->M0_CGC,'@R 99.999.999/9999-99'),oFont14)
	oPrint:Say(300,1690,'Insc. Est.',oFont14)
	oPrint:Say(300,1920,SM0->M0_INSC,oFont14)

	//Titulo do Relatorio
	oPrint:Say(0400,1000,OemToAnsi('Pedido de Compras'),oFont22)
	
	//Fornecedor
	oPrint:Say(0530,0030,OemToAnsi('Fornecedor:'),oFont14)
	oPrint:Say(0520,0360,AllTrim(SA2->A2_NOME) + '  ('+AllTrim(SA2->A2_COD)+'/'+AllTrim(SA2->A2_LOJA)+')',oFont16)
	oPrint:Say(0580,0030,OemToAnsi('Endereço:'),oFont14)
	oPrint:Say(0580,0360,AllTrim(SA2->A2_END),oFont14)
	oPrint:Say(0630,0030,OemToAnsi('Município/U.F.:'),oFont14)
	oPrint:Say(0630,0360,AllTrim(SA2->A2_MUN)+'/'+AllTrim(SA2->A2_EST),oFont14)
	oPrint:Say(0630,1080,OemToAnsi('Cep:'),oFont14)
	oPrint:Say(0630,1300,TransForm(SA2->A2_CEP,'@R 99.999-999'),oFont14)
	oPrint:Say(0680,0030,OemToAnsi('Telefone:'),oFont14)
	if empty(SA2->A2_DDD)
		oPrint:Say(0680,0360,alltrim(SA2->A2_TEL),oFont14)
	else
		oPrint:Say(0680,0360,"("+alltrim(SA2->A2_DDD)+")" + " " + alltrim(SA2->A2_TEL),oFont14)
	endif
	oPrint:Say(0680,1080,OemToAnsi('Fax:'),oFont14)
	oPrint:Say(0680,1300,SA2->A2_DDD+" "+SA2->A2_FAX,oFont14)
	oPrint:Say(0730,0030,'Contato: ' + " ",oFont14)
	oPrint:Say(0730,0360, TRA->C7_CONTATO ,oFont14)
	oPrint:Say(0730,1080,OemToAnsi('Bairro:'),oFont14)
	oPrint:Say(0730,1300,AllTrim(SA2->A2_BAIRRO),oFont14)
	//Numero/Emissao
	if sim == .F.
		oPrint:Say(0650,1930,'Nº '+ TRA->C7_NUM,oFont18)
		numeroped:=TRA->C7_NUM
		dEmissao :=  CtoD(SubStr(TRA->C7_EMISSAO,7,2)  + "/" + SubStr(TRA->C7_EMISSAO,5,2)  + "/" + SubStr(TRA->C7_EMISSAO,3,2))
		oPrint:Say(0750,1860,'Data: '+ DtoC(dEmissao),oFont14)
		sim:= .t.
	else
		oPrint:Say(0640,1910,TRA->C7_NUM,oFont18)
		oPrint:Say(0750,1860,DtoC(dEmissao),oFont14)
	endif
	oPrint:Say(0780,0030,OemToAnsi('C.G.C.'),oFont14)
	oPrint:Say(0780,0360,TransForm(SA2->A2_CGC,'@R 99.999.999/9999-99'),oFont14)
	oPrint:Say(0780,1080,OemToAnsi('Insc.Est.:'),oFont14)
	oPrint:Say(0780,1340,SA2->A2_INSCR,oFont14)
	nLinha:= 850
	oPrint:Line(nLinha+8,030,nLinha+8,2170)

	oPrint:Say(nLinha,0045,OemToAnsi('Item'),oFont13)
	oPrint:Say(nLinha,0150,OemToAnsi('Cód'),oFont13)
	oPrint:Say(nLinha,0275,OemToAnsi('Cód Forn'),oFont13)
	oPrint:Say(nLinha,0580,OemToAnsi('Descrição'),oFont13)

	oPrint:Say(nLinha,1280,OemToAnsi('UN'),oFont13)
	oPrint:Say(nLinha,1370,OemToAnsi('Qtde'),oFont13)
	oPrint:Say(nLinha,1570,OemToAnsi('Vlr.U.'),oFont13)
	oPrint:Say(nLinha,1660,OemToAnsi('('+wmoeda+')'),oFont09nn)
	
	oPrint:Say(nLinha,1750,OemToAnsi('Vlr.T'),oFont13)
	oPrint:Say(nLinha,1855,OemToAnsi('('+wmoeda+')'),oFont09nn)
	oPrint:Say(nLinha,1945,OemToAnsi('%IPI'),oFont13)
	oPrint:Say(nLinha,2050,OemToAnsi('Dt.Entr.'),oFont13)

	nLinha += 50
   	nCountReg := 1
Return
//
//-------------------------------------------------------------
// Verifica página
Static Function xVerPag()
	//Inicia a montagem da impressao.
Return
//
//-------------------------------------------------------------
// Verifica se deve ou nao saltar pagina
Static Function xPulaPag()
	//Inicia a montagem da impressao.
	If nLinha >= 2700
		oPrint:Line(2800,0100,2800,2300)
		oPrint:Say(2830,1000,'CONTINUA NA PROXIMA PAGINA',oFont08n)
		oPrint:Line(2900,0100,2900,2300)

		oPrint:EndPage()
		xCabec()
	EndIf
Return
