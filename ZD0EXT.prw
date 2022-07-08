// Programa...: ZD0EXT
// Autor......: Cláudia Lionço
// Data.......: 08/07/2022
// Descricao..: Extrato Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Extrato Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function ZD0EXT()
	Private oReport
	Private cPerg := "ZD0EXT"
	
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

	oReport := TReport():New("ZD0EXT","Extrato Pagar.me",cPerg,{|oReport| PrintReport(oReport)},"Extrato Pagar.me")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		    ,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Id Recebível"		,       					,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Id Transação"	    ,       					,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Dt.Pgto"	        ,                         	,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Método Pgto"	    ,                         	,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Bandeira"	        ,							,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Nota"			    ,	    					,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Série"	            ,	    					,10,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Parcela"	        ,	    					,10,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Status Baixa"	    ,   	                    ,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Dt.Baixa"	        ,                       	,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Vlr.Parcela"	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA13", 	"" ,"Vlr.Taxa"	        , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA14", 	"" ,"Taxa Antecipação"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA15", 	"" ,"Taxa Antifraude"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA16", 	"" ,"Total Líquido"	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
    TRFunction():New(oSection1:Cell("COLUNA12")	,,"SUM"	,oBreak1,"Total Vlr.Parcela "       , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA13")	,,"SUM"	,oBreak1,"Total Taxa "              , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA14")	,,"SUM"	,oBreak1,"Total Taxa Antecipação "  , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA15")	,,"SUM"	,oBreak1,"Total Taxa Antifraude"    , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA16")	,,"SUM"	,oBreak1,"Total Líquido"            , "@E 99,999,999.99", NIL, .F., .T.)
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
    Local oSection1   := oReport:Section(1)	
    Local _aDados     := {}
    Local i           := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "		ZD0_FILIAL AS FILIAL "
    _oSQL:_sQuery += "	   ,ZD0_RID AS ID_RECEBIVEL "
    _oSQL:_sQuery += "	   ,ZD0_TID AS ID_TRANSACAO "
    _oSQL:_sQuery += "	   ,ZD0_DTAPGT AS DATA_PGTO "
    _oSQL:_sQuery += "	   ,ZD0_PGTMET AS METODO_PGTO "
    _oSQL:_sQuery += "	   ,ZD0_CARDB AS CARTAO_BANDEIRA "
    _oSQL:_sQuery += "	   ,SC5.C5_NOTA AS NOTA "
    _oSQL:_sQuery += "	   ,SC5.C5_SERIE AS SERIE "
    _oSQL:_sQuery += "	   ,ZD0_PARCEL AS PARCELA "
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZD0_STABAI = 'A' THEN 'Aberto' "
    _oSQL:_sQuery += "			WHEN ZD0_STABAI = 'B' THEN 'Baixado' "
    _oSQL:_sQuery += "			WHEN ZD0_STABAI = 'F' THEN 'Fechado' "
    _oSQL:_sQuery += "		END AS STATUS_BAIXA "
    _oSQL:_sQuery += "	   ,ZD0_DTABAI AS DATA_BAIXA "
    _oSQL:_sQuery += "	   ,ZD0_VLRPAR AS VALOR_PARCELA "
    _oSQL:_sQuery += "	   ,ZD0_TAXA AS TAXA "
    _oSQL:_sQuery += "	   ,ZD0_TAXANT AS TAXA_ANTECIPACAO "
    _oSQL:_sQuery += "	   ,ZD0_TAXFRA AS TAXA_ANTIFRAUDE "
    _oSQL:_sQuery += "	   ,ZD0_VLRPAR - ZD0_TAXA - ZD0_TAXANT - ZD0_TAXFRA AS TOTAL_LIQUIDO "
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZD0") + " ZD0"
    _oSQL:_sQuery += "	LEFT JOIN " + RetSQLName ("SC5") + " SC5 "
    _oSQL:_sQuery += "		ON SC5.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SC5.C5_VAIDT <> '' "
    _oSQL:_sQuery += "			AND SC5.C5_VAIDT = ZD0_TID "
    _oSQL:_sQuery += "	WHERE ZD0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "	AND ZD0_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    _oSQL:_sQuery += "	AND ZD0_DTAPGT BETWEEN '" + dtos(mv_par03) + "' AND '" + dtos(mv_par04) + "'"
    _oSQL:_sQuery += "	ORDER BY ZD0_FILIAL, ZD0_DTAPGT "
    _aDados := _oSQL:Qry2Array ()

	oSection1:Init()

	For i:=1 to Len(_aDados)
      
        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1]       })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[i,2]       })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[i,3]       })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| STOD(_aDados[i,4]) })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[i,5]       })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[i,6]       })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[i,7]       })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[i,8]       })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[i,9]       })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[i,10]      })
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| STOD(_aDados[i,11])})
        oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aDados[i,12]      })
        oSection1:Cell("COLUNA13")	:SetBlock   ({|| _aDados[i,13]      })
        oSection1:Cell("COLUNA14")	:SetBlock   ({|| _aDados[i,14]      })
        oSection1:Cell("COLUNA15")	:SetBlock   ({|| _aDados[i,15]      })
        oSection1:Cell("COLUNA16")	:SetBlock   ({|| _aDados[i,16]      })

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
    aadd (_aRegsPerg, {01, "Filial de"       , "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial até "     , "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Data pgto de "   , "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Data pgto até "  , "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return

