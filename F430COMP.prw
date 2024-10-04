// Programa.:  F430COMP
// Autor....:  Claudia Lionço
// Data.....:  04/10/2024
// Descricao:  P.E. execuções complementares após a gravação dos dados financeiros no CNAB a pagar
//             https://tdn.totvs.com/pages/releaseview.action?pageId=6071579
//             Criado inicialmente para controle de baixa de títulos no conta corrente
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. execuções complementares após a gravação dos dados financeiros no CNAB a pagar
// #PalavasChave      #baixa #contas_a_receber
// #TabelasPrincipais #SE2 
// #Modulos           #FIN
//
// Historico de alteracoes:
// 04/10/2024 - Claudia = Criação do P.E. GLPI: 16125
//
// ----------------------------------------------------------------------------------------------------
User Function F430COMP()
    Local _oCtaCorr  := NIL
    Local _aTitulos  := {}
    Local _x         := 0
    Local _lContinua := .T.

    _oSQL := ClsSQL():New()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     SZI.R_E_C_N_O_ "
    _oSQL:_sQuery += "    ,SE2.E2_IDCNAB "
    _oSQL:_sQuery += " FROM " + RetSQLName("SE2") + " SE2 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName("SZI") + " SZI "
    _oSQL:_sQuery += " 	ON SZI.D_E_L_E_T_  ='' "
    _oSQL:_sQuery += " 	    AND ZI_FILIAL  = E2_FILIAL "
    _oSQL:_sQuery += " 		AND ZI_DOC     = E2_NUM "
    _oSQL:_sQuery += " 		AND ZI_SERIE   = E2_PREFIXO "
    _oSQL:_sQuery += " 		AND ZI_ASSOC   = E2_FORNECE "
    _oSQL:_sQuery += " 		AND ZI_LOJASSO = E2_LOJA "
    _oSQL:_sQuery += " WHERE SE2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND E2_FILIAL  = '" + cFilial + "' "
    _oSQL:_sQuery += " AND E2_VAASSOC = 'I' "
    _aTitulos := aclone(_oSQL:Qry2Array())

    For _x:=1 to len(_aTitulos)
        _oCtaCorr  := ClsCtaCorr():New(_aTitulos[_x, 1])
		_nRegSE2   := _oCtaCorr:RecnoSE2()
        _nSaldoAnt := szi -> zi_saldo

        _lContinua := _oCtaCorr:AtuSaldo()

        if _lContinua
            if _nSaldoAnt != szi -> zi_saldo
                u_help ("Saldo deste lcto alterado de " + cvaltochar(_nSaldoAnt) + " para " + cvaltochar(szi -> zi_saldo))
            endif
        
            DbSelectArea('SE2')        
            DbSetOrder(11) //SE2	B E2_FILIAL+E2_IDCNAB    
            if DbSeek(xFilial() + _aTitulos[_x, 2])  
                RecLock("SE2", .F.)
                    se2 -> e2_vaassoc := 'P'
                MsUnlock()   
            endif     
        endif             
    Next
Return
