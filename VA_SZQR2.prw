#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"

//13/06/2011
//OBJETIVO: PROGRAMA DE IMPRESSÃO DA GUIA DE LIVRE TRANSITO EM FORMULARIO PRE-IMPRESSO
//
// Historico de alteracoes:
// 16/06/2011 - Robert - Ajuste posicionamento dados de analises.
// 05/07/2011 - Robert - Campo B1_MARPR separado por filial (B1_VARMAAL, B1_VARMASP, ...)
// 15/05/2012 - Robert - Unificacao dos campos B1_MARPR, B1_VARMAAL e B1_VARMASP.
// 13/02/2013 - Robert - Campo B1_TPPROD passa a ser padrao no Protheus 11. Criado B1_VACOR em seu lugar.
// 02/05/2013 - Elaine - Alteracao para tratar as informaçoes cadastrais do fornecedor quando a nota for do tipo B ou D
// 02/04/2015 - Robert - Deixa de usar os campos ZQ_NF01, ZQ_NF02, ... e faz toda a leitura do SF2.
// 17/05/2016 - Robert - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 07/02/2016 - Robert - Passa a imprimir o 'CR' (codigo Sisdeclara) e nao mais o reg. do MA do produto.
//

User Function VA_SZQR2(_cNumGuia)

Local aArea     := GetArea()

Local oPrint

_oFNumero 	:=	TFont():New("Courier New",,16,,.T.,,,,,.F.)		//fonte do número do laboratório
_oFCabec 	:=	TFont():New("Courier New",,10,,.f.,,,,,.F.)		//fonte das informações dos cabeçalhos
_oFNotas 	:=	TFont():New("Courier New",,08,,.f.,,,,,.F.)		//fonte das informações dos cabeçalhos
_oFProdNor 	:=	TFont():New("Courier New",,08,,.f.,,,,,.F.)		//fonte dos dados dos produtos

_nColCab1	:=	0250
_nColCab2	:=	0400
_nColCab3	:=	0700
_nColCab4	:=	1000
_nColCab5	:=	1850

_nLinInc	:=	085		//incremento da linha nos cabeçalhos
_nIncPrd	:=	040		//incremento da linha dos produtos

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

//
Static Function _Relatorio(oPrint, lEnd, _cNumGuia)

Local	_cPerg		:=	"VA_SZQR001"
Local	_nLinha		:=	1000
Local	_nLitros	:=	0                           
Local	_aSafras	:=	{}
Local	_bFormEsp	:=	.f.		//formulário da gráfica Lige Ltda. Flores da Cunha
Local	_nCopias	:=	5		//número de cópias iguais a primeira página
Local	_nPagina	:=	0
Local 	_sTipoNF  	:= ""
Local 	_cNotas   	:= _Notas(@_sTipoNF)
Local 	_nPaginas	:= 0	

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
	//
	_bFormEsp	:=	IIf( SZQ->ZQ_FILIAL $ "07/12", .f., .t. )
	_nLinIni	:=	IIf( _bFormEsp, 450, 500 )
	//
	For _nPaginas := 1 To _nCopias
		_nLinha	:=	_nLinIni

		oPrint:Say(_nLinha, _nColCab5, SZQ->ZQ_NUMLAB, _oFNumero)	//imprime o número do laboratório
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 270, 280 )
		_CabProd(@oPrint, @_nLinha, _cNotas)		//imprime cabeçalho da produtora
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 580, 600 )
		_CabReceb(@oPrint, @_nLinha, _sTipoNF)	//imprime cabeçalho da recebedora
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 890, 920 )
		_CabTransp(@oPrint, @_nLinha)	//imprime dados da transportadora
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1250, 1270 )
		_nLitros	:=	0
		_ProdNor(@oPrint, @_nLinha, @_nLitros, @_aSafras)		//imprime os dados dos produtos
		//
		//imprime o total de litros por extenso com controle de adição de linha
		If _nLitros > 0
			_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1500, 1550 )
			_cLitros	:=	AllTrim( Extenso(_nLitros) )
			_cLitros	:=	Replicate( "X.", 5) + Left(_cLitros, Len(_cLitros) - 5) + "LITROS "
			If Len(_cLitros) <= 70
				_cLitros 	:=	_cLitros + Replicate( "X.", (70 - Len(_cLitros)) / 2 )
				oPrint:Say(_nLinha, _nColCab3, _cLitros, _oFCabec)	//imprime o número de litros por extenso
			Else
				oPrint:Say(_nLinha, _nColCab3, Left(_cLitros, 70), _oFCabec)	//imprime o número de litros por extenso
				_nLinha	+=	(_nLinInc / 2)
				_cLitros	:=	Substr(_cLitros, 71, Len(_cLitros) - 110)
				_cLitros 	:=	_cLitros + Replicate( "X.", (110 - Len(_cLitros)) / 2 )
				oPrint:Say(_nLinha, _nColNor01, Left(_cLitros, 110), _oFCabec)
			Endif
		Endif
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1600, 1650 )
		_Observacao(@oPrint, @_nLinha, _aSafras)	//imprime os dados da observação
