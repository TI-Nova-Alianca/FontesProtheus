// Programa...: VA_PERMAX
// Autor......: Cláudia Lionço
// Data.......: 15/04/2021
// Descricao..: Atualizador de percentual máximo de desconto tabela de preço/Mercanet
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Atualizador de percentual máximo de desconto tabela de preço/Mercanet
// #PalavasChave      #tabela_de_preco #desconto #desconto_maximo #mercanet 
// #TabelasPrincipais #DA0
// #Modulos   		  #FAT
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function VA_PERMAX()
    Local _x     := 0
    Local _aDA0  := {}
    Local _aDA02 := {}

    if !U_ZZUVL ("128", __cUserID, .T.)
		u_help("Usuário sem permissão para usar essa rotina")
    else
        cPerg   := "VA_PERMAX"
        _ValidPerg ()
        If ! pergunte (cPerg, .T.)
            return
        Endif

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT"
        _oSQL:_sQuery += " 	  count(*)"
        _oSQL:_sQuery += " FROM " + RetSQLName ("DA0") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND DA0_DATDE  <= '"+ DTOS(date())+"'"
        _oSQL:_sQuery += " AND DA0_DATATE >= '"+ DTOS(date())+"'"
        _oSQL:_sQuery += " AND DA0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"'"
        _oSQL:_sQuery += " AND DA0_CODTAB BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
        _aDA0 := aclone (_oSQL:Qry2Array ())

        If Len(_aDA0) > 0
            If msgyesno("Existem "+ alltrim(str(_aDA0[1,1])) +" tabela(s) para serem atualizadas. Deseja atualizar?")
                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " SELECT"
                _oSQL:_sQuery += " 	   DA0_FILIAL "
                _oSQL:_sQuery += " 	  ,DA0_CODTAB "
                _oSQL:_sQuery += " 	  ,R_E_C_N_O_ "
                _oSQL:_sQuery += " FROM " + RetSQLName ("DA0") 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
                _oSQL:_sQuery += " AND DA0_DATDE  <= '"+ DTOS(date())+"'"
                _oSQL:_sQuery += " AND DA0_DATATE >= '"+ DTOS(date())+"'"
                _oSQL:_sQuery += " AND DA0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"'"
                _oSQL:_sQuery += " AND DA0_CODTAB BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"'"
                _aDA02 := aclone (_oSQL:Qry2Array ())

                For _x:=1 to Len(_aDA02)
                    _sFilial := _aDA02[_x, 1]
                    _sTabela := _aDA02[_x, 2]
                    _nRecno  := _aDA02[_x, 3]
                    _nPerMax := mv_par05

                    dbSelectArea("DA0")
                    dbSetOrder(1) // DA0_FILIAL + DA0_CODTAB
                    dbGoTop()
		
		            If dbSeek(_sFilial + _sTabela)
                        Reclock("DA0",.F.)
                            DA0->DA0_PERMAX := _nPerMax
                        DA0->(MsUnlock())

                        U_AtuMerc ('DA0', _nRecno)
                    EndIf
                Next
                u_help("Tabelas atualizadas com sucesso!")

            Else
                u_help("Tabelas não atualizadas!")
            EndIf
        Else
            u_help("Sem tabelas para alteração!")
        EndIf
	endif

Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    Local _aRegsPerg := {}

    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes     Help
    aadd (_aRegsPerg, {01, "Filial de          ", "C", 02, 0,  "",  "SM0", {},          ""})
    aadd (_aRegsPerg, {02, "Filial até         ", "C", 02, 0,  "",  "SM0", {},          ""})
    aadd (_aRegsPerg, {03, "Tabela de          ", "C", 03, 0,  "",  "DA0", {},          ""})
    aadd (_aRegsPerg, {04, "Tabela até         ", "C", 03, 0,  "",  "DA0", {},          ""})
    aadd (_aRegsPerg, {05, "Valor % maximo     ", "N", 06, 2,  "",  "   ", {},          ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
