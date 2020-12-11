// Programa...: ZB1_IMP
// Autor......: Cláudia Lionço
// Data.......: 21/08/2020
// Descricao..: Importação de extrato de recebimento Cielo - EDI 13 Cielo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Importação de extrato de recebimento Cielo
// #PalavasChave      #extrato #cielo #recebimento #cartoes 
// #TabelasPrincipais #ZB1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 14/10/2020 - Claudia - Alterada a impressão das colunas vlr.liquido e taxa.GLPI: 8647
// 02/12/2020 - Claudia - Ajuste de devoluções - GLPI: 8937
//
// --------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB1_IMP()
	local i			:= 0
	Local cDir 		:= ""
	Local cArq 		:= ""
	Local cExt 		:= ""
	Local cLinha 	:= ""
	Local lContinue := .F.
	Private _aRel   := {}
	Private aErro 	:= {}

	u_logIni ("Inicio Importação Cielo " + DTOS(date()) )
	
	cPerg   := "ZB1_IMP"
	_ValidPerg ()
	If ! pergunte (cPerg, .T.)
		return
	Endif
	
	cDir := alltrim(mv_par01)
	cArq := alltrim(mv_par02)
	cExt := alltrim(mv_par03)
	
	cFile := alltrim(cDir)+ Alltrim(cArq)+ alltrim(cExt)
	If !File(cFile)
		MsgStop("O arquivo " + cFile + " não foi encontrado. A importação será abortada!","[ZB1] - ATENCAO")
		Return
	EndIf
	
	// VERIFICA SE O ARQUIVO CIELO É DE REGISTROS DE PAGAMENTO 04
	FT_FUSE(cFile)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	
	While i == 0 .and. !FT_FEOF()
		cLinha := FT_FREADLN()
		_OpcExtrato := SubStr(cLinha,48,2)
		
		If _OpcExtrato <> '04' // Extrato de pagamentos
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
	
			IncProc("Lendo extrato cielo...")
			
			cLinha := FT_FREADLN()
			
			_TpReg := SubStr(cLinha,1,1)
			
			Do Case
			
				Case _TpReg == '0' // Header
					_aHeader := {}
					_aHeader := BuscaHeader(_aHeader, cLinha)
				
				Case _TpReg == '1' // Detalhe do resumo de operações RO
					_aRO := {}
					_aRO := BuscaRO(_aRO, cLinha)
				
				Case _TpReg == '2' //Detalhe do comprovante de venda CV
					_aCV := {}
					_aCV := BuscaCV(_aCV, cLinha)
					
					// No registro 2 gravo os valores num registro do ZB1
					GravaZB1(_aHeader, _aRO, _aCV, _aRel )
					
			EndCase
			
			FT_FSKIP()
		EndDo
		
		FT_FUSE()
	
		// imprime relatório
		If len(_aRel) > 0
			RelImportacao(_aRel)
		EndIf
		ApMsgInfo("Importação dos registros concluída com sucesso!","[ZB1_IMP] - SUCESSO")
	EndIf
	u_logFim ("Inicio Importação Cielo " + DTOS(date()) )
Return
//
// --------------------------------------------------------------------------
// Carrega header do arquivo
Static Function BuscaHeader(_aHeader, cLinha)

	_sDtPro := STOD(SubStr(cLinha,12,8))
	_dDtIni := STOD(SubStr(cLinha,20,8))
	_dDtFin := STOD(SubStr(cLinha,28,8))
	_sNSeq  := SubStr(cLinha,36,7)
	
	aadd (_aHeader,{ _sDtPro ,; // 1
					 _dDtIni ,; // 2
					 _dDtFin ,; // 3
					 _sNSeq	 }) // 4

