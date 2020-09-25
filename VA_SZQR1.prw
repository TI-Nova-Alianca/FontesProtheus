#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

//13/06/2011
//OBJETIVO: PROGRAMA DE IMPRESSÃO DA GUIA DE LIVRE TRANSITO EM PAPEL A4
//
// Historico de alteracoes:
// 16/06/2011 - Robert - Ajuste posicionamento dados de analises.
// 05/07/2011 - Robert - Campo B1_MARPR separado por filial (B1_VARMAAL, B1_VARMASP, ...)
// 15/05/2012 - Robert - Unificacao dos campos B1_MARPR, B1_VARMAAL e B1_VARMASP.
// 13/02/2013 - Robert - Campo B1_TPPROD passa a ser padrao no Protheus 11. Criado B1_VACOR em seu lugar.
// 18/03/2013 - DWT    - Ajustes para que saia toda a impressao da guia não so os dados.
// 02/05/2013 - Elaine - Alteracao para tratar as informaçoes cadastrais do fornecedor quando a nota for do tipo B ou D
// 10/10/2014 - Robert - Melhorias diversas do layout, possibilidade de listar mais itens.
// 02/04/2015 - Robert - Deixa de usar os campos ZQ_NF01, ZQ_NF02, ... e faz toda a leitura do SF2.
// 17/05/2016 - Robert - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 07/02/2016 - Robert - Passa a imprimir o 'CR' (codigo Sisdeclara) e nao mais o reg. do MA do produto.
//

// -------------------------------------------------------------------------
User Function VA_SZQR1(_cNumGuia)
	Local aArea     := GetArea()
	Local oPrint

	_oFN19N   	:=	TFont():New("Courier New",,17,,.T.,,,,,.F.)		//fonte do número do laboratório
	_oFN19   	:=	TFont():New("Courier New",,17,,.F.,,,,,.F.)		//fonte do número do laboratório
	_oFN16N   	:=	TFont():New("Courier New",,13,,.T.,,,,,.F.)		//fonte do número do laboratório
	_oFN16  	:=	TFont():New("Courier New",,13,,.F.,,,,,.F.)		//fonte do número do laboratório
	_oFNumero 	:=	TFont():New("Courier New",,16,,.T.,,,,,.F.)		//fonte do número do laboratório
	_oFCabec 	:=	TFont():New("Courier New",,10,,.f.,,,,,.F.)		//fonte das informações dos cabeçalhos
	_oFNotas 	:=	TFont():New("Courier New",,08,,.f.,,,,,.F.)		//fonte das informações dos cabeçalhos
	_oFProdNor 	:=	TFont():New("Courier New",,08,,.f.,,,,,.F.)		//fonte dos dados dos produtos
	_oFProd 	:=	TFont():New("Courier New",,10,,.f.,,,,,.F.)		//fonte dos dados dos produtos
	_oFVias		:=	TFont():New("Courier New",,07,,.f.,,,,,.F.)		//fonte das descricoes das vias

	_nColCab1	:=	0250
	_nColCab2	:=	0400
	_nColCab3	:=	0700
	_nColCab4	:=	1000
	_nColCab5	:=	1850

	_nLinInc	:=	085		//incremento da linha nos cabeçalhos
	_nIncPrd	:=	27  // 040		//incremento da linha dos produtos

	_nColNor01	:=	0030	//
	_nColNor02	:=	0270	//
	_nColNor03	:=	0440	//
	_nColNor04	:=	0610	//
	_nColNor05	:=	0850    //
	_nColNor06	:=	1000    //
	_nColNor07	:=	1250	//
	_nColNor08	:=	1400	//
	_nColNor09	:=	1700    //
	_nColNor10	:=	1870    //
	_nColNor11	:=	2150    //

	_nColAnl01	:=	_nColNor01 + 100
	_nColAnl02	:=	_nColNor03
	_nColAnl03	:=	_nColNor04 + 200
	_nColAnl04	:=	_nColNor06 + 200
	_nColAnl05	:=	_nColNor08 + 100
	_nColAnl06	:=	_nColNor10 + 200

	oPrint 	:= TMSPrinter():New("GLT - Guia de Livre Transito")
	oPrint:SetPortrait()
	oPrint:Setup()

	Private PixelX := oPrint:nLogPixelX()
	Private PixelY := oPrint:nLogPixelY()

	RptStatus({|lEnd| _Relatorio(@oPrint, @lEnd, _cNumGuia)},"Imprimindo Guia...")
	oPrint:Preview()

	RestArea(aArea)
