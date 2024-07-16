// Programa...: VA_SZOI
// Autor......: Robert Koch
// Data.......: 16/07/2008
// Descricao..: Rotina de impressao de ordens de ordens de embarque.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Rotina de impressao de ordens de ordens de embarque.
// #PalavasChave      #impressao #ordens_de_embarque
// #TabelasPrincipais #SD2 #SF2 #SB1 
// #Modulos   		  #FAT
//
// Historico de alteracoes:
// 18/07/2008 - Robert  - Nao agrupava produto quando era de notas diferentes.
// 26/11/2008 - Robert  - Impressao da relacao dos municipios para entrega.
// 10/04/2019 - Robert  - Migrada tabela 98 do SX5 para 50 do ZX5.
// 30/08/2019 - Claudia - Alterado campo peso bruto para b1_pesbru.
// 23/11/2020 - Claudia - Ajustada a gravação de parametros SX1/SXK. GLPI: 8750
// 15/07/2024 - Claudia - Alterado o modelo de relatorio e busca de peso bruto. GLPI: 15278
//
// ------------------------------------------------------------------------------------------
#include "protheus.ch"
#include "tbiconn.ch"

User Function VA_SZOI(_sOrdem)
	Private oReport
	Private cPerg := "VA_SZOI"

	// Cria as perguntas na tabela SX1
	_validPerg()
	
	// Se foi passado o numero da ordem de embarque, ajusta os parametros.
	if _sOrdem != NIL
		_ValidSXK(_sOrdem, 'D')
		_ValidSXK(_sOrdem, 'G')

		U_GravaSX1(cPerg, "01", _sOrdem)           // Ordem de
		U_GravaSX1(cPerg, "02", _sOrdem)           // Ordem ate
		U_GravaSX1(cPerg, "03", "")                // Transp de
		U_GravaSX1(cPerg, "04", "zzzzz")           // Transp ate
		U_GravaSX1(cPerg, "05", ctod(""))          // Data de
		U_GravaSX1(cPerg, "06", stod("20491231"))  // data ate
		U_GravaSX1(cPerg, "07", "")                // Cliente
		U_GravaSX1(cPerg, "08", "")                // Loja
		U_GravaSX1(cPerg, "09", "zzzzzz")          // Cliente ate
		U_GravaSX1(cPerg, "10", "zz")              // Loja ate
		U_GravaSX1(cPerg, "11", "")                // Estado de
		U_GravaSX1(cPerg, "12", "zz")              // Estado ate
	endif
	
	Pergunte(cPerg, .T.)
	oReport := ReportDef()
    oReport:PrintDialog()

	_ValidSXK(_sOrdem, 'G')
