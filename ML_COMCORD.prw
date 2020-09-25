// Programa  : ML_COMCORD
// Autor     : Catia Cardoso
// Data      : 27/04/2016
// Descricao : Relatorio Comissao de Coordenadores/Externos
// 
// Historico de alteracoes:
// 
// 30/05/2016 - Catia - novo campo para controlar se considera vendas da loja ou não
// 07/10/2016 - Catia - tratamento campo - considera terceiros S/N
// 19/10/2016 - Catia - parametro de clientes a excluir
// 17/11/2016 - Catia - ajustada mascara do campo %comissão
// 28/03/2018 - Catia - implantado novos requisitos conforme definicao do Fernando/Cesar
// 02/04/2018 - Catia - no caso das faixas estava calculo incorreto - ajustado
// 26/04/2018 - Catia - tinha erro no calculo da comissao quando tinha crescimento
// 09/05/2018 - Catia - refeito o teste de itens da loja - visto que estamos faturando pela matriz codigos unitarios
// 09/05/2018 - Catia - alterado novamente o testes de venda das lojas - usado a filial agora
// 21/06/2018 - Catia - alterado para que considere as vendas pela filial 09 tambem
// 28/03/2019 - Catia - incluido parametro de produtos a excluir
// 01/04/2019 - Robert - Migrada tabela 88 do SX5 para 38 do ZX5 (linhas comerciais).
// 08/04/2019 - Catia  - erro SX5.X5_DESCRI
// -----------------------------------------------------------------------------------------------------------------
user function ML_COMCORD
    cString := "SD1"
    cDesc1  := "Relatorio Comissão de Coordenadores/Externos"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_COMCORD"
    titulo  := "Relatorio Comissão de Coordenadores/Externos"
    wnrel   := "ML_COMCORD"
    nTipo   := 0
	
	if ! u_zzuvl ('067', __cUserId, .T.)
		return
	endif
    
    _ValidPerg()
    Pergunte(cPerg,.F.)
    
    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

    If nLastKey == 27
	   Return
    Endif
    SetDefault(aReturn,cString)
    If nLastKey == 27
	   Return
    Endif
    
    RptStatus({|| RptDetail()})
Return