Return



// --------------------------------------------------------------------------------------
Static Function _Relatorio(oPrint, lEnd, _cNumGuia)
	Local	_cPerg		:=	"VA_SZQR001"
	Local	_nLinha		:=	1000
	Local	_nLitros	:=	0
	Local	_aSafras	:=	{}
	Local	_bFormEsp	:=	.f.		//formulário da gráfica Lige Ltda. Flores da Cunha
	Local	_nCopias	:=	5		//número de cópias iguais a primeira página
	Local	_nPagina	:=	0
	Local _cLitros  	:= ""
	Local _cLitros2 	:= ""
	Local _sTipoNF  	:= ""
	Local _cNotas   	:= _Notas(@_sTipoNF)
	Local _nPaginas		:= 0

	//verifica se o número do laboratório já foi informado na guia
	DbSelectArea( "SZQ" )
	DbSetOrder(1)
	DbSeek( xFilial("SZQ")+_cNumGuia )
	If Found()
		If Empty(SZQ->ZQ_NUMLAB)
			_ValidPerg(_cPerg)
			U_GravaSX1 (_cPerg, "01", Space( TamSx3("ZQ_NUMLAB")[1] ))
			If Pergunte(_cPerg, .t.) .and. !Empty(mv_par01)
				DbSelectArea( "SZQ" )
				RecLock("SZQ", .f.)
				ZQ_NUMLAB	:=	mv_par01
				MsUnLock()
			Endif
		Endif

		_bFormEsp	:=	IIf( SZQ->ZQ_FILIAL $ "07/12", .f., .t. )
		_nLinIni	:=	IIf( _bFormEsp, 450, 500 )

		For _nPaginas := 1 To _nCopias
			oPrint:SayBitmap(050,080,'Brasao_Republica.bmp',300,300)
		
			oPrint:Say(_nLinIni-370, 400,'MINISTÉRIO DA AGRICULTURA, PECUÁRIA E ABASTECIMENTO', _oFN16N)
			oPrint:Say(_nLinIni-320, 400,'SECRETARIA DE DEFESA AGROPECUÁRIA', _oFN16)
			oPrint:Say(_nLinIni-270, 400,'DELEGACIA FEDERAL DO RIO GRANDE DO SUL', _oFN16)
			oPrint:Say(_nLinIni-220, 400,'SECRETARIA DA AGRICULTURA, PECUÁRIA, PESCA E AGRONEGÓCIO DO RS', _oFN16)

			Do Case
			Case _nPaginas = 1
				oPrint:Say(_nLinIni-400, 1900,'1ª VIA', _oFN16)
				oPrint:Say(_nLinIni-350, 1900,'ACOMPANHA A MERCADORIA', _oFVias)
			Case _nPaginas = 2
				oPrint:Say(_nLinIni-400, 1900,'2ª VIA', _oFN16)
				oPrint:Say(_nLinIni-350, 1900,'ÓRGÃO DE FISCALIZAÇÃO DE DESTINO', _oFVias)
			Case _nPaginas = 3
				oPrint:Say(_nLinIni-400, 1900,'3ª VIA', _oFN16)
				oPrint:Say(_nLinIni-350, 1900,'ÓRGÃO DE FISCALIZAÇÃO LOCAL', _oFVias)
			Case _nPaginas = 4
				oPrint:Say(_nLinIni-400, 1900,'4ª VIA', _oFN16)
				oPrint:Say(_nLinIni-350, 1900,'ESTATÍSTICA', _oFVias)
			Case _nPaginas = 5
				oPrint:Say(_nLinIni-400, 1900,'5ª VIA', _oFN16)
				oPrint:Say(_nLinIni-350, 1900,'EMPRESA REMETENTE', _oFVias)
			EndCase

			oPrint:Line(_nLinIni-110,0030,_nLinIni+150,0030) //barra inicial
			oPrint:Line(_nLinIni-110,2400,_nLinIni+150,2400) //barra final
			oPrint:Line(_nLinIni-110,030,_nLinIni-110,2400) //linha superior
			oPrint:Line(_nLinIni+150,030,_nLinIni+150,2400) //linha inferior
			oPrint:Line(_nLinIni+20,030,_nLinIni+20,2400) //linha meio
			oPrint:Line(_nLinIni+20,_nColCab5-80,_nLinIni+150,_nColCab5-80) //barra formulario
  		
			oPrint:Say(_nLinIni-60, 50,'GUIA DE LIVRE TRÂNSITO N°', _oFN19N)
			oPrint:Say(_nLinIni+50, 50,'Para produtos que transitem a granel.', _oFN19)
	
			_nLinha	:=	_nLinIni
			oPrint:Say(_nLinha+30, _nColCab5, 'Nº DO FORMULARIO', _oFProd)
			oPrint:Say(_nLinha-40, _nColCab5, SZQ->ZQ_NUMLAB, _oFNumero)	//imprime o número do laboratório
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 270, 280 )
		
			_CabProd(@oPrint, @_nLinha, _cNotas)		//imprime cabeçalho da produtora
		
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 580, 600 )
			_CabReceb(@oPrint, @_nLinha, _sTipoNF)	//imprime cabeçalho da recebedora
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 890, 920 )
			_CabTransp(@oPrint, @_nLinha)	//imprime dados da transportadora
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1250, 1270 )
			_nLitros	:=	0
			_ProdNor(@oPrint, @_nLinha, @_nLitros, @_aSafras)		//imprime os dados dos produtos

			//imprime o total de litros por extenso com controle de adição de linha
			If _nLitros > 0
				_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1500, 1550 )
				_cLitros	:=	AllTrim( Extenso(_nLitros) )
				_cLitros = Left(_cLitros, Len(_cLitros) - 5) + "LITROS"
				If Len(_cLitros) <= 100
					_cLitros2 = ""
				else
					_cLitros2 = substr (_cLitros, 101, 100)
					_cLitros  = left (_cLitros, 100)
				endif
				oPrint:Say(_nLinha, 030, 'TOTAL DE LITROS POR EXTENSO: '+ _cLitros, _oFCabec)	//imprime o número de litros por extenso
				oPrint:Say(_nLinha + _nLinInc,  030, _cLitros2, _oFCabec)	//imprime o número de litros por extenso
			Endif
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1600, 1650 )
			_Observacao(@oPrint, @_nLinha, _aSafras)	//imprime os dados da observação
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1820, 1850 )
			_ProdAnl(@oPrint, @_nLinha)		//imprime os dados analíticos
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 2270, 2320 )
			oPrint:Say(_nLinha, _nColAnl01, AllTrim(SM0->M0_CIDENT) + ", " + DTOC(dDataBase), _oFCabec)	//imprime local e data
			oPrint:Say(_nLinha+50, _nColAnl01+70, 'Local e Data', _oFCabec)	//imprime local e data
			oPrint:Say(_nLinha+50, _nColAnl01+780, 'Assinatura e Carimbo do Responsável Técnico da Empresa', _oFCabec)	//imprime local e data      00
			oPrint:Say(_nLinha+100, 60, 'Declaro que recebi cópia da presente Guia de Livre Trânsito', _oFNotas)	//imprime local e data
			oPrint:Say(_nLinha+310, _nColAnl01+780, 'Assinatura e Carimbo do Responsável da Unidade de Fiscalização', _oFCabec)	//imprime local e data
			oPrint:Say(_nLinha+310, _nColAnl01+70, 'Local e Data', _oFCabec)	//imprime local e data
			oPrint:Say(_nLinha+370, 60, 'ESTA GUIA SUBSTITUI, PROVISORIAMENTE, O MODELO OFICIAL PREVISTO NA LEI N° 7.678 E NO DECRETO 99.066', _oFCabec)
			oPrint:EndPage()
		Next
	Endif
