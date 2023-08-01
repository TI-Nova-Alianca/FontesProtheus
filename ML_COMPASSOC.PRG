//  Programa...: ML_COMPASSOC
//  Autor......: Catia Cardoso
//  Data.......: 08/02/2019
//  Descricao..: Relatorio de compras de associados
//
// #TipoDePrograma    #Relatório
// #Descricao         #Relatorio de compras de associados
// #PalavasChave      #associados #vendas #lojas
// #TabelasPrincipais #SL1 #SA3 #SF3 #SD1
// #Modulos 		  #LOJA
//
//  Historico de alteracoes:
// 30/10/2020 - Cláudia - Repassado para novo modelo de relatorio e acrescentada 
//                        coluna de status. GLPI: 8724
// 02/05/2022 - Claudia - Incluída validação para o campo L1_IndCtb.
// 01/08/2023 - Claudia - Incluido distinct na consulta. GLPI: 14028
//
// ------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function ML_COMPASSOC()
	Private oReport
	Private cPerg := "ML_COMPASSOC"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil

    oReport := TReport():New("ML_COMPASSOC","Compras de Associados",cPerg,{|oReport| PrintReport(oReport)},"Compras de Associados")
	
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Loja"			,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Dt.Emissão"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cupom"			,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Série"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Cliente"		,       				,45,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Código/Loja"	,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Valor"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Int.C/C"		,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Status"		,   					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
	Local oBreak1
    Local _aDados   := {}
    Local i         := 0
	Local _nVendas  := 0
	Local _nDevol   := 0
	Local _nCanc    := 0

	If mv_par07 == 2
		oBreak1 := TRBreak():New(oSection1,{|| oSection1:Cell("COLUNA7"):uPrint },"Total por associado")
		TRFunction():New(oSection1:Cell("COLUNA8")	,,"SUM"	,oBreak1, "Valor total ", "@E 999,999,999,999.99", NIL, .F., .F.)
	EndIf
	
    _oSQL  := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT DISTINCT "
	_oSQL:_sQuery += "	SL1.L1_FILIAL"
	_oSQL:_sQuery += "   ,CASE"
	_oSQL:_sQuery += "		WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS'"
	_oSQL:_sQuery += "		WHEN SL1.L1_FILIAL = '10' THEN 'FLORES'"
	_oSQL:_sQuery += "		WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO'"
	_oSQL:_sQuery += "		ELSE 'VICENTINA'"
	_oSQL:_sQuery += "	END AS LOJA_NOME"
	_oSQL:_sQuery += "   ,SL1.L1_EMISNF"
	_oSQL:_sQuery += "   ,SL1.L1_DOC"
	_oSQL:_sQuery += "   ,SL1.L1_SERIE"
	_oSQL:_sQuery += "   ,SA2.A2_NOME"
	_oSQL:_sQuery += "   ,SA2.A2_COD"
	_oSQL:_sQuery += "   ,SA2.A2_LOJA"
	_oSQL:_sQuery += "   ,SL4.L4_VALOR"
	_oSQL:_sQuery += "   ,SL1.L1_INDCTB"
	_oSQL:_sQuery += "   ,CASE"
	_oSQL:_sQuery += "		WHEN (SELECT"
	_oSQL:_sQuery += "					COUNT(*)"
	_oSQL:_sQuery += "				FROM SD1010"
	_oSQL:_sQuery += "				WHERE D1_NFORI = SL1.L1_DOC"
	_oSQL:_sQuery += "				AND D1_SERIORI = SL1.L1_SERIE"
	_oSQL:_sQuery += "				AND D1_FILIAL = SL1.L1_FILIAL)"
	_oSQL:_sQuery += "			> 0 THEN 'DEVOLVIDO'"
	_oSQL:_sQuery += "		WHEN SF3.F3_DTCANC <> '' THEN 'CANCELADO'"
	_oSQL:_sQuery += "		ELSE '-'"
	_oSQL:_sQuery += "	END AS STA"
	_oSQL:_sQuery += " FROM " + RetSqlName("SL1") + " SL1"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName("SL4") + " SL4"
	_oSQL:_sQuery += "	ON (SL4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "			AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_oSQL:_sQuery += "			AND SL4.L4_NUM = SL1.L1_NUM"
	_oSQL:_sQuery += "			AND SL4.L4_FORMA = 'CO'"
	_oSQL:_sQuery += "			AND SL4.L4_ADMINIS LIKE '%800 %')"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName("SA2") + " SA2"
	_oSQL:_sQuery += "	ON (SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "			AND SA2.A2_CGC = SL1.L1_CGCCLI"
	_oSQL:_sQuery += "			AND SA2.A2_LOJA = SL1.L1_LOJA"
	_oSQL:_sQuery += "			AND SA2.A2_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_oSQL:_sQuery += " INNER JOIN " + RetSqlName("SF3") + "  SF3"
	_oSQL:_sQuery += "	ON (SF3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "			AND SF3.F3_FILIAL = SL1.L1_FILIAL"
	_oSQL:_sQuery += "			AND SF3.F3_NFISCAL = SL1.L1_DOC"
	_oSQL:_sQuery += "			AND SF3.F3_SERIE = SL1.L1_SERIE)"
	_oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SL1.L1_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_oSQL:_sQuery += " AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
	_oSQL:_sQuery += " AND SL1.L1_DOC != ''"
	if mv_par07 = 2
		_oSQL:_sQuery += " ORDER BY SA2.A2_NOME, SL1.L1_EMISNF"
	else
		_oSQL:_sQuery += " ORDER BY SL1.L1_EMISNF"
	EndIf
	
    _aDados := _oSQL:Qry2Array ()

    oSection1:Init()

    For i := 1 to Len(_aDados)
		_sCodCli := _aDados[i,7] + "/" + _aDados[i,8]

		If empty(_aDados[i,10])
			_sIndCtb := 'N'
		else
			_sIndCtb := 'S'
		EndIf
		
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1]  })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2]  })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3]  })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[i,4]  })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[i,5]  })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[i,6]  })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _sCodCli 	   })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[i,9]  })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[i,10]  })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[i,11] })

		Do Case
			Case alltrim(_aDados[i,11]) == 'DEVOLVIDO'
				_nDevol   += _aDados[i,9] 
			Case alltrim(_aDados[i,11]) == 'CANCELADO'
				_nCanc    += _aDados[i,9] 
			otherwise
				_nVendas  += _aDados[i,9] 
		EndCase	 
        oSection1:PrintLine()
    Next

    oSection1:Finish()

	oReport:ThinLine()
	_nLinha :=  oReport:Row()

	oReport:PrintText("VENDAS TOTAL: ",_nLinha, 100)
	oReport:PrintText(PADL('R$' + Transform(_nVendas, "@E 999,999,999.99"),20,' '),_nLinha, 700)
	oReport:SkipLine(1) 

	_nLinha :=  oReport:Row()
	oReport:PrintText("CANCELAMENTO TOTAL: ",_nLinha, 100)
	oReport:PrintText(PADL('R$' + Transform(_nCanc, "@E 999,999,999.99"),20,' '),_nLinha, 700)
	oReport:SkipLine(1) 

	_nLinha :=  oReport:Row()
	oReport:PrintText("DEVOLUÇÃO TOTAL: ",_nLinha, 100)
	oReport:PrintText(PADL('R$' + Transform(_nDevol, "@E 999,999,999.99"),20,' '),_nLinha, 700)
	oReport:SkipLine(1) 
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Loja de                 ", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Loja até                ", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Compra          ", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Compra          ", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {05, "Associado de            ", "C", 6, 0,  "",  "SA2", {},                         "Associado Inicial"})
	aadd (_aRegsPerg, {06, "Associado até           ", "C", 6, 0,  "",  "SA2", {},                         "Associado Final"})
	aadd (_aRegsPerg, {07, "Total por Associado     ", "N", 1, 0,  "",  "   ", {"Nao", "Sim"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
