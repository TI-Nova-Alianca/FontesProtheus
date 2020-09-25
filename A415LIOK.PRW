#include "rwmake.ch"

User Function A415LIOK()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ M415LIOK ³ Autor ³    Adelar D. Minuzzo  ³ Data ³ abr/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Validacao Linhas do pre pedido (orcamento)                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Cooperativa Nova Alianca                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Local _aArea    := GetArea()
local _xFim     := chr(13)+chr(10)
local _lRet   := .T.

DbSelectArea("SA1")
RecLock("SA1",.F.)
IF EMPTY(SA1->A1_SAVBLQ)
	SA1->A1_SAVBLQ    := SA1->A1_MSBLQL    //salva o conteudo da campo para no ponto de entrada
	SA1->A1_MSBLQL    := "2"               // a415tdok retornar a posicao atual
	MsUnlock()                             // objetivo e desbloquear o cliente para fazer o pre pedido
ENDIF
//Tratamento de negociacao de vendas para os representantes contido no parametro
//ML_REPRES - "125    /107   /020   "
//verifica se o percentual de desconto para o item esta dentro dos limites
//maximo % desconto a ser concedido esta no cadastro de vendedores A3_PERDDESC
//sera buscado apartir do codigo do vendedor do cabecalho do pedido de venda C5_VEND1
/*IF CEMPANT== "01" .AND. CFILANT == "01" 
 IF M->CJ_VEND1 $ GETMV("ML_REPRES")
	DbSelectArea("TMP1")
	_xPRUNIT  := TMP1->CK_PRUNIT
	_xPRCVEN  := TMP1->CK_PRCVEN
	_xqtdven  := TMP1->CK_QTDVEN
	_xFLAG    := TMP1->CK_FLAG

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ VerIfica se a linha foi deletada ou estou Cancelando ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
    If _xFLAG .Or. 'A415CANCEL' $ ProcName(8) .Or. 'A415CANCEL' $ ProcName(12)
		RestArea(_aArea)
		Return(_lRet)
	Endif
	_xPERDESC := Fbuscacpo("DA0", 1, xFilial("DA0") + M->CJ_TABELA , "DA0->DA0_DESC")
	_xFATOR   := Fbuscacpo("DA0", 1, xFilial("DA0") + M->CJ_TABELA , "DA0->DA0_FATOR")
	_xPERCALC := ROUND((1 - (_XPRCVEN / _XPRUNIT))*100,2) // %DESCONTO QUE ESTA SENDO PRATICADO
	_xpercomis := m->cJ_comis1
	_xdescfat := (_xpercalc * _XFATOR)
	_xnovcomis := round(_xpercomis-((_xpercomis*_xdescfat)/100),2)
	IF _XNOVCOMIS < _XPERCOMIS
		TMP1->CK_COMIS1:= _xnovcomis
		Sysrefresh()
	ENDIF
	IF _xPERCALC > _xPERDESC
	    TMP1->CK_BLQCRED:="01"
		Alert("DESCONTO: " + " Superior a desconto liberado."+_xFim+"Verifique o Vlr informado.","ATENCAO!!!","STOP")
		_lRet := .T.
	ENDIF
	IF _xQTDVEN = 0
		MsgBox("Quantidade: " + " Não Informada."+_xFim+"Verifique a quantidade informado.","ATENCAO!!!","STOP")
		_lRet := .F.
	ENDIF
 ENDIF 	
ENDIF   */                 

// Valida se a Linha Nao estiver deletada
_xcjpvcond := m->cj_PVCOND
DbSelectArea("TMP1")
_xPEDCLI  := TMP1->CK_PEDCLI
_xTES     := TMP1->CK_TES
_xCF      := TMP1->CK_CF
_xBONIFIC := TMP1->CK_BONIFIC
_xFLAG    := TMP1->CK_FLAG
_xckpvcond := TMP1->CK_PVCOND

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ VerIfica se a linha foi deletada ou estou Cancelando ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If _xFLAG .Or. 'A415CANCEL' $ ProcName(8) .Or. 'A415CANCEL' $ ProcName(12)
	RestArea(_aArea)
	Return(_lRet)
Endif

// Verifica o TES
DbSelectArea("SF4")
DbSetOrder(1)
DbSeek(xFilial("SF4")+_xTES,.F.)
If Found()
	_xSF4CF   := SF4->F4_CF
	_XSF4BON  := SF4->F4_MARGEM
Else
	_xSF4CF   := ""
	_XSF4BON  := ""
Endif

IF _xSF4BON  == "3"   // BONIFICACAO
	// Verifica o se foi informado o tipo de bonificacao
	If empty(_xBONIFIC)
		MsgBox(" Informe  o tipo de bonificação."+_xFim+"","ATENCAO!!!","STOP")
		_lRet := .F.
	Endif
Endif                    
If _xcjpvcond == "S" .AND. _XCKPVCOND == 0 
		MsgBox("PVCOND"+_xFim+"Falta informar preco de venda da condicão.","ERRO!!!","STOP")
		_lRet := .F.
Endif


RestArea(_aArea)
Return(_lRet)