Return



// --------------------------------------------------------------------------------------
//imprime os dados daobservação da Guia
Static Function _Observacao(oPrint, _nLinha, _aSafras)
	Local	_aArea	:=	GetArea()
	Local	_cTexto	:=	""
	Local	_cMemo	:=	AllTrim( MSMM(SZQ->ZQ_CODOBS,,,,3) )
	Local	_aTextos	:=	{}
	Local	_nLinTxt	:=	0

	_cTexto	+=	"OPERAÇÃO: " + AllTrim( FBuscaCpo("SX5" , 1, xFilial("SX5")+"Z8"+SZQ->ZQ_TPOPER, "X5_DESCRI") )
	_cTexto	+=	" - SAFRA "
	For _nLinTxt := 1 To Len(_aSafras)
		_cTexto	+=	_aSafras[_nLinTxt, 1] + "/"
	Next
	_cTexto	:=	Left(_cTexto, Len(_cTexto) - 1)
	_cTexto	:=	_cTexto + IIf( !Empty(_cMemo), " - OBSERVAÇÃO: " + _cMemo, "" )
	_aTextos	:=	aclone ( U_QuebraTXT (_cTexto, 135) )
	For _nLinTxt := 1 To IIf( Len(_aTextos) <= 1, Len(_aTextos), 2 )
		oPrint:Say(_nLinha, _nColNor01, _aTextos[_nLinTxt], _oFProdNor)
		_nLinha	+=	_nIncPrd
	Next

	RestArea(_aArea)
