// Programa...: FC010CON
// Autor......: Jeferson Rech
// Data.......: 12/2005
// Descricao..: P.E. para Consultas Especificas Consulta Cliente - Posição de clientes
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para Consultas Especificas Consulta Cliente - Posição de clientes
// #PalavasChave      #consultas_especificas #posicao_de_clientes
// #TabelasPrincipais #SA1 #SF1 #SD1 
// #Modulos 		  #FAT         
//      
// Historico de alteracoes:
// 14/05/2008 - Robert  - Incluida transportadora na consulta de notas bonificadas total
//                      - Criado botao para exportar para Excel na consulta produtos X clientes.
// 04/06/2008 - Robert  - Ajustes na visualizacao de NF bonificadas
// 08/01/2014 - Leandro - Inclusão de pesquisa de histórico de NFs, conforme solicitação de Jeferson
// 02/08/2014 - Robert  - Funcoes de historico de notas migradas para fonte proprio.
// 28/10/2015 - Robert  - Eliminadas linhas comentariadas.
// 22/09/2016 - Catia   - estava dando erro quando ia visualizar notas de devolução
// 13/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - SX3
// 06/05/2021 - Claudia - retirada a chamada do programa VAHISTNF
// 27/03/2024 - Claudia - Incluido botão de titulo em aberto. GLPI: 14957
//
// --------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function FC010CON()
	Local _aArea    := GetArea()
	Local _aSaveAmb := U_SalvaAmb()   // Salva Variaveis de Ambiente
	
	pergunte("FIC010",.F.)
	_xParam1 := mv_par01
	_xParam2 := mv_par02
	
	@ 200, 100 TO 505, 440 DIALOG oDlg2 TITLE "Selecione a Consulta Especifica"

	@ 020, 055 BUTTON OemToAnsi(" _Cad. Produtos      ") SIZE 60,10 ACTION MATA010() .And. Close(oDlg2)
	@ 035, 055 BUTTON OemToAnsi(" NFs _Devolucao      ") SIZE 60,10 ACTION LPCLIDEV()
	@ 050, 055 BUTTON OemToAnsi(" NFs _Beneficiamento ") SIZE 60,10 ACTION LPCLIBEN()
	@ 065, 055 BUTTON OemToAnsi(" NFs _Bonif. Total   ") SIZE 60,10 ACTION LPCLIOUT()
	@ 080, 055 BUTTON OemToAnsi(" NFs Bonif. _Itens   ") SIZE 60,10 ACTION U_LPITBOM(SA1->A1_COD,SA1->A1_LOJA)
	@ 095, 055 BUTTON OemToAnsi("      Co_missoes     ") SIZE 60,10 ACTION Comissoes()
	@ 110, 055 BUTTON OemToAnsi(" _Produtos X Cliente ") SIZE 60,10 ACTION LPAMASA7(SA1->A1_COD,SA1->A1_LOJA,"N")
	@ 125, 055 BUTTON OemToAnsi(" NFs Loja (Varejo)   ") SIZE 60,10 ACTION U_LPNFLOJA(SA1->A1_COD,SA1->A1_LOJA)
	@ 125, 055 BUTTON OemToAnsi("  Títulos em aberto  ") SIZE 60,10 ACTION LPCLITIT(SA1->A1_COD,SA1->A1_LOJA)
	@ 140, 055 BUTTON OemToAnsi("         _Sair       ") SIZE 60,10 ACTION Close(oDlg2)
	ACTIVATE DIALOG oDlg2 CENTERED
	
	U_SalvaAmb(_aSaveAmb)   // Restaura Variaveis de Ambiente
	
	RestArea(_aArea)
Return(nil)
//
// --------------------------------------------------------------------------------------------
// Busca as Devolucoes                                          
Static Function LPCLIDEV()
	Private _zTIPO  := "D"
	Private _xDESCR := "Devolucao"
	
	U_LPCLIOPC() // Chama Funcao
Return(nil)
//
// --------------------------------------------------------------------------------------------
// Busca os Beneficiamentos                                     
Static Function LPCLIBEN()
	Private _zTIPO  := "B"
	Private _xDESCR := "Beneficiamento"
	
	U_LPCLIOPC() // Chama Funcao

Return(nil)
//
// --------------------------------------------------------------------------------------------
// Busca as Outras Notas                                        
Static Function LPCLIOUT()
	Private _xDESCR := "Outras Notas"
	
	U_LPCLIOUTX() // Chama Funcao

Return(nil)
//
// --------------------------------------------------------------------------------------------
// Busca as Devolucoes / Beneficiamentos                        
User Function LPCLIOPC()
	aHeader  := {}
	aCols    := {}
	
	// SELECIONA SF1
	_aCpoSX3 := FwSX3Util():GetAllFields('SF1')
	
	//F1_TIPO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_TIPO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	// F1_DOC
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_DOC"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	// F1_EMISSAO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_EMISSAO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf				

	// F1_VALBRUT
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_VALBRUT"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})	
	EndIf
	
	//F1_DUPL
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_DUPL"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	_xVLTOTNF  := 0
	_xQTTOTNF  := 0
	
	aAreaSF1   := SF1->(GetArea())
	
	DbSelectArea("SF1")
	Processa({|| ML_CNT1()},"Processando ...")
