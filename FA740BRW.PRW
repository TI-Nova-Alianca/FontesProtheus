// Programa...: FA740BRW
// Autor......: Catia Cardoso
// Data.......: 28/06/2017
// Descricao..: Ponto de Entrada - Funções a Receber - Criando mais opcoes

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada na tela de funcoes contas a receber (FINA740)
// #PalavasChave      #atalhos #botoes_adicionais #facilitadores
// #TabelasPrincipais #SE1
// #Modulos           #FIN

// Historico de alteracoes:
// 30/01/2018 - Catia   - criada a opcao de base de rape 3 = total nf - dt
// 25/09/2018 - Catia   - impressao de boleto a partir da tela de funcoes do contas a receber
// 28/09/2018 - Catia   - impressão da carta de anuencia
// 03/10/2018 - Catia   - ajustado a carta de anuencia pq nao saia as ultimas linhas
// 15/02/2019 - Andre   - adicionado CNPJ na carta de anuencia
// 15/03/2019 - Catia   - Alterado para que seja possivel reimprimir boletos tambem dessa tela
// 08/04/2019 - Andre   - Desconsiderar sub contas = '100'.
// 07/05/2019 - Catia   - Impressao de boletos estava imprimindo mais de uma vez, devido ao um produto cartesiano 
//						  no array _atitulos que nao estava desconsiderando a subconta 100
// 01/04/2020 - Claudia - Alterada a chamada do arquivo de trabalho _sAliasQ2 que nao existia mais para o array aTitulos. GLPI 7752
// 24/09/2020 - Cláudia - Criada a rotina "Baixa Rapel" - VA_040BRAP. GLPI: 8367
// 10/11/2020 - Claudia - Incluido CNPJ formatado com mascara no corpo e rodapé da impressão do relatorio de anuencia. GLPI: 8789
// 22/01/2021 - Cláudia - Incluida validação verificando se o valor já movimentado + rapel é igual ou menor que o valor do título. GLPI: 9066
// 01/09/2022 - Robert  - Trocado teste [SE1->E1_NUMBOR!=''] por [!empty(SE1->E1_NUMBOR)]
// 02/09/2022 - Robert  - Melhoradas algumas mensagens para o usuario (GLPI 12543)
//

// ---------------------------------------------------------------------------------------------------------------------------------
User Function FA740BRW()
	Local aBotao := {}

	aAdd(aBotao, {"Rapel"				, "U_VA_040RAP()" ,   0,  2})
	aAdd(aBotao, {"Baixa Rapel"			, "U_VA_040BRAP()",   0,  2})
	aAdd(aBotao, {"Boleto"				, "U_VA_040BOL()" ,   0,  2})
	aAdd(aBotao, {"Carta Anuência"		, "U_VA_040CART()",   0,  2})
	aAdd(aBotao, {"Alt.Bandeira Cartão"	, "U_VA_040BAND()",   0,  2})
	aAdd(aBotao, {"Eventos"	            , "U_VA_040EVEN(se1->e1_filial,se1->e1_num,se1->e1_prefixo,se1->e1_cliente,se1->e1_loja)",   0,  2})

