// Programa..: ML_FECHASAFRA
// Autor.....: Catia Cardoso
// Data......: 25/04/2017
// Nota......: Relatorio Fechamento de Safra
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio Fechamento de Safra
// #PalavasChave      #fechamento_de_safra 
// #TabelasPrincipais #VA_VNOTAS_SAFRA #SE2 #VA_VPRECO_EFETIVO_SAFRA
// #Modulos           #FAT
//
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
// 08/03/2021 - Robert  - Resumo por variedade/grau medio passa a listar graus abertos (GLPI 9572)
//                      - Novos parametros metodo ClsAssoc:FechSafra()
// 28/07/2021 - Sandra  - Incluso rodapé com nomenclatura 'Documento Sigiloso" GLPI 10139
// 30/07/2021 - Robert  - Valores efetivos por variedade, na opcao resumido, nao tinha coluna de valor unitario (GLPI 10625)
// 27/02/2022 - Robert  - Melhoria coluna historico nas previsoes de pagamento (GLPI 11678)
// 15/06/2022 - Robert  - Impressao de descontos de FUNRURAL (GLPI 11723).
// 11/04/2023 - Robert  - Passa a listar aux.combustivel/frete no modelo resumido, para facilitar fechto.valores.
// 14/04/2023 - Robert  - Em versoes anteriores a 2020, listava titulos futuros na previsao de pagamento.
// 02/06/2023 - Robert  - Modelo resumido passa a listar tags do <valoresEfetivos> em vez de <resumoVarGrauClas> - GLPI 13532
// 21/07/2023 - Robert  - Nova forma de parametrizacao (via atributos) do metodo ClsAssoc:FechSafra() - GLPI 13956
// 05/08/2023 - Robert  - Removido parametro de filtragem por 'nucleo' do associado.
//                      - Removidas opcoes 'detalhado' e 'somente NF compra'
// 29/09/2023 - Robert  - Implementado modelo4 em 132 colunas, mostrando descontos (GLPI 9561)
// 04/12/2023 - Robert  - Ajustes titulos colunas no modelo 132 colunas
// 12/03/2024 - Robert  - Removida opcao de "nao mostrar pagtos e compensacoes" por que calculava o saldo errado.
// 11/07/2024 - Claudia - Criada a chamada para relatorio de fechamento de safra não associados. GLPI: 15699
//
// ----------------------------------------------------------------------------------------------------------------
#include "protheus.ch"
#INCLUDE "XMLXFUN.CH"

User Function ML_FECHASAFRA(_lAutomat)
	local _sArqOrig := ''
	local _sArqDest := ''
	local _lCont    := .T.
	private _lAuto  := iif(valtype(_lAutomat) == "L", _lAutomat, .F.)

	cString := "SD2"
	cDesc1  := "Fechamento Safra"
	cDesc2  := " "
	cDesc3  := " "
	tamanho := "G"
	limite  := 220
	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha  := {}
	nLastKey:= 0
	titulo  := "Fechamento Safra"
	cPerg   := "ML_FECHASA"
	wnrel   := "ML_FECHASAFRA"
	nTipo   := 0

	U_Log2('debug', '[' + procname () + ']teste')

	_nModelo =  aviso("Modelo de relatórios de safra" ;
						, "O relatório de safra possui modelo para associados e para não associados (fornecedores)" ;
						, { "Não Associados","Associados"} ;
						, 2 ;
						, "Selecione o modelo de relatório de safra")
	
	do case
	
		case _nModelo == 1
			U_VA_SAFFOR()

		case _nModelo == 2 
			_ValidPerg()
			Pergunte(cPerg, .t.)

			_oAssoc := ClsAssoc():New (mv_par02, mv_par03)	
			if _oAssoc:EhSocio(dDataBase)
				_lCont := .T.
			else
				_lCont := .F.
				u_help("O fornecedor selecionado NÃO é sócio. Deve-se imprimir o modelo de relatório <Não Associados>")
			endif

			if _lCont
				if ! _lAuto
					Pergunte(cPerg, .t.)
					if mv_par01 >= '2023'
						tamanho := "M"
						limite  := 132
					endif
					wnrel  := SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
				else
					if mv_par01 >= '2023'
						tamanho := "M"
						limite  := 132
					endif
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

				titulo := "Fechamento Safra " + mv_par01

				// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
				delete file (__reldir + wnrel + ".##r")

				SetDefault(aReturn,cString)
				If nLastKey == 27
					Return
				Endif

				u_logSX1 (cPerg)

				if mv_par01 < '2020'  // Metodo original
					processa ({|| RptDetail ()})
				else  // Busca da classe ClsAssoc.
					if mv_par01 < '2023'
						processa({|| _Modelo3()})
					else
						processa({|| _Modelo4()})
					endif
				endif

				Set Printer TO
				MS_FLUSH()
				DbCommitAll()
				MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

				if ! _lAuto
					If aReturn [5] == 1
						ourspool(wnrel)
					Endif
				else
					// Copia para arquivo com nome diferente por que eh comum
					// eu precisar gerar de varios associados para conferencia.
					_sArqOrig := alltrim(wnrel) + '.##r'
					_sArqDest := alltrim(wnrel) + "_" + alltrim(mv_par01) + '_' + alltrim(mv_par02) + alltrim(mv_par03) 
					_sArqDest += '.##r'
					copy file (__reldir + _sArqOrig) to (__reldir + _sArqDest)
				endif
			endif

		otherwise
			u_help("Modelo sem tratamento",, .t.)
	endcase

