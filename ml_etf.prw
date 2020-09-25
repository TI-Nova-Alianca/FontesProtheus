//  Programa...: ML_ETF
//  Autor......: Alexandre Dalpiaz
//  Data.......: 29/04/04
//  Cliente....: Alianca
//  Descricao..: Impressao de etiquetas de volumes por nota fiscal (impressora termica)
//
// Historico de alteracoes:
// 21/07/2004 - Robert  - Busca dados de fornecedor quando NF tipo B ou D
// 01/06/2009 - Robert  - Desabilitado uso do indice 10 do SD2
//                      - Ajustada funcao ValidPerg para versao 10
// 15/10/2010 - Fabiano - Criada opcao de impressora matricial.
// 07/06/2011 - Robert  - Novas tentativas de deixar a impressao posicionada para a proxima etiqueta.
// 06/09/2012 - Elaine  - Alteracao na rotina _ValidPerg para tratar o tamanho do campo
//                        da NF com a funcao TamSX3 (ref mudancas do tamanho do campo da NF de 6 p/9 posicoes) 
// 10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 -  Parametro em looping
//
//------------------------------------------------------------------------------------------------------------

#Include "rwmake.ch"

User Function ML_ETF()
	local _nI:=0
	
	LI:=0
	tamanho  :="P"
	limite   :=80
	titulo   :="Nota Fiscal - Alianca"
	cDesc1   :="Este programa ira emitir a Nota Fiscal de Entrada/Saida"
	cDesc2   :=""
	cDesc3   :=""
	cNatureza:=""
	aReturn  := { "Especial", 1,"Administracao", 1, 2, 1,"",1 }
	nomeprog :="nfiscal"
	cPerg    :="ML_ETF"
	nLastKey := 0
	lContinua:= .T.
	nLin     :=0
	wnrel    := "ML_ETF"
	_wDESC1  := 0
	
	// Tamanho do Formulario de Nota Fiscal (em Linhas)          
	//nTamNf:=72     // Apenas Informativo

	// Verifica as perguntas selecionadas, busca o padrao da Nfiscal           
	_ValidPerg ()
	
	If ! Pergunte(cPerg,.T.)               // Pergunta no SX1
		Return
	EndIf
	
	If mv_par07 == 2
		setprc (0, 0)
		li = 0
		@ li, 0 psay chr (255)
		@ li, 0 psay avalimp (80)
	Endif

	cString:="SF2"
	
	//Identifica tipo de impressao 1= grafica
	If mv_par07 == 1
	
		//Objetos para tamanho e tipo das fontes
		oBookman10 := TFont():New("Bookman Old Style",,12,,.T.,,,,,.F.)
		oArial08   := TFont():New("Arial",,10,,.f.,,,,,.F.)
		oArial10   := TFont():New("Arial",,14,,.f.,,,,,.F.)
		oArial10N  := TFont():New("Arial",,18,,.T.,,,,,.F.)
		
		oPrn:=TAVPrinter():New("Etiquetas de Volumes")
		oPrn:Setup()           // Impressora Padrão
		oPrn:SetPortrait()     // ou SetLanscape()
	Else
		wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F.,, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
		If nLastKey == 27
			Return
		Endif
		
		delete file (__reldir + wnrel + ".##r")
		SetDefault (aReturn, cString)
		If nLastKey == 27
			Return
		Endif
	Endif
	
	DbSelectArea('SF2')
	If !(FunName() $ '#ML_NFA')
		DbSeek(xFilial('SF2') + mv_par01 + mv_par02,.t.)
		If EOF()
			MsgBox('Nota fiscal nao localizada','ATENCAO!!!','STOP')
		EndIf
	EndIf
	
	// Se for NF de beneficiamento ou devolucao, busca cadastro do fornecedor
	If sf2 -> f2_tipo $ "BD"
		_cCliente := SF2->F2_CLIENTE + '/' + SF2->F2_LOJA + ' - ' + left(Posicione('SA2',1,xFilial('SA2') + SF2->F2_cliente + SF2->F2_LOJA,'A2_NOME'),28)
		_cEnd     := SA2->A2_END
		_cCEP     := tran(SA2->A2_CEP,'@R 99.999-999') + ' - ' + alltrim(SA2->A2_MUN) + ' - ' + SA2->A2_EST
		_cMun     := alltrim(SA2->A2_MUN) + ' - ' + SA2->A2_EST
		
	Else
		_cCliente := left(Posicione('SA1',1,xFilial('SA1') + SF2->F2_CLIENTE + SF2->F2_LOJA,'A1_NOME'),23)
		_cEnd     := SA1->A1_END
		_cCEP     := 'Cep: ' + tran(SA1->A1_CEP,'@R 99.999-999') + ' - ' + alltrim(SA1->A1_MUN) + ' - ' + SA1->A1_EST
		_cMun     := alltrim(SA1->A1_MUN) + ' - ' + SA1->A1_EST
	Endif
	_cTransp  := LEFT(Posicione('SA4',1,xFilial('SA4') + SF2->F2_TRANSP,'A4_NOME'),30)
	
	_cWWW     := ''
	_xNota    := sf2->f2_doc
	_XQTD_PRO:=0
	
	DbSelectArea("SD2")      // Itens da NF Saida
	DbSetOrder(3)  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	If DBSeek(xFilial()+SF2->F2_DOC+ SF2->F2_SERIE,.F.)
		DbSelectArea('SC5')
		DbSetOrder(1)
		If DbSeek(xFilial('SC5') + SD2->D2_PEDIDO,.f.)
			If SC5->C5_EMISSAO >= CTOD("28/11/07")
				_XQTD_PRO := SC5->C5_VOLUME1 //+ SC5->C5_VOLUME2
			EndIf
		EndIf
	EndIf
	
	If _XQTD_PRO == 0  // NAO PEGOU VOLUME DO SC5  - VAI PEGAR DOS ITENS DA NOTA
		dbSelectArea("SD2")                   // * Itens de Venda da N.F.
		DbSetOrder(3)  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		dbSeek(xFilial()+SF2->F2_DOC+SF2->F2_SERIE)
		
		_CarTu := GETMV("ML_CARTU")
		Do While !eof() .and. SD2->D2_DOC==SF2->F2_DOC .and. SD2->D2_SERIE==SF2->F2_SERIE
			If SD2->D2_SERIE # mv_par02        // Se a Serie do Arquivo for Diferente
				DbSkip()                       // do Parametro Informado !!!
				Loop
			Endif
			
			If !ALLTRIM(SD2->D2_COD) $ _CarTu
				_XQTD_PRO  := _XQTD_PRO + SD2->D2_QUANT     // Guarda as quant. da NF
			EndIf
			DbSelectArea("SD2")
			dbskip()
		Enddo
	EndIf
	
	_netiq1 :="N"
	_netiq2 := "N"
	_netiq3 := "N"
	_XTETIQ:= 0
	_xqtvol:= 00
	
	_XQTD_PRO := _XQTD_PRO + MV_PAR03 // SOMA OS VOLUMES ADICIONAIS INFOMADO NO PARAMETRO
	If MV_PAR04 > 0   // PARA IMPRESSAO DE ETIQUETAS AVULSAS, NESTE CASO AS QTDES DO PEDIDO E SUBSTITUIDA
		_XQTD_PRO := MV_PAR04
	EndIf
	
	If mv_par05  > 0
		_xqtvol := mv_par05
		_xqtd_pro := mv_par06
		If MV_PAR05 > 1
			_XQTVOL := _xQTVOL -1
		EndIF
	EndIf
	
	_xnetiq := _xqtd_pro
	If mv_par05 > 0
		_xnetiq := mv_par04
	EndIf

	If _XQTD_PRO > 0
		For _nI := 1 to iif(_xnetiq == 0, 1, _xnetiq)
			_xqtvol:= _xqtvol+1
			_cNota    := 'NF: ' + _xnota +  ' VOL: ' + alltrim(str(_xqtvol)) + '/' + alltrim(str(iif(_XQTD_PRO == 0, 1, _XQTD_PRO)))
			If _XTETIQ = 8
				
				If mv_par07 == 1
				oPrn:EndPage()       // Finaliza a página
				Endif
				
				_XTETIQ = 0
			EndIf
			If _XTETIQ = 0
				
				If mv_par07 == 1
					oPrn:StartPage()       // Inicia uma Nova Página
					LI:= 200
				Endif			
				
				_XTETIQ :=1
			EndIf
			
			Do Case
				Case  _netiq1 == "N"
					_xicol:= 85
					_netiq1 :="S"
				Case  _netiq2 == "N"
					_xicol:= 870
					If mv_par07 == 1
						li:= li-450
					EndIf 
					_netiq2 :="S"
				Case  _netiq3 == "N"
					_xicol:= 1650
					If mv_par07 == 1
						li:= li-450
					EndIf
					_netiq1 :="N"
					_netiq2 := "N"
					_netiq3 := "N"
					_XTETIQ:= _XTETIQ+1
			EndCase
			
			If mv_par07 == 1 
				oPrn:Say(li , _xicol , _cCliente  , oArial10)
				li:= li+100
				oPrn:Say(li , _xicol , _cMun      , oArial10)
				li:= li+100
				oPrn:Say(li , _xicol , _cNota    , oArial10N)
				li:= li+100
				oPrn:Say(li , _xicol , _ctransp  , oArial08)
				li:= li+150
			Else 
			    li+=2
				@li,0 psay _cCliente
				li++ 
				@li,0 psay _cMun
				li++
				@li,0 psay _cNota
				li++    
				
				@li,0 psay _ctransp
				li+=4				
			EndIf 	
		Next
	EndIf
	
	If mv_par07 ==1
		If li == 0
			oPrn:EndPage()       // Finaliza a página
		EndIf
		oPrn:Print()       // Visualiza antes de imprimir
		oPrn:End()
	Else
		li += 4 //3
		@ li, 0 psay "."
		setprc (0, 0)
	EndIf
	
	MS_FLUSH()
	DbCommitAll ()
	If mv_par07 == 2
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	Endif	
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))
	
	//                     PERGUNT                           TIPO TAM            DEC           VALID F3     Opcoes                Help
	aadd (_aRegsPerg, {01, "Nota fiscal de                ", "C", _aTamDoc [1], _aTamDoc [2],  "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {02, "Serie                         ", "C", 3,             0,            "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {03, "Qtde vol adicionais           ", "N", 5,             0,            "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {04, "Qtde etiq avulsas             ", "N", 5,             0,            "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {05, "Vol. inicial                  ", "N", 5,             0,            "",   "   ", {},                   ""})
	aadd (_aRegsPerg, {06, "Vol. final                    ", "N", 5,             0,            "",   "   ", {},                   ""}) 
	aadd (_aRegsPerg, {07, "Impressora                    ", "N", 1,             0,            "",   "   ", {"A4", "Matricial"},  ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