Return(aBotao)
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Altera bandeira do cartão
user function VA_040BAND()

	local _aAreaAnt  := U_ML_SRArea ()
	_lContinua = .T.
	
	// testar se eh cartao para alterar a bandeira
	if se1 -> e1_tipo <> 'CC' .and.  se1 -> e1_tipo <> 'CD'
		u_help ("Titulo não pode ser alterado, não refere-se a venda com cartão")
		return
	endif
	// -- testa se o titulo ja esta pago
	if se1 -> e1_saldo = 0
		u_help ("Titulo não pode ser alterado pois ja esta quitado.")
		return
	endif
	
	// -- solicita nova bandeira
	if U_ZZUVL ('043', __cUserId, .T.)
	
		do while _lContinua
			_sBandeira = U_Get ("Informe nova Bandeira: ", "C", 6, "", "SA1C", se1 -> e1_cliente, .F., '.t.')
			if _sBandeira = NIL
				_lContinua = .F.
				exit
			endif
			// verifica se eh uma administradora de cartao
			if  val(_sBandeira) > 99 .and. val(_sBandeira) < 450
				exit
			else 	
				u_help ("Cliente não é uma administradora de cartão de credito")
				loop
			endif
		enddo
		
		// verificar se alterou de db pra cr
		if _lContinua
			_wdebcred = fBuscaCpo ('SA1', 1, xfilial('SA1') + _sBandeira + '01', "A1_NOME")
			if 'CREDITO' $ _wdebcred
				_wtipo = 'CC'
			elseif 'DEBITO' $ _wdebcred
				_wtipo = 'CD'
			endif	
			
			reclock ("SE1", .F.)
				se1 -> e1_cliente = _sBandeira
				se1 -> e1_tipo    = _wtipo
				se1 -> e1_nomcli  = fBuscaCpo ('SA1', 1, xfilial('SA1') + _sBandeira + '01', "A1_NOME")
			msunlock ()      
		
			_ntexto:= 'Alterado Bandeira de Cartao de Credito - Função do Financeiro.'          
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SE1001"
			_oEvento:Texto	   = "Alterado Cliente e Tipo do Titulo proveniente de vendas a cartao nas lojas"
			_oEvento:Filial	   = xfilial("SE1")
			_oEvento:PedVenda  = se1 -> e1_num
			_oEvento:Cliente   = se1 -> e1_cliente
			_oEvento:LojaCli   = se1 -> e1_loja
			_oEvento:Grava ()  
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	
return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Rapel
user function VA_040RAP()
	
	if SE1 -> E1_VARAPEL = 0
		u_help("Titulo não tem valor de rapel.")
		return
	endif
		
	_sQuery := " "
	_sQuery := ""
	// busca itens da nota - detalha a nota com itens e rapel por item
	_sQuery += " SELECT SD2.D2_COD 								  AS PROD_COD"
	_sQuery += " 	  , SB1.B1_DESC 							  AS PROD_DESC"
	_sQuery += "      , SB1.B1_CLINF 							  AS LIN_COD"
	_sQuery += "      , ZAZ.ZAZ_NLINF 							  AS LIN_DES"
    _sQuery += "      , SD2.D2_TOTAL 							  AS VLR_MERC"
	_sQuery += "      , SD2.D2_VALIPI 							  AS VLR_IPI"
	_sQuery += "      , SD2.D2_ICMSRET 							  AS VLR_ST"
	_sQuery += "      , SD2.D2_TOTAL+SD2.D2_VALIPI+SD2.D2_ICMSRET AS VLR_TOTAL"
	_sQuery += "      , CASE SA1.A1_VABARAP" 
	_sQuery += " 	       WHEN 0 THEN 'SEM RAPEL'"
	_sQuery += " 	       WHEN 1 THEN 'BASE NOTA'"
	_sQuery += " 	       WHEN 2 THEN 'BASE MERCADORIA'"
	_sQuery += " 	    END 									  AS RAPEL_TIPO"
	_sQuery += "     , CASE SA1.A1_VABARAP" 
	_sQuery += " 	       WHEN 0 THEN 0"
	_sQuery += " 	       WHEN 1 THEN SD2.D2_TOTAL+SD2.D2_VALIPI+SD2.D2_ICMSRET"
	_sQuery += " 	       WHEN 2 THEN SD2.D2_TOTAL"
	_sQuery += " 	    END 									  AS RAPEL_BASE"
    _sQuery += "     , SD2.D2_RAPEL                               AS RAPEL_PER"
	_sQuery += "     , SD2.D2_VRAPEL                              AS RAPEL_VALOR"
  	_sQuery += "  FROM SD2010 AS SD2"
	_sQuery += " 	INNER JOIN SB1010 AS SB1"
	_sQuery += " 		ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += " 			AND SB1.B1_COD = SD2.D2_COD)"
	_sQuery += " 	LEFT JOIN ZAZ010 AS ZAZ"
	_sQuery += " 		ON (ZAZ.D_E_L_E_T_ = ''"
	_sQuery += " 			AND ZAZ.ZAZ_CLINF = SB1.B1_CLINF)"
	_sQuery += " 	INNER JOIN SA1010 AS SA1"
	_sQuery += " 		ON (SA1.D_E_L_E_T_  = ''"
	_sQuery += " 			AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += " 			AND SA1.A1_LOJA = SD2.D2_LOJA)"
 	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SD2.D2_FILIAL  = '" + SE1 -> E1_FILIAL + "'"
    _sQuery += "   AND SD2.D2_DOC     = '" + SE1 -> E1_NUM + "'"
   	_sQuery += "   AND SD2.D2_SERIE   = '" + SE1 -> E1_PREFIXO + "'"
   	_sQuery += "   AND SD2.D2_CLIENTE = '" + SE1 -> E1_CLIENTE + "'"
   	_sQuery += "   AND SD2.D2_LOJA    = '" + SE1 -> E1_LOJA + "'"
   	// busca totais da nota
   	_sQuery += " UNION ALL"
	_sQuery += " SELECT ''         								  AS PROD_COD"
	_sQuery += " 	  , 'DADOS DA NOTA'				  			  AS PROD_DESC"
	_sQuery += "      , ''             						      AS LIN_COD"
	_sQuery += "      , ''   							          AS LIN_DES"
    _sQuery += "      , SF2.F2_VALMERC                            AS VLR_MERC"
	_sQuery += "      , SF2.F2_VALIPI 				              AS VLR_IPI"
	_sQuery += "      , SF2.F2_ICMSRET 							  AS VLR_ST"
	_sQuery += "      , SF2.F2_VALBRUT                            AS VLR_TOTAL"
	_sQuery += "      , CASE SA1.A1_VABARAP" 
	_sQuery += " 	       WHEN 0 THEN 'SEM RAPEL'"
	_sQuery += " 	       WHEN 1 THEN 'BASE NOTA'"
	_sQuery += " 	       WHEN 2 THEN 'BASE MERCADORIA'"
	_sQuery += " 	       WHEN 3 THEN 'TOTAL NF - ST'"
	_sQuery += " 	    END 									  AS RAPEL_TIPO"
	_sQuery += "     , CASE SA1.A1_VABARAP" 
	_sQuery += " 	       WHEN 0 THEN 0"
	_sQuery += " 	       WHEN 1 THEN SF2.F2_VALMERC+SF2.F2_VALIPI+SF2.F2_ICMSRET"
	_sQuery += " 	       WHEN 2 THEN SF2.F2_VALMERC"
	_sQuery += " 	       WHEN 3 THEN SF2.F2_VALMERC+SF2.F2_VALIPI"
	_sQuery += " 	    END 									  AS RAPEL_BASE"
    _sQuery += "     , 0                                          AS RAPEL_PER"
	_sQuery += "     , SF2.F2_VARAPEL                             AS RAPEL_VALOR"
	_sQuery += "  FROM SF2010 AS SF2"
	_sQuery += " 	INNER JOIN SA1010 AS SA1"
	_sQuery += " 		ON (SA1.D_E_L_E_T_  = ''"
	_sQuery += " 			AND SA1.A1_COD  = SF2.F2_CLIENTE"
	_sQuery += " 			AND SA1.A1_LOJA = SF2.F2_LOJA)"
 	_sQuery += " WHERE SF2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SF2.F2_FILIAL  = '" + SE1 -> E1_FILIAL + "'"
    _sQuery += "   AND SF2.F2_DOC     = '" + SE1 -> E1_NUM + "'"
   	_sQuery += "   AND SF2.F2_SERIE   = '" + SE1 -> E1_PREFIXO + "'"
   	_sQuery += "   AND SF2.F2_CLIENTE = '" + SE1 -> E1_CLIENTE + "'"
   	_sQuery += "   AND SF2.F2_LOJA    = '" + SE1 -> E1_LOJA + "'"
   	// busca totais da nota
   	_sQuery += " UNION ALL"
	_sQuery += " SELECT ''         								  AS PROD_COD"
	_sQuery += " 	  , 'DADOS DOS TITULOS'			  			  AS PROD_DESC"
	_sQuery += "      , SE1.E1_PARCELA 						      AS LIN_COD"
	_sQuery += "      , SE1.E1_NUM                                AS LIN_DES"
    _sQuery += "      , 0                            			  AS VLR_MERC"
	_sQuery += "      , 0 				              			  AS VLR_IPI"
	_sQuery += "      , 0 							  			  AS VLR_ST"
	_sQuery += "      , SE1.E1_VALOR                              AS VLR_TOTAL"
	_sQuery += "      , CASE SA1.A1_VABARAP" 
	_sQuery += " 	       WHEN 0 THEN 'SEM RAPEL'"
	_sQuery += " 	       WHEN 1 THEN 'BASE NOTA'"
	_sQuery += " 	       WHEN 2 THEN 'BASE MERCADORIA'"
	_sQuery += " 	       WHEN 3 THEN 'TOTAL NF - ST'"
	_sQuery += " 	    END 									  AS RAPEL_TIPO"
	_sQuery += "     , SE1.E1_VALOR				                  AS RAPEL_BASE"
    _sQuery += "     , 0                                          AS RAPEL_PER"
	_sQuery += "     , SE1.E1_VARAPEL                             AS RAPEL_VALOR"
	_sQuery += "  FROM SE1010 AS SE1"
	_sQuery += " 	INNER JOIN SA1010 AS SA1"
	_sQuery += " 		ON (SA1.D_E_L_E_T_  = ''"
	_sQuery += " 			AND SA1.A1_COD  = SE1.E1_CLIENTE"
	_sQuery += " 			AND SA1.A1_LOJA = SE1.E1_LOJA)"
 	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
    _sQuery += "   AND SE1.E1_FILIAL  = '" + SE1 -> E1_FILIAL + "'"
    _sQuery += "   AND SE1.E1_NUM     = '" + SE1 -> E1_NUM + "'"
   	_sQuery += "   AND SE1.E1_PREFIXO = '" + SE1 -> E1_PREFIXO + "'"
   	_sQuery += "   AND SE1.E1_CLIENTE = '" + SE1 -> E1_CLIENTE + "'"
   	_sQuery += "   AND SE1.E1_LOJA    = '" + SE1 -> E1_LOJA + "'"
   	
   	
	_aDados := U_Qry2Array(_sQuery)
	_aCols = {}

	aadd (_aCols, {1,  "Item"         ,  20,  "@!"})
	aadd (_aCols, {2,  "Descricao"    ,  50,  "@!"})
	aadd (_aCols, {3,  "Linha"        ,  20,  "@D"})
	aadd (_aCols, {4,  "Descr.Linha"  ,  40,  "@!"})
	aadd (_aCols, {5,  "Vlr.Merc"     ,  40,  "@Z 9,999,999.99"})
	aadd (_aCols, {6,  "Vlr.IPI"   	  ,  40,  "@Z 9,999,999.99"})
	aadd (_aCols, {7,  "Vlr.ST"   	  ,  40,  "@Z 9,999,999.99"})
	aadd (_aCols, {8,  "Vlr.Total"    ,  40,  "@E 9,999,999.99"})
	aadd (_aCols, {9,  "Tipo Rapel"   ,  20,  "@!"})
	aadd (_aCols, {10, "Base Rapel"   ,  40,  "@E 9,999,999.99"})
	aadd (_aCols, {11, "%Rapel"       ,  35,  "@Z 999.99"})
	aadd (_aCols, {12, "Vlr Rapel"    ,  40,  "@E 9,999,999.99"})
	
	U_F3Array (_aDados, "Consulta Valores Rapel", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -250 , "", "", .F., 'C' )
	
