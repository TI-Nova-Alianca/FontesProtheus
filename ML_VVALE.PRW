// Programa..: ML_VVALE.PRW
// Autor.....: Sandra Sugari
// Data......: 09/07/2021
// Descricao..: Vendas/Recebimentos de Vales para Associados
//      
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Vendas/Recebimentos de Vales para Associados
// #PalavasChave      #vale #cupom #cliente #associados
// #TabelasPrincipais #MDD #SA1
// #Modulos           #SIGALOJA
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

User function ML_VVALE()
	Private oReport
	Private cPerg   := "ML_VVALE"
	
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

	oReport := TReport():New("ML_VVALE","Vendas/Recebimentos de Vales para Associados  ",cPerg,{|oReport| PrintReport(oReport)},"Vendas/Recebimentos de Vales para Associados ")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Vale"               ,	    			   	,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	//TRCell():New(oSection1,"COLUNA2", 	"" ,"Vlr_Vale"	         , "@E 999,999,999.99"  , 6,/*lPixel*/,{|| 	},"RIGHT",,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cup Venda"	         ,       				, 6,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Ser Venda"   	     ,						, 3,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"DT Venda"	         ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Cli Venda"	         ,       		    	, 6,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Nom Venda"		     ,       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Lj Cli Venda"	     ,       		    	, 2,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Cup Rec"		     ,       				, 6,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Ser Rec"		     ,       				, 3,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"DT Rec"		     ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Cli Rec"            ,	    	        	, 6,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"Nome Rec"      	 ,       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA14", 	"" ,"Lj Cli Rec"	     ,       			    , 2,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA15", 	"" ,"Lj Rec"			 ,       				, 6,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)


Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _oSQL      := ClsSQL ():New ()

_oSQL:_sQuery := ""
_oSQL:_sQuery += "SELECT "

_oSQL:_sQuery += "    MDD_CODIGO AS VALE "
//_oSQL:_sQuery += "   ,MDD_VALOR AS Vlr_VALE "
_oSQL:_sQuery += "   ,MDD_DOCV AS CUP_VENDA "
_oSQL:_sQuery += "   ,MDD_SERIV AS SERIE_VENDA "
_oSQL:_sQuery += "   ,MDD_DATAV AS DT_VENDA "
_oSQL:_sQuery += "   ,MDD_CLIV AS COD_CLI_VENDA "
_oSQL:_sQuery += "   ,V.A1_NOME AS CLI_VENDA "
_oSQL:_sQuery += "   ,MDD_LJCLIV AS LJ_CLI_VENDA "
_oSQL:_sQuery += "   ,MDD_DOCR AS CUP_REC "
_oSQL:_sQuery += "   ,MDD_SERIR AS SERIE_REC "
_oSQL:_sQuery += "   ,MDD_DATAR AS DT_REC "
_oSQL:_sQuery += "   ,MDD_CLIR AS COD_CLI_REC "
_oSQL:_sQuery += "   ,R.A1_NOME AS CLI_RECEBIMENTO "
_oSQL:_sQuery += "   ,MDD_LJCLIR AS LJ_CLI_REC "
_oSQL:_sQuery += "   ,MDD_LOJAR AS LJ_REC "
_oSQL:_sQuery += " FROM MDD010 "
_oSQL:_sQuery += "	,SA1010 V "
_oSQL:_sQuery += "	,SA1010 R "
_oSQL:_sQuery += " WHERE MDD010.D_E_L_E_T_ = '' "
_oSQL:_sQuery += " AND V.D_E_L_E_T_ = '' "
_oSQL:_sQuery += " AND R.D_E_L_E_T_ = '' "
_oSQL:_sQuery += " AND R.A1_FILIAL='' "
_oSQL:_sQuery += " AND V.A1_FILIAL=''"
_oSQL:_sQuery += " AND MDD_FILIAL=''"
_oSQL:_sQuery += " AND MDD_CLIV = V.A1_COD "
_oSQL:_sQuery += " AND MDD_LJCLIV = V.A1_LOJA "
_oSQL:_sQuery += " AND MDD_CLIR = R.A1_COD "
_oSQL:_sQuery += " AND MDD_LJCLIR = R.A1_LOJA "
_oSQL:_sQuery += " AND MDD_DOCR != '' "
_oSQL:_sQuery += " AND MDD_SERIR != '' "
if !empty (mv_par01)
    _oSQL:_sQuery += " AND MDD_CLIV = '" + mv_par01 +  "' "
