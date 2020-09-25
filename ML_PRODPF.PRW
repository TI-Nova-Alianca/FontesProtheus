// Programa..: ML_PRODFP
// Autor.....: Catia Cardoso
// Data......: 18/03/2015
// Nota......: Produtos controlados pela Policia Federal

// Historico de alteracoes:
// 06/05/2015 - tatamento do campo B1_CTRPF estava errado
// 08/09/2015 - alterado para que se nao tiver transportador no SF8 busque o transportador informado na entrada da nota
// 09/11/2015 - alterado o filtro do relatorio para data de emissao - estava pela daa de digitaçao
// 18/02/2016 - alterado select pq estava muito lenta a geracao do relatorio

#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_PRODPF()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SD1"
    cDesc1  := "Produtos Controlados pela Policia Federal"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_PRODPF"
    titulo  := "Produtos Controlados pela Policia Federal"
    wnrel   := "ML_PRODPF"
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
    cabec1 := "PRODUTO                                           UNIDADE         QUANTIDADE  DT.EMISSAO  NOTA           FORNECEDOR/CLIENTE                                         TRANSPORTADOR"
    /////      999999  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX      XXX   999,999,999,9999  99/99/9999  999999999 999  999.999.999/9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXxx  999.999.999/9999-99 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    cabec2 := ""
    
    _sQuery := " "
    _sQuery += "SELECT 'E'             AS TIPO_MOV"
    _sQuery += "     , SF1.F1_EMISSAO  AS DATA"
	_sQuery += "     , SF1.F1_TIPO     AS TIPO_NF"
	_sQuery += "     , SF1.F1_DOC      AS NOTA"
	_sQuery += "     , SF1.F1_SERIE    AS SERIE"
	_sQuery += "     , SF1.F1_ESPECIE  AS ESPECIE"
	_sQuery += "     , SF1.F1_FORNECE  AS CLI_FOR"
	_sQuery += "     , SF1.F1_LOJA     AS LJ_CLIFOR"
	_sQuery += "     , SF1.F1_TRANSP   AS TRANSP"
	_sQuery += "     , SD1.D1_COD      AS PROD_COD"
    _sQuery += "     , SD1.D1_DESCRI   AS PROD_DESC"
	_sQuery += "     , SD1.D1_UM       AS PROD_UM"
    _sQuery += "     , SD1.D1_QUANT	   AS QUANT"
    _sQuery += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
  	_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "	ON (SB1.D_E_L_E_T_ = ''"  
	_sQuery += "		AND SB1.B1_COD   = SD1.D1_COD"
	_sQuery += "		AND SB1.B1_CTRPF = '1' )"
	_sQuery += " INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	_sQuery += "	ON (SF1.D_E_L_E_T_ = ''"
	_sQuery += "		AND SF1.F1_FILIAL  = SD1.D1_FILIAL"
	_sQuery += "		AND SF1.F1_EMISSAO = SD1.D1_EMISSAO"
	_sQuery += "		AND SF1.F1_DOC     = SD1.D1_DOC"
	_sQuery += "		AND SF1.F1_SERIE   = SD1.D1_SERIE"
	_sQuery += "		AND SF1.F1_FORNECE = SD1.D1_FORNECE"
	_sQuery += "		AND SF1.F1_LOJA    = SD1.D1_LOJA )"
	_sQuery += "  WHERE SD1.D_E_L_E_T_ = ''"
   	_sQuery += "    AND SD1.D1_FILIAL  = '" + xfilial ("SD1") + "'"
   	_sQuery += "    AND SD1.D1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "    AND SD1.D1_TIPO != 'C'"
	_sQuery += "  UNION ALL"
	_sQuery += " SELECT 'S'             AS TIPO_MOV"
	_sQuery += "      , SF2.F2_EMISSAO  AS DATA"
	_sQuery += "      , SF2.F2_TIPO     AS TIPO_NF"
	_sQuery += "      , SF2.F2_DOC      AS NOTAS"
	_sQuery += "      , SF2.F2_SERIE    AS SERIE"
	_sQuery += "      , SF2.F2_ESPECIE  AS ESPECIE"
	_sQuery += "      , SF2.F2_CLIENTE  AS CLI_FOR"
	_sQuery += "      , SF2.F2_LOJA     AS LJ_CLIFOR"
	_sQuery += "      , SF2.F2_TRANSP   AS TRANSP"
	_sQuery += "      , SD2.D2_COD      AS PROD_COD"
    _sQuery += "      , SB1.B1_DESC     AS PROD_DESC"
	_sQuery += "      , SD2.D2_UM       AS PROD_UM"
    _sQuery += "      , SD2.D2_QUANT	AS QUANT"
  	_sQuery += "   FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "  INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	_sQuery += "	 ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "	 	 AND SB1.B1_COD   = SD2.D2_COD"
	_sQuery += "		AND SB1.B1_CTRPF = '1' )"
	_sQuery += "  INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "	 ON (SF2.D_E_L_E_T_ = ''"
	_sQuery += "		 AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
	_sQuery += "		 AND SF2.F2_EMISSAO = SD2.D2_EMISSAO"
	_sQuery += "		 AND SF2.F2_DOC     = SD2.D2_DOC"
	_sQuery += "		 AND SF2.F2_SERIE   = SD2.D2_SERIE"
	_sQuery += "		 AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
	_sQuery += "		 AND SF2.F2_LOJA    = SD2.D2_LOJA )"
 	_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "    AND SD2.D2_FILIAL  = '" + xfilial ("SD2") + "'"
    _sQuery += "    AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += " ORDER BY PROD_COD, TIPO_MOV, DATA, NOTA"
    
    //u_showmemo(_sQuery)
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _xTotProd = 0
    _xprodAnt = ''
    
	(_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	If li>58
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    If _xprodAnt !='' .and. _xprodAnt <> (_sAliasQ) -> PROD_COD 
	    	// imprime total do item
	    	@ li, 009 PSAY "Total movimentado do Item (E-S):"
	    	@ li, 062 PSAY _xTotProd Picture "@E 999,999,999.99"
	    	li ++
	    	_xTotProd = 0 
	    endif
	    
	    @ li, 000 PSAY (_sAliasQ) -> TIPO_MOV
	    @ li, 003 PSAY (_sAliasQ) -> PROD_COD
	    @ li, 010 PSAY SUBSTR((_sAliasQ) -> PROD_DESC,1,40)
	    @ li, 056 PSAY (_sAliasQ) -> PROD_UM
	    @ li, 063 PSAY (_sAliasQ) -> QUANT     Picture "@E 999,999,999.99"
	    @ li, 079 PSAY stod((_sAliasQ) -> DATA)
	    @ li, 091 PSAY (_sAliasQ) -> NOTA
	    @ li, 101 PSAY (_sAliasQ) -> SERIE
	    // dados do fornecedor / cliente
	    _xCLIFORN := ""
	    IF (_sAliasQ) -> TIPO_MOV = "E"
	    	// notas de entrada
	    	IF (_sAliasQ) -> TIPO_NF = 'N'
	    		// busca dos de fornecedores
	    		_xTAB = "SA2"
	    	ELSE
	    		// busca clientes
				_xTAB = "SA1"	    			
	    	ENDIF
		ELSE
			// notas de saida
			IF (_sAliasQ) -> TIPO_NF = 'N'
				// busca clientes
				_xTAB = "SA1"
	    	ELSE
	    		// busca fornecedores
				_xTAB = "SA2"	    			
	    	ENDIF
	    ENDIF
	    _xCGC = fBuscaCpo (_xTAB, 1, xfilial (_xTAB) + (_sAliasQ) -> CLI_FOR + (_sAliasQ) -> LJ_CLIFOR, SUBSTR(_xTAB,2,2)+ "_CGC")
	    _xNOME= fBuscaCpo (_xTAB, 1, xfilial (_xTAB) + (_sAliasQ) -> CLI_FOR + (_sAliasQ) -> LJ_CLIFOR, SUBSTR(_xTAB,2,2)+ "_NOME")
	    @ li, 106 PSAY iif (len (alltrim (_xCGC)) == 14, transform (_xCGC, "@R 99.999.999/9999-99"), transform (_xCGC, "@R 999.999.999-99") + "    ")
	    @ li, 126 PSAY SUBSTR(_xNOME,1,35)

	    // dados do transportador
	    IF VAL( (_sAliasQ) -> TRANSP ) > 0
	    	_xCGC = fBuscaCpo ("SA4", 1, xfilial ("SA4") + (_sAliasQ) -> TRANSP + '01', "A4_CGC")
	    	_xNOME= fBuscaCpo ("SA4", 1, xfilial ("SA4") + (_sAliasQ) -> TRANSP + '01', "A4_NOME")
	    	@ li, 165 PSAY iif (len (alltrim (_xCGC)) == 14, transform (_xCGC, "@R 99.999.999/9999-99"), transform (_xCGC, "@R 999.999.999-99") + "    ")
	    	@ li, 185 PSAY SUBSTR(_xNOME,1,30)
	    ENDIF
	    
	    IF (_sAliasQ) -> TIPO_MOV = "E"
	    	_xTotProd += (_sAliasQ) -> QUANT
		ELSE
			_xTotProd -= (_sAliasQ) -> QUANT
		ENDIF
			    	
	    _xprodAnt = (_sAliasQ) -> PROD_COD
	    
	    li ++
	 	(_sAliasQ) -> (dbskip())
     enddo
     
     If _xTotProd > 0  
	   	// imprime total do item
	   	@ li, 009 PSAY "Total movimentado do Item :"
	   	@ li, 062 PSAY _xTotProd Picture "@E 999,999,999.99"
	   	li ++
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
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	aadd (_aRegsPerg, {01, "Emissao de         ?", "D",  8, 0,  "",   "   ", {},                        "Data inicial do intervalo de notas de entrada e saida"})
	aadd (_aRegsPerg, {02, "Emissao ate        ?", "D",  8, 0,  "",   "   ", {},                        "Data final do intervalo de notas de entrada e saida"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return