//		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1800, 1850 )
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 1820, 1850 )
		_ProdAnl(@oPrint, @_nLinha)		//imprime os dados analíticos
		_nLinha	:=	_nLinIni + IIf( _bFormEsp, 2270, 2320 )
		oPrint:Say(_nLinha, _nColAnl01, AllTrim(SM0->M0_CIDENT) + ", " + DTOC(dDataBase), _oFCabec)	//imprime local e data
		oPrint:EndPage()
	Next
Endif

Return

//imprime os dados daobservação da Guia
Static Function _Observacao(oPrint, _nLinha, _aSafras)

Local	_aArea	:=	GetArea()
Local	_cTexto	:=	""
Local	_cMemo	:=	AllTrim( MSMM(SZQ->ZQ_CODOBS,,,,3) )
Local	_aTextos	:=	{}
Local	_nLinTxt	:=	0

_cTexto	+=	"OPERAÇÃO: " + AllTrim( FBuscaCpo("SX5" , 1, xFilial("SX5")+"Z8"+SZQ->ZQ_TPOPER, "X5_DESCRI") )
//
_cTexto	+=	" - SAFRA "
For _nLinTxt := 1 To Len(_aSafras)
	_cTexto	+=	_aSafras[_nLinTxt, 1] + "/"
Next
_cTexto	:=	Left(_cTexto, Len(_cTexto) - 1)                
//
_cTexto	:=	_cTexto + IIf( !Empty(_cMemo), " - OBSERVAÇÃO: " + _cMemo, "" )
_aTextos	:=	aclone ( U_QuebraTXT (_cTexto, 135) )
For _nLinTxt := 1 To IIf( Len(_aTextos) <= 1, Len(_aTextos), 2 )
	oPrint:Say(_nLinha, _nColNor01, _aTextos[_nLinTxt], _oFProdNor)
	_nLinha	+=	_nIncPrd
Next

RestArea(_aArea) 

Return

//imprime os dados de cada produto da guia
Static Function _ProdAnl(oPrint, _nLinha)

Local	_aArea	:=	GetArea()

DbSelectArea( "SZR" )
DbSetOrder(1)
DbSeek( xFilial("SZR") + SZQ->ZQ_NUMERO )
While !Eof() .and. (ZR_FILIAL+ZR_NUMERO == xFilial("SZR") + SZQ->ZQ_NUMERO)
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
RestArea(_aArea)

Return

//imprime os dados de cada produto da guia
Static Function _ProdNor(oPrint, _nLinha, _nLitros, _aSafras)

Local	_aArea	:=	GetArea()
Local	_cTexto	:=	""    
Local	_bDupLin	:=	.f.
Local	_nPos
local	_oSisd  := NIL

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
	oPrint:Say(_nLinha, _nColNor01, X3COMBO("ZR_EMBALAG", SZR->ZR_EMBALAG), _oFProdNor)
	oPrint:Say(_nLinha, _nColNor02, AllTrim( Transform(SZR->ZR_LITROS, "@E 999,999") ), _oFProdNor)
	//
	//oPrint:Say(_nLinha, _nColNor03, AllTrim( SB1->B1_PROD ), _oFProdNor)
	oPrint:Say(_nLinha, _nColNor03, AllTrim(sb5 -> b5_vatpsis), _oFProdNor)
//	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+SB1->B1_PROD, "X5_DESCRI") )
	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+sb5 -> b5_vatpsis, "X5_DESCRI") )
	If Len(_cTexto) > 12
		oPrint:Say(_nLinha, _nColNor04, Left(_cTexto, 12), _oFProdNor)
		oPrint:Say(_nLinha + _nIncPrd, _nColNor04, Substr(_cTexto, 13, 12), _oFProdNor)
		_bDupLin	:=	.t.
	Else
		oPrint:Say(_nLinha, _nColNor04, _cTexto, _oFProdNor)
	Endif
	//
	oPrint:Say(_nLinha, _nColNor05, AllTrim( SB1->B1_TPPROD ), _oFProdNor)
//	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"95"+SB1->B1_TPPROD, "X5_DESCRI") )
	_cTexto	:=	alltrim (x3combo ('B1_VACOR', sb1 -> b1_vacor))
	If Len(_cTexto) > 12
		oPrint:Say(_nLinha, _nColNor06, Left(_cTexto, 12), _oFProdNor)
		oPrint:Say(_nLinha + _nIncPrd, _nColNor06, Substr(_cTexto, 13, 12), _oFProdNor)
		_bDupLin	:=	.t.
	Else
		oPrint:Say(_nLinha, _nColNor06, _cTexto, _oFProdNor)
	Endif
	//
//	oPrint:Say(_nLinha, _nColNor07, AllTrim( SB1->B1_CLASPR ), _oFProdNor)
//	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"94"+SB1->B1_CLASPR, "X5_DESCRI") )
	oPrint:Say(_nLinha, _nColNor07, AllTrim( SB5->B5_vacpsis ), _oFProdNor)
	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"94"+SB5->B5_vacpsis, "X5_DESCRI") )
	If Len(_cTexto) > 16
		oPrint:Say(_nLinha, _nColNor08, Left(_cTexto, 16), _oFProdNor)
		oPrint:Say(_nLinha + _nIncPrd, _nColNor08, Substr(_cTexto, 17, 16), _oFProdNor)
		_bDupLin	:=	.t.
	Else
		oPrint:Say(_nLinha, _nColNor08, _cTexto, _oFProdNor)
	Endif
	//
//	oPrint:Say(_nLinha, _nColNor09, AllTrim( SB1->B1_ESPPRD ), _oFProdNor)
//	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"93"+SB1->B1_ESPPRD, "X5_DESCRI") )
	oPrint:Say(_nLinha, _nColNor09, AllTrim(sb5 -> b5_vaepsis), _oFProdNor)
	_cTexto	:=	AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"93"+sb5 -> b5_vaepsis, "X5_DESCRI") )
	If Len(_cTexto) > 15
		oPrint:Say(_nLinha, _nColNor10, Left(_cTexto, 15), _oFProdNor)
		oPrint:Say(_nLinha + _nIncPrd, _nColNor10, Substr(_cTexto, 16, 15), _oFProdNor)
		_bDupLin	:=	.t.
	Else
		oPrint:Say(_nLinha, _nColNor10, _cTexto, _oFProdNor)
	Endif
	//
//	oPrint:Say(_nLinha, _nColNor11, AllTrim (SB1->b1_varmaal), _oFProdNor)
	_oSisd := ClsSisd ():New (szr -> zr_produto, 'SB5', szr -> zr_filial)
	oPrint:Say(_nLinha, _nColNor11, _oSisd:CodSisd, _oFProdNor)
	_nLinha	+=	_nIncPrd 
	If _bDupLin
		_nLinha	+=	_nIncPrd 
	Endif
	_nLitros	+=	SZR->ZR_LITROS
	//atualiza os dados da safra
	_nPos	:=	ascan (_aSafras, {|x| x[1] == SZR->ZR_SAFRA})
	If _nPos <= 0
//		aadd( _aSafras, {SZR->ZR_SAFRA, AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+SB1->B1_PROD, "X5_DESCRI") ), nil, nil} )
		aadd( _aSafras, {SZR->ZR_SAFRA, AllTrim( FBuscaCpo("SX5", 1, xFilial("SX5")+"96"+sb5 -> b5_vatpsis, "X5_DESCRI") ), nil, nil} )
	Endif                              
	//
	DbSelectArea( "SZR" )
	DbSkip()
End
RestArea(_aArea)

Return

//imprime os dados do cabeçalho da produtora
Static Function _CabProd(oPrint, _nLinha, _cNotas)

Local	_aArea	:=	GetArea()
//Local	_cNotas	:=	_Notas()

oPrint:Say(_nLinha, _nColCab3, SM0->M0_NOMECOM, _oFCabec)
_nLinha	+=	_nLinInc
oPrint:Say(_nLinha, _nColCab1, AllTrim( GetMv("VA_INSCMA") ), _oFCabec)
oPrint:Say(_nLinha, _nColCab4, Transform(SM0->M0_CGC, "@R 99.999.999/9999-99"), _oFCabec)
If (Len(_cNotas) > 27) .and. (Len(_cNotas) <= 54)
	oPrint:Say(_nLinha - 030, _nColCab5, Left(_cNotas, 27), _oFNotas)
	oPrint:Say(_nLinha, _nColCab5, Substr(_cNotas, 29, 27), _oFNotas)
ElseIf Len(_cNotas) > 54
	oPrint:Say(_nLinha - 030, _nColCab5, Left(_cNotas, 27), _oFNotas)
	oPrint:Say(_nLinha, _nColCab5, Substr(_cNotas, 29, 27), _oFNotas)
	oPrint:Say(_nLinha + 030, _nColCab5, Substr(_cNotas, 57, 27), _oFNotas)
Else
	oPrint:Say(_nLinha, _nColCab5, Left(_cNotas, 27), _oFNotas)
