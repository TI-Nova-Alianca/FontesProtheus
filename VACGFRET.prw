//#include 'totvs.ch'
#include 'VA_Inclu.prw'
/*
#TRANSLATE	.CNPJ		=>	1
#TRANSLATE	.NOME		=>	2
#TRANSLATE	.MODAL		=>	3
#TRANSLATE	.TPFRETE	=>	4
#TRANSLATE	.STTABELA	=>	5
#TRANSLATE	.ROTA		=>	6
#TRANSLATE	.CDTABELA	=>	7
#TRANSLATE	.VLRFRETE	=>	8
#TRANSLATE	.VLRTAXA	=>	9
#TRANSLATE	.VLRTOTAL	=>	10
#TRANSLATE	.DTPREV		=>	11
#TRANSLATE	.DIASENT	=>	12
#TRANSLATE	.MAX		=>	12
*/
/**
* @author      Daniel Scheeren
* @copyright   PROCDATA 
* @name        VACGFRET
* @param       {}
* @return      @Bolean
* @date        08/08/2017                                                 
* @modulo      @FATURAMENTO
* @pendency    {}
* @description 		Programa de envio e retorno de dados via WSDL para portal entregou.com
* 
*********************************************
*****@atualizacoes 		
****@authorAtt      	
****@dateAtt        	
****@descriptionAtt		
*********************************************
*/ 

