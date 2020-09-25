/////////////////////////////////////////////////////////////////////////////////////////////////
// Relatório Referencial de Custos - Júlio Pedroni                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Historico de alteracoes:
//

// -------------------------------------------------------------------------
User Function VA_RELZAH()
	Local oReport
	private cPerg    := "VA_RELZAH"

	_ValidPerg()
	If TRepInUse()
		Pergunte(cPerg, .F.)
		oReport := ReportDef()
		oReport:PrintDialog()
	EndIf
Return

// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport
	Local _oSec1 := NIL
	Local _oSec2 := NIL
	Local oBreak := NIL
	Local cTitulo := "Referencial de Custos"

	oReport := TReport():New(cPerg,cTitulo,cPerg,{|oReport| PrintReport(oReport)},cTitulo)
	oReport:SetLandScape()
	oReport:SetTotalInLine(.F.)
	oReport:nfontbody := 8

	//Secao 1 (Quebra Principal: Celula)
	_oSec1 := TRSection():New (oReport, "CELULA", {"ZAH"}, , .F., .T.)
	//_oSec1:SetTotalInLine(.F.)
	TRCell():New(_oSec1,"ZAH_CELCOD", "_trb", "CELULA"     ,"@!",6)
	TRCell():New(_oSec1,"ZAH_CELDES", "_trb", "DESCRICAO"  ,"@!",40)
	TRCell():New(_oSec1,"ZAH_CENCUS", "_trb", "C.CUSTO"    ,"@!",6)
	TRCell():New(_oSec1,"ZAH_CENDES", "_trb", "DESCRICAO"  ,"@!",40)
	TRCell():New(_oSec1,"ZAH_PRONOM", "_trb", "PROD. NOM." ,"@!",10)
	_oSec1:SetPageBreak(.T.) //Quebra pagina no final da secao.

	//Secao 2 (Quebra Secundaria: Ativo/Maquina)
	_oSec2 := TRSection():New(oReport, "MAQUINA", {"ZAH"})
	//_oSec2:SetTotalInLine(.F.)
	TRCell():New(_oSec2, "ZAH_CELCOD", "", ""         , /*Picture*/      , 00, /*lPixel*/, {||  	}, ""    ,  ,,,,,,, .T.)
	TRCell():New(_oSec2, "ZAH_SEQMAQ", "", "Seq."     , /*Picture*/      , 04, /*lPixel*/, {||  	}, "LEFT",  ,,,,,,, .T.)
	TRCell():New(_oSec2, "ZAH_BEMCOD", "", "Maquina"  , /*Picture*/      , 10, /*lPixel*/, {||  	}, "LEFT",  ,,,,,,, .T.)
	TRCell():New(_oSec2, "ZAH_BEMDES", "", "Descricao", /*Picture*/      , 60, /*lPixel*/, {||  	}, "LEFT",  ,,,,,,, .T.)
	TRCell():New(_oSec2, "LINHA_PREV", "", "Previsto" , "@E 9,999,999.9" , 12, /*lPixel*/, {||  	}, "RIGHT", ,"RIGHT",,,,,,.T.)
	TRCell():New(_oSec2, "LINHA_REAL", "", "Realizado", "@E 9,999,999.9" , 12, /*lPixel*/, {||  	}, "RIGHT", ,"RIGHT",,,,,,.T.)
	TRCell():New(_oSec2, "LINHA_DIFE", "", "Diferenca", "@E 9,999,999.9" , 12, /*lPixel*/, {||  	}, "RIGHT", ,"RIGHT",,,,,,.T.)
	
	// Totalizacao na secao 2
	oBreak := TRBreak():New(_oSec2,_oSec2:Cell("ZAH_CELCOD"),"Totais da Celula")
	TRFunction():New(_oSec2:Cell("LINHA_PREV")	,,"SUM"	,oBreak,"Total Previsto ", "@E 99,999,999.9", NIL, .F., .T.)
	TRFunction():New(_oSec2:Cell("LINHA_REAL")  ,,"SUM"	,oBreak,"Total Realizado", "@E 99,999,999.9", NIL, .F., .T.)
	TRFunction():New(_oSec2:Cell("LINHA_DIFE")	,,"SUM"	,oBreak,"Total Diferenca", "@E 99,999,999.9", NIL, .F., .T.)
	
Return oReport

// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	local _oSec1 := oReport:Section(1)
	local _oSec2 := oReport:Section(2)
	//local _oSec3 := oReport:Section(3)
	local _sQuery := ""

	_sQuery := " select" 
	_sQuery += "     ZAH_CELCOD,"
	_sQuery += "     ZAH_CELDES,"
	_sQuery += "     ZAH_CENCUS,"
	_sQuery += "     CTT_DESC01 as ZAH_CENDES,"
	_sQuery += "     ZAH_PRONOM,"
	_sQuery += "     ZAH_SEQMAQ,"
	_sQuery += "     ZAH_BEMCOD,"
	_sQuery += "     N1_DESCRIC as ZAH_BEMDES"
	_sQuery += " from"
	_sQuery += "     " + RetSQLName("ZAH") + " ZAH,"
	_sQuery += "     " + RetSQLName("CTT") + " CTT,"
	_sQuery += "     " + RetSQLName("SN1") + " SN1"
	_sQuery += " where" 
	_sQuery += "     ZAH.D_E_L_E_T_ = '' and"
	_sQuery += "     CTT.D_E_L_E_T_ = '' and"
	_sQuery += "     SN1.D_E_L_E_T_ = '' and"
	_sQuery += "     ZAH_CENCUS = CTT_CUSTO and"
	_sQuery += "     ZAH_BEMCOD = N1_CBASE  and"
	_sQuery += "     LTRIM(RTRIM(N1_ITEM)) = '0'"
	_sQuery += " order by" 
	_sQuery += "     ZAH_CELCOD," 
	_sQuery += "     ZAH_SEQMAQ"
	
	//U_Log(_sQuery)
	
	DbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery) , "_trb", .F., .T.)
	DbSelectArea("_trb")

	oFont10 := TFont():New("Arial",,10,,.f.,,,,,.f.)
	oReport:SetMeter(LastRec("_trb"))
	oReport:Say(oReport:Row(), 10, "", oFont10)
	oReport:Say(oReport:Row(), 10, "Mes/Ano de Referencia: " + AllTrim(mv_par01) + "/"     + AllTrim(mv_par02) + " - Celula de Producao: "    + AllTrim(mv_par03) + " ate " + AllTrim(mv_par04), oFont10)

	do while ! _trb -> (EOF())
		_sLinha = _trb -> ZAH_CELCOD
		
		//Imprimir a primeira seção
		_oSec1:Init()
		_oSec1:Cell("ZAH_CELCOD"):SetValue(_trb -> ZAH_CELCOD)
		_oSec1:Cell("ZAH_CELDES"):SetValue(_trb -> ZAH_CELDES)
		_oSec1:Cell("ZAH_CENCUS"):SetValue(_trb -> ZAH_CENCUS)
		_oSec1:Cell("ZAH_CENDES"):SetValue(_trb -> ZAH_CENDES)
		_oSec1:Cell("ZAH_PRONOM"):SetValue(_trb -> ZAH_PRONOM)
		_oSec1:Printline()
		oReport:SkipLine()
		oReport:ThinLine()

		_oSec2:Init()
		do while ! _trb -> (EOF()) .and. _sLinha == _trb -> ZAH_CELCOD
			oReport:IncMeter()
	
			If oReport:Cancel()
				MsgAlert("Operacao cancelada pelo usuario.")
				Exit
			End
		
			_oSec2:Cell("ZAH_SEQMAQ"):SetBlock({||_trb -> ZAH_SEQMAQ})
			_oSec2:Cell("ZAH_BEMCOD"):SetBlock({||_trb -> ZAH_BEMCOD})
			_oSec2:Cell("ZAH_BEMDES"):SetBlock({||_trb -> ZAH_BEMDES})
			_oSec2:Cell("LINHA_PREV"):SetBlock({||1})
			_oSec2:Cell("LINHA_REAL"):SetBlock({||2})
			_oSec2:Cell("LINHA_DIFE"):SetBlock({||3})
			_oSec2:PrintLine()

			_trb -> (dbSkip())
		EndDo
		_oSec2:Finish()
		_oSec1:Finish()
	enddo

	DbSelectArea("_trb")
	dbCloseArea()
Return

// -------------------------------------------------------------------------
Static Function _ValidPerg()
	local _aRegsPerg := {}
	
	//                     PERGUNT                         TIPO TAM DEC VALID F3       OPCOES                      HELP   
	aadd (_aRegsPerg, {01, "Mes de Referencia ?         ", "C", 02, 0,  "U_VALPARREL(mv_par01, mv_par01, 'Mes', 'MES', .T.)", "     ", {}, ""})
	aadd (_aRegsPerg, {02, "Ano de Referencia ?         ", "C", 04, 0,  "U_VALPARREL(mv_par02, mv_par02, 'Ano', 'ANO', .T.)", "     ", {}, ""})
	aadd (_aRegsPerg, {03, "Celula de Producao inicial ?", "C", 04, 0,  "", "ZAH02", {}, ""})
	aadd (_aRegsPerg, {04, "Celula de Producao final ?  ", "C", 04, 0,  "U_VALPARREL(mv_par03, mv_par04, 'Celula', 'INTERVALO', .T.)", "ZAH02", {}, ""})
	aadd (_aRegsPerg, {05, "Tipo de Impressao ?         ", "N", 01, 0,  "",   "     ", {"Sintetico", "Analitico"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
