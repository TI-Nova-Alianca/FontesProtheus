// Programa:   PETRS006
// Autor:      Robert Koch
// Data:       20/07/2022
// Descricao:  Ponto de entrada no importador de XML da Totvs RS.
//             Permite manipulacao dos dados de cabecalho e linha para execauto.
//             Criado inicialmente para gravacao de eventos e logs

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Ponto de entrada no importador de XML da Totvs RS. Permite manipulacao dos dados de cabecalho e linha para execauto.
// #PalavasChave      #ponto_entrada #importador_XML
// #TabelasPrincipais #SD1 #SF1
// #Modulos           #COM #EST

// Historico de alteracoes:
// 28/11/2022 - Claudia - Acrescentada a gravação do campo F1_VAFLAG. GLPI: 12841
//
// -------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "RwMake.ch"

User Function PETRS006()
	Local _aTRS006   := PARAMIXB
	Local _aCabec    := _aTRS006[3]
	Local _aLinha    := _aTRS006[4]
	Local _lManut    := _aTRS006[5]
	Local _lEscrit   := _aTRS006[6]
	local _aRet      := {}
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()

	// Grava flag de identificação
	AADD(_aCabec, {"F1_VAFLAG"	,'P',Nil})

	// Deve sempre retornar cabecalho e itens.
	_aRet := {_aCabec,_aLinha}

	U_Log2 ('debug', '[' + procname () + ']Olha eu aqui...')

	// Grava alguns eventos e logs.
	_Logs (_aCabec, _lManut, _lEscrit)

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
Return _aRet
//
// --------------------------------------------------------------------------
// Gravação de logs
static function _Logs (_aCabec, _lManut, _lEscrit)
	local _oEvento   := NIL
	local _sChvNFe   := ''
	local _nPosChave := 0

	// Extrai a chave
	_nPosChave := ascan (_aCabec, {|_aVal| alltrim (upper (_aVal [1])) == 'F1_CHVNFE'})

	if _nPosChave > 0
		_sChvNFe = _aCabec [_nPosChave, 2]
		U_Log2 ('debug', '[' + procname () + ']chave: ' + _sChvNFe)

		// Grava evento temporario para rastreio de eventuais chaves perdidas
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "ZBE001"
		_oEvento:Texto     = "Processando (a nivel de item) a chave NFE, com _lManut = " + cvaltochar (_lManut) + " e _lEscrit = " + cvaltochar (_lEscrit)  // Este P.E. eh executado para cada item da nota
		_oEvento:ChaveNFe  = _sChvNFe
		_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
		_oEvento:GravaNovo ()
	endif
return

