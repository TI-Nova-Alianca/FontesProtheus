// Programa:  CTBA080_PE
// Autor:     Robert Koch
// Data:      13/12/2018
// Descricao: Ponto entrada na tela CTBA080 (cadastro lancamento padrao)
//            Criado inicialmente para gravar evento de alteracao.
//
// Historico de alteracoes:
// 27/08/2019 - Robert - Criado tratamento para chamada tipo MODELCANCEL
//

#include "Protheus.ch"
#include "FWMVCDEF.CH"

//Static lFlag := .F.

User Function CTBA080()
	Local aParam := PARAMIXB
	Local _xRet := NIL
	Local _sIdPonto := ''
	
	If aParam <> NIL
		//oObj := aParam[1]
		_sIdPonto := aParam[2]
		//u_log (_sIdPonto)
		//cIdModel := aParam[3]
		//lIsGrid := ( oObj:ClassName()=="FWFORMGRID" )   //.F. //( Len( aParam ) == 5 .And. aParam[5] != NIL )
		
		do case
		case _sIdPonto == 'MODELVLDACTIVE'  // Valida se permite abrir a tela.
			_xRet = .T.
		case _sIdPonto == 'MODELPOS'  // Na valida��o total do modelo.
			_xRet = .T.
		case _sIdPonto == 'MODELPRE'  // Antes da altera��o de qualquer campo do modelo.
			_xRet = .T.
		case _sIdPonto == 'FORMPRE'  // Antes da altera��o de qualquer campo do formul�rio.
			_xRet = .T.
		case _sIdPonto == 'FORMPOS'  // Na valida��o total do formul�rio.
			_xRet = .T.
		case _sIdPonto == 'FORMLINEPRE'  // Antes da altera��o da linha do formul�rio FWFORMGRID.
			_xRet = .T.
		case _sIdPonto == 'FORMLINEPOS'  // Na valida��o total da linha do formul�rio FWFORMGRID.
			_xRet = .T.
		case _sIdPonto == "MODELCANCEL"  // Quando o usuario cancela a edicao (tenta sair sem salvar)
			_xRet = .T.
		case _sIdPonto == 'MODELCOMMITTTS'  // Ap�s a grava��o total do modelo e dentro da transa��o.
			_xRet = NIL
		case _sIdPonto == 'MODELCOMMITNTTS'  // Ap�s a grava��o total do modelo e fora da transa��o.
			_xRet = NIL
		case _sIdPonto == 'FORMCOMMITTTSPRE'  // Antes da grava��o da tabela do formul�rio.
			_GeraLog ()
			_xRet = NIL
		case _sIdPonto == 'FORMCOMMITTTSPOS'  // Ap�s a grava��o da tabela do formul�rio.
			_xRet = NIL
		case _sIdPonto == 'FORMCANCEL'  // No cancelamento do bot�o.
			_xRet = .T.
		case _sIdPonto == 'BUTTONBAR'  // Para a inclus�o de bot�es na ControlBar.
			_xRet = {}  // Requer um array de retorno com estrutura pr� definida
		endcase
	endif
Return _xRet



// --------------------------------------------------------------------------
// Grava log de evento de alteracao de cadastro.
static function _GeraLog ()
	local _oEvento  := NIL
	if altera
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("CT5", m->ct5_lanpad + m->ct5_sequen, ct5 -> (recno ()))
	endif
return
