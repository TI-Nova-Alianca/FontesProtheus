//  Programa...: ZB2_REL
//  Autor......: Cláudia Lionço
//  Data.......: 12/11/2020
//  Cliente....: Alianca
//  Descricao..: Relatório de importação de registros Banrisul
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de importação de registros Banrisul
// #PalavasChave      #cartao #titulos #
// #TabelasPrincipais #ZB2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function ZB2_REL()
	Private oReport
	Private cPerg := "ZB2_REL"
	
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

	oReport := TReport():New("ZB2_REL","Importação de registros Banrisul",cPerg,{|oReport| PrintReport(oReport)},"Importação de registros Banrisul")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Recebido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"NSU"			,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Lançamento"	,	    					,30,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Status"		,	    					,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .F., .T.)
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
    Local oSection1 := oReport:Section(1)	
    Local _aDados   := {}
    Local i         := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT"
    _oSQL:_sQuery += "		ZB2_FILIAL"
    _oSQL:_sQuery += "	   ,E1_NUM"
    _oSQL:_sQuery += "	   ,E1_PREFIXO"
    _oSQL:_sQuery += "	   ,E1_PARCELA"
    _oSQL:_sQuery += "	   ,E1_CLIENTE"
    _oSQL:_sQuery += "	   ,E1_NOMCLI"
    _oSQL:_sQuery += "	   ,ZB2_VLRPAR"
    _oSQL:_sQuery += "	   ,ZB2_VLRTAR"
    _oSQL:_sQuery += "	   ,ZB2_AUTCOD"
    _oSQL:_sQuery += "	   ,ZB2_NSUCOD"
    _oSQL:_sQuery += "	   ,ZB2_DESLAN"
    _oSQL:_sQuery += "	   ,CASE"
    _oSQL:_sQuery += "			WHEN ZB2_STAIMP = 'I' THEN 'IMPORTADO'"
    _oSQL:_sQuery += "			WHEN ZB2_STAIMP = 'C' THEN 'BAIXADO'"
    _oSQL:_sQuery += "			WHEN ZB2_STAIMP = 'F' THEN 'FECHADO'"
    _oSQL:_sQuery += "		END"
    _oSQL:_sQuery += "	FROM ZB2010 ZB2"
    _oSQL:_sQuery += "	LEFT JOIN SE1010 SE1"
    _oSQL:_sQuery += "		ON (SE1.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "				AND SE1.E1_FILIAL = ZB2.ZB2_FILIAL"
    _oSQL:_sQuery += "				AND SE1.E1_NSUTEF = ZB2_NSUCOD"
    _oSQL:_sQuery += "				AND SE1.E1_EMISSAO = ZB2_DTAMOV"
    _oSQL:_sQuery += "              AND SE1.E1_PARCELA = ZB2.ZB2_PARTIT"
    _oSQL:_sQuery += "          )"
    _oSQL:_sQuery += "	WHERE ZB2.D_E_L_E_T_ = ''"
    _oSQL:_sQuery += "	AND ZB2.ZB2_DTAGER = '"+ DTOS(mv_par01)+"'"
    _aDados := _oSQL:Qry2Array ()

	oSection1:Init()

	For i:=1 to Len(_aDados)
        If empty(_aDados[i,2])
            _titulo  := "-"
            _cliente := "-"
        Else
            _titulo  := alltrim(_aDados[i,2]) + "/" + alltrim(_aDados[i,3]) + "/" + alltrim(_aDados[i,4])
            _cliente := alltrim(_aDados[i,5]) + "-" + alltrim(_aDados[i,6])
        EndIf

        oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[i,1]  })
        oSection1:Cell("COLUNA2")	:SetBlock   ({|| _titulo       })
        oSection1:Cell("COLUNA3")	:SetBlock   ({|| _cliente      })
        oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[i,7]  })
        oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[i,8]  })
        oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[i,9]  })
        oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[i,10] })
        oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[i,11] })
        oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aDados[i,12] })
        
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
    aadd (_aRegsPerg, {01, "Data de geração ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return

