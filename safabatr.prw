#INCLUDE "rwmake.ch"

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  � safabatr   � Autor � Adelar             � Data �  mar/2007 ���
�������������������������������������������������������������������������͹��
���Descricao � programa executado na configuracao do lay-out de geracao    ��
���            do arquivo para banco                                      ��
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � Clientes Microsiga                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������

Historico de alteracoes:
/*/

User Function safabatr()

_nValSom := 0
_cPrefixo := SE1->E1_PREFIXO
_cNumero := SE1->E1_NUM
_cParcela := SE1->E1_PARCELA
_nMoeda := SE1->E1_MOEDA
_dData := SE1->E1_VENCREA
_cFornCli := SE1->E1_CLIENTE
_cLoja := SE1->E1_LOJA
_cFilAbat := SE1->E1_FILIAL

_nValSom := SomaAbat(_cPrefixo,_cNumero,_cParcela,"R",_nMoeda,_dData,_cFornCli,_cLoja)

_nValSom := STRZERO((_nValSom*100),13) 

Return(_nValSom)