Return



// --------------------------------------------------------------------------------------
//imprime os dados de cada produto da guia
Static Function _ProdNor(oPrint, _nLinha, _nLitros, _aSafras)
	Local	_aArea	:=	GetArea()
	Local	_cTexto	:=	""
	Local	_bDupLin	:=	.f.
	Local	_nPos
	local	_oSisd  := NIL

	// Monta cabecalho dos itens
	oPrint:Line(_nLinha-110,0030,         _nLinha-110,2400) //linha superior
	oPrint:Line(_nLinha-060,030,          _nLinha-060,2400) //linha inferior
	oPrint:Line(_nLinha-110,0030,         _nLinha-070,0030) //barra inicial
	oPrint:Line(_nLinha-110,_nColNor02-40,_nLinha-070,_nColNor02-40) //barra inicial  quant
	oPrint:Line(_nLinha-110,_nColNor03-10,_nLinha-070,_nColNor03-10) //barra inicial  cod
	oPrint:Line(_nLinha-110,_nColNor04-10,_nLinha-070,_nColNor04-10) //barra inicial  produto
	oPrint:Line(_nLinha-110,_nColNor05-10,_nLinha-070,_nColNor05-10) //barra inicial  cod
	oPrint:Line(_nLinha-110,_nColNor06-10,_nLinha-070,_nColNor06-10) //barra inicial  'Tipo'
	oPrint:Line(_nLinha-110,_nColNor07-10,_nLinha-070,_nColNor07-10) //barra inicial  'Código'
	oPrint:Line(_nLinha-110,_nColNor08-10,_nLinha-070,_nColNor08-10) //barra inicial  'Classe'
	oPrint:Line(_nLinha-110,_nColNor09-10,_nLinha-070,_nColNor09-10) //barra inicial  'Espécie'
	oPrint:Line(_nLinha-110,_nColNor10-10,_nLinha-070,_nColNor10-10) //barra inicial  'Reg.Prod'
	oPrint:Line(_nLinha-110,_nColNor11-10,_nLinha-070,_nColNor11-10) //barra inicial  MAA'
	oPrint:Line(_nLinha-110,2400,         _nLinha-070,2400) //barra final
	oPrint:Say(_nLinha-100, _nColNor01+10, 'Tq/barril', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor02-30, 'Qt.litros ' , _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor03, 'Código', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor04, 'Produto', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor05, 'Código', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor06, 'Tipo', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor07, 'Código', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor08, 'Classe', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor09, 'Código', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor10, 'Espécie', _oFProdNor)
