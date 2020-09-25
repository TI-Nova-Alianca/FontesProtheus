//  Programa...: ML_SLDRAP
//  Autor......: Catia Cardoso
//  Data.......: 08/07/2019
//  Cliente....: Alianca
//  Descricao..: Relatório Conferencia cartoes de credito
//
//  Alterações:

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_CARTOES(_wfilDESC)

    cString := "SE1"
    cDesc1  := "Relatório de Conferencia Recebimentos -  Cartoes Credito"
    cDesc2  := ""
    cDesc3  := ""
    cPerg   := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    wnrel   := "ML_CARTOES"
    nTipo   := 0

	titulo  := "Relatório de Conferencia Recebimentos -  Cartoes Credito"

	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	If nLastKey == 27
   		Return
	Endif

	SetDefault(aReturn,cString)
	If nLastKey == 27
   		Return
	Endif

	RptStatus({|| RptDetail()})

return

Static Function RptDetail()

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
   	cabec1:=" FILIAL   DT LANCAM.         NSU    TX_ADM     TARIFA ADM     TARIFA COM   VALOR LIQUIDO       DT VENDA  PARC   TITULO PARC   TIPO  ADMINISTRADORA         VALOR TITULO    DT.EMISSAO    DT.VENCIM.
               //XX   99/99/9999    99999999     99,99     999,999,99     999,999.99    999.999.999,99    99/99/9999    99    999999    9    XX  XXX-XXXXXXXXXXXXX    999.999.999,99    99/99/9999    99/99/9999
   	cabec2:=""

    _sQuery := " "
    _sQuery += " SELECT AUX.FILIAL     AS FILIAL"
    _sQuery += "  	  , dbo.VA_DTOC(AUX.DTLAN) AS DTLAN"
	_sQuery += "  	  , AUX.NSUMOV     AS NSU"
	_sQuery += "	  , AUX.VLRPARC    AS VLR_PARC"
	_sQuery += "      , AUX.TAXAADM    AS TX_ADM"
    _sQuery += "  	  , AUX.TARIFADMC  AS TAR_ADM"
    _sQuery += "	  , AUX.TARIFCOMC  AS TAR_COM"
    _sQuery += "	  , AUX.VLRPARCLIQ AS VLR_LIQ"
	_sQuery += "  	  , dbo.VA_DTOC(AUX.DTMOV) AS DTMOV"
	_sQuery += "  	  , AUX.PARCELA    AS PARCELA"
	_sQuery += "  	  , SE1.E1_NUM"
	_sQuery += "	  , SE1.E1_PARCELA" 
	_sQuery += "	  , SE1.E1_TIPO"
	_sQuery += "	  , SE1.E1_CLIENTE"
	_sQuery += "	  , SE1.E1_LOJA"
	_sQuery += "  	  , SE1.E1_NOMCLI"
	_sQuery += "	  , SE1.E1_VALOR"
	_sQuery += "	  , SE1.E1_SALDO"
	_sQuery += "  	  , dbo.VA_DTOC(SE1.E1_EMISSAO) AS EMISSAO"
	_sQuery += "  	  , dbo.VA_DTOC(SE1.E1_VENCREA) AS VENCIMENTO"
	_sQuery += "   FROM AUX_CARTOES AS AUX"
    _sQuery += " 		LEFT JOIN SE1010 AS SE1"
	_sQuery += " 			ON (SE1.D_E_L_E_T_     = ''"
	_sQuery += " 				AND SE1.E1_FILIAL  = AUX.FILIAL"
	_sQuery += "				AND SE1.E1_SALDO >0"
	_sQuery += "				AND SE1.E1_VALOR   = AUX.VLRPARC"
	_sQuery += "				AND SE1.E1_EMISSAO = AUX.DTMOV"
	_sQuery += "				AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
	_sQuery += "				AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
	_sQuery += "		                          		  WHEN AUX.PARCELA='02' THEN 'B'" 
	_sQuery += "								  		  WHEN AUX.PARCELA='03' THEN 'C'"
	_sQuery += "								  		  WHEN AUX.PARCELA='04' THEN 'D'" 
	_sQuery += "								  		  WHEN AUX.PARCELA='05' THEN 'E'"
	_sQuery += "								  		  WHEN AUX.PARCELA='06' THEN 'F'" 
	_sQuery += "							 		END )"	 
	_sQuery += "  ORDER BY FILIAL, SE1.E1_CLIENTE"

    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0,0,0,0,0}
    _aTotGer  = {0,0,0,0,0,0,0}
    
    wcol:=0
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
			     
	   		If li>62
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	
           	@li,  05 PSAY (_sAliasQ) -> FILIAL
           	@li,  10 PSAY (_sAliasQ) -> DTLAN
           	@li,  24 PSAY (_sAliasQ) -> NSU
           	@li,  37 PSAY (_sAliasQ) -> TX_ADM   Picture "@E 999.99"
           	@li,  47 PSAY (_sAliasQ) -> TAR_ADM  Picture "@E 999,999.99"
           	@li,  62 PSAY (_sAliasQ) -> TAR_COM  Picture "@E 999,999.99"
           	@li,  76 PSAY (_sAliasQ) -> VLR_LIQ  Picture "@E 9,999,999.99"
           	@li,  94 PSAY (_sAliasQ) -> DTMOV
           	@li, 108 PSAY (_sAliasQ) -> PARCELA
           	if val((_sAliasQ) -> E1_NUM) > 0 
	           	@li, 114 PSAY (_sAliasQ) -> E1_NUM  
	           	@li, 124 PSAY (_sAliasQ) -> E1_PARCELA
	           	@li, 129 PSAY (_sAliasQ) -> E1_TIPO
	           	@li, 133 PSAY alltrim( (_sAliasQ) -> E1_CLIENTE) + '-' + SUBS((_sAliasQ) -> E1_NOMCLI,1,12)
	           	@li, 154 PSAY (_sAliasQ) -> E1_VALOR Picture "@E 999,999,999.99"
	           	@li, 172 PSAY (_sAliasQ) -> EMISSAO
	            @li, 186 PSAY (_sAliasQ) -> VENCIMENTO
	        else
	            @li, 114 PSAY "*** Titulo não localizado"
	        endif
           	li ++
           	
           _aTotGer [1] += (_sAliasQ) -> TAR_ADM
           _aTotGer [2] += (_sAliasQ) -> TAR_COM 
           _aTotGer [3] += (_sAliasQ) -> VLR_LIQ
           _aTotGer [4] += (_sAliasQ) -> E1_VALOR
           (_sAliasQ) -> (dbskip())
     enddo
     
 	if _aTotGer [1] > 0
        // imprime totais do arquivo
        If li>62
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li,  00 PSAY "TOTAIS DO ARQUIVO --> "
		@ li,  47 PSAY _aTotGer [1]  Picture "@E 999,999.99"
       	@ li,  62 PSAY _aTotGer [2]  Picture "@E 999,999.99"
       	@ li,  76 PSAY _aTotGer [3]  Picture "@E 9,999,999.99"
       	@ li, 154 PSAY _aTotGer [4]  Picture "@E 999,999,999.99"
       	li++
     Endif
     
     // imprime faturas que serão geradas por filial - que devem fechar com os lctos no extrato
     // GERA FATURAS REFERENTE AOS TITULOS RECEBIDOS
     _sQuery := ""
     _sQuery += " SELECT AUX.FILIAL AS FILIAL, dbo.VA_DTOC(AUX.DTLAN) AS DATA, SE1.E1_TIPO AS TIPO, SE1.E1_CLIENTE AS CLIENTE, SE1.E1_NOMCLI AS NOMCLI"
	 _sQuery += "      , SUM(AUX.VLRPARCLIQ) AS VLR_EXTRATO"
     _sQuery += " 	 FROM AUX_CARTOES AS AUX"
     _sQuery += " 		LEFT JOIN SE1010 AS SE1"
     _sQuery += " 			ON (SE1.D_E_L_E_T_     = ''"
     _sQuery += " 				AND SE1.E1_FILIAL  = AUX.FILIAL"
     _sQuery += "				AND SE1.E1_VALOR   = AUX.VLRPARC"
     _sQuery += "				AND SE1.E1_EMISSAO = AUX.DTMOV"
     _sQuery += "              AND SE1.E1_SALDO >0"
	 _sQuery += " 				AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
	 _sQuery += "				AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
	 _sQuery += "			                          	  WHEN AUX.PARCELA='02' THEN 'B'" 
	 _sQuery += "									  	  WHEN AUX.PARCELA='03' THEN 'C'"
	 _sQuery += "									  	  WHEN AUX.PARCELA='04' THEN 'D'" 
	 _sQuery += "									      WHEN AUX.PARCELA='05' THEN 'E'"
	 _sQuery += "									  	  WHEN AUX.PARCELA='06' THEN 'F'" 
	 _sQuery += "								 	  END )"	  
	 if _wfilDESC != ''
		 _sQuery += "   WHERE AUX.FILIAL NOT IN " + FormatIn(_wfilDESC,"/")
	 endif
	 _sQuery += "    GROUP BY AUX.FILIAL, AUX.DTLAN, SE1.E1_TIPO, SE1.E1_CLIENTE, SE1.E1_NOMCLI"
	 _sQuery += " 	 ORDER BY AUX.FILIAL, AUX.DTLAN, SE1.E1_TIPO, SE1.E1_CLIENTE"
	 
	 _sAliasF = GetNextAlias ()
	 DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasF, .f., .t.)
    
	 _wtit :=0
     (_sAliasF) -> (DBGoTop ())
     Do While ! (_sAliasF) -> (Eof ())
			     
	   		If li>62
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	if _wtit = 0
           		li ++
           		li ++
           		li ++
           		li ++
           		@li, 000 PSAY "Serão geradas as seguintes faturas:"
           		li ++
           		li ++
           		@li, 000 PSAY "FILIAL     DATA             TIPO       ADMINISTRADORA                     VALOR"
           		li ++
           		_wtit := 1
           	endif	
           	
           	If li>62
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	
           	@li,  04 PSAY (_sAliasF) -> FILIAL  
          	@li,  11 PSAY (_sAliasF) -> DATA
           	@li,  29 PSAY (_sAliasF) -> TIPO
           	@li,  39 PSAY alltrim( (_sAliasF) -> CLIENTE) + '-' + SUBS((_sAliasF) -> NOMCLI,1,12)
           	@li,  65 PSAY (_sAliasF) -> VLR_EXTRATO Picture "@E 999,999,999.99"
           	li ++
           	
           (_sAliasF) -> (dbskip())
     enddo
     
     Set Device To Screen

     If aReturn[5]==1
           Set Printer TO
           dbcommitAll()
           ourspool(wnrel)
     Endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return