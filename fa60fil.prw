/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � FA60FIL  � Autor �    Jeferson Rech    � Data �  Jun/2002  ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Filtro Geracao do Bordero - Financeiro                     ���
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
// Historico de alteracoes:
// 08/06/2015 - Robert - Passa a validar o campo A1_VAEBOL.
//                     - Passa a salvar area de trabalho e usar variavel para retorno.
//

#include "rwmake.ch"

User Function fa60fil()
	local _sRet     := ""
	local _aAreaAnt := U_ML_SRArea ()
	//IF SE1->E1_CLIENTE $ getmv('ML_CLIC19')
	IF fBuscaCpo ("SA1", 1, xfilial ("SA1") + SE1->E1_CLIENTE + se1 -> e1_loja, "A1_VAEBOL") == "B"
	   //Return("Empty(SE1->E1_PORT2)")
	   _sRet = "Empty(SE1->E1_PORT2)"
	ELSE 
	   //Return("(SE1->E1_PORT2==cPort060 .And. !Empty(SE1->E1_NUMBCO)) .Or. Empty(SE1->E1_PORT2)")
	   _sRet = "(SE1->E1_PORT2==cPort060 .And. !Empty(SE1->E1_NUMBCO)) .Or. Empty(SE1->E1_PORT2)"
	ENDIF   
   	U_ML_SRArea (_aAreaAnt)
return _sRet

