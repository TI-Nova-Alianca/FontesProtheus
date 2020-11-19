//  Programa  : ML_ABC
//  Autor     : Catia Cardos
//  Data      : 04/05/2016
//  Descricao : Relatorio de Curva ABC de Clientes / Fornecedores / Produtos
// 
//  Historico de alteracoes:
//  16/07/2016 - Catia   - opção por parametro de imprimir rentabilidade do cliente (só na opcao cliente e so na impressao)
//  09/06/2017 - Catia   - alterado para buscar o rapel direto do campo F2_VARAPEL 
//  18/08/2017 - Catia   - ocpao de listar insumos
//  22/08/2017 - Catia   - acertado erro na query na opcao fornecedores
//  23/08/2017 - Catia   - query de fornecedores - ajustes para fechar com o total de operacao do analise de entradas
//  17/01/2018 - Catia   - parametro com opção do custo a usar para calcular a rentabilidade
//  25/02/2020 - Claudia - Alterado o uso da view VA_VFAT para a tabela BI_ALIANCA.dbo.VA_FATDADOS
//
//  ---------------------------------------------------------------------------------------------------------------------
User Function ML_ABC()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := ""
    cDesc1  := "Curva ABC "
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_ABC"
    titulo  := "Curva ABC "
    wnrel   := "ML_ABC"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	
    	if val(mv_par04) < 1
    		mv_par04 = '40'
    	endif
    
		do case
    		case mv_par03 = 1
    			_wcomp = 'Clientes'
    		case mv_par03 = 2
    			_wcomp = 'Produtos'
    	endcase
    
		cDesc1  := "Curva ABC - " + _wcomp
		titulo  := "Curva ABC - " + _wcomp
	    
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

    	If nLastKey == 27
	   		Return
    	Endif
	    SetDefault(aReturn,cString)
	    If nLastKey == 27
		   Return
	    Endif
	
	    RptStatus({|| RptDetail()})
	endif			    
Return

Static Function RptDetail()

	SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="RANKING    CODIGO   NOME                                                                    VALOR        PERC"
    if mv_par03 = 1 .and. mv_par08 != 1
    	cabec1 += '        RENTABILIADE'	
    endif
	cabec2:=""
	
	_sQuery := " "
	_MontaQuery()
	//u_showmemo (_sQuery)
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	count to _nRecCount
    procregua (_nRecCount)
    
	if mv_par05 == 1  // gera em planilha
		processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		return
	endif
    
	_wtotal  := 0
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
	    _wtotal = _wtotal + (_sAliasQ) -> TOTAL
	 	(_sAliasQ) -> (dbskip())
    enddo
    
    _wcont   := 0
    _wtotimp := 0
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	if _wcont >= val(mv_par04)
			exit	
		endif
		If li>65
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    
	    _wcont = _wcont + 1
	    @ li, 03 PSAY strzero(_wcont,4)
	    if mv_par03 = 2
			@ li, 11 PSAY LEFT((_sAliasQ) -> CODIGO,4)
		else
			@ li, 11 PSAY LEFT((_sAliasQ) -> CODIGO,6)
		endif
		@ li, 20 PSAY LEFT((_sAliasQ) -> NOME,40)
		@ li, 83 PSAY (_sAliasQ) -> TOTAL Picture "@E 999,999,999.99"
		_wperc = ( (_sAliasQ) -> TOTAL / _wtotal) * 100 
		@ li, 103 PSAY _wperc  Picture "@E 999.99"
		if mv_par03 = 1 .and. mv_par08 != 1
			if mv_par08 = 2
				_wrentab = _Busca1Rent((_sAliasQ) -> CODIGO)
			else
				_wrentab = _Busca2Rent((_sAliasQ) -> CODIGO)
			endif				
			@ li, 115 PSAY _wrentab Picture "@E 999,999,999.99"
    	endif
		li ++
	    _wtotimp = _wtotimp + (_sAliasQ) -> TOTAL
	 	(_sAliasQ) -> (dbskip())
    enddo
    
    li ++
    If li>65
       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif
    @ li, 20 PSAY "Total " + _wcomp + " Listados"
    @ li, 83 PSAY _wtotimp Picture "@E 999,999,999.99"
    _wperc = ( _wtotimp / _wtotal) * 100 
	@ li, 103 PSAY _wperc  Picture "@E 999.99"
	li ++
	li ++
    _wtotdemais = _wtotal - _wtotimp
    @ li, 20 PSAY "Demais " + _wcomp
    @ li, 83 PSAY _wtotdemais Picture "@E 999,999,999.99"
    _wperc = ( _wtotdemais / _wtotal) * 100 
	@ li, 103 PSAY _wperc  Picture "@E 999.99"
	li ++
	li ++
    If li>65
       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif
    @ li, 20 PSAY "Total Geral"
    @ li, 83 PSAY _wtotal Picture "@E 999,999,999.99"
    _wperc = 100
    @ li, 103 PSAY _wperc  Picture "@E 999.99"
    li ++
     
    U_ImpParam (65)
	 
	Set Device To Screen

    If aReturn[5]==1
	   Set Printer TO
	   dbcommitAll()
	   ourspool(wnrel)
    Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return

