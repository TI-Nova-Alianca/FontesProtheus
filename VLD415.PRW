#include "rwmake.ch"

User Function VLD415()

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � VLD415 � Autor �    Adelar D. Minuzzo  � Data � abr/2007 ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Validacao Linhas do pre pedido (orcamento)                 ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Utilizacao� Especifico para Cooperativa Nova Alianca                   ���
�������������������������������������������������������������������������Ĵ��
���   Data   � Programador   �Manutencao Efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
Local _aArea    := GetArea()
local _xFim     := chr(13)+chr(10)
local _lRet   := .T.

//Tratamento de negociacao de vendas para os representantes contido no parametro
//ML_REPRES - "125    /107   /020   "
//verifica se o percentual de desconto para o item esta dentro dos limites
//maximo % desconto a ser concedido esta no cadastro de vendedores A3_PERDDESC
//sera buscado apartir do codigo do vendedor do cabecalho do pedido de venda C5_VEND1
IF CEMPANT== "01" .AND. CFILANT == "01" 
	_xTABELA  := M->CJ_TABELA
   _XCJPVCOND := M->CJ_PVCOND
 IF M->CJ_VEND1 $ GETMV("ML_REPRES")
	DbSelectArea("TMP1")
	_xPRUNIT  := TMP1->CK_PRUNIT
	_xPRCVEN  := TMP1->CK_PRCVEN
	_xCKPVCOND  := TMP1->CK_PVCOND
	_xqtdven  := TMP1->CK_QTDVEN
	_xFLAG    := TMP1->CK_FLAG

	//������������������������������������������������������Ŀ
	//� VerIfica se a linha foi deletada ou estou Cancelando �
	//��������������������������������������������������������
    If _xFLAG .Or. 'A415CANCEL' $ ProcName(8) .Or. 'A415CANCEL' $ ProcName(12)
		RestArea(_aArea)
		Return(_lRet)
    Endif                    
	 IF !EMPTY(_XTABELA) .AND. _XCJPVCOND == "S" 
         if  _XCKPVCOND == 0
			    MsgBox("PVCOND: " + " N�o informado."+_xFim+"Informe antes o preco de venda da condi��o.","ATENCAO!!!","STOP")
			    _lRet := .F.
             Return(_lRet)
          endif    
         _xPRCVEN  := _XCKPVCOND
    ENDIF	
	_xPERDESC := Fbuscacpo("DA0", 1, xFilial("DA0") + M->CJ_TABELA , "DA0->DA0_DESC")
	_xFATOR   := Fbuscacpo("DA0", 1, xFilial("DA0") + M->CJ_TABELA , "DA0->DA0_FATOR")
	_xPERCALC := ROUND((1 - (_XPRCVEN / _XPRUNIT))*100,2) // %DESCONTO QUE ESTA SENDO PRATICADO
	_xpercomis := m->cJ_comis1
	_xdescfat := (_xpercalc * _XFATOR)
	_xnovcomis := round(_xpercomis-((_xpercomis*_xdescfat)/100),2)
	TMP1->CK_COMIS1:= M->CJ_COMIS1
	IF _XNOVCOMIS < 0
		_XNOVCOMIS := 0
    ENDIF
	IF _XNOVCOMIS < _XPERCOMIS
		TMP1->CK_COMIS1:= _xnovcomis
		Sysrefresh()
	ENDIF
    TMP1->CK_BLQCRED:="  "
	IF _xPERCALC > _xPERDESC
	    TMP1->CK_BLQCRED:="01"
		Alert("DESCONTO: " + " Superior a desconto liberado."+_xFim+"Verifique o Vlr informado.","ATENCAO!!!","STOP")
		_lRet := .T.               
		
	ENDIF
	IF _xQTDVEN = 0
		MsgBox("Quantidade: " + " N�o Informada."+_xFim+"Verifique a quantidade informado.","ATENCAO!!!","STOP")
		_lRet := .F.
	ENDIF
 ENDIF 	
ENDIF   
RestArea(_aArea)
Return(_lRet)
