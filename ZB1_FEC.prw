// Programa...: ZB1_FEC
// Autor......: Cl�udia Lion�o
// Data.......: 26/10/2020
// Descricao..: Fechamento de registros de pagamentos sem concilia��o - Cielo
//
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Fechamento de registros de pagamentos sem concilia��o - Cielo
// #PalavasChave      #extrato #cielo #recebimento #cartoes #fechamento
// #TabelasPrincipais #ZB1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 29/03/2021 - Claudia - Incluida filial 13. GLPI: 9710
//
// --------------------------------------------------------------------------
User function ZB1_FEC()
    	u_logIni ("Fechamento de registros ZB1" + DTOS(date()) )

        cPerg   := "ZB1_FEC"
		_ValidPerg ()
		
		If ! pergunte (cPerg, .T.)
			return
		Endif

        If empty(mv_par01) .and. empty(mv_par02)
            u_help("Autoriza��o ou NSU devem ser preenchidos")
        else
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT * "
            _oSQL:_sQuery += " FROM " + RetSQLName ("ZB1") 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''" 
            _oSQL:_sQuery += " AND ZB1_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
            _oSQL:_sQuery += " AND ZB1_ARQUIV LIKE'%CIELO%'" //-- APENAS ARQUIVOS DA CIELO
            If !empty(mv_par01)
                _oSQL:_sQuery += " AND ZB1_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
            EndIf
            If !empty(mv_par02) 
                _oSQL:_sQuery += " AND ZB1_AUTCOD = '" + mv_par02 + "' " // FILTRA PELO C�DIGO DE AUTORIZA��O
            EndIf
            _oSQL:Log ()

            _aZB1 := aclone (_oSQL:Qry2Array ())

            _cMens := "Existem " + alltrim(str(len(_aZB1))) + " registros para fechar. Deseja continuar?"
		    If MsgYesNo(_cMens,"Fechamento de registros")
                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " UPDATE " + RetSQLName ("ZB1") 
                _oSQL:_sQuery += " SET  ZB1_STAIMP = 'F'" 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''" 
                _oSQL:_sQuery += " AND ZB1_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
                _oSQL:_sQuery += " AND ZB1_ARQUIV LIKE'%CIELO%'" //-- APENAS ARQUIVOS DA CIELO
                If !empty(mv_par01)
                    _oSQL:_sQuery += " AND ZB1_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
                EndIf
                If !empty(mv_par02) 
                    _oSQL:_sQuery += " AND ZB1_AUTCOD = '" + mv_par02 + "' " // FILTRA PELO C�DIGO DE AUTORIZA��O
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
    aadd (_aRegsPerg, {02, "Cod.Autoriza��o    ", "C",  6, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
