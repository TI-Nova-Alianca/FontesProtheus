// Programa...: VA_ORDPRE
// Autor......: Sandra Sugari
// Data.......: 25/06/2021
// Descricao..: Relatorio Ordens de Manutenção Preventivas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio Ordens de Manutenção Preventivas
// #PalavasChave      #ordens_manutenção#preventivas
// #TabelasPrincipais #STJ #ST4 #ST9 #STL #ST1
// #Modulos   		  #MANUTENÇÃO ATIVOS
//
// Historico de alteracoes:
// 
//
// ------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function VA_ORDPRE()
	Private oReport
	Private cPerg   := "VA_ORDPRE"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil

	oReport := TReport():New("VA_ORDPRE","Relatorio Ordens de Manutenção Preventivas",cPerg,{|oReport| PrintReport(oReport)},"Relatorio Ordens de Manutenção Preventivas")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"            ,	    			, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Ordem"		       ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Plano"			   ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cod Bem"   	   ,					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Nome do Bem"	   ,                    ,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Serviço"		   ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Nome do Serviço"  ,       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Data Inicio"	   ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Data Fim"         ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Executante"	   ,                    ,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Observação"	   ,        			,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	
	
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _oSQL      := ClsSQL ():New ()

_oSQL:_sQuery := ""
_oSQL:_sQuery += " SELECT "
_oSQL:_sQuery += "  	STJ.TJ_FILIAL AS FILIAL "
_oSQL:_sQuery += "     ,STJ.TJ_ORDEM AS ORDEM "
_oSQL:_sQuery += "     ,STJ.TJ_PLANO AS PLANO "
_oSQL:_sQuery += "     ,STJ.TJ_CODBEM AS CODBEM "
_oSQL:_sQuery += "     ,ST9.T9_NOME AS NOME_BEM "
_oSQL:_sQuery += "     ,STJ.TJ_SERVICO AS SERVI "
_oSQL:_sQuery += "     ,ST4.T4_NOME AS NOME_SERVICO "
_oSQL:_sQuery += "     ,STJ.TJ_DTMPINI AS DT_INICIO "
_oSQL:_sQuery += "     ,STJ.TJ_DTMPFIM AS DT_FIM "
_oSQL:_sQuery += "     ,ST1.T1_NOME AS EXECUTANTE "
_oSQL:_sQuery += "     ,ISNULL(CAST(CAST (STJ.TJ_OBSERVA AS VARBINARY (8000)) AS VARCHAR (8000)), '') AS OBSERV "
_oSQL:_sQuery += " FROM " + RETSQLName ("STJ") + " STJ "
_oSQL:_sQuery += "       INNER JOIN " + RETSQLName ("ST9") + " ST9 " // LIGAÇÃO DA TAB PRINCIPAL 
_oSQL:_sQuery += "	     ON (ST9.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "			AND ST9.T9_FILIAL = STJ.TJ_FILIAL "
_oSQL:_sQuery += "	        AND ST9.T9_CODBEM = STJ.TJ_CODBEM) "

_oSQL:_sQuery += "		 INNER JOIN  " + RETSQLName ("ST4") + " ST4 " // LIGAÇÃO DA TAB PRINCIPAL 
_oSQL:_sQuery += "		 ON (ST4.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "			AND ST4.T4_SERVICO = STJ.TJ_SERVICO) "

_oSQL:_sQuery += "		 INNER JOIN  " + RETSQLName ("STL") + " STL " // LIGAÇÃO DA TAB PRINCIPAL 
_oSQL:_sQuery += "				LEFT JOIN  " + RETSQLName ("ST1") + " ST1 " // LIGAÇÃO DA TAB STL COM OUTRA TAB "
_oSQL:_sQuery += "					ON (ST1.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "						AND STL.TL_CODIGO = ST1.T1_CODFUNC) "
_oSQL:_sQuery += " 		 ON (STL.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "			AND STL.TL_ORDEM = STJ.TJ_ORDEM "
_oSQL:_sQuery += "			AND STL.TL_FILIAL = STJ.TJ_FILIAL "
_oSQL:_sQuery += "			AND STL.TL_PLANO = STJ.TJ_PLANO) "
_oSQL:_sQuery += " WHERE STJ.TJ_TIPO = 'PRE' "
_oSQL:_sQuery += " AND STJ.D_E_L_E_T_ = '' "
_oSQL:_sQuery += " AND STJ.TJ_DTMPINI >= '" + dtos (MV_PAR01) + "'"
_oSQL:_sQuery += " AND STJ.TJ_DTMPFIM <= '" + dtos (MV_PAR02) + "'"
_oSQL:_sQuery += " AND STJ.TJ_CODBEM BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
_oSQL:_sQuery += " AND ST1.T1_CODFUNC BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
_oSQL:_sQuery += " ORDER BY STJ.TJ_DTMPINI "

	// nHandle := FCreate("c:\temp\log.txt")
	// FWrite(nHandle, _oSQL:_sQuery )
	// FClose(nHandle)

	_sAliasQ := _oSQL:Qry2Trb (.f.)
	(_sAliasQ) -> (dbgotop ())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While !(_sAliasQ) -> (eof ())
		


		oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> FILIAL       	})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| (_sAliasQ) -> ORDEM     		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| (_sAliasQ) -> PLANO      		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> CODBEM       	})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| (_sAliasQ) -> NOME_BEM    	    })
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| (_sAliasQ) -> SERVI    	    })
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| (_sAliasQ) -> NOME_SERVICO     })
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| Stod((_sAliasQ)-> DT_INICIO    )})
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| Stod((_sAliasQ)-> DT_FIM       )})
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| (_sAliasQ) -> EXECUTANTE       })
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| (_sAliasQ) -> OBSERV           })

		oSection1:PrintLine()
		
		(_sAliasQ) -> (dbskip ())
	Enddo
	oSection1:Finish()
	(_sAliasQ) -> (dbclosearea ())
Return
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                      TIPO   TAM DEC VALID F3     Opcoes                      				Help
	aadd (_aRegsPerg, {01, "Data Inicio                ?", "D", 8, 0,  "",  "   ", {},                         						""})
    aadd (_aRegsPerg, {02, "Data Fim                   ?", "D", 8, 0,  "",  "   ", {},                         						""})
    aadd (_aRegsPerg, {03, "Executante de              ?", "C",11, 0,  "",  "ST1", {},                         						"Executante Inicial"})
	aadd (_aRegsPerg, {04, "Executante até             ?", "C",11, 0,  "",  "ST1", {},                         						"Executante Final"})
    aadd (_aRegsPerg, {05, "Cod Bem de                 ?", "C",18, 0,  "",  "ST9", {},                         						""})
    aadd (_aRegsPerg, {06, "Cod Bem Até                ?", "C",18, 0,  "",  "ST9", {},                         						""})
	

     U_ValPerg (cPerg, _aRegsPerg)
Return