Return
//
// --------------------------------------------------------------------------------------------
// Busca as Devolucoes / Beneficiamentos  
Static Function ML_CNT1()
	ProcRegua(RecCount())
	
	DbSelectArea("SF1")
	DbSetOrder(2)
	DbSeek(xFilial("SF1")+SA1->A1_COD+SA1->A1_LOJA)
	Do While !Eof() .And. SF1->F1_FILIAL==xFilial("SF1") .And. SF1->F1_FORNECE+SF1->F1_LOJA == SA1->A1_COD+SA1->A1_LOJA
		If !(SF1->F1_TIPO $ _zTIPO)
			DbSkip()
			Loop
		Endif
		If SF1->F1_EMISSAO < _xParam1 .Or. SF1->F1_EMISSAO > _xParam2
			DbSkip()
			Loop
		Endif
		IncProc("Processando Documento "+SF1->F1_DOC+" "+SF1->F1_SERIE)
		
		_xTOTNF:=SF1->F1_VALMERC+SF1->F1_FRETE+SF1->F1_VALIPI+SF1->F1_DESPESA-SF1->F1_DESCONT
		If SF1->F1_TIPO == "N"
			_xTipo := "NF Normal"
		ElseIf SF1->F1_TIPO == "P"
			_xTipo := "NF de Compl. IPI"
		ElseIf SF1->F1_TIPO == "I"
			_xTipo := "NF de Compl. ICMS"
		ElseIf SF1->F1_TIPO == "P"
			_xTipo := "NF de Compl. IPI"
		ElseIf SF1->F1_TIPO == "C"
			_xTipo := "NF de Compl. Preco/Frete"
		ElseIf SF1->F1_TIPO == "B"
			_xTipo := "NF de Beneficiamento"
		ElseIf SF1->F1_TIPO == "D"
			_xTipo := "NF de Devolucao"
		Else
			_xTipo := ""
		Endif
		
		aAdd ( aCols , { _xTipo          ,;
		SF1->F1_DOC     ,;
		SF1->F1_EMISSAO ,;
		_xTOTNF         ,;
		SF1->F1_DUPL    ,;
		Recno() })
		_xVLTOTNF += _xTOTNF
		_xQTTOTNF += 1
		DbSelectArea("SF1")
		DbSkip()
	Enddo

	RestArea(aAreaSF1)
	
	FinalOpc()

Return(.T.)
//
// --------------------------------------------------------------------------------------------
// Apresenta Tela de MultiLine (Entradas SF1)                   
Static Function FinalOpc()
	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 400,610 DIALOG oDlg1 TITLE "Consulta Notas Fiscais de "+_xDESCR
		@ 10,10 TO 160,290 MULTILINE FREEZE 1 object _oDlg1
		@ 165,010 SAY "Qtd Notas -> "
		@ 165,070 GET _xQTTOTNF   When .F.   Picture "@E 999,999"       SIZE 40,11
		@ 165,120 SAY "Total "+_xDESCR+" -> "
		@ 165,180 GET _xVLTOTNF   When .F.   Picture "@E 99,999,999.99" SIZE 80,11
		@ 185,030 BUTTON "_Pesquisa"  SIZE 50,10 ACTION GdSeek(_oDlg1,OemtoAnsi("Pesquisa"))
		@ 185,105 BUTTON "_Visualiza" SIZE 50,10 ACTION LpVisuaNFE()
		@ 185,180 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
	Endif
Return
//
// --------------------------------------------------------------------------------------------
// Apresenta Visualizacao da NF de Entrada                      
Static Function LpVisuaNFE()
	Local _xRecno      := aCols[n,6]
	Local aArea        := GetArea()
	Local aAreaSD1     := SD1->(GetArea())
	Local aAreaSF1     := SF1->(GetArea())
	Local aRotAnt      := aClone(aRotina)   // Armazena conteudo da aRotina
	
	DbSelectArea("SF1")
	dbgoto(_xRecno)
	A103NFiscal ("SF1", _xRecno, 2)
	
	aRotina := aClone(aRotAnt)
	RestArea(aAreaSD1)
	RestArea(aAreaSF1)
	RestArea(aArea)
Return
//
// --------------------------------------------------------------------------------------------
// Busca as Outras Notas Fiscais                                
User Function LPCLIOUTX()
	aHeader  := {}
	aCols    := {}
	
	_aCpoSX3 := FwSX3Util():GetAllFields('SF1')
	// F1_TIPO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_TIPO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf
	// F1_DOC
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_DOC"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf
	// F1_SERIE
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_SERIE"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf
	//F1_EMISSAO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_EMISSAO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."									,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf
	//F1_VALBRUT
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F1_VALBRUT"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf
	// NATUREZA
	AADD(aHeader, { "Natureza" , "XXX","",                     50, 0,"","","C","" } )
	
	_aCpoSX3 := FwSX3Util():GetAllFields('SF2')
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "F2_TRANSP"})
	
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf 
	// A4_NOME
	_aCpoSX3 := FwSX3Util():GetAllFields('SA4')
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A4_NOME"})
	
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})
	EndIf 
	// RECNO
	AADD(aHeader, {"R_E_C_N_O_" ,"R_E_C_N_O_","",10,0,".T.","","N","SF2","V"} )
	
	_xVLTOTNF  := 0
	_xQTTOTNF  := 0
	aAreaSF2   := SF2->(GetArea())
	aAreaSD2   := SD2->(GetArea())
	
	DbSelectArea("SF2")
	Processa({|| ML_CNT0()},"Processando ...")
