#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

/* ===============================================================================
WSDL Location    http://192.168.1.3:7980/ws/WS_ALIANCA.APW?WSDL
Gerado em        05/25/18 17:10:49
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

User Function _EPJKIOO ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSWS_ALIANCA
------------------------------------------------------------------------------- */

WSCLIENT WSWS_ALIANCA

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD INTEGRAWS

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cXMLRCV                   AS string
	WSDATA   oWSINTEGRAWSRESULT        AS WS_ALIANCA_RETORNOWS

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSWS_ALIANCA
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20180315 NG] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSWS_ALIANCA
	::oWSINTEGRAWSRESULT := WS_ALIANCA_RETORNOWS():New()
Return

WSMETHOD RESET WSCLIENT WSWS_ALIANCA
	::cXMLRCV            := NIL 
	::oWSINTEGRAWSRESULT := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSWS_ALIANCA
Local oClone := WSWS_ALIANCA():New()
	oClone:_URL          := ::_URL 
	oClone:cXMLRCV       := ::cXMLRCV
	oClone:oWSINTEGRAWSRESULT :=  IIF(::oWSINTEGRAWSRESULT = NIL , NIL ,::oWSINTEGRAWSRESULT:Clone() )
Return oClone

// WSDL Method INTEGRAWS of Service WSWS_ALIANCA

WSMETHOD INTEGRAWS WSSEND cXMLRCV WSRECEIVE oWSINTEGRAWSRESULT WSCLIENT WSWS_ALIANCA
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<INTEGRAWS xmlns="http://192.168.1.3:7980/">'
cSoap += WSSoapValue("XMLRCV", ::cXMLRCV, cXMLRCV , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += "</INTEGRAWS>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://192.168.1.3:7980/INTEGRAWS",; 
	"DOCUMENT","http://192.168.1.3:7980/",,"1.031217",; 
	"http://192.168.1.3:7980/ws/WS_ALIANCA.apw")

::Init()
::oWSINTEGRAWSRESULT:SoapRecv( WSAdvValue( oXmlRet,"_INTEGRAWSRESPONSE:_INTEGRAWSRESULT","RETORNOWS",NIL,NIL,NIL,NIL,NIL,NIL) )

END WSMETHOD

oXmlRet := NIL
Return .T.


// WSDL Data Structure RETORNOWS

WSSTRUCT WS_ALIANCA_RETORNOWS
	WSDATA   cMENSAGENS                AS string OPTIONAL
	WSDATA   cRESULTADO                AS string
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WS_ALIANCA_RETORNOWS
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WS_ALIANCA_RETORNOWS
Return

WSMETHOD CLONE WSCLIENT WS_ALIANCA_RETORNOWS
	Local oClone := WS_ALIANCA_RETORNOWS():NEW()
	oClone:cMENSAGENS           := ::cMENSAGENS
	oClone:cRESULTADO           := ::cRESULTADO
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT WS_ALIANCA_RETORNOWS
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::cMENSAGENS         :=  WSAdvValue( oResponse,"_MENSAGENS","string",NIL,NIL,NIL,"S",NIL,NIL) 
	::cRESULTADO         :=  WSAdvValue( oResponse,"_RESULTADO","string",NIL,"Property cRESULTADO as s:string on SOAP Response not found.",NIL,"S",NIL,NIL) 
Return


