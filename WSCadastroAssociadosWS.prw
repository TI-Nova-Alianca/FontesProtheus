// Programa.:  WSCadastroAssociadosWS
// Autor....:  Cláudia Lionço
// Data.....:  08/10/2024
// Descricao:  Acessa web service do NaWeb - Grava dados de fornecedor-associado
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cliente_web_service
// #Descricao         #Acessa web service do NaWeb - Grava dados de fornecedor-associado
// #PalavasChave      #web_service #naweb #notificacoes
// #TabelasPrincipais #
// #Modulos           #Todos
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------------
#INCLUDE "protheus.ch"
#INCLUDE "apwebsrv.ch"

User Function _SLMRJNA ; Return  // "dummy" function - Internal Use 

//
// ----------------------------------------------------------------------------------------
WSCLIENT WSCadastroAssociadosWS
	WSMETHOD NEW
	WSMETHOD Execute

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   cEntrada                  AS string
	WSDATA   cSaida                    AS string
ENDWSCLIENT
//
// ----------------------------------------------------------------------------------------
WSMETHOD NEW WSCLIENT WSCadastroAssociadosWS
	If !FindFunction("XMLCHILDEX")
		UserException("O Codigo-Fonte Client atual requer os executaveis do Protheus Build [7.00.210324P-20220608] ou superior. Atualize o Protheus ou gere o Codigo-Fonte novamente utilizando o Build atual.")
	EndIf
Return Self
//
// ----------------------------------------------------------------------------------------
WSMETHOD Execute WSSEND cEntrada WSRECEIVE cSaida WSCLIENT WSCadastroAssociadosWS
	Local cSoap := ""
	local _sURI := ''
	private oXmlRet

	BEGIN WSMETHOD

	//_sURI = "http://naweb17.novaalianca.coop.br/cadastroassociadosWS.aspx?wsdl"
	_sURI = "http://naweb.novaalianca.coop.br/cadastroassociadosWS.aspx?wsdl"

	cSoap += '<CadastroAssociadosWS.Execute xmlns="NAWeb">'
	cSoap += WSSoapValue("Entrada", ::cEntrada, cEntrada , "string", .T. , .F., 0 , NIL, .F.,.F.) 
	cSoap += "</CadastroAssociadosWS.Execute>"
    
	oXmlRet := SvcSoapCall(	Self,;
							cSoap,; 
							"NAWebaction/ACADASTROASSOCIADOSWS.Execute",; 
							"DOCUMENT","NAWeb",,,; 
							_sURI)  

	::cSaida = oXmlRet:_CADASTROASSOCIADOSWS_EXECUTERESPONSE:_RETORNO:TEXT

	END WSMETHOD

	oXmlRet := NIL
Return .T.
