//  Programa...: BatPagar
//  Autor......: Cláudia Lionço
//  Data.......: 15/12/2020
//  Cliente....: Alianca
//  Descricao..: Batch para baixa e gravação de transações pagar.me
//
// #TipoDePrograma    #batch
// #Descricao         #Batch para baixa e gravação de transações pagar.me
// #PalavasChave      #Pagarme #baixa_de_titulos #ecommerce  
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function BatPagar(_sTipo)
    Private cPerg := "BatPagar"
	
    _sTipo := '2'
    If _sTipo == '1' // Bat
        dDataIni := DaySub(Date(),1)
        dDataFin := DaySub(Date(),1)
    Else            // Tela de sistema
        _ValidPerg()
	    Pergunte(cPerg,.T.)  
        dDataIni := mv_par01
        dDataFin := mv_par02
    EndIf

    u_log2('aviso', 'Pagar.me:' + DTOC(mv_par01) +" até "+ DTOC(mv_par02))
    _BuscaRecebiveis(dDataIni, dDataFin)  

Return
//
// -----------------------------------------------------------------------------------
// Acessa o link de recebiveis do dia anterior =  Recebiveis são as parcelas recebidas
Static Function _BuscaRecebiveis(dDataIni, dDataFin)
    local cUrlReceb  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetorno   := ""
    local i          := 1
    local aTrans     := {}
    local aParcela   := {}
    local oJSON

    cUrlReceb := MontaLinkReceb(dDataIni, dDataFin) // Monta Link Recebiveis
    
    cRetorno := HttpGet( cUrlReceb , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link

    oJSON := JsonObject():New()
    oJSON:fromJSON(cRetorno)

    nNumReg := len(oJSON)

    u_log2('aviso', 'Pagar.me: Qnt. registros:' + alltrim(Str(nNumReg)))
    If nNumReg == 0
        u_log2('aviso', 'Verifique a chave API')
    EndIf
    
    If nNumReg > 0
        For i := 1 to nNumReg
            aParcela    := {}

            _nId         := IIF(empty(oJSON[i]["id"]), 0, oJSON[i]["id"])
            _sStatus     := IIF(empty(oJSON[i]["status"]),"", oJSON[i]["status"])
            _nVlrBrtPar  := IIF(empty(oJSON[i]["amount"]), 0, oJSON[i]["amount"]/100)
            _nTaxa       := IIF(empty(oJSON[i]["fee"]), 0, oJSON[i]["fee"]/100)
            _nTaxaAntec  := IIF(empty(oJSON[i]["anticipation_fee"]), 0, oJSON[i]["anticipation_fee"]/100)
            _nTaxaFraude := IIF(empty(oJSON[i]["fraud_coverage_fee"]), 0, oJSON[i]["fraud_coverage_fee"]/100)
            _nParcela    := IIF(empty(oJSON[i]["installment"]), 0, oJSON[i]["installment"])
            _nIdTransacao:= IIF(empty(oJSON[i]["transaction_id"]), 0, oJSON[i]["transaction_id"])
            _sIdTransacao:= Alltrim(str(_nIdTransacao))
            _dDtPgto     := IIF(Empty(oJSON[i]["payment_date"]),STOD('19000101'),_CastData(oJSON[i]["payment_date"]))
            _dDtPgtoOri  := IIF(Empty(oJSON[i]["original_payment_date"]),STOD('19000101'),_CastData(oJSON[i]["original_payment_date"]))
            _sTipo       := IIF(Empty(oJSON[i]["type"]), "", oJSON[i]["type"])
            _sMetodoPgto := IIF(Empty(oJSON[i]["payment_method"]), "", oJSON[i]["payment_method"])
            _dDtAcres    := IIF(Empty(oJSON[i]["accrual_date"]),STOD('19000101'),_CastData(oJSON[i]["accrual_date"]))
            _dDtCriacao  := IIF(Empty(oJSON[i]["date_created"]),STOD('19000101'),_CastData(oJSON[i]["date_created"]))

            _sParcPro := _BuscaParcProtheus(_nParcela)

            aadd (aParcela,{    _nId            ,; //  1
					            _sStatus        ,; //  2
					            _nVlrBrtPar     ,; //  3
					            _nTaxa	        ,; //  4
                                _nTaxaAntec     ,; //  5
                                _nTaxaFraude    ,; //  6
                                _nParcela       ,; //  7
                                _nIdTransacao   ,; //  8
                                _dDtPgto        ,; //  9
                                _dDtPgtoOri     ,; // 10
                                _sTipo          ,; // 11
                                _sMetodoPgto    ,; // 12
                                _dDtAcres       ,; // 13
                                _dDtCriacao     ,; // 14
                                _sParcPro       }) // 15

            aTrans := _BuscaTransacao(_sIdTransacao)

            // -----------------------------------------------------------------------
            // GRAVA REGISTRO ZB3
            _lRetGrv := _GravaZB3(aTrans, aParcela)

            If _lRetGrv == .T.
                u_log2('aviso', "Registro " + _sIdTransacao + " gravado com sucesso!")
            Else
                u_log2('aviso', "Registro " + _sIdTransacao + " não gravado!")
            EndIf
        Next
    Else
        u_log2('aviso', 'Pagar.me: Sem registros')
        u_help("Sem registros")
    Endif

Return
//
// -----------------------------------------------------------------------------------
// Retorna array com dados da transação
Static Function _BuscaTransacao(_sIdTransacao)
    local cUrlTrans  := ""
    local cGetParms  := ""
    local nTimeOut   := 200
    local aHeadStr   := {"Content-Type: application/json"}
    local cHeaderGet := ""
    local cRetTrans  := ""
    Local aTrans     := {}
    local oJSONT

    cUrlTrans := MontaLinkTrans(_sIdTransacao) // Monta Link
    cRetTrans := HttpGet( cUrlTrans , cGetParms, nTimeOut, aHeadStr, @cHeaderGet ) // Retorno do link da transação

    oJSONT := JsonObject():New()
    oJSONT:fromJSON(cRetTrans)

    nNum := len(oJSONT)

    If nNum == 0 

        _sTStatus    := IIF(empty(oJSONT["status"]), "",oJSONT["status"])
        _sTMotRecusa := IIF(empty(oJSONT["refuse_reason"]), "",oJSONT["refuse_reason"])   
        _sTStaAgente := IIF(empty(oJSONT["status_reason"]), "",oJSONT["status_reason"])   
        _sTCodAut    := IIF(empty(oJSONT["authorization_code"]), "",oJSONT["authorization_code"])   
        _sTNSU       := IIF(empty(oJSONT["nsu"]), "",alltrim(str(oJSONT["nsu"])))   
        _dTDtaCri    := IIF(Empty(oJSONT["date_created"]),STOD('19000101'),_CastData(oJSONT["date_created"]))  
        _dTDtaUpd    := IIF(Empty(oJSONT["date_update"]),STOD('19000101'),_CastData(oJSONT["date_update"]))  
        _nTVlrBrt    := IIF(Empty(oJSONT["amount"]), 0, oJSONT["amount"]/100) 
        _nTVlrAut    := IIF(Empty(oJSONT["authorized_amount"]), 0, oJSONT["authorized_amount"]/100)
        _nTVlrPago   := IIF(Empty(oJSONT["paind_amount"]), 0, oJSONT["paind_amount"]/100)
        _nTVlrRec    := IIF(Empty(oJSONT["refunded_amount"]), 0, oJSONT["refunded_amount"]/100)
        _nTParTot    := IIF(Empty(oJSONT["installments"]), 0, oJSONT["installments"])
        _nTCusto     := IIF(Empty(oJSONT["cost"]), 0, oJSONT["cost"]/100)
        _sNomeCart   := IIF(Empty(oJSONT["card_holder_name"]), "", oJSONT["card_holder_name"])
        _sBandCart   := IIF(Empty(oJSONT["card_brand"]), "", oJSONT["card_brand"])
        _sUrlBoleto  := IIF(Empty(oJSONT["boleto_url"]), "", oJSONT["boleto_url"])
        _sBarCodrBol := IIF(Empty(oJSONT["boleto_barcode"]), "", oJSONT["boleto_barcode"])
        _dDtaBol     := IIF(Empty(oJSONT["boleto_expiration_date"]),STOD('19000101'),_CastData(oJSONT["boleto_expiration_date"]))

        aadd (aTrans,{  _sTStatus       ,; //  1
				        _sTMotRecusa    ,; //  2
				        _sTStaAgente    ,; //  3
				        _sTCodAut	    ,; //  4
				        _sTNSU          ,; //  5
				        _dTDtaCri       ,; //  6
				        _dTDtaUpd       ,; //  7
				        _nTVlrBrt       ,; //  8
				        _nTVlrAut       ,; //  9
				        _nTVlrPago      ,; // 10
				        _nTVlrRec       ,; // 11
				        _nTParTot       ,; // 12
				        _nTCusto        ,; // 13
				        _sNomeCart      ,; // 14
				        _sBandCart      ,; // 15
				        _sUrlBoleto     ,; // 16
				        _sBarCodrBol    ,; // 17
				        _dDtaBol        }) // 18

    Else
        If nNum > 0
            u_help("Vários registros encontrados")
        Else
            u_help("Sem registros de transações")
        EndIf
    Endif
Return aTrans
//
// -----------------------------------------------------------------------------------
// Grava registro em tabela ZB3
Static Function _GravaZB3(aTrans, aParcela)
    Local _lRet := .T.

	Begin Transaction

        sId  := Alltrim(Str(aParcela[1, 1]))    
		
		dbSelectArea("ZB3") 
		dbSetOrder(1) 
		dbGoTop()
		
		If !dbSeek(sId)
            If alltrim(aTrans[1, 1]) == 'refunded'
                _sStaTrans := 'R'
            Else
                _sStaTrans := 'I'
            EndIf

			Reclock("ZB3",.T.)
                //ZB3->ZB3_FILIAL := cFilAnt
				ZB3->ZB3_RECID  := aParcela[1, 1]
                ZB3->ZB3_STAPAR := aParcela[1, 2]
                ZB3->ZB3_VLRPAR := aParcela[1, 3]
                ZB3->ZB3_VLRTAX := aParcela[1, 4]
                ZB3->ZB3_ANTTAX := aParcela[1, 5]
                ZB3->ZB3_FRATAX := aParcela[1, 6]
                ZB3->ZB3_PARCEL := aParcela[1, 7]
                ZB3->ZB3_IDTRAN := aParcela[1, 8]
                ZB3->ZB3_DTAPGT := aParcela[1, 9]
                ZB3->ZB3_PGTORI := aParcela[1,10]
                ZB3->ZB3_TIPREG := aParcela[1,11]
                ZB3->ZB3_METPGT := aParcela[1,12]
                ZB3->ZB3_DTAACR := aParcela[1,13]
                ZB3->ZB3_DTACRI := aParcela[1,14]
                ZB3->ZB3_PARPRO := aParcela[1,15]
                ZB3->ZB3_STATRN := aTrans[1, 1]
                ZB3->ZB3_MOTREC := aTrans[1, 2]
                ZB3->ZB3_STAAGE := aTrans[1, 3]
                ZB3->ZB3_AUTCOD := aTrans[1, 4]
                ZB3->ZB3_NSUCOD := aTrans[1, 5]                
                ZB3->ZB3_DTAEMI := aTrans[1, 6]
                ZB3->ZB3_DTAUPD := aTrans[1, 7]
                ZB3->ZB3_VLRTOT := aTrans[1, 8]
                ZB3->ZB3_VLRAUT := aTrans[1, 9]
                ZB3->ZB3_VLRPGT := aTrans[1,10]
                ZB3->ZB3_VLREST := aTrans[1,11]
                ZB3->ZB3_PARTOT := aTrans[1,12]
                ZB3->ZB3_CUSTO  := aTrans[1,13]
                ZB3->ZB3_NOMCAR := aTrans[1,14]
                ZB3->ZB3_ADMNOM := aTrans[1,15]
                ZB3->ZB3_BOLURL := aTrans[1,16]
                ZB3->ZB3_BOLCOD := aTrans[1,17]
                ZB3->ZB3_BOLDTA := aTrans[1,18]
                ZB3->ZB3_STAIMP := _sStaTrans
                //ZB3->ZB3_DTABAI := ""
			ZB3->(MsUnlock())
        Else
            _lRet := .F.
        EndIf
	End Transaction

Return _lRet
//
// -----------------------------------------------------------------------------------
// Cria o link de recebiveis
Static Function MontaLinkReceb(dDataIni, dDataFin)
    Local _sDia  := ""
    Local _sMes  := ""
    Local _sAno  := ""
    Local _sDt01 := ""
    Local _sDt02 := ""

    _sDia   := PADL(alltrim(str(Day(dDataIni))),2,'0')
    _sMes   := PADL(alltrim(str(Month(dDataIni))),2,'0')
    _sAno   := alltrim(str(Year(dDataIni)))
    _sDt01  := _sAno + "-" + _sMes + "-" + _sDia

    _sDia   := PADL(alltrim(str(Day(dDataFin))),2,'0')
    _sMes   := PADL(alltrim(str(Month(dDataFin))),2,'0')
    _sAno   := alltrim(str(Year(dDataFin)))
    _sDt02  := _sAno +"-"+_sMes+"-" + _sDia
    _sAkKey := GETMV("VA_PAGARME")//ak_live_NibpfgedhX5VM3nyFWTo5hiBF6TleD

    _sLink := 'https://api.pagar.me/1/payables?count=500&created_at=%3E=' + _sDt01 + 'T00:00:00.000Z&created_at=%3C=' + _sDt02 + 'T23:59:59.999Z&status=paid&api_key=' + alltrim(_sAkKey)
Return _sLink
//
// -----------------------------------------------------------------------------------
// Cria o link de transações
Static Function MontaLinkTrans(_sIdTransacao)
    _sAkKey := GETMV("VA_PAGARME")
    _sLink  := 'https://api.pagar.me/1/transactions/' + _sIdTransacao + '?api_key=' + alltrim(_sAkKey)
Return _sLink
//
// -----------------------------------------------------------------------------------
//Transforma data string -> data date
Static Function _CastData(_sDt)

    _sAno := SubStr(_sDt, 1, 4)
    _sMes := SubStr(_sDt, 6, 2)
    _sDia := SubStr(_sDt, 9, 2)
    _dDt  := STOD(_sAno + _sMes + _sDia)

Return _dDt

Static Function _BuscaParcProtheus(_nParcela)
    Local _sParcPro := ""

    Do Case
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

    EndCase
Return _sParcPro
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