Return _aHeader
//
// --------------------------------------------------------------------------
// Carrega registro 1 - RO do arquivo
Static Function BuscaRO(_aRO, cLinha)

	_sEstab   := SubStr(cLinha,  2, 10)
	_sFilial  := BuscaFilial(_sEstab)
	_sTpTran  := SubStr(cLinha, 24,  2) 
	_ano 	  := '20' + SubStr(cLinha, 26, 2)
	_mesdia   := SubStr(cLinha, 28, 4)
	_dDtApre  := STOD(_ano +_mesdia)
	_ano 	  := '20' + SubStr(cLinha, 38, 2)
	_mesdia   := SubStr(cLinha, 40, 4)
	_dDtEnv   := STOD(_ano +_mesdia)
	_nVlrBrt  := val(SubStr(cLinha, 45,  13))/100
	_nVlrTax  := val(SubStr(cLinha, 59,  13))/100
	_nVlrRej  := val(SubStr(cLinha, 73,  13))/100
	_nVlrLiq  := val(SubStr(cLinha, 87,  13))/100
	_sBanco   := SubStr(cLinha,100,  4)
	_sAgencia := SubStr(cLinha,104,  5)
	_sConta   := SubStr(cLinha,109, 14)
	_sStaPgto := SubStr(cLinha,123,  2)
	_sAdm	  := SubStr(cLinha,185,  3)
	_sAdmDes  := BuscaBandeira(_sAdm)
	_sNumRO   := SubStr(cLinha,188, 22)
	_nPerTax  := Val(SubStr(cLinha,210, 4))/100
	_nVlrTar  := Val(SubStr(cLinha,214, 5))/100	
	
	aadd (_aRO,{ 	_sFilial	,; // 1
					_sEstab  	,; // 2
					_sTpTran 	,; // 3
					_dDtApre 	,; // 4	
					_dDtEnv		,; // 5
					_nVlrBrt	,; // 6
					_nVlrTax	,; // 7
					_nVlrRej	,; // 8
					_nVlrLiq	,; // 9
					_sBanco		,; // 10
					_sAgencia	,; // 11
					_sConta     ,; // 12
					_sStaPgto	,; // 13
					_sAdm		,; // 14
					_sAdmDes	,; // 15
					_sNumRO		,; // 16
					_nPerTax	,; // 17
					_nVlrTar	}) // 18
	
Return _aRO
//
// --------------------------------------------------------------------------
// Carrega registro 2 - CV do arquivo
Static Function BuscaCV(_aCV, cLinha)

	_sCartao := SubStr(cLinha, 19,19)
	_dDtVen  := STOD(SubStr(cLinha, 38, 8))
	_nVlrPar := val(SubStr(cLinha, 47,  13))/100
	_sParNum := SubStr(cLinha, 60, 2)
	_sParTot := SubStr(cLinha, 62, 2)
	_sMotRej := SubStr(cLinha, 64, 3)
	_sDesRej := BuscaRejeicao(_sMotRej)
	_sAutCod := SubStr(cLinha, 67, 6)
	_sTID	 := SubStr(cLinha, 73,20)
	_sNSUCod := SubStr(cLinha, 93, 6)
	_sNumNFe := SubStr(cLinha,140, 9)
	_sIDTran := SubStr(cLinha,189,29)
	_sSinal  := SubStr(cLinha,46,1)
	If _sSinal == '+'
		_sStaImp := 'I'
	Else
		_sStaImp := 'D'
	EndIf
	
	aadd (_aCV,{_sCartao ,; // 1
				_dDtVen	 ,; // 2
				_nVlrPar ,; // 3
				_sParNum ,; // 4
				_sParTot ,; // 5
				_sMotRej ,; // 6
				_sDesRej ,; // 7
				_sAutCod ,; // 8
				_sTID	 ,; // 9
				_sNSUCod ,; // 10
				_sNumNFe ,; // 11
				_sIDTran ,; // 12
				_sStaImp ,; // 13
				_sSinal })  // 14
				
