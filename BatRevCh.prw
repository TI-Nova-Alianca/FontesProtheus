// Programa:   BatRevCh
// Autor:      Robert Koch
// Data:       09/10/2018
// Descricao:  Revalida chaves de XMLs da tabela ZZX.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 07/05/2019 - Robert  - Leitura certificado atualizado.
//                      - Alguns testes de erros de comunicacao. Por fim era a pasta SSO que foi descompactada no appserver.
//                      - Melhorado retorno de mensagens.
//                      - Aceita retorno 150 (autorizada fora do prazo)
//                      - Chaves emitidas ha mais de 180 dias abortavam o restante da verificacao
//                      - Parametro para gerar ou nao logs de depuracao.
//                      - Da preferencia a leitura das chaves nunca validadas.
// 18/06/2019 - Robert  - Removido tratamento de nome de arquivo de log (jah vem pronto da rotina que dispara os batches).
// 02/06/2020 - Claudia - Ajuste conforme GLPI 7950
// 13/07/2020 - Robert  - Inseridas tags para catalogacao de fontes
//                      - Melhorias mensagens de log e de erros.
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #PalavasChave      #batch #XML #chave #NFe #CTe #Revalidacao #auxiliar #uso_generico
// #TabelasPrincipais #ZZX
// #Modulos           #FIS

// --------------------------------------------------------------------------
// Documentacao Totvs: http://tdn.totvs.com/display/tec/Classe+TWsdlManager
// Lista de web services NF-e: http://www.nfe.fazenda.gov.br/PORTAL/WebServices.aspx
// Lista de web services CT-e: http://www.cte.fazenda.gov.br/portal/webservices.aspx
// Exemplos de uso:
// - validar determinada chave                   ---> U_BatRevCh (,,, '35180912855910000135570000000073811000076587')
// - validar determinada chave gerando logs      ---> U_BatRevCh (,,, '35180912855910000135570000000073811000076587', .T.)
// - revalidar chaves dedeterminada UF + layout  ---> U_BatRevCh ('RS', 'NFE', 90, NIL)
// 
user function BatRevCh (_sEstado, _sTipo, _nQtDias, _sChave, _lDebug)
	local _aAreaAnt  := U_ML_SRArea ()
