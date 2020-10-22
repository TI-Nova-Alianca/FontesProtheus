//  Programa...: VA_COMRDEV
//  Autor......: Cláudia Lionço
//  Data.......: 15/10/2020
//  Cliente....: Alianca
//  Descricao..: Relatório de devoluções para Comissoes
//
// #TipoDePrograma    #relatorio
// #PalavasChave      #comissoes #devolucao #representante 
// #TabelasPrincipais #SE5 #SA1
// #Modulos 		  #FIN 
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

User Function VA_COMRDEV()
	Private oReport
	Private cPerg := "VA_COMRDEV"
	
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

    oReport := TReport():New("VA_COMRDEV","Registros de devoluções",cPerg,{|oReport| PrintReport(oReport)},"Registros de devoluções")
	
	// DEVOLUÇÕES
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Data"					,	    				,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Cliente"				,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Nome"					,       				,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Título"				,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Prefixo"				,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Parc."					,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Valor"					, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Vendedor"				,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Nome"					,       				,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local _aDev     := {}
    Local _sMot     := ""
    Local i         := 0
    
    If mv_par03 == 1
        _sMot := 'CMP'
    else
        _sMot := 'DEB'
    EndIf

    _oSQL  := ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		E5_DATA AS DT_MOV"
    _oSQL:_sQuery += "	   ,E5_CLIFOR AS CLIENTE"
    _oSQL:_sQuery += "	   ,E5_BENEF AS CLIENTE_NOME"
    _oSQL:_sQuery += "	   ,E5_NUMERO AS TITULO"
    _oSQL:_sQuery += "	   ,E5_PREFIXO AS PREFIXO"
    _oSQL:_sQuery += "	   ,E5_PARCELA AS PARCELA"
    _oSQL:_sQuery += "	   ,E5_VALOR AS VALOR"
    _oSQL:_sQuery += "	   ,SA1.A1_VEND AS VENDEDOR"
    _oSQL:_sQuery += "	   ,SA3.A3_NOME AS VEND_NOME"
    _oSQL:_sQuery += "	FROM " + RetSQLName ("SE5") + " AS SE5 "
    _oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
    _oSQL:_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "				AND SA1.A1_COD = SE5.E5_CLIFOR"
    _oSQL:_sQuery += "				AND SA1.A1_LOJA = SE5.E5_LOJA)"
    _oSQL:_sQuery += "	INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
    _oSQL:_sQuery += "		ON (SA3.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "				AND SA3.A3_COD = SA1.A1_VEND)"
    _oSQL:_sQuery += "	WHERE SE5.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "	AND E5_FILIAL = '" + xFilial('SE5') + "' "
    _oSQL:_sQuery += "	AND E5_TIPO = 'NCC'"
    _oSQL:_sQuery += "	AND E5_DATA BETWEEN '" + DTOS(mv_par01) + "' and '" + dtos(mv_par02) + "'"
    _oSQL:_sQuery += "	AND E5_MOTBX = 'CMP'"
    _oSQL:_sQuery += "	AND E5_NATUREZ <> '"+ _sMot +"'"
    _oSQL:_sQuery += "	ORDER BY E5_DATA"
    _aDev := _oSQL:Qry2Array ()

    oSection1:Init()

    For i := 1 to Len(_aDev)
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| STOD(_aDev[i,1]) })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDev[i,2] })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDev[i,3] })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDev[i,4] })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDev[i,5] })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDev[i,6] })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDev[i,7] })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDev[i,8] })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDev[i,9] })

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
    aadd (_aRegsPerg, {01, "Data de          ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data ate         ", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Tipo             ", "N", 1, 0,  "",   "   ", {"CMP","DEB"},                        		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
