// Programa...: ZD0CMP
// Autor......: Cláudia Lionço
// Data.......: 08/07/2022
// Descricao..: Compensação Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Compensação Pagar.me
// #PalavasChave      #extrato #pagar.me #compensacao #ecommerce 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function ZD0CMP()
    Local aArea      := GetArea()
    Local nTaxaCM    := 0
    Local aTxMoeda   := {}
    Local _x         := 0
    Local nSaldoComp := 0  // Valor a ser compensado (Caso seja parcial Pode ser parcial)
    
    Private cPerg := "ZD0CMP"
	
    u_logIni()
    
    _ValidPerg()
    Pergunte(cPerg,.T.)  
    dDataIni := mv_par01
    dDataFin := mv_par02

    u_log2('aviso', 'Pagar.me compensação:' + DTOC(mv_par01) +" até "+ DTOC(mv_par02))
    
    if mv_par04 == 1
        _oSQL := ClsSQL():New ()  
        _oSQL:_sQuery := "" 		
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   R_E_C_N_O_ "
        _oSQL:_sQuery += "    ,ZD0_FILIAL "
        _oSQL:_sQuery += "    ,ZD0_TID "
        _oSQL:_sQuery += "    ,ZD0_PARCEL "
        _oSQL:_sQuery += "    ,ZD0_VLRLIQ " 
        _oSQL:_sQuery += "    ,ZD0_TAXTOT "
        _oSQL:_sQuery += " FROM " + RetSQLName ("ZD0") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND ZD0_FILIAL   = '" + xFilial('ZD0') + "' "
        _oSQL:_sQuery += " AND ZD0_STABAI   = 'R' "
        _oSQL:_sQuery += " AND ZD0_DTAPGT BETWEEN '" + dtos(dDataIni) + "' AND '" + dtos(dDataFin) + "' "
        if !empty(mv_par03)
            _oSQL:_sQuery += " AND ZD0_TID = '" + mv_par03 + "' "
        endif
        _aZD0 := _oSQL:Qry2Array ()

        For _x := 1 to Len(_aZD0)

            _oSQL := ClsSQL():New ()  
            _oSQL:_sQuery := "" 		
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	   R_E_C_N_O_ "
            _oSQL:_sQuery += "    ,E1_FILIAL "
            _oSQL:_sQuery += "    ,E1_PREFIXO "
            _oSQL:_sQuery += "    ,E1_NUM "
            _oSQL:_sQuery += "    ,E1_PARCELA "
            _oSQL:_sQuery += "    ,E1_CLIENTE "
            _oSQL:_sQuery += "    ,E1_LOJA "
            _oSQL:_sQuery += "    ,E1_TIPO "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_= '' "
            _oSQL:_sQuery += " AND E1_FILIAL   = '" + _aZD0[_x, 2] + "' "
            _oSQL:_sQuery += " AND E1_VAIDT    = '" + _aZD0[_x, 3] + "' "
            _oSQL:_sQuery += " AND E1_PARCELA  = '" + _aZD0[_x, 4] + "' "
            _oSQL:_sQuery += " AND E1_TIPO    <> 'RA' "
            _aSE1 := _oSQL:Qry2Array ()

            If len(_aSE1) > 0

                PERGUNTE("FIN330",.F.)
                lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
                lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
                lAglutina       := .F.
            
                //NF X RA
                aRecSE1    := { _aSE1[ 1, 1] }
                aRecRA     := { _aZD0[_x, 1] }
                nSaldoComp := _aZD0[_x, 5]

                Begin Transaction

                If !MaIntBxCR(3, aRecSE1,,aRecRA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp,,,, nTaxaCM, aTxMoeda)
                    u_log2('erro', 'Erro na compensação dos títulos! RECNOs:')
                    lRet := .F.
                    DisarmTransaction()
                else
                    u_help(" Compensação realizada com sucesso!")
                    u_log2('aviso', 'Compensação realizada com sucesso! RECNOs: NF:' + alltrim(str(_aSE1[ 1, 1])) + " RA:" + alltrim(str(_aZD0[_x, 1])) )

                    // Realiza movimento da taxa
                    // Define banco
                    If xFilial('ZD0') == '01'
                        _sBanco     := '237'
                        _sAgencia   := '03471'
                        _sConta     := '0000470'
                    else
                        _sBanco     := '041'
                        _sAgencia   := '0873'
                        _sConta     := '0619710901'
                    EndIf

                    lMsErroAuto := .F.
                    _sMotBaixa := 'NORMAL' 
                    _sHist     := 'Taxa pagar.me'

                    // executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
                    _aAutoSE1 := {}
                    aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aSE1[ 1, 2]  , Nil})
                    aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aSE1[ 1, 3]  , Nil})
                    aAdd(_aAutoSE1, {"E1_NUM"     	, _aSE1[ 1, 4]  , Nil})
                    aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aSE1[ 1, 5]  , Nil})
                    aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aSE1[ 1, 6]	, Nil})
                    aAdd(_aAutoSE1, {"E1_LOJA"    	, _aSE1[ 1, 7]	, Nil})
                    aAdd(_aAutoSE1, {"E1_TIPO"    	, _aSE1[ 1, 8]	, Nil})
                    aAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  	, Nil})
                    aAdd(_aAutoSE1, {"CBANCO"  		, _sBanco	    , Nil})  	
                    aAdd(_aAutoSE1, {"CAGENCIA"   	, _sAgencia		, Nil})  
                    aAdd(_aAutoSE1, {"CCONTA"  		, _sConta		, Nil})
                    aAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase		, Nil})
                    aAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		, Nil})
                    aAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    	, Nil})
                    aAdd(_aAutoSE1, {"AUTDESCONT"	, _aZD0[_x, 6]  , Nil})
                    aAdd(_aAutoSE1, {"AUTMULTA"  	, 0         	, Nil})
                    aAdd(_aAutoSE1, {"AUTJUROS"  	, 0         	, Nil})
                    aAdd(_aAutoSE1, {"AUTVALREC"  	, 0				, Nil})
                
                    _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

                    cPerg = 'FIN070'
                    _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
                    U_GravaSX1 (cPerg, "01", 2)    // testar mostrando o lcto contabil depois pode passar para nao
                    U_GravaSX1 (cPerg, "04", 2)    // esse movimento tem que contabilizar
                    U_GravaSXK (cPerg, "01", "2", 'G' )
                    U_GravaSXK (cPerg, "04", "2", 'G' )

                    MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

                    If lMsErroAuto
                        u_log(memoread (NomeAutoLog ()))
                        _sErro := ALLTRIM(memoread (NomeAutoLog ()))
                        u_log2('erro', "Movimentação não realizada. RECNO. NF:" + alltrim(str(_aSE1[ 1, 1])) + " RA:" + alltrim(str(_aZD0[_x, 1])) )
                        u_log2('erro', _sErro )                       
                    Else
                        u_log2('aviso', "Movimentação realizada. RECNO. NF:" + alltrim(str(_aSE1[ 1, 1])) + " RA:" + alltrim(str(_aZD0[_x, 1])) )
                    Endif
                    
                    U_GravaSXK (cPerg, "01", "2", 'D' )
                    U_GravaSXK (cPerg, "04", "2", 'D' )

                    U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
                EndIf

                End Transaction
            EndIf
        Next
 
    else
        

        PERGUNTE("FIN330",.F.)
        lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
        lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
        lAglutina       := .F.
    
        //NF X RA
        aRecSE1    := { 630763 }
        aRecRA     := { 632235 }
        nSaldoComp := 512.8
        aEstorno   := {}
        AADD(aEstorno,{ "10 2806222  BRA 01"  }) 

        Begin Transaction

        If !MaIntBxCR(3, aRecSE1,,aRecRA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,aEstorno,,,nSaldoComp,,,, nTaxaCM, aTxMoeda)
            u_log2('erro', 'Erro na compensação dos títulos! RECNOs:')
            lRet := .F.
            DisarmTransaction()
        EndIf

        End Transaction
    endif
    RestArea(aArea)
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Id Transacao ", "C",12, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Tipo.Mov     ", "N", 1, 0,  "",   "   ", {"Compensação", "Estorno"},         ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return




