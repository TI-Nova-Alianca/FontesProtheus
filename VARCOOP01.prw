// Programa...: VARCOOP01
// Descricao..: Impressao de laudos de analises de laboratorio.
// Data.......: 2016
// Autor......: Procdata
//
// Historico de alteracoes:
// 01/03/2017 - Robert - Alguns ajustes de layout para entrada em producao.
// 22/06/2017 - Pedroni - Incluída impressão da Filial e da Estabilização Tartarica.
//
// ---------------------------------------------------------------------------------------
#include "totvs.ch"
#include "parmtype.ch"
#include "fivewin.ch"
#include "topconn.ch"
#include "PROTHEUS.CH"
#include "RPTDEF.CH"
#include "FWPrintSetup.ch"

User Function VARCOOP01(_cEnsaio)
	cPerg		:= "VARCOOP01"
	
	If empty(_cEnsaio)
		_ValidPerg()
		If	( ! Pergunte(cPerg,.T.) )
			Return
		EndIf
	Else
		MV_PAR01 := _cEnsaio
	EndIf
	
	Processa({ |lEnd| xPrintRel(),OemToAnsi('Gerando laudo.')}, OemToAnsi('Aguarde...'))
Return
//
// ----------------------------------------------------------------------------------------
Static Function xPrintRel()

	PRIVATE lAdjustToLegacy 	:= .T.
	PRIVATE lDisableSetup  		:= .T.
	PRIVATE _cPathPDF 			:= "C:\Temp\" //PASTA ONDE IRA SALVAR O PDF
	
	// Fonte
	oFont08		 := TFont():New('Arial',,08,.T.)
	oFont08n	 := TFont():New('Arial',,08,.T.,.T.)
	oFont12		 := TFont():New('Arial',,12,.T.)
	oFont12n	 := TFont():New('Arial',,12,.T.,.T.)
	oFont16	   	 := TFont():New('Arial',,16,.T.)
	oFont16n   	 := TFont():New('Arial',,16,.T.,.T.)
	oFont22		 := TFont():New('Arial',,22,.T.)
	oFont22n	 := TFont():New('Arial',,22,.T.,.T.)


	// SQL
	cQuery :=" SELECT * "
	cQuery +=" FROM "+RetSqlName("ZAF") + " ZAF "
	cQuery +=" WHERE ZAF.D_E_L_E_T_= '' "
	cQuery +=" AND ZAF.ZAF_ENSAIO = '" + Alltrim(MV_PAR01) + "' "
	cQuery +=" AND ZAF.ZAF_FILIAL = '" + XFILIAL("ZAF") + "' "

	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"_ZAF",.T.,.T.)

	DbSelectArea("_ZAF")
	DbGoTop()

	//Inicia objeto de impressão
	oPrint 	:= FWMSPrinter():New( upper("LAUDO"+alltrim(_ZAF->ZAF_ENSAIO) + ".pdf"), IMP_PDF, lAdjustToLegacy, , lDisableSetup)

	oPrint:SetResolution(72) 		// resolução
	oPrint:SetPortrait() 			// retrato
	oPrint:SetPaperSize(DMPAPER_A4) // folha A4
	oPrint:cPathPDF := _cPathPDF	// local onde vai savar o PDF
	oPrint:StartPage()

	//Impressão do cabeçalho
	
	cFileLogo	:= GetSrvProfString('Startpath','') + 'Logo.jpg'
	oPrint:SayBitmap(050,050,cFileLogo,400,200)

	_nLinha := 50
	
	oPrint:Say(_nLinha+100,650,OemToAnsi('LAUDO ANALÍTICO'),oFont22n)

	_nLinha += 50
	
	oPrint:Say(_nLinha,1500,"Codigo:",oFont16n)
	oPrint:Say(_nLinha,1800,"FML64",oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,1500,"Revisao:",oFont16n)
	oPrint:Say(_nLinha,1800,"3",oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,1500,"Data:",oFont16n)
	oPrint:Say(_nLinha,1800,dtoc(stod(_ZAF->ZAF_DATA)),oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,1500,"Pagina:",oFont16n)
	oPrint:Say(_nLinha,1800,"1 de 1",oFont16n)
	_nLinha += 50
	
	oPrint:Line(_nLinha,50, _nLinha,2350,CLR_BLACK ,"-2")
	_nLinha += 100


	oPrint:Say(_nLinha,600,OemToAnsi('Relatorio de Ensaio No: '),oFont22n)
	oPrint:Say(_nLinha,1300,OemToAnsi(alltrim(_ZAF->ZAF_ENSAIO)),oFont22)
	_nLinha += 100
	oPrint:Say(_nLinha,100,"Identificação do Produto:",oFont16n)
	oPrint:Say(_nLinha,1000,alltrim(_ZAF->ZAF_PRODUT) + ' - ' + Posicione("SB1",1,xFilial("SB1") + _ZAF->ZAF_PRODUT,"B1_DESC") ,oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,100,"Lote:",oFont16n)
	oPrint:Say(_nLinha,1000,_ZAF->ZAF_LOTE,oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,100,"Capacidade:" ,oFont16n)
	oPrint:Say(_nLinha,1000,cvaltochar(_ZAF->ZAF_ESTQ) + ' Litros',oFont16n)
	_nLinha += 50
	oPrint:Say(_nLinha,100,"Tanque:",oFont16n)
	_cTanque := alltrim(_ZAF->ZAF_FILIAL + _ZAF->ZAF_LOCAL + _ZAF->ZAF_LOCALI)
	oPrint:Say(_nLinha,1000,_cTanque + ' - ' + Posicione("SBE",1,xFilial("SBE") + _ZAF->ZAF_LOCAL + _ZAF->ZAF_LOCALI ,"BE_DESCRIC"),oFont16n)
	_nLinha += 50
	
	oPrint:Say(_nLinha,100,"Filial:",oFont16n)
	oPrint:Say(_nLinha,1000,alltrim(_ZAF->ZAF_FILIAL) + ' - ' + AllTrim(SM0->M0_FILIAL),oFont16n)
	_nLinha += 50
	
	_nLinha += 100

	// ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
	
	oPrint:Say(_nLinha,600,OemToAnsi('Características Físico-Químicas'),oFont22n)
	_nLinha += 50
	
	oPrint:Line(_nLinha-30,50, _nLinha-30,2350,CLR_BLACK ,"-4")
	oPrint:Say(_nLinha,0100,OemToAnsi('ENSAIOS'),oFont16n)
	oPrint:Say(_nLinha,0800,OemToAnsi('RESULTADO'),oFont16n)
	oPrint:Say(_nLinha,1500,OemToAnsi('UNIDADE'),oFont16n)
	oPrint:Line(_nLinha+5,50, _nLinha+5,2350,CLR_BLACK ,"-4")
	_nLinha += 50
	
	if _ZAF->ZAF_ACTOT != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Acidez Total'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_ACTOT)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('g/L'),oFont12n)
		_nLinha += 50
	endif

	if _ZAF->ZAF_ACVOL != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Acidez Volátil'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_ACVOL)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('g/L'),oFont12n)
		_nLinha += 50
	endif

	if _ZAF->ZAF_ACRED != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Açúcares Redutores'),oFont12n)
		if _ZAF->ZAF_ACRED <= 1
			oPrint:Say(_nLinha,0800,'<=1',oFont12)
		else
			oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_ACRED)),oFont12)
		endif
		oPrint:Say(_nLinha,1500,OemToAnsi('g/L'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_ALCOOL != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Álcool'),oFont12n)
		if _ZAF->ZAF_ALCOOL <= 0.1
			oPrint:Say(_nLinha,0800,'<=0,1',oFont12)
		else
			oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_ALCOOL)),oFont12)
		endif
		oPrint:Say(_nLinha,1500,OemToAnsi('%vol'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_DENSID != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Densidade'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_DENSID)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('g/cm'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_EXTRSE != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Extrato Seco'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_EXTRSE)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('g/L'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_SO2LIV
		oPrint:Say(_nLinha,0100,OemToAnsi('SO2 livre'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_SO2LIV)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('mg/L'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_SO2TOT
		oPrint:Say(_nLinha,0100,OemToAnsi('SO2 total'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_SO2TOT)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('mg/L'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_BRIX != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Brix'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_BRIX)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('°Brix'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_PH != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('pH'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_PH)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_TURBID != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Turbidez'),oFont12n)
		if _ZAF->ZAF_TURBID = 1000
			oPrint:Say(_nLinha,0800,'>=1000',oFont12)
		else
			oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_TURBID)),oFont12)
		endif
		oPrint:Say(_nLinha,1500,OemToAnsi('NTU'),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_COR420 != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Cor 420 nm'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_COR420)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_COR520 != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Cor 520 nm'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_COR520)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_COR620 != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Cor 620 nm'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_COR620)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
		_nLinha += 50
	endif

	if _ZAF->ZAF_ESTTAR != 0
		oPrint:Say(_nLinha,0100,OemToAnsi('Estab. Tartarica'),oFont12n)
		oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_ESTTAR)),oFont12)
		oPrint:Say(_nLinha,1500,OemToAnsi('%'),oFont12)
		_nLinha += 50
	endif

	oPrint:Say(_nLinha,0100,OemToAnsi('Intensidade'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_COR420 + _ZAF->ZAF_COR520 + _ZAF->ZAF_COR620)),oFont12)
	oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Ratio 420/520'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(cvaltochar(_ZAF->ZAF_COR520 / _ZAF->ZAF_COR420)),oFont12)
	oPrint:Say(_nLinha,1500,OemToAnsi(''),oFont12)
	_nLinha += 50

	_nLinha += 100

	// se campo estiver vazio, imprimir "Ausente"
	oPrint:Say(_nLinha,600,OemToAnsi('Características Microbiológicas'),oFont22n)
	_nLinha += 50
	
	oPrint:Line(_nLinha-30,50, _nLinha-30,2350,CLR_BLACK ,"-4")
	oPrint:Say(_nLinha,0100,OemToAnsi('ENSAIOS'),oFont16n)
	oPrint:Say(_nLinha,0800,OemToAnsi('RESULTADO'),oFont16n)
	oPrint:Say(_nLinha,1500,OemToAnsi('UNIDADE'),oFont16n)
	oPrint:Line(_nLinha+5,50, _nLinha+5,2350,CLR_BLACK ,"-4")
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Bolores e Leveduras'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(IIF(_ZAF->ZAF_BOLOR>0,cvaltochar(_ZAF->ZAF_BOLOR),"Ausente")),oFont12)
	oPrint:Say(_nLinha,1500,OemToAnsi('UFC/mL'),oFont12)
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Coliformes Totais 35 oC'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(IIF(_ZAF->ZAF_COLIF>0,cvaltochar(_ZAF->ZAF_COLIF),"Ausente")),oFont12)
	oPrint:Say(_nLinha,1500,OemToAnsi('UFC/mL'),oFont12)
	_nLinha += 50
	
	_nLinha += 100
	
	oPrint:Say(_nLinha,600,OemToAnsi('Características Sensoriais'),oFont22n)
	_nLinha += 50
	
	oPrint:Line(_nLinha-30,50, _nLinha-30,2350,CLR_BLACK ,"-4")
	oPrint:Say(_nLinha,0100,OemToAnsi('ENSAIOS'),oFont16n)
	oPrint:Say(_nLinha,0800,OemToAnsi('RESULTADO'),oFont16n)
	oPrint:Line(_nLinha+5,50, _nLinha+5,2350,CLR_BLACK ,"-4")
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Cor'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(IIF(_ZAF->ZAF_COR>0,cvaltochar(_ZAF->ZAF_COR),"Característico")  ),oFont12)
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Sabor'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(IIF(_ZAF->ZAF_SABOR>0,cvaltochar(_ZAF->ZAF_SABOR),"Característico")),oFont12)
	_nLinha += 50
	
	oPrint:Say(_nLinha,0100,OemToAnsi('Aroma'),oFont12n)
	oPrint:Say(_nLinha,0800,OemToAnsi(IIF(_ZAF->ZAF_AROMA>0,cvaltochar(_ZAF->ZAF_AROMA),"Característico")),oFont12)
	_nLinha += 150

	oPrint:Line(_nLinha,50, _nLinha,2350,CLR_BLACK ,"-4")
	_nLinha += 50

	oPrint:Say(_nLinha,0100,OemToAnsi('Produto em acordo com os Padrões Legais Vigentes, segundo ANVISA e MINISTÉRIO DA AGRICULTURA.'),oFont12)		
	_nLinha += 100
	
	_dia := day(stod(_ZAF->ZAF_DATA))
	_mes := alltrim(MesExtenso(month(stod(_ZAF->ZAF_DATA))))
	_ano := year(stod(_ZAF->ZAF_DATA))
	
	oPrint:Say(_nLinha,1500,OemToAnsi(Alltrim(SM0->M0_CIDCOB) + ", " + cvaltochar(_dia) + " de " + _mes + " de " + cvaltochar(_ano) + "."),oFont12)				
	oPrint:Say(_nLinha,200,OemToAnsi('Responsável Técnico:'),oFont16n)		
	_nLinha += 50		
	oPrint:Say(_nLinha,200,OemToAnsi('Nome:'),oFont12n)
	oPrint:Say(_nLinha,600,OemToAnsi(U_RetZX5('20',_ZAF->ZAF_CRQRES,'ZX5_20NOME')),oFont12)
	_nLinha += 50
	oPrint:Say(_nLinha,200,OemToAnsi('CRQ:'),oFont12n)
	oPrint:Say(_nLinha,600,OemToAnsi(_ZAF->ZAF_CRQRES),oFont12)
	_nLinha += 50

	// Impressão do rodapé
	oPrint:Line(2850,50,2850,2350,CLR_BLACK ,"-4")
	oPrint:Say(2900,0800,OemToAnsi(alltrim (sm0->m0_nomecom)),oFont12)
	oPrint:Say(2950,0800,OemToAnsi(alltrim (sm0->m0_endcob) + " - " + "Bairro " + alltrim (sm0->m0_BairCob)),oFont12)
	oPrint:Say(3000,0800,"CEP " + alltrim (transform (sm0->m0_CEPCob, "@R 99.999-999")) + " - " + alltrim (sm0->m0_CidCob) + " - " + sm0->m0_EstCob + " - ",oFont12)

	// ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

	oPrint:EndPage()
	oPrint:Preview()

	DbSelectArea("_ZAF")
	DbCloseArea()
	
Return
// ---------------------------------------------------------------------------------------
// Função para perguntas
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                       TIPO TAM DEC VALID F3     Opcoes                        Help
	aadd (_aRegsPerg, {01, "Numero do Laudo          ", "C", 09, 0,  "",   "ZAF", {},                            ""})

	U_ValPerg (cPerg, _aRegsPerg)

Return