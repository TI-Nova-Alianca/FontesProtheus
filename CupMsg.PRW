// Programa:   CupMsg
// Autor:      Robert Koch
// Data:       16/09/2010
// Descricao:  Gera mensagem para cupom fiscal.
//             Inicialmente abre tela para o usuario alterar caso necessario.
//             Criado para ser chamado a partir do parametro MV_LJFISMS com a seguinte sintaxe:  &U_CUPMSG()
// 
// Historico de alteracoes:
// 29/06/2012 - Robert  - CPF/CNPJ do cliente inserido no inicio da mensagem.
//                      - Envia string maior (mensagem em 2 linhas).
// 14/06/2013 - Leandro - Imprime o nome do contato
// 18/11/2016 - Catia   - Estava dando erro
// 16/03/2018 - Robert  - Se estiver retransmitindo um cupom, nao abre tela.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function CupMsg ()
	local _sRet    := ""
	local _sNome   := ""
	local _sCGC    := ""
	local _nLimite := 48 * 2 - 18  // 2 linhas de 48 caracteres menos "orcamento: xxxxxx " no inicio.

	// Se estiver retransmitindo um cupom, nao abre tela.
	if IsInCallStack ("LJNFCERETR")
		_sRet = ''
	else
		// Se tiver CNPJ / CPF informado, o mesmo deve permanecer.
		if ! empty (m->lq_vacgc)
			_sCGC = iif (len (alltrim (m->lq_vacgc)) == 14, " CNPJ:", " CPF:") + alltrim (m->lq_vacgc)
			_sRet = _sCGC
			m->l1_cgccli := _sCGC
			m->lq_cgccli := _sCGC
		endif
		
		// nome do contato cadastrado
		//_sNome = left (fBuscaCpo ("SU5",8,xfilial("SU5")+m->lq_vacgc, "U5_CONTAT"), _nLimite - len (_sCGC))
		if ! empty(m->lq_contato)
			_sNome = left (fBuscaCpo ("SU5",1,xfilial("SU5")+m->lq_contato, "U5_CONTAT"), _nLimite - len (alltrim (_sCGC)))
		endif		
		
		// se não achar o nome no cadastro de contato, pega do cliente
		if empty(_sNome)
			_sNome = left (fBuscaCpo ("SA1", 1, xfilial ("SA1") + M->lq_cliente + M->lq_loja, "A1_NOME"), _nLimite - len (_sCGC))
		endif
	
		// Dialogo para confirmar o nome do cliente.
		@ 0, 0 TO 100, 450 DIALOG oDlg1 TITLE "Nome Cliente p/ Cupom Fiscal"
		@ 012, 002 GET _sNome PICTURE "@!" SIZE 150, 11
		@ 032, 140 BMPBUTTON TYPE 1 ACTION Close(oDlg1)
		ACTIVATE DIALOG oDlg1 CENTERED
		
		_sRet = alltrim (left (_sCGC + ' ' + 'Nome: ' + _sNome, _nLimite))
	endif

return _sRet