//	local _aAmbAnt   := U_SalvaAmb ()
	local _oWSDL     := NIL
	local _oSQL      := NIL
	local _lContinua := .T.
	local _sCodUF    := ""
	local _sLayout   := ""
	local _sVersao   := ""
	local _sSOAP     := ""
	local _sError    := ''
	local _sWarning  := ''
	local _sAliasQ   := ''
	local _sSoapResp := ""
	private _lWSDL_OK  := .T.  // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	private _nQtReval  := 0    // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	_lDebug := iif (_lDebug == NIL, .F., _lDebug)
	_oBatch:Mensagens = ''
	_oBatch:Retorno   = ''
	
	if _lContinua .and. empty (_sEstado) .and. empty (_sTipo) .and. empty (_sChave)
		u_help ("Informe estado (UF) + tipo (NFE/CTE) ou chave.",, .t.)
	endif
	if _lContinua .and. empty (_sChave) .and. ! empty (_sEstado)
		do case
			case _sEstado == 'RO' ; _sCodUF = '11'
			case _sEstado == 'AC' ; _sCodUF = '12'
			case _sEstado == 'AM' ; _sCodUF = '13'
			case _sEstado == 'RR' ; _sCodUF = '14'
			case _sEstado == 'PA' ; _sCodUF = '15'
			case _sEstado == 'AP' ; _sCodUF = '16'
			case _sEstado == 'TO' ; _sCodUF = '17'
			case _sEstado == 'MA' ; _sCodUF = '21'
			case _sEstado == 'PI' ; _sCodUF = '22'
			case _sEstado == 'CE' ; _sCodUF = '23' // nao conecta
			case _sEstado == 'RN' ; _sCodUF = '24'
			case _sEstado == 'PB' ; _sCodUF = '25'
			case _sEstado == 'PE' ; _sCodUF = '26'
			case _sEstado == 'AL' ; _sCodUF = '27'
			case _sEstado == 'SE' ; _sCodUF = '28'
			case _sEstado == 'BA' ; _sCodUF = '29'
			case _sEstado == 'MG' ; _sCodUF = '31'
			case _sEstado == 'ES' ; _sCodUF = '32'
			case _sEstado == 'RJ' ; _sCodUF = '33'
			case _sEstado == 'SP' ; _sCodUF = '35'
			case _sEstado == 'PR' ; _sCodUF = '41'
			case _sEstado == 'SC' ; _sCodUF = '42'
			case _sEstado == 'RS' ; _sCodUF = '43'
			case _sEstado == 'MS' ; _sCodUF = '50'
			case _sEstado == 'MT' ; _sCodUF = '51'
			case _sEstado == 'GO' ; _sCodUF = '52' // nao conecta
			case _sEstado == 'DF' ; _sCodUF = '53'
			
			otherwise
				u_help ("UF '" + _sEstado + "' desconhecida.",, .t.)
				_lContinua = .F.
		endcase
	endif

	if _lContinua
		// A verificacao de chaves sempre eh feita em cima do arquivo ZZX (preciso dados adicionais dele)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT top 1000 R_E_C_N_O_ AS RECNO, ZZX_CHAVE AS CHAVE, ZZX_VERSAO AS VERSAO, "
		_oSQL:_sQuery +=       " SUBSTRING (ZZX_CHAVE, 1, 2) AS UF,"
		_oSQL:_sQuery +=       " CASE WHEN UPPER(ZZX_LAYOUT) LIKE '%NFE%' THEN 'NFE' ELSE CASE WHEN UPPER(ZZX_LAYOUT) LIKE '%CTE%' THEN 'CTE' ELSE '' END END AS LAYOUT"
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZZX") + " ZZX "
		_oSQL:_sQuery += " WHERE ZZX.D_E_L_E_T_     = ''"
		_oSQL:_sQuery +=   " AND ZZX_CHAVE         != ''"
		_oSQL:_sQuery +=   " AND upper (ZZX_CHAVE) != 'NAO SE APLICA'"
		_oSQL:_sQuery +=   " AND ZZX_LAYOUT != ''"
		if ! empty (_sChave)
			_oSQL:_sQuery += " AND ZZX.ZZX_CHAVE = '" + _sChave + "'"
		else
			// Seleciona chaves precisando de revalidacao periodica
			_oSQL:_sQuery +=   " AND ZZX_VERSAO >= '3'"  // Versao antiga nao valida quando tpEmis=0
			_oSQL:_sQuery +=   " AND ZZX_EMISSA != ''"
	
			// Determinadas UFs nao aceitam mais chaves emitidas ha mais de 6 meses
			_oSQL:_sQuery +=   " AND not (ZZX_CHAVE like '43%' AND DATEDIFF (DAY, CAST (ZZX_EMISSA + ' ' + '00:00' AS DATETIME), GETDATE ()) > 180)"
	
			// Notas emitidas ha muito tempo nao vou mais verificar (caso necessite verificar notas antigas, desabilitar esta validacao).
			_oSQL:_sQuery +=   " AND DATEDIFF (DAY, CAST (ZZX_DTIMP + ' ' + '00:00' AS DATETIME), GETDATE ()) <= " + cvaltochar (_nQtDias)
	
			// Pelo menos algumas horas depois da ultima verificacao.
			_oSQL:_sQuery +=   " AND DATEDIFF (HOUR, CAST (ZZX_DUCC + ' ' + ZZX_HUCC AS DATETIME), GETDATE ()) >= 6"
	
			if ! empty (_sEstado) .and. ! empty (_sTipo)  // Permite agendar um batch para cada UF
				_oSQL:_sQuery += " AND substring (ZZX_CHAVE, 1, 2) = '" + _sCodUF + "'"
				_oSQL:_sQuery += " AND UPPER (ZZX_LAYOUT) LIKE '%" + _sTipo + "%'"
			endif
		endif
