// Programa..: ML_FECHASAFRA
// Autor.....: Catia Cardoso
// Data......: 25/04/2017
// Nota......: Relatorio Fechamento de Safra

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio Fechamento de Safra
// #PalavasChave      #fechamento_de_safra 
// #TabelasPrincipais #VA_VNOTAS_SAFRA #SE2 #VA_VPRECO_EFETIVO_SAFRA
// #Modulos           #FAT

// Historico de alteracoes:
// 29/06/2017 - Catia   - Alteração para que as notas de complemento de compra listem por ultimo
// 17/07/2017 - Catia   - Incluido parametro de Nucleo
// 17/07/2017 - Catia   - Incluido parametro de saldo de conta corrente
// 17/07/2017 - Catia   - Alteração para possibilitar que se imprima tds os associados de um nucleo
// 18/07/2017 - Catia   - Listar em ordem alfabetica
// 12/09/2017 - Catia   - parcela C da Safra
// 25/03/2018 - Catia   - Parametros para safra 2018
// 04/04/2018 - Catia   - Quebra de pagina nos registros da conta corrente nao estava fazendo corretamente
// 24/05/2018 - Robert  - Nao listava previsao de pagamento (safra 2018) a cada quebra de associado.
// 10/04/2019 - Robert  - Ajustes diversos para a safra 2019
// 10/06/2019 - Robert  - Considera tambem notas na previsao de pagamentos (antes pegava apenas tipo FAT)
// 17/06/2019 - Robert  - Aumentada mascara do valor unitario para 4 decimais.
// 15/04/2020 - Robert  - Unificar com metodo FechSafr da classe ClsAssoc (GLPI 7794) para safras a partir de 2020.
// 17/04/2020 - Robert  - Criado tratamento para NF producao propria.
// 06/07/2020 - Robert  - Tratamento para nova secao <freteSafra>, com dados do auxilio combustivel.
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 31/08/2020 - Robert  - Concatena safra+cod+loja associado no nome do arquivo destino.
// 03/09/2020 - Robert  - Criado layout resumido.
// 15/02/2021 - Robert  - Criados modelos com/sem previsao de pagamento - GLPI 9318
//                      - Novos parametros metodo ClsAssoc:FechSafra() - GLPI 9318
//

#include "protheus.ch"
#include "tbiconn.ch"
#INCLUDE "XMLXFUN.CH"

// ----------------------------------------------------------------------------------------------------------------
User Function ML_FECHASAFRA (_lAutomat)
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	cString := "SD2"
	cDesc1  := "Fechamento Safra"
	cDesc2  := " "
	cDesc3  := " "
	tamanho := "G"
	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha  := {}
	nLastKey:= 0
	titulo  := "Fechamento Safra "
	cPerg   := "ML_FECHASA"
	wnrel   := "ML_FECHASAFRA"
	nTipo   := 0

	_ValidPerg()
	Pergunte(cPerg, .f.)
	wnrel   := "ML_FECHASAFRA_" + mv_par01 + '_' + mv_par02 + mv_par03
	titulo := "Fechamento Safra " + mv_par01

	if ! _lAuto
		wnrel  := SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint ( cString	, ;  // Alias
							wnrel	, ;  // Sugestao de nome de arquivo para gerar em disco
							cPerg	, ;  // Parametros
							@titulo	, ;  // Titulo do relatorio
							cDesc1	, ;  // Descricao 1
							cDesc2	, ;  // Descricao 2
							cDesc3	, ;  // Descricao 3
							.F.		, ;  // .T. = usa dicionario
							{}		, ;  // Array de ordenacoes para o usuario selecionar
							.T.		, ;  // .T. = comprimido
							tamanho	, ;  // P/M/G
							NIL		, ;  // Nao pude descobrir para que serve.
							.F.		, ;  // .T. = usa filtro
							NIL		, ;  // lCrystal
							NIL		, ;  // Nome driver. Ex.: "EPSON.DRV"
							.T.		, ;  // .T. = NAO mostra interface para usuario
							.T.		, ;  // lServer
							NIL		  )  // cPortToPrint
	endif

	If nLastKey == 27
		Return
	Endif

	// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
	delete file (__reldir + wnrel + ".##r")

	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif

	// u_logSX1 (cPerg)

	if mv_par01 < '2020'  // Metodo original
		processa ({|| RptDetail ()})
	else  // Busca da classe ClsAssoc.
		if mv_par06 == 1  // Detalhado
			processa ({|| _Modelo2 (.f.)})
		elseif mv_par06 == 2  // Resumido
			processa ({|| _Modelo3 ()})
		elseif mv_par06 == 3  // Resumido (apenas NF compra)
			processa ({|| _Modelo2 (.T.)})
		else
			u_help ("Modelo sem tratamento.",, .t.)
		endif
	endif

	Set Printer TO
	MS_FLUSH ()
	DbCommitAll ()
	MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

	if ! _lAuto
		If aReturn [5] == 1
			ourspool(wnrel)
		Endif
	endif
