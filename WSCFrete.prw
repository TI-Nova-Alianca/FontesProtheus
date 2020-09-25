#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWEBSRV.CH"

/* ===============================================================================
WSDL Location    https://ws.entregou.com/WSFrete?wsdl
Gerado em        08/08/17 10:25:48
Observações      Código-Fonte gerado por ADVPL WSDL Client 1.120703
                 Alterações neste arquivo podem causar funcionamento incorreto
                 e serão perdidas caso o código-fonte seja gerado novamente.
=============================================================================== */

User Function VACFFRET ; Return  // "dummy" function - Internal Use 

/* -------------------------------------------------------------------------------
WSDL Service WSCFrete
------------------------------------------------------------------------------- */

WSCLIENT WSCFrete

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD CalcularFreteDataEntrega

	WSDATA   _URL                      AS String
	WSDATA   _HEADOUT                  AS Array of String
	WSDATA   _COOKIES                  AS Array of String
	WSDATA   oWSCalcularFreteDataEntregaentradaCalculo AS WSFrete_reqCalcularFreteDataEntrega
	WSDATA   oWSCalcularFreteDataEntregasaidaCalculo AS WSFrete_retCalcularFreteDataEntrega

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSCFrete
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.131227A-20151103] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSCFrete
	::oWSCalcularFreteDataEntregaentradaCalculo := WSFrete_REQCALCULARFRETEDATAENTREGA():New()
	::oWSCalcularFreteDataEntregasaidaCalculo := WSFrete_RETCALCULARFRETEDATAENTREGA():New()
Return

WSMETHOD RESET WSCLIENT WSCFrete
	::oWSCalcularFreteDataEntregaentradaCalculo := NIL 
	::oWSCalcularFreteDataEntregasaidaCalculo := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSCFrete
Local oClone := WSCFrete():New()
	oClone:_URL          := ::_URL 
	oClone:oWSCalcularFreteDataEntregaentradaCalculo :=  IIF(::oWSCalcularFreteDataEntregaentradaCalculo = NIL , NIL ,::oWSCalcularFreteDataEntregaentradaCalculo:Clone() )
	oClone:oWSCalcularFreteDataEntregasaidaCalculo :=  IIF(::oWSCalcularFreteDataEntregasaidaCalculo = NIL , NIL ,::oWSCalcularFreteDataEntregasaidaCalculo:Clone() )
Return oClone

// WSDL Method CalcularFreteDataEntrega of Service WSCFrete

WSMETHOD CalcularFreteDataEntrega WSSEND oWSCalcularFreteDataEntregaentradaCalculo WSRECEIVE oWSCalcularFreteDataEntregasaidaCalculo WSCLIENT WSCFrete
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<q1:CalcularFreteDataEntrega xmlns:q1="http://ws.entregou.com/WSFrete">'
cSoap += WSSoapValue("entradaCalculo", ::oWSCalcularFreteDataEntregaentradaCalculo, oWSCalcularFreteDataEntregaentradaCalculo , "reqCalcularFreteDataEntrega", .T. , .T. , 0 , NIL, .F.) 
cSoap += "</q1:CalcularFreteDataEntrega>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://ws.entregou.com/WSFreteCalcularFreteDataEntrega",; 
	"RPCX","http://ws.entregou.com/WSFrete",,,; 
	"http://ws.entregou.com/WSFrete")

::Init()
::oWSCalcularFreteDataEntregasaidaCalculo:SoapRecv( WSAdvValue( oXmlRet,"_SAIDACALCULO","retCalcularFreteDataEntrega",NIL,NIL,NIL,"O",NIL,NIL) )

END WSMETHOD

oXmlRet := NIL
Return .T.


// WSDL Data Structure reqCalcularFreteDataEntrega

WSSTRUCT WSFrete_reqCalcularFreteDataEntrega
	WSDATA   ctoken                    AS string
	WSDATA   cCNPJTomador              AS string
	WSDATA   cCNPJDestinatario         AS string OPTIONAL
	WSDATA   oWSTransportador          AS WSFrete_reqTransportador OPTIONAL
	WSDATA   cCEPOrigem                AS string
	WSDATA   cCEPDestino               AS string
	WSDATA   nModal                    AS integer OPTIONAL
	WSDATA   cTipoCarga                AS string OPTIONAL
	WSDATA   dDataEmbarque             AS date OPTIONAL
	WSDATA   oWSCalculoFrete           AS WSFrete_reqCalculoFrete OPTIONAL
	WSDATA   oWSCorreios               AS WSFrete_reqCorreios OPTIONAL
	WSDATA   cSomenteCorreios          AS string OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_reqCalcularFreteDataEntrega
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_reqCalcularFreteDataEntrega
Return

