// Programa...: AvisaTI
// Autor......: Robert Koch
// Data.......: 27/08/2008
// Descricao..: Manda um aviso para o setor de TI. Inicialmente, via e-mail.
//
// Historico de alteracoes:
// 28/11/2009 - Robert - Inclui parte da mensagem no campo do assunto.
// 01/07/2009 - Robert - Nao executa no computador de Livramento.
// 25/05/2011 - Robert - Grava mensagem tambem no arquivo de log, caso esteja habilitado.
// 22/09/2014 - Robert - Grava aviso na tabela VA_AVISOS_PARA_TI.
// 03/07/2015 - Robert - Passa a gravar apenas um arquivo texto na pasta do sigaadv (vai ser monitorado via Zabbix).
// 24/08/2015 - Robert - Grava usuario e ambiente.
// 06/05/2016 - Robert - Grava empresa/filial.
// 04/01/2017 - Robert - Formatacao dados adicionais.
// 01/10/2018 - Robert - Gera um arquivo por mes.
// 10/10/2019 - Robert - Inicio gravacao tabela avisos.
// 04/01/2021 - Robert - Nao grava mais em arquivo (nunca foi consultado).
// 31/08/2022 - Robert - Melhoria uso classe ClsAviso.
// 02/10/2022 - Robert - Trocado grpTI por grupo 122 no envio de avisos.
//

// --------------------------------------------------------------------------
user function AvisaTI (_sAviso)
//	local _aAreaAnt  := U_ML_SRArea ()
//	local _aAmbAnt   := U_SalvaAmb ()
	local _oAviso := NIL
	local _sMsg   := ''

	//_sMsg := '[' + dtoc (date ()) + ' ' + time () + ']'
	_sMsg += '[porta/ambiente:' + cvaltochar(GetServerPort ()) + '/' + GetEnvServer () + ']'
	_sMsg += '[username:' + cUserName + ']'
	_sMsg += '[emp/filial:' + cEmpAnt + '/' + cFilAnt + ']'
	//_sMsg += _sAviso
	_sMsg += '[' + _PCham () + ']'
	//_sMsg += chr (13) + chr (10)

	// Caso tenha arquivo de log, grava a mensagem nele tambem.
	U_Log2 ('aviso', procname () + ": " + _sAviso)

	// Ainda em implementacao. Depois pretendemos passar para o NaWeb.
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'E'
	_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
	_oAviso:Titulo     = 'Avisos para TI'
	_oAviso:Texto      = alltrim (_sAviso) + ' ' + _sMsg
	_oAviso:Origem     = procname (1)
	_oAviso:Grava ()

//	U_ML_SRArea (_aAreaAnt)
//	U_SalvaAmb (_aAmbAnt)
return



// --------------------------------------------------------------------------
static Function _PCham ()
	local _i      := 0
	local _sPilha := " Pilha de chamadas: "
	do while procname (_i) != ""
		_sPilha += '=>' + procname (_i)
		_i++
	enddo
return _sPilha