Return
//
// --------------------------------------------------------------------------
// Modelo original
Static Function RptDetail()
	local _oAssoc := NIL
	local _oSQL   := NIL
	local FAT	  := 0
	local i		  := 0

	procRegua(800)
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1

	cabec1:="FILIAL  NF/SERIE  DT EMISSAO   PRODUTO (UVA)                          GRAU/CLAS           PESO    VLR UNIT         VLR TOTAL  OBSERVACOES"
	cabec2:=""

	// monta query
	_sQuery := " "
	_sQuery += "SELECT ASSOCIADO, LOJA_ASSOC, NOME_ASSOC"
	_sQuery += "     , CASE WHEN TIPO_NF = 'V' THEN 'A' ELSE TIPO_NF END AS TIPO_NF"
	_sQuery += "     , FILIAL, DATA, DOC, SERIE" 
	_sQuery += "     , PRODUTO, DESCRICAO, GRAU, PESO_LIQ, VALOR_UNIT, VALOR_TOTAL"
	_sQuery += "     , CLAS_FINAL, CLAS_ABD, SIST_CONDUCAO"
	if mv_par01 = '2017'
		_sQuery += "     , CASE WHEN DATA < '20170630' THEN	
		_sQuery += "	  		   CASE WHEN PRODUTO IN ('9925', '9948', '9822', '9959') THEN 'A - 100%'" 
		_sQuery += "            	 	WHEN TIPO_ORGANICO = 'O' THEN 'A - 100%'"
		_sQuery += "	        	 	WHEN FINA_COMUM    = 'F' AND FORMA_CLAS_UVA_FINA = 'F' AND SIST_CONDUCAO = 'E' THEN 'A - 50%, B - 50%'"
		_sQuery += "                    WHEN TINTOREA      = 'S' THEN 'A - 50%, B - 50%'"
		_sQuery += "                    ELSE 'A - 15%, B - 22%, C - 31,5%' END"
		// complemento - notas geradas em julho
		_sQuery += "       	    WHEN DATA > '20170630' AND DATA < '20170731' THEN"  
		_sQuery += "			   CASE WHEN PRODUTO IN ('9925', '9948', '9822', '9959') THEN 'B - 100%'"            
		_sQuery += " 					WHEN TIPO_ORGANICO = 'O' THEN 'B - 100%'"	        
		_sQuery += " 					WHEN FINA_COMUM    = 'F' AND FORMA_CLAS_UVA_FINA = 'F' AND SIST_CONDUCAO = 'E' THEN 'B - 100%'"           
		_sQuery += " 				    WHEN TINTOREA      = 'S' THEN 'B - 100%'"       
		_sQuery += " 					ELSE 'B - 22%, C - 31,5%' END"
		// complemento - notas geradas em agosto
		_sQuery += "       	    WHEN DATA > '20170731' THEN"  
		_sQuery += "			   CASE WHEN PRODUTO IN ('9925', '9948', '9822', '9959') THEN 'C - 100%'"            
		_sQuery += " 					WHEN TIPO_ORGANICO = 'O' THEN 'C - 100%'"	        
		_sQuery += " 					WHEN FINA_COMUM    = 'F' AND FORMA_CLAS_UVA_FINA = 'F' AND SIST_CONDUCAO = 'E' THEN 'C - 100%'"           
		_sQuery += " 				    WHEN TINTOREA      = 'S' THEN 'C - 100%'"       
		_sQuery += " 					ELSE 'B - 22%, C - 31,5%' END"
		_sQuery += "	   END AS REGR_PAG" 
	endif
	_sQuery += "  FROM VA_VNOTAS_SAFRA"

	_sQuery += " WHERE SAFRA      = '" + mv_par01 + "'"
	// se informou o associado busca so o associado - senão le todos
	if val(mv_par02) > 0
		_sQuery += "   AND ASSOCIADO  = '" + mv_par02 + "'"
		_sQuery += "   AND LOJA_ASSOC = '" + mv_par03 + "'"
	endif			
	_sQuery += " ORDER BY NOME_ASSOC, ASSOCIADO, LOJA_ASSOC, TIPO_NF DESC, DATA"
	//u_showmemo(_sQuery)

	// imprime relatorio
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	count to _nRecCount
	procregua (_nRecCount)

	_aTot       = {0,0,0,0,0,0,0,0}
	_aTotTp     = {0,0,0,0,0,0,0,0}
	_wtotA      := 0
	_wtotB      := 0
	_wtotC      := 0
	_wvlrA		:= 0
	_wvlrB		:= 0
	_wsaldo     := 0
	_vAnt       := ""
	_VAntLj     := ""
	_vAntnome   := ""
	_wtipoNFant := ""
	_wfilial      := ""
	_wcomplemento := ""

	// lista fechamento safra do associado      
	(_sAliasQ) -> (DBGoTop ())
	Do While ! (_sAliasQ) -> (Eof ())
			
		// se informou o Nucleo filtra por nucleo
		if mv_par04 != '  '
			_oAssoc := ClsAssoc ():New ((_sAliasQ) -> ASSOCIADO, (_sAliasQ) -> LOJA_ASSOC)
			if valtype (_oAssoc) != 'O' .or. _oAssoc:Nucleo != mv_par04
				//u_log ('nucleo', _oAssoc:Nucleo)
				(_sAliasQ) -> (dbskip ())
				loop
			endif
		endif

		IF _vAnt + _VAntLj  != (_sAliasQ) -> ASSOCIADO + (_sAliasQ) -> LOJA_ASSOC
			IF _aTotTp[2] = 0
				If li>63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif

				@ li, 00 PSAY "Associado: " + (_sAliasQ) -> ASSOCIADO + '-' + ALLTRIM((_sAliasQ) -> LOJA_ASSOC) + ' ' + ALLTRIM((_sAliasQ) -> NOME_ASSOC)
				li ++ 
				li ++
			endif			   	 
			if _aTotTp[2] > 0
				// imprime por tipo de nota
				If li>63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif 
				       
				if _wtipoNFant = 'E'
					@li, 09 PSAY "Total NF's de ENTREGA de Uva"
				elseif _wtipoNFant = 'C'
					@li, 09 PSAY "Total NF's de COMPRA de Uva"
				elseif _wtipoNFant = 'A'
					@li, 09 PSAY "Total NF's de Complemento Vlr"
				elseif _wtipoNFant = 'P'
					@li, 09 PSAY "Total NF's de Produção Própria"
				endif
				@ li,  78 PSAY _aTotTp [1]  Picture "@E 9,999,999,999.99"
				@ li, 108 PSAY _aTotTp [2]  Picture "@E 9,999,999,999.99"
				li++
				li++
				
				// imprime totais do associado
				If li+6 > 63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				
				@ li, 00 PSAY "Totais do Associado: "
				@ li, 39 PSAY "Entrega"
				@ li, 78 PSAY _aTot [1]  Picture "@E 9,999,999,999.99"
				@ li,108 PSAY _aTot [2]  Picture "@E 9,999,999,999.99"
				li++
				@ li, 39 PSAY "Compra"
				@ li, 78 PSAY _aTot [3]  Picture "@E 9,999,999,999.99"
				@ li,108 PSAY _aTot [4]  Picture "@E 9,999,999,999.99"
				li++
				@ li, 39 PSAY "Compl.Vlr"
				@ li, 78 PSAY _aTot [5]  Picture "@E 9,999,999,999.99"
				@ li,108 PSAY _aTot [6]  Picture "@E 9,999,999,999.99"
				li++
				@ li, 39 PSAY "Total a Receber"
				@ li,108 PSAY (_aTot [4] + _aTot [6])  Picture "@E 9,999,999,999.99"
				li++
				li++
				
				// previsao de pagamento
				// le as variadades e monta valor das parcelas previstas
				If li+6 > 63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif        
					
				if mv_par01 = '2017'
					@ li, 00 PSAY "Previsão de Pagamento: "
					@ li, 39 PSAY "Parcela A - ABRIL"
					@ li,155 PSAY _wtotA  Picture "@E 9,999,999,999.99"
					li++ 
					@ li, 39 PSAY "Parcela B - JULHO"
					@ li,155 PSAY _wtotB  Picture "@E 9,999,999,999.99"
					li++
					@ li, 39 PSAY "Parcela C - SETEMBRO"
					@ li,155 PSAY _wtotC  Picture "@E 9,999,999,999.99"
					li++
					@ li, 39 PSAY "Saldo Restante"
					@ li,155 PSAY _wsaldo  Picture "@E 9,999,999,999.99"
					li++
					@ li, 39 PSAY "Total"
					@ li,155 PSAY (_wtotA + _wtotB + _wtotC + _wsaldo)  Picture "@E 9,999,999,999.99"
					li++
					li++
					li++

				elseif mv_par01 >= '2018'
					_sQuery  = " "
					_sQuery += "SELECT E2_NUM, E2_VENCTO, E2_VALOR, E2_SALDO"
					_sQuery += "  FROM SE2010"
					_sQuery += " WHERE D_E_L_E_T_ = ''"
					_sQuery += "   AND E2_FILIAL  = '01'"
					_sQuery += "   AND E2_FORNECE = '" + _vant + "'"
					_sQuery += "   AND E2_LOJA    = '" + _vantlj + "'"
					_sQuery += "   AND E2_PREFIXO = '30'"
					_sQuery += "   AND ((E2_TIPO = 'FAT' AND E2_NUM like '" + mv_par01 + "%') OR (E2_TIPO IN ('NF', 'DP') AND E2_FATURA = ''))"
					if mv_par01 == '2018'
						_sQuery += "   AND E2_EMISSAO > '20180301'"
					endif
					_sQuery += "   AND E2_EMISSAO >= '" + mv_par01 + "0101'"
					_sQuery += " ORDER BY E2_VENCTO, E2_NUM"
					u_log (_sQuery)
					
					_aDados := U_Qry2Array(_sQuery)
					if len(_aDados) > 0
						@ li, 00 PSAY "Previsão de Pagamento: "
						li++
						@ li, 39 PSAY "FATURA"  
						@ li, 60 PSAY "VENCIMENTO"
						@ li, 89 PSAY "VALOR"
						@ li,108 PSAY "SALDO"
						li++
						_wtotvlr = 0
						_wtotsld = 0
						for FAT=1 to len(_aDados)
							@ li, 39 PSAY _aDados[FAT,1]   
							@ li, 60 PSAY _aDados[FAT,2]
							@ li, 80 PSAY _aDados[FAT,3] Picture "@E 999,999,999.99"
							@ li,100 PSAY _aDados[FAT,4] Picture "@E 999,999,999.99"
							li++
							_wtotvlr = _wtotvlr + _aDados[FAT,3]
							_wtotsld = _wtotsld + _aDados[FAT,4]
						next
						@ li, 39 PSAY "Totais: "
						@ li, 80 PSAY _wtotvlr Picture "@E 999,999,999.99"
						@ li,100 PSAY _wtotsld Picture "@E 999,999,999.99"
						li++	
						li++		 
					endif	
				endif
					
				If li+3 > 63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				
				if mv_par01 = '2017'
					@ li, 00 PSAY "Regras Pagamento:"
					@ li, 39 PSAY "Parcela A = 100% Bordô, 100% Orgânicas, 50% Tintóreas, 50% Viníferas em espaldeira, 15% das demais variedades"
					li++
					@ li, 39 PSAY "Parcela B = 50% Tintóreas, 50% Viníferas em espaldeira, 22% das demais variedades, 100% do complemento de julho Bordô, Orgânicas, Tintóreas"
					li++
					li++
					@ li, 39 PSAY "Parcela C = 31,5% das demais variedades, 100% dos complementos de de julho Bordô, Orgânicas, Tintóreas"
					li++
					li++
				elseif mv_par01 >= '2018'
					@ li, 00 PSAY "Regras Pagamento:"
					@ li, 39 PSAY "Grupo 1 -  5 vezes - Bordo e Organicas"
					li++
					@ li, 39 PSAY "Grupo 2 -  9 vezes - Tintorias e Vinifereas espaldeira"
					li++
					@ li, 39 PSAY "Grupo 3 - 11 vezes - Demais Variedades"
					li++
				else
					@ li, 39 PSAY "Regras Pagamento ainda não definidas para esta safra."
					li++
				endif

				if _wcomplemento = 'S'
					_sQuery := " "
					_sQuery += "SELECT DISTINCT PRODUTO, DESCRICAO, GRAU, PESO_LIQ"
					_sQuery += "     ,   VUNIT_EFETIVO"
					_sQuery += "     , VALOR_COMPRA + VALOR_COMPLEMENTO AS VALOR_TOTAL"
					_sQuery += "  FROM VA_VPRECO_EFETIVO_SAFRA"
					_sQuery += " WHERE SAFRA      = '" + mv_par01 + "'"
					_sQuery += "   AND ASSOCIADO  = '" + _vAnt + "'"
					_sQuery += "   AND LOJA_ASSOC = '" + _VAntLj + "'"
					_sQuery += " ORDER BY DESCRICAO, GRAU"
					_aDados := U_Qry2Array(_sQuery)
					
					// lista valor efetivo por variedade/grau
					if len(_aDados)> 0
						li ++
						li++
						@li,  00 PSAY "Valor Efetivo por Variedade/Grau:"
						for i=1 to len(_aDados)
							If li + len(_aDados) > 63
								cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
							Endif        
							
							@li,  31 PSAY left (ALLTRIM( _aDados [i,1])  + ' - ' + ALLTRIM(_aDados [i,2]), 40)
							@li,  89 PSAY _aDados [i,3] Picture "@E 99.99"
							@li, 115 PSAY _aDados [i,4] Picture "@E 9,999,999,999.99"
							@li, 135 PSAY _aDados [i,5] Picture "@E 9,999,999.99"
							@li, 155 PSAY _aDados [i,6] Picture "@E 9,999,999,999.99"
							li ++
						next
						li ++
					endif
				endif
				// imprime saldo conta corrente
				if mv_par05 == 1				 
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += "SELECT SZI.ZI_DATA, ZI_TM, ZI_DOC, ZI_HISTOR, ZX5_10DC, ZI_SALDO"
					_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
					_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
					_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
					_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
					_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = SZI.ZI_TM"
					_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
					_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '  ' and 'zz'"
					_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + _vAnt + "'"
					_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + _vAntLj + "'"
					_oSQL:_sQuery +=   " AND SZI.ZI_TM       NOT IN ('10/17/18/19')"
					_oSQL:_sQuery +=   " AND SZI.ZI_DATA     like '" + mv_par01 + "%'"
					_oSQL:_sQuery +=   " AND SZI.ZI_SALDO    > 0"
					_oSQL:_sQuery += " ORDER BY ZI_DATA, ZI_TM, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
					//u_log (_oSQL:_sQuery)
					_aSld := aclone (_oSQL:Qry2Array (.F., .F.))
					
					if len (_aSld) > 0
						li ++
						_wsaldo := 0
						@li,  00 PSAY "Lctos Aberto Conta Corrente:"
						for i=1 to len (_aSld)
							_wdata  = stod (_aSld [i,1])
							_wtpmov = _aSld [i,2]
							_wdoc   = _aSld [i,3]
							_whist  = substr(_aSld [i,4],1,80)
							_wdc    = _aSld [i,5]
							_wvalor = _aSld [i,6]
				
							If li>63
								cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
							Endif        
								
							@li,  39 PSAY _wdata
							@li,  55 PSAY _wtpmov 
							@li,  60 PSAY _wdoc + '-' + _whist 
							@li, 155 PSAY _wvalor Picture "@E 9,999,999,999.99"
							@li, 172 PSAY _wdc
							li ++
							if _wdc = "C"
								_wsaldo += _wvalor
							else
								_wsaldo -= _wvalor
							endif																																																		
						next
						@li,  60 PSAY "SALDO"
						@li, 155 PSAY _wsaldo Picture "@E 9,999,999,999.99"
						if _wsaldo > 0
							@li, 172 PSAY "C"
						else
							@li, 172 PSAY "D"
						endif
						
						li ++
					endif
				endif		
				
				// salta pagina
				li := 80
				If li>63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
					li ++
					@ li, 00 PSAY "Associado: " + (_sAliasQ) -> ASSOCIADO + '-' + ALLTRIM((_sAliasQ) -> NOME_ASSOC)
					li ++ 
					li ++
					
					_aTot       = {0,0,0,0,0,0,0,0}
					_aTotTp     = {0,0,0,0,0,0,0,0}
					_wtotA      := 0
					_wtotB      := 0
					_wtotC      := 0
					_wvlrA		:= 0
					_wvlrB		:= 0
					_wsaldo     := 0
					_wfilial      := ""
					_wcomplemento := ""
					
					
				endif    
				endif				
			endif
			
			IF  _wtipoNFant != (_sAliasQ) -> TIPO_NF .and. _aTotTp[2] > 0
				// imprime totais
				If li>63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif        
				if _wtipoNFant = 'E'
					@li, 09 PSAY "Total NF's de ENTREGA de Uva"
				elseif _wtipoNFant = 'C'
					@li, 09 PSAY "Total NF's de COMPRA de Uva"
				elseif _wtipoNFant = 'A'
					@li, 09 PSAY "Total NF's de Complemento Vlr"
				elseif _wtipoNFant = 'P' 
					@li, 09 PSAY "Total NF's de Produção Própria"
				endif
				@ li, 78  PSAY _aTotTp [1]  Picture "@E 9,999,999,999.99"
				@ li, 108 PSAY _aTotTp [2]  Picture "@E 9,999,999,999.99"
				_aTotTp [1] := 0 
				_aTotTp [2] := 0
				li++
				li++
			Endif
			
			if  _wtipoNFant != (_sAliasQ) -> TIPO_NF 
				If li>63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				if (_sAliasQ) -> TIPO_NF = 'E'
					@li, 09 PSAY "NF's de ENTREGA de Uva"
					li ++
				elseif (_sAliasQ) -> TIPO_NF = 'C'
					@li, 09 PSAY "NF's de COMPRA de Uva"
					li ++
				elseif (_sAliasQ) -> TIPO_NF = 'A'
					@li, 09 PSAY "NF's de Complemento Vlr"
					li ++
				elseif (_sAliasQ) -> TIPO_NF = 'P'
					@li, 09 PSAY "NF's de Produção Própria"
					li ++
				endif
			endif
			
					
			If li>63
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif

			@li,  00 PSAY (_sAliasQ) -> FILIAL
			@li,  04 PSAY (_sAliasQ) -> DOC + '/' + SERIE
			@li,  18 PSAY stod ((_sAliasQ) -> DATA)
			@li,  31 PSAY U_TamFixo (ALLTRIM((_sAliasQ) -> PRODUTO)  + ' - ' + ALLTRIM((_sAliasQ) -> DESCRICAO), 40, ' ')
			@li,  72 PSAY (_sAliasQ) -> GRAU Picture "@E 99.99"
			if mv_par01 <= '2018'
				if (_sAliasQ) -> FILIAL  ='03'
					@li, 79 PSAY (_sAliasQ) -> CLAS_FINAL
				else
					@li, 79 PSAY (_sAliasQ) -> CLAS_ABD
				endif
			else
				@ li, 79 psay iif ((_sAliasQ) -> SIST_CONDUCAO == "E", (_sAliasQ) -> clas_final, (_sAliasQ) -> CLAS_ABD)
			endif
			@li, 81  PSAY (_sAliasQ) -> PESO_LIQ     Picture "@E 99,999,999.99"
			@li, 95  PSAY (_sAliasQ) -> VALOR_UNIT   Picture "@E 99,999.9999"
			@li, 108 PSAY (_sAliasQ) -> VALOR_TOTAL  Picture "@E 9,999,999,999.99"

			// Observacoes conforme tipo de nota
			if mv_par01 >= '2019'
				if (_sAliasQ) -> TIPO_NF == 'E'
					@ LI, 126 PSAY "(Nao serve como base para valor de compra)"
				elseif mv_par01 >= '2019'  // Antes nao tinha comentarios sobre os precos.
					_oSQL := ClsSQL():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT top 1 RTRIM (ZZ9_MSGNF) + CASE WHEN ZZ9_MSGNF = '' THEN '' ELSE ';' END + ZZ9_OBS"
					_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZ9") + " ZZ9 "
					_oSQL:_sQuery +=  " WHERE ZZ9.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=    " AND ZZ9_FILIAL     = '" + (_sAliasQ) -> filial + "'"
					_oSQL:_sQuery +=    " AND ZZ9_SAFRA      = '" + mv_par01 + "'"
					_oSQL:_sQuery +=    " AND ZZ9_FORNEC     = '" + (_sAliasQ) -> ASSOCIADO + "'"
					_oSQL:_sQuery +=    " AND ZZ9_LOJA       = '" + (_sAliasQ) -> LOJA_ASSOC + "'"
					_oSQL:_sQuery +=    " AND ZZ9_NFCOMP     = '" + (_sAliasQ) -> doc + "'"
					_oSQL:_sQuery +=    " AND ZZ9_SERCOM     = '" + (_sAliasQ) -> serie + "'"
					_oSQL:_sQuery +=    " AND ZZ9_PRODUT     = '" + (_sAliasQ) -> PRODUTO + "'"
					_oSQL:_sQuery +=    " AND ZZ9_GRAU       = '" + (_sAliasQ) -> grau + "'"
					_oSQL:_sQuery +=    " AND ZZ9_CLASSE     = '" + (_sAliasQ) -> clas_final + "'"
					_oSQL:_sQuery +=    " AND ZZ9_CLABD      = '" + (_sAliasQ) -> clas_abd + "'"
					_oSQL:_sQuery +=    " AND ZZ9_VUNIT      = " + cvaltochar ((_sAliasQ) -> valor_unit)
					//_oSQL:Log ()
					@ li, 126 psay left (_oSQL:RetQry (), 93)
				endif
			endif

			if (_sAliasQ) -> TIPO_NF != 'E'
				// acumula totais das parcelas
				if mv_par01 = '2017'
					@li, 126 PSAY (_sAliasQ) -> REGR_PAG
					do case
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "A - 100%"
							_wtotA += (_sAliasQ) -> VALOR_TOTAL
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "A - 50%, B - 50%"
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL /2 ,2)
							_wtotA += _wvalor
							_wtotB += ((_sAliasQ) -> VALOR_TOTAL - _wvalor)
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "A - 15%, B - 22%, C - 31,5%"
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL*15/100 ,2)
							_wtotA += _wvalor
							_wvlrA  = _wvalor
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL*22/100 ,2)
							_wtotB += _wvalor
							_wvlrB  = _wvalor
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL*31.5/100 ,2)
							_wtotC += _wvalor
							_wvlrC  = _wvalor
							_wsaldo += (_sAliasQ) -> VALOR_TOTAL - (_wvlrA + _wvlrB + _wvlrC)  
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "B - 100%"
							_wtotB += (_sAliasQ) -> VALOR_TOTAL
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "B - 22%, C - 31,5%""
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL*22/100 ,2)
							_wtotB += _wvalor
							_wvlrB  = _wvalor
							_wvalor = ROUND( (_sAliasQ) -> VALOR_TOTAL*31.5/100 ,2)
							_wtotC += _wvalor
							_wvlrC  = _wvalor
							_wsaldo += (_sAliasQ) -> VALOR_TOTAL - (_wvlrB + _wvlrC)
						case ALLTRIM((_sAliasQ) -> REGR_PAG) == "C - 100%"
							_wtotC += (_sAliasQ) -> VALOR_TOTAL
					endcase	
				endif	           		
       		
			elseif (_sAliasQ) -> TIPO_NF = 'C' .and. mv_par01 >= '2019'
				do case
					case ALLTRIM((_sAliasQ) -> REGR_PAG) == "A"
						_wtotA += (_sAliasQ) -> VALOR_TOTAL
					case ALLTRIM((_sAliasQ) -> REGR_PAG) == "B"
						_wtotB += (_sAliasQ) -> VALOR_TOTAL
					case ALLTRIM((_sAliasQ) -> REGR_PAG) == "C"
						_wtotC += (_sAliasQ) -> VALOR_TOTAL
				endcase	
			endif
			li++
			// acumula total
			do case
				case (_sAliasQ) -> TIPO_NF = 'E'
					_aTot [1]   += (_sAliasQ) -> PESO_LIQ
					_aTot [2]   += (_sAliasQ) -> VALOR_TOTAL
				case (_sAliasQ) -> TIPO_NF = 'C'          
					_aTot [3]   += (_sAliasQ) -> PESO_LIQ
					_aTot [4]   += (_sAliasQ) -> VALOR_TOTAL
				case (_sAliasQ) -> TIPO_NF = 'A'			
					_aTot [5]   += (_sAliasQ) -> PESO_LIQ
					_aTot [6]   += (_sAliasQ) -> VALOR_TOTAL
				case (_sAliasQ) -> TIPO_NF = 'P'			
					_aTot [7]   += (_sAliasQ) -> PESO_LIQ
					_aTot [8]   += (_sAliasQ) -> VALOR_TOTAL            		
			endcase            		
					
			_aTotTp [1]   += (_sAliasQ) -> PESO_LIQ
			_aTotTp [2]   += (_sAliasQ) -> VALOR_TOTAL
			
			_vAnt       := (_sAliasQ) -> ASSOCIADO
			_VAntLj     := (_sAliasQ) -> LOJA_ASSOC
			_vAntnome   := (_sAliasQ) -> NOME_ASSOC
			
			_wtipoNFant := (_sAliasQ) -> TIPO_NF
			
			if (_sAliasQ) -> TIPO_NF != "E" .and. (_sAliasQ) -> FILIAL != '01'
				_wfilial = 'S'
			endif
			
			if (_sAliasQ) -> TIPO_NF = "A"
				_wcomplemento = 'S'
			endif
				
			(_sAliasQ) -> (dbskip())
			
		enddo

		IF _aTotTp[2] > 0
		// imprime por tipo de nota
		If li>63
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif        
		if _wtipoNFant = 'E'
			@li, 09 PSAY "Total NF's de ENTREGA de Uva"
		elseif _wtipoNFant = 'C'
			@li, 09 PSAY "Total NF's de COMPRA de Uva"
		elseif _wtipoNFant = 'A'
			@li, 09 PSAY "Total NF's de Complemento Vlr"
		elseif _wtipoNFant = 'P'
			@li, 09 PSAY "Total NF's de Produção Própria"
		endif
		@ li,  78 PSAY _aTotTp [1]  Picture "@E 9,999,999,999.99"
		@ li, 108 PSAY _aTotTp [2]  Picture "@E 9,999,999,999.99"
		li++
		li++
		Endif

	// imprime totais do associado
	If li+6 > 63
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif

	@ li, 00 PSAY "Totais do Associado: "
	@ li, 39 PSAY "Entrega"
	@ li, 78  PSAY _aTot [1]  Picture "@E 9,999,999,999.99"
	@ li,108 PSAY _aTot [2]  Picture "@E 9,999,999,999.99"
	li++
	@ li, 39 PSAY "Compra"
	@ li, 78 PSAY _aTot [3]  Picture "@E 9,999,999,999.99"
	@ li,108 PSAY _aTot [4]  Picture "@E 9,999,999,999.99"
	li++
	@ li, 39 PSAY "Compl.Vlr"
	@ li, 78 PSAY _aTot [5]  Picture "@E 9,999,999,999.99"
	@ li,108 PSAY _aTot [6]  Picture "@E 9,999,999,999.99"
	li++
	@ li, 39 PSAY "Total a Receber"
	@ li,108 PSAY (_aTot [4] + _aTot [6])  Picture "@E 9,999,999,999.99"
	li++
	li++
	li++

	// previsao de pagamento
	// le as variadades e monta valor das parcelas previstas
	If li+6 > 63
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif        
	
	if mv_par01 = '2017'
		@ li, 00 PSAY "Previsão de Pagamento: "
		@ li, 39 PSAY "Parcela A - ABRIL"
		@ li,108 PSAY _wtotA  Picture "@E 9,999,999,999.99"
		li++ 
		@ li, 39 PSAY "Parcela B - JULHO"
		@ li,108 PSAY _wtotB  Picture "@E 9,999,999,999.99"
		li++
		@ li, 39 PSAY "Parcela C - SETEMBRO"
		@ li,108 PSAY _wtotC  Picture "@E 9,999,999,999.99"
		li++
		@ li, 39 PSAY "Saldo Restante"
		@ li,108 PSAY _wsaldo  Picture "@E 9,999,999,999.99"
		li++
		@ li, 39 PSAY "Total"
		@ li,108 PSAY (_wtotA + _wtotB + _wtotC + _wsaldo)  Picture "@E 9,999,999,999.99"
		li++
		li++
		li++
	elseif mv_par01 >= '2018'
		_sQuery  = " "
		_sQuery += "SELECT E2_NUM, E2_VENCTO, E2_VALOR, E2_SALDO"
		_sQuery += "  FROM SE2010"
		_sQuery += " WHERE D_E_L_E_T_ = ''"
		_sQuery += "   AND E2_FILIAL  = '01'"
		_sQuery += "   AND E2_FORNECE = '" + _vant + "'"
		_sQuery += "   AND E2_LOJA    = '" + _vantlj + "'"
		_sQuery += "   AND E2_PREFIXO = '30'"
		_sQuery += "   AND ((E2_TIPO = 'FAT' AND E2_NUM like '" + mv_par01 + "%') OR (E2_TIPO IN ('NF', 'DP') AND E2_FATURA = ''))"
		_sQuery += "   AND E2_EMISSAO > '" + mv_par01 + "0301'"
		_sQuery += " ORDER BY E2_VENCTO, E2_NUM"
		//u_log (_sQuery)
		
		_aDados := U_Qry2Array(_sQuery)
		if len(_aDados) > 0
			@ li, 00 PSAY "Previsão de Pagamento: "
			//li++
			@ li, 39 PSAY "FATURA"  
			@ li, 60 PSAY "VENCIMENTO"
			@ li, 89 PSAY "VALOR"
			@ li,109 PSAY "SALDO"
			li++
			_wtotvlr = 0
			_wtotsld = 0
			for FAT=1 to len(_aDados)
				@ li, 39 PSAY _aDados[FAT,1]   
				@ li, 60 PSAY _aDados[FAT,2]
				@ li, 80 PSAY _aDados[FAT,3] Picture "@E 999,999,999.99"
				@ li,100 PSAY _aDados[FAT,4] Picture "@E 999,999,999.99"
				li++
				_wtotvlr = _wtotvlr + _aDados[FAT,3]
				_wtotsld = _wtotsld + _aDados[FAT,4]
			next
			@ li, 39 PSAY "Totais: "
			@ li, 80 PSAY _wtotvlr Picture "@E 999,999,999.99"
			@ li,100 PSAY _wtotsld Picture "@E 999,999,999.99"
			li++	
			li++		 
		endif	
	endif
		
	If li+3 > 63
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif        
		
	if mv_par01 = '2017'
		@ li, 00 PSAY "Regras Pagamento:"
		@ li, 39 PSAY "Parcela A = 100% Bordô, 100% Orgânicas, 50% Tintóreas, 50% Viníferas em espaldeira, 15% das demais variedades"
		li++
		@ li, 39 PSAY "Parcela B = 50% Tintóreas, 50% Viníferas em espaldeira, 22% das demais variedades, 100% do complemento de julho Bordô, Orgânicas, Tintóreas"
		li++
		@ li, 39 PSAY "Parcela C = 31,5% das demais variedades, 100% do complemento de julho Bordô, Orgânicas, Tintóreas"
		li++
		li++
		elseif mv_par01 >= '2018'
		@ li, 00 PSAY "Regras Pagamento"
		li++
		@ li, 39 PSAY "Grupo 1 - Bordo e Organicas                -  5 vezes"
		li++
		@ li, 39 PSAY "Grupo 2 - Tintorias e Viniferas espaldeira -  9 vezes"
		li++
		@ li, 39 PSAY "Grupo 3 - Demais Variedades                - 11 vezes"
		li++
	endif
			
	if _wcomplemento = 'S'
		_sQuery := " "
		_sQuery += "SELECT DISTINCT PRODUTO, DESCRICAO, GRAU, PESO_LIQ"
		_sQuery += "     ,   VUNIT_EFETIVO"
		_sQuery += "     , VALOR_COMPRA + VALOR_COMPLEMENTO AS VALOR_TOTAL"
		_sQuery += "  FROM VA_VPRECO_EFETIVO_SAFRA"
		_sQuery += " WHERE SAFRA      = '" + mv_par01 + "'"
		_sQuery += "   AND ASSOCIADO  = '" + _vAnt + "'"
		_sQuery += "   AND LOJA_ASSOC = '" + _VAntLj + "'"
		_sQuery += " ORDER BY DESCRICAO, GRAU"
		_aDados := U_Qry2Array(_sQuery)
		
		// lista valor efetivo por variedade/grau
		if len(_aDados)> 0
			li ++
			li++
			@li,  00 PSAY "Valor Efetivo por Variedade/Grau:"
			for i=1 to len(_aDados)
				If li + len(_aDados) > 63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif      
				@li,  31 PSAY ALLTRIM( _aDados [i,1])  + ' - ' + ALLTRIM(_aDados [i,2])
				@li,  72 PSAY _aDados [i,3] Picture "@E 99.99"
				@li,  81 PSAY _aDados [i,4] Picture "@E 9,999,999,999.99"
				@li,  98 PSAY _aDados [i,5] Picture "@E 9,999,999.99"
				@li, 108 PSAY _aDados [i,6] Picture "@E 9,999,999,999.99"
				li ++
			next
			li ++
		endif
	endif
	
	// imprime saldo conta corrente
	if mv_par05 == 1
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SZI.ZI_DATA, ZI_TM, ZI_DOC, ZI_HISTOR, ZX5_10DC, ZI_SALDO"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI, "
		_oSQL:_sQuery +=             RETSQLNAME ("ZX5") + " ZX5 "
		_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_FILIAL  = '" + xfilial ("ZX5")  + "'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_TABELA  = '10'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_10COD   = SZI.ZI_TM"
		_oSQL:_sQuery +=   " AND SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   BETWEEN '  ' and 'zz'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + _vAnt + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + _vAntLj + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_TM       NOT IN ('10/17/18/19')"
		_oSQL:_sQuery +=   " AND SZI.ZI_DATA     like '" + mv_par01 + "%'"
		_oSQL:_sQuery +=   " AND SZI.ZI_SALDO    > 0"
		_oSQL:_sQuery += " ORDER BY ZI_DATA, ZI_TM, ZI_FILIAL, ZI_HISTOR, ZI_SERIE, ZI_DOC, ZI_PARCELA"
		//u_log (_oSQL:_sQuery)
		_aSld := aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aSld) > 0
			_wsaldo := 0
			li ++
			// @li,  00 PSAY "Lctos Conta Corrente:"
			@li,  00 PSAY "Lctos Aberto Conta Corrente:"
			for i=1 to len (_aSld)
				_wdata  = stod (_aSld [i,1])
				_wtpmov = _aSld [i,2]
				_wdoc   = _aSld [i,3]
				_whist  = substr(_aSld [i,4],1,80)
				_wdc    = _aSld [i,5]
				_wvalor = _aSld [i,6]
				
				If li > 63
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif  
					
				@li,  39 PSAY _wdata
				@li,  55 PSAY _wtpmov 
				@li,  60 PSAY _wdoc + '-' + _whist
				@li, 155 PSAY _wvalor Picture "@E 9,999,999,999.99"
				@li, 172 PSAY _wdc
				li ++
				if _wdc = "C"
					_wsaldo += _wvalor
				else
					_wsaldo -= _wvalor
				endif																																																		
			next
			@li,  60 PSAY "SALDO"
			@li, 155 PSAY _wsaldo Picture "@E 9,999,999,999.99"
			if _wsaldo > 0
				@li, 172 PSAY "C"
			else
				@li, 172 PSAY "D"
			endif
			
			li ++
		endif
	endif		
