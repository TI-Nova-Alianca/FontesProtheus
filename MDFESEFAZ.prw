
// Programa.:  XmlMDFeSef
// Autor....:  Natalia Sartori
// Data.....:  25/02/2014
// Descricao:  Regras para chamada do método remessa
// 
//  #TipoDePrograma    #processo
//  #Descricao         #Regras para chamada do método remessa
//  #PalavasChave      #MDfe 
//  #TabelasPrincipais #SF2 
//  #Modulos 		   #FAT 
//
// @param 	cFilCC0 		- Filial
// 			cSerie  		- Série do MDFe
// 			cNumMDF 		- Número do MDFe
// 			cAmbiente		- 1- Produção; 2- Homologação
// 			cVersao 		- Versão do MDFe
// 			cModalidade		- 1- Normal; 2- Contingência
// 			cTipo			- Tipo do XML a Ser montado 1- MDFe; 
// 							  2-Cancelamento; 3- Encerramento		
//
// @return	cChvMDFe	- Chave do MDFe
// 			cString		- String com XML Encodado
//
// Historico de alteracoes:
//
//----------------------------------------------------------------------
#Include 'Protheus.ch'

User Function XmlMDFeSef(cFil)
	Local cString		:= ""
	Local cChvMDFe		:= ""
	Local aNota			:= {}
	Local lRespTec  	:= iif(findFunction("getRespTec"),getRespTec("2"),.T.)   //0-Todos, 1-NFe, 2-MDFe
	Local lTagProduc	:= date() > CTOD("15/06/2019") 
	Local lPosterior	:= Type("cPoster") == "C" .And. SubStr(cPoster,1,1) == "1"
	
	Private aUF		    := {}
	Private cTipModal   := IIF(Empty(cModal),"1", substr(cModal,1,1))    

	// Preenchimento do Array de UF                                            
	aadd(aUF,{"RO","11"})
	aadd(aUF,{"AC","12"})
	aadd(aUF,{"AM","13"})
	aadd(aUF,{"RR","14"})
	aadd(aUF,{"PA","15"})
	aadd(aUF,{"AP","16"})
	aadd(aUF,{"TO","17"})
	aadd(aUF,{"MA","21"})
	aadd(aUF,{"PI","22"})
	aadd(aUF,{"CE","23"})
	aadd(aUF,{"RN","24"})
	aadd(aUF,{"PB","25"})
	aadd(aUF,{"PE","26"})
	aadd(aUF,{"AL","27"})
	aadd(aUF,{"MG","31"})
	aadd(aUF,{"ES","32"})
	aadd(aUF,{"RJ","33"})
	aadd(aUF,{"SP","35"})
	aadd(aUF,{"PR","41"}) 
	aadd(aUF,{"SC","42"})
	aadd(aUF,{"RS","43"})
	aadd(aUF,{"MS","50"})
	aadd(aUF,{"MT","51"})
	aadd(aUF,{"GO","52"})
	aadd(aUF,{"DF","53"})
	aadd(aUF,{"SE","28"})
	aadd(aUF,{"BA","29"})
	aadd(aUF,{"EX","99"})

	aadd(aNota,cSerie)
	aadd(aNota,IIF(Len(cNumero)==6,"000","")+cNumero)
	aadd(aNota,dDataEmi)
	aadd(aNota,cTime)
	aadd(aNota,cUFCarr)
	aadd(aNota,cUFDesc)
	aadd(aNota,alltrim(TRB->TRB_CODMUN))
	aadd(aNota,alltrim(TRB->TRB_NOMMUN))
	aadd(aNota,alltrim(TRB->TRB_EST))
	aadd(aNota,alltrim(iif( lPosterior,"1","0")))

	If !Empty(aNota)
		cString := ""
		cString += MDFeIde(@cChvMDFe,aNota,cVeiculo)
		cString += MDFeEmit()
		If cTipModal =="1"
			cString += MDFeModal(cVeiculo,aNota)
		else
		    cString += MDFeModalA()
		EndIf
		cString += MDFeInfDoc(aNota)
		cString += MDFeProdPred()
		cString += MDFeTotais()
		cString += MDFeLacres()
		cString += MDFeAutoriz()
		cString += MDFeInfAdic()
		if lRespTec .and. lTagProduc .and. existFunc("NfeRespTec") .and. !lUsaColab
			cString += NfeRespTec(,58) //Responsavel Tecnico
		endif
			
		cString += '</infMDFe>'
		if !lUsaColab
			cString += MDFeInfMDFeSupl()
		endif
		cString += '</MDFe>'
	EndIf

Return ({cChvMDFe, EncodeUTF8(cString)})
//
//----------------------------------------------------------------------
//Montagem do elemento ide do XML
Static Function MDFeIde(cChave,aNota,cVeiculo)

Local cString		:= ""
Local cTpEmis		:= "1"
Local cDV			:= ""
Local cDhEmi		:= "" 
Local lEndFis 	:= GetNewPar("MV_SPEDEND",.F.)

Default cVeiculo := ""

	cDV := cTpEmis + Inverte(StrZero( val(aNota[02]),8))
	cChave := MDFeChave( aUF[aScan(aUF,{|x| x[1] == IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) })][02],;
							FsDateConv(aNota[03],"YYMM"),AllTrim(SM0->M0_CGC),'58',;
							StrZero(Val(aNota[01]),3),;
							StrZero(Val(aNota[02]),9),;
							cDV )

	cDhEmi := SubStr(DToS(aNota[3]), 1, 4) + "-" + SubStr(DToS(aNota[3]), 5, 2) + "-" + SubStr(DToS(aNota[3]), 7, 2) + "T" + aNota[4] + cTZD

	cString += '<MDFe xmlns="http://www.portalfiscal.inf.br/mdfe">'
	cString += '<infMDFe Id="MDFe' + AllTrim(cChave) + '" versao="' /*+ cVersao */+ '">'
	cString += '<ide>'
	cString += '<cUF>'+ ConvType(aUF[aScan(aUF,{|x| x[1] == IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT)) })][02],02)+ '</cUF>'
	cString += '<tpAmb>' /*+ cAmbiente*/ + '</tpAmb>'      
	/* Se tipo emitente informado for igual a Prestador de Serviço de Transporte (tpEmit=1), não poderão ser informados os grupos de documentos NF e/ou chaves de acesso de NF-e. 
	Portanto, deverá incluir apenas chaves de acesso de CT-e. 
	Sendo assim, Tag <tpEmit> sempre será 2 para NFe
	*/    		
	cString += '<tpEmit>2</tpEmit>'  //2 - Transportador de Carga Própria OBS: Para emitentes de NF-e e pelas transportadoras quando estiverem fazendo transporte de carga própria 

	cString += retTpTransp(cVeiculo)

	cString += '<mod>58</mod>'
	If Empty(aNota[01])
		cString += '<serie>'+ "000" +'</serie>'
	Else
		cString += '<serie>'+ ConvType(Val(aNota[01]),3) +'</serie>'
	Endif                  
	cString += '<nMDF>' + ConvType(Val(aNota[02]),9) + '</nMDF>'
	cString += '<cMDF>'+ NoAcento(substr(cDV,2,8)) + '</cMDF>'
	cString += '<cDV>' + SubStr( AllTrim(cChave), Len( AllTrim(cChave) ), 1) + '</cDV>'
	cString += '<modal>'+cTipModal+'</modal>'  //1=Modal Rodoviário 2=Modal Aéreo
	cString += '<dhEmi>' + cDhEmi + '</dhEmi>'
	cString += '<tpEmis>' + cTpEmis + '</tpEmis>'
	cString += '<procEmi>0</procEmi>'
	cString += '<verProc>' + GetlabelTSS() + '</verProc>'
	cString += '<UFIni>' + aNota[05] + '</UFIni>'
	cString += '<UFFim>' + aNota[06] + '</UFFim>'

	//InfMunCarrega
	cString += MDFeCarrega() 

	If len(aNota) >= 10 .And. aNota[10] == "1"
		cString +=	"<indCarregaPosterior>1</indCarregaPosterior>"
	EndIf
	//InfPercurso
	cString += MDFePercu(aNota) 

	cString += '</ide>'

