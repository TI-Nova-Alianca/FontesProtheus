/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ ML_VCLI1  ³ Autor ³    Adelar D. Minuzzo  ³ Data ³ OUT/2006 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Consistencia para enviar mensagem ao fazer pre pedido p/   ³±±
±±³          ³ clientes bloqueados                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Utilizacao³ Especifico para Clientes Microsiga                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   Data   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
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
		msgalert ("Cliente nao cadastrado.")
		_lRet = .F.
	endif
	
	if _lRet
		if sa1 -> a1_vend != m->cj_vend1
			sa3 -> (dbsetorder (1))
			if ! sa3 -> (dbseek (xfilial ("SA3") + m->cj_vend1, .F.))
				msgalert ("Representante nao cadastrado.")
				_lRet = .F.
			else
				if sa3 -> a3_ativo != "S"
					msgalert ("Representante inativo.")
					_lRet = .F.
				else
					if sa3 -> a3_vaClOut != "S"
						msgalert ("Representante sem permissao para atender clientes de outros representantes.")
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
