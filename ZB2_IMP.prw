// Programa...: ZB2_IMP
// Autor......: Cláudia Lionço
// Data.......: 10/11/2020
// Descricao..: Importação de extrato de recebimento Banrisul - Versão 2018
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Importação de extrato de recebimento Banrisul
// #PalavasChave      #extrato #Banrisul #recebimento #cartoes 
// #TabelasPrincipais #ZB2
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB2_IMP()
	local i			:= 0
	Local cDir 		:= ""
	Local cArq 		:= ""
	Local cExt 		:= ""
	Local cLinha 	:= ""
	Local lContinue := .F.
	Private _aRel   := {}
	Private aErro 	:= {}
	Private _OpcExtrato :=""

	u_logIni ("Inicio Importação Banri " + DTOS(date()) )
	
	cPerg   := "ZB2_IMP"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif
	
	cDir := alltrim(mv_par01)
	cArq := alltrim(mv_par02)
	cExt := alltrim(mv_par03)
	
	cFile := alltrim(cDir)+ Alltrim(cArq)+ alltrim(cExt)
	If !File(cFile)
		MsgStop("O arquivo " + cFile + " não foi encontrado. A importação será abortada!","[ZB2] - ATENCAO")
		Return
	EndIf
	
	// VERIFICA SE O ARQUIVO CIELO É DE REGISTROS DE PAGAMENTO 04
	FT_FUSE(cFile)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	
	While i == 0 .and. !FT_FEOF()
		cLinha := FT_FREADLN()
		_OpcExtrato := SubStr(cLinha,43,7)
		
		If _OpcExtrato <> 'BJRVCMB' .AND.  _OpcExtrato <> 'BJRVCC1'  // Extrato de pagamentos
			u_help('O arquivo de extrato não é de pagamento! Registros não poderão ser importados!')
			lContinue := .F.
		Else
			lContinue := .T.
		EndIf
		i += 1
	EndDo
	FT_FUSE()
	
	// Importação
	If lContinue == .T.
		FT_FUSE(cFile)
		ProcRegua(FT_FLASTREC())
		FT_FGOTOP()
	
		While !FT_FEOF()
	
			IncProc("Lendo extrato Banri-Vero...")
			
			cLinha := FT_FREADLN()
			
			_TpReg := SubStr(cLinha,1,1)
			
			Do Case
			
				Case _TpReg == '0' // Header
					_aHeader := {}
					_aHeader := BuscaHeader(_aHeader, cLinha)
				
				Case _TpReg == '1' // Registro de lançamento
					_aRO := {}
					_aRO := BuscaRO(_aRO, cLinha)
				
				Case _TpReg == '2' //Registro de parcela de lançamento
					_aCV := {}
					_aCV := BuscaCV(_aCV, cLinha)
					
					// No registro 2 gravo os valores num registro do ZB1
					GravaZB2(_aHeader, _aRO, _aCV, _aRel )
					
			EndCase
			
			FT_FSKIP()
		EndDo
		
		FT_FUSE()
	
		// imprime relatório
		If len(_aRel) > 0
			RelImportacao(_aRel)
		EndIf
		ApMsgInfo("Importação dos registros concluída com sucesso!","[ZB2_IMP] - SUCESSO")
	EndIf
	u_logFim ("Fim Importação Banri-Vero " + DTOS(date()) )
Return
//
// --------------------------------------------------------------------------
// Carrega header do arquivo
Static Function BuscaHeader(_aHeader, cLinha)

    _sIDArq := SubStr(cLinha,43,7)
	_sDtRef := STOD(SubStr(cLinha,51,8))
	_dDtGer := STOD(SubStr(cLinha,59,8))
	_sOrig  := SubStr(cLinha,73,10)
	
	aadd (_aHeader,{ _sIDArq ,; // 1
					 _sDtRef ,; // 2
					 _dDtGer ,; // 3
					 _sOrig	 }) // 4