Return cString
//
//----------------------------------------------------------------------
// Montagem do elemento emit do XML
Static Function MDFeEmit()
	Local cFoneDest	:= ""
	Local cString 		:= ""
	Local cEndEmit		:= ""
	Local lEndFis 		:= GetNewPar("MV_SPEDEND",.F.)
	Local lUsaGesEmp	:= IIF(FindFunction("FWFilialName") .And. FindFunction("FWSizeFilial") .And. FWSizeFilial() > 2,.T.,.F.)

	cString := '<emit>'
	If Len(AllTrim(SM0->M0_CGC))==14
		cString += '<CNPJ>'+SM0->M0_CGC+'</CNPJ>'
	ElseIf Len(AllTrim(SM0->M0_CGC))<>0
		cString += '<CPF>'+AllTrim(SM0->M0_CGC)+'</CPF>'
	Else
		cString += '<CNPJ></CNPJ>'
	EndIf  
		
	cString += '<IE>'+ConvType(VldIE(SM0->M0_INSC))+'</IE>'      
	cString += '<xNome>' + alltrim(NoAcento(SubStr(SM0->M0_NOMECOM,1,60))) + '</xNome>'
	If lUsaGesEmp
		cString += NfeTag('<xFant>',ConvType(FWFilialName()))
	Else
		cString += NfeTag('<xFant>',ConvType(SM0->M0_NOME))
	EndIf
	cString += '<enderEmit>'
	cString += '<xLgr>'+IIF(!lEndFis,ConvType(FisGetEnd(SM0->M0_ENDCOB,SM0->M0_ESTCOB)[1]),ConvType(FisGetEnd(SM0->M0_ENDENT,SM0->M0_ESTENT)[1]))+'</xLgr>'

	If !lEndFis
		If FisGetEnd(SM0->M0_ENDCOB,SM0->M0_ESTCOB)[2]<>0
			cString += '<nro>'+FisGetEnd(SM0->M0_ENDCOB,SM0->M0_ESTCOB)[3]+'</nro>'  
		Else
			cString += '<nro>'+"SN"+'</nro>' 
		EndIf
	Else
		If FisGetEnd(SM0->M0_ENDENT,SM0->M0_ESTENT)[2]<>0
			cString += '<nro>'+FisGetEnd(SM0->M0_ENDENT,SM0->M0_ESTENT)[3]+'</nro>' 
		Else
			cString += '<nro>'+"SN"+'</nro>'
		EndIf
	EndIf

	cEndEmit :=  IIF(!lEndFis,Iif(!Empty(SM0->M0_COMPCOB),SM0->M0_COMPCOB,ConvType(FisGetEnd(SM0->M0_ENDCOB,SM0->M0_ESTCOB)[4]) ) ,;
							Iif(!Empty(SM0->M0_COMPENT),SM0->M0_COMPENT,ConvType(FisGetEnd(SM0->M0_ENDENT,SM0->M0_ESTENT)[4]) ) )

	cString += NfeTag('<xCpl>',cEndEmit)
	cString += '<xBairro>'+IIF(!lEndFis,ConvType(SM0->M0_BAIRCOB),ConvType(SM0->M0_BAIRENT))+'</xBairro>'
	cString += '<cMun>'+ConvType(SM0->M0_CODMUN)+'</cMun>'
	cString += '<xMun>'+IIF(!lEndFis,ConvType(SM0->M0_CIDCOB),ConvType(SM0->M0_CIDENT))+'</xMun>'
	cString += NfeTag('<CEP>',IIF(!lEndFis,ConvType(SM0->M0_CEPCOB),ConvType(SM0->M0_CEPENT)))
	cString += '<UF>'+IIF(!lEndFis,ConvType(SM0->M0_ESTCOB),ConvType(SM0->M0_ESTENT))+'</UF>'

	cFoneDest := right(FormatTel(SM0->M0_TEL), 12)
	cString += NfeTag('<fone>',cFoneDest)
	//cString += NfeTag('<email>',)
	cString += '</enderEmit>'
	cString += '</emit>'				  

Return cString
//
//----------------------------------------------------------------------
//Tags InfMunCarrega
Static Function MDFeCarrega()
	Local cString := ""
	Local nI := 0
	Local aMunicipios := aClone(oGetDMun:aCols)
	Local cUfCode := ""
	
	For nI := 1 to len(aMunicipios)
	    If !aMunicipios[nI,len(aMunicipios[nI])]			//Linha nao deletada
			cUfCode := GetUfCode(aMunicipios[nI,2])
		
			cString += '<infMunCarrega>'
			cString += '<cMunCarrega>' + alltrim(cUfCode) + alltrim(aMunicipios[nI,1]) + '</cMunCarrega>'
			cString += '<xMunCarrega>' + alltrim(aMunicipios[nI,3]) + '</xMunCarrega>'
			cString += '</infMunCarrega>'
		EndIf
	Next nI
Return cString
//
//----------------------------------------------------------------------
// Tags InfMunPercurso
Static Function MDFePercu(aNota)
	Local cString := ""
	Local nI 	:= 0
	Local aUFs	:= aClone(oGetDPerc:aCols)
	
    For nI := 1 to len(aUFs)
   		If !aUFs[nI,len(aUFs[nI])] //Linha nao deletada
   	 		//Desconsidera as UFs ja informadas em UF Carregamento e UF Descarregamento. Orientacao do manual do contribuinte
	   		If alltrim(aUFs[nI,1]) != aNota[05] .and. alltrim(aUFs[nI,1]) != aNota[06] .and. !Empty(aUFs[nI,1])
		   		cString += "<infPercurso>"
			  	cString += "<UFPer>" + aUFs[nI,1] + "</UFPer>"
		   		cString += "</infPercurso>"
		   	EndIf
		EndIf
    Next nI
		