//	oPrint:Say(_nLinha-100, _nColNor11, 'Reg.Prod.MAA', _oFProdNor)
	oPrint:Say(_nLinha-100, _nColNor11, 'Cód.rastreab.', _oFProdNor)

	_nLinha -= 50

	DbSelectArea( "SB1" )
	DbSetOrder(1)
	DbSelectArea( "SZR" )
	DbSetOrder(1)
	DbSeek( xFilial("SZR") + SZQ->ZQ_NUMERO )
	While !Eof() .and. (ZR_FILIAL+ZR_NUMERO == xFilial("SZR") + SZQ->ZQ_NUMERO)
		_bDupLin	:=	.f.
		DbSelectArea( "SB1" )
		DbSeek( xFilial("SB1") + SZR->ZR_PRODUTO )
		DbSelectArea( "SB5" )
		DbSeek( xFilial("SB5") + SZR->ZR_PRODUTO )

		// Linhas verticais de separacao das colunas dos itens
		oPrint:Line(_nLinha-20,0030,         _nLinha+025,0030) //barra inicial
		oPrint:Line(_nLinha-20,_nColNor02-40,_nLinha+025,_nColNor02-40) //barra inicial  quant
		oPrint:Line(_nLinha-20,_nColNor03-10,_nLinha+025,_nColNor03-10) //barra inicial  cod
		oPrint:Line(_nLinha-20,_nColNor04-10,_nLinha+025,_nColNor04-10) //barra inicial  produto
		oPrint:Line(_nLinha-20,_nColNor05-10,_nLinha+025,_nColNor05-10) //barra inicial  cod
		oPrint:Line(_nLinha-20,_nColNor06-10,_nLinha+025,_nColNor06-10) //barra inicial  'Tipo'
		oPrint:Line(_nLinha-20,_nColNor07-10,_nLinha+025,_nColNor07-10) //barra inicial  'Código'
		oPrint:Line(_nLinha-20,_nColNor08-10,_nLinha+025,_nColNor08-10) //barra inicial  'Classe'
		oPrint:Line(_nLinha-20,_nColNor09-10,_nLinha+025,_nColNor09-10) //barra inicial  'Espécie'
		oPrint:Line(_nLinha-20,_nColNor10-10,_nLinha+025,_nColNor10-10) //barra inicial  'Reg.Prod'
		oPrint:Line(_nLinha-20,_nColNor11-10,_nLinha+025,_nColNor11-10) //barra inicial  MAA'
		oPrint:Line(_nLinha-20,2400,         _nLinha+025,2400) //barra final
				
		oPrint:Say(_nLinha, _nColNor01+10, X3COMBO("ZR_EMBALAG", SZR->ZR_EMBALAG), _oFProdNor)
		oPrint:Say(_nLinha, _nColNor02-50, Transform(SZR->ZR_LITROS, "@E 99,999,999"), _oFProdNor)
		oPrint:Say(_nLinha, _nColNor03, AllTrim(sb5 -> b5_vatpsis), _oFProdNor)
		_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+SB5->B5_vatpsis, "X5_DESCRI") )
		If Len(_cTexto) > 12
			oPrint:Say(_nLinha, _nColNor04, Left(_cTexto, 12), _oFProdNor)
			oPrint:Say(_nLinha + _nIncPrd, _nColNor04, Substr(_cTexto, 13, 12), _oFProdNor)
			_bDupLin	:=	.t.
		Else
			oPrint:Say(_nLinha, _nColNor04, _cTexto, _oFProdNor)
		Endif

		oPrint:Say(_nLinha, _nColNor05, AllTrim( SB1->B1_TPPROD ), _oFProdNor)
		_cTexto	:= 	alltrim(x3combo('B1_VACOR',sb1->b1_vacor))
		If Len(_cTexto) > 12
			oPrint:Say(_nLinha, _nColNor06, Left(_cTexto, 12), _oFProdNor)
			oPrint:Say(_nLinha + _nIncPrd, _nColNor06, Substr(_cTexto, 13, 12), _oFProdNor)
			_bDupLin	:=	.t.
		Else
			oPrint:Say(_nLinha, _nColNor06, _cTexto, _oFProdNor)
		Endif

		oPrint:Say(_nLinha, _nColNor07, AllTrim(sb5 -> b5_vacpsis ), _oFProdNor)
		_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"94"+SB5->B5_vacpsis, "X5_DESCRI") )
		If Len(_cTexto) > 16
			oPrint:Say(_nLinha, _nColNor08, Left(_cTexto, 16), _oFProdNor)
			oPrint:Say(_nLinha + _nIncPrd, _nColNor08, Substr(_cTexto, 17, 16), _oFProdNor)
			_bDupLin	:=	.t.
		Else
			oPrint:Say(_nLinha, _nColNor08, _cTexto, _oFProdNor)
		Endif

		oPrint:Say(_nLinha, _nColNor09, AllTrim(sb5 -> b5_vaepsis), _oFProdNor)
		_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"93"+sb5 -> b5_vaepsis, "X5_DESCRI") )
		If Len(_cTexto) > 15
			oPrint:Say(_nLinha, _nColNor10, Left(_cTexto, 15), _oFProdNor)
			oPrint:Say(_nLinha + _nIncPrd, _nColNor10, Substr(_cTexto, 16, 15), _oFProdNor)
			_bDupLin	:=	.t.
		Else
			oPrint:Say(_nLinha, _nColNor10, _cTexto, _oFProdNor)
		Endif

		//oPrint:Say(_nLinha, _nColNor11, AllTrim (SB1->b1_varmaal), _oFProdNor)
		_oSisd := ClsSisd ():New (szr -> zr_produto, 'SB5', szr -> zr_filial)
		oPrint:Say(_nLinha, _nColNor11, _oSisd:CodSisd, _oFProdNor)
		_nLinha	+=	_nIncPrd
		If _bDupLin
			_nLinha	+= _nIncPrd
		Endif
		_nLitros	+=	SZR->ZR_LITROS

		//atualiza os dados da safra
		_nPos	:=	ascan (_aSafras, {|x| x[1] == SZR->ZR_SAFRA})
		If _nPos <= 0
			aadd( _aSafras, {SZR->ZR_SAFRA, AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+SB5->B5_vatpsis, "X5_DESCRI") ), nil, nil} )
		Endif

		DbSelectArea( "SZR" )
		DbSkip()
	End

	// Linha apos o ultimo item.
	oPrint:Line(_nLinha,030,_nLinha,2400) //linha inferior

	RestArea(_aArea)
