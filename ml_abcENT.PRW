//  Programa  : ML_ABCENT
//  Autor     : Catia Cardoso
//  Data      : 26/01/2018
//  Descricao : Relatorio de Curva ABC de Clientes / Fornecedores / Produtos
// 
//  Historico de alteracoes:
//
//  29/01/2018 - Catia - Alterado para nao validar F4_duplic e nem F4_estoque na opcao demais fornecedores
//  ---------------------------------------------------------------------------------------------------------------------
User Function ML_ABCENT()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := ""
    cDesc1  := "Curva ABC - Entradas"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_ABCENT"
    titulo  := "Curva ABC - Entradas "
    wnrel   := "ML_ABCENT"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	
    	if val(mv_par04) < 1
    		mv_par04 = '40'
    	endif
    
		do case
    		case mv_par03 = 1
    			_wcomp = 'Fornecedores'
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
	case mv_par03 = 1 // 'Fornecedores' 
 		_sQuery += "   WITH C AS (SELECT D1_FORNECE    AS CODIGO"
		_sQuery += "   			       , SA2.A2_NOME   AS NOME"
		_sQuery += "                   , SUM(ROUND(SD1.D1_DESPESA + SD1.D1_SEGURO + SD1.D1_VALFRE + SD1.D1_TOTAL + SD1.D1_VALIPI + SD1.D1_ICMSRET - SD1.D1_VALDESC,2)) AS TOTAL"
		_sQuery += "   	 			FROM SD1010 AS SD1"
		_sQuery += "   					INNER JOIN SF4010 AS SF4"
		_sQuery += "   						ON (SF4.D_E_L_E_T_ =''"
		do case
			case mv_par08 = 1
					_sQuery += "   				AND SF4.F4_MARGEM = '6'"
			case mv_par08 = 2
					_sQuery += "   				AND SF4.F4_MARGEM = '7'"
			case mv_par08 = 3
					_sQuery += "   				AND SF4.F4_MARGEM = '8'"
			case mv_par08 = 4
					_sQuery += "   				AND SF4.F4_MARGEM IN ('9','4','5')"
			case mv_par08 = 5 											
					_sQuery += "   				AND SF4.F4_MARGEM  = '1'"
		endcase
		_sQuery += "   							AND SF4.F4_CODIGO = SD1.D1_TES)"
		_sQuery += "   					INNER JOIN SA2010 AS SA2"
		_sQuery += "   						ON (SA2.D_E_L_E_T_ = ''"
		_sQuery += "   							AND SA2.A2_COD  = SD1.D1_FORNECE"
		_sQuery += "   							AND SA2.A2_LOJA = SD1.D1_LOJA)"
		_sQuery += "   			  WHERE SD1.D_E_L_E_T_ = ''"
		_sQuery += "                AND SD1.D1_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		    AND SD1.D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "   	  			AND SD1.D1_TIPO NOT IN ('D')"
		_sQuery += "      		  GROUP BY SD1.D1_FORNECE, D1_LOJA, SA2.A2_NOME"
		_sQuery += "      		  UNION ALL"
		_sQuery += "      		 SELECT D2_CLIENTE       AS CODIGO"
		_sQuery += "   			      , SA2.A2_NOME      AS NOME"
		_sQuery += "  				  , SUM(SD2.D2_VALBRUT)*(-1) AS TOTAL"
		_sQuery += "        	   FROM SD2010 AS SD2"
		_sQuery += "   				 INNER JOIN SF4010 AS SF4"
		_sQuery += "   					ON (SF4.D_E_L_E_T_ =''"
		do case
			case mv_par08 = 1
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // essa condicao nao existe e nao eh pra trazer nada mesmo  								
			case mv_par08 = 2
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // essa condicao nao existe e nao eh pra trazer nada mesmo
			case mv_par08 = 3
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // nao vou fazer o tratamento agora dificilmente acontece isso
			case mv_par08 = 4
					_sQuery += "   			AND SF4.F4_MARGEM = '2'"
					_sQuery += "   			AND SD2.D2_TIPO   = 'B'"
			case mv_par08 = 5 											
					_sQuery += "   			AND SF4.F4_MARGEM  = '2'"
					_sQuery += "   			AND SD2.D2_TIPO    = 'D'"
		endcase
		_sQuery += "   						AND SF4.F4_CODIGO = SD2.D2_TES)"
		_sQuery += "   				 INNER JOIN SA2010 AS SA2"
		_sQuery += "   					ON (SA2.A2_COD      = SD2.D2_CLIENTE"
		_sQuery += "   						AND SA2.A2_LOJA = SD2.D2_LOJA)"
        _sQuery += "       		  WHERE SD2.D_E_L_E_T_ =''"
        _sQuery += "                AND SD2.D2_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += " 	  		    AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "	  			AND (SD2.D2_TIPO ='D'  OR SD2.D2_TIPO ='B')"
		_sQuery += "			  GROUP BY SD2.D2_CLIENTE, SA2.A2_NOME"
		_sQuery += " )"
		_sQuery += "  SELECT C.CODIGO, C.NOME, SUM(C.TOTAL) AS TOTAL"
		_sQuery += "    FROM C"
 		_sQuery += "   GROUP BY C.CODIGO, C.NOME"
 		_sQuery += "   ORDER BY SUM(C.TOTAL) DESC"
	case mv_par03 = 2 // 'Produtos'	
		_sQuery += " WITH C AS (SELECT D2_COD        AS CODIGO"
		_sQuery += "		         , SB1.B1_DESC   AS NOME"
		_sQuery += "		         , SUM(SD2.D2_VALBRUT)*(-1) AS TOTAL"
		_sQuery += "	          FROM SD2010 AS SD2"
		_sQuery += "					INNER JOIN SF4010 AS SF4"
		_sQuery += "						ON (SF4.D_E_L_E_T_ =''"
		do case
			case mv_par08 = 1
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // essa condicao nao existe e nao eh pra trazer nada mesmo  								
			case mv_par08 = 2
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // essa condicao nao existe e nao eh pra trazer nada mesmo
			case mv_par08 = 3
					_sQuery += "   			AND SF4.F4_MARGEM = 'W'"  // nao vou fazer o tratamento agora dificilmente acontece isso
			case mv_par08 = 4
					_sQuery += "   			AND SF4.F4_MARGEM = '2'"
					_sQuery += "   			AND SD2.D2_TIPO   = 'B'"
			case mv_par08 = 5 											
					_sQuery += "   			AND SF4.F4_MARGEM  = '2'"
					_sQuery += "   			AND SD2.D2_TIPO    = 'D'"
		endcase
		_sQuery += "							AND SF4.F4_CODIGO = SD2.D2_TES)"
		_sQuery += "					INNER JOIN SB1010 AS SB1"
		_sQuery += "						ON (SB1.D_E_L_E_T_ = ''"
		_sQuery += "							AND SB1.B1_COD = SD2.D2_COD)"
		_sQuery += "			WHERE SD2.D_E_L_E_T_ = ''"
		_sQuery += "              AND SD2.D2_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
		_sQuery += "	  		  AND SD2.D2_TIPO ='D'
		_sQuery += " 	  		  AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
		_sQuery += "   			GROUP BY SD2.D2_COD, SB1.B1_DESC"
		_sQuery += "   		    UNION ALL"
		_sQuery += "   			SELECT D1_COD        AS CODIGO"
		_sQuery += "				 , SB1.B1_DESC   AS NOME"
		_sQuery += " 				 , ROUND(SUM(SD1.D1_TOTAL+SD1.D1_VALIPI+SD1.D1_ICMSRET),2) AS TOTAL"
		_sQuery += "	 		  FROM SD1010 AS SD1"
		_sQuery += "				INNER JOIN SF4010 AS SF4"
		_sQuery += "					ON (SF4.D_E_L_E_T_ =''"
		_sQuery += "						AND SF4.F4_CODIGO = SD1.D1_TES"
		do case
			case mv_par08 = 1
					_sQuery += "   		AND SF4.F4_MARGEM = '6')"
			case mv_par08 = 2
					_sQuery += "   		AND SF4.F4_MARGEM = '7')"
			case mv_par08 = 3
					_sQuery += "   		AND SF4.F4_MARGEM = '8')"
			case mv_par08 = 4
					_sQuery += "   			AND SF4.F4_MARGEM IN ('9','4','5'))"
			case mv_par08 = 5 											
					_sQuery += "   			AND SF4.F4_MARGEM  = '1')"
		endcase
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

//u_showmemo(_sQuery)
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Periodo de        ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Periodo ate       ? ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "ABC de            ? ", "N", 1,  0,  "",   "   ", {"Fornecedores","Produtos"},    ""})
	aadd (_aRegsPerg, {04, "Listar primeiros  ? ", "C", 6,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Gera em Planilha  ? ", "N", 2,  0,  "",   "   ", {"Sim", "Nao"}, "Indique se deseja gerar em planilha."})
	aadd (_aRegsPerg, {06, "Filial de         ? ", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {07, "Filial até        ? ", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {08, "Tipo              ? ", "N", 1,  0,  "",   "   ", {"Fretes","Servicos","Uso e Consumo","Outras Entradas","Compras"},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
	