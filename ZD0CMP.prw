// Programa...: ZD0CMP
// Autor......: Cl�udia Lion�o
// Data.......: 08/07/2022
// Descricao..: Compensa��o Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Compensa��o Pagar.me
// #PalavasChave      #extrato #pagar.me #compensacao #ecommerce 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 20/07/2023 - Claudia - Ajustado calculo de taxa. GLPI: 12280
//
// --------------------------------------------------------------------------
User Function ZD0CMP(_sTipo, _sFilial, _sTrans, _sReceb)
    Local aArea      := GetArea()
    Local nTaxaCM    := 0
    Local aTxMoeda   := {}
    Local aTaxa      := {}
    Local _x         := 0
    Local _lContinua := .T.
    Local nSaldoComp := 0  // Valor a ser compensado (Caso seja parcial Pode ser parcial)  
    
    Private cPerg := "ZD0CMP"
	
    u_logIni()
    
    If _sTipo == '1'
        u_log2('aviso', 'Pagar.me compensa��o:' + _sTrans)

        _oSQL := ClsSQL():New ()  
        _oSQL:_sQuery := "" 		
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += " 	   R_E_C_N_O_ "
        _oSQL:_sQuery += "    ,ZD0_FILIAL "
        _oSQL:_sQuery += "    ,ZD0_TID "
        _oSQL:_sQuery += "    ,ZD0_PARCEL "
        _oSQL:_sQuery += "    ,ZD0_VLRLIQ " 
        _oSQL:_sQuery += "    ,ZD0_TAXTOT "
        _oSQL:_sQuery += "    ,ZD0_RID "
        _oSQL:_sQuery += " FROM " + RetSQLName ("ZD0") 
        _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND ZD0_FILIAL   = '" + _sFilial + "' "
        _oSQL:_sQuery += " AND ZD0_STABAI   = 'R'"
        _oSQL:_sQuery += " AND ZD0_TID      = '" + _sTrans + "' "
        _oSQL:_sQuery += " AND ZD0_RID      = '" + _sReceb + "' "
        _aZD0 := _oSQL:Qry2Array ()
    else
        _ValidPerg()
        If Pergunte(cPerg,.T.)  
            dDataIni := mv_par01
            dDataFin := mv_par02
            _lContinua := .T.

            u_log2('aviso', 'Pagar.me compensa��o:' + DTOC(mv_par01) +" at� "+ DTOC(mv_par02))
   
            _oSQL := ClsSQL():New ()  
            _oSQL:_sQuery := "" 		
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	   R_E_C_N_O_ "
            _oSQL:_sQuery += "    ,ZD0_FILIAL "
            _oSQL:_sQuery += "    ,ZD0_TID "
            _oSQL:_sQuery += "    ,ZD0_PARCEL "
            _oSQL:_sQuery += "    ,ZD0_VLRLIQ " 
            _oSQL:_sQuery += "    ,ZD0_TAXTOT "
            _oSQL:_sQuery += "    ,ZD0_RID "
            _oSQL:_sQuery += " FROM " + RetSQLName ("ZD0") 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND ZD0_FILIAL   = '" + xFilial('ZD0') + "' "
            _oSQL:_sQuery += " AND ZD0_STABAI   = 'R' "
            _oSQL:_sQuery += " AND ZD0_DTAPGT BETWEEN '" + dtos(dDataIni) + "' AND '" + dtos(dDataFin) + "' "
            if !empty(mv_par03)
                _oSQL:_sQuery += " AND ZD0_TID = '" + mv_par03 + "' "
            endif
            _aZD0 := _oSQL:Qry2Array ()
        else
            _lContinua := .F.
        EndIf
    EndIf

    If _lContinua
        For _x := 1 to Len(_aZD0)

            if _aZD0[_x, 5] > 0

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
                _oSQL:_sQuery += "    ,E1_VALOR "
                _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_= '' "
                _oSQL:_sQuery += " AND E1_FILIAL   = '" + _aZD0[_x, 2] + "' "
                _oSQL:_sQuery += " AND E1_VAIDT    = '" + _aZD0[_x, 3] + "' "
                _oSQL:_sQuery += " AND E1_PARCELA  = '" + _aZD0[_x, 4] + "' "
                _oSQL:_sQuery += " AND E1_TIPO    <> 'RA' "
                _aSE1 := _oSQL:Qry2Array ()

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
                _oSQL:_sQuery += "    ,E1_VALOR"
                _oSQL:_sQuery += "    ,E1_SALDO"
                _oSQL:_sQuery += " FROM " + RetSQLName ("SE1") 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_= '' "
                _oSQL:_sQuery += " AND E1_FILIAL   = '" + _aZD0[_x, 2] + "' "
                _oSQL:_sQuery += " AND E1_VAIDT    = '" + _aZD0[_x, 3] + "' "
                _oSQL:_sQuery += " AND E1_PARCELA  = '" + _aZD0[_x, 4] + "' "
                _oSQL:_sQuery += " AND E1_TIPO     = 'RA' "
                _aRA := _oSQL:Qry2Array ()

                If len(_aSE1) > 0 .and. len(_aRA) > 0
                    PERGUNTE("FIN330",.F.)
                    lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
                    lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
                    lAglutina       := .F.
                
                    //NF X RA
                    aRecSE1    := { _aSE1[ 1, 1] }
                    aRecRA     := { _aRA[ 1, 1] }
                    nSaldoComp := _aRA[ 1, 9]

                    Begin Transaction

                    If !MaIntBxCR(3, aRecSE1,,aRecRA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp,,,, nTaxaCM, aTxMoeda)
                        u_log2('erro', 'Erro na compensa��o dos t�tulos! RECNOs:')
                        lRet := .F.
                        DisarmTransaction()

                    else
                        u_log2('aviso', 'Compensa��o realizada com sucesso! RECNOs: NF:' + alltrim(str(_aSE1[ 1, 1])) + " RA:" + alltrim(str(_aRA[ 1, 1])) )
                        aadd(aTaxa,{    _aSE1[ 1, 2],; // 01 filial
                                        _aSE1[ 1, 3],; // 02 prefixo
                                        _aSE1[ 1, 4],; // 03 n�mero
                                        _aSE1[ 1, 5],; // 04 parcela
                                        _aSE1[ 1, 6],; // 05 cliente
                                        _aSE1[ 1, 7],; // 06 loja
                                        _aSE1[ 1, 8],; // 07 tipo
                                        _aZD0[_x, 6],; // 08 desconto - TAXA
                                        _aSE1[ 1, 1],; // 09 recno titulo
                                        _aRA[ 1, 1] ,; // 10 recno RA
                                        _aZD0[_x, 3],; // 11 TID
                                        _aZD0[_x, 7],; // 12 RID
                                        _aSE1[ 1, 9],; // 13 Valor t�tulo
                                        _aZD0[_x, 5]}) // 14 Valor liquido pagar.me

                        _BaixaTaxa(aTaxa)
                    EndIf
                    
                    End Transaction
                else
                    If len(_aSE1) <= 0
                        u_help(" N�o encontrado t�tulo original para a compensa��o! ID:" + _aZD0[_x, 3])
                    EndIf
                    If len(_aRA) <= 0
                        u_help(" N�o encontrado t�tulo RA para a compensa��o! ID:" + _aZD0[_x, 3])
                    EndIf
                    
                EndIf
            EndIf
        Next

        If _sTipo == '2'
            // chama relatorio de baixas
            U_ZD0RCMP(dDataIni, dDataFin)
        EndIf
    EndIf

    RestArea(aArea)
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _BaixaTaxa(aTaxa)
    Local _x := 0

    For _x:=1 to Len(aTaxa)                       
        // Realiza movimento da taxa
        // Define banco
        If aTaxa[_x,1] == '01'
            _sBanco     := '237'
            _sAgencia   := '03471'
            _sConta     := '0000470'
        else
            _sBanco     := '041'
            _sAgencia   := '0873 '
            _sConta     := '0619710901'
        EndIf

        lMsErroAuto := .F.
        _sMotBaixa := 'NORMAL' 
        _sHist     := 'Taxa pagar.me'

        // executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR L�QUIDO
        _aAutoSE1 := {}

        _nTaxa := aTaxa[_x,13] - aTaxa[_x,14]  
        _nVlrMaior := aTaxa[_x,8] + 0.5
        _nVlrMenor := aTaxa[_x,8] - 0.5

        If _nTaxa <= _nVlrMaior .and. _nTaxa >= _nVlrMenor  // taxa com diferen�a de arredondamento
            _nTaxa := aTaxa[_x,13] - aTaxa[_x,14]  
        else                                                // se a diferen�a for maior de 0.5, usa a taxa pagar.me e titulo ficar� aberto
            _nTaxa := aTaxa[_x,8] 
        EndIf

        aAdd(_aAutoSE1, {"E1_FILIAL" 	, aTaxa[_x,1]       , Nil})
        aAdd(_aAutoSE1, {"E1_PREFIXO" 	, aTaxa[_x,2]       , Nil})
        aAdd(_aAutoSE1, {"E1_NUM"     	, aTaxa[_x,3]       , Nil})
        aAdd(_aAutoSE1, {"E1_PARCELA" 	, aTaxa[_x,4]       , Nil})
        aAdd(_aAutoSE1, {"E1_CLIENTE" 	, aTaxa[_x,5] 	    , Nil})
        aAdd(_aAutoSE1, {"E1_LOJA"    	, aTaxa[_x,6] 	    , Nil})
        aAdd(_aAutoSE1, {"E1_TIPO"    	, aTaxa[_x,7] 	    , Nil})
        aAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  	    , Nil})
        aAdd(_aAutoSE1, {"CBANCO"  		, _sBanco	        , Nil})  	
        aAdd(_aAutoSE1, {"CAGENCIA"   	, _sAgencia         , Nil})  
        aAdd(_aAutoSE1, {"CCONTA"  		, _sConta	        , Nil})
        aAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase		    , Nil})
        aAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		    , Nil})
        aAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    	    , Nil})
        aAdd(_aAutoSE1, {"AUTDESCONT"	, _nTaxa            , Nil})
        aAdd(_aAutoSE1, {"AUTMULTA"  	, 0         	    , Nil})
        aAdd(_aAutoSE1, {"AUTJUROS"  	, 0         	    , Nil})
        aAdd(_aAutoSE1, {"AUTVALREC"  	, 0				    , Nil})

        _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicion�rio de dados

        cPerg = 'FIN070'
        _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
        U_GravaSX1 (cPerg, "01", 1)    // testar mostrando o lcto contabil depois pode passar para nao
        U_GravaSX1 (cPerg, "04", 1)    // esse movimento tem que contabilizar
        U_GravaSXK (cPerg, "01", "1", 'G' )
        U_GravaSXK (cPerg, "04", "1", 'G' )

        MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina autom�tica para baixa de t�tulos

        If lMsErroAuto
            u_log(memoread (NomeAutoLog ()))
            _sErro := ALLTRIM(memoread (NomeAutoLog ()))
            u_help("Erro" + _sErro)
            u_log2('erro', "Movimenta��o n�o realizada. RECNO. NF:" + alltrim(str(aTaxa[_x,9])) + " RA:" + alltrim(str(aTaxa[_x,10])) )
            u_log2('erro', _sErro )                       
        Else
            u_log2('aviso', "Movimenta��o realizada. RECNO. NF:" + alltrim(str(aTaxa[_x,9])) + " RA:" + alltrim(str(aTaxa[_x,10])) )

            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " UPDATE " + RetSQLName ("ZD0") + " SET ZD0_STABAI = 'B' "
            _oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
            _oSQL:_sQuery += " AND ZD0_FILIAL = '" + aTaxa[_x,1]  + "'"
            _oSQL:_sQuery += " AND ZD0_TID    = '" + aTaxa[_x,11] + "'"
            _oSQL:_sQuery += " AND ZD0_RID    = '" + aTaxa[_x,12] + "'"
            _oSQL:Log ()
            _oSQL:Exec ()

        Endif
        
        U_GravaSXK (cPerg, "01", "1", 'D' )
        U_GravaSXK (cPerg, "04", "1", 'D' )

        U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  

        u_log2('aviso', 'Baixa de taxa realizada com sucesso! RECNOs: NF:' + alltrim(str(aTaxa[_x,9])) + " RA:" + alltrim(str(aTaxa[_x,10])) )
    Next

Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D",  8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Id Transacao ", "C", 15, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return




