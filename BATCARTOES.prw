//  Programa...: BATCARTOES
//  Autor......: Catia Cardoso
//  Data.......: 09/07/2019
//  Descricao..: Concilia recebimentos cartoes de credito por filial
// 
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------

User Function BATCARTOES()
Local i := 0
local j := 0

	// FAZ O LANÇAMENTO DAS TARIFAS NOS TITULOS
	u_help("Efetua lançamento de tarifas")
	_sSQL := ""
	_sSQL += " SELECT AUX.FILIAL, AUX.DTLAN, AUX.TARIFADMC, AUX.TARIFCOMC"
	_sSQL += "  	, SE1.E1_NUM, SE1.E1_PREFIXO, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_CLIENTE"
	_sSQL += "  	, SE1.R_E_C_N_O_"
	_sSQL += "  	, AUX.VLRPARCLIQ"
	_sSQL += " 	 FROM AUX_CARTOES AS AUX"
	_sSQL += " 		LEFT JOIN SE1010 AS SE1"
	_sSQL += " 			ON (SE1.D_E_L_E_T_     = ''"
	_sSQL += " 				AND SE1.E1_FILIAL  = AUX.FILIAL"
	_sSQL += "				AND SE1.E1_VALOR   = AUX.VLRPARC"
	_sSQL += "				AND SE1.E1_EMISSAO = AUX.DTMOV"
	_sSQL += "              AND SE1.E1_SALDO >0"
	_sSQL += " 				AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
	_sSQL += "				AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
	_sSQL += "			                          	  WHEN AUX.PARCELA='02' THEN 'B'" 
	_sSQL += "									  	  WHEN AUX.PARCELA='03' THEN 'C'"
	_sSQL += "									  	  WHEN AUX.PARCELA='04' THEN 'D'" 
	_sSQL += "									      WHEN AUX.PARCELA='05' THEN 'E'"
	_sSQL += "									  	  WHEN AUX.PARCELA='06' THEN 'F'" 
	_sSQL += "								 	  END )"
	_sSQL += "   WHERE AUX.FILIAL = '" + xfilial("SE1") + "'" 
	_sSQL += " 	 ORDER BY AUX.FILIAL"
	//u_showmemo(_sSQL)
	_aTitulos  := U_Qry2Array(_sSQL)
	//u_showarray(_aTitulos)
	if len(_aTitulos) > 0
		for i=1 to len(_aTitulos)
			lMsErroAuto := .F.
			// executar a rotina de baixa automatica do SE1 gerando o SE5
			_aAutoSE1 := {}
			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulos[i,1]    , Nil})
			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulos[i,6]    , Nil})
			aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulos[i,5]    , Nil})
			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulos[i,7]    , Nil})
			aAdd(_aAutoSE1, {"E1_TIPO" 	    , _aTitulos[i,8]    , Nil})
			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulos[i,9]    , Nil})
			aAdd(_aAutoSE1, {"E1_BAIXA" 	, stod (_aTitulos[i,2])   , Nil})
			aAdd(_aAutoSE1, {"E1_LOJA"    	, '01'              , Nil})
			AAdd(_aAutoSE1, {"AUTMOTBX"		, 'NORMAL'  		, Nil})
			AAdd(_aAutoSE1, {"AUTBANCO"  	, '041'		    	, Nil})
			AAdd(_aAutoSE1, {"AUTAGENCIA"  	, fBuscaCpo ('SA6', 4, _aTitulos[i,1] + '2041', "A6_AGENCIA") , Nil})
			AAdd(_aAutoSE1, {"AUTCONTA"  	, fBuscaCpo ('SA6', 4, _aTitulos[i,1] + '2041', "A6_NUMCON")  , Nil})
			AAdd(_aAutoSE1, {"AUTDTBAIXA"	, stod (_aTitulos[i,2])	, Nil})      
			AAdd(_aAutoSE1, {"AUTDTCREDITO"	, stod (_aTitulos[i,2])	, Nil})  
			AAdd(_aAutoSE1, {"AUTHIST"   	, 'Tarifa Cartoes'  , Nil})
			AAdd(_aAutoSE1, {"AUTDESCONT"	, _aTitulos[i,3] + _aTitulos[i,4] , Nil})
			AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTVALREC"  	, 0 				, Nil})
			
			//u_showarray (_aAutoSE1)
		   _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
		   
		   cPerg = 'FIN070'
		   _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		   U_GravaSX1 (cPerg, "01", 1)    // testar mostrando o lcto contabil depois pode passar para nao
		   U_GravaSX1 (cPerg, "04", 1)    // esse movimento tem que contabilizar
		   
		   MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
			
	       If lMsErroAuto
	       		MostraErro()
			    Return()
		   Endif  
		   	
		   U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina
		   
		next
	endif
	u_help("conferir a baixa das tarifas e contabilizacao destes lançamentos")
