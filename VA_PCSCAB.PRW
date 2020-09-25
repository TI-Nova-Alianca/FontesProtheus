/////////////////////////////////////////////////////////////////////////////////////////////////
// Solicitações e Pedidos de Compra x Produto - 20/05/2014 - Bruno Silva                       //
/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Historico de alteracoes:
// 29/06/2015 - Robert - Unificadas queries do SC1 e SC7
//                     - Eliminadas linhas em branco
//                     - Incluida coluna com tipo (firme/prevista)
//                     - Incluida coluna com data limite (cfe. MATR100)
//

/////////////////////////////////////////////////// FUNÇÃO PRINCIPAL
User Function VA_PCSCAB()

	Local oReport
	Local oSection1
	Local oSection2
	Local oSection3
	Local oBreak
	Private cPerg := "VA_PCSCAB"
//	private _sArqLog := U_NomeLog ()

	If TRepInUse()
	
		_validPerg()
		Pergunte("VA_PCSCAB",.F.)
		oReport := ReportDef()
		oReport:PrintDialog()
	else
		u_help ("Relatorio disponivel apenas na versao 'personalizavel'.")	
	EndIf

Return



/////////////////////////////////////////////////// DEFINIÇÃO
Static Function ReportDef()

	Local oReport
	Local oSection1
	Local cTitulo := "Solicitações e Pedidos de Compra x Produto"

	oReport := TReport():New("VA_PCSCAB",cTitulo,"VA_PCSCAB",{|oReport| PrintReport(oReport)}, cTitulo)
	oReport:SetLandScape()//Portrait()
	oReport:SetTotalInLine(.T.)
	oReport:lHeaderVisible := .T.

	oSection1 := TRSection():New(oReport,"Produtos",{"SB1"})
	oSection1:SetHeaderPage()
	oSection1:SetTotalInLine(.F.)

	//           oParent   cName          cAlias cTitle         cPict             nSize lPixel bBlock cAlign lLineBreak cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold
	TRCell():New(oSection1,"PRODUTO",     "",    "Produto"      ,NIL,             15,   NIL,   {|| }, "LEFT",,"LEFT",,,,,,.T.)
	TRCell():New(oSection1,"DESCRICAO",   "",    "Descrição"    ,NIL,             60,   NIL,   {|| }, "LEFT",,"LEFT",,,,,,.T.)
	TRCell():New(oSection1,"TIPO",        "",    "Tipo"         ,NIL,              2,   NIL,   {|| }, "LEFT",,"LEFT",,,,,,.T.)
	TRCell():New(oSection1,"UN_MEDIDA",   "",    "UM"           ,NIL,              2,   NIL,   {|| }, "LEFT",,"LEFT",,,,,,.T.)
	TRCell():New(oSection1,"FIRME_PREV",  "",    "Tipo"         ,NIL,              5,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"NUM",         "",    "Numero"       ,NIL,              6,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"ITEM",        "",    "Item"         ,NIL,              4,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"FORNECE",     "",    "Fornec."      ,NIL,              6,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"QUANT",       "",    "Quant."       ,"@E 999,999.99", 15,   NIL,   {|| }, "RIGHT",,'RIGHT',,,,,,.T.)
	TRCell():New(oSection1,"EMISSAO",     "",    "Emissão"      ,NIL,             10,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"ENTREGA",     "",    "Entrega"      ,NIL,             10,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"DT_LIMITE",   "",    "Dt.limite"    ,NIL,             10,   NIL,   {|| }, "LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"SOLICITANTE", "",    "Solicitante"  ,NIL,             15,   NIL,   {|| }, "LEFT",,"LEFT",,,,,,.T.)
	TRCell():New(oSection1,"QT_ENTREGUE", "",    "Qt.entregue"  ,"@E 999,999.99", 15,   NIL,   {|| }, "RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"SALDO",       "",    "Qt.a receber" ,"@E 999,999.99", 15,   NIL,   {|| }, "RIGHT",,"RIGHT",,,,,,.T.)
Return oReport


///////////////////////////////////////////////// IMPRESSAO
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(1):Section(1)
	local _oSQL     := ClsSQL ():New ()
	local _sAliasQ  := ""
	local _sProduto := ""

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery +=      " SELECT SC7.C7_PRODUTO AS PRODUTO, RTRIM (SB1.B1_DESC) AS DESCRICAO, SB1.B1_TIPO AS TIPO,"
	_oSQL:_sQuery +=             " CASE SC7.C7_UM WHEN '' THEN SB1.B1_UM ELSE SC7.C7_UM END AS UM,"
	_oSQL:_sQuery +=             " CASE WHEN SC7.C7_TPOP IN (' ', 'F') THEN 'FIRME' ELSE 'PREV' END AS FIRME_PREV,"
	_oSQL:_sQuery +=             " SC7.C7_NUM AS NUM, SC7.C7_ITEM AS ITEM, SC7.C7_FORNECE AS FORNECE,"
	_oSQL:_sQuery +=             " SC7.C7_QUANT AS QUANT, SC7.C7_EMISSAO AS EMISSAO, SC7.C7_DATPRF AS ENTREGA,"
	_oSQL:_sQuery +=             " (SELECT TOP 1 C1_SOLICIT
	_oSQL:_sQuery +=                " FROM " + RetSqlName ("SC1") + " SC1"
	_oSQL:_sQuery +=               " WHERE SC1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=                 " AND SC1.C1_FILIAL   = SC7.C7_FILIAL"
	_oSQL:_sQuery +=                 " AND SC1.C1_NUM      = SC7.C7_NUMSC"
	_oSQL:_sQuery +=                 " AND SC1.C1_ITEM     = SC7.C7_ITEMSC"
	_oSQL:_sQuery +=              " ) AS SOLICITANTE,"
	_oSQL:_sQuery +=             " SC7.C7_QUJE AS QT_ENTREGUE, SC7.C7_QUANT - SC7.C7_QUJE AS SALDO"
	_oSQL:_sQuery +=        " FROM " + RetSqlName ("SC7") + " SC7,"
	_oSQL:_sQuery +=                   RetSqlName ("SB1") + " SB1"
	_oSQL:_sQuery +=       " WHERE SC7.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=         " AND SC7.C7_FILIAL  = '" + xFilial ("SC7") + "'"
	_oSQL:_sQuery +=         " AND SC7.C7_PRODUTO BETWEEN '" + mv_par01 +"' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=         " AND SC7.C7_DATPRF  BETWEEN '" + dtos (MV_PAR05) + "' AND '" + dtos (MV_PAR06) + "'"
	_oSQL:_sQuery +=         " AND SC7.C7_QUANT   > SC7.C7_QUJE"
	_oSQL:_sQuery +=         " AND SC7.C7_RESIDUO != 'S'"
	if mv_par07 == 1
		_oSQL:_sQuery +=     " AND SC7.C7_TPOP IN ('F', ' ')"
	elseif mv_par07 == 2
		_oSQL:_sQuery +=     " AND SC7.C7_TPOP NOT IN ('F', ' ')"
	endif
	_oSQL:_sQuery +=         " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=         " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=         " AND SB1.B1_COD     = SC7.C7_PRODUTO"
	_oSQL:_sQuery +=         " AND SB1.B1_TIPO    BETWEEN '" + mv_par03 +"' AND '" + mv_par04 + "'"
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery +=      " SELECT SC1.C1_PRODUTO AS PRODUTO, RTRIM (SB1.B1_DESC) AS DESCRICAO, SB1.B1_TIPO AS TIPO,"
	_oSQL:_sQuery +=             " CASE SC1.C1_UM WHEN '' THEN SB1.B1_UM ELSE SC1.C1_UM END AS UM,"
	_oSQL:_sQuery +=             " CASE WHEN SC1.C1_TPOP IN (' ', 'F') THEN 'FIRME' ELSE 'PREV' END AS FIRME_PREV,"
	_oSQL:_sQuery +=             " SC1.C1_NUM AS NUM, SC1.C1_ITEM AS ITEM, SC1.C1_FORNECE AS FORNECE,"
	_oSQL:_sQuery +=             " SC1.C1_QUANT AS QUANT, SC1.C1_EMISSAO AS EMISSAO, SC1.C1_DATPRF AS ENTREGA,"
	_oSQL:_sQuery +=             " SC1. C1_SOLICIT AS SOLICITANTE,"
	_oSQL:_sQuery +=             " SC1.C1_QUJE AS QT_ENTREGUE, SC1.C1_QUANT - SC1.C1_QUJE AS SALDO"
	_oSQL:_sQuery +=        " FROM " + RetSqlName ("SC1") + " SC1,"
	_oSQL:_sQuery +=                   RetSqlName ("SB1") + " SB1"
	_oSQL:_sQuery +=       " WHERE SC1.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=         " AND SC1.C1_FILIAL  = '" + xFilial ("SC1") + "'"
	_oSQL:_sQuery +=         " AND SC1.C1_PRODUTO BETWEEN '" + mv_par01 +"' AND '" + mv_par02 + "'"
	_oSQL:_sQuery +=         " AND SC1.C1_DATPRF  BETWEEN '" + dtos (MV_PAR08) + "' AND '" + dtos (MV_PAR09) + "'"
	_oSQL:_sQuery +=         " AND SC1.C1_QUANT   > SC1.C1_QUJE"
	_oSQL:_sQuery +=         " AND SC1.C1_RESIDUO != 'S'"
	if mv_par07 == 1
		_oSQL:_sQuery +=     " AND SC1.C1_TPOP IN ('F', ' ')"
	elseif mv_par07 == 2
		_oSQL:_sQuery +=     " AND SC1.C1_TPOP NOT IN ('F', ' ')"
	endif
	_oSQL:_sQuery +=         " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=         " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=         " AND SB1.B1_COD     = SC1.C1_PRODUTO"
	_oSQL:_sQuery +=         " AND SB1.B1_TIPO    BETWEEN '" + mv_par03 +"' AND '" + mv_par04 + "'"
	_oSQL:_sQuery += ")"
	_oSQL:_sQuery += " SELECT *"
	_oSQL:_sQuery +=   " FROM C"
	_oSQL:_sQuery +=  " ORDER BY PRODUTO, ENTREGA, NUM, ITEM"
//	u_log (_oSQL:_sQuery)
	_oSQL:SetField ('EMISSAO', 'D')
	_oSQL:SetField ('ENTREGA', 'D')
	_sAliasQ = _oSQL:Qry2Trb (.T.)

	oSection1:Init()
	oSection1:SetHeaderBreak(.F.)
	lPrint := .T.
	oReport:SetMeter ((_sAliasQ) -> (reccount ()))
	_sProduto = '' 
	(_sAliasQ) -> (dbgotop ()) 

	do while ! (_sAliasQ) -> (EOF())
		oReport:IncMeter()
		If oReport:Cancel()
			MsgAlert("Operação cancelada pelo usuário.")
			Exit
		End

		// Seta os dados do produto somente quando houver troca do mesmo, para que nao
		// lista repetidamente o produto em todas as linhas.
		if _sProduto != (_sAliasQ) -> produto
			oReport:ThinLine()
			oSection1:Cell("PRODUTO")  :SetBlock({|| (_sAliasQ) -> produto})
			oSection1:Cell("DESCRICAO"):SetBlock({|| (_sAliasQ) -> descricao})
			oSection1:Cell("TIPO")     :SetBlock({|| (_sAliasQ) -> tipo})
			oSection1:Cell("UN_MEDIDA"):SetBlock({|| (_sAliasQ) -> um})
			_sProduto = (_sAliasQ) -> produto
		else
			oSection1:Cell("PRODUTO")  :SetBlock({|| ''})
			oSection1:Cell("DESCRICAO"):SetBlock({|| ''})
			oSection1:Cell("TIPO")     :SetBlock({|| ''})
			oSection1:Cell("UN_MEDIDA"):SetBlock({|| ''})
		endif

		oSection1:Cell("FIRME_PREV") :SetBlock({|| (_sAliasQ) -> firme_prev})
		oSection1:Cell("NUM")		 :SetBlock({|| (_sAliasQ) -> num})
		oSection1:Cell("ITEM")		 :SetBlock({|| (_sAliasQ) -> item})
		oSection1:Cell("FORNECE")	 :SetBlock({|| (_sAliasQ) -> fornece})
		oSection1:Cell("ENTREGA") 	 :SetBlock({|| (_sAliasQ) -> entrega})
		oSection1:Cell("QUANT") 	 :SetBlock({|| (_sAliasQ) -> quant})
		oSection1:Cell("EMISSAO") 	 :SetBlock({|| (_sAliasQ) -> emissao})
		oSection1:Cell("DT_LIMITE")  :SetBlock({|| SomaPrazo ((_sAliasQ) -> entrega, -CalcPrazo ((_sAliasQ) -> produto, (_sAliasQ) -> quant))})
		oSection1:Cell("SOLICITANTE"):SetBlock({|| (_sAliasQ) -> solicitante})
		oSection1:Cell("QT_ENTREGUE"):SetBlock({|| (_sAliasQ) -> qt_entregue})
		oSection1:Cell("SALDO")      :SetBlock({|| (_sAliasQ) -> saldo})
		oSection1:PrintLine()
		(_sAliasQ) -> (dbSkip ())
	EndDo
	oSection1:Finish()

	(_sAliasQ) -> (dbCloseArea())
Return



// --------------------------------------------------------------------------
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                          TIPO TAM DEC VALID  F3     Opcoes                        Help   
	aadd (_aRegsPerg, {01, "Produto de ?                 ", "C", 15, 0,  "",    "SB1", {},                           ""})
	aadd (_aRegsPerg, {02, "Produto até ?                ", "C", 15, 0,  "",    "SB1", {},                           ""})
	aadd (_aRegsPerg, {03, "Tipo Prod. até ?             ", "C", 2,  0,  "",    "02",  {},                           ""})
	aadd (_aRegsPerg, {04, "Tipo Prod. até ?             ", "C", 2,  0,  "",    "02",  {},                           ""})
	aadd (_aRegsPerg, {05, "Dt. Previsão Entrega PC de ? ", "D", 8,  0,  "",    "   ", {},                           ""})
	aadd (_aRegsPerg, {06, "Dt. Previsão Entrega PC até ?", "D", 8,  0,  "",    "   ", {},                           ""})
	aadd (_aRegsPerg, {07, "Condição do PC ?             ", "N", 1,  0,  "",    "   ", {"Firme","Prevista",'Ambas'}, ""})
	aadd (_aRegsPerg, {08, "Dt. Limite de Compra de ?    ", "D", 8,  0,  "",    "   ", {},                           ""})
	aadd (_aRegsPerg, {09, "Dt. Limite de Compra até ?   ", "D", 8,  0,  "",    "   ", {},                           ""})
	aadd (_aRegsPerg, {10, "Condição da SC ?             ", "N", 1,  0,  "",    "   ", {"Firme","Prevista",'Ambas'}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
