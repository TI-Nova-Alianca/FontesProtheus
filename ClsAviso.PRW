// Programa:  ClsAviso
// Autor:     Robert Koch
// Data:      30/10/2019
// Descricao: Declaracao de classe para uso em outros programas. Poderia trabalhar como
//            uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 17/06/2020 - Robert - Passa a validar codigo do aviso, para manter consistencia.
// 14/02/2021 - Robert - Atributo ::Destinatar substituido por ::DestinAvis
//                     - Nao grava mais para GrpTI qunto tipo 'Erro'.
// 08/12/2021 - Robert - Gera log quando tipo de aviso invalido.
// 30/08/2022 - Robert - Atributo ClsAviso:DestinAvis passa a ser tipo string.
//                     - Versao inicial de envio para NaWeb via web service.
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
	data Destinatar  // soh pra manter compatibilidade com fontes antigos
	data DestinAvis
	data Texto
	data Titulo
	data Origem
	data DiasDeVida
	data CodAviso

	// Declaração dos Métodos da Classe
	METHOD New ()
	METHOD EnviaNAWeb ()
	METHOD Grava ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New () Class ClsAviso
	::Tipo       := ""
	::Destinatar := ""
	::DestinAvis := ''
	::Texto      := ""
	::Titulo     := ""
	::Origem     := ""
	::DiasDeVida := 0
	::CodAviso   := ""
Return Self


// --------------------------------------------------------------------------
// Serializacao e gravacao em arquivo
METHOD Grava () Class ClsAviso
	local _aAreaAnt  := U_ML_SRArea ()
	local _i         := 0
	local _sPilha    := ""
	local _aCodAvis  := {}
	local _lEnvNAW   := .T.

	if ! ::Tipo $ 'E/A/I'  // [E]rro, [A]viso, [I]nfo
		u_log2 ('erro', "Tipo de aviso invalido: '" + cvaltochar (::Tipo) + "'")
		_lEnvNAW = .F.
	endif

	::DiasDeVida = iif (::DiasDeVida == NIL, iif (::Tipo == 'E', 0, 30), ::DiasDeVida)

	// Tenho alguns grupos ja usados em outros fontes, que ainda preciso pensar
	// em como tratar...
	if upper (alltrim (::DestinAvis)) == 'GRPTI'
		::DestinAvis = 'robert.koch,sandra.sugari,claudia.lionco'
	endif

	if empty (::DestinAvis)  // ateh eliminar o atributo antigo
		::DestinAvis = ::Destinatar
	endif

//	u_log (::Tipo)
//	u_log (::DestinAvis)
//	u_log (::Texto)
	u_log2 (iif (::Tipo == 'E', 'erro', iif (::Tipo == 'A', 'aviso', 'info')), '[' + GetClassName (::Self) + '.' + procname () + ']Notificacao para ' + ::DestinAvis + ': ' + ::Texto)

	if empty (::CodAviso)	
		U_Log2 ('aviso', 'Codigo de aviso nao informado.')
		_lEnvNAW = .F.
	endif

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
	aadd (_aCodAvis, {'014', 'Tamanho chave medicao performance excedido'})
	aadd (_aCodAvis, {'015', 'Problemas para gerar contabilizacao'})
	aadd (_aCodAvis, {'00000000-0000-0000-0000-000000000000', 'testes naweb'})

	if ascan (_aCodAVis, {|_aVal| _aVal [1] == ::CodAviso}) == 0
		u_log2 ('erro', "Codigo de aviso '" + ::CodAviso + "' nao cadastrado na classe " + GetClassName (::Self))
		_lEnvNAW = .F.
	endif

	reclock ("ZAB", .T.)
	zab -> zab_tipo   = ::Tipo
	zab -> zab_destin = ::DestinAvis
	zab -> zab_titulo = ::Titulo
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
	zab -> zab_valid  = ::DiasDeVida
	zab -> zab_codigo = ::CodAviso
	msunlock ()

/*ainda nao
	// Tenta fazer o envio para web service do NaWeb
	if _lEnvNAW  // Se nao tinha algum problema anterior...
		if ::EnviaNaWeb ()
			reclock ("ZAB", .F.)
			zab -> zab_EnvNAW = 'S'
			msunlock ()
		endif
	endif
*/
	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Envia para NaWeb (local padrao de consulta) via web service.
METHOD EnviaNAWeb () Class ClsAviso
	local _lRetWSNA  := .F.
	local _sXMLNotif := ''
	local _oWSNaWeb  := NIL
	U_Log2 ('debug', '[' + procname () + ']Enviando para NaWeb')
	_sXMLNotif := '<SdtNotificacoes>'
	_sXMLNotif +=    '<SdtNotificacoesItem>'
//	_sXMLNotif +=    '<NotifIcone/>'

	_sXMLNotif +=    '<NotifTitulo>' + alltrim (::Titulo) + '</NotifTitulo>'
	_sXMLNotif +=    '<NotifMsg>' + alltrim (::Texto) + '</NotifMsg>'
	_sXMLNotif +=    '<Notifcod>' + ::CodAviso + '</Notifcod>'
//	_sXMLNotif +=    '<NotifData>'
//	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 1, 4) + '-'
//	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 5, 2) + '-'
//	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 7, 2)
//	_sXMLNotif +=       'T' + zab -> zab_hremis
//	_sXMLNotif +=    '</NotifData>'
//	_sXMLNotif +=    '<NotifLink/>'
	_sXMLNotif +=    '<NotifUsuarios>' + ::DestinAvis + '</NotifUsuarios>'
	_sXMLNotif +=    '<NotifHTML/>'
	_sXMLNotif +=    '<NotifRecorrencia>' + cvaltochar (::DiasDeVida) + '</NotifRecorrencia>'
	_sXMLNotif +=    '<NotifTipo>' + ::Tipo + '</NotifTipo>'
	_sXMLNotif +=    '</SdtNotificacoesItem>'
	_sXMLNotif += '</SdtNotificacoes>'
	U_Log2 ('debug', '[' + procname () + ']' + _sxmlNotif)
	_oWSNaWeb := WSPrcNotificacoesWS():New()
	_oWSNaWeb:cEntrada := _sXMLNotif
	_oWSNaWeb:Execute()
	u_log ('retorno:', _oWSNaWeb:cSaida)
return _lRetWSNA


