// Programa..: ML_IPI
// Autor.....: Jeferson Rech
// Data......: Dez/2000
// Nota......: Relatorio de IPI 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de IPI 
// #PalavasChave      #IPI
// #TabelasPrincipais #SF2
// #Modulos           #FAT
//
// Historico de alteracoes:
// 16/06/2008 - Robert  - Passa a validar o parametro VA_SERIECF
// 05/06/2010 - Robert  - Perguntas ajustadas para versao 10
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// --------------------------------------------------------------------------------
#include "rwmake.ch"

User Function ML_IPI()
	cString   := "SF2"
	cDesc1    := "Este Programa Tem Como Objetivo a Impressao do Relatorio de IPI"
	cDesc2    := "diario especifico para Cooperativa Agroindustrial Nova Alianca."
	cDesc3    := ""
	tamanho   := "P"
	aReturn   := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	nLastKey  := 0
	nTamanho  := IIF(aReturn[4]==1,15,18)
	titulo    := "Relatorio De IPI"
	cPerg     := "ML_IPI"
	wnrel     := "ML_IPI"
	nomeprog  := "ML_IPI"
	nTipo     := 0
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	// Envia controle para a funcao SETPRINT                        
	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	
	If nLastKey == 27
		Return
	Endif
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	
	RptStatus({|| RptDetail()})
Return
//
// ---------------------------------------------------------------------------------
// Impressão
Static Function RptDetail()
	
	// Variaveis utilizadas para Impressao do Cabecalho e Rodape    
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	
	// Cria o cabecalho.                                        
	cabec1 := "Numero CP    Serie CP      Valor Mercadoria     Valor Base IPI         Valor IPI"
	cabec2 := ""
	
	_xTOTMERC := 0
	_xTOTBASE := 0
	_xTOTIPI  := 0
	
	// Verificacao dos Dados                                    
	DbSelectArea("SF2")
	DbSetOrder(9)
	DbSeek(xFilial()+Dtos(mv_par01),.T.)
	SetRegua(RecCount())
	
	_vaSerieECF := GetMV ("VA_SERIECF")
	
	Do While !Eof() .And. xFilial()==SF2->F2_FILIAL .And. SF2->F2_EMISSAO<=mv_par01
		IncRegua()
		// Cupom Fiscal
		If ! SF2->F2_SERIE $ _vaSerieECF // GetMV ("VA_SERIECF")
			DbSelectArea("SF2")
			DbSkip()
			Loop
		Endif
		
		_xEMISSAO := SF2->F2_EMISSAO
		_xDOC     := SF2->F2_DOC
		_xSERIE   := SF2->F2_SERIE
		_xVALIPI  := SF2->F2_VALIPI
		_xBASEIPI := SF2->F2_BASEIPI
		_xVALMERC := SF2->F2_VALMERC
		
		If li>56
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		
		@ li, 000 PSAY _xDOC
		@ li, 018 PSAY _xSERIE
		@ li, 029 PSAY _xVALMERC  Picture "@E 999,999,999.99"
		@ li, 048 PSAY _xBASEIPI  Picture "@E 999,999,999.99"
		@ li, 066 PSAY _xVALIPI   Picture "@E 999,999,999.99"
		li:=li+1
		_xTOTMERC := _xTOTMERC + _xVALMERC
		_xTOTBASE := _xTOTBASE + _xBASEIPI
		_xTOTIPI  := _xTOTIPI  + _xVALIPI
		DbSelectArea("SF2")
		DbSkip()
	Enddo
	
	If _xTOTMERC > 0
		li:=li+2
		@ li, 000 PSAY "Total do dia "+Dtoc(mv_par01)+" - > "
		@ li, 029 PSAY _xTOTMERC  Picture "@E 999,999,999.99"
		@ li, 048 PSAY _xTOTBASE  Picture "@E 999,999,999.99"
		@ li, 066 PSAY _xTOTIPI   Picture "@E 999,999,999.99"
		Roda(0,"",Tamanho)
	Endif
	
	Set Device To Screen
	
	If aReturn[5] == 1
		Set Printer To
		DbCommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH()
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Data de emissao               ", "D", 8,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