//		_oSQL:_sQuery += " ORDER BY UF, ZZX_LAYOUT, ZZX_VERSAO desc"  // Pega as versoes mais novas antes por que provavelmente sejam as mais urgentes

		// Ordena por UF + layout + versao para fazer um unico acesso a cada servico.
		// Dentro disso, inicia pelas chaves nunca validadas e depois pelas emitidas ha mais tempo.
		_oSQL:_sQuery += " ORDER BY UF, ZZX_LAYOUT, ZZX_VERSAO desc, ZZX_DUCC, ZZX_EMISSA"
		if _lDebug
			_oSQL:Log ()
		endif
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
	
		do while ! (_sAliasQ) -> (eof ())
	
			// Quebra por UF / layout / versao por que para cada caso tem um web service diferente.
			_sUF      = (_sAliasQ) -> uf
			_sLayout  = (_sAliasQ) -> layout
			_sVersao  = (_sAliasQ) -> versao
			_lWSDL_OK = .T.
			u_log2 ('info', '---------------------------------------------------------------')
			u_log2 ('info', 'UF: ' + _sUF + ' Layout: ' + _sLayout + ' Versao: ' + _sVersao)
	
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZZ4")
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZZ4_FILIAL = '" + xfilial ("ZZ4") + "'"
			_oSQL:_sQuery +=   " AND ZZ4_NUMUF  = '" + _sUF + "'"
			_oSQL:_sQuery +=   " AND ZZ4_LAYOUT = '" + _sLayout + "'"
			_oSQL:_sQuery +=   " AND ZZ4_VLAYOU = '" + _sVersao + "'"
			_oSQL:_sQuery +=   " AND ZZ4_ATIVO  = 'S'"
			_oSQL:Log ()
			_aRegZZ4 = aclone (_oSQL:Qry2Array ())
			if len (_aRegZZ4) == 0
				u_help ("Sem tratamento (ou inativo) na tabela ZZ4 para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao + ". Query para verificacao: " + _oSQL:_sQuery,, .t.)
				_lWSDL_OK = .F.
				_oBatch:Retorno = 'N'
			elseif len (_aRegZZ4) > 1
				u_help ("Existe mais de um tratamento na tabela ZZ4 para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao + ". Elimine a duplicidade. Query para verificacao: " + _oSQL:_sQuery,, .t.)
				_lWSDL_OK = .F.
				_oBatch:Retorno = 'N'
			else
				zz4 -> (dbgoto (_aRegZZ4 [1, 1]))
				if empty (zz4 -> zz4_wsdl)
					u_help ("Caminho WSDL nao informado para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao,, .t.)
					_lWSDL_OK = .F.
					_oBatch:Retorno = 'N'
				else
	
					// Cria o objeto para acesso ao web service
					_oWSDL := TWsdlManager():New()
					if _lDebug
						// Ao liga o verbose da classe, � exibido no console do Application Server, mas n�o gravados no arquivo console.log, algumas informa��es sobre headers que s�o enviados.
						// Dessa maneira, ser� criado na mesma pasta em que se encontra o TOTVS Application Server o arquivo request.log, que cont�m as mensagens que s�o enviadas ao servidor, e o arquivo response.log, que cont�m as mensagens que s�o recebidas do servidor.
						// https://tdn.totvs.com/pages/viewpage.action?pageId=189313583
						// nao fez diferenca --> _oWsdl:lVerbose := .F.
					endif
					_oWSDL:nTimeout := 30  // tempo em segundos para aguardar envio e recebimento de mensagens SOAP
					  
					// http://tdn.totvs.com/display/tec/Acesso+a+Web+Services+que+exigem+certificados+de+CA
					// http://tdn.totvs.com/pages/viewpage.action?pageId=223932805

					// Usa os mesmos arquivos de certificados do TSS
//					_oWSDL:cSSLCACertFile := "\certs\000021_ca.pem"
//					_oWSDL:cSSLCertFile   := "\certs\000021_cert.pem"
//					_oWSDL:cSSLKeyFile    := "\certs\000021_key.pem"

					_oWSDL:cSSLCACertFile := "\\192.168.1.3\siga\TSS\certs\000021_ca.pem"
					_oWSDL:cSSLCertFile   := "\\192.168.1.3\siga\TSS\certs\000021_cert.pem"
					_oWSDL:cSSLKeyFile    := "\\192.168.1.3\siga\TSS\certs\000021_key.pem"

					_oWsdl:lSSLInsecure   := .T.

					_oWSDL:ParseURL (alltrim (zz4 -> zz4_wsdl))
					if len (_oWSDL:ListOperations()) == 0
						u_help ("Erro na consulta WSDL. Confira o certificado digital e/ou tente novamente mais tarde. " + _oWSDL:cError,, .t.)
						u_log2 ('debug', 'URL: ' + alltrim (zz4 -> zz4_wsdl))
//						u_log2 ('debug', _oWSDL:ListOperations())
						_lWSDL_OK = .F.
						_oBatch:Retorno = 'N'
					else
						if empty (zz4 -> zz4_SOper)
							u_help ("Sem definicao de operacao SOAP na tabela ZZ4.",, .t.)
							_lWSDL_OK = .F.
							_oBatch:Retorno = 'N'
						else
							if ! _oWSDL:SetOperation (alltrim (zz4 -> zz4_SOper))
								u_help ("Erro definicao operacao do WSDL para layout " + zz4 -> zz4_layout + ":" + _oWSDL:cError,, .t.)
								u_log2 ('debug', 'Operacao: ' + alltrim (zz4 -> zz4_SOper))
								_lWSDL_OK = .F.
								_oBatch:Retorno = 'N'
							endif
						endif
					endif
				endif
			endif
	
			// Varre as chaves desta UF / layout / versao
			do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> UF == _sUF .and. (_sAliasQ) -> layout == _sLayout .and. (_sAliasQ) -> versao == _sVersao 
				if _lWSDL_OK
	
					// Deixa ZZX posicionado para receber o retorno da consulta
					zzx -> (dbgoto ((_sAliasQ) -> recno))
					if zzx -> zzx_emissa < (date () - 180)
						u_help ("Chave " + zzx -> zzx_chave + " emitida em " + dtoc (zzx -> zzx_emissa) + " (ha mais de 180 dias): nao sera mais verificada pelos web services.")
						(_sAliasQ) -> (dbskip ())
						loop
					endif

				/* aguarda atualizar build da base quente
					// Testa chaves muito antigas para algumas UF que jah sei que nao aceitam mais.
				//	u_log2 ('debug', left (dtos (zzx -> zzx_emissa), 6))
				//	u_log2 ('debug', ClsDUtil():SubtrMes (left (dtos (date ()), 6), 5))
					if left (zzx -> zzx_chave, 2) == '35' .and. left (dtos (zzx -> zzx_emissa), 6) < ClsDUtil ():SubtrMes (left (dtos (date ()), 6), 5) // SP maximo 5 meses
						u_help ("Chave " + zzx -> zzx_chave + " emitida em " + dtoc (zzx -> zzx_emissa) + ": web service desta UF nao valida mais.")
						(_sAliasQ) -> (dbskip ())
						loop
					endif
					*/

					// Monta pacote SOAP
					_sSOAP := '<?xml version="1.0" encoding="utf-8"?>'
					_sSOAP += alltrim (zz4 -> zz4_SEnvel)
					_sSOAP += '<soap:Header>'
					_sSoap +=    alltrim (zz4 -> zz4_ACabMs)
					if zz4 -> zz4_layout == 'NFE'
						_sSoap +=       '<versaoDados>' + zz4 -> zz4_vLayou + '</versaoDados>'
						_sSoap +=       '<cUF>' + zz4 -> zz4_numUF + '</cUF>'
					elseif zz4 -> zz4_layout == 'CTE'
						_sSoap +=       '<ctec:cUF>' + zz4 -> zz4_numUF + '</ctec:cUF>'
						_sSoap +=       '<ctec:versaoDados>' + zz4 -> zz4_vLayou + '</ctec:versaoDados>'
					endif
					_sSoap +=    alltrim (zz4 -> zz4_FCabMs)
					_sSOAP += '</soap:Header>'
					_sSOAP += '<soap:Body>
					_sSoap += alltrim (zz4 -> zz4_adadm)
					if zz4 -> zz4_layout == 'NFE'
						_sSoap +=    '<consSitNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + alltrim (zz4 -> zz4_vLayou) + '">'
					elseif zz4 -> zz4_layout == 'CTE'
						_sSoap +=    '<consSitCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="' + alltrim (zz4 -> zz4_vLayou) + '">'
					endif
					_sSoap +=       '<tpAmb>1</tpAmb>'
					_sSoap +=       '<xServ>CONSULTAR</xServ>'
					if zz4 -> zz4_layout == 'NFE'
						_sSoap +=    '<chNFe>' + alltrim (zzx -> zzx_chave) + '</chNFe>'
						_sSoap +=    '</consSitNFe>'
					elseif zz4 -> zz4_layout == 'CTE'
						_sSoap +=    '<chCTe>' + alltrim (zzx -> zzx_chave) + '</chCTe>'
						_sSoap +=    '</consSitCTe>'
					endif
					_sSoap += alltrim (zz4 -> zz4_fdadm)
					_sSoap += '</soap:Body></soap:Envelope>'
	
					// Envia a mensagem SOAP ao servidor
					if _lDebug


						if date () == stod ('20200911')  // aoh hoje - teste com SOAP gerado pelo SoapUI
							u_log ('aviso', 'fazendo alteracoes manuais para testes')
							_sSOAP = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2"><versaoDados>4.00</versaoDados><cUF>31</cUF></nfeCabecMsg></soap:Header><soap:Body><nfec:nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsulta2" xmlns:nfec="http://www.portalfiscal.inf.br/nfe/wsdl/NFeConsultaProtocolo4"><consSitNFe versao="4.00" xmlns="http://www.portalfiscal.inf.br/nfe"><tpAmb>1</tpAmb><xServ>CONSULTAR</xServ><chNFe>31200302363425000433550010000003021159871670</chNFe></consSitNFe></nfec:nfeDadosMsg></soap:Body></soap:Envelope>'
							// nao fez diferenca -->_oWSDL:lProcResp = .F.
							// retornou vazio --> u_log2 ('debug', _oWSDL:GetWSDLDoc ())
						endif


						u_log2 ('debug', 'Enviando SOAP: ' + _sSOAP)
					endif
					if ! _oWSDL:SendSoapMsg(_sSOAP)
						u_help ("Erro envio soap: " + _oWSDL:cError,, .t.)
						// esta vindo vazio --> u_log2 ('erro', 'Atributo cFaultCode...: ' + cvaltochar (_oWSDL:cFaultCode))
						// esta vindo vazio --> u_log2 ('erro', 'Atributo cFaultSubCode: ' + cvaltochar (_oWSDL:cFaultSubCode))
						// esta vindo vazio --> u_log2 ('erro', 'Atributo cFaultString.: ' + cvaltochar (_oWSDL:cFaultString))
						// esta vindo vazio --> u_log2 ('erro', 'Atributo cFaultActor..: ' + cvaltochar (_oWSDL:cFaultActor))
						_oBatch:Retorno = 'N'
					endif
			 
					// Pega a mensagem de resposta
					_sSoapResp = _oWSDL:GetSoapResponse()
					if _lDebug
						u_log2 ('debug', 'URL: ' + alltrim (zz4 -> zz4_wsdl))
						U_LOG2 ('debug', 'SOAP response: ' + _sSoapResp)
					endif
					 
					// Leitura da mensagem de retorno.
					if empty (_sSoapResp)
						u_help ("Retorno vazio para o pacote SOAP",, .t.)
						_lWSDL_OK = .F.
						loop
						_oBatch:Retorno = 'N'
					else
//						_oXMLRet := XmlParser(strtran(strtran (_sSoapResp, 'soap:', ''),'env:', ''), "_", @_sError, @_sWarning )
						_sSoapResp = strtran (_sSoapResp, 'soapenv:', '')
						_sSoapResp = strtran (_sSoapResp, 'env:', '')
						_sSoapResp = strtran (_sSoapResp, 'soap:', '')
						_oXMLRet := XmlParser(_sSoapResp, "_", @_sError, @_sWarning )
						if ! empty (_sError) .or. ! empty (_sWarning)
							u_help ("Erro ao decodificar retorno: " + _sError + _sWarning + '    SOAP response: ', _sSoapResp, .t.)
							_lWSDL_OK = .F.
							loop
							_oBatch:Retorno = 'N'
						else
		
							// Interpreta e da tratamento ao retorno do web service.
							_TrataRet (_lDebug)

						endif
						//u_logFim (zzx -> zzx_chave)
					endif
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	_oBatch:Mensagens += iif (empty (_oBatch:Mensagens), '', '; ') + cvaltochar (_nQtReval) + ' chaves verificadas'
	if empty (_oBatch:Retorno)
		_oBatch:Retorno = 'S'
	endif
//	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_log2 ('info', 'Finalizando execucao ' + procname ())
Return



// --------------------------------------------------------------------------
// Interpreta e da tratamento ao retorno do web service.
static function _TrataRet (_lDebug)
	local _sRetChv   := ''
	local _sRetStat  := ''
	local _sRetPrAut := ''
	local _sRetPrCan := ''
	local _sRetEvCan := ''
	local _sRetMsg   := ''
	local _lAtuZZX   := .T.
	local _oEvtCanc  := NIL
	local _nEvtCanc  := 0
	
	// Extrai tags basicas (presentes em todos os XML)
	_sRetStat = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRStat) + ':TEXT')
	_sRetMsg  = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRMsg)  + ':TEXT')
	if _lDebug
		u_log2 ('debug', 'Status................: ' + _sRetStat)
		u_log2 ('debug', 'Mensagem..............: ' + _sRetMsg)
	endif
	// Extrai tags especificas, de acordo com o status retornado.
	if _sRetStat $ '656/678'         // Uso indevido
		u_log2 ('aviso', 'Servico retornou mensagem de uso indevido. Tente esta UF mais tarde.')
		u_help ('Servico retornou mensagem de uso indevido. Tente esta UF mais tarde.')
		_lWSDL_OK = .F.
		_lAtuZZX = .F.
