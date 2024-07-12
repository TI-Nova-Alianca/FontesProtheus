// Programa...: ZD0RAS
// Autor......: Cláudia Lionço
// Data.......: 13/07/2022
// Descricao..: Gera títulos RA's dos recebíveis Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera títulos RA's dos recebíveis Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce #RA
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include "protheus.ch"
#include "tbiconn.ch"

User Function VA_SAFFOR()
	Private oReport
	Private cPerg := "VA_SAFFOR"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)

        _oAssoc := ClsAssoc():New (mv_par02, mv_par03)	
		If _oAssoc:EhSocio(dDataBase)
            u_help("O fornecedor selecionado é sócio. Deve-se imprimir o modelo de relatório <Associados>")
		Else
			oReport := ReportDef()
            oReport:PrintDialog()
		Endif

Return
//
//
// -------------------------------------------------------------------------
Static Function ReportDef()
    Local oReport   := Nil
	Local oSection1 := Nil

    oReport := TReport():New("VA_SAFFOR","Fechamento de Safra Não Associados",cPerg,{|oReport| PrintReport(oReport)},"Fechamento de Safra Não Associados")
	TReport():ShowParamPage()
	oReport:SetTotalInLine(.F.)
	//oReport:SetLandScape()
	
	// NOTAS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    TRCell():New(oSection1,"COLUNA01", 	"" ,"TIPO"		   ,	    				,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA02", 	"" ,"FILIAL"		,	    				,08,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA03", 	"" ,"NF/SERIE"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA04", 	"" ,"DT.EMISSÃO"	,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA05", 	"" ,"PRODUTO (UVA)"	,       				,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA06", 	"" ,"GRAU"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA07", 	"" ,"CLASS."		,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA08", 	"" ,"SIS.COND."     ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA09", 	"" ,"PESO"		    , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"VLR.UNITÁRIO"	, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"VLR.TOTAL"	    , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA01"),"Total por Tipo")
	TRFunction():New(oSection1:Cell("COLUNA09")	,,"SUM"	,oBreak1,""  , "@E 999,999,999.99", NIL, .F., .F., .F.)
	TRFunction():New(oSection1:Cell("COLUNA11")	,,"SUM"	,oBreak1,""  , "@E 999,999,999.99", NIL, .F., .F., .F.)

    // TOTAIS NOTAS
	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    TRCell():New(oSection2,"COLUNA01", 	"" ,"TOTALIZADOR"		   ,	    	,100,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection2,"COLUNA02", 	"" ,"VALOR"	    , "@E 999,999,999.99"   , 30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    // FATURAS
	oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    TRCell():New(oSection3,"COLUNA01", 	"" ,"MÊS/ANO REFERÊNCIA",	    			    ,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection3,"COLUNA02", 	"" ,"SALDO"	            , "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

     // VALOR EFETIVO
	oSection4 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
    TRCell():New(oSection4,"COLUNA01", 	"" ,"PRODUTO"		    ,	    			    ,40,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection4,"COLUNA02", 	"" ,"GRAU"              ,	    			    ,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection4,"COLUNA03", 	"" ,"CLASS."            ,	    			    ,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection4,"COLUNA04", 	"" ,"SIS.CONDUÇÃO"      ,	    			    ,15,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection4,"COLUNA05", 	"" ,"PESO"		        , "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA06", 	"" ,"VLR.UN.EFETIVO"    , "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection4,"COLUNA07", 	"" ,"VALOR TOTAL"	    , "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)	
    Local oSection2 := oReport:Section(2)	
    Local oSection3 := oReport:Section(3)	
    Local oSection4 := oReport:Section(4)	
    Local _aDados   := {}
    Local _x        := 0

    // NOTAS -----------------------------------------------------------------------
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   ASSOCIADO +'/'+ LOJA_ASSOC +' - ' + NOME_ASSOC "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN TIPO_NF = 'V' THEN 'NFs de Complemento Valor' "
    _oSQL:_sQuery += " 		    WHEN TIPO_NF = 'E' THEN 'NFs de ENTREGA de Uva' "
    _oSQL:_sQuery += " 		    WHEN TIPO_NF = 'C' THEN 'NFs de COMPRA de Uva' "
    _oSQL:_sQuery += " 		    WHEN TIPO_NF = 'P' THEN 'NFs de Produção Própria' "
    _oSQL:_sQuery += " 	   END DESC_TIPONF "
    _oSQL:_sQuery += "    ,FILIAL "
    _oSQL:_sQuery += "    ,DOC + '/' + SERIE AS NF "
    _oSQL:_sQuery += "    ,SUBSTRING(DATA, 7, 2) + '/' + SUBSTRING(DATA, 5, 2) + '/' + SUBSTRING(DATA, 1, 4) AS EMISSAO "
    _oSQL:_sQuery += "    ,TRIM(PRODUTO) + ' - ' + DESCRICAO AS PROD "
    _oSQL:_sQuery += "    ,GRAU "
    _oSQL:_sQuery += "    ,CLAS_ABD "
    _oSQL:_sQuery += "    ,SIST_CONDUCAO "
    _oSQL:_sQuery += "    ,PESO_LIQ "
    _oSQL:_sQuery += "    ,VALOR_UNIT "
    _oSQL:_sQuery += "    ,VALOR_TOTAL "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += " 		    WHEN TIPO_NF = 'V' THEN 'A' "
    _oSQL:_sQuery += " 		    ELSE TIPO_NF "
    _oSQL:_sQuery += " 	   END AS TIPO_NF "
    _oSQL:_sQuery += " FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += " WHERE SAFRA    = '"+ mv_par01 +"' "
    _oSQL:_sQuery += " AND ASSOCIADO  = '"+ mv_par02 +"' "
    _oSQL:_sQuery += " AND LOJA_ASSOC = '"+ mv_par03 +"' "
    _oSQL:_sQuery += " ORDER BY NOME_ASSOC, ASSOCIADO, LOJA_ASSOC, TIPO_NF DESC, DATA "
    _aDados := _oSQL:Qry2Array ()

    If len(_aDados) > 0
    oReport:SkipLine(1)
        oReport:PrintText(" FORNECEDOR:" + _aDados[1,1],,100)
        oReport:SkipLine(1)
        oReport:SkipLine(1)
    EndIf

    oSection1:Init()

    For _x := 1 to Len(_aDados)
        oSection1:Cell("COLUNA01")	:SetBlock   ({|| _aDados[_x, 2] })
        oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aDados[_x, 3] })
        oSection1:Cell("COLUNA03")	:SetBlock   ({|| _aDados[_x, 4] })
        oSection1:Cell("COLUNA04")	:SetBlock   ({|| _aDados[_x, 5] })
        oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aDados[_x, 6] })
        oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aDados[_x, 7] })
        oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aDados[_x, 8] })
        oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aDados[_x, 9] })
        oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aDados[_x,10] })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[_x,11] })
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aDados[_x,12] })

        oSection1:PrintLine()
    Next

    oSection1:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)

    // TOTAIS NOTAS ----------------------------------------------------------------
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT
    _oSQL:_sQuery += " 	  'TOTAL DO FORNECEDOR' AS TITULO "
    _oSQL:_sQuery += "    ,SUM(VALOR_TOTAL) AS VALOR "
    _oSQL:_sQuery += " FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += " WHERE SAFRA    = '" + mv_par01 + "' "
    _oSQL:_sQuery += " AND ASSOCIADO  = '" + mv_par02 + "' "
    _oSQL:_sQuery += " AND LOJA_ASSOC = '" + mv_par03 + "' "
    _oSQL:_sQuery += "      UNION ALL "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	  'TOTAL DE DESCONTOS (TAXA FUNRURAL)' AS TITULO "
    _oSQL:_sQuery += "    ,SUM(SE2.E2_VALOR) AS VALOR "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SE2") + " SE2 "
    _oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND E2_TIPO = 'TX' "
    _oSQL:_sQuery += " AND SE2.E2_NUM + SE2.E2_PREFIXO IN (SELECT "
    _oSQL:_sQuery += " 	DISTINCT "
    _oSQL:_sQuery += " 		DOC + SERIE "
    _oSQL:_sQuery += " 	FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += "  WHERE SAFRA    = '" + mv_par01 + "' "
    _oSQL:_sQuery += "  AND ASSOCIADO  = '" + mv_par02 + "' "
    _oSQL:_sQuery += "  AND LOJA_ASSOC = '" + mv_par03 + "' "
    _oSQL:_sQuery += " ) "
    _aDados := _oSQL:Qry2Array ()

    oSection2:Init()

    For _x := 1 to Len(_aDados)
        oSection2:Cell("COLUNA01")	:SetBlock   ({|| _aDados[_x, 1] })
        oSection2:Cell("COLUNA02")	:SetBlock   ({|| _aDados[_x, 2] })
        oSection2:PrintLine()
    Next

    oSection2:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)


    // PREVISAO DE PGTO ----------------------------------------------------------------
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		TRIM(PRODUTO) + ' - ' + DESCRICAO AS PROD "
    _oSQL:_sQuery += " 	   ,GRAU "
    _oSQL:_sQuery += " 	   ,CLAS_ABD "
    _oSQL:_sQuery += " 	   ,SIST_CONDUCAO "
    _oSQL:_sQuery += " 	   ,CASE "
    _oSQL:_sQuery += " 			WHEN SD1.D1_QUANT > 0 THEN SD1.D1_QUANT "
    _oSQL:_sQuery += " 			ELSE PESO_LIQ "
    _oSQL:_sQuery += " 		END AS PESO "
    _oSQL:_sQuery += " 	   ,CASE "
    _oSQL:_sQuery += " 			WHEN TIPO_NF = 'V' THEN VALOR_TOTAL / SD1.D1_QUANT "
    _oSQL:_sQuery += " 			ELSE VALOR_UNIT "
    _oSQL:_sQuery += " 		END AS VLR_EFETIVO_UNITARIO "
    _oSQL:_sQuery += " 	   ,VALOR_TOTAL "
    _oSQL:_sQuery += " 	FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += " 	LEFT JOIN " + RetSQLName ("SD1") + " SD1 "
    _oSQL:_sQuery += " 		ON SD1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SD1.D1_FILIAL = FILIAL "
    _oSQL:_sQuery += " 		AND SD1.D1_DOC = NF_ORIGEM "
    _oSQL:_sQuery += " 		AND SD1.D1_SERIE = SERIE_ORIGEM "
    _oSQL:_sQuery += " WHERE SAFRA    = '"+ mv_par01 +"' "
    _oSQL:_sQuery += " AND ASSOCIADO  = '"+ mv_par02 +"' "
    _oSQL:_sQuery += " AND LOJA_ASSOC = '"+ mv_par03 +"' "
    _oSQL:_sQuery += "  ) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   PROD
    _oSQL:_sQuery += "    ,GRAU "
    _oSQL:_sQuery += "    ,CLAS_ABD "
    _oSQL:_sQuery += "    ,SIST_CONDUCAO "
    _oSQL:_sQuery += "    ,PESO "
    _oSQL:_sQuery += "    ,ROUND(SUM(VLR_EFETIVO_UNITARIO), 2) AS VLR_UN_EFETIVO "
    _oSQL:_sQuery += "    ,SUM(VALOR_TOTAL) AS VALOR_TOTAL "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " GROUP BY PROD "
    _oSQL:_sQuery += " 		,GRAU "
    _oSQL:_sQuery += " 		,CLAS_ABD "
    _oSQL:_sQuery += " 		,SIST_CONDUCAO "
    _oSQL:_sQuery += " 		,PESO "
    _aDados := _oSQL:Qry2Array ()

    oReport:PrintText(" VALOR EFETIVO POR VARIEDADE:",,100)
    oSection4:Init()

    For _x := 1 to Len(_aDados)
        oSection4:Cell("COLUNA01")	:SetBlock   ({|| _aDados[_x, 1] })
        oSection4:Cell("COLUNA02")	:SetBlock   ({|| _aDados[_x, 2] })
        oSection4:Cell("COLUNA03")	:SetBlock   ({|| _aDados[_x, 3] })
        oSection4:Cell("COLUNA04")	:SetBlock   ({|| _aDados[_x, 4] })
        oSection4:Cell("COLUNA05")	:SetBlock   ({|| _aDados[_x, 5] })
        oSection4:Cell("COLUNA06")	:SetBlock   ({|| _aDados[_x, 6] })
        oSection4:Cell("COLUNA07")	:SetBlock   ({|| _aDados[_x, 7] })

        oSection4:PrintLine()
    Next

    oSection4:Finish()
    oReport:SkipLine(1)
    oReport:ThinLine()
    oReport:SkipLine(1)

    // PREVISAO DE PGTO ----------------------------------------------------------------
    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH C "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SUBSTRING(SE2.E2_VENCREA, 5, 2) + '/' + SUBSTRING(SE2.E2_VENCREA, 1, 4) AS VENC_REAL "
    _oSQL:_sQuery += " 	   ,SE2.E2_SALDO AS SALDO "
    _oSQL:_sQuery += " 	   ,SUBSTRING(SE2.E2_VENCREA, 1, 4) + SUBSTRING(SE2.E2_VENCREA, 5, 2) AS ORD "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE2") + " SE2 "
    _oSQL:_sQuery += " 	WHERE SE2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "  AND SE2.E2_FORNECE = '"+ mv_par02 +"' "
    _oSQL:_sQuery += "  AND SE2.E2_LOJA    = '"+ mv_par03 +"' "
    _oSQL:_sQuery += " 	AND SE2.E2_SALDO > 0 "
    _oSQL:_sQuery += " 	AND SE2.E2_NUM + SE2.E2_PREFIXO IN (SELECT "
    _oSQL:_sQuery += " 		DISTINCT "
    _oSQL:_sQuery += " 			DOC + SERIE "
    _oSQL:_sQuery += " 		FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += " 		WHERE SAFRA    = '"+ mv_par01 +"' "
    _oSQL:_sQuery += " 		AND ASSOCIADO  = SE2.E2_FORNECE "
    _oSQL:_sQuery += " 		AND LOJA_ASSOC = SE2.E2_LOJA)) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   VENC_REAL AS MES_ANO_REFERENCIA "
    _oSQL:_sQuery += "    ,SUM(SALDO) AS SALDO "
    _oSQL:_sQuery += " FROM C "
    _oSQL:_sQuery += " GROUP BY VENC_REAL "
    _oSQL:_sQuery += " 		    ,ORD "
    _oSQL:_sQuery += " ORDER BY ORD "
    _aDados := _oSQL:Qry2Array ()

    oReport:PrintText(" PREVISÃO DE PAGAMENTO:",,100)
    oSection3:Init()

    For _x := 1 to Len(_aDados)
        oSection3:Cell("COLUNA01")	:SetBlock   ({|| _aDados[_x, 1] })
        oSection3:Cell("COLUNA02")	:SetBlock   ({|| _aDados[_x, 2] })

        oSection3:PrintLine()
    Next

    oSection3:Finish()
    oReport:SkipLine(1)
    oReport:FatLine()
    oReport:PrintText(" **** DOCUMENTO CONFIDENCIAL ****",,900)
    oReport:FatLine()
    oReport:SkipLine(1)


Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes           Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {02, "Fornecedor                    ", "C", 6,  0,  "",   "SA2", {},             ""})
	aadd (_aRegsPerg, {03, "Loja                          ", "C", 2,  0,  "",   "   ", {},             ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
