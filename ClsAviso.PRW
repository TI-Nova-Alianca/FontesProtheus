// Programa:  ClsAviso
// Autor:     Robert Koch
// Data:      30/10/2019
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 17/06/2020 - Robert - Passa a validar codigo do aviso, para manter consistencia.
//

#include "protheus.ch"


// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsAviso ()
return


// ==========================================================================
// Classe usada para criar, gravar e executar processos em Aviso ou agendados.
CLASS ClsAviso

	// Declaracao das propriedades da Classe
	data Tipo
	data Destinatar
	data Texto
	data Origem
	data DiasDeVida
	data CodAviso

	// Declara��o dos M�todos da Classe
	METHOD New ()
	METHOD Grava ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New () Class ClsAviso
	::Tipo       := ""
	::Destinatar := ""
	::Texto      := ""
	::Origem     := ""
	::DiasDeVida := 0
	::CodAviso   := ""
Return Self


// --------------------------------------------------------------------------
// Serializacao e gravacao em arquivo
METHOD Grava () Class ClsAviso
	local _aAreaAnt := U_ML_SRArea ()
	local _i        := 0
	local _sPilha   := ""
	local _aCodAvis := {}

	u_log2 (iif (::Tipo == 'A', 'info', 'erro'), '[' + GetClassName (::Self) + '.' + procname () + '] ' + iif (::Tipo == 'A', 'Aviso', 'Notificacao de erro') + ' para ' + ::Destinatar + ': ' + ::Texto)

	_aCodAVis = {}
	aadd (_aCodAvis, {'001', 'Usuario deveria estar bloqueado (ferias/afastamento/desligamento)'})
	aadd (_aCodAvis, {'002', 'Transportadora nao localizada para gerar tag de redespacho'})
	aadd (_aCodAvis, {'003', 'Inconsistencias acessos/cadastro usuarios'})
	aadd (_aCodAvis, {'004', 'Erros recepcao / envio de e-mail'})
	aadd (_aCodAvis, {'005', 'Problemas com gatilhos ou validacoes de campos'})
	aadd (_aCodAvis, {'006', 'Alteracao no STATUSCANC da tabela SPED050 por rejeicao 656. Precisa acao manual posterior para retransmissao.'})
	aadd (_aCodAvis, {'007', 'Bloqueio de semaforo para execucao de batches (provavelmente o batch anterior esteja travado)'})
	aadd (_aCodAvis, {'008', 'Alteracao no STATUSCANC da tabela SPED050 por ter muitos registros na tabela TSS0004.'})
	aadd (_aCodAvis, {'009', 'Monitoramento de disponibilidade do sistema'})
	aadd (_aCodAvis, {'010', 'Inconsistencia cadastro associados'})
	aadd (_aCodAvis, {'011', 'Problemas no calculo de frete de uva para associados.'})
	aadd (_aCodAvis, {'012', 'Ajustado custo negativo no B2_VATU'})
	aadd (_aCodAvis, {'013', 'Erro atualizacao SE5 na compensacao de contas a pagar'})

	if ascan (_aCodAVis, {|_aVal| _aVal [1] == ::CodAviso}) == 0
		u_log2 ('erro', "Codigo de aviso '" + ::CodAviso + "' nao cadastrado na classe " + GetClassName (::Self))
	endif

	if ::Tipo == 'E'  // Erro
		if ! 'GRPTI' $ upper (::Destinatar)
			::Destinatar += ';grpTI'
		endif
	endif

	reclock ("ZAB", .T.)
	zab -> zab_tipo   = ::Tipo
	zab -> zab_destin = ::Destinatar
	zab -> zab_texto  = ::Texto
	zab -> zab_dtemis = date ()
	zab -> zab_hremis = time ()
	if ::Origem == NIL .or. empty (::Origem)
		do while procname (_i) != ""
			_sPilha += '=>' + procname (_i)
			_i++
		enddo
		zab -> zab_origem = _sPilha
	else
		zab -> zab_origem = ::Origem
	endif
	zab -> zab_valid  = iif (::DiasDeVida == NIL, iif (::Tipo == 'E', 0, 30), ::DiasDeVida)
	zab -> zab_lido   = 'N'
	zab -> zab_codigo = ::CodAviso
	msunlock ()

	U_ML_SRArea (_aAreaAnt)
return