Static Function RptDetail()
	local i := 0
    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "" 
    cabec2 := ""
    
    // le tabela de coordenadores / externos - conforme intervalo solicitado
    _sQuery := " "
    _sQuery += " SELECT ZAE_CCORD, ZAE_TPPER, ZAE_COMPAR, ZAE_IVEND, ZAE_ILINHA, ZAE_IPROD, ZAE_IMPRES"
    _sQuery += "      , ZAE_PERC, ZAE_VMAN, ZAE_TIPO, ZAE_CLOJAS, ZAE_IEST, ZAE_CTERC, ZAE_EXCLI, ZAE_EXCLI1, ZAE_NOME, ZAE_PEXCL"
    _sQuery += "   FROM ZAE010" // padrao empresa
  	_sQuery += "  WHERE D_E_L_E_T_ = ''"
  	_sQuery += "    AND ZAE_CCORD BETWEEN '" + mv_par02   + "' AND '" + mv_par03 + "'"
  	u_log (_sQuery)
    _aDados := U_Qry2Array(_sQuery)
    //u_showarray(_aDados)
	if len(_aDados) > 0
		for i=1 to len(_aDados)
			_wcoord      = _aDados[i,1]
			_wtpperiodo  = _aDados[i,2]
			_wcompara    = _aDados[i,3]
			_wintvend    = alltrim(_aDados[i,4])
			_wintlin     = alltrim(_aDados[i,5])
			_wintprod    = alltrim(_aDados[i,6])
			_worder      = _aDados[i,7]
			_wperccom    = _aDados[i,8]
			_wvalormanut = _aDados[i,9]
			_wtipo       = _aDados[i,10]
			_wclojas     = _aDados[i,11]
			_wintest     = alltrim(_aDados[i,12])
			_wcterceiros = _aDados[i,13]
			_wcliexcluir = alltrim(_aDados[i,14])
			_wcli1excluir = alltrim(_aDados[i,15])
			_wnome        = _aDados[i,16]
			_wprodexcluir = alltrim(_aDados[i,17])
			
			if len(_wcliexcluir) > 1
				if substr(_wcliexcluir,len(_wcliexcluir),1) == '/' .or. substr(_wcliexcluir,len(_wcliexcluir),1) == '\'
					_wcliexcluir = substr(_wcliexcluir,1,len(_wcliexcluir)-1)
				endif 
			endif
			
			if len(_wcli1excluir) > 1
				if substr(_wcli1excluir,len(_wcli1excluir),1) == '/' .or. substr(_wcli1excluir,len(_wcli1excluir),1) == '\'
					_wcli1excluir = substr(_wcli1excluir,1,len(_wcli1excluir)-1)
				endif 
			endif
			
			if len(_wprodexcluir) > 1
				if substr(_wprodexcluir,len(_wprodexcluir),1) == '/' .or. substr(_wprodexcluir,len(_wprodexcluir),1) == '\'
					_wprodexcluir = substr(_wprodexcluir,1,len(_wprodexcluir)-1)
				endif 
			endif
			
			
			// define intervalo de datas de apuração
			if _wtpperiodo = '1'  // mensal
		   		_wdataini = SUBSTR ( dtos (mv_par01), 1, 6 ) + '01'
		   		_wdatafim = SUBSTR ( dtos (mv_par01), 1, 6 ) + '31'
			else // folha
				_wano = VAL( SUBSTR ( dtos (mv_par01), 1,4))
				_wmes = VAL( SUBSTR ( dtos (mv_par01), 5, 2 )) - 1
				if _wmes = 0
					_wmes = 12
					_wano = VAL( SUBSTR ( dtos (mv_par01), 1, 4 )) - 1
				endif 
				_wdataini = STRZERO(_wano, 4) + STRZERO( _wmes, 2) + '26'
		   		_wdatafim = SUBSTR ( dtos (mv_par01), 1, 6 ) + '25'
			endif		   		
		   	
			_sQuery := " "
			_MontaQuery(_wdataini, _wdatafim)
			_sAliasQ = GetNextAlias ()
			DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
		  	
			(_sAliasQ) -> (DBGoTop ())
		    _wtot1 := 0
			_wtot2 := 0
			_wtot1a:= 0
			_wtot2a:= 0
				
			Do While ! (_sAliasQ) -> (Eof ())
		    	If li>63
			        cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			        @ li, 015 PSAY 'Coordenador/Externo : ' + _wcoord +  ' - ' + _wnome
			        li ++
			        li ++
	       		    @ li, 015 PSAY 'Periodo             : ' + substr(_wdataini,7,2) + '/' + substr(_wdataini,5,2) + '/' + substr(_wdataini,1,4)  + ' até ' + substr(_wdatafim,7,2) + '/' + substr(_wdatafim,5,2) + '/' + substr(_wdatafim,1,4)  
			    	li ++
			    Endif
			    
			    @ li, 002 PSAY ALLTRIM((_sAliasQ) -> CODIGO)
			    @ li, 015 PSAY ALLTRIM((_sAliasQ) -> DESCRICAO)
			    @ li, 079 PSAY (_sAliasQ) -> QUANT  Picture "@E 999,999.9999"
			    @ li, 098 PSAY (_sAliasQ) -> VALOR  Picture "@E 999,999,999.99"
			    li ++
			    // acumula totais
			    _wtot1 = _wtot1 + (_sAliasQ) -> QUANT
				_wtot2 = _wtot2 + (_sAliasQ) -> VALOR
			 	(_sAliasQ) -> (dbskip())
		    enddo
		    // imprime total do periodo 
		    @ li, 015 PSAY 'Total:'
		    @ li, 079 PSAY _wtot1 Picture "@E 999,999.9999"
			@ li, 098 PSAY _wtot2 Picture "@E 999,999,999.99"
			li ++
			if  _wcompara != '2' // define datas para comparativo // SIM e P/FAIXAS
		  		_wdataini = STRZERO(VAL(SUBSTR(_wdataini,1,4))-1,4) + SUBSTR(_wdataini,5,4)
				_wdatafim = STRZERO(VAL(SUBSTR(_wdatafim,1,4))-1,4) + SUBSTR(_wdatafim,5,4)
				_sQuery  := " "
				_MontaQuery(_wdataini, _wdatafim)
				
				_sAliasANT = GetNextAlias ()
				DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasANT,.F.,.F.)
				
				_wtot1a := 0
				_wtot2a := 0
				(_sAliasANT) -> (DBGoTop ())
				Do While ! (_sAliasANT) -> (Eof ())
		    		If li>63
			       		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			       		li ++
			       		li ++
			       		@ li, 015 PSAY 'Periodo             : ' + substr(_wdataini,7,2) + '/' + substr(_wdataini,5,2) + '/' + substr(_wdataini,1,4)  + ' até ' + substr(_wdatafim,7,2) + '/' + substr(_wdatafim,5,2) + '/' + substr(_wdatafim,1,4)
			       		li ++ 
			    	Endif
			    	
			    	if _wtot2a = 0
			       		li ++
			       		li ++
			       		@ li, 015 PSAY 'Periodo Anterior    : ' + substr(_wdataini,7,2) + '/' + substr(_wdataini,5,2) + '/' + substr(_wdataini,1,4)  + ' até ' + substr(_wdatafim,7,2) + '/' + substr(_wdatafim,5,2) + '/' + substr(_wdatafim,1,4) 
			    		li ++
			    	endif
			    	
				    @ li, 002 PSAY ALLTRIM((_sAliasANT) -> CODIGO)
				    @ li, 015 PSAY ALLTRIM((_sAliasANT) -> DESCRICAO)
				    @ li, 079 PSAY (_sAliasANT) -> QUANT  Picture "@E 999,999.9999"
				    @ li, 098 PSAY (_sAliasANT) -> VALOR  Picture "@E 999,999,999.99"
				    li ++
				    // acumula totais
				    _wtot1a = _wtot1a + (_sAliasANT) -> QUANT
					_wtot2a = _wtot2a + (_sAliasANT) -> VALOR
				 	(_sAliasANT) -> (dbskip())
			    enddo
			    @ li, 015 PSAY 'Total:'
			    @ li, 079 PSAY _wtot1a Picture "@E 999,999.9999"
				@ li, 098 PSAY _wtot2a Picture "@E 999,999,999.99"
				li ++
				li ++
				_wcrescimento = (_wtot2 - _wtot2a)
				_wPcresc = _wcrescimento*100/_wtot2a
				@ li, 015 PSAY 'Crescimento:'
				@ li, 081 PSAY _wPcresc Picture "@E 99,999.99%"
			    @ li, 098 PSAY _wcrescimento Picture "@E 999,999,999.99"
			    li ++
			else			    
				_wcrescimento := _wtot2
			endif
			// apura a comissao do coordenador / externo
			if _wcrescimento > 0
				li ++
				@ li, 015 PSAY 'Comissão:'
				if _wcompara = '3'
					do case 
						case _wintvend $ '186' .or. _wintvend $ '240' // LOJA FLORES ou FARROUPILHA 
							if _wtipo = '2'
								if _wPcresc > 25
						 			_wperccom = 7 
								endif
							elseif _wtipo = '3'
								if _wPcresc > 25
						 			_wperccom = 3.5 
								endif
							endif
						case _wintvend $ '135' .or. _wintvend $ '060' // LOJA CAXIAS
							if _wtipo = '2'
								if _wPcresc > 25
						 			_wperccom = 2 
								endif
							elseif _wtipo = '3'
								if _wPcresc > 25
						 			_wperccom = 1 
								endif
							endif
					endcase 									
				endif
				_wvlrcomissao = ( _wcrescimento * _wperccom)/100					
				@ li, 085 PSAY _wperccom Picture "@E 99.99%"
				@ li, 098 PSAY _wvlrcomissao Picture "@E 999,999,999.99"
				li ++
				// valor de manutenção
				if _wvalormanut > 0
					@ li, 015 PSAY 'Manutenção:'
					@ li, 098 PSAY _wvalormanut  Picture "@E 999,999,999.99"
					li ++
				endif
			else
				_wvalormanut  := 0
				_wvlrcomissao := 0													
			endif									
			// total comissao + valor manutenção 
			@ li, 015 PSAY 'T o t a l:'
			@ li, 098 PSAY _wvalormanut + _wvlrcomissao Picture "@E 999,999,999.99"
			li ++
			// salta pagina por coordenador
			li := 100
		next
	endif			    
     
    U_ImpParam (58)
	 
	Set Device To Screen

    If aReturn[5]==1
	   Set Printer TO
	   dbcommitAll()
	   ourspool(wnrel)
    Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return