Return



// --------------------------------------------------------------------------------------
//imprime os dados de cada produto da guia
Static Function _ProdAnl(oPrint, _nLinha)
	Local	_aArea	:=	GetArea()

	oPrint:Line(_nLinha-060,0030,_nLinha-15,0030) //barra inicial
	oPrint:Line(_nLinha-060,2400,_nLinha-15,2400) //barra final
	oPrint:Line(_nLinha-060,030,_nLinha-060,2400) //linha superior
	oPrint:Line(_nLinha-15,030,_nLinha-15,2400) //linha inferior
		
	oPrint:Line(_nLinha-060,_nColAnl02-10,_nLinha-15,_nColAnl02-10) //linha inferior'ALCOOL'
	oPrint:Line(_nLinha-060,_nColAnl03-10,_nLinha-15,_nColAnl03-10) //linha inferiorAC. VOLATIL'
	oPrint:Line(_nLinha-060,_nColAnl04-10,_nLinha-15,_nColAnl04-10) //linha inferiorAC. TOTAL'
	oPrint:Line(_nLinha-060,_nColAnl05-10,_nLinha-15,_nColAnl05-10)//linha inferiorEX. SECO R
	oPrint:Line(_nLinha-060,_nColAnl06-10,_nLinha-15,_nColAnl06-10)//linha inferior'DENSIDADE

	oPrint:Say(_nLinha-100, 30, 'DADOS ANALÍTICOS', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl01, 'DATA', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl02, 'ALCOOL', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl03, 'AC. VOLATIL', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl04, 'AC. TOTAL', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl05, 'EX. SECO R.', _oFProdNor)
	oPrint:Say(_nLinha-50, _nColAnl06, 'DENSIDADE', _oFProdNor)

	DbSelectArea( "SZR" )
	DbSetOrder(1)
	DbSeek( xFilial("SZR") + SZQ->ZQ_NUMERO )
	While !Eof() .and. (ZR_FILIAL+ZR_NUMERO == xFilial("SZR") + SZQ->ZQ_NUMERO)

		// Linhas verticais de separacao das colunas dos dados analiticos
		oPrint:Line(_nLinha-15, 0030,         _nLinha+37,0030) //barra inicial
		oPrint:Line(_nLinha-015,_nColAnl02-10,_nLinha+37,_nColAnl02-10) //coluna inferior'ALCOOL'
		oPrint:Line(_nLinha-015,_nColAnl03-10,_nLinha+37,_nColAnl03-10) //coluna inferiorAC. VOLATIL'
		oPrint:Line(_nLinha-015,_nColAnl04-10,_nLinha+37,_nColAnl04-10) //coluna inferiorAC. TOTAL'
		oPrint:Line(_nLinha-015,_nColAnl05-10,_nLinha+37,_nColAnl05-10)//coluna inferiorEX. SECO R
		oPrint:Line(_nLinha-015,_nColAnl06-10,_nLinha+37,_nColAnl06-10)//coluna inferior'DENSIDADE
		oPrint:Line(_nLinha-15, 2400,         _nLinha+37,2400) //barra final

		oPrint:Say(_nLinha, _nColAnl01, DTOC(SZR->ZR_DATA), _oFProdNor)
		oPrint:Say(_nLinha, _nColAnl02, AllTrim(Transform( SZR->ZR_ALCOOL, "@E 99,999.99" )) + " ºGL", _oFProdNor)
		oPrint:Say(_nLinha, _nColAnl03, AllTrim(Transform( SZR->ZR_ACVOLAT, "@E 99,999.99" )) + " meq/l", _oFProdNor)
		oPrint:Say(_nLinha, _nColAnl04, AllTrim(Transform( SZR->ZR_ACTOTAL, "@E 99,999.99" )) + " meq/l", _oFProdNor)
		oPrint:Say(_nLinha, _nColAnl05, AllTrim(Transform( SZR->ZR_EXTRSEC, "@E 99,999.99" ))+ " g/l", _oFProdNor)
		oPrint:Say(_nLinha, _nColAnl06, AllTrim(Transform( SZR->ZR_DENSID, "@E 999.9999" )), _oFProdNor)
		_nLinha	+=	_nIncPrd
		DbSelectArea( "SZR" )
		DbSkip()
	End

	// Linha abaixo dos itens
	oPrint:Line(_nLinha + 10,030,_nLinha+10,2400) //linha inferior

	RestArea(_aArea)

	oPrint:Say(_nLinha+050, 130, 'Declaro, sob as penas da lei, que estes dados analíticos se referem ao produto que está acompanhado ', _oFProd)
	oPrint:Say(_nLinha+100, 30, 'por este documento sendo que este produto atende aos padrões de identidade e qualidade (PiQs) da legislação', _oFProd)
	oPrint:Say(_nLinha+150, 30, 'vigente e tem condições de livre trânsito no território nacional.', _oFProd)
	_nLinha	+= 150
