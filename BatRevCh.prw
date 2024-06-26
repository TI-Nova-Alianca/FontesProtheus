// Programa:   BatRevCh
// Autor:      Robert Koch
// Data:       09/10/2018
// Descricao:  Revalida chaves de XMLs da tabela ZZX.
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Revalida chaves de XMLs da tabela ZZX.
// #PalavasChave      #batch #XML #chave #NFe #CTe #Revalidacao #auxiliar #uso_generico
// #TabelasPrincipais #ZZX
// #Modulos           #FIS

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
// 15/10/2020 - Robert  - Passa a ler lista de chaves a revalidar a partir da view VA_VDFES_A_REVALIDAR (para ter consistencia com PowerShell e Zabbix)
//                      - Melhoria nos logs e mensagens de retorno.
//                      - Deixa de gravar campo ZZX_DPCC (vai ser eliminado)
//                      - Passa a gravar protocolo de cancelamento (criado campo zzx_prtcan).
// 01/02/2021 - Robert  - Ajuste leitura retorno CTe do MS (GLPI 9196)
// 20/07/2022 - Robert  - Gravacao de eventos temporarios para rastreio de movimentacao dos XML (GLPI 12336)
// 28/07/2022 - Robert  - Nao considerava parametro _nQtDias (reprocessava sempre 90 dias) - GLPI 12384
//                      - Melhorada ordenacao (preferencia para chaves nunca revalidadas)
//                      - Nao revalida mais as chaves jah marcadas como 'canceladas pelo emitente'
// 13/11/2023 - Robert  - MG (UF31) passa a mandar 'S:' na tag <S:ENVELOPE> no XML de retorno.
// 14/11/2023 - Robert  - Muda nome do arquivo de log cfe. UF e layout.
//                      - Gera aviso para TI caso encontre layout sem definicao na tabela ZZ4.
// 17/11/2023 - Robert  - Criado tratamento para codigos de retorno 217 e 613.
// 06/12/2023 - Robert  - Grava tipo e estado junto nas mensagens de aviso.
// 03/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 03/06/2024 - Robert  - Nao testava se tem tag de protocolo de autorizacao no retorno da SEFAZ.
//

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
	local _oWSDL     := NIL
	local _oSQL      := NIL
	local _lContinua := .T.
//	local _sCodUF    := ""
	local _sLayout   := ""
	local _sVersao   := ""
	local _sSOAP     := ""
	local _sError    := ''
	local _sWarning  := ''
	local _sAliasQ   := ''
	local _sSoapResp := ""
	local _oEvento   := NIL
	private _lWSDL_OK  := .T.  // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	private _nQtAReval  := 0    // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	private _nQtReval  := 0    // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	private _sTxtEvt := ''    // Deixar PRIVATE para a rotina de interpretacao do retorno poder alterar.
	_lDebug := iif (_lDebug == NIL, .F., _lDebug)
	_oBatch:Mensagens = ''
	_oBatch:Retorno   = ''

	// Como o log fica extenso e tenho muitas chaves e muitas UF a verificar,
	// prefiro trabalhar com logs separados.
	U_MudaLog (procname () + '_' + cvaltochar (_sEstado) + '_' + cvaltochar (_sTipo) + '.log')

	//_nQtDias = iif (_nQtDias == NIL, 0, _nQtDias)

	if _lContinua .and. empty (_sEstado) .and. empty (_sTipo) .and. empty (_sChave)
		_Evento ("ERRO: Informe estado (UF) + tipo (NFE/CTE) ou chave.", .T., .f., '', '')
	endif

	if _lContinua
		// A verificacao de chaves sempre eh feita em cima do arquivo ZZX (preciso dados adicionais dele)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT R_E_C_N_O_ AS RECNO, ZZX_CHAVE AS CHAVE, ZZX_VERSAO AS VERSAO"
		_oSQL:_sQuery +=      ", SUBSTRING (ZZX_CHAVE, 1, 2) AS UF"
		_oSQL:_sQuery +=      ", CASE WHEN UPPER(ZZX_LAYOUT) LIKE '%NFE%' THEN 'NFE' ELSE CASE WHEN UPPER(ZZX_LAYOUT) LIKE '%CTE%' THEN 'CTE' ELSE '' END END AS LAYOUT"

		// Se recebi uma chave especifica, busco direto no ZZX por que pode
		// estar sendo desconsiderada pela view (por motivo de data, etc.)
		if ! empty (_sChave)
			_oSQL:_sQuery += " FROM " + RetSQLName ("ZZX") + " ZZX "
			_oSQL:_sQuery += " WHERE ZZX.D_E_L_E_T_     = ''"
			_oSQL:_sQuery += " AND ZZX_CHAVE = '" + _sChave + "'"
		else
			_oSQL:_sQuery += " FROM VA_VDFES_A_REVALIDAR"
			_oSQL:_sQuery += " WHERE "
			
			// Somente doctos emitidos nos ultimos N dias
			_oSQL:_sQuery += " ZZX_EMISSA >= '" + dtos (date () - _nQtDias) + "'"
			
			// Pelo menos algumas horas entre uma revalidacao e outra
			_oSQL:_sQuery += " AND (HORAS_DESDE_ULTIMA_REVALIDACAO >= 24 OR ZZX_RETSEF = '' OR ZZX_PROTOC = '')"
			
