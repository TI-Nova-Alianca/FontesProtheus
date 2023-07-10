// Programa...: VA_M700E
// Autor......: Cláudia Lionço
// Data.......: 06/07/2023
// Descricao..: Exporta documento de Previsão de vendas para comercial
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Deleta documento de Previsão de vendas
// #PalavasChave      #vendas 
// #TabelasPrincipais #SC4
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
User Function VA_M700E()
    Local _aDados := {}
    Local _x      := 0

    cPerg   := "VA_M700E"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif

    If !empty(mv_par01)
        _oSQL := ClsSQL ():New ()
        _oSQL:_sQuery := " WITH C "
        _oSQL:_sQuery += " AS "
        _oSQL:_sQuery += " (SELECT "
        _oSQL:_sQuery += " 		C4_CODLIN AS COD_LINHA "
        _oSQL:_sQuery += " 	   ,ZX5_39.ZX5_39DESC AS LINHA "
        _oSQL:_sQuery += " 	   ,C4_VAMARCM AS COD_MARCA "
        _oSQL:_sQuery += " 	   ,ZX5_40.ZX5_40DESC AS MARCA "
        _oSQL:_sQuery += " 	   ,C4_PRODUTO AS PRODUTO "
        _oSQL:_sQuery += " 	   ,SB1.B1_DESC AS DESCRICAO "
        _oSQL:_sQuery += " 	   ,MONTH(C4_DATA) AS MES "
        _oSQL:_sQuery += " 	   ,C4_QUANT AS QTD "
        _oSQL:_sQuery += " 	FROM " + RetSQLName ("SC4") + " SC4 "
        _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("ZX5") + " ZX5_39 " 
        _oSQL:_sQuery += " 		ON ZX5_39.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND ZX5_39.ZX5_39COD = C4_CODLIN "
        _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("ZX5") + " ZX5_40 " 
        _oSQL:_sQuery += " 		ON ZX5_40.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND ZX5_40.ZX5_40COD = C4_VAMARCM "
        _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " 		ON SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND B1_COD = C4_PRODUTO "
        _oSQL:_sQuery += " 	WHERE SC4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 	AND C4_DOC = '"+ mv_par01 +"') "
        _oSQL:_sQuery += "  SELECT "
        _oSQL:_sQuery += " 	   COD_LINHA "
        _oSQL:_sQuery += "    ,LINHA "
        _oSQL:_sQuery += "    ,COD_MARCA "
        _oSQL:_sQuery += "    ,MARCA "
        _oSQL:_sQuery += "    ,PRODUTO "
        _oSQL:_sQuery += "    ,DESCRICAO "
        _oSQL:_sQuery += "    ,[1] AS JANEIRO "
        _oSQL:_sQuery += "    ,[2] AS FEVEREIRO "
        _oSQL:_sQuery += "    ,[3] AS MARÇO "
        _oSQL:_sQuery += "    ,[4] AS ABRIL "
        _oSQL:_sQuery += "    ,[5] AS MAIO "
        _oSQL:_sQuery += "    ,[6] AS JUNHO "
        _oSQL:_sQuery += "    ,[7] AS JULHO "
        _oSQL:_sQuery += "    ,[8] AS AGOSTO "
        _oSQL:_sQuery += "    ,[9] AS SETEMBRO "
        _oSQL:_sQuery += "    ,[10] AS OUTUBRO "
        _oSQL:_sQuery += "    ,[11] AS NOVEMBRO "
        _oSQL:_sQuery += "    ,[12] AS DEZEMBRO "
        _oSQL:_sQuery += " FROM C PIVOT (SUM(QTD) "
        _oSQL:_sQuery += " FOR MES IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) P "
        _oSQL:_sQuery += " ORDER BY COD_LINHA, COD_MARCA, PRODUTO "
        _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

        nHandle := FCreate("c:\temp\previsao_vendas.csv")
        _sLinha := " COD LINHA;LINHA;COD MARCA;MARCA;PRODUTO;DESCRICAO;JAN;FEV;MAR;ABR;MAI;JUN;JUL;AGO;SET;OUT;NOV;DEZ" + CHR(13) + CHR(10)
        FWrite(nHandle, _sLinha)

        For _x:=1 to Len(_aDados)
            _sLinha := _aDados[_x,1]  +";"+ _aDados[_x,2]  +";"+ _aDados[_x,3]  + ";" + _aDados[_x,4]  + ";" + _aDados[_x,5]  + ";" + _aDados[_x,6]  + ";" 
            _sLinha += str(_aDados[_x, 7]) + ";" + str(_aDados[_x, 8]) + ";" + str(_aDados[_x, 9]) + ";" + str(_aDados[_x,10]) + ";" + str(_aDados[_x,11]) + ";" + str(_aDados[_x,12]) + ";" 
            _sLinha += str(_aDados[_x,13]) + ";" + str(_aDados[_x,14]) + ";" + str(_aDados[_x,15]) + ";" + str(_aDados[_x,16]) + ";" + str(_aDados[_x,17]) + ";" + str(_aDados[_x,18]) + CHR(13)+CHR(10)
            FWrite(nHandle, _sLinha)
        Next

        FClose(nHandle)
        u_help("Arquivo gerado com sucesso em c:\temp\")
    EndIf
Return
//
// -------------------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT              TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Documento        ", "C", 9, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return

