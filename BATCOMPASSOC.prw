// Programa...: BATCOMPASSOC
// Autor......: Catia Cardoso
// Data.......: 08/02/2018
// Descricao..: Gera titulos no conta corrente / financeiro referente a compra de associados nas lojas

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Gera titulos no conta corrente / financeiro referente a compra de associados nas lojas
// #PalavasChave      #associados #venda #conta_corrente 
// #TabelasPrincipais #SA2 #SL1 
// #Modulos 		  #LOJA 

// Historico de alteracoes:
// 16/19/2021 - Claudia - Alterado o TM de 23 para 04. GLPI: 10948
// 12/01/2022 - Robert  - Revisao da query (inclusao EXISTS SZI e teste de cod/loja base associado)
//                      - Fixada parcela 'A' (antes gerava vazia)
// 02/05/2022 - Claudia - Comentado o "exit".
// 03/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

//---------------------------------------------------------------------------------------------------------------
User function BATCOMPASSOC()
	Local _nTitGer   := 0
	local _oSQL      := NIL
	local _sParcCAs  := 'A'
	local _sTMCAssoc := '04'

	if cFilAnt != '01'
		u_help ("Este programa tem previsao de ser executado apenas na matriz, pois busca cupons de todas as filiais.",, .t.)
	else

		// LE VENDAS DE CUPONS DAS LOJAS - PARA ASSOCIADOS
		_oSQL := ClsSQL ():New ()

		_oSQL:_sQuery := " "
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += "    SA2.A2_COD"
		_oSQL:_sQuery += "    ,SA2.A2_LOJA"
		_oSQL:_sQuery += "    ,L1_EMISNF"
		_oSQL:_sQuery += "    ,L4_VALOR"
		_oSQL:_sQuery += "    ,L1_DOC"
		_oSQL:_sQuery += "    ,L1_SERIE"
		_oSQL:_sQuery += "    ,L1_FILIAL"
		_oSQL:_sQuery += "    ,SL1.R_E_C_N_O_"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SL1") + " AS SL1"
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SL4") + " AS SL4"
		_oSQL:_sQuery += " 	ON (SL4.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 			AND SL4.L4_FILIAL = SL1.L1_FILIAL"
		_oSQL:_sQuery += " 			AND SL4.L4_NUM = SL1.L1_NUM"
		_oSQL:_sQuery += " 			AND SL4.L4_FORMA = 'CO'"
		_oSQL:_sQuery += " 			AND SL4.L4_ADMINIS LIKE '%800%')"
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " AS SA2"
		_oSQL:_sQuery += " 	ON (SA2.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 			AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
		_oSQL:_sQuery += " 			AND SA2.A2_CGC = SL1.L1_CGCCLI"
		_oSQL:_sQuery += " 			AND SA2.A2_COD = A2_VACBASE"  // EXECUTAR SEMPRE NO COD/LOJA BASE
		_oSQL:_sQuery += " 			AND SA2.A2_LOJA = A2_VALBASE)"  // EXECUTAR SEMPRE NO COD/LOJA BASE
		_oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SL1.L1_EMISNF >= '" + dtos (date () - 30) + "'"  // Ultimos dias, para nao gerar muito processamento.
		_oSQL:_sQuery += " AND SL1.L1_DOC    != ''"
		_oSQL:_sQuery += " AND SL1.L1_SERIE  != '999'"
		_oSQL:_sQuery += " AND SL1.L1_INDCTB  = ''"  // Flag de 'ainda nao gerado'
		_oSQL:_sQuery += " AND NOT EXISTS (SELECT *"  // Nao pode existir ainda na conta corrente
		_oSQL:_sQuery +=                   " FROM " + RetSQLName ("SZI") + " AS SZI "
		_oSQL:_sQuery +=                  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=                    " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"
		_oSQL:_sQuery +=                    " AND ZI_ASSOC   = A2_COD"
		_oSQL:_sQuery +=                    " AND ZI_LOJASSO = A2_LOJA"
		_oSQL:_sQuery +=                    " AND ZI_DOC     = L1_DOC"
		_oSQL:_sQuery +=                    " AND ZI_SERIE   = L1_SERIE"
		_oSQL:_sQuery +=                    " AND ZI_PARCELA = '" + _sParcCAs + "'"
		_oSQL:_sQuery +=                    " AND ZI_TM      = '" + _sTMCAssoc + "')"
		_oSQL:_sQuery += " ORDER BY L1_FILIAL, SL1.L1_EMISNF, L1_DOC"
		_oSQL:Log ()
		_atitger := aclone (_oSQL:Qry2Array (.f., .f.))
		for _nTitGer = 1 to len(_atitger)
			// grava conta corrente e financeiro dos associados
			_oCtaCorr := ClsCtaCorr():New ()
			_oCtaCorr:Assoc    = _aTitger[_ntitger,1]
			_oCtaCorr:Loja     = _aTitger[_ntitger,2]
			_oCtaCorr:TM       = _sTMCAssoc
			_oCtaCorr:DtMovto  = stod (_aTitger[_ntitger,3])
			_oCtaCorr:Valor    = _aTitger[_ntitger,4]
			_oCtaCorr:SaldoAtu = _aTitger[_ntitger,4]
			_oCtaCorr:Usuario  = cUserName
			_oCtaCorr:Histor   = "VENDA (VIA FL." + _aTitger[_ntitger, 7] + ") PROD.REUNIAO DE NUCLEO"
			_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
			_oCtaCorr:Doc      = _aTitger[_ntitger,5]
			_oCtaCorr:Serie    = "INS"
			_oCtaCorr:Origem   = "BATCOMPASSOC"
			_oCtaCorr:Parcela  = _sParcCAs

			if _oCtaCorr:PodeIncl ()
				if  _oCtaCorr:Grava (.F., .F.)
					
					// Marca SL1 como 'jah processado'
					DbSelectArea("SL1")
					dbgoto( _aTitger[_ntitger,8] ) // RECNO DO SL1
					reclock("SL1", .F.)
						SL1->L1_INDCTB := 'S'
					MsUnLock()
				endif
			endif
			// cai fora no primeiro caso (excluir depois)
			//exit
		next
	endif
return