return



// --------------------------------------------------------------------------
// Modelo a partir da safra 2020, onde busca dados da classe ClsAssoc para
// manter consistencia web service que atende APP de associados.
static function _Modelo2 (_lSohCompr)
	local _aAssoc    := {}
	local _nAssoc    := 0
	local _oAssoc    := NIL
	local _oSQL      := NIL
	local _sXmlFech  := ''
	local _sError    := ''
	local _sWarning  := ''
	local _nNota     := 0
	local _nFatPag   := 0
	local _nRegraPag := 0
	local _nVlEfetiv := 0
	local _nLctoCC   := 0
	local _sLinImp   := ''
	local _sNFFilial := ''
	local _sNFDoc    := ''
	local _sNFEmis   := ''
	local _sNFProd   := ''
	local _sNFDescr  := ''
	local _sNFGrau   := ''
	local _sNFClas   := ''
	local _nNFPeso   := 0
	local _nNFVUnit  := 0
	local _nNFVTot   := 0
	local _sNFObs    := ''
	private _aTAsEnt   := {}  // Totais (qt/valor) de notas de entrada (associado)
	private _aTAsPro   := {}  // Totais (qt/valor) de notas de producao propria (associado)
	private _aTAsCom   := {}  // Totais (qt/valor) de notas de compra (associado)
	private _aTAsCpl   := {}  // Totais (qt/valor) de notas de complemento (associado)
	private _aTGerEnt  := {}  // Totais (qt/valor) de notas de entrada (geral)
	private _aTGerPro  := {}  // Totais (qt/valor) de notas de producao propria (geral)
	private _aTGerCom  := {}  // Totais (qt/valor) de notas de compra (geral)
	private _aTGerCpl  := {}  // Totais (qt/valor) de notas de complemento (geral)
	private _sMascPeso := "@E 9,999,999,999"
	private _sMascVUni := "@E 9,999.9999"
	private _sMascVTot := "@E 9,999,999,999.99"
	private _oXMLFech  := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.

	// Variaveis padrao para relatorios.
	private nTipo    := IIF(aReturn[4]==1,15,18)
	private li       := 80
	private m_pag    := 1
	private cabec1   := "FILIAL  NF/SERIE   DT EMISSAO  PRODUTO    DESCRICAO                                 GRAU/CLAS        PESO    VLR UNIT        VLR TOTAL  OBSERVACOES"
	private cabec2   := ""
	private _nMaxLin := 68
	li = _nMaxLin + 1

	_aTGerEnt := {0, 0}
	_aTGerPro := {0, 0}
	_aTGerCom := {0, 0}
	_aTGerCpl := {0, 0}

	// Gera lista de associados a imprimir.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery += "SELECT DISTINCT ASSOCIADO, LOJA_ASSOC, NOME_ASSOC"
	_oSQL:_sQuery += "  FROM VA_VNOTAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA      = '" + mv_par01 + "'"
	if ! empty (mv_par02)
		_oSQL:_sQuery += "   AND ASSOCIADO  = '" + mv_par02 + "'"
		_oSQL:_sQuery += "   AND LOJA_ASSOC = '" + mv_par03 + "'"
	endif
	_oSQL:_sQuery += " ORDER BY NOME_ASSOC"
	_oSQL:Log ()
	_aAssoc = _oSQL:Qry2Array ()

	procRegua (len (_aAssoc))

	for _nAssoc = 1 to len (_aAssoc)
		incproc (_aAssoc [_nAssoc, 3])
		U_LOG (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2])

		// Instancia objeto 'associado' para gerar seu fechamento de safra.
		_oAssoc := ClsAssoc ():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2])
		if valtype (_oAssoc) != 'O'
			u_help ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados: ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2],, .t.)
			loop
		endif

		// Filtra por nucleo do associado
		if ! empty (mv_par04) .and. _oAssoc:Nucleo != mv_par04
			u_log ('outro nucleo', _oAssoc:Nucleo)
			loop
		endif

		// Busca dados do fechamento de safra. Usa mesmo o metodo do APP associados.
		//                                  _sSafra, _lFSNFE, _lFSNFC, _lFSNFV, _lFSNFP, _lFSPrPg, _lFSRgPg, _lFSVlEf, _lFSResV, _lFSFrtS, _lFSLcCC
		if _lSohCompr
			_sXmlFech = _oAssoc:FechSafra (mv_par01, .f.,     .t.,     .f.,     .f.,     .f.,      .f.,      .f.,      .f.,      .f.,      .f.)
		else
			_sXmlFech = _oAssoc:FechSafra (mv_par01, .t.,     .t.,     .t.,     .t.,     .t.,      .t.,      .t.,      .t.,      .t.,      .t.)
		endif
		//	u_log2 ('debug', _sXmlFech)
		if empty (_sXmlFech)
			u_help ("Associado ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2] + ": Retorno vazio metodo FechSafra " + _oAssoc:UltMsg,, .t.)
			loop
		endif

		// Converte de texto para XML
		_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
		if ! empty (_sError) .or. ! empty (_sWarning)
			u_help ("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
			loop
		endif

		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 00 PSAY "Associado: " + _oAssoc:Codigo + '-' + _oAssoc:Loja + ' ' + _oAssoc:Nome
		li += 2

		_aTAsEnt := {0, 0}
		_aTAsPro := {0, 0}
		_aTAsCom := {0, 0}
		_aTAsCpl := {0, 0}

		// Verifica se tem este tipo de nota no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem')
		//if type ('_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem') == 'A'  // Array com mais de uma nota
		If _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 09 PSAY "NF's de ENTREGA de Uva"
			li ++
			for _nNota = 1 to len (_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem)
				_sNFFilial = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_filial:TEXT
				_sNFDoc    = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_doc:TEXT
				_sNFEmis   = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_emissao:TEXT
				_sNFProd   = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_varied:TEXT
				_sNFDescr  = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_desc:TEXT
				_sNFGrau   = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_grau:TEXT
				_sNFClas   = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_clas:TEXT
				_nNFPeso   = val (_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_peso:TEXT)
				_nNFVUnit  = val (_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_valunit:TEXT)
				_nNFVTot   = val (_oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_valtot:TEXT)
				_sNFObs    = _oXMLFech:_assocFechSafra:_nfEntrada:_nfEntradaItem[_nNota]:_obs:TEXT
				_ImprNota ('E', _sNFFilial, _sNFDoc, _sNFEmis, _sNFProd, _sNFDescr, _sNFGrau, _sNFClas, _nNFPeso, _nNFVUnit, _nNFVTot, _sNFObs)
				li ++
			next
			li ++
		endif
		

		// Verifica se tem este tipo de nota no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 09 PSAY "NF's de PRODUCAO PROPRIA de Uva"
			li ++
			for _nNota = 1 to len (_oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem)
				_sNFFilial = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_filial:TEXT
				_sNFDoc    = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_doc:TEXT
				_sNFEmis   = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_emissao:TEXT
				_sNFProd   = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_varied:TEXT
				_sNFDescr  = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_desc:TEXT
				_sNFGrau   = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_grau:TEXT
				_sNFClas   = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_clas:TEXT
				_nNFPeso   = val (_oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_peso:TEXT)
				_nNFVUnit  = val (_oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_valunit:TEXT)
				_nNFVTot   = val (_oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_valtot:TEXT)
				_sNFObs    = _oXMLFech:_assocFechSafra:_nfProdPropria:_nfProdPropriaItem[_nNota]:_obs:TEXT
				_ImprNota ('P', _sNFFilial, _sNFDoc, _sNFEmis, _sNFProd, _sNFDescr, _sNFGrau, _sNFClas, _nNFPeso, _nNFVUnit, _nNFVTot, _sNFObs)
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de nota no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 09 PSAY "NF's de COMPRA de Uva"
			li ++
			for _nNota = 1 to len (_oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem)
				_sNFFilial = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_filial:TEXT
				_sNFDoc    = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_doc:TEXT
				_sNFEmis   = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_emissao:TEXT
				_sNFProd   = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_varied:TEXT
				_sNFDescr  = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_desc:TEXT
				_sNFGrau   = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_grau:TEXT
				_sNFClas   = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_clas:TEXT
				_nNFPeso   = val (_oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_peso:TEXT)
				_nNFVUnit  = val (_oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_valunit:TEXT)
				_nNFVTot   = val (_oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_valtot:TEXT)
				_sNFObs    = _oXMLFech:_assocFechSafra:_nfCompra:_nfCompraItem[_nNota]:_obs:TEXT
				_ImprNota ('C', _sNFFilial, _sNFDoc, _sNFEmis, _sNFProd, _sNFDescr, _sNFGrau, _sNFClas, _nNFPeso, _nNFVUnit, _nNFVTot, _sNFObs)
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de nota no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 09 PSAY "NF's de COMPLEMENTO Vlr"
			li ++
			for _nNota = 1 to len (_oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem)
				_sNFFilial = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_filial:TEXT
				_sNFDoc    = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_doc:TEXT
				_sNFEmis   = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_emissao:TEXT
				_sNFProd   = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_varied:TEXT
				_sNFDescr  = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_desc:TEXT
				_sNFGrau   = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_grau:TEXT
				_sNFClas   = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_clas:TEXT
				_nNFPeso   = val (_oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_peso:TEXT)
				_nNFVUnit  = val (_oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_valunit:TEXT)
				_nNFVTot   = val (_oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_valtot:TEXT)
				_sNFObs    = _oXMLFech:_assocFechSafra:_nfComplemento:_nfComplementoItem[_nNota]:_obs:TEXT
				_ImprNota ('V', _sNFFilial, _sNFDoc, _sNFEmis, _sNFProd, _sNFDescr, _sNFGrau, _sNFClas, _nNFPeso, _nNFVUnit, _nNFVTot, _sNFObs)
				li ++
			next
			li ++
		endif


		// Imprime totais do associado por tipo de nota.
		if ! _lSohCompr
			li ++
			_ImprTot ('Totais do associado', _aTAsEnt, _aTAsPro, _aTAsCom, _aTAsCpl)
			li ++
		endif

		// Acumula totais gerais
		_aTGerEnt [1] += _aTAsEnt [1]
		_aTGerEnt [2] += _aTAsEnt [2]
		_aTGerPro [1] += _aTAsPro [1]
		_aTGerPro [2] += _aTAsPro [2]
		_aTGerCom [1] += _aTAsCom [1]
		_aTGerCom [2] += _aTAsCom [2]
		_aTGerCpl [1] += _aTAsCpl [1]
		_aTGerCpl [2] += _aTAsCpl [2]


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem') 
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Previsao de pagamento:                FATURA             VENCIMENTO              VALOR              SALDO  HISTORICO'
			li ++
			for _nFatPag = 1 to len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_sLinImp := ''
				if _oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT != 'TOTAIS'
					_sLinImp += space (35)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT, 15) + '       '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_vencto:TEXT, 10) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT), _sMascVTot) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT), _sMascVTot) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_hist:TEXT, 110) + '  '
				else
					@ li, 0 psay space (74) + '------------       ------------'
					li ++
					_sLinImp += space (70)
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT), _sMascVTot) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT), _sMascVTot) + '  '
				endif
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem')
		if _ValType == 'A'  // Enquanto tivermos mais de um grupo de pagamentos, vai funcionar...
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Regras para pagamento:'
			li ++
			for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_sLinImp := space (35)
				_sLinImp += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Valores efetivos:                                GRAU/CLAS              PESO    VLR UNIT         VLR TOTAL'
			li ++
			for _nVlEfetiv = 1 to len (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_sLinImp := space (7)
				_sLinImp += U_TamFixo (ALLTRIM(_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_varied:TEXT) + ' - ' + alltrim (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_desc:TEXT), 40, ' ') + '  '
				_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_grau:TEXT, 4) + '  '
				_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasLatada:TEXT, 2) + '  '
				_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasEspaldeira:TEXT, 2) + '  '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_peso:TEXT), _sMascPeso) + '  '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valunit:TEXT), _sMascVUni) + '  '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valtot:TEXT), _sMascVTot) + '  '
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 titulo + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			li ++
			@li, 0 PSAY 'Auxilio combustivel:                  TITULO             VENCIMENTO              VALOR              SALDO  HISTORICO'
			li ++
			for _nFatPag = 1 to len (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_sLinImp := ''
				if _oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_doc:TEXT != 'TOTAIS'
					_sLinImp += space (35)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_doc:TEXT, 15) + '       '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_vencto:TEXT, 10) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_valor:TEXT), _sMascVTot) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_saldo:TEXT), _sMascVTot) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_hist:TEXT, 110) + '  '
				else
					@ li, 0 psay space (74) + '------------       ------------'
					li ++
					_sLinImp += space (70)
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_valor:TEXT), _sMascVTot) + '   '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_saldo:TEXT), _sMascVTot) + '  '
				endif
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			// @li, 0 PSAY 'Lctos conta corrente:'
			@li, 0 PSAY 'Lctos em aberto na conta corrente:'
			li ++
			for _nLctoCC = 1 to len (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				if _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT != 'TOTAIS'
					_sLinImp := space (9)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dtMovto:TEXT, 10) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT, 15) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_hist:TEXT, 50) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT), '@E 999,999,999.99') + ' '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dc:TEXT, 1)
				else
					@ li, 0 psay space (90) + '--------------'
					li ++
					_sLinImp := space (90) + transform (val (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT), '@E 999,999,999.99')
				endif
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif
	next

	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	_ImprTot ('TOTAIS GERAIS', _aTGerEnt, _aTGerPro, _aTGerCom, _aTGerCpl)
	li ++
