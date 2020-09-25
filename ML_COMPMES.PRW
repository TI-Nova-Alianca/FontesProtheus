// Programa..: ML_COMPMES.PRX
// Autor.....: Catia Cardoso
// Data......: 16/08/2017
// Nota......: Analise de Entradas

// Historico de alteracoes:
// 
// 21/08/2017 - alterado o cabeçalho do relatorio onde fazia referencia a data de emissao p/data entrada
// 22/08/2017 - alterado para que nas entradas, considere despesa+desconto+frete como outras despesas
// 23/08/2017 - abrir no relatorio as margem 4/5 - comodato e retorno de comodato
// 23/08/2017 - colocado total de operacao para ficar mais facil de validar o relatorio com o fiscal e os relatorios de curva ABC 
//

#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_COMPMES()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SD1"
    cDesc1  := "Analise de Entradas"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_COMPMES"
    titulo  := "Analise de Entradas"
    wnrel   := "ML_COMPMES"
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

Static Function RptDetail()

    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "IND  DT.ENTRADA  NOTA           FORNEC.   RAZAO SOCIAL                                         UF             TOTAL PRODUTOS     (+) VALOR IPI  (+) VALOR ST (-)VLR DESCONTOS (+)VLR DESPESAS (=)TOTAL DA NOTA"
    cabec2 := ""
    
    _sQuery := " "
    _sQuery += "SELECT SD2.D2_EMISSAO      AS DT_EMISSAO"
    _sQuery += " 	 , SF4.F4_MARGEM       AS MARGEM"
    if mv_par11 = 1 // opcao analitica
    	_sQuery += " 	 , SD2.D2_DOC          AS NOTA"
  		_sQuery += " 	 , SD2.D2_SERIE        AS SERIE"
  		_sQuery += " 	 , SD2.D2_TIPO         AS TIPO"
  		_sQuery += " 	 , SD2.D2_CLIENTE      AS FORNECE"
  		_sQuery += " 	 , SD2.D2_LOJA         AS LOJA"
  		_sQuery += " 	 , SD2.D2_EST          AS UF"
	endif  		
  	_sQuery += "     , ROUND(SUM(D2_PRCVEN*D2_QUANT),2) AS VLR_PROD"
  	_sQuery += "	 , SUM(SD2.D2_VALIPI)  AS VLR_IPI"
  	_sQuery += " 	 , SUM(SD2.D2_ICMSRET) AS VLR_ST"
	_sQuery += " 	 , 0 AS VLR_DESCONTO"
	_sQuery += " 	 , 0 AS VLR_DESPESA"
	_sQuery += " 	 , SUM(SD2.D2_VALBRUT) AS VLR_BRT"
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
  	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
  	_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
  	_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
  	_sQuery += "				AND SF2.F2_LOJA    = SD2.D2_LOJA"
  	_sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "	INNER JOIN SF4010 AS SF4"
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
  	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES)"
  	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
  	_sQuery += "   AND SD2.D2_TIPO = 'D'" // so as notas de devolucao de compras
  	_sQuery += "   AND SD2.D2_FILIAL    BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    _sQuery += "   AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "   AND SD2.D2_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "   AND SD2.D2_CLIENTE   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "   AND SD2.D2_LOJA      BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    if mv_par11 = 1 // opcao analitica 
    	_sQuery += " GROUP BY SD2.D2_EMISSAO, SF4.F4_MARGEM, SD2.D2_DOC ,SD2.D2_SERIE, SD2.D2_TIPO, SD2.D2_CLIENTE , SD2.D2_LOJA, SD2.D2_EST"
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
    	_sQuery += "      , SD1.D1_FORNECE      AS FORNECE"
    	_sQuery += "      , SD1.D1_LOJA         AS LOJA" 	 
    	_sQuery += "      , SF1.F1_EST          AS UF"
	endif    		 
    _sQuery += "      , SUM(SD1.D1_TOTAL)    AS VLR_PROD" 
    _sQuery += "      , SUM(SD1.D1_VALIPI)   AS VLR_IPI" 	 
    _sQuery += "      , SUM(SD1.D1_ICMSRET)  AS VLR_ST" 	 
    _sQuery += "      , SUM(SD1.D1_VALDESC)  AS VLR_DESCONTO"
    _sQuery += "      , SUM(ROUND(SD1.D1_DESPESA + SD1.D1_SEGURO + SD1.D1_VALFRE,2)) AS VLR_DESPESA"
	_sQuery += "      , SUM(ROUND(SD1.D1_DESPESA + SD1.D1_SEGURO + SD1.D1_VALFRE + SD1.D1_TOTAL + SD1.D1_VALIPI + SD1.D1_ICMSRET - SD1.D1_VALDESC,2)) AS VLR_BRT"
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
	_sQuery += "			AND SF4.F4_CODIGO  = SD1.D1_TES)"
	_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
	_sQuery += "   AND SD1.D1_FILIAL    BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
	_sQuery += "   AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "   AND SD1.D1_TIPO NOT IN ('D')" // desconsidera as devolucoes pq sao de saidas nesse caso
	//_sQuery += "   AND SD1.D1_TIPO IN ('N','C')" // nota normais de entrada, fretes sobre vendas e C para fretes sobre compras
	_sQuery += "   AND SD1.D1_FORNECE   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "   AND SD1.D1_LOJA      BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    if mv_par11 = 1 // opcao analitica
    	_sQuery += " GROUP BY SD1.D1_DTDIGIT, SF4.F4_MARGEM, SD1.D1_DOC ,SD1.D1_SERIE, SD1.D1_TIPO, SD1.D1_FORNECE , SD1.D1_LOJA, SF1.F1_EST"
    	_sQuery += " ORDER BY DT_EMISSAO, NOTA, SERIE"
  	else
 		_sQuery += " GROUP BY SD1.D1_DTDIGIT, SF4.F4_MARGEM"
	    _sQuery += " ORDER BY DT_EMISSAO, MARGEM"	
  	endif
    
    //u_showmemo(_sQuery)
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotData   = {0,0,0,0,0,0}
    _aTotCompra = {0,0,0,0,0,0}
    _aTotFretes = {0,0,0,0,0,0}
    _aTotServ   = {0,0,0,0,0,0}
	_aTotUcons  = {0,0,0,0,0,0}
    _aTotDev    = {0,0,0,0,0,0}
    _aTotBonif  = {0,0,0,0,0,0}
    _aTotComod  = {0,0,0,0,0,0}
	_aTotRetCom = {0,0,0,0,0,0}
	_aTotOutras = {0,0,0,0,0,0}
	_aTotErro   = {0,0,0,0,0,0}
	
	_wdata = ''
    
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	If li>58
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    
	    IF mv_par11 = 1
	           @ li, 002 PSAY (_sAliasQ) -> MARGEM
			   @ li, 005 PSAY stod((_sAliasQ) -> DT_EMISSAO)
		       @ li, 017 PSAY (_sAliasQ) -> NOTA
		       @ li, 033 PSAY (_sAliasQ) -> FORNECE
		       // busca nome do cliente
		       IF (_sAliasQ) -> TIPO = 'N'
		       		@ li, 042 PSAY fBuscaCpo ("SA2", 1, xfilial ("SA2") + (_sAliasQ) -> FORNECE + (_sAliasQ) -> LOJA, "A2_NOME")
		       ELSE
			       	@ li, 042 PSAY fBuscaCpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> FORNECE + (_sAliasQ) -> LOJA, "A1_NOME")
		       ENDIF
			   @ li, 095 PSAY (_sAliasQ) -> UF
		   	   @ li, 108 PSAY (_sAliasQ) -> VLR_PROD     Picture "@E 9,999,999,999.99"
		       @ li, 129 PSAY (_sAliasQ) -> VLR_IPI      Picture "@E 99,999,999.99"
		       @ li, 143 PSAY (_sAliasQ) -> VLR_ST       Picture "@E 99,999,999.99"
		       @ li, 160 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 99,999,999.99"
		       @ li, 176 PSAY (_sAliasQ) -> VLR_DESPESA  Picture "@E 99,999,999.99"
		       @ li, 190 PSAY (_sAliasQ) -> VLR_BRT      Picture "@E 99,999,999,999.99"
	           li ++
     	ELSE
	 		// opcao sintetica
	 		// acumula totais na data e imprime o total da data
	 			@ li, 005 PSAY stod((_sAliasQ) -> DT_EMISSAO)
	 			DO CASE
	 				CASE (_sAliasQ) -> MARGEM = '1' 
	 					w_tipo= 'Compra'
	 				CASE (_sAliasQ) -> MARGEM = '2' 
	 					w_tipo= 'Devolução'
	 				CASE (_sAliasQ) -> MARGEM = '3' 
	 					w_tipo= 'Bonificação'
	 				CASE (_sAliasQ) -> MARGEM = '4'
	 					w_tipo= 'Comodato'
	 				CASE (_sAliasQ) -> MARGEM = '5'
	 					w_tipo= 'Ret.Comodato'	
	 				CASE (_sAliasQ) -> MARGEM = '6'
	 					w_tipo= 'Frete'
	 				CASE (_sAliasQ) -> MARGEM = '7'
	 					w_tipo= 'Serviços'
	 				CASE (_sAliasQ) -> MARGEM = '8'
	 					w_tipo= 'Uso e Consumo'	
	 				CASE (_sAliasQ) -> MARGEM = '9' 
	 					w_tipo= 'Outras Entradas'
	 				OTHERWISE 
	 					w_tipo= 'Erro'
	 			ENDCASE
	 			@ li, 017 PSAY w_tipo
		       	@ li, 108 PSAY (_sAliasQ) -> VLR_PROD     Picture "@E 9,999,999,999.99"
		       	@ li, 129 PSAY (_sAliasQ) -> VLR_IPI      Picture "@E 99,999,999.99"
		       	@ li, 143 PSAY (_sAliasQ) -> VLR_ST       Picture "@E 99,999,999.99"
		       	@ li, 160 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 99,999,999.99"
		       	@ li, 176 PSAY (_sAliasQ) -> VLR_DESPESAS Picture "@E 99,999,999,999.99"
		       	@ li, 190 PSAY (_sAliasQ) -> VLR_BRT      Picture "@E 99,999,999,999.99"
		        li ++
	 	ENDIF
	 	// total por indicador de faturamento
        DO CASE
       		CASE (_sAliasQ) -> MARGEM = '1'
       			_aTotCompra [1] += (_sAliasQ) -> VLR_PROD
       			_aTotCompra [2] += (_sAliasQ) -> VLR_IPI
       			_aTotCompra [3] += (_sAliasQ) -> VLR_ST
       			_aTotCompra [4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotCompra [5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotCompra [6] += (_sAliasQ) -> VLR_BRT
			CASE (_sAliasQ) -> MARGEM = '2'
       			_aTotDev [1] += (_sAliasQ) -> VLR_PROD
       			_aTotDev [2] += (_sAliasQ) -> VLR_IPI
       			_aTotDev [3] += (_sAliasQ) -> VLR_ST
       			_aTotDev [4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotDev [5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotDev [6] += (_sAliasQ) -> VLR_BRT           			
			CASE (_sAliasQ) -> MARGEM = '3'
       			_aTotBonif [1] += (_sAliasQ) -> VLR_PROD
       			_aTotBonif [2] += (_sAliasQ) -> VLR_IPI
       			_aTotBonif [3] += (_sAliasQ) -> VLR_ST
       			_aTotBonif [4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotBonif [5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotBonif [6] += (_sAliasQ) -> VLR_BRT
       		CASE (_sAliasQ) -> MARGEM = '4'
       			_aTotComod [1] += (_sAliasQ) -> VLR_PROD
       			_aTotComod [2] += (_sAliasQ) -> VLR_IPI
       			_aTotComod [3] += (_sAliasQ) -> VLR_ST
       			_aTotComod [4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotComod [5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotComod [6] += (_sAliasQ) -> VLR_BRT
       		CASE (_sAliasQ) -> MARGEM = '5'
       			_aTotRetCom [1] += (_sAliasQ) -> VLR_PROD
       			_aTotRetCom [2] += (_sAliasQ) -> VLR_IPI
       			_aTotRetCom [3] += (_sAliasQ) -> VLR_ST
       			_aTotRetCom [4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotRetCom [5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotRetCom [6] += (_sAliasQ) -> VLR_BRT
			CASE (_sAliasQ) -> MARGEM = '6'
       			_aTotFretes[1] += (_sAliasQ) -> VLR_PROD
       			_aTotFretes[2] += (_sAliasQ) -> VLR_IPI
       			_aTotFretes[3] += (_sAliasQ) -> VLR_ST
       			_aTotFretes[4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotFretes[5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotFretes[6] += (_sAliasQ) -> VLR_BRT
       		CASE (_sAliasQ) -> MARGEM = '7'
       			_aTotServ[1] += (_sAliasQ) -> VLR_PROD
       			_aTotServ[2] += (_sAliasQ) -> VLR_IPI
       			_aTotServ[3] += (_sAliasQ) -> VLR_ST
       			_aTotServ[4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotServ[5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotServ[6] += (_sAliasQ) -> VLR_BRT
       		CASE (_sAliasQ) -> MARGEM = '8'
       			_aTotUcons[1] += (_sAliasQ) -> VLR_PROD
       			_aTotUcons[2] += (_sAliasQ) -> VLR_IPI
       			_aTotUcons[3] += (_sAliasQ) -> VLR_ST
       			_aTotUcons[4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotUcons[5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotUcons[6] += (_sAliasQ) -> VLR_BRT
       		CASE (_sAliasQ) -> MARGEM = '9'
       			_aTotOutras[1] += (_sAliasQ) -> VLR_PROD
       			_aTotOutras[2] += (_sAliasQ) -> VLR_IPI
       			_aTotOutras[3] += (_sAliasQ) -> VLR_ST
       			_aTotOutras[4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotOutras[5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotOutras[6] += (_sAliasQ) -> VLR_BRT  
			OTHERWISE 
				_aTotErro[1] += (_sAliasQ) -> VLR_PROD
       			_aTotErro[2] += (_sAliasQ) -> VLR_IPI
       			_aTotErro[3] += (_sAliasQ) -> VLR_ST
       			_aTotErro[4] += (_sAliasQ) -> VLR_DESCONTO
       			_aTotErro[5] += (_sAliasQ) -> VLR_DESPESA
       			_aTotErro[6] += (_sAliasQ) -> VLR_BRT  
	    ENDCASE
	 	(_sAliasQ) -> (dbskip())
     enddo
	 
	 li ++      
     If li>58
     	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif  
      // imprime totais por operacao
     @ li, 005 PSAY "TOTAIS POR OPERACAO: "
     li ++
     li ++
	 // imprime total de COMPRA
	 @ li, 005 PSAY "1 - COMPRA:"
	 @ li, 108 PSAY _aTotCompra[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotCompra[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotCompra[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotCompra[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotCompra[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotCompra[6] Picture "@E 99,999,999,999.99"
     li ++
 	 // imprime total da devolucoes
 	 @ li, 005 PSAY "2 - DEVOLUÇÕES:"
	 @ li, 108 PSAY _aTotDev[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotDev[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotDev[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotDev[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotDev[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotDev[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de bonificacoes
 	 @ li, 005 PSAY "3 - BONIFICAÇÕES:"
	 @ li, 108 PSAY _aTotBonif[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotBonif[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotBonif[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotBonif[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotBonif[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotBonif[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de comodato
 	 @ li, 005 PSAY "4 - COMODATO:"
	 @ li, 108 PSAY _aTotComod[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotComod[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotComod[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotComod[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotComod[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotComod[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de ret comodato
 	 @ li, 005 PSAY "5 - RET.COMODATO:"
	 @ li, 108 PSAY _aTotRetCom[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotRetCom[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotRetCom[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotRetCom[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotRetCom[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotRetCom[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de fretes
 	 @ li, 005 PSAY "6 - FRETES:"
	 @ li, 108 PSAY _aTotFretes[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotFretes[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotFretes[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotFretes[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotFretes[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotFretes[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de serviço
 	 @ li, 005 PSAY "6 - SERVICOS:"
	 @ li, 108 PSAY _aTotServ[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotServ[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotServ[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotServ[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotServ[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotServ[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de uso e consumo
 	 @ li, 005 PSAY "7 - USO E CONSUMO:"
	 @ li, 108 PSAY _aTotUcons[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotUcons[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotUcons[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotUcons[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotUcons[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotUcons[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de outras
	 @ li, 005 PSAY "8 - OUTRAS ENTRADAS:"
	 @ li, 108 PSAY _aTotOutras[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotOutras[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotOutras[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotOutras[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotOutras[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotOutras[6] Picture "@E 99,999,999,999.99"
	 li ++
	 // imprime total de ERROS
	 IF _aTotErro[1] > 0 
		@ li, 005 PSAY "X - ERRO - VERIFIQUE CADASTRO TES:"
		@ li, 108 PSAY _aTotErro[1] Picture "@E 9,999,999,999.99"
		@ li, 129 PSAY _aTotErro[2] Picture "@E 99,999,999.99"
		@ li, 143 PSAY _aTotErro[3] Picture "@E 99,999,999.99"
		@ li, 160 PSAY _aTotErro[4] Picture "@E 99,999,999.99"
		@ li, 176 PSAY _aTotErro[5] Picture "@E 99,999,999.99"
		@ li, 190 PSAY _aTotErro[6] Picture "@E 99,999,999,999.99"
		li ++
	 ENDIF
	 li ++
	 li ++
	 @ li, 005 PSAY "*** COMPRA LIQUIDA = COMPRA(-)DEVOLUÇÕES :
	 @ li, 108 PSAY _aTotCompra[1] - _aTotDev[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotCompra[2] - _aTotDev[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotCompra[3] - _aTotDev[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotCompra[4] - _aTotDev[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotCompra[5] - _aTotDev[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotCompra[6] - _aTotDev[6] Picture "@E 9,999,999,999.99"
	 li ++
	 li ++
	 @ li, 005 PSAY "*** TOTAL DE OPERACAO :
	 @ li, 108 PSAY _aTotCompra[1] - _aTotDev[1] + _aTotBonif[1] + _aTotComod[1] +  _aTotRetCom[1] + _aTotFretes[1] + _aTotServ[1] + _aTotUcons[1] + _aTotOutras[1] + _aTotErro[1] Picture "@E 9,999,999,999.99"
	 @ li, 129 PSAY _aTotCompra[2] - _aTotDev[2] + _aTotBonif[2] + _aTotComod[2] +  _aTotRetCom[2] + _aTotFretes[2] + _aTotServ[2] + _aTotUcons[2] + _aTotOutras[2] + _aTotErro[2] Picture "@E 99,999,999.99"
	 @ li, 143 PSAY _aTotCompra[3] - _aTotDev[3] + _aTotBonif[3] + _aTotComod[3] +  _aTotRetCom[3] + _aTotFretes[3] + _aTotServ[3] + _aTotUcons[3] + _aTotOutras[3] + _aTotErro[3] Picture "@E 99,999,999.99"
	 @ li, 160 PSAY _aTotCompra[4] - _aTotDev[4] + _aTotBonif[4] + _aTotComod[4] +  _aTotRetCom[4] + _aTotFretes[4] + _aTotServ[4] + _aTotUcons[4] + _aTotOutras[4] + _aTotErro[4] Picture "@E 99,999,999.99"
	 @ li, 176 PSAY _aTotCompra[5] - _aTotDev[5] + _aTotBonif[5] + _aTotComod[5] +  _aTotRetCom[5] + _aTotFretes[5] + _aTotServ[5] + _aTotUcons[5] + _aTotOutras[5] + _aTotErro[5] Picture "@E 99,999,999.99"
	 @ li, 190 PSAY _aTotCompra[6] - _aTotDev[6] + _aTotBonif[6] + _aTotComod[6] +  _aTotRetCom[6] + _aTotFretes[6] + _aTotServ[6] + _aTotUcons[6] + _aTotOutras[6] + _aTotErro[6] Picture "@E 9,999,999,999.99"
	 li ++
	 li ++
	 
	 U_ImpParam (58)
	      
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
	aadd (_aRegsPerg, {01, "Emissao de         ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao ate        ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "UF de               ", "C", 2,  0,  "",   "12 ", {},    "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate              ", "C", 2,  0,  "",   "12 ", {},      "UF final do cliente"})
	aadd (_aRegsPerg, {05, "Fornecedor de       ", "C", 6,  0,  "",   "SA2", {},       "Fornecedor Inicial"})
	aadd (_aRegsPerg, {06, "Fornecedor até      ", "C", 6,  0,  "",   "SA2", {},         "Fornecedor Final"})
	aadd (_aRegsPerg, {07, "Loja de             ", "C", 2,  0,  "",   "   ", {},             "Loja Inicial"})
	aadd (_aRegsPerg, {08, "Loja ate            ", "C", 2,  0,  "",   "   ", {},               "Loja Final"})
	aadd (_aRegsPerg, {09, "Filial de          ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {10, "Filial até         ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {11, "Opção Desejada      ", "N", 1,  0,  "",   "   ", {"Analitico","Sintetico"},  ""})
	
   	U_ValPerg (cPerg, _aRegsPerg)
Return