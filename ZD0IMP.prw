// Programa...: ZD0IMP
// Autor......: Cláudia Lionço
// Data.......: 16/09/2022
// Descricao..: Baixa de registros do extrato Pagar.me
//              https://docs.pagar.me/v4/docs/extrato
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Baixa de registros do extrato Pagar.me
// #PalavasChave      #extrato #pagar.me #recebimento #ecommerce 
// #TabelasPrincipais #ZD0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 20/06/2024 - Claudia - Alterado os links (rotas) de acesso aos pagamentos. GLPI: 15271
//
// ------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include "tbiconn.ch"
#include 'parmtype.ch'

User Function ZD0IMP()
    Private cPerg := "ZD0IMP"
	
    u_logIni()

    _ValidPerg()
    If Pergunte(cPerg,.T.)  
        u_log2('aviso', 'Pagar.me:' + DTOC(mv_par01) +" até "+ DTOC(mv_par02))

        MsAguarde({|| _GravaRecebidos(mv_par01, mv_par02)}, "Aguarde...", "Processando Registros...")

        MsAguarde({|| _GravaTransf(mv_par01, mv_par02)}, "Aguarde...", "Processando transferencias...")

        u_log2('aviso', 'Importação finalizada!')
        
    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Busca Pagamentos recebidos no período
