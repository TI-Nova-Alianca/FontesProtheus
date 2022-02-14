// Programa...: ZB3CON
// Autor......: Cláudia Lionço
// Data.......: 19/07/2021
// Descricao..: Conciliação/baixa de títulos por registros de pgto Pagar.me
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Conciliação/baixa de títulos por registros de pgto Pagar.me
// #PalavasChave      #pagarme #pagar #recebimento #ecommerce #baixa_de_titulos
// #TabelasPrincipais #ZB1 #SE1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 
// -----------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB3CON()
    Local _oSQL  	  := ClsSQL ():New ()
	Local _aZB3  	  := {}
    Local _lContinua  := .T.
	Local i		 	  := 0
	Local x      	  := 0
	Local y           := 0
	Private _aRelImp  := {}
	Private _aRelErr  := {}

    u_logIni ("Inicio Conciliação pagar-me" + DTOS(date()) )

    cPerg   := "ZB3CON"
    _ValidPerg ()
    
    If ! pergunte (cPerg, .T.)
        return
    Endif

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "		SE1.E1_FILIAL AS FILIAL "       // 01
    _oSQL:_sQuery += "	   ,SE1.E1_PREFIXO AS PREFIXO "     // 02
    _oSQL:_sQuery += "	   ,SE1.E1_NUM AS NUMERO "          // 03
    _oSQL:_sQuery += "	   ,SE1.E1_PARCELA AS PARCELA "     // 04
    _oSQL:_sQuery += "	   ,SE1.E1_VALOR AS VALOR "         // 05
    _oSQL:_sQuery += "	   ,SE1.E1_CLIENTE AS CLIENTE "     // 06
    _oSQL:_sQuery += "	   ,SE1.E1_LOJA AS LOJA "           // 07
    _oSQL:_sQuery += "	   ,SE1.E1_EMISSAO AS EMISSAO "     // 08
    _oSQL:_sQuery += "	   ,SE1.E1_TIPO AS TIPO "           // 09
    _oSQL:_sQuery += "	   ,SE1.E1_BAIXA AS BAIXA "         // 10
    _oSQL:_sQuery += "	   ,SE1.E1_SALDO AS SALDO "         // 11
    _oSQL:_sQuery += "	   ,SE1.E1_STATUS AS TIT_STATUS "   // 12
    _oSQL:_sQuery += "	   ,SE1.E1_ADM AS TIT_ADM "         // 13
    _oSQL:_sQuery += "	   ,SE1.E1_VENCREA AS DTA_VENC "    // 14
    _oSQL:_sQuery += "	   ,ZB3.ZB3_IDTRAN AS ID_TRANS "    // 15
    _oSQL:_sQuery += "	   ,ZB3.ZB3_NSUCOD AS NSU "         // 16
    _oSQL:_sQuery += "	   ,ZB3.ZB3_AUTCOD AS AUTORIZACAO " // 17
    _oSQL:_sQuery += "	   ,ZB3.ZB3_DTAPGT AS DTA_PGTO "    // 18
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTOT AS VLR_TOTAL "   // 19
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRPAR AS VLR_PARC "    // 20
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTAX AS VLR_TAXA "    // 21
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'paid' THEN 'PAGO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'refunded' THEN 'DEVOL/RECUSADO' "
    _oSQL:_sQuery += "		END AS STATUS "                 // 22
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_BOLCOD <> '' THEN 'SIM' "
    _oSQL:_sQuery += "			ELSE 'NÃO' "
    _oSQL:_sQuery += "		END AS BOLETO "                 // 23
    _oSQL:_sQuery += "	   ,ZB3.ZB3_BOLDTA AS DTA_BOL "     // 24
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'boleto' THEN 'BOLETO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'credit_card' THEN 'CARTÃO CRED' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'pix' THEN 'PIX' "
    _oSQL:_sQuery += "		END AS TP_PGTO "                // 25
    _oSQL:_sQuery += "	   ,UPPER(ZB3.ZB3_ADMNOM) AS OPER " // 26
    _oSQL:_sQuery += "     ,ZB3.ZB3_STAIMP AS STAIMP"       // 27
    _oSQL:_sQuery += "     ,ZB3.ZB3_RECID "                 // 28
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZB3") + " AS ZB3 "
    _oSQL:_sQuery += "	LEFT JOIN " + RetSQLName ("SE1") + " AS SE1 "
    _oSQL:_sQuery += "		ON SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SE1.E1_VAIDT = ZB3.ZB3_IDTRAN "
    _oSQL:_sQuery += "			AND ((SE1.E1_PARCELA = ZB3.ZB3_PARPRO) "
    _oSQL:_sQuery += "				OR (TRIM(SE1.E1_PARCELA) = '' "
    _oSQL:_sQuery += "					AND ZB3.ZB3_PARPRO = 'A')) "
    _oSQL:_sQuery += "	WHERE ZB3.D_E_L_E_T_ = '' "
    //_oSQL:_sQuery += "  AND ZB3_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    //_oSQL:_sQuery += "	AND ZB3_DTAPGT BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) + "'"
    _oSQL:_sQuery += "	AND SE1.E1_NUM    <> '' "  // títulos encontrados
    _oSQL:_sQuery += "	AND SE1.E1_BAIXA   = '' "  // títulos não baixados
    _oSQL:_sQuery += "	AND ZB3.ZB3_STAIMP = 'I'"  // títulos com status importado
    If !empty(mv_par01)
        _oSQL:_sQuery += "	AND ZB3.ZB3_IDTRAN = '" + alltrim(str(mv_par01)) + "' " // FILTRA POR ID TRANSAÇÃO
    EndIf
    _oSQL:_sQuery += "	ORDER BY SE1.E1_NUM "              
    _oSQL:Log ()
		
	_aZB3 := aclone (_oSQL:Qry2Array ())

    _cMens := "Existem " + alltrim(str(len(_aZB3))) + " registros para realizar a baixa de títulos. Deseja continuar?"
    If MsgYesNo(_cMens,"Baixa de titulos")
        _nImpReg := 0
        _nTotReg := Len(_aZB3)

        For i:=1 to Len(_aZB3)
            _sNSUCod := _aZB3[i,16]			        // ZB3_NSUCOD
            _sAutCod := _aZB3[i,17]			        // ZB3_AUTCOD
            _sIdRec  := alltrim(str(_aZB3[i,28]))   // ZB3_RECID
            _sIdTran := alltrim(str(_aZB3[i,15]))   // ZB3_IDTRAN

            _nVlrTit := _aZB3[i,05] 		        // E1_VALOR
            _nVlrPar := _aZB3[i,20]                 // ZB3_VLRPAR
            _nVlrTax := _aZB3[i,21]                 // ZB3_VLRTAX

            _dDtaEmis := STOD(_aZB3[i,8]) 
            _dDtaPgto := STOD(_aZB3[i,18])          // data de recebimento do valor no banco
            _sAdm     := _aZB3[i,13]                // E1_ADM

            _nDecres := 0
            _nAcresc := 0

            // Baixa
            _sMotBaixa  := 'NORMAL' 
            _sHist      := 'Baixa pagar.me'
            _sBanco     := '237'
            _sAgencia   := '03471'
            _sConta     := '0000470   '

            If _nVlrTit <> _nVlrPar // verifica se o valor do titulo protheus é diferente do pagar.me
                _nDif := _nVlrTit - _nVlrPar

                If _nDif >= -0.05 .and. _nDif <= 0.05 // se a diferença for 5 centavos, é arredondamento
                    If _nDif > 0 // decrescimo
                        _nDecres := _nDif
                    Else         // acrescimo
                        _nAcresc := _nDif
                    EndIf

                    GravaAcrDes(_nAcresc, _nDecres, _aZB3[i,1], _aZB3[i,2], _aZB3[i,3], _aZB3[i,4], _aZB3[i,6], _aZB3[i,7])

                    //_nVlrLiq := _nVlrTit - _nVlrTax
                    _nVlrLiq := _nVlrPar - _nVlrTax
                    _lContinua := .T.
                    u_log("ENCONTRADA DIFERENÇA DE: " + alltrim(str(_nDif))+ " Registro RECID + IDTRAN:" + _sIdRec +"/"+ _sIdTran + ", mas processo continua!")
                Else
                    _lContinua := .F.
                    u_log("ENCONTRADA DIFERENÇA DE: " + alltrim(str(_nDif))+ " Registro RECID + IDTRAN:" + _sIdRec +"/"+ _sIdTran + ", PROCESSO CANCELADO!")
                EndIf
            Else
                //_nVlrLiq := _nVlrTit - _nVlrTax
                _nVlrLiq := _nVlrPar - _nVlrTax
                _lContinua := .T.  // se n for diferente, tudo certo
                u_log("SEM DIFERENÇA. Registro RECID + IDTRAN:" + _sIdRec +"/"+ _sIdTran)
            EndIf

            If _lContinua == .T.
                //u_help(_sBanco)
                // executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
                lMsErroAuto := .F.
                _aAutoSE1   := {}
                aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aZB3[i, 1]       , Nil})
                aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aZB3[i, 2]     	, Nil})
                aAdd(_aAutoSE1, {"E1_NUM"     	, _aZB3[i, 3]     	, Nil})
                aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aZB3[i, 4]     	, Nil})
                aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aZB3[i, 6]  		, Nil})
                aAdd(_aAutoSE1, {"E1_LOJA"    	, _aZB3[i, 7]  		, Nil})
                aAdd(_aAutoSE1, {"E1_TIPO"    	, _aZB3[i, 9] 		, Nil})
                AAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  		, Nil})
                AAdd(_aAutoSE1, {"AUTBANCO"  	, _sBanco           , Nil})  	
                AAdd(_aAutoSE1, {"AUTAGENCIA"   , _sAgencia         , Nil})  
                AAdd(_aAutoSE1, {"AUTCONTA"  	, _sConta           , Nil})
                //AAdd(_aAutoSE1, {"CBANCO"  		, _sBanco           , Nil})  	
                //AAdd(_aAutoSE1, {"CAGENCIA"   	, _sAgencia         , Nil})  
                //AAdd(_aAutoSE1, {"CCONTA"  		, _sConta           , Nil})                
                AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _dDtaPgto		 	, Nil})
                AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _dDtaPgto		 	, Nil})
                AAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    		, Nil})
                AAdd(_aAutoSE1, {"AUTDESCONT"	, _nVlrTax         	, Nil})
                AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
                AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
                AAdd(_aAutoSE1, {"AUTVALREC"  	, _nVlrLiq		    , Nil})
            
                _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

                cPerg = 'FIN070'
                _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
                // PARAMETRO 01 - Mostra Lço contabil -> 1 = sim, 2 = não
                // PARAMETRO 04 - Contabiliza On-Line -> 1 = sim, 2 = não
                U_GravaSX1 (cPerg, "01", 2)    
                U_GravaSX1 (cPerg, "04", 2)    
                U_GravaSXK (cPerg, "01", "2", 'G' )
                U_GravaSXK (cPerg, "04", "2", 'G' )

                MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

                If lMsErroAuto
                    u_log(memoread (NomeAutoLog ()))
                    u_log("IMPORTAÇÃO NÃO REALIZADA: Registro RECID + IDTRAN:" + _sIdRec +"/"+ _sIdTran)
                    
                    // Salva dados para impressão
                    _nTot := _nVlrLiq + _nVlrTax
                    _sErro := ALLTRIM(memoread (NomeAutoLog ()))
                    aadd(_aRelErr,{ _aZB3[i,1],; // filial
                                    _aZB3[i,2],; // prefixo
                                    _aZB3[i,3],; // número
                                    _aZB3[i,4],; // parcela
                                    _aZB3[i,6],; // cliente
                                    _aZB3[i,7],; // loja
                                    _nVlrLiq  ,; // valor recebido
                                    _nVlrTax  ,; // taxa
                                    _nTot     ,; // recebido + taxa
                                    _sAutCod  ,; // autorização
                                    _sNSUCod  ,; // NSU
                                    _sErro    }) // status

                Else               
                    _nTot := _nVlrLiq + _nVlrTax     
                    // Salva dados para impressão
                    aadd(_aRelImp,{ _aZB3[i,1],; // filial
                                    _aZB3[i,2],; // prefixo
                                    _aZB3[i,3],; // número
                                    _aZB3[i,4],; // parcela
                                    _aZB3[i,6],; // cliente
                                    _aZB3[i,7],; // loja
                                    _nVlrLiq  ,; // valor recebido
                                    _nVlrTax  ,; // taxa
                                    _nTot     ,; // recebido + taxa
                                    _sAutCod  ,; // autorização
                                    _sNSUCod  ,; // NSU
                                    'BAIXADO' }) // status

                    dbSelectArea("ZB3")
                    dbSetOrder(1) // ZB3_RECID + ZB3_IDTRAN
                    dbGoTop()

                    If dbSeek(PADR(_sIdRec,12,' ') + PADR(_sIdTran ,12,' '))
                        Reclock("ZB3",.F.)
                            ZB3 -> ZB3_STAIMP := 'C'
                            ZB3 -> ZB3_DTABAI := dDataBase
                        ZB3->(MsUnlock())
                    EndIf

                    _nImpReg += 1
                    u_log("IMPORTAÇÃO FINALIZADA COM SUCESSO: Registro RECID + IDTRAN:" + _sIdRec +"/"+ _sIdTran)
                Endif
                
                U_GravaSXK (cPerg, "01", "2", 'D' )
                U_GravaSXK (cPerg, "04", "2", 'D' )

                U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
            
            EndIf		
        Next
        u_help("Processo finalizado! Baixados "+ alltrim(str(_nImpReg)) +" de " + alltrim(str(_nTotReg)) )

        If len(_aRelErr) > 0 .or. len(_aRelImp) > 0
            RelBaixas(_aRelImp, _aRelErr)
        Endif
    Else
        u_help("Operação cancelada pelo usuário!")
        u_log("OPERAÇÃO CANCELADA PELO USUÁRIO")
    EndIf
	
	u_logFim ("Fim Conciliação pagar.me " + DTOS(date()) )

Return
//
// --------------------------------------------------------------------------
// Função para gravação de acrescimo/decrescimo
Static Function GravaAcrDes(_nAcresc, _nDecres, _sFilial, _sPrefixo, _sTitulo, _sParcela, _sCliente, _sLoja)

    u_log("Gravação de acrescimo/decrescimo do título:" + _sFilial +"/"+ _sPrefixo +"/"+ _sTitulo +"/"+ _sParcela +"/"+ _sCliente +"/"+ _sLoja)
    dbSelectArea("SE1")
    dbSetOrder(2) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
    dbGoTop()

    If DbSeek(xFilial("SE1") + _sCliente + _sLoja + _sPrefixo + _sTitulo + _sParcela)
        RecLock("SE1",.F.)
            SE1-> E1_ACRESC  := _nAcresc
            SE1-> E1_DECRESC := (_nDecres) * -1
        MsUnLock()

        If _nDecres <> 0
            u_log("Decrescimo de : " + alltrim(str(_nDecres)))
        EndIf
        If _nAcresc <> 0
            u_log("Acrescimo de : " + alltrim(str(_nAcresc)))
        EndIf
    EndIf
Return
//
// --------------------------------------------------------------------------
// Relatorio de registros importados
Static Function RelBaixas(_aRelImp, _aRelErr)
	Private oReport
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil

	oReport := TReport():New("ZB3CON","Baixas de títulos Pagar-me",cPerg,{|oReport| PrintReport(oReport)},"Baixas de títulos Pagar-me")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Recebido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Total"		    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Status"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .T., .F.)
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .T., .F.)
    TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	, , "Total      "	  , "@E 999,999,999.99", NIL, .T., .F.)

	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Vlr.Recebido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection2,"COLUNA6", 	"" ,"Total"		    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA8", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA9", 	"" ,"Status"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection2:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .T., .F.)
	TRFunction():New(oSection2:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .T., .F.)
    TRFunction():New(oSection2:Cell("COLUNA6")	,,"SUM"	, , "Total     "	  , "@E 999,999,999.99", NIL, .T., .F.)
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local i         := 0

	If len(_aRelImp) > 0
		oSection1:Init()

		oReport:PrintText("TÍTULOS BAIXADOS" ,,100)
		oReport:PrintText("" ,,100)

		oSection1:SetHeaderSection(.T.)

		For i:=1 to Len(_aRelImp)
			_sTitulo  := alltrim(_aRelImp[i,3]) +"/" + alltrim(_aRelImp[i,2] +"/"+_aRelImp[i,4])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aRelImp[i,5] + _aRelImp[i,6],"A1_NOME")
			_sCliente := alltrim(_aRelImp[i,5]) +"/" + alltrim(_sNome)

			oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aRelImp[i,1]  })
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo       })
			oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sCliente      })
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aRelImp[i,7]  })
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aRelImp[i,8]  })
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aRelImp[i,9]  })
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aRelImp[i,10] })
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aRelImp[i,11] })
            oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aRelImp[i,12] })
			
			oSection1:PrintLine()
		Next
		oSection1:Finish()
	EndIf
	
	If len(_aRelErr) > 0
		oReport:PrintText("" ,,100)
		oReport:PrintText("" ,,100)
		oReport:PrintText("" ,,100)
		oReport:ThinLine()

		oSection2:Init()

		oReport:PrintText("TÍTULOS COM ERROS" ,,100)
		oReport:PrintText("" ,,100)

		oSection2:SetHeaderSection(.T.)
		For i:=1 to Len(_aRelErr)
			_sTitulo  := alltrim(_aRelErr[i,3]) +"/" + alltrim(_aRelErr[i,2] +"/"+_aRelErr[i,4])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aRelErr[i,5] + _aRelErr[i,6],"A1_NOME")
			_sCliente := alltrim(_aRelErr[i,5]) +"/" + alltrim(_sNome)

			oSection2:Cell("COLUNA1")	:SetBlock   ({|| _aRelErr[i,1]  })
			oSection2:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo       })
			oSection2:Cell("COLUNA3")	:SetBlock   ({|| _sCliente      })
			oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aRelErr[i,7]  })
			oSection2:Cell("COLUNA5")	:SetBlock   ({|| _aRelErr[i,8]  })
			oSection2:Cell("COLUNA6")	:SetBlock   ({|| _aRelErr[i,9]  })
			oSection2:Cell("COLUNA7")	:SetBlock   ({|| _aRelErr[i,10] })
			oSection2:Cell("COLUNA8")	:SetBlock   ({|| _aRelErr[i,11] })
            oSection2:Cell("COLUNA8")	:SetBlock   ({|| _aRelErr[i,12] })
			
			oSection2:PrintLine()
		Next
		oSection2:Finish()
	EndIf
	
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes  
    aadd (_aRegsPerg, {01, "Id Transação       ", "N", 9, 0,  "", "   ", {},                         		""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
 