Return
//
//
// -------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil
	Local oSection2 := Nil
	Local oSection3 := Nil

    oReport := TReport():New("VA_SZOI","Ordem de Embarque",cPerg,{|oReport| PrintReport(oReport)},"Ordem de Embarque")
	TReport():ShowParamPage()
	oReport:SetTotalInLine(.F.)
	
	// GRUPOS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	TRCell():New(oSection1,"COLUNA01", 	"" ,"GRUPO"     ,	    				, 30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA02", 	"" ,"PRODUTO"   ,	    				, 60,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA03", 	"" ,"QUANTIDADE", "@E 999,999,999.99"   , 25,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA04", 	"" ,"PESO"		, "@E 999,999,999.99"   , 25,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	
    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA01"),"Total do grupo")
	TRFunction():New(oSection1:Cell("COLUNA03")	,,"SUM"	,oBreak1,""  , "@E 999,999,999.99", NIL, .F., .F., .F.)
	TRFunction():New(oSection1:Cell("COLUNA04")	,,"SUM"	,oBreak1,""  , "@E 999,999,999.99", NIL, .F., .F., .F.)

    // NOTAS/MUNICIPIOS
	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    TRCell():New(oSection2,"COLUNA01", 	"" ,"NOTA FISCAL"	,	 ,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA02", 	"" ,"MUNICÍPIO"		,	 ,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA03", 	"" ,"ESTADO"		,	 ,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)

	// TOTAIS
	oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	TRCell():New(oSection3,"COLUNA01", 	"" ,""     ,	    						, 30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection3,"COLUNA02", 	"" ,""   	,	    						, 60,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection3,"COLUNA03", 	"" ,"TOTAL QTD."	, "@E 999,999,999.99"   , 25,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA04", 	"" ,"TOTAL PESO"	, "@E 999,999,999.99"   , 25,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local oSection2 := oReport:Section(2)	
	Local oSection3 := oReport:Section(3)
    Local _aDados   := {}
	Local _sTransp  := ""
	Local _sTel     := ""
    Local _x        := 0
	Local _nTotQtd  := 0 
	Local _nTotPeso := 0

	// GRUPOS ----------------------------------------------------------------
    _oSQL:= ClsSQL():New()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "     F2_ORDEMB AS ORDEM_EMBARQUE "
	_oSQL:_sQuery += "    ,F2_TRANSP AS TRANSP "
	_oSQL:_sQuery += "    ,A4_NOME AS NOME_TRANSP "
	_oSQL:_sQuery += "    ,B1_GRPEMB AS GRUPO_EMB "
	_oSQL:_sQuery += "    ,ZX5_50DESC AS NOME_GRUPO "
	_oSQL:_sQuery += "    ,TRIM(D2_COD) +' - '+ TRIM(C6_DESCRI) AS PRODUTO "
	_oSQL:_sQuery += "    ,SUBSTRING(B1_VAGRLP, 1, 1) AS LISTAPRC1 "
	_oSQL:_sQuery += "    ,SUBSTRING(B1_VAGRLP, 2, 1) AS LISTAPRC2 "
	_oSQL:_sQuery += "    ,D2_QUANT AS QUANT "
	_oSQL:_sQuery += "    ,C6_VAPBRU  * D2_QUANT/C6_QTDVEN AS PESO "
	_oSQL:_sQuery += "    ,A4_TEL AS TEL_TRANSP "
	_oSQL:_sQuery += " FROM " + RetSQLName("SF2") + " SF2 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName("SD2") + " SD2 "
	_oSQL:_sQuery += " 	ON SD2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND D2_FILIAL = '" + xfilial("SD2") + "'"
	_oSQL:_sQuery += " 		AND D2_SERIE  = F2_SERIE "
	_oSQL:_sQuery += " 		AND D2_DOC    = F2_DOC "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName("SA4") + " SA4 "
	_oSQL:_sQuery += " 	ON SA4.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND A4_FILIAL = '" + xfilial("SA4") + "'"
	_oSQL:_sQuery += " 		AND A4_COD    = F2_TRANSP "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	_oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND B1_FILIAL = '" + xfilial("SB1") + "'"
	_oSQL:_sQuery += " 		AND B1_COD    = D2_COD "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND A1_FILIAL = '" + xfilial("SA1") + "'"
	_oSQL:_sQuery += " 		AND A1_LOJA   = F2_LOJA "
	_oSQL:_sQuery += " 		AND A1_COD    = F2_CLIENTE "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("ZX5") + " ZX5_50 " 
	_oSQL:_sQuery += " 	ON ZX5_50.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND ZX5_50.ZX5_FILIAL = '" + xfilial("ZX5") + "'"
	_oSQL:_sQuery += " 		AND ZX5_50.ZX5_50COD  = B1_GRPEMB "
	_oSQL:_sQuery += " 		AND ZX5_50.ZX5_TABELA = '50' "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SC6") + " SC6 "
	_oSQL:_sQuery += " 	ON (SC6.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND C6_FILIAL  = '" + xfilial("SC6") + "'"
	_oSQL:_sQuery += " 			AND C6_NUM     = D2_PEDIDO "
	_oSQL:_sQuery += " 			AND C6_ITEM    = D2_ITEMPV "
	_oSQL:_sQuery += " 			AND C6_PRODUTO = D2_COD) "
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND F2_FILIAL = '" + xfilial("SF2") + "'"
	_oSQL:_sQuery += " AND F2_ORDEMB  BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
	_oSQL:_sQuery += " AND F2_TRANSP  BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
	_oSQL:_sQuery += " AND F2_EMISSAO BETWEEN '" + dtos(mv_par05) + "' and '" + dtos(mv_par06) + "'"
	_oSQL:_sQuery += " AND F2_CLIENTE BETWEEN '" + mv_par07 + "' and '" + mv_par09 + "'"
	_oSQL:_sQuery += " AND F2_LOJA    BETWEEN '" + mv_par08 + "' and '" + mv_par10 + "'"
	_oSQL:_sQuery += " AND F2_EST     BETWEEN '" + mv_par11 + "' and '" + mv_par12 + "'"
	_oSQL:_sQuery += " ORDER BY F2_ORDEMB, B1_GRPEMB, SUBSTRING(B1_VAGRLP, 1, 1), SUBSTRING(B1_VAGRLP, 2, 1), B1_DESC "
    _aDados := aclone(_oSQL:Qry2Array(.f., .f.))

	if len(_aDados) > 0
		_sOrdem  := alltrim(_aDados[1,1])
		_sTransp := alltrim(_aDados[1,2]) +" - " + alltrim(_aDados[1,3])
		_sTel    := alltrim(_aDados[1,11])
	endif
	oReport:PrintText(" ORDEM DE EMBARQUE:" + _sOrdem  +"                                                                          Via 1 - Transportadora (conferência)",,0)
	oReport:PrintText(" TRANSPORTADORA   :" + _sTransp +"      Telefone: "+ _sTel,,0)
	oReport:SkipLine(1)
	oReport:ThinLine()

    oSection1:Init()

    For _x := 1 to Len(_aDados)
        oSection1:Cell("COLUNA01"):SetBlock({|| alltrim(_aDados[_x, 4]) +" - "+alltrim(_aDados[_x, 5]) })
        oSection1:Cell("COLUNA02"):SetBlock({|| alltrim(_aDados[_x, 6]) })
        oSection1:Cell("COLUNA03"):SetBlock({|| _aDados[_x, 9] })
        oSection1:Cell("COLUNA04"):SetBlock({|| _aDados[_x,10] })
        oSection1:PrintLine()
		_nTotQtd  += _aDados[_x, 9] 
		_nTotPeso += _aDados[_x,10]
    Next

    oSection1:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)

	// TOTAIS ----------------------------------------------------------------
	oSection3:Init()
	oSection3:Cell("COLUNA01"):SetBlock({|| "" 			})
	oSection3:Cell("COLUNA02"):SetBlock({|| "" 			})
	oSection3:Cell("COLUNA03"):SetBlock({|| _nTotQtd  	})
	oSection3:Cell("COLUNA04"):SetBlock({|| _nTotPeso 	})
	oSection3:PrintLine()

	oSection3:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)

    // NOTAS ----------------------------------------------------------------
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   SF2.F2_DOC +' '+ SF2.F2_SERIE "
	_oSQL:_sQuery += "    ,CASE SF2.F2_TIPO "
	_oSQL:_sQuery += " 			WHEN 'B' THEN SA2.A2_MUN "
	_oSQL:_sQuery += " 			WHEN 'D' THEN SA2.A2_MUN "
	_oSQL:_sQuery += " 			ELSE SA1.A1_MUN "
	_oSQL:_sQuery += " 	   END "
	_oSQL:_sQuery += "    ,CASE SF2.F2_TIPO "
	_oSQL:_sQuery += " 			WHEN 'B' THEN SA2.A2_EST "
	_oSQL:_sQuery += " 			WHEN 'D' THEN SA2.A2_EST "
	_oSQL:_sQuery += " 			ELSE SA1.A1_EST "
	_oSQL:_sQuery += " 	   END "
	_oSQL:_sQuery += " FROM " + RetSQLName("SF2") + " SF2 "
	// Busca clientes e fornecedores com left join por que vai depender do tipo de nota
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SA2") + " SA2 "
	_oSQL:_sQuery += " 	ON SA2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SA2.A2_FILIAL = '' "
	_oSQL:_sQuery += " 			AND SA2.A2_COD = SF2.F2_CLIENTE "
	_oSQL:_sQuery += " 			AND SA2.A2_LOJA = SF2.F2_LOJA "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
	_oSQL:_sQuery += " 			AND SA1.A1_COD = SF2.F2_CLIENTE "
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF2.F2_LOJA "
	_oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND F2_FILIAL = '" + xfilial("SF2") + "'"
	_oSQL:_sQuery += " AND F2_ORDEMB = '"+ _sOrdem +"' "
	_oSQL:_sQuery += " ORDER BY F2_DOC "
    _aNF := aclone(_oSQL:Qry2Array(.f., .f.))

    oSection2:Init()

    For _x := 1 to Len(_aNF)
        oSection2:Cell("COLUNA01"):SetBlock({|| _aNF[_x, 1] 		 })
        oSection2:Cell("COLUNA02"):SetBlock({|| alltrim(_aNF[_x, 2]) })
		oSection2:Cell("COLUNA03"):SetBlock({|| alltrim(_aNF[_x, 3]) })
        oSection2:PrintLine()
    Next

    oSection2:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(6)

	oReport:PrintText("----------------------------------------------------            ----------------------------------------------------",,450)
	oReport:PrintText("            Separador (Nova Aliança)                                         Conferente (Nova Aliança)              ",,450)
	
	oReport:SkipLine(4)
	_sEmp := _BuscaNomeEmpresa(xfilial("SF2"))
	_sMsg := "Recebemos da " + alltrim(_sEmp) + " os produtos acima discriminados pela ordem de embarque No. "+ _sOrdem + ".
	oReport:PrintText(_sMsg,,100)
	_sMsg := "Deste momento em diante me responsabilizo pela integridade da mercadoria."
	oReport:PrintText(_sMsg,,100)
	oReport:SkipLine(4)

	oReport:PrintText("----------------------------------------------------            ----------------------------------------------------",,450)
	oReport:PrintText("         Conferente transp.(Nome legível)                                            Assinatura                     ",,450)
	oReport:SkipLine(4)
	oReport:PrintText("----------------------------------------------------            ----------------------------------------------------",,450)
	oReport:PrintText("                      Placa                                                             Data                        ",,450)