Return cString
//
//----------------------------------------------------------------------
// Montagem do elemento InfModal do XML
Static Function MDFeModal (cVeiculo,aNota)

	Local aVeiSF2		:= {}
	Local aVeiculo		:= {}
	Local aMotorista	:= {}
	Local aProp			:= {}
	Local cString 		:= ""
	Local ctpProp		:= ""
	Local nCapcM3		:= 0
	Local nX			:= 0
	Local lPosterior	:= .F.
	Local lMotorista	:= .F. 

	Default aNota		:= {}

	lPosterior	:= Len(aNota) >= 10 .And. aNota[10] == "1"
	lMotorista	:= Type('cMotorista') == 'C' .and. !empty(cMotorista)

	cString += '<infModal versaoModal="'/*+cVersao*/+'">'
	cString += '<rodo>'
	cString += '<infANTT>'
	cString += NfeTag('<RNTRC>',ConvType(SM0->M0_RNTRC))
	cString += getInfCIOT()
	cString += valePed(cVeiculo)
	cString += getInfPag()
	cString += '</infANTT>'

	If !Empty(cVeiculo)

		dbSelectArea('TRB')
		TRB->(dbGoToP())
		While TRB->(!Eof())
			If !Empty(TRB->TRB_MARCA)
				If Len(aVeiSF2) == 0
					If TRB->TRB_VEICU1 == cVeiculo
						aadd(aVeiSF2,TRB->TRB_VEICU1)
					ElseIf TRB->TRB_VEICU2 == cVeiculo
						aadd(aVeiSF2,TRB->TRB_VEICU2)
					ElseIf TRB->TRB_VEICU3 == cVeiculo
						aadd(aVeiSF2,TRB->TRB_VEICU3)
					EndIf
				EndIf

				If !Empty(TRB->TRB_VEICU1) .And. TRB->TRB_VEICU1 <> cVeiculo .And. Len(aVeiSF2) < 4
					If (aScan(aVeiSF2,{|x| x == TRB->TRB_VEICU1 })) == 0
						aadd(aVeiSF2,TRB->TRB_VEICU1)
					EndIf
				EndIf
				If !Empty(TRB->TRB_VEICU2) .And. TRB->TRB_VEICU2 <> cVeiculo .And. Len(aVeiSF2) < 4
					If (aScan(aVeiSF2,{|x| x == TRB->TRB_VEICU2 })) == 0
						aadd(aVeiSF2,TRB->TRB_VEICU2)
					EndIf
				EndIf
				If !Empty(TRB->TRB_VEICU3) .And. TRB->TRB_VEICU3 <> cVeiculo .And. Len(aVeiSF2) < 4
					If (aScan(aVeiSF2,{|x| x == TRB->TRB_VEICU3 })) == 0
						aadd(aVeiSF2,TRB->TRB_VEICU3)
					EndIf
				EndIf

				If Len(aVeiSF2) >= 4
					Exit
				EndIf
			EndIf	
			
			TRB->(dbSkip())
		EndDo

		If Type("cPoster") == "C" .And. SubStr(cPoster,1,1) == "1" .and. Len(aVeiSF2) == 0 //"1-Sim" Vincula posterior
			aadd(aVeiSF2,cVeiculo)
		EndIf

		For nX := 1 To Len(aVeiSF2)
			If HasTemplate("DCLEST")	//ExistTemplate("OMSA200P")
				dbSelectArea("SA4")
				dbSetOrder(1)
				dbSelectArea("LBW")
				dbSetOrder(1)

				If MsSeek(xFilial("LBW")+PADR(aVeiSF2[nX],Len(LBW->LBW_PLACA)))
					aadd(aVeiculo,{})
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_PLACA")) > 0 ,LBW->LBW_PLACA,""))
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_PLACA")) > 0 ,LBW->LBW_PLACA,""))				
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_UF")) > 0 ,LBW->LBW_UF,""))					
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_TARA")) > 0 ,LBW->LBW_TARA,""))				
					aadd( aVeiculo[Len(aVeiculo)],"")
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_TRANSP")) > 0 ,LBW->LBW_TRANSP,""))
					aadd( aVeiculo[Len(aVeiculo)],"")
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_FROVEI")) > 0 ,LBW->LBW_FROVEI,""))	//Frota 1-Própria;2-Terceiro;3-Agregado
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_CAPTOT")) > 0 ,LBW->LBW_CAPTOT,""))	//Capacidade Máxima
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_ALTINT")) > 0 ,LBW->LBW_ALTINT,""))	//Altura Interna
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_LARINT")) > 0 ,LBW->LBW_LARINT,""))	//Largura Interna
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_COMINT")) > 0 ,LBW->LBW_COMINT,""))	//Comprimento Interno
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_TIPROD")) > 0 ,LBW->LBW_TIPROD,""))	//Tipo de Rodado
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_TIPCAR")) > 0 ,LBW->LBW_TIPCAR,""))	//Tipo de Carroceria
					aadd( aVeiculo[Len(aVeiculo)] , Iif(LBW->(ColumnPos("LBW_RENAVA")) > 0 ,LBW->LBW_RENAVA,""))	//Renavam
															
					aadd(aProp,{})
					If !Empty(aVeiculo[Len(aVeiculo)][6])
						dbSelectArea("SA4")
						dbSetOrder(1)
						MsSeek(xFilial("SA4")+aVeiculo[Len(aVeiculo)][6])
						
						aadd(aProp[Len(aProp)],SA4->A4_COD)
						aadd(aProp[Len(aProp)],SA4->A4_CGC)
						aadd(aProp[Len(aProp)],SA4->A4_RNTRC)
						aadd(aProp[Len(aProp)],SA4->A4_NOME)
						aadd(aProp[Len(aProp)],SA4->A4_INSEST)
						aadd(aProp[Len(aProp)],SA4->A4_EST)	
					EndIf

					If nX == 1
						aadd(aMotorista,{})
						aadd(aMotorista[Len(aMotorista)],"")
						aadd(aMotorista[Len(aMotorista)],Iif(LBW->(ColumnPos("LBW_NOMMOT")) > 0 ,LBW->LBW_NOMMOT,""))
						aadd(aMotorista[Len(aMotorista)],Iif(LBW->(ColumnPos("LBW_CPFMOT")) > 0 ,LBW->LBW_CPFMOT,""))
					EndIf
				Else
					dbSelectArea("DA3")
					dbSetOrder(1)
					dbSelectArea("DUT")
					dbSetOrder(1)
					DA3->(MsSeek(xFilial("DA3")+aVeiSF2[nX]))
				
					aadd(aVeiculo,{})
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_COD)					
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_PLACA) 
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_ESTPLA)
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_TARA)
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_LOJFOR)
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_CODFOR)
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_MOTORI)
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_FROVEI) //Frota 1-Própria;2-Terceiro;3-Agregado
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_CAPACM) //Capacidade Máxima
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_ALTINT) //Altura Interna
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_LARINT) //Largura Interna
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_COMINT) //Comprimento Interno
					
					If DUT->( msSeek( xFilial( "DUT" ) + DA3->DA3_TIPVEI ) )
						aadd( aVeiculo[Len(aVeiculo)] , DUT->DUT_TIPROD ) 	//Tipo de Rodado
						aadd( aVeiculo[Len(aVeiculo)] , DUT->DUT_TIPCAR ) 	//Tipo de Carroceria
					Else
						aadd( aVeiculo[Len(aVeiculo)] , "" ) 	//Tipo de Rodado
						aadd( aVeiculo[Len(aVeiculo)] , "" ) 	//Tipo de Carroceria
					Endif
					aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_RENAVA) //Renavam
					
					aadd(aProp,{})
					If !Empty(aVeiculo[Len(aVeiculo)][5]) .and. !Empty(aVeiculo[Len(aVeiculo)][6])
						dbSelectArea("SA2")
						dbSetOrder(1)
						MsSeek(xFilial("SA2")+aVeiculo[Len(aVeiculo)][6]+aVeiculo[Len(aVeiculo)][5])
						
						aadd(aProp[Len(aProp)],SA2->A2_COD)
						aadd(aProp[Len(aProp)],SA2->A2_CGC)
						aadd(aProp[Len(aProp)],SA2->A2_RNTRC)
						aadd(aProp[Len(aProp)],SA2->A2_NOME)
						aadd(aProp[Len(aProp)],SA2->A2_INSCR)
						aadd(aProp[Len(aProp)],SA2->A2_EST)	
					EndIf
					
					If nX == 1
						aadd(aMotorista,{})
						If !Empty(aVeiculo[Len(aVeiculo)][7])
							dbSelectArea("DA4")
							dbSetOrder(1)
							MsSeek(xFilial("DA4")+aVeiculo[Len(aVeiculo)][7])
							
							aadd(aMotorista[Len(aMotorista)],DA4->DA4_COD)
							aadd(aMotorista[Len(aMotorista)],DA4->DA4_NOME)
							aadd(aMotorista[Len(aMotorista)],DA4->DA4_CGC)
						EndIf
					EndIf
				EndIf
			Else
				dbSelectArea("DA3")
				dbSetOrder(1)
				dbSelectArea("DUT")
				dbSetOrder(1)
				DA3->(MsSeek(xFilial("DA3")+aVeiSF2[nX]))

				aadd(aVeiculo,{})
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_COD)					
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_PLACA) 
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_ESTPLA)
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_TARA)
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_LOJFOR)
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_CODFOR)
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_MOTORI)
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_FROVEI) //Frota 1-Própria;2-Terceiro;3-Agregado
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_CAPACM) //Capacidade Máxima
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_ALTINT) //Altura Interna
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_LARINT) //Largura Interna
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_COMINT) //Comprimento Interno
				
				If DUT->( msSeek( xFilial( "DUT" ) + DA3->DA3_TIPVEI ) )
					aadd( aVeiculo[Len(aVeiculo)] , DUT->DUT_TIPROD ) 	//Tipo de Rodado
					aadd( aVeiculo[Len(aVeiculo)] , DUT->DUT_TIPCAR ) 	//Tipo de Carroceria
				Else
					aadd( aVeiculo[Len(aVeiculo)] , "" ) 	//Tipo de Rodado
					aadd( aVeiculo[Len(aVeiculo)] , "" ) 	//Tipo de Carroceria
				Endif
				//Retirada validação dos campos abaixo por já existirem em outro tabela
				//aadd(aVeiculo[Len(aVeiculo)],Iif(DA3->(FieldPos("DA3_TPROD")) > 0 ,DA3->DA3_TPROD,"")) 	//Tipo de Rodado
				//aadd(aVeiculo[Len(aVeiculo)],Iif(DA3->(FieldPos("DA3_TPCAR")) > 0, DA3->DA3_TPCAR,"")) 	//Tipo de Carroceria
				aadd(aVeiculo[Len(aVeiculo)],DA3->DA3_RENAVA) //Renavam
				
				aadd(aProp,{})
				If !Empty(aVeiculo[Len(aVeiculo)][5]) .and. !Empty(aVeiculo[Len(aVeiculo)][6])
					dbSelectArea("SA2")
					dbSetOrder(1)
					MsSeek(xFilial("SA2")+aVeiculo[Len(aVeiculo)][6]+aVeiculo[Len(aVeiculo)][5])
					
					aadd(aProp[Len(aProp)],SA2->A2_COD)
					aadd(aProp[Len(aProp)],SA2->A2_CGC)
					aadd(aProp[Len(aProp)],SA2->A2_RNTRC)
					aadd(aProp[Len(aProp)],SA2->A2_NOME)
					aadd(aProp[Len(aProp)],SA2->A2_INSCR)
					aadd(aProp[Len(aProp)],SA2->A2_EST)	
				EndIf
				
				If nX == 1
					aadd(aMotorista,{})
					If !Empty(aVeiculo[Len(aVeiculo)][7])
						dbSelectArea("DA4")
						dbSetOrder(1)
						MsSeek(xFilial("DA4")+aVeiculo[Len(aVeiculo)][7])
						
						aadd(aMotorista[Len(aMotorista)],DA4->DA4_COD)
						aadd(aMotorista[Len(aMotorista)],DA4->DA4_NOME)
						aadd(aMotorista[Len(aMotorista)],DA4->DA4_CGC)
					EndIf
				EndIf
			EndIf
		Next	
	EndIf

	For nX := 1 To Len(aVeiculo)
		If nX == 1
			cString += '<veicTracao>'
			cString += '<cInt>' + ConvType(aVeiculo[nX][1]) + '</cInt>'
			cString += '<placa>' + ConvType(aVeiculo[nX][2]) + '</placa>'
			cString += NfeTag('<RENAVAM>',ConvType((aVeiculo[nX][15]),11,0))
			cString += '<tara>' + ConvType((aVeiculo[nX][4]),6,0) + '</tara>'
			cString += NfeTag('<capKG>',ConvType((aVeiculo[nX][9]),6,0))

			//Converte Valor da capacidade KG para M3
			If !Empty(aVeiculo[nX][10]) .and. !Empty(aVeiculo[nX][11]) .and. !Empty(aVeiculo[nX][12])
				nCapcM3 := Round(aVeiculo[nX][10] * aVeiculo[nX][11] * aVeiculo[nX][12],0)
				cString += NfeTag('<capM3>',ConvType((nCapcM3),3,0))
			EndIf

			//TAG: Prop - Se o veiculo for de terceiros, preencher tags com informações do proprietário
			If !Empty(aVeiculo[nX][08]) .and. aVeiculo[nX][08] <> '1'
				If Len(aProp[nX]) > 0
					cString += '<prop>'

					If Len(Alltrim(aProp[nX][2])) > 11
						cString += '<CNPJ>' + Alltrim(aProp[nX][2]) + '</CNPJ>'
					Else
						cString += '<CPF>' + Alltrim(aProp[nX][2]) + '</CPF>'
					EndIf

					cString += '<RNTRC>' + StrZero(Val(AllTrim(aProp[nX][3])),8) + '</RNTRC>'	
					cString += '<xNome>' + ConvType(aProp[nX][4]) + '</xNome>'
					
					cString += '<IE>'+ ConvType(VldIE(aProp[nX][5],.F.)) + '</IE>'  
					cString += '<UF>'+ ConvType(aProp[nX][6]) + '</UF>'

					If aVeiculo[nX][08] == '3'  
						ctpProp := "0" //TAC Agregado
					ElseIf aVeiculo[nX][08] == '2'
						ctpProp	:= "1" //TAC Independente
					Else
						ctpProp	:= "2" //Outros
					EndIf

					cString += '<tpProp>' + ctpProp + '</tpProp>'

					cString += '</prop>'
				EndIf
			EndIf

			If lMotorista
				dbSelectArea("DA4")
				dbSetOrder(1)
				MsSeek(xFilial("DA4")+cMotorista)

				cString += '<condutor>'
				cString +=   '<xNome>' + ConvType(DA4->DA4_NOME) +'</xNome>'
				cString +=   '<CPF>'   + AllTrim(DA4->DA4_CGC) +'</CPF>'
				cString += '</condutor>'
			Else
				If Len(aMotorista[nX]) > 0
					cString += '<condutor>'
					cString +=   '<xNome>' + ConvType(aMotorista[nX][2]) +'</xNome>'
					cString +=   '<CPF>'   + AllTrim(aMotorista[nX][3]) +'</CPF>'
					cString += '</condutor>'
				EndIf
			EndIf
			cString +=   '<tpRod>' + alltrim(aVeiculo[nX][13]) + '</tpRod>'
			cString +=   '<tpCar>' + alltrim(aVeiculo[nX][14]) + '</tpCar>'
			if !empty( aVeiculo[nX][3] )
				cString +=   '<UF>' + ConvType(aVeiculo[nX][3]) + '</UF>'
			endIf
			cString += '</veicTracao>'
		Else
			cString += '<veicReboque>'
			cString += '<cInt>' + ConvType(aVeiculo[nX][1]) + '</cInt>'
			cString += '<placa>' + ConvType(aVeiculo[nX][2]) + '</placa>'
			//Inclusão do renavam NT2014/003
			cString += NfeTag('<RENAVAM>',ConvType((aVeiculo[nX][15]),11,0))
			cString += '<tara>' + ConvType((aVeiculo[nX][4]),6,0) + '</tara>'
			cString += NfeTag('<capKG>',ConvType((aVeiculo[nX][9]),6,0))

			//Converte Valor da capacidade KG para M3
			If !Empty(aVeiculo[nX][10]) .and. !Empty(aVeiculo[nX][11]) .and. !Empty(aVeiculo[nX][12])
				nCapcM3 := Round(aVeiculo[nX][10] * aVeiculo[nX][11] * aVeiculo[nX][12],0)
				cString += NfeTag('<capM3>',ConvType((nCapcM3),3,0))
			EndIf

			//TAG: Prop - Se o veiculo for de terceiros, preencher tags com informações do proprietário
			If !Empty(aVeiculo[nX][08]) .and. aVeiculo[nX][08] <> '1'
				If Len(aProp[nX]) > 0
					cString += '<prop>'

					If Len(Alltrim(aProp[nX][2])) > 11
						cString += '<CNPJ>' + Alltrim(aProp[nX][2]) + '</CNPJ>'
					Else
						cString += '<CPF>' + Alltrim(aProp[nX][2]) + '</CPF>'
					EndIf

					cString += '<RNTRC>' + StrZero(Val(AllTrim(aProp[nX][3])),8) + '</RNTRC>'	
					cString += '<xNome>' + ConvType(aProp[nX][4]) + '</xNome>'
					
					cString += '<IE>'+ ConvType(VldIE(aProp[nX][5],.F.)) + '</IE>'
					cString += '<UF>'+ ConvType(aProp[nX][6]) + '</UF>'
					
					If aVeiculo[nX][08] == '3'  
						ctpProp := "0" //TAC Agregado
					ElseIf aVeiculo[nX][08] == '2'
						ctpProp	:= "1" //TAC Independente
					Else
						ctpProp	:= "2" //Outros
					EndIf

					cString += '<tpProp>' + ctpProp + '</tpProp>'

					cString += '</prop>'
				EndIf
			EndIf

			cString +=   '<tpCar>' + alltrim(aVeiculo[nX][14]) + '</tpCar>'
			if !empty( aVeiculo[nX][3] )
				cString +=   '<UF>' + ConvType(aVeiculo[nX][3]) + '</UF>'
			endIf
			cString += '</veicReboque>'
		EndIf
	Next

	cString += '</rodo>'
	cString += '</infModal>'
	
