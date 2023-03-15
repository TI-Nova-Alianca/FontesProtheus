// Programa...: VA_LOJPGT
// Autor......: Cláudia Lionço
// Data.......: 15/03/2023
// Descricao..: Relatorio de vendas de lojas com listagem de tipo de de pagamentos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de vendas de lojas com listagem de tipo de de pagamentos
// #PalavasChave      #vendas_loja #movimentos_diarios
// #TabelasPrincipais #SL1 #SL4 #SF2 #SE1 #SC5 
// #Modulos   		  #LOJA
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------

#include 'protheus.ch'
#include "totvs.ch

User Function VA_LOJPGT
	cPerg   := "VA_LOJPGT"
	_ValidPerg()
	
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
	
Return
//
// -----------------------------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
    Local oSection2:= Nil

	oReport := TReport():New("VA_LOJPGT","Movimentos diários",cPerg,{|oReport| PrintReport(oReport)},"Movimentos diários")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()

	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	oSection1:SetTotalInLine(.F.)	
    TRCell():New(oSection1,"COLUNA0", 	" ",""		,	    			        , 8,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA1", 	" ","Documento"		,	    			, 8,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	" ","Série"			,       			, 6,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	" ","Emissão"		,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	" ","Tipo"			,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	" ","Forma Pgto."	,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	" ","Administradora",    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	" ","NSU"			,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	" ","Histórico"		,    				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	" ","Valor Total"	,"@E 99,999,999.99" ,30,/*lPixel*/,{||  },"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA0"),"Total")
    TRFunction():New(oSection1:Cell("COLUNA9")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .F.)


    oSection2 :=  TRSection():New(oReport," ",{""}, , , , , ,.F.,.F.,.F.) 	
	oSection2:SetTotalInLine(.F.)
    TRCell():New(oSection2,"COLUNA0", 	" ",""		                ,					,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA1", 	" ","Forma Pgto"		    ,					,30,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	" ","Administradora(cartão)",					,40,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	" ","Valor"				    ,"@E 99,999,999.99" ,30,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak2 := TRBreak():New(oSection2,oSection2:Cell("COLUNA0"),"Total")
    TRFunction():New(oSection2:Cell("COLUNA3")  ,,"SUM" ,oBreak2,""          , "@E 99,999,999.99", NIL, .F., .F.)

Return(oReport)
//
// -----------------------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local oSection2 := oReport:Section(2)
    Local _aNatExc := {}
    Local _aDados  := {}
    Local _aResumo := {}
    Local _x       := 0

    If !empty(mv_par03)
        _aNatExc := StrToKarr( mv_par03 , ';')
        
        For _x := 1 to len(_aNatExc)
            sNatExc += "'"+ upper(alltrim(_aNatExc[_x])) + "'"
            If _x != len(_aNatExc)
                sNatExc += ","
            EndIf
        Next
    EndIf
	
    // Impressão dos dados
    _aDados := RetArray(1)
    oSection1:Init()
    For _x:= 1 to Len(_aDados)
        oSection1:Cell("COLUNA1"):SetValue(_aDados[_x, 1])
        oSection1:Cell("COLUNA2"):SetValue(_aDados[_x, 2])	
        oSection1:Cell("COLUNA3"):SetValue(stod(_aDados[_x, 3]))
        oSection1:Cell("COLUNA4"):SetValue(_aDados[_x, 4])
        oSection1:Cell("COLUNA5"):SetValue(_aDados[_x, 5])
        oSection1:Cell("COLUNA6"):SetValue(_aDados[_x, 6])
        oSection1:Cell("COLUNA7"):SetValue(_aDados[_x, 7])
        oSection1:Cell("COLUNA8"):SetValue(_aDados[_x, 8])
        oSection1:Cell("COLUNA9"):SetValue(_aDados[_x, 9])
        oSection1:Printline()
    Next
    oSection1:Finish()

    oReport:PrintText(" " ,,50)
    oReport:ThinLine()
    oReport:PrintText(" " ,,50)

    // Impressão do resumo
    _aResumo := RetArray(2)
    oSection2:Init()
    For _x:= 1 to Len(_aResumo)
        oSection2:Cell("COLUNA1"):SetValue(_aResumo[_x, 1])
        oSection2:Cell("COLUNA2"):SetValue(_aResumo[_x, 2])	
        oSection2:Cell("COLUNA3"):SetValue(_aResumo[_x, 3])
        oSection2:Printline()
    Next
    oSection2:Finish()
	
Return
//
// -----------------------------------------------------------------------------------------------
// Consulta de retorno de dados
Static Function RetArray(_nTp)
    Local _aRet := {}

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " WITH LOJA "
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SL1.L1_DOC AS DOC "
    _oSQL:_sQuery += " 	   ,SL1.L1_SERIE AS SERIE "
    _oSQL:_sQuery += " 	   ,SL1.L1_EMISNF AS EMISSAO "
    _oSQL:_sQuery += " 	   ,'CUPOM' AS TIPO "
    _oSQL:_sQuery += " 	   ,SL4.L4_FORMA AS FORMA "
    _oSQL:_sQuery += " 	   ,SL4.L4_ADMINIS AS ADM "
    _oSQL:_sQuery += " 	   ,SL4.L4_NSUTEF AS NSU "
    _oSQL:_sQuery += " 	   ,'-' AS HISTORICO "
    _oSQL:_sQuery += " 	   ,SUM(SL4.L4_VALOR) AS VALOR "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SL1") + " AS SL1"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SL4") + " AS SL4"
    _oSQL:_sQuery += " 		ON  SL4.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SL1.L1_FILIAL  = SL4.L4_FILIAL "
    _oSQL:_sQuery += " 		AND SL1.L1_NUM     = SL4.L4_NUM "
    _oSQL:_sQuery += " 	WHERE SL1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND SL1.L1_FILIAL = '" + xFilial("SL1") +"'"
    _oSQL:_sQuery += " 	AND SL1.L1_SERIE <> '999' "
    _oSQL:_sQuery += " 	AND SL1.L1_DOC   <> '' "
    _oSQL:_sQuery += " 	AND SL1.L1_EMISNF BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
    _oSQL:_sQuery += " 	GROUP BY SL1.L1_DOC "
    _oSQL:_sQuery += " 			,SL1.L1_SERIE "
    _oSQL:_sQuery += " 			,SL1.L1_EMISNF "
    _oSQL:_sQuery += " 			,SL4.L4_FORMA "
    _oSQL:_sQuery += " 			,SL4.L4_ADMINIS "
    _oSQL:_sQuery += " 			,SL4.L4_NSUTEF "

    _oSQL:_sQuery += " 	UNION ALL "

    _oSQL:_sQuery += " 	SELECT "
    _oSQL:_sQuery += " 		'-' AS DOC "
    _oSQL:_sQuery += " 	   ,'-' AS SERIE "
    _oSQL:_sQuery += " 	   ,E5_DATA AS EMISSAO "
    _oSQL:_sQuery += " 	   ,'DEPOSITO' AS TIPO "
    _oSQL:_sQuery += " 	   ,'DEPOSITO' AS FORMA "
    _oSQL:_sQuery += " 	   ,'-' AS ADM "
    _oSQL:_sQuery += " 	   ,'-' AS NSU "
    _oSQL:_sQuery += " 	   ,E5_HISTOR AS HISTORICO "
    _oSQL:_sQuery += " 	   ,E5_VALOR AS VALOR "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE5") + " AS SE5"
    _oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND E5_FILIAL    = '" + xFilial("SE5") +"'"
    _oSQL:_sQuery += " 	AND E5_SITUACA  <> 'C' "
    _oSQL:_sQuery += " 	AND E5_MOEDA     = 'M1' "
    _oSQL:_sQuery += " 	AND E5_BANCO     = 'CL1' "
    If !empty(mv_par03)
        _oSQL:_sQuery += " 	AND E5_NATUREZ NOT IN ("+ alltrim(sNatExc) + ") "
    EndIf
    _oSQL:_sQuery += " 	AND E5_DATA BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"

    _oSQL:_sQuery += " 	UNION ALL "

    _oSQL:_sQuery += " 	SELECT "
    _oSQL:_sQuery += " 		'-' AS DOC "
    _oSQL:_sQuery += " 	   ,'-' AS SERIE "
    _oSQL:_sQuery += " 	   ,E5_DATA AS EMISSAO "
    _oSQL:_sQuery += " 	   ,'DEPOSITO' AS TIPO "
    _oSQL:_sQuery += " 	   ,'DEPOSITO' AS FORMA "
    _oSQL:_sQuery += " 	   ,'-' AS ADM "
    _oSQL:_sQuery += " 	   ,'-' AS NSU "
    _oSQL:_sQuery += " 	   ,E5_HISTOR AS HISTORICO "
    _oSQL:_sQuery += " 	   ,E5_VALOR AS VALOR "
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SE5") + " AS SE5"
    _oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND E5_FILIAL    = '" + xFilial("SE5") +"'"
    _oSQL:_sQuery += " 	AND E5_SITUACA  <> 'C' "
    _oSQL:_sQuery += " 	AND E5_BANCO     = 'CL1' "
    _oSQL:_sQuery += " 	AND E5_NATUREZ IN ('120643') "
    If !empty(mv_par03)
        _oSQL:_sQuery += " 	AND E5_NATUREZ NOT IN ("+ alltrim(sNatExc) + ") "
    EndIf
    _oSQL:_sQuery += " 	AND E5_DATA BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"

    _oSQL:_sQuery += " 	UNION ALL "

    _oSQL:_sQuery += " 	SELECT "
    _oSQL:_sQuery += " 		SF2.F2_DOC AS DOC "
    _oSQL:_sQuery += " 	   ,SF2.F2_SERIE AS SERIE "
    _oSQL:_sQuery += " 	   ,SF2.F2_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += " 	   ,'NOTA FISCAL' AS TIPO "
    _oSQL:_sQuery += " 	   ,SE1.E1_TIPO AS FORMA "
    _oSQL:_sQuery += " 	   ,'-' AS ADM "
    _oSQL:_sQuery += " 	   ,SE1.E1_NSUTEF AS NSU "
    _oSQL:_sQuery += " 	   ,'-' AS HISTORICO "
    _oSQL:_sQuery += " 	   ,SUM(SE1.E1_VALOR) AS VALOR " 
    _oSQL:_sQuery += " 	FROM " + RetSQLName ("SF2") + " AS SF2"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SC5") + " AS SC5"
    _oSQL:_sQuery += " 		ON SC5.D_E_L_E_T_  = '' "
    _oSQL:_sQuery += " 		AND SC5.C5_FILIAL  = SF2.F2_FILIAL "
    _oSQL:_sQuery += " 		AND SC5.C5_NOTA    = SF2.F2_DOC "
    _oSQL:_sQuery += " 		AND SC5.C5_SERIE   = SF2.F2_SERIE "
    _oSQL:_sQuery += " 		AND SC5.C5_PEDECOM = '' "
    _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SE1") + " AS SE1"
    _oSQL:_sQuery += " 		ON SE1.D_E_L_E_T_  = '' "
    _oSQL:_sQuery += " 		AND SE1.E1_FILIAL  = SF2.F2_FILIAL "
    _oSQL:_sQuery += " 		AND SE1.E1_NUM     = SF2.F2_DOC "
    _oSQL:_sQuery += " 		AND SE1.E1_PREFIXO = SF2.F2_SERIE "
    _oSQL:_sQuery += " 	WHERE SF2.D_E_L_E_T_   = '' "
    _oSQL:_sQuery += " 	AND SF2.F2_FILIAL = '" + xFilial("SF2") +"'"
    _oSQL:_sQuery += " 	AND SF2.F2_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"'"
    _oSQL:_sQuery += " 	GROUP BY SF2.F2_DOC "
    _oSQL:_sQuery += " 			,SF2.F2_SERIE "
    _oSQL:_sQuery += " 			,SF2.F2_EMISSAO "
    _oSQL:_sQuery += " 			,SE1.E1_TIPO "
    _oSQL:_sQuery += " 			,SE1.E1_NSUTEF) "
    If _nTp == 1
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	* "
        _oSQL:_sQuery += " FROM LOJA "
        _oSQL:_sQuery += " ORDER BY TIPO, EMISSAO, DOC, SERIE "
    Else
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "     FORMA "
        _oSQL:_sQuery += "    ,ADM "
        _oSQL:_sQuery += "    ,SUM(VALOR) AS VALOR "
        _oSQL:_sQuery += " FROM LOJA "
        _oSQL:_sQuery += " GROUP BY FORMA "
        _oSQL:_sQuery += " 		    ,ADM "
        _oSQL:_sQuery += " ORDER BY FORMA, ADM "
    EndIf
    _aRet := aclone(_oSQL:Qry2Array())

Return _aRet
//
// -----------------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes         Help
    aadd (_aRegsPerg, {01, "Emissao de       :", "D", 8, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {02, "Emissao até      :", "D", 8, 0,  "",  "   ", {},            ""})
    aadd (_aRegsPerg, {03, "Excluir naturezas:", "C",80, 0,  "",  "   ", {}, 		    "Separar por ;"})

     U_ValPerg (cPerg, _aRegsPerg)
Return