//clausula passada para a view VA_VDFES_A_REVALIDAR			// Se jah consta como cancelada (e com protocolo
//clausula passada para a view VA_VDFES_A_REVALIDAR			// de cancelamento), nem revalido mais.
//clausula passada para a view VA_VDFES_A_REVALIDAR			_oSQL:_sQuery +=  " AND NOT (ZZX_RETSEF = '101' AND ZZX_PRTCAN != '')"
			
//			if ! empty (_sCodUF)  // Permite agendar um batch para cada UF
//				_oSQL:_sQuery += " AND substring (ZZX_CHAVE, 1, 2) = '" + _sCodUF + "'"
//			endif
			if ! empty (_sEstado)  // Permite agendar um batch para cada UF
				_oSQL:_sQuery += " AND SIGLA = '" + _sEstado + "'"
			endif
			if ! empty (_sTipo)  // Permite agendar um batch para cada tipo (CTe/NFe/...)
				_oSQL:_sQuery += " AND UPPER (ZZX_LAYOUT) LIKE '%" + _sTipo + "%'"
			endif
		endif

		// Como faz uma conexao ao web service da UF e valida todas as chaves
		// nessa mesma conexao, a ordenacao principal vai ser por UF.
		_oSQL:_sQuery += " ORDER BY substring (ZZX_CHAVE, 1, 2)"
		
		// Apesar de ser um web service para cada tipo e versao de documento,
		// preciso dar preferencia para as chaves que nunca foram revalidadas,
		// ou que foram revalidadas ha mais tempo. Se a cada execucao do batch
		// eu tivesse certeza de que todas foram revalidadas, nao precisaria...
		_oSQL:_sQuery +=          " ,ZZX_DUCC "
		
		// Continua com a ordenacao por layout, pois tem um web service
		// para cada tipo de documento.
		_oSQL:_sQuery +=          " ,ZZX_LAYOUT"
		
		// Mais uma ultima ordenacao incluindo a chave, para facilitar
		// comparativos entre logs de execucao, por exemplo quando preciso
		// executar varias vezes uma mesma sequencia, durante desenvolvimento.
		_oSQL:_sQuery +=          " ,ZZX_VERSAO desc, ZZX_EMISSA, ZZX_CHAVE"
		
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		count to _nQtAReval
		u_log2 ('info', cvaltochar (_nQtAReval) + " chaves a verificar")
		(_sAliasQ) -> (dbgotop ())
		do while ! (_sAliasQ) -> (eof ())
	
			// Quebra por UF / layout / versao por que para cada caso tem um web service diferente.
			_sUF      = (_sAliasQ) -> uf
			_sLayout  = (_sAliasQ) -> layout
			_sVersao  = (_sAliasQ) -> versao
			_lWSDL_OK = .T.
			u_log2 ('info', '---------------------------------------------------------------')
			u_log2 ('info', 'UF: ' + _sUF + ' ' + cvaltochar (_sEstado) + ' Layout: ' + _sLayout + ' Versao: ' + _sVersao)
	
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
			_aRegZZ4 = aclone (_oSQL:Qry2Array (.f., .f.))
			if len (_aRegZZ4) == 0
				_Evento ("ERRO: Sem tratamento (ou inativo) na tabela ZZ4 para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao + ". Query para verificacao: " + _oSQL:_sQuery, .T., .t., _sEstado, _sTipo)
				_lWSDL_OK = .F.
				_oBatch:Retorno = 'N'
			elseif len (_aRegZZ4) > 1
				_Evento ("ERRO: Existe mais de um tratamento na tabela ZZ4 para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao + ". Elimine a duplicidade. Query para verificacao: " + _oSQL:_sQuery, .T., .t., _sEstado, _sTipo)
				_lWSDL_OK = .F.
				_oBatch:Retorno = 'N'
			else
				zz4 -> (dbgoto (_aRegZZ4 [1, 1]))
				if empty (zz4 -> zz4_wsdl)
					_Evento ("ERRO: Caminho WSDL nao informado para UF/layout/versao " + _sUF + "/" + _sLayout + "/" + _sVersao, .T., .t., _sEstado, _sTipo)
					_lWSDL_OK = .F.
					_oBatch:Retorno = 'N'
				else
					U_LOG2 ('INFO', 'Criando objeto WSDL para ' + zz4 -> zz4_wsdl)

					// Cria o objeto para acesso ao web service
					_oWSDL := TWsdlManager():New()
					if _lDebug
						// Ao ligar o verbose da classe, � exibido no console do Application Server, mas n�o gravados no arquivo console.log, algumas informa��es sobre headers que s�o enviados.
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

					U_LOG2 ('INFO', 'Realizando parse --> ' + zz4 -> zz4_wsdl)
					_oWSDL:ParseURL (alltrim (zz4 -> zz4_wsdl))
					if _lDebug
						U_Log2 ('debug', 'Parse finalizado')
					endif
					if len (_oWSDL:ListOperations()) == 0
						_Evento ("ERRO na consulta WSDL. Confira o certificado digital e/ou tente novamente mais tarde. " + _oWSDL:cError, .T., .f., _sEstado, _sTipo)
						_lWSDL_OK = .F.
						_oBatch:Retorno = 'N'
					else
						if empty (zz4 -> zz4_SOper)
							_Evento ("ERRO: Sem definicao de operacao SOAP na tabela ZZ4.", .T., .t., _sEstado, _sTipo)
							_lWSDL_OK = .F.
							_oBatch:Retorno = 'N'
						else
							if ! _oWSDL:SetOperation (alltrim (zz4 -> zz4_SOper))
								_Evento ("ERRO na definicao de operacao do WSDL para layout " + zz4 -> zz4_layout + ":" + _oWSDL:cError, .T., .f., _sEstado, _sTipo)
								_lWSDL_OK = .F.
								_oBatch:Retorno = 'N'
							endif
						endif
					endif
				endif
			endif
	
			// Varre as chaves desta UF / layout / versao
			do while ! (_sAliasQ) -> (eof ()) ;
				.and. (_sAliasQ) -> UF == _sUF ;
				.and. (_sAliasQ) -> layout == _sLayout ;
				.and. (_sAliasQ) -> versao == _sVersao
			//	.and. _lWSDL_OK

				if _lWSDL_OK
	
					// Deixa ZZX posicionado para receber o retorno da consulta
					zzx -> (dbgoto ((_sAliasQ) -> recno))
					if zzx -> zzx_emissa < (date () - 90)  //180)
						u_help ("Chave " + zzx -> zzx_chave + " emitida em " + dtoc (zzx -> zzx_emissa) + " (muito antiga): nao sera mais verificada pelos web services.")
						(_sAliasQ) -> (dbskip ())
						loop
					endif

					U_Log2 ('info', '[' + procname () + '](' + cvaltochar (_nQtReval) + ' de ' + cvaltochar (_nQtAReval) + ') Verificando ' + zzx -> zzx_layout + ' ' + zzx -> zzx_chave)

					// Monta pacote SOAP
					_sSOAP := '<?xml version="1.0" encoding="utf-8"?>'
					_sSOAP += alltrim (zz4 -> zz4_SEnvel)
					_sSOAP += '<soap:Header>'
					_sSoap +=    alltrim (zz4 -> zz4_ACabMs)
					if zz4 -> zz4_layout == 'NFE'
//						_sSoap +=       '<versaoDados>' + zz4 -> zz4_vLayou + '</versaoDados>'
						_sSoap +=       '<versaoDados>' + zz4 -> zz4_VerDad + '</versaoDados>'
						_sSoap +=       '<cUF>' + zz4 -> zz4_numUF + '</cUF>'
					elseif zz4 -> zz4_layout == 'CTE'
						_sSoap +=       '<ctec:cUF>' + zz4 -> zz4_numUF + '</ctec:cUF>'
//						_sSoap +=       '<ctec:versaoDados>' + zz4 -> zz4_vLayou + '</ctec:versaoDados>'
						_sSoap +=       '<ctec:versaoDados>' + zz4 -> zz4_VerDad + '</ctec:versaoDados>'
					endif
					_sSoap +=    alltrim (zz4 -> zz4_FCabMs)
					_sSOAP += '</soap:Header>'
					_sSOAP += '<soap:Body>
					_sSoap += alltrim (zz4 -> zz4_adadm)
					if zz4 -> zz4_layout == 'NFE'
//						_sSoap +=    '<consSitNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + alltrim (zz4 -> zz4_vLayou) + '">'
						_sSoap +=    '<consSitNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="' + alltrim (zz4 -> zz4_VerDad) + '">'
					elseif zz4 -> zz4_layout == 'CTE'
//						_sSoap +=    '<consSitCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="' + alltrim (zz4 -> zz4_vLayou) + '">'
						_sSoap +=    '<consSitCTe xmlns="http://www.portalfiscal.inf.br/cte" versao="' + zz4 -> zz4_VerDad + '">'


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
						u_log2 ('debug', 'Enviando SOAP: ' + _sSOAP)
					endif
					
					// Apesar de acusar erro, parece que a operacao prossegue.
					if ! _oWSDL:SendSoapMsg(_sSOAP)
						u_log2 ('aviso', "Erro metodo SendSoapMsg: " + _oWSDL:cError)
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
						_Evento ("ERRO: Retorno vazio para o pacote SOAP", .T., .f., _sEstado, _sTipo)
						_lWSDL_OK = .F.
						loop
						_oBatch:Retorno = 'N'
					else
						_sSoapResp = strtran (_sSoapResp, 'soapenv:', '')
						_sSoapResp = strtran (_sSoapResp, 'env:', '')
						_sSoapResp = strtran (_sSoapResp, 'soap:', '')

						// Peguei caso da tag ENVELOPE vir com S: na frente. Ex.: <S:Envelope [..]>
						// Nao sei se isso ocorre noutras UF. por enquanto notei apenas em alguns.
						if (_sUF == 'MS' .and. _sTipo == 'CTE') .or. _sUF == '31'
							if _lDebug
								U_Log2 ('debug', '[' + procname () + ']_sUF: ' + _sUF)
								U_LOG2 ('debug', 'Removendo S: do retorno SOAP response, antes de mandar ao parser: ' + _sSoapResp)
							endif
							_sSoapResp = strtran (_sSoapResp, 'S:', '')
						endif

						_oXMLRet := XmlParser(_sSoapResp, "_", @_sError, @_sWarning )
						if ! empty (_sError) .or. ! empty (_sWarning)
							_Evento ("ERRO ao decodificar retorno: " + _sError + _sWarning + '    SOAP response: ' + _sSoapResp, .T., .f., _sEstado, _sTipo)
							_lWSDL_OK = .F.
							loop
							_oBatch:Retorno = 'N'
						else

							// Interpreta e da tratamento ao retorno do web service.
							_TrataRet (_sEstado, _sTipo, _lDebug)

						endif
					endif
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif

	_Evento ('Verificadas ' + cvaltochar (_nQtReval) + ' de ' + cvaltochar (_nQtAReval) + ' chaves pendentes.', .F., .f., _sEstado, _sTipo)

	// Grava um evento de 'revalidei chaves para esta UF' para posterior acompanhamento pelo setor fiscal e demais interessados
	_oEvento := ClsEvent ():New ()
	_oEvento:CodEven = 'ZZX001'
	_oEvento:Chave   = _sEstado + ' - ' + _sTipo
	_oEvento:Texto   = _sTxtEvt
	_oEvento:Grava ()
	_sTxtEvt = ''

	if empty (_oBatch:Retorno)
		_oBatch:Retorno = 'S'
	endif
	U_ML_SRArea (_aAreaAnt)
	u_log2 ('info', 'Finalizando execucao ' + procname ())
Return



// --------------------------------------------------------------------------
// Interpreta e da tratamento ao retorno do web service.
static function _TrataRet (_sEstado, _sTipo, _lDebug)
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
		u_log2 ('debug', 'Status..................: ' + _sRetStat)
		u_log2 ('debug', 'Mensagem................: ' + _sRetMsg)
	endif

	if _sRetStat $ '656/678'  // Uso indevido
		u_log2 ('aviso', 'Servico retornou mensagem de uso indevido. Tente esta UF mais tarde.')
		_Evento ('AVISO: Servico retornou mensagem de uso indevido. Tente esta UF mais tarde.', .T., .f., _sEstado, _sTipo)
		_lWSDL_OK = .F.  // Nem adianta prosseguir com este WSDL
		_lAtuZZX = .F.

	elseif _sRetStat $ '239/'  // Cabecalho XML invalido
		u_log2 ('aviso', 'Servico retornou mensagem de cabecalho invalido. Verifique o XML que voce esta enviando!')
		_Evento ('AVISO: Servico retornou mensagem de cabecalho invalido. Verifique o XML que voce esta enviando!', .T., .f., _sEstado, _sTipo)
		_lWSDL_OK = .F.  // Nem adianta prosseguir com este WSDL
		_lAtuZZX = .F.

	// Encontrei uma boa explicacao sobre o status 613 em https://www.oobj.com.br/bc/article/rejei%C3%A7%C3%A3o-613-chave-de-acesso-difere-da-existente-em-bd-como-resolver-370.html
	elseif _sRetStat $ '613/'  // Chave de Acesso difere da existente em BD  Rejeicao: Codigo Numerico informado na Chave de Acesso difere do Codigo Numerico da NF-e
		u_log2 ('aviso', 'Servico retornou Codigo Numerico informado na Chave de Acesso difere do Codigo Numerico da NF-e')
		_Evento ('AVISO: Servico retornou mensagem de Codigo Numerico informado na Chave de Acesso difere do Codigo Numerico da NF-e.', .T., .f., _sEstado, _sTipo)

	elseif _sRetStat $ '587/731/526'  // Tags erradas, chave muito antiga, etc.
		_Evento ("AVISO: Retornou status '" + _sRetStat + "' para a chave " + zzx -> zzx_chave, .F., .f., _sEstado, _sTipo)
		_lAtuZZX = .F.

	elseif _sRetStat $ '280'  // Certificado emissor invalido
		_Evento ("ERRO: Retornou status '" + _sRetStat + "' (certificado emissor invalido)", .T., .f., _sEstado, _sTipo)
		_lWSDL_OK = .F.  // Nem adianta prosseguir com este WSDL
		_lAtuZZX = .F.

	elseif _sRetStat $ '100/150'  // Autorizada (100) ou autorizada fora do prazo por ter sido emitida em contingencia (150)
		_sRetChv  = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRChAu)  + ':TEXT')

		// Jah tive casos em que faltava a tag com protocolo de autorizacao 
		// talvez quando acompanha mensagem "documento indisponivel no momento".
		if type ('_oXmlRet:' + alltrim (zz4 -> zz4_TRPrAu) + ':TEXT') == "C"
			_sRetPrAut = &('_oXmlRet:' + alltrim (zz4 -> zz4_TRPrAu) + ':TEXT')
		else
			_sRetPrAut = ''
		endif
		if _lDebug
			u_log2 ('debug', 'Chave (autorizada)......: ' + _sRetChv)
			u_log2 ('debug', 'Protocolo autorizacao...: ' + _sRetPrAut)
		endif

	elseif _sRetStat == '101'  // Cancelada

		// Leitura dos eventos vinculados: pode estar em formato de array, caso tenha mais de um evento.
		_oEvtCanc = &('_oXmlRet:' + alltrim (zz4 -> zz4_TEvCan))
		if valtype (_oEvtCanc) == 'O'  // Tem apenas um evento
			_sRetChv  = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TRChCa)  + ':TEXT')
			u_log2 ('aviso', 'Chave (cancelada).......: ' + _sRetChv)
			_sRetEvCan = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TREvCa) + ':TEXT')
			if _sRetEvCan != '110111'
				_Evento ("ERRO: Status de cancelamento (" + _sRetStat + "), mas evento (" + _sRetEvCan + ") nao corresponde.", .T., .f., _sEstado, _sTipo)
				_lAtuZZX = .F.
			else
				_sRetPrCan = &('_oEvtCanc:' + alltrim (zz4 -> zz4_TRPrCa) + ':TEXT')
				if _lDebug
					u_log2 ('aviso', 'Protocolo cancelamento: ' + _sRetPrCan)
				endif
			endif
		else
			_lAtuZZX = .F.  // Assume como falso, ateh encontrar um evento de cancelamento.
			for _nEvtCanc = 1 to len (_oEvtCanc)  // Tem mais de um evento
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
			next
		endif
	endif

	// Se pretento atualizar o ZZX, confiro consistencia entre chave, protocolos, etc.
	if _lAtuZZX
