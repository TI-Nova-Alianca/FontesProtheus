// Programa...: ZB3REL
// Autor......: Cláudia Lionço
// Data.......: 12/07/2021
// Descricao..: Relatório de recebimentos Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de recebimentos Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce 
// #TabelasPrincipais #ZB3
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function ZB3REL()
	Private oReport
	Private cPerg := "ZB3REL"
	
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

	oReport := TReport():New("ZB3REL","Importação de registros Pagar.me",cPerg,{|oReport| PrintReport(oReport)},"Importação de registros Pagar.me")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Emissão"	    ,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Baixa"	        ,                         	,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Venc."	        ,                         	,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"ID"		    ,							,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"NSU"			,	    					,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Autoriz."	    ,	    					,15,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Dt.Pgto"	    ,	    					,20,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Vlr.Total"	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Vlr.Parc."	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Vlr.Taxa"	    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA13", 	"" ,"Status"		,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA14", 	"" ,"É Boleto"		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    //TRCell():New(oSection1,"COLUNA15", 	"" ,"Dta.Boleto"	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA16", 	"" ,"Tipo Pgto"	    ,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    //TRCell():New(oSection1,"COLUNA17", 	"" ,"Operadora"	    ,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

	//TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .F., .T.)
	//TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
    Local oSection1  := oReport:Section(1)	
    Local _aDados    := {}
    Local i          := 0
    //Local _nVlrTotPg := 0
    Local _nVlrParPg := 0
    Local _nVlrTaxPg := 0
    //Local _nVlrTotDv := 0
    Local _nVlrParDv := 0
    Local _nVlrTaxDv := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "		SE1.E1_FILIAL AS FILIAL "
    _oSQL:_sQuery += "	   ,SE1.E1_NUM + '/' + SE1.E1_PREFIXO + '/' + SE1.E1_PARCELA AS TITULO "
    _oSQL:_sQuery += "	   ,SE1.E1_EMISSAO AS DTA_EMISSAO "
    _oSQL:_sQuery += "	   ,SE1.E1_BAIXA AS DTA_BAIXA "
    _oSQL:_sQuery += "	   ,SE1.E1_VENCREA AS DTA_VENC "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_IDTRAN AS ID_TRANS "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_NSUCOD AS NSU "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_AUTCOD AS AUTORIZACAO "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_DTAPGT AS DTA_PGTO "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTOT AS VLR_TOTAL "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRPAR AS VLR_PARC "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTAX AS VLR_TAXA "
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'paid' THEN 'PAGO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'refunded' THEN 'DEVOL/RECUSADO' "
    _oSQL:_sQuery += "		END AS STATUS "
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_BOLCOD <> '' THEN 'SIM' "
    _oSQL:_sQuery += "			ELSE 'NÃO' "
    _oSQL:_sQuery += "		END AS BOLETO "
    _oSQL:_sQuery += "	   ,ZB3.ZB3_BOLDTA AS DTA_BOL "
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'boleto' THEN 'BOLETO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'credit_card' THEN 'CARTÃO CRED' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'pix' THEN 'PIX' "
    _oSQL:_sQuery += "		END AS TP_PGTO "
    _oSQL:_sQuery += "	   ,UPPER(ZB3.ZB3_ADMNOM) AS OPERADORA "
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZB3") + " AS ZB3 "
    _oSQL:_sQuery += "	LEFT JOIN " + RetSQLName ("SE1") + " AS SE1 "
    _oSQL:_sQuery += "		ON SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SE1.E1_VAIDT = ZB3.ZB3_IDTRAN "
    _oSQL:_sQuery += "			AND ((SE1.E1_PARCELA = ZB3.ZB3_PARPRO) "
    _oSQL:_sQuery += "				OR (TRIM(SE1.E1_PARCELA) = '' "
    _oSQL:_sQuery += "					AND ZB3.ZB3_PARPRO = 'A')) "
    _oSQL:_sQuery += "	WHERE ZB3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "  AND ZB3_FILIAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _oSQL:_sQuery += "	AND ZB3_DTAPGT BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "'"
    _oSQL:_sQuery += "	ORDER BY SE1.E1_NUM "              
    _aDados := _oSQL:Qry2Array ()

	oSection1:Init()

	For i:=1 to Len(_aDados)
        If empty(_aDados[i,2])
            _titulo  := "-"
        Else
            _titulo  := alltrim(_aDados[i,2]) 
        EndIf

        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1]       })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _titulo            })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| STOD(_aDados[i,3]) })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| STOD(_aDados[i,4]) })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| STOD(_aDados[i,5]) })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[i,6]       })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[i,7]       })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[i,8]       })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| STOD(_aDados[i,9]) })
        oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aDados[i,10]      })
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aDados[i,11]      })
        oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aDados[i,12]      })
        oSection1:Cell("COLUNA13")	:SetBlock   ({|| _aDados[i,13]      })
        oSection1:Cell("COLUNA14")	:SetBlock   ({|| _aDados[i,14]      })
        //oSection1:Cell("COLUNA15")	:SetBlock   ({|| _aDados[i,15]      })
        oSection1:Cell("COLUNA16")	:SetBlock   ({|| _aDados[i,16]      })
        //oSection1:Cell("COLUNA17")	:SetBlock   ({|| _aDados[i,17]  })

        If alltrim(_aDados[i,13]) == 'PAGO'
            //_nVlrTotPg += _aDados[i,10] 
            _nVlrParPg += _aDados[i,11] 
            _nVlrTaxPg += _aDados[i,12] 
        Else
            //_nVlrTotDv += _aDados[i,10] 
            _nVlrParDv += _aDados[i,11] 
            _nVlrTaxDv += _aDados[i,12] 
        EndIf
        
        oSection1:PrintLine()
	Next

    oReport:ThinLine()
	oReport:SkipLine(1)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("VALORES PAGOS:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor total das parcelas:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nVlrParPg, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor total das Taxas:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nVlrTaxPg, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)

    oReport:ThinLine()
	oReport:SkipLine(1)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("VALORES DEVOLVIDOS/REJEITADOS:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor total das parcelas:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nVlrParDv, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor total das Taxas:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nVlrTaxDv, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)

    oSection1:Finish()

Return
//
// --------------------------------------------------------------------------
// Pular folha na impressão
Static Function _PulaFolha(_nLinha)
	local _nRet := 0

	If  _nLinha > 2300
		oReport:EndPage()
		oReport:StartPage()
		_nRet := oReport:Row()
	Else
		_nRet := _nLinha
	EndIf
Return _nRet
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data pgto de "   , "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data pgto até "  , "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Filial de"       , "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Filial até "     , "C", 2, 0,  "",   "   ", {},                         		 ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return