//	elseif _sRetStat $ '587/731'  // Tags erradas, chave muito antiga, etc.
	elseif _sRetStat $ '587/731/526'  // Tags erradas, chave muito antiga, etc.
		u_help (_sRetMsg)
		_lAtuZZX = .F.
	else
		if _sRetStat $ '100/150'  // Autorizada (100) ou autorizada fora do prazo por ter sido emitida em contingencia (150)
			_sRetChv  = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRChAu)  + ':TEXT')
			_sRetPrAut = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRPrAu) + ':TEXT')
			if _lDebug
				u_log2 ('debug', 'Chave (autorizada)......: ' + _sRetChv)
				u_log2 ('debug', 'Protocolo autorizacao...: ' + _sRetPrAut)
			endif
		
		elseif _sRetStat == '101'  // Cancelada

			// Leitura dos eventos vinculados: pode estar em formato de array, caso tenha mais de um evento.
			_oEvtCanc = &('_oXmlRet:' + alltrim (zz4 -> zz4_TEvCan))
			if valtype (_oEvtCanc) == 'O'  // Tem apenas um evento
				_sRetChv  = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TRChCa)  + ':TEXT')
			//	if _lDebug
					u_log2 ('aviso', 'Chave (cancelada).......: ' + _sRetChv)
			//	endif
				_sRetEvCan = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TREvCa) + ':TEXT')
				if _sRetEvCan != '110111'
					u_help ("Status de cancelamento (" + _sRetStat + "), mas evento (" + _sRetEvCan + ") nao corresponde.",, .t.)
					_lAtuZZX = .F.
				else
					_sRetPrCan = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TRPrCa) + ':TEXT')
					if _lDebug
						u_log2 ('aviso', 'Protocolo cancelamento: ' + _sRetPrCan)
					endif
				endif
			else
				_lAtuZZX = .F.
				for _nEvtCanc = 1 to len (_oEvtCanc)  // Tem mais de um evento
					//u_logIni ('Evento ' + cvaltochar (_nEvtCanc))
					_sRetChv  = &('_oEvtCanc [' + cvaltochar (_nEvtCanc) + ']:' + alltrim (zz4 -> zz4_TRChCa)  + ':TEXT')
					if _lDebug
						u_log2 ('aviso', 'Chave (evt.cancelamento): ' + _sRetChv)
					endif
					_sRetEvCan = &('_oEvtCanc [' + cvaltochar (_nEvtCanc) + ']:' + alltrim (zz4 -> zz4_TREvCa) + ':TEXT')
					if _sRetEvCan == '110111'  // Se for um evento de cancelamento, nem preciso olhar os demais.
						_sRetPrCan = &('_oEvtCanc [' + cvaltochar (_nEvtCanc) + ']:' + alltrim (zz4 -> zz4_TRPrCa) + ':TEXT')
						if _lDebug
							u_log2 ('aviso', 'Protocolo cancelamento: ' + _sRetPrCan)
						endif
						_lAtuZZX = .T.
						exit
					else
						if _lDebug
							u_log2 ('debug', "Evento (" + _sRetEvCan + ") nao eh cancelamento.")
						endif
					endif
					//u_logFim ('Evento ' + cvaltochar (_nEvtCanc))
				next
			endif
		endif

		// Para ter certeza, confiro consistencia entre chave, protocolos, etc.
		if _sRetChv != zzx -> zzx_chave
			u_help ("Retorno veio para outra chave (" + _sRetChv + ")",, .t.)
			_lAtuZZX = .F.
			_oBatch:Retorno = 'N'
		endif
		if _sRetStat $ '100/150' .and. empty (_sRetPrAut)
			u_help ("Nao consegui ler protocolo de autorizacao.",, .t.)
			_lAtuZZX = .F.
			_oBatch:Retorno = 'N'
		elseif _sRetStat == '101' .and. empty (_sRetPrCan) 
			u_help ("Nao consegui ler protocolo de cancelamento.",, .t.)
			_lAtuZZX = .F.
			_oBatch:Retorno = 'N'
		endif
	endif


	if _lAtuZZX
		if _lDebug .or. zzx -> zzx_retsef != _sRetStat
			u_log2 ('info', 'Atualizando status da chave ' + zzx -> zzx_chave + ' na tabela ZZX: ' + zzx -> zzx_retsef + ' ==> ' + _sRetStat)
		endif
		_nQtReval ++
		reclock ("ZZX", .F.)
		zzx -> zzx_dpcc   = zzx -> zzx_ducc
		zzx -> zzx_ducc   = date ()
		zzx -> zzx_hucc   = left (time (), 5)
		zzx -> zzx_retsef = _sRetStat
		zzx -> zzx_protoc = _sRetPrAut
		msunlock ()
	endif
return