return



// --------------------------------------------------------------------------
// Imprime valores de contranotas formatados.
static function _ImprNota (_sTipoNota, _sNFFilial, _sNFDoc, _sNFEmis, _sNFProd, _sNFDescr, _sNFGrau, _sNFClas, _nNFPeso, _nNFVUnit, _nNFVTot, _sNFObs)
	local _sLinImp := ''

	If li > _nMaxLin
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	if _sNFDoc != 'TOTAIS'
		_sLinImp += '  ' + U_TamFixo (_sNFFilial, 2) + '    '
		_sLinImp += U_TamFixo (_sNFDoc, 9) + '  '
		_sLinImp += U_TamFixo (_sNFEmis, 10) + '  '
		_sLinImp += U_TamFixo (_sNFProd, 10) + ' '
		_sLinImp += U_TamFixo (_sNFDescr, 40) + '  '
		_sLinImp += U_TamFixo (_sNFGrau, 4) + ' '
		_sLinImp += U_TamFixo (_sNFClas, 2) + ' '
		_sLinImp += transform (_nNFPeso, _sMascPeso) + '  '
		_sLinImp += transform (_nNFVUnit, _sMascVUni) + ' '
		_sLinImp += transform (_nNFVTot, _sMascVTot) + '  '
		_sLinImp += U_TamFixo (_sNFObs, 90)
	else
		@ li, 0 psay space (93) + '------------              ---------------'
		li ++
		_sLinImp += space (92)
		_sLinImp += transform (_nNFPeso, _sMascPeso) + '  '
		_sLinImp += space (11)
		_sLinImp += transform (_nNFVTot, _sMascVTot) + '  '
		if _sTipoNota == 'E'
			_aTAsEnt [1] += _nNFPeso
			_aTAsEnt [2] += _nNFVTot
		elseif _sTipoNota == 'P'
			_aTAsPro [1] += _nNFPeso
			_aTAsPro [2] += _nNFVTot
		elseif _sTipoNota == 'C'
			_aTAsCom [1] += _nNFPeso
			_aTAsCom [2] += _nNFVTot
		elseif _sTipoNota == 'V'
			_aTAsCpl [1] += _nNFPeso
			_aTAsCpl [2] += _nNFVTot
		endif
	endif
	@ li, 0 psay _sLinImp