//		if _sRetChv != zzx -> zzx_chave
//			_Evento ("ERRO: Retorno veio para outra chave: '" + _sRetChv + "'", .T., .f., _sEstado, _sTipo)
//			_lAtuZZX = .F.
//			_oBatch:Retorno = 'N'
//		endif
		if _sRetChv == zzx -> zzx_chave .and. _sRetStat $ '100/150'
			if empty (_sRetPrAut)
				_Evento ("ERRO: Retornou status '" + _sRetStat + "' (autorizado), mas nao consegui ler protocolo de autorizacao para a chave " + zzx -> zzx_chave, .T., .f., _sEstado, _sTipo)
				_lAtuZZX = .F.
				_oBatch:Retorno = 'N'
			endif
		elseif _sRetChv == zzx -> zzx_chave .and. _sRetStat == '101'
			if empty (_sRetPrCan)
				_Evento ("ERRO: Retornou status '" + _sRetStat + "' (cancelado), mas nao consegui ler protocolo de cancelamento para a chave " + zzx -> zzx_chave, .T., .f., _sEstado, _sTipo)
				_lAtuZZX = .F.
				_oBatch:Retorno = 'N'
			endif
		elseif empty (_sRetChv) .and. _sRetStat == '217'
			_Evento ("ERRO: Retornou status '" + _sRetStat + "' (nao existe na SEFAZ) - " + _sRetMsg, .T., .f., _sEstado, _sTipo)
		else
			_Evento ("ERRO: Retornou status '" + _sRetStat + "' (nao sei como tratar esse retorno) - " + _sRetMsg, .T., .f., _sEstado, _sTipo)
			u_log2 ('info', 'Mensagem................: ' + _sRetMsg)
			_lAtuZZX = .F.
			_oBatch:Retorno = 'N'
		endif
	endif

	if _lAtuZZX
		if zzx -> zzx_retsef != _sRetStat
			u_log2 ('info', 'Atualizando chave ' + zzx -> zzx_chave + ' no ZZX status  autorizacao: ' + zzx -> zzx_retsef + ' ==> ' + _sRetStat)
		endif
		if alltrim (zzx -> zzx_protoc) != alltrim (_sRetPrAut)
			u_log2 ('info', 'Atualizando chave ' + zzx -> zzx_chave + ' no ZZX protoc. autorizacao: ' + zzx -> zzx_protoc + ' ==> ' + _sRetPrAut)
		endif
		if alltrim (zzx -> zzx_prtcan) != alltrim (_sRetPrCan)
			u_log2 ('info', 'Atualizando chave ' + zzx -> zzx_chave + ' no ZZX protoc.cancelamento: ' + zzx -> zzx_prtcan + ' ==> ' + _sRetPrCan)
		endif

		_nQtReval ++
		reclock ("ZZX", .F.)
		zzx -> zzx_ducc   = date ()
		zzx -> zzx_hucc   = left (time (), 5)
		zzx -> zzx_retsef = _sRetStat
		zzx -> zzx_protoc = _sRetPrAut
		zzx -> zzx_prtcan = _sRetPrCan
		msunlock ()

		// Grava evento temporario
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "ZZX001"
		_oEvento:Texto     = "Finalizada revalidacao (de chave junto a SEFAZ), com retorno = " + _sRetStat
		_oEvento:ChaveNFe  = zzx -> zzx_chave
		_oEvento:DiasValid = 365  // Manter o evento por alguns dias, depois disso vai ser deletado.
		_oEvento:Grava ()
	endif
