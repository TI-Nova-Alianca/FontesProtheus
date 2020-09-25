//  Programa...: VA_TITBARRAS
//  Autor......: Catia Cardoso
//  Data.......: 17/10/2018
//  Descricao..: Consulta Documentos de Entrada EXCLUIDOS p/Periodo 
// 04/12/2018 - Andre  - Adicionado validação dos campos E2_CODBAR e E2_LINDIG com a função VLDCODBAR
// 
//  Historico de alterações
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_TITBARRAS()

	cPerg   := "VA_TITBARRAS"
	
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.)
     	do while .t.
	    	_sQuery := ""
	    	_sQuery += "SELECT dbo.VA_DTOC(E2_VENCREA)"
	    	_sQuery += " 	 , sum(CASE WHEN E2_CODBAR = ''  THEN 1 ELSE 0 END) AS SEM"
	    	_sQuery += " 	 , sum(CASE WHEN E2_CODBAR = ''  THEN 1 ELSE 0 END) * 100 / count(*) AS PSEM"
	    	_sQuery += " 	 , sum(CASE WHEN E2_CODBAR != ''  THEN 1 ELSE 0 END) AS COM"
	    	_sQuery += " 	 , sum(CASE WHEN E2_CODBAR != ''  THEN 1 ELSE 0 END) * 100 / count(*) AS PCOM"
	    	_sQuery += " 	 , COUNT(*)  AS TOTAL_HOJE"
	    	_sQuery += " 	 , IIF((sum(CASE WHEN E2_CODBAR != ''  THEN 1 ELSE 0 END) * 100 / count(*)>60),'Aconselhável gerar arquivo','Não aconselhável gerar arquivo') AS OBSERVACAO"
	    	_sQuery += " 	 , E2_VENCREA"
	    	_sQuery += "  FROM SE2010"
	    	_sQuery += " WHERE D_E_L_E_T_  = ''"
	    	_sQuery += "   AND E2_FILIAL   = '01'"
		    _sQuery += "   AND E2_PREFIXO != '30'" // ignora pagamento de safra
	    	_sQuery += "   AND E2_PREFIXO != '31'" // ignora pagamento de safra
	    	_sQuery += "   AND E2_TIPO    !='PR'"  // ignora provisorios
	    	_sQuery += "   AND E2_TIPO    !='PRI'" // ignora provisorios
	    	_sQuery += "   AND E2_TIPO    !='TX'"  // ignora impostos
	    	_sQuery += "   AND E2_TIPO    !='TXA'" // ignora impostos
	    	_sQuery += "   AND E2_TIPO    !='INS'" // ignora impostos
	    	_sQuery += "   AND E2_TIPO    !='ISS'" // ignora impostos
	    	_sQuery += "   AND E2_TIPO    !='IRF'" // ignora impostos
	    	_sQuery += "   AND E2_TIPO    !='FOL'" // ignora impostos
	    	_sQuery += "   AND NOT (E2_TIPO ='NF' AND E2_NATUREZ = '120206' AND E2_CODBAR = '')" // ignora titulos de fretes pois eh gerada fatura
	    	_sQuery += "   AND E2_NUMBOR = ''"     // desconsidera o que ja esta em bordero
	    	_sQuery += "   AND E2_VENCREA BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    	_sQuery += " GROUP BY E2_VENCREA"
	    	_sQuery += " ORDER BY E2_VENCREA"
	   		//u_showmemo (_sQuery)
	   		
			_aDados := U_Qry2Array(_sQuery)
	    	if len(_aDados) > 0
	    	    
	    		_aCols = {}
	    	
	    		aadd (_aCols, { 1, "Vencimento"     	,  40,  "@D"})
	    		aadd (_aCols, { 2, "SemCodBarras"       ,  40,  "@!"})
		    	aadd (_aCols, { 3, "%Sem"   	        ,  40,  "@E 999"})
				aadd (_aCols, { 4, "ComCodBarras"       ,  40,  "@!"})
				aadd (_aCols, { 5, "%Com"   	        ,  40,  "@E 999"})
				aadd (_aCols, { 6, "Total Titulos"      ,  40,  "@!"})
				aadd (_aCols, { 7, "Observação"         , 150,  "@!"})
				
				_wlinha = U_F3Array (_aDados, "Consulta Titulos a Pagar", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )
				
		    	if _wlinha > 0
		    		
		    		do while .t.
			    		_sQuery := ""
			    		_sQuery += " SELECT E2_EMISSAO, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_NOMFOR, E2_NATUREZ"
			    		_sQuery += "      , E2_CODBAR, E2_VALOR, R_E_C_N_O_"
			    		_sQuery += "  FROM SE2010"
			    		_sQuery += " WHERE D_E_L_E_T_  = ''"
			    		_sQuery += "   AND E2_FILIAL   = '01'"
			    		_sQuery += "   AND E2_PREFIXO != '30'" // ignora pagamento de safra
			    		_sQuery += "   AND E2_PREFIXO != '31'" // ignora pagamento de safra
			    		_sQuery += "   AND E2_TIPO    !='PR'"  // ignora provisorios
			    		_sQuery += "   AND E2_TIPO    !='PRI'" // ignora provisorios
			    		_sQuery += "   AND E2_TIPO    !='TX'"  // ignora impostos
			    		_sQuery += "   AND E2_TIPO    !='TXA'" // ignora impostos
			    		_sQuery += "   AND E2_TIPO    !='INS'" // ignora impostos
			    		_sQuery += "   AND E2_TIPO    !='ISS'" // ignora impostos
			    		_sQuery += "   AND E2_TIPO    !='IRF'" // ignora impostos
			    		_sQuery += "   AND E2_TIPO    !='FOL'" // ignora impostos
			    		_sQuery += "   AND NOT (E2_TIPO ='NF' AND E2_NATUREZ = '120206' AND E2_CODBAR = '')" // ignora titulos de fretes pois eh gerada fatura
			    		_sQuery += "   AND E2_NUMBOR = ''"     // desconsidera o que ja esta em bordero
			    		_sQuery += "   AND E2_VENCREA = '" + dtos (_aDados[_wlinha,8]) + "'"
		    			_sQuery += " ORDER BY E2_NOMFOR 
		    			_aDados1 := U_Qry2Array(_sQuery)
			    		if len(_aDados1) > 0
			    			_aCols1 = {}
			    	
			    			aadd (_aCols1, {01, "Emissao"         	,  10,  "@D"})
			    			aadd (_aCols1, {02, "Prefixo"         	,  10,  "@!"})
				    		aadd (_aCols1, {03, "Numero"     	 	,  10,  "@!"})
				    		aadd (_aCols1, {04, "Parcela"        	,  30,  "@!"})
				    		aadd (_aCols1, {05, "Tipo"           	,  10,  "@!"})
				    		aadd (_aCols1, {06, "Fornecedor"     	,  40,  "@!"})
				    		aadd (_aCols1, {07, "Nome" 	     	  	, 100,  "@!"})
				    		aadd (_aCols1, {08, "Natureza"         	,  30,  "@!"})
				    		aadd (_aCols1, {09, "Cod.Barras"  	    ,  60,  "@!"})
				    		aadd (_aCols1, {10, "Valor"       	    ,  60,  "@E 9,999,999.99"})
				    		
			    			_wtitulo = U_F3Array (_aDados1, "Consulta Titulos com vencimento em : "+_aDados[_wlinha,1], _aCols1, oMainWnd:nClientWidth - 300, oMainWnd:nClientHeight -200 , "", "", .T., 'C' )
			    			if _wtitulo > 0
			    				if empty(_aDados1[_wtitulo,9])
			    					_walterou  = .F.
			    					_lContinua = .T.
				    				do while _lContinua
				    					_wbarras = space(47)
										_wbarras = U_Get ("Informe o codigo de barras: ", "C", 47, "", "", _wbarras, .F., '.T.')
										if _wbarras = NIL  // Usuario cancelou
											_lContinua = .F.
										endif
										if _lContinua .and. ! empty (_wbarras)
											// valida codigo de barras
											_wCodBar := VldCodBar(_wbarras)
											if _wCodBar = .T.
												_wvalor = _aDados1[_wtitulo,10]
												// se o valor esta no final da string informada é a linha digitavel	
												if (val(substr(_wbarras,38,10))/100) == _wvalor 
													_wlindig = _wbarras 
													// converte o codigo de barras para o formato CNAB correto
													_wbarras := SUBSTR(_wbarras,1,4)+SUBSTR(_wbarras,33,15)+SUBSTR(_wbarras,5,5)+SUBSTR(_wbarras,11,10)+SUBSTR(_wbarras,22,10)
													_wCodBar := VldCodBar(_wbarras)
													if _wCodBar = .F.
													 _lContinua = .F.
													endif
												else 
													_wlindig = ''
												endif
											else
											_lContinua = .F.
											endif
											// atualiza codigo de barras no SE2
											if _lContinua 
												dbselectarea("SE2")
												dbgoto(_aDados1[_wtitulo,11])
												reclock("SE2", .F.)
												SE2->E2_CODBAR = _wbarras
												SE2->E2_LINDIG = _wlindig
												MsUnLock()
												_lContinua = .F.
											endif
										endif
									enddo
								endif
							else
								exit	
			    			endif
			    		endif	
					enddo
				else	
					exit
				endif
			else
				msgalert("Não foram encontrados dados para consulta")
			endif
	   enddo	
		    		
	endif
	
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Vencimento Inicial  ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Vencimento Final    ?", "D", 8, 0,  "",   "   ", {},  ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return