Return cString
//
//----------------------------------------------------------------------
// Montagem do elemento InfModal  Aéreo do XML
Static Function MDFeModalA ()
	Local cString 		:= ""
	Local cData         := alltrim(cDatVoo)
	Local aMarVei       := {}
	Local cMarca        := ""

	cData := substr(cData,5,4)+'-'+substr(cData,3,2)+'-'+substr(cData,1,2)
	aMarVei:= FWGetSX5("M6",DA3->DA3_MARVEI)
	If len(aMarVei) > 0
		If len(aMarVei[1]) > 0
			If len(aMarVei[1][4]) > 0
				cMarca := aMarVei[1][4]
			EndIf
		EndIf
	EndIf

	cString += '<infModal versaoModal="'/*+cVersao*/+'">'
	cString += '<aereo>'
	cString += '<nac>'+Alltrim(cMarca)+'</nac>'
	cString += '<matr>'+Alltrim(DA3->DA3_PLACA)+'</matr>'
	cString += '<nVoo>'+Alltrim(cNumVoo)+'</nVoo>'
	cString += '<cAerEmb>'+Alltrim(cAerOrig)+'</cAerEmb>'
	cString += '<cAerDes>'+Alltrim(cAerDest)+'</cAerDes>'
	cString += '<dVoo>'+cData+'</dVoo>'
	cString += '</aereo>'
	cString += '</infModal>'

