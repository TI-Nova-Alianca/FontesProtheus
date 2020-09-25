//  Programa...: ML_LOJTABVEN
//  Autor......: Catia Cardoso
//  Data.......: 29/06/2018
//  Descricao..: VENDAS LOJAS - ANALISE TABELA USADA NA VENDA  
// 
// 	Definiçoes das tabela enviadas pelo GIOVANI
//  01 - Preço Gôndola;
//  02 - Preço Caixa Fechada;
//  03 - Preço Associados e Funcionários;
//  04 - Preço Parceiros / Revenda / Eventos;
//  05 - Preço Festa de Comunidade / Feira Ponta de Estoque;
//  06 - Preço Representantes;
//  07 - Preço Representantes;
//  08 - Preço Tumelero;
//  09 - Preço Representantes;
//
//  Historico de alterações
//
//  11/01/2019 - Catia - Consulta/Relatorio desabilitado - programa substituido pelo ML_LOJFATTAB

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function ML_LOJTABVEN()
	local i := 0
	
	u_help ("Consulta/Relatorio desabilitado")
	return

	cPerg   := "ML_LOJTABVEN"
	
	if ! u_zzuvl ('083', __cUserId, .T.)
		return
	endif
    
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
		_lContinua = .T.
		
		// Controle de semaforo.
		_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SA1"))
		if _nLock == 0
			msgalert ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
			_lContinua = .F.
		endif
		
		if _lContinua
			tcsqlexec ('DROP TABLE TMP_TABVEN')
	        // gera tabela temporaria			
			_sSQL  = " "
			_sSQL += "SELECT SL2.L2_FILIAL  AS FILIAL"  		// 1
	 		_sSQL += "     , SL2.L2_EMISSAO AS DTEMIS"			// 2
	 		_sSQL += "     , SL2.L2_DOC     AS DOC"				// 3
	 		_sSQL += "	   , SL2.L2_SERIE   AS SERIE"			// 4
	 		_sSQL += "     , SL2.L2_PRODUTO AS PRODUTO"			// 5	
	 		_sSQL += "	   , SB1.B1_DESC    AS DESCR"			// 6
	 		_sSQL += "	   , SL2.L2_QUANT   AS QUANT"			// 7
	 		_sSQL += "	   , SL2.L2_VRUNIT  AS VLRUNIT"			// 8
	 		_sSQL += "     , SL2.L2_VLRITEM AS VLRITEM"			// 9
	 		_sSQL += "	   , SL2.L2_PRCTAB  AS VLRTAB"			// 10
		 	_sSQL += "	   , SL2.L2_TABELA  AS TABELA"			// 11
		 	_sSQL += "	   , SL1.L1_CONTATO AS CONTATO"			// 12
		 	_sSQL += "	   , SL1.L1_VACGC   AS VAGCG"			// 13
		 	_sSQL += "	   , (CASE WHEN SL2.L2_TABELA = '8' THEN 'SIM' ELSE '   ' END) AS PARCEIRO" 	// 14
		 	_sSQL += "	   , SPACE(3) AS FUNCIONARIO"			// 15
		 	_sSQL += "	   , SPACE(3) AS ASSOCIADO"				// 16
		 	_sSQL += "	   , SPACE(45) AS OBSERVACAO"			// 17
		 	_sSQL += "	   , ROW_NUMBER() OVER(ORDER BY SL2.L2_FILIAL,SL2.L2_DOC) AS RECNO"		// 18
	  		_sSQL += "  INTO TMP_TABVEN"
	  		_sSQL += "  FROM SL2010 AS SL2"
			_sSQL += "		INNER JOIN SD2010 AS SD2"
			_sSQL += "			ON (SD2.D_E_L_E_T_ = ''"
			_sSQL += "				AND SD2.D2_FILIAL = SL2.L2_FILIAL"
			_sSQL += "				AND SD2.D2_DOC    = SL2.L2_DOC"
			_sSQL += "				AND SD2.D2_SERIE  = SL2.L2_SERIE"
			_sSQL += "				AND SD2.D2_ITEM   = SL2.L2_ITEM"
			_sSQL += "				AND SD2.D2_COD    = SL2.L2_PRODUTO)"
			_sSQL += "		INNER JOIN SB1010 AS SB1"
			_sSQL += "			ON (SB1.D_E_L_E_T_ = ''"
			_sSQL += "				AND SB1.B1_COD = SD2.D2_COD)"
			_sSQL += "		INNER JOIN SL1010 AS SL1"
			_sSQL += "			ON (SL1.D_E_L_E_T_ = ''"
			_sSQL += "				AND SL1.L1_FILIAL = SL2.L2_FILIAL"
			_sSQL += "				AND SL1.L1_DOC    = SL2.L2_DOC"
			_sSQL += "				AND SL1.L1_SERIE  = SL2.L2_SERIE)"
			_sSQL += " WHERE SL2.D_E_L_E_T_ = ''"
			_sSQL += "   AND SL2.L2_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		    _sSQL += "   AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_sSQL += "   AND SL2.L2_SERIE IN ('001','002') "
			TCSQLExec (_sSQL)
			// le a tabela temporaria e verifica as vendas
	        _sQuery := " "
		   	_sQuery += " SELECT *"
	     	_sQuery += "   FROM TMP_TABVEN"
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0
				for i = 1 to len(_aDados)
					_wtabela  = _aDados[i,11]
		 			_wcgc     = _aDados[i,13]
		 			if _wtabela = '3'
		 				// analisa vendas conforme a tabela usada - 03 - Preço Associados e Funcionários;
						// se foi usada a tabela 3, obrigatoriamente tem que ter sido venda para associado ou funcionario
						_sQuery  = ""
						_sQuery += "SELECT TOP 1 SA2.A2_CGC"
					   	_sQuery += "  FROM SA2010 AS SA2"
						_sQuery += "  	INNER JOIN SZI010 AS SZI"
						_sQuery += "		ON (SZI.D_E_L_E_T_ = ''"
						_sQuery += "	    	AND SZI.ZI_TM    = '13' "
						_sQuery += "			AND SZI.ZI_ASSOC = SA2.A2_COD)"
					  	_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
					  	_sQuery += "   AND SA2.A2_CGC = '" + _wcgc + "'"
					  	_aAssoc := U_Qry2Array(_sQuery)
						if len(_aAssoc) > 0
							_sSQL  = ""
							_sSQL += " UPDATE TMP_TABVEN"
							_sSQL += "	  SET ASSOCIADO = 'SIM'"
				 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 9999")
	 						TCSQLExec (_sSQL)
						endif
						// se foi usada a tabela 3, obrigatoriamente tem que ter sido venda para associado ou funcionario
						_sQuery  = ""
						_sQuery += "SELECT ZAD_CPF"
 						_sQuery += "     , ZAD_SITUA"
 						_sQuery += "  FROM ZAD010"
						_sQuery += " WHERE D_E_L_E_T_ = ''"
						_sQuery += "   AND ZAD_CPF = '" + _wcgc + "'"
						_sQuery += "   AND ZAD_SITUA NOT IN ('3','4') " // busca desligados
					  	_aFunc := U_Qry2Array(_sQuery)
						if len(_aFunc) > 0
							_sSQL = ""
							_sSQL += " UPDATE TMP_TABVEN"
							_sSQL += "	  SET FUNCIONARIO = 'EX'"
				 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 9999")
	 						TCSQLExec (_sSQL)
						endif	
						// se foi usada a tabela 3, obrigatoriamente tem que ter sido venda para associado ou funcionario
						_sQuery  = ""
						_sQuery += "SELECT ZAD_CPF"
 						_sQuery += "     , ZAD_SITUA"
 						_sQuery += "  FROM ZAD010"
						_sQuery += " WHERE D_E_L_E_T_ = ''"
						_sQuery += "   AND ZAD_CPF = '" + _wcgc + "'"
						_sQuery += "   AND ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados
					  	_aFunc := U_Qry2Array(_sQuery)
						if len(_aFunc) > 0
							_sSQL = ""
							_sSQL += " UPDATE TMP_TABVEN"
							_sSQL += "	  SET FUNCIONARIO = 'SIM'"
				 			_sSQL += "  WHERE RECNO     = "  + TRANSF(i, "@ 9999")
	 						TCSQLExec (_sSQL)
						endif	
					endif															 	
				next
			endif
			// le novamente a tabela temporaria e gera as observacoes de não conformidade
			_sSQL = ""
			_sSQL += " UPDATE TMP_TABVEN"
			_sSQL += "    SET OBSERVACAO  = 'NAO CONFORME,CPF NAO É FUNCIONARIO/ASSOCIADO'"
 			_sSQL += "  WHERE TABELA      = '3'"
   			_sSQL += "    AND PARCEIRO    != 'SIM'"
   			_sSQL += "    AND FUNCIONARIO != 'SIM'"
   			_sSQL += "    AND ASSOCIADO   != 'SIM'"
   			TCSQLExec (_sSQL)
        	_sQuery = ""
			_sQuery += " WITH C AS ("
			_sQuery += " 	SELECT PRODUTO, DESCR, QUANT, SB1P.B1_CODPAI, SB1C.B1_CONV"
     		_sQuery += " 		 , QUANT/SB1C.B1_CONV AS RESTO"
     		_sQuery += " 		 , CASE WHEN (QUANT/SB1C.B1_CONV) < 1 THEN 'ERRO' ELSE '' END AS OBS"
	 		_sQuery += " 		 , TMP.RECNO"
  			_sQuery += "    FROM TMP_TABVEN AS TMP"
			_sQuery += " 		INNER JOIN SB1010 AS SB1P"
			_sQuery += " 			ON (SB1P.B1_COD = TMP.PRODUTO)" 
			_sQuery += " 		INNER JOIN SB1010 AS SB1C"
			_sQuery += " 			ON (SB1C.B1_COD = SB1P.B1_CODPAI)" 
 			_sQuery += "   WHERE TABELA = '2'"
 			_sQuery += "	 )"
 			_sQuery += " SELECT *"
   			_sQuery += "   FROM C"
  			_sQuery += "  WHERE C.OBS != ''"
        	_aDados := U_Qry2Array(_sQuery)
        	if len(_aDados) > 0
				for i = 1 to len(_aDados)
					_sSQL = ""
					_sSQL += " UPDATE TMP_TABVEN"
					_sSQL += "	  SET OBSERVACAO = 'NAO CONFORME,PR CAIXA FECHADA, QUANT INFERIOR'"  
		 			_sSQL += "  WHERE TABELA = '2' 
		 			_sSQL += "    AND RECNO  = "  + TRANSF(_aDados[i,8], "@ 9999")
					TCSQLExec (_sSQL)
				next												
			endif 	
			// gera array para visualizar dados
   			_sQuery = ""
   			_sQuery += "SELECT FILIAL"
	 		_sQuery += "     , DTEMIS"
	 		_sQuery += "     , DOC"
	 		_sQuery += "	 , SERIE"
	 		_sQuery += "     , PRODUTO"
	 		_sQuery += "	 , DESCR"
	 		_sQuery += "	 , QUANT"
	 		_sQuery += "	 , VLRUNIT"
		 	_sQuery += "	 , TABELA"
		 	_sQuery += "	 , PARCEIRO"
		 	_sQuery += "	 , FUNCIONARIO"
		 	_sQuery += "	 , ASSOCIADO"
		 	_sQuery += "	 , OBSERVACAO"
		 	_sQuery += "  FROM TMP_TABVEN"
		 	if mv_par05 == 2
		 		_sQuery += " WHERE OBSERVACAO != ''"
			endif		 		  
			_aDados := U_Qry2Array(_sQuery)
			if len(_aDados) > 0 
				do while .t.
					_aCols = {}
					aadd (_aCols, { 1, "Filial"      ,  10, "@!"})
					aadd (_aCols, { 2, "Data"        ,  30, "@D"})
	    			aadd (_aCols, { 3, "Cupom"     	 ,  30, "@!"})
	    			aadd (_aCols, { 4, "Serie"       ,  10, "@!"})
	    			aadd (_aCols, { 5, "Produto"     ,  40, "@!"})
					aadd (_aCols, { 6, "Descricao"   ,  80, "@!"})
					aadd (_aCols, { 7, "Quantidade"  ,  40, "@E 9999999"})
					aadd (_aCols, { 8, "Vlr.Unit"    ,  40, "@E 9,999.99"})
					aadd (_aCols, { 9, "Tabela"      ,  10, "@!"})
					aadd (_aCols, {10, "Parceiro"    ,  40, "@!"})
					aadd (_aCols, {11, "Funcionario" ,  40, "@!"})
					aadd (_aCols, {12, "Associado"   ,  40, "@!"})
					aadd (_aCols, {13, "Observações" , 100, "@!"})
					if mv_par01 == mv_par02
						_wperiodo = "Dia : " + dtoc(mv_par01)
					else
						_wperiodo = "Periodo de : " + dtoc(mv_par01) + " até " + dtoc (mv_par02) 											
					endif
					if mv_par03 == mv_par04
						_wfiliais = " - Filial : " + mv_par03
					else
						_wfiliais = " - Filiais de : " + mv_par03 + " até " + mv_par04 											
					endif
					 _wlinha = U_F3Array (_aDados, "Vendas Loja - Analise Tabelas usadas nas Vendas - " + _wperiodo + _wfiliais, _aCols, oMainWnd:nClientWidth - 50, NIL, "")
					if _wlinha = 0
						exit
					endif
				enddo				
			else
				msgalert("Não foram encontrados dados para consulta")
			endif
		endif
	endif			
return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data de Venda de         ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data de Venda até        ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Loja de                  ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {04, "Loja até                 ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {05, "Apenas não conformidades ?", "N", 1,  0,  "",   "   ", {"Nao", "Sim"}, ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return