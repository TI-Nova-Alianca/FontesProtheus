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
//

// --------------------------------------------------------------------------
user function AvisaTI (_sAviso)
	//local _oSQL := NIL
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _sArqAviso := "Avisos_para_TI_" + left (dtos (date ()), 6) + ".txt"
	local _nHdl      := 0
	local _oAviso    := NIL

	_sMsg := '[' + dtoc (date ()) + ' ' + time () + ']'
	_sMsg += '[' + cvaltochar(GetServerPort ()) + '/' + GetEnvServer () + ']'
	_sMsg += '[' + cUserName + ']'
	_sMsg += '[' + cEmpAnt + '/' + cFilAnt + ']'
	_sMsg += _sAviso
	_sMsg += _PCham ()
	_sMsg += chr (13) + chr (10)

	if file (_sArqAviso)
		_nHdl = fopen(_sArqAviso, 1)
	else
		_nHdl = fcreate(_sArqAviso, 0)
	endif
	fseek (_nHdl, 0, 2)  // Encontra final do arquivo
	fwrite (_nHdl, _sMsg)
	fclose (_nHdl)

	// Caso tenha arquivo de log, grava a mensagem nele tambem.
	U_Log (procname () + ": " + _sMsg)

	// Ainda em implementacao. Depois pretendemos passar para o NaWeb.
	//U_GrvAviso ('E', 'robert.koch', _sAviso, procname (1) + '==>' + procname (2), 0)
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'E'
	_oAviso:Destinatar = 'grpTI'
	_oAviso:Texto      = _sAviso
	_oAviso:Grava ()

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
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
