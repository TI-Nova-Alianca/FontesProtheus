//  Programa...: VA_DIGXDIS
//  Autor......: Cláudia Lionço
//  Data.......: 18/01/2021
//  Descricao..: Relatório de clientes a receber - Data de digitação X data de disponibilização
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de clientes a receber - Data de digitação X data de disponibilização
// #PalavasChave      #data_de_dogitacao #data_de_disponibilizacao #clientes_a_receber
// #TabelasPrincipais #SE1 #SE5
// #Modulos 		  #FIN #CTB
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_DIGXDIS()
	Private oReport
	Private cPerg := "VA_DIGXDIS"
	
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
    Local oBreak

    oReport := TReport():New("VA_DIGXDIS","Dt.Digitacao X Dt.Disponibilizacao em meses diferentes",cPerg,{|oReport| PrintReport(oReport)},"Dt.Digitacao X Dt.Disponibilizacao em meses diferentes")
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Titulo"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente/Loja"	,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Nome"		    ,       				,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Dt.Digitacao"	,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Dt.Dispo."	    ,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Valor"		    , "@E 999,999,999.99"   ,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    TRFunction():New(oSection1:Cell("COLUNA7"),"Valor Total","SUM",oBreak,,"@E 99,999,999.99",,.T.,.F.,.F.,oSection1)      
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aDados   := {}
    Local i         := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		E5_FILIAL AS FILIAL"
    _oSQL:_sQuery += "	   ,E5_NUMERO + '/' + E5_PREFIXO + '/' + E5_PARCELA AS TITULO"
    _oSQL:_sQuery += "	   ,E5_CLIFOR + '/' + E5_LOJA AS CLIENTE"
    _oSQL:_sQuery += "	   ,E1_NOMCLI AS NOMECLIENTE"
    _oSQL:_sQuery += "	   ,E5_DTDIGIT AS DIGITACAO"
    _oSQL:_sQuery += "	   ,E5_DTDISPO AS DISPONIB"
    _oSQL:_sQuery += "	   ,E5_VALOR AS VALOR"
    _oSQL:_sQuery += "	FROM SE5010 SE5"
    _oSQL:_sQuery += "	INNER JOIN SE1010 SE1"
    _oSQL:_sQuery += "		ON (SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "				AND SE1.E1_FILIAL = SE5.E5_FILIAL"
    _oSQL:_sQuery += "				AND SE1.E1_NUM = SE5.E5_NUMERO"
    _oSQL:_sQuery += "				AND SE1.E1_PREFIXO = SE5.E5_PREFIXO"
    _oSQL:_sQuery += "				AND SE1.E1_PARCELA = SE5.E5_PARCELA"
    _oSQL:_sQuery += "				AND SE1.E1_CLIENTE = SE5.E5_CLIFOR"
    _oSQL:_sQuery += "				AND SE1.E1_LOJA = SE5.E5_LOJA)"
    _oSQL:_sQuery += "	WHERE SE5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "	AND E5_FILIAL BETWEEN'" + mv_par01 + "' and '" + mv_par02 + "'"
    _oSQL:_sQuery += "	AND E5_DTDIGIT BETWEEN '" + DTOS(mv_par03) + "' and '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	AND E5_DTDISPO > '" + dtos(mv_par04) +"'"
    _oSQL:_sQuery += "	ORDER BY SE1.E1_FILIAL, SE1.E1_NUM, SE1.E1_PREFIXO, SE1.E1_PARCELA"

    _aDados := _oSQL:Qry2Array ()

    oSection1:Init()

    For i := 1 to Len(_aDados)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1] })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3] })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[i,4] })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| STOD(_aDados[i,5]) })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| STOD(_aDados[i,6]) })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[i,7] })

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
    aadd (_aRegsPerg, {01, "Filial de        ", "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial ate       ", "C", 2, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Dt.Digitacao de  ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Dt.Digitacao ate ", "D", 8, 0,  "",   "   ", {},                        		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