Return
//
// --------------------------------------------------------------------------------------------
// Busca as Outras Notas Fiscais     
Static Function ML_CNT0()
	ProcRegua(RecCount())
	
	DbSelectArea("SF2")
	DbSetOrder(2)
	DbSeek(xFilial("SF2")+SA1->A1_COD+SA1->A1_LOJA)
	Do While !Eof() .And. SF2->F2_FILIAL==xFilial("SF2") .And. SF2->F2_CLIENTE+SF2->F2_LOJA == SA1->A1_COD+SA1->A1_LOJA
		If SF2->F2_VALFAT > 0.00
			DbSkip()
			Loop
		Endif
		If SF2->F2_TIPO $ "D/B"
			DbSkip()
			Loop
		Endif
		If SF2->F2_EMISSAO < _xParam1 .Or. SF2->F2_EMISSAO > _xParam2
			DbSkip()
			Loop
		Endif
		IncProc("Processando Documento "+SF2->F2_DOC+" "+SF2->F2_SERIE)
		
		_lTemSo1 := .T.
		_xCHAV   := SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial("SF2")+_xCHAV)
		_xCF     := SD2->D2_CF
		Do While !Eof() .And. SD2->D2_FILIAL==xFilial("SD2") .And. SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA == _xCHAV
			If _xCF <> SD2->D2_CF
				_lTemSo1 := .F.
			Endif
			DbSelectArea("SD2")
			DbSkip()
		Enddo
		
		If _lTemSo1
			_xNATUREZ := Posicione("SX5", 1, xFilial("SX5")+"13"+_xCF, "X5_DESCRI")
		Else
			_xNATUREZ := "DIVERSOS"
		Endif
		
		DbSelectArea("SF2")
		_xTOTNF := SF2->F2_VALMERC+SF2->F2_VALIPI+SF2->F2_SEGURO+SF2->F2_FRETE+SF2->F2_DESPESA
		
		If SF2->F2_TIPO == "N"
			_xTipo := "NF Normal"
		ElseIf SF2->F2_TIPO == "P"
			_xTipo := "NF de Compl. IPI"
		ElseIf SF2->F2_TIPO == "I"
			_xTipo := "NF de Compl. ICMS"
		ElseIf SF2->F2_TIPO == "P"
			_xTipo := "NF de Compl. IPI"
		ElseIf SF2->F2_TIPO == "C"
			_xTipo := "NF de Compl. Preco/Frete"
		ElseIf SF2->F2_TIPO == "B"
			_xTipo := "NF de Beneficiamento"
		ElseIf SF2->F2_TIPO == "D"
			_xTipo := "NF de Devolucao"
		Else
			_xTipo := ""
		Endif
		aAdd ( aCols , { _xTipo          ,;
		SF2->F2_DOC     ,;
		SF2->F2_SERIE   ,;
		SF2->F2_EMISSAO ,;
		_xTOTNF         ,;
		_xNATUREZ       ,;
		SF2->F2_transp ,;
		fBuscaCpo ("SA4", 1, xfilial ("SA4") + SF2->F2_transp, "A4_NOME") ,;
		Recno()  })
		_xVLTOTNF  += _xTOTNF
		_xQTTOTNF  += 1
		
		DbSelectArea("SF2")
		DbSkip()
	Enddo

	RestArea(aAreaSF2)
	RestArea(aAreaSD2)
	
	FinalOpcOut()

Return(.T.)
//
// --------------------------------------------------------------------------------------------
// Apresenta Tela de MultiLine (Saidas   SF2)                   
Static Function FinalOpcOut()
	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 400,610 DIALOG oDlg1 TITLE "Consulta Notas Fiscais de "+_xDESCR
		@ 10,10 TO 160,290 MULTILINE FREEZE 1 object _oDlg1
		@ 165,010 SAY "Qtd Notas -> "
		@ 165,070 GET _xQTTOTNF   When .F.   Picture "@E 999,999"       SIZE 40,11
		@ 165,120 SAY "Total "+_xDESCR+" -> "
		@ 165,180 GET _xVLTOTNF   When .F.   Picture "@E 99,999,999.99" SIZE 80,11
		@ 185,030 BUTTON "_Pesquisa"  SIZE 50,10 ACTION GdSeek(_oDlg1,OemtoAnsi("Pesquisa"))
		@ 185,105 BUTTON "_Visualiza" SIZE 50,10 ACTION LpVisuaNFS()
		@ 185,180 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
	Endif
Return
//
// --------------------------------------------------------------------------------------------
// Apresenta Visualizacao da NF de Saida                        
Static Function LpVisuaNFS()
	Local _xRecno      := GDFieldGet ("R_E_C_N_O_") //aCols[n,7]
	Local aArea        := GetArea()
	Local aAreaSD2     := SD2->(GetArea())
	Local aAreaSF2     := SF2->(GetArea())
	Local aRotAnt      := aClone(aRotina)   // Armazena conteudo da aRotina
	
	DbSelectArea("SF2")
	DbGoTo(_xRecno)
	MC090Visual("SF2",Recno(),2)
	
	aRotina := aClone(aRotAnt)
	RestArea(aAreaSD2)
	RestArea(aAreaSF2)
	RestArea(aArea)
