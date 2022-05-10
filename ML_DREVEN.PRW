// Programa..: ML_DREVEN.PRX
// Autor.....: Catia Cardoso
// Data......: 25/04/2015
// Descricao.: Relatorio de Analise Rentabilidade
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de Analise Rentabilidade
// #PalavasChave      #analise_de_rentabilidade
// #TabelasPrincipais #SD2 #SF2 #SB1 
// #Modulos   		  #FAT
//
// Historico de alteracoes:
// 19/09/2018 - Catia   - Redefinido o relatorio conforme solicitacao Fernando, Rodrigo
//                      - chamado GLPI - Validacao do Cesar
// 02/10/2018 - Catia   - Voltada a versao que tinha sido perdida
// 10/12/2018 - Catia   - tratamento para vendedor do SF2 e do SE1
// 18/02/2018 - Catia   - Verbas utilizadas tratamento do vendedor SE1 e SA1
// 22/10/2019 - Cláudia - Ajustes de previsto/realizado conforme GLPI: 6810
// 04/11/2019 - Cláudia - No union all das devoluções, invertidos os inners Sd2, Sf2 para sf2, sd2, 
//						  pois alguns itens não estavam constando como devolvidos, diferentemente do Exposta dados. 
// 13/11/2019 - Cláudia - Ajuste na consulta de faturamento (1) - Alterado de INNER para LEFT a consulta na SC5
//						  Ajuste na consulta de devolução(4) - Realizando a ligação na tabela SE1 para busca do vendedor
// 10/05/2022 - Claudia - Alterado campo de peso bruto para B1_PESBRU. GLPI: 11822
//
// ------------------------------------------------------------------------------------------------------------------------ 
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_DREVEN()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	
	cString := "SD2"
    cDesc1  := "Analise Rentabilidade"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "M"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_DREVEN"
    titulo  := "Analise Rentabilidade"
    wnrel   := "ML_DREVEN"
    nTipo   := 0
    _lContinua = .T.
	
	if ! u_zzuvl ('039', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina/relatório.")
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
    
    if mv_par17 = 2
   		u_help("Na opção de cliente por REDE, o sistema busca o codigo do cliente MATRIZ informado no cadastro. Esta informação tem que estar correta para que funcione como o esperado.")
   		if mv_par07 != mv_par08
   			u_help("Na opção por REDE, os parametros inicial e final de cliente devem ser iguais.")
   			Return   			
   		endif
   		// verifica se o codigo digitado é um codigo matriz
   		_wmatriz := fbuscacpo ("SA1", 1, xfilial ("SA1") + mv_par07,  "A1_VACBASE")
   		if _wmatriz != mv_par07
   			u_help("Codigo de cliente informado não é o codigo matriz, alterando para o codigo matriz correto.")
   			mv_par07 := _wmatriz
   			mv_par08 := _wmatriz
   		endif
   	endif
   	
   	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SA1"))
	if _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
		_lContinua = .F.
	endif
	
	if _lContinua
		// drop table TMP_TOPLJ
		tcsqlexec ('DELETE TMP_DRE')
		
		RptStatus({|| RptDetail()})
    
		// Libera semaforo
		U_Semaforo (_nLock)
    endif		
Return

Static Function RptDetail()
	Local j := 0
	Local i := 0
    SetRegua(LastRec())
	
	_wdesc  := " "
    _sQuery := " "

   	_ExecQuery()

	//u_showmemo(_sQuery)
	
	_sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
	
	nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "Analise de Rentabilidade: " +  iif(mv_par20==1,'REALIZADO','PREVISTO') + " por " + _wdesc + " Período: " + dtoc(mv_par01) + " até " + dtoc(mv_par02) 
    cabec2 := ""
    
    if mv_par17=2
		_wdescrede = fBuscaCpo ('SA1', 1, xfilial('SA1') + mv_par07 + '01', "A1_NOME")		
	endif
	
	// cria tabela temporario - escopo da impressao
	(_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	_sSQL := ""
        _sSQL += " INSERT INTO TMP_DRE (CODIGO, DESCRICAO, TIPO, DESCTIPO, TOTAL_FATURADO, CUSTO_TOTAL, IMP_TOTAL_NF, IMP_DEB, COMISSAO, FRETE, RAPEL_DESC_TOTAL)"
        _sSQL += " VALUES ( '" + (_sAliasQ) -> CODIGO + "'"
        _sSQL += "        , '" + LEFT((_sAliasQ) -> DESCRICAO ,50) + "'"
        _sSQL += "        , '" + (_sAliasQ) -> TIPO + "'"
        _sSQL += "        , '" + LEFT(ALLTRIM((_sAliasQ) -> DESCTIPO),30) + "'"
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> TOTAL_FATURADO*100,   "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> CUSTO_TOTAL*100,      "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> IMP_TOTAL_NF*100,     "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> IMP_DEB*100,          "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> COMISSAO*100,         "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> FRETE*100,            "@E 9999999999,99" )
        _sSQL += "        , " + TRANSF( (_sAliasQ) -> RAPEL_DESC_TOTAL*100, "@E 9999999999,99" )
        _sSQL += " )"
        if TCSQLExec (_sSQL) < 0
           u_showmemo(_sSQL)
           return
        endif
        (_sAliasQ) -> (dbskip())
    enddo
    // le temporaria em ordem de codigo e ve quais registros faltam
    _wdescricao = U_SeparaCpo ('FATURAMENTO#DEVOLUCOES#FATURAMENTO - DEVOLU#BONIFICACOES#VERBAS LIBERADAS#(-)VERBAS UTILIZADAS','#')
    _sQuery := ""
    _sQuery += "SELECT DISTINCT CODIGO ,DESCRICAO"
    _sQuery += "  FROM TMP_DRE"
    _aDados := U_Qry2Array(_sQuery)
    if len (_aDados) > 0
    	for i=1 to len(_aDados) // codigo da TMPO (VENDEDOR no teste)
    		for j=1 to 6 // codigo do tipo
    			// verifica se ja existe na TMP 
    			_sQuery := ""
    			_sQuery += "SELECT CODIGO, DESCRICAO"
    			_sQuery += "  FROM TMP_DRE"
    			_sQuery += " WHERE TIPO     = '" + str(j,1) + "'"
    			_sQuery += "   AND CODIGO = '" + _aDados[i,1] + "'"
    			_aJatem := U_Qry2Array(_sQuery)
    			// se nao existir cria com os valores zerados
    			if len(_aJatem) = 0
    				_sSQL := ""
    				_sSQL += " INSERT INTO TMP_DRE (CODIGO, DESCRICAO, TIPO, DESCTIPO, TOTAL_FATURADO, CUSTO_TOTAL, IMP_TOTAL_NF, IMP_DEB, COMISSAO, FRETE, RAPEL_DESC_TOTAL)"
    				_sSQL += " VALUES ( '" + _aDados[i,1] + "'"
    				_sSQL += "        , '" + _aDados[i,2] + "'"
    				_sSQL += "        , '" + str(j,1) + "'"
    				_sSQL += "        , '" + _wdescricao [j] + "'""
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
    				_sSQL += "        , 0"
        			_sSQL += " )"
    				if TCSQLExec (_sSQL) < 0
    					u_showmemo(_sSQL)
    					return
    				endif
    			endif
    		next
    	next
    endif
    _sQuery := ""
    _sQuery += "SELECT *"
    _sQuery += "  FROM TMP_DRE"
    _sQuery += " ORDER BY CODIGO, TIPO" 
    
    _sAliasR = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasR, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
//    if mv_par19 = 2
//     	processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
//     	return
//	endif     	
    
    _wmargem := 0
    _wfaturamento := 1
    _wfatbruto :=0
    
    (_sAliasR) -> (DBGoTop ())
    Do While ! (_sAliasR) -> (Eof ())
    
    	If li>65
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	       if mv_par17=2
				@ li, 01 PSAY 'OPCAO POR REDE: ' + alltrim(_wdescrede)
				li ++
			endif	
		endif			      
		
	    _wtitulo = _wdesc + ' : ' + (_sAliasR) -> CODIGO + ' - ' + (_sAliasR) -> DESCRICAO
	    
		if (_sAliasR) -> TIPO = '1'
			if _wmargem != 0
			    li ++
				@ li, 10 PSAY "=== >>> MARGEM"	    
				@ li, 50 PSAY _wmargem  Picture "@E 999,999,999.99"
				if _wfaturamento <= 0
					_wfaturamento := _wfatbruto
				endif
				@ li, 65 PSAY _wmargem/_wfaturamento*100 Picture "@E 999,999.99%"
				li ++
				li ++
			endif	
			@ li, 01 PSAY _wtitulo
			li ++
		endif
				      
		// totais do faturamento
		do case
		case (_sAliasR) -> TIPO = '1' .or. (_sAliasR) -> TIPO = '2'
		    @ li, 10 PSAY ALLTRIM((_sAliasR) -> DESCTIPO)
	        if (_sAliasR) -> TIPO = '1'
				_wfatbruto := (_sAliasR) -> TOTAL_FATURADO
				@ li, 50 PSAY (_sAliasR) -> TOTAL_FATURADO       Picture "@E 999,999,999.99"
			else
				/// imprime percentual de devocluoes sobre o faturamento
				@ li, 50 PSAY (_sAliasR) -> TOTAL_FATURADO*-1       Picture "@E 999,999,999.99"
				@ li, 65 PSAY (_sAliasR) -> TOTAL_FATURADO*-1/_wfatbruto *100 Picture "@E 999,999.99%"
			endif	
		case (_sAliasR) -> TIPO = '3' .or. (_sAliasR) -> TIPO = '4'
		    li ++
		    @ li, 10 PSAY ALLTRIM((_sAliasR) -> DESCTIPO)
	        @ li, 50 PSAY (_sAliasR) -> TOTAL_FATURADO       Picture "@E 999,999,999.99"
	        /// imprime o percentual de bonificacoes
	        if (_sAliasR) -> TIPO = '4'
				@ li, 65 PSAY (_sAliasR) -> TOTAL_FATURADO/_wfatbruto *100 Picture "@E 999,999.99%"
			endif	
			li ++
	        if (_sAliasR) -> TIPO = '3'
				_wfaturamento := (_sAliasR) -> TOTAL_FATURADO
				_wmargem      := _wfaturamento
			endif
	        @ li, 10 PSAY "(-) Custo Produtos"
        	@ li, 50 PSAY (_sAliasR) -> CUSTO_TOTAL             Picture "@E 999,999,999.99"
		    @ li, 65 PSAY (_sAliasR) -> CUSTO_TOTAL/_wfaturamento *100 Picture "@E 999,999.99%"
		    _wmargem = _wmargem - (_sAliasR) -> CUSTO_TOTAL
		    li ++
		    @ li, 10 PSAY "(-) Impostos Destacados NF"
        	@ li, 50 PSAY (_sAliasR) ->IMP_TOTAL_NF    	     Picture "@E 999,999,999.99"
		    @ li, 65 PSAY (_sAliasR) ->IMP_TOTAL_NF/_wfaturamento *100 Picture "@E 999,999.99%"
		    _wmargem = _wmargem - (_sAliasR) -> IMP_TOTAL_NF 
			li ++
			@ li, 10 PSAY "(-) Impostos Sobre Faturamento"	        
			@ li, 50 PSAY (_sAliasR) ->IMP_DEB         	Picture "@E 999,999,999.99"
		    @ li, 65 PSAY (_sAliasR) ->IMP_DEB/_wfaturamento *100 Picture "@E 999,999.99%"
		    _wmargem = _wmargem - (_sAliasR) ->IMP_DEB
			li ++
			_wcomissao = (_sAliasR) ->COMISSAO
			if (_sAliasR) -> TIPO = '4'
				_wcomissao = 0
			endif	
			@ li, 10 PSAY "(-) Comissão"
        	@ li, 50 PSAY _wcomissao       		 Picture "@E 999,999,999.99"
			@ li, 65 PSAY _wcomissao/_wfaturamento *100 Picture "@E 999,999.99%"
			_wmargem = _wmargem - _wcomissao
			li ++
			@ li, 10 PSAY "(-) Frete"
		    @ li, 50 PSAY (_sAliasR) ->FRETE          	  Picture "@E 999,999,999.99"
		    @ li, 65 PSAY (_sAliasR) ->FRETE/_wfaturamento *100 Picture "@E 999,999.99%"
		    _wmargem = _wmargem - (_sAliasR) ->FRETE
			li ++
			_wrapel = (_sAliasR) ->RAPEL_DESC_TOTAL
			if (_sAliasR) -> TIPO = '4'
				_wrapel = 0
			endif	
			@ li, 10 PSAY "(-) Rapel"
			@ li, 50 PSAY _wrapel 	         Picture "@E 999,999,999.99"
		    @ li, 65 PSAY _wrapel/_wfaturamento *100 Picture "@E 999,999.99%"
		    _wmargem = _wmargem - _wrapel			    
		case (_sAliasR) -> TIPO = '5' .or. (_sAliasR) -> TIPO = '6'
		    li ++
			@ li, 10 PSAY ALLTRIM((_sAliasR) -> DESCTIPO)
	        @ li, 50 PSAY (_sAliasR) -> TOTAL_FATURADO       Picture "@E 999,999,999.99"
			@ li, 65 PSAY (_sAliasR) -> TOTAL_FATURADO/_wfaturamento *100 Picture "@E 999,999.99%"
			if (_sAliasR) -> TIPO = '6'
				_wmargem = _wmargem - (_sAliasR) -> TOTAL_FATURADO
			endif
		endcase 
								
		li ++
		(_sAliasR) -> (dbskip())
     enddo
	 
	 li ++
	 @ li, 10 PSAY "=== >>> MARGEM"	    
	 @ li, 50 PSAY _wmargem  Picture "@E 999,999,999.99"
	 if _wfaturamento <= 0
	 	_wfaturamento := _wfatbruto
	 endif
	 @ li, 65 PSAY _wmargem/_wfaturamento*100 Picture "@E 999,999.99%"
	 li ++
 	 	 
	 U_ImpParam (58)
	 
	 Set Device To Screen

     If aReturn[5]==1
	       Set Printer TO
	       dbcommitAll()
	       ourspool(wnrel)
     Endif

     if mv_par19 = 2 
     	_ImprimeCSV(_sQuery)
     endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return

Static Function _ExecQuery()  // previsto e realizado é tratado na mesma query
	_sQuery += " WITH C AS ( SELECT '1' AS TIPO"
	_sQuery += "      , 'FATURAMENTO' AS DESCTIPO"
	if mv_par17 = 2
		_sQuery += "      , SA1.A1_VACBASE       AS CLIENTE"
		_sQuery += "  	  , SA1.A1_VALBASE       AS LOJA" 	 
	else
		_sQuery += "      , SD2.D2_CLIENTE       AS CLIENTE"
		_sQuery += "  	  , SD2.D2_LOJA          AS LOJA"
	endif	 	 
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par20 == 2 // previsto - custo stand
		_sQuery += "      , SUM(ROUND(D2_VACUSTD*SD2.D2_QUANT,2)) AS CUSTO_STAN_B1" // busca do exporta dados pra pegar o custo STAND na hora da emissao da nota
	else // realizado - custo médio
		_sQuery += "      , SUM(ROUND(D2_CUSTO1,2)) AS CUSTO_STAN_B1"
		//_sQuery += "      , SUM(ROUND(D1_CUSTO,2)) AS CUSTO_STAN_B1"
	endif
	_sQuery += "      , SUM(SD2.D2_QUANT)        	AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       	AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRCVEN*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       	AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      	AS NF_ICMSRET"
	_sQuery += "      , SUM(SD2.D2_VALBRUT)      	AS NF_VLR_BRT"
	_sQuery += "	  , SUM(SD2.D2_VALICM)       	AS NF_ICMS"
	_sQuery += "      , SUM(SD2.D2_VALIMP5)      	AS NF_COFINS"
	_sQuery += "      , SUM(SD2.D2_VALIMP6)      	AS NF_PIS"
	// comissao
	if mv_par20 == 2
		_sQuery += "      , SUM(SD2.D2_TOTAL*SD2.D2_COMIS1/100) AS VLR_COMISSAO"  // comissao da nota - PREVISTO
	else
		_sQuery += "	  , ((SELECT SUM(SE3.E3_COMIS)"
		_sQuery += "	      FROM SE3010 AS SE3"
		_sQuery += "		 WHERE SE3.D_E_L_E_T_ = ''"				
		_sQuery += "		   AND SE3.E3_FILIAL   = SD2.D2_FILIAL"
	   	_sQuery += "		   AND SE3.E3_NUM      = SD2.D2_DOC"
	   	_sQuery += "		   AND SE3.E3_EMISSAO >= SD2.D2_EMISSAO"
	   	_sQuery += "		   AND SE3.E3_VEND     BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	   	_sQuery += "		   AND SE3.E3_CODCLI   = SD2.D2_CLIENTE)*SD2.D2_TOTAL/SF2.F2_VALMERC) AS VLR_COMISSAO"
	endif
	_sQuery += "      , SF2.F2_VALMERC           AS TOTPROD_NF"
    // frete
    if mv_par20 == 2
		//_sQuery += "      , SUM(SD2.D2_FRETCIF) AS FRETE"	// frete - PREVISTO
		_sQuery += "      ,ISNULL(CASE SF2.F2_PBRUTO"
		_sQuery += "      		WHEN 0 THEN 0"
		_sQuery += "      		ELSE ROUND(SC5.C5_MVFRE * (SB1.B1_PESBRU * SD2.D2_QUANT) / SF2.F2_PBRUTO, 2)"
		_sQuery += "      		END, 0) AS FRETE"
	else
		_sQuery += "	  , (SELECT  SUM(SZH.ZH_RATEIO)"
		_sQuery += "	       FROM " + RetSQLName ("SZH") + " AS SZH"
		_sQuery += "		  WHERE SZH.D_E_L_E_T_ = ''"				
		_sQuery += "		    AND SZH.ZH_FILIAL  = SD2.D2_FILIAL"
	   	_sQuery += "		    AND SZH.ZH_TPFRE   = 'S'
	   	_sQuery += "		    AND SZH.ZH_NFSAIDA = SD2.D2_DOC"
	   	_sQuery += "		    AND SZH.ZH_SERNFS  = SD2.D2_SERIE"
	   	_sQuery += "		    AND SZH.ZH_ITNFS   = SD2.D2_ITEM) AS FRETE"
	endif
	// rapel
	if mv_par20 == 2		
		_sQuery += "      , SUM(ROUND(SD2.D2_VRAPEL,2))  AS DF_RAPEL"		/// rapel da nota - PREVISTO
	else
		_sQuery += "	    , ((SELECT SUM(SE5.E5_VARAPEL)
		_sQuery += "	        FROM SE5010 AS SE5"
		_sQuery += "		   WHERE SE5.D_E_L_E_T_ = ''"				
		_sQuery += "   		     AND SE5.E5_FILIAL = SD2.D2_FILIAL"
	   	_sQuery += "			 AND SE5.E5_NUMERO = SD2.D2_DOC"
	   	_sQuery += "			 AND SE5.E5_DATA   >= SD2.D2_EMISSAO"
	   	_sQuery += "			 AND SE5.E5_RECPAG = 'R'
	   	_sQuery += "			 AND SE5.E5_CLIENTE = SD2.D2_CLIENTE"
	   	_sQuery += "			 AND SE5.E5_LOJA    = SD2.D2_LOJA"
	   	_sQuery += "			 AND SE5.E5_TIPODOC = 'DC'"
	   	_sQuery += "			 AND SE5.E5_SITUACA = ''"
	   	_sQuery += "			 AND SE5.E5_VARAPEL > 0)*SD2.D2_TOTAL/SF2.F2_VALMERC) AS DF_RAPEL"
	endif		
	_sQuery += "      , SA3.A3_VAGEREN AS SUPER" 	 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "                AND SF2.F2_VEND1   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "    INNER JOIN SA1010 AS SA1" 			
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	IF mv_par17 = 2  // opcao por rede	
		_sQuery += "			AND SA1.A1_VACBASE  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	ENDIF		
	_sQuery += "				AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "    INNER JOIN SA3010 AS SA3" 			
	_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA3.A3_COD  = SF2.F2_VEND1"
	_sQuery += "			    AND SA3.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('1')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "                AND SB1.B1_CODLIN BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"			
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	//_sQuery += "	INNER JOIN SC5010 AS SC5"
	_sQuery += "	LEFT JOIN SC5010 AS SC5"
	_sQuery += "			ON (SC5.D_E_L_E_T_ = ''"
	_sQuery += "			AND SC5.C5_NUM = SD2.D2_PEDIDO"
	_sQuery += "			AND SC5.C5_FILIAL = SD2.D2_FILIAL)"
	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par15 + "' AND '" + mv_par16 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	IF mv_par17 = 1  // opcao por cliente
		_sQuery += "    AND SD2.D2_CLIENTE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    	_sQuery += "    AND SD2.D2_LOJA      BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    ENDIF
   	_sQuery += " 	AND SD2.D2_COD       BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
   	if mv_par17 = 2
   		_sQuery += " GROUP BY SA1.A1_VACBASE , SA1.A1_VALBASE"
   	else
   		_sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA"
   	endif
   	_sQuery += " , SD2.D2_EST, SA3.A3_VAGEREN, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC, "
   	_sQuery += " SD2.D2_VRAPEL,SD2.D2_FILIAL ,SD2.D2_DOC ,SD2.D2_EMISSAO ,SD2.D2_TOTAL ,SD2.D2_SERIE ,SD2.D2_ITEM,"
   	_sQuery += " SD2.D2_CLIENTE,SD2.D2_LOJA,SF2.F2_PBRUTO,SC5.C5_MVFRE,SB1.B1_PESBRU,SD2.D2_QUANT "
   	// busca bonificacoes
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT '4' AS TIPO" 
   	_sQuery += "      , 'BONIFICACOES' AS DESCTIPO"
   	IF mv_par17 = 2  // opcao por rede
   		_sQuery += "      , SA1.A1_VACBASE       AS CLIENTE"
		_sQuery += "  	  , SA1.A1_VALBASE       AS LOJA"
   	else
	   	_sQuery += "  	  , SD2.D2_CLIENTE       AS CLIENTE" 	 
	    _sQuery += "  	  , SD2.D2_LOJA          AS LOJA"
    endif
    _sQuery += "  	  , SD2.D2_EST           AS ESTADO"
	_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR"	 
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD2.D2_COD           AS PRODUTO"
	if mv_par20 == 2 // PREVISTO - STAND
		_sQuery += "      , SUM(ROUND(D2_VACUSTD*SD2.D2_QUANT,2)) AS CUSTO_STAN_B1" // busca do exporta dados pra pegar o custo STAND na hora da emissao da nota
	else // REALIZADO - MÉDIO
		_sQuery += "      , SUM(ROUND(D2_CUSTO1,2)) AS CUSTO_STAN_B1" 
	endif
	_sQuery += "      , SUM(SD2.D2_QUANT)        AS NF_QUANT"
	_sQuery += "      , SUM(SD2.D2_PRUNIT)       AS NF_VLRUNIT"
	_sQuery += "      , SUM(SD2.D2_PRCVEN*D2_QUANT) AS NF_VLRPROD"	
	_sQuery += "      , SUM(SD2.D2_VALIPI)       AS NF_VALIPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET)      AS NF_ICMSRET"
	_sQuery += "      , SUM(SD2.D2_VALBRUT)      AS NF_VLR_BRT"
	_sQuery += "	  , SUM(SD2.D2_VALICM)       AS NF_ICMS"
	_sQuery += "      , SUM(SD2.D2_VALIMP5)      AS NF_COFINS"
	_sQuery += "      , SUM(SD2.D2_VALIMP6)      AS NF_PIS"
	_sQuery += "      , 0                        AS VLR_COMISSAO" // comissao
	_sQuery += "      , SF2.F2_VALMERC           AS TOTPROD_NF"
    if mv_par20 == 2
		//_sQuery += "      , SUM(SD2.D2_FRETCIF) AS FRETE"	// frete - PREVISTO
		_sQuery += "      ,ISNULL(CASE SF2.F2_PBRUTO"
		_sQuery += "      		WHEN 0 THEN 0"
		_sQuery += "      		ELSE ROUND(SC5.C5_MVFRE * (SB1.B1_PESBRU * SD2.D2_QUANT) / SF2.F2_PBRUTO, 2)"
		_sQuery += "      		END, 0) AS FRETE"
	else
		_sQuery += "	  , (SELECT  SUM(SZH.ZH_RATEIO)"    // frete realizdo
		_sQuery += "	       FROM " + RetSQLName ("SZH") + " AS SZH"
		_sQuery += "		  WHERE SZH.D_E_L_E_T_ = ''"				
		_sQuery += "		    AND SZH.ZH_FILIAL  = SD2.D2_FILIAL"
	   	_sQuery += "		    AND SZH.ZH_TPFRE   = 'S'
	   	_sQuery += "		    AND SZH.ZH_NFSAIDA = SD2.D2_DOC"
	   	_sQuery += "		    AND SZH.ZH_SERNFS  = SD2.D2_SERIE"
	   	_sQuery += "		    AND SZH.ZH_ITNFS   = SD2.D2_ITEM) AS FRETE"
	endif
	_sQuery += "      , 0                       AS DF_RAPEL"  // rapel
	_sQuery += "      , SA3.A3_VAGEREN AS SUPER" 
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "		   	ON (SF2.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"				
	_sQuery += "			   	AND SF2.F2_DOC     = SD2.D2_DOC"				
	_sQuery += "			   	AND SF2.F2_SERIE   = SD2.D2_SERIE"				
	_sQuery += "			   	AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"				
	_sQuery += "			   	AND SF2.F2_LOJA    = SD2.D2_LOJA"	
	_sQuery += "                AND SF2.F2_VEND1   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += "			   	AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "   INNER JOIN SA1010 AS SA1" 			
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "			AND SA1.A1_COD  = SD2.D2_CLIENTE"
	IF mv_par17 = 2  // opcao por rede	
		_sQuery += "		AND SA1.A1_VACBASE  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	ENDIF	
	_sQuery += "			AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sQuery += "    INNER JOIN SA3010 AS SA3" 			
	_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA3.A3_COD  = SF2.F2_VEND1"
	_sQuery += "			    AND SA3.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SF4.F4_MARGEM IN ('3')"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)" 
	_sQuery += "	INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "			ON (SB1.D_E_L_E_T_ = ''"				
	_sQuery += "                AND SB1.B1_CODLIN BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"			
	_sQuery += "				AND SB1.B1_COD    = SD2.D2_COD)"
	_sQuery += "	INNER JOIN SC5010 AS SC5"
	_sQuery += "			ON (SC5.D_E_L_E_T_ = ''"
	_sQuery += "			AND SC5.C5_NUM = SD2.D2_PEDIDO"
	_sQuery += "			AND SC5.C5_FILIAL = SD2.D2_FILIAL)"
   	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"   
   	_sQuery += "    AND SD2.D2_FILIAL    BETWEEN '" + mv_par15 + "' AND '" + mv_par16 + "'"
   	_sQuery += "    AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "    AND SD2.D2_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	IF mv_par17 = 1  // opcao por cliente
		_sQuery += "    AND SD2.D2_CLIENTE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    	_sQuery += "    AND SD2.D2_LOJA      BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    ENDIF
   	_sQuery += " 	AND SD2.D2_COD       BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
   	if mv_par17 = 2
   		_sQuery += " GROUP BY SA1.A1_VACBASE , SA1.A1_VALBASE"
   	else
   		_sQuery += " GROUP BY SD2.D2_CLIENTE , SD2.D2_LOJA"
   	endif
   	_sQuery += " , SD2.D2_EST, SA3.A3_VAGEREN, SF2.F2_VEND1, SB1.B1_CODLIN, SD2.D2_COD, SF2.F2_VALMERC,SD2.D2_FILIAL ,SD2.D2_DOC ,"
   	_sQuery += " SD2.D2_EMISSAO ,SD2.D2_TOTAL ,SD2.D2_SERIE ,SD2.D2_ITEM,SD2.D2_CLIENTE,SD2.D2_LOJA,SF2.F2_PBRUTO,SC5.C5_MVFRE,SB1.B1_PESBRU,SD2.D2_QUANT "
   	// busca devoluções e reversao de impostos
   	_sQuery += " UNION ALL "
   	_sQuery += " SELECT '2' AS TIPO"
   	_sQuery += "      , 'DEVOLUCOES' AS DESCTIPO" 
   	if mv_par17 = 2
   		_sQuery += "      , SA1.A1_VACBASE       AS CLIENTE"
		_sQuery += "  	  , SA1.A1_VALBASE       AS LOJA"
	else
	   	_sQuery += "  	  , SD1.D1_FORNECE       AS CLIENTE" 	 
	    _sQuery += "  	  , SD1.D1_LOJA          AS LOJA" 	 
	endif
    _sQuery += "  	  , SF1.F1_EST           AS ESTADO"
	//_sQuery += "  	  , SF2.F2_VEND1         AS VENDEDOR" //
	_sQuery += "  	  , SE1.E1_VEND1         AS VENDEDOR"	 	
	_sQuery += "      , SB1.B1_CODLIN        AS LINHA"
	_sQuery += "      , SD1.D1_COD           AS PRODUTO"
	if mv_par20 == 2 // previsto - custo stand
		_sQuery += "	  , ISNULL(SUM(ROUND(SD2.D2_VACUSTD*SD1.D1_QUANT, 2))*-1,0) AS CUSTO_STAN_B1" // REVERTE PELO CUSTO DA NOTA DE ENTRADA 
	else // previsto - custo medio
		//_sQuery += "	  , ISNULL(SUM(ROUND(SD2.D2_CUSTO1, 2))*-1,0) AS CUSTO_STAN_B1"
		_sQuery += "	  , ISNULL(SUM(ROUND(SD1.D1_CUSTO, 2))*-1,0) AS CUSTO_STAN_B1"
	endif
	_sQuery += "   	  , SUM(SD1.D1_QUANT)*-1 AS NF_QUANT"
	_sQuery += "   	  , ISNULL(SUM(SD1.D1_VUNIT)*-1,0) AS NF_VLRUNIT"
	_sQuery += "      , ISNULL(SUM(SD1.D1_VUNIT * D1_QUANT)*-1,0) AS NF_VLRPROD"
	_sQuery += "   	  , SUM(SD1.D1_VALIPI)*-1 AS NF_VALIPI"
	_sQuery += "      , SUM(SD1.D1_ICMSRET)*-1 AS NF_ICMSRET"
	_sQuery += "      , SUM(SD1.D1_TOTAL + SD1.D1_VALIPI + SD1.D1_ICMSRET)*-1 AS NF_VLR_BRT"
	_sQuery += "      , SUM(SD1.D1_VALICM)*-1  AS NF_ICMS"
	_sQuery += "      , SUM(SD1.D1_VALIMP5)*-1 AS NF_COFINS"
	_sQuery += "      , SUM(SD1.D1_VALIMP6)*-1 AS NF_PIS"
	if mv_par20 == 2
		_sQuery += "      , SUM((SD2.D2_TOTAL*SD2.D2_COMIS1/100)*SD1.D1_QUANT/SD2.D2_QUANT)*-1 AS VLR_COMISSAO"  // comissao da nota - PREVISTO
	else
		_sQuery += "      , 0 AS VLR_COMISSAO" // realizado nas comissoes nao tem
	endif
	_sQuery += "      , SD1.D1_TOTAL*-1 AS TOTPROD_NF"
	if mv_par20 == 2 // frete PREVISTO 
		//_sQuery += "      , ISNULL(SUM(SD2.D2_FRETCIF*SD1.D1_QUANT/SD2.D2_QUANT), 0) AS FRETE" // frete PREVISTO
		_sQuery += "      , 0 AS FRETE" // frete PREVISTO
	else
		_sQuery += "      , ISNULL(SUM(SZH.ZH_RATEIO), 0) AS FRETE"  // frete REALIZADO
	endif
	if mv_par20 == 2
		_sQuery += "      , ISNULL(SUM(SD2.D2_VRAPEL*SD1.D1_QUANT/SD2.D2_QUANT)*-1, 0)  AS DF_RAPEL"		/// rapel da nota - PREVISTO
	else
		_sQuery += "      , 0 AS DF_RAPEL"  // realizado nas devolucções nao tem		
	endif
	_sQuery += "      , SA3.A3_VAGEREN AS SUPER"
	_sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_sQuery += "		INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_sQuery += "			ON (SF1.D_E_L_E_T_ = ''
	_sQuery += "				AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
	_sQuery += "    			AND SF1.F1_DOC     = SD1.D1_DOC"				
	_sQuery += "				AND SF1.F1_SERIE   = SD1.D1_SERIE"			
	_sQuery += "    			AND SF1.F1_FORNECE = SD1.D1_FORNECE"
	_sQuery += "				AND SF1.F1_LOJA    = SD1.D1_LOJA"
	_sQuery += "  			AND SF1.F1_EST  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"			  
    _sQuery += "	 			AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"
	_sQuery += "		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO  = SD1.D1_TES"
	_sQuery += "				AND SF4.F4_MARGEM  = '2')"
	IF mv_par17 = 2  // opcao por rede 
		_sQuery += "	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
		_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
		_sQuery += "				AND SA1.A1_COD  = SD1.D1_FORNECE"
		_sQuery += " 			    AND SA1.A1_VEND BETWEEN     '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sQuery += "		    	AND SA1.A1_VACBASE  BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"	
		_sQuery += "				AND SA1.A1_LOJA = SD1.D1_LOJA)"
	ENDIF		
	_sQuery += "		INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "	 			ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SB1.B1_CODLIN BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
    _sQuery += "	 			AND SB1.B1_COD  = SD1.D1_COD)"
    /*
    _sQuery += "		LEFT JOIN " + RetSQLName ("SD2") + " AS SD2 "
	_sQuery += "	 			ON (SD2.D_E_L_E_T_     = ''"
	_sQuery += "	                AND SD2.D2_FILIAL  = SD1.D1_FILIAL"
   	_sQuery += "					AND SD2.D2_CLIENTE = SD1.D1_FORNECE"
    _sQuery += "					AND SD2.D2_DOC     = SD1.D1_NFORI"
   	_sQuery += "					AND SD2.D2_ITEM    = SD1.D1_ITEMORI"
   	_sQuery += "					AND SD2.D2_LOJA = SD1.D1_LOJA)"
   	_sQuery += "		 INNER JOIN SF2010 SF2"
	_sQuery += "				 ON (SF2.D_E_L_E_T_ = ''"
	_sQuery += "					AND SF2.F2_FILIAL = SD2.D2_FILIAL"
	_sQuery += "					AND SF2.F2_DOC = SD2.D2_DOC"
	_sQuery += "					AND SF2.F2_SERIE = SD2.D2_SERIE"
	_sQuery += "					AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
	_sQuery += "					AND SF2.F2_LOJA = SD2.D2_LOJA"
	_sQuery += "					AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')" */
	
	_sQuery += "		LEFT JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "	 		ON (SF2.F2_DOC = SD1.D1_NFORI"
	_sQuery += "	 		AND SF2.F2_SERIE = SD1.D1_SERIORI"
	_sQuery += "	 		AND SF2.D_E_L_E_T_ <> '*'"
	_sQuery += "	 		AND SF2.F2_FILIAL = SD1.D1_FILIAL)"
	//_sQuery += "			AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')" //
	_sQuery += "		LEFT JOIN " + RetSQLName ("SD2") + " AS SD2 "
	_sQuery += "			ON (SD2.D2_DOC = SD1.D1_NFORI"
	_sQuery += "			AND SD2.D2_SERIE = SD1.D1_SERIORI"
	_sQuery += "			AND SD2.D2_ITEM = SD1.D1_ITEMORI"
	_sQuery += "			AND SD2.D_E_L_E_T_ <> '*'"
	_sQuery += "			AND SD2.D2_FILIAL = SD1.D1_FILIAL)"
	_sQuery += "		LEFT JOIN " + RetSQLName ("SE1") + " AS SE1 " // ACESSA O FINANCEIRO PARA BUSCAR O VENDEDOR QUE FOI DEBITADA A DEVOLUCAO //
	_sQuery += "		ON (SE1.D_E_L_E_T_ = '' "
	_sQuery += "				AND SE1.E1_FILIAL = SD1.D1_FILIAL "
	_sQuery += "				AND SE1.E1_NUM = SD1.D1_DOC "
	_sQuery += "				AND SE1.E1_PREFIXO = SD1.D1_SERIE "
	_sQuery += "				AND SE1.E1_CLIENTE = SD1.D1_FORNECE "
	_sQuery += "				AND SE1.E1_LOJA = SD1.D1_LOJA "
	_sQuery += "				AND SE1.E1_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_sQuery += "    	INNER JOIN SA3010 AS SA3" 			
	_sQuery += "				ON (SA3.D_E_L_E_T_ = ''"				
	//_sQuery += "					AND SA3.A3_COD  = SF2.F2_VEND1" // 
	_sQuery += "					AND SA3.A3_COD  = SE1.E1_VEND1 "
	_sQuery += "			    	AND SA3.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
    _sQuery += "	    LEFT JOIN " + RetSQLName ("SZH") + " AS SZH"
	_sQuery += "		   		ON (SZH.D_E_L_E_T_ = ''"	
	_sQuery += "					AND SZH.ZH_FILIAL  = SD1.D1_FILIAL"
   	_sQuery += "					AND SZH.ZH_TPFRE   = 'E'
   	_sQuery += "					AND SZH.ZH_NFENTR  = SD1.D1_DOC"
   	_sQuery += "					AND SZH.ZH_SRNFENT = SD1.D1_SERIE"
   	_sQuery += "					AND SZH.ZH_FORNECE = SD1.D1_FORNECE"
	_sQuery += "					AND SZH.ZH_LOJA    = SD1.D1_LOJA"
   	_sQuery += "					AND SZH.ZH_ITNFE   = SUBSTRING (SD1.D1_ITEM,3,2) )"
 	_sQuery += "   WHERE SD1.D_E_L_E_T_ = ''"
 	_sQuery += "	  AND SD1.D1_FILIAL    BETWEEN '" + mv_par15 + "' AND '" + mv_par16 + "'"
    _sQuery += "	  AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    if mv_par17 = 1  // opcao por cliente
		_sQuery += " 	  AND SD1.D1_FORNECE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"    
   		_sQuery += " 	  AND SD1.D1_LOJA      BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	endif   		
	_sQuery += " 	  AND SD1.D1_COD       BETWEEN '" + mv_par13 + "' AND '" + mv_par14 + "'"
	if mv_par17 = 2
   		_sQuery += " GROUP BY SA1.A1_VACBASE , SA1.A1_VALBASE"
   	else
   		_sQuery += " GROUP BY SD1.D1_FORNECE , SD1.D1_LOJA"
   	endif
   	_sQuery += " , SF1.F1_EST, SA3.A3_VAGEREN, " //SF2.F2_VEND1, 
   	_sQuery += " SE1.E1_VEND1, SB1.B1_CODLIN, SD1.D1_COD, SD1.D1_TOTAL ,SD1.D1_DOC,SD1.D1_FORNECE,SD1.D1_LOJA "
	_sQuery += " UNION ALL "
	_sQuery += " SELECT '5' AS TIPO"
	_sQuery += " 	 ,'VERBAS LIBERADAS' AS DESCTIPO"
	_sQuery += " 	 ,ZA4.ZA4_CLI AS CLIENTE"
	_sQuery += " 	 ,ZA4.ZA4_LOJA AS LOJA"
	_sQuery += " 	 ,SA1.A1_EST AS ESTADO"
	_sQuery += " 	 ,SA1.A1_VEND AS VENDEDOR"
	_sQuery += " 	 ,'' AS LINHA"
	_sQuery += " 	 ,'VERBA' AS PRODUTO"
	_sQuery += " 	 ,0 AS CUSTO_STAN_B1"
	_sQuery += " 	 ,0 AS NF_QUANT"
	_sQuery += " 	 ,0 AS NF_VLRUNIT"
	_sQuery += " 	 ,0 AS NF_VLRPROD"
	_sQuery += " 	 ,0 AS NF_VALIPI"
	_sQuery += " 	 ,0 AS NF_ICMSRET"
	_sQuery += " 	 ,SUM(ZA4.ZA4_VLR) AS NF_VLR_BRT"
	_sQuery += "     ,0 AS NF_ICMS"
	_sQuery += "     ,0 AS NF_COFINS"
	_sQuery += "     ,0 AS NF_PIS"
	_sQuery += "     ,0 AS VLR_COMISSAO"
	_sQuery += " 	 ,0 AS TOTPROD_NF"
	_sQuery += " 	 ,0 AS FRETE"
	_sQuery += " 	 ,0 AS DF_RAPEL"
	_sQuery += "     , SA3.A3_VAGEREN AS SUPER"
	_sQuery += "   FROM ZA4010 AS ZA4"
	_sQuery += "   INNER JOIN SA1010 AS SA1"
	_sQuery += " 	  ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += " 	  AND SA1.A1_COD = ZA4.ZA4_CLI"
	_sQuery += " 	  AND SA1.A1_VEND BETWEEN '   ' AND 'ZZZ'"
	_sQuery += " 	  AND SA1.A1_LOJA = ZA4.ZA4_LOJA)"
	_sQuery += "    INNER JOIN SA3010 AS SA3" 			
	_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"				
	_sQuery += "				AND SA3.A3_COD  = SA1.A1_VEND"
	_sQuery += "			    AND SA3.A3_COD  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += "			    AND SA3.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "   WHERE ZA4.D_E_L_E_T_ = ''"
	_sQuery += "   AND ZA4.ZA4_DLIB  BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "   AND ZA4.ZA4_TLIB != '1'"
	_sQuery += "   AND ZA4.ZA4_CLI   BETWEEN  '" + mv_par07 + "' AND '" + mv_par08 + "'"    
   	_sQuery += "   AND ZA4.ZA4_LOJA  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_sQuery += "   GROUP BY ZA4.ZA4_CLI"
	_sQuery += " 		  ,ZA4.ZA4_LOJA"
	_sQuery += " 		  ,SA1.A1_EST"
	_sQuery += " 		  ,SA3.A3_VAGEREN"
	_sQuery += " 		  ,SA1.A1_VEND"
	_sQuery += " UNION ALL "
	_sQuery += " SELECT '6' AS TIPO"
	_sQuery += " 	 ,'(-)VERBAS UTILIZADAS' AS DESCTIPO"
	if mv_par17 = 1
		_sQuery += " 	 ,ZA5.ZA5_CLI AS CLIENTE"
		_sQuery += " 	 ,ZA5.ZA5_LOJA AS LOJA"
	else
		_sQuery += " 	 ,SA1.A1_VACBASE AS CLIENTE"
		_sQuery += " 	 ,SA1.A1_VALBASE AS LOJA"
	endif	
	_sQuery += " 	 ,SA1.A1_EST AS ESTADO"
	//_sQuery += " 	 , ISNULL(SF2.F2_VEND1,SE1.E1_VEND1) AS VENDEDOR"
	_sQuery += " 	 , ISNULL(SE1.E1_VEND1, SA1.A1_VEND) AS VENDEDOR"
	_sQuery += " 	 ,'' AS LINHA"
	_sQuery += " 	 ,'VERBA' AS PRODUTO"
	_sQuery += " 	 ,0 AS CUSTO_STAN_B1"
	_sQuery += " 	 ,0 AS NF_QUANT"
	_sQuery += " 	 ,0 AS NF_VLRUNIT"
	_sQuery += " 	 ,0 AS NF_VLRPROD"
	_sQuery += " 	 ,0 AS NF_VALIPI"
	_sQuery += " 	 ,0 AS NF_ICMSRET"
	_sQuery += " 	 ,SUM(ZA5.ZA5_VLR) AS NF_VLR_BRT"
	_sQuery += "     ,0 AS NF_ICMS"
	_sQuery += "     ,0 AS NF_COFINS"
	_sQuery += "     ,0 AS NF_PIS"
	_sQuery += "     ,0 AS VLR_COMISSAO"
	_sQuery += " 	 ,0 AS TOTPROD_NF"
	_sQuery += " 	 ,0 AS FRETE"
	_sQuery += " 	 ,0 AS DF_RAPEL"
	//_sQuery += "     ,IIF(SF2.F2_VEND1 != '',SA3N.A3_VAGEREN, SA3T.A3_VAGEREN) AS SUPER"
	_sQuery += "     ,IIF(SE1.E1_VEND1 != '',SA3T.A3_VAGEREN, SA3C.A3_VAGEREN) AS SUPER"
	_sQuery += "   FROM ZA5010 AS ZA5"
	_sQuery += "	  INNER JOIN SA1010 AS SA1"
	_sQuery += " 	     ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += " 	  	     AND SA1.A1_COD = ZA5.ZA5_CLI"
	if mv_par17 = 2
		_sQuery += " 	  	 AND SA1.A1_VACBASE BETWEEN  '" + mv_par07 + "' AND '" + mv_par08 + "'"
	endif
	_sQuery += " 	         AND SA1.A1_LOJA = ZA5.ZA5_LOJA)"
	_sQuery += "	  LEFT JOIN SF2010 AS SF2"
 	_sQuery += "		  ON (SF2.D_E_L_E_T_ = ''"
 	_sQuery += "			    AND SF2.F2_DOC     = ZA5.ZA5_DOC"
	_sQuery += "			    AND SF2.F2_SERIE   = '10'"
	//_sQuery += "				AND SF2.F2_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"  
	_sQuery += "	            AND SF2.F2_CLIENTE = ZA5.ZA5_CLI"
	_sQuery += "	            AND SF2.F2_LOJA    = ZA5.ZA5_LOJA)"
	//_sQuery += "      LEFT JOIN SA3010 AS SA3N" 			
	//_sQuery += "		 ON (SA3N.D_E_L_E_T_ = ''"				
	//_sQuery += "		 	 AND SA3N.A3_COD  = SF2.F2_VEND1"
	//_sQuery += "			 AND SA3N.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "	  LEFT JOIN SE1010 AS SE1"
 	_sQuery += "		  ON (SE1.D_E_L_E_T_ = ''"
 	_sQuery += "			   AND SE1.E1_NUM     = ZA5.ZA5_DOC"
	//_sQuery += "			   AND SE1.E1_VEND1 BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"  
	_sQuery += "	           AND SE1.E1_CLIENTE = ZA5.ZA5_CLI"
	_sQuery += "	           AND SE1.E1_PARCELA = ZA5.ZA5_PARC"
	_sQuery += "	           AND SE1.E1_LOJA    = ZA5.ZA5_LOJA)"
	_sQuery += "      LEFT JOIN SA3010 AS SA3T" 			
	_sQuery += "		 ON (SA3T.D_E_L_E_T_ = ''"				
	_sQuery += "		 	 AND SA3T.A3_COD  = SE1.E1_VEND1"
	_sQuery += "			 AND SA3T.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "      LEFT JOIN SA3010 AS SA3C" 			
	_sQuery += "		 ON (SA3C.D_E_L_E_T_ = ''"				
	_sQuery += "		 	 AND SA3C.A3_COD  = SA1.A1_VEND"
	_sQuery += "			 AND SA3C.A3_VAGEREN  BETWEEN '" + mv_par21 + "' AND '" + mv_par22 + "')"
	_sQuery += "   WHERE ZA5.D_E_L_E_T_ = ''"
	_sQuery += "     AND ZA5.ZA5_TLIB NOT IN ('1','9')"
	_sQuery += "     AND ZA5.ZA5_DTA  BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	if mv_par17 = 1
		_sQuery += "     AND ZA5.ZA5_CLI   BETWEEN  '" + mv_par07 + "' AND '" + mv_par08 + "'"
		_sQuery += "     AND ZA5.ZA5_LOJA  BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		_sQuery += "   GROUP BY ZA5.ZA5_CLI"
		_sQuery += " 		  ,ZA5.ZA5_LOJA"
	else
		_sQuery += "   GROUP BY SA1.A1_VACBASE"
		_sQuery += " 		  , SA1.A1_VALBASE"
	endif	
	_sQuery += " 		  ,SA1.A1_EST"
	_sQuery += " 		  ,SA3T.A3_VAGEREN"
	_sQuery += " 		  ,SA3C.A3_VAGEREN"
	_sQuery += " 		  ,SE1.E1_VEND1"
	_sQuery += " 		  ,SA1.A1_VEND"
	_sQuery += " ) "
	// busca dados da with
	_sQuery += " SELECT '3' AS TIPO, 'FATURAMENTO - DEVOLUÇÕES' AS DESCTIPO, ISNULL(SUM(NF_VLR_BRT),0)  AS TOTAL_FATURADO"
 	_sQuery += "      , ISNULL(SUM(CUSTO_STAN_B1),0) 				 AS CUSTO_TOTAL"
	_sQuery += "   	  , ISNULL(SUM(NF_VALIPI+NF_ICMSRET),0) 		 AS IMP_TOTAL_NF"
	_sQuery += "      , ISNULL(SUM(NF_ICMS+NF_PIS+NF_COFINS),0) 	 AS IMP_DEB"
	_sQuery += "      , ISNULL(SUM(VLR_COMISSAO),0) 				 AS COMISSAO"
	_sQuery += "      , ISNULL(SUM(FRETE),0) 					 	 AS FRETE"
	_sQuery += "      , ISNULL(SUM(DF_RAPEL),0) 					 AS RAPEL_DESC_TOTAL"
	DO CASE
		CASE mv_par18 = 1
			_sQuery += "       , C.ESTADO 				 AS CODIGO"
			_sQuery += "       , C.ESTADO 				 AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += " WHERE C.TIPO IN ('1','2')" 
			_sQuery += " GROUP BY C.ESTADO"
		CASE mv_par18 = 2
			_sQuery += "      , C.SUPER                 AS CODIGO"
			_sQuery += "      , SUP.ZAE_NOME            AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "	INNER JOIN ZAE010 AS SUP"
			_sQuery += "		ON (SUP.D_E_L_E_T_ = ''"
			_sQuery += "			AND SUP.ZAE_CCORD = C.SUPER)"
			_sQuery += " WHERE C.TIPO IN ('1','2')"
			_sQuery += " GROUP BY C.SUPER, SUP.ZAE_NOME"
		CASE mv_par18 = 3	
			_sQuery += "      , C.CLIENTE               AS CODIGO"
			_sQuery += "      , SA1.A1_NOME             AS DESCRICAO"
			_sQuery += " FROM C"
			_sQuery += " 	INNER JOIN SA1010 AS SA1"
			_sQuery += " 		ON (SA1.D_E_L_E_T_ = ''"
			_sQuery += " 			AND SA1.A1_COD = C.CLIENTE)"
			_sQuery += " WHERE C.TIPO IN ('1','2')"
			_sQuery += " GROUP BY C.CLIENTE, SA1.A1_NOME"
		CASE mv_par18 = 4	
			_sQuery += "      , C.VENDEDOR              AS CODIGO"
			_sQuery += "      , SA3.A3_NOME             AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "  	INNER JOIN SA3010 AS SA3"
			_sQuery += "		ON (SA3.D_E_L_E_T_ = ''"
			_sQuery += "  			AND SA3.A3_COD = C.VENDEDOR)"
			_sQuery += " WHERE C.TIPO IN ('1','2')"
			_sQuery += " GROUP BY C.VENDEDOR, SA3.A3_NOME"
		CASE mv_par18 = 5
			_sQuery += "      , C.PRODUTO              AS CODIGO"
			_sQuery += "      , SB1.B1_DESC            AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "  	LEFT JOIN SB1010 AS SB1"
			_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += "  			AND SB1.B1_COD = C.PRODUTO)"
			_sQuery += " WHERE C.TIPO IN ('1','2')"
			_sQuery += " GROUP BY C.PRODUTO, SB1.B1_DESC"
	ENDCASE
	_sQuery += " UNION ALL"
	_sQuery += " SELECT C.TIPO AS TIPO, C.DESCTIPO AS DESCTIPO, ISNULL(SUM(NF_VLR_BRT),0)  AS TOTAL_FATURADO"
 	_sQuery += "      , ISNULL(SUM(CUSTO_STAN_B1),0) 				 AS CUSTO_TOTAL"
	_sQuery += "   	  , ISNULL(SUM(NF_VALIPI+NF_ICMSRET),0) 		 AS IMP_TOTAL_NF"
	_sQuery += "      , ISNULL(SUM(NF_ICMS+NF_PIS+NF_COFINS),0) 	 AS IMP_DEB"
	_sQuery += "      , ISNULL(SUM(VLR_COMISSAO),0) 				 AS COMISSAO"
	_sQuery += "      , ISNULL(SUM(FRETE),0) 					 	 AS FRETE"
	_sQuery += "      , ISNULL(SUM(DF_RAPEL),0) 					 AS RAPEL_DESC_TOTAL"
	DO CASE
		CASE mv_par18 = 1
			_sQuery += "       , C.ESTADO 				 AS ESTADO"
			_sQuery += "       , C.ESTADO 				 AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += " WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " GROUP BY C.ESTADO, C.TIPO, C.DESCTIPO"
			_sQuery += " ORDER BY C.ESTADO, TIPO"
			_wdesc  = "ESTADO"
		CASE mv_par18 = 2
			_sQuery += "      , C.SUPER                 AS CODIGO"
			_sQuery += "      , SUP.ZAE_NOME            AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "	INNER JOIN ZAE010 AS SUP"
			_sQuery += "		ON (SUP.D_E_L_E_T_ = ''"
			_sQuery += "			AND SUP.ZAE_CCORD = C.SUPER)"
			_sQuery += " WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " GROUP BY C.SUPER, SUP.ZAE_NOME, C.TIPO,C.DESCTIPO"
			_sQuery += " ORDER BY C.SUPER, SUP.ZAE_NOME, TIPO"
			_wdesc  = "SUPERVISOR"
		CASE mv_par18 = 3	
			_sQuery += "      , C.CLIENTE              AS CODIGO"
			_sQuery += "      , SA1.A1_NOME            AS DESCRICAO"
			_sQuery += " FROM C"
			_sQuery += " 	INNER JOIN SA1010 AS SA1"
			_sQuery += " 		ON (SA1.D_E_L_E_T_ = ''"
			_sQuery += " 			AND SA1.A1_COD = C.CLIENTE)"
			_sQuery += " WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " GROUP BY C.CLIENTE, SA1.A1_NOME, C.TIPO ,C.DESCTIPO"
			_sQuery += " ORDER BY C.CLIENTE, SA1.A1_NOME, TIPO"
			_wdesc  = "CLIENTE"
		CASE mv_par18 = 4	
			_sQuery += "      , C.VENDEDOR             AS CODIGO"
			_sQuery += "      , SA3.A3_NOME            AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "  	INNER JOIN SA3010 AS SA3"
			_sQuery += "		ON (SA3.D_E_L_E_T_ = ''"
			_sQuery += "  			AND SA3.A3_COD = C.VENDEDOR)"
			_sQuery += " WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " GROUP BY C.VENDEDOR, SA3.A3_NOME, C.TIPO, C.DESCTIPO"
			_sQuery += " ORDER BY C.VENDEDOR, SA3.A3_NOME, TIPO"
			_wdesc  = "VENDEDOR"
		CASE mv_par18 = 5
			_sQuery += "      , C.PRODUTO             AS CODIGO"
			_sQuery += "      , SB1.B1_DESC           AS DESCRICAO"
			_sQuery += "  FROM C"
			_sQuery += "  	LEFT JOIN SB1010 AS SB1"
			_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
			_sQuery += "  			AND SB1.B1_COD = C.PRODUTO)"
			_sQuery += " WHERE C.VENDEDOR BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
			_sQuery += " GROUP BY C.PRODUTO, SB1.B1_DESC, C.TIPO, C.DESCTIPO"
			_sQuery += " ORDER BY C.PRODUTO, SB1.B1_DESC, TIPO"
			_wdesc  = "PRODUTO"
	ENDCASE
	//u_showmemo(_sQuery)
nHandle := FCreate("c:\temp\RENTABILIDADE.txt")
FWrite(nHandle,_sQuery )
FClose(nHandle)
return	

Static Function _ImprimeCSV(_sQuery)
	local oExcelApp := NIL
	local _sProg    := ""
	_wmargem 		:= 0
	_wfaturamento 	:= 0
	_wfatbruto 		:= 0
	_wcomissao 		:= 0
	
	If mv_par20 == 1 // realizado
		nHandle := FCreate("c:\temp\RentRealizado.csv")
	Else // previsto
		nHandle := FCreate("c:\temp\RentPrevisto.csv")
	EndIf
				
	_TRB = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _TRB, .f., .t.)
	
	(_TRB) -> (DBGoTop ())
	Do While ! (_TRB) -> (Eof ())
		//FClose(nHandle)
		
		if (_TRB) -> TIPO = '1'
			if _wmargem != 0			
				if _wfaturamento <= 0
					_wfaturamento := _wfatbruto
				endif
				
				_sCSV := "**** MARGEM;" + alltrim(str(_wmargem,18,2)) +";" + alltrim(str(_wmargem/_wfaturamento*100,18,2))
				FWrite(nHandle,_sCSV )
				
				_sCSV := ";;;;" + chr (13) + chr (10)
				FWrite(nHandle,_sCSV )
	
			endif	
			_sCSV := ";;;;" + chr (13) + chr (10)
			FWrite(nHandle,_sCSV )
			
			_sCSV:=(_TRB) -> CODIGO + '; - ;' + (_TRB) -> DESCRICAO  + chr (13) + chr (10)
			FWrite(nHandle,_sCSV )
			
			_sCSV := ";;;;" + chr (13) + chr (10)
			FWrite(nHandle,_sCSV )
		endif
	
		do case
		case (_TRB) -> TIPO = '1' .or. (_TRB) -> TIPO = '2'
			if (_TRB) -> TIPO = '1'
				_sCSV :=  ALLTRIM((_TRB) -> DESCTIPO) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO,18,2)) + chr (13) + chr (10)
				FWrite(nHandle,_sCSV )
			else
				_sCSV :=  ALLTRIM((_TRB) -> DESCTIPO) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO*-1,18,2)) + ";" + alltrim(str((_TRB) -> TOTAL_FATURADO*-1/_wfatbruto *100,18,2)) + chr (13) + chr (10)
				FWrite(nHandle,_sCSV )
			endif
	
		case (_TRB) -> TIPO = '3' .or. (_TRB) -> TIPO = '4'
			If (_TRB) -> TIPO = '3'
				_sCSV := ALLTRIM((_TRB) -> DESCTIPO) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO,18,2)) + chr (13) + chr (10)
				FWrite(nHandle,_sCSV )
			EndIf
			/// imprime o percentual de bonificacoes
			if (_TRB) -> TIPO = '4'		
				_sCSV := ALLTRIM((_TRB) -> DESCTIPO) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO,18,2)) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO/_wfatbruto *100,18,2)) + chr (13) + chr (10)
				FWrite(nHandle,_sCSV )
			endif	
	
			if (_TRB) -> TIPO = '3'
				_wfaturamento := (_TRB) -> TOTAL_FATURADO
				_wmargem      := _wfaturamento
			endif
			_sCSV := "(-) Custo Produtos;" + alltrim(str((_TRB) -> CUSTO_TOTAL,18,2)) + ";" + alltrim(str((_TRB) -> CUSTO_TOTAL/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV )
			_wmargem = _wmargem - (_TRB) -> CUSTO_TOTAL
	
			_sCSV := "(-) Impostos Destacados NF;" + alltrim(str((_TRB) ->IMP_TOTAL_NF,18,2)) +";" + alltrim(str((_TRB) ->IMP_TOTAL_NF/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV )
			_wmargem = _wmargem - (_TRB) -> IMP_TOTAL_NF 
			
			_sCSV := "(-) Impostos Sobre Faturamento;" + alltrim(str((_TRB) ->IMP_DEB,18,2)) +";"+ alltrim(str((_TRB) ->IMP_DEB/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV ) 
			_wmargem = _wmargem - (_TRB) ->IMP_DEB
			
			_wcomissao = (_TRB) ->COMISSAO
			if (_TRB) -> TIPO = '4'
				_wcomissao = 0
			endif	
			
			_sCSV := "(-) Comissão;" + alltrim(str(_wcomissao,18,2)) +";"+ alltrim(str(_wcomissao/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV ) 
			_wmargem = _wmargem - _wcomissao
			
			_sCSV := "(-) Frete;"+ alltrim(str((_TRB) ->FRETE,18,2)) +";" + alltrim(str((_TRB) ->FRETE/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV ) 
			_wmargem = _wmargem - (_TRB) ->FRETE
			
			_wrapel = (_TRB) ->RAPEL_DESC_TOTAL
			if (_TRB) -> TIPO = '4'
				_wrapel = 0
			endif	
			
			_sCSV := "(-) Rapel;" + alltrim(str(_wrapel,18,2)) +";" + alltrim(str(_wrapel/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV ) 
			_wmargem = _wmargem - _wrapel	
			
		case (_TRB) -> TIPO = '5' .or. (_TRB) -> TIPO = '6'
			
			_sCSV :=  ALLTRIM((_TRB) -> DESCTIPO) +";"+ alltrim(str((_TRB) -> TOTAL_FATURADO,18,2)) +";" + alltrim(str((_TRB) -> TOTAL_FATURADO/_wfaturamento *100,18,2)) + chr (13) + chr (10)
			FWrite(nHandle,_sCSV ) 
			if (_TRB) -> TIPO = '6'
				_wmargem = _wmargem - (_TRB) -> TOTAL_FATURADO
			endif
		endcase 
								
		(_TRB) -> (dbskip())
	enddo
	
	if _wfaturamento <= 0
		_wfaturamento := _wfatbruto
	endif
	
	_sCSV := "**** MARGEM;" + alltrim(str(_wmargem,18,2)) +";" + alltrim(str(_wmargem/_wfaturamento*100,18,2))
	FWrite(nHandle,_sCSV )
	
	_sCSV := ";;;;" + chr (13) + chr (10)
	FWrite(nHandle,_sCSV )
	
	FClose(nHandle)
	
	//u_help("Arquivo gerado em: C:\temp\")
	
		// Define o programa a ser chamado e o tipo do arquivo.
	If ApOleClient ('MsExcel')
		_sProg = "MsExcel"
	endif
	If mv_par20 == 1 // realizado
		_sArq := "C:\temp\RentRealizado.csv"
	Else // previsto
		_sArq := "C:\temp\RentPrevisto.csv"
	EndIf
	
	If _sProg == 'MsExcel'
		oExcelApp := MsExcel():New()
		oExcelApp:WorkBooks:Open (_sArq) // Abre uma planilha
		oExcelApp:SetVisible(.T.)
	else
		winexec ("cmd /c start " + _sArq)
	endif
 
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Periodo de                   ?", "D", 8,  0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {02, "Periodo ate                  ?", "D", 8,  0,  "",   "   ", {},                        ""})
	aadd (_aRegsPerg, {03, "UF de                        ?", "C", 2,  0,  "",   "12 ", {},                        "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate                       ?", "C", 2,  0,  "",   "12 ", {},                        "UF final do cliente"})
	aadd (_aRegsPerg, {05, "Representante de             ?", "C", 3,  0,  "",   "SA3", {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {06, "Representante de             ?", "C", 3,  0,  "",   "SA3", {},                        "Representante Final"})
	aadd (_aRegsPerg, {07, "Cliente de                   ?", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {08, "Cliente ate                  ?", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {09, "Loja de                      ?", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {10, "Loja ate                     ?", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {11, "Linha de produto de          ?", "C", 2,  0,  "",   "88" , {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {12, "Linha de produto até         ?", "C", 2,  0,  "",   "88" , {},                        "Representante Final"})
	aadd (_aRegsPerg, {13, "Produto de                   ?", "C", 4,  0,  "",   "SB1", {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {14, "Produto ate                  ?", "C", 4,  0,  "",   "SB1", {},                        "Representante Final"})
	aadd (_aRegsPerg, {15, "Filial de                    ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {16, "Filial até                   ?", "C", 2,  0,  "",   "SM0", {},                        ""})
    aadd (_aRegsPerg, {17, "Opção para cliente           ?", "N", 1,  0,  "",   "   ", {"Cliente","Rede"},        ""})
    aadd (_aRegsPerg, {18, "Tipo DRE                     ?", "N", 1,  0,  "",   "   ", {"Estado","Supervisor","Cliente","Vendedor","Produto"},""})
    aadd (_aRegsPerg, {19, "Gerar Excel                  ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},             ""})
	aadd (_aRegsPerg, {20, "Base Informações             ?", "N", 1,  0,  "",   "   ", {"Realizado","Previsto"},       ""})
    aadd (_aRegsPerg, {21, "Supervisor de                ?", "C", 6,  0,  "",   "ZAE", {},                        "Supervisor Inicial"})
	aadd (_aRegsPerg, {22, "Supervisor até               ?", "C", 6,  0,  "",   "ZAE", {},                        "Supervidor Final"})
	
   	U_ValPerg (cPerg, _aRegsPerg)   	  
   	
Return