Return cString
//
//----------------------------------------------------------------------
// Montagem do elemento InfDoc do XML
Static Function MDFeInfDoc(aNota)
	Local cString	:= ""
	Local cCodMun	:= ""
	Local cUfCode 	:= ""
	Local cSerieNFe	:= ""
	Local cNumNFe	:= ""
	Local cXmlRet	:= ""
	Local cChvCTG	:= ""
	Local aXmlRet	:= {}
	Default aNota	:= {}
	Private oNFeRet
	
	dbSelectArea('TRB')
	TRBSetIndex(2)
	TRB->(dbGoToP())

	cString += '<infDoc>'	
	While TRB->(!Eof())
		cCodMun := TRB->TRB_CODMUN

		//Considera apenas documentos Marcados
		If !Empty(TRB->TRB_MARCA)
			cUfCode := GetUfCode(TRB->TRB_EST)
		
			cString += '<infMunDescarga>'
			cString += '<cMunDescarga>'+ alltrim(cUfCode) + alltrim(TRB->TRB_CODMUN) +'</cMunDescarga>'
			cString += '<xMunDescarga>'+ alltrim(TRB->TRB_NOMMUN) +'</xMunDescarga>'
	
			While TRB->(!Eof()) .and. cCodMun == TRB->TRB_CODMUN
				//Considera apenas documentos Marcados
				If !Empty(TRB->TRB_MARCA)
					cString += '<infNFe>'
					cString += '<chNFe>'+ TRB->TRB_CHVNFE +'</chNFe>'
					If substr(TRB->TRB_CHVNFE,35,1) $ '2-5' //Contingencia FS-IA/FS-DA
						cSerieNFe := substr(TRB->TRB_CHVNFE,23,3)
						cNumNFe := substr(TRB->TRB_CHVNFE,26,9)
						If FindFunction("RetXmlNFe")
							aXmlRet := RetXmlNFe(cSerieNFe,cNumNFe)
							
							If len(aXmlRet) > 0
								cXmlRet:= aXmlRet[1][1]
								cChvCTG:= RetCodBarra(cXmlRet)
								If !Empty(cChvCTG)
									cString += '<SegCodBarra>'+ cChvCTG +'</SegCodBarra>'
								Else
									cString += '<SegCodBarra>'+ SubStr(TRB->TRB_CHVNFE,1,36) +'</SegCodBarra>'
								EndIf
							Else
								cString += '<SegCodBarra>'+ SubStr(TRB->TRB_CHVNFE,1,36) +'</SegCodBarra>'
							Endif
						Else
							MsgInfo("Atualize o fonte SPEDMFE.prw para montagem da tag SegCodBarra")
						EndIf
					endif		
					cString += '</infNFe>'					
				EndIf
				TRB->(dbSkip())
			EndDo
			cString += '</infMunDescarga>'
		EndIf	
		
		If TRB->(!Eof()) .and. cCodMun == TRB->TRB_CODMUN
			TRB->(dbSkip())
		EndIf
	EndDo

	If Len(aNota) >= 10 .And. aNota[10] == "1"
		cUfCode := GetUfCode(aNota[9])
		cString += '<infMunDescarga>'
		cString += '<cMunDescarga>'+ alltrim(cUfCode) + alltrim(aNota[7]) +'</cMunDescarga>'   
		cString += '<xMunDescarga>'+ alltrim(aNota[8]) +'</xMunDescarga>'
		cString += '</infMunDescarga>'
	EndIF

	cString += '</infDoc>'
	
	TRBSetIndex(1)
