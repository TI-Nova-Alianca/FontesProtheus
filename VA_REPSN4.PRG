// Programa...: VA_REPSN4
// Autor......: Catia Cardoso
// Data.......: 11/01/2018
// Descricao..: Grava conta contabil correta no SFT - conforme regra do ato coopertivo/não cooperativo  
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #rotina
// #Descricao         #Grava conta contabil correta no SFT - conforme regra do ato coopertivo/não cooperativo  
// #PalavasChave      #safra #tabelas_de_preco_uva #tabelas_de_preco 
// #TabelasPrincipais #SZT
// #Modulos   		  #COOP 
//
// Historico de alteracoes:
// 12/01/2018 - Catia - tratamento para fretes sobre saidas assumir a conta correta
//
// -----------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function VA_REPSN4()
	local i	:= 0
	cPerg   := "VA_REPSN4"
	_ValidPerg()

	if Pergunte(cPerg,.T.)
		do case
			case mv_par05 = 1
				// 1 - GERA OCORRENCIA 03 A PARTIR DA OCORRENCIA 04
				// 2 - GERA OCORRENCIA 01 A PARTIR DA OCORRENCIA 04
				// BUSCA OS ITENS QUE PRECISAM SER TRATADOS
				_sSQL := ""
				_sSQL += " SELECT SN4.N4_DATA, SN4.N4_TIPO, SN4.N4_TIPOCNT, SN4.N4_CBASE, SN4.N4_ITEM"
				_sSQL += "   FROM SN4010 AS SN4"
				_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
				_sSQL += "    AND SN4.N4_DATA    > '20170101'"
				_sSQL += "    AND SN4.N4_OCORR   = '04'"
				_sSQL += "    AND SN4.N4_CBASE   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
				_sSQL += "    AND SN4.N4_ITEM    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'" 
				_sSQL += "    AND SN4.N4_CBASE  != '0000004060'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004062'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004063'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004064'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND NOT EXISTS (SELECT 1"
				_sSQL += "					    FROM SN4010 AS SN404"
				_sSQL += "		               WHERE SN404.N4_OCORR   = '03'"
				_sSQL += "					     AND SN404.N4_DATA    = SN4.N4_DATA"
				_sSQL += "					     AND SN404.N4_CBASE   = SN4.N4_CBASE"
				_sSQL += "					     AND SN404.N4_ITEM    = SN4.N4_ITEM"
				_sSQL += "					     AND SN404.N4_TIPO    = SN4.N4_TIPO"
				_sSQL += "					     AND SN404.N4_TIPOCNT = SN4.N4_TIPOCNT)"
				_sSQL += "  ORDER BY N4_TIPO, N4_TIPOCNT" 	
					
				//u_showmemo(_sSQL)
				_aDados := U_Qry2Array(_sSQL)
				if len (_aDados) > 0
					for i=1 to len(_aDados)
						_wdata    = _adados[i,1]
						_wtipo    = _adados[i,2]
						_wtipocnt = _adados[i,3]
						_wcbase   = _adados[i,4]
						_witem   =  _adados[i,5]
						// GERA A OCORRENCIA 03 QUE TEM QUE SER "PAR" COM A 04 - 1 PRA 1
						_sSQL := ""	
						_sSQL += " INSERT INTO SN4010 (N4_FILIAL, N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR, N4_MOTIVO, N4_TIPOCNT, N4_CONTA"
						_sSQL += "        , N4_DATA, N4_QUANTD, N4_VLROC1, N4_VLROC2, N4_VLROC3, N4_VLROC4"
						_sSQL += "	      , N4_VLROC5, N4_SERIE, N4_NOTA, N4_VENDA, N4_TXMEDIA, N4_TXDEPR, N4_CCUSTO, N4_LOCAL"
						_sSQL += "	      , N4_SEQ, N4_SUBCTA, N4_SEQREAV, N4_CODBAIX, N4_FILORIG, N4_CLVL, N4_DCONTAB, N4_IDMOV"
						_sSQL += "	      , N4_TPSALDO, N4_QUANTPR, N4_NODIA, N4_DIACTB, N4_CALCPIS, N4_HORA"
						_sSQL += "	      , N4_ORIGEM, N4_LA, N4_LP, N4_CCUSTOT, N4_GRUPOTR, N4_TAXAPAD, N4_SDOC, D_E_L_E_T_"
						_sSQL += "	      , R_E_C_N_O_ )"
						_sSQL += " SELECT SN4.N4_FILORIG, SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_TIPO, '03', SN4.N4_MOTIVO, SN4.N4_TIPOCNT, SN4.N4_CONTA"
						_sSQL += "      , SN4.N4_DATA, SN4.N4_QUANTD, SN4.N4_VLROC1, SN4.N4_VLROC2, SN4.N4_VLROC3, SN4.N4_VLROC4"
						_sSQL += "	    , SN4.N4_VLROC5, SN4.N4_SERIE, SN4.N4_NOTA, SN4.N4_VENDA, SN4.N4_TXMEDIA, SN4.N4_TXDEPR, SN4.N4_CCUSTO, SN4.N4_LOCAL"
						_sSQL += "	    , '1', SN4.N4_SUBCTA, SN4.N4_SEQREAV, SN4.N4_CODBAIX, SN4.N4_FILORIG, SN4.N4_CLVL, SN4.N4_DCONTAB, SN4.N4_IDMOV"
						_sSQL += "	    , SN4.N4_TPSALDO, SN4.N4_QUANTPR, SN4.N4_NODIA, SN4.N4_DIACTB, SN4.N4_CALCPIS, SN4.N4_HORA, SN4.N4_ORIGEM, SN4.N4_LA"
						_sSQL += "	    , SN4.N4_LP, SN4.N4_CCUSTOT, SN4.N4_GRUPOTR, SN4.N4_TAXAPAD, SN4.N4_SDOC"
						_sSQL += "	    , SN4.D_E_L_E_T_"
						_sSQL += "	    , ( SELECT TOP 1 R_E_C_N_O_" 
						_sSQL += "		 	  FROM SN4010"
						_sSQL += "		     ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
						_sSQL += "   FROM SN4010 AS SN4"
						_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
						_sSQL += "    AND SN4.N4_OCORR   = '04'"
						_sSQL += "    AND SN4.N4_DATA    = '" + dtos(_wdata) + "'"
						_sSQL += "    AND N4_TIPO        = '" + _wtipo + "'"
						_sSQL += "    AND N4_TIPOCNT     = '" + _wtipocnt + "'"
						_sSQL += "    AND SN4.N4_CBASE   = '" + _wcbase + "'"
						_sSQL += "    AND SN4.N4_ITEM    = '" + _witem + "'"
						if TCSQLExec (_sSQL) < 0
							u_showmemo(_sSQL)
							return
						endif
							
						// VERIFICA SE O VALOR DA OCORRENCIA 04 QUE ESTA SENDO LIDA TEM VALOR - SE TIVER GERA A OCORRENCIA 01
						_sSQL := ""	
						_sSQL += " INSERT INTO SN4010 (N4_FILIAL, N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR, N4_MOTIVO, N4_TIPOCNT, N4_CONTA"
						_sSQL += "      , N4_DATA, N4_QUANTD, N4_VLROC1, N4_VLROC2, N4_VLROC3, N4_VLROC4"
						_sSQL += " 	    , N4_VLROC5, N4_SERIE, N4_NOTA, N4_VENDA, N4_TXMEDIA, N4_TXDEPR, N4_CCUSTO, N4_LOCAL"
						_sSQL += " 	    , N4_SEQ, N4_SUBCTA, N4_SEQREAV, N4_CODBAIX, N4_FILORIG, N4_CLVL, N4_DCONTAB, N4_IDMOV"
						_sSQL += " 	    , N4_TPSALDO, N4_QUANTPR, N4_NODIA, N4_DIACTB, N4_CALCPIS, N4_HORA"
						_sSQL += " 	    , N4_ORIGEM, N4_LA, N4_LP, N4_CCUSTOT, N4_GRUPOTR, N4_TAXAPAD, N4_SDOC, D_E_L_E_T_"
						_sSQL += " 	    , R_E_C_N_O_ )"
						_sSQL += " SELECT SN4.N4_FILORIG, SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_TIPO, '01', '18', SN4.N4_TIPOCNT, SN4.N4_CONTA"
						_sSQL += "      , SN4.N4_DATA, SN4.N4_QUANTD, SN4.N4_VLROC1, SN4.N4_VLROC2, SN4.N4_VLROC3, SN4.N4_VLROC4"
						_sSQL += " 	    , SN4.N4_VLROC5, SN4.N4_SERIE, SN4.N4_NOTA, SN4.N4_VENDA, SN4.N4_TXMEDIA, SN4.N4_TXDEPR, SN4.N4_CCUSTO, SN4.N4_LOCAL"
						_sSQL += " 	    , '1', SN4.N4_SUBCTA, SN4.N4_SEQREAV, SN4.N4_CODBAIX, SN4.N4_FILORIG, SN4.N4_CLVL, SN4.N4_DCONTAB, SN4.N4_IDMOV"
						_sSQL += " 	    , SN4.N4_TPSALDO, SN4.N4_QUANTPR, SN4.N4_NODIA, SN4.N4_DIACTB, SN4.N4_CALCPIS, SN4.N4_HORA, 'ATFA036', SN4.N4_LA"
						_sSQL += " 	    , SN4.N4_LP, SN4.N4_CCUSTOT, SN4.N4_GRUPOTR, SN4.N4_TAXAPAD, SN4.N4_SDOC"
						_sSQL += " 	    , SN4.D_E_L_E_T_"
						_sSQL += " 	    , ( SELECT TOP 1 R_E_C_N_O_" 
						_sSQL += " 			  FROM SN4010"
						_sSQL += " 		     ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
						_sSQL += "  FROM SN4010 AS SN4"
						_sSQL += " WHERE SN4.D_E_L_E_T_ = ''"
						_sSQL += "   AND SN4.N4_OCORR   = '04'" 
						_sSQL += "   AND SN4.N4_VLROC1  > 0" 
						_sSQL += "    AND SN4.N4_DATA    = '" + dtos(_wdata) + "'"
						_sSQL += "    AND N4_TIPO        = '" + _wtipo + "'"
						_sSQL += "    AND N4_TIPOCNT     = '" + _wtipocnt + "'"
						_sSQL += "    AND SN4.N4_CBASE   = '" + _wcbase + "'"
						_sSQL += "    AND SN4.N4_ITEM    = '" + _witem + "'"
						if TCSQLExec (_sSQL) < 0
							u_showmemo(_sSQL)
							return
						endif	
															
					next
				endif
			// 2 - GERA OCORRENCIA 04 A PARTIR DA OCORRENCIA 03
			case mv_par05 = 2
				// BUSCA OS ITENS QUE PRECISAM SER TRATADOS
				_sSQL := ""
				_sSQL += " SELECT DISTINCT SN4.N4_FILORIG"
				_sSQL += "      , SN4.N4_CBASE"
				_sSQL += "      , SN4.N4_ITEM"
				_sSQL += "      , SN4.N4_TIPO"
				_sSQL += "      , SN4.N4_TIPOCNT"
				_sSQL += "      , SN4.N4_DATA"
				_sSQL += "   FROM SN4010 AS SN4"
				_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
				_sSQL += "    AND SN4.N4_DATA > '20170101'"
				_sSQL += "    AND SN4.N4_OCORR = '03'"
				_sSQL += "    AND SN4.N4_CBASE   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
				_sSQL += "    AND SN4.N4_ITEM    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sSQL += "    AND SN4.N4_CBASE  != '0000004155'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004156'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004157'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000003385'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004366'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND SN4.N4_CBASE  != '0000004491'" // segundo a planilha do gabriel desconsiderar esses
				_sSQL += "    AND NOT EXISTS (SELECT 1"
				_sSQL += " 				        FROM SN4010 AS SN404"
				_sSQL += " 				       WHERE SN404.N4_OCORR   = '04'"
				_sSQL += " 				         AND SN404.N4_DATA    = SN4.N4_DATA"
				_sSQL += " 				         AND SN404.N4_CBASE   = SN4.N4_CBASE"
				_sSQL += " 				         AND SN404.N4_ITEM    = SN4.N4_ITEM"
				_sSQL += " 				         AND SN404.N4_TIPO    = SN4.N4_TIPO"
				_sSQL += " 				         AND SN404.N4_TIPOCNT = SN4.N4_TIPOCNT)"
				_sSQL += "  ORDER BY SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_DATA"
				_aDados := U_Qry2Array(_sSQL)
				if len (_aDados) > 0
					for i=1 to len(_aDados)
						_wdata    = _adados[i,6]
						_wtipo    = _adados[i,4]
						_wtipocnt = _adados[i,5]
						_wcbase   = _adados[i,2]
						_witem    = _adados[i,3]
						
						_wfilial  = '01'
						if _wcbase='0000001257' .or. _wcbase= '0000001258' .or. _wcbase= '0000001978' .or. _wcbase= '0000001979' .or. _wcbase= '0000001980' .or. _wcbase= '0000001981'
							_wfilial  = '07'
						endif
						if _wcbase='0000001333' .or. _wcbase= '0000001759'
							_wfilial  = '03'
						endif
						
						// GERAR OCORRENCIAS 04 - DUPLICANDO A 03
						_sSQL := ""	
						_sSQL += " INSERT INTO SN4010 (N4_FILIAL, N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR, N4_MOTIVO, N4_TIPOCNT, N4_CONTA"
						_sSQL += "        , N4_DATA, N4_QUANTD, N4_VLROC1, N4_VLROC2, N4_VLROC3, N4_VLROC4"
						_sSQL += "	      , N4_VLROC5, N4_SERIE, N4_NOTA, N4_VENDA, N4_TXMEDIA, N4_TXDEPR, N4_CCUSTO, N4_LOCAL"
						_sSQL += "	      , N4_SEQ, N4_SUBCTA, N4_SEQREAV, N4_CODBAIX, N4_FILORIG, N4_CLVL, N4_DCONTAB, N4_IDMOV"
						_sSQL += "	      , N4_TPSALDO, N4_QUANTPR, N4_NODIA, N4_DIACTB, N4_CALCPIS, N4_HORA"
						_sSQL += "	      , N4_ORIGEM, N4_LA, N4_LP, N4_CCUSTOT, N4_GRUPOTR, N4_TAXAPAD, N4_SDOC, D_E_L_E_T_"
						_sSQL += "	      , R_E_C_N_O_ )"
						// como o maior numero de itens veio para a matriz, gera tudo na matriz e depois altera se houver necessidade
						_sSQL += " SELECT '" + _wfilial + "'"
						_sSQL += "      , SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_TIPO, '04', SN4.N4_MOTIVO, SN4.N4_TIPOCNT, SN4.N4_CONTA"
						_sSQL += "      , SN4.N4_DATA, SN4.N4_QUANTD, SN4.N4_VLROC1, SN4.N4_VLROC2, SN4.N4_VLROC3, SN4.N4_VLROC4"
						_sSQL += "	    , SN4.N4_VLROC5, SN4.N4_SERIE, SN4.N4_NOTA, SN4.N4_VENDA, SN4.N4_TXMEDIA, SN4.N4_TXDEPR, SN4.N4_CCUSTO, SN4.N4_LOCAL"
						_sSQL += "	    , '1', SN4.N4_SUBCTA, SN4.N4_SEQREAV, SN4.N4_CODBAIX, SN4.N4_FILORIG, SN4.N4_CLVL, SN4.N4_DCONTAB, SN4.N4_IDMOV"
						_sSQL += "	    , SN4.N4_TPSALDO, SN4.N4_QUANTPR, SN4.N4_NODIA, SN4.N4_DIACTB, SN4.N4_CALCPIS, SN4.N4_HORA, SN4.N4_ORIGEM, SN4.N4_LA"
						_sSQL += "	    , SN4.N4_LP, SN4.N4_CCUSTOT, SN4.N4_GRUPOTR, SN4.N4_TAXAPAD, SN4.N4_SDOC"
						_sSQL += "	    , SN4.D_E_L_E_T_"
						_sSQL += "	    , ( SELECT TOP 1 R_E_C_N_O_" 
						_sSQL += "		 	  FROM SN4010"
						_sSQL += "		     ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
						_sSQL += "   FROM SN4010 AS SN4"
						_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
						_sSQL += "    AND SN4.N4_OCORR   = '03'"
						_sSQL += "    AND SN4.N4_DATA    = '" + dtos(_wdata) + "'"
						_sSQL += "    AND N4_TIPO        = '" + _wtipo + "'"
						_sSQL += "    AND N4_TIPOCNT     = '" + _wtipocnt + "'"
						_sSQL += "    AND SN4.N4_CBASE   = '" + _wcbase + "'"
						_sSQL += "    AND SN4.N4_ITEM    = '" + _witem + "'"
						if TCSQLExec (_sSQL) < 0
							u_showmemo(_sSQL)
							return
						endif		
					next
				endif
			// 3 - GERA OCORRENCIA 05/10 A PARTIR DA OCORRENCIA 05/01
			case mv_par05 = 3
				// BUSCA OS ITENS QUE PRECISAM SER TRATADOS
				_sSQL := ""
				_sSQL += " SELECT DISTINCT SN4.N4_FILIAL"
				_sSQL += "      , SN4.N4_CBASE"
				_sSQL += "      , SN4.N4_ITEM"
				_sSQL += "      , SN4.N4_TIPO"
				_sSQL += "      , SN4.N4_TIPOCNT"
				_sSQL += "      , SN4.N4_DATA"
				_sSQL += "      , SN4.N4_OCORR"
				_sSQL += "   FROM SN4010 AS SN4"
				_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
				_sSQL += "    AND SN4.N4_FILIAL  = '01'"
				_sSQL += "    AND SN4.N4_OCORR   = '05'"
				_sSQL += "    AND SN4.N4_TIPO    = '01'"
				_sSQL += "    AND SN4.N4_CBASE   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
				_sSQL += "    AND SN4.N4_ITEM    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sSQL += "    AND NOT EXISTS (SELECT 1"
				_sSQL += " 				        FROM SN4010 AS SN404"
				_sSQL += " 				       WHERE SN404.D_E_L_E_T_ = ''"
				_sSQL += "    					 AND SN404.N4_FILIAL  = SN4.N4_FILIAL"
				_sSQL += "    					 AND SN404.N4_OCORR   = SN4.N4_OCORR"	
				_sSQL += "    					 AND SN404.N4_TIPO    = '10'"
				_sSQL += " 				         AND SN404.N4_DATA    = SN4.N4_DATA"
				_sSQL += " 				         AND SN404.N4_CBASE   = SN4.N4_CBASE"
				_sSQL += " 				         AND SN404.N4_ITEM    = SN4.N4_ITEM"
				_sSQL += " 				         AND SN404.N4_TIPOCNT = SN4.N4_TIPOCNT)"
				_sSQL += "  ORDER BY SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_DATA"
				
				_aDados := U_Qry2Array(_sSQL)
				
				if len (_aDados) > 0
					for i=1 to len(_aDados)
						_wdata    = _adados[i,6]
						_wtipo    = _adados[i,4]
						_wtipocnt = _adados[i,5]
						_wcbase   = _adados[i,2]
						_witem    = _adados[i,3]
						
						// GERAR OCORRENCIAS 05/10 A PARTIR DAS 05/01
						_sSQL := ""	
						_sSQL += " INSERT INTO SN4010 (N4_FILIAL, N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR, N4_MOTIVO, N4_TIPOCNT, N4_CONTA"
						_sSQL += "        , N4_DATA, N4_QUANTD, N4_VLROC1, N4_VLROC2, N4_VLROC3, N4_VLROC4"
						_sSQL += "	      , N4_VLROC5, N4_SERIE, N4_NOTA, N4_VENDA, N4_TXMEDIA, N4_TXDEPR, N4_CCUSTO, N4_LOCAL"
						_sSQL += "	      , N4_SEQ, N4_SUBCTA, N4_SEQREAV, N4_CODBAIX, N4_FILORIG, N4_CLVL, N4_DCONTAB, N4_IDMOV"
						_sSQL += "	      , N4_TPSALDO, N4_QUANTPR, N4_NODIA, N4_DIACTB, N4_CALCPIS, N4_HORA"
						_sSQL += "	      , N4_ORIGEM, N4_LA, N4_LP, N4_CCUSTOT, N4_GRUPOTR, N4_TAXAPAD, N4_SDOC, D_E_L_E_T_"
						_sSQL += "	      , R_E_C_N_O_ )"
						// como o maior numero de itens veio para a matriz, gera tudo na matriz e depois altera se houver necessidade
						_sSQL += " SELECT SN4.N4_FILIAL"
						_sSQL += "      , SN4.N4_CBASE, SN4.N4_ITEM, '10', '05', SN4.N4_MOTIVO, SN4.N4_TIPOCNT, SN4.N4_CONTA"
						_sSQL += "      , SN4.N4_DATA, SN4.N4_QUANTD, SN4.N4_VLROC1, SN4.N4_VLROC2, SN4.N4_VLROC3, SN4.N4_VLROC4"
						_sSQL += "	    , SN4.N4_VLROC5, SN4.N4_SERIE, SN4.N4_NOTA, SN4.N4_VENDA, SN4.N4_TXMEDIA, SN4.N4_TXDEPR, SN4.N4_CCUSTO, SN4.N4_LOCAL"
						_sSQL += "	    , '1', SN4.N4_SUBCTA, SN4.N4_SEQREAV, SN4.N4_CODBAIX, SN4.N4_FILORIG, SN4.N4_CLVL, SN4.N4_DCONTAB, SN4.N4_IDMOV"
						_sSQL += "	    , SN4.N4_TPSALDO, SN4.N4_QUANTPR, SN4.N4_NODIA, SN4.N4_DIACTB, SN4.N4_CALCPIS, SN4.N4_HORA, SN4.N4_ORIGEM, SN4.N4_LA"
						_sSQL += "	    , SN4.N4_LP, SN4.N4_CCUSTOT, SN4.N4_GRUPOTR, SN4.N4_TAXAPAD, SN4.N4_SDOC"
						_sSQL += "	    , SN4.D_E_L_E_T_"
						_sSQL += "	    , ( SELECT TOP 1 R_E_C_N_O_" 
						_sSQL += "		 	  FROM SN4010"
						_sSQL += "		     ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
						_sSQL += "   FROM SN4010 AS SN4"
						_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
						_sSQL += "    AND SN4.N4_FILIAL  = '01'"
						_sSQL += "    AND SN4.N4_OCORR   = '05'"
						_sSQL += "    AND SN4.N4_DATA    = '" + dtos(_wdata) + "'"
						_sSQL += "    AND SN4.N4_TIPO    = '" + _wtipo + "'"
						_sSQL += "    AND SN4.N4_TIPOCNT = '" + _wtipocnt + "'"
						_sSQL += "    AND SN4.N4_CBASE   = '" + _wcbase + "'"
						_sSQL += "    AND SN4.N4_ITEM    = '" + _witem + "'"
						
						if TCSQLExec (_sSQL) < 0
							u_showmemo(_sSQL)
							return
						endif
						
						// verifica SN3010
						_sSQL = ""
						_sSQL += "SELECT N3_SEQ"
						_sSQL += "  FROM SN3010"
						_sSQL += " WHERE N3_FILIAL = '01'"
						_sSQL += "   AND N3_CBASE  = '" + _wcbase + "'"
						_sSQL += "   AND N3_ITEM   = '" + _witem + "'"
						_sSQL += "   AND N3_TIPO   = '10'"
						_aSN3 := U_Qry2Array(_sSQL)
						if len(_aSN3) = 0
		
							_sSQL := ""	
							_sSQL += " INSERT INTO SN3010 ( N3_FILIAL, N3_CBASE, N3_ITEM, N3_TIPO, N3_BAIXA, N3_HISTOR, N3_TPSALDO, N3_TPDEPR"
							_sSQL += "                    , N3_CCONTAB, N3_CUSTBEM, N3_CCUSTO, N3_DINDEPR"
							_sSQL += "                    , N3_VORIG1, N3_AQUISIC, N3_SEQ"
							_sSQL += "                    , N3_FILORIG, N3_RATEIO, N3_CRIDEPR"
							_sSQL += "                    , R_E_C_N_O_, N3_INTP)"
							_sSQL += "               SELECT SN3.N3_FILIAL, SN3.N3_CBASE, SN3.N3_ITEM, '10', SN3.N3_BAIXA, SN3.N3_HISTOR,SN3. N3_TPSALDO, SN3.N3_TPDEPR"
							_sSQL += "                    , SN3.N3_CCONTAB, SN3.N3_CUSTBEM, SN3.N3_CCUSTO, SN3.N3_DINDEPR"
							_sSQL += "                    , SN3.N3_VORIG1, SN3.N3_AQUISIC, '1'"
							_sSQL += "                    , SN3.N3_FILORIG, SN3.N3_RATEIO, SN3.N3_CRIDEPR"
							_sSQL += "                    , ( SELECT TOP 1 R_E_C_N_O_ "
							_sSQL += " 	                        FROM SN3010"
							_sSQL += "                         ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
							_sSQL += "                    , SN3.N3_INTP"
							_sSQL += "                 FROM SN3010 AS SN3"
							_sSQL += "                WHERE SN3.D_E_L_E_T_ = ''"
							_sSQL += "                  AND SN3.N3_FILIAL  = '01'"
							_sSQL += "                  AND SN3.N3_CBASE   = '" + _wcbase + "'"
							_sSQL += "                  AND SN3.N3_ITEM    = '" + _witem + "'"
							_sSQL += "                  AND SN3.N3_TIPO    = '01'"
							
							if TCSQLExec (_sSQL) < 0
								u_showmemo(_sSQL)
								return
							endif
						endif    		
					next
				endif			
			// 4 - GERA OCORRENCIA 01/10 A PARTIR DA OCORRENCIA 01/01
			case mv_par05 = 4
				// BUSCA OS ITENS QUE PRECISAM SER TRATADOS
				_sSQL := ""
				_sSQL += " SELECT SN4.N4_FILIAL"
				_sSQL += "      , SN4.N4_CBASE"
				_sSQL += "      , SN4.N4_ITEM"
				_sSQL += "      , SN4.N4_TIPO"
				_sSQL += "      , SN4.N4_TIPOCNT"
				_sSQL += "      , SN4.N4_DATA"
				_sSQL += "      , SN4.N4_OCORR"
				_sSQL += "   FROM SN4010 AS SN4"
				_sSQL += "  WHERE SN4.D_E_L_E_T_ = ''"
				_sSQL += "    AND SN4.N4_FILIAL  = '01'"
				_sSQL += "    AND SN4.N4_OCORR   = '01'"
				_sSQL += "    AND SN4.N4_TIPO    = '01'"
				_sSQL += "    AND SN4.N4_CBASE   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
				_sSQL += "    AND SN4.N4_ITEM    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
				_sSQL += "    AND NOT EXISTS (SELECT 1"
				_sSQL += " 				        FROM SN4010 AS SN404"
				_sSQL += " 				       WHERE SN404.D_E_L_E_T_ = ''"
				_sSQL += "    					 AND SN404.N4_FILIAL  = SN4.N4_FILIAL"
				_sSQL += "                       AND SN404.N4_OCORR   = SN4.N4_OCORR"
				_sSQL += "    					 AND SN404.N4_TIPO    = '10'"
				_sSQL += " 				         AND SN404.N4_DATA    = SN4.N4_DATA"
				_sSQL += " 				         AND SN404.N4_CBASE   = SN4.N4_CBASE"
				_sSQL += " 				         AND SN404.N4_ITEM    = SN4.N4_ITEM"
				_sSQL += " 				         AND SN404.N4_TIPOCNT = SN4.N4_TIPOCNT)"
				_sSQL += "  ORDER BY SN4.N4_CBASE, SN4.N4_ITEM, SN4.N4_DATA"
				_aDados := U_Qry2Array(_sSQL)
				
				if len (_aDados) > 0
					for i=1 to len(_aDados)
						_wdata    = _adados[i,6]
						_wtipo    = _adados[i,4]
						_wtipocnt = _adados[i,5]
						_wcbase   = _adados[i,2]
						_witem    = _adados[i,3]
						
						// GERAR OCORRENCIAS 04 - DUPLICANDO A 03
						_sSQL := ""	
						_sSQL += " INSERT INTO SN4010 (N4_FILIAL, N4_CBASE, N4_ITEM, N4_TIPO, N4_OCORR, N4_MOTIVO, N4_TIPOCNT, N4_CONTA"
						_sSQL += "        , N4_DATA, N4_QUANTD, N4_VLROC1, N4_VLROC2, N4_VLROC3, N4_VLROC4"
						_sSQL += "	      , N4_VLROC5, N4_SERIE, N4_NOTA, N4_VENDA, N4_TXMEDIA, N4_TXDEPR, N4_CCUSTO, N4_LOCAL"
						_sSQL += "	      , N4_SEQ, N4_SUBCTA, N4_SEQREAV, N4_CODBAIX, N4_FILORIG, N4_CLVL, N4_DCONTAB, N4_IDMOV"
						_sSQL += "	      , N4_TPSALDO, N4_QUANTPR, N4_NODIA, N4_DIACTB, N4_CALCPIS, N4_HORA"
						_sSQL += "	      , N4_ORIGEM, N4_LA, N4_LP, N4_CCUSTOT, N4_GRUPOTR, N4_TAXAPAD, N4_SDOC, D_E_L_E_T_"
						_sSQL += "	      , R_E_C_N_O_ )"
						// como o maior numero de itens veio para a matriz, gera tudo na matriz e depois altera se houver necessidade
						_sSQL += " SELECT SN4.N4_FILIAL"
						_sSQL += "      , SN4.N4_CBASE, SN4.N4_ITEM, '10', '01', SN4.N4_MOTIVO, SN4.N4_TIPOCNT, SN4.N4_CONTA"
						_sSQL += "      , SN4.N4_DATA, SN4.N4_QUANTD, SN4.N4_VLROC1, SN4.N4_VLROC2, SN4.N4_VLROC3, SN4.N4_VLROC4"
						_sSQL += "	    , SN4.N4_VLROC5, SN4.N4_SERIE, SN4.N4_NOTA, SN4.N4_VENDA, SN4.N4_TXMEDIA, SN4.N4_TXDEPR, SN4.N4_CCUSTO, SN4.N4_LOCAL"
						_sSQL += "	    , '1', SN4.N4_SUBCTA, SN4.N4_SEQREAV, SN4.N4_CODBAIX, SN4.N4_FILORIG, SN4.N4_CLVL, SN4.N4_DCONTAB, SN4.N4_IDMOV"
						_sSQL += "	    , SN4.N4_TPSALDO, SN4.N4_QUANTPR, SN4.N4_NODIA, SN4.N4_DIACTB, SN4.N4_CALCPIS, SN4.N4_HORA, SN4.N4_ORIGEM, SN4.N4_LA"
						_sSQL += "	    , SN4.N4_LP, SN4.N4_CCUSTOT, SN4.N4_GRUPOTR, SN4.N4_TAXAPAD, SN4.N4_SDOC"
						_sSQL += "	    , SN4.D_E_L_E_T_"
						_sSQL += "	    , ( SELECT TOP 1 R_E_C_N_O_" 
						_sSQL += "		 	  FROM SN4010"
						_sSQL += "		     ORDER BY R_E_C_N_O_ DESC ) + 1 AS RECNO"
						_sSQL += "   FROM SN4010 AS SN4"
						_sSQL += "  WHERE SN4.D_E_L_E_T_  = ''"
						_sSQL += "    AND SN4.N4_OCORR    = '01'"
						_sSQL += "    AND SN4.N4_DATA     = '" + dtos(_wdata) + "'"
						_sSQL += "    AND SN4.N4_TIPO     = '" + _wtipo + "'"
						_sSQL += "    AND SN4.N4_TIPOCNT  = '" + _wtipocnt + "'"
						_sSQL += "    AND SN4.N4_CBASE    = '" + _wcbase + "'"
						_sSQL += "    AND SN4.N4_ITEM     = '" + _witem + "'"
				
						if TCSQLExec (_sSQL) < 0
							u_showmemo(_sSQL)
							return
						endif		
					next
				endif			
		endcase		
	endif		 								
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Código Base de   ?", "C",  10, 0,  "",   "SN1", {},  ""})
    aadd (_aRegsPerg, {02, "Código Base até  ?", "C",  10, 0,  "",   "SN1", {},  ""})
    aadd (_aRegsPerg, {03, "Item de          ?", "C",  04, 0,  "",   "", {},  ""})
    aadd (_aRegsPerg, {04, "Item até         ?", "C",  04, 0,  "",   "", {},  ""})
    aadd (_aRegsPerg, {05, "Refaz Ocorrencia ?", "N",   1, 0,  "",   "   ", {"03 a partir da 04","04 a partir da 03","05 tipo 10 e SN3","01 tipo 10"},   ""})
	    
    U_ValPerg (cPerg, _aRegsPerg)
Return
