// Programa...: A415LIOK
// Autor......: Adelar D. Minuzzo
// Data.......: 04/2007
// Descricao..: Validacao Linhas do pre pedido (orcamento)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Validacao Linhas do pre pedido (orcamento)
// #PalavasChave      #orcamento #pre_pedido
// #TabelasPrincipais #SA1 #SF4
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 03/05/2022 - Claudia - Retirada a gravação do campo A1_SAVBLQ. GLPI: 11922
// 
// ---------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function A415LIOK()
	Local _aArea    := GetArea()
	local _xFim     := chr(13)+chr(10)
	local _lRet   := .T.

	// DbSelectArea("SA1")
	// RecLock("SA1",.F.)
	// IF EMPTY(SA1->A1_SAVBLQ)
	// 	SA1->A1_SAVBLQ    := SA1->A1_MSBLQL    //salva o conteudo da campo para no ponto de entrada
	// 	SA1->A1_MSBLQL    := "2"               // a415tdok retornar a posicao atual
	// 	MsUnlock()                             // objetivo e desbloquear o cliente para fazer o pre pedido
	// ENDIF

	// Valida se a Linha Nao estiver deletada
	_xcjpvcond := m->cj_PVCOND
	DbSelectArea("TMP1")
	_xPEDCLI  := TMP1->CK_PEDCLI
	_xTES     := TMP1->CK_TES
	_xCF      := TMP1->CK_CF
	_xBONIFIC := TMP1->CK_BONIFIC
	_xFLAG    := TMP1->CK_FLAG
	_xckpvcond := TMP1->CK_PVCOND

	// VerIfica se a linha foi deletada ou estou Cancelando 
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
