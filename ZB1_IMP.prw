// Programa...: ZB1_IMP
// Autor......: Cl�udia Lion�o
// Data.......: 21/08/2020
// Descricao..: Importa��o de extrato de recebimento Cielo - EDI 13 Cielo
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Importa��o de extrato de recebimento Cielo
// #PalavasChave      #extrato #cielo #recebimento #cartoes 
// #TabelasPrincipais #ZB1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB1_IMP()
	local i			:= 0
	Local cDir 		:= ""
	Local cArq 		:= ""
	Local cExt 		:= ""
	Local cLinha 	:= ""
	Local lContinue := .F.
	Private aErro 	:= {}

	u_logIni ("Inicio Importa��o Cielo " + DTOS(date()) )
	
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
		MsgStop("O arquivo " + cFile + " n�o foi encontrado. A importa��o ser� abortada!","[ZB1] - ATENCAO")
		Return
	EndIf
	
	// VERIFICA SE O ARQUIVO CIELO � DE REGISTROS DE PAGAMENTO 04
	FT_FUSE(cFile)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	
	While i == 0 .and. !FT_FEOF()
		cLinha := FT_FREADLN()
		_OpcExtrato := SubStr(cLinha,48,2)
		
		If _OpcExtrato <> '04' // Extrato de pagamentos
			u_help('O arquivo de extrato n�o � de pagamento! Registros n�o poder�o ser importados!')
			lContinue := .F.
		Else
			lContinue := .T.
		EndIf
		i += 1
	EndDo
	FT_FUSE()
	
	// Importa��o
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
				
				Case _TpReg == '1' // Detalhe do resumo de opera��es RO
					_aRO := {}
					_aRO := BuscaRO(_aRO, cLinha)
				
				Case _TpReg == '2' //Detalhe do comprovante de venda CV
					_aCV := {}
					_aCV := BuscaCV(_aCV, cLinha)
					
					// No registro 2 gravo os valores num registro do ZB1
					GravaZB1(_aHeader, _aRO, _aCV )
					
			EndCase
			
			FT_FSKIP()
		EndDo
		
		FT_FUSE()
	
		ApMsgInfo("Importa��o dos registros conclu�da com sucesso!","[ZB1_IMP] - SUCESSO")
	EndIf
	u_logFim ("Inicio Importa��o Cielo " + DTOS(date()) )
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
	_sStaImp := 'I'
	
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
				_sStaImp }) // 13
				
Return _aCV
//
// --------------------------------------------------------------------------
// Grava ZB1
Static Function GravaZB1(_aHeader, _aRO, _aCV )
	Begin Transaction
		
		sAut	 := alltrim(_aCV[1,8])
		sNSU	 := alltrim(_aCV[1,10])
		sBanco   := Buscabanco(_aRO[1,2],'B')
		sAgencia := Buscabanco(_aRO[1,2],'A')
		sConta   := Buscabanco(_aRO[1,2],'C')
		
		dbSelectArea("ZB1")
		dbSetOrder(1) // ZB1_NUMNSU + ZB1_CODAUT
		dbGoTop()
		
		If !dbSeek(sNSU + sAut)
		
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
				ZB1->ZB1_ARQUIV := alltrim(mv_par02)	
			ZB1->(MsUnlock())

			u_log("Registro Importado! NSU:" + sNSU +" Autoriza��o:"+ sAut)
		Else
			_Status := Posicione('ZB1',1,sNSU + sAut,'ZB1_STAIMP')
			If _Status == 'I' // DEIXA ATUALIZAR O REGISTRO APENAS SE NAO TIVER CONCILIADO
				Reclock("ZB1",.F.)
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
				ZB1->(MsUnlock())
				u_log("Registro Alterado! NSU:" + sNSU +" Autoriza��o:"+ sAut)
			EndIf
		EndIf

	End Transaction