return



// --------------------------------------------------------------------------
// Imprime totais (por associado ou gerais) formatados.
static function _ImprTot (_sTitTot, _aEntradas, _aPropria, _aCompra, _aComplem)
	If li > _nMaxLin - 4
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	@ li, 0 psay U_TamFixo (_sTitTot, 72, ' ') + 'Entrega          ' + transform (_aEntradas [1], "@E 9,999,999,999.99") + '             ' + transform (_aEntradas [2], "@E 9,999,999,999.99")
	li ++
	// Lista somente se tiver dados, pois somente as filiais possuem producao propria (salvo alguma negociacao muito especifica com associado)
	if _aPropria [1] != 0 .or. _aPropria [2] != 0
		@ li, 0 psay space (72) + 'Producao propria ' + transform (_aPropria [1], "@E 9,999,999,999.99") + '             ' + transform (_aPropria [2], "@E 9,999,999,999.99")
		li ++
	endif
	@ li, 0 psay space (72) + 'Compra           ' + transform (_aCompra [1], "@E 9,999,999,999.99") + '             ' + transform (_aCompra [2], "@E 9,999,999,999.99")
	li ++
	@ li, 0 psay space (72) + 'Compl.Vlr        ' + transform (_aComplem [1], "@E 9,999,999,999.99") + '             ' + transform (_aComplem [2], "@E 9,999,999,999.99")
	li ++
	@ li, 0 psay space (72) + 'Total a receber                               ' + transform (_aCompra [2] + _aComplem [2], "@E 9,999,999,999.99")
	li += 2
