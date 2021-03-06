/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Programa  � ML_VCLI1  � Autor �    Adelar D. Minuzzo  � Data � OUT/2006 ���
�������������������������������������������������������������������������Ĵ��
���Descricao � Consistencia para enviar mensagem ao fazer pre pedido p/   ���
���          � clientes bloqueados                                        ���
�������������������������������������������������������������������������Ĵ��
���Retorno   �                                                            ���
�������������������������������������������������������������������������Ĵ��
���Utilizacao� Especifico para Clientes Microsiga                         ���
�������������������������������������������������������������������������Ĵ��
���   Data   � Programador   �Manutencao Efetuada                         ���
�������������������������������������������������������������������������Ĵ��
���          �               �                                            ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
// Historico de alteracoes:
// 24/07/2008 - Robert - Nao aceita clientes que nao pertencam ao vendedor corrente.
// 28/07/2008 - Robert - Valida campo A3_VACLOUT.
// 

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function ml_vcli1 ()
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.

	sa1 -> (dbsetorder (1))
	if ! sa1 -> (dbseek (xfilial ("SA1") + m->cj_Cliente + iif (!empty (m->cj_loja), m->cj_loja, ""), .F.))
		u_help ("Cliente nao cadastrado.")
		_lRet = .F.
	endif
	
	if _lRet
		if sa1 -> a1_vend != m->cj_vend1
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + m->cj_vend1, .F.))
				u_help ("Representante nao cadastrado.")
				_lRet = .F.
			else
				if sa3 -> a3_ativo != "S"
					u_help ("Representante inativo.")
					_lRet = .F.
				else
					if sa3 -> a3_vaClOut != "S"
						u_help ("Representante sem permissao para atender clientes de outros representantes.")
						_lRet = .F.
					endif
				endif
			endif
		endif
	endif

	if _lRet
		If SA1->A1_MSBLQL == "1"
			MsgInfo ("Cliente " + sa1 -> a1_nome + ":" + chr (13) + chr (10) + "Cliente Bloqueado para Faturamento. Verifique com Financeiro ou Comercial.","Atencao!!! Cliente Bloqueado para Faturamento.")
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
