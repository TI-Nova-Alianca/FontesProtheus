/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³  ML_SCI  ³ Autor ³     Jeferson Rech     ³ Data ³ Set/2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Geracao Arquivo Texto do SCI                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Clientes Microsiga                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±                                                        

±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//
// Historico de alteracoes:
// 05/06/2010 - Robert - Perguntas ajustadas para versao 10
// 19/09/2012 - Elaine - Ajuste tratamento titulo de 6 para 9 posicoes
//

#include "rwmake.ch"

User Function ml_sci()
	Local cCadastro := "Arquivo p/ SCI"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	
	Private cPerg   := "ML_SCI"
	_ValidPerg()
	Pergunte(cPerg,.F.)      // Pergunta no SX1
	
	AADD(aSays,"    Este programa tem como objetivo gerar o arquivo texto para o            ")
	AADD(aSays,"    o nome de SCI.TXT no diretorio \sigaadv                                 ")
	AADD(aSays,"                                                                            ")
	
	AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
	
	FormBatch( cCadastro, aSays, aButtons )
		
	If nOpca == 1
		Processa( { |lEnd| GeraTxt() } )
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para parametros                         ³
	//³ mv_par01     // Data Inicial                                 ³
	//³ mv_par02     // Data Final                                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Return(nil)
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Funcao Gera Arquivo TXT                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Static Function GeraTxt()
	
	cArq :="SCI.TXT"
	nHdl :=fCreate(cArq)
	_xFIM:=CHR(13)+CHR(10)       // Caracteres para final de linha
	If nHdl==-1
		MsgAlert("O arquivo de nome "+cArq+" nao pode ser executado! Verifique os parametros.","Atencao!")
		Return
	Endif
	
	Processa({|| ML_TXT()},"Processando "+cArq+" ...")
	Return
	Static Function ML_TXT()
	ProcRegua(RecCount())
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Processamento Header                                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cLin:=""
	DbSelectArea("SE1")
	DbSetOrder(6)
	DbSeek(xFilial("SE1")+DTOS(mv_par01),.T.)
	Do While !Eof() .And. SE1->E1_FILIAL==xFilial("SE1") .And. SE1->E1_EMISSAO <= mv_par02
		IncProc("Processando o Titulo: "+SE1->E1_PREFIXO+"-"+SE1->E1_NUM+"/"+SE1->E1_PARCELA)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Processamento Detalhe                                               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Alltrim(SE1->E1_TIPO) $ "NCC/"
			DbSelectArea("SE1")
			DbSkip()
			cLin:=""
			Loop
		Endif
		
		_xDOC   := SE1->E1_NUM
		_xSERIE := SE1->E1_PREFIXO
		DbSelectArea("SF2")      // Notas Fiscais
		DbSetOrder(1)
		DbSeek(xFilial()+_xDOC+_xSERIE)
		If !Found()
			DbSelectArea("SE1")
			DbSkip()
			cLin:=""
			Loop
		Endif
		If Left(SF2->F2_ESPECIE,2) == "CF"   // Cupom Fiscal
			DbSelectArea("SE1")
			DbSkip()
			cLin:=""
			Loop
		Endif                                                                      
		//  20120919 - Elaine Alteracao NF Alianca
		_xTITULO:="000000000"+LEFT(SE1->E1_NUM+SPACE(99),09)  // Numero do titulo  
		_xCLIENT:=SE1->E1_CLIENTE                          // Cliente
		_xLOJCLI:=SE1->E1_LOJA                             // Loja
		_xNATURE:="F"                                      // Natureza do titulo
		_xTMOEDA:="R$  "                                   // Moeda
		_xVLRTIT:=STRZERO(SE1->E1_VALOR,11)                // Valor inteiro do titulo
		_xCENTIT:=RIGHT(STR(SE1->E1_VALOR,17,2),2)         // Valor em centavos do titulo
		_xVALPAG:=STRZERO(SE1->E1_VALLIQ,11)               // Valor inteiro pago
		_xCENPAG:=RIGHT(STR(SE1->E1_VALLIQ,17,2),2)        // Valor em centavos pago
		_xDTEMIS:=DTOS(SE1->E1_EMISSAO)                    // Data da emissao
		_xDTEMIS:=SUBSTR(_xDTEMIS,7,2)+SUBSTR(_xDTEMIS,5,2)+LEFT(_xDTEMIS,4)
		_xDTVENC:=DTOS(SE1->E1_VENCREA)                    // Data do vencimento
		_xDTVENC:=SUBSTR(_xDTVENC,7,2)+SUBSTR(_xDTVENC,5,2)+LEFT(_xDTVENC,4)
		_xDTPAGO:=DTOS(SE1->E1_BAIXA)                      // Data do pagamento
		_xDTPAGO:=SUBSTR(_xDTPAGO,7,2)+SUBSTR(_xDTPAGO,5,2)+LEFT(_xDTPAGO,4)
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFILIAL("SA1")+_xCLIENT+_xLOJCLI)
			_xTIPCLI:=IIF((LEN(ALLTRIM(SA1->A1_CGC))==11),"F","J")
			_xCGCCLI:=LEFT(SA1->A1_CGC+SPACE(99),14)
			_xIDECLI:=LEFT(SA1->A1_RG+SPACE(99),20)
			_xNOMCLI:=LEFT(SA1->A1_NOME+SPACE(99),55)
			_xFANCLI:=LEFT(SA1->A1_NREDUZ+SPACE(99),55)
			_xNATCLI:=SPACE(01)
			_xENDCLI:=LEFT(SA1->A1_END+SPACE(99),70)
			_xCIDCLI:=LEFT(SA1->A1_MUN+SPACE(99),30)
			_xESTCLI:=LEFT(SA1->A1_EST+SPACE(99),02)
			_xCEPCLI:=LEFT(SA1->A1_CEP+SPACE(99),08)
			_xDTECLI:=SPACE(04)
			_xTELCLI:=SPACE(10)
			_xDFACLI:=SPACE(04)
			_xFAXCLI:=SPACE(10)
			_xEMACLI:=LEFT(SA1->A1_EMAIL+SPACE(99),50)
			_xPRCCLI:=DTOS(SA1->A1_PRICOM)
			_xPRCCLI:=SUBSTR(_xPRCCLI,5,2)+LEFT(_xPRCCLI,4)
		Else
			u_help("Cliente "+_xCLIENT+" Nao Cadastrado. Verifique !!!")
			_xTIPCLI:=SPACE(01)
			_xCGCCLI:=SPACE(14)
			_xIDECLI:=SPACE(20)
			_xNOMCLI:=SPACE(55)
			_xFANCLI:=SPACE(55)
			_xNATCLI:=SPACE(01)
			_xENDCLI:=SPACE(70)
			_xCIDCLI:=SPACE(30)
			_xESTCLI:=SPACE(02)
			_xCEPCLI:=SPACE(08)
			_xDTECLI:=SPACE(04)
			_xTELCLI:=SPACE(10)
			_xDFACLI:=SPACE(04)
			_xFAXCLI:=SPACE(10)
			_xEMACLI:=SPACE(50)
			_xPRCCLI:=SPACE(06)
		Endif
		If SA1->A1_TIPO=="X"
			DbSelectArea("SE1")
			DbSkip()
			cLin:=""
			Loop
		EndIF
		If SA1->A1_GERASCI=="N"
			DbSelectArea("SE1")
			DbSkip()
			cLin:=""
			Loop
		EndIF
		// Se no e-mail nao tiver o caracter @ nao envia o conteudo
		If !("@" $ _xEMACLI)
			_xEMACLI:=SPACE(50)
		Endif
		If _xTIPCLI == "J"
			cLin:=cLin+_xTIPCLI+_xCGCCLI+_xNOMCLI+_xFANCLI+_xNATCLI+_xENDCLI+_xCIDCLI+;
			_xESTCLI+_xCEPCLI+_xDTECLI+_xTELCLI+_xDFACLI+_xFAXCLI+_xEMACLI+_xPRCCLI+;
			_xTITULO+_xNATURE+_xTMOEDA+_xVLRTIT+_xCENTIT+_xVALPAG+_xCENPAG+_xDTEMIS+;
			_xDTVENC+_xDTPAGO+_xFIM
		Else
			cLin:=cLin+_xTIPCLI+LEFT(_xCGCCLI,11)+_xIDECLI+SPACE(04)+_xNOMCLI+_xNATCLI+_xENDCLI+_xCIDCLI+;
			_xESTCLI+_xCEPCLI+_xDTECLI+_xTELCLI+_xDFACLI+_xFAXCLI+_xEMACLI+_xPRCCLI+;
			_xTITULO+_xNATURE+_xTMOEDA+_xVLRTIT+_xCENTIT+_xVALPAG+_xCENPAG+_xDTEMIS+;
			_xDTVENC+_xDTPAGO+SPACE(34)+_xFIM
		Endif
		
		If fWrite(nHdl,cLin,Len(cLin)) != Len(cLin)
			If !MsgAlert("Ocorreu um erro na gravacao do arquivo "+cArq+".   Continua?","Atencao!")
				Exit
			Endif
		Endif
		
		DbSelectArea("SE1")
		DbSkip()
		cLin:=""
	Enddo
	
	fClose(nHdl)
	
	MsgInfo("Geracao do arquivo concluida !!!","Concluido!!!")
	
Return
	
/*
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria Perguntas no SX1                                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Static Function ValidPerg()
	cAlias := Alias()
	aRegs  := {}
	
	// Grupo/Ordem/Pergunta/Pergunta Espanhol/Pergunta Ingles/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
	AADD(aRegs,{cPerg,"01","Data Inicial       ?","Data Inicial       ?","Data Inicial       ?","mv_ch1","D",08,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	AADD(aRegs,{cPerg,"02","Data Final         ?","Data Final         ?","Data Final         ?","mv_ch2","D",08,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","",""})
	
	DbSelectArea("SX1")
	DbSetOrder(1)
	For i:=1 to Len(aRegs)
		If !DbSeek(cPerg+aRegs[i,2])
			RecLock("SX1",.T.)
			For j:=1 to FCount()
				If j<=Len(aRegs[i])
					FieldPut(j,aRegs[i,j])
				Endif
			Next
			MsUnlock()
		Endif
	Next
	DbSelectArea(cAlias)
	Return
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Valida o TudoOk do Processamento                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Static Function _TudoOk()
	
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	
	RestArea(_aArea)
Return(_lRet)
*/



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
