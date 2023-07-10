// Programa...: VA_M700P
// Autor......: Cláudia Lionço
// Data.......: 06/07/2023
// Descricao..: Exporta documento de Previsão de vendas para PCP
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
User Function VA_M700P()
    Local _aDados := {}
    Local _x      := 0

    cPerg   := "VA_M700P"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif

    If !empty(mv_par01)
        _oSQL := ClsSQL ():New ()
        _oSQL:_sQuery := " SELECT "
        _oSQL:_sQuery += " 	    C4_PRODUTO AS PRODUTO "
        _oSQL:_sQuery += " 	   ,SB1.B1_DESC AS DESCRICAO "
        _oSQL:_sQuery += " 	   ,C4_DATA AS DT "
        _oSQL:_sQuery += " 	   ,C4_QUANT AS QTD "
        _oSQL:_sQuery += " 	FROM " + RetSQLName ("SC4") + " SC4 "
        _oSQL:_sQuery += " 	INNER JOIN " + RetSQLName ("SB1") + " SB1 "
        _oSQL:_sQuery += " 		ON SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND B1_COD = C4_PRODUTO "
        _oSQL:_sQuery += " 	WHERE SC4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 	AND C4_DOC = '"+ mv_par01 +"'"
        _oSQL:_sQuery += "  ORDER BY PRODUTO "
        _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

        nHandle := FCreate("c:\temp\previsao_vendas_pcp.csv")
        _sLinha := "PRODUTO;DESCRICAO;DATA;QUANTIDADE" + CHR(13) + CHR(10)
        FWrite(nHandle, _sLinha)

        For _x:=1 to Len(_aDados)
            _dDt := stod(_aDados[_x,3]) 
            _sLinha := _aDados[_x,1]  +";"+ _aDados[_x,2]  +";"+ dtoc(_dDt) + ";" + str(_aDados[_x,4]) + CHR(13) + CHR(10)
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

