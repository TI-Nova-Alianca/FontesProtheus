// Programa...: F200VAR
// Autor......: Jeferson Rech
// Data.......: 03/2007
// Cliente....: Alianca
// Descricao..: Tratamento Recepcao Bancaria CNAB - Compatibiliza Baixas 
//
// Historico de alteracoes:
// 16/09/2008 - Robert  - Na leitura do BB, soma 'outros creditos' aos 'juros'.
// 01/10/2008 - Robert  - Zera variavel nVarCc na leitura do BB, apos somar 'outros creditos' aos 'juros'.
// 17/02/2009 - Robert  - Desabilitada gravacao de logs.
// 03/06/2009 - Robert  - Zera valor desconto em baixas normais do Banco do Brasil
// 17/06/2010 - Robert  - Ajustes para quando for chamado a partir do P.E. F650VAR
//                      - Quando recebto. a maior no Sicredi, joga a diferenca como juros.
//                      - Zera valor recebido quando ocorrencia = 28 (tarifa) no Sicredi.
// 10/09/2010 - Robert  - Soma custas de cartorio aos juros para qquer ocorrencia no banco 001 (antes soh fazia para ocor. 15)
// 14/06/2012 - Robert  - Gera log de evento quando joga vl.recebido a maior como juros (Sicredi). O procedimento jah existia, apenas nao gerava evento.
// 24/09/2012 - Robert  - Insere prefixo no inicio do numero do titulo (ver comentario no local).
// 05/11/2012 - Robert  - Nao insere mais prefixo no inicio do numero do titulo (vamos usar IDCNAB).
// 01/03/2013 - Robert  - Volta a usar E1_NUM em lugar do E1_IDCNAB por exigencia de alguns clientes.
// 20/03/2013 - Robert  - Ajustes na busca do IDCNAB de titulos antigos (6 posicoes + parcela).
// 28/06/2013 - Leandro - Considerar juros e despesas no total recebido, quando banco � Banrisul
// 02/07/2014 - Catia   - zerar o valor do desconto tb no caso do BANRISUL e NAO considerar despesas no total recebido.
// 11/07/2014 - Catia   - BANRISUL - n�o estava fazendo corretamente o tratamento do R A P E L - transitorio - instrucao 30
// 25/09/2014 - Catia   - BANRISUL - tratamento para que trate as despesas so se a ocorrencias for <> de 15
// 26/11/2014 - Catia   - TITULO NAO ENCONTRADO/ESPECIE NAO ENCONTRADA - estava setando errado o nro do titulo - BANRISUL - FILIAL 13
// 04/12/2014 - Catia   - TITULO NAO ENCONTRADO/ESPECIE NAO ENCONTRADA - estava setando errado o nro do titulo - BB FILIAIS - CONV 7 POSICOES
// 23/12/2014 - Catia   - Tratamento para que pegue o nro do titulo correto quando for banco SAFRA - filial 01
// 23/12/2014 - Catia   - Tratamento para que pegue o nro do titulo correto quando for banco BANRISUL - filial 13
// 29/12/2014 - Catia   - Tratamento para que pegue o nro do titulo correto para todos os bancos - filial 01
// 22/01/2015 - Catia   - Tratamento da regra de desconto para o SAFRA igual a do BB
// 26/06/2015 - Catia   - Santander - Tratamento de custas de cartorio - que vem na coluna de multas (?) - n�o sei pq
// 24/07/2015 - Catia   - Banrisul - ajustes para processar o retorno da filial 10
// 28/09/2015 - Catia   - Erro quando baixava arquivo do contas a receber
// 30/09/2015 - Catia   - Mensagem titulo nao encontrado no relatorio do contas a receber
// 02/10/2015 - Catia   - Teste especifico do contas a receber para identificar os titulos
// 19/02/2016 - Catia   - Ajuste da rotina especifica do SICREDI - nao estava dando o tratamento correto pra juros e descontos
// 08/06/2016 - Catia   - Ajuste para conta do banco do brasil da filial 09 - IDCNAB - que estava dando mensagem de titulo nao encontrado
// 25/10/2016 - Catia   - Ajuste despesas de cartorio que nao estava baixando automatico no titulo
// 10/04/2017 - Catia   - Ajuste para banco 237 - igual ao que ja fazia para o 239
// 29/04/2017 - Catia   - Ajuste despeas de cartorio - banco 001
// 05/06/2017 - Catia   - Banco Novo ITAU - 341 - as despesa vem deduzidas do valor pago
// 29/06/2017 - Catia   - Ajuste para atender a situa��o das faturas a receber
// 17/08/2017 - Catia   - Tratamento para banco 104 - CAIXA - alguns titulos que o sistema nao estava localizando o E1_IDCNAB
// 06/09/2017 - Catia   - Banrisul pra filial 08
// 04/04/2018 - Catia   - Bradesco tratamento para buscar as despesas de cartorio
// 08/05/2018 - Catia   - BBrasil - tratamento despesas para a ocorrencia 12
// 27/08/2018 - Catia   - Sicredi - tratamento para buscar as despesas financeiras na ocorrencia 28
// 26/06/2019 - Catia   - Itau - tratamento despesas de cartorio ocorrencias 08
// 01/07/2020 - Cl�udia - Inclus�o de filial 16 para banco do brasil. GLPI: 8103
//
// -------------------------------------------------------------------------------------------------------------------------------------------
User Function F200VAR()

	Local _aArea    := GetArea()
	Local _aAreaSE1 := SE1->(GetArea())
	Local _aAreaSA1 := SA1->(GetArea())
	Local _lRet     := .T.
	local _aValores := aclone (paramixb [1])
	local _oEvento  := NIL
	local _l650     := .F.
	local _aAux     := {}
	local _nValOri  := 0
	local _sTitulo  := ""

	// Verifica se foi chamado a partir do P.E. F650Var (FINR650 - relatorio do CNAB)
	if len (_aValores) == 14
		_l650 = .T.
		
		// Ajusta dados para que fiquem com o mesmo formato enviado pelo FINA200.
		cBanco = mv_par03
		nOutrDesp = 0
		_aAux = array (16)
		_aAux [1]  = _aValores  [1]
		_aAux [2]  = _aValores  [2]
		_aAux [3]  = _aValores  [3]
		_aAux [4]  = _aValores  [4] // nosso numero
		_aAux [5]  = _aValores  [5]
		_aAux [6]  = _aValores  [6]
		_aAux [7]  = _aValores  [7]
		_aAux [8]  = _aValores  [8]
		_aAux [9]  = _aValores  [9] // juros
		_aAux [10] = _aValores [10] // tarifa de cobranca
		_aAux [11] = 0
		_aAux [12] = _aValores [11] // outras despesas
		_aAux [13] = _aValores [12] // despesas de cartorio
		_aAux [14] = _aValores [13]
		_aAux [15] = ""
		_aAux [16] = _aValores [14]
		_aValores  = aclone (_aAux)
	endif
	
	//u_showarray (_aValores)

	// Posicoes dos dados na array:
	// aValores[01] - Numero do titulo
	// aValores[02] - Data da baixa
	// aValores[03] - Tipo do titulo
	// aValores[04] - Nosso numero
	// aValores[05] - Valor da despesa
	// aValores[06] - Valor do desconto
	// aValores[07] - Valor do abatimento
	// aValores[08] - Valor recebido
	// aValores[09] - Valor dos juros
	// aValores[10] - Valor da multa
	// aValores[11] - Valor de outras depesas
	// aValores[12] - Valor do credito
	// aValores[13] - Data do credito
	// aValores[14] - Ocorrencia
	// aValores[15] - Motivo da baixa
	// aValores[16] - Linha Inteira

	// Logs para depuracao
//	u_log ("cBanco = ", cbanco)
//	u_log ("_aValores:", {_avalores})
//	u_log ("nValRec: ",   nValRec)
//	u_log ("nJuros: ",    nJuros)
//	u_log ("nAbatim: ",   nAbatim)
//	u_log ("nDescont: ",  nDescont)
//	u_log ("nDespes: ",   nDespes)
//	u_log ("nMulta: ",    nMulta)
//	u_log ("nOutrDesp: ", nOutrDesp)
//	u_log ("nValCC: ",    nValCC)

	// Verifica qual banco estah sendo processado. Verifica diferentes variaveis por que este
	// ponto de entrada eh executado na impressao de relatorio e na importacao do arquivo de retorno.
//	u_log ('Banco:', cBanco)
	
	// TRATAMENTO DO CNAB A RECEBER
	if IsInCallStack ("FINA200") .or. (IsInCallStack ("FINR650") .and. mv_par07= 1) 
	
		if substr(cNumTit,1,3) == '000'
			_sTitulo = '10 ' + cNumTit
		else
			_sTitulo = 'FAT' + cNumTit
		endif

		if cBanco == '104' .and. xFilial("SE1") = '01'
			if len(cNumTit) = 10 
				// em alguns casos especifico da caixa, busca o E1_IDCNAB pelo nosso numero
				_wnnro = '14' + _aValores [4]
				
				_sQuery := " "
	    		_sQuery += " SELECT E1_IDCNAB"
	  			_sQuery += "   FROM SE1010"
	 			_sQuery += "  WHERE E1_FILIAL = '01'"
	   			_sQuery += "    AND E1_PORTADO = '104'"
	   			_sQuery += "    AND E1_EMISSAO > '20180501'"
	   			_sQuery += "    AND E1_NUMBCO LIKE '%"+ _wnnro + "%'"  // tem que ser com like pq falta um digito no final ainda em alguns casos
	   			_awnnro := U_Qry2Array(_sQuery)
				if len(_awnnro) = 1
					cNumTit = _awnnro[1,1]				
				endif
			else 
				if xFilial("SE1") = '01' 
					cNumTit = fBuscaCpo ("SE1", 1, xfilial ("SE1") + _sTitulo, "E1_IDCNAB")
				endif					
 			endif 
		endif
		
    	if cBanco == '422' .or. cBanco == '748' .or. cBanco == '399' .or. cBanco == '033' .or. cBanco == '237' .or. cBanco == '341' 
			if xFilial("SE1") = '01'
				cNumTit = fBuscaCpo ("SE1", 1, xfilial ("SE1") + _sTitulo, "E1_IDCNAB")
			endif	
		endif
		
		if cBanco == '001'
			if xFilial("SE1") = '01'
				cNumTit = fBuscaCpo ("SE1", 1, xfilial ("SE1") + _sTitulo, "E1_IDCNAB")
			endif
			if xFilial("SE1") = '09' .or. xFilial("SE1") = '03' .or. xFilial("SE1") = '07' .or. xFilial("SE1") = '16'
				// verifica se veio no arquivo o  IDCNAB
				_widcnab = fBuscaCpo ("SE1", 16, xfilial ("SE1") + cNumTit, "E1_IDCNAB")
				if _widcnab != cNumTit 
					// se nao veio no arquivo o IDCNAB busca o IDCNAB pelo numero do titulo
				cNumTit = fBuscaCpo ("SE1", 1, xfilial ("SE1") + _sTitulo, "E1_IDCNAB")
			    endif
			endif
		endif	
		
		if cBanco == '041'
			if xFilial("SE1") = '01' .or. xFilial("SE1") = '13' .or. xFilial("SE1") = '10' .or. xFilial("SE1") = '08'
		    	cNumTit = fBuscaCpo ("SE1", 1, xfilial ("SE1") + _sTitulo, "E1_IDCNAB")
			endif	
		endif
			
		// n�o eh relatorio - eh processamento do retorno
		if ! _l650
		   // Armazena o Codigo do Sacado na Cooperativa Cedente ou seja, codigo do cliente no Sicredi
	    	DbSelectArea("SE1")
			DbSetOrder(1)
			DbSeek(xFilial("SE1")+_aValores[01])
			If Found()
				If cBanco == "748"  // Banco Sicredi
					DbSelectArea("SA1")
					DbSetOrder(1)
					DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
					If Found()
						RecLock("SA1",.F.)
						SA1->A1_SACSICR := SubStr(cLinhaInt,15,5)
						MsUnLock()
					Endif
				Endif
			Endif
		endif
		
		// ACOES ESPECIFICAS se BANCO DO BRASIL
		if cBanco == "001"
		    if (alltrim (_aValores [14]) == "98" .or. alltrim (_aValores [14]) == "23" .or. alltrim (_aValores [14]) == "12")
		    	if  _aValores [10] > 0
		           nDespes := nDespes + _aValores [10]
				endif
				if  _aValores [11] > 0
					nDespes := nDespes + _aValores [11]
		        endif
		        if  _aValores [12] > 0
					nDespes := nDespes + _aValores [12]
		        endif
	        endif    
			if alltrim (_aValores [14]) == "06" .and. nDescont > 0
			    // Zera 'descontos' quando baixa normal - controle de R A P E L
	           nDescont = 0
	           // n�o eh relatorio - eh processamento do retorno
	           if ! _l650
	              // Grava evento no sistema
	               _oEvento := ClsEvent():new ()
	               _oEvento:CodEven   = "SE1001"
	               _oEvento:Texto     = "Descontos ($ " + alltrim (cvaltochar (_aValores [6])) + ") zerados no retorno CNAB banco " + cBanco
	               _oEvento:NFSaida   = substr (_aValores [1], 4, 6)
	               _oEvento:SerieSaid = substr (_aValores [1], 1, 3)
	               _oEvento:Grava ()
	           endif
	    	endif
		endif                                                                       
		
		// ACOES ESPECIFICAS se BANRISUL
	    if cBanco == "041" 
	       // Considerar juros no total recebido
	       if nJuros > 0 
	           nValrec := nValrec +  nJuros
	       end if
	       // Zera 'descontos' quando baixa normal - controle de R A P E L
	       if alltrim (_aValores [14]) == "06" .or. alltrim (_aValores [14]) == "30" 
	           if nDescont > 0
	              nDescont = 0
	              // n�o eh relatorio - eh processamento do retorno
	              if ! _l650
	                 // Grava evento no sistema
	                 _oEvento := ClsEvent():new ()
	                 _oEvento:CodEven   = "SE1001"
	                 _oEvento:Texto     = "Descontos ($ " + alltrim (cvaltochar (_aValores [6])) + ") zerados no retorno CNAB banco " + cBanco
	                 _oEvento:NFSaida   = substr (_aValores [1], 4, 6)
	                 _oEvento:SerieSaid = substr (_aValores [1], 1, 3)
	                 _oEvento:Grava ()
	              endif
	          endif
	       end if
	       if alltrim (_aValores [14]) != "15"
	            // manipula valor despesas de cobranca
	            if (_aValores [12] > 0)
	              // soma despesas de cartorio nas despesas de cobranca
	                nDespes := nDespes + _aValores [12]
	                // soma outras despesas no valor recebido
	                nValrec := nValrec + _aValores [12]
	                nValCc = 0
	            endif
	            // manipula outras despesas de cobranca
	            if _aValores [11] > 0
	                // soma outras despesas nas despesas de cobranca
	                nDespes := nDespes + _aValores [11]
	                // soma outras despesas no valor recebido
	                nValrec := nValrec + _aValores [11]
	                nValCc = 0
	            endif
	        endif            
	    endif     
	
		// PARA O SICREDI - Zera 'valor recebido' quando ocorrencia = tarifa
		if cBanco == "748" 
		   if alltrim (_aValores [14]) == "28"
	   	  	    nDespes = _aValores [08]
	   	  	    nMulta  :=0
                nValrec :=0
                nJuros  :=0
                nValCc  :=0
		   endif
		   // Se valor recebido a maior, joga diferenca na coluna de juros
	       if alltrim (_aValores [14]) == "06"
		        _nValOri = fBuscaCpo ("SE1", 31, xfilial ("SE1") + _aValores [4], "E1_VALOR")
		        
	            //nJuros = nValRec - _nValOri
	            if _nValOri > nValRec
	           		nDescont = _nValOri - nValRec
	            endif
	           
	            if _nValOri < nValRec
	           		nJuros = nValRec - _nValOri 
			    endif
		   endif
		endif
    
	    // PARA O SANTANDER
		if cBanco == "033" .or. cBanco == "353"
			if alltrim (_aValores [14]) == "24"
				// manipula valor de multas
		    	if nMulta > 0
		           // n�o sei pq o santander manda na coluna de multas as custas de cartorio
		           nDespes = nDespes + nMulta
		           nMulta  = 0           
		        endif
			endif	        
	    endif
	    
	    // PARA O BRADESCO
		if cBanco == "237"
			if alltrim (_aValores [14]) == "23" .or. alltrim (_aValores [14]) == "28" 
				// manipula valor de multas
		    	if nMulta > 0
		           // n�o sei pq o santander manda na coluna de multas as custas de cartorio
		           nDespes = nDespes + nMulta
		           nMulta  = 0           
		        endif
			endif	        
	    endif
    
	    // PARA O SAFRA - Zera 'valor recebido' quando ocorrencia = tarifa
		if cBanco == "422" 
	    	if alltrim (_aValores [14]) == "06" .and. nDescont > 0
			    // Zera 'descontos' quando baixa normal - controle de R A P E L 
	           nDescont = 0
	           // n�o eh relatorio - eh processamento do retorno
	           if ! _l650
	              // Grava evento no sistema
	               _oEvento := ClsEvent():new ()
	               _oEvento:CodEven   = "SE1001"
	               _oEvento:Texto     = "Descontos ($ " + alltrim (cvaltochar (_aValores [6])) + ") zerados no retorno CNAB banco " + cBanco
	               _oEvento:NFSaida   = substr (_aValores [1], 4, 6)
	               _oEvento:SerieSaid = substr (_aValores [1], 1, 3)
	               _oEvento:Grava ()
	           endif
	    	endif
		endif
		
		// PARA O ITAU - zera o valor de juros quando ocorrencia de confirma��o de entrada
		if cBanco == "341"
		
			if alltrim (_aValores [14]) == "02" .and. nJuros > 0
				nJuros = 0
			endif
			
			if alltrim (_aValores [14]) = "06" // liquida��o normal
				// o valor recebido vem deduzindo o valor das despesas de cobran�a
	            if (_aValores [5] > 0)
	              	// soma o valor das despesas no valor recebido
	                nValrec := nValrec + _aValores [5]
	            endif
	            if  nDescont > 0
			   	    // Zera 'descontos' quando baixa normal - controle de R A P E L 
	           		nDescont = 0
				endif	           		
	        endif
	        
	        if alltrim (_aValores [14]) = "08" // liquida��o emc artorio
				// o valor recebido vem deduzindo o valor das despesas de cartorio
	            if (_aValores [5] > 0)
	              	// soma o valor das despesas no valor recebido
	                nValrec := nValrec + _aValores [5]
	            endif
	        endif
	        
	        if alltrim (_aValores [14]) = "09" // baixa de titulo
				// o valor da despesa esta vindo no valor recebido
	            if (_aValores [5] > 0)
	              	// soma o valor das despesas no valor recebido
	              	if nValrec > 0
	                	nValrec := nValrec - _aValores [5]
					endif	                	
	            endif
	        endif	            
	       
		endif
		
		RestArea(_aAreaSE1)
		RestArea(_aAreaSA1)
	
	endif		
	
	RestArea(_aArea)
		
Return(_lRet)