Return _aHeader
//
// --------------------------------------------------------------------------
// Carrega registro 1 - Registro de lançamento
Static Function BuscaRO(_aRO, cLinha)

    _sEstab   := SubStr(cLinha, 43, 14)
    _sFilial  := BuscaFilial(_sEstab)
	_sAgencia := SubStr(cLinha, 57,  4)
	_sConta   := SubStr(cLinha, 61, 10)
	_nVlrLiq  := Val(SubStr(cLinha, 71, 15))/100	
	
	aadd (_aRO,{ 	_sFilial	,; // 1
					_sEstab  	,; // 2
					_sAgencia	,; // 3
					_sConta     ,; // 4
					_nVlrLiq	}) // 5
	
Return _aRO
//
// --------------------------------------------------------------------------
// Carrega registro 2 - CV do arquivo
Static Function BuscaCV(_aCV, cLinha)

    _dDtLan  := STOD(SubStr(cLinha, 29, 8))
    _sCodLan := SubStr(cLinha, 37, 4)
    _dDtMov  := STOD(SubStr(cLinha, 43, 8))
    _sNSUCod := SubStr(cLinha, 51, 8)
    _sParNum := SubStr(cLinha, 59, 2)
	_nBrtPar := val(SubStr(cLinha, 61, 15))/100
    _nTarFix := val(SubStr(cLinha, 76,  6))/100
    _nTaxa   := (val(SubStr(cLinha, 82,  6))/100)/100
    _nTarADM := val(SubStr(cLinha, 88, 10))/100
    _nTarCOM := val(SubStr(cLinha, 98, 10))/100
    _nLiqPar := val(SubStr(cLinha,108, 15))/100
    _sSeqReg := SubStr(cLinha,312, 9)
	_sStaImp := 'I'
	_sDesLan := BuscaLancamento(_sCodLan)

	aadd (_aCV,{_dDtLan  ,; // 1
				_sCodLan ,; // 2
				_dDtMov  ,; // 3
				_sNSUCod ,; // 4
				_sParNum ,; // 5
				_nBrtPar ,; // 6
				_nTarFix ,; // 7
				_nTaxa   ,; // 8
				_nTarADM ,; // 9
				_nTarCOM ,; // 10
				_nLiqPar ,; // 11
				_sSeqReg ,; // 12
				_sStaImp ,; // 13
				_sDesLan }) // 14
				
Return _aCV
//
// --------------------------------------------------------------------------
// Grava ZB1
Static Function GravaZB2(_aHeader, _aRO, _aCV, _aRel )
	Begin Transaction
		
		sAut	 := PADL(sAut,6,' ')
		sNSU	 := alltrim(_aCV[1,4])
		sMov     := DTOS(_aCV[1,3])
		dbSelectArea("ZB2")
		dbSetOrder(1) // ZB2_NSUCOD +  ZB2_AUTCOD + ZB2_DTAMOV 
		dbGoTop()
		
		If !dbSeek(sNSU + sAut + sMov )
		
			Reclock("ZB2",.T.)
				ZB2 -> ZB2_FILIAL := _aRO[1,1]
				ZB2 -> ZB2_IDARQ  := _aHeader[1,1]
				ZB2 -> ZB2_DTAREF := _aHeader[1,2]
				ZB2 -> ZB2_DTAGER := _aHeader[1,3]
				ZB2 -> ZB2_ORIGEM := _aHeader[1,4]
				ZB2 -> ZB2_CODEST := _aRO[1,2]
				ZB2 -> ZB2_AGENCI := _aRO[1,3]
				ZB2 -> ZB2_CONTA  := _aRO[1,4]
				ZB2 -> ZB2_VLRLIQ := _aRO[1,5]
				ZB2 -> ZB2_DTALAN := _aCV[1,1]
				ZB2 -> ZB2_CODLAN := _aCV[1,2]
				ZB2 -> ZB2_DESLAN := _aCV[1,14]
				ZB2 -> ZB2_DTAMOV := _aCV[1,3]
				ZB2 -> ZB2_NSUCOD := _aCV[1,4]
				ZB2 -> ZB2_AUTCOD := sAut
				ZB2 -> ZB2_NUMPAR := _aCV[1,5]
				ZB2 -> ZB2_PARBRT := _aCV[1,6]
				ZB2 -> ZB2_TARFIX := _aCV[1,7]
				ZB2 -> ZB2_PERTAX := _aCV[1,8]
				ZB2 -> ZB2_VLRTAR := _aCV[1,9]
				ZB2 -> ZB2_TARCOM := _aCV[1,10]
				ZB2 -> ZB2_VLRPAR := _aCV[1,11]
				ZB2 -> ZB2_SEQREG := _aCV[1,12]
				ZB2 -> ZB2_STAIMP := _aCV[1,13]
				ZB2 -> ZB2_ARQUIV := alltrim(mv_par02)
			
			ZB2->(MsUnlock())

			aadd(_aRel,{ 	_aRO[1,1] ,; 	// filial
							_aCV[1,6] ,;    // vlr bruto
							_aRO[1,5] ,; 	// valor liquido da venda
							_aCV[1,11],; 	// valor da parcela
							_aCV[1,8] ,; 	// % taxa
							_aCV[1,9] ,;    // valor da taxa
							_aCV[1,3] ,;    // data do movimento
							sAut      ,; 	// autorização
							_aCV[1,4] ,; 	// NSU
							_aCV[1,14],;	// lançamento
							'INCLUIDO'  })

			u_log("Registro Importado! NSU:" + sNSU +" Autorização:"+ sAut)
		Else
			aadd(_aRel,{ 	_aRO[1,1] ,; 	// filial
							_aCV[1,6] ,;    // vlr bruto
							_aRO[1,5] ,; 	// valor liquido da venda
							_aCV[1,11],; 	// valor da parcela
							_aCV[1,8] ,; 	// % taxa
							_aCV[1,9] ,;    // valor da taxa
							_aCV[1,3] ,;    // data do movimento
							sAut      ,; 	// autorização
							_aCV[1,4] ,; 	// NSU
							_aCV[1,14],;	// lançamento
							'JÁ IMPORTADO'  })

			u_log("Registro já importado! NSU:" + sNSU +" Autorização:"+ sAut)
		EndIf

	End Transaction
Return _aRel
//
// --------------------------------------------------------------------------
// Busca filial pela empresa do arquivo
Static Function BuscaFilial(_sEmpresa)
	Local _oSQL  := ClsSQL ():New ()
	Local _aCNPJ := {}
	Local _sFilial := ""

	// BUSCA CNPJ LOGADO
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT M0_CODFIL FROM VA_SM0 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
	_oSQL:_sQuery += " AND M0_CODIGO = '01'"
	_oSQL:_sQuery += " AND M0_CGC = '"+ _sEmpresa +"'"
	_aCNPJ = aclone (_oSQL:Qry2Array ())

    If Len(_aCNPJ) > 0
        _sFilial := _aCNPJ[1,1]
    Else
        _sFilial := ""
    EndIf
	
