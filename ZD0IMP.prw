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
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include "tbiconn.ch"
#include 'parmtype.ch'

User Function ZD0IMP()
    Private cPerg := "ZD0IMP"
	
    u_logIni()

    _ValidPerg()
    If Pergunte(cPerg,.T.)  
        dDataIni := mv_par01
        dDataFin := mv_par02

        u_log2('aviso', 'Pagar.me:' + DTOC(mv_par01) +" até "+ DTOC(mv_par02))

        MsAguarde({|| _GravaExtrato(dDataIni, dDataFin)}, "Aguarde...", "Processando Registros...")
    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Busca Pagamentos recebidos no período
Static Function _GravaExtrato(dDataIni, dDataFin) 
    local cUrlReceb  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetorno   := ""
    local i          := 1
    local oJSON

    cUrlReceb := _RetLinkExt( dDataIni, dDataFin)
    cRetorno := HttpGet( cUrlReceb , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link

    oJSON:= JsonObject():New()
    oJSON:fromJSON(cRetorno)

    nNumReg := len(oJSON)

    If nNumReg >=0
        u_log2('aviso', 'Pagar.me: Qnt.de pagamentos de recebiveis no período '+ alltrim(Str(nNumReg)) + ".Período:" + DTOC(mv_par01) +" até "+ DTOC(mv_par02))
    else
        u_log2('aviso', 'Verifique a chave API')
    EndIf
    
    If nNumReg >= 0
        For i := 1 to nNumReg
            MsProcTxt("Importando registro " + alltrim(str(i)) + " de " + alltrim(str(nNumReg)) + "...")

            _lContinua   := .T.
            _IdExtrato   := oJSON[i]["id"]
            _sTipoExt    := IIF(empty(oJSON[i]["type"])                                             , ""                , _CastTipo(oJSON[i]["type"]))
            _nVlr        := IIF(empty(oJSON[i]["amount"])                                           , 0                 , oJSON[i]["amount"]/100)
            _nTaxa       := IIF(empty(oJSON[i]["fee"])                                              , 0                 , oJSON[i]["fee"]/100)
            _sDtExtrato  := IIF(Empty(oJSON[i]["date_created"])                                     ,STOD('19000101')   , _CastData(oJSON[i]["date_created"]))
            _sHoraExt    := IIF(Empty(oJSON[i]["date_created"])                                     ,STOD('19000101')   , _CastHora(oJSON[i]["date_created"]))
            _IdTrans     := oJSON[i]["movement_object"]["transaction_id"]
            _IdReceb     := oJSON[i]["movement_object"]["id"]
            _sStatus     := IIF(empty(oJSON[i]["movement_object"]["status"])                        , ""                , oJSON[i]["movement_object"]["status"])
            _dDtPgto     := IIF(Empty(oJSON[i]["movement_object"]["payment_date"])                  ,STOD('19000101')   ,_CastData(oJSON[i]["movement_object"]["payment_date"]))
            _dDtCriacao  := IIF(Empty(oJSON[i]["movement_object"]["date_created"])                  ,STOD('19000101')   ,_CastData(oJSON[i]["movement_object"]["date_created"]))
            _sTpPgto     := IIF(Empty(oJSON[i]["movement_object"]["type"])                          , ""                , oJSON[i]["movement_object"]["type"])
            _sMetodoPgto := IIF(Empty(oJSON[i]["movement_object"]["payment_method"])                , ""                , oJSON[i]["movement_object"]["payment_method"])
            _nParcela    := IIF(empty(oJSON[i]["movement_object"]["installment"])                   , 0                 , oJSON[i]["movement_object"]["installment"])
            _nTaxaAntec  := IIF(empty(oJSON[i]["movement_object"]["anticipation_fee"])              , 0                 , oJSON[i]["movement_object"]["anticipation_fee"]/100)
            _nTaxaFraude := IIF(empty(oJSON[i]["movement_object"]["fraud_coverage_fee"])            , 0                 , oJSON[i]["movement_object"]["fraud_coverage_fee"]/100)

            _sIdTrans   := _VerifType(_IdTrans, _sTipoExt)
            _sIdReceb   := _VerifType(_IdReceb, _sTipoExt)
            _sIdExtrato := _VerifType(_IdExtrato,_sTipoExt)
        
            _sStaBai := 'A'
            Do Case
                Case _sTipoExt == '1'
                     _sCliente    := _BuscaCliente(_IdTrans,_sMetodoPgto)
                     
                Case _sTipoExt == '2'
                    _sIdTrans := _sIdReceb
                    _sStaBai  := 'T'
                    _sCliente := ""

                Case _sTipoExt == '3'
                    _sIdTrans := _sIdExtrato
                    _sIdReceb := _sIdExtrato
                    _sStaBai  := 'X'
                    _sCliente := ""
            EndCase
            _sParProt    := _BuscaParcProtheus(_nParcela)
           
            _nVlrTaxTot  := _nTaxa + _nTaxaAntec + _nTaxaFraude
            _nVlrLiq     := _nVlr - _nVlrTaxTot
           
            dbSelectArea("ZD0") 
            dbSetOrder(1) 
            dbGoTop()
            
            _sChaveZD0 := xFilial('ZD0') + PADR(alltrim(_sIdTrans),15,' ') + PADR(alltrim(_sIdReceb),15,' ') + PADR(alltrim(_sIdExtrato),15,' ')
            If !dbSeek(_sChaveZD0)
                Begin Transaction
                    Reclock("ZD0",.T.)
                    ZD0 -> ZD0_FILIAL := xFilial('ZD0')
                    ZD0 -> ZD0_EID    := _sIdExtrato
                    ZD0 -> ZD0_RID    := _sIdReceb
                    ZD0 -> ZD0_TID    := _sIdTrans
                    ZD0 -> ZD0_TIPO   := _sTipoExt
                    ZD0 -> ZD0_STATUS := _sStatus
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
                    ZD0 -> ZD0_TIPO   := _sTipoExt
                    ZD0 -> ZD0_DTAEXT := _sDtExtrato
                    ZD0 -> ZD0_HOREXT := _sHoraExt
                    ZD0 -> ZD0_STABAI := _sStaBai
                    ZD0 -> ZD0_CLIENT := _sCliente
                    ZD0 -> ZD0_LOJA   := '01'

                    ZD0->(MsUnlock())
                End Transaction
            Else
                _lContinua := .F.
                u_log2('aviso', 'Transação ' + alltrim(_sIdTrans) + ' Recebível:'+ alltrim(_sIdReceb) + ' já gravada no sistema.')
            EndIf            
        Next

        u_log2('aviso', 'Importação finalizada!')

    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Cria o link do extrato
Static Function _RetLinkExt( dDataIni, dDataFin)
    Local _sAkKey := GETMV("VA_PAGAR")

    _sDt01 := _FormataTimeStamp(dDataIni)
    _sDt02 := _FormataTimeStamp(dDataFin)
    
    _sLink := 'https://api.pagar.me/1/balance/operations?api_key='+_sAkKey +'&count=1000&start_date='+ _sDt01 +'&end_date='+_sDt02

    u_log2("Aviso", " Link de pagamentos recebidos gerado:" + _sLink)
Return _sLink
//
// -----------------------------------------------------------------------------------
// Retirna cliente pela bandeira do cartão
Static Function _BuscaCliente(_IdTrans, _sMetPgto)
    local cUrlTrans  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetTrans  := ""
    local _sCardBand := ""
    local oJSONT
    Local _sAkKey := GETMV("VA_PAGAR")

    cUrlTrans  := 'https://api.pagar.me/1/transactions/' + alltrim(str(_IdTrans)) + '?api_key=' + alltrim(_sAkKey)
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
//Transforma data tipo timestamp em milissegundos
Static Function _FormataTimeStamp(_dData)
    Local _sData := DTOS(_dData)
    Local _x     := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT DATEDIFF (SECOND, CAST ('19700101 00:00' AS DATETIME), CAST ('" + _sData + " 23:59:59' AS DATETIME)) * 1000. "
    _aDados := _oSQL:Qry2Array ()

    For _x=1 to Len(_aDados)
        _sDt := alltrim(str(_aDados[_x, 1]))
    Next
Return _sDt
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
// -----------------------------------------------------------------------------------
// Tratamento ID's
Static Function _VerifType(_Campo, _sTipoExt)
    Do Case 
        Case valtype(_Campo) == 'C'
            If empty(_Campo) .or. alltrim(_Campo) == 'null'
                _ret := '0'
            else
                _ret := _Campo
            EndIf

        Case valtype(_Campo) == 'N'
            If empty(_Campo) 
                _ret := '0'
            else
                _ret := alltrim(str(_Campo))
            EndIf
        OTHERWISE
            _ret := '0'
    EndCase
Return _ret
//
// -----------------------------------------------------------------------------------
//Transforma data string -> data date
Static Function _CastTipo(_sTipo)

    Do Case
        Case _sTipo == "payable"
            _sTp := '1'
        Case _sTipo == "transfer"
            _sTp := '2'
        Case _sTipo == "fee_collection"
            _sTp := '3'
    EndCase

Return _sTp
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




