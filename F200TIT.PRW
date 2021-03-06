// Programa:   F200TIT
// Autor:      Jeferson Rech
// Data:       01/01/2002
// Cliente:    Alianca
// Descricao:  Atualiza o SE5 quando da recepcao bancaria - Cnab 
// 
// Historico de alteracoes:
// 09/07/2019 - Andre - Alterado para gravar usu�rio em todas as opera��es, e n�o somente no d�bito.

#include "rwmake.ch"

User Function f200tit()

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � F200TIT  � Autor �     Jeferson Rech     � Data � Jan/2002 ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Atualiza o SE5 quando da recepcao bancaria - Cnab          ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Utilizacao� Especifico para Alianca                                    ���
�������������������������������������������������������������������������Ĵ��
���   Data   � Programador   �Manutencao Efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

Local _aArea     := GetArea()
Local _aAreaSE5  := SE5->(GetArea())

DbSelectArea("SE5")
DbSetOrder(7)
DbSeeK(xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA)
Do While !Eof() .And. xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA==SE5->E5_FILIAL+SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA
	If SE5->E5_DTDISPO==Ctod("") .And. ALLTRIM(SE5->E5_TIPODOC)=="DB"
		RecLock("SE5",.F.)
		If SE5->E5_DATA > Ctod("25/01/02")
			SE5->E5_DTDISPO := SE5->E5_DATA
		Endif
		MsUnlock()
	EndIf
	RecLock("SE5",.F.)
	If SE5->E5_DATA > Ctod("25/01/02")
		SE5->E5_VAUSER  := alltrim(cUserName)
	Endif
	MsUnlock()
	DbSelectArea("SE5")
	DbSkip()
Enddo

RestArea(_aAreaSE5)
RestArea(_aArea)
Return