Static Function _MontaQuery()
_sQuery := " "
do case
	case mv_par03 = 1 // 'Clientes'
		_sQuery += " WITH C AS (SELECT D2_CLIENTE    AS CODIGO"
		_sQuery += " 		         , SA1.A1_NOME   AS NOME"
		_sQuery += " 		         , SUM(SD2.D2_VALBRUT) AS TOTAL"
		_sQuery += " 	          FROM SD2010 AS SD2"
		_sQuery += " 				INNER JOIN SF4010 AS SF4"
		_sQuery += " 					ON (SF4.D_E_L_E_T_ =''"
		_sQuery += " 						AND SF4.F4_CODIGO = SD2.D2_TES"
		_sQuery += " 						AND SF4.F4_MARGEM = '1')"
		_sQuery += " 				INNER JOIN SA1010 AS SA1"
		_sQuery += " 					ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 						AND SA1.A1_COD  = SD2.D2_CLIENTE"
		_sQuery += " 						AND SA1.A1_LOJA = SD2.D2_LOJA)"
		_sQuery += " 			WHERE SD2.D_E_L_E_T_ = ''"
		_sQuery += "              AND SD2.D2_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		  AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "    	    GROUP BY SD2.D2_CLIENTE, SD2.D2_LOJA, SA1.A1_NOME"
		_sQuery += "    	    UNION ALL"
		_sQuery += "    		SELECT D1_FORNECE    AS CODIGO"
		_sQuery += " 				 , SA1.A1_NOME   AS NOME"
		_sQuery += " 				 , ROUND(SUM(SD1.D1_TOTAL+SD1.D1_VALIPI+SD1.D1_ICMSRET),2)*(-1) AS TOTAL"
		_sQuery += " 	 		  FROM SD1010 AS SD1"
		_sQuery += " 				INNER JOIN SF4010 AS SF4"
		_sQuery += " 					ON (SF4.D_E_L_E_T_ =''"
		_sQuery += " 						AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += " 						AND SF4.F4_MARGEM = '2')"
		_sQuery += " 				LEFT JOIN SA1010 AS SA1"
		_sQuery += " 					ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += " 						AND SA1.A1_COD  = SD1.D1_FORNECE"
		_sQuery += " 						AND SA1.A1_LOJA = SD1.D1_LOJA)"
		_sQuery += " 			 WHERE SD1.D_E_L_E_T_ = ''"
		_sQuery += "               AND SD1.D1_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		   AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "               AND SD1.D1_TIPO = 'D'"
		_sQuery += " 			 GROUP BY SD1.D1_FORNECE, SD1.D1_LOJA, SA1.A1_NOME"
 		_sQuery += " )"
		_sQuery += "  SELECT C.CODIGO, C.NOME, SUM(C.TOTAL) AS TOTAL"
		_sQuery += "    FROM C"
 		_sQuery += "   GROUP BY C.CODIGO, C.NOME"
 		_sQuery += "   ORDER BY SUM(C.TOTAL) DESC"
 	case mv_par03 = 2  // 'Produtos'
		_sQuery += " WITH C AS (SELECT D2_COD        AS CODIGO"
		_sQuery += "		         , SB1.B1_DESC   AS NOME"
		_sQuery += "		         , SUM(SD2.D2_VALBRUT) AS TOTAL"
		_sQuery += "	          FROM SD2010 AS SD2"
		_sQuery += "					INNER JOIN SF4010 AS SF4"
		_sQuery += "						ON (SF4.D_E_L_E_T_ =''"
		_sQuery += "							AND SF4.F4_CODIGO = SD2.D2_TES"
		_sQuery += "							AND SF4.F4_MARGEM = '1')"
		_sQuery += "					INNER JOIN SB1010 AS SB1"
		_sQuery += "						ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "							AND SB1.B1_COD = SD2.D2_COD)"
		_sQuery += "			WHERE SD2.D_E_L_E_T_ = ''"
		_sQuery += "              AND SD2.D2_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		  AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "   			GROUP BY SD2.D2_COD, SB1.B1_DESC"
		_sQuery += "   		    UNION ALL"
		_sQuery += "   			SELECT D1_COD        AS CODIGO"
		_sQuery += "				 , SB1.B1_DESC   AS NOME"
		_sQuery += " 				 , ROUND(SUM(SD1.D1_TOTAL+SD1.D1_VALIPI+SD1.D1_ICMSRET),2)*(-1) AS TOTAL"
		_sQuery += "	 		  FROM SD1010 AS SD1"
		_sQuery += "				INNER JOIN SF4010 AS SF4"
		_sQuery += "					ON (SF4.D_E_L_E_T_ =''"
		_sQuery += "						AND SF4.F4_CODIGO = SD1.D1_TES"
		_sQuery += "						AND SF4.F4_MARGEM = '2')"
		_sQuery += "				INNER JOIN SB1010 AS SB1"
		_sQuery += "					ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "						AND SB1.B1_COD  = SD1.D1_COD)"
		_sQuery += "			 WHERE SD1.D_E_L_E_T_ = ''"
		_sQuery += "               AND SD1.D1_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		   AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"		
		_sQuery += "			 GROUP BY SD1.D1_COD, SB1.B1_DESC)"
		_sQuery += "  SELECT C.CODIGO, C.NOME"
	  	_sQuery += "      , SUM(C.TOTAL) AS TOTAL"
   		_sQuery += "   FROM C"
 		_sQuery += "  GROUP BY C.CODIGO, C.NOME"
 		_sQuery += "  ORDER BY SUM(C.TOTAL) DESC"
 	endcase
return