User Function VACGFRET (_sCNPJDest, _sCEPDest, _dEmbarq, _nQtVol, _sTpFrete, _nVlrNF, _nPeso, _nCubag, _nAliqICM, _aCandidat)
	local _lContinua := .T.
	Local oSvc		:=	NIL
	Local oTransp	:=	NIL
	Local oNfVal	:=	NIL
	Local oReturn	:=	NIL
	//Local lCancel	:= .F.
	//Local nVolumes  := 0
	//Local nTPFrete	:= 1
	local _aRet		:= {}
	local nLinha	:= 0
	
	if _lContinua
		oSvc := WSCFrete():New()
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:ctoken				:=	"1AB4038AE0024D5E13A004BC05CE38C3B57E9DA6"	//AS string
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cCNPJTomador			:=	'88612486000160' // Sempre a matriz, pois nao temos contrato das filiais com a E-Sales...   SM0->M0_CGC		//AS string
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cCNPJDestinatario	:=	_sCNPJDest		//AS string OPTIONAL
	
		oTransp	:=	WSFrete_reqTransportador():New()
		oTransp:cCNPJ := aclone (_aCandidat)

		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:oWSTransportador		:=	oTransp					//AS WSFrete_reqTransportador OPTIONAL
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cCEPOrigem			:=	sm0 -> m0_cepcob		//AS string
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cCEPDestino			:=	_sCEPDest				//AS string
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:nModal				:=	1						//AS integer OPTIONAL
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cTipoCarga			:=	'A'						//AS string OPTIONAL
		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:dDataEmbarque		:=	_dEmbarq				//AS date OPTIONAL

		oNfVal	:=	WSFrete_reqCalculoFrete():New()
		oNfVal:nValorNF			:=	round (_nVlrNF, 2) 				//SF2->F2_VALBRUT		//AS decimal OPTIONAL
		oNfVal:npesoKg			:=	round (_nPeso, 0) 				//SF2->F2_PBRUTO		//AS decimal
		oNfVal:npesoM3			:=	round (_nCubag, 0)				//(B5_ECCUBAG)			//AS decimal
		oNfVal:nICMS			:=	round (_nAliqICM, 2) 			//AS decimal OPTIONAL
		oNfVal:nqtdeVolumes		:=	round (_nQtVol, 0) 				//nVolumes				//AS decimal OPTIONAL
		oNfVal:nTipoFrete		:=	iif (_sTpFrete == "C", 1, 2) 	//nTPFrete				//AS integer OPTIONAL

		oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:oWSCalculoFrete		:=	oNfVal           		//AS WSFrete_reqCalculoFrete OPTIONAL
		
		//oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:oWSCorreios               //AS WSFrete_reqCorreios OPTIONAL
		//oSvc:oWSCalcularFreteDataEntregaEntradaCalculo:cSomenteCorreios          //AS string OPTIONAL

		If oSvc:CalcularFreteDataEntrega()
			oReturn	:=	oSvc:oWSCalcularFreteDataEntregasaidaCalculo

			If !Empty(oReturn:cErro)
				u_help (AllTrim (oReturn:cErro), 'Erro retornado pelo webservice')
			Else
				//u_log ('OWSTRANSPORTADOR:', ORETURN:OWSTRANSPORTADOR)
				For nLinha := 1 to Len(ORETURN:OWSTRANSPORTADOR)

					if empty (ORETURN:OWSTRANSPORTADOR[nLinha]:CCNPJ)
						u_log ("Retorno vazio na tag CCNPJ")
					else
						aAdd(_aRet, afill (Array(.ESalesRetQtColunas), 0))
						_aRet[Len(_aRet), .ESalesRetCodTransp]	:=	fBuscaCpo ("SA4", 3, xfilial ("SA4") + ORETURN:OWSTRANSPORTADOR[nLinha]:CCNPJ, "A4_COD")
						_aRet[Len(_aRet), .ESalesRetCNPJ]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:CCNPJ
						_aRet[Len(_aRet), .ESalesRetNOME]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:CNOMEFANTASIA
						_aRet[Len(_aRet), .ESalesRetMODAL]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:NMODAL
						_aRet[Len(_aRet), .ESalesRetTPFRETE]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:NTIPOFRETE
						If ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO <> nil
							_aRet[Len(_aRet), .ESalesRetSTTABELA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:CSTTABELA
							_aRet[Len(_aRet), .ESalesRetROTA]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NCDROTA
							_aRet[Len(_aRet), .ESalesRetCDTABELA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NCDTABELA
							_aRet[Len(_aRet), .ESalesRetVLRFRETE]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORFRETE
							_aRet[Len(_aRet), .ESalesRetVLRTAXA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORTAXAS
							_aRet[Len(_aRet), .ESalesRetVLRTOTAL]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORTOTAL
						else
							_aRet[Len(_aRet), .ESalesRetErroFrete]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:CERROFRETE
						EndIf
						if ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA <> nil
							_aRet[Len(_aRet), .ESalesRetDTPREV]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA:DDATAPREVISAO
							_aRet[Len(_aRet), .ESalesRetDIASENT]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA:NDIASENTREGA
						EndIf
					endif
				Next
			EndIf
		Else
			u_help('Erro na solicitacao de cotacao de frete. Causa mais provavel: portal entregou.com inacessivel ou inativo. Descricao do erro:' + chr (13) + chr (10) + GetWSCError ())
		EndIf
	EndIf
//	u_logFim ()
Return _aRet

/*
Static Function RetArray(oReturn)

	Local nLinha	:= 0
	Local nProtocolo:= oReturn:nProtocolo
	Local aCabec	:= {}

	aAdd(aCabec, "CNPJ")
	aAdd(aCabec, "NOME FANTASIA")
	aAdd(aCabec, "MODAL")
	aAdd(aCabec, "TIPO FRETE")
	aAdd(aCabec, "CST TABELA")
	aAdd(aCabec, "ROTA")
	aAdd(aCabec, "CD TABELA")
	aAdd(aCabec, "VALOR FRETE")
	aAdd(aCabec, "VALOR TAXA")
	aAdd(aCabec, "VALOR TOTAL")
	aAdd(aCabec, "PREVISÃO ENTREGA")
	aAdd(aCabec, "DIAS ENTREGA")
	
	If Len(ORETURN:OWSTRANSPORTADOR) > 0
		
		For nLinha := 1 to Len(ORETURN:OWSTRANSPORTADOR)
			
			aAdd(_aRet, Array(.MAX))
			_aRet[Len(_aRet), .CNPJ]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:CCNPJ
			_aRet[Len(_aRet), .NOME]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:CNOMEFANTASIA
			_aRet[Len(_aRet), .MODAL]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:NMODAL
			_aRet[Len(_aRet), .TPFRETE]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:NTIPOFRETE
			If ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO <> nil
				_aRet[Len(_aRet), .STTABELA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:CSTTABELA
				_aRet[Len(_aRet), .ROTA]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NCDROTA
				_aRet[Len(_aRet), .CDTABELA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NCDTABELA
				_aRet[Len(_aRet), .VLRFRETE]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORFRETE
				_aRet[Len(_aRet), .VLRTAXA]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORTAXAS
				_aRet[Len(_aRet), .VLRTOTAL]	:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSFRETECALCULADO:NVALORTOTAL
			EndIf
			If ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA <> nil
				_aRet[Len(_aRet), .DTPREV]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA:DDATAPREVISAO
				_aRet[Len(_aRet), .DIASENT]		:=	ORETURN:OWSTRANSPORTADOR[nLinha]:OWSPRAZOENTREGA:NDIASENTREGA
			EndIf
		Next
		If Len(_aRet) > 0
			U_ShowArray( _aRet, "PROTOCOLO: " + AllTrim(Str(nProtocolo)), aCabec )
		EndIf
	EndIf

Return


Static Function _ValidPerg()
	Local _aRegsPerg := {}

//                         PERGUNT          TIPO TAM 					DEC VALID F3    Opcoes                        			Help
	aAdd (_aRegsPerg, {01, "CNPJ Destino?", "C", TamSx3("A1_CGC")[1], 	0,  "",  "SA1", {},                           			 ""})
	aAdd (_aRegsPerg, {02, "CEP Origem?", 	"C", TamSx3("A1_CEP")[1], 	0,  "",  "SA1", {},                          			 ""})
	aAdd (_aRegsPerg, {03, "CEP Destino?", 	"C", TamSx3("A1_CEP")[1], 	0,  "",  "SA1", {},                          			 ""})
	aAdd (_aRegsPerg, {04, "Modal?", 		"C", 01, 					0,  "",  "   ", {"Rodoviário","Aeroviário"}, 			 ""})
	aAdd (_aRegsPerg, {05, "Tipo de Carga?","C", 01, 					0,  "",  "   ", {},                                      ""})
	aAdd (_aRegsPerg, {06, "Data Embarque?","D", 08, 					0,  "",  "   ", {},                           			 ""})
	aAdd (_aRegsPerg, {07, "Documento?", 	"C", TamSx3("F2_DOC")[1], 	0,  "",  "SF2", {},                           			 ""})
	aAdd (_aRegsPerg, {08, "Serie?", 		"C", TamSx3("F2_DOC")[1], 	0,  "",  "   ", {},                           			 ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
*/
