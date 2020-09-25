//  Programa...: ML_SLDRAP
//  Autor......: Catia Cardoso
//  Data.......: 25/02/2015
//  Cliente....: Alianca
//  Descricao..: Relatório de Saldo de Provisao de Comissoes
//
//  Alterações:
//  18/08/2015 - Alterado para que busque o percentual de rapel do dia da emissao do titulo - busca pelo SF2 - campo F2_VAPERAP
//  19/08/2015 - Incluido campo Cliente no relatorio e intervalo de cliente.
//  20/08/2015 - impressao de parametros no final do relatorio
//  19/10/2015 - Catia - criada opcao por REDE para facilitar na conciliação

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_SLDRAP()

	u_help ("Entre em contato com a TI para atualizar este relatorio, pois nao contempla % de rapel por item.")

    cString := "SE1"
    cDesc1  := "Relatório de Saldo de Provisao de Rapel"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_SLDRAP"
    wnrel   := "ML_SLDRAP"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	titulo  := "Relatório de Saldo de Provisao de Rapel - Posição em: " + dtoc(mv_par01)
    
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

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
   	cabec1:="FIL PRF NUMERO       EMISSAO    CLIENTE                                               VALOR             VALOR            VALOR             VALOR             SALDO        %          VLR RAPEL          VLR RAPEL"
   	cabec2:="        TITULO                                                                     ORIGINAL          RECEBIDO        DESCONTOS      COMPENSAÇÕES            TITULO                        PAGO            A PAGAR"

    _sQuery := " "
    _sQuery += "WITH C AS (SELECT E1_PREFIXO AS PREFIXO"
	_sQuery += " 				, E1_NUM     AS NUMERO"
	_sQuery += " 				, E1_PARCELA AS PARCELA"
	_sQuery += " 				, E1_EMISSAO AS EMISSAO"
	_sQuery += " 				, E1_VENCTO  AS VENCIMENTO"
	_sQuery += " 				, E1_BAIXA   AS PAGAMENTO"   
	_sQuery += " 				, E1_VALOR   AS VLR_ORIGINAL"
	_sQuery += " 				, E1_FILIAL  AS FILIAL"
	_sQuery += " 				, E1_CLIENTE AS CLIENTE"
	_sQuery += " 				, E1_LOJA    AS LOJA"
	
	_sQuery += "                , SF2.F2_VAPERAP   AS PER_RAPEL"
	
	_sQuery += " 				, ISNULL (( SELECT SUM(E5_VALOR)"
    _sQuery += "                    		  FROM " + RetSQLName ("SE5") + " AS SE5 "
    _sQuery += "			  				 WHERE E5_FILIAL = E1_FILIAL"
    _sQuery += "                			   AND D_E_L_E_T_ != '*'"
    _sQuery += "                			   AND E5_RECPAG = 'R'"
    _sQuery += "                			   AND E5_NUMERO = E1_NUM"
    _sQuery += "                			   AND E5_TIPODOC = 'VL'"
    _sQuery += "                    		   AND E5_PREFIXO = E1_PREFIXO"	
	_sQuery += "                        	   AND E5_PARCELA = E1_PARCELA"
	_sQuery += "    						   AND E5_DATA <= '" + dtos (mv_par01) + "'"
	_sQuery += "                        	   AND E5_SITUACA = ''"
	_sQuery += "                      		GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0)  AS VLR_RECEBIDO"
	_sQuery += "      			, ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
    _sQuery += "                    		  FROM " + RetSQLName ("SE5") + " AS SE5 "
    _sQuery += "                   			 WHERE E5_FILIAL = E1_FILIAL"
    _sQuery += "                     		   AND D_E_L_E_T_ != '*'"
    _sQuery += "                     		   AND E5_RECPAG = 'R'"
    _sQuery += "                     		   AND E5_NUMERO = E1_NUM"
    _sQuery += "                     		   AND E5_TIPODOC = 'JR'"
    _sQuery += "                     		   AND E5_PREFIXO = E1_PREFIXO"
    _sQuery += "                     		   AND E5_PARCELA = E1_PARCELA"
    _sQuery += "    						   AND E5_DATA <= '" + dtos (mv_par01) + "'"
    _sQuery += "                        	   AND E5_SITUACA = ''"
	_sQuery += "                  			GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0)  AS VLR_JUROS"
	_sQuery += "     			, ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
    _sQuery += "                    		  FROM " + RetSQLName ("SE5") + " AS SE5 "
    _sQuery += "                      		 WHERE E5_FILIAL = E1_FILIAL"
	_sQuery += "                        	   AND D_E_L_E_T_ != '*'"
	_sQuery += "                        	   AND E5_RECPAG = 'R'"
	_sQuery += "                        	   AND E5_NUMERO = E1_NUM"
	_sQuery += "                        	   AND E5_TIPODOC = 'DC'"
	_sQuery += "                        	   AND E5_PREFIXO = E1_PREFIXO"
	_sQuery += "                        	   AND E5_PARCELA = E1_PARCELA"
	_sQuery += "                        	   AND E5_SITUACA = ''"
	_sQuery += "    						   AND E5_DATA <= '" + dtos (mv_par01) + "'"
	_sQuery += "                    		GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO),0)  AS VLR_DESCONTO"
	_sQuery += "         		, ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
	_sQuery += "                    		  FROM " + RetSQLName ("SE5") + " AS SE5 "
    _sQuery += "                      		 WHERE E5_FILIAL = E1_FILIAL"
	_sQuery += "                        	   AND D_E_L_E_T_ != '*'"
	_sQuery += "                        	   AND E5_RECPAG = 'R'"
	_sQuery += "                        	   AND E5_NUMERO = E1_NUM"
	_sQuery += "                        	   AND E5_TIPODOC = 'CP'"
	_sQuery += "                        	   AND E5_PREFIXO = E1_PREFIXO"
	_sQuery += "                        	   AND E5_PARCELA = E1_PARCELA"
	_sQuery += "    						   AND E5_DATA <= '" + dtos (mv_par01) + "'"
	_sQuery += "                        	   AND E5_SITUACA = ''"
	_sQuery += "                      		GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO),0)  AS VLR_COMP"
	_sQuery += "     			, SE1.E1_COMIS1 AS PERC_COM"
  	_sQuery += "    		 FROM SE1010 AS SE1"
  	_sQuery += "        		INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "        		  		ON (SF2.D_E_L_E_T_ = ''"
 	_sQuery += "        			  		AND SF2.F2_FILIAL  = SE1.E1_FILIAL"
 	_sQuery += "        			  		AND SF2.F2_DOC     = SE1.E1_NUM"
 	_sQuery += "        			  		AND SF2.F2_SERIE   = SE1.E1_PREFIXO"
 	_sQuery += "        			  		AND SF2.F2_CLIENTE = SE1.E1_CLIENTE"
 	_sQuery += "        			  		AND SF2.F2_LOJA    = SE1.E1_LOJA"
  	_sQuery += "        			  		AND SF2.F2_EMISSAO = SE1.E1_EMISSAO"
  	_sQuery += "        			  		AND SF2.F2_VAPERAP > 0"
  	_sQuery += "        			  		AND SF2.F2_DUPL   != '')"
  	_sQuery += "     		INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "						ON (SA1.D_E_L_E_T_ = ''"
 	_sQuery += "							AND SA1.A1_COD     = SE1.E1_CLIENTE"
 	IF mv_par08 = 2  // opcao por rede 
		_sQuery += "						AND SA1.A1_VACBASE  BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
	ENDIF			
	_sQuery += "							AND SA1.A1_LOJA    = SE1.E1_LOJA)"
	_sQuery += "    		WHERE SE1.D_E_L_E_T_ = ''
 	_sQuery += "              AND SE1.E1_FILIAL  BETWEEN '" + mv_par02 + "' AND '" + mv_par03 + "'"
 	_sQuery += "              AND SE1.E1_EMISSAO <= '" + dtos (mv_par01) + "'"
 	_sQuery += "              AND SE1.E1_NATUREZ != '110199'"
 	IF mv_par08 = 1  // opcao por cliente
 		_sQuery += "              AND SE1.E1_CLIENTE BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
 		_sQuery += "              AND SE1.E1_LOJA    BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
 	endif
  	_sQuery += "              AND SE1.E1_TIPO = 'NF')"
    _sQuery += "SELECT * "
  	_sQuery += "  FROM C "
 	_sQuery += " WHERE ROUND(C.VLR_ORIGINAL,2) > ROUND(C.VLR_RECEBIDO + C.VLR_DESCONTO + C.VLR_COMP,2)"
    _sQuery += " ORDER BY C.EMISSAO, C.NUMERO, C.PARCELA"
    
    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0,0,0,0,0}
    _aTotGer  = {0,0,0,0,0,0,0}
    
    wcol:=0
    
    (_sAliasQ) -> (DBGoTop ())
     _vendAnt := ""
     _vendAntnome := ""
     Do While ! (_sAliasQ) -> (Eof ())
			     
	   		w_recebido = (_sAliasQ) -> VLR_RECEBIDO - (_sAliasQ) -> VLR_JUROS
			w_saldo = (_sAliasQ) -> VLR_ORIGINAL - ( (_sAliasQ) -> VLR_RECEBIDO + (_sAliasQ) -> VLR_DESCONTO + (_sAliasQ) -> VLR_COMP) 
			// BUSCAR O PERCENTUAL DE RAPEL DA NOTA
	        w_per_rapel = (_sAliasQ) -> PER_RAPEL
	        // BUSCA RAZAO SOCIAL CLIENTE
	        w_nome = SUBSTR(fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) -> CLIENTE + (_sAliasQ) -> LOJA + ' - ', "A1_NOME"),1,25)
	        if w_recebido >  0
	           	w_paga := w_recebido * w_per_rapel /100
	        else
	         	w_paga :=0
	        endif
	        
	        if w_saldo > 0
	           	w_pagar := w_saldo * w_per_rapel /100
	        else
	           	w_pagar :=0
	        endif	
	           	
		   	If li>58
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           	
           	@li,  00 PSAY (_sAliasQ) -> FILIAL
           	@li,  05 PSAY (_sAliasQ) -> PREFIXO
           	@li,  07 PSAY (_sAliasQ) -> NUMERO + IIF( (_sAliasQ) -> PARCELA !=' ' ,'-' + (_sAliasQ) -> PARCELA, '')
           	@li,  20 PSAY stod((_sAliasQ) -> EMISSAO)
           	@li,  31 PSAY (_sAliasQ) -> CLIENTE + '/' + (_sAliasQ) -> LOJA + ' - ' + w_nome  
           	@li,  78 PSAY (_sAliasQ) -> VLR_ORIGINAL Picture "@E 9,999,999.99"
           	@li,  96 PSAY w_recebido                 Picture "@E 9,999,999.99"
           	@li, 113 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 9,999,999.99"
           	@li, 131 PSAY (_sAliasQ) -> VLR_COMP     Picture "@E 9,999,999.99"
           	@li, 149 PSAY w_saldo                    Picture "@E 9,999,999.99"
           	@li, 167 PSAY w_per_rapel                Picture "@E 99.99"
           	@li, 177 PSAY w_paga  Picture "@E 9,999,999.99"
           	@li, 196 PSAY w_pagar Picture "@E 9,999,999.99"			          		
           	li ++
        
           _aTotGer [1] += (_sAliasQ) -> VLR_ORIGINAL
           _aTotGer [2] += w_recebido
           _aTotGer [3] += (_sAliasQ) -> VLR_DESCONTO
           _aTotGer [4] += (_sAliasQ) -> VLR_COMP
           _aTotGer [5] += w_saldo
           _aTotGer [6] += w_paga
           _aTotGer [7] += w_pagar
                           
           (_sAliasQ) -> (dbskip())
     enddo
     
 	if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAL GERAL --> "
		@ li, 77 PSAY _aTotGer [1]  Picture "@E 999,999,999.99"
       	@ li, 95 PSAY _aTotGer [2]  Picture "@E 999,999,999.99"
       	@ li,112 PSAY _aTotGer [3]  Picture "@E 999,999,999.99"
       	@ li,130 PSAY _aTotGer [4]  Picture "@E 999,999,999.99"
       	@ li,148 PSAY _aTotGer [5]  Picture "@E 999,999,999.99"
       	@ li,176 PSAY _aTotGer [6]  Picture "@E 999,999,999.99"
       	@ li,195 PSAY _aTotGer [7]  Picture "@E 999,999,999.99"
       	
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
    aadd (_aRegsPerg, {01, "Posição em                   ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial de                    ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Filial até                   ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {04, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {05, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {06, "Loja de                       ", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {07, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {08, "Opção para cliente           ?", "N", 1,  0,  "",   "   ", {"Cliente","Rede"},   ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
