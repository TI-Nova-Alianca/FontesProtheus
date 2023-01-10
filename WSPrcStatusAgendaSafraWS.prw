// Programa:  WSPrcStatusAgendaSafraWS
// Autor:     Robert Koch
// Data:      30/08/2022
// Descricao: Acessa web service do NaWeb para atualizar agenda safra (GLPI 12695)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cliente_web_service
// #Descricao         #Acessa web service do NaWeb - agenda safra
// #PalavasChave      #web_service #naweb #Agenda #Safra
// #TabelasPrincipais #SZE
// #Modulos           #COOP

#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

// --------------------------------------------------------------------------
User Function _SLMRJNE ; Return  // "dummy" function - Internal Use

// --------------------------------------------------------------------------
WSCLIENT WSPrcStatusAgendaSafraWS
	WSMETHOD NEW
	WSMETHOD Execute

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cEntrada                  AS string
	WSDATA   cSaida                    AS string
ENDWSCLIENT


// --------------------------------------------------------------------------
WSMETHOD NEW WSCLIENT WSPrcStatusAgendaSafraWS
	If !FindFunction("XMLCHILDEX")
		UserException("O C�digo-Fonte Client atual requer os execut�veis do Protheus Build [7.00.210324P-20220608] ou superior. Atualize o Protheus ou gere o C�digo-Fonte novamente utilizando o Build atual.")
	EndIf
Return Self


// --------------------------------------------------------------------------
WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSPrcStatusAgendaSafraWS
	Local _sSOAP := ""
	local _sURI  := ''
	private _oXmlRet

	BEGIN WSMETHOD

	// Tenho enderecos diferentes para a base de testes e a de producao.
//	if "TESTE" $ upper (GetEnvServer()) .or. "R22" $ upper (GetEnvServer()) .or. "R23" $ upper (GetEnvServer())
	if U_AmbTeste ()
		U_Log2 ('aviso', '[' + procname () + ']Estou definindo web service para base teste')
		_sURI = "http://naweb17.novaalianca.coop.br/PrcStatusAgendaSafraWS.aspx"
	else
//		_sURI = "http://naweb17.novaalianca.coop.br/PrcStatusAgendaSafraWS.aspx"
//		U_Log2 ('aviso', '[' + procname () + ']Ainda estou usando naweb17 seria bom ir para naweb oficial.')
		_sURI = "http://naweb.novaalianca.coop.br/PrcStatusAgendaSafraWS.aspx"
	endif

	_sSOAP += '<PrcStatusAgendaSafraWS.Execute xmlns="NAWeb">'
	_sSOAP += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	_sSOAP += "</PrcStatusAgendaSafraWS.Execute>"
//	U_Log2 ('debug', '[' + procname () + ']SOAP: ' + _sSOAP)
	_oXmlRet := SvcSOAPCall(Self,_sSOAP,;
		"NAWebaction/APRCSTATUSAGENDASAFRAWS.Execute",; 
		"DOCUMENT","NAWeb",,,;
		_sURI)
//	u_logobj (_oXmlRet:_PRCSTATUSAGENDASAFRAWS_EXECUTERESPONSE:_RETORNO)
	::cSaida = _oXmlRet:_PRCSTATUSAGENDASAFRAWS_EXECUTERESPONSE:_RETORNO:TEXT

	END WSMETHOD

	_oXmlRet := NIL
Return .T.
