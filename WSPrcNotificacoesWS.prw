// Programa:  WSPrcNotificacoesWS
// Autor:     Robert Koch
// Data:      30/08/2022
// Descricao: Acessa web service do NaWeb

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cliente_web_service
// #Descricao         #Acessa web service do NaWeb - notificacoes
// #PalavasChave      #web_service #naweb #notificacoes
// #TabelasPrincipais #
// #Modulos           #Todos

// Historico de alteracoes:
// 08/11/2022 - Robert - Passa a usar a funcao U_AmbTeste().
//

#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

// --------------------------------------------------------------------------
User Function _SLMRJND ; Return  // "dummy" function - Internal Use 

// --------------------------------------------------------------------------
WSCLIENT WSPrcNotificacoesWS
	WSMETHOD NEW
	WSMETHOD Execute

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cEntrada                  AS string
	WSDATA   cSaida                    AS string
ENDWSCLIENT


// --------------------------------------------------------------------------
WSMETHOD NEW WSCLIENT WSPrcNotificacoesWS
	If !FindFunction("XMLCHILDEX")
		UserException("O C�digo-Fonte Client atual requer os execut�veis do Protheus Build [7.00.210324P-20220608] ou superior. Atualize o Protheus ou gere o C�digo-Fonte novamente utilizando o Build atual.")
	EndIf
Return Self


// --------------------------------------------------------------------------
WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSPrcNotificacoesWS
	Local cSoap := ""
	local _sURI := ''
	private oXmlRet

	BEGIN WSMETHOD

//	_sURI = "http://naweb17.novaalianca.coop.br/prcnotificacoesws.aspx"
	_sURI = "http://naweb.novaalianca.coop.br/prcnotificacoesws.aspx"

	cSoap += '<PrcNotificacoesWS.Execute xmlns="NAWeb">'
	cSoap += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += "</PrcNotificacoesWS.Execute>"

	oXmlRet := SvcSoapCall(Self,cSoap,; 
		"NAWebaction/APRCNOTIFICACOESWS.Execute",; 
		"DOCUMENT","NAWeb",,,; // "DOCUMENT","NAWeb",,,; 
		_sURI)  // 		"http://naweb17.novaalianca.coop.br/prcnotificacoesws.aspx")

	::cSaida = oXmlRet:_PRCNOTIFICACOESWS_EXECUTERESPONSE:_SAIDA:TEXT

	END WSMETHOD

	oXmlRet := NIL
Return .T.
