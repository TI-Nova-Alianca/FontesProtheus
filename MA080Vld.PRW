#include "protheus.ch"

// Programa:  MA080Vld
// Autor:     Robert Koch
// Data:      19/11/2010
// Descricao: P.E. 'Tudo OK' no cadastro de TES.
//            Criado inicialmente para gravar log de evento de alteracao.
//
// Historico de alteracoes:
// 07/10/2011 - Robert  - Libera gravacao somente para usuarios restritos.
// 21/08/2013 - Leandro - Envia e-mail para Sara quando um TES é alterado.
// 12/03/2015 - Robert  - Passa a validar usuarios pela funcao U_ZZUVL.
// 18/11/2016 - ProcData - Validação de exclusão para ompatibilidade com sistema Mercanet.

// --------------------------------------------------------------------------
user function MA080Vld ()
	local _lRet := .T.
	local _oEvento  := NIL

	// Verifica se o usuario tem liberacao para esta rotina.
	_lRet = U_ZZUVL ('035')

	// Grava log de evento em case de alteracao de cadastro.
	if _lRet .and. altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SF4", m->f4_codigo, sf4 -> (recno ()))
	endif 
	
	//Bloqueio de exclusão de TES 
	if !inclui .and. !altera
		_lRet := .F.
		alert("Nenhum registro de TES pode ser excluído em função da integração com o software Mercanet.")
	endif
return _lRet