Return
//
// --------------------------------------------------------------------------
// Modelo original
Static Function RptDetail()
	local _oSQL   := NIL
	local FAT	  := 0
	local i		  := 0

	U_Log2('debug', 'Gerando rel.fechto.safra pela funcao ' + procname ())

	procRegua(800)
	nTipo := IIF(aReturn[4]==1,15,18)
	li    := 80
	m_pag := 1

	IF m_pag >1
		_roda()
	endif

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
	U_Log2('debug', '[' + procname() + ']' + _sQuery)

	// imprime relatorio
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry(,, _sQuery), _sAliasQ, .f., .t.)
	count to _nRecCount
	procregua(_nRecCount)

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
	(_sAliasQ) -> (DBGoTop())
	Do While ! (_sAliasQ) -> (Eof())

		IF _vAnt + _VAntLj  != (_sAliasQ) -> ASSOCIADO + (_sAliasQ) -> LOJA_ASSOC
			IF _aTotTp[2] = 0
				If li>63
				IF m_pag >1
					_roda()
				endif
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif

				@ li, 00 PSAY "Associado: " + (_sAliasQ) -> ASSOCIADO + '-' + ALLTRIM((_sAliasQ) -> LOJA_ASSOC) + ' ' + ALLTRIM((_sAliasQ) -> NOME_ASSOC)
				li ++ 
				li ++
			endif			   	 
			if _aTotTp[2] > 0
				// imprime por tipo de nota
					
				If li>63
				IF m_pag >1
					_roda()
				endif
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
				IF m_pag >1
					_roda()
				endif
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
				IF m_pag >1
					_roda()
				endif
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

					// Robert, 14/04/2023
					// Fatura para pagamento pode ainda ser gerada em janeiro do ano seguinte (GLPI 9558).
					_sQuery +=   " AND (E2_EMISSAO <= '" + mv_par01 + "1231' OR (E2_EMISSAO <= '" + Soma1 (mv_par01) + "0131' AND E2_TIPO = 'FAT'))"

					_sQuery += " ORDER BY E2_VENCTO, E2_NUM"
					U_Log2('debug', '[' + procname() + ']' + _sQuery)
					
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
				IF m_pag >1
					_roda()
				endif
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

							IF m_pag >1
								_roda()
							endif

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
				if mv_par04 == 1
					_oSQL := ClsSQL():New()
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
					_aSld := aclone(_oSQL:Qry2Array (.F., .F.))
					
					if len(_aSld) > 0
						li ++
						_wsaldo := 0
						@li,  00 PSAY "Lctos Aberto Conta Corrente:"
						for i=1 to len(_aSld)
							_wdata  = stod (_aSld [i,1])
							_wtpmov = _aSld [i,2]
							_wdoc   = _aSld [i,3]
							_whist  = substr(_aSld [i,4],1,80)
							_wdc    = _aSld [i,5]
							_wvalor = _aSld [i,6]
				
							If li>63
							IF m_pag >1
								_roda()
							endif

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
					IF m_pag >1
						_roda()
					endif
						cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
						li ++
						@ li, 00 PSAY "Associado: " + (_sAliasQ) -> ASSOCIADO + '-' + ALLTRIM((_sAliasQ) -> NOME_ASSOC)
						li ++ 
						li ++
						
						_aTot         = {0,0,0,0,0,0,0,0}
						_aTotTp       = {0,0,0,0,0,0,0,0}
						_wtotA        := 0
						_wtotB        := 0
						_wtotC        := 0
						_wvlrA		  := 0
						_wvlrB		  := 0
						_wsaldo       := 0
						_wfilial      := ""
						_wcomplemento := ""
										
					endif    
				endif				
			endif
			
			IF  _wtipoNFant != (_sAliasQ) -> TIPO_NF .and. _aTotTp[2] > 0
				// imprime totais
				If li>63
				IF m_pag >1
					_roda()
				endif
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
				IF m_pag >1
					_roda()
				endif

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
			IF m_pag >1
				_roda()
			endif

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
			IF m_pag >1
				_roda()
			endif

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
		IF m_pag >1
			_roda()
		endif

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
		IF m_pag >1
			_roda()
		endif

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

		// Robert, 14/04/2023
		// Fatura para pagamento pode ainda ser gerada em janeiro do ano seguinte (GLPI 9558).
		_sQuery +=   " AND (E2_EMISSAO <= '" + mv_par01 + "1231' OR (E2_EMISSAO <= '" + Soma1 (mv_par01) + "0131' AND E2_TIPO = 'FAT'))"

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
	IF m_pag >1
		_roda()
	endif

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
				IF m_pag >1
					_roda()
				endif

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
	if mv_par04 == 1
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
				IF m_pag >1
					_roda()
				endif

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

	IF m_pag >1
		_roda()
	endif
