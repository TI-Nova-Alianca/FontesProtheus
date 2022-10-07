// Programa:  WSPrcStatusAgendaSafraWS
// Autor:     Robert Koch
// Data:      30/08/2022
// Descricao: Acessa web service do NaWeb

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cliente_web_service
// #Descricao         #Acessa web service do NaWeb - agenda safra
// #PalavasChave      #web_service #naweb #notificacoes
// #TabelasPrincipais #
// #Modulos           #Todos

#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

User Function _SLMRJNE ; Return  // "dummy" function - Internal Use 

WSCLIENT WSPrcStatusAgendaSafraWS

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD Execute

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cEntrada                  AS string
	WSDATA   cSaida                    AS string

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSPrcStatusAgendaSafraWS
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O C�digo-Fonte Client atual requer os execut�veis do Protheus Build [7.00.210324P-20220608] ou superior. Atualize o Protheus ou gere o C�digo-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSPrcStatusAgendaSafraWS
Return

WSMETHOD RESET WSCLIENT WSPrcStatusAgendaSafraWS
	::cEntrada           := NIL 
	::cSaida             := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSPrcStatusAgendaSafraWS
Local oClone := WSPrcStatusAgendaSafraWS():New()
	oClone:_URL          := ::_URL 
	oClone:cEntrada      := ::cEntrada
	oClone:cSaida        := ::cSaida
Return oClone

// WSDL Method Execute of Service WSPrcStatusAgendaSafraWS

WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSPrcStatusAgendaSafraWS
	Local cSoap := ""
	local _sURI := ''
	private oXmlRet

	BEGIN WSMETHOD

	// Tenho enderecos diferentes para a base de testes e a de producao.
	if "TESTE" $ upper (GetEnvServer()) .or. "R22" $ upper (GetEnvServer()) .or. "R23" $ upper (GetEnvServer())
		U_Log2 ('debug', '[' + procname () + ']Estou definindo web service para base teste')
		_sURI = "http://naweb17.novaalianca.coop.br/PrcStatusAgendaSafraWS.aspx"
	else
		_sURI = "http://naweb.novaalianca.coop.br/PrcStatusAgendaSafraWS.aspx"
	endif

	cSoap += '<PrcStatusAgendaSafraWS.Execute xmlns="NAWeb">'
	cSoap += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += "</PrcStatusAgendaSafraWS.Execute>"

	oXmlRet := SvcSoapCall(Self,cSoap,; 
		"NAWebaction/APRCSTATUSAGENDASAFRAWS.Execute",; 
		"DOCUMENT","NAWeb",,,; // "DOCUMENT","NAWeb",,,; 
		_sURI)

	::Init()
	::cSaida = oXmlRet:_PRCSTATUSAGENDASAFRAWS_EXECUTERESPONSE:_SAIDA:TEXT

END WSMETHOD

oXmlRet := NIL
Return .T.