Return
//
// --------------------------------------------------------------------------------------------
// Busca as Amarracoes Produtos X Clientes                      
Static Function LPAMASA7(_xCLIENTE,_xLOJA,_xTIPO)
	Local aArea        := GetArea()
	
	U__Cons_SA7(_xCLIENTE,_xLOJA,_xTIPO)
	
	RestArea(aArea)
Return(nil)
//
// --------------------------------------------------------------------------------------------
// Funcao que retorna a Amarracao Produto X Cliente             
User Function _Cons_SA7(_xCLIENTE,_xLOJA,_xTIPO)
	Private _aArea    := GetArea()
	Private _aAreaSA1 := SA1->(GetArea())
	Private _aAreaSA7 := SA7->(GetArea())
	Private _aAreaSX3 := SX3->(GetArea())
	Private _aAreaSB1 := SB1->(GetArea())
	Private _lInclui  := IIf(Type("Inclui")<>"U",Inclui,.F.)
	
	// Pedido de Venda
	If Alltrim(FunName()) == "MATA410" .And. _lInclui
		_xCLIENTE := IIf(Type("M->C5_CLIENTE")<>"U",M->C5_CLIENTE,SC5->C5_CLIENTE)
		_xLOJA    := IIf(Type("M->C5_LOJACLI")<>"U",M->C5_LOJACLI,SC5->C5_LOJACLI)
		_xTIPO    := IIf(Type("M->C5_TIPO")<>"U",M->C5_TIPO,SC5->C5_TIPO)
		// Orcamento de Venda
	ElseIf Alltrim(FunName()) == "MATA415" .And. _lInclui
		_xCLIENTE := IIf(Type("M->CJ_CLIENTE")<>"U",M->CJ_CLIENTE,SCJ->CJ_CLIENTE)
		_xLOJA    := IIf(Type("M->CJ_LOJA")<>"U",M->CJ_LOJA,SCJ->CJ_LOJA)
		_xTIPO    := "N"
	Endif
	
	If Empty(_xCLIENTE+_xLOJA)
		Return
	Endif
	
	If _xTIPO $ "B/D"
		Return
	Endif
	
	Private _aRotIni  := If(Type("aRotina")=="U",{},aClone(aRotina))    // Armazena conteudo
	Private _aHeaIni  := If(Type("aHeader")=="U",{},aClone(aHeader))    // Armazena conteudo
	Private _aColIni  := If(Type("aCols")=="U"  ,{},aClone(aCols))      // Armazena conteudo
	Private _aTelIni  := If(Type("aTela")=="U"  ,{},aClone(aTela))      // Armazena conteudo
	Private _aGetIni  := If(Type("aGets")=="U"  ,{},aClone(aGets))      // Armazena conteudo
	Private _cCadIni  := iif (type ('cCadastro')!="U", cCadastro, "")   // Armazena conteudo
	Private _xN       := If(Type("N")=="U",1,N)                         // Armazena conteudo
	Private n         := 1
	Private aHeader   := {}
	Private aCols     := {}

	// SELECIONA SA7
	_aCpoSX3 := FwSX3Util():GetAllFields('SA7')
	
	//A7_PRODUTO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRODUTO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	// SELECIONA SB1
	_aCpoSX3 := FwSX3Util():GetAllFields('SB1')
	
	//B1_DESC
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "B1_DESC"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	// SELECIONA SA7
	_aCpoSX3 := FwSX3Util():GetAllFields('SA7')
	
	//A7_PRECO12
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO12"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_DTREF12
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF12"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_PRECO11
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO11"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_DTREF11
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF11"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_PRECO10
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO10"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_DTREF10
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF10"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_PRECO09
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO09"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_DTREF09
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF09"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//A7_PRECO08
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO08"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF08
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF08"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO07
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO07"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF07
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF07"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO06
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO06"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF06
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF06"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO05
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO05"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF05
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF05"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO04
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO04"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF04
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF04"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO03
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO03"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF03
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF03"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO02
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO02"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF02
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF02"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_PRECO01
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_PRECO01"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf
	
	//A7_DTREF01
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "A7_DTREF01"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf

	DbSelectArea("SA7")
	Processa({|| ML_CNTX(_xCLIENTE,_xLOJA)},"Processando ...")
	