Return
//
// --------------------------------------------------------------------------
// Busca nome da empresa
Static Function _BuscaNomeEmpresa(_sFilial)
	Local _sEmp := ""

	_oSQL:= ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " 	SELECT "
	_oSQL:_sQuery += " 		M0_NOMECOM "
	_oSQL:_sQuery += " 	FROM VA_SM0 "
	_oSQL:_sQuery += " 	WHERE M0_CODIGO = '01' "
	_oSQL:_sQuery += " 	AND M0_CODFIL   = '"+ _sFilial +"' "
	_aDados := aclone(_oSQL:Qry2Array(.f., .f.))

	if Len(_aDados) > 0
		_sEmp := _aDados[1,1]
	endif
Return _sEmp
//
// --------------------------------------------------------------------------
// Executa SXK
Static Function _ValidSXK(_sOrdem, _sTipo)
	U_GravaSXK (cPerg, "01", _sOrdem			, _sTipo )
	U_GravaSXK (cPerg, "02", _sOrdem			, _sTipo )
	U_GravaSXK (cPerg, "03", ""					, _sTipo )
	U_GravaSXK (cPerg, "04", "zzzzz"			, _sTipo )
	U_GravaSXK (cPerg, "05", ""					, _sTipo )
	U_GravaSXK (cPerg, "06", "20491231"			, _sTipo )
	U_GravaSXK (cPerg, "07", ""					, _sTipo )
	U_GravaSXK (cPerg, "08", ""					, _sTipo )
	U_GravaSXK (cPerg, "09", "zzzzzz"			, _sTipo )
	U_GravaSXK (cPerg, "10", "zz"				, _sTipo )
	U_GravaSXK (cPerg, "11", ""					, _sTipo )
	U_GravaSXK (cPerg, "12", "zz"				, _sTipo )
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Ordem embarque de             ", "C", 5,  0,  "",   "SZO", {},    ""})
	aadd (_aRegsPerg, {02, "Ordem embarque ate            ", "C", 5,  0,  "",   "SZO", {},    ""})
	aadd (_aRegsPerg, {03, "Transportadora de             ", "C", 6,  0,  "",   "SA4", {},    ""})
	aadd (_aRegsPerg, {04, "Transportadora ate            ", "C", 6,  0,  "",   "SA4", {},    ""})
	aadd (_aRegsPerg, {05, "Data emissao da ordem de      ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {06, "Data emissao da ordem ate     ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {07, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {08, "Loja de                       ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {09, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {10, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {11, "Estado de                     ", "C", 2,  0,  "",   "12 ", {},    ""})
	aadd (_aRegsPerg, {12, "Estado ate                    ", "C", 2,  0,  "",   "12 ", {},    ""})
	//aadd (_aRegsPerg, {13, "Quantidade de vias            ", "N", 2,  0,  "",   "   ", {},    ""})
	//aadd (_aRegsPerg, {14, "Maximo de linhas por pagina   ", "N", 2,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
