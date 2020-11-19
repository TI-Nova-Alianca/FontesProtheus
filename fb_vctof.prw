/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � FB_VCTOF � Autor � Evandro Mugnol        � Data �08/01/2008���
�������������������������������������������������������������������������Ĵ��
���Unidade   � Serra Gaucha     �Contato � evandrom@microsiga.com.br      ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Validacao de digitacao de vencimento de titulos a pagar    ���
���          � Devera ser incluido um ExecBlock("FB_VCTOF",.F.,.F.) na    ���
���          � validacao de usuario dos campos F1_FORNECE, F1_COND e      ���
���          � F1_EMISSAO                                                 ���
�������������������������������������������������������������������������Ĵ��
���Parametros�                                                            ���
�������������������������������������������������������������������������Ĵ��
���Uso       � Especifico para Cooperativa Nova Alianca                   ���
�������������������������������������������������������������������������Ĵ��
���Analista Resp.�  Data  � Bops � Manutencao Efetuada                    ���
�������������������������������������������������������������������������Ĵ��
���              �  /  /  �      �                                        ���
���              �  /  /  �      �                                        ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
// Historico de alteracoes:
// 17/10/2010 - Robert - Nao executa validacao quando chamado via rotinas batch.
// 07/06/2011 - Robert - Nao executa validacao quando chamado via importacao de XML ou pre-nota.
// 18/09/2013 - Leandro - Fonte recolocado no projeto
//

#include "rwmake.ch"

User Function FB_VCTOF()

Local _lRet  := .T.
Local _aArea := GetArea()
Local _xI    := 0
If cTipo <> "D" .and. ! IsInCallStack ("MATA140")
	_cCond := Condicao(10000,cCondicao,,dDEmissao)
	
	For _xI:=1 To Len(_cCond)
		If _cCond[_xI,1] < DATE()
			If !MsgYesNo("Confirmar inclus�o da parcelas " + cvaltochar(_xI) + " com data de vencimento menor que a data de digita��o ?","Confirmar")
				_lRet := .F.
			Endif
		Endif
	Next
Endif

RestArea(_aArea)

return(_lRet)
