//  Programa...: ML_ESTCOMI
//  Autor......: Andre Alves
//  Data.......: 14/11/2018
//  Descricao..: Relatório Conferencia Estornos de Comissao
//
//  Historico de alteracoes:


#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_ESTCOMI()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatório Conferencia Estorno Comissao"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório Conferencia Estorno Comissao"
    cPerg   := "ML_ESTCOMI"
    wnrel   := "ML_ESTCOMI"
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
return

Static Function RptDetail()
	//local _aCFOP  := {}
	//local _nCFOP   := 0
	//local _aFILCFOP  := {}
	//local _nFILCFOP  := 0
	//local _nMaxLin   := 63
	local _sQuery    := ""
	//local _aAliasQ   := ""
	//local _nValor    := 0
	//local _aTotVend  := {}
	local _aTotGer   := {}
	//local _sFilial   := ""
	//local _aTotFil   := {}
	
    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    cabec1  :="    DATA       NUMERO     PARCELA  NOME CLIENTE                       VENDEDOR  NOME VENDEDOR                     VLR_TITULO      VLR_RAPEL     BASE_COMIS     P_COMIS     VLR_PROVISIO      VLR_DESCONTO     VLR_ESTORNADO"
    cabec2  :=""
     
    _sQuery := " "
    _sQuery += " SELECT SE5.E5_DATA AS DATAS, SE5.E5_NUMERO AS NUMERO, SE5.E5_PARCELA AS PARCELA, "
    _sQuery += "        SA1.A1_NOME AS CLI_NOME, "
    _sQuery += "        SE1.E1_VEND1 AS VENDEDOR, SA3.A3_NOME  AS VEND_NOME, SE1.E1_VALOR AS VLR_TITULO, SE1.E1_VARAPEL AS VLR_RAPEL, "
	_sQuery += "        SE1.E1_BASCOM1 AS BASE_COMISSAO, SE1.E1_COMIS1 AS P_COMISSAO, "
	_sQuery += "        ROUND(SE1.E1_BASCOM1*SE1.E1_COMIS1/100,2) AS VLR_PROVISIONADO, "
	_sQuery += "	    SE5.E5_VALOR AS VLR_DESCONTO, "
	_sQuery += "        ROUND(SE5.E5_VALOR*(SE1.E1_BASCOM1*SE1.E1_COMIS1/100)/SE1.E1_VALOR,2) AS VLR_ESTORNADO"
    _sQuery += "  FROM " + RetSQLName ("SE5") + " SE5 "
    _sQuery += "  		INNER JOIN " + RetSQLName ("SE1") +  " SE1 "
    _sQuery += "   		ON (SE1.D_E_L_E_T_ = ''"
    _sQuery += "  			AND SE1.E1_FILIAL  = SE5.E5_FILIAL"
    _sQuery += "            AND SE1.E1_CLIENTE = SE5.E5_CLIFOR"
    _sQuery += "  			AND SE1.E1_NUM     = SE5.E5_NUMERO"
    _sQuery += "  			AND SE1.E1_PREFIXO = SE5.E5_PREFIXO"
  //_sQuery += "            AND SE1.E1_VEND1 NOT IN ('001','060','135','186','240','244','248')"
    _sQuery += "            AND SE1.E1_VEND1 NOT IN " + FormatIn (alltrim (GetMv ('MV_VENDDIR')), '/') // desconsidera os vendedores diretos
	_sQuery += "  			AND SE1.E1_COMIS1 > 0
    _sQuery += "  			AND SE1.E1_PARCELA = SE5.E5_PARCELA)
	_sQuery += "        INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _sQuery += "  		ON (SA1.D_E_L_E_T_  = ''"
    _sQuery += "  			AND SA1.A1_COD  = SE5.E5_CLIFOR"
    _sQuery += "  			AND SA1.A1_LOJA = SE5.E5_LOJA)"
    _sQuery += "  	    INNER JOIN " + RetSQLName ("SA3") + " SA3 "
    _sQuery += "		ON (SA3.D_E_L_E_T_  = ''"
    _sQuery += "			AND SA3.A3_COD  = SE1.E1_VEND1)"
    _sQuery += "  WHERE SE5.D_E_L_E_T_ = ''"
    _sQuery += "    AND SE5.E5_FILIAL  = '" + xFilial("SE5") + "' " // usar filial do menu XFILIAL
    _sQuery += "	AND SE5.E5_DATA BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'" // no programa usar o intervalo de datas dos parametros
    _sQuery += "    AND SE5.E5_RECPAG  = 'R'"
  //_sQuery += "    AND SE5.E5_TIPODOC = 'DC'"
    _sQuery += "    AND (SE5.E5_TIPODOC = 'DC' OR (SE5.E5_TIPODOC = 'CP' AND SE5.E5_DOCUMEN NOT LIKE '% RA %'))"
    _sQuery += "    AND E5_SITUACA != 'C'"
    _sQuery += "  ORDER BY SE5.E5_DATA"
    
    
    
//	u_showmemo (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotGer  = {0,0,0,0,0,0,0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     	
		   If li>58
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           Endif        
       
           @li,  01 PSAY stod((_sAliasQ) -> DATAS)
//           @li,  16 PSAY (_sAliasQ) -> PREFIXO
           @li,  14 PSAY (_sAliasQ) -> NUMERO
           @li,  29 PSAY (_sAliasQ) -> PARCELA
//		   @li,  44 PSAY (_sAliasQ) -> CLIENTE
           @li,  35 PSAY left((_sAliasQ) -> CLI_NOME,30)
           @li,  72 PSAY (_sAliasQ) -> VENDEDOR
           @li,  80 PSAY left((_sAliasQ) -> VEND_NOME,30)
           @li, 111 PSAY (_sAliasQ) -> VLR_TITULO Picture       "@E 99,999,999.99"
           @li, 126 PSAY (_sAliasQ) -> VLR_RAPEL Picture        "@E 99,999,999.99"
           @li, 141 PSAY (_sAliasQ) -> BASE_COMISSAO Picture    "@E 99,999,999.99"
           @li, 152 PSAY (_sAliasQ) -> P_COMISSAO Picture       "@E 99,999,999.99"
           @li, 170 PSAY (_sAliasQ) -> VLR_PROVISIONADO Picture "@E 99,999,999.99"
           @li, 188 PSAY (_sAliasQ) -> VLR_DESCONTO Picture     "@E 99,999,999.99"
           @li, 206 PSAY (_sAliasQ) -> VLR_ESTORNADO Picture    "@E 99,999,999.99"
           li ++
		   
           // acumula total 
           _aTotGer[1] += (_sAliasQ) -> VLR_TITULO
           _aTotGer[2] += (_sAliasQ) -> VLR_RAPEL
           _aTotGer[3] += (_sAliasQ) -> BASE_COMISSAO
           _aTotGer[4] += (_sAliasQ) -> P_COMISSAO
           _aTotGer[5] += (_sAliasQ) -> VLR_PROVISIONADO
           _aTotGer[6] += (_sAliasQ) -> VLR_DESCONTO
           _aTotGer[7] += (_sAliasQ) -> VLR_ESTORNADO
         
           (_sAliasQ) -> (dbskip())
    
     enddo
     
     if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @li, 00 PSAY "TOTAL DO GERAL --> "
        @li, 111 PSAY _aTotGer[1] Picture "@E 99,999,999.99"
        @li, 126 PSAY _aTotGer[2] Picture "@E 99,999,999.99"
        @li, 141 PSAY _aTotGer[3] Picture "@E 99,999,999.99"
        @li, 152 PSAY _aTotGer[4] Picture "@E 99,999,999.99"
        @li, 170 PSAY _aTotGer[5] Picture "@E 99,999,999.99"
        @li, 188 PSAY _aTotGer[6] Picture "@E 99,999,999.99"
	    @li, 206 PSAY _aTotGer[7] Picture "@E 99,999,999.99"
        li++
     Endif
	
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


    aadd (_aRegsPerg, {01, "Data de            			 ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data até    			     ?", "D", 8, 0,  "",   "   ", {},                         ""})
//	aadd (_aRegsPerg, {05, "Estado                       ?", "C", 2, 0,  "",   "   ", {},                         ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