Return



// --------------------------------------------------------------------------------------
//imprime os dados do cabeçalho da produtora
Static Function _CabProd(oPrint, _nLinha, _cNotas)
	Local	_aArea	:=	GetArea()
	local _aNotas := {}
	local _nNota := 0

	// Quebra lista de notas em mais de uma linha, caso necessario.
	_aNotas = aclone (U_QuebraTXT (_cNotas, 33))

	oPrint:Say(_nLinha, 030,'EMPRESA PRODUTORA:('+ alltrim(SM0->M0_NOMECOM)+')', _oFCabec)
	_nLinha	+=	_nLinInc

	oPrint:Say(_nLinha, 030, 'REG. MAA Nº: '+AllTrim( GetMv("VA_INSCMA") ), _oFCabec)
	oPrint:Say(_nLinha, _nColCab4-100, 'CNPJ: '+ Transform(SM0->M0_CGC, "@R 99.999.999/9999-99"), _oFCabec)

	oPrint:Say(_nLinha - 060, 1500, 'NOTA(S) FISCAL(IS):', _oFNotas)
	for _nNota = 1 to len (_aNotas)
		oPrint:Say(_nLinha - 060 + (_nNota - 1) * 27, 1830, _aNotas [_nNota], _oFNotas)
	next

	_nLinha	+=	_nLinInc
	oPrint:Say(_nLinha, 030, 'ENDEREÇO: ' + SM0->M0_ENDENT, _oFCabec)
	oPrint:Say(_nLinha, _nColCab5-150, 'ESTADO: ' + SM0->M0_ESTENT, _oFCabec)
	oPrint:Line(_nLinha+50,030,_nLinha+50,2400) //linha superior
	RestArea(_aArea)
Return



// --------------------------------------------------------------------------------------
//imprime os dados do cabeçalho da recebedora (cliente)
Static Function _CabReceb(oPrint, _nLinha, _sTipoNF)
	Local	_aArea	:=	GetArea()

	//if FBUSCACPO("SF2", 2, xFilial("SF2")+SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA + SZQ->ZQ_NF01 + SZQ->ZQ_SERIE01, "F2_TIPO") $ ('D|B')  // Fornecedor
	if _sTipoNF $ 'BD'  // Fornecedor
		DbSelectArea( "SA2" )
		DbSetOrder(1)
		DbSeek( xFilial("SA2") + SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA )
		oPrint:Say(_nLinha, 030, 'EMPRESA RECEBEDORA: '+SA2->A2_NOME, _oFCabec)
		_nLinha	+=	_nLinInc
		oPrint:Say(_nLinha, 030, 'REG. MAA Nº: ' + SA2->A2_VAREGMA, _oFCabec)
		oPrint:Say(_nLinha, _nColCab4-100, 'CNPJ:' + Transform(SA2->A2_CGC, "@R 99.999.999/9999-99"), _oFCabec)
		_nLinha	+=	_nLinInc
		oPrint:Say(_nLinha, 030, 'ENDEREÇO: ' + SA2->A2_END, _oFCabec)
		oPrint:Say(_nLinha, _nColCab5-150, 'ESTADO: ' +  SA2->A2_EST, _oFCabec)

	else  // Cliente
		DbSelectArea( "SA1" )
		DbSetOrder(1)
		DbSeek( xFilial("SA1") + SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA )
		oPrint:Say(_nLinha, 030, 'EMPRESA RECEBEDORA: '+SA1->A1_NOME, _oFCabec)
		_nLinha	+=	_nLinInc
		oPrint:Say(_nLinha, 030, 'REG. MAA Nº: ' + SA1->A1_VAREGMA, _oFCabec)
		oPrint:Say(_nLinha, _nColCab4-100, 'CNPJ:' + Transform(SA1->A1_CGC, "@R 99.999.999/9999-99"), _oFCabec)
		_nLinha	+=	_nLinInc
		oPrint:Say(_nLinha, 030, 'ENDEREÇO: ' + SA1->A1_END, _oFCabec)
		oPrint:Say(_nLinha, _nColCab5-150, 'ESTADO: ' +  SA1->A1_EST, _oFCabec)
	endif

	oPrint:Line(_nLinha+50,030,_nLinha+50,2400) //linha superior
	RestArea(_aArea)
