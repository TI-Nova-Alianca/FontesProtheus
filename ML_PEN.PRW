// Programa..: ML_PEN.PRX
// Autor.....: Eleandro Casagrande
// Data......: Marco/2001
// Nota......: Posicao Titulos pendentes p/vendedor
//
// Historico de alteracoes:
// 06/03/2008 - Robert  - Criados logs para avaliacao de tempo de processamento.
// 26/01/2010 - Robert  - Perguntas ajustadas para versao 10.
// 18/06/2016 - Catia   - alterada razao social
// 09/03/2020 - Claudia - Ajustada criação de arquivo de trabalho conforme solicitação da release 12.1.25
//
// --------------------------------------------------------------------------------------
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_PEN()
	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

	// Variaveis utilizadas para parametros        
	// mv_par01      // Emissao  de                
	// mv_par02      // Emissao  ate               
	// mv_par03      // Vendedor de                
	// mv_par04      // Vendedor ate               
	// mv_par05      // Vencto   de                
	// mv_par06      // Vencto   ate               
	// mv_par07      // Prefixo  de                
	// mv_par08      // Prefixo  ate               
	// mv_par09      // Cliente  de                
	// mv_par10      // Cliente  ate               

	// Variaveis obrigatorias dos programas de relatorio            
	cString := "SE1"
	cDesc1  := "Este programa ir  emitir oas titulos conforme"
	cDesc2  := "parametros especificados da"
	cDesc3  := "Cooperativa Agroindustrial Nova Alianca Ltda"
	tamanho := "M"
	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha  := {}
	nLastKey:= 0
	cPerg   := "ML_PZN"
	titulo  := "Titulos Pendentes p/ Vendedor"
	wnrel   := "ML_PEN"
	nTipo   := 0
	_aArqTrb  := {}

	// Perguntas no Arquivo SX1                                     
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
// --------------------------------------------------------------------------------------
Static Function RptDetail()
	// Inicializa regua de impressao                             
	SetRegua(LastRec())

	// Inicializa os codigos de caracter Comprimido/Normal da impressora 
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1
	
	// Definição dos cabeçalhos 
	cabec1 := "Codigo Nome do Cliente               Tipo   Titulo    Emissao    Vencto   Banco   Saldo Titulo Historico                         ATR "
	cabec2 := "                                                                                                                                     "
	*****      XXXXXX X---------------------------X   XX  XXXXXX-X  XX/XX/XX   XX/XX/XX   XXX    X,XXX,XXX.XX X-------------------------------X XXX
	*****                1         2         3         4         5         6         7         8         9         0         1         2         3
	*****      0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
	
	// Gera arquivo de Trabalho                                     
	aCampos := {}
	aTam:=TamSX3("E1_PREFIXO")
	AADD(aCampos,{"PREFIXO" ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_NUM")
	AADD(aCampos,{"NUMERO"  ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_PARCELA")
	AADD(aCampos,{"PARCELA" ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_TIPO")
	AADD(aCampos,{"TIPO"    ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_CLIENTE")
	AADD(aCampos,{"CLIENTE" ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_LOJA")
	AADD(aCampos,{"LOJA"    ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_NOMCLI")
	AADD(aCampos,{"NOMCLI"  ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_EMISSAO")
	AADD(aCampos,{"EMISSAO" ,"D",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_VENCTO")
	AADD(aCampos,{"VENCTO"  ,"D",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_VALOR")
	AADD(aCampos,{"VALOR"   ,"N",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_VEND1")
	AADD(aCampos,{"VEND1"   ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_SALDO")
	AADD(aCampos,{"SALDO"   ,"N",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_PORTADO")
	AADD(aCampos,{"PORTADO" ,"C",aTam[1],aTam[2]})
	aTam:=TamSX3("E1_HIST")
	AADD(aCampos,{"HIST"    ,"C",aTam[1],aTam[2]})
	
	//cArqTra := CriaTrab(aCampos)
	//DbUseArea( .T.,, cArqTra,cArqTra, .T. , .F. )
	//cArqTra1:=Substr(cArqTra,1,7)+"1"
	//
	//DbSelectArea(cArqTra)
	//Index on VEND1+NOMCLI+DTOS(VENCTO)+PREFIXO+NUMERO+PARCELA to &cArqTra1
	
	_aArqTrb  := {}
	U_ArqTrb ("Cria", "TRB", aCampos, {"VEND1 + NOMCLI + VENCTO + PREFIXO + NUMERO + PARCELA"}, @_aArqTrb)
	
	_nSegIni := seconds ()

	// Verificacao de Dados                                         
	DbSelectArea("SE1")
	DbSetOrder(6)
	DbSeek(xFilial()+Dtos(mv_par01),.t.)
	
	Do While !Eof() .and. xFilial()==E1_FILIAL .and. E1_EMISSAO <= mv_par02
		IncRegua()              // Termometro de Impressao
		If SE1->E1_VEND1 < mv_par03 .or. SE1->E1_VEND1 > mv_par04
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		If SE1->E1_VENCTO < mv_par05 .or. SE1->E1_VENCTO > mv_par06
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		If SE1->E1_PREFIXO < mv_par07 .or. SE1->E1_PREFIXO > mv_par08
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		If SE1->E1_CLIENTE < mv_par09 .or. SE1->E1_CLIENTE > mv_par10
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		If SE1->E1_SALDO == 0
			DbSelectArea("SE1")
			DbSkip()
			Loop
		Endif
		
		DbSelectArea("TRB")
		Reclock("TRB",.T.)
		Replace  PREFIXO   With  SE1->E1_PREFIXO ,;
		NUMERO    With  SE1->E1_NUM     ,;
		PARCELA   With  SE1->E1_PARCELA ,;
		TIPO      With  SE1->E1_TIPO    ,;
		CLIENTE   With  SE1->E1_CLIENTE ,;
		LOJA      With  SE1->E1_LOJA    ,;
		NOMCLI    With  SE1->E1_NOMCLI  ,;
		EMISSAO   With  SE1->E1_EMISSAO ,;
		VENCTO    With  SE1->E1_VENCREA ,;
		VALOR     With  SE1->E1_VALOR   ,;
		SALDO     With  SE1->E1_SALDO   ,;
		VEND1     With  SE1->E1_VEND1   ,;
		HIST      With  SE1->E1_HIST    ,;
		PORTADO   With  SE1->E1_PORTADO
		MsUnlock()
		
		DbSelectArea("SE1")
		DbSkip()
	Enddo
	
	_nSegIni := seconds ()
	
	_x_VEND1 := "######"
	_x_CLIE1 := "######"
	_x_FLAG1 := 1
	_x_FLAG2 := 1
	_x_SALDO := 0
	_x_SALCL := 0
	_x_TOTCL := 0
	_x_TOTGE := 0
	x_NOM    := ""
	x_TEL    := ""
	DbSelectArea("TRB")
	DBGoTop()
	
	Do While !Eof()
		IncRegua()              // Termometro de Impressao
		If li>58
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif
		x_VEND1 := VEND1
		x_CLIE1 := CLIENTE
		x_LOJA1 := LOJA
		// Quebra do cliente
		IF _x_CLIE1 <> x_CLIE1
			IF _x_FLAG2 == 2
				li:=li+1
				If li>58
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				@ li, 007 PSAY x_NOM
				@ li, 064 PSAY "F: "+x_TEL
				@ li, 082 PSAY _x_SALCL   PICTURE "@E 9,999,999.99"
				li:=li+1
				If li>58
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				@ li, 001 PSAY REPLICATE("-",132)
				li:=li+1
				If li>58
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_x_SALCL := 0
			ENDIF
			li:=li+1
			If li>58
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			_x_CLIE1:=x_CLIE1
			_x_FLAG2:=2
		ENDIF
		//Quebra do vendedor
		IF _x_VEND1 <> x_VEND1
			DbSelectArea("SA3")
			DbSeek(xFilial()+x_VEND1)
			If Found()
				_x_DESC:=Left(SA3->A3_NOME,40)
				_xTEL  :=SA3->A3_TEL
				_xTELEX:=SA3->A3_TELEX
			Else
				_x_DESC:=REPLICATE("?",40)
				_xTEL  :=REPLICATE("?",15)
				_xTELEX:=REPLICATE("?",15)
			Endif
			IF _x_FLAG1 == 2
				li:=li+1
				If li>58
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				@ li, 064 PSAY "** Total Vendedor"
				@ li, 082 PSAY _x_SALDO   PICTURE "@E 9,999,999.99"
				_x_SALDO := 0
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			ENDIF
			@ li, 002 PSAY "Vendedor : "+Trim(x_VEND1)+" - "+Trim(_x_DESC)+" - "+Trim(_xTEL)+"/"+Trim(_xTELEX)
			li:=li+2
			If li>58
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			_x_VEND1:=x_VEND1
			_x_FLAG1:=2
		ENDIF
		DbSelectArea("TRB")
		@ li, 000 PSAY CLIENTE
		@ li, 007 PSAY LEFT(NOMCLI,28)
		@ li, 039 PSAY TIPO
		@ li, 043 PSAY NUMERO+"-"+PARCELA
		@ li, 053 PSAY EMISSAO
		@ li, 064 PSAY VENCTO
		@ li, 075 PSAY PORTADO
		@ li, 082 PSAY SALDO             PICTURE "@E 9,999,999.99"
		@ li, 095 PSAY Left(HIST,33)
		@ li, 129 PSAY DDATABASE-VENCTO  PICTURE "@E 999"
		li:=li+1
		_x_SALDO := _x_SALDO + SALDO
		_x_SALCL := _x_SALCL + SALDO
		_x_TOTGE := _x_TOTGE + SALDO
		AcessaCli()
		DbSelectArea("TRB")
		DbSkip()
	Enddo
	
	li:=li+1
	If li>58
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	@ li, 007 PSAY x_NOM
	@ li, 064 PSAY "F: "+x_TEL
	@ li, 082 PSAY _x_SALCL   PICTURE "@E 9,999,999.99"
	li:=li+2
	If li>58
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	@ li, 064 PSAY "** Total Vendedor"
	@ li, 082 PSAY _x_SALDO   PICTURE "@E 9,999,999.99"
	li:=li+1
	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	@ li, 064 PSAY "** Total Geral"
	@ li, 082 PSAY _x_TOTGE   PICTURE "@E 9,999,999.99"
	li:=li+1
	
	Set Device To Screen
	
	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif
	
	MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
	
	// Deleta o Arquivo de Trabalho                                 
	DbSelectArea("TRB")
	DbCloseArea()
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
//	cDelArq:=cArqTra+".DBF"
//	FERASE(cDelArq)
//	cDelArq:=SubStr(cArqTra,1,7)+"*"+OrdBagExt()
//	FERASE(cDelArq)
Return
// --------------------------------------------------------------------------
// Acessa o Cadastro de Clientes                                
Static Function AcessaCli
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial()+x_CLIE1+x_LOJA1)
	
	If Found()
		x_TEL := IIf(!Empty(SA1->A1_TELCOB),SA1->A1_TELCOB,SA1->A1_TEL)
		x_NOM := SA1->A1_NOME
	Else
		x_TEL := ""
		x_NOM := ""
	Endif
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Emissao de                   ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao ate                  ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "Vendedor Inicial             ?", "C",  6, 0,  "",   "SA3", {},                         ""})
	aadd (_aRegsPerg, {04, "Vendedor Final               ?", "C",  6, 0,  "",   "SA3", {},                         ""})
	aadd (_aRegsPerg, {05, "Vencto de                    ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {06, "Vencto ate                   ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {07, "Prefixo de                   ?", "C",  3, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {08, "Prefixo ate                  ?", "C",  3, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {09, "Cliente de                   ?", "C",  6, 0,  "",   "SA1", {},                         ""})
	aadd (_aRegsPerg, {10, "Cliente ate                  ?", "C",  6, 0,  "",   "SA1", {},                         ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return