//  Programa...: VA_AMPARA
//  Autor......: Cláudia Lionço
//  Data.......: 03/08/2018
//  Descricao..: Relatório auxiliar para apuracao AMPARA/RS
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório auxiliar para apuracao AMPARA/RS
// #PalavasChave      #AMPARA_RS #apuracao 
// #TabelasPrincipais #SA1 #SF3
// #Modulos 		  #FIS
//
//  Historico de alteracoes:
//  23/01/2034 - Claudia - Migrado do programa ML_AMPARA para TREPORT e separadas as entradas/saidas. GLPI: 14678
//
// ----------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'totvs.ch'

User function VA_AMPARA()
	Private oReport
	Private cPerg   := "VA_AMPARA"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ----------------------------------------------------------------------------------------------------------------
//
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
    Local oSection2:= Nil
    Local oSection3:= Nil
    Local oSection4:= Nil
    Local oSection5:= Nil
    Local oSection6:= Nil
    Local oBreak1
    Local oBreak2
    Local oBreak3
    Local oBreak4
    Local oBreak5
    Local oBreak6

	oReport := TReport():New("VA_AMPARA","Relatório AMPARA",cPerg,{|oReport| PrintReport(oReport)},"Relatório AMPARA")
	oReport:ShowParamPage() 
	oReport:SetTotalInLine(.F.)
	oReport:SetLandScape(.T.)
	//oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,"ENTRADAS",{}, , , , , ,.F.,.F.,.F.) 
    oSection1:SetTotalInLine(.F.)
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Entrada"		,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nota Fiscal"	,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Serie"			,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Cli/Forn"		,                   ,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Tipo"		    ,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"CFOP"	        ,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"UF"			,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Emissão"		,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Aliq.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA13", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA14", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA15", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA16", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak1 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA1"):uPrint },"Total entradas da filial:")
    TRFunction():New(oSection1:Cell("COLUNA11")	,,"SUM"	,oBreak1, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection1:Cell("COLUNA12")	,,"SUM"	,oBreak1, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection1:Cell("COLUNA13")	,,"SUM"	,oBreak1, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection1:Cell("COLUNA14")	,,"SUM"	,oBreak1, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection1:Cell("COLUNA15")	,,"SUM"	,oBreak1, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection1:Cell("COLUNA16")	,,"SUM"	,oBreak1, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)

	oSection2 := TRSection():New(oReport,"SAIDAS",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection2:SetTotalInLine(.F.)
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Entrada"		,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Nota Fiscal"	,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Serie"			,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"Cli/Forn"		,                   ,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"Tipo"		    ,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"CFOP"	        ,                   ,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA8", 	"" ,"UF"			,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA9", 	"" ,"Emissão"		,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA10", 	"" ,"Aliq.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA11", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA12", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA13", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA14", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA15", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA16", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak2 := TRBreak():New(oSection2,{|| oSection2:Cell("COLUNA1"):uPrint },"Total saídas da filial:")
    TRFunction():New(oSection2:Cell("COLUNA11")	,,"SUM"	,oBreak2, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection2:Cell("COLUNA12")	,,"SUM"	,oBreak2, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection2:Cell("COLUNA13")	,,"SUM"	,oBreak2, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection2:Cell("COLUNA14")	,,"SUM"	,oBreak2, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection2:Cell("COLUNA15")	,,"SUM"	,oBreak2, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection2:Cell("COLUNA16")	,,"SUM"	,oBreak2, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)

    oSection3 := TRSection():New(oReport,"",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection3:SetTotalInLine(.F.)
	TRCell():New(oSection3,"COLUNA1", 	"" ,"Filial"		,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA2", 	"" ,"CFOP"		    ,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection3,"COLUNA3", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA4", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA5", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA6", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA7", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection3,"COLUNA8", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak3 := TRBreak():New(oSection3,{|| oSection3:Cell("COLUNA1"):uPrint},"Total por filial/cfop")
    TRFunction():New(oSection3:Cell("COLUNA3")	,,"SUM"	,oBreak3, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection3:Cell("COLUNA4")	,,"SUM"	,oBreak3, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection3:Cell("COLUNA5")	,,"SUM"	,oBreak3, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection3:Cell("COLUNA6")	,,"SUM"	,oBreak3, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection3:Cell("COLUNA7")	,,"SUM"	,oBreak3, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection3:Cell("COLUNA8")	,,"SUM"	,oBreak3, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)

    oSection4 := TRSection():New(oReport,"",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection4:SetTotalInLine(.F.)
	TRCell():New(oSection4,"COLUNA1", 	"" ,"Filial"		,                   ,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA2", 	"" ,"CFOP"		    ,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection4,"COLUNA3", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA4", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA5", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA6", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA7", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA8", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak4 := TRBreak():New(oSection4,{|| oSection4:Cell("COLUNA1"):uPrint},"Total por filial/cfop")
    TRFunction():New(oSection4:Cell("COLUNA3")	,,"SUM"	,oBreak4, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection4:Cell("COLUNA4")	,,"SUM"	,oBreak4, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection4:Cell("COLUNA5")	,,"SUM"	,oBreak4, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection4:Cell("COLUNA6")	,,"SUM"	,oBreak4, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection4:Cell("COLUNA7")	,,"SUM"	,oBreak4, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection4:Cell("COLUNA8")	,,"SUM"	,oBreak4, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)

    oSection5 := TRSection():New(oReport,"",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection5:SetTotalInLine(.F.)
	TRCell():New(oSection5,"COLUNA1", 	"" ,"CFOP"		    ,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection5,"COLUNA2", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection5,"COLUNA3", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection5,"COLUNA4", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection5,"COLUNA5", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection5,"COLUNA6", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection5,"COLUNA7", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak5 := TRBreak():New(oSection5,{|| },"Total por cfop")
    TRFunction():New(oSection5:Cell("COLUNA2")	,,"SUM"	,oBreak5, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection5:Cell("COLUNA3")	,,"SUM"	,oBreak5, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection5:Cell("COLUNA4")	,,"SUM"	,oBreak5, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection5:Cell("COLUNA5")	,,"SUM"	,oBreak5, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection5:Cell("COLUNA6")	,,"SUM"	,oBreak5, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection5:Cell("COLUNA7")	,,"SUM"	,oBreak5, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    
    oSection6 := TRSection():New(oReport,"",{""}, , , , , ,.F.,.F.,.F.) 
	
	oSection6:SetTotalInLine(.F.)
	TRCell():New(oSection6,"COLUNA1", 	"" ,"CFOP"		    ,                   ,12,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection6,"COLUNA2", 	"" ,"Val.Conta"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection6,"COLUNA3", 	"" ,"Base ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection6,"COLUNA4", 	"" ,"Val.ICMS"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection6,"COLUNA5", 	"" ,"Val.FECP"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection6,"COLUNA6", 	"" ,"ICMS Ret"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection6,"COLUNA7", 	"" ,"V.FECP ST"		,"@E 99,999,999.99" ,20,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak6 := TRBreak():New(oSection6,{|| },"Total por cfop")
    TRFunction():New(oSection6:Cell("COLUNA2")	,,"SUM"	,oBreak6, "Val.Conta ", "@E 999,999,999,999.99", NIL, .F., .F.)
	TRFunction():New(oSection6:Cell("COLUNA3")	,,"SUM"	,oBreak6, "Base ICMS ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection6:Cell("COLUNA4")	,,"SUM"	,oBreak6, "Val.ICMS  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection6:Cell("COLUNA5")	,,"SUM"	,oBreak6, "Val.FECP  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection6:Cell("COLUNA6")	,,"SUM"	,oBreak6, "ICMS Ret  ", "@E 999,999,999,999.99", NIL, .F., .F.)
    TRFunction():New(oSection6:Cell("COLUNA7")	,,"SUM"	,oBreak6, "V.FECP ST ", "@E 999,999,999,999.99", NIL, .F., .F.)
Return(oReport)
//
// ----------------------------------------------------------------------------------------------------------------
// Imprime
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
    Local oSection2  := oReport:Section(2)
    Local oSection3  := oReport:Section(3)
    Local oSection4  := oReport:Section(4)
    Local oSection5  := oReport:Section(5)
    Local oSection6  := oReport:Section(6)
    Local _x         := 0

    // ENTRADAS
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SF3.F3_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SF3.F3_ENTRADA AS ENTRADA "
    _oSQL:_sQuery += "    ,SF3.F3_NFISCAL AS NFISCAL "
    _oSQL:_sQuery += "    ,SF3.F3_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SF3.F3_CLIEFOR AS CLIEFOR "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'S' THEN 'SOLIDARIO' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'F' THEN 'CONS. FINAL' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'L' THEN 'PRODUTOR RURAL' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'R' THEN 'OUTROS' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'X' THEN 'EXPORTACAO' "
    _oSQL:_sQuery += " 	    END TIPO "
    _oSQL:_sQuery += "    ,SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SF3.F3_ESTADO AS ESTADO "
    _oSQL:_sQuery += "    ,SF3.F3_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += "    ,SF3.F3_ALIQICM AS ALIQICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALCONT * -1 AS VALCONT "
    _oSQL:_sQuery += "    ,SF3.F3_BASEICM * -1 AS BASEICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALICM * -1 AS VALICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALFECP * -1 AS VALFECP "
    _oSQL:_sQuery += "    ,SF3.F3_ICMSRET * -1 AS ICMRET "
    _oSQL:_sQuery += "    ,SF3.F3_VFECPST * -1 AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO < '5000' "
    _oSQL:_sQuery += " ORDER BY SF3.F3_FILIAL, SF3.F3_ENTRADA "
    _aEntradas := aclone (_oSQL:Qry2Array ())

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    For _x:=1 to Len(_aEntradas)
        oSection1:Cell("COLUNA1")  :SetBlock({|| _aEntradas[_x,  1] }) 
        oSection1:Cell("COLUNA2")  :SetBlock({|| stod(_aEntradas[_x,  2]) }) 
        oSection1:Cell("COLUNA3")  :SetBlock({|| _aEntradas[_x,  3] }) 
        oSection1:Cell("COLUNA4")  :SetBlock({|| _aEntradas[_x,  4] }) 
        oSection1:Cell("COLUNA5")  :SetBlock({|| _aEntradas[_x,  5] }) 
        oSection1:Cell("COLUNA6")  :SetBlock({|| _aEntradas[_x,  6] }) 
        oSection1:Cell("COLUNA7")  :SetBlock({|| _aEntradas[_x,  7] }) 
        oSection1:Cell("COLUNA8")  :SetBlock({|| _aEntradas[_x,  8] }) 
        oSection1:Cell("COLUNA9")  :SetBlock({|| stod(_aEntradas[_x,  9]) }) 
        oSection1:Cell("COLUNA10") :SetBlock({|| _aEntradas[_x, 10] }) 
        oSection1:Cell("COLUNA11") :SetBlock({|| _aEntradas[_x, 11] }) 
        oSection1:Cell("COLUNA12") :SetBlock({|| _aEntradas[_x, 12] }) 
        oSection1:Cell("COLUNA13") :SetBlock({|| _aEntradas[_x, 13] }) 
        oSection1:Cell("COLUNA14") :SetBlock({|| _aEntradas[_x, 14] }) 
        oSection1:Cell("COLUNA15") :SetBlock({|| _aEntradas[_x, 15] }) 
        oSection1:Cell("COLUNA16") :SetBlock({|| _aEntradas[_x, 16] }) 

        oSection1:PrintLine()
    Next
    oSection1:Finish()

    // SAIDAS
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SF3.F3_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SF3.F3_ENTRADA AS ENTRADA "
    _oSQL:_sQuery += "    ,SF3.F3_NFISCAL AS NFISCAL "
    _oSQL:_sQuery += "    ,SF3.F3_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SF3.F3_CLIEFOR AS CLIEFOR "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'S' THEN 'SOLIDARIO' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'F' THEN 'CONS. FINAL' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'L' THEN 'PRODUTOR RURAL' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'R' THEN 'OUTROS' "
    _oSQL:_sQuery += " 		    WHEN SA1.A1_TIPO = 'X' THEN 'EXPORTACAO' "
    _oSQL:_sQuery += " 	    END TIPO "
    _oSQL:_sQuery += "    ,SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SF3.F3_ESTADO AS ESTADO "
    _oSQL:_sQuery += "    ,SF3.F3_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += "    ,SF3.F3_ALIQICM AS ALIQICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALCONT AS VALCONT "
    _oSQL:_sQuery += "    ,SF3.F3_BASEICM AS BASEICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALICM AS VALICM "
    _oSQL:_sQuery += "    ,SF3.F3_VALFECP AS VALFECP "
    _oSQL:_sQuery += "    ,SF3.F3_ICMSRET AS ICMRET "
    _oSQL:_sQuery += "    ,SF3.F3_VFECPST AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO >= '5000' "
    _oSQL:_sQuery += " ORDER BY SF3.F3_FILIAL, SF3.F3_ENTRADA "
    _aSaidas := aclone (_oSQL:Qry2Array ())

    oSection2:Init()
	oSection2:SetHeaderSection(.T.)

    For _x:=1 to Len(_aSaidas)
        oSection2:Cell("COLUNA1")  :SetBlock({|| _aSaidas[_x,  1] }) 
        oSection2:Cell("COLUNA2")  :SetBlock({|| stod(_aSaidas[_x,  2]) }) 
        oSection2:Cell("COLUNA3")  :SetBlock({|| _aSaidas[_x,  3] }) 
        oSection2:Cell("COLUNA4")  :SetBlock({|| _aSaidas[_x,  4] }) 
        oSection2:Cell("COLUNA5")  :SetBlock({|| _aSaidas[_x,  5] }) 
        oSection2:Cell("COLUNA6")  :SetBlock({|| _aSaidas[_x,  6] }) 
        oSection2:Cell("COLUNA7")  :SetBlock({|| _aSaidas[_x,  7] }) 
        oSection2:Cell("COLUNA8")  :SetBlock({|| _aSaidas[_x,  8] }) 
        oSection2:Cell("COLUNA9")  :SetBlock({|| stod(_aSaidas[_x,  9]) }) 
        oSection2:Cell("COLUNA10") :SetBlock({|| _aSaidas[_x, 10] }) 
        oSection2:Cell("COLUNA11") :SetBlock({|| _aSaidas[_x, 11] }) 
        oSection2:Cell("COLUNA12") :SetBlock({|| _aSaidas[_x, 12] }) 
        oSection2:Cell("COLUNA13") :SetBlock({|| _aSaidas[_x, 13] }) 
        oSection2:Cell("COLUNA14") :SetBlock({|| _aSaidas[_x, 14] }) 
        oSection2:Cell("COLUNA15") :SetBlock({|| _aSaidas[_x, 15] }) 
        oSection2:Cell("COLUNA16") :SetBlock({|| _aSaidas[_x, 16] }) 

        oSection2:PrintLine()
    Next
    oSection2:Finish()

    oReport:EndPage()
	oReport:StartPage()

    // ********************************************************************************************************
    // TOTAIS POR FILIAL/CFOP

    oReport:PrintText(" *** TOTAIS POR FILIAL/CFOP *** ",,100)
    oReport:PrintText(" ",,100)
    oReport:PrintText(" -> ENTRADAS",,100)
    oReport:PrintText(" ",,100)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SF3.F3_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALCONT * -1) AS VALCONT "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_BASEICM * -1) AS BASEICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALICM * -1) AS VALICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALFECP * -1) AS VALFECP "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_ICMSRET * -1) AS ICMRET "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VFECPST * -1) AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO < '5000' "
    _oSQL:_sQuery += " GROUP BY SF3.F3_FILIAL, SF3.F3_CFO "
    _oSQL:_sQuery += " ORDER BY SF3.F3_FILIAL, SF3.F3_CFO "
    _aEntradas := aclone (_oSQL:Qry2Array ())

    oSection3:Init()
	oSection3:SetHeaderSection(.T.)

    For _x:=1 to Len(_aEntradas)
        oSection3:Cell("COLUNA1")  :SetBlock({|| _aEntradas[_x,  1] }) 
        oSection3:Cell("COLUNA2")  :SetBlock({|| _aEntradas[_x,  2] }) 
        oSection3:Cell("COLUNA3")  :SetBlock({|| _aEntradas[_x,  3] }) 
        oSection3:Cell("COLUNA4")  :SetBlock({|| _aEntradas[_x,  4] }) 
        oSection3:Cell("COLUNA5")  :SetBlock({|| _aEntradas[_x,  5] }) 
        oSection3:Cell("COLUNA6")  :SetBlock({|| _aEntradas[_x,  6] }) 
        oSection3:Cell("COLUNA7")  :SetBlock({|| _aEntradas[_x,  7] }) 
        oSection3:Cell("COLUNA8")  :SetBlock({|| _aEntradas[_x,  8] }) 

        oSection3:PrintLine()
    Next
    oSection3:Finish()

    oReport:PrintText(" ",,100)
    oReport:PrintText(" ",,100)
    oReport:PrintText(" -> SAIDAS",,100)
    oReport:PrintText(" ",,100)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SF3.F3_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALCONT) AS VALCONT "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_BASEICM) AS BASEICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALICM) AS VALICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALFECP) AS VALFECP "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_ICMSRET) AS ICMRET "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VFECPST) AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO >= '5000' "
    _oSQL:_sQuery += " GROUP BY SF3.F3_FILIAL, SF3.F3_CFO "
    _oSQL:_sQuery += " ORDER BY SF3.F3_FILIAL, SF3.F3_CFO "
    _aSaidas := aclone (_oSQL:Qry2Array ())

    oSection4:Init()
	oSection4:SetHeaderSection(.T.)

    For _x:=1 to Len(_aSaidas)
        oSection4:Cell("COLUNA1")  :SetBlock({|| _aSaidas[_x,  1] }) 
        oSection4:Cell("COLUNA2")  :SetBlock({|| _aSaidas[_x,  2] }) 
        oSection4:Cell("COLUNA3")  :SetBlock({|| _aSaidas[_x,  3] }) 
        oSection4:Cell("COLUNA4")  :SetBlock({|| _aSaidas[_x,  4] }) 
        oSection4:Cell("COLUNA5")  :SetBlock({|| _aSaidas[_x,  5] }) 
        oSection4:Cell("COLUNA6")  :SetBlock({|| _aSaidas[_x,  6] }) 
        oSection4:Cell("COLUNA7")  :SetBlock({|| _aSaidas[_x,  7] }) 
        oSection4:Cell("COLUNA8")  :SetBlock({|| _aSaidas[_x,  8] }) 

        oSection4:PrintLine()
    Next
    oSection4:Finish()

    oReport:EndPage()
	oReport:StartPage()

    // ********************************************************************************************************
    // TOTAIS POR CFOP

    oReport:PrintText(" *** TOTAIS POR CFOP *** ",,100)
    oReport:PrintText(" ",,100)
    oReport:PrintText(" -> ENTRADAS",,100)
    oReport:PrintText(" ",,100)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALCONT * -1) AS VALCONT "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_BASEICM * -1) AS BASEICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALICM * -1) AS VALICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALFECP * -1) AS VALFECP "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_ICMSRET * -1) AS ICMRET "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VFECPST * -1) AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO < '5000' "
    _oSQL:_sQuery += " GROUP BY SF3.F3_CFO "
    _oSQL:_sQuery += " ORDER BY SF3.F3_CFO "
    _aEntradas := aclone (_oSQL:Qry2Array ())

    oSection5:Init()
	oSection5:SetHeaderSection(.T.)

    For _x:=1 to Len(_aEntradas)
        oSection5:Cell("COLUNA1")  :SetBlock({|| _aEntradas[_x,  1] }) 
        oSection5:Cell("COLUNA2")  :SetBlock({|| _aEntradas[_x,  2] }) 
        oSection5:Cell("COLUNA3")  :SetBlock({|| _aEntradas[_x,  3] }) 
        oSection5:Cell("COLUNA4")  :SetBlock({|| _aEntradas[_x,  4] }) 
        oSection5:Cell("COLUNA5")  :SetBlock({|| _aEntradas[_x,  5] }) 
        oSection5:Cell("COLUNA6")  :SetBlock({|| _aEntradas[_x,  6] }) 
        oSection5:Cell("COLUNA7")  :SetBlock({|| _aEntradas[_x,  7] }) 

        oSection5:PrintLine()
    Next
    oSection5:Finish()

    oReport:PrintText(" ",,100)
    oReport:PrintText(" ",,100)
    oReport:PrintText(" -> SAIDAS",,100)
    oReport:PrintText(" ",,100)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     SF3.F3_CFO AS CFO "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALCONT) AS VALCONT "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_BASEICM) AS BASEICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALICM) AS VALICM "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VALFECP) AS VALFECP "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_ICMSRET) AS ICMRET "
    _oSQL:_sQuery += "    ,SUM(SF3.F3_VFECPST) AS VFECPST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF3") + " AS SF3"
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1"
    _oSQL:_sQuery += " 	    ON (SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_FILIAL = '' "
    _oSQL:_sQuery += " 			AND SA1.A1_COD = SF3.F3_CLIEFOR "
    _oSQL:_sQuery += " 			AND SA1.A1_LOJA = SF3.F3_LOJA) "
    _oSQL:_sQuery += " WHERE SF3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND SF3.F3_FILIAL  BETWEEN '" + mv_par01       + "' AND '" + mv_par02       + "'"
    _oSQL:_sQuery += " AND SF3.F3_ENTRADA BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += " AND SF3.F3_DTCANC = '' "
    _oSQL:_sQuery += " AND SF3.F3_ESTADO = '" + mv_par05 + "'"
    _oSQL:_sQuery += " AND (SF3.F3_VALFECP > 0 "
    _oSQL:_sQuery += " OR SF3.F3_VFECPST > 0) "
    _oSQL:_sQuery += " AND SF3.F3_CFO >= '5000' "
    _oSQL:_sQuery += " GROUP BY SF3.F3_CFO "
    _oSQL:_sQuery += " ORDER BY SF3.F3_CFO "
    _aSaidas := aclone (_oSQL:Qry2Array ())

    oSection6:Init()
	oSection6:SetHeaderSection(.T.)

    For _x:=1 to Len(_aSaidas)
        oSection6:Cell("COLUNA1")  :SetBlock({|| _aSaidas[_x,  1] }) 
        oSection6:Cell("COLUNA2")  :SetBlock({|| _aSaidas[_x,  2] }) 
        oSection6:Cell("COLUNA3")  :SetBlock({|| _aSaidas[_x,  3] }) 
        oSection6:Cell("COLUNA4")  :SetBlock({|| _aSaidas[_x,  4] }) 
        oSection6:Cell("COLUNA5")  :SetBlock({|| _aSaidas[_x,  5] }) 
        oSection6:Cell("COLUNA6")  :SetBlock({|| _aSaidas[_x,  6] }) 
        oSection6:Cell("COLUNA7")  :SetBlock({|| _aSaidas[_x,  7] }) 

        oSection6:PrintLine()
    Next
    oSection6:Finish()

Return
//
// ----------------------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de                     ", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial até                    ", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Entrada de            ", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Entrada até           ", "D", 8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {05, "Estado                        ", "C", 2, 0,  "",   "   ", {},                         ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