Return _sFilial
//
// --------------------------------------------------------------------------
// Busca descrição do lançamento
Static Function BuscaLancamento(_sCodLan)
 
	If _OpcExtrato == 'BJRVCMB' 
		Do Case
			Case alltrim(_sCodLan)== '0201'
				_sDesLan := 'Débito à vista'
			Case alltrim(_sCodLan)== '0202'
				_sDesLan := 'Crédito a vista'
			Case alltrim(_sCodLan)== '0203'
				_sDesLan := 'Crédito parcelado lojista'
			Case alltrim(_sCodLan)== '0205'
				_sDesLan := 'Cancelamento/chargeback'
			Case alltrim(_sCodLan)== '0206'
				_sDesLan := 'Parcela à vista cred.parcelado'
			Case alltrim(_sCodLan)== '0207'
				_sDesLan := 'Crédito parcelado emissor'
			Case alltrim(_sCodLan)== '0208'
				_sDesLan := 'Crédito a vista internacional'
			Case alltrim(_sCodLan)== '0214'
				_sDesLan := 'Cartão de débito internacional'
			Case alltrim(_sCodLan)== '0021'
				_sDesLan := 'Alimentação PAT'
			Case alltrim(_sCodLan)== '0022'
				_sDesLan := 'Refeição PAT'
			Case alltrim(_sCodLan)== '0023'
				_sDesLan := 'Vouchers empresariais'
			Case alltrim(_sCodLan)== '0024'
				_sDesLan := 'Auto'
			Otherwise
				_sDesLan := ""
		EndCase
	Else
		Do Case
			Case alltrim(_sCodLan)== '0001'
				_sDesLan := 'À vista'
			Case alltrim(_sCodLan)== '0002'
				_sDesLan := 'Parcelado com entrada'
			Case alltrim(_sCodLan)== '0003'
				_sDesLan := 'Parcelado sem entrada'
			Case alltrim(_sCodLan)== '0004'
				_sDesLan := 'Pré-datado'
			Case alltrim(_sCodLan)== '0005'
				_sDesLan := 'Banco SIM parcelado'
			Case alltrim(_sCodLan)== '0006'
				_sDesLan := 'Crédito 1 minuto'
			Case alltrim(_sCodLan)== '0007'
				_sDesLan := 'Parcelado liquidado pelo cliente'
			Case alltrim(_sCodLan)== '0008'
				_sDesLan := 'Pré-datado pelo cliente'
			Case alltrim(_sCodLan)== '0009'
				_sDesLan := 'Giro fácil'
			Otherwise
				_sDesLan := ""
		EndCase
	EndIf

Return _sDesLan
//
// --------------------------------------------------------------------------
// Relatorio de registros importados
Static Function RelImportacao(_aRel)
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
	//Local oBreak1

	oReport := TReport():New("ZB2_IMP","Importação de pagamentos Banrisul",cPerg,{|oReport| PrintReport(oReport)},"Importação de pagamentos Banrisul")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Bruto"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Vlr.Parcela"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"%.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Dt.Movimento"  ,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"Lançamento"			,	    			,35,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"Status"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	, , "Total parcela ", "@E 999,999,999.99", NIL, .F., .T.)
	TRFunction():New(oSection1:Cell("COLUNA7")	,,"SUM"	, , "Total taxa "   , "@E 999,999,999.99", NIL, .F., .T.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local i         := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	For i:=1 to Len(_aRel)

// Busca dados do título para fazer a baixa
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "     SE1.E1_PREFIXO"	// 01
		_oSQL:_sQuery += "    ,SE1.E1_NUM"		// 02
		_oSQL:_sQuery += "    ,SE1.E1_PARCELA"	// 03
		_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"	// 04
		_oSQL:_sQuery += "    ,SE1.E1_LOJA"		// 05
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
		_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + _aRel[i, 1] + "'"
		_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aRel[i,7]) + "'"
		_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aRel[i,9] + "'"
		_aTitulo := aclone (_oSQL:Qry2Array ())

		If len(_aTitulo) > 0
			_sTitulo  := alltrim(_aTitulo[1,2]) +"/" + alltrim(_aTitulo[1,1] +"/"+_aTitulo[1,3])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aTitulo[1,4] + _aTitulo[1,5],"A1_NOME")
			_sCliente := alltrim(_aTitulo[1,4]) +"/" + alltrim(_sNome)
		Else
			_sTitulo  := "-"
			_sNome    := "-"
			_sCliente := "-"
		EndIf

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aRel[i,1] }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo   }) // titulo
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sCliente  }) // cliente
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aRel[i,2]})  // vlr. bruto
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aRel[i,3] }) // vlr. liquido
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aRel[i,4] }) // vlr.parcela
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aRel[i,5] }) // % taxa
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aRel[i,6] }) // vlr. taxa
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aRel[i,7] }) // dt. movimento
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aRel[i,8] }) // cod.autoriz
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aRel[i,9] }) // NSU
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aRel[i,10]}) // Lançamento
		oSection1:Cell("COLUNA13")	:SetBlock   ({|| _aRel[i,11]}) // status
			
		oSection1:PrintLine()
	Next
	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Diretorio          ", "C", 40, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Nome do arquivo    ", "C", 20, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {03, "Extensão           ", "C",  4, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