return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Baixas rapel
user function VA_040BRAP()
	local _aTitulo := {}
	local _aSE5    := {}
	local x        := 0

	cPerg   := "VA_040BRAP"
	_ValidPerg ()
	
	if ! pergunte (cPerg, .T.)
		return
	else
		if empty(mv_par01) .or. empty(mv_par02) .or. empty(mv_par03) .or. empty(mv_par04)
			u_help("Banco, agencia, conta e data da baixa devem ser preenchidos!")
		else
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT DISTINCT "
			_oSQL:_sQuery += " 		 E1_FILIAL"
			_oSQL:_sQuery += " 		,E1_PREFIXO"
			_oSQL:_sQuery += " 		,E1_NUM"
			_oSQL:_sQuery += " 		,E1_PARCELA"
			_oSQL:_sQuery += " 		,E1_CLIENTE"
			_oSQL:_sQuery += "  	,E1_LOJA"
			_oSQL:_sQuery += " 		,E1_TIPO"
			_oSQL:_sQuery += " 		,E1_VARAPEL"
			_oSQL:_sQuery += " 		,E1_BAIXA"
			_oSQL:_sQuery += " 		,E1_VALOR"
			_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
			_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " AND E1_FILIAL   = '" + cFilAnt  + "'"
			_oSQL:_sQuery += " AND E1_PORT2    = '" + mv_par01  + "'"
			_oSQL:_sQuery += " AND E1_AGEDEP   = '" + mv_par02  + "'"
			_oSQL:_sQuery += " AND E1_CONTA    = '" + mv_par03 + "'"
			_oSQL:_sQuery += " AND E1_NUMBCO  <> ''"
			_oSQL:_sQuery += " AND E1_BAIXA    = '" + DTOS(mv_par04) + "'"
			_oSQL:_sQuery += " AND E1_VARAPEL <> 0"
			if !empty(mv_par05) .and. !empty(mv_par06)
				_oSQL:_sQuery += " AND E1_NUM     = '" + mv_par05  + "'" 
				_oSQL:_sQuery += " AND E1_PREFIXO = '" + mv_par06 + "'" 
			endif
			if !empty(mv_par07) .and. !empty(mv_par08)
				_oSQL:_sQuery += " AND E1_CLIENTE = '" + mv_par07 + "'" 
				_oSQL:_sQuery += " AND E1_LOJA    = '" + mv_par08    + "'" 
			endif
			_oSQL:Log ()

			_aTitulo := aclone (_oSQL:Qry2Array ())
			if len(_aTitulo) <= 0
				u_help("Não existe titulos com rapel para baixar")
			endif

			if len(_aTitulo) > 0
				_cMens := "Existem " + alltrim(str(len(_aTitulo))) + " registros para realizar a baixa de rapel. Deseja continuar?"

				if MsgYesNo(_cMens,"Baixa de rapel de titulos")
					for x:=1 to len(_aTitulo)

						_oSQL:= ClsSQL ():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " SELECT"
						_oSQL:_sQuery += " 		SUM(E5_VALOR)"
						_oSQL:_sQuery += " FROM " + RetSQLName ("SE5")
						_oSQL:_sQuery += " WHERE E5_FILIAL = '" + _aTitulo[x,1]	+ "'"
						_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _aTitulo[x,2]	+ "'"
						_oSQL:_sQuery += " AND E5_NUMERO   = '" + _aTitulo[x,3]	+ "'"
						_oSQL:_sQuery += " AND E5_PARCELA  = '" + _aTitulo[x,4]	+ "'"
						_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _aTitulo[x,5] + "'"
						_oSQL:_sQuery += " AND E5_LOJA     = '" + _aTitulo[x,6] + "'"
						_oSQL:_sQuery += " AND E5_TIPODOC IN ('VL', 'DC')"
						_aSE5 := aclone (_oSQL:Qry2Array ())

						if len(_aSE5) > 0
							_nSE5Vlr := _aSE5[1,1]
						else
							_nSE5Vlr := 0
						endif

						_nValorSE5 := _nSE5Vlr + _aTitulo[x,8] 
						_nValorSE1 := _aTitulo[x,10] 
				
						_sTitulo := alltrim(_aTitulo[x,3])+"/"+ alltrim(_aTitulo[x,2])+"/"+ _aTitulo[x,4]
						if _nValorSE5 > _nValorSE1
							u_help("Não será realizada a baixa de rapel do titulo:" + _sTitulo + " pois o valor do titulo é menor que o valor das baixas!")
						else
							lMsErroAuto := .F.

							// executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
							_aAutoSE1 := {}
							aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[x,1]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[x,2]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[x,3]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[x,4]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[x,5] 					, Nil})
							aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[x,6] 					, Nil})
							aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[x,7] 					, Nil})
							aAdd(_aAutoSE1, {"E1_VARAPEL"   , _aTitulo[x,8] 					, Nil})
							AAdd(_aAutoSE1, {"AUTMOTBX"		, 'NORMAL'  						, Nil})
							AAdd(_aAutoSE1, {"AUTBANCO"  	, 'CX1'		    					, Nil})
							AAdd(_aAutoSE1, {"AUTAGENCIA"  	, 'CX1  '		    				, Nil})
							AAdd(_aAutoSE1, {"AUTCONTA"  	, 'CX1       '		    			, Nil})				
							AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _aTitulo[x,9]		 				, Nil})
							AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _aTitulo[x,9]		 				, Nil})
							AAdd(_aAutoSE1, {"AUTHIST"   	, 'DESC RAPEL'					    , Nil})
							AAdd(_aAutoSE1, {"AUTDESCONT"	, _aTitulo[x,8]          		    , Nil})
							AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTVALREC"  	, 0								    , Nil})
						
							_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

							cPerg = 'FIN070'
							_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
							U_GravaSX1 (cPerg, "01", 1)    // testar mostrando o lcto contabil depois pode passar para nao
							U_GravaSX1 (cPerg, "04", 1)    // esse movimento tem que contabilizar

							MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

							if lMsErroAuto
								u_help("Erro na baixa do titulo:" + _sTitulo)
								u_help(memoread (NomeAutoLog ()))
							endif
						endif
					next
				endif
			endif
		endif
	endif
