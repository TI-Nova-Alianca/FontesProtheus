#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"

/* ===============================================================================
WSDL Location    https://portalnfe.wmne.com.br/Gnfe_Port_ws/cls_403_nfe_xml.asmx?WSDL
Gerado em        11/06/12 11:20:28
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

//User Function _POOKLRR ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WScls_ne_nfe_xml
------------------------------------------------------------------------------- */

WSCLIENT WScls_ne_nfe_xml

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD fu_upld

	WSDATA   _URL                      AS String
	WSDATA   _CERT                     AS String
	WSDATA   _PRIVKEY                  AS String
	WSDATA   _PASSPHRASE               AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cpa_tp_cd_usua            AS string
	WSDATA   npa_cd_usua               AS decimal
	WSDATA   cpa_ds_xml_nfe            AS string
	WSDATA   oWSfu_upldResult          AS cls_ne_nfe_xml_SqlExecutionRetn

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WScls_ne_nfe_xml
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.111010P-20120120] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WScls_ne_nfe_xml
	::oWSfu_upldResult   := cls_ne_nfe_xml_SQLEXECUTIONRETN():New()
Return

WSMETHOD RESET WSCLIENT WScls_ne_nfe_xml
	::cpa_tp_cd_usua     := NIL 
	::npa_cd_usua        := NIL 
	::cpa_ds_xml_nfe     := NIL 
	::oWSfu_upldResult   := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WScls_ne_nfe_xml
Local oClone := WScls_ne_nfe_xml():New()
	oClone:_URL          := ::_URL 
	oClone:_CERT         := ::_CERT 
	oClone:_PRIVKEY      := ::_PRIVKEY 
	oClone:_PASSPHRASE   := ::_PASSPHRASE 
	oClone:cpa_tp_cd_usua := ::cpa_tp_cd_usua
	oClone:npa_cd_usua   := ::npa_cd_usua
	oClone:cpa_ds_xml_nfe := ::cpa_ds_xml_nfe
	oClone:oWSfu_upldResult :=  IIF(::oWSfu_upldResult = NIL , NIL ,::oWSfu_upldResult:Clone() )
Return oClone

// WSDL Method fu_upld of Service WScls_ne_nfe_xml

WSMETHOD fu_upld WSSEND cpa_tp_cd_usua,npa_cd_usua,cpa_ds_xml_nfe WSRECEIVE oWSfu_upldResult WSCLIENT WScls_ne_nfe_xml
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<fu_upld xmlns="http://www.pontsystems.com.br/">'
cSoap += WSSoapValue("pa_tp_cd_usua", ::cpa_tp_cd_usua, cpa_tp_cd_usua , "string", .F. , .F., 0 , NIL, .F.) 
cSoap += WSSoapValue("pa_cd_usua", ::npa_cd_usua, npa_cd_usua , "decimal", .T. , .F., 0 , NIL, .F.) 
cSoap += WSSoapValue("pa_ds_xml_nfe", ::cpa_ds_xml_nfe, cpa_ds_xml_nfe , "string", .F. , .F., 0 , NIL, .F.) 
cSoap += "</fu_upld>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://www.pontsystems.com.br/fu_upld",; 
	"DOCUMENT","http://www.pontsystems.com.br/",,,; 
	"https://portalnfe.wmne.com.br/Gnfe_Port_ws/cls_403_nfe_xml.asmx")

::Init()
::oWSfu_upldResult:SoapRecv( WSAdvValue( oXmlRet,"_FU_UPLDRESPONSE:_FU_UPLDRESULT","SqlExecutionRetn",NIL,NIL,NIL,NIL,NIL,NIL) )

END WSMETHOD

oXmlRet := NIL
Return .T.


// WSDL Data Structure SqlExecutionRetn

WSSTRUCT cls_ne_nfe_xml_SqlExecutionRetn
	WSDATA   nreturn_code              AS int
	WSDATA   creturn_chav              AS string OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT cls_ne_nfe_xml_SqlExecutionRetn
	::Init()
Return Self

WSMETHOD INIT WSCLIENT cls_ne_nfe_xml_SqlExecutionRetn
Return

WSMETHOD CLONE WSCLIENT cls_ne_nfe_xml_SqlExecutionRetn
	Local oClone := cls_ne_nfe_xml_SqlExecutionRetn():NEW()
	oClone:nreturn_code         := ::nreturn_code
	oClone:creturn_chav         := ::creturn_chav
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT cls_ne_nfe_xml_SqlExecutionRetn
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::nreturn_code       :=  WSAdvValue( oResponse,"_RETURN_CODE","int",NIL,"Property nreturn_code as s:int on SOAP Response not found.",NIL,"N",NIL,NIL) 
	::creturn_chav       :=  WSAdvValue( oResponse,"_RETURN_CHAV","string",NIL,NIL,NIL,"S",NIL,NIL) 
Return