Static Function _Busca1Rent (_wcliente) // Rentabilidade Prevista
	_sQuery := " "
	_sQuery += " WITH C AS ( SELECT SD2.D2_CLIENTE       AS CLIENTE" 	 
    _sQuery += "  	  , SD2.D2_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par09 = 1
		_sQuery += "      , SUM(ROUND(VAFAT.CUSTOREPOS*SD2.D2_QUANT,2)) AS CUSTO"
	else
		_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS CUSTO"
	endif		
	_sQuery += "      , SUM(VAFAT.CUSTOMEDIO)    AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , SUM(SD2.D2_QUANT)        AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      AS NF_ICMSRET"
	_sQuery += "      , SUM(SD2.D2_DESCON)       AS DESCONTO_PEDIDO" 
	_sQuery += "      , SUM(SD2.D2_VALBRUT)      AS NF_VLR_BRT"
	_sQuery += "      , SUM(VAFAT.QUANTIDADE)    AS VAFAT_QUANT"
	_sQuery += "      , SUM(VAFAT.PRUNIT)        AS VAFAT_PRUNIT"
	_sQuery += "      , SUM(VAFAT.TOTAL)         AS VAFAT_TOTAL"
    _sQuery += "      , SUM(VAFAT.VALIPI)        AS VAFAT_VALIPI"
	_sQuery += "      , SUM(VAFAT.ICMSRET)       AS VAFAT_ICMSRET"
	_sQuery += "      , SUM(VAFAT.DESCONTO)      AS VAFAT_DESCONTO"
	_sQuery += "      , SUM(VAFAT.VALBRUT)       AS VAFAT_VALBRUT"
	_sQuery += "      , SUM(VAFAT.VALICM)        AS VAFAT_VALICM"
	_sQuery += "      , SUM(VAFAT.VALPIS)        AS VAFAT_VALPIS"
	_sQuery += "      , SUM(VAFAT.VALCOFINS)     AS VAFAT_COFINS"
	_sQuery += "      , SUM(SD2.D2_TOTAL*SD2.D2_COMIS1/100) AS VLR_COMISSAO"
    _sQuery += "      , SF2.F2_VALMERC           AS TOTPROD_NF"
	_sQuery += "      , SUM(D2_VALBRUT*6/100) AS FRETE"
	//_sQuery += "      , SUM(ROUND(D2_VALBRUT*SF2.F2_VAPERAP/100,2))AS DF_RAPEL"
	_sQuery += "  	  , SF2.F2_VARAPEL       AS DF_RAPEL"
	_sQuery += "      , SUM(VAFAT.DFENCART)  AS DF_ENCARTE"
	_sQuery += "      , SUM(VAFAT.DFFEIRAS)  AS DF_FEIRAS"
	_sQuery += "      , SUM(VAFAT.DFFRETES)  AS DF_FRETES"
	_sQuery += "      , SUM(VAFAT.DFDESCONT) AS DF_DESCONTO"
	_sQuery += "      , SUM(VAFAT.DFDEVOL)   AS DF_DEVOL"
	_sQuery += "      , SUM(VAFAT.DFCAMPANH) AS DF_CAMPANHA"
	_sQuery += "      , SUM(VAFAT.DFABLOJA)  AS DF_ABLOJA"
	_sQuery += "      , SUM(VAFAT.DFCONTRAT) AS DF_CONTRAT"
	_sQuery += "      , SUM(VAFAT.DFOUTROS)  AS DF_OUTROS"
	_sQuery += "	  , 0 AS VLR_BONIFIC"
	_sQuery += "      , 0 AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , 0 AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , 0 AS ST_DEVOLUCOES"
    _sQuery += "      , 0 AS ICMS_DEVOLUCOES"
    _sQuery += "      , 0 AS PIS_DEVOLUCOES"
    _sQuery += "      , 0 AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "    INNER JOIN SA1010 AS SA1" 			
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "				AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('1')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "		LEFT JOIN BI_ALIANCA.dbo.VA_FATDADOS AS VAFAT"
	_sQuery += "			ON (VAFAT.EMPRESA     = '01'"
	_sQuery += "		    	AND VAFAT.ORIGEM  = 'SD2'"
	_sQuery += "				AND VAFAT.FILIAL  = SD2.D2_FILIAL"
	_sQuery += "		    	AND VAFAT.DOC     = SD2.D2_DOC"
	_sQuery += "				AND VAFAT.SERIE   = SD2.D2_SERIE"
	_sQuery += "				AND VAFAT.ITEMNOTA= SD2.D2_ITEM)"
	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_CLIENTE   = '" + _wcliente + "'"
   	_sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, A1_REGIAO, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC, SF2.F2_VARAPEL "
   	// busca bonificacoes
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT SD2.D2_CLIENTE       AS CLIENTE" 	 
    _sQuery += "  	  , SD2.D2_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par09 = 1
		_sQuery += "      , SUM(ROUND(SB1.B1_CUSTD*SD2.D2_QUANT,2)) AS CUSTO"
	else		
		_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS CUSTO"
	endif	
	_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , SUM(SD2.D2_QUANT)        AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      AS NF_ICMSRET"
	_sQuery += "      , 0                        AS DESCONTO_PEDIDO"
	_sQuery += "      , 0				        AS NF_VLR_BRT"
	_sQuery += "      , SUM(VAFAT.QUANTIDADE)   AS VAFAT_QUANT"
	_sQuery += "      , SUM(VAFAT.PRUNIT)       AS VAFAT_PRUNIT"
	_sQuery += "      , SUM(VAFAT.TOTAL)        AS VAFAT_TOTAL"
    _sQuery += "      , SUM(VAFAT.VALIPI)       AS VAFAT_VALIPI"
	_sQuery += "      , SUM(VAFAT.ICMSRET)      AS VAFAT_ICMSRET"
	_sQuery += "      , SUM(VAFAT.DESCONTO)     AS VAFAT_DESCONTO"
	_sQuery += "      , SUM(VAFAT.VALBRUT)      AS VAFAT_VALBRUT"
	_sQuery += "      , SUM(VAFAT.VALICM)       AS VAFAT_VALICM"
	_sQuery += "      , SUM(VAFAT.VALPIS)       AS VAFAT_VALPIS"
	_sQuery += "      , SUM(VAFAT.VALCOFINS)    AS VAFAT_COFINS"      
	_sQuery += "      , 0                       AS VLR_COMISSAO"
	_sQuery += "      , SF2.F2_VALMERC          AS TOTPROD_NF"
	_sQuery += "      , 0                       AS FRETE"
	_sQuery += "      , 0                       AS DF_RAPEL"
	_sQuery += "      , SUM(VAFAT.DFENCART)  AS DF_ENCARTE"
	_sQuery += "      , SUM(VAFAT.DFFEIRAS)  AS DF_FEIRAS"
	_sQuery += "      , SUM(VAFAT.DFFRETES)  AS DF_FRETES"
	_sQuery += "      , SUM(VAFAT.DFDESCONT) AS DF_DESCONTO"
	_sQuery += "      , SUM(VAFAT.DFDEVOL)   AS DF_DEVOL"
	_sQuery += "      , SUM(VAFAT.DFCAMPANH) AS DF_CAMPANHA"
	_sQuery += "      , SUM(VAFAT.DFABLOJA)  AS DF_ABLOJA"
	_sQuery += "      , SUM(VAFAT.DFCONTRAT) AS DF_CONTRAT"
	_sQuery += "      , SUM(VAFAT.DFOUTROS)  AS DF_OUTROS"
	_sQuery += "	  , SUM(SD2.D2_TOTAL)  AS VLR_BONIFIC"
	_sQuery += "      , 0 AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , 0 AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , 0 AS ST_DEVOLUCOES"
    _sQuery += "      , 0 AS ICMS_DEVOLUCOES"
    _sQuery += "      , 0 AS PIS_DEVOLUCOES"
    _sQuery += "      , 0 AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "   INNER JOIN SA1010 AS SA1" 			
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "			AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "			AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('3')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "		LEFT JOIN BI_ALIANCA.dbo.VA_FATDADOS AS VAFAT"
	_sQuery += "			ON (VAFAT.EMPRESA     = '01'"
	_sQuery += "		    	AND VAFAT.ORIGEM  = 'SD2'"
	_sQuery += "				AND VAFAT.FILIAL  = SD2.D2_FILIAL"
	_sQuery += "		    	AND VAFAT.DOC     = SD2.D2_DOC"
	_sQuery += "				AND VAFAT.SERIE   = SD2.D2_SERIE"
	_sQuery += "				AND VAFAT.ITEMNOTA= SD2.D2_ITEM)"
 	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_CLIENTE   = '" + _wcliente + "'"
    _sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, A1_REGIAO, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC "
   	// busca devoluções e reversao de impostos
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT SD1.D1_FORNECE       AS CLIENTE" 	 
    _sQuery += "  	  , SD1.D1_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SF1.F1_EST           AS ESTADO"
	_sQuery += "  	  , SA1.A1_VEND          AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD1.D1_COD           AS PRODUTO"
	_sQuery += "      , 0 AS CUSTO"
	_sQuery += "      , 0 AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , 0 AS NF_QUANT"
	_sQuery += "      , 0 AS NF_VLRUNIT"
	_sQuery += "      , 0 AS NF_VLRPROD"	
	_sQuery += "      , 0 AS NF_VALIPI"
	_sQuery += "      , 0 AS NF_ICMSRET"
	_sQuery += "      , 0 AS DESCONTO_PEDIDO" 
	_sQuery += "      , 0 AS NF_VLR_BRT"
	_sQuery += "      , 0 AS VAFAT_QUANT"
	_sQuery += "      , 0 AS VAFAT_PRUNIT"
	_sQuery += "      , 0 AS VAFAT_TOTAL"
    _sQuery += "      , 0 AS VAFAT_VALIPI"
	_sQuery += "      , 0 AS VAFAT_ICMSRET"
	_sQuery += "      , 0 AS VAFAT_DESCONTO"
	_sQuery += "      , 0 AS VAFAT_VALBRUT"
	_sQuery += "      , 0 AS VAFAT_VALICM"
	_sQuery += "      , 0 AS VAFAT_VALPIS"
	_sQuery += "      , 0 AS VAFAT_COFINS"      
	_sQuery += "      , 0 AS VLR_COMISSAO"
	_sQuery += "      , SF1.F1_VALMERC          AS TOTPROD_NF"
	_sQuery += "      , 0 AS FRETE"
	_sQuery += "      , 0 AS DF_RAPEL"
	_sQuery += "      , 0 AS DF_ENCARTE"
	_sQuery += "      , 0 AS DF_FEIRAS"
	_sQuery += "      , 0 AS DF_FRETES"
	_sQuery += "      , 0 AS DF_DESCONTO"
	_sQuery += "      , 0 AS DF_DEVOL"
	_sQuery += "      , 0 AS DF_CAMPANHA"
	_sQuery += "      , 0 AS DF_ABLOJA"
	_sQuery += "      , 0 AS DF_CONTRAT"
	_sQuery += "      , 0 AS DF_OUTROS"
	_sQuery += "	  , 0 AS VLR_BONIFIC"
   	_sQuery += "      , ROUND(SUM((SD1.D1_VUNIT*SD1.D1_QUANT)+SD1.D1_VALIPI+SD1.D1_ICMSRET),2) AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , SUM(SD1.D1_VALIPI)   AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , SUM(SD1.D1_ICMSRET)  AS ST_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALICM)   AS ICMS_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALIMP6)  AS PIS_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALIMP5)  AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
    _sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_sQuery += "		INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_sQuery += "			ON (SF1.D_E_L_E_T_ = ''
	_sQuery += "				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
	_sQuery += "    			AND SF1.F1_DOC     = SD1.D1_DOC"				
	_sQuery += "				AND SF1.F1_SERIE   = SD1.D1_SERIE"			
	_sQuery += "    			AND SF1.F1_FORNECE = SD1.D1_FORNECE"
	_sQuery += "				AND SF1.F1_LOJA    = SD1.D1_LOJA"
	_sQuery += "	 			AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"
	_sQuery += "		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO  = SD1.D1_TES"
	_sQuery += "				AND SF4.F4_MARGEM  = '2')"
	_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "				AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += "		INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "	 			ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "	 			AND SB1.B1_COD  = SD1.D1_COD)"
 	_sQuery += "   WHERE SD1.D_E_L_E_T_ = ''"
 	_sQuery += "	  AND SD1.D1_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
    _sQuery += "	  AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "	  AND SD1.D1_TIPO = 'D'"
    _sQuery += " 	  AND SD1.D1_FORNECE   = '" + _wcliente + "'"    
   	_sQuery += " GROUP BY SD1.D1_FORNECE , SD1.D1_LOJA, SF1.F1_EST, A1_REGIAO, SA1.A1_VEND, SB1.B1_CODLIN, SD1.D1_COD, SF1.F1_VALMERC ) "
	// monta a margem percentual
	_sQuery += " SELECT CASE WHEN SUM(NF_VLR_BRT) = 0 THEN 0
	_sQuery += "             ELSE (SUM(NF_VLR_BRT) - ( "
	_sQuery += "      			  SUM(CUSTO) "
	_sQuery += "   	  				+ SUM(NF_VALIPI+NF_ICMSRET)"
	_sQuery += "      				+ SUM(VAFAT_VALICM+VAFAT_VALPIS+VAFAT_COFINS)"
	_sQuery += "      				+ SUM(VLR_BONIFIC)"
	_sQuery += "      				+ SUM(VLR_COMISSAO)"
	_sQuery += "      				+ SUM(FRETE)"
	_sQuery += "      				+ SUM(DF_RAPEL)"
	_sQuery += "      				+ SUM(DF_ENCARTE+DF_FEIRAS+DF_FRETES+DF_DESCONTO+DF_DEVOL+DF_CAMPANHA+DF_ABLOJA+DF_CONTRAT+DF_OUTROS)"
	_sQuery += "	  				+ SUM(TOTAL_DEVOLUCOES)) "      
	_sQuery += "      				+ SUM(IPI_DEVOLUCOES) "      
	_sQuery += "     				+ SUM(ST_DEVOLUCOES)"      
	_sQuery += "     				+ SUM(ICMS_DEVOLUCOES)"      
	_sQuery += "      				+ SUM(PIS_DEVOLUCOES)"      
	_sQuery += "      				+ SUM(COFINS_DEVOLUCOES))"
	_sQuery += "     				 / ((CASE WHEN SUM(NF_VLR_BRT) = 0 THEN 1"
	_sQuery += "              			 ELSE SUM(NF_VLR_BRT) "
	_sQuery += "         				 END))*100 "
	_sQuery += "        END AS MARGEM_PERC"
	_sQuery += "  FROM C

	aDados := U_Qry2Array(_sQuery)
    _wrentab := 0
      
    if len (aDados) > 0
    	_wrentab = aDados [1,1] 
    endif
     
