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
// 31/08/2022 - Robert - Desabilitado tratamento de 'codigo de mensagem'.
// 09/09/2022 - Robert - Criado atributo ::DestinZZU.
// 16/09/2022 - Robert - Criado tratamento para enviar HTML para NaWeb.
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
	data Titulo
	data DtAviso
	data HrAviso
	data Destinatar  // soh pra manter compatibilidade com fontes antigos
	data DestinAvis  // Nomes dos usuarios no formato fulano.silva;ciclano.dastantas
	data DestinZZU   // Codigos de um grupo da tabela ZZU no formato {grp1, grp2, ...}
	data Texto
	data Formato     // [T]exto ou [H]tml
	data Origem
	data DiasDeVida
	data CodAviso  // a ser descontinuado

	// Declaração dos Métodos da Classe
	METHOD New ()
	METHOD EnviaNAWeb ()
	METHOD GeraAtrib ()
	METHOD Grava ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New (_nRegZAB) Class ClsAviso

	// Se receber numerico, eh por que se trata do numero de registro do ZA1.
	if valtype (_nRegZAB) == "N"
		ZAB -> (dbgoto (_nRegZAB))
		::GeraAtrib ("ZAB")
	else
		::GeraAtrib ("")
	endif
return Self


// --------------------------------------------------------------------------
// Alimenta os atributos da classe.
METHOD GeraAtrib (_sOrigem) Class ClsAviso
	::Tipo       = ""
	::DtAviso    = date ()
	::HrAviso    = time ()
	::Destinatar = ""
	::DestinAvis = ''
	::DestinZZU  = {}
	::Texto      = ""
	::Formato    = "T"  // Formato padrao: [T]exto
	::Titulo     = ""
	::Origem     = ""
	::DiasDeVida = 1
	if _sOrigem == 'ZAB'
		::Tipo       = zab -> zab_tipo
		::DtAviso    = zab -> zab_dtemis
		::HrAviso    = zab -> zab_hremis
		::DestinAvis = alltrim (zab -> zab_destin)
		::Texto      = alltrim (zab -> zab_texto)
		::Formato    = zab -> zab_format
		::Titulo     = alltrim (zab -> zab_titulo)
		::Origem     = alltrim (zab -> zab_origem)
		::DiasDeVida = zab -> zab_valid
	endif

Return Self


// --------------------------------------------------------------------------
// Serializacao e gravacao em arquivo
METHOD Grava () Class ClsAviso
	local _aAreaAnt  := U_ML_SRArea ()
	local _i         := 0
	local _sPilha    := ""
	local _lEnvNAW   := .T.
	local _nDestZZU  := 0
	local _sDestZZU  := ''

	::Titulo     = iif (empty (::Titulo), ::Texto, ::Titulo)
	::DiasDeVida = iif (::DiasDeVida == NIL, iif (::Tipo == 'E', 90, 30), ::DiasDeVida)

	// Tenho alguns grupos ja usados em outros fontes.
	if upper (alltrim (::DestinAvis)) == 'GRPTI'
		::DestinZZU  = {'122'}
	endif

	// Se recebi uma lista de grupos a notificar, adiciono os usuarios desses grupos.
	if valtype (::DestinZZU) == 'A' //.and. len (::DestinZZU) > 0
//		::DestinAvis = ''
		for _nDestZZU = 1 to len (::DestinZZU)
		//	U_Log2 ('debug', '[' + procname () + ']Verificando grupo ' + ::DestinZZU [_nDestZZU])
			_sDestZZU = U_ZZULD (::DestinZZU [_nDestZZU], cFilAnt, '23') [4]
			if empty (_sDestZZU)
				U_Log2 ('aviso', '[' + procname () + ']Grupo ' + ::DestinZZU [_nDestZZU] + ' nao retornou nenhum destinatario para notificacao.')
			else
				::DestinAvis += iif (empty (::DestinAvis), '', ';') + _sDestZZU
			endif
		next
	//	U_Log2 ('debug', 'Destinatarios ficou assim:' + ::DestinAvis)
	endif

	if ! ::Tipo $ 'E/A/I'  // [E]rro, [A]viso, [I]nfo
		u_log2 ('erro', "Tipo de aviso invalido: '" + cvaltochar (::Tipo) + "'. Nao vou enviar para NaWeb.")
		_lEnvNAW = .F.
	endif

	if ::DiasDeVida <= 0
		u_log2 ('erro', "Dias de vida deve ser um inteiro positivo. Nao vou enviar para NaWeb.")
		_lEnvNAW = .F.
	endif

	u_log2 (iif (::Tipo == 'E', 'erro', iif (::Tipo == 'A', 'aviso', 'info')), '[' + GetClassName (::Self) + '.' + procname () + ']Notificacao para ' + ::DestinAvis + ': ' + ::Texto)

	reclock ("ZAB", .T.)
	zab -> zab_dtemis = ::DtAviso
	zab -> zab_hremis = ::HrAviso
	zab -> zab_tipo   = ::Tipo
	zab -> zab_titulo = ::Titulo
	zab -> zab_texto  = ::Texto
	zab -> zab_format = ::Formato
	zab -> zab_destin = ::DestinAvis
	zab -> zab_valid  = ::DiasDeVida
	if ::Origem == NIL .or. empty (::Origem)
		do while _i <= 5 .and. procname (_i) != ""
			_sPilha += '=>' + procname (_i)
			_i++
		enddo
		zab -> zab_origem = _sPilha
	else
		zab -> zab_origem = ::Origem
	endif
	msunlock ()

	// Tenta fazer o envio para web service do NaWeb
	if _lEnvNAW  // Se nao tinha algum problema anterior...
		::EnviaNaWeb ()
	endif

	U_ML_SRArea (_aAreaAnt)