Return



// --------------------------------------------------------------------------------------
//imprime os dados do cabeçalho da recebedora (cliente)
Static Function _CabTransp(oPrint, _nLinha)
	Local	_aArea	:=	GetArea()

	DbSelectArea( "SA4" )
	DbSetOrder(1)
	DbSeek( xFilial("SA4") + SZQ->ZQ_TRANSP )
	oPrint:Say(_nLinha, 030, 'TRANSPORTADO POR: ' + SA4->A4_NOME, _oFCabec)
	oPrint:Say(_nLinha, 1600, 'PLACA(S) VEÍC:' + szq -> zq_placas, _oFNotas)

	_nLinha	+=	_nLinInc
	oPrint:Say(_nLinha, 030, 'ENDEREÇO: '+ SA4->A4_END, _oFCabec)
	oPrint:Say(_nLinha, _nColCab5-100, 'ESTADO: ' + SA4->A4_EST, _oFCabec)
	_nLinha	+=	_nLinInc
	oPrint:Say(_nLinha, 030, 'MUNICÍPIO:' + SA4->A4_MUN, _oFCabec)
	oPrint:Say(_nLinha, _nColCab5-100, 'FONE: ' + SA4->A4_TEL, _oFCabec)

	RestArea(_aArea)
Return



// --------------------------------------------------------------------------------------
// rotina que transforma em texto o numero das notas
Static Function _Notas (_sTipoNF)
	Local _cTexto  := ""
	Local _aArea   := GetArea()
	local _oSQL    := NIL
	local _aRetQry := {}
/*	Local	_nF, _cNf

	DbSelectArea( "SZQ" )
	For _nF := 1 To 15
		_cNf	:=	StrZero(_nF, 2)
		If !Empty( SZQ->&("ZQ_NF"+_cNf) )
			_cTexto	+=	AllTrim( SZQ->&("ZQ_NF"+_cNf) ) + ", "
		Else
			Exit
		Endif
	Next _nF
	RestArea(_aArea)

	// Remove virgula do final da lista
	If Len(_cTexto) > 0
		_cTexto	:=	Left(_cTexto, Len(_cTexto) - 2	)
	Endif
*/
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT F2_DOC, F2_SERIE, F2_TIPO"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("SF2") + " SF2 " 
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''" 
	_oSQL:_sQuery +=   " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'" 
	_oSQL:_sQuery +=   " AND SF2.F2_VAGUIA  = '" + szq -> zq_numero + "'"
	u_log (_oSQL:_sQuery)
	_aRetQry := aclone (_oSQL:Qry2Array ())
	if len (_aRetQry) == 0
		u_help ("Nao foram encontradas notas fiscais ligadas a esta guia.")
	else
		_sTipoNF = _aRetQry [1, 3]  // Pega da primeira nota, pois sao todas do mesmo cliente/fornecedor.
		_cTexto = _oSQL:Qry2Str (1, ', ')  // Deixa um espaco junto com o separador para ajudar posteriormente a funcao U_QuebraTXT().
	endif
Return _cTexto



// --------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg (cPerg)
	local _aRegsPerg := {}

//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Informe o Número do Laborat.: ", "C", TAMSX3("ZQ_NUMLAB")[1], 0,  "",   "   ", {},                                     ""})
	U_ValPerg (cPerg, _aRegsPerg)

Return
