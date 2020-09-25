#include "rwmake.ch"
#include "totvs.ch"
#include "protheus.ch"
#include "report.ch"

// Programa...: VA_RASTCRG
// Autor......: Leandro DWT
// Data.......: 08/04/2014
// Cliente....: Nova Alianca
// Descricao..: Rastreamento de cargas, com informações dos pedidos e de todos movimentos envolvidos
//
// Historico de alteracoes:
//

User Function VA_RASTCRG()

Local oReport
Local oSA1
Local oBreak
Local oSection1
Local z := 1

cPerg   := "VA_RASTCRG"
_ValidPerg()

If TRepInUse()
	Pergunte(cPerg,.F.)
	oReport := ReportDef()
	oReport:PrintDialog()
EndIf

return


// ************************************************************
// função para definições do relatório (cabeçalho, quebras, etc)
Static Function ReportDef()

Local oReport
Local oSection1
Local oBreak

oReport := TReport():New("VA_RASTCRG","Rastreamento de carga","VA_RASTCRG",{|oReport| PrintReport(oReport)},"Rastreamento de carga")
oReport:SetPortrait()

oSection1 := TRSection():New(oReport,"Rastreamento de carga",{"DAK","DAI","SD3","SDB","DCF","SD2"},,,,,.F.)

TRCell():New(oSection1,"VA_CARGA"		,"","Carga"		,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,1]} ,"LEFT" ,,,,,,,,)
TRCell():New(oSection1,"VA_PEDIDO"		,"","Pedido"	,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,2]} ,"LEFT" ,,,,,,,,)
TRCell():New(oSection1,"VA_PRODUTO"		,"","Produto"	,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,3]} ,"LEFT" ,,,,,,,,)
TRCell():New(oSection1,"VA_DESCRICAO"	,"","Descri"	,/*Picture*/			,30,/*lPixel*/,	{|| aImp[z,4]} ,"LEFT" ,,,,,,,,)
TRCell():New(oSection1,"VA_QUANT"		,"","Quant"		,"@E 999,999,999.9999"	,15,/*lPixel*/,	{|| aImp[z,5]} ,"RIGHT" ,,,,,,,,)
TRCell():New(oSection1,"VA_LOTE"		,"","Lote"		,/*Picture*/	    	,15,/*lPixel*/,	{|| aImp[z,6]} ,"RIGHT",,,,,,,,)
TRCell():New(oSection1,"VA_DATA"		,"","Data"		,/*Picture*/			,10,/*lPixel*/,	{|| aImp[z,7]} ,"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_ENDEREÇO"	,"","Endereco"	,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,8]} ,"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_DESTINO"		,"","Destino"	,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,9]} ,"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_CLIENTE"		,"","Cliente"	,/*Picture*/			,06,/*lPixel*/,	{|| aImp[z,10]},"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_LOJA"		,"","Loja"		,/*Picture*/			,02,/*lPixel*/,	{|| aImp[z,11]},"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_NOME"		,"","Nome"		,/*Picture*/			,30,/*lPixel*/,	{|| aImp[z,12]},"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_NOTA"		,"","Nota"		,/*Picture*/			,30,/*lPixel*/,	{|| aImp[z,13]},"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_SERIE"		,"","Serie"		,/*Picture*/			,30,/*lPixel*/,	{|| aImp[z,14]},"LEFT",,,,,,,,)
TRCell():New(oSection1,"VA_OPERADOR"	,"","Operador"	,/*Picture*/			,15,/*lPixel*/,	{|| aImp[z,15]},"LEFT" ,,,,,,,,)
TRCell():New(oSection1,"VA_TABELA"		,"","Tabela"	,/*Picture*/			,03,/*lPixel*/,	{|| aImp[z,16]},"LEFT" ,,,,,,,,)

Return oReport


// ************************************************************
// função para buscas informações e adicionar nos arrays
Static Function PrintReport(oReport)

