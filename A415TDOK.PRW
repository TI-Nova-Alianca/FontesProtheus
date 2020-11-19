/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ M415tdOK ³ Autor ³    Adelar D. Minuzzo  ³ Data ³ abr/2007 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Validacao Linhas do pre pedido (orcamentos)                ³±±
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
// Historico de alteracoes:
// 18/09/2008 - Robert - Criadas validacoes para campanhas de venda.
//

#include "rwmake.ch"

User Function A415TDOK()
	local _lRet      := .T.
	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()

	// Retorna o conteudo do campo SA1->A1_MSBLQL salvo no ponto de
	// entrada A415LIOK - caso o tiver bloquear no momento da inclusao
	// volta a bloquear neste momento (foi desbloqueado para incluir o pre-pedido)
	DbSelectArea("SA1")
	RecLock("SA1",.F.)
	SA1->A1_MSBLQL    := SA1->A1_SAVBLQ
	SA1->A1_SAVBLQ    := ""
	MsUnlock()                           


	// Consistencias referentes a campanhas promocionais.
	if _lRet
		_lRet = _Campanhas ()
	endif


	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return _lRet



// --------------------------------------------------------------------------
// Consistencias referentes a campanhas promocionais.
static function _Campanhas ()
	local _lRet   := .T.

	if ! empty (m->cj_vaverba)
		ack -> (dbsetorder (1))  // ACK_FILIAL+ACK_CODVER+ACK_GRPVEN+ACK_CODVEN+ACK_GRPCLI+ACK_CODCLI+ACK_LOJA+DTOS(ACK_DATINI)+DTOS(ACK_DATFIM)
		if ! ack -> (dbseek (xfilial ("ACK") + M->cj_vaverba, .F.))
			U_HELP ("Campanha nao cadastrada.")
			_lRet = .F.
		endif
		if _lRet .and. ! empty (ack -> ack_codcli) .and. m->cj_cliente + m-> cj_loja != ack -> ack_codcli + ack -> ack_loja
			u_help ("Campanha especifica para o cliente " + ack -> ack_codcli + "/" + ack -> ack_loja)
			_lRet = .F.
		endif
		if _lRet
			if ack -> ack_vacomi != 0 .and. m->cj_comis1 != ack -> ack_vacomi
  				u_help ("Comissao para esta campanha deve ser de " + cvaltochar (ack -> ack_vacomi) + "%")
				_lRet = .F.
			endif
		endif
		if _lRet

			// Se a campanha tiver algum item, os produtos do pedido devem estar contemplados nesse(s) item(s).
			acl -> (dbsetorder (1))  // ACL_FILIAL+ACL_CODVER+ACL_ITEM+ACL_CODPRO
			if acl -> (dbseek (xfilial ("ACL") + ack->ack_codver, .T.)) .and. ! empty (acl -> acl_codpro)
				acl -> (dbsetorder (2))  // ACL_FILIAL+ACL_CODPRO+ACL_CODVER
				
				// Varre os itens do pre-pedido.
				tmp1 -> (dbgotop ())
				do while ! tmp1 -> (eof ())
					if ! tmp1 -> ck_flag .and. ! acl -> (dbseek (xfilial ("ACL") + tmp1 -> Ck_PRODUTO, .F.))
						u_help ("Produto '" + tmp1 -> Ck_PRODUTO + "' nao consta na campanha de vendas " + m->cj_vaverba)
						_lRet = .F.
						exit
					endif
					tmp1 -> (dbskip ())
				enddo
			endif
		endif

		if _lRet
			// Varre os itens do pre-pedido.
			tmp1 -> (dbgotop ())
			do while ! tmp1 -> (eof ())
				if ! tmp1 -> ck_flag .and. tmp1 -> ck_ENTREG < ack -> ack_datini .or. tmp1 -> CK_ENTREG > ack -> ack_datfim
					u_help ("Linha " + cvaltochar (tmp1 -> (recno ())) + ": data de entrega fora do periodo da campanha (" + dtoc (ack -> ack_datini) + " a " + dtoc (ack -> ack_datfim) + ").")
					_lRet = .F.
					exit
				endif
				tmp1 -> (dbskip ())
			enddo
		endif

	endif

return _lRet
