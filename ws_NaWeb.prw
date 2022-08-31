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

/* -------------------------------------------------------------------------------
WSDL Service WSPrcNotificacoesWS
------------------------------------------------------------------------------- */

WSCLIENT WSPrcNotificacoesWS

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

WSMETHOD NEW WSCLIENT WSPrcNotificacoesWS
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O C�digo-Fonte Client atual requer os execut�veis do Protheus Build [7.00.210324P-20220608] ou superior. Atualize o Protheus ou gere o C�digo-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSPrcNotificacoesWS
Return

WSMETHOD RESET WSCLIENT WSPrcNotificacoesWS
	::cEntrada           := NIL 
	::cSaida             := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSPrcNotificacoesWS
Local oClone := WSPrcNotificacoesWS():New()
	oClone:_URL          := ::_URL 
	oClone:cEntrada      := ::cEntrada
	oClone:cSaida        := ::cSaida
Return oClone

// WSDL Method Execute of Service WSPrcNotificacoesWS

WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSPrcNotificacoesWS
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<PrcNotificacoesWS.Execute xmlns="NAWeb">'
cSoap += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += "</PrcNotificacoesWS.Execute>"

oXmlRet := SvcSoapCall(Self,cSoap,; 
	"NAWebaction/APRCNOTIFICACOESWS.Execute",; 
	"DOCUMENT","NAWeb",,,; 
	"http://naweb17.novaalianca.coop.br/prcnotificacoesws.aspx")

::Init()
::cSaida             :=  WSAdvValue( oXmlRet,"_PRCNOTIFICACOESWS.EXECUTERESPONSE:_SAIDA:TEXT","string",NIL,NIL,NIL,NIL,NIL,NIL) 

END WSMETHOD

oXmlRet := NIL
Return .T.
