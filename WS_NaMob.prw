// Programa...: WS_NaMob
// Autor......: Robert Koch (royalties: http://advploracle.blogspot.com.br/2014/09/webservice-no-protheus-parte-2-montando.html)
// Descricao..: Disponibilizacao de Web Services para acesso do sistema NaMob (aplicativo associados)
// Data.......: 10/05/2019
 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #web_service
// #PalavasChave      #web_service #generico #integracoes #namob #acesso_externo
// #TabelasPrincipais #SD1 #SD2 #SD3 #SZE
// #Modulos           #COOP

// Historico de alteracoes:
// 14/05/2019 - Robert - Implementado metodo de consulta de capital social.
// 24/09/2019 - Robert - Implementado metodo de consulta de conta corrente.
// 15/01/2021 - Robert - Acao 'RetTicketCargaSafra' migrada do ws_alianca para ca (preciso acessar das filiais)
// 12/02/2021 - Robert - Novos parametros metodo ClsAssoc:FechSafra() - GLPI 9318
// 08/03/2021 - Robert - Novos parametros metodo ClsAssoc:FechSafra (GLPI 9572)
// 31/01/2022 - Robert - Acao 'RetTicketCargaSafra' removida, pois nao se aplica diretamente a associados.
// 20/02/2022 - Robert - Variavel _sErros renomeada para _sErroWS
//                     - Funcao _ExtraiTag() migrada para U_ExTagXML().
// 18/03/2022 - Robert - Migradas consultas de fech.safra e cota capital para a classe WS_Alianca.
// 21/07/2023 - Robert - Eliminadas linhas comentariadas; removido do projeto.
//

// ------------------------------------------------------------------------------------------------
#include "APWEBSRV.CH"
#include "PROTHEUS.CH"
#include "tbiconn.ch"
#include "VA_INCLU.prw"
#include "totvs.ch"

// Estrutura de retorno de dados
WSSTRUCT RetWSNaMob
	WSDATA Resultado AS String
	WSDATA Mensagens AS String OPTIONAL
ENDWSSTRUCT
// ------------------------------------------------------------------------------------------------
// WebService
WSSERVICE WS_NaMob DESCRIPTION "WS_NaMob_Alianca"
	WSDATA XmlRcv  AS string
	WSDATA Retorno AS RetWSNaMob

	WSMETHOD IntegraWS DESCRIPTION "Executa integracoes conforme tags do XML."
ENDWSSERVICE
//
// --------------------------------------------------------------------------
WSMETHOD IntegraWS WSRECEIVE XmlRcv WSSEND Retorno WSSERVICE WS_NaMob
	local _sError    := ""
	local _sWarning  := ""
	private __cUserId  := ''
	private cUserName  := ''
	private _sWS_Empr  := ""
	private _sWS_Filia := ""
	private _oXML      := NIL
	private _sErroWS  := ""
	private _sMsgRetWS := ""
	private _sAcao     := ""
	private _sArqLog   := GetClassName (::Self) + "_" + dtos (date ()) + ".log"

	u_logIni (GetClassName (::Self) + '.' + procname ())
	u_logDH ()

	// Validacoes gerais e extracoes de dados basicos.
	U_ValReqWS (GetClassName (::Self), ::XmlRcv, @_sErroWS, @_sWS_Empr, @_sWS_Filia, @_sAcao)
	
	// Prepara o ambiente conforme empresa e filial solicitadas.
	if empty (_sErroWS)
		prepare environment empresa _sWS_Empr filial _sWS_Filia
		private __RelDir  := "c:\temp\spool_protheus\"
		set century on
	endif

	// Converte novamente a string recebida para XML, pois a criacao do ambiente parece apagar o XML.
	// Nao vou tratar erros do parser pois teoricamente jah foram tratador na funcao VarReqWS
	if empty (_sErroWS)
		_oXML := XmlParser(::XmlRcv, "_", @_sError, @_sWarning)
	endif
	
	// Executa a acao especificada no XML.
	if empty (_sErroWS)
		u_log ('Acao:', _sAcao)
		//PtInternal (1, _sAcao)
		do case
			case _sAcao == 'ConsultaExtratoCCAssoc'
				_AsExtrCC ()
			otherwise
				_sErroWS += "A acao especificada no XML eh invalida: " + _sAcao
		endcase
	else
		u_log (_sErroWS)
	endif

	// Cria a instância de retorno
	::Retorno := WSClassNew ("RetWSNaMob")
	::Retorno:Resultado = iif (empty (_sErroWS), "OK", "ERRO")
	::Retorno:Mensagens = _sErroWS + _sMsgRetWS
	u_log ('::Retorno:Resultado =', ::Retorno:Resultado)
	u_log ('::Retorno:Mensagens =', ::Retorno:Mensagens)

	u_logFim (GetClassName (::Self) + '.' + procname ())
Return .T.


// --------------------------------------------------------------------------
// Associados - consulta extrato conta corrente.
static function _AsExtrCC ()
	local   _sAssoc    := ""
	local   _sLoja     := ""
	local   _oAssoc    := NIL
	local   _dDataIni  := ctod ('')
	local   _dDataFim  := ctod ('')
	local   _oExtr     := NIL
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	u_logIni ()
	if empty (_sErroWS) ; _sAssoc   = U_ExTagXML ("_oXML:_WSAlianca:_Assoc",   .T., .F.) ; endif
	if empty (_sErroWS) ; _sLoja    = U_ExTagXML ("_oXML:_WSAlianca:_Loja",    .T., .F.) ; endif
	if empty (_sErroWS) ; _dDataIni = U_ExTagXML ("_oXML:_WSAlianca:_DataIni", .T., .T.) ; endif
	if empty (_sErroWS) ; _dDataFim = U_ExTagXML ("_oXML:_WSAlianca:_DataFim", .T., .T.) ; endif

	if empty (_sErroWS)
		_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
		if valtype (_oAssoc) != 'O'
			_sErroWS += "Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto
		endif
	endif
	if empty (_sErroWS)
		_oExtr := ClsExtrCC ():New ()
		_oExtr:Cod_assoc   = _oAssoc:Codigo
		_oExtr:Loja_assoc  = _oAssoc:Loja
		_oExtr:DataIni     = stod (_dDataIni)
		_oExtr:DataFim     = stod (_dDataFim)
		_oExtr:TMIni       = ''
		_oExtr:TMFim       = 'zz'
		_oExtr:LerObs      = .F.
		_oExtr:LerComp3os  = .t.
		_oExtr:TipoExtrato = 'N'
		_oExtr:FormaResult = 'X'  // Quero o resultado em formato XML.
		_oExtr:Gera ()
		u_log (_oExtr:UltMsg)
		u_log ('Extrato retornado:', _oExtr:Resultado)
		if empty (_oExtr:Resultado)
			_sErroWS += "Retorno invalido objeto ExtrCC " + _oAssoc:UltMsg
		else
			_sMsgRetWS = _oExtr:Resultado
		endif
	endif
	u_logFim ()
return
