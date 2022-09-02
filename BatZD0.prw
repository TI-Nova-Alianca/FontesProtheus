// Programa...: BatZD0
// Autor......: Cláudia Lionço
// Data.......: 06/07/2022
// Descricao..: Baixa de registro de recebíveis pagos Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Batch
// #Descricao         #Baixa de registro de recebíveis pagos Pagar.me
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

User Function BatZD0(_sTipo)
    Private cPerg := "BatZD0"
	
    u_logIni()

    _ValidPerg()
    If Pergunte(cPerg,.T.)  
        dDataIni := mv_par01
        dDataFin := mv_par02

        u_log2('aviso', 'Pagar.me:' + DTOC(mv_par01) +" até "+ DTOC(mv_par02))

        If _sTipo == '2' 
            MsAguarde({|| _GravaPgtos(_sTipo, dDataIni, dDataFin)}, "Aguarde...", "Processando Registros...")
        else
            _GravaPgtos(_sTipo,  dDataIni, dDataFin)
        EndIf
    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Busca Pagamentos recebidos no período
Static Function _GravaPgtos(_sTipo, dDataIni, dDataFin) 
    local cUrlReceb  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetorno   := ""
    local i          := 1
    local oJSONR

    cUrlReceb := _RetLinkPgto( dDataIni, dDataFin)
    cRetorno := HttpGet( cUrlReceb , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link

    oJSONR:= JsonObject():New()
    oJSONR:fromJSON(cRetorno)

    nNumReg := len(oJSONR)

    If nNumReg >=0
        u_log2('aviso', 'Pagar.me: Qnt.de pagamentos de recebiveis no período '+ alltrim(Str(nNumReg)) + ".Período:" + DTOC(mv_par01) +" até "+ DTOC(mv_par02))
    else
        u_log2('aviso', 'Verifique a chave API')
    EndIf
    
    If nNumReg >= 0
        For i := 1 to nNumReg
            If _sTipo == '2'
                MsProcTxt("Importando registro " + alltrim(str(i)) + " de " + alltrim(str(nNumReg)) + "...")
            EndIf

            _lContinua := .T.
            _sId         := alltrim(STR(IIF(empty(oJSONR[i]["id"])              , 0                 , oJSONR[i]["id"])))
            _sIdTrans    := alltrim(STR(IIF(empty(oJSONR[i]["transaction_id"])  , 0                 , oJSONR[i]["transaction_id"])))
            _sStatus     := IIF(empty(oJSONR[i]["status"])                      ,""                 , oJSONR[i]["status"])
            _dDtPgto     := IIF(Empty(oJSONR[i]["payment_date"])                ,STOD('19000101')   ,_CastData(oJSONR[i]["payment_date"]))
            _dDtCriacao  := IIF(Empty(oJSONR[i]["date_created"])                ,STOD('19000101')   ,_CastData(oJSONR[i]["date_created"]))
            _sTpPgto     := IIF(Empty(oJSONR[i]["type"])                        , ""                , oJSONR[i]["type"])
            _sMetodoPgto := IIF(Empty(oJSONR[i]["payment_method"])              , ""                , oJSONR[i]["payment_method"])
            _nParcela    := IIF(empty(oJSONR[i]["installment"])                 , 0                 , oJSONR[i]["installment"])
            _nVlr        := IIF(empty(oJSONR[i]["amount"])                      , 0                 , oJSONR[i]["amount"]/100)
            _nTaxa       := IIF(empty(oJSONR[i]["fee"])                         , 0                 , oJSONR[i]["fee"]/100)
            _nTaxaAntec  := IIF(empty(oJSONR[i]["anticipation_fee"])            , 0                 , oJSONR[i]["anticipation_fee"]/100)
            _nTaxaFraude := IIF(empty(oJSONR[i]["fraud_coverage_fee"])          , 0                 , oJSONR[i]["fraud_coverage_fee"]/100)
            _sParProt    := _BuscaParcProtheus(_nParcela)
            _nVlrTaxTot  := _nTaxa + _nTaxaAntec + _nTaxaFraude
            _nVlrLiq     := _nVlr - _nVlrTaxTot
           
            dbSelectArea("ZD0") 
            dbSetOrder(1) 
            dbGoTop()
            
            _sChaveZD0 := xFilial('ZD0') + PADR(alltrim(_sIdTrans),15,' ') + PADR(alltrim(_sId),15,' ')
            If !dbSeek(_sChaveZD0)
                Begin Transaction
                    Reclock("ZD0",.T.)
                    ZD0 -> ZD0_FILIAL := xFilial('ZD0')
                    ZD0 -> ZD0_RID    := _sId
                    ZD0 -> ZD0_TID    := _sIdTrans
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

                    ZD0->(MsUnlock())
                End Transaction

                _GravaTransacoes(_sTipo, _sChaveZD0, _sIdTrans, _sId)
            Else
                _lContinua := .F.
                u_log2('aviso', 'Transação ' + alltrim(_sIdTrans) + ' Recebível:'+ alltrim(_sId) + ' já gravada no sistema.')
            EndIf            
        Next
        // If _sTipo == '2'
        //     u_help("Importação finalizada com sucesso!")
        //     _cMens := "Deseja realizar a geração dos RA's?"
        //     If MsgYesNo(_cMens,"ATENÇÃO","YESNO")
        //         u_ZD0RAS(dDataIni, dDataFin)
        //     EndIf
        // else
        //     u_log2('aviso', 'Importação finalizada com sucesso!')
        // EndIf
        If _sTipo == '2'
            u_help('Importação finalizada!')
        else
            u_log2('aviso', 'Importação finalizada!')
        EndIf
        // Emite relatório da importação
        U_ZD0RIMP(mv_par01, mv_par02)

    EndIf
Return
//
// -----------------------------------------------------------------------------------
// Acessa o link da transação para gravar demais dados
Static Function _GravaTransacoes(_sTipo, _sChaveZD0,_sIdTrans, _sId)
    local cUrlTrans  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetTrans  := ""
    local oJSONT

    cUrlTrans := _RetLinkTransacao(_sIdTrans) // Monta Link
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

        // Dados das transações
        _nTVlr       := IIF(Empty(oJSONT["amount"])          , 0 , oJSONT["amount"]/100) 
        _nTParTot    := IIF(Empty(oJSONT["installments"])    , 0 , oJSONT["installments"])
        _sNomeCart   := IIF(Empty(oJSONT["card_holder_name"]), "", oJSONT["card_holder_name"])
        _sBandCart   := IIF(Empty(oJSONT["card_brand"])      , "", oJSONT["card_brand"])

        // Grava transação
        dbSelectArea("ZD0") 
        dbSetOrder(1) 
        dbGoTop()
        
        If dbSeek(_sChaveZD0)
            Begin Transaction
                Reclock("ZD0",.F.)
                    ZD0 -> ZD0_VLRTOT  := _nTVlr
                    ZD0 -> ZD0_QTDPAR  := _nTParTot
                    ZD0 -> ZD0_CARDN   := _sNomeCart
                    ZD0 -> ZD0_CARDB   := _sBandCart
                    ZD0 -> ZD0_STABAI  := 'A'

                ZD0->(MsUnlock())
            End Transaction
        Else
            _lContinua := .F.
            u_log2('aviso', 'Transação ' + alltrim(_sIdTrans) + ' não encontrado no sistema.')
        EndIf        
    Else
        u_log2('aviso', 'Pagar.me: Sem registro de transação')
    Endif
Return
//
// -----------------------------------------------------------------------------------
// Cria o link de recebíveis pagos
Static Function _RetLinkPgto( dDataIni, dDataFin)
    Local _sDt01  := alltrim(str(Year(dDataIni))) + "-" + PADL(alltrim(str(Month(dDataIni))),2,'0') +"-"+ PADL(alltrim(str(Day(dDataIni))),2,'0')
    Local _sDt02  := alltrim(str(Year(dDataFin))) +"-"+ PADL(alltrim(str(Month(dDataFin))),2,'0') +"-"+PADL(alltrim(str(Day(dDataFin))),2,'0')
    Local _sAkKey := GETMV("VA_PAGAR")
    
    _sLink := 'https://api.pagar.me/1/payables?api_key='+_sAkKey +'&count=1000&payment_date=>='+ _sDt01 +'T00:00:00.000Z&payment_date=<='+ _sDt02 +'T23:59:59.000Z'

    u_log2("Aviso", " Link de pagamentos recebidos gerado:" + _sLink)
Return _sLink
//
// -----------------------------------------------------------------------------------
// Cria o link de transações
Static Function _RetLinkTransacao(_sIdTransacao)
    Local _sAkKey := GETMV("VA_PAGAR")

    _sLink  := 'https://api.pagar.me/1/transactions/' + _sIdTransacao + '?api_key=' + alltrim(_sAkKey)
    u_log2("Aviso", _sLink)
Return _sLink
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
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT          TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial ", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Final   ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return




