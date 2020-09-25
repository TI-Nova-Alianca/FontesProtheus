#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

/* ===============================================================================
WSDL Location    http://naweb.novaalianca.coop.br/aprcnucwebservice.aspx?wsdl
Gerado em        04/19/18 14:53:23
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

User Function _KZKBPMC ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSPrcNucWebService
------------------------------------------------------------------------------- */

WSCLIENT WSPrcNucWebService

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

WSMETHOD NEW WSCLIENT WSPrcNucWebService
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20180315 NG] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSPrcNucWebService
Return

WSMETHOD RESET WSCLIENT WSPrcNucWebService
	::cEntrada           := NIL 
	::cSaida             := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSPrcNucWebService
Local oClone := WSPrcNucWebService():New()
	oClone:_URL          := ::_URL 
	oClone:cEntrada      := ::cEntrada
	oClone:cSaida        := ::cSaida
Return oClone

// WSDL Method Execute of Service WSPrcNucWebService

WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSPrcNucWebService
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<PrcNucWebService.Execute xmlns="NAWeb">'
cSoap += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += "</PrcNucWebService.Execute>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"NAWebaction/APRCNUCWEBSERVICE.Execute",; 
	"DOCUMENT","NAWeb",,,; 
	"http://naweb.novaalianca.coop.br/aprcnucwebservice.aspx")

::Init()
//::cSaida             :=  WSAdvValue( oXmlRet,"_PRCNUCWEBSERVICE.EXECUTERESPONSE:_SAIDA:TEXT","string",NIL,NIL,NIL,NIL,NIL,NIL) 
//::cSaida :=  XGetInfo( oXmlRet,'_PRCNUCWEBSERVICE.EXECUTERESPONSE:_SAIDA:TEXT', '')
::cSaida := oXmlRet:_PRCNUCWEBSERVICE_EXECUTERESPONSE:_SAIDA:TEXT

END WSMETHOD

//U_Log(oXmlRet)
//U_LogObj(oXmlRet)

oXmlRet := NIL
Return .T.