WSMETHOD CLONE WSCLIENT WSFrete_reqCalcularFreteDataEntrega
	Local oClone := WSFrete_reqCalcularFreteDataEntrega():NEW()
	oClone:ctoken               := ::ctoken
	oClone:cCNPJTomador         := ::cCNPJTomador
	oClone:cCNPJDestinatario    := ::cCNPJDestinatario
	oClone:oWSTransportador     := IIF(::oWSTransportador = NIL , NIL , ::oWSTransportador:Clone() )
	oClone:cCEPOrigem           := ::cCEPOrigem
	oClone:cCEPDestino          := ::cCEPDestino
	oClone:nModal               := ::nModal
	oClone:cTipoCarga           := ::cTipoCarga
	oClone:dDataEmbarque        := ::dDataEmbarque
	oClone:oWSCalculoFrete      := IIF(::oWSCalculoFrete = NIL , NIL , ::oWSCalculoFrete:Clone() )
	oClone:oWSCorreios          := IIF(::oWSCorreios = NIL , NIL , ::oWSCorreios:Clone() )
	oClone:cSomenteCorreios     := ::cSomenteCorreios
Return oClone

WSMETHOD SOAPSEND WSCLIENT WSFrete_reqCalcularFreteDataEntrega
	Local cSoap := ""
	cSoap += WSSoapValue("token", ::ctoken, ::ctoken , "string", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("CNPJTomador", ::cCNPJTomador, ::cCNPJTomador , "string", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("CNPJDestinatario", ::cCNPJDestinatario, ::cCNPJDestinatario , "string", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("Transportador", ::oWSTransportador, ::oWSTransportador , "reqTransportador", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("CEPOrigem", ::cCEPOrigem, ::cCEPOrigem , "string", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("CEPDestino", ::cCEPDestino, ::cCEPDestino , "string", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("Modal", ::nModal, ::nModal , "integer", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("TipoCarga", ::cTipoCarga, ::cTipoCarga , "string", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("DataEmbarque", ::dDataEmbarque, ::dDataEmbarque , "date", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("CalculoFrete", ::oWSCalculoFrete, ::oWSCalculoFrete , "reqCalculoFrete", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("Correios", ::oWSCorreios, ::oWSCorreios , "reqCorreios", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("SomenteCorreios", ::cSomenteCorreios, ::cSomenteCorreios , "string", .F. , .T., 0 , NIL, .F.) 
Return cSoap

// WSDL Data Structure reqTransportador

WSSTRUCT WSFrete_reqTransportador
	WSDATA   cCNPJ                     AS string
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_reqTransportador
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_reqTransportador
	::cCNPJ                := {} // Array Of  ""
Return

WSMETHOD CLONE WSCLIENT WSFrete_reqTransportador
	Local oClone := WSFrete_reqTransportador():NEW()
	oClone:cCNPJ                := IIf(::cCNPJ <> NIL , aClone(::cCNPJ) , NIL )
Return oClone

WSMETHOD SOAPSEND WSCLIENT WSFrete_reqTransportador
	Local cSoap := ""
	aEval( ::cCNPJ , {|x| cSoap := cSoap  +  WSSoapValue("CNPJ", x , x , "string", .T. , .T., 0 , NIL, .F.)  } ) 
Return cSoap

// WSDL Data Structure reqCalculoFrete

WSSTRUCT WSFrete_reqCalculoFrete
	WSDATA   nValorNF                  AS decimal OPTIONAL
	WSDATA   npesoKg                   AS decimal
	WSDATA   npesoM3                   AS decimal
	WSDATA   nICMS                     AS decimal OPTIONAL
	WSDATA   cxCaracAd                 AS string OPTIONAL
	WSDATA   cxCaracSer                AS string OPTIONAL
	WSDATA   nqtdeVolumes              AS decimal OPTIONAL
	WSDATA   nTipoFrete                AS integer OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_reqCalculoFrete
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_reqCalculoFrete
Return

WSMETHOD CLONE WSCLIENT WSFrete_reqCalculoFrete
	Local oClone := WSFrete_reqCalculoFrete():NEW()
	oClone:nValorNF             := ::nValorNF
	oClone:npesoKg              := ::npesoKg
	oClone:npesoM3              := ::npesoM3
	oClone:nICMS                := ::nICMS
	oClone:cxCaracAd            := ::cxCaracAd
	oClone:cxCaracSer           := ::cxCaracSer
	oClone:nqtdeVolumes         := ::nqtdeVolumes
	oClone:nTipoFrete           := ::nTipoFrete
Return oClone

WSMETHOD SOAPSEND WSCLIENT WSFrete_reqCalculoFrete
	Local cSoap := ""
	cSoap += WSSoapValue("ValorNF", ::nValorNF, ::nValorNF , "decimal", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("pesoKg", ::npesoKg, ::npesoKg , "decimal", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("pesoM3", ::npesoM3, ::npesoM3 , "decimal", .T. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("ICMS", ::nICMS, ::nICMS , "decimal", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("xCaracAd", ::cxCaracAd, ::cxCaracAd , "string", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("xCaracSer", ::cxCaracSer, ::cxCaracSer , "string", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("qtdeVolumes", ::nqtdeVolumes, ::nqtdeVolumes , "decimal", .F. , .T., 0 , NIL, .F.) 
	cSoap += WSSoapValue("TipoFrete", ::nTipoFrete, ::nTipoFrete , "integer", .F. , .T., 0 , NIL, .F.) 
Return cSoap

// WSDL Data Structure reqCorreios

WSSTRUCT WSFrete_reqCorreios
	WSDATA   oWSServicosCorreios       AS WSFrete_reqServicosCorreios
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_reqCorreios
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_reqCorreios
Return

WSMETHOD CLONE WSCLIENT WSFrete_reqCorreios
	Local oClone := WSFrete_reqCorreios():NEW()
	oClone:oWSServicosCorreios  := IIF(::oWSServicosCorreios = NIL , NIL , ::oWSServicosCorreios:Clone() )
Return oClone

WSMETHOD SOAPSEND WSCLIENT WSFrete_reqCorreios
	Local cSoap := ""
	cSoap += WSSoapValue("ServicosCorreios", ::oWSServicosCorreios, ::oWSServicosCorreios , "reqServicosCorreios", .T. , .T., 0 , NIL, .F.) 
Return cSoap

// WSDL Data Structure retCalcularFreteDataEntrega

WSSTRUCT WSFrete_retCalcularFreteDataEntrega
	WSDATA   cErro                     AS string OPTIONAL
	WSDATA   oWSTransportador          AS WSFrete_retTransportador OPTIONAL
	WSDATA   nProtocolo                AS integer OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_retCalcularFreteDataEntrega
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_retCalcularFreteDataEntrega
	::oWSTransportador     := {} // Array Of  WSFrete_RETTRANSPORTADOR():New()
Return

WSMETHOD CLONE WSCLIENT WSFrete_retCalcularFreteDataEntrega
	Local oClone := WSFrete_retCalcularFreteDataEntrega():NEW()
	oClone:cErro                := ::cErro
	oClone:oWSTransportador := NIL
	If ::oWSTransportador <> NIL 
		oClone:oWSTransportador := {}
		aEval( ::oWSTransportador , { |x| aadd( oClone:oWSTransportador , x:Clone() ) } )
	Endif 
	oClone:nProtocolo           := ::nProtocolo
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT WSFrete_retCalcularFreteDataEntrega
	Local nRElem2 , nTElem2
	Local aNodes2 := WSRPCGetNode(oResponse,.T.)
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::cErro              :=  WSAdvValue( oResponse,"_ERRO","string",NIL,NIL,NIL,"S",NIL,NIL) 
	nTElem2 := len(aNodes2)
	For nRElem2 := 1 to nTElem2 
		If !WSIsNilNode( aNodes2[nRElem2] )
			aadd(::oWSTransportador , WSFrete_retTransportador():New() )
  			::oWSTransportador[len(::oWSTransportador)]:SoapRecv(aNodes2[nRElem2])
		Endif
	Next
	::nProtocolo         :=  WSAdvValue( oResponse,"_PROTOCOLO","integer",NIL,NIL,NIL,"N",NIL,NIL) 
Return

// WSDL Data Structure reqServicosCorreios

WSSTRUCT WSFrete_reqServicosCorreios
	WSDATA   cCodigoServico            AS string
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPSEND
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_reqServicosCorreios
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_reqServicosCorreios
	::cCodigoServico       := {} // Array Of  ""
Return

WSMETHOD CLONE WSCLIENT WSFrete_reqServicosCorreios
	Local oClone := WSFrete_reqServicosCorreios():NEW()
	oClone:cCodigoServico       := IIf(::cCodigoServico <> NIL , aClone(::cCodigoServico) , NIL )
Return oClone

WSMETHOD SOAPSEND WSCLIENT WSFrete_reqServicosCorreios
	Local cSoap := ""
	aEval( ::cCodigoServico , {|x| cSoap := cSoap  +  WSSoapValue("CodigoServico", x , x , "string", .T. , .T., 0 , NIL, .F.)  } ) 
Return cSoap

// WSDL Data Structure retTransportador

WSSTRUCT WSFrete_retTransportador
	WSDATA   cCNPJ                     AS string OPTIONAL
	WSDATA   cNomeFantasia             AS string OPTIONAL
	WSDATA   nModal                    AS integer OPTIONAL
	WSDATA   cTipoCarga                AS string OPTIONAL
	WSDATA   nServicoCorreios          AS integer OPTIONAL
	WSDATA   cErroPrazo                AS string OPTIONAL
	WSDATA   oWSPrazoEntrega           AS WSFrete_retPrazoEntrega OPTIONAL
	WSDATA   cErroFrete                AS string OPTIONAL
	WSDATA   oWSFreteCalculado         AS WSFrete_retFreteCalculado OPTIONAL
	WSDATA   nTipoFrete                AS integer OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_retTransportador
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_retTransportador
Return

WSMETHOD CLONE WSCLIENT WSFrete_retTransportador
	Local oClone := WSFrete_retTransportador():NEW()
	oClone:cCNPJ                := ::cCNPJ
	oClone:cNomeFantasia        := ::cNomeFantasia
	oClone:nModal               := ::nModal
	oClone:cTipoCarga           := ::cTipoCarga
	oClone:nServicoCorreios     := ::nServicoCorreios
	oClone:cErroPrazo           := ::cErroPrazo
	oClone:oWSPrazoEntrega      := IIF(::oWSPrazoEntrega = NIL , NIL , ::oWSPrazoEntrega:Clone() )
	oClone:cErroFrete           := ::cErroFrete
	oClone:oWSFreteCalculado    := IIF(::oWSFreteCalculado = NIL , NIL , ::oWSFreteCalculado:Clone() )
	oClone:nTipoFrete           := ::nTipoFrete
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT WSFrete_retTransportador
	Local oNode7
	Local oNode9
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::cCNPJ              :=  WSAdvValue( oResponse,"_CNPJ","string",NIL,NIL,NIL,"S",NIL,NIL) 
	::cNomeFantasia      :=  WSAdvValue( oResponse,"_NOMEFANTASIA","string",NIL,NIL,NIL,"S",NIL,NIL) 
	::nModal             :=  WSAdvValue( oResponse,"_MODAL","integer",NIL,NIL,NIL,"N",NIL,NIL) 
	::cTipoCarga         :=  WSAdvValue( oResponse,"_TIPOCARGA","string",NIL,NIL,NIL,"S",NIL,NIL) 
	::nServicoCorreios   :=  WSAdvValue( oResponse,"_SERVICOCORREIOS","integer",NIL,NIL,NIL,"N",NIL,NIL) 
	::cErroPrazo         :=  WSAdvValue( oResponse,"_ERROPRAZO","string",NIL,NIL,NIL,"S",NIL,NIL) 
	oNode7 :=  WSAdvValue( oResponse,"_PRAZOENTREGA","retPrazoEntrega",NIL,NIL,NIL,"O",NIL,NIL) 
	If oNode7 != NIL
		::oWSPrazoEntrega := WSFrete_retPrazoEntrega():New()
		::oWSPrazoEntrega:SoapRecv(oNode7)
	EndIf
	::cErroFrete         :=  WSAdvValue( oResponse,"_ERROFRETE","string",NIL,NIL,NIL,"S",NIL,NIL) 
	oNode9 :=  WSAdvValue( oResponse,"_FRETECALCULADO","retFreteCalculado",NIL,NIL,NIL,"O",NIL,NIL) 
	If oNode9 != NIL
		::oWSFreteCalculado := WSFrete_retFreteCalculado():New()
		::oWSFreteCalculado:SoapRecv(oNode9)
	EndIf
	::nTipoFrete         :=  WSAdvValue( oResponse,"_TIPOFRETE","integer",NIL,NIL,NIL,"N",NIL,NIL) 
Return

// WSDL Data Structure retPrazoEntrega

WSSTRUCT WSFrete_retPrazoEntrega
	WSDATA   dDataPrevisao             AS date
	WSDATA   nDiasEntrega              AS integer
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_retPrazoEntrega
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_retPrazoEntrega
Return

WSMETHOD CLONE WSCLIENT WSFrete_retPrazoEntrega
	Local oClone := WSFrete_retPrazoEntrega():NEW()
	oClone:dDataPrevisao        := ::dDataPrevisao
	oClone:nDiasEntrega         := ::nDiasEntrega
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT WSFrete_retPrazoEntrega
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::dDataPrevisao      :=  WSAdvValue( oResponse,"_DATAPREVISAO","date",NIL,"Property dDataPrevisao as s:date on SOAP Response not found.",NIL,"D",NIL,NIL) 
	::nDiasEntrega       :=  WSAdvValue( oResponse,"_DIASENTREGA","integer",NIL,"Property nDiasEntrega as s:integer on SOAP Response not found.",NIL,"N",NIL,NIL) 
Return

// WSDL Data Structure retFreteCalculado

WSSTRUCT WSFrete_retFreteCalculado
	WSDATA   nValorFrete               AS decimal
	WSDATA   nValorTaxas               AS decimal
	WSDATA   nValorTotal               AS decimal
	WSDATA   ncdTabela                 AS integer OPTIONAL
	WSDATA   cstTabela                 AS string OPTIONAL
	WSDATA   ncdRota                   AS integer OPTIONAL
	WSDATA   cstRota                   AS string OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT WSFrete_retFreteCalculado
	::Init()
Return Self

WSMETHOD INIT WSCLIENT WSFrete_retFreteCalculado
Return

WSMETHOD CLONE WSCLIENT WSFrete_retFreteCalculado
	Local oClone := WSFrete_retFreteCalculado():NEW()
	oClone:nValorFrete          := ::nValorFrete
	oClone:nValorTaxas          := ::nValorTaxas
	oClone:nValorTotal          := ::nValorTotal
	oClone:ncdTabela            := ::ncdTabela
	oClone:cstTabela            := ::cstTabela
	oClone:ncdRota              := ::ncdRota
	oClone:cstRota              := ::cstRota
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT WSFrete_retFreteCalculado
	::Init()
	If oResponse = NIL ; Return ; Endif 
	::nValorFrete        :=  WSAdvValue( oResponse,"_VALORFRETE","decimal",NIL,"Property nValorFrete as s:decimal on SOAP Response not found.",NIL,"N",NIL,NIL) 
	::nValorTaxas        :=  WSAdvValue( oResponse,"_VALORTAXAS","decimal",NIL,"Property nValorTaxas as s:decimal on SOAP Response not found.",NIL,"N",NIL,NIL) 
	::nValorTotal        :=  WSAdvValue( oResponse,"_VALORTOTAL","decimal",NIL,"Property nValorTotal as s:decimal on SOAP Response not found.",NIL,"N",NIL,NIL) 
	::ncdTabela          :=  WSAdvValue( oResponse,"_CDTABELA","integer",NIL,NIL,NIL,"N",NIL,NIL) 
	::cstTabela          :=  WSAdvValue( oResponse,"_STTABELA","string",NIL,NIL,NIL,"S",NIL,NIL) 
	::ncdRota            :=  WSAdvValue( oResponse,"_CDROTA","integer",NIL,NIL,NIL,"N",NIL,NIL) 
	::cstRota            :=  WSAdvValue( oResponse,"_STROTA","string",NIL,NIL,NIL,"S",NIL,NIL) 
Return