Return



// --------------------------------------------------------------------------
// Retorno do type - type em looling nao é permitido da R25 
Static Function _RetType(_var)
	_type := type(_var)
Return _type



// --------------------------------------------------------------------------
// Modelo (resumido) a partir da safra 2020, onde busca dados da classe ClsAssoc para
// manter consistencia web service que atende APP de associados.
static function _Modelo3 (_lSohCompr)
	local _aAssoc    := {}
	local _nAssoc    := 0
	local _oAssoc    := NIL
	local _oSQL      := NIL
	local _sXmlFech  := ''
	local _sError    := ''
	local _sWarning  := ''
	local _sLinImp   := ''
	local _nVaried   := 0
	local _aResPag   := {}
	local _nResPag   := 0
	local _nFatPag   := 0
//	local _aTotResV  := {}
	local _aTotResP  := {}
	local _nRegraPag := 0
	local _nLctoCC   := 0
	local _sMesPagto := ''
	local _nTotDesc  := 0
	private _sMascPeso := "@E 9,999,999,999"
	private _sMascVUni := "@E 9,999.9999"
	private _sMascVTot := "@E 9,999,999,999.99"
	private _oXMLFech  := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.

	// Variaveis padrao para relatorios.
	private nTipo    := IIF(aReturn[4]==1,15,18)
	private li       := 80
	private m_pag    := 1
	private cabec1   := ""
	private cabec2   := ""
	private _nMaxLin := 68
	li = _nMaxLin + 1

	// Gera lista de associados a imprimir.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery += "SELECT DISTINCT ASSOCIADO, LOJA_ASSOC, NOME_ASSOC"
	_oSQL:_sQuery += "  FROM VA_VNOTAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA      = '" + mv_par01 + "'"
	if ! empty (mv_par02)
		_oSQL:_sQuery += "   AND ASSOCIADO  = '" + mv_par02 + "'"
		_oSQL:_sQuery += "   AND LOJA_ASSOC = '" + mv_par03 + "'"
	endif
	_oSQL:_sQuery += " ORDER BY NOME_ASSOC"
	_oSQL:Log ()
	_aAssoc = _oSQL:Qry2Array ()

	procRegua (len (_aAssoc))

	for _nAssoc = 1 to len (_aAssoc)
		incproc (_aAssoc [_nAssoc, 3])
		U_LOG2 ('debug', 'assoc: ' + _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2])

		// Instancia objeto 'associado' para gerar seu fechamento de safra.
		_oAssoc := ClsAssoc ():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2])
		if valtype (_oAssoc) != 'O'
			u_help ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados: ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2],, .t.)
			loop
		endif

		// Filtra por nucleo do associado
		if ! empty (mv_par04) .and. _oAssoc:Nucleo != mv_par04
			u_log ('outro nucleo', _oAssoc:Nucleo)
			loop
		endif

		// Busca dados do fechamento de safra. Usa mesmo o metodo do APP associados.
		//                                  _sSafra, _lFSNFE, _lFSNFC, _lFSNFV, _lFSNFP, _lFSPrPg, _lFSRgPg, _lFSVlEf, _lFSResV, _lFSFrtS, _lFSLcCC
		if _lSohCompr
			_sXmlFech = _oAssoc:FechSafra (mv_par01, .f.,     .t.,     .f.,     .f.,     .f.,      .t.,      .f.,      .f.,      .f.,      .f.)
		else
			_sXmlFech = _oAssoc:FechSafra (mv_par01, .t.,     .t.,     .t.,     .t.,     .t.,      .t.,      .t.,      .t.,      .t.,      .t.)
		endif
		u_log2 ('debug', _sXmlFech)
		if empty (_sXmlFech)
			u_help ("Associado ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2] + ": Retorno vazio metodo FechSafra " + _oAssoc:UltMsg,, .t.)
			loop
		endif

		// Converte de texto para XML
		_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
		if ! empty (_sError) .or. ! empty (_sWarning)
			u_help ("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
			loop
		endif

		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 00 PSAY "Associado: " + _oAssoc:Codigo + '-' + _oAssoc:Loja + ' ' + _oAssoc:Nome
		li += 2

		// Verifica se tem este tipo de nota no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem')
		u_log2 ('debug', _ValType)
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 nota + 1 linha de totais)
			@ li, 0 psay 'Producao:              Codigo          Variedade                           Kg total  Grau medio   Vlr.medio        Vlr.total'
			li ++
//			_aTotResV = {0, 0}
			for _nVaried = 1 to len (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem)
				If li > _nMaxLin - 4
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				if _oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_varied:TEXT != 'TOTAIS'
					_sLinImp = space (23)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_varied:TEXT, 15) + ' '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_desc:TEXT, 30) + ' '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_peso:TEXT), _sMascPeso) + '       '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_grauMedio:TEXT), '@E 999.9') + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_valMedio:TEXT), _sMascVUni) + ' '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_valTotal:TEXT), _sMascVTot)
					@ li, 0 psay _sLinImp
					li ++
				else
					@ li, 0 psay '                                                                     --------------                            -------------'
					li ++
					@ li, 0 psay '                                                                      ' + transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_peso:TEXT), _sMascPeso) + '                         ' + transform (val (_oXMLFech:_assocFechSafra:_resumoVariedade:_resumoVariedadeItem[_nVaried]:_valTotal:TEXT), _sMascVTot)
					li += 2
				endif
			next
		endif


		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem') 
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 nota/fatura + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Resumo pagamento:      Mes/ano                 Valor             Saldo'
			li ++
			// Monta array resumida, acumulando os pagamentos de cada mes. Nao posso aproveitar a linha
			// de totais que vem no XML por que vou agrupar as faturas por mes.
			_aResPag = {}
			for _nFatPag = 1 to len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem)
				if _oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT != 'TOTAIS'
					_sMesPagto = substr (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_vencto:TEXT, 4)
					_nResPag = ascan (_aResPag, {|_aVal| _aVal [1] == _sMesPagto})
					if _nResPag == 0
						aadd (_aResPag, {_sMesPagto, 0, 0})
						_nResPag = len (_aResPag)
					endif
					_aResPag [_nResPag, 2] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT)
					_aResPag [_nResPag, 3] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT)
				endif
			next

