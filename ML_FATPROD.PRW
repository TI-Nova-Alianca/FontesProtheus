// Programa  : ML_FATPROD
// Autor     : Catia Cardos
// Data      : 05/05/2016
// Descricao : Relatorio de Faturamento por Produto quantidade e valor
// 
// Historico de alteracoes:
// --------------------------------------------------------------------------
User Function ML_FATPROD()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := ""
    cDesc1  := "Faturamento por Produto"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_FATPROD"
    titulo  := "Faturamento por Produto"
    wnrel   := "ML_FATPROD"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    
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
	Local _nTipo    := 0
	Local _nUnidade := 0
	
	SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="CODIGO    DESCRICAO                                                  TIPO   UM           QUANTIDADE               VALOR"
	cabec2:=""
	
	_sQuery := " "
	_sQuery += " WITH C AS (SELECT D2_COD              AS CODIGO"
	_sQuery += "		         , SB1.B1_DESC         AS NOME"
	_sQuery += "		         , SUM(SD2.D2_QUANT)   AS QUANT"
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
	_sQuery += "              AND SD2.D2_FILIAL  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += " 	  		  AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "   			GROUP BY SD2.D2_COD, SB1.B1_DESC"
	_sQuery += "   		    UNION ALL"
	_sQuery += "   			SELECT D1_COD            AS CODIGO"
	_sQuery += "				 , SB1.B1_DESC       AS NOME"
	_sQuery += "				 , SUM(SD1.D1_QUANT) AS QUANT"
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
	_sQuery += "               AND SD1.D1_FILIAL  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += " 	  		   AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "               AND SD1.D1_TIPO = 'D'"
	_sQuery += "			 GROUP BY SD1.D1_COD, SB1.B1_DESC)"
	_sQuery += "  SELECT C.CODIGO, C.NOME"
	_sQuery += "      , SUM(C.QUANT) AS QUANT"
  	_sQuery += "      , SUM(C.TOTAL) AS TOTAL"
	_sQuery += "   FROM C"
	_sQuery += "  GROUP BY C.CODIGO, C.NOME"
	do case
		case mv_par03 = 1
			_sQuery += "  ORDER BY CODIGO"
		case mv_par03 = 2
			_sQuery += "  ORDER BY NOME"
		case mv_par03 = 3
			_sQuery += "  ORDER BY SUM(C.QUANT) DESC"
		case mv_par03 = 4
			_sQuery += "  ORDER BY SUM(C.TOTAL) DESC"
	endcase		
	
	//u_showmemo (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	count to _nRecCount
    procregua (_nRecCount)
        
    if mv_par04 == 1  // gera em planilha
		processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		return
	endif
    
    _aUnidade  := {}
	_nUnidade  := 0
	_aTipo  := {}
	_nTipo  := 0
	
    _wtotquant := 0
    _wtotvlr   := 0
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    
    	_wtipo = fBuscaCpo ('SB1', 1, xfilial('SB1') + (_sAliasQ) -> CODIGO, "B1_TIPO")
		_wun   = fBuscaCpo ('SB1', 1, xfilial('SB1') + (_sAliasQ) -> CODIGO, "B1_UM")
		    
    	if mv_par07 == 2
	    	If li>65
		       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		    Endif
		    @ li, 001 PSAY LEFT((_sAliasQ) -> CODIGO,4)
			@ li, 010 PSAY LEFT((_sAliasQ) -> NOME,40)
			@ li, 070 PSAY _wtipo
			@ li, 076 PSAY _wun
			@ li, 083 PSAY (_sAliasQ) -> QUANT Picture "@E 9,999,999,999.99"
			@ li, 103 PSAY (_sAliasQ) -> TOTAL Picture "@E 9,999,999,999.99"
		    li ++
		endif	    
	    // acumula array por tipo de produto
		_nTipo = ascan (_aTipo, {|_aVal| _aVal [1] ==  _wtipo})
		if _nTipo == 0
			aadd (_aTipo, { _wtipo, 0,0 } )
			_nTipo = len (_aTipo)
		endif
		_aTipo [_nTipo, 2] += (_sAliasQ) -> QUANT
		_aTipo [_nTipo, 3] += (_sAliasQ) -> TOTAL
		
	    // acumula array por unidade
		_nUnidade = ascan (_aUnidade, {|_aVal| _aVal [1] ==  _wun})
		if _nUnidade == 0
			aadd (_aUnidade, { _wun, 0,0})
			_nUnidade = len (_aUnidade)
		endif
		_aUnidade [_nUnidade, 2] += (_sAliasQ) -> QUANT
		_aUnidade [_nUnidade, 3] += (_sAliasQ) -> TOTAL
		
		(_sAliasQ) -> (dbskip())
    enddo
    
    li ++
    if mv_par07 == 1
    	li:= 80 // força que salte a pagina antes de imprimir os resumos
	endif    	
    // Imprime totais por tipo
	if len (_aTipo) > 0
		if li > 65
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		endif
				
		_aTipo = asort (_aTipo,,, {|_x, _y| _x [1] < _y [1]})
		@ li, 0 psay "Totais por TIPO:"
		li += 2
		@ li, 0 psay "TIPO           Quantidade              Valor
		li ++
		@ li, 0 psay "-----   -----------------  -----------------"
		li ++
		_wtot2 :=0
		_wtot3 :=0
		for _nTipo = 1 to len (_aTipo)
			if li > 65
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay U_TamFixo (_aTipo [_nTipo, 1] , 8) + "   " + ;
				    transform (_aTipo [_nTipo, 2], "@E 999,999,999.99") + "     " + ;                   // quantidade
				    transform (_aTipo [_nTipo, 3], "@E 999,999,999.99")                                 // valor
			li ++
			// totaliza tipo
			_wtot2 = _wtot2 + (_aTipo [_nTipo, 2])
			_wtot3 = _wtot3 + (_aTipo [_nTipo, 3])
		next
		
		@ li, 0 psay "-----   -----------------  -----------------"
		li ++
		@ li, 0 psay U_TamFixo ( "", 8) + "                      " + ;
		        transform ( _wtot3, "@E 999,999,999.99")                              // valor
		li ++
		li += 2
	endif
	
	if len (_aUnidade) > 0
		if li > 65
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		endif
				
		_aUnidade = asort (_aUnidade,,, {|_x, _y| _x [1] < _y [1]})
		@ li, 0 psay "Totais por UNIDADE:"
		li += 2
		@ li, 0 psay "UNIDADE        Quantidade               Valor
		li ++
		@ li, 0 psay "-------  ----------------   -----------------"
		li ++
		_wtot2 :=0
		_wtot3 :=0
		for _nUnidade = 1 to len (_aUnidade)
			if li > 65
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay U_TamFixo (_aUnidade [_nUnidade, 1] , 8) + "   " + ;
				    transform (_aUnidade [_nUnidade, 2], "@E 999,999,999.99") + "      " + ;                   // quantidade
				    transform (_aUnidade [_nUnidade, 3], "@E 999,999,999.99")                                   // valor
			li ++
			// totaliza UNIDADES
			_wtot2 = _wtot2 + (_aUnidade [_nUnidade, 2])
			_wtot3 = _wtot3 + (_aUnidade [_nUnidade, 3])
		next
		@ li, 0 psay "-------  ----------------   -----------------"
		li ++
		@ li, 0 psay U_TamFixo ( "", 8) + "                       " + ;
		        transform ( _wtot3, "@E 999,999,999.99")                                    // valor
		li ++
		li += 2
	endif
	
    U_ImpParam (65)
	 
	Set Device To Screen

    If aReturn[5]==1
	   Set Printer TO
	   dbcommitAll()
	   ourspool(wnrel)
    Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Periodo de           ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Periodo ate          ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Odernar por          ? ", "N", 1,  0,  "",   "   ", {"Codigo", "Descricao","Quantidade","Valor"},    ""})
	aadd (_aRegsPerg, {04, "Gera em Planilha     ? ", "N", 1,  0,  "",   "   ", {"Sim", "Nao"}, "Indique se deseja gerar em planilha."})
	aadd (_aRegsPerg, {05, "Filial de            ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {06, "Filial até           ?", "C", 2, 0,  "",   "SM0", {},                         ""})
	aadd (_aRegsPerg, {07, "Imprime Apenas Resumo?", "N", 1,  0,  "",   "   ", {"Sim", "Nao"}, "Indique se deseja imprimir apenas resumo."})
	U_ValPerg (cPerg, _aRegsPerg)
Return
