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

#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

/* ===============================================================================
WSDL Location    http://naweb17.novaalianca.coop.br/PrcNotificacoesWS.aspx?wsdl
Gerado em        30/08/22 14:23:38
Observa��es      C�digo-Fonte gerado por ADVPL WSDL Client 1.120703
                 Altera��es neste arquivo podem causar funcionamento incorreto
                 e ser�o perdidas caso o c�digo-fonte seja gerado novamente.
=============================================================================== */

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

	// Tenho enderecos diferentes para a base de testes e a de producao.
	if "TESTE" $ upper (GetEnvServer()) .or. "R22" $ upper (GetEnvServer()) .or. "R23" $ upper (GetEnvServer())
		U_Log2 ('debug', '[' + procname () + ']Estou definindo web service para base teste')
		_sURI = "http://naweb17.novaalianca.coop.br/prcnotificacoesws.aspx"
	else
		_sURI = "http://naweb17.novaalianca.coop.br/prcnotificacoesws.aspx"
		U_Log2 ('aviso', '[' + procname () + ']Ainda estou usando naweb17 seria bom ir para naweb oficial.')
	endif

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
