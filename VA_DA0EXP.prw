// Programa: VA_DA0EXP
// Autor...: Cláudia Lionço
// Data....: 19/09/2023
// Funcao..: Exporta tabela de preços para .CSV
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Exporta tabela de preços para .CSV
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------------------------
User Function VA_DA0EXP(_sFilial, _sTabCod)
    Local _oSQL := ClsSQL():New ()
    Local _x    := 0

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DA0_FILIAL "
    _oSQL:_sQuery += "    ,DA0_CODTAB "
    _oSQL:_sQuery += "    ,DA1.DA1_ITEM "
    _oSQL:_sQuery += "    ,DA1.DA1_CODPRO "
    _oSQL:_sQuery += "    ,DA1.DA1_ESTADO "
    _oSQL:_sQuery += "    ,DA1.DA1_PRCVEN "
    _oSQL:_sQuery += " FROM " + RetSQLName ("DA0") + " DA0 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("DA1") + " DA1 "
    _oSQL:_sQuery += " 	ON DA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND DA1.DA1_FILIAL = DA0.DA0_FILIAL "
    _oSQL:_sQuery += " 		AND DA1.DA1_CODTAB = DA0.DA0_CODTAB "
    _oSQL:_sQuery += " WHERE DA0_FILIAL = '" + _sFilial + "' "
    _oSQL:_sQuery += " AND DA0_CODTAB   = '" + _sTabCod + "' "
    _oSQL:_sQuery += " ORDER BY DA1.DA1_ITEM "
    _aDados := aclone (_oSQL:Qry2Array (.F., .F.))

    _sArq := 'tabela_' + alltrim(_sTabCod)
    nHandle := FCreate("c:\temp\"+ alltrim(_sArq)+".csv")

    _sTexto := "FILIAL;TABELA;ITEM;PRODUTO;ESTADO;PRECO_VENDA;STATUS" + Chr(13) + Chr(10) 
    FWrite(nHandle,_sTexto )

    For _x:= 1 to Len(_aDados)
    
        _sTexto := _aDados[_x, 1] +";"+ _aDados[_x, 2] +";"+  _aDados[_x, 3] +";"+  _aDados[_x, 4] +";"+  _aDados[_x, 5] +";"+  strtran(str(_aDados[_x, 6]),".",",") +";"+ 'A' + Chr(13) + Chr(10) 
        FWrite(nHandle,_sTexto )

    Next

    FClose(nHandle)
    u_help(" Exportação finalizada com sucesso em: C:\temp\")
Return
