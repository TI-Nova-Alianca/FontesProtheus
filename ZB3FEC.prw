// Programa...: ZB3FEC
// Autor......: Cláudia Lionço
// Data.......: 14/07/2021
// Descricao..: Fechamento de registros de pagamentos sem conciliação - Pagar-me
//
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Fechamento de registros de pagamentos sem conciliação - Pagar-me
// #PalavasChave      #extrato #pagarme #recebimento #ecommerce #fechamento
// #TabelasPrincipais #ZB3
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User function ZB3FEC()
    	u_logIni ("Fechamento de registros ZB3" + DTOS(date()) )

        cPerg   := "ZB3FEC"
		_ValidPerg ()
		
		If ! pergunte (cPerg, .T.)
			return
		Endif

        If empty(mv_par01) .and. empty(mv_par02)
            u_help("Autorização ou NSU devem ser preenchidos")
        else
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT * "
            _oSQL:_sQuery += " FROM " + RetSQLName ("ZB3") 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''" 
            _oSQL:_sQuery += " AND ZB3_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
            If !empty(mv_par01)
                _oSQL:_sQuery += " AND ZB3_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
            EndIf
            If !empty(mv_par02) 
                _oSQL:_sQuery += " AND ZB3_AUTCOD = '" + mv_par02 + "' " // FILTRA PELO CÓDIGO DE AUTORIZAÇÃO
            EndIf
            _oSQL:Log ()

            _aZB1 := aclone (_oSQL:Qry2Array ())

            _cMens := "Existem " + alltrim(str(len(_aZB1))) + " registros para fechar. Deseja continuar?"
		    If MsgYesNo(_cMens,"Fechamento de registros")
                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " UPDATE " + RetSQLName ("ZB3") 
                _oSQL:_sQuery += " SET  ZB3_STAIMP = 'F'" 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''" 
                _oSQL:_sQuery += " AND ZB3_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
                If !empty(mv_par01)
                    _oSQL:_sQuery += " AND ZB3_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
                EndIf
                If !empty(mv_par02) 
                    _oSQL:_sQuery += " AND ZB3_AUTCOD = '" + mv_par02 + "' " // FILTRA PELO CÓDIGO DE AUTORIZAÇÃO
                EndIf
                _oSQL:Log ()
				_oSQL:Exec ()
                
                u_help("Processo finalizado")
            EndIf

        EndIf
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "NSU                ", "C",  6, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Cod.Autorização    ", "C",  6, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