return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Boleto
user function VA_040BOL()
	local   _lRet     := .T.
	local   _aBanco   := {}
	local 	i		  := 0
	private _aBoletos := {}
	
	if _lRet .AND. (SE1 -> E1_TIPO = 'NCC' .OR. SE1 -> E1_TIPO = 'RA') 
		u_help ("Não é possivel imprimir boletos pra esse tipo de titulo",, .t.)
		_lRet = .F.
	endif
//	if _lRet .AND. VAL(SE1 -> E1_PORTADO) = 0 .AND. SE1 -> E1_BOLIMP = 'S' .AND. SE1-> E1_NUMBOR  != ''
	if _lRet .AND. VAL(SE1 -> E1_PORTADO) = 0 .AND. SE1 -> E1_BOLIMP = 'S' .AND. ! empty (SE1-> E1_NUMBOR)
		u_help ("Não é possivel imprimir boletos nesse caso, titulo em protesto",, .t.)
		_lRet = .F.
	endif
	if _lRet
		if SE1 -> E1_BOLIMP = 'S'
			_sBanco = SE1 -> E1_PORTADO
			if empty (_sBanco)
				u_help ("Titulo consta como tendo boleto ja impresso, mas nao ha banco (portador) informado neste titulo!",, .t.)
				_lRet = .F.
			endif
		else
			_sBanco = U_Get ("Informe o novo banco para impressão do boleto: ", "C", 3, "", "SA6", se1 -> e1_portado, .F., '.t.')
			_sBanco = iif (_sBanco == NIL, '', _sBanco)  // Funcao U_Get retorna NIL se o usuario cancelar.
			if ! empty (_sBanco) .and. ! sa6 -> (dbseek (xfilial ("SA6") + _sBanco, .F.))
				u_help ("Banco '" + _sBanco + "' nao cadastrado.",, .t.)
				_lRet = .F.
			endif
		endif	
	endif
	if _lRet .and. empty (_sBanco)
		u_help ("Banco nao informado no titulo, impossivel impressao de boletos.",, .t.)
		_lRet = .F.
	endif
	if _lRet
		_sQuery := ""
		_sQuery += " SELECT SEE.EE_AGENCIA"
		_sQuery += "      , SEE.EE_CONTA"
		_sQuery += "      , SEE.EE_SUBCTA"
	 	_sQuery += "   FROM " + RetSQLName ("SA6") + " AS SA6 "
		_sQuery += " 	INNER JOIN " + RetSQLName ("SEE") + " AS SEE"
		_sQuery += " 		ON (SEE.D_E_L_E_T_ = ''"
		_sQuery += " 			AND SEE.EE_FILIAL  = SA6.A6_FILIAL"
		_sQuery += " 			AND SEE.EE_CODIGO  = SA6.A6_COD"
		_sQuery += " 			AND SEE.EE_AGENCIA = SA6.A6_AGENCIA"
		_sQuery += " 			AND SEE.EE_CONTA   = SA6.A6_NUMCON"
		if _sBanco = '001' .and. SE1 -> E1_FILIAL = '01' // troca de convenio da matriz usar sempre subconta 1
			_sQuery += "		AND SEE.EE_SUBCTA  = '1'"
		endif
		_sQuery += "			AND SEE.EE_SUBCTA != '100')"
		_sQuery += "  WHERE SA6.D_E_L_E_T_ = ''"
		_sQuery += " 	AND SA6.A6_FILIAL  = '" + SE1 -> E1_FILIAL + "'"
		_sQuery += " 	AND SA6.A6_COD     = '" + _sBanco + "'"
		_sQuery += " 	AND SA6.A6_BLOCKED = '2'"
		_aBanco := U_Qry2Array(_sQuery) // dados do banco - conta/agencia/subconta
		if len(_aBanco) = 0
			u_help ("Não foram encontrados os dados de cobrança do banco '" + _sBanco + "'", _sQuery, .t.)
			_lRet = .F.
		endif
	endif
	if _lRet
		_sQuery := ""
		_sQuery += " SELECT "
		_sQuery += "	      E1_FILIAL"
		_sQuery += "		, E1_PORTADO"
		_sQuery += "		, E1_AGEDEP"
		_sQuery += "		, E1_CONTA"
	    _sQuery += " 	  	, SE1.E1_BOLIMP"
	    _sQuery += "		, SE1.E1_NUMBCO"
		_sQuery += "  	  	, SEE.EE_CODIGO"
		_sQuery += "        , SEE.EE_AGENCIA"
		_sQuery += "        , SEE.EE_CONTA"
		_sQuery += "        , SEE.EE_SUBCTA"
		_sQuery += "   FROM " + RetSQLName ("SE1") + " AS SE1"
		_sQuery += " 	LEFT JOIN " + RetSQLName ("SEE") + " AS SEE"
		_sQuery += " 		ON (SEE.D_E_L_E_T_ = ''"
		_sQuery += " 			AND SEE.EE_FILIAL  = SE1.E1_FILIAL"
		_sQuery += " 			AND SEE.EE_CODIGO  = SE1.E1_PORTADO"
		_sQuery += " 			AND SEE.EE_AGENCIA = SE1.E1_AGEDEP"
		if _sBanco = '001' .and. SE1 -> E1_FILIAL = '01' // troca de convenio da matriz usar sempre subconta 1
			_sQuery += "		AND SEE.EE_SUBCTA  = '1'"
		endif
		_sQuery += "			AND SEE.EE_SUBCTA != '100'"
		_sQuery += " 			AND SEE.EE_CONTA   = SE1.E1_CONTA )"
		_sQuery += "  WHERE SE1.D_E_L_E_T_ = ''"
		_sQuery += "    AND SE1.E1_FILIAL  = '" + SE1 -> E1_FILIAL + "'"
	    _sQuery += "    AND SE1.E1_NUM     = '" + SE1 -> E1_NUM + "'"
	   	_sQuery += "    AND SE1.E1_PREFIXO = '" + SE1 -> E1_PREFIXO + "'"
	   	_sQuery += "    AND SE1.E1_CLIENTE = '" + SE1 -> E1_CLIENTE + "'"
	   	_sQuery += "    AND SE1.E1_LOJA    = '" + SE1 -> E1_LOJA + "'"
	   	_sQuery += "    AND SE1.E1_PARCELA = '" + SE1 -> E1_PARCELA + "'"
	   	_aTitulos := U_Qry2Array(_sQuery)
	   		   	
	   	if len(_aTitulos) > 0
	   		_aBoletos = {}
	   		for i=1 to len(_aTitulos)
	   			if _aTitulos[i,5]  = 'S'
	   				aadd (_aBoletos, { SE1 -> E1_PREFIXO, SE1 -> E1_NUM, _sBanco, _abanco[1,1], _abanco[1,2], _abanco[1,3] , "FA740BRW"})
	   			else
	   				aadd (_aBoletos, { SE1 -> E1_PREFIXO, SE1 -> E1_NUM, SE1 -> E1_PORTADO, _aTitulos[i,8], _aTitulos[i,9], _aTitulos[i,10] , "FA740BRW"})
	  			endif	
	    	next
		endif
		
		if len (_aBoletos) > 0
			processa ({|| U_ML_BOLLSR (_aBoletos)})
		endif
	endif