Return cString
//
//----------------------------------------------------------------------
//Tag Totais
Static Function MDFeTotais()
	Local cString := ""
	                   
	cString += "<tot>"
	cString += "<qNFe>" + ConvType(nQtNFe,0)   + "</qNFe>"
	cString += "<vCarga>" + ConvType(nVTotal,15,2) + "</vCarga>"
	cString += "<cUnid>01</cUnid>"
	cString += "<qCarga>" + ConvType(nPBruto,15,4) + "</qCarga>"
	cString += "</tot>"
	
Return cString 
//
//----------------------------------------------------------------------
//Tag Lacres
Static Function MDFeLacres()
	Local cString := ""
	Local aLacres := aClone(oGetDLacre:aCols)
	Local nI := 1
	
	If Len (aLacres) > 0
		For nI := 1 to len(aLacres)		
			If !aLacres[nI,len(aLacres[nI])]	.and. !Empty(aLacres[nI,1]) 	//Linha nao deletada e nao vazio
				cString += "<lacres>"
				cString += "<nLacre>" + alltrim(aLacres[nI,1]) + "</nLacre>"
				cString += "</lacres>"
			EndIf
		Next nI
	EndIf
	
Return cString
//
//----------------------------------------------------------------------
//Tag autXML
Static Function MDFeAutoriz()
	Local cString := ""
	Local aCNPJ := aClone(oGetDAut:aCols)
	Local nI := 1    

	If Len (aCNPJ) > 0
		For nI := 1 to len(aCNPJ)	

			If !aCNPJ[nI,len(aCNPJ[nI])] .and. !Empty(aCNPJ[nI,1]) //Linha nao deletada
				cString += "<autXML>"
				If Len(Alltrim(aCNPJ[nI,1])) > 11
					cString += "<CNPJ>"+ Alltrim(aCNPJ[nI,1])+"</CNPJ>"
				Else
					cString += "<CPF>"+ Alltrim(aCNPJ[nI,1])+ "</CPF>"
				EndIf			
				cString += "</autXML>"
			EndIf				
		Next nI
	EndIf	
	
Return cString
//
//----------------------------------------------------------------------
//Tag autXML
Static Function MDFeInfAdic()
	Local cString := ""
	
	If !Empty(cInfFsc) .or. !Empty(cInfCpl)
		cString += "<infAdic>"
		If !Empty(cInfFsc)
			cString += NfeTag("<infAdFisco>",ConvType(cInfFsc,2000))
		EndIf
		If !Empty(cInfCpl)
			cString += NfeTag("<infCpl>",ConvType(cInfCpl,5000))
		EndIf		
		cString += "</infAdic>"
	EndIf
Return cString
//
//----------------------------------------------------------------------
// Tag MDFeSupl
Static Function MDFeInfMDFeSupl()
	Local cString := ""
	
	cString += '<infMDFeSupl>'
	cString += '<qrCodMDFe>'
	cString += 'https://dfe-portal.svrs.rs.gov.br/mdfe/QRCode?chMDFe='
	cString += '</qrCodMDFe>'
	cString += '</infMDFeSupl>'	
	
Return cString
//
//----------------------------------------------------------------------
// Retorna o nro do Estado de acordo com a sigla recebida como parametro
Static Function GetUfCode(cUf)
	Local nPos := 0	
	Local cNroUf := ""
	
	nPos := aScan(aUF,{|x| x[1] == Alltrim(cUf) })
	If nPos > 0
		cNroUf	:= aUf[nPos,2]
	EndIf