Return _aCV
//
// --------------------------------------------------------------------------
// Grava ZB1
Static Function GravaZB1(_aHeader, _aRO, _aCV, _aRel )
	Begin Transaction
		
		sAut	 := alltrim(_aCV[1,8])
		sNSU	 := alltrim(_aCV[1,10])
		sSinal	 := alltrim(_aCV[1,14])
		sDtPro   := DTOS(_aHeader[1,1])
		sBanco   := Buscabanco(_aRO[1,2],'B')
		sAgencia := Buscabanco(_aRO[1,2],'A')
		sConta   := Buscabanco(_aRO[1,2],'C')
		
		dbSelectArea("ZB1")
		dbSetOrder(4) // ZB1_NUMNSU + ZB1_CODAUT + DTA PROCESSAMENTO
		dbGoTop()
		
		If !dbSeek(sDtPro + PADR(sNSU ,8,' ') +sAut + sSinal)
		
			Reclock("ZB1",.T.)
				ZB1->ZB1_FILIAL := _aRO[1,1]
				ZB1->ZB1_CODEST := _aRO[1,2]
				ZB1->ZB1_DTAPRO := _aHeader[1,1] 
				ZB1->ZB1_DTAINI := _aHeader[1,2] 
				ZB1->ZB1_DTAFIN := _aHeader[1,3] 
				ZB1->ZB1_NUMSEQ := _aHeader[1,4] 
				ZB1->ZB1_TPTRAN := _aRO[1,3]
				ZB1->ZB1_DTAAPR := _aRO[1,4]
				ZB1->ZB1_DTAENV := _aRO[1,5]
				ZB1->ZB1_VLRBRT := _aRO[1,6] 
				ZB1->ZB1_VLRTAX := _aRO[1,7]
				ZB1->ZB1_VLRREJ := _aRO[1,8]
				ZB1->ZB1_VLRLIQ := _aRO[1,9]
				ZB1->ZB1_BANCO  := sBanco	//_aRO[1,10] 
				ZB1->ZB1_AGENCI := sAgencia //_aRO[1,11] 
				ZB1->ZB1_CONTA  := sConta   //_aRO[1,12]
				ZB1->ZB1_STAPGT := _aRO[1,13]
				ZB1->ZB1_ADM	:= _aRO[1,14]
				ZB1->ZB1_ADMDES := _aRO[1,15] 
				ZB1->ZB1_NUMRO  := _aRO[1,16]  
				ZB1->ZB1_PERTAX := _aRO[1,17]  
				ZB1->ZB1_VLRTAR := _aRO[1,18]  
				ZB1->ZB1_CARTAO := _aCV[1,1] 
				ZB1->ZB1_DTAVEN := _aCV[1,2]  
				ZB1->ZB1_VLRPAR := _aCV[1,3]  
				ZB1->ZB1_PARNUM := _aCV[1,4]  
				ZB1->ZB1_PARTOT := _aCV[1,5]  
				ZB1->ZB1_MOTREJ := _aCV[1,6]  
				ZB1->ZB1_DESREJ := _aCV[1,7] 
				ZB1->ZB1_AUTCOD := _aCV[1,8]  
				ZB1->ZB1_TID	:= _aCV[1,9]  
				ZB1->ZB1_NSUCOD := _aCV[1,10]  
				ZB1->ZB1_NUMNFE := _aCV[1,11]  
				ZB1->ZB1_IDTRAN := _aCV[1,12]  
				ZB1->ZB1_STAIMP := _aCV[1,13] 	
				ZB1->ZB1_SINAL  := _aCV[1,14] 	
				ZB1->ZB1_ARQUIV := alltrim(mv_par02)	
			ZB1->(MsUnlock())

			_vlrTaxa := ROUND((_aCV[1,3] * _aRO[1,17])/100,2)
			aadd(_aRel,{ 	_aRO[1,1],; 	// filial
							_aRO[1,9],; 	// valor liquido da venda
							_aCV[1,3],; 	// valor da parcela
							_aRO[1,17],; 	// % taxa
							_vlrTaxa ,;     // valor da taxa
							_aCV[1,2],; 	// data de venda
							_aHeader[1,1],; // data do processamento
							_aCV[1,8] ,; 	// autorização
							_aCV[1,10],; 	// NSU
							'INCLUIDO',;    // status
							_aCV[1,4] ,;	// parcela
							_aCV[1,13],;    // status letra
							_aCV[1,14] })   // sinal

			u_log("Registro Importado! NSU:" + sNSU +" Autorização:"+ sAut)

			// se é um registro de debito procurar registro de credito e fechar
			If alltrim(_aCV[1,14]) == '-'
				If dbSeek(sDtPro + PADR(sNSU ,8,' ') +sAut + '+')
					Reclock("ZB1",.F.)
						ZB1->ZB1_STAIMP := 'F'
					ZB1->(MsUnlock())
				EndIf
			EndIf
		Else

			_vlrTaxa := ROUND((_aCV[1,3] * _aRO[1,17])/100,2)
			aadd(_aRel,{ 	_aRO[1,1],; 	// filial
							_aRO[1,9],; 	// valor liquido da venda
							_aCV[1,3],; 	// valor da parcela
							_aRO[1,17],; 	// % taxa
							_vlrTaxa ,;     // valor da taxa
							_aCV[1,2],; 	// data de venda
							_aHeader[1,1],; // data do processamento
							_aCV[1,8] ,; 	// autorização
							_aCV[1,10],; 	// NSU
							'JÁ IMPORTADO',;// status
							_aCV[1,4]  ,;	// parcela
							_aCV[1,13],;    // status letra
							_aCV[1,14] })   // sinal

			u_log("Registro já importado! NSU:" + sNSU +" Autorização:"+ sAut)
		EndIf

	End Transaction
