// Programa...: ML_RECTIT
// Autor......: Catia Cardoso
// Data.......: 14/08/2017
// Descricao..: Relatório de Títulos Recebidos - valor de juros e dias de atraso
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Títulos Recebidos - valor de juros e dias de atraso
// #PalavasChave      #titulos_recebidos #juros #dia_de_atraso
// #TabelasPrincipais #SF2 #SE1 #SE5 #SA1
// #Modulos           #FAT
//
// Historico de alteracoes:
//
// 05/07/2018 - Catia   - Desconsiderar os movimentos com valores recebidos igual a zero, pois sao instruçoes e 
//						  não devem ser consideradas
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// --------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_RECTIT()
	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatorio de Títulos Recebidos"
    cDesc2  := ""
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_RECTIT"
    titulo  := "Relatório de Títulos Recebidos"
    wnrel   := "ML_RECTIT"
    nTipo   := 0

    _ValidPerg()
    Pergunte(cPerg,.T.)
    
	if val(mv_par01) = 0
		u_help("É necessário informar o codigo do cliente")
	else
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
//
// -----------------------------------------------------------------------------
// Imprime
Static Function RptDetail()

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="TIP   PREF NUMERO      PARC DT.EMISSAO             VALOR   VENCIMENTO            SALDO          VLR.REC.      VLR.JUR.      VLR.DESC.     DT.PAGTO        DIAS"
    cabec2:=""
    
    _sQuery := " "
    _sQuery += " WITH C AS (SELECT 'TIT' AS TIPO"
    _sQuery += "  				 , SE1.E1_CLIENTE AS CLIENTE, SE1.E1_PREFIXO AS PREFIXO, SE1.E1_NUM AS NUMERO, SE1.E1_PARCELA AS PARCELA"
    _sQuery += " 				 , SE1.E1_EMISSAO AS EMISSAO"
	_sQuery += " 				 , SE1.E1_VALOR AS VALOR"
	_sQuery += "  				 , SE1.E1_VENCTO AS VENCIMENTO"
	_sQuery += "  				 , SE1.E1_SALDO AS SALDO"
    _sQuery += "  				 , ISNULL ((SELECT SUM(SE5.E5_VALOR)"
	_sQuery += " 	  		  				  FROM SE5010 AS SE5"
	_sQuery += " 	 						 WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   						   AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   						   AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   						   AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   						   AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   						   AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += " 	   						   AND SE5.E5_TIPODOC != 'JR'"
	_sQuery += " 	   						   AND SE5.E5_TIPODOC != 'DC'"
	_sQuery += " 	   						   AND SE5.E5_RECPAG  = 'R'" 
	_sQuery += " 	   						),0) - ISNULL ((SELECT SUM(SE5.E5_VALOR)"
	_sQuery += " 	  										  FROM SE5010 AS SE5"
	_sQuery += " 	 										 WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   										   AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   										   AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   										   AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   										   AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   										   AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += " 	   										   AND SE5.E5_RECPAG  = 'P'" 
	_sQuery += " 	   										   AND SE5.E5_TIPODOC = 'ES'"
	_sQuery += " 	   								),0)  AS VLR_REC"
    _sQuery += " 				, ISNULL((SELECT SUM(SE5.E5_VALOR)"
	_sQuery += " 	  						FROM SE5010 AS SE5"
	_sQuery += " 	 					   WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   						 AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   						 AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   						 AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   						 AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   						 AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += " 	   						 AND SE5.E5_TIPODOC = 'JR'"
	_sQuery += " 	   						 AND SE5.E5_SITUACA != 'C'"
	_sQuery += " 	  	 					 AND SE5.E5_RECPAG  = 'R'"
	_sQuery += " 	   				),0) - ISNULL((SELECT SUM(SE5.E5_VALOR)"
	_sQuery += " 	  								 FROM SE5010 AS SE5"
	_sQuery += " 	 								WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   								  AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   								  AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   								  AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   								  AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   								  AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += " 	   								  AND SE5.E5_TIPODOC = 'JR'"
	_sQuery += " 	   								  AND SE5.E5_RECPAG  = 'P'"
	_sQuery += " 	   								  AND SE5.E5_TIPODOC = 'ES'"
	_sQuery += " 	   						),0) AS VLR_JUR"
	_sQuery += " 			, ISNULL((SELECT SUM(SE5.E5_VALOR)"
	_sQuery += " 	  					FROM SE5010 AS SE5"
	_sQuery += " 	 				   WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   					 AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   					 AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   					 AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   					 AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   					 AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += " 	   					 AND SE5.E5_TIPODOC = 'DC'"
	_sQuery += " 	   					 AND SE5.E5_RECPAG  = 'R'"
	_sQuery += " 	   					 AND SE5.E5_SITUACA != 'C'"
	_sQuery += " 	   				),0) AS VLR_DESC"
    _sQuery += " 			, (SELECT MAX(SE5.E5_DATA)"
	_sQuery += " 	  			 FROM SE5010 AS SE5"
	_sQuery += " 	 			WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += " 	   			  AND SE5.E5_FILIAL  = SE1.E1_FILIAL"
	_sQuery += " 	   			  AND SE5.E5_NUMERO  = SE1.E1_NUM"
	_sQuery += " 	   			  AND SE5.E5_CLIFOR  = SE1.E1_CLIENTE"
	_sQuery += " 	   			  AND SE5.E5_PARCELA = SE1.E1_PARCELA"
	_sQuery += " 	   			  AND SE5.E5_PREFIXO = SE1.E1_PREFIXO"
	_sQuery += "        		  AND SE5.E5_RECPAG  = 'R') AS DT_PAGTO"
  	_sQuery += " 		FROM SE1010 AS SE1"
 	_sQuery += " 	   WHERE SE1.D_E_L_E_T_ = ''"
   	_sQuery += " 		 AND SE1.E1_FILIAL  = '" + xFilial('SE1') + "'"
   	_sQuery += " 		 AND SE1.E1_CLIENTE = '" + mv_par01 + "'" 
   	_sQuery += "  UNION ALL"
	_sQuery += " 	 SELECT 'NF' AS TIPO"
    _sQuery += "  		  , SF2.F2_CLIENTE AS CLIENTE, SF2.F2_SERIE AS PREFIXO, SF2.F2_DOC AS NUMERO, '' AS PARCELA"
    _sQuery += "  		  , SF2.F2_EMISSAO AS EMISSAO"
	_sQuery += "  		  , SF2.F2_VALFAT AS VALOR"
	_sQuery += "  		  , '' AS VENCIMENTO"
	_sQuery += "  		  , SF2.F2_VALFAT AS VALOR"
	_sQuery += "  		  , 0 AS VLR_REC"
	_sQuery += "  		  , 0 AS VLR_JUR"
	_sQuery += "  		  , 0 AS VLR_DESC"
	_sQuery += "  		  , '' AS PAGAMENTO"
  	_sQuery += " 	   FROM SF2010 AS SF2"
 	_sQuery += " 	  WHERE SF2.D_E_L_E_T_ = ''"
   	_sQuery += " 		AND SF2.F2_FILIAL  = '" + xFilial('SF2') + "'"
   	_sQuery += " 		AND SF2.F2_CLIENTE = '" + mv_par01 + "'"
   	_sQuery += " 		AND SF2.F2_DUPL = SF2.F2_DOC"
   	_sQuery += " 	)"
	_sQuery += " SELECT C.TIPO, C.CLIENTE, C.PREFIXO, C.NUMERO, C.PARCELA"
    _sQuery += "  	  , dbo.VA_DTOC(C.EMISSAO) AS EMISSAO"
	_sQuery += "  	  , C.VALOR"
	_sQuery += "  	  , dbo.VA_DTOC(C.VENCIMENTO) AS VENCIMENTO"
	_sQuery += "  	  , C.SALDO"
	_sQuery += "  	  , C.VLR_REC - (C.VLR_JUR - C.VLR_DESC) AS REC_LIQ"
	_sQuery += "  	  , C.VLR_REC"
	_sQuery += "  	  , C.VLR_JUR"
	_sQuery += "  	  , C.VLR_DESC"
	_sQuery += "  	  , dbo.VA_DTOC(C.DT_PAGTO) AS PAGAMENTO"
	_sQuery += "  	  , DATEDIFF(day, cast (C.VENCIMENTO as DATETIME), cast(C.DT_PAGTO as DATETIME)) AS QDIAS"
    _sQuery += "   FROM C"
    _sQuery += "  WHERE C.SALDO != C.VALOR" 
	_sQuery += "  ORDER BY C.CLIENTE, C.EMISSAO, C.NUMERO, C.TIPO, C.PARCELA"
        
    _sAliasQ = GetNextAlias ()
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
           
           If li>62
                cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	  _wnome = fbuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) -> CLIENTE + '01', "A1_NOME")
           	  @li, 000 PSAY 'CLIENTE: ' + (_sAliasQ) -> CLIENTE + ' - ' + _wnome   
           	  li++
           	  li++
		   endif           	  
           
           @li, 000 PSAY (_sAliasQ) -> TIPO
           @li, 007 PSAY (_sAliasQ) -> PREFIXO  
           @li, 012 PSAY (_sAliasQ) -> NUMERO
           @li, 024 PSAY (_sAliasQ) -> PARCELA
           @li, 029 PSAY (_sAliasQ) -> EMISSAO
           @li, 043 PSAY (_sAliasQ) -> VALOR Picture "@E 999,999,999.99"
           if (_sAliasQ) -> TIPO = 'TIT'
	           @li, 060 PSAY (_sAliasQ) -> VENCIMENTO
	           @li, 073 PSAY (_sAliasQ) -> SALDO Picture "@E 999,999,999.99"
	           @li, 091 PSAY (_sAliasQ) -> VLR_REC Picture "@E 999,999,999.99"
	           @li, 109 PSAY (_sAliasQ) -> VLR_JUR Picture "@E 999,999.99"
	           @li, 124 PSAY (_sAliasQ) -> VLR_DESC Picture "@E 999,999.99"
	           @li, 139 PSAY (_sAliasQ) -> PAGAMENTO
	           @li, 151 PSAY (_sAliasQ) -> QDIAS Picture "@E 9999"
		   endif	           
	       li ++
           
           (_sAliasQ) -> (dbskip())
     enddo
     
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
    aadd (_aRegsPerg, {01, "Cliente                    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	U_ValPerg (cPerg, _aRegsPerg)
Return