/*	Abaixo codigo que recebi como exemplo. Robert, 20/07/2022
User Function PETRS006()
	Local aRet	    := {}
	Local aArea		:= GetArea()
	Local _aTRS006	:= PARAMIXB
	Local _aCabec	:= _aTRS006[3]
	Local _aLinha	:= _aTRS006[4]
	Local lManut	:= _aTRS006[5]
	Local lEscrit	:= _aTRS006[6]
	Local nPosQtd	:= 0
	Local nPosQtSeg := 0
	Local nPosProd 	:= 0
	// 	Local cLog 		:= ''
	Local nN 		:= 1
	// Local nPosForn	:= aScan(_aCabec,{|x| x[1] == "F1_FORNECE"})
	// Local nPosLoja	:= aScan(_aCabec,{|x| x[1] == "F1_LOJA"})

	ConOut('PETRS006')
	// Alimenta o Log
	// For nN := 1 To Len(_aCabec)
	// cLog += cValToChar(_aCabec[nN, 1]) +  ': ' + cValToChar(_aCabec[nN, 2]) + ' | '
	// Next

	If aScan(_aLinha,{|x| x[1] == "D1_QUANT"}) > 0 
		nPosQtd	:= aScan(_aLinha,{|x| x[1] == "D1_QUANT"})
	EndIf

	If aScan(_aLinha,{|x| x[1] == "D1_QTSEGUM"}) > 0 
		nPosQtSeg := aScan(_aLinha,{|x| x[1] == "D1_QTSEGUM"})
	EndIf

	If aScan(_aLinha,{|x| x[1] == "D1_COD"}) > 0 
		nPosProd := aScan(_aLinha,{|x| x[1] == "D1_COD"})
	EndIf

	// Alert(xFilial('SB1') + PadR(_aLinha[nPosProd, 2], TamSX3('B1_COD')[1]))
	SB1->(dbSetOrder(1))
	If SB1->(MsSeek(xFilial('SB1') + PadR(_aLinha[nPosProd, 2], TamSX3('B1_COD')[1])))
		// cLog := ''
		// Alert('Found')
		If nPosQtSeg > 0
			If SB1->B1_TIPCONV == 'M'
				AADD(aLinha, {"D1_QUANT", _aLinha[nPosQtSeg, 2] / SB1->B1_CONV, Nil})
			Else
				AADD(aLinha, {"D1_QUANT", _aLinha[nPosQtSeg, 2] * SB1->B1_CONV, Nil})
			EndIf
		Else
			If SB1->B1_TIPCONV == 'M'
				AADD(aLinha, {"D1_QTSEGUM", _aLinha[nPosQtd, 2] * SB1->B1_CONV, Nil})
			Else
				AADD(aLinha, {"D1_QTSEGUM", _aLinha[nPosQtd, 2] / SB1->B1_CONV, Nil})
			EndIf
		EndIf

		AADD(_aLinha, {"D1_UM"		,SB1->B1_UM 	,Nil})
		If !Empty(AllTrim(SB1->B1_SEGUM))
			AADD(_aLinha, {"D1_SEGUM"	,SB1->B1_SEGUM 	,Nil})
		EndIf

		AADD(_aLinha, {"D1_TDESCPR"	,SB1->B1_DESC 	,Nil})
		If lEscrit
			AADD(_aLinha, {"D1_DESCRI"	,_aTRS006[1] 	,Nil}) // PRENTISS
		Else
			AADD(_aLinha, {"D1_DESCRI"	,SB1->B1_DESC 	,Nil}) // FARINA - PRENTISS
		EndIf
		AADD(_aLinha, {"D1_XDESCRI"	,SB1->B1_DESC 	,Nil}) // HDA
		AADD(_aLinha, {"D1_RDESCR "	,SB1->B1_DESC 	,Nil}) // RUGERI

		If lManut 
			AADD(_aLinha, {"D1_ZDESCRI"	,_aTRS006[1] 	,Nil}) // NUTRITEC	
		Else
			AADD(_aLinha, {"D1_ZDESCRI"	,SB1->B1_DESC 	,Nil}) // NUTRITEC	
		EndIf	
		AADD(_aLinha, {"D1_CONTA"	,SB1->B1_CONTA 	,Nil})
		AADD(_aLinha, {"D1_SNCM"	,SB1->B1_POSIPI	,Nil})
		AADD(_aLinha, {"D1_CC"		,SB1->B1_CC 	,Nil})
		AADD(_aLinha, {"D1_LOCAL"	,SB1->B1_LOCPAD ,Nil})
		AADD(_aLinha, {"D1_ITEMCTA"	,"" 			,Nil})

		// cLog += 'Encontrou SB1'
	Else
		// cLog += 'Não encontrou SB1'
	EndIf

//	SB6->(dbSetOrder(1))
//	If (SB6->(MsSeek(xFilial('SB6') + PadR(_aLinha[nPosProd, 2], TamSX3('B1_COD')[1]) + PadR(_acabec[nPosForn, 2], TamSX3('B6_CLIFOR')[1]) + PadR(_acabec[nPosLoja, 2], TamSX3('B6_LOJA')[1]))))
//	SF4->(dbSetOrder(1))
//	If SF4->(MsSeek(xFilial('SF4') + SB6->B6_TES))
//	AADD(_aLinha, {"D1_TES", SF4->F4_TESDV, Nil})	 	
//	EndIf
//	EndIf

	aRet := {_aCabec,_aLinha}
Return aRet
*/