EndIf	
if !empty (mv_par02) 
    _oSQL:_sQuery += " AND MDD_LJCLIV = '" + mv_par02 + "' "
EndIf
if !empty (mv_par03)
	_oSQL:_sQuery += " AND MDD_CLIR = '" + mv_par03 + "' "
EndIf
if !empty (mv_par04)
	_oSQL:_sQuery += " AND MDD_LJCLIR = '" + mv_par04 + "' "
EndIf
if !empty (mv_par05) .and. !empty (mv_par06)
	_oSQL:_sQuery += " AND MDD_CODIGO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
EndIf
if !empty (mv_par07)
	_oSQL:_sQuery += " AND MDD_DOCR = '" + mv_par07 + "' "  

//EndCase 
  EndIf
	_oSQL:_sQuery += " ORDER BY MDD_CODIGO "

	// nHandle := FCreate("c:\temp\log.txt")
	// FWrite(nHandle, _oSQL:_sQuery )
	// FClose(nHandle)

	_oSQL:LOG ()
	_sAliasQ := _oSQL:Qry2Trb (.f.)
	(_sAliasQ) -> (dbgotop ())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While !(_sAliasQ) -> (eof ())
		
	    oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> Vale                 	})
		//oSection1:Cell("COLUNA2")	:SetBlock   ({|| (_sAliasQ) -> Vlr_Vale     	    	})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| (_sAliasQ) -> Cup_Venda        		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> Serie_Venda      		})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| Stod((_sAliasQ)-> DT_Venda)            })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| (_sAliasQ) -> Cod_Cli_Venda           	})
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| (_sAliasQ) -> Cli_Venda            	})
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| (_sAliasQ) -> Lj_Cli_Venda         	})
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| (_sAliasQ) -> Cup_Rec              	})
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| (_sAliasQ) -> Serie_Rec            	})
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| Stod((_sAliasQ)-> DT_Rec)              })
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| (_sAliasQ) -> Cod_Cli_Rec              })
		oSection1:Cell("COLUNA13")	:SetBlock   ({|| (_sAliasQ) -> Cli_Recebimento     	    })
        oSection1:Cell("COLUNA14")	:SetBlock   ({|| (_sAliasQ) -> Lj_Cli_Rec           	})
        oSection1:Cell("COLUNA15")	:SetBlock   ({|| (_sAliasQ) -> Lj_Rec   	            })

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
    //                     PERGUNT                      TIPO TAM DEC VALID  F3   Opcoes                      				       Help
	aadd (_aRegsPerg, {01, "Cliente Venda             ?", "C",11, 0,  "",  "SA1", {},                         						""})
	aadd (_aRegsPerg, {02, "Loja Cliente Venda        ?", "C", 2, 0,  "",  "SA1", {},                         						""})
    aadd (_aRegsPerg, {03, "Cliente Rec               ?", "C",11, 0,  "",  "SA1", {},                         						""})
    aadd (_aRegsPerg, {04, "Loja CLiente Rec          ?", "C", 2, 0,  "",  "SA1", {},                         						""})
    aadd (_aRegsPerg, {05, "Vale de                   ?", "C", 9, 0,  "",  "MDD", {},                         						""})
    aadd (_aRegsPerg, {06, "Vale Até                  ?", "C", 9, 0,  "",  "MDD", {},                         						""})
	aadd (_aRegsPerg, {07, "Cupom Rec                 ?", "C", 6, 0,  "",  "MDD", {},                                               ""})
    

     U_ValPerg (cPerg, _aRegsPerg)
Return
