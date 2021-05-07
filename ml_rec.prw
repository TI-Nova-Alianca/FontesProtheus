//  Programa...: ML_REC
//  Autor......: Eleandro Casagrande
//  Data.......: 02/2001
//  Descricao..: Relatorio de Titulos Receber/Recebidos (em aberto, pagos)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de Titulos Receber/Recebidos (em aberto, pagos)
// #PalavasChave      #titulos_a_receber #titulos_recebidos
// #TabelasPrincipais #SE1 
// #Modulos   		  #FIN
//
// Historico de alteracoes:
// 05/06/2010 - Robert - Perguntas ajustadas para versao 10
// 06/05/2021 - Claudia - Incluido tags de customizações
// 
// ------------------------------------------------------------------

#include "rwmake.ch"

User Function ml_rec()
	cString   := "SE1"
	cDesc1    := "Este Programa Tem Como Objetivo a Impressao do Relatorio de titulos"
	cDesc2    := "receber/recebidos (em aberto, pagos)  p/ Cooperativa Alianca."
	cDesc3    := ""
	tamanho   := "M"
	aReturn := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	nLastKey  := 0
	cPerg     := "ML_REC"
	titulo    := "Relatorio Titulos Receber"
	wnrel     := "ML_REC"
	nomeprog  := "ML_REC"
	nTipo     := 0
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
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
// ---------------------------------------------------------------------------
Static Function RptDetail()
	SetRegua(LastRec())
	
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1

	cabec1 := "Prefixo   Numero    Parcela     Vencimento        Valor Titulo                  "
	cabec2 := ""
	*****                1         2         3         4         5         6         7         8
	*****      012345678901234567890123456789012345678901234567890123456789012345678901234567890
	
	_nTotal := 0
	DbSelectArea("SE1")
	DbSetOrder(7)
	DbSeek(xFilial()+Dtos(mv_par01),.T.)
	Do While !Eof() .And. xFilial()==SE1->E1_FILIAL .AND. SE1->E1_VENCREA <= mv_par02
		IncRegua()
		If li>56
			cabec(titulo,cabec1,cabec2,nomeprog,tamanho,nTipo)
		Endif
		IF SE1->E1_PREFIXO <> "S1" .And. !Empty(SE1->E1_PREFIXO) // Nota fiscal
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		@ li, 000 PSAY SE1->E1_PREFIXO
		@ li, 010 PSAY SE1->E1_NUM
		@ li, 023 PSAY SE1->E1_PARCELA
		@ li, 032 PSAY SE1->E1_VENCREA
		@ li, 050 PSAY SE1->E1_VALOR    Picture "@E 999,999,999.99"
		_nTotal := _nTotal + SE1->E1_VALOR
		li:=li+1
		DbSelectArea("SE1")
		DbSkip()
	Enddo
	li:=li+1
	@ li, 032 PSAY "** Total"
	@ li, 050 PSAY _nTotal  Picture "@E 999,999,999.99"
	If li!=0
		Roda(0,"",Tamanho)
	Endif

	DbSelectArea("SE1")
	RetIndex("SE1")
	
	li:=li+1
	@ li,000 PSAY CHR(18)
	
	SetPrc(0,0)
	
	Set Device To Screen
	
	If aReturn[5] == 1
		Set Printer To
		DbCommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH() // libera fila de relatorios em spool (Tipo Rede Netware)
return
// 
// ------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Vencimento de                 ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Vencimento ate                ", "D", 8,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