return
//
// --------------------------------------------------------------------------
// Retorno do type - type em looling nao é permitido da R25 
Static Function _RetType(_var)
	_type := type(_var)
Return _type
//
// --------------------------------------------------------------------------
// Modelo (resumido) a partir da safra 2020, onde busca dados da classe ClsAssoc para
// manter consistencia web service que atende APP de associados.
static function _Modelo3()
	local _aAssoc    := {}
	local _nAssoc    := 0
	local _oAssoc    := NIL
	local _oSQL      := NIL
	local _sXmlFech  := ''
	local _sError    := ''
	local _sWarning  := ''
	local _sLinImp   := ''
	local _aResPag   := {}
	local _nResPag   := 0
	local _nFatPag   := 0
	local _aTotResP  := {}
	local _nRegraPag := 0
	local _nLctoCC   := 0
	local _sMesPagto := ''
	local _nTotDesc  := 0
	local _sFtPgHist := ''
	local _nItFunr   := 0
	local _nVlEfetiv := 0
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

	U_Log2 ('debug', 'Gerando rel.fechto.safra pela funcao ' + procname ())

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
	_aAssoc = _oSQL:Qry2Array()

	procRegua(len(_aAssoc))

	for _nAssoc = 1 to len(_aAssoc)
		incproc(_aAssoc [_nAssoc, 3])
		U_LOG2('debug', 'assoc: ' + _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2])

		// Instancia objeto 'associado' para gerar seu fechamento de safra.
		_oAssoc := ClsAssoc ():New (_aAssoc [_nAssoc, 1], _aAssoc [_nAssoc, 2])
		if valtype (_oAssoc) != 'O'
			u_help ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados: ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2],, .t.)
			loop
		endif

		// Busca dados do fechamento de safra. Usa mesmo o metodo do APP associados.
		_oAssoc:FSSafra      = mv_par01
		_oAssoc:FSNFEntrada  = .t.
		_oAssoc:FSNFCompra   = .t.
		_oAssoc:FSNFComplem  = .t.
		_oAssoc:FSNFPrdProp  = .t.
		_oAssoc:FSPrevPagto  = .t.
		_oAssoc:FSRegraPagto = .t.
		_oAssoc:FSResValEfet = .t.
		_oAssoc:FSResVaried  = .f.
		_oAssoc:FSFrete      = .t.
		_oAssoc:FSLctosCC    = (mv_par04 == 1)
		_oAssoc:FSResVarGC   = .t.
		_oAssoc:FSDFunrur    = .t.
		_sXmlFech = _oAssoc:FechSafra ()

		if empty(_sXmlFech)
			u_help ("Associado ", _aAssoc [_nAssoc, 1] + '/' + _aAssoc [_nAssoc, 2] + ": Retorno vazio metodo FechSafra " + _oAssoc:UltMsg,, .t.)
			loop
		endif

		// Converte de texto para XML
		_oXMLFech := XmlParser (_sXmlFech, "_", @_sError, @_sWarning)
		if ! empty(_sError) .or. ! empty(_sWarning)
			u_help("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
			loop
		endif

		IF m_pag >1
		_roda()
		endif
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 00 PSAY "Associado: " + _oAssoc:Codigo + '-' + _oAssoc:Loja + ' ' + _oAssoc:Nome
		li += 2

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			if li > _nMaxLin - 4
				if m_pag >1
					_roda()
				endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Valores efetivos:                                GRAU/CLAS     CONDUCAO             PESO        VLR.COMPRA       VLR.COMPLEM        VLR.PREMIO         VLR.TOTAL    UNIT.EFETIVO'
			li ++
			for _nVlEfetiv = 1 to len (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem)
				_sLinImp := space (7)
				if _oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_varied:TEXT != 'TOTAIS'
					If li > _nMaxLin
						IF m_pag >1
							_roda()
						endif
						cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
					Endif
					_sLinImp += U_TamFixo (ALLTRIM(_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_varied:TEXT) + ' - ' + alltrim (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_desc:TEXT), 40, ' ') + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_grau:TEXT, 4) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasLatada:TEXT, 2) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasEspaldeira:TEXT, 2) + '  '
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_conducao:TEXT, 10) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_peso:TEXT), _sMascPeso) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vCompra:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vComplem:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vPremio:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valtot:TEXT), _sMascVTot) + '      '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valunit:TEXT), _sMascVUni) + '  '
					@ li, 0 psay _sLinImp
					li ++
				else
					@ li, 0 psay space (76) + '------------     -------------     -------------     -------------     -------------'
					li ++
					_sLinImp += space (68)
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_peso:TEXT), _sMascPeso) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vCompra:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vComplem:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vPremio:TEXT), _sMascVTot) + '  '
					_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valtot:TEXT), _sMascVTot) + '  '

					@ li, 0 psay _sLinImp
					li ++
				endif
			next
			li ++
		else
			u_help ("Tag <_valoresEfetivos> nao foi gerada no formato esperado.",, .t.)
		endif

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 titulo + 1 linha de totais)
			If li > _nMaxLin - 4
			IF m_pag >1
				_roda()
			endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			li ++
			@li, 0 PSAY 'Auxilio combustivel:                           VALOR'
			li ++
			_nFatPag = len(_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem)
			If li > _nMaxLin
			IF m_pag >1
				_roda()
			endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			_sLinImp := ''

			// Apenas a linha de total; nao precisa listar nota a nota.
			_sLinImp += space(36) // (70)
			_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_valor:TEXT), _sMascVTot) + '   '
			@ li, 0 psay _sLinImp
			li ++
			li ++
		endif

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem') 
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 nota/fatura + 1 linha de totais)
			If li > _nMaxLin - 4
				IF m_pag >1
					_roda()
				endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			_sLinImp = 'Resumo pagamento:      Mes/ano                 Valor             Saldo  Obs.'
			@li, 0 PSAY _sLinImp
			li ++
			// Monta array resumida, acumulando os pagamentos de cada mes. Nao posso aproveitar a linha
			// de totais que vem no XML por que vou agrupar as faturas por mes.
			_aResPag = {}
			for _nFatPag = 1 to len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem)
				//U_Log2 ('debug', '[' + procname () + ']Verificando linha ' + cvaltochar (_nFatPag) + ' do XML. DOC = ' + _oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT)
				if _oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT != 'TOTAIS'
					_sMesPagto = substr (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_vencto:TEXT, 4)
					_nResPag = ascan (_aResPag, {|_aVal| _aVal [1] == _sMesPagto})
					if _nResPag == 0
						aadd (_aResPag, {_sMesPagto, 0, 0, ''})
						_nResPag = len (_aResPag)
					endif
					_aResPag [_nResPag, 2] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT)
					_aResPag [_nResPag, 3] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT)
					
					// Concatena historicos para ajudar a explicar, por exemplo, casos em que tenho complemento gerado
					// em forma de 'premiacao de qualidade' e, portanto, nao consta na lista das notas de producao.
					_sFtPgHist = alltrim (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_hist:TEXT)
					if ! _sFtPgHist $ _aResPag [_nResPag, 4]
						_aResPag [_nResPag, 4] += _sFtPgHist + '; '
					endif
				endif
			next

			_aTotResP = {0, 0}
			for _nResPag = 1 to len(_aResPag)
				If li > _nMaxLin - 4
					IF m_pag >1
						_roda()
					endif
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				_sLinImp = space (23)
				_sLinImp += _aResPag [_nResPag, 1] + '      '
				_sLinImp += transform (_aResPag [_nResPag, 2], _sMascVTot) + '  '
				_sLinImp += transform (_aResPag [_nResPag, 3], _sMascVTot) + '  '
				_sLinImp += left (_aResPag [_nResPag, 4], 148)
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
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_descontoFUNRURAL:_descontoFUNRURALItem')
		if _ValType == 'A'  // Sempre eh uma array com mais de um registro (pelo menos 1 lcto + 1 linha de totais)
			If li > _nMaxLin - 4
				IF m_pag >1
					_roda()
				endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			_nItFunr = len (_oXMLFech:_assocFechSafra:_descontoFUNRURAL:_descontoFUNRURALItem)  // Quero a ultima linha (totais)
			if _nItFunr > 0
				_sLinImp := ''
				_sLinImp += 'Descontos FUNRURAL:' + space (17)
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_descontoFUNRURAL:_descontoFUNRURALItem[_nItFunr]:_vlFunru:TEXT), _sMascVTot) + '  '
				@ li, 0 psay _sLinImp
				li ++
			endif
			li ++
		endif

		// Verifica se tem este tipo de tag no XML
		_ValType := _RetType('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem')
		if _ValType == 'A'  // Enquanto tivermos mais de um grupo de pagamentos, vai funcionar...
			If li > _nMaxLin - 4
			IF m_pag >1
				_roda()
			endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Regras para pagamento:'
			li ++
			for _nRegraPag = 1 to len (_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
				If li > _nMaxLin
				IF m_pag >1
					_roda()
				endif
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
			IF m_pag >1
				_roda()
			endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			Endif
			@li, 0 PSAY 'Descontos em aberto:   Data        Historico                                                    Saldo'
			li ++
			_nTotDesc = 0
			for _nLctoCC = 1 to len (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem)
				If li > _nMaxLin
				IF m_pag >1
					_roda()
				endif
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				Endif
				if _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT != 'TOTAIS' .and. _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dc:TEXT == 'D'
					_sLinImp := space (23)
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dtMovto:TEXT, 10) + '  '
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

	if m_pag >1
		_roda()
	endif