Return
//
// --------------------------------------------------------------------------------------------
// Funcao que retorna a Amarracao Produto X Cliente   
Static Function ML_CNTX(_xCLIENTE,_xLOJA)
	ProcRegua(RecCount())
	
	_xNOMECLI := FBuscaCpo("SA1", 1, xFilial("SA1")+_xCLIENTE+_xLOJA , "A1_NOME")
	
	DbSelectArea("SA7")
	DbSetOrder(1)
	DbSeek(xFilial("SA7")+_xCLIENTE+_xLOJA)
	Do While !Eof() .And. SA7->A7_FILIAL==xFilial("SA7") .And. SA7->A7_CLIENTE+SA7->A7_LOJA == _xCLIENTE+_xLOJA
		IncProc("Processando ...")
		
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSeek(xFilial("SB1")+SA7->A7_PRODUTO)
		
		aAdd ( aCols , { SA7->A7_PRODUTO        ,;
		SB1->B1_DESC    ,;
		SA7->A7_PRECO12 ,;
		SA7->A7_DTREF12 ,;
		SA7->A7_PRECO11 ,;
		SA7->A7_DTREF11 ,;
		SA7->A7_PRECO10 ,;
		SA7->A7_DTREF10 ,;
		SA7->A7_PRECO09 ,;
		SA7->A7_DTREF09 ,;
		SA7->A7_PRECO08 ,;
		SA7->A7_DTREF08 ,;
		SA7->A7_PRECO07 ,;
		SA7->A7_DTREF07 ,;
		SA7->A7_PRECO06 ,;
		SA7->A7_DTREF06 ,;
		SA7->A7_PRECO05 ,;
		SA7->A7_DTREF05 ,;
		SA7->A7_PRECO04 ,;
		SA7->A7_DTREF04 ,;
		SA7->A7_PRECO03 ,;
		SA7->A7_DTREF03 ,;
		SA7->A7_PRECO02 ,;
		SA7->A7_DTREF02 ,;
		SA7->A7_PRECO01 ,;
		SA7->A7_DTREF01 })
		
		DbSelectArea("SA7")
		DbSkip()
	Enddo

	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 460,680 DIALOG oDlgx TITLE "Amarracao Cliente X Produto: "+_xNOMECLI
		@ 10,10 TO 200,320 MULTILINE FREEZE 1 object _oDlg1
		@ 205,10  BUTTON "_Excel"     SIZE 50,10 ACTION U_AColsXLS ()
		@ 205,130 BUTTON "_Pesquisa"  SIZE 50,10 ACTION GdSeek(_oDlg1,OemtoAnsi("Pesquisa"))
		@ 205,220 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlgx)
		ACTIVATE DIALOG oDlgx CENTERED
	Endif

	n         := _xN                    // Retorna conteudo
	cCadastro := _cCadIni               // Retorna conteudo
	aCols     := aClone(_aColIni)       // Retorna conteudo
	aHeader   := aClone(_aHeaIni)       // Retorna conteudo
	aRotina   := aClone(_aRotIni)       // Retorna conteudo
	aTela     := aClone(_aTelIni)       // Retorna conteudo
	aGets     := aClone(_aGetIni)       // Retorna conteudo
	RestArea(_aAreaSB1)
	RestArea(_aAreaSX3)
	RestArea(_aAreaSA7)
	RestArea(_aAreaSA1)
	RestArea(_aArea)
Return(.T.)
//
// --------------------------------------------------------------------------------------------
// Funcao que Processa as Comissoes                              
Static Function Comissoes()

	Private _aArea    := GetArea()
	Private _aAreaSA1 := SA1->(GetArea())
	Private _aAreaSE3 := SE3->(GetArea())
	Private _aAreaSX3 := SX3->(GetArea())
	Private _aAreaSF2 := SF2->(GetArea())
	Private _aAreaSD2 := SD2->(GetArea())
	
	Private _aRotIni  := If(Type("aRotina")=="U",{},aClone(aRotina))    // Armazena conteudo
	Private _aHeaIni  := If(Type("aHeader")=="U",{},aClone(aHeader))    // Armazena conteudo
	Private _aColIni  := If(Type("aCols")=="U"  ,{},aClone(aCols))      // Armazena conteudo
	Private _aTelIni  := If(Type("aTela")=="U"  ,{},aClone(aTela))      // Armazena conteudo
	Private _aGetIni  := If(Type("aGets")=="U"  ,{},aClone(aGets))      // Armazena conteudo
	Private _cCadIni  := cCadastro                                      // Armazena conteudo
	Private _xN       := If(Type("N")=="U",1,N)                         // Armazena conteudo
	Private n         := 1
	Private aHeader   := {}
	Private aCols     := {}
	
	// SELECIONA SE3
	_aCpoSX3 := FwSX3Util():GetAllFields('SE3')
	
	//E3_VEND
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_VEND"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_NUM
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_NUM"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_PREFIXO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_PREFIXO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_TIPO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_TIPO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_PARCELA
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_PARCELA"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_EMISSAO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_EMISSAO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_BASE
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_BASE"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_PORC
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_PORC"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_COMIS
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_COMIS"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf	
	
	//E3_PEDIDO
	_nPos := Ascan(_aCpoSX3,{|xCpo| Alltrim(xCpo) == "E3_PEDIDO"})
	If _nPos > 0
		Aadd (aHeader, {GetSx3Cache(_aCpoSX3[_nPos], 'X3_TITULO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CAMPO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_PICTURE')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TAMANHO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_DECIMAL')	,;
						".T."										,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_USADO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_TIPO')		,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_ARQUIVO')	,;
						GetSx3Cache(_aCpoSX3[_nPos], 'X3_CONTEXT')	})			
	EndIf

	DbSelectArea("SE3")
	Processa({|| ML_CNTY()},"Processando ...")