Return
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
// Busca Rejei��o
Static Function BuscaRejeicao(_sMotRej)
	Do case
		Case alltrim(_sMotRej) == ''
			_sDesRej := ''
		Case alltrim(_sMotRej) == '002'
			_sDesRej := 'Cart�o inv�lido'
		Case alltrim(_sMotRej) == '023'
			_sDesRej := 'Outros erros'
		Case alltrim(_sMotRej) == '024'
			_sDesRej := 'Tipo cart�o inv�lido'
		Case alltrim(_sMotRej) == '031'
			_sDesRej := 'Saque com cart�o Electron valor zerado'
		Case alltrim(_sMotRej) == '039'
			_sDesRej := 'Banco emissor inv�lido'
		Case alltrim(_sMotRej) == '044'
			_sDesRej := 'Data da transa��o inv�lida'
		Case alltrim(_sMotRej) == '045'
			_sDesRej := 'C�digo de autoriza��o inv�lido'
		Case alltrim(_sMotRej) == '055'
			_sDesRej := 'N�mero de parcelas inv�lido'
		Case alltrim(_sMotRej) == '056'
			_sDesRej := 'Trans.financiada p/estabelecimento n�o autorizado'
		Case alltrim(_sMotRej) == '057'
			_sDesRej := 'Cart�o em boletim protetor'
		Case alltrim(_sMotRej) == '061'
			_sDesRej := 'N�mero de cart�o inv�lido'
		Case alltrim(_sMotRej) == '073'
			_sDesRej := 'Transa��o inv�lida'
		Case alltrim(_sMotRej) == '074'
			_sDesRej := 'Valor de transa��o inv�lido'
		Case alltrim(_sMotRej) == '075'
			_sDesRej := 'N�mero de cart�o inv�lido'
		Case alltrim(_sMotRej) == '081'
			_sDesRej := 'Cart�o vencido'
		Case alltrim(_sMotRej) == '092'
			_sDesRej := 'Banco emissor sem comunica��o'
		Case alltrim(_sMotRej) == '093'
			_sDesRej := 'Desbalanceamento no plano parcelado'
		Case alltrim(_sMotRej) == '094'
			_sDesRej := 'Venda parcelada p/cart�o emitido no exterior'
		Case alltrim(_sMotRej) == '097'
			_sDesRej := 'Valor de parcela menor do que o permitido'
		Case alltrim(_sMotRej) == '099'
			_sDesRej := 'Banco emissor inv�lido'
		Case alltrim(_sMotRej) == '101' .or. alltrim(_sMotRej) == '102'
			_sDesRej := 'Transa��o duplicada'
		Case alltrim(_sMotRej) == '124'
			_sDesRej := 'BIN n�o cadastrado'
		Case alltrim(_sMotRej) == '126' .or. alltrim(_sMotRej) == '128' .or. alltrim(_sMotRej) == '129' .or. alltrim(_sMotRej) == '130' .or. alltrim(_sMotRej) == '133' .or. alltrim(_sMotRej) == '134'
			_sDesRej := 'Saque com cart�o Electron inv�lida'
		Case alltrim(_sMotRej) == '140'
			_sDesRej := 'Estabelecimento n�o e-commerce'
		Case alltrim(_sMotRej) == '141'
			_sDesRej := 'Cart�o travel transa��o inv�lida'
		Case alltrim(_sMotRej) == '143'
			_sDesRej := 'Venda em d�lar inv�lido'
		Case alltrim(_sMotRej) == '145'
			_sDesRej := 'Estabelecimento inv�lido para distribui��o'
		Case alltrim(_sMotRej) == '147'
			_sDesRej := 'Parcelado emissor n�o habilitado'
		Case alltrim(_sMotRej) == '150'
			_sDesRej := 'Estabelecimento n�o financeiro'
		Otherwise
			_sDesRej := 'Transa��o n�o autorizada'
	
	EndCase

Return _sDesRej
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Diretorio          ", "C", 40, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Nome do arquivo    ", "C", 20, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {03, "Extens�o           ", "C",  4, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