return


// --------------------------------------------------------------------------
// Envia para NaWeb (local padrao de consulta) via web service.
METHOD EnviaNAWeb () Class ClsAviso
	local _lRetWSNA  := .F.
	local _sXMLNotif := ''
	local _oWSNaWeb  := NIL

	// Alguns caracteres sao invalidos para uso em XML
	::Origem = _Limpa (::Origem)
	::Titulo = _Limpa (::Titulo)
	::Texto  = _Limpa (::Texto)

	U_Log2 ('debug', '[' + procname () + ']Enviando para NaWeb: ' + ::Titulo)

	_sXMLNotif := '<?xml version="1.0" encoding="utf-8"?>'
	_sXMLNotif += '<SdtNotificacoes>'
	_sXMLNotif +=    '<SdtNotificacoesItem>'
	_sXMLNotif +=    '<NotifTipo>' + ::Tipo + '</NotifTipo>'
	_sXMLNotif +=    '<NotifTitulo>' + alltrim (::Titulo) + '</NotifTitulo>'
	if ::Formato == 'H'
		_sXMLNotif += '<NotifHTML>' + alltrim (::Texto) + '</NotifHTML>'
		_sXMLNotif += '<NotifMsg>Mensagem em formato HTML</NotifMsg>'
	else
		_sXMLNotif += '<NotifMsg>' + alltrim (::Texto) + '</NotifMsg>'
	endif
	_sXMLNotif +=    '<NotifData>'
	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 1, 4) + '-'
	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 5, 2) + '-'
	_sXMLNotif +=       substring (dtos (zab -> zab_dtemis), 7, 2)
	_sXMLNotif +=       'T' + zab -> zab_hremis
	_sXMLNotif +=    '</NotifData>'
	_sXMLNotif +=    '<NotifLink/>'
	_sXMLNotif +=    '<NotifUsuarios>' + alltrim (::DestinAvis) + '</NotifUsuarios>'
	_sXMLNotif +=    '<NotifRecorrencia>' + cvaltochar (::DiasDeVida) + '</NotifRecorrencia>'
	_sXMLNotif +=    '<NotifOrigem>' + '[PROTHEUS]' + alltrim (::Origem) + '</NotifOrigem>'
	_sXMLNotif +=    '</SdtNotificacoesItem>'
	_sXMLNotif += '</SdtNotificacoes>'

	U_Log2 ('debug', '[' + procname () + ']' + _sXMLNotif)
	
	_oWSNaWeb := WSPrcNotificacoesWS():New()
	_oWSNaWeb:cEntrada := _sXMLNotif
	_oWSNaWeb:Execute()
	U_Log2 ('debug', '[' + procname () + ']Retorno do NaWeb: ' + _oWSNaWeb:cSaida)

	// Se retornou ok, marca como 'enviado'.
	if _oWSNaWeb:cSaida == 'OK'
		_lRetWSNA = .T.
		reclock ("ZAB", .F.)
		zab -> zab_EnvNAW = 'S'
		msunlock ()
	endif
return _lRetWSNA


// --------------------------------------------------------------------------
// Limpa caracteres que podem atrapalhar no XML
static function _Limpa (_sCampoX)
	_sCampoX = strtran (_sCampoX, '>', '&gt;')
	_sCampoX = strtran (_sCampoX, '<', '&lt;')
	_sCampoX = strtran (_sCampoX, '"', '')  // '&quot;')
	_sCampoX = strtran (_sCampoX, "'", '')  // "&apos;")
//	_sCampoX = strtran (_sCampoX, "&", '')  // "&amp;")
return _sCampoX