Return
//
// --------------------------------------------------------------------------------------------
// Funcao que Processa as Comissoes    
Static Function ML_CNTY()
	ProcRegua(RecCount())
	
	_xCHAV    := SA1->A1_COD+SA1->A1_LOJA
	_xNOMECLI := SA1->A1_NOME
	DbSelectArea("SE3")
	DbSetOrder(4)
	DbSeek(xFilial()+_xCHAV)
	Do While !Eof() .And. SE3->E3_FILIAL==xFilial("SE3") .And. SE3->E3_CODCLI+SE3->E3_LOJA <= _xCHAV
		IncProc("Processando ...")
		aAux := {SE3->E3_VEND,SE3->E3_NUM,SE3->E3_PREFIXO,SE3->E3_TIPO,SE3->E3_PARCELA,SE3->E3_EMISSAO,SE3->E3_BASE,SE3->E3_PORC,SE3->E3_COMIS,SE3->E3_PEDIDO,.F.}
		aAdd(aCols,aAux)
		DbSelectArea("SE3")
		DbSkip()
	Enddo
	
	DbSelectArea("SF2")
	DbSetOrder(2)
	DbSeek(xFilial("SF2")+Soma1(_xCHAV),.T.)
	If Bof()
		_xNOTAF2 := ""
	Else
		If Eof()
			DbGoBottom()
		Else
			DbSkip(-1)
		EndIf
		If SF2->F2_CLIENTE+SF2->F2_LOJA <> _xCHAV
			_xNOTAF2 := ""
		Else
			DbSelectArea("SF2")
			Do While .T.
				If SF2->F2_CLIENTE+SF2->F2_LOJA <> _xCHAV
					_xNOTAF2 := ""
					Exit
				Endif
				If !Empty(SF2->F2_DUPL)
					_xNOTAF2 := SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA
					Exit
				Endif
				DbSelectArea("SF2")
				DbSkip(-1)
			Enddo
		EndIf
	Endif
	_xULCOMIS := 0
	If !Empty(_xNOTAF2)
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSeek(xFilial()+_xNOTAF2)
		Do While !Eof() .And. SD2->D2_FILIAL==xFilial("SD2") .And. SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA <= _xNOTAF2
			_xULCOMIS := SD2->D2_COMIS1
			Exit
			DbSelectArea("SD2")
			DbSkip()
		Enddo
	Endif
	
	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 400,610 DIALOG oDlg1 TITLE OemToAnsi("Comissoes do Cliente :  ")+Left(_xCHAV,6)+SubStr(_xCHAV,7,2)+" - "+_xNOMECLI
		@ 10,10 TO 160,290 MULTILINE FREEZE 1
		@ 165,120 SAY "% Ultima Comissao :  "
		@ 165,180 GET _xULCOMIS   When .F.   Picture "@E 99,999,999.99" SIZE 80,11
		@ 185,180 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
	Endif
	
	n         := _xN                    // Retorna conteudo
	cCadastro := _cCadIni               // Retorna conteudo
	aCols     := aClone(_aColIni)       // Retorna conteudo
	aHeader   := aClone(_aHeaIni)       // Retorna conteudo
	aRotina   := aClone(_aRotIni)       // Retorna conteudo
	aTela     := aClone(_aTelIni)       // Retorna conteudo
	aGets     := aClone(_aGetIni)       // Retorna conteudo
	RestArea(_aAreaSD2)
	RestArea(_aAreaSF2)
	RestArea(_aAreaSX3)
	RestArea(_aAreaSE3)
	RestArea(_aAreaSA1)
	RestArea(_aArea)
