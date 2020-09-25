/*
+------------------------------------------------------+
| Programa: VAGERANE                                   |
| Desc.:Acessa NAWeb, manda gerar anexos e retorna lista para envio|
| Data: 13/04/2018                                     |
| Autor: PEDRONI                                           |
+------------------------------------------------------+
*/

#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

/* ===============================================================================
WSDL Location    http://naweb.novaalianca.coop.br/aprcnucgeraranexos.aspx?wsdl
Gerado em        04/13/18 09:14:04
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

User Function _NLKSXSR ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSPrcNucGerarAnexos
------------------------------------------------------------------------------- */

WSCLIENT WSPrcNucGerarAnexos

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD Execute

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cTrnnucanexovinculoori    AS string
	WSDATA   cTrnnucanexovinculocha    AS string
	WSDATA   cTrnnucanexotipouso       AS string
	WSDATA   cretval                   AS string

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSPrcNucGerarAnexos
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20180315 NG] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSPrcNucGerarAnexos
Return

WSMETHOD RESET WSCLIENT WSPrcNucGerarAnexos
	::cTrnnucanexovinculoori := NIL 
	::cTrnnucanexovinculocha := NIL 
	::cTrnnucanexotipouso := NIL 
	::cretval            := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSPrcNucGerarAnexos
Local oClone := WSPrcNucGerarAnexos():New()
	oClone:_URL          := ::_URL 
	oClone:cTrnnucanexovinculoori := ::cTrnnucanexovinculoori
	oClone:cTrnnucanexovinculocha := ::cTrnnucanexovinculocha
	oClone:cTrnnucanexotipouso := ::cTrnnucanexotipouso
	oClone:cretval       := ::cretval
Return oClone

// WSDL Method Execute of Service WSPrcNucGerarAnexos

WSMETHOD Execute WSSEND cTrnnucanexovinculoori,cTrnnucanexovinculocha,cTrnnucanexotipouso WSRECEIVE cretval WSCLIENT WSPrcNucGerarAnexos
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<PrcNucGerarAnexos.Execute xmlns="NAWeb">'
cSoap += WSSoapValue("Trnnucanexovinculoori", ::cTrnnucanexovinculoori, cTrnnucanexovinculoori , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += WSSoapValue("Trnnucanexovinculocha", ::cTrnnucanexovinculocha, cTrnnucanexovinculocha , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += WSSoapValue("Trnnucanexotipouso", ::cTrnnucanexotipouso, cTrnnucanexotipouso , "string", .T. , .F., 0 , NIL, .F.,.F.) 
cSoap += "</PrcNucGerarAnexos.Execute>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"NAWebaction/APRCNUCGERARANEXOS.Execute",; 
	"DOCUMENT","NAWeb",,,; 
	"http://naweb.novaalianca.coop.br/aprcnucgeraranexos.aspx")

::Init()
::cretval            :=  WSAdvValue( oXmlRet,"_PRCNUCGERARANEXOS.EXECUTERESPONSE:_RETVAL:TEXT","string",NIL,NIL,NIL,NIL,NIL,NIL) 

END WSMETHOD

oXmlRet := NIL
Return .T.

User Function GAnexos(_aProds)
	Local _oDlg := nil
	Private _aCaminho := {}
	#define DS_MODALFRAME 128
	define msdialog _oDlg from 0, 0 to 0, 300 of oMainWnd pixel title "Gerando Anexos... Aguarde..." Style DS_MODALFRAME
	activate msdialog _oDlg center on init (_GAnexo(_aProds), _oDlg:End())
Return _aCaminho

Static Function _GAnexo(_aProds)
	Local _aDir := {}
	Local _nProd := 0
	Local _nDir := 0
	Local _sXML := ""

	for _nProd = 1 to len (_aProds)
	
		//Limpar
		_aDir := Directory ("\\192.168.1.3\Siga\Protheus12\protheus_data\NAWeb\" + _aProds[_nProd] + "*.*")
		For _nDir = 1 to len (_aDir)
			//MsgAlert("Excluir: " + _aDir[_nDir, 1])
			FErase("\\192.168.1.3\Siga\Protheus12\protheus_data\NAWeb\" + _aDir[_nDir, 1])
		Next
	
		//MsgAlert("Ferase")
		/*
		oAnexo := WSPrcNucGerarAnexos():New()
		oAnexo:cTrnnucanexovinculoori := "GX0004_PRODUTOS" 
		oAnexo:cTrnnucanexovinculocha := _aProds[_nProd]
		oAnexo:cTrnnucanexotipouso    := "COM"
		oAnexo:Execute()
		*/
		
		_sXML += '<SdtNucParametro xmlns="NAWeb">'
		_sXML += '    <SdtNucParametroItem>'
		_sXML += '        <SdtNucParametroNome>Funcionalidade</SdtNucParametroNome>'
		_sXML += '        <SdtNucParametroValor>GERAR_ANEXOS</SdtNucParametroValor>'
		_sXML += '    </SdtNucParametroItem>'
		_sXML += '    <SdtNucParametroItem>'
		_sXML += '        <SdtNucParametroNome>TrnNucAnexoVinculoOri</SdtNucParametroNome>'
		_sXML += '        <SdtNucParametroValor>GX0004_PRODUTOS</SdtNucParametroValor>'
		_sXML += '    </SdtNucParametroItem>'
		_sXML += '    <SdtNucParametroItem>'
		_sXML += '        <SdtNucParametroNome>TrnNucAnexoVinculoCha</SdtNucParametroNome>'
		_sXML += '        <SdtNucParametroValor>' + _aProds[_nProd] + '</SdtNucParametroValor>'
		_sXML += '    </SdtNucParametroItem>'
		_sXML += '    <SdtNucParametroItem>'
		_sXML += '        <SdtNucParametroNome>TrnNucAnexoTipoUso</SdtNucParametroNome>'
		_sXML += '        <SdtNucParametroValor>COM</SdtNucParametroValor>'
		_sXML += '    </SdtNucParametroItem>'
		_sXML += '</SdtNucParametro>'		

		oAnexo := WSPrcNucWebService():New()
		oAnexo:cEntrada := _sXML
		oAnexo:Execute()
		//U_Help(oAnexo:cSaida)
		
		//Busca
		_aDir = Directory ("\\192.168.1.3\Siga\Protheus12\protheus_data\NAWeb\" + _aProds[_nProd] + "*.*")
		For _nDir = 1 to len (_aDir)
			Aadd(_aCaminho, "\NAWeb\" + _aDir[_nDir, 1])
		Next
		
	Next
Return