return
//
// --------------------------------------------------------------------------
// Modelo em 132 colunas.
static function _Modelo4 ()
	local _lContinua := .T.
	local _oAssoc    := NIL
	local _sXmlFech  := ''
	local _sError    := ''
	local _sWarning  := ''
	local _sLinImp   := ''
	local _aResPag   := {}
	local _nFatPag   := 0
	local _nRegraPag := 0
	local _nLctoCC   := 0
	local _sMesPagto := ''
	local _nTotDesc  := 0
	local _nVlEfetiv := 0
	local _nSldPagto := 0
	local _nTFatXML  := 0
	local _nTSldXML  := 0
	local _nTGFat    := 0
	local _nTGAbat   := 0
	local _nAbatim   := 0
	local _aLinImp   := {}
	local _nLinImp   := 0

	private _sMascPeso := "@E 99,999,999"
	private _sMascVUni := "@E 999.9999"
	private _sMascVTot := "@E 99,999,999.99"
	private _oXMLFech  := NIL  // Precisa ser do tipo PRIVATE senao a funcao XmlParser() nao funciona... vai entender.

	// Variaveis padrao para relatorios.
	private nTipo    := IIF(aReturn[4]==1,15,18)
	private li       := 80
	private m_pag    := 1
	private cabec1   := ""
	private cabec2   := ""
	private _nMaxLin := 68
	li = _nMaxLin + 1
	limite = 132
	tamanho = 'M'

	U_Log2('debug', 'Gerando rel.fechto.safra pela funcao ' + procname ())

	procRegua(10)

	// Instancia objeto 'associado' para gerar seu fechamento de safra.
	_oAssoc := ClsAssoc():New(mv_par02, mv_par03)
	if valtype(_oAssoc) != 'O' .or. empty(_oAssoc:Codigo)
		u_help("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados.",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		_oAssoc:FSSafra      = mv_par01
		_oAssoc:FSPrevPagto  = .t.  // Buscar previsoes de pagamento
		_oAssoc:FSPrPgtAbat  = .t.  // (mv_par05 == 1)  // Buscar os abatimentos de cada previsao de pagamento
		_oAssoc:FSRegraPagto = .t.  // Buscar regras de pagamento
		_oAssoc:FSResValEfet = .t.  // Buscar resumo com valores efetivos (premios, complementos, etc)
		_oAssoc:FSFrete      = .t.  // Buscar fretes/aux.combustivel
		_oAssoc:FSLctosCC    = (mv_par04 == 1)  // Buscar (ou nao) lctos em aberto na cta.corrente
		_sXmlFech = _oAssoc:FechSafra()
		if empty(_sXmlFech)
			u_help("Retorno vazio metodo FechSafra " + _oAssoc:UltMsg,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		// Converte de texto para XML
		_oXMLFech := XmlParser(_sXmlFech, "_", @_sError, @_sWarning)
		if ! empty(_sError) .or. ! empty(_sWarning)
			u_help("Erro ao decodificar retorno: " + _sError + _sWarning,, .t.)
			_lContinua = .F.
		endif
	endif

	if _lContinua
		if m_pag >1
			_roda()
		endif
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		@ li, 00 PSAY "Associado: " + _oAssoc:Codigo + '-' + _oAssoc:Loja + ' ' + _oAssoc:Nome
		li += 2
	endif

	// Lista resumo de variedades e respectivos valores.
	if _lContinua .and. type ('_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem') == 'A'
		@li, 0 PSAY 'Valores efetivos:                Grau/clas  Conduc    Peso Kg    Vlr.compra    Vlr.complem    Vlr.premio     Vlr.total  Un.efetivo'
		li ++
		@li, 0 PSAY '------------------------------   ---------  ------   --------   -----------   ------------   -----------   -----------  ----------'
		li ++
		for _nVlEfetiv = 1 to len (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem)
			_sLinImp := ''
			if _oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_varied:TEXT != 'TOTAIS'
				_Cabec(_nMaxLin)
				_sLinImp += U_TamFixo (ALLTRIM(_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_varied:TEXT) + ' - ' + alltrim (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_desc:TEXT), 35, ' ') + ' '
				_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_grau:TEXT, 4) + ' '
				if upper (left (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_conducao:TEXT, 1)) == 'L'
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasLatada:TEXT, 2) + ' '
				else
					_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_clasEspaldeira:TEXT, 2) + ' '
				endif
				_sLinImp += U_TamFixo (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_conducao:TEXT, 6) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_peso:TEXT), _sMascPeso) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vCompra:TEXT), _sMascVTot) + '  
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vComplem:TEXT), _sMascVTot) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vPremio:TEXT), _sMascVTot) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valtot:TEXT), _sMascVTot) + '    '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valunit:TEXT), _sMascVUni)
				@ li, 0 psay _sLinImp
				li ++
			else
				@ li, 0 psay space(52) + '---------   -----------   ------------   -----------   -----------'
				li ++
				_sLinImp += space(50)
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_peso:TEXT), _sMascPeso) + '  '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vCompra:TEXT), _sMascVTot) + '  '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vComplem:TEXT), _sMascVTot) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_vPremio:TEXT), _sMascVTot) + ' '
				_sLinImp += transform (val (_oXMLFech:_assocFechSafra:_valoresEfetivos:_valorEfetivoItem[_nVlEfetiv]:_valtot:TEXT), _sMascVTot)
				@ li, 0 psay _sLinImp
				li ++
			endif
		next
		li ++
	endif
		
	// Lista auxilio combustivel
	if _lContinua .and. type ('_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem') == 'A'
		_Cabec(_nMaxLin - 2)
		_nFatPag = len (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem)
		_sLinImp := 'Auxilio combustivel: ' + GetMv ("MV_SIMB1") + ' '
		_sLinImp += alltrim (transform (val (_oXMLFech:_assocFechSafra:_freteSafra:_freteSafraItem[_nFatPag]:_valor:TEXT), _sMascVTot))
		@ li, 0 psay _sLinImp
		li += 2
	endif

	// Lista previsoes de pagamento da safra
	if _lContinua .and. type ('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem') == 'A'
		_Cabec (_nMaxLin - 4)
		_aLinImp = {}
		aadd (_aLinImp, 'Mes/ano         Valor   Observacoes                                                                                            Saldo')
		aadd (_aLinImp, '-------   -----------   ------------------------------------------------------------------------------------------    --------------')
		_nFatPag = 1
		do while _lContinua .and. _nFatPag <= len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem)

			// O XML vem jah ordenado por data de vencimento, mas aberto por
			// documento. Como quero listar um resumo mensal, tenho que varrer
			// os documentos e acumular em arrays.
			_sMesPagto = substr (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_vencto:TEXT, 4)
			_aAbatim = {}  // Array para guardar os possiveis abatimentos do mes
			_aResPag = {_sMesPagto, 0, 0}  // Array para guardar totais do mes
			do while _lContinua .and. _nFatPag <= len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem) ;
			.and. substr (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_vencto:TEXT, 4) == _sMesPagto

				// O XML jah retorna com uma linha de totais, que nao quero listar agora.
				if _oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_doc:TEXT != 'TOTAIS'

					_aResPag  [2] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT)
					_aResPag  [3] += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT)
					_nTGFat       += val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT)

					// Se tiver tags de abatimentos, preciso ler.
					// Se tiver mais de um abatimento, eh formato array.
					if type ('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[' + cvaltochar (_nFatPag) + ']:_FatPagAbatItem') == 'A'
						_nAbatim = 1
						do while _nAbatim <= len (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem)
							aadd (_aAbatim, {_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem [_nAbatim]:_abatData:TEXT, ;
											_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem [_nAbatim]:_abatHist:TEXT, ;
										val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem [_nAbatim]:_abatValor:TEXT)})
							_nAbatim ++
							_nTGAbat += _aAbatim [len(_aAbatim), 3]
						enddo
					elseif type ('_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[' + cvaltochar (_nFatPag) + ']:_FatPagAbatItem') == 'O'
						aadd(_aAbatim, {_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem:_abatData:TEXT, ;
										_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem:_abatHist:TEXT, ;
									val (_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_FatPagAbatItem:_abatValor:TEXT)})
						_nTGAbat += _aAbatim [len(_aAbatim), 3]
					endif

				else

					// Aproveito que o XML jah traz tags de totais, para
					// conferir totais que calculei aqui.
					_nTFatXML = val(_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_valor:TEXT)
					_nTSldXML = val(_oXMLFech:_assocFechSafra:_faturaPagamento:_faturaPagamentoItem[_nFatPag]:_saldo:TEXT)

					if _nTGFat != _nTFatXML
						u_help("Total de pagamentos que calculei aqui (" + cvaltochar(_nTGFat) + ") nao bate com o que veio no XML (" + cvaltochar(_nTFatXML) + ")",, .t.)
						_aLinImp = {}
					endif
					if (_nTGFat - _nTGAbat) != _nTSldXML
						u_help("Saldo final que calculei aqui (" + cvaltochar(_nTGFat - _nTGAbat) + ") nao bate com o que veio no XML (" + cvaltochar(_nTSldXML) + ")",, .t.)
						_aLinImp = {}
					endif
				endif
				_nFatPag ++
			enddo

			_nSldPagto = _aResPag [2]
			
			// Agora que tenho o resumo do mes nas arrays, posso gerar linhas para impressao.
			// A tag de totais ao final nao tem data (e nem quero imprimir ela aqui)
			if _lContinua .and. ! empty(_aResPag [1])
				_sLinImp := _aResPag [1] + ' '
				_sLinImp += transform(_aResPag [2], _sMascVTot)
				_sLinImp += '               Valor safra' + space(72)
				_sLinImp += transform(_nSldPagto, _sMascVTot)
				aadd(_aLinImp, _sLinImp)
				_sLinImp = ''
				
				// Lista os abatimentos/baixas/pagtos/compensacoes (se existirem)
				for _nAbatim = 1 to len(_aAbatim)
					_nSldPagto -= _aAbatim [_nAbatim, 3]
					_sLinImp := '        '
					_sLinImp += transform(_aAbatim [_nAbatim, 3], _sMascVTot) + '-  '
					_sLinImp += dtoc(stod(_aAbatim [_nAbatim, 1])) + '  '
					_sLinImp += U_TamFixo(_aAbatim [_nAbatim, 2], 81, ' ') + '  '
					_sLinImp += transform(_nSldPagto, _sMascVTot)
					aadd(_aLinImp, _sLinImp)
					_sLinImp = ''
				next

				// Linha separando cada parcela
				_sLinImp = replicate('-', limite)
				aadd(_aLinImp, _sLinImp)
				_sLinImp = ''
			endif
		enddo

		_sLinImp := 'TOTAIS  '
		_sLinImp += transform(_nTGFat, _sMascVTot)
		_sLinImp += space (98)
		_sLinImp += transform(_nTGFat - _nTGAbat, _sMascVTot)
		aadd(_aLinImp, _sLinImp)
		_sLinImp = ''

		for _nLinImp = 1 to len(_aLinImp)
			_Cabec(_nMaxLin - 4)
			_sLinImp = _aLinImp [_nLinImp]
			@ li, 0 psay _sLinImp
			li ++
		next
		li += 2
	endif

	// Lista regras para pagamento de safra
	if _lContinua .and. type ('_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem') == 'A'
		_Cabec(_nMaxLin - 4)
		@li, 0 PSAY 'Regras para pagamento:'
		li ++
		for _nRegraPag = 1 to len(_oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem)
			_Cabec(_nMaxLin)
			_sLinImp := space(35)
			_sLinImp += _oXMLFech:_assocFechSafra:_regraPagamento:_regraPagamentoItem[_nRegraPag]:_descComParc:TEXT
			@ li, 0 psay _sLinImp
			li ++
		next
		li ++
	endif

	// Lista lancamentos em aberto a debito na conta corrente
	if _lContinua .and. type ('_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem') == 'A'
		_Cabec(_nMaxLin - 4)
		@li, 0 PSAY 'Descontos em aberto:   Data        Historico                                                    Saldo   Vcto'
		li ++
		_nTotDesc = 0

		for _nLctoCC = 1 to len(_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem)
			_Cabec(_nMaxLin)
			if _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_doc:TEXT != 'TOTAIS' .and. _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dc:TEXT == 'D' .and. _oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_capital:TEXT != 'S'
				_sLinImp := space(23)
				_sLinImp += U_TamFixo(_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_dtMovto:TEXT, 10) + '  '
				_sLinImp += U_TamFixo(_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_hist:TEXT, 50) + '  '
				_sLinImp += transform(val(_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT), '@E 999,999,999.99') + '   '

				// Nao posso aproveitar a linha de totais que vem no XML por que acumula debitos
				// e creditos, e neste momento quero apenas os debitos.
				_nTotDesc += val (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_saldo:TEXT)

				_sLinImp += dtoc(stod (_oXMLFech:_assocFechSafra:_lctoCC:_lctoCCItem[_nLctoCC]:_vctoFin:TEXT))
				@ li, 0 psay _sLinImp
				li ++
			endif
		next
		@ li, 0 psay '                                                                                       --------------'
		li ++
		@ li, 0 psay '                                                                                        ' + transform (_nTotDesc, _sMascVTot)
		li += 2
	endif

	IF m_pag >1
		_roda()
	endif
