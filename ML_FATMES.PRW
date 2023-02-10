// Programa..: ML_FATMES.PRX
// Autor.....: Catia Cardoso
// Data......: 13/02/2015
// Nota......: Analise de Saidas
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Analise de Saidas
// #PalavasChave      #analise_de_saidas
// #TabelasPrincipais #SD2 #SF2 #SD1 #SF1 
// #Modulos           #FAT 
//
// Historico de alteracoes:
// 04/03/2015 - Catia   - incluida parametros de filial de ate
// 31/03/2015 - Catia   - incluido parametro de listar parametros no relatorio
// 27/05/2015 - Catia   - aumentado mascara de valores estava imprimindo *** quando pedia um periodo grande
// 18/06/2015 - Catia   - fazer o calculo do total dos produtos usando o PRCVEND e nao o PRUNIT
// 05/08/2016 - Catia   - opcao de imprimir apenas os cupons
// 19/01/2017 - Catia   - incluido campo D1_DESPESA para montar o total da nota
// 08/08/2017 - Catia   - incluido campo D1_VALDESC para montar o total da nota - notas de devolucao 
//                        estava com diferença quando lancava algum valor no desconto
// 14/09/2017 - Catia   - estava listando devolucoes de compras - e, decidimos que isso vai ser 
//                        considerado no analise de entradas 
// 28/10/2017 - Robert  - Passa a validar parametro VA_SERIECF para leitura de cupons.
// 22/05/2019 - Catia   - Considerar D1_VALFRE no total das notas de devolucao
// 03/05/2021 - Claudia - Retirado os TES '732','573', '891'. GLPI: 9926
// 03/02/2023 - Claudia - Inclusao de coluna de faturamento. GLPI: 12857
// 08/02/2023 - Claudia - Tratamento para icms st de guias MG. GLPI: 13161
//
// ----------------------------------------------------------------------------------------------
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_FATMES()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SD2"
    cDesc1  := "Analise de Saidas"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_FATMES"
    titulo  := "Analise de Saidas"
    wnrel   := "ML_FATMES"
    nTipo   := 0

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
//
// ----------------------------------------------------------------------------------------------
Static Function RptDetail()

    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "IND  DT.EMISSAO  NOTA           CLIENTE   RAZAO SOCIAL                                         UF             TOTAL PRODUTOS     (+) VALOR IPI  (+) VALOR ST (-)VLR DESCONTOS (=)TOTAL DA NOTA  (=)TOTAL FATURAMENTO"
    cabec2 := ""
    
    _sQuery := " "
    _sQuery += "SELECT SD2.D2_EMISSAO      AS DT_EMISSAO"
    _sQuery += " 	 , SF4.F4_MARGEM       AS MARGEM"
    if mv_par11 = 1 // opcao analitica
    	_sQuery += " 	 , SD2.D2_DOC          AS NOTA"
  		_sQuery += " 	 , SD2.D2_SERIE        AS SERIE"
  		_sQuery += " 	 , SD2.D2_TIPO         AS TIPO"
  		_sQuery += " 	 , SD2.D2_CLIENTE      AS CLIENTE"
  		_sQuery += " 	 , SD2.D2_LOJA         AS LOJA"
  		_sQuery += " 	 , SD2.D2_EST          AS UF"
	endif  		
  	_sQuery += "     , ROUND(SUM(D2_PRCVEN*D2_QUANT),2) AS VLR_PROD"
  	_sQuery += "	 , SUM(SD2.D2_VALIPI)  AS VLR_IPI"
  	//_sQuery += " 	 , SUM(SD2.D2_ICMSRET) AS VLR_ST"
	_sQuery += "     ,CASE "
	_sQuery += "    		WHEN SF4.F4_CREDST = '4' THEN 0 "
	_sQuery +="    			ELSE SUM(SD2.D2_ICMSRET) "
	_sQuery += "      END AS VLR_ST "
	_sQuery += " 	 , 0 AS VLR_DESCONTO"
	_sQuery += " 	 , SUM(SD2.D2_VALBRUT) AS VLR_BRT"
  	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
  	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
  	_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
  	_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
  	_sQuery += "				AND SF2.F2_LOJA    = SD2.D2_LOJA"
  	_sQuery += "                AND SF2.F2_VEND1   BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    _sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "	INNER JOIN SF4010 AS SF4"
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
  	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)"
  	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
  	_sQuery += "   AND SD2.D2_FILIAL    BETWEEN '" + mv_par12 + "' AND '" + mv_par13 + "'"
    _sQuery += "   AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "   AND SD2.D2_TIPO != 'D'" // AS DEVOLUÇÕES DE COMPRA SERAO CONSIDERADAS NO ANALISE DE ENTRADAS
    if mv_par14 = 2 // apenas CUPONS
    	_sQuery += "   AND SD2.D2_SERIE IN " + FormatIn (GetMv ('VA_SERIECF'), '/')
    endif
	_sQuery += "   AND SD2.D2_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "   AND SD2.D2_CLIENTE   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "   AND SD2.D2_LOJA      BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sQuery += "   AND SD2.D2_TES NOT IN ('732','573', '891')"
    if mv_par11 = 1 // opcao analitica 
    	_sQuery += " GROUP BY SD2.D2_EMISSAO, SF4.F4_MARGEM, SD2.D2_DOC ,SD2.D2_SERIE, SD2.D2_TIPO, SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST, SF4.F4_CREDST"
 	else
 		_sQuery += " GROUP BY SD2.D2_EMISSAO, SF4.F4_MARGEM"
 	endif
    _sQuery += " UNION ALL "
 	_sQuery += " SELECT SD1.D1_DTDIGIT      AS DT_EMISSAO"
 	_sQuery += "      , SF4.F4_MARGEM       AS MARGEM" 	 
 	if mv_par11 = 1 // opcao analitica
 		_sQuery += "      , SD1.D1_DOC          AS NOTA" 	 
    	_sQuery += "      , SD1.D1_SERIE        AS SERIE"
    	_sQuery += "      , SD1.D1_TIPO         AS TIPO" 	 
    	_sQuery += "      , SD1.D1_FORNECE      AS CLIENTE"
    	_sQuery += "      , SD1.D1_LOJA         AS LOJA" 	 
    	_sQuery += "      , SF1.F1_EST          AS UF"
	endif    		 
    _sQuery += "      , SUM(SD1.D1_TOTAL)    AS VLR_PROD" 
    _sQuery += "      , SUM(SD1.D1_VALIPI)   AS VLR_IPI" 	 
    //_sQuery += "      , SUM(SD1.D1_ICMSRET)  AS VLR_ST" 	
	_sQuery += "      , CASE "
	_sQuery += "    		WHEN SF4.F4_CREDST = '4' THEN 0 "
	_sQuery +="    			ELSE SUM(SD1.D1_ICMSRET) "
	_sQuery += "        END AS VLR_ST " 
    _sQuery += "      , SUM(SD1.D1_VALDESC)  AS VLR_DESCONTO" 
    // foi feito assim pra preservar integridade com os relatorios retroativos
    // das 2 uma: ou nao conciliavam direito e nunca viram a situacao dos valores digitados nas despesas
    //            ou foi a primeira vez que aconteceu, por isso o case na data     	 
    _sQuery += "      , CASE WHEN SD1.D1_DTDIGIT >= '20161201' THEN ROUND(SUM(SD1.D1_TOTAL+SD1.D1_VALIPI+SD1.D1_ICMSRET+SD1.D1_DESPESA+SD1.D1_VALFRE  - SD1.D1_VALDESC ),2)" 
    _sQuery += "        ELSE ROUND(SUM(SD1.D1_TOTAL+SD1.D1_VALIPI+SD1.D1_ICMSRET),2) END AS VLR_BRT"
    _sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_sQuery += "	 INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_sQuery += "   	    ON (SF1.D_E_L_E_T_ = ''"				
	_sQuery += "		    AND SF1.F1_FILIAL  = SD1.D1_FILIAL"				
	_sQuery += "		    AND SF1.F1_DOC     = SD1.D1_DOC"				
	_sQuery += "		    AND SF1.F1_SERIE   = SD1.D1_SERIE"				
	_sQuery += "		    AND SF1.F1_FORNECE = SD1.D1_FORNECE"				
	_sQuery += "   		    AND SF1.F1_LOJA    = SD1.D1_LOJA"	
	_sQuery += "            AND SF1.F1_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += " 		    AND SF1.F1_EMISSAO = SD1.D1_EMISSAO)"	
	_sQuery += "     INNER JOIN SF4010 AS SF4"			
	_sQuery += "		ON (SF4.D_E_L_E_T_ = ''"				
	_sQuery += "			AND SF4.F4_CODIGO  = SD1.D1_TES"
	_sQuery += "			AND SF4.F4_MARGEM  = '2')"
	_sQuery += "     INNER JOIN SA1010 AS SA1"			
	_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"				
	_sQuery += "			AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "            AND SA1.A1_VEND   BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    _sQuery += "			AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += "   AND SD1.D1_FILIAL    BETWEEN '" + mv_par12 + "' AND '" + mv_par13 + "'"
	_sQuery += "   AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "   AND SD1.D1_TIPO = 'D'"
	if mv_par14 = 2 // apenas CUPONS
    	_sQuery += "   AND SD1.D1_SERIORI IN " + FormatIn (GetMv ('VA_SERIECF'), '/')
    endif
	_sQuery += "   AND SD1.D1_FORNECE   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "   AND SD1.D1_LOJA      BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    if mv_par11 = 1 // opcao analitica
    	_sQuery += " GROUP BY SD1.D1_DTDIGIT, SF4.F4_MARGEM, SD1.D1_DOC ,SD1.D1_SERIE, SD1.D1_TIPO, SD1.D1_FORNECE , SD1.D1_LOJA, SF1.F1_EST, SF4.F4_CREDST"
  	else
 		_sQuery += " GROUP BY SD1.D1_DTDIGIT, SF4.F4_MARGEM"
 	endif
    if mv_par11 = 1 // opcao analitica
    	_sQuery += " ORDER BY DT_EMISSAO, NOTA, SERIE"
	else
	    _sQuery += " ORDER BY DT_EMISSAO, MARGEM"	
  	endif

    //u_showmemo(_sQuery)
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotData   = {0,0,0,0,0,0}
    _aTotVenda  = {0,0,0,0,0,0}
    _aTotDev    = {0,0,0,0,0,0}
    _aTotBonif  = {0,0,0,0,0,0}
	_aTotOutras = {0,0,0,0,0,0}
	_aTotErro   = {0,0,0,0,0,0}
	
	_wdata = ''
    
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	If li>58
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    
	    If mv_par11 = 1
			If (_sAliasQ) -> DT_EMISSAO >= '20230101' // GLPI: 12857
				_nVlrNf := (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST 
			else
				_nVlrNf := (_sAliasQ) -> VLR_BRT 
			EndIf

			If (_sAliasQ) -> MARGEM $ '1239'
				@ li, 002 PSAY (_sAliasQ) -> MARGEM
			Else           	   
				@ li, 002 PSAY 'X'
			EndIf
			@ li, 005 PSAY stod((_sAliasQ) -> DT_EMISSAO)
			@ li, 017 PSAY (_sAliasQ) -> NOTA
			@ li, 033 PSAY (_sAliasQ) -> CLIENTE
			// busca nome do cliente
			If (_sAliasQ) -> MARGEM = '2' .OR. (_sAliasQ) -> TIPO = 'N'
				@ li, 042 PSAY fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CLIENTE + (_sAliasQ) -> LOJA, "A1_NOME")
			Else
				@ li, 042 PSAY fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> CLIENTE + (_sAliasQ) -> LOJA, "A2_NOME")
			EndIf
			@ li, 095 PSAY (_sAliasQ) -> UF
			@ li, 108 PSAY (_sAliasQ) -> VLR_PROD     Picture "@E 9,999,999,999.99"
			@ li, 129 PSAY (_sAliasQ) -> VLR_IPI      Picture "@E 99,999,999.99"
			@ li, 143 PSAY (_sAliasQ) -> VLR_ST       Picture "@E 99,999,999.99"
			@ li, 160 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 99,999,999.99"
			@ li, 173 PSAY (_sAliasQ) -> VLR_BRT      Picture "@E 99,999,999,999.99"
			@ li, 190 PSAY _nVlrNf                    Picture "@E 99,999,999,999.99"
			li ++
     	Else
	 		// opcao sintetica
			If (_sAliasQ) -> DT_EMISSAO >= '20230101' // GLPI: 12857
				_nVlrNf := (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST 
			else
				_nVlrNf := (_sAliasQ) -> VLR_BRT
			EndIf

	 		// acumula totais na data e imprime o total da data
			@ li, 005 PSAY stod((_sAliasQ) -> DT_EMISSAO)
			Do Case
				Case (_sAliasQ) -> MARGEM = '1' 
					w_tipo= 'Venda'
				Case (_sAliasQ) -> MARGEM = '2' 
					w_tipo= 'Devolução'
				Case (_sAliasQ) -> MARGEM = '3' 
					w_tipo= 'Bonificação'
				Case (_sAliasQ) -> MARGEM = '9' 
					w_tipo= 'Outras saidas'
				Otherwise 
					w_tipo= 'Erro'
			EndCase
			@ li, 017 PSAY w_tipo
			@ li, 108 PSAY (_sAliasQ) -> VLR_PROD     Picture "@E 9,999,999,999.99"
			@ li, 129 PSAY (_sAliasQ) -> VLR_IPI      Picture "@E 99,999,999.99"
			@ li, 143 PSAY (_sAliasQ) -> VLR_ST       Picture "@E 99,999,999.99"
			@ li, 160 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 99,999,999.99"
			@ li, 173 PSAY (_sAliasQ) -> VLR_BRT      Picture "@E 99,999,999,999.99"
			@ li, 190 PSAY _nVlrNf                    Picture "@E 99,999,999,999.99"
			
			li ++
		EndIf
		// total por indicador de faturamento
		Do Case
			Case (_sAliasQ) -> MARGEM = '1'
				_aTotVenda [1] += (_sAliasQ) -> VLR_PROD
				_aTotVenda [2] += (_sAliasQ) -> VLR_IPI
				_aTotVenda [3] += (_sAliasQ) -> VLR_ST
				_aTotVenda [4] += (_sAliasQ) -> VLR_DESCONTO
				_aTotVenda [5] += (_sAliasQ) -> VLR_BRT
				_aTotVenda [6] += (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST
			Case (_sAliasQ) -> MARGEM = '2'
				_aTotDev [1] += (_sAliasQ) -> VLR_PROD
				_aTotDev [2] += (_sAliasQ) -> VLR_IPI
				_aTotDev [3] += (_sAliasQ) -> VLR_ST
				_aTotDev [4] += (_sAliasQ) -> VLR_DESCONTO
				_aTotDev [5] += (_sAliasQ) -> VLR_BRT  
				_aTotDev [6] += (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST        			
			Case (_sAliasQ) -> MARGEM = '3'
				_aTotBonif [1] += (_sAliasQ) -> VLR_PROD
				_aTotBonif [2] += (_sAliasQ) -> VLR_IPI
				_aTotBonif [3] += (_sAliasQ) -> VLR_ST
				_aTotBonif [4] += (_sAliasQ) -> VLR_DESCONTO
				_aTotBonif [5] += (_sAliasQ) -> VLR_BRT
				_aTotBonif [6] += (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST  
			Case (_sAliasQ) -> MARGEM = '9'
				_aTotOutras[1] += (_sAliasQ) -> VLR_PROD
				_aTotOutras[2] += (_sAliasQ) -> VLR_IPI
				_aTotOutras[3] += (_sAliasQ) -> VLR_ST
				_aTotOutras[4] += (_sAliasQ) -> VLR_DESCONTO
				_aTotOutras[5] += (_sAliasQ) -> VLR_BRT  
				_aTotOutras[6] += (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST  
			Otherwise 
				_aTotErro[1] += (_sAliasQ) -> VLR_PROD
				_aTotErro[2] += (_sAliasQ) -> VLR_IPI
				_aTotErro[3] += (_sAliasQ) -> VLR_ST
				_aTotErro[4] += (_sAliasQ) -> VLR_DESCONTO
				_aTotErro[5] += (_sAliasQ) -> VLR_BRT  
				_aTotErro[6] += (_sAliasQ) -> VLR_BRT - (_sAliasQ) -> VLR_IPI - (_sAliasQ) -> VLR_ST  
		EndCase
		(_sAliasQ) -> (dbskip())
	EndDo
	 
		li ++      
		If li>58
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		Endif  
		// imprime totais por operacao
		@ li, 005 PSAY "TOTAIS POR OPERACAO: "
		li ++
		li ++
		// imprime total da venda
		@ li, 005 PSAY "1 - VENDA:"
		@ li, 108 PSAY _aTotVenda[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotVenda[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotVenda[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotVenda[4] Picture "@E 99,999,999.99"
		@ li, 173 PSAY _aTotVenda[5] Picture "@E 99,999,999,999.99"
		@ li, 190 PSAY _aTotVenda[6] Picture "@E 99,999,999,999.99"
		li ++
		// imprime total da devolucoes
		@ li, 005 PSAY "2 - DEVOLUÇÕES:"
		@ li, 108 PSAY _aTotDev[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotDev[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotDev[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotDev[4] Picture "@E 99,999,999.99"
		@ li, 173 PSAY _aTotDev[5] Picture "@E 99,999,999,999.99"
		@ li, 190 PSAY _aTotDev[6] Picture "@E 99,999,999,999.99"
		li ++
		// imprime total de bonificacoes
		@ li, 005 PSAY "3 - BONIFICAÇÕES:"
		@ li, 108 PSAY _aTotBonif[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotBonif[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotBonif[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotBonif[4] Picture "@E 99,999,999.99"
		@ li, 173 PSAY _aTotBonif[5] Picture "@E 99,999,999,999.99"
		@ li, 190 PSAY _aTotBonif[6] Picture "@E 99,999,999,999.99"
		li ++
		// imprime total de bonificacoes
		@ li, 005 PSAY "9 - OUTRAS SAIDAS:"
		@ li, 108 PSAY _aTotOutras[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotOutras[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotOutras[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotOutras[4] Picture "@E 99,999,999.99"
		@ li, 173 PSAY _aTotOutras[5] Picture "@E 99,999,999,999.99"
		@ li, 190 PSAY _aTotOutras[6] Picture "@E 99,999,999,999.99"
		li ++
		// imprime total de ERROS
		If _aTotErro[1] > 0 
			@ li, 005 PSAY "X - ERRO - VERIFIQUE CADASTRO TES:"
			@ li, 108 PSAY _aTotErro[1] Picture "@E 9,999,999,999.99"
			@ li, 129 PSAY _aTotErro[2] Picture "@E 99,999,999.99"
			@ li, 143 PSAY _aTotErro[3] Picture "@E 99,999,999.99"
			@ li, 160 PSAY _aTotErro[4] Picture "@E 99,999,999.99"
			@ li, 173 PSAY _aTotErro[5] Picture "@E 99,999,999,999.99"
			@ li, 190 PSAY _aTotErro[6] Picture "@E 99,999,999,999.99"
			li ++
		EndIf
		li ++
		li ++
		@ li, 005 PSAY "*** VENDA LIQUIDA = VENDA(-)DEVOLUÇÕES :
		@ li, 108 PSAY _aTotVenda[1] - _aTotDev[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotVenda[2] - _aTotDev[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotVenda[3] - _aTotDev[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotVenda[4] - _aTotDev[4] Picture "@E 99,999,999.99"
		@ li, 173 PSAY _aTotVenda[5] - _aTotDev[5] Picture "@E 99,999,999,999.99"
		@ li, 190 PSAY _aTotVenda[6] - _aTotDev[6] Picture "@E 99,999,999,999.99"
		li ++
	 
	U_ImpParam (58)
	      
    Set Device To Screen

	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Emissao de         ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao ate        ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "UF de                         ", "C", 2,  0,  "",   "12 ", {},                        "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate                        ", "C", 2,  0,  "",   "12 ", {},                        "UF final do cliente"})
	aadd (_aRegsPerg, {05, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {06, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {07, "Loja de                       ", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {08, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {09, "Representante de              ", "C", 3,  0,  "",   "SA3", {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {10, "Representante de              ", "C", 3,  0,  "",   "SA3", {},                        "Representante Final"})
	aadd (_aRegsPerg, {11, "Opção Desejada                ", "N", 1,  0,  "",   "   ", {"Analitico","Sintetico"},   ""})
	aadd (_aRegsPerg, {12, "Filial de                    ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {13, "Filial até                   ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {14, "Apenas CUPONS                ?", "N", 1,  0,  "",   "   ", {"Nao", "Sim"}, ""})
    
   	U_ValPerg (cPerg, _aRegsPerg)
Return