return	
	// GERA FATURAS REFERENTE AOS TITULOS RECEBIDOS
	u_help("Gera faturas referente aos titulos recebidos")
	_sSQL := ""
	_sSQL += " SELECT DISTINCT AUX.FILIAL, AUX.DTLAN, SE1.E1_TIPO, SE1.E1_CLIENTE"
	_sSQL += " 	 FROM AUX_CARTOES AS AUX"
	_sSQL += " 		LEFT JOIN SE1010 AS SE1"
	_sSQL += " 			ON (SE1.D_E_L_E_T_     = ''"
	_sSQL += " 				AND SE1.E1_FILIAL  = AUX.FILIAL"
	_sSQL += "				AND SE1.E1_VALOR   = AUX.VLRPARC"
	_sSQL += "				AND SE1.E1_EMISSAO = AUX.DTMOV"
	_sSQL += "              AND SE1.E1_SALDO >0"
	_sSQL += " 				AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
	_sSQL += "				AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
	_sSQL += "			                          	  WHEN AUX.PARCELA='02' THEN 'B'" 
	_sSQL += "									  	  WHEN AUX.PARCELA='03' THEN 'C'"
	_sSQL += "									  	  WHEN AUX.PARCELA='04' THEN 'D'" 
	_sSQL += "									      WHEN AUX.PARCELA='05' THEN 'E'"
	_sSQL += "									  	  WHEN AUX.PARCELA='06' THEN 'F'" 
	_sSQL += "								 	  END )"
	_sSQL += "   WHERE AUX.FILIAL = '" + xfilial("SE1") + "'"	  
	_sSQL += " 	 ORDER BY AUX.FILIAL"
	u_showmemo(_sSQL)
	_aFaturas  := U_Qry2Array(_sSQL)
	u_showarray(_aFaturas)
	if len(_aFaturas) > 0
	
		for i=1 to len(_aFaturas)
	
			aTit := {}
			aCab := {}
			aDadosTit := {}
			lMsErroAuto := .F.
		
			_wnumero  := _aFaturas[i,3]
			_wfilial  := _aFaturas[i,1]
			_wdata	  := _aFaturas[i,2]
			_wtipo    := _aFaturas[i,3]
			_wcliente := _aFaturas[i,4]
			
			_sSQL := ""
			_sSQL += " SELECT AUX.FILIAL, AUX.DTLAN, AUX.TARIFADMC, AUX.TARIFCOMC"
			_sSQL += "  	, SE1.E1_NUM, SE1.E1_PREFIXO, SE1.E1_PARCELA, SE1.E1_TIPO, SE1.E1_CLIENTE"
			_sSQL += "  	, SE1.R_E_C_N_O_, AUX.VLRPARCLIQ"
			_sSQL += " 	 FROM AUX_CARTOES AS AUX"
			_sSQL += " 		INNER JOIN SE1010 AS SE1"
			_sSQL += " 			ON (SE1.D_E_L_E_T_     = ''"
			_sSQL += " 				AND SE1.E1_FILIAL  = AUX.FILIAL"
			_sSQL += "				AND SE1.E1_VALOR   = AUX.VLRPARC"
			_sSQL += "				AND SE1.E1_EMISSAO = AUX.DTMOV"
			_sSQL += "              AND SE1.E1_TIPO    = '" + _wtipo + "'"
			_sSQL += "              AND SE1.E1_CLIENTE = '" + _wcliente + "'"
			_sSQL += "              AND SE1.E1_SALDO >0"
			_sSQL += " 				AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
			_sSQL += "				AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
			_sSQL += "			                          	  WHEN AUX.PARCELA='02' THEN 'B'" 
			_sSQL += "									  	  WHEN AUX.PARCELA='03' THEN 'C'"
			_sSQL += "									  	  WHEN AUX.PARCELA='04' THEN 'D'" 
			_sSQL += "									      WHEN AUX.PARCELA='05' THEN 'E'"
			_sSQL += "									  	  WHEN AUX.PARCELA='06' THEN 'F'" 
			_sSQL += "								 	  END )"	  
			_sSQL += " 	 WHERE AUX.FILIAL = '" + _wfilial + "'"
			_sSQL += " 	   AND AUX.DTLAN  = '" + _wdata + "'"
			_sSQL += " 	 ORDER BY AUX.FILIAL, SE1.E1_CLIENTE"
			u_showmemo(_sSQL)
			_aDadosTit  := U_Qry2Array(_sSQL)
			u_showarray(_aDadosTit)
			for j=1 to len(_aDadosTit)
				// gera array de titulos a ser baixado para gerar a fatura
				_wrecno := _aDadosTit [j,10] 
				AADD(aTit, {"RECNO"		, _wrecno, Nil})
			next
			
			// gera a fatura da administradora de cartao
			AADD(aCab, {"AUTPREFIXO"	, "FAT"  	, Nil})
			AADD(aCab, {"AUTTIPO" 		, _wtipo	, Nil}) 
			AADD(aCab, {"AUTNUMFAT"		, _wnumero	, Nil})  
			AADD(aCab, {"AUTNATUR"		, "CARTAO"  , Nil}) 
			AADD(aCab, {"AUTMOEDA"		, "01"		, Nil}) 
			AADD(aCab, {"AUTCLIGER"		, _wcliente	, Nil}) 
			AADD(aCab, {"AUTLOJGER"		, "01"		, Nil})
			AADD(aCab, {"AUTCONDPG"		, "097"     , Nil}) // CONDICAO QUE SEJA APRESENTACAO E VENÇA NO MESMO DIA QUE FOI EMITIDA
	
			aAdd(aCab,{"AUTSELTIT",aTit,Nil}) // Adicionando os Títulos a serem Faturados;
		
			MsExecAuto( { |x,y,z| FINA280(x,y,z)} , 3, .F. , aCab)
			
			If lMsErroAuto
		   		MostraErro()
			    Return()
			Endif
		next
	endif
	// apos geracao da fatura - baixa as fatura geradas, gerando movimento bancario no valor total do movimento que vai fechar com o extrato
	if len(_aFaturas) > 0
		u_help("Baixa Faturas Geradas")
		for i=1 to len(_aFaturas)
		
			_wfilial  := _aFaturas[i,1]
			_wdata    := _aFaturas[i,2]
			_wtipo    := _aFaturas[i,3]
			_wcliente := _aFaturas[i,4]
	
			_sSQL := ""
			_sSQL += " SELECT E1_NUM, E1_PREFIXO, E1_PARCELA, E1_SALDO"
			_sSQL += "   FROM SE1010
			_sSQL += "  WHERE E1_FILIAL  = '" + _wfilial + "'"
			_sSQL += "    AND E1_CLIENTE = '" + _wcliente + "'"
			_sSQL += "    AND E1_TIPO    = '" + _wtipo + "'"
			_sSQL += "    AND E1_EMISSAO = '" + _wdata + "'"
			_sSQL += "    AND E1_PREFIXO = 'FAT'
			_sSQL += "    AND E1_NATUREZ = 'CARTAO'
			u_showmemo(_sSQL)
			_aFatBaixar  := U_Qry2Array(_sSQL)
			u_showarray(_aFatBaixar)
			if len(_aFatBaixar) > 0
				for j=1 to len(_aFatBaixar)
	
					_aAutoSE1 := {}
					aAdd(_aAutoSE1, {"E1_FILIAL" 	, _wfilial          , Nil})
					aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aFatBaixa[j,2]	, Nil})
					aAdd(_aAutoSE1, {"E1_NUM"     	, _aFatBaixa[j,1] 	, Nil})
					aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aFatBaixa[j,3]	, Nil})
					aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _wcliente		 	, Nil})
					aAdd(_aAutoSE1, {"E1_LOJA"    	, "01" 				, Nil})
					AAdd(_aAutoSE1, {"AUTMOTBX"		, 'NORMAL'  		, Nil})
					AAdd(_aAutoSE1, {"AUTBANCO"  	, '041'		    	, Nil})
					AAdd(_aAutoSE1, {"AUTAGENCIA"  	, fBuscaCpo ('SA6', 4, _wfilial + '2041', "A6_AGENCIA")  , Nil})
					AAdd(_aAutoSE1, {"AUTCONTA"  	, fBuscaCpo ('SA6', 4, _wfilial + '2041', "A6_NUMCON")  , Nil})
					AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _wdata	  		, Nil})  
					AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _wdata			, Nil})  
					AAdd(_aAutoSE1, {"AUTHIST"   	, 'Valor recebido Cartoes', Nil}) // ver que historico querem colocar
					AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         		, Nil})
					AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
					AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
					AAdd(_aAutoSE1, {"AUTVALREC"  	, _aFatBaixa[j,4]	, Nil})
						
				   _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
				   
				   cPerg = 'FIN070'
				   _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
				   U_GravaSX1 (cPerg, "01", 1)
				   U_GravaSX1 (cPerg, "04", 1)
					
				   MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
		
				   If lMsErroAuto
				   		MostraErro()
					    Return()
				   Endif  
				
				   U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina
			  next
		   endif
		next
	endif   
	u_help("Processo finalizado")
return