Return(.T.)
// --------------------------------------------------------------------------------------------
// Funcao que Processa os Itens Bonificados                      
User Function LPITBOM(_xCLIENTE,_xLOJA)
	Local nX		:= 0
	Local i         := 0
	Local _aArea    := GetArea()
	Local _aAreaSD2 := SD2->(GetArea())
	Local _aAreaSF4 := SF4->(GetArea())
	Local _aAreaSX3 := SX3->(GetArea())
	
	Private _aRotIni  := If(Type("aRotina")=="U",{},aClone(aRotina))    // Armazena conteudo
	Private _aHeaIni  := If(Type("aHeader")=="U",{},aClone(aHeader))    // Armazena conteudo
	Private _aColIni  := If(Type("aCols")=="U"  ,{},aClone(aCols))      // Armazena conteudo
	Private _aTelIni  := If(Type("aTela")=="U"  ,{},aClone(aTela))      // Armazena conteudo
	Private _aGetIni  := If(Type("aGets")=="U"  ,{},aClone(aGets))      // Armazena conteudo
	Private _cCadIni  := If(Type("cCadastro")=="U","",cCadastro)        // Armazena conteudo
	Private _xN       := If(Type("N")=="U",1,N)                         // Armazena conteudo
	Private n         := 1
	Private aHeader   := {}
	Private aCols     := {}
	Private nUsado    := 0
	Private _xVLTOTNF  := 0
	Private _xQTTOTNF  := 0

	_aCampos := {}
	_aCpoSX3 := FwSX3Util():GetAllFields('SD2')
	
	For i := 1 To Len(_aCpoSX3)
		If  GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO') == "SD2" .and. X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL') .and. GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT') <> "V"
				nUsado++
				Aadd (aHeader, {GetSx3Cache(_aCpoSX3[i], 'X3_TITULO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_PICTURE')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TAMANHO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_DECIMAL')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_VALID')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_USADO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TIPO')		,;
								GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT')	})							
			EndIf
	Next i   
	
	// Montando aCols                                               
	DbSelectArea("SD2")
	ProcRegua(RecCount())
	xChv    := (xFilial("SD2")+_xCLIENTE+_xLOJA)
	xChvAte := (xFilial("SD2")+_xCLIENTE+_xLOJA)
	DbSetOrder(9)
	DbSeek(xChv)
	Do While !Eof() .And. SD2->D2_FILIAL+SD2->D2_CLIENTE+SD2->D2_LOJA <= xChvAte
		If (SD2->D2_TIPO $ "B/D")
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		If SD2->D2_EMISSAO < _xParam1 .Or. SD2->D2_EMISSAO > _xParam2
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		_xDUPLIC  := FBuscaCpo("SF4", 1, xFilial("SF4")+SD2->D2_TES  , "F4_DUPLIC")
		// Nao Gerar Duplicata Sai Fora
		If _xDUPLIC == "S"
			DbSelectArea("SD2")
			DbSkip()
			Loop
		Endif
		IncProc("Processando Documento "+SD2->D2_DOC+" "+SD2->D2_SERIE)
		AADD(aCols,Array(nUsado+1))
		DbSelectArea("SD2")
		For nX := 1 To nUsado
			If ( aHeader[nX,10] !=  "V" )
				aCols[Len(aCols)][nX] := FieldGet(FieldPos(aHeader[nX,2]))
			Else
				aCols[Len(aCols)][nX] := CriaVar(aHeader[nX,2],.T.)
			EndIf
		Next nX
		aCols[Len(aCols)][nUsado+1] := .F.
		_xTOTNF   := SD2->D2_TOTAL+SD2->D2_VALIPI+SD2->D2_SEGURO+SD2->D2_DESPESA
		_xVLTOTNF += _xTOTNF
		_xQTTOTNF += 1
		DbSelectArea("SD2")
		DbSkip()
	Enddo
	DbSeek(xChv)

	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 400,610 DIALOG oDlg1 TITLE OemToAnsi("Itens Bonificados")
		@ 10,10 TO 160,290 MULTILINE FREEZE 1 object _oDlgx
		@ 165,010 SAY "Qtd Itens -> "
		@ 165,070 GET _xQTTOTNF   When .F.   Picture "@E 999,999"       SIZE 40,11
		@ 165,120 SAY "Total     -> "
		@ 165,180 GET _xVLTOTNF   When .F.   Picture "@E 99,999,999.99" SIZE 80,11
		@ 185,110 BUTTON "_Pesquisa"  SIZE 50,10 ACTION GdSeek(_oDlgx,OemtoAnsi("Pesquisa"))
		@ 185,180 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
	Endif

	n         := _xN                    // Retorna conteudo
	cCadastro := _cCadIni               // Retorna conteudo
	aCols     := aClone(_aColIni)       // Retorna conteudo
	aHeader   := aClone(_aHeaIni)       // Retorna conteudo
	aRotina   := aClone(_aRotIni)       // Retorna conteudo
	aTela     := aClone(_aTelIni)       // Retorna conteudo
	aGets     := aClone(_aGetIni)       // Retorna conteudo
	RestArea(_aAreaSX3)
	RestArea(_aAreaSF4)
	RestArea(_aAreaSD2)
	RestArea(_aArea)
Return(.T.)
// --------------------------------------------------------------------------------------------
// Funcao que Processa as NFs da Loja (sigaloja)                 
User Function LPNFLOJA(_xCLIENTE,_xLOJA)
	Local nX		:= 0
	Local i         := 0
	Local _aArea    := GetArea()
	Local _aAreaSF2 := SF2->(GetArea())
	Local _aAreaSX3 := SX3->(GetArea())
	
	Private _aRotIni  := If(Type("aRotina")=="U",{},aClone(aRotina))    // Armazena conteudo
	Private _aHeaIni  := If(Type("aHeader")=="U",{},aClone(aHeader))    // Armazena conteudo
	Private _aColIni  := If(Type("aCols")=="U"  ,{},aClone(aCols))      // Armazena conteudo
	Private _aTelIni  := If(Type("aTela")=="U"  ,{},aClone(aTela))      // Armazena conteudo
	Private _aGetIni  := If(Type("aGets")=="U"  ,{},aClone(aGets))      // Armazena conteudo
	Private _cCadIni  := If(Type("cCadastro")=="U","",cCadastro)        // Armazena conteudo
	Private _xN       := If(Type("N")=="U",1,N)                         // Armazena conteudo
	Private n         := 1
	Private aHeader   := {}
	Private aCols     := {}
	Private nUsado    := 0
	Private _xVLTOTNF  := 0
	Private _xQTTOTNF  := 0

	_aCampos := {}
	_aCpoSX3 := FwSX3Util():GetAllFields('SF2')
	
	For i := 1 To Len(_aCpoSX3)
		If  GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO') == "SF2" .and. X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. cNivel >= GetSx3Cache(_aCpoSX3[i], 'X3_NIVEL') .and. GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT') <> "V"
				nUsado++
				Aadd (aHeader, {GetSx3Cache(_aCpoSX3[i], 'X3_TITULO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_PICTURE')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TAMANHO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_DECIMAL')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_VALID')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_USADO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TIPO')		,;
								GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_CONTEXT')	})							
			EndIf
	Next i   

	// Montando aCols                                               
	DbSelectArea("SF2")
	ProcRegua(RecCount())
	xChv    := (xFilial("SF2")+_xCLIENTE+_xLOJA)
	xChvAte := (xFilial("SF2")+_xCLIENTE+_xLOJA)
	DbSetOrder(2)
	DbSeek(xChv)
	Do While !Eof() .And. SF2->F2_FILIAL+SF2->F2_CLIENTE+SF2->F2_LOJA <= xChvAte
		If (SF2->F2_TIPO $ "B/D")
			DbSelectArea("SF2")
			DbSkip()
			Loop
		Endif
		If SF2->F2_EMISSAO < _xParam1 .Or. SF2->F2_EMISSAO > _xParam2
			DbSelectArea("SF2")
			DbSkip()
			Loop
		Endif
		// So quero as NFs da Loja ... por enquanto so achei essa diferenciacao... hehehe
		If (Empty(SF2->F2_BANCO) .And. Empty(SF2->F2_TPFRETE))
			DbSelectArea("SF2")
			DbSkip()
			Loop
		Endif
		IncProc("Processando Documento "+SF2->F2_DOC+" "+SF2->F2_SERIE)
		AADD(aCols,Array(nUsado+1))
		DbSelectArea("SF2")
		For nX := 1 To nUsado
			If ( aHeader[nX,10] !=  "V" )
				aCols[Len(aCols)][nX] := FieldGet(FieldPos(aHeader[nX,2]))
			Else
				aCols[Len(aCols)][nX] := CriaVar(aHeader[nX,2],.T.)
			EndIf
		Next nX
		aCols[Len(aCols)][nUsado+1] := .F.
		_xTOTNF   := SF2->F2_VALMERC+SF2->F2_VALIPI+SF2->F2_SEGURO+SF2->F2_FRETE+SF2->F2_DESPESA
		_xVLTOTNF += _xTOTNF
		_xQTTOTNF += 1
		DbSelectArea("SF2")
		DbSkip()
	Enddo
	DbSeek(xChv)

	If Len(aCols) == 0
		MsgAlert("Nao existe movimentacao p/ selecao efetuada","Aviso!")
	Else
		@ 000,015 TO 400,610 DIALOG oDlg1 TITLE OemToAnsi("NFs da Loja (Sigaloja)")
		@ 10,10 TO 160,290 MULTILINE FREEZE 1 object _oDlgx
		@ 165,010 SAY "Qtd Notas -> "
		@ 165,070 GET _xQTTOTNF   When .F.   Picture "@E 999,999"       SIZE 40,11
		@ 165,120 SAY "Total     -> "
		@ 165,180 GET _xVLTOTNF   When .F.   Picture "@E 99,999,999.99" SIZE 80,11
		@ 185,110 BUTTON "_Pesquisa"  SIZE 50,10 ACTION GdSeek(_oDlgx,OemtoAnsi("Pesquisa"))
		@ 185,180 BUTTON "_Finaliza"  SIZE 50,10 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
	Endif

	n         := _xN                    // Retorna conteudo
	cCadastro := _cCadIni               // Retorna conteudo
	aCols     := aClone(_aColIni)       // Retorna conteudo
	aHeader   := aClone(_aHeaIni)       // Retorna conteudo
	aRotina   := aClone(_aRotIni)       // Retorna conteudo
	aTela     := aClone(_aTelIni)       // Retorna conteudo
	aGets     := aClone(_aGetIni)       // Retorna conteudo
	RestArea(_aAreaSX3)
	RestArea(_aAreaSF2)
	RestArea(_aArea)
Return(.T.)
//
// --------------------------------------------------------------------------------------------
// Titulos em aberto do cliente      
Static Function LPCLITIT(_sCliente, _sLoja)
	cPerg   := "VA_040BRAP"
	_ValidPerg ()

	if pergunte (cPerg, .T.)
		Processa({|| _IMPTIT(_sCliente, _sLoja)},"Processando ...")
	endif
Return
//
// --------------------------------------------------------------------------
// Titulos em aberto do cliente   
Static Function _IMPTIT(_sCliente, _sLoja)
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   E1_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,E1_NUM AS TITULO "
	_oSQL:_sQuery += "    ,E1_PARCELA AS PARCELA "
	_oSQL:_sQuery += "    ,E1_TIPO AS TIPO"
	_oSQL:_sQuery += "    ,E1_CLIENTE AS CLIENTE"
	_oSQL:_sQuery += "    ,E1_LOJA AS LOJA"
	_oSQL:_sQuery += "    ,E1_NOMCLI AS NOME "
	_oSQL:_sQuery += "    ,E1_EMISSAO AS DT_EMISSAO "
	_oSQL:_sQuery += "    ,E1_VENCTO AS DT_VENC"
	_oSQL:_sQuery += "    ,E1_VENCREA AS DT_VENCREAL"
	_oSQL:_sQuery += "    ,E1_VALOR AS VALOR "
	_oSQL:_sQuery += "    ,E1_SALDO AS SALDO "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_CLIENTE   = '"+ _sCliente +"' "
	_oSQL:_sQuery += " AND E1_LOJA      = '"+ _sLoja    +"' "
	_oSQL:_sQuery += " AND E1_PREFIXO   = '10' "
	_oSQL:_sQuery += " AND E1_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02) +"' "
	_oSQL:_sQuery += " AND E1_VENCREA BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
	_oSQL:_sQuery += " AND E1_STATUS = 'A' "
	_oSQL:ArqDestXLS = 'LPCLITIT'
	_oSQL:Log()
	_oSQL:Qry2Xls(.F., .F., .F.)
Return
//
// --------------------------------------------------------------------------
// Perguntas
static function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
	aadd (_aRegsPerg, {01, "Dt.Emissão de     ", "D",  8 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {02, "Dt.Emissão até    ", "D",  8 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {03, "Dt.Vencimento de  ", "D",  8 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {04, "Dt.Vencimento até ", "D",  8 , 0,  "",  "   ", {},                         				""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
