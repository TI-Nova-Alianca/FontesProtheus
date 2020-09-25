#include "rwmake.ch"

User Function loja140()

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � LOJA140  � Autor �    Jeferson Rech    � Data �  Abr/2001  ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Exclusao do Livro Fiscal na Exclusao da Venda Balcao       ���
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

_cAlias   := Alias()
_xDOC     := SF2->F2_DOC
_xSERIE   := SF2->F2_SERIE

DbSelectArea("SF3")     // Livros Fiscais
DbSetOrder(5)
DbSeek(xFilial()+_xSERIE+_xDOC)
Do While !Eof() .And. SF3->F3_FILIAL+SF3->F3_SERIE+SF3->F3_NFISCAL == xFilial()+_xSERIE+_xDOC

   RecLock("SF3",.F.)

   //DbDelete()
   SF3->F3_DTCANC := dDataBase
   SF3->F3_OBSERV := "NF CANCELADA"

   MsUnLock()

   DbSelectArea("SF3")
   DbSkip()
Enddo

DbSelectArea("SF3")
RetIndex("SF3")

DbSelectArea(_cAlias)
Return(.T.)