// executa query 
Static Function _MontaQuery(_wdtini, _wdtfim)
_sQuery := " "
_sQuery += " WITH C AS (" 
_sQuery += "  SELECT 'ATUAL'        AS PERIODO"
_sQuery += "       , 'VENDA'        AS TIPO"
_sQuery += "   	   , SD2.D2_DOC     AS NOTA"
_sQuery += "       , SD2.D2_COD     AS PROD_COD"
_sQuery += "       , SB1.B1_DESC    AS PROD_DESC"
_sQuery += "       , SD2.D2_QUANT   AS QUANT"
_sQuery += "       , SD2.D2_TOTAL   AS VALOR"
_sQuery += "       , SB1.B1_CODLIN  AS LIN_COD"
//_sQuery += "       , SX5.X5_DESCRI  AS LIN_NOME"
_sQuery += "       , ZX5_39.ZX5_39DESC AS LIN_NOME"
_sQuery += "       , SD2.D2_EMISSAO AS DATA"
_sQuery += "       , SD2.D2_CLIENTE AS CLI_COD"
_sQuery += "       , SA1.A1_NOME    AS CLI_NOME"
_sQuery += "       , SF2.F2_VEND1   AS VEND_COD"
_sQuery += "    FROM SD2010 AS SD2"
_sQuery += "		INNER JOIN SF4010 AS SF4"
_sQuery += "			ON (SF4.D_E_L_E_T_    = ''"
_sQuery += "				AND SF4.F4_CODIGO = SD2.D2_TES"
_sQuery += "				AND SF4.F4_MARGEM = '1')"
_sQuery += "		INNER JOIN SF2010 AS SF2"
_sQuery += "			ON (SF2.D_E_L_E_T_     = ''"
_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
if _wintest != ''
	_sQuery += "            AND SF2.F2_EST IN " + FormatIn(_wintest,"/")
