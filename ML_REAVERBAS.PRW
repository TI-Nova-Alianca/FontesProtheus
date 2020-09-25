// Programa..: ML_REAVERBAS
// Autor.....: Catia Cardoso
// Data......: 23/06/2015
// Nota......: Verbas de Cliente - Utilizacao

// Historico de alteracoes:
// 24/06/2015 - tinha esquecido um showmemo da query
// 30/11/2015 - criado parametros separados para periodo de faturamento e periodo de verbas

#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_REAVERBAS()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)
	
	cString := "ZA5"
    cDesc1  := "Verbas de Cliente X Faturamento"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_VERBAS"
    wnrel   := "ML_REAVERBAS"
    nTipo   := 0
    titulo  := "Verbas de Cliente X Faturamento"
    
    _ValidPerg()
    Pergunte(cPerg,.F.)
    	
    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
    	
    // se iniciar o parametro de data inicial como branco - assume a data da primeira verba liberada
    if dtos(mv_par09) < '20150424'
		msgalert("Data inicial não pode ser menor do que 24/04/2015, que foi quando foi implantado o controle de verbas")
   		return		    		
    endif
    
   	If nLastKey == 27
	   Return
    Endif
    
    SetDefault(aReturn,cString)
    
    RptStatus({|| RptDetail()})
    
Return

