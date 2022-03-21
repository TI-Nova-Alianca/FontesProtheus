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
//			case _sAcao == 'ConsultaFechamentoSafraAssoc'
//				_AsFecSaf ()
//			case _sAcao == 'ConsultaCapitalSocialAssoc'
//				_AsCapSoc ()
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



/* Migrado para WS_ALIANCA em 18/03/2022
// --------------------------------------------------------------------------
// Associados - consulta capital social.
static function _AsCapSoc ()
	local   _sAssoc    := ""
	local   _sLoja     := ""
	//local   _aCapSoc   := {}
	local   _sRet      := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	u_logIni ()
	if empty (_sErroWS) ; _sAssoc = U_ExTagXML ("_oXML:_WSAlianca:_Assoc", .T., .F.) ; endif
	if empty (_sErroWS) ; _sLoja  = U_ExTagXML ("_oXML:_WSAlianca:_Loja", .T., .F.)  ; endif
	if empty (_sErroWS)
		_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
		if valtype (_oAssoc) != 'O'
			_sErroWS += "Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto
		endif
	endif
	if empty (_sErroWS)
		_sRet = _oAssoc:SldQuotCap (date ()) [.QtCapRetXML]
		if empty (_sRet)
			_sErroWS += "Retorno invalido metodo SldQuotCap " + _oAssoc:UltMsg
		else
			_sMsgRetWS = _sRet
		endif
	endif
	u_logFim ()
return
*/


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



/* Migrado para WS_ALIANCA em 18/03/22
// --------------------------------------------------------------------------
// Associados - consulta fechamento de safra.
static function _AsFecSaf ()
	local   _sAssoc    := ""
	local   _sLoja     := ""
	local   _sSafra    := ""
	local   _oAssoc    := NIL
	local   _sRet      := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	u_logIni ()
	if empty (_sErroWS) ; _sAssoc = U_ExTagXML ("_oXML:_WSAlianca:_Assoc", .T., .F.) ; endif
	if empty (_sErroWS) ; _sLoja  = U_ExTagXML ("_oXML:_WSAlianca:_Loja", .T., .F.)  ; endif
	if empty (_sErroWS) ; _sSafra = U_ExTagXML ("_oXML:_WSAlianca:_Safra", .T., .F.) ; endif
	if empty (_sErroWS)
		_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
		if valtype (_oAssoc) != 'O'
			_sErroWS += "Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto
		endif
	endif
	if empty (_sErroWS)
		//                         _sSafra, _lFSNFE, _lFSNFC, _lFSNFV, _lFSNFP, _lFSPrPg, _lFSRgPg, _lFSVlEf, _lFSResVGM, _lFSFrtS, _lFSLcCC, _lFSResVGC
		_sRet = _oAssoc:FechSafra (_sSafra, .t.,     .t.,     .t.,     .t.,     .t.,      .t.,      .t.,      .t.,        .t.,      .t.,      .f.)
//		_sRet = _oAssoc:FechSafra (_sSafra, .F., .T.)
		if empty (_sRet)
			_sErroWS += "Retorno invalido metodo FechSafra " + _oAssoc:UltMsg
		else
			_sMsgRetWS = _sRet
		endif
	endif
	u_logFim ()
return
*/


/*
// --------------------------------------------------------------------------
static function _ExtraiTag (_sTag, _lObrig, _lValData)
	local _sRet    := ""
	local _lDataOK := .T.
	local _nPos    := 0
	//u_logIni ()
	//u_log ('Procurando tag', _sTag)
	if type (_sTag) != "O"
		if _lObrig
			_sErroWS += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
		if _lValData  // Preciso validar formato da data
			if ! empty (_sRet)
				if len (_sRet) != 8
					_lDataOK = .F.
				else
					for _nPos = 1 to len (_sRet)
						if ! IsDigit (substr (_sRet, _nPos, 1))
							_lDataOK = .F.
							exit
						endif
					next
				endif
				if ! _lDataOK
					_sErroWS += "Data deve ser informada no formato AAAAMMDD"
				endif
			endif
		endif
	endif
	//u_log ('_sRet = ', _sRet)
	//u_logFim ()
return _sRet
*/