return
//
// --------------------------------------------------------------------------
// Rodapé
static function _roda()
	@ li, 0 psay __PrtfatLine()
	li ++
	@ li, 20 psay Padc('**** DOCUMENTO CONFIDENCIAL ****', limite,' ') 
	li ++ 
	@ li, 0 psay __PrtfatLine()
	li ++
return
//
// --------------------------------------------------------------------------
// Gera quebra de pagina
static function _Cabec(_nLinha)
	if li > _nLinha
		if m_pag > 1
			@ li, 0 psay __PrtfatLine()
			li ++
			@ li, 20 psay Padc('**** DOCUMENTO CONFIDENCIAL ****', limite,' ') 
			li ++ 
			@ li, 0 psay __PrtfatLine()
			li ++
		endif
		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes           Help
	aadd(_aRegsPerg, {01, "Safra                         ", "C", 4,  0,  "",   "   ", {},             ""})
	aadd(_aRegsPerg, {02, "Associado                     ", "C", 6,  0,  "",   "SA2", {},             ""})
	aadd(_aRegsPerg, {03, "Loja                          ", "C", 2,  0,  "",   "",    {},             ""})
	aadd(_aRegsPerg, {04, "Lista Saldo C/C               ", "N", 1,  0,  "",   "   ", {"Sim", "Não"}, ""})
	
	U_ValPerg(cPerg, _aRegsPerg)
Return

	