Return cNroUf
//
//----------------------------------------------------------------------
// Conversão de tipo
Static Function ConvType(xValor,nTam,nDec)
	Local cNovo	:= ""
	Default nDec	:= 0

	Do Case
		Case ValType(xValor)=="N"
			If xValor <> 0
				cNovo := AllTrim(Str(xValor,nTam,nDec))	
			Else
				cNovo := "0"
			EndIf
		Case ValType(xValor)=="D"
			cNovo := FsDateConv(xValor,"YYYYMMDD")
			cNovo := SubStr(cNovo,1,4)+"-"+SubStr(cNovo,5,2)+"-"+SubStr(cNovo,7)
		Case ValType(xValor)=="C"
			If nTam==Nil
				xValor := AllTrim(xValor)
			EndIf
			DEFAULT nTam := 60
			cNovo := AllTrim(EnCodeUtf8(NoAcento(SubStr(xValor,1,nTam))))
	EndCase
Return(cNovo)
//
//----------------------------------------------------------------------
// Retira acento
Static Function NoAcento(cString)
	Local cChar	:= ""
	Local cVogal	:= "aeiouAEIOU"
	Local cAgudo	:= "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu	:= "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema	:= "äëïöü"+"ÄËÏÖÜ"
	Local cCrase	:= "àèìòù"+"ÀÈÌÒÙ" 
	Local cTio		:= "ãõÃÕ"
	Local cCecid	:= "çÇ"
	Local cMaior	:= "&lt;"
	Local cMenor	:= "&gt;"
	Local cEcom		:= "&"

	Local nX		:= 0 
	Local nY		:= 0

	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase+cEcom
			nY:= At(cChar,cAgudo)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf		
			nY:= At(cChar,cTio)
			If nY > 0          
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf		
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
			nY:= At(cChar,cEcom)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("eE",nY,1))
			EndIf
		Endif
	Next

	If cMaior$ cString 
		cString := strTran( cString, cMaior, "" ) 
	EndIf
	If cMenor$ cString 
		cString := strTran( cString, cMenor, "" )
	EndIf

	cString := StrTran( cString, CRLF, " " )

	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If (Asc(cChar) < 32 .Or. Asc(cChar) > 123) .and. !cChar $ '|' 
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
Return cString
//
//----------------------------------------------------------------------
// Inverte
Static Function Inverte(uCpo, nDig)
	Local cRet		:= ""
	Default nDig	:= 8

	cRet	:=	GCifra(Val(uCpo),nDig)
Return(cRet)
//
//----------------------------------------------------------------------
// NfeTag
Static Function NfeTag(cTag,cConteudo)
	Local cRetorno		:= ""

	If (!Empty(AllTrim(cConteudo)) .And. IsAlpha(AllTrim(cConteudo))) .Or. Val(AllTrim(cConteudo))<>0
		cRetorno := cTag+AllTrim(cConteudo)+SubStr(cTag,1,1)+"/"+SubStr(cTag,2)
	EndIf

Return(cRetorno)
//
//----------------------------------------------------------------------
// Valida Ie
Static Function VldIE(cInsc,lContr)
	Local cRet		:=	""
	Local nI		:=	1
	Default lContr  :=      .T.

	For nI:=1 To Len(cInsc)
		If Isdigit(Subs(cInsc,nI,1)) .Or. IsAlpha(Subs(cInsc,nI,1))
			cRet+=Subs(cInsc,nI,1)
		Endif
	Next
	cRet := AllTrim(cRet)
	If "ISENT"$Upper(cRet)
		cRet := ""
	EndIf
	If lContr .And. Empty(cRet)
		cRet := "ISENTO"
	EndIf
	If !lContr
		cRet := ""
	EndIf
Return(cRet)
//
//----------------------------------------------------------------------
// Função responsável em montar a Chave de Acesso e calcular o seu digito verIficador
/*

@param      	cUF...: Codigo da UF
				cAAMM.: Ano (2 Digitos) + Mes da Emissao do MDFe
				cCNPJ.: CNPJ do Emitente do MDFe
				cMod..: Modelo (58 = MDFe)
				cSerie: Serie do MDFe
				nCT...: Numero do MDFe
				cDV...: Numero do Lote de Envio a SEFAZ
@Return	cString
/*/
//-----------------------------------------------------------------------
Static Function MDFeChave(cUF, cAAMM, cCNPJ, cMod, cSerie, nMDF, cDV)

	Local nCount      := 0
	Local nSequenc    := 2
	Local nPonderacao := 0
	Local cResult     := ''
	Local cChvAcesso  := cUF +  cAAMM +  PADL(ALLTRIM(cCNPJ),14,"0") + cMod + cSerie + nMDF + cDV

	// SEQUENCIA DE MULTIPLICADORES (nSequenc), SEGUE A SEGUINTE        
	// ORDENACAO NA SEQUENCIA: 2,3,4,5,6,7,8,9,2,3,4... E PRECISA SER   
	// GERADO DA DIREITA PARA ESQUERDA, SEGUINDO OS CARACTERES          
	// EXISTENTES NA CHAVE DE ACESSO INFORMADA (cChvAcesso)             
	For nCount := Len( AllTrim(cChvAcesso) ) To 1 Step -1
		nPonderacao += ( Val( SubStr( AllTrim(cChvAcesso), nCount, 1) ) * nSequenc )
		nSequenc += 1
		If (nSequenc == 10)
			nSequenc := 2
		EndIf
	Next nCount

	// Quando o resto da divisão for 0 (zero) ou 1 (um), o DV devera   
	// ser igual a 0 (zero).                                           
	If ( mod(nPonderacao,11) > 1)
		cResult := (cChvAcesso + cValToChar( (11 - mod(nPonderacao,11) ) ) )
	Else
		cResult := (cChvAcesso + '0')
	EndIf
Return(cResult)
//
//----------------------------------------------------------------------
/* Função responsável buscar os dados do CIOT <infCIOT> (0-n)
<infCIOT>
	<CIOT> - Código Identificador da Operação de Transporte 
	(Também Conhecido como conta frete)
	<CPF> - Número do CPF responsável pela geração do CIOT ou
	ou
	<CNPJ> - Número do CNPJ responsável pela geração do CIOT
</infCIOT>

@Return	cString
*/
static function getInfCIOT()
	Local cString	:= ""
	Local cCgcCont	:= ""
	Local cCiot		:= ""
	Local nI		:= 1
	Local aCiot		:= iif(Type("oGetDCiot")<>"U",aClone(oGetDCiot:aCols),{})

	for nI := 1 to Len(aCiot)
		if !empty(aCiot[nI,1]) .And. !aCiot[nI,len(aCiot[nI])]
			cCiot	:= aCiot[nI,1]
			cCgcCont:= AllTrim(strTran(strTran(strTran(aCiot[nI,2],"."),"/"),"-"))

			cString += '<infCIOT>'
			cString += NfeTag('<CIOT>', ConvType(aCiot[nI,1],12,0))
			if len(cCgcCont) > 11
				cString += '<CNPJ>' + cCgcCont + '</CNPJ>'
			else
				cString += '<CPF>' + cCgcCont + '</CPF>'
			endIf
			cString += '</infCIOT>'
		endIf
	next nI

