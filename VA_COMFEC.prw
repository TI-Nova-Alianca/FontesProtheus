//  Programa...: VA_COMFEC
//  Autor......: Cláudia Lionço
//  Cliente....: Alianca
//  Data.......: 16/10/2020
//  Descricao..: Processo de fechamento de registros de verbas pagas
//
// #TipoDePrograma    #processo
// #Descricao         #Processo de fechamento de registros de verbas pagas
// #PalavasChave      #comissoes #verbas #fechamento
// #TabelasPrincipais #ZB0 
// #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
User Function VA_COMFEC()

cPerg := "VA_COMRDEV"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)

    processa ({||_FechaReg ()})
Return
//
// -------------------------------------------------------------------------
// Fecha registros ZB0
Static Function _FechaReg()
    Local _lContinua := .T.

    If _lContinua .and. (empty (mv_par01) .or. empty (mv_par02) .or. empty (mv_par05))
		u_help ("As datas de execução e pagamento devem ser informadas!")
		_lContinua = .F.
	Endif

	procregua (1)

    If _lContinua
        _oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE ZB0010 SET ZB0_DTAPGT='"+ DTOS(mv_par05)+"'"
        _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
        _oSQL:_sQuery += " AND ZB0_DATA BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) +"'"
        _oSQL:_sQuery += " AND ZB0_VENDCH BETWEEN '" + mv_par03 + "' AND '" + mv_par04 +"'"
        _oSQL:Log ()
        If _oSQL:Exec ()
            u_help(" Registros atualizado com sucesso!")
        Else
            u_help(" Registros não atualizados!")
        Endif
    EndIf

Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de          ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data ate         ", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Vendedor de      ", "C", 3, 0,  "",   "SA3", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Vendedor ate     ", "C", 3, 0,  "",   "SA3", {},                        		 ""})
    aadd (_aRegsPerg, {05, "Data de pgto     ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