endif
if _wintvend != ''
	_sQuery += "            AND SF2.F2_VEND1 IN " + FormatIn(_wintvend,"/")
endif
_sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
_sQuery += "		INNER JOIN SA3010 AS SA3"
_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"
if _wtipo = '1'
	_sQuery += "		    AND SA3.A3_VAGEREN = '" + _wcoord + "'"
endif	
_sQuery += "				AND SA3.A3_COD     = SF2.F2_VEND1)"
_sQuery += "		INNER JOIN SB1010 AS SB1"
_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
if _wintlin != ''
	_sQuery += "            AND SB1.B1_CODLIN IN " + FormatIn(_wintlin,"/")
endif
if _wcterceiros != '1'
	_sQuery += "				AND SB1.B1_GRUPO != '1006'"  // NAO CONSIDERA TERCEIROS
endif		
_sQuery += "				AND SB1.B1_COD  = SD2.D2_COD)"
_sQuery += "		INNER JOIN " + RetSQLName ("ZX5") + " AS ZX5_39"
_sQuery += "			ON (ZX5_39.D_E_L_E_T_ = ''"
_sQuery += "				AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
_sQuery += "				AND ZX5_39.ZX5_TABELA = '39'"
_sQuery += "				AND ZX5_39.ZX5_39COD  = SB1.B1_CODLIN)"

_sQuery += "		INNER JOIN SA1010 AS SA1"
_sQuery += "			ON (SA1.D_E_L_E_T_  = ''"
_sQuery += "				AND SA1.A1_COD     = SD2.D2_CLIENTE"
_sQuery += "				AND SA1.A1_LOJA    = SD2.D2_LOJA"
if _wcliexcluir != ''
	_sQuery += "            AND SA1.A1_VACBASE NOT IN " + FormatIn(_wcliexcluir,"/")
endif
if _wcli1excluir != ''
	_sQuery += "            AND SA1.A1_VACBASE NOT IN " + FormatIn(_wcli1excluir,"/")
endif
_sQuery += "                AND SA1.A1_SATIV1 != '08.02')" // NAO CONSIDERA CESTEIROS 
_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"
_sQuery += "    AND SD2.D2_EMISSAO BETWEEN '" + _wdtini   + "' AND '" + _wdtfim   + "'"
if _wintprod != ''
	_sQuery += " AND SD2.D2_COD IN " + FormatIn(_wintprod,"/")
endif
if _wprodexcluir != ''
	_sQuery += "            AND SD2.D2_COD NOT IN " + FormatIn(_wprodexcluir,"/")
endif
if _wclojas != '1'
	_sQuery += "   AND (SD2.D2_FILIAL  = '01' OR SD2.D2_FILIAL  = '09')"
endif
_sQuery += "  UNION ALL"
_sQuery += " SELECT 'ATUAL'          AS PERIODO"
_sQuery += "      , 'DEVOLUCAO'      AS TIPO"
_sQuery += "      , SD1.D1_DOC       AS NOTA"
_sQuery += "      , SD1.D1_COD       AS PROD_COD"
_sQuery += "      , SB1.B1_DESC      AS PROD_DESC"
_sQuery += "      , SD1.D1_QUANT*-1  AS QUANT"
_sQuery += "      , SD1.D1_TOTAL*-1  AS VALOR"
_sQuery += "      , SB1.B1_CODLIN    AS LIN_COD"
//_sQuery += "      , SX5.X5_DESCRI    AS LIN_NOME"
_sQuery += "       , ZX5_39.ZX5_39DESC AS LIN_NOME"
_sQuery += "      , SD1.D1_DTDIGIT   AS DATA"
_sQuery += "      , SD1.D1_FORNECE   AS CLI_COD"
_sQuery += "      , SA1.A1_NOME      AS CLI_NOME"
_sQuery += "      , SF2ORIG.F2_VEND1 AS VEND_COD"
_sQuery += "   FROM SD1010 AS SD1"
_sQuery += "		INNER JOIN SF4010 AS SF4"
_sQuery += "			ON (SF4.D_E_L_E_T_    = ''"
_sQuery += "				AND SF4.F4_CODIGO = SD1.D1_TES"
_sQuery += "				AND SF4.F4_MARGEM = '2')"
_sQuery += "		INNER JOIN SF2010 AS SF2ORIG"
_sQuery += "			ON (SF2ORIG.D_E_L_E_T_     = ''"
_sQuery += "				AND SF2ORIG.F2_FILIAL  = SD1.D1_FILIAL"
_sQuery += "				AND SF2ORIG.F2_SERIE   = SD1.D1_SERIORI"
if _wintest != ''
	_sQuery += "            AND SF2ORIG.F2_EST IN " + FormatIn(_wintest,"/")
endif
if _wintvend != ''
	_sQuery += "            AND SF2ORIG.F2_VEND1 IN " + FormatIn(_wintvend,"/")
endif
_sQuery += "				AND SF2ORIG.F2_DOC     = SD1.D1_NFORI)"
_sQuery += "		INNER JOIN SA3010 AS SA3"
_sQuery += "			ON (SA3.D_E_L_E_T_     = ''"
if _wtipo = '1'
	_sQuery += "		    AND SA3.A3_VAGEREN = '" + _wcoord + "'"
endif
_sQuery += "				AND SA3.A3_COD     = SF2ORIG.F2_VEND1)"
_sQuery += "		INNER JOIN SB1010 AS SB1"
_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"
if _wintlin != ''
	_sQuery += "            AND SB1.B1_CODLIN IN " + FormatIn(_wintlin,"/")
endif
if _wcterceiros != '1'
	_sQuery += "				AND SB1.B1_GRUPO != '1006'"  // NAO CONSIDERA TERCEIROS
endif	
_sQuery += "				AND SB1.B1_COD = SD1.D1_COD)"
_sQuery += "		INNER JOIN " + RetSQLName ("ZX5") + " AS ZX5_39"
_sQuery += "			ON (ZX5_39.D_E_L_E_T_ = ''"
_sQuery += "				AND ZX5_39.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
_sQuery += "				AND ZX5_39.ZX5_TABELA = '39'"
_sQuery += "				AND ZX5_39.ZX5_39COD  = SB1.B1_CODLIN)"

_sQuery += "		INNER JOIN SA1010 AS SA1"
_sQuery += "			ON (SA1.D_E_L_E_T_  = ''"
_sQuery += "				AND SA1.A1_COD  = SD1.D1_FORNECE"
_sQuery += "				AND SA1.A1_LOJA = SD1.D1_LOJA"
if _wcliexcluir != ''
	_sQuery += "            AND SA1.A1_VACBASE NOT IN " + FormatIn(_wcliexcluir,"/")
endif
if _wcli1excluir != ''
	_sQuery += "            AND SA1.A1_VACBASE NOT IN " + FormatIn(_wcli1excluir,"/")
endif
_sQuery += "                AND SA1.A1_SATIV1 != '08.02')" // NAO CONSIDERA CESTEIROS
_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
_sQuery += "    AND SD1.D1_DTDIGIT BETWEEN '" + _wdtini   + "' AND '" + _wdtfim   + "'"
_sQuery += "    AND SD1.D1_TIPO = 'D'"
if _wintprod != ''
	_sQuery += " AND SD1.D1_COD IN " + FormatIn(_wintprod,"/")
endif
if _wprodexcluir != ''
	_sQuery += "            AND SD1.D1_COD NOT IN " + FormatIn(_wprodexcluir,"/")
endif
if _wclojas != '1'
	_sQuery += "   AND (SD1.D1_FILIAL  = '01' OR SD1.D1_FILIAL  = '09')"
endif
_sQuery += " )"
do case
	case _worder = '1'  // cliente
		_sQuery += " SELECT C.CLI_COD    AS CODIGO"
		_sQuery += "      , C.CLI_NOME   AS DESCRICAO"
		_sQuery += "      , SUM(C.QUANT) AS QUANT"
		_sQuery += "      , SUM(C.VALOR) AS VALOR"
		_sQuery += "   FROM C"
		_sQuery += "  GROUP BY C.CLI_COD, C.CLI_NOME"
		_sQuery += "  ORDER BY C.CLI_NOME"
		cabec1 := "               CLIENTE                                                                CX                VALOR" 
	case _worder = '2' // linha
		_sQuery += " SELECT C.LIN_COD    AS CODIGO"
		_sQuery += "      , C.LIN_NOME   AS DESCRICAO"
		_sQuery += "      , SUM(C.QUANT) AS QUANT"
		_sQuery += "      , SUM(C.VALOR) AS VALOR"
		_sQuery += "   FROM C"
		_sQuery += "  GROUP BY C.LIN_COD, C.LIN_NOME"
		_sQuery += "  ORDER BY C.LIN_NOME"
		cabec1 := "               LINHA                                                                  CX                 VALOR"
	case _worder = '3' // produto
		_sQuery += " SELECT C.PROD_COD   AS CODIGO"
		_sQuery += "      , C.PROD_DESC  AS DESCRICAO"
		_sQuery += "      , SUM(C.QUANT) AS QUANT"
		_sQuery += "      , SUM(C.VALOR) AS VALOR"
		_sQuery += "   FROM C"
		_sQuery += "  GROUP BY C.PROD_COD, C.PROD_DESC"
		_sQuery += "  ORDER BY C.PROD_DESC"
		cabec1 := "               PRODUTO                                                                CX                  VALOR"
endcase
u_log (_sQuery)

//u_showmemo (_sQuery)

return		  	

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Data Referencial  ?", "D", 8,  0,  "",   "   ", {}            , "Último dia do mês, que deseja fazer apuração da comissão."})
	aadd (_aRegsPerg, {02, "Código de         ?", "C", 6,  0,  "",   "ZAE", {}            , ""})
	aadd (_aRegsPerg, {03, "Código até        ?", "C", 6,  0,  "",   "ZAE", {}            , ""})
	
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