Static Function _GravaRecebidos(dDataIni, dDataFin) 
    local cUrlReceb  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetorno   := ""
    local _x         := 0
    local i          := 1
    local oJSON

    _nDias := DateDiffDay(dDataIni, dDataFin)

    _nDias := _nDias + 1
    _dData := dDataIni
    For _x := 1 to _nDias

        cUrlReceb := _RetLinkExt(_dData)
        cRetorno  := HttpGet( cUrlReceb , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link
        
        oJSON:= JsonObject():New()
        oJSON:fromJSON(cRetorno)

        nNumReg := len(oJSON)

        MsProcTxt("Importando registros de recebidos...")

        If nNumReg >=0
            u_log2('aviso', 'Pagar.me: Qnt.de pagamentos de recebiveis no período '+ alltrim(Str(nNumReg)) + ".Período:" + DTOC(mv_par01) +" até "+ DTOC(mv_par02))
        else
            u_log2('aviso', 'Verifique a chave API')
        EndIf

        If nNumReg >= 0
            For i := 1 to nNumReg

                _lContinua   := .T.
                _IdReceb     := oJSON[i]["id"]
                _IdTrans     := oJSON[i]["transaction_id"]
                _sTpPgto     := IIF(empty(oJSON[i]["type"])                 , ""                , oJSON[i]["type"])
                _nVlr        := IIF(empty(oJSON[i]["amount"])               , 0                 , oJSON[i]["amount"]/100)
                _nTaxa       := IIF(empty(oJSON[i]["fee"])                  , 0                 , oJSON[i]["fee"]/100)
                _nParcela    := IIF(empty(oJSON[i]["installment"])          , 0                 , oJSON[i]["installment"])
                _dDtPgto     := IIF(Empty(oJSON[i]["payment_date"])         ,STOD('19000101')   ,_CastData(oJSON[i]["payment_date"]))
                _sMetodoPgto := IIF(Empty(oJSON[i]["payment_method"])       , ""                , oJSON[i]["payment_method"])
                _dDtCriacao  := IIF(Empty(oJSON[i]["date_created"])         ,STOD('19000101')   ,_CastData(oJSON[i]["date_created"]))
                _sDtExtrato  := IIF(Empty(oJSON[i]["payment_date"])         ,STOD('19000101')   ,_CastData(oJSON[i]["payment_date"]))
                _sHoraExt    := IIF(Empty(oJSON[i]["payment_date"])         ,STOD('19000101')   ,_CastHora(oJSON[i]["payment_date"]))
                _nTaxaAntec  := IIF(empty(oJSON[i]["anticipation_fee"])     , 0                 , oJSON[i]["anticipation_fee"]/100)
                _nTaxaFraude := IIF(empty(oJSON[i]["fraud_coverage_fee"])   , 0                 , oJSON[i]["fraud_coverage_fee"]/100)

                _sIdTrans   := alltrim(str(_IdTrans))
                _sIdReceb   := alltrim(str(_IdReceb))
                _sIdExtrato := ''

                _sCliente    := _BuscaCliente(_sIdTrans,_sMetodoPgto)
                _sStaBai     := 'A'
                _sParProt    := _BuscaParcProtheus(_nParcela)

                _nVlrTaxTot  := _nTaxa + _nTaxaAntec + _nTaxaFraude
                _nVlrLiq     := _nVlr - _nVlrTaxTot
               
                _oSQL:= ClsSQL ():New ()
                _oSQL:_sQuery := ""
                _oSQL:_sQuery += " SELECT "
                _oSQL:_sQuery += "     COUNT(*) "
                _oSQL:_sQuery += " FROM ZD0010 " 
                _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
                _oSQL:_sQuery += " AND ZD0_FILIAL = '"+ xFilial('ZD0') +"' "
                _oSQL:_sQuery += " AND ZD0_TID = '"+ _sIdTrans +"' "
                _oSQL:_sQuery += " AND ZD0_RID = '"+ _sIdReceb +"' "
                _aZD0 := aclone(_oSQL:Qry2Array(.f., .f.))

                if len(_aZD0) > 0
                    if _aZD0[1,1] == 0
                        Begin Transaction
                            Reclock("ZD0",.T.)
                            ZD0 -> ZD0_FILIAL := xFilial('ZD0')
                            ZD0 -> ZD0_EID    := _sIdExtrato
                            ZD0 -> ZD0_RID    := _sIdReceb
                            ZD0 -> ZD0_TID    := _sIdTrans
                            ZD0 -> ZD0_TIPO   := '1'            // tipo transação
                            ZD0 -> ZD0_STATUS := 'paid'
                            ZD0 -> ZD0_DTAPGT := _dDtPgto
                            ZD0 -> ZD0_DTACRI := _dDtCriacao
                            ZD0 -> ZD0_PGTTIP := _sTpPgto
                            ZD0 -> ZD0_PGTMET := _sMetodoPgto
                            ZD0 -> ZD0_PARCEL := _sParProt
                            ZD0 -> ZD0_VLRPAR := _nVlr
                            ZD0 -> ZD0_TAXA   := _nTaxa
                            ZD0 -> ZD0_TAXANT := _nTaxaAntec
                            ZD0 -> ZD0_TAXFRA := _nTaxaFraude
                            ZD0 -> ZD0_TAXTOT := _nVlrTaxTot
                            ZD0 -> ZD0_VLRLIQ := _nVlrLiq
                            ZD0 -> ZD0_DTAEXT := _sDtExtrato
                            ZD0 -> ZD0_HOREXT := _sHoraExt
                            ZD0 -> ZD0_STABAI := _sStaBai
                            ZD0 -> ZD0_CLIENT := _sCliente
                            ZD0 -> ZD0_LOJA   := '01'

                            ZD0->(MsUnlock())
                        End Transaction
                    else
                        u_log2('aviso', 'Transação ' + alltrim(_sIdTrans) + ' Recebível:'+ alltrim(_sIdReceb) + ' já gravada no sistema.')
                    endif
                endif         
            Next
        EndIf
        _dData := DaySum(_dData, 1)
    Next
Return
//
// -----------------------------------------------------------------------------------
// Busca Pagamentos recebidos no período
Static Function _GravaTransf(dDataIni, dDataFin) 
    local cUrlReceb  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetorno   := ""
    local i          := 1
    local oJSON

    cUrlReceb := _RetLinkOper( dDataIni, dDataFin)
    cRetorno  := HttpGet( cUrlReceb , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link
    
    oJSON:= JsonObject():New()
    oJSON:fromJSON(cRetorno)

    nNumReg := len(oJSON)

    MsProcTxt("Importando registros de transferencias...")

    For i := 1 to nNumReg
        _sTipo := IIF(empty(oJSON[i]["type"]) , "", oJSON[i]["type"])

        if alltrim(_sTipo) == 'transfer' .or. alltrim(_sTipo) == 'fee_collection'

            _IdReceb     := oJSON[i]["id"]             
            _nVlr        := IIF(empty(oJSON[i]["amount"])               , 0                 , oJSON[i]["amount"]/100)
            _dDtCriacao  := IIF(Empty(oJSON[i]["date_created"])         ,STOD('19000101')   ,_CastData(oJSON[i]["date_created"]))
            _sDtExtrato  := IIF(Empty(oJSON[i]["date_created"])         ,STOD('19000101')   ,_CastData(oJSON[i]["date_created"]))
            _sHoraExt    := IIF(Empty(oJSON[i]["date_created"])         ,STOD('19000101')   ,_CastHora(oJSON[i]["date_created"]))
            _nVlrLiq     := _nVlr 

            _sIdTrans   := alltrim(str(_IdReceb))
            _sIdReceb   := alltrim(str(_IdReceb))

            if alltrim(_sTipo) == 'transfer' 
                _sStatus := 'T'
                _sTp     := '2'
            else
                if alltrim(_sTipo) == 'fee_collection'
                    _sStatus := 'X'
                    _sTp     := '3'
                endif
            endif

            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += "     COUNT(*) "
            _oSQL:_sQuery += " FROM ZD0010 " 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND ZD0_FILIAL = '"+ xFilial('ZD0') +"' "
            _oSQL:_sQuery += " AND ZD0_TID = '"+ _sIdTrans +"' "
            _oSQL:_sQuery += " AND ZD0_RID = '"+ _sIdReceb +"' "
            _aZD0 := aclone(_oSQL:Qry2Array(.f., .f.))

            if len(_aZD0) > 0
                if _aZD0[1,1] == 0
                    Begin Transaction
                        Reclock("ZD0",.T.)
                        ZD0 -> ZD0_FILIAL := xFilial('ZD0')
                        ZD0 -> ZD0_EID    := ''
                        ZD0 -> ZD0_RID    := _sIdReceb
                        ZD0 -> ZD0_TID    := _sIdTrans
                        ZD0 -> ZD0_TIPO   := _sTp            // tipo transferencia/tarifas
                        ZD0 -> ZD0_STATUS := 'available'
                        ZD0 -> ZD0_DTACRI := _dDtCriacao
                        ZD0 -> ZD0_DTAPGT := _dDtCriacao
                        ZD0 -> ZD0_DTAEXT := _sDtExtrato
                        ZD0 -> ZD0_HOREXT := _sHoraExt
                        ZD0 -> ZD0_VLRPAR := _nVlr
                        ZD0 -> ZD0_TAXA   := 0
                        ZD0 -> ZD0_TAXANT := 0
                        ZD0 -> ZD0_TAXFRA := 0
                        ZD0 -> ZD0_TAXTOT := 0
                        ZD0 -> ZD0_VLRLIQ := _nVlr
                        ZD0 -> ZD0_STABAI := _sStatus

                        ZD0->(MsUnlock())
                    End Transaction
                else
                    u_log2('aviso', 'Transação ' + alltrim(_sIdTrans) + ' Recebível:'+ alltrim(_sIdReceb) + ' já gravada no sistema.')
                endif
            endif         
        endif
    Next
Return
//
// -----------------------------------------------------------------------------------
// Cria o rota dos recebidos pagos
Static Function _RetLinkExt(dData)
    Local _sAkKey := GETMV("VA_PAGAR")
    Local _sLink  := ""

    _sDt   :=  Substr(DTOS(dData), 1, 4) + "-" + Substr(DTOS(dData), 5, 2) + "-" +  Substr(DTOS(dData), 7, 2)
    _sLink := 'https://api.pagar.me/1/payables?api_key='+_sAkKey +'&count=1000&status=paid&payment_date='+ _sDt
    
    u_log2("Aviso", " Link de recebidos pagos:" + _sLink)
Return _sLink
//
// -----------------------------------------------------------------------------------
// Cria rota operações
Static Function _RetLinkOper( dDataIni, dDataFin)
    Local _sAkKey := GETMV("VA_PAGAR")

    _sDt01 := _FormataTimeStamp(dDataIni,'00:00:00')
    _sDt02 := _FormataTimeStamp(dDataFin,'23:59:59')
    
    _sLink := 'https://api.pagar.me/1/balance/operations?api_key='+_sAkKey +'&count=1000&start_date='+ _sDt01 +'&end_date='+_sDt02

    u_log2("Aviso", " Link de transferencias:" + _sLink)
Return _sLink
//
// -----------------------------------------------------------------------------------
//Transforma data tipo timestamp em milissegundos
Static Function _FormataTimeStamp(_dData,_sSeg)
    Local _sData := DTOS(_dData)
    Local _x     := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT DATEDIFF (SECOND, CAST ('19700101 00:00' AS DATETIME), CAST ('" + _sData +" " +_sSeg +"' AS DATETIME)) * 1000. "
    _aDados := _oSQL:Qry2Array ()

    For _x=1 to Len(_aDados)
        _sDt := alltrim(str(_aDados[_x, 1]))
    Next
Return _sDt
//
// -----------------------------------------------------------------------------------
// Retorna cliente pela bandeira do cartão
Static Function _BuscaCliente(_sIdTrans, _sMetPgto) 
    local cUrlTrans  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetTrans  := ""
    local _sCardBand := ""
    local oJSONT
    Local _sAkKey := GETMV("VA_PAGAR")

    cUrlTrans  := 'https://api.pagar.me/1/transactions/' + alltrim(_sIdTrans) + '?api_key=' + alltrim(_sAkKey)
    u_log2("Aviso", cUrlTrans)
    cRetTrans := HttpGet( cUrlTrans , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link da transação

    oJSONT := JsonObject():New()
    oJSONT:fromJSON(cRetTrans)

    nNum := len(oJSONT)

    If nNum == 0
        u_log2('aviso', 'Pagar.me: Transação encontada:' + _sIdTrans)
    else
        u_log2('aviso', 'Verifique a chave API')
    EndIf
    
    If nNum == 0
        _lContinua := .T.
        _sCardBand   := IIF(Empty(oJSONT["card_brand"])      , "", oJSONT["card_brand"])
               
    Else
        u_log2('aviso', 'Pagar.me: Sem registro de transação')
    Endif

       Do Case 
        Case alltrim(_sMetPgto) == 'pix'
            _sCliente := '005'
        Case alltrim(_sMetPgto) == 'boleto'
            _sCliente := '005'                   // criar cliente boleto
        Case alltrim(_sMetPgto) == 'credit_card'
            Do Case
                Case alltrim(_sCardBand) == 'amex'
                     _sCliente := '503'
                Case alltrim(_sCardBand) == 'elo'
                     _sCliente := '401'
                Case alltrim(_sCardBand) == 'mastercard'
                     _sCliente := '101'
                Case alltrim(_sCardBand) == 'visa'
                     _sCliente := '201'
                Case alltrim(_sCardBand) == 'hipercard'
                     _sCliente := '501'
                Otherwise
                    u_log2("Aviso", 'Cartão de débito não previsto!')
                    _sCliente := ''
            EndCase

        Case empty(_sMetPgto) 
            Do Case
                Case alltrim(_sCardBand) == 'amex'
                     _sCliente := '502'
                Case alltrim(_sCardBand) == 'elo'
                     _sCliente := '400'
                Case alltrim(_sCardBand) == 'mastercard'
                     _sCliente := '100'
                Case alltrim(_sCardBand) == 'visa'
                     _sCliente := '200'
                Case alltrim(_sCardBand) == 'hipercard'
                     _sCliente := '500'                    
                Otherwise
                    u_log2("Aviso", 'Cartão de crédito não previsto!')
                    _sCliente := '005'
            EndCase
        Otherwise
            u_log2("Aviso", 'Método de pagamento não previsto!')
            _sCliente := '005'
    EndCase

Return _sCliente
//
// -------------------------------------------------------------------------
// Transforma parcela pagar.me em protheus
Static Function _BuscaParcProtheus(_nParcela)
    Local _sParcPro := ""

    Do Case
        Case _nParcela == 0
            _sParcPro := ''
        Case _nParcela == 1
            _sParcPro := 'A'
        Case _nParcela == 2
            _sParcPro := 'B'
        Case _nParcela == 3
            _sParcPro := 'C'
        Case _nParcela == 4
            _sParcPro := 'D'
        Case _nParcela == 5
            _sParcPro := 'E'
        Case _nParcela == 6
            _sParcPro := 'F'
        Case _nParcela == 7
            _sParcPro := 'G'
        Case _nParcela == 8
            _sParcPro := 'H'
        Case _nParcela == 9
            _sParcPro := 'I'
        Case _nParcela == 10
            _sParcPro := 'J'
        Case _nParcela == 11
            _sParcPro := 'K'
        Case _nParcela == 12
            _sParcPro := 'L'
        OTHERWISE
            _sParcPro := ''
    EndCase
Return _sParcPro
//
// -----------------------------------------------------------------------------------
//Transforma data string -> data date
Static Function _CastData(_sDt)
    _sAno := SubStr(_sDt, 1, 4)
    _sMes := SubStr(_sDt, 6, 2)
    _sDia := SubStr(_sDt, 9, 2)
    _dDt  := STOD(_sAno + _sMes + _sDia)
Return _dDt
//
// -----------------------------------------------------------------------------------
// Busca hora da gravação
Static Function _CastHora(_sDt)
    _sHr := SubStr(_sDt, 12, 8)
Return _sHr
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return