return _wrentab

Static Function _Busca2Rent (_wcliente) // Rentabilidade Real
	_sQuery = ""
	_sQuery += " WITH C AS ( SELECT SD2.D2_CLIENTE       AS CLIENTE" 	 
    _sQuery += "  	  , SD2.D2_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par09 = 1
		_sQuery += "      , SUM(ROUND(VAFAT.CUSTOREPOS*SD2.D2_QUANT,2)) AS CUSTO"
	else
		_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS CUSTO"
	endif		
	_sQuery += "      , SUM(VAFAT.CUSTOMEDIO)    AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , SUM(SD2.D2_QUANT)        AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      AS NF_ICMSRET"
	_sQuery += "      , SUM(SD2.D2_DESCON)       AS DESCONTO_PEDIDO" 
	_sQuery += "      , SUM(SD2.D2_VALBRUT)      AS NF_VLR_BRT"
	_sQuery += "      , SUM(VAFAT.QUANTIDADE)    AS VAFAT_QUANT"
	_sQuery += "      , SUM(VAFAT.PRUNIT)        AS VAFAT_PRUNIT"
	_sQuery += "      , SUM(VAFAT.TOTAL)         AS VAFAT_TOTAL"
    _sQuery += "      , SUM(VAFAT.VALIPI)        AS VAFAT_VALIPI"
	_sQuery += "      , SUM(VAFAT.ICMSRET)       AS VAFAT_ICMSRET"
	_sQuery += "      , SUM(VAFAT.DESCONTO)      AS VAFAT_DESCONTO"
	_sQuery += "      , SUM(VAFAT.VALBRUT)       AS VAFAT_VALBRUT"
	_sQuery += "      , SUM(VAFAT.VALICM)        AS VAFAT_VALICM"
	_sQuery += "      , SUM(VAFAT.VALPIS)        AS VAFAT_VALPIS"
	_sQuery += "      , SUM(VAFAT.VALCOFINS)     AS VAFAT_COFINS"
	_sQuery += "      , 0                        AS VLR_COMISSAO"
    _sQuery += "      , SF2.F2_VALMERC           AS TOTPROD_NF"
	_sQuery += "      , ISNULL(SUM(VAFAT.VALORFRETE),0)  AS FRETE"
	_sQuery += "      , ISNULL(SUM(VAFAT.DFRAPEL),0)  AS DF_RAPEL"
	_sQuery += "      , SUM(VAFAT.DFENCART)  AS DF_ENCARTE"
	_sQuery += "      , SUM(VAFAT.DFFEIRAS)  AS DF_FEIRAS"
	_sQuery += "      , SUM(VAFAT.DFFRETES)  AS DF_FRETES"
	_sQuery += "      , SUM(VAFAT.DFDESCONT) AS DF_DESCONTO"
	_sQuery += "      , SUM(VAFAT.DFDEVOL)   AS DF_DEVOL"
	_sQuery += "      , SUM(VAFAT.DFCAMPANH) AS DF_CAMPANHA"
	_sQuery += "      , SUM(VAFAT.DFABLOJA)  AS DF_ABLOJA"
	_sQuery += "      , SUM(VAFAT.DFCONTRAT) AS DF_CONTRAT"
	_sQuery += "      , SUM(VAFAT.DFOUTROS)  AS DF_OUTROS"
	_sQuery += "	  , 0 AS VLR_BONIFIC"
	_sQuery += "      , 0 AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , 0 AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , 0 AS ST_DEVOLUCOES"
    _sQuery += "      , 0 AS ICMS_DEVOLUCOES"
    _sQuery += "      , 0 AS PIS_DEVOLUCOES"
    _sQuery += "      , 0 AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "    INNER JOIN SA1010 AS SA1" 			
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "				AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('1')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "		LEFT JOIN BI_ALIANCA.dbo.VA_FATDADOS AS VAFAT"
	_sQuery += "			ON (VAFAT.EMPRESA     = '01'"
	_sQuery += "		    	AND VAFAT.ORIGEM  = 'SD2'"
	_sQuery += "				AND VAFAT.FILIAL  = SD2.D2_FILIAL"
	_sQuery += "		    	AND VAFAT.DOC     = SD2.D2_DOC"
	_sQuery += "				AND VAFAT.SERIE   = SD2.D2_SERIE"
	_sQuery += "				AND VAFAT.ITEMNOTA= SD2.D2_ITEM)"
	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_CLIENTE   = '" + _wcliente + "'"
    _sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, A1_REGIAO, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC "
   	// busca comissoes
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT SD2.D2_CLIENTE       AS CLIENTE"
   	_sQuery += "  	  , SD2.D2_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	_sQuery += "      , 0                    AS CUSTO"
	_sQuery += "      , 0                    AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , 0                    AS NF_QUANT"
	_sQuery += "      , 0                    AS NF_VLRUNIT"
	_sQuery += "      , 0                    AS NF_VLRPROD"	
	_sQuery += "      , 0  AS NF_VALIPI"
	_sQuery += "      , 0  AS NF_ICMSRET"
	_sQuery += "      , 0  AS DESCONTO_PEDIDO" 
	_sQuery += "      , 0  AS NF_VLR_BRT"
	_sQuery += "      , 0  AS VAFAT_QUANT"
	_sQuery += "      , 0  AS VAFAT_PRUNIT"
	_sQuery += "      , 0  AS VAFAT_TOTAL"
    _sQuery += "      , 0  AS VAFAT_VALIPI"
	_sQuery += "      , 0  AS VAFAT_ICMSRET"
	_sQuery += "      , 0  AS VAFAT_DESCONTO"
	_sQuery += "      , 0  AS VAFAT_VALBRUT"
	_sQuery += "      , 0  AS VAFAT_VALICM"
	_sQuery += "      , 0  AS VAFAT_VALPIS"
	_sQuery += "      , 0  AS VAFAT_COFINS"
	// verificar
	_sQuery += "      , ROUND((SUM(SE3.E3_COMIS)/SF2.F2_VALMERC)*(SD2.D2_TOTAL),2) AS VLR_COMISSAO"
	//
	_sQuery += "      , SF2.F2_VALMERC          AS TOTPROD_NF"
	_sQuery += "      , 0 AS FRETE"
	_sQuery += "      , 0 AS DF_RAPEL"
	_sQuery += "      , 0 AS DF_ENCARTE"
	_sQuery += "      , 0 AS DF_FEIRAS"
	_sQuery += "      , 0 AS DF_FRETES"
	_sQuery += "      , 0 AS DF_DESCONTO"
	_sQuery += "      , 0 AS DF_DEVOL"
	_sQuery += "      , 0 AS DF_CAMPANHA"
	_sQuery += "      , 0 AS DF_ABLOJA"
	_sQuery += "      , 0 AS DF_CONTRAT"
	_sQuery += "      , 0 AS DF_OUTROS"
	_sQuery += "	  , 0 AS VLR_BONIFIC"
	_sQuery += "      , 0 AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , 0 AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , 0 AS ST_DEVOLUCOES"
    _sQuery += "      , 0 AS ICMS_DEVOLUCOES"
    _sQuery += "      , 0 AS PIS_DEVOLUCOES"
    _sQuery += "      , 0 AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "    INNER JOIN SA1010 AS SA1" 			
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "				AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('1')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "		LEFT JOIN SE3010 AS SE3"
	_sQuery += "			ON (SE3.D_E_L_E_T_ = ''"
	_sQuery += "				AND SE3.E3_FILIAL	 = SD2.D2_FILIAL"
	_sQuery += "				AND SE3.E3_SERIE     = SD2.D2_SERIE"
	_sQuery += "				AND SE3.E3_CODCLI    = SD2.D2_CLIENTE"
	_sQuery += "				AND SE3.E3_LOJA      = SD2.D2_LOJA"
	_sQuery += "				AND SE3.E3_NUM       = SD2.D2_DOC)"
	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_CLIENTE   = '" + _wcliente + "'"
    _sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, A1_REGIAO, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC, SD2.D2_TOTAL 	 
    // busca bonificacoes
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT SD2.D2_CLIENTE       AS CLIENTE" 	 
    _sQuery += "  	  , SD2.D2_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par09 = 1
		_sQuery += "      , SUM(ROUND(SB1.B1_CUSTD*SD2.D2_QUANT,2)) AS CUSTO"
	else
		_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS CUSTO"
	endif			
	_sQuery += "      , SUM(VAFAT.CUSTOMEDIO) AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , SUM(SD2.D2_QUANT)        AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      AS NF_ICMSRET"
	_sQuery += "      , 0                        AS DESCONTO_PEDIDO"
	_sQuery += "      , 0				        AS NF_VLR_BRT"
	_sQuery += "      , SUM(VAFAT.QUANTIDADE)   AS VAFAT_QUANT"
	_sQuery += "      , SUM(VAFAT.PRUNIT)       AS VAFAT_PRUNIT"
	_sQuery += "      , SUM(VAFAT.TOTAL)        AS VAFAT_TOTAL"
    _sQuery += "      , SUM(VAFAT.VALIPI)       AS VAFAT_VALIPI"
	_sQuery += "      , SUM(VAFAT.ICMSRET)      AS VAFAT_ICMSRET"
	_sQuery += "      , SUM(VAFAT.DESCONTO)     AS VAFAT_DESCONTO"
	_sQuery += "      , SUM(VAFAT.VALBRUT)      AS VAFAT_VALBRUT"
	_sQuery += "      , SUM(VAFAT.VALICM)       AS VAFAT_VALICM"
	_sQuery += "      , SUM(VAFAT.VALPIS)       AS VAFAT_VALPIS"
	_sQuery += "      , SUM(VAFAT.VALCOFINS)    AS VAFAT_COFINS"      
	_sQuery += "      , 0                       AS VLR_COMISSAO"
	_sQuery += "      , SF2.F2_VALMERC          AS TOTPROD_NF"
	_sQuery += "      , ISNULL(SUM(VAFAT.VALORFRETE),0)  AS FRETE"
	_sQuery += "      , ISNULL(SUM(VAFAT.DFRAPEL),0)  AS DF_RAPEL"
	_sQuery += "      , SUM(VAFAT.DFENCART)  AS DF_ENCARTE"
	_sQuery += "      , SUM(VAFAT.DFFEIRAS)  AS DF_FEIRAS"
	_sQuery += "      , SUM(VAFAT.DFFRETES)  AS DF_FRETES"
	_sQuery += "      , SUM(VAFAT.DFDESCONT) AS DF_DESCONTO"
	_sQuery += "      , SUM(VAFAT.DFDEVOL)   AS DF_DEVOL"
	_sQuery += "      , SUM(VAFAT.DFCAMPANH) AS DF_CAMPANHA"
	_sQuery += "      , SUM(VAFAT.DFABLOJA)  AS DF_ABLOJA"
	_sQuery += "      , SUM(VAFAT.DFCONTRAT) AS DF_CONTRAT"
	_sQuery += "      , SUM(VAFAT.DFOUTROS)  AS DF_OUTROS"
	_sQuery += "	  , SUM(SD2.D2_TOTAL)  AS VLR_BONIFIC"
	_sQuery += "      , 0 AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , 0 AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , 0 AS ST_DEVOLUCOES"
    _sQuery += "      , 0 AS ICMS_DEVOLUCOES"
    _sQuery += "      , 0 AS PIS_DEVOLUCOES"
    _sQuery += "      , 0 AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "   INNER JOIN SA1010 AS SA1" 			
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "			AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "			AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('3')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "		LEFT JOIN BI_ALIANCA.dbo.VA_FATDADOS AS VAFAT"
	_sQuery += "			ON (VAFAT.EMPRESA     = '01'"
	_sQuery += "		    	AND VAFAT.ORIGEM  = 'SD2'"
	_sQuery += "				AND VAFAT.FILIAL  = SD2.D2_FILIAL"
	_sQuery += "		    	AND VAFAT.DOC     = SD2.D2_DOC"
	_sQuery += "				AND VAFAT.SERIE   = SD2.D2_SERIE"
	_sQuery += "				AND VAFAT.ITEMNOTA= SD2.D2_ITEM)"
 	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_CLIENTE   = '" + _wcliente + "'"
    _sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, A1_REGIAO, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC "
   	// busca devoluções e reversao de impostos
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT SD1.D1_FORNECE       AS CLIENTE" 	 
    _sQuery += "  	  , SD1.D1_LOJA          AS LOJA" 	 
    _sQuery += "  	  , SF1.F1_EST           AS ESTADO"
	_sQuery += "  	  , SA1.A1_VEND          AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD1.D1_COD           AS PRODUTO"
	_sQuery += "      , 0 AS CUSTO"
	_sQuery += "      , 0 AS VAFAT_CUSTOMEDIO"
	_sQuery += "      , 0 AS NF_QUANT"
	_sQuery += "      , 0 AS NF_VLRUNIT"
	_sQuery += "      , 0 AS NF_VLRPROD"	
	_sQuery += "      , 0 AS NF_VALIPI"
	_sQuery += "      , 0 AS NF_ICMSRET"
	_sQuery += "      , 0 AS DESCONTO_PEDIDO" 
	_sQuery += "      , 0 AS NF_VLR_BRT"
	_sQuery += "      , 0 AS VAFAT_QUANT"
	_sQuery += "      , 0 AS VAFAT_PRUNIT"
	_sQuery += "      , 0 AS VAFAT_TOTAL"
    _sQuery += "      , 0 AS VAFAT_VALIPI"
	_sQuery += "      , 0 AS VAFAT_ICMSRET"
	_sQuery += "      , 0 AS VAFAT_DESCONTO"
	_sQuery += "      , 0 AS VAFAT_VALBRUT"
	_sQuery += "      , 0 AS VAFAT_VALICM"
	_sQuery += "      , 0 AS VAFAT_VALPIS"
	_sQuery += "      , 0 AS VAFAT_COFINS"      
	_sQuery += "      , 0 AS VLR_COMISSAO"
	_sQuery += "      , SF1.F1_VALMERC          AS TOTPROD_NF"
	_sQuery += "      , 0 AS FRETE"
	_sQuery += "      , 0 AS DF_RAPEL"
	_sQuery += "      , 0 AS DF_ENCARTE"
	_sQuery += "      , 0 AS DF_FEIRAS"
	_sQuery += "      , 0 AS DF_FRETES"
	_sQuery += "      , 0 AS DF_DESCONTO"
	_sQuery += "      , 0 AS DF_DEVOL"
	_sQuery += "      , 0 AS DF_CAMPANHA"
	_sQuery += "      , 0 AS DF_ABLOJA"
	_sQuery += "      , 0 AS DF_CONTRAT"
	_sQuery += "      , 0 AS DF_OUTROS"
	_sQuery += "	  , 0 AS VLR_BONIFIC"
   	_sQuery += "      , ROUND(SUM((SD1.D1_VUNIT*SD1.D1_QUANT)+SD1.D1_VALIPI+SD1.D1_ICMSRET),2) AS TOTAL_DEVOLUCOES"	 
    _sQuery += "      , SUM(SD1.D1_VALIPI)   AS IPI_DEVOLUCOES" 	 
    _sQuery += "      , SUM(SD1.D1_ICMSRET)  AS ST_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALICM)   AS ICMS_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALIMP6)  AS PIS_DEVOLUCOES"
    _sQuery += "      , SUM(SD1.D1_VALIMP5)  AS COFINS_DEVOLUCOES"
    _sQuery += "      , A1_REGIAO AS REGIAO" 	 
    _sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_sQuery += "		INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_sQuery += "			ON (SF1.D_E_L_E_T_ = ''
	_sQuery += "				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
	_sQuery += "    			AND SF1.F1_DOC     = SD1.D1_DOC"				
	_sQuery += "				AND SF1.F1_SERIE   = SD1.D1_SERIE"			
	_sQuery += "    			AND SF1.F1_FORNECE = SD1.D1_FORNECE"
	_sQuery += "				AND SF1.F1_LOJA    = SD1.D1_LOJA"
	_sQuery += "	 			AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"
	_sQuery += "		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO  = SD1.D1_TES"
	_sQuery += "				AND SF4.F4_MARGEM  = '2')"
	_sQuery += "		INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "				AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += "		INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "	 			ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "	 			AND SB1.B1_COD  = SD1.D1_COD)"
 	_sQuery += "   WHERE SD1.D_E_L_E_T_ = ''"
 	_sQuery += "	  AND SD1.D1_FILIAL    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
    _sQuery += "	  AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "	  AND SD1.D1_TIPO = 'D'"
    _sQuery += " 	  AND SD1.D1_FORNECE   = '" + _wcliente + "'"    
   	_sQuery += " GROUP BY SD1.D1_FORNECE , SD1.D1_LOJA, SF1.F1_EST, A1_REGIAO, SA1.A1_VEND, SB1.B1_CODLIN, SD1.D1_COD, SF1.F1_VALMERC ) "
	// monta as margens percentual
	_sQuery += " SELECT CASE WHEN SUM(NF_VLR_BRT) = 0 THEN 0
	_sQuery += "             ELSE (SUM(NF_VLR_BRT) - ( "
	_sQuery += "      			  SUM(CUSTO) "
	_sQuery += "   	  				+ SUM(NF_VALIPI+NF_ICMSRET)"
	_sQuery += "      				+ SUM(VAFAT_VALICM+VAFAT_VALPIS+VAFAT_COFINS)"
	_sQuery += "      				+ SUM(VLR_BONIFIC)"
	_sQuery += "      				+ SUM(VLR_COMISSAO)"
	_sQuery += "      				+ SUM(FRETE)"
	_sQuery += "      				+ SUM(DF_RAPEL)"
	_sQuery += "      				+ SUM(DF_ENCARTE+DF_FEIRAS+DF_FRETES+DF_DESCONTO+DF_DEVOL+DF_CAMPANHA+DF_ABLOJA+DF_CONTRAT+DF_OUTROS)"
	_sQuery += "	  				+ SUM(TOTAL_DEVOLUCOES)) "      
	_sQuery += "      				+ SUM(IPI_DEVOLUCOES) "      
	_sQuery += "     				+ SUM(ST_DEVOLUCOES)"      
	_sQuery += "     				+ SUM(ICMS_DEVOLUCOES)"      
	_sQuery += "      				+ SUM(PIS_DEVOLUCOES)"      
	_sQuery += "      				+ SUM(COFINS_DEVOLUCOES))"
	_sQuery += "     				 / ((CASE WHEN SUM(NF_VLR_BRT) = 0 THEN 1"
	_sQuery += "              			 ELSE SUM(NF_VLR_BRT) "
	_sQuery += "         				 END))*100 "
	_sQuery += "        END AS MARGEM_PERC"
	_sQuery += "  FROM C

	aDados := U_Qry2Array(_sQuery)
    _wrentab := 0
      
    if len (aDados) > 0
    	_wrentab = aDados [1,1] 
    endif
     
return _wrentab

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Periodo de            ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Periodo ate           ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "ABC de                ? ", "N", 1,  0,  "",   "   ", {"Clientes", "Produtos"},    ""})
	aadd (_aRegsPerg, {04, "Listar primeiros      ? ", "C", 6,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Gera em Planilha      ? ", "N", 2,  0,  "",   "   ", {"Sim", "Nao"}, "Indique se deseja gerar em planilha."})
	aadd (_aRegsPerg, {06, "Filial de             ? ", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {07, "Filial até            ? ", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {08, "Imprime Rentabilidade ? ", "N", 1,  0,  "",   "   ", {"Nao","Prevista","Real"}, "Indique se deseja gerar rentabilidade de clientes."})
    aadd (_aRegsPerg, {09, "Usa Custo             ? ", "N", 1,  0,  "",   "   ", {"Sandart", "Medio"},      ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
	