return


// --------------------------------------------------------------------------
// Grava evento para monitoramento posterior
static function _Evento (_sMsgEvt, _lErroEvt, _lAvisarTI, _sEstado, _sTipo)
	local _sLinMsg := alltrim (_sMsgEvt)
	local _oAviso  := NIL

	u_help (alltrim (_sMsgEvt),, _lErroEvt)
	if ! _sLinMsg $ _sTxtEvt
		u_log2 ('debug', 'adicionando: ' + _sLinMsg)
		_sTxtEvt += iif (empty (_sTxtEvt), '', chr (13) + chr (10)) + _sLinMsg
	endif
	if _lAvisarTI
		_oAviso := ClsAviso():new ()
		_oAviso:Tipo       = 'E'  // I=Info;A=Aviso;E=Erro
		_oAviso:Titulo     = 'Problema revalidacao chaves DF-e'
		_oAviso:Texto      = _sTipo + ' ' + _sEstado + ' ' + _sMsgEvt
		_oAviso:DestinZZU  = {'122'}  // 122 = TI
		_oAviso:Origem     = procname ()
		_oAviso:DiasDeVida = 2  // Como este programa roda diariamente, nao vejo motivo de encher a caixa postal
		_oAviso:InfoSessao = .T.  // se .T. inclui informacoes adicionais de sessao na mensagem.
		_oAviso:Grava ()
	endif
return