Static Function RptDetail()

    SetRegua(LastRec())
	
	_sQuery := " "
    _sQuery += "WITH C AS ( SELECT ZA5.ZA5_CLI    AS CLIENTE"     
	_sQuery += " 				 , ZA5.ZA5_LOJA   AS LOJA"
	_sQuery += "	  		     , ISNULL(SF2.F2_VEND1,SA1.A1_VEND) AS VENDEDOR" 
	_sQuery += " 				 , ZA5.ZA5_TLIB	  AS TP_LIB"
    _sQuery += " 				 , CASE WHEN ZA5.ZA5_TLIB = '1' THEN SUM(ZA5_VLR) ELSE 0 END AS BON_TOT_VER"
    _sQuery += " 				 , CASE WHEN ZA5.ZA5_TLIB = '2' THEN SUM(ZA5_VLR) ELSE 0 END AS DESC_TOT_VER"
    _sQuery += " 				 , CASE WHEN ZA5.ZA5_TLIB IN ('3','4') THEN SUM(ZA5_VLR) ELSE 0 END AS DEP_TOT_VER"
    _sQuery += " 				 , 0 AS DEV_TOT_PER"
    _sQuery += " 				 , 0 AS FATB_TOT_PER"
    _sQuery += " 				 , 0 AS FATL_TOT_PER"
    _sQuery += " 				 , SA1.A1_VACBASE AS MATRIZ" 				 
    _sQuery += " 				 , SA1.A1_VALBASE AS MLOJA" 
	_sQuery += "			  FROM ZA5010 AS ZA5" 
	_sQuery += "				INNER JOIN SA1010 AS SA1"
	_sQuery += "					ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "						AND SA1.A1_COD   = ZA5.ZA5_CLI
	_sQuery += "                        AND SA1.A1_VACBASE BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'" 			   
	_sQuery += "	                    AND SA1.A1_VALBASE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "						AND SA1.A1_LOJA  = ZA5.ZA5_LOJA)"
	_sQuery += "				LEFT JOIN SF2010 AS SF2" 
	_sQuery += "					ON (SF2.D_E_L_E_T_     = ''"
	_sQuery += "						AND SF2.F2_FILIAL  = '01'"
	_sQuery += "						AND SF2.F2_DOC     = ZA5.ZA5_DOC"
	_sQuery += "						AND SF2.F2_SERIE   = '10'
	_sQuery += "						AND SF2.F2_EMISSAO > '20150424')"
	_sQuery += "			 WHERE ZA5.D_E_L_E_T_ = ''" 
	_sQuery += "			   AND ZA5.ZA5_DTA BETWEEN '" + dtos(mv_par09) + "' AND '" + dtos(mv_par10) + "'"
	_sQuery += " 	         GROUP BY SA1.A1_VACBASE, SA1.A1_VALBASE, ZA5.ZA5_CLI, ZA5.ZA5_LOJA, ISNULL(SF2.F2_VEND1,SA1.A1_VEND), ZA5.ZA5_TLIB"
	_sQuery += "			 UNION ALL"
	// BUSCA FATURAMENTO BRUTO E LIQUIDO (SEM ST E IPI)
	_sQuery += "			SELECT SD2.D2_CLIENTE       AS CLIENTE" 	 
	_sQuery += "				 , SD2.D2_LOJA          AS LOJA"
	_sQuery += "				 , SF2.F2_VEND1         AS VENDEDOR"
	_sQuery += "				 , 0 AS TP_LIB"
	_sQuery += "				 , 0 AS BON_TOT_VER"
	_sQuery += "				 , 0 AS DESC_TOT_VER"
	_sQuery += "				 , 0 AS DEP_TOT_VER"
	_sQuery += "				 , 0 AS DEV_TOT_PER"
	_sQuery += "				 , ROUND(SUM(SD2.D2_VALBRUT),2) AS FATB_TOT_PER"
	_sQuery += "				 , ROUND(SUM(SD2.D2_VALBRUT - SD2.D2_VALIPI - SD2.D2_ICMSRET),2) AS FATL_TOT_PER"
	_sQuery += " 				 , SA1.A1_VACBASE AS MATRIZ"
    _sQuery += " 				 , SA1.A1_VALBASE AS MLOJA"
	_sQuery += "			  FROM SD2010 AS SD2"
	_sQuery += "				INNER JOIN SA1010 AS SA1"
	_sQuery += "					ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "						AND SA1.A1_COD   = SD2.D2_CLIENTE"
	_sQuery += "			            AND SA1.A1_VACBASE BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'" 
	_sQuery += " 			            AND SA1.A1_VALBASE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "						AND SA1.A1_LOJA  = SD2.D2_LOJA)"
	_sQuery += "				INNER JOIN SF2010 AS SF2"
	_sQuery += "   					ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "						AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "	   					AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "	   					AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "	   					AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "	   					AND SF2.F2_LOJA    = SD2.D2_LOJA"
    _sQuery += "	  					AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "				INNER JOIN SF4010 AS SF4"
	_sQuery += "					ON (SF4.D_E_L_E_T_ = ''"		
	_sQuery += "						AND SF4.F4_MARGEM IN ('1')"
	_sQuery += "						AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "			 WHERE SD2.D_E_L_E_T_ = ''"
  	_sQuery += "			   AND SD2.D2_EMISSAO   BETWEEN '" + dtos(mv_par07) + "' AND '" + dtos(mv_par08) + "'"
  	_sQuery += " 			   AND EXISTS (SELECT 1"
	_sQuery += "              			     FROM " + RetSQLName ("ZA4") + " ZA4 "
	_sQuery += "								INNER JOIN " + RetSQLName ("ZA5") + " ZA5 "
	_sQuery += "									ON (ZA5.D_E_L_E_T_ = ''"
	_sQuery += "                        				AND ZA5.ZA5_DTA BETWEEN '" + dtos(mv_par09) + "' AND '" + dtos(mv_par10) + "'"
	_sQuery += "										AND ZA5.ZA5_NUM = ZA4.ZA4_NUM)" 
	_sQuery += "                            WHERE ZA4.D_E_L_E_T_ = ''"
	_sQuery += "						      AND ZA4.ZA4_CLI  = SA1.A1_VACBASE"
	_sQuery += "						      AND ZA4.ZA4_LOJA = SA1.A1_VALBASE)"
	_sQuery += "			 GROUP BY SA1.A1_VACBASE, SA1.A1_VALBASE, SD2.D2_CLIENTE , SD2.D2_LOJA,  SF2.F2_VEND1"
	_sQuery += "			 UNION ALL"
	// BUSCA AS DEVOLUÇÕES
	_sQuery += "			SELECT SD1.D1_FORNECE       AS CLIENTE" 	 
	_sQuery += "				 , SD1.D1_LOJA          AS LOJA"	 
	_sQuery += "			     , SA1.A1_VEND          AS VENDEDOR"
	_sQuery += "				 , 0 AS TP_LIB"
	_sQuery += "				 , 0 AS BON_TOT_VER"
	_sQuery += "				 , 0 AS DESC_TOT_VER"
	_sQuery += "				 , 0 AS DEP_TOT_VER"
	_sQuery += "				 , ROUND(SUM((SD1.D1_VUNIT*SD1.D1_QUANT)+SD1.D1_VALIPI+SD1.D1_ICMSRET),2) AS DEV_TOT_PER"
	_sQuery += "				 , 0 AS FATB_TOT_PER"
	_sQuery += "				 , 0 AS FATL_TOT_PER"
	_sQuery += " 				 , SA1.A1_VACBASE AS MATRIZ"
    _sQuery += " 				 , SA1.A1_VALBASE AS MLOJA"
	_sQuery += "			  FROM SD1010 AS SD1"
	_sQuery += "				INNER JOIN SA1010 AS SA1"
	_sQuery += "					ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "						AND SA1.A1_COD   = SD1.D1_FORNECE"
	_sQuery += "			            AND SA1.A1_VACBASE BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'" 
	_sQuery += " 			            AND SA1.A1_VALBASE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "						AND SA1.A1_LOJA  = SD1.D1_LOJA)"
	_sQuery += "				INNER JOIN SF1010 AS SF1"
	_sQuery += "					ON (SF1.D_E_L_E_T_ = ''"
	_sQuery += "						AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
	_sQuery += "   						AND SF1.F1_DOC     = SD1.D1_DOC"				
	_sQuery += "						AND SF1.F1_SERIE   = SD1.D1_SERIE"			
 	_sQuery += "   						AND SF1.F1_FORNECE = SD1.D1_FORNECE"
	_sQuery += "						AND SF1.F1_LOJA    = SD1.D1_LOJA"
	_sQuery += " 						AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"
	_sQuery += "				INNER JOIN SF4010 AS SF4"
	_sQuery += "					ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "						AND SF4.F4_CODIGO  = SD1.D1_TES"
	_sQuery += "						AND SF4.F4_MARGEM  = '2')"
	_sQuery += "			WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += "			  AND SD1.D1_DTDIGIT BETWEEN '" + dtos(mv_par07) + "' AND '" + dtos(mv_par08) + "'"
	_sQuery += "			  AND SD1.D1_TIPO = 'D'"
	_sQuery += " 			   AND EXISTS (SELECT 1"
	_sQuery += "              			     FROM " + RetSQLName ("ZA4") + " ZA4 "
	_sQuery += "								INNER JOIN " + RetSQLName ("ZA5") + " ZA5 "
	_sQuery += "									ON (ZA5.D_E_L_E_T_ = ''"
	_sQuery += "                        				AND ZA5.ZA5_DTA BETWEEN '" + dtos(mv_par09) + "' AND '" + dtos(mv_par10) + "'"
	_sQuery += "										AND ZA5.ZA5_NUM = ZA4.ZA4_NUM)" 
	_sQuery += "                            WHERE ZA4.D_E_L_E_T_ = ''"
	_sQuery += "						      AND ZA4.ZA4_CLI  = SA1.A1_VACBASE"
	_sQuery += "						      AND ZA4.ZA4_LOJA = SA1.A1_VALBASE)"
	_sQuery += "			GROUP BY SA1.A1_VACBASE, SA1.A1_VALBASE, SD1.D1_FORNECE, SD1.D1_LOJA, SA1.A1_VEND"
	_sQuery += ")"
	_sQuery += " SELECT C.MATRIZ, C.MLOJA, C.CLIENTE, C.LOJA, C.VENDEDOR, SUM(C.BON_TOT_VER) AS BON_TOT_VER, SUM(C.DESC_TOT_VER) AS DESC_TOT_VER"
	_sQuery += "	  , SUM(C.DEP_TOT_VER) AS DEP_TOT_VER, SUM(DEV_TOT_PER) AS DEV_TOT_PER"
	_sQuery += "      , SUM(FATB_TOT_PER) AS FATB_TOT_PER, SUM(FATL_TOT_PER) AS FATL_TOT_PER"
	_sQuery += "   FROM C"
	_sQuery += "  WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"			
	_sQuery += "  GROUP BY C.MATRIZ, C.MLOJA, C.CLIENTE, C.LOJA, C.VENDEDOR"
    _sQuery += "  ORDER BY C.MATRIZ, C.MLOJA, C.CLIENTE, C.LOJA, C.VENDEDOR"
    
	//u_showmemo(_sQuery)
	
	nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="                                                                                                            ------- F A T U R A M E N T O -------                ------------- V E R B A S ------------                  "
    cabec2:="CLIENTE                                         UF   MATRIZ     REPRESENTANTE                               BRUTO(c/IPI e ST)             LIQUIDO    DEVOLUCOES  BONIFICACOES   DESCONTOS    PAGAMENTOS   % BRUTO   % LIQ"
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotGer = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    _aTotMat = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    _wmatriz = ""
    _wcont =0
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    
    	If li>65
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	
		if _wmatriz !="" .and. _wmatriz != (_sAliasQ) -> MATRIZ
			if _wcont > 1
				// imprime total da matriz
        		If li>65
     				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     			Endif
     			@ li, 90 PSAY "Total Matriz:"
				@ li,107 PSAY _aTotMat [1] Picture "@E 999,999,999,999.99" 
	 			@ li,127 PSAY _aTotMat [2] Picture "@E 999,999,999,999.99"
	 			@ li,145 PSAY _aTotMat [3] Picture "@E 999,999,999.99"
	 			@ li,160 PSAY _aTotMat [4] Picture "@E 9,999,999.99"
	 			@ li,173 PSAY _aTotMat [5] Picture "@E 9,999,999.99"
	 			@ li,187 PSAY _aTotMat [6] Picture "@E 9,999,999.99"
	 			_wtotverbas = _aTotMat[4] + _aTotMat[5] + _aTotMat[6]
	 			@ li,201 PSAY (_wtotverbas /( _aTotMat [1] - _aTotMat [3] ))*100 Picture "@E 9,999.99"
	 			@ li,209 PSAY (_wtotverbas /( _aTotMat [2] - _aTotMat [3] ))*100 Picture "@E 9,999.99"
     			li ++
			endif
			     			
     		li ++
     		
     		_aTotMat [1] = 0
       		_aTotMat [2] = 0
       		_aTotMat [3] = 0
       		_aTotMat [4] = 0
       		_aTotMat [5] = 0
       		_aTotMat [6] = 0
     		_wcont = 0
		endif
		 
		@ li, 00 PSAY (_sAliasQ) -> CLIENTE
        @ li, 07 PSAY LEFT(fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) ->CLIENTE + (_sAliasQ) ->LOJA, "A1_NOME"),38)
        @ li, 48 PSAY fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) ->MATRIZ  + (_sAliasQ) ->MLOJA, "A1_EST")
		@ li, 53 PSAY (_sAliasQ) -> MATRIZ
	    //@ li, 39 PSAY LEFT(fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) ->MATRIZ  + (_sAliasQ) ->MLOJA, "A1_NOME"),23)
		@ li, 64 PSAY (_sAliasQ) -> VENDEDOR Picture "@E 999"
	    @ li, 69 PSAY LEFT(fBuscaCpo ('SA3', 1, xfilial('SA3') + (_sAliasQ) -> VENDEDOR , "A3_NOME"),30)
	    //_wcanal = fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) ->CLIENTE + (_sAliasQ) ->LOJA, "A1_VACANAL")
	    //@ li, 87 PSAY _wcanal Picture "@E 99"
	    //@ li, 90 PSAY LEFT(fBuscaCpo ('ZX5', 1, xfilial('ZX5') + '18' + _wcanal, "ZX5_18DESC"),15)
	    @ li,109 PSAY (_sAliasQ) -> FATB_TOT_PER Picture "@E 9,999,999,999.99" 
	    @ li,129 PSAY (_sAliasQ) -> FATL_TOT_PER Picture "@E 9,999,999,999.99"
	    @ li,147 PSAY (_sAliasQ) -> DEV_TOT_PER  Picture "@E 9,999,999.99"
	    @ li,160 PSAY (_sAliasQ) -> BON_TOT_VER  Picture "@E 9,999,999.99"
	    @ li,173 PSAY (_sAliasQ) -> DESC_TOT_VER Picture "@E 9,999,999.99"
	    @ li,187 PSAY (_sAliasQ) -> DEP_TOT_VER  Picture "@E 9,999,999.99"
	    _wperc = ((DEP_TOT_VER + DESC_TOT_VER + BON_TOT_VER) / (FATB_TOT_PER - DEV_TOT_PER))*100 
	    @ li,201 PSAY _wperc Picture "@E 9,999.99"
	    _wperc1 = ((DEP_TOT_VER + DESC_TOT_VER + BON_TOT_VER) / (FATL_TOT_PER - DEV_TOT_PER))*100
	    @ li,209 PSAY _wperc1 Picture "@E 9,999.99"
	   
	    _aTotMat [1] += (_sAliasQ) -> FATB_TOT_PER
       	_aTotMat [2] += (_sAliasQ) -> FATL_TOT_PER
       	_aTotMat [3] += (_sAliasQ) -> DEV_TOT_PER
       	_aTotMat [4] += (_sAliasQ) -> BON_TOT_VER
       	_aTotMat [5] += (_sAliasQ) -> DESC_TOT_VER
       	_aTotMat [6] += (_sAliasQ) -> DEP_TOT_VER
       	
	    _aTotGer [1] += (_sAliasQ) -> FATB_TOT_PER
       	_aTotGer [2] += (_sAliasQ) -> FATL_TOT_PER
       	_aTotGer [3] += (_sAliasQ) -> DEV_TOT_PER
       	_aTotGer [4] += (_sAliasQ) -> BON_TOT_VER
       	_aTotGer [5] += (_sAliasQ) -> DESC_TOT_VER
       	_aTotGer [6] += (_sAliasQ) -> DEP_TOT_VER
       	
       	_wmatriz = (_sAliasQ) -> MATRIZ
       	_wcont = _wcont +1 
       	li ++
     	(_sAliasQ) -> (dbskip())
     enddo
     
     if _aTotMat [1] > 0 
     	// imprime total da matriz
     	if _wcont >1
        	If li>65
     			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     		Endif
     		@ li, 90 PSAY "Total Matriz:"
			@ li,107 PSAY _aTotMat [1] Picture "@E 999,999,999,999.99" 
	 		@ li,127 PSAY _aTotMat [2] Picture "@E 999,999,999,999.99"
	 		@ li,145 PSAY _aTotMat [3] Picture "@E 999,999,999.99"
	 		@ li,160 PSAY _aTotMat [4] Picture "@E 9,999,999.99"
	 		@ li,173 PSAY _aTotMat [5] Picture "@E 9,999,999.99"
	 		@ li,187 PSAY _aTotMat [6] Picture "@E 9,999,999.99"
	 		_wtotverbas = _aTotMat[4] + _aTotMat[5] + _aTotMat[6]
	 		@ li,201 PSAY (_wtotverbas /( _aTotMat [1] - _aTotMat [3] ))*100 Picture "@E 9,999.99"
	 		@ li,209 PSAY (_wtotverbas /( _aTotMat [2] - _aTotMat [3] ))*100 Picture "@E 9,999.99"
     		li ++
		endif     		
     	li ++
     endif
     
	 li ++      
     If li>65
     	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     li ++
     _wtotverbas = _aTotGer[4] + _aTotGer[5] + _aTotGer[6]
     @ li, 60 PSAY "Total Utilizado em Verbas:"
     @ li, 87 PSAY _wtotverbas  Picture "@E 999,999,999,999.99"
     @ li,107 PSAY _aTotGer [1] Picture "@E 999,999,999,999.99" 
	 @ li,127 PSAY _aTotGer [2] Picture "@E 999,999,999,999.99"
	 @ li,145 PSAY _aTotGer [3] Picture "@E 999,999,999.99"
	 @ li,160 PSAY _aTotGer [4] Picture "@E 9,999,999.99"
	 @ li,173 PSAY _aTotGer [5] Picture "@E 9,999,999.99"
	 @ li,187 PSAY _aTotGer [6] Picture "@E 9,999,999.99"
	 @ li,201 PSAY (_wtotverbas /( _aTotGer [1] - _aTotGer [3] ))*100 Picture "@E 9,999.99"
	 @ li,209 PSAY (_wtotverbas /( _aTotGer [2] - _aTotGer [3] ))*100 Picture "@E 9,999.99"
     li ++
     li ++
     li ++
     
     U_ImpParam(65)
	      
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
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Cliente de              ?", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {02, "Cliente ate             ?", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {03, "Loja de                 ?", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {04, "Loja ate                ?", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {05, "Representante de        ?", "C", 3,  0,  "",   "SA3", {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {06, "Representante de        ?", "C", 3,  0,  "",   "SA3", {},                        "Representante Final"})
	aadd (_aRegsPerg, {07, "Periodo Faturamento de  ?", "D", 8,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {08, "Periodo Faturamento até ?", "D", 8,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {09, "Periodo Verbas de       ?", "D", 8,  0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {10, "Periodo Verbas até      ?", "D", 8,  0,  "",   "   ", {},                         ""})
	
   	U_ValPerg (cPerg, _aRegsPerg)   	  
   	
Return