Local cAliasDAI := GetNextAlias()
local _sAliasQ  := ""
Local _aArray 	:= {}
Local _i		:= 0
Local nI		:= 0
Local z 		:= 1
_aItens := {}
_aImp   := {}
_aNotas := {}
_aDocs	:= {}
_aPeds  := {}

oSection1 := oReport:Section(1)
MakeSqlExp("VA_RASTCRG")

_sQuery := "SELECT DISTINCT(DAI_COD) "
_sQuery += " FROM DAI010 "
_sQuery += " WHERE DAI010.D_E_L_E_T_ = '' "
_sQuery += " AND DAI_COD >= '" + MV_PAR01 + "' "
_sQuery += " AND DAI_COD <= '" + MV_PAR02 + "' "
_sQuery += " AND DAI_PEDIDO >= '" + MV_PAR03 + "' "
_sQuery += " AND DAI_PEDIDO <= '" + MV_PAR04 + "' "
_sQuery += " AND DAI_PEDIDO IN (SELECT DISTINCT(C6_NUM) "
_sQuery += " 					FROM SC6010 "
_sQuery += " 					WHERE SC6010.D_E_L_E_T_ = '' "
_sQuery += " 					AND C6_PRODUTO >= '" + MV_PAR05 + "' "
_sQuery += " 					AND C6_PRODUTO <= '" + MV_PAR06 + "' )"
_sQuery += " ORDER BY DAI_COD "

_sAliasQ = GetNextAlias ()
DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "cAliasDAI", .f., .t.)

dbSelectArea("cAliasDAI")
dbgotop()
While !Eof()
	
	// ********************************************************************************
	// adiciona registros da DAI
	_sQuery := " SELECT * "
	_sQuery += " FROM DAI010 "
	_sQuery += " WHERE D_E_L_E_T_ = '' "
	_sQuery += " AND DAI_COD = '" + ("cAliasDAI")->DAI_COD  + "' "
	_sQuery += " ORDER BY DAI_COD "
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "TRB1", .f., .t.)
	
	While !EoF()
		
		aadd(_aItens, ("TRB1")->DAI_COD)
		aadd(_aItens, ("TRB1")->DAI_PEDIDO)
		aadd(_aItens, '')
		aadd(_aItens, '')
		aadd(_aItens, ("TRB1")->DAI_PESO)
		aadd(_aItens, '')
		aadd(_aItens, ("TRB1")->DAI_DATA)
		aadd(_aItens, '')
		aadd(_aItens, '')
		aadd(_aItens, ("TRB1")->DAI_CLIENT)
		aadd(_aItens, ("TRB1")->DAI_LOJA)
		aadd(_aItens, Posicione("SA1",1,xFilial("SA1") + ("TRB1")->DAI_CLIENT + ("TRB1")->DAI_LOJA,"A1_NREDUZ"))
		aadd(_aItens, ("TRB1")->DAI_NFISCA)
		aadd(_aItens, ("TRB1")->DAI_SERIE)
		aadd(_aItens, '')
		aadd(_aItens, 'DAI')
		
		aadd(_aImp, _aItens)
		_aItens := {}
		
		aadd(_aNotas, {("TRB1")->DAI_COD, ("TRB1")->DAI_NFISCA, ("TRB1")->DAI_SERIE})
		
		dbselectarea("TRB1")
		dbskip()
	enddo
	
	dbselectarea("TRB1")
	dbclosearea()
	
	
	// ********************************************************************************
	// adiciona registros da SDB
	_sQuery := " SELECT * "
	_sQuery += " FROM SDB010 "
	_sQuery += " WHERE D_E_L_E_T_ = '' "
	_sQuery += " AND DB_CARGA = '" + ("cAliasDAI")->DAI_COD  + "' "
	_sQuery += " AND DB_ESTORNO <> 'S' "
	_sQuery += " ORDER BY DB_CARGA "
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "TRB2", .f., .t.)
	
	While !EoF()
		
		aadd(_aItens, ("TRB2")->DB_CARGA)
		aadd(_aItens, '')
		aadd(_aItens, ("TRB2")->DB_PRODUTO)
		aadd(_aItens, Posicione("SB1",1,xFilial("SB1") + ("TRB2")->DB_PRODUTO,"B1_DESC"))
		aadd(_aItens, ("TRB2")->DB_QUANT)
		aadd(_aItens, ("TRB2")->DB_LOTECTL)
		aadd(_aItens, ("TRB2")->DB_DATA)
		aadd(_aItens, ("TRB2")->DB_LOCALIZ)
		aadd(_aItens, '')
		aadd(_aItens, ("TRB2")->DB_CLIFOR)
		aadd(_aItens, ("TRB2")->DB_LOJA)
		aadd(_aItens, Posicione("SA1",1,xFilial("SA1") + ("TRB2")->DB_CLIFOR + ("TRB2")->DB_LOJA,"A1_NREDUZ"))
		aadd(_aItens, '')
		aadd(_aItens, '')
		aadd(_aItens, ("TRB2")->DB_IDOPERA)
		aadd(_aItens, 'SDB')
		
		aadd(_aImp, _aItens)
		
		dbselectarea("TRB2")
		dbskip()
	enddo
	
	dbselectarea("TRB2")
	dbclosearea()
	
	
	// ********************************************************************************
	// adiciona registros da DCF
	_sQuery := " SELECT * "
	_sQuery += " FROM DCF010 "
	_sQuery += " WHERE D_E_L_E_T_ = '' "
	_sQuery += " AND DCF_CARGA = '" + ("cAliasDAI")->DAI_COD  + "' "
	_sQuery += " ORDER BY DCF_CARGA "
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "TRB3", .f., .t.)
	
	While !EoF()
		
		aadd(_aItens, ("TRB3")->DCF_CARGA)
		aadd(_aItens, '')
		aadd(_aItens, ("TRB3")->DCF_CODPRO)
		aadd(_aItens, Posicione("SB1",1,xFilial("SB1") + ("TRB3")->DCF_CODPRO,"B1_DESC"))
		aadd(_aItens, ("TRB3")->DCF_QUANT)
		aadd(_aItens, ("TRB3")->DCF_LOTECT)
		aadd(_aItens, ("TRB3")->DCF_DATA)
		aadd(_aItens, ("TRB3")->DCF_ENDER)
		aadd(_aItens, '')
		aadd(_aItens, ("TRB3")->DCF_CLIFOR)
		aadd(_aItens, ("TRB3")->DCF_LOJA)
		aadd(_aItens, Posicione("SA1",1,xFilial("SA1") + ("TRB3")->DCF_CLIFOR + ("TRB3")->DCF_LOJA,"A1_NREDUZ"))
		aadd(_aItens, ("TRB3")->DCF_DOCTO)
		aadd(_aItens, ("TRB3")->DCF_SERIE)
		aadd(_aItens, '')
		aadd(_aItens, 'DCF')
		
		aadd(_aImp, _aItens)
		_aItens := {}
		
		dbselectarea("TRB3")
		dbskip()
	enddo
	
	dbselectarea("TRB3")
	dbclosearea()
	
	
	// ********************************************************************************
	// adiciona registros da SD3
	
	// primeiro verifica o numero dos documentos no SDB
	_sQuery := " SELECT DISTINCT(DB_DOC) "
	_sQuery += " FROM SDB010 "
	_sQuery += " WHERE D_E_L_E_T_ = '' "
	_sQuery += " AND DB_CARGA = '" + ("cAliasDAI")->DAI_COD  + "' "
	_sQuery += " AND DB_ESTORNO <> 'S' "
	_sQuery += " ORDER BY DB_DOC "
	
	
	_aDocs := U_Qry2Array(_sQuery)
	
	If len(_aDocs) > 0
		
		For _i = 1 to len(_aDocs)
			
			if alltrim(_aNotas[_i][1]) == alltrim(("cAliasDAI")->DAI_COD)
				
				_sQuery := " SELECT * "
				_sQuery += " FROM SD3010 "
				_sQuery += " WHERE D_E_L_E_T_ = '' "
				_sQuery += " AND D3_DOC = '" + _aDocs[_i][1]  + "' "
				_sQuery += " AND D3_FILIAL = '13' "
				_sQuery += " ORDER BY D3_DOC "
				
				_sAliasQ = GetNextAlias ()
				DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "TRB4", .f., .t.)
				
				While !EoF()
					
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, ("TRB4")->D3_COD)
					aadd(_aItens, Posicione("SB1",1,xFilial("SB1") + ("TRB4")->D3_COD,"B1_DESC"))
					aadd(_aItens, ("TRB4")->D3_QUANT)
					aadd(_aItens, ("TRB4")->D3_LOTECTL)
					aadd(_aItens, ("TRB4")->D3_EMISSAO)
					aadd(_aItens, ("TRB4")->D3_LOCALIZ)
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, '')
					aadd(_aItens, ("TRB4")->D3_USUARIO)
					aadd(_aItens, 'SD3')
					
					aadd(_aImp, _aItens)
					_aItens := {}
					
					dbselectarea("TRB4")
					dbskip()
				enddo
				
				dbselectarea("TRB4")
				dbclosearea()
			endif
		next _i
	endif
	
	
	// ********************************************************************************
	// adiciona registros da SD2
	
	// Primeiro verifica os pedidos relacionados
	_sQuery := "SELECT DISTINCT(DAI_PEDIDO) "
	_sQuery += " FROM DAI010 "
	_sQuery += " WHERE DAI010.D_E_L_E_T_ = '' "
	_sQuery += " AND DAI_COD = '" + ("cAliasDAI")->DAI_COD + "' "
	_sQuery += " AND DAI_PEDIDO >= '" + MV_PAR03 + "' "
	_sQuery += " AND DAI_PEDIDO <= '" + MV_PAR04 + "' "
	_sQuery += " AND DAI_PEDIDO IN (SELECT DISTINCT(C6_NUM) "
	_sQuery += " 					FROM SC6010 "
	_sQuery += " 					WHERE SC6010.D_E_L_E_T_ = '' "
	_sQuery += " 					AND C6_PRODUTO >= '" + MV_PAR05 + "' "
	_sQuery += " 					AND C6_PRODUTO <= '" + MV_PAR06 + "' )"
	_sQuery += " ORDER BY DAI_PEDIDO "
	
	_aPeds := U_Qry2Array(_sQuery)
	
	If len(_aPeds) > 0
		
		For _i = 1 to len(_aPeds)
			
			_sQuery := " SELECT * "
			_sQuery += " FROM SD2010 "
			_sQuery += " WHERE D_E_L_E_T_ = '' "
			_sQuery += " AND D2_PEDIDO = '" + _aPeds[_i][1]  + "' "
			_sQuery += " AND D2_FILIAL = '13' "
			_sQuery += " ORDER BY D2_DOC "
			
			_sAliasQ = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "TRB5", .f., .t.)
			
			dbselectarea("TRB5")
			dbgotop()
			While !EoF()
				
				aadd(_aItens, '')
				aadd(_aItens, ("TRB5")->D2_PEDIDO)
				aadd(_aItens, ("TRB5")->D2_COD)
				aadd(_aItens, Posicione("SB1",1,xFilial("SB1") + ("TRB5")->D2_COD,"B1_DESC"))
				aadd(_aItens, ("TRB5")->D2_QUANT)
				aadd(_aItens, ("TRB5")->D2_LOTECTL)
				aadd(_aItens, ("TRB5")->D2_EMISSAO)
				aadd(_aItens, '')
				aadd(_aItens, '')
				aadd(_aItens, ("TRB5")->D2_CLIENTE)
				aadd(_aItens, ("TRB5")->D2_LOJA)
				aadd(_aItens, Posicione("SA1",1,xFilial("SA1") + ("TRB5")->D2_CLIENTE + ("TRB5")->D2_LOJA,"A1_NREDUZ"))
				aadd(_aItens, ("TRB5")->D2_DOC)
				aadd(_aItens, ("TRB5")->D2_SERIE)
				aadd(_aItens, '')
				aadd(_aItens, 'SD2')
				
				aadd(_aImp, _aItens)
				_aItens := {}
				
				dbselectarea("TRB5")
				dbskip()
			enddo
			
			dbselectarea("TRB5")
			dbclosearea()
		next _i
	endif
	
	dbselectarea("cAliasDAI")
	dbskip()
	
enddo

For z := 1 To Len(_aImp)
	oSection1:Cell("VA_CARGA")		:SetBlock({|| _aImp[z,1] })
	oSection1:Cell("VA_PEDIDO")		:SetBlock({|| _aImp[z,2] })
	oSection1:Cell("VA_PRODUTO")	:SetBlock({|| _aImp[z,3] })
	oSection1:Cell("VA_DESCRICAO")	:SetBlock({|| _aImp[z,4] })
	oSection1:Cell("VA_QUANT")		:SetBlock({|| _aImp[z,5] })
	oSection1:Cell("VA_LOTE")		:SetBlock({|| _aImp[z,6] })
	oSection1:Cell("VA_DATA")		:SetBlock({|| _aImp[z,7] })
	oSection1:Cell("VA_ENDEREÇO")	:SetBlock({|| _aImp[z,8] })
	oSection1:Cell("VA_DESTINO")	:SetBlock({|| _aImp[z,9] })
	oSection1:Cell("VA_CLIENTE")	:SetBlock({|| _aImp[z,10] })
	oSection1:Cell("VA_LOJA")		:SetBlock({|| _aImp[z,11] })
	oSection1:Cell("VA_NOME")		:SetBlock({|| _aImp[z,12] })
	oSection1:Cell("VA_NOTA")		:SetBlock({|| _aImp[z,13] })
	oSection1:Cell("VA_SERIE")		:SetBlock({|| _aImp[z,14] })
	oSection1:Cell("VA_OPERADOR")	:SetBlock({|| _aImp[z,15] })
	oSection1:Cell("VA_TABELA")		:SetBlock({|| _aImp[z,16] })
next

For nI := 1 To Len(_aImp)
	z := nI
	oReport:Section(1):SetHeaderBreak(.T.)
	oReport:Section(1):Init()
	oReport:Section(1):PrintLine()
Next
oReport:Section(1):SetHeaderBreak(.T.)
oReport:Section(1):Finish()

dbselectarea("cAliasDAI")
dbclosearea()

Return

// ************************************************************
// função para as perguntas
Static Function _ValidPerg ()
local _aRegsPerg := {}
//                     PERGUNT              	TIPO TAM DEC VALID F3     Opcoes                        Help
aadd (_aRegsPerg, {01, "Carga de             ?", "C", 06, 0,  "",   "DAK", {},                           ""})
aadd (_aRegsPerg, {02, "Carga ate            ?", "C", 06, 0,  "",   "DAK", {},                           ""})
aadd (_aRegsPerg, {03, "Pedido de            ?", "C", 06, 0,  "",   "SC5", {},                           ""})
aadd (_aRegsPerg, {04, "Pedido ate           ?", "C", 06, 0,  "",   "SC5", {},                           ""})
aadd (_aRegsPerg, {05, "Produto de           ?", "C", 06, 0,  "",   "SB1", {},                           ""})
aadd (_aRegsPerg, {06, "Produto ate          ?", "C", 06, 0,  "",   "SB1", {},                           ""})
U_ValPerg (cPerg, _aRegsPerg)
Return