/*
// --------------------------------------------------------------------------
// Retorna texto ticket carga safra
static function _RTkCarSaf ()
	local _sSafra    := ''
	local _sBalanca  := ''
	local _sCargaIni := ''
	local _sCargaFim := ''
	local _dDataIni  := ctod ('')
	local _dDataFim  := ctod ('')

	U_Log2 ('info', 'Iniciando ' + procname ())
	if empty (_sErroWS) ; _sSafra    = U_ExTagXML ("_oXML:_WSAlianca:_Safra",                  .T., .F.) ; endif
	if empty (_sErroWS) ; _sBalanca  = U_ExTagXML ("_oXML:_WSAlianca:_Balanca",                .T., .F.) ; endif
	if empty (_sErroWS) ; _sCargaIni = U_ExTagXML ("_oXML:_WSAlianca:_CargaIni",               .T., .F.) ; endif
	if empty (_sErroWS) ; _sCargaFim = U_ExTagXML ("_oXML:_WSAlianca:_CargaFim",               .T., .F.) ; endif
	if empty (_sErroWS) ; _dDataIni  = U_ExTagXML ("_oXML:_WSAlianca:_DataIni",                .T., .T.) ; endif
	if empty (_sErroWS) ; _dDataFim  = U_ExTagXML ("_oXML:_WSAlianca:_DataFim",                .T., .T.) ; endif
	if empty (_sErroWS)
		private _lImpTick  := .T.         // Variavel usada pelo programa de impressao do ticket
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		sze -> (dbseek (xfilial ("SZE") + _sSafra + _sCargaIni, .T.))
		do while ! sze -> (eof ()) .and. sze -> ze_filial == xfilial ("SZE") .and. sze -> ze_safra == _sSafra .and. sze -> ze_carga <= _sCargaFim
			if sze -> ze_status = 'C'
				U_Log2 ('info', 'Carga ' + sze -> ze_carga + ' cancelada; Nao retornarei ticket.')
				sze -> (dbskip ())
				loop
			endif
			if sze -> ze_local != _sBalanca
				U_Log2 ('info', 'Carga ' + sze -> ze_carga + ' foi gerada pela balanca ' + sze -> ze_local + '; Nao retornarei ticket.')
				sze -> (dbskip ())
				loop
			endif
			if sze -> ze_data < stod (_dDataIni) .or. sze -> ze_data > stod (_dDataFim)
				U_Log2 ('info', 'Carga ' + sze -> ze_carga + ' fora do intervalo de datas; Nao retornarei ticket.')
				sze -> (dbskip ())
				loop
			endif
			if ! empty (sze -> ze_ImpTk)
				U_Log2 ('info', 'Carga ' + sze -> ze_carga + ' ticket jah foi impresso; Nao retornarei ticket.')
				sze -> (dbskip ())
				loop
			endif
			_sMsgRetWS = U_va_rusTk (1, '', 1, {}, 'BEMATECH', .t.)

			// Substitui caracteres especiais, pois ficam invalidos no XML
			_sMsgRetWS = strtran (_sMsgRetWS, chr (27), 'chr(27)')
			_sMsgRetWS = strtran (_sMsgRetWS, chr (29), 'chr(29)')
			_sMsgRetWS = strtran (_sMsgRetWS, chr (60), 'chr(60)')
			_sMsgRetWS = strtran (_sMsgRetWS, chr (11), 'chr(11)')


			//DURANTE TESTES. depois a intencao eh retornar varios tickets numa mesma chamada.
			EXIT

			sze -> (dbskip ())
		enddo
	endif
	U_Log2 ('info', 'Finalizando ' + procname ())
Return
*/