//			u_log2 ('debug', _aResPag)
			_aTotResP = {0, 0}
			for _nResPag = 1 to len (_aResPag)
				If li > _nMaxLin - 4
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				_sLinImp = space (23)
				_sLinImp += _aResPag [_nResPag, 1] + '      '
				_sLinImp += transform (_aResPag [_nResPag, 2], _sMascVTot) + '  '
				_sLinImp += transform (_aResPag [_nResPag, 3], _sMascVTot)
				_aTotResP [1] += _aResPag [_nResPag, 2]
				_aTotResP [2] += _aResPag [_nResPag, 3]
				@ li, 0 psay _sLinImp
				li ++
			next
			@ li, 0 psay '                                      --------------    --------------'
			li ++
			@ li, 0 psay '                                    ' + transform (_aTotResP [1], _sMascVTot) + '  ' + transform (_aTotResP [2], _sMascVTot)
			li += 2
		endif

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem')
		if _ValType == 'A'  // Enquanto tivermos mais de um grupo de pagamentos, vai funcionar...
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Regras para pagamento:'
			li ++
			for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				_sLinImp := space (35)
				_sLinImp += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT
				@ li, 0 psay _sLinImp
				li ++
			next
			li ++
		endif

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Descontos em aberto:   Data        Historico                                                    Saldo'
			li ++
			_nTotDesc = 0
			for _nLctoCC = 1 to len (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem)
				If li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				if _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT != 'TOTAIS' .and. _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dc:TEXT == 'D'
					_sLinImp := space (23)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dtMovto:TEXT, 10) + '  '
					//_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT, 15) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_hist:TEXT, 50) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT), '@E 999,999,999.99') + ' '

					// Nao posso aproveitar a linha de totais que vem no XML por que acumula debitos
					// e creditos, e neste momento quero apenas os debitos.
					_nTotDesc += val (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT)
					@ li, 0 psay _sLinImp
					li ++
				endif
			next
			@ li, 0 psay '                                                                                       --------------'
			li ++
			@ li, 0 psay '                                                                                     ' + transform (_nTotDesc, _sMascVTot)
			li += 2
		endif

	next
return

//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {02, "Associado                     ", "C", 6,  0,  "",   "SA2", {},                        ""})
	aadd (_aRegsPerg, {03, "Loja                          ", "C", 2,  0,  "",   "",    {},                        ""})
	aadd (_aRegsPerg, {04, "Nucleo                        ", "C", 2,  0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {05, "Lista Saldo C/C               ", "N", 1,  0,  "",   "   ", {"Sim", "Não"}           , ""})	
//	aadd (_aRegsPerg, {06, "Detalhado ou resumido         ", "N", 1,  0,  "",   "   ", {"Det.COM prev.pg", "Det.SEM prev.pg", "Res.COM prev.pg", "Res.SEM prev.pg", "Apenas NF compra"}, ""})
	aadd (_aRegsPerg, {06, "Detalhado ou resumido         ", "N", 1,  0,  "",   "   ", {"Detalhado", "Resumido", "Apenas NF compra"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
