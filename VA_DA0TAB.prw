// Programa: VA_DA0TAB
// Autor...: Cláudia Lionço
// Data....: 06/10/2023
// Funcao..: Impressão de tabela de preço
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Impressão de tabela de preço
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0 #DA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_DA0TAB()
	Private oReport
	Private cPerg := "VA_DA0TAB"
	
    If ! U_ZZUVL ('156', __cUserID, .T.)
        u_help("Usuário sem permissão no grupo 156!")
		return
	EndIf
    
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
    Local oBreak

	oReport := TReport():New("VA_DA0TAB","Impressão de tabela de preço",cPerg,{|oReport| PrintReport(oReport)},"Impressão de tabela de preço")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				    , 10,/*lPixel*/,{||     },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Tabela"		,       					, 10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Descrição"		,       					, 30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"Item"		    ,       					, 08,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Produto"		,       					, 20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Estado"		,       					, 08,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Preço Venda"	, "@E 999,999,999.99"   	, 20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Vlr.ST"	    , "@E 999,999,999.99"   	, 20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak := TRBreak():New(oSection1,oSection1:Cell("COLUNA2"),"",.T.,"",.T.)
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local _aDados   := {}
	Local _x        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DA0.DA0_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,DA0.DA0_CODTAB AS TABELA "
    _oSQL:_sQuery += "    ,DA0.DA0_DESCRI AS DESCRICAO "
    _oSQL:_sQuery += "    ,DA1.DA1_ITEM AS ITEM "
    _oSQL:_sQuery += "    ,DA1.DA1_CODPRO AS PRODUTO "
    _oSQL:_sQuery += "    ,DA1.DA1_ESTADO AS ESTADO "
    _oSQL:_sQuery += "    ,DA1.DA1_PRCVEN AS PRECO_VENDA "
    _oSQL:_sQuery += "    ,DA1.DA1_VAST AS VALOR_ST "
    _oSQL:_sQuery += " FROM " + RetSQLName ("DA0") + " AS DA0 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("DA1") + " AS DA1 "
    _oSQL:_sQuery += " 	ON DA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND DA1.DA1_FILIAL = DA0.DA0_FILIAL "
    _oSQL:_sQuery += " 		AND DA1.DA1_CODTAB = DA0.DA0_CODTAB "
    _oSQL:_sQuery += " 		AND DA1.DA1_CODPRO BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
    _oSQL:_sQuery += " 		AND DA1_ESTADO BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"' "
    _oSQL:_sQuery += " WHERE DA0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND DA0.DA0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
    _oSQL:_sQuery += " AND DA0_ATIVO <> '2' "
    _oSQL:_sQuery += " AND DA0_CODTAB BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
    _oSQL:_sQuery += " ORDER BY DA0.DA0_FILIAL, DA0.DA0_CODTAB, DA1.DA1_ITEM "

    _aDados := aclone (_oSQL:Qry2Array ())

	For _x :=1 to Len(_aDados)

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2] }) 
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 3] }) 
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_x, 4] }) 
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_x, 5] }) 
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[_x, 6] }) 
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[_x, 7] }) 
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[_x, 8] }) 

		oSection1:PrintLine()
        
	Next

	oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de         ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial até        ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Tabela de         ", "C",  3, 0,  "",       "DA0", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Tabela até        ", "C",  3, 0,  "",       "DA0", {},                         		 ""})
    aadd (_aRegsPerg, {05, "Produto de        ", "C", 15, 0,  "",       "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {06, "Produto até       ", "C", 15, 0,  "",       "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {07, "Estado de         ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {08, "Estado até        ", "C",  2, 0,  "",       "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