Endif
_nLinha	+=	_nLinInc
oPrint:Say(_nLinha, _nColCab1, SM0->M0_ENDENT, _oFCabec)
oPrint:Say(_nLinha, _nColCab5, SM0->M0_ESTENT, _oFCabec)

RestArea(_aArea)

Return

//imprime os dados do cabeçalho da recebedora (cliente)
Static Function _CabReceb(oPrint, _nLinha, _sTipoNF)

Local	_aArea	:=	GetArea()


//if FBUSCACPO("SF2", 2, xFilial("SF2")+SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA + SZQ->ZQ_NF01 + SZQ->ZQ_SERIE01, "F2_TIPO") $ ('D|B')  // Fornecedor
if _sTipoNF $ 'BD'  // Fornecedor
   DbSelectArea( "SA2" )
   DbSetOrder(1)
   DbSeek( xFilial("SA2") + SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA )
   oPrint:Say(_nLinha, _nColCab3, SA2->A2_NOME, _oFCabec)
   _nLinha	+=	_nLinInc
   oPrint:Say(_nLinha, _nColCab1, SA2->A2_VAREGMA, _oFCabec)
   oPrint:Say(_nLinha, _nColCab4, Transform(SA2->A2_CGC, "@R 99.999.999/9999-99"), _oFCabec)
   _nLinha	+=	_nLinInc
   oPrint:Say(_nLinha, _nColCab1, SA2->A2_END, _oFCabec)
   oPrint:Say(_nLinha, _nColCab5, SA2->A2_EST, _oFCabec)

else  // Cliente
   DbSelectArea( "SA1" )
   DbSetOrder(1)
   DbSeek( xFilial("SA1") + SZQ->ZQ_CLIENTE + SZQ->ZQ_LOJA )
   oPrint:Say(_nLinha, _nColCab3, SA1->A1_NOME, _oFCabec)
   _nLinha	+=	_nLinInc
   oPrint:Say(_nLinha, _nColCab1, SA1->A1_VAREGMA, _oFCabec)
   oPrint:Say(_nLinha, _nColCab4, Transform(SA1->A1_CGC, "@R 99.999.999/9999-99"), _oFCabec)
   _nLinha	+=	_nLinInc
   oPrint:Say(_nLinha, _nColCab1, SA1->A1_END, _oFCabec)
   oPrint:Say(_nLinha, _nColCab5, SA1->A1_EST, _oFCabec)

endif                


RestArea(_aArea)

Return

//imprime os dados do cabeçalho da recebedora (cliente)
Static Function _CabTransp(oPrint, _nLinha)

Local	_aArea	:=	GetArea()

DbSelectArea( "SA4" )
DbSetOrder(1)
DbSeek( xFilial("SA4") + SZQ->ZQ_TRANSP )
oPrint:Say(_nLinha, _nColCab2, SA4->A4_NOME, _oFCabec)
oPrint:Say(_nLinha, _nColCab5, Left(SZQ->ZQ_PLACAS, 27), _oFCabec)
_nLinha	+=	_nLinInc
oPrint:Say(_nLinha, _nColCab1, SA4->A4_END, _oFCabec)
oPrint:Say(_nLinha, _nColCab5, SA4->A4_EST, _oFCabec)
_nLinha	+=	_nLinInc
oPrint:Say(_nLinha, _nColCab1, SA4->A4_MUN, _oFCabec)
oPrint:Say(_nLinha, _nColCab5, SA4->A4_TEL, _oFCabec)

RestArea(_aArea)

Return

//rotina que transforma em texto o numero das notas
Static Function _Notas(_sTipoNF)
Local	_cTexto	:=	""
Local	_aArea	:=	GetArea()
local _oSQL    := NIL
local _aRetQry := {}
 /*Local	_nF, _cNf

DbSelectArea( "SZQ" )
//For _nF := 1 To 10
For _nF := 1 To 15
	_cNf	:=	StrZero(_nF, 2)
	If !Empty( SZQ->&("ZQ_NF"+_cNf) )
		_cTexto	+=	AllTrim( SZQ->&("ZQ_NF"+_cNf) ) + ","
	Else
		Exit
	Endif
Next _nF
RestArea(_aArea)
If Len(_cTexto) > 0
	_cTexto	:=	Left(_cTexto, Len(_cTexto) - 1)
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


// Cria Perguntas no SX1
Static Function _ValidPerg (cPerg)

local _aRegsPerg := {}

//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                  Help
aadd (_aRegsPerg, {01, "Informe o Número do Laborat.: ", "C", TAMSX3("ZQ_NUMLAB")[1], 0,  "",   "   ", {},                                     ""})
U_ValPerg (cPerg, _aRegsPerg)

Return
