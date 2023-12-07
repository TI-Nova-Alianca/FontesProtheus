// Programa: VA_DA0LOG
// Autor...: Cláudia Lionço
// Data....: 02/10/2023
// Funcao..: Log de alteração de tabelas de preço
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Log de alteração de tabelas de preço
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0 #DA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 07/12/2023 - Claudia - Incluido filtro de tabela de preço. GLPI: 14604
//
// ---------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_DA0LOG()
	Private oReport
	Private cPerg := "VA_DA0LOG"
	
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

	oReport := TReport():New("VA_DA0LOG","Logs de alteração de tabelas de preço",cPerg,{|oReport| PrintReport(oReport)},"Logs de alteração de tabelas de preço")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Data"		    ,	    					, 15,/*lPixel*/,{||     },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA2", 	"" ,"Tabela"		,       					, 10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Usuário"		,       					, 25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Descrição"		,       					,250,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

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
    _oSQL:_sQuery += " SELECT TOP 100 "
    _oSQL:_sQuery += " 	   DATA "
    _oSQL:_sQuery += "    ,USUARIO "
    _oSQL:_sQuery += "    ,TRIM(PRODUTO) "
    _oSQL:_sQuery += "    ,TRIM(DESCRITIVO) "
    _oSQL:_sQuery += "    ,CODIGO_ALIAS "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " WHERE (CODEVENTO LIKE ('%DA0%') "
    _oSQL:_sQuery += " OR CODEVENTO LIKE ('%DA1%')) "
    _oSQL:_sQuery += " AND CODIGO_ALIAS = '" + mv_par03 + "'"
    if !empty(mv_par01)
        _oSQL:_sQuery += " AND DATA BETWEEN '" + dtos(mv_par01) + "' AND '"+ dtos(mv_par02) + "'"
    endif
    _oSQL:_sQuery += " ORDER BY DATA DESC "
    _aDados := aclone (_oSQL:Qry2Array ())

	For _x :=1 to Len(_aDados)

        If !empty(_aDados[_x, 3])
            _sDesc := alltrim(_aDados[_x, 3]) + '-' + alltrim(_aDados[_x, 4])
        else
            _sDesc := alltrim(_aDados[_x, 4])
        EndIf
        
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| stod(_aDados[_x, 1])   }) 
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 5]         }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 2]         }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _sDesc                 }) 

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
    aadd (_aRegsPerg, {01, "Data de         ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data até        ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Tabela          ", "C", 3, 0,  "",   "DA0", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