return cString
//
//----------------------------------------------------------------------
// Função responsável buscar os dados da informações de pagamento de 
Static Function getInfPag()
	local cString	:= ""
	local aDados	:= {}
	local aInfPag	:= {}

	if findFunction("MDFeInfPag")
		aDados := MDFeInfPag()
		cString := aDados[1]
		aInfPag := aDados[2]
	endif

Return cString
//
//----------------------------------------------------------------------
// Função para retirada dos caracteres '(', ')' , '+', ' ' e '-'
static function FormatTel(cTel)
	local cRet := ""
	default cTel := SM0->M0_TEL
	
	cRet := strtran(strtran(strtran(strtran(strtran(cTel, "(", ""), ")", ""), "+", ""), "-", ""), " ", "")
return cRet
//
//----------------------------------------------------------------------
// Responsavel por montar a TAG <tpTransp>
static function retTpTransp(cVeiculo)
	local cString	:= ""
	local cTpProp	:= ""
	local cTpTransp	:= "3"

	default cVeiculo	:= ""

	if !Empty(cVeiculo)
		DA3->(dbSetOrder(1)) //"DA3_FILIAL+DA3_COD"
		if DA3->(MsSeek(xFilial("DA3")+cVeiculo)) .and. !(DA3->DA3_FROVEI == '1') //1-Propria / 2-Terceiro / 3-Agregado

			cTpProp := posicione("SA2", 1, xfilial("SA2")+DA3->DA3_CODFOR+DA3->DA3_LOJFOR, "A2_TIPO")

			if cTpProp == "F"
				cTpTransp := "2"
			elseIf cTpProp == "J"
				cTpTransp := "1"
			endIf

			cString := '<tpTransp>' + cTpTransp + '</tpTransp>' // 1-ETC  2-TAC  3-CTC 
		endIf
	endIf

return cString
//
//----------------------------------------------------------------------
// Responsavel por montar o grupo de Vale Pedagio TAG <valePed>
static function valePed(cVeiculo)
	local cString	:= ""
	local cCgc		:= ""
	local nI		:= 0
	local aValPed	:= iif(Type("oGetDValPed")=="O",aClone(oGetDValPed:aCols),{})
	local lHasData	:= .F.

	if len(aValPed) > 0
		cString += "<valePed>"
		for nI := 1 to len(aValPed)
			if !aValPed[nI,len(aValPed[nI])] .and. !Empty(aValPed[nI,1]) 
				lHasData := .T.
				cString += "<disp>"
					cCgc := allTrim(aValPed[nI,1])
					cString += "<CNPJForn>" + replic("0",14-len(cCgc)) + cCgc  + "</CNPJForn>" //CNPJ da empresa fornecedora do Vale-Pedágio
					if !Empty(aValPed[nI,2])
						cCgc := StrTran(StrTran(StrTran(alltrim(aValPed[nI,2]),"."),"/"),"-")
						if len(cCgc) < 14
							cString += "<CPFPg>" +  replic("0",11-len(cCgc)) + cCgc + "</CPFPg>" //CPF do responsável pelo pagamento do Vale-Pedágio
						else
							cString += "<CNPJPg>" + replic("0",14-len(cCgc))  + cCgc + "</CNPJPg>" //CNPJ do responsável pelo pagamento do Vale-Pedágio
						endIf
					endIf
					if !Empty(aValPed[nI,3])
						cString += "<nCompra>" + allTrim(aValPed[nI,3]) + "</nCompra>" //Número do comprovante de compra
					endif
					cString += "<vValePed>" + ConvType(aValPed[nI,4],16,2) + "</vValePed>" //Valor do Vale-Pedagio
					if !Empty(aValPed[nI,5])
						cString += "<tpValePed>" + StrZero(val(aValPed[nI,5]),2) + "</tpValePed>" //Tipo do Vale Pedagio
					endIf
				cString += "</disp>"
			endIf
		next nI
		
		cString +=	"<categCombVeic>" + CatCombVeic(cVeiculo) + "</categCombVeic>"
		cString += "</valePed>"

		if !lHasData //tratamento para caso o vale-pedagio tenha sido excluido
			cString := ""
		endIf
	endIf
return cString
//
//----------------------------------------------------------------------
// Define a Categoria de Combinação Veicular 
static function CatCombVeic(cVeiculo)
	local cCategoria	:= ""
	local nQtdEixo		:= 0

	DA3->(dbSetOrder(1)) //
	if DA3->(MsSeek(xFilial("DA3")+cVeiculo))
		nQtdEixo := DA3->DA3_QTDEIX

		do case 
			case nQtdEixo == 2
				cCategoria := "02"
			case nQtdEixo == 3
				cCategoria := "04"
			case nQtdEixo == 4
				cCategoria := "06"
			case nQtdEixo == 5
				cCategoria := "07"
			case nQtdEixo == 6
				cCategoria := "08"
			case nQtdEixo == 7
				cCategoria := "10"
			case nQtdEixo == 8
				cCategoria := "11"
			case nQtdEixo == 9
				cCategoria := "12"
			case nQtdEixo == 10
				cCategoria := "13"
			case nQtdEixo > 10
				cCategoria := "14"
		end case
	endIf
return cCategoria
//
//----------------------------------------------------------------------
// Retorna a TAG de Produto Predominante
static function MDFeProdPred()
	local cString	:= ""

	if type("oGettpCarga") <> "U" .and.;
		(!empty(cPPxProd) .or. !empty(cVVTpCarga) .or. !empty(cPPCEPCarr) .or.;
		!empty(cPPCEPDesc) .or. !empty(cPPCodbar) .or. !empty(cPPNCM) )

		cString += "<prodPred>"
			cString += "<tpCarga>" + subStr(cVVTpCarga,1,2) + "</tpCarga>"
			cString += "<xProd>" + allTrim(cPPxProd) + "</xProd>"
			if !empty(cPPCodbar)
				cString += "<cEAN>" + allTrim(cPPCodbar) + "</cEAN>"
			endIf
			if !empty(cPPNCM)
				cString += "<NCM>" + allTrim(cPPNCM) + "</NCM>"
			endIf

			if !empty(cPPCEPCarr) .Or. !empty(cPPCEPDesc)
				cString += "<infLotacao>"
					cString += "<infLocalCarrega>"
						cString += "<CEP>" + iif(!empty(cPPCEPCarr),strZero(val(cPPCEPCarr),8),"") + "</CEP>"
					cString += "</infLocalCarrega>"
					cString += "<infLocalDescarrega>"
						cString += "<CEP>" + iif(!empty(cPPCEPDesc),strZero(val(cPPCEPDesc),8),"") + "</CEP>"
					cString += "</infLocalDescarrega>"
				cString += "</infLotacao>"
			endif
		cString += "</prodPred>"
	EndIf
return cString
