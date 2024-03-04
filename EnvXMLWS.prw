// Programa:   EnvXMLWS
// Autor:      Elaine Ballico - DWT
// Data:       06/11/2012
// Descricao:  Envia xml da nota para o Walmart via Webservice
//
// Historico de alteracoes:
//      
// 02/07/2014 - Catia  - Alterado para que busque a entidade usando o MAX, para que pegue a maior entidade que ativa do CNPJ
// 20/08/2015 - Robert - Criado parametro 'reenvia notas ja enviadas' quando execucao manual.
// 21/08/2015 - Robert - Reexecuta notas marcadas como 'E' (erro no envio) quando rotina automatica.
// 30/11/2015 - Robert - Passa a validar campo A1_VAEDING = '3' e nao mais pelo CNPJ dos clientes.
// 06/07/2016 - Robert - Gera evento quando NF nao estiver autorizada.
//                     - Execucao automatica aumentada de 5 para ultimos 15 dias.
// 13/06/2019 - Robert - Melhorados logs para depuracao de erros de conexao.
// 07/04/2020 - Robert - Inseridor logs para tentar verificar erro no envio de 6 notas recentes.
// 03/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#include "tbiconn.ch"

// --------------------------------------------------------------------------
user function EnvXMLWS (_lAutomat)
	local cURL       := PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
	local oWS        := NIL
	local _lRet      := .T.
	local _sSerie    := ""
	local _sEntidade := ""
	local _sProtEmis := ""
	local _sProtCanc := ""
	local _sXML      := ""
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	Local cCadastro  := "Envia XML Walmart"
	local _oSQL      := NIL
	local _sAliasQ   := ""
	local _cCnpj     := ""
	local _cTexto    := ""
	local _sMsgErr   := ""
	local nX		 := 0
	Private cPerg   := "ENVXMLWS"

	u_logIni ()
	u_logId ()
	u_logpcham ()

	_lAutomat := iif (_lAutomat == NIL, .F., _lAutomat)
	u_log ('execucao automatica:', _lAutomat)

	if !_lAutomat

		_ValidPerg()
		Pergunte(cPerg,.F.)

		AADD (aSays, "Este Programa Tem Como Objetivo Enviar XML para Walmart")

		AADD (aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD (aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD (aButtons, { 2,.T.,{|| FechaBatch() }} )

		FormBatch( cCadastro, aSays, aButtons )

		If nOpca != 1
			u_logFim ()
			return
		endif
	endif


	procregua (10)

	// Busca lista de 'candidatos'.
	if _lAutomat
		mv_par01 := DaySub(date(), 30) //5)  // Varios dias para tras, para evitar a perda de alguma NF
		mv_par02 := date()
		mv_par03 := " "
		mv_par04 := "ZZZZZZZZZ"
		mv_par05 := 2
	endif

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += " SELECT SF2.F2_SERIE, SF2.F2_DOC, SA1.A1_CGC, SF2.F2_CLIENTE, SF2.F2_LOJA, SF2.F2_FILIAL "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SF2") + " SF2, " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery +=  " WHERE SA1.A1_COD = SF2.F2_CLIENTE "
	_oSQL:_sQuery +=    " AND SF2.F2_FILIAL  = '" + xfilial ("SF2") + "'"
	_oSQL:_sQuery +=    " AND SA1.A1_LOJA = SF2.F2_LOJA "
	_oSQL:_sQuery +=    " AND SF2.F2_TIPO = 'N' "
	_oSQL:_sQuery +=    " AND SF2.D_E_L_E_T_ = '' "
	_oSQL:_sQuery +=    " AND F2_ESPECIE = 'SPED' "
	_oSQL:_sQuery +=    " AND SA1.A1_VAEDING = '3'"
	_oSQL:_sQuery +=    " and SF2.F2_EMISSAO  BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery +=    " and SF2.F2_DOC  BETWEEN '" + mv_par03 + "' and '" +  mv_par04 + "'"
	if mv_par05 == 2  //_lAutomat
		_oSQL:_sQuery +=    " AND SF2.F2_VAENVWS != 'S' "
	endif
	u_log (_oSQL:_sQuery)

    // ao buscara entidade alterado para que busque a maior entidade, usando a inscricao correta
    // ver como vai ficar isso para notas antigas - talvez tenha que prever alguma coisa referente a emissao da nota fiscal
	_sEntidade := U_RetSQL ("SELECT MAX(ID_ENT) FROM SPED001 WHERE CNPJ = '" + sm0 -> m0_cgc + "' AND D_E_L_E_T_ = ''")
	_sAliasQ = _oSQL:Qry2Trb (.f.)

	if (_sAliasQ) -> (eof ())
		u_help("Nao ha nota a enviar ou notas ja foram enviadas com os parametros informados!")
	endif

	Do While ! (_sAliasQ) -> (eof ())
		procregua ((_sAliasQ) -> (reccount ()))

		_sSerie := (_sAliasQ)->F2_SERIE
		_sNF    := (_sAliasQ)->F2_DOC
		_cCnpj  := (_sAliasQ)->A1_CGC

		oWS:= WSNFeSBRA():New()
		oWS:cUSERTOKEN        := "TOTVS"
		oWS:cID_ENT           := _sEntidade
		oWS:oWSNFEID          := NFESBRA_NFES2():New()
		oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
		aadd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
		Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := _sSerie + _sNF

		oWS:nDIASPARAEXCLUSAO := 0
		oWS:_URL := AllTrim(cURL)+"/NFeSBRA.apw"
		If oWS:RETORNANOTAS()
			// Precisa ler toda a array por que o mesmo numero de nota pode retornar
			// em producao/homologacao, ou em modo normal/contingencia
			For nX := 1 To Len(oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3)
				if valtype (oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE) == "O"
					_sProtEmis = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CPROTOCOLO
				endif
				if valtype (oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFECANCELADA) == "O"
					_sProtCanc = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFECANCELADA:CPROTOCOLO
				endif
				if ! empty (_sProtEmis) .or. ! empty (_sProtCanc)  // Se nota autorizada, faz mais testes
					_sXML := oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CXML
					if at ("<tpAmb>1</tpAmb>", _sXml) = 0  // Ambiente: 1=producao, 2=homologacao
						u_help ('NF ' + _sNF + ' autorizada em homologacao')
						// Se a nota tiver sido autorizada em homologacao, nao envia
						_lRet = .F.
						exit
					else
						u_log ('NF autorizada.')
						_lRet = .T.
					endif
				else
					// Se a nota não tiver protocolo de autorizacao ou cancelamento, não envia
					u_help ('NF ' + _sNF + ' nao autorizada.')
					_lRet = .F.
					exit
				endif

				if ! _lRet
					_oEvento := ClsEvent():new ()
					_cTexto := "Export.Webservice p/Walmart: NF nao autorizada (ou em homologacao)"
					_oEvento:CodEven   = "SF2012"
					_oEvento:Texto   := _cTexto
					_oEvento:NFSaida   = _sNF
					_oEvento:SerieSaid = _sSerie
					_oEvento:Cliente   = (_sAliasQ) -> F2_CLIENTE
					_oEvento:LojaCli   = (_sAliasQ) -> F2_LOJA
					_oEvento:MailToZZU = {'001'}
					_oEvento:Grava ()
				endif

			next


			if _lRet
				if Substr(_cCnpj,1,8) == "00063960" //SUDESTE:    Raiz CNPJ WM: 00.063.960:
					oWsEnvXml:= WScls_sud_nfe_xml():New()
					cCamWebServ:="WScls_sud_nfe_xml"
					u_log ('Vou comunicar com a regiao sudeste')
				elseif Substr(_cCnpj,1,8) == "93209765"  //SUL:            Raiz CNPJ WM:
					oWsEnvXml:= WScls_SUL_nfe_xml():New()
					cCamWebServ:="WScls_SUL_nfe_xml"
					u_log ('Vou comunicar com a regiao sul')
// Nao temos clientes nestes CNPJ. Robert, 28/10/2016.
//				elseif Substr(_cCnpj,1,8) == "13004510" .OR. Substr(_cCnpj,1,8) == "97422620" //NORDESTE: Raiz CNPJ WM 13.004.510 ou 97.422.620:
//					oWsEnvXml:= WScls_ne_nfe_xml():New()
//					cCamWebServ:="WScls_ne_nfe_xml"
				ELSE

					// Nao e´ nenhum dos CNPJs disponibilizados até então no site do Walmart - verificar se não tem outros informados no site para
					// implementar aqui ou se o CNPJ do cliente está realmente correto e é do Walmart
					_sMsgErr = "CNPJ do Walmart da Nota " + _sNF + " Serie: " + _sSerie + " nao parametrizado para envio do XML no programa " + procname () + ". Verifique se esta loja do Walmart deve mesmo receber as notas por webservice e ajuste o campo '" + alltrim (RetTitle ("A1_VAEDING")) + "' no cadastro do cliente."
					u_help(_sMsgErr)
					U_ZZUNU ('001', _sMsgErr)  // Notifica destinatarios envolvidos em EDI, etc.
					(_sAliasQ) -> (dbskip ())
					loop
				Endif

				oWsEnvXml:INIT()
				oWsEnvXml:RESET()
				oWsEnvXml:cpa_tp_cd_usua :="J"
				oWsEnvXml:npa_cd_usua:= val(SM0->M0_CGC) //VAL(GETMV("MV_VENDORW"))//código do Vendor
				oWsEnvXml:cpa_ds_xml_nfe:= _sXML // arquivo xml
				oWsEnvXml:fu_upld()

				// Caso a execucao nao chegue ateh aqui, verifique se falta a secao [SSLConfigure] no arquivo INI do servico.

				u_log ("executou comando de upload.")
				u_log ('oWsEnvXml:')
				u_logObj (oWsEnvXml)
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ('oWsEnvXml:owsfu_upldresult:')
				u_logObj (oWsEnvXml:owsfu_upldresult)
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ('')
				u_log ("nreturn_code: ", oWsEnvXml:owsfu_upldresult:nreturn_code)
				u_log ("creturn_chav: ", oWsEnvXml:owsfu_upldresult:creturn_chav)

				If oWsEnvXml:owsfu_upldresult:nreturn_code != 0
					if ! empty (oWsEnvXml:owsfu_upldresult:creturn_chav)
						_sMsgErr = "XML da nota: " + _sNF + " Serie: "+_sSerie +" Não transmitido: " + oWsEnvXml:owsfu_upldresult:creturn_chav + " | "+DTOC(DATE())+" | "+TIME()
					else  // retorno do erro em branco/nulo
						_sMsgErr = "XML da nota: " + _sNF + " Serie: "+_sSerie +" Não transmitida: ERRO NAO IDENTIFICADO | "+DTOC(DATE())+" | "+TIME()
					endif
					u_help (_sMsgErr)

					// Posiciona o registro na nota que esta sendo enviada e e altera para "E" o campo F2_VAENVWS para caracterizar que a nota esta com erro
					dbSelectArea("SF2")
					DbSetOrder(2)
					DbSeek((_sAliasQ)->F2_FILIAL+(_sAliasQ)->F2_CLIENTE+(_sAliasQ)->F2_LOJA+(_sAliasQ)->F2_DOC+(_sAliasQ)->F2_SERIE,.t.)
					RecLock("SF2",.F.)
					Replace F2_VAENVWS With "E"
					MsUnlock()
					DbSkip()

					// Grava evento para posterior consulta.
					if ! empty (oWsEnvXml:owsfu_upldresult:creturn_chav)
						_cErro :=  oWsEnvXml:owsfu_upldresult:creturn_chav
					else  // se erro retorna em branco/nulo
						_cErro := "ERRO NAO IDENTIFICADO"
					endif

					_oEvento := ClsEvent():new ()
					_cTexto := "Exportacao da NF " + _sNF + " via Webservice para Walmart com erro: " + _cErro
					_oEvento:CodEven   = "SF2012"
					_oEvento:Texto   := _cTexto
					_oEvento:NFSaida   = _sNF
					_oEvento:SerieSaid = _sSerie
					_oEvento:Cliente   = (_sAliasQ) -> F2_CLIENTE
					_oEvento:LojaCli   = (_sAliasQ) -> F2_LOJA
					_oEvento:MailToZZU = {'001'}
					_oEvento:Grava ()

				Else
					u_help("XML da nota: " + _sNF + " Serie: "+_sSerie +" transmitido com sucesso"+" | "+DTOC(DATE())+" | "+TIME())

					// Posiciona o registro na nota que esta sendo enviada e atualiza F2_VAENVWS com "S" para caracterizar que nota foi enviada OK
					dbSelectArea("SF2")
					DbSetOrder(2)
					DbSeek((_sAliasQ)->F2_FILIAL+(_sAliasQ)->F2_CLIENTE+(_sAliasQ)->F2_LOJA+(_sAliasQ)->F2_DOC+(_sAliasQ)->F2_SERIE,.t.)
					RecLock("SF2",.F.)
					Replace F2_VAENVWS With "S"
					MsUnlock()
					DbSkip()

					// Grava evento para posterior consulta.
					_oEvento := ClsEvent():new ()
					_cTexto := "Exportacao via Webservice para Walmart - OK"
					_oEvento:CodEven   := "SF2012"
					_oEvento:Texto     := _cTexto
					_oEvento:NFSaida   := _sNF
					_oEvento:SerieSaid := _sSerie
					_oEvento:Cliente   := (_sAliasQ) -> F2_CLIENTE
					_oEvento:LojaCli   := (_sAliasQ) -> F2_LOJA
					_oEvento:Grava ()
				Endif
			else
				_sMsgErr := "Xml nao pode ser enviado, verifique a nota "+ _sNF + " Serie: "+_sSerie
				U_help (_sMsgErr)
				_oEvento := ClsEvent():new ()
				_oEvento:CodEven   = "SF2012"
				_oEvento:Texto     = "Transmissao XML via Webservice para Walmart não pode ser realizada"
				_oEvento:NFSaida   = _sNF
				_oEvento:SerieSaid = _sSerie
				_oEvento:Cliente   = (_sAliasQ) -> F2_CLIENTE
				_oEvento:LojaCli   = (_sAliasQ) -> F2_LOJA
				_oEvento:Grava ()
			endif

//			_Enviar ()
		endif

		
		
		
//		u_help ('Estou finalizando apos a primeira nota, para testes. Remover isto mais tarde!')
//		exit




		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())

	u_logFim ()
return


/* ainda nao funcionou...
// --------------------------------------------------------------------------
Static Function _Enviar ()
	local _oWSDL := NIL
	local _sURL  := 'https://portalnfe.walmart.com.br/Gnfe_Port_ws/cls_403_nfe_xml.asmx?WSDL'

	u_logIni ()
	// Cria o objeto para acesso ao web service
	_oWSDL := TWsdlManager():New()
	_oWSDL:nTimeout := 30  // tempo em segundos para aguardar envio e recebimento de mensagens SOAP

	// Usa os mesmos arquivos de certificados do TSS
//	_oWSDL:cSSLCACertFile := "\certs\000020_ca.pem"
//	_oWSDL:cSSLCertFile   := "\certs\000020_cert.pem"
//	_oWSDL:cSSLKeyFile    := "\certs\000020_key.pem"
//	_oWsdl:lSSLInsecure   := .T.

	// http://tdn.totvs.com/pages/viewpage.action?pageId=223932805
	_lParse = _oWSDL:ParseURL (_sURL)
	u_log ('_lParse:', _lParse)
	u_log (_oWSDL:ListOperations ())
	if len (_oWSDL:ListOperations()) == 0
		u_help ("Erro na consulta WSDL. Tente novamente mais tarde. " + _oWSDL:cError)
	else
		if ! _oWSDL:SetOperation ('fu_upld')
			u_help ("Erro definicao operacao do WSDL:" + _oWSDL:cError )
		endif
	endif
	u_logFim ()
return
*/


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aTamDoc   := aclone (TamSX3 ("D2_DOC"))

	//                     PERGUNT                           TIPO          TAM           DEC VALID    F3 Opcoes          Help
	aadd (_aRegsPerg, {01, "Data Emissao Inicial         ?", "D",           08,            0,  "",   "", {},             "Informe a Data de Emissao Inicial"})
	aadd (_aRegsPerg, {02, "Data Emissao Final           ?", "D",           08,            0,  "",   "", {},             "Informe a Data de Emissao Final"})
	aadd (_aRegsPerg, {03, "Nota Inicial                 ?", "C", _aTamDoc [1], _aTamDoc [2],  "",   "", {},             "Informe a Nota Fiscal Inicial"})
	aadd (_aRegsPerg, {04, "Nota Final                   ?", "C", _aTamDoc [1], _aTamDoc [2],  "",   "", {},             "Informe a Nota Fiscal Final"})
	aadd (_aRegsPerg, {05, "Reenviar notas ja enviadas   ?", "N",           01,            0,  "",   "", {'Sim', 'Nao'}, "Reenviar notas marcadas como ja enviadas"})

	U_ValPerg (cPerg, _aRegsPerg)
Return