Return _aRel
//
// --------------------------------------------------------------------------
// Busca filial pela empresa do arquivo
Static Function BuscaFilial(_sEmpresa)
	local sFilial := ""
	
	Do Case
		Case alltrim(_sEmpresa) == '1032432176'
			sFilial := '10'
			
		Case alltrim(_sEmpresa) == '2778224593'
			sFilial := '01'
			
	EndCase
	
Return sFilial
//
// --------------------------------------------------------------------------
// Busca filial pela empresa do arquivo
Static Function Buscabanco(_sEmpresa,_sTipo)
	local _sRet := ""
	
	Do Case
		Case alltrim(_sEmpresa) == '1032432176'
			Do Case 
				Case _sTipo == 'B' // banco
					_sRet := '041'
				Case _sTipo == 'A' // agencia
					_sRet := '0568'
				Case _sTipo == 'C' // conta
					_sRet := '0606136809'
			EndCase

		Case alltrim(_sEmpresa) == '2778224593'
			Do Case 
				Case _sTipo == 'B' // banco
					_sRet := '001'
				Case _sTipo == 'A' // agencia
					_sRet := '3412'
				Case _sTipo == 'C' // conta
					_sRet := '32972'
			EndCase
			
	EndCase
	
Return _sRet
//
// --------------------------------------------------------------------------
// Busca Bandeira
Static Function BuscaBandeira(_sAdm)

	Do Case
		Case alltrim(_sAdm)== '001'
			_sAdmDes := 'Visa'
		Case alltrim(_sAdm)== '002'
			_sAdmDes := 'Mastercard'
		Case alltrim(_sAdm)== '003'
			_sAdmDes := 'Amex'
		Case alltrim(_sAdm)== '006'
			_sAdmDes := 'Sorocred'
		Case alltrim(_sAdm)== '007'
			_sAdmDes := 'Elo'
		Case alltrim(_sAdm)== '009'
			_sAdmDes := 'Diners'
		Case alltrim(_sAdm)== '011'
			_sAdmDes := 'Agiplan'
		Case alltrim(_sAdm)== '015'
			_sAdmDes := 'Banescard'
		Case alltrim(_sAdm)== '023'
			_sAdmDes := 'Cabal'
		Case alltrim(_sAdm)== '029'
			_sAdmDes := 'Credsystem'
		Case alltrim(_sAdm)== '035'
			_sAdmDes := 'Esplanada'
		Case alltrim(_sAdm)== '040'
			_sAdmDes := 'Hipercard'
		Case alltrim(_sAdm)== '060'
			_sAdmDes := 'Jcb'
		Case alltrim(_sAdm)== '064'
			_sAdmDes := 'Credz'
		Case alltrim(_sAdm)== '072'
			_sAdmDes := 'Hiper'
		Case alltrim(_sAdm)== '075'
			_sAdmDes := 'Ourocard'
	
	EndCase

