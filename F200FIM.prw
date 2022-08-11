// Programa...: F200VAR
// Autor......: Cláudia Lionço
// Data.......: 05/05/2021
// Descricao..: P.E. Gravação de linha de lançamento
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Gravação de linha de lançamento
// #PalavasChave      #CNAB #final_CNAB 
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 05/05/2021 - Claudia - Incluida msg de valore e taxas. GLPI: 9983
//
// ---------------------------------------------------------------------------------------------------------------

User Function F200FIM()
    If cFilAnt $ GetMv("VA_FILTNSF")
        u_ZB5TRANSF(cFilAnt)

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT"
        _oSQL:_sQuery += "     SUM(ZB5_VLRREC)"
        _oSQL:_sQuery += "    ,SUM(ZB5_VLRDES)"
        _oSQL:_sQuery += " FROM " + RetSQLName ("ZB5")
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND ZB5_FILIAL = '" + cFilAnt      + "'"
        _oSQL:_sQuery += " AND ZB5_DTABAS= '" + dtos(dDataBase) + "'"
        _aTot := aclone (_oSQL:Qry2Array ())

        If len(_aTot) > 0
            u_help(" FILIAL:" + alltrim(cFilAnt) + " VLR.RECEBIDO:" + alltrim(str(_aTot[1,1]))+ " VLR.TAXA:" + alltrim(str(_aTot[1,2])))
        EndIf
    EndIf
Return
