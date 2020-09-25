// Programa:   AL_AJSPED                                                                   
// Autor:      Leandro Perondi
// Data:       13/05/2013
// Descricao:  Ajustar arquivo do SPED PIS/COFINS, incluindo registros de créditos antigos com utilização 
//			   de seus saldos para abater valores
//
// Observações:
// Este programa possui algumas particularidades. Caso seja ajustado o arquivo SPED de algum
// mês e, ao validar no programa da SEFAZ, seja verificado algum erro, será preciso voltar as
// tabelas ZZW, ZZY e ZZV do mês anterior e voltar o parâmetro "AL_MESSPED" para o mês anterior
// também, antes de ajustar o arquivo novamente neste programa. Se isso não for feito, o 
// programa não utilizará os saldos corretamente, sendo assim os registros irão inconsistentes
// para o arquivo ajustado. É recomendável realizar o backup das tabelas ZZW, ZZY e ZZV após
// cada mês ter seu arquivo ajustado e validado no programa da SEFAZ.
//
// Historico de alteracoes:
// 14/08/2020 - Cláudia - Retirado o parametro AL_MESSPED de loop, conforme solicitação versao 25. GPLI: 7339
//
// ----------------------------------------------------------------------------------------------------------
#include "protheus.ch"

User Function AL_AJSPED()

	cLinha  := ""
	aDados  := {}
	cArq := ""
	
	Static oDlg
	Static oButton1 			// ...
	Static oButton2 			// Ajusta
	Static oButton3 			// Fechar
	Static oGet1
	Static cArq := space(100)
	Static oGet2
	Static dGet2 := Date()
	Static oSay1 				// Selecione o arquivo texto do SPED a ser ajustado e a data de apuração:
	Static oSay2 				// Caminho:
	Static oSay3 				// Data:

  DEFINE MSDIALOG oDlg TITLE "Importar Arquivo SPED (.TXT)" FROM 000, 000  TO 200, 400 COLORS 0, 16777215 PIXEL

    @ 010, 007 SAY oSay1 PROMPT "Selecione o arquivo texto do SPED a ser ajustado e a data de apuração:" SIZE 182, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 033, 007 SAY oSay2 PROMPT "Caminho:" SIZE 028, 009 OF oDlg COLORS 0, 16777215 PIXEL
    @ 052, 008 SAY oSay3 PROMPT "Data:" SIZE 021, 009 OF oDlg COLORS 0, 16777215 PIXEL
    @ 032, 036 MSGET oGet1 VAR cArq SIZE 121, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 032, 164 BUTTON oButton1 PROMPT "..." SIZE 022, 010 OF oDlg PIXEL Action (diretorio())
    @ 073, 038 BUTTON oButton2 PROMPT "Ajusta" SIZE 047, 015 OF oDlg PIXEL Action (U_AjustaSPED(cArq,dGet2))
    @ 073, 114 BUTTON oButton3 PROMPT "Fechar" SIZE 047, 015 OF oDlg PIXEL Action (oDlg:End())
    @ 052, 036 MSGET oGet2 VAR dGet2 SIZE 056, 010 OF oDlg PICTURE "@D 99/99/9999" COLORS 0, 16777215 PIXEL
  ACTIVATE MSDIALOG oDlg CENTERED

Return
//
// --------------------------------------------------------------------------------------------
// função para gravar o local e arquivo selecionados na variável que será usada no AjustaSPED()
Static Function diretorio()
	cArq := cGetFile('.TXT|*.TXT','Arquivos (.TXT)',1,,.T.,GETF_LOCALHARD + GETF_NETWORKDRIVE)
Return
//
// --------------------------------------------------------------------------------------------
// função para ajustar o arquivo do SPED em relação aos registros 1100 e 1500
User Function AjustaSPED(cArq,cData)
	local _x := 0
	local i	 := 0
	local _al_messped := getmv("AL_MESSPED")
	
	If !File(cArq)
		MsgStop("O arquivo '" + cArq + "' não foi encontrado. O ajuste não será realizado !","ATENCAO")
		Return
	EndIf
	
	// Remove registros M220
	_RemovM220 () 
	
	_messped  	:= month(cData)
	_anosped  	:= year(cData)
	
	// 20130717 - antes de começar qualquer coisa, copia os registros da CCW para a ZZW e da CCY para a ZZY
	dbselectarea("CCW")
	dbgotop()
	while !eof() .and. CCW->CCW_PERIOD <= alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))        
		dbselectarea("ZZW")
		dbsetorder(3)
		dbseek(xFilial("ZZW")+CCW->CCW_ANO+CCW->CCW_MES)
		// se encontrar registro, só atualiza valor de crédito total e disponível
		if found()
			reclock("ZZW",.F.)
			Replace ZZW->ZZW_TOTCRD	With CCW->CCW_TOTCRD
			Replace ZZW->ZZW_CRDISP	With CCW->CCW_TOTCRD - ZZW->ZZW_CREDUT
			msunlock()
		else
			reclock("ZZW",.T.)
			Replace ZZW->ZZW_PERIOD	With CCW->CCW_PERIOD
			Replace ZZW->ZZW_COD	With CCW->CCW_COD
			Replace ZZW->ZZW_TOTCRD	With CCW->CCW_TOTCRD
			//Replace ZZW->ZZW_CREDUT	With CCW->CCW_CREDUT
			Replace ZZW->ZZW_CREDUT	With 0
			//Replace ZZW->ZZW_CRDISP	With CCW->CCW_CRDISP
			Replace ZZW->ZZW_CRDISP	With CCW->CCW_TOTCRD // cria registro com todo o crédito, pois não foi utilizado nada ainda
			Replace ZZW->ZZW_VACNPJ	With '88612486000160'
			Replace ZZW->ZZW_ANO	With CCW->CCW_ANO
			Replace ZZW->ZZW_MES	With CCW->CCW_MES
			Replace ZZW->ZZW_ORIGEM With '01'
			msunlock()
		endif
		dbselectarea("ZZW")
		dbclosearea()
		
		// zera utilizados da CCY e totaliza saldo disponível
		reclock("CCW",.F.)
		Replace CCW->CCW_CREDUT With 0
		Replace CCW->CCW_CRDISP With CCW->CCW_TOTCRD
		Replace CCW->CCW_UTIANT With 0   
		msunlock()
		                 
		dbselectarea("CCW")
		dbskip()
	enddo 
	
	dbselectarea("CCY")
	dbgotop()
	while !eof() .and. CCY->CCY_PERIOD <= alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))       
		dbselectarea("ZZY")
		dbsetorder(3)
		dbseek(xFilial("ZZY")+CCY->CCY_ANO+CCY->CCY_MES)
		// se encontrar registro, só atualiza valor de crédito total e disponível
		if found()
			reclock("ZZY",.F.)
			Replace ZZY->ZZY_TOTCRD	With CCY->CCY_TOTCRD
			Replace ZZY->ZZY_CRDISP	With CCY->CCY_TOTCRD - ZZY->ZZY_CREDUT
			msunlock()
		else
			reclock("ZZY",.T.)
			Replace ZZY->ZZY_PERIOD	With CCY->CCY_PERIOD
			Replace ZZY->ZZY_COD	With CCY->CCY_COD
			Replace ZZY->ZZY_TOTCRD	With CCY->CCY_TOTCRD 
			//Replace ZZY->ZZY_CREDUT	With CCY->CCY_CREDUT
			Replace ZZY->ZZY_CREDUT	With 0
			//Replace ZZY->ZZY_CRDISP	With CCY->CCY_CRDISP
			Replace ZZY->ZZY_CRDISP	With CCY->CCY_TOTCRD // cria registro com todo o crédito, pois não foi utilizado nada ainda
			Replace ZZY->ZZY_VACNPJ	With '88612486000160'
			Replace ZZY->ZZY_ANO	With CCY->CCY_ANO
			Replace ZZY->ZZY_MES	With CCY->CCY_MES
			Replace ZZY->ZZY_ORIGEM With '01'
			msunlock()
		endif	
		dbselectarea("ZZY")
		dbclosearea()
		
		// zera utilizados da CCY e totaliza saldo disponível
		reclock("CCY",.F.)
		Replace CCY->CCY_CREDUT With 0
		Replace CCY->CCY_CRDISP With CCY->CCY_TOTCRD 
		Replace CCY->CCY_UTIANT With 0  
		msunlock()
		                 
		dbselectarea("CCY")
		dbskip()
	enddo
	
	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()
	While !FT_FEOF()
		
		IncProc("Lendo arquivo texto SPED...")
		
		cLinha := FT_FREADLN()
		
		// separa em cada posição do array a informação que está entre as barras
		AADD(aDados,Separa(cLinha,"|",.T.))
		
		FT_FSKIP()
	EndDo
	
	// cria arquivo texto
	nHdl    := 0
	_sArqLog := cArq + "_2.TXT"
	nHdl = fCreate(_sArqLog)
	
	Begin Transaction
	
	_messped  	:= month(cData)
	_anosped  	:= year(cData)
	_totalpis 	:= 0
	_totalcof 	:= 0
	_totlin	:= 0
	_totlpc	:= 1
	_utilanter := 0
	_valutil := 0
	
	For i:=1 to Len(aDados) // passa por todas linhas
	
		/*
		coluna: 1    2     3   4      5           6     7    8   9      10    11 12  13    14 15 16 17 18   19
		PIS		  	|1100|052013|02|09611753000108|102|913,27 |0|913,27 |113,14|  |  |800,13 |0 |0 |0 |0 |0 |800,13 |
		COFINS	  	|1500|052013|01|              |101|4206,57|0|4206,57|521,14|  |  |3685,43|0 |0 |0 |0 |0 |3685,43|
		
		Ordem dos campos
		(*) possui valor
		
		01 Branco (não existe campo)
		02 Controle de Créditos Fiscais
		03 Período de Apuração do Crédito
		04 Origem do Crédito (01 Para Crédito decorrente de operações próprias; 02 Para Crédito transferido por pessoa jurídica sucedida.)
		05 CNPJ do Cedente do Crédito
		06 Tipo do Crédito
		07 *Valor do Crédito Apurado no Período a que se refere este registro (campo 03)
		08 Valor do Crédito Extemporâneo Apurado referente ao Período a que se refere este registro (campo 03)
		09 *Valor Total do Crédito Apurado
		10 *Valor do Crédito Utilizado Mediante Desconto, em Período(s) Anterior(es)
		11 Valor do Crédito Utilizado Mediante Pedido de Ressarcimento, em Período(s) Anterior(es)
		12 Valor do Crédito Utilizado Mediante Declaração de Compensação Intermediária, em Período(s) Anterior(es)
		13 *Saldo do Crédito Disponível para utilização neste Período de Escrituração
		14 Valor do crédito descontado neste período de escrituração
		15 Valor do crédito objeto de Pedido de Ressarcimento neste Período de Escrituração
		16 Valor do crédito utilizado mediante declaração de Compensação Intermediária neste Período de Escrituração
		17 Valor do crédito transferido em evento de cisão, fusão ou incorporação
		18 Valor do crédito utilizado por outras formas
		19 *Saldo de Créditos a Utilizar em Período de Apuração Futuro
		*/
		
		cLin := ''
		
		// começa da posição [2] pois a função SEPARA considera do início da linha até o primeiro '|' como uma coluna
		
		if aDados[i][2] == 'M100' // se for registro de crédito do PIS do mês de apuração
		
			for _x = 2 to len(aDados[i]) // passa por todas colunas da linha (i) em questão
			
				if _x == 2 // primeira coluna
					cLin += "|"+alltrim(aDados[i][_x])+"|"
				elseif _x == len(aDados[i]) // ultima coluna
					cLin += alltrim(aDados[i][_x])+ chr(13) + chr(10)
				else // demais colunas
					cLin += alltrim(aDados[i][_x])+"|"
				endif
				
			next _x 
			
			_totlin += 1
			
		elseif aDados[i][2] == 'M200' // se for registro de débito do PIS 
		
			//cLin := '|M200|' + aDados[i][3] + '|' + aDados[i][4] + '|0|0|0|0|0|0|0|0|0|0|'  + chr(13) + chr(10)
		
			// |M200|4717,31|4717,31|0|0|0|0|0|0|0|0|0|0|
			_totalpis := val(cvaltochar(val(aDados[i][3]))+"."+right(aDados[i][3],2))
			
			for _x = 2 to len(aDados[i]) // passa por todas colunas da linha (i) em questão
			
				if _x == 2 // primeira coluna
					cLin += "|"+alltrim(aDados[i][_x])+"|"
				elseif _x == 3 // segunda coluna
					cLin += alltrim(aDados[i][3])+"|"
				elseif _x == 4 // terceira coluna
					cLin += "0|" 
				elseif _x == 5 // quarta coluna
					cLin += alltrim(aDados[i][3])+"|"
				elseif _x == len(aDados[i]) // ultima coluna
					cLin += alltrim(aDados[i][_x])+ chr(13) + chr(10)
				else // demais colunas
					cLin += alltrim(aDados[i][_x])+"|"
				endif
				
			next _x 
			
			_totlin += 1
		
		elseif aDados[i][2] == 'M500' // se for registro de crédito do COFINS do mês de apuração
		
			for _x = 2 to len(aDados[i]) // passa por todas colunas da linha (i) em questão
			
				if _x == 2 // primeira coluna
					cLin += "|"+alltrim(aDados[i][_x])+"|"
				elseif _x == len(aDados[i]) // ultima coluna
					cLin += alltrim(aDados[i][_x])+ chr(13) + chr(10)
				else // demais colunas
					cLin += alltrim(aDados[i][_x])+"|"
				endif
				
			next _x 
			
			_totlin += 1
				
		elseif aDados[i][2] == 'M600' // se for registro de débito do COFINS
		
			//cLin := '|M600|' + aDados[i][3] + '|' + aDados[i][4] + '|0|0|0|0|0|0|0|0|0|0|'  + chr(13) + chr(10)
			
			// |M600|21728,21|21728,21|0|0|0|0|0|0|0|0|0|0|
			_totalcof := val(cvaltochar(val(aDados[i][3]))+"."+right(aDados[i][3],2)) 
			
			for _x = 2 to len(aDados[i]) // passa por todas colunas da linha (i) em questão
			
				if _x == 2 // primeira coluna
					cLin += "|"+alltrim(aDados[i][_x])+"|"
				elseif _x == 3 // segunda coluna
					cLin += alltrim(aDados[i][3])+"|"
				elseif _x == 4 // terceira coluna
					cLin += "0|"
				elseif _x == 5 // quarta coluna
					cLin += alltrim(aDados[i][3])+"|"
				elseif _x == len(aDados[i]) // ultima coluna
					cLin += alltrim(aDados[i][_x])+ chr(13) + chr(10)
				else // demais colunas
					cLin += alltrim(aDados[i][_x])+"|"
				endif
				
			next _x 
			
			_totlin += 1
			
		elseif aDados[i][2] == '1100' // se for registro do crédito do PIS (cadastrados na ZZY)		
			dbselectarea("ZZY")
			dbsetorder(3) // FILIAL + ANO + MES + ORIGEM + CNPJ
			dbgotop() 		// vai para o primeiro registro para pegar o lançamento de crédito mais antigo
	
			// leva para o arquivo do SPED todos os registros que possuem créditos
			
			while !EOF()
	
				// se crédito já foi todo utilizado, registro não precisa ir para o arquivo SPED
				if ZZY->ZZY_CRDISP <= 0 //.and. getmv("AL_MESSPED") <> alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
					dbselectarea("ZZY")
					dbskip()
					loop	
				endif
				
				// verifica se crédito prescreveu, ou seja, é mais antigo do que 5 anos
				_datasped := stod(cvaltochar(_anosped)+right('0'+cvaltochar(_messped),2)+'01')
				_datacred := stod(ZZY->ZZY_ANO+ZZY->ZZY_MES+'01')
				_datapres := YearSub(_datasped,5) // pega a data do SPED, e diminui 5 anos, para ver se prescreveu
				
				// se data do crédito for menos do que a data do SPED menos 5 anos, pula registro
				if _datacred < _datapres
				
					// atualiza os saldos da tabela ZZY para que estes crédito não seja aproveitado mais
					// crédito disponível fica zerado, pois foi prescrito
					reclock("ZZY",.F.)
					ZZY->ZZY_CRDISP := 0
					ZZY->ZZY_CREDUT := ZZY->ZZY_TOTCRD
					msunlock()
					
					dbselectarea("ZZY")
					dbskip()
					loop
				endif  
				
				// atualiza os saldos de cada lançamento antes de jogar no arquivo, conforme vai abatendo os valores
				if _totalpis > 0
					
					// verifica se, ao utilizar o saldo disponível, crédito do PIS fica totalmente abatido ou não
					_aux := _totalpis - ZZY->ZZY_CRDISP
					
					if _aux >= 0 // significa que foi usado tudo que tinha de saldo e ainda tem valor positivo no PIS
						
						// valor que foi utilizado na movimentação para abater o débito
						_valutil := ZZY->ZZY_CRDISP
						
						// diminui do total do PIS o valor utilizado
						_totalpis := _totalpis - ZZY->ZZY_CRDISP
						
						// guarda o valor do crédito utilizado anteriormente, antes ed fazer a atualização dos valores
						_utilanter := ZZY->ZZY_CREDUT
						
						// só atualiza os saldos da tabela ZZY se o SPED está sendo gerado pela primeira vez para o mês em questão
						//if getmv("AL_MESSPED") < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
						if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
							// crédito disponível fica zerado, pois foi utilizado tudo
							reclock("ZZY",.F.)
							ZZY->ZZY_CRDISP := 0
							ZZY->ZZY_CREDUT := ZZY->ZZY_TOTCRD
							msunlock()
						endif
	
					else // significa que valor de crédito do PIS foi totalmente abatida e ainda sobrou valor
						
						// valor suficiente que será usado para abater totalmente o PIS, deixando-o zerado
						_difere := ZZY->ZZY_CRDISP + _aux
						
						// valor que foi utilizado na movimentação para abater o débito
						_valutil := _difere
						
						// deve zerar o valor do PIS
						_totalpis := _totalpis - _difere
						
						// guarda o valor do crédito utilizado anteriormente, antes ed fazer a atualização dos valores
						_utilanter := ZZY->ZZY_CREDUT
						
						// só atualiza os saldos da tabela ZZY se o SPED está sendo gerado pela primeira vez para o mês em questão
						if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
							// crédito disponível tem o decréscimo do valor utilizado para zerar o PIS	
							reclock("ZZY",.F.)
							ZZY->ZZY_CRDISP := ZZY->ZZY_CRDISP - _difere
							ZZY->ZZY_CREDUT := ZZY->ZZY_CREDUT + _difere
							msunlock()
						 endif
										
					endif
					
					// grava log na tabela ZZV para cada movimentação realizada
					if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
						reclock("ZZV", .T.)
						Replace ZZV_FILIAL With xFilial("ZZY") 
						Replace ZZV_TABELA With 'ZZY'
						Replace ZZV_PERIOD With alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
						Replace ZZV_CODIGO With ZZY->ZZY_COD
						Replace ZZV_CREDIT With ZZY->ZZY_TOTCRD
						Replace ZZV_UTILIZ With _utilanter
						Replace ZZV_MOVIM  With _valutil
						Replace ZZV_SALDO  With ZZY->ZZY_CRDISP
						Replace ZZV_CNPJ   With ZZY->ZZY_VACNPJ
						Replace ZZV_ANO    With ZZY->ZZY_ANO
						Replace ZZV_MES    With ZZY->ZZY_MES
						Replace ZZV_ORIGEM With ZZY->ZZY_ORIGEM
						msunlock()
					endif
					
				endif
			
				dbselectarea("ZZY")
				
				// inclui no arquivo texto o registro atualizado com os saldos utilizados
				cLin += "|"+'1100'														+ "|"		// '1100'
				cLin += alltrim(ZZY->ZZY_MES)+alltrim(ZZY->ZZY_ANO)					+ "|" 		// Período
				cLin += alltrim(ZZY->ZZY_ORIGEM) 										+ "|" 		// Origem ('01' ou '02')
				cLin += alltrim(ZZY->ZZY_VACNPJ) 										+ "|" 		// CNPJ
				cLin += alltrim(ZZY->ZZY_COD) 											+ "|" 		// tipo ('101' ou '102')
				cLin += alltrim(transform(ZZY->ZZY_TOTCRD, "@E 999999999.99")) 	+ "|"			
				cLin += '0,00'															+ "|"				
				cLin += alltrim(transform(ZZY->ZZY_TOTCRD, "@E 999999999.99")) 	+ "|"
				cLin += alltrim(transform(_utilanter, "@E 999999999.99"))		 	+ "|"
				cLin += '0,00'															+ "|"		
				cLin += '0,00'															+ "|"
				cLin += alltrim(transform(ZZY->ZZY_TOTCRD - _utilanter, "@E 999999999.99")) 	+ "|"
				cLin += alltrim(transform(_valutil, "@E 999999999.99"))		+ "|"
				cLin += '0,00'															+ "|"		
				cLin += '0,00'															+ "|"
				cLin += '0,00'															+ "|"
				cLin += '0,00'															+ "|"
				cLin += alltrim(transform(ZZY->ZZY_TOTCRD - (_utilanter + _valutil), "@E 999999999.99")) 	+ "|" + chr(13) + chr(10)
				
				// somatório de linhas para o final do arquivo SPED
				_totlin += 1
				_totlpc += 1
				
				dbselectarea("ZZY")
				dbskip() 
				
				_utilanter := 0
				_valutil := 0
			enddo

		elseif aDados[i][2] == '1500' // se for registro do crédito do COFINS
			
			dbselectarea("ZZW")
			dbsetorder(3) // FILIAL + ANO + MES + ORIGEM + CNPJ
			dbgotop() 		// vai para o primeiro registro para pegar o lançamento de crédito mais antigo
			
			// leva para o arquivo do SPED, todos os registros que possuem créditos
			while !EOF()
				
				// se crédito já foi todo utilizado, registro não precisa ir para o arquivo SPED
				if ZZW->ZZW_CRDISP <= 0 //.and. getmv("AL_MESSPED") <> alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
					dbselectarea("ZZW")
					dbskip()
					loop	
				endif
				
				// verifica se crédito prescreveu, ou seja, é mais antigo do que 5 anos
				_datasped := stod(cvaltochar(_anosped)+right('0'+cvaltochar(_messped),2)+'01')
				_datacred := stod(ZZW->ZZW_ANO+ZZW->ZZW_MES+'01')
				_datapres := YearSub(_datasped,5) // pega a data do SPED, e diminui 5 anos, para ver se prescreveu
				
				// se data do crédito for menos do que a data do SPED menos 5 anos, pula registro
				if _datacred < _datapres
				
					// atualiza os saldos da tabela ZZY para que estes crédito não seja aproveitado mais
					//if getmv("AL_MESSPED") <> alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
						// crédito disponível fica zerado, pois foi prescrito
						reclock("ZZY",.F.)
						ZZW->ZZW_CRDISP := 0
						ZZW->ZZW_CREDUT := ZZW->ZZW_TOTCRD
						msunlock()
				   	//endif
					
					dbselectarea("ZZW")
					dbskip()
					loop
				endif 
				
				// atualiza os saldos de cada lançamento antes de jogar no arquivo, conforme vai abatendo os valores
				if _totalcof > 0
					
					// verifica se, ao utilizar o saldo disponível, crédito do PIS fica totalmente abatido ou não
					_aux := _totalcof - ZZW->ZZW_CRDISP
					
					if _aux >= 0 // significa que foi usado tudo que tinha de saldo e ainda tem valor positivo no PIS
					
						// valor que foi utilizado na movimentação para abater o débito
						_valutil := ZZW->ZZW_CRDISP
						
						// diminui do total do PIS o valor utilizado
						_totalcof := _totalcof - ZZW->ZZW_CRDISP
						
						// guarda o valor do crédito utilizado anteriormente, antes ed fazer a atualização dos valores
						_utilanter := ZZW->ZZW_CREDUT
						
						// só atualiza os saldos da tabela ZZW se o SPED está sendo gerado pela primeira vez para o mês em questão
						if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6)) 
							// crédito disponível fica zerado, pois foi utilizado tudo
							reclock("ZZW",.F.)
							ZZW->ZZW_CRDISP := 0
							ZZW->ZZW_CREDUT := ZZW->ZZW_TOTCRD
							msunlock()
						endif
						
					else  // significa que valor de crédito do PIS foi totalmente abatida e ainda sobrou valor
						
						// valor suficiente que será usado para abater totalmente o PIS, deixando-o zerado
						_difere := ZZW->ZZW_CRDISP + _aux
						
						// valor que foi utilizado na movimentação para abater o débito
						_valutil := _difere 
						
						// deve zerar o valor do COFINS
						_totalcof := _totalcof - _difere   
						
						// guarda o valor do crédito utilizado anteriormente, antes ed fazer a atualização dos valores
						_utilanter := ZZW->ZZW_CREDUT
						
						// só atualiza os saldos da tabela ZZW se o SPED está sendo gerado pela primeira vez para o mês em questão
						if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
							// crédito disponível tem o decréscimo do valor utilizado para zerar o PIS	
							reclock("ZZW",.F.)
							ZZW->ZZW_CRDISP := ZZW->ZZW_CRDISP - _difere
							ZZW->ZZW_CREDUT := ZZW->ZZW_CREDUT + _difere
							msunlock()
						endif
						
					endif
					
					// grava log na tabela ZZV para cada movimentação realizada
					if _al_messped < alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
					
						reclock("ZZV", .T.)
						Replace ZZV_FILIAL With xFilial("ZZW") 
						Replace ZZV_TABELA With 'ZZW'
						Replace ZZV_PERIOD With alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6))
						Replace ZZV_CODIGO With ZZW->ZZW_COD
						Replace ZZV_CREDIT With ZZW->ZZW_TOTCRD
						Replace ZZV_UTILIZ With _utilanter
						Replace ZZV_MOVIM  With _valutil
						Replace ZZV_SALDO  With ZZW->ZZW_CRDISP
						Replace ZZV_CNPJ   With ZZW->ZZW_VACNPJ
						Replace ZZV_ANO    With ZZW->ZZW_ANO
						Replace ZZV_MES    With ZZW->ZZW_MES
						Replace ZZV_ORIGEM With ZZW->ZZW_ORIGEM
						msunlock()
					
					endif
					
				endif
				
				dbselectarea("ZZW")
				
				// inclui no arquivo texto o registro atualizado com os saldos utilizados
				cLin += "|"+'1500'														+ "|"		// '1500'
				cLin += alltrim(ZZW->ZZW_MES)+alltrim(ZZW->ZZW_ANO)					+ "|" 		// Período
				cLin += alltrim(ZZW->ZZW_ORIGEM) 										+ "|" 		// Origem ('01' ou '02')
				cLin += alltrim(ZZW->ZZW_VACNPJ) 										+ "|" 		// CNPJ
				cLin += alltrim(ZZW->ZZW_COD) 											+ "|" 		// tipo ('101' ou '102')
				cLin += alltrim(transform(ZZW->ZZW_TOTCRD, "@E 999999999.99"))		+ "|"			
				cLin += '0,00'															+ "|"				
				cLin += alltrim(transform(ZZW->ZZW_TOTCRD, "@E 999999999.99")) 	+ "|"
				cLin += alltrim(transform(_utilanter, "@E 999999999.99"))			+ "|"
				cLin += '0,00'															+ "|"		
				cLin += '0,00'															+ "|"
				cLin += alltrim(transform(ZZW->ZZW_TOTCRD - _utilanter, "@E 999999999.99")) 	+ "|"
				cLin += alltrim(transform(_valutil, "@E 999999999.99"))				+ "|"
				cLin += '0,00'															+ "|"		
				cLin += '0,00'															+ "|"
				cLin += '0,00'															+ "|"
				cLin += '0,00'															+ "|"
				cLin += alltrim(transform(ZZW->ZZW_TOTCRD - (_utilanter + _valutil), "@E 999999999.99"))		+ "|" + chr(13) + chr(10)
				
				// somatório de linhas para o final do arquivo SPED
				_totlin += 1
				_totlpc += 1
				
				dbselectarea("ZZW")
				dbskip()
				
				_utilanter := 0
				_valutil := 0
				
			enddo
			
		elseif aDados[i][2] == '9999' // último registro ... contém o total de linhas
		
			_totlin += 1
			cLin := "|9999|"+cvaltochar(_totlin)+"|" + chr(13) + chr(10)
		
		elseif aDados[i][2] == '1990' // fechamento do bloco 1 ... número de linhas de pis e cofins
		
			_totlin += 1
			_totlpc += 1
			cLin := "|1990|"+cvaltochar(_totlpc)+"|" + chr(13) + chr(10)	 
			
		else // demais registros (tem essa parte para gerar o arquivo de novo com todas informações, igual ao original)
		
			for _x = 2 to len(aDados[i]) // passa por todas colunas da linha (i) em questão
			
				if _x == 2 // primeira coluna
					cLin := "|"+alltrim(aDados[i][_x])+"|"
				elseif _x == len(aDados[i]) // ultima coluna
					cLin += alltrim(aDados[i][_x])+ chr(13) + chr(10)
				else // demais colunas
					cLin += alltrim(aDados[i][_x])+"|"
				endif
	
			next _x 
			_totlin += 1
			
		endif
		
		fwrite(nHdl,cLin,Len(cLin))
		cLin := ""  
		
	Next i
	
	End Transaction
	
	fClose(nHdl) // fecha arquivo texto
	FT_FUSE()
	
	// atualiza o parâmetro com o último mês e ano em que foi rodado o ajuste, para não duplicar registros na ZZV e não atualizar de novo os mesmos saldos
	PUTMV("AL_MESSPED", alltrim(right("0"+cvaltochar(_messped)+cvaltochar(_anosped),6)))
	
	ApMsgInfo("Alteração do arquivo Sped finalizada. Verifique se informações ficaram corretas !","SUCESSO")

Return
//
// --------------------------------------------------------------------------------------------
// Remove registros M220 do arquivo.
static function _RemovM220 ()
	// Falta fazer...
return