Return _sAdmDes
//
// --------------------------------------------------------------------------
// Busca Rejeição
Static Function BuscaRejeicao(_sMotRej)
	Do case
		Case alltrim(_sMotRej) == ''
			_sDesRej := ''
		Case alltrim(_sMotRej) == '002'
			_sDesRej := 'Cartão inválido'
		Case alltrim(_sMotRej) == '023'
			_sDesRej := 'Outros erros'
		Case alltrim(_sMotRej) == '024'
			_sDesRej := 'Tipo cartão inválido'
		Case alltrim(_sMotRej) == '031'
			_sDesRej := 'Saque com cartão Electron valor zerado'
		Case alltrim(_sMotRej) == '039'
			_sDesRej := 'Banco emissor inválido'
		Case alltrim(_sMotRej) == '044'
			_sDesRej := 'Data da transação inválida'
		Case alltrim(_sMotRej) == '045'
			_sDesRej := 'Código de autorização inválido'
		Case alltrim(_sMotRej) == '055'
			_sDesRej := 'Número de parcelas inválido'
		Case alltrim(_sMotRej) == '056'
			_sDesRej := 'Trans.financiada p/estabelecimento não autorizado'
		Case alltrim(_sMotRej) == '057'
			_sDesRej := 'Cartão em boletim protetor'
		Case alltrim(_sMotRej) == '061'
			_sDesRej := 'Número de cartão inválido'
		Case alltrim(_sMotRej) == '073'
			_sDesRej := 'Transação inválida'
		Case alltrim(_sMotRej) == '074'
			_sDesRej := 'Valor de transação inválido'
		Case alltrim(_sMotRej) == '075'
			_sDesRej := 'Número de cartão inválido'
		Case alltrim(_sMotRej) == '081'
			_sDesRej := 'Cartão vencido'
		Case alltrim(_sMotRej) == '092'
			_sDesRej := 'Banco emissor sem comunicação'
		Case alltrim(_sMotRej) == '093'
			_sDesRej := 'Desbalanceamento no plano parcelado'
		Case alltrim(_sMotRej) == '094'
			_sDesRej := 'Venda parcelada p/cartão emitido no exterior'
		Case alltrim(_sMotRej) == '097'
			_sDesRej := 'Valor de parcela menor do que o permitido'
		Case alltrim(_sMotRej) == '099'
			_sDesRej := 'Banco emissor inválido'
		Case alltrim(_sMotRej) == '101' .or. alltrim(_sMotRej) == '102'
			_sDesRej := 'Transação duplicada'
		Case alltrim(_sMotRej) == '124'
			_sDesRej := 'BIN não cadastrado'
		Case alltrim(_sMotRej) == '126' .or. alltrim(_sMotRej) == '128' .or. alltrim(_sMotRej) == '129' .or. alltrim(_sMotRej) == '130' .or. alltrim(_sMotRej) == '133' .or. alltrim(_sMotRej) == '134'
			_sDesRej := 'Saque com cartão Electron inválida'
		Case alltrim(_sMotRej) == '140'
			_sDesRej := 'Estabelecimento não e-commerce'
		Case alltrim(_sMotRej) == '141'
			_sDesRej := 'Cartão travel transação inválida'
		Case alltrim(_sMotRej) == '143'
			_sDesRej := 'Venda em dólar inválido'
		Case alltrim(_sMotRej) == '145'
			_sDesRej := 'Estabelecimento inválido para distribuição'
		Case alltrim(_sMotRej) == '147'
			_sDesRej := 'Parcelado emissor não habilitado'
		Case alltrim(_sMotRej) == '150'
			_sDesRej := 'Estabelecimento não financeiro'
		Otherwise
			_sDesRej := 'Transação não autorizada'
	
	EndCase

Return _sDesRej
//
// --------------------------------------------------------------------------
// Relatorio de registros importados
Static Function RelImportacao(_aRel)
	Private oReport
	//Private cPerg   := "VA_RELPORT"
	
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

	oReport := TReport():New("ZB1_IMP","Importação de pagamentos Cielo",cPerg,{|oReport| PrintReport(oReport)},"Importação de pagamentos Cielo")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Parcela"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"%.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Dt.Venda"		,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Dt.Proces."	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"Status"		,	    					,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"Cre/Deb"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	//TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	, , "Total parcela ", "@E 999,999,999.99", NIL, .F., .T.)
	//TRFunction():New(oSection1:Cell("COLUNA7")	,,"SUM"	, , "Total taxa "   , "@E 999,999,999.99", NIL, .F., .T.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	Local i          := 0
	Local _nTotVenda := 0
	Local _nTotTax   := 0
	Local _nTotDVenda:= 0
	Local _nTotDTax  := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	For i:=1 to Len(_aRel)

		_sParc := ''
		If alltrim(_aRel[i, 11]) <> '00' .or. alltrim(_aRel[i, 11]) <> '' 
			_sParc := BuscaParcela(_aRel[i, 11])
		EndIf
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
		If alltrim(_aRel[i, 1]) <> '01'
			_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aRel[i,8] + "'" // Loja salva cod.aut no campo NSU
			_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aRel[i,6]) + "'"
		Else
			_oSQL:_sQuery += " AND SE1.E1_CARTAUT = '" + _aRel[i,8] + "'"
			_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aRel[i,9] + "'"
		EndIf
		If alltrim(_sParc) <> ''
			_oSQL:_sQuery += " AND SE1.E1_PARCELA   = '" + _sParc + "'"
		EndIf
			_oSQL:_sQuery += " AND SE1.E1_TIPO IN ('CC','CD')"
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

		If _aRel[i,13] == '+'
			_sCreDeb := 'Crédito'
		Else
			_sCreDeb := 'Débito'
		EndIf
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aRel[i,1] }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo   }) // titulo
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sCliente  }) // cliente
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aRel[i,2] }) // vlr. liquido
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aRel[i,3] }) // vlr.parcela
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aRel[i,4] }) // % taxa
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aRel[i,5] }) // vlr. taxa
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aRel[i,6] }) // dt. venda
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aRel[i,7] }) // dt. process
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aRel[i,8] }) // cod.autoriz
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aRel[i,9] }) // NSU
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aRel[i,10]}) // status
		oSection1:Cell("COLUNA13")	:SetBlock   ({|| _sCreDeb  }) // status
		
		If alltrim(_aRel[i,12]) == 'I'
			_nTotVenda += _aRel[i,3]
			_nTotTax   += _aRel[i,5] 
		Else
			If alltrim(_aRel[i,12]) == 'D'
				_nTotDVenda += _aRel[i,3]
				_nTotDTax   += _aRel[i,5] 
			EndIf
		EndIf
		oSection1:PrintLine()
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL CREDITO EM CONTA:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVenda, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)

	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL DEBITO EM CONTA:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotDVenda, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotDTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)
	oReport:ThinLine()

	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL GERAL" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVenda - _nTotDVenda , "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotTax - _nTotDTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)
	oReport:ThinLine()

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Pular folha na impressão
Static Function _PulaFolha(_nLinha)
	local _nRet := 0

	If  _nLinha > 2300
		oReport:EndPage()
		oReport:StartPage()
		_nRet := oReport:Row()
	Else
		_nRet := _nLinha
	EndIf
Return _nRet
// --------------------------------------------------------------------------
// Busca Parcelas
Static Function BuscaParcela(_sParcela)
	Local _sParc := ''

	Do Case
		Case alltrim(_sParcela) == '01'
			_sParc:= 'A'
		Case alltrim(_sParcela) == '02'
			_sParc:= 'B'
		Case alltrim(_sParcela) == '03'
			_sParc:= 'C'
		Case alltrim(_sParcela) == '04'
			_sParc:= 'D'
		Case alltrim(_sParcela) == '05'
			_sParc:= 'E'
		Case alltrim(_sParcela) == '06'
			_sParc:= 'F'
		Case alltrim(_sParcela) == '07'
			_sParc:= 'G'
		Case alltrim(_sParcela) == '08'
			_sParc:= 'H'
		Case alltrim(_sParcela) == '09'
			_sParc:= 'I'
		Case alltrim(_sParcela) == '10'
			_sParc:= 'J'
		Case alltrim(_sParcela) == '11'
			_sParc:= 'K'
		Case alltrim(_sParcela) == '12'
			_sParc:= 'L'
		Otherwise
			_sParc:=''
	EndCase
Return _sParc
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