return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Carta Anuência
user function VA_040CART()
	local _lRet := .T.
	
	if _lRet .AND. (SE1 -> E1_TIPO = 'NCC' .OR. SE1 -> E1_TIPO = 'RA') 
		u_help ("Não é possivel imprimir carta de anuência pra esse tipo de titulo")
		_lRet = .F.
	endif
	if _lRet .AND. SE1 -> E1_SALDO > 0 
		u_help ("Titulo ainda tem saldo, não é possivel imprimir carta de anuência nesse caso")
		_lRet = .F.
	endif
	if _lRet
		_oPrn:=TAVPrinter():New("CARTA ANUENCIA")
		if _oPrn:Setup()      		// Tela para selecao da impressora.
			_oPrn:SetPortrait()     // ou SetLanscape()
			RptStatus({|| RptDetail()})
		endif		
	endif	
Return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// Carta Anuência impressão
Static Function RptDetail()
	Local _oSQL  := ClsSQL ():New ()
	Local _aCNPJ := {}
	Local _sCNPJ := ""

	// BUSCA CNPJ LOGADO
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT M0_CGC FROM VA_SM0 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
	_oSQL:_sQuery += " AND M0_CODIGO = '01'"
	_oSQL:_sQuery += " AND M0_CODFIL = '"+ cFilAnt +"'"
	_aCNPJ = aclone (_oSQL:Qry2Array ())

	If Len(_aCNPJ) > 0
		_sCNPJ := SUBSTR(alltrim(_aCNPJ[1,1]),1,2) +"."+ SUBSTR(alltrim(_aCNPJ[1,1]),3,3) +"."+ SUBSTR(alltrim(_aCNPJ[1,1]),6,3) +"/"+ SUBSTR(alltrim(_aCNPJ[1,1]),9,4) +"-"+ SUBSTR(alltrim(_aCNPJ[1,1]),13,2) 
	Else
		_sCNPJ := ""
	EndIf

    // imprime relatorio
    // Objetos para impressao
	::_oPrn      := _oPrn
	::_nPagAtual := 1  // Contador de paginas
	::_nLinAtual := 0
	::_nAltLin   := 50  // Altura de cada linha em pontos (para trabalhar de forma semelhante a impressao caracter)
	::_nMargSup  := 40  // Margem superior da pagina
	::_nMargInf  := 50  // Margem inferior da pagina
	::_nMargEsq  := 40   // Margem esquerda da pagina
	::_nAltPag   := 3100  //3400  // Altura maxima da pagina
	::_nLargPag  := 2350  // Largura maxima da pagina
	::_oTimes8   := TFont():New("Times New Roman",,8,,.T.,,,,,.F.)
	::_oTimes16  := TFont():New("Times New Roman",,16,,.T.,,,,,.F.)

	// Objetos para tamanho e tipo das fontes
	_oCour12N := TFont():New("Courier New",,12,,.T.,,,,,.F.)
	_oCour10N := TFont():New("Courier New",,10,,.T.,,,,,.F.)
	
    // imprime cabeçalho
    _Cabec (.T., 0, .T.)
    
    // imprime local e data
	 ::_nLinAtual += ::_nAltLin * 7
	 _sLinhaImp := alltrim (sm0 -> m0_CidCob) + ", " + SUBSTR(dtos(dDatabase),7,2) + " de " + MesExtenso( val(SUBStr(dtos(dDatabase),5,2) )) + " de " + SUBSTR(dtos(dDatabase),1,4)
	 ::_oPrn:Say (::_nMargsup + ::_nLinAtual , ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	 ::_nLinAtual += ::_nAltLin * 1
	 
    // imprime titulo
	::_nLinAtual += ::_nAltLin * 5
	_sLinhaImp := "CARTA DE ANUÊNCIA"
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 1000, _sLinhaImp, _oCour12N, 100)
	::_nLinAtual += ::_nAltLin * 2
	
	// imprime texto
	::_nLinAtual += ::_nAltLin * 2
	_sLinhaImp := "Prezados Senhores"
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1

	::_nLinAtual += ::_nAltLin * 2
	_sLinhaImp := "Autorizamos V.Sas. a cancelar o PROTESTO referente a duplicata abaixo, registradas e"
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	_sLinhaImp := "emitida por nós, credores originários no CNPJ " + alltrim(_sCNPJ) + "."
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	::_nLinAtual += ::_nAltLin * 2
	_sLinhaImp := "Sacado ..........: " + fbuscacpo ("SA1", 1, xfilial("SA1") + se1->e1_cliente + se1->e1_loja,  "A1_NOME")
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	_sLinhaImp := "CNPJ/CPF ........: " + fbuscacpo ("SA1", 1, xfilial("SA1") + se1->e1_cliente + se1->e1_loja,  "A1_CGC")
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	_sLinhaImp := "Duplicata número : " + se1 -> e1_num
	if  len(alltrim(se1 -> e1_parcela)) > 0
		_sLinhaImp += " - " + se1 -> e1_parcela
	endif
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
		
	_sLinhaImp := "Emitida em ......: " + dtoc(se1->e1_emissao)
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	_sLinhaImp := "Vencida em ......: " + dtoc(se1->e1_vencto)
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
		
	_sLinhaImp := "No valor de .....: R$ " + alltrim(transform (se1->e1_valor, "@E 9,999,999,999.99"))
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	_aExt := U_QuebraTxt (alltrim (Extenso (se1->e1_valor) ), 70)
	_sLinhaImp := "                   (" + _aExt [1]
	if len (_aExt) = 1
		_sLinhaImp += ")"
		::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
		::_nLinAtual += ::_nAltLin * 1
	else
		::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
		::_nLinAtual += ::_nAltLin * 1
		_sLinhaImp := "                    " + _aExt [2] + ")"
		::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
		::_nLinAtual += ::_nAltLin * 1
	endif
			
	::_nLinAtual += ::_nAltLin * 2
	_sLinhaImp := "Outro sim, informamos que a duplicata em questão foi devidamente quitada pelo sacado."  
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 2
	_sLinhaImp := "Sem mais, firmamo-nos"  
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	::_nLinAtual += ::_nAltLin * 3
	_sLinhaImp := "Atenciosamente"  
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 200, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
		
	::_nLinAtual += ::_nAltLin * 4
	_sLinhaImp := "Alceu Dalle Molle"  
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 1000, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
		
	_sLinhaImp := "Diretor Presidente"  
	::_oPrn:Say (::_nMargsup + ::_nLinAtual, ::_nMargEsq + 1000, _sLinhaImp, _oCour10N, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	::_nLinAtual += ::_nAltLin * 13
	_rodape(_sCNPJ)
			
     // Visualiza antes de imprimir
	 _oPrn:Preview()
	 _oPrn:End()

return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// imprime cabeçalho
static function _Cabec(_lObrig, _nMinimo, _lZeraPag)
	_sLinhaImp := ""
	_nMinimo   := iif (_nMinimo == NIL, 0, _nMinimo)

	if ::_nLinAtual >= ::_nAltPag - (::_nMargInf + _nMinimo) .or. _lObrig
		::_oPrn:StartPage ()  // Inicia uma nova pagina
		::_nPagAtual = 1
		::_nLinAtual = ::_nMargSup
		::_oPrn:SayBitmap(::_nLinAtual		, ;  // Linha
		                  800				, ;  // Coluna
		                  "Logo_carta.png"	, ;  // Arquivo
		                  900				, ;  // Largura
		                  280				  )  // Altura
		::_nLinAtual += 60
		::_nPagAtual ++
	endif
return
//
// ---------------------------------------------------------------------------------------------------------------------------------
// imprime rodapé
static function _rodape(_sCNPJ)
	
	_sLinhaImp := "Cooperativa Agroindustrial Nova Aliança Ltda"
	::_oPrn:Say (::_nLinAtual, 200, _sLinhaImp, ::_oTimes8, 100)
	::_nLinAtual += ::_nAltLin * 1

	_sLinhaImp := "CNPJ:" + _sCNPJ
	::_oPrn:Say (::_nLinAtual, 200, _sLinhaImp, ::_oTimes8, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	_sLinhaImp := "Estrada Gerardo Santin Guarese S/N - Caixa Postal 21"
	_sLinhaImp += space(50) + " Fone: (54) 3279-3400"
	_sLinhaImp += space(50) + "www.novaalianca.coop.br "
	::_oPrn:Say (::_nLinAtual, 200, _sLinhaImp, ::_oTimes8, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	_sLinhaImp := "Travessão Lagoa Bela - "
	_sLinhaImp += alltrim (sm0 -> m0_CidCob) + " - " + sm0 -> m0_EstCob
	_sLinhaImp += space(50) + "facebook/cooperativanovaalianca"
	::_oPrn:Say (::_nLinAtual, 200, _sLinhaImp, ::_oTimes8, 100)
	::_nLinAtual += ::_nAltLin * 1
	
	::_nPagAtual ++
	
return	
//
// --------------------------------------------------------------------------
// Perguntas
static function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "Banco       ", "C",  3 , 0,  "",  "SEE", {},                         				""})
    aadd (_aRegsPerg, {02, "Agencia     ", "C",  5 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {03, "Conta    	", "C",  10, 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {04, "Dt.Baixa    ", "D",  8 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {05, "Titulo      ", "C",  9 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {06, "Prefixo     ", "C",  3 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {07, "Cliente     ", "C",  6 , 0,  "",  "   ", {},                         				""})
	aadd (_aRegsPerg, {08, "Loja        ", "C",  2 , 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
