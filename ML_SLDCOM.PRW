//  Programa...: ML_COMISSAO
//  Autor......: Catia Cardoso
//  Data.......: 04/02/2015
//  Cliente....: Alianca
//  Descricao..: Relatório de Saldo de Provisao de Comissoes
//
//  24/02/2015 - Catia - Incluido paramentros de filial inicial e final
//  20/08/2015 - impressao de parametros no final do relatorio
//  02/09/2015 - desconsiderar vendedor 135 e 186
//  22/10/2015 - criada coluna de valor base da comissao
//  04/11/2015 - desconsiderar o vendedor 240
//  25/01/2016 - recalculo da base e consequentemente o valor da comissao conforme o MSE3440
//  19/10/2016 - Catia - Alterado teste de vendedores diretos por parametro $GETMV("MV_VENDDIR")
//  27/09/2018 - Catia - Ajustado para que nao liste os vendedores inativos 

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_SLDCOM()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatório de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_SLDCOM"
    wnrel   := "ML_SLDCOM"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	titulo  := "Relatório de Saldo de Provisao de Comissões - Posição em: " + dtoc(mv_par01)
    
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
    if mv_par05 = 1
    	cabec1:="PRF NUMERO PARC                 VALOR             VALOR            VALOR             VALOR             SALDO           VLR.BASE     %      VLR COMISSAO           VLR COMISSAO"
    	cabec2:="    TITULO                   ORIGINAL          RECEBIDO        DESCONTOS      COMPENSAÇÕES            TITULO           COMISSAO                 JA PAGA                A PAGAR"
    	
	else
		cabec1:="VENDEDOR                                                                VALOR             VALOR            VALOR             VALOR             SALDO           VLR.BASE            VLR COMISSAO           VLR COMISSAO"
    	cabec2:="                                                                     ORIGINAL          RECEBIDO        DESCONTOS      COMPENSAÇÕES            TITULO           COMISSAO                 JA PAGA                A PAGAR"
	endif    	
       
    _sQuery := " "
    _sQuery += "WITH C AS (SELECT E1_VEND1   AS VENDEDOR"
    _sQuery += "                , A3_NOME    AS NOM_VEND"
    _sQuery += " 				, E1_PREFIXO AS PREFIXO"
	_sQuery += " 				, E1_NUM     AS NUMERO"
	_sQuery += " 				, E1_PARCELA AS PARCELA"
	_sQuery += " 				, E1_EMISSAO AS EMISSAO"
	_sQuery += " 				, E1_VENCTO  AS VENCIMENTO"
	_sQuery += " 				, E1_BAIXA   AS PAGAMENTO"   
	_sQuery += " 				, E1_VALOR   AS VLR_ORIGINAL"
	_sQuery += " 				, E1_FILIAL  AS FILIAL"
	_sQuery += " 				, E1_BASCOM1 AS BASECOM"
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
	_sQuery += "                      		GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO),0)  AS VLR_COMP"
	_sQuery += "     			, SE1.E1_COMIS1  AS PERC_COM"
	_sQuery += "     			, SE1.E1_CLIENTE AS CLIENTE"
	_sQuery += "     			, SE1.E1_LOJA    AS LOJA"
	_sQuery += "    		 FROM SE1010 AS SE1"
  	_sQuery += "    			INNER JOIN SA3010 AS SA3"
	_sQuery += "    				ON (SA3.D_E_L_E_T_ = '' "
   	_sQuery += "           			AND SA3.A3_MSBLQL != '1'"
   	_sQuery += "           			AND SA3.A3_ATIVO  != 'N'"
  	_sQuery += "    		          	AND SA3.A3_COD     = SE1.E1_VEND1)"
 	_sQuery += "    		WHERE SE1.D_E_L_E_T_ = ''
 	_sQuery += "              AND SE1.E1_FILIAL  BETWEEN '" + mv_par06 + "' AND '" + mv_par07 + "'"
 	_sQuery += "              AND SE1.E1_EMISSAO <= '" + dtos (mv_par01) + "'"
 	_sQuery += "              AND SE1.E1_NATUREZ != '110199'"
 	_sQuery += "              AND SE1.E1_TIPO = 'NF'"
 	_sQuery += "    		  AND SE1.E1_VEND1 != ''"
 	_sQuery += "              AND SE1.E1_VEND1 NOT IN " + FormatIn (alltrim (GetMv ('MV_VENDDIR')), '/') // desconsidera os vendedores diretos
    _sQuery += "              AND SE1.E1_VEND1 BETWEEN '" + mv_par02 + "' AND '" + mv_par03 + "'"
   	_sQuery += "    		  AND SE1.E1_COMIS1 > 0) "
   	_sQuery += "SELECT * "
  	_sQuery += "  FROM C "
 	_sQuery += " WHERE ROUND(C.VLR_ORIGINAL,2) > ROUND(C.VLR_RECEBIDO + C.VLR_DESCONTO + C.VLR_COMP,2)"
    _sQuery += " ORDER BY C.VENDEDOR, C.EMISSAO, C.NUMERO, C.PARCELA"
    
    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0,0,0,0,0,0}
    _aTotGer  = {0,0,0,0,0,0,0,0}
    
    wcol:=0
    if mv_par05=2
       wcol:=40
    endif
    
    (_sAliasQ) -> (DBGoTop ())
     _vendAnt := ""
     _vendAntnome := ""
     Do While ! (_sAliasQ) -> (Eof ())
			     
           IF _vendAnt != "" .and. _vendAnt != (_sAliasQ) -> VENDEDOR
                // imprime totais do vendedor
                If li>58
                    cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
                Endif        
                li++
                if mv_par05 = 1
                	@ li, 00 PSAY "TOTAL DO VENDEDOR --> "
                else
					@ li, 00 PSAY _vendAnt + ' - ' + _vendAntnome
				endif

                @ li,  25+wcol PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
        		@ li,  43+wcol PSAY _aTotVend [2]  Picture "@E 9,999,999.99"
				@ li,  60+wcol PSAY _aTotVend [3]  Picture "@E 9,999,999.99"
        		@ li,  78+wcol PSAY _aTotVend [4]  Picture "@E 9,999,999.99"
				@ li,  96+wcol PSAY _aTotVend [5]  Picture "@E 9,999,999.99"
				@ li, 124+wcol PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
        		@ li, 143+wcol PSAY _aTotVend [7]  Picture "@E 9,999,999.99"
        		li++
                li++
                
                if mv_par05 = 1 
                	if mv_par04 = 1 
                		li := 80 // se opcao analitica - quebra pagina por vendedor
					endif                		
				else
				    @ li, 000 PSAY REPLICATE("-",218)
					li:=li+1            	
                endif	
                
                _aTotVend [1] := 0
                _aTotVend [2] := 0
                _aTotVend [3] := 0
                _aTotVend [4] := 0
             	_aTotVend [5] := 0
                _aTotVend [6] := 0
                _aTotVend [7] := 0
                _aTotVend [8] := 0
             
           Endif
		   
	   	   IF _vendAnt = "" .or. _vendAnt != (_sAliasQ) -> VENDEDOR
                if mv_par05 = 1
            		If li>58
                		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
            		Endif
            		dbSelectArea("SA3")
            		dbSeek( (_sAliasQ) -> FILIAL + (_sAliasQ) -> VENDEDOR)
            		@li, 00 PSAY (_sAliasQ) -> VENDEDOR
            		@li, 07 PSAY (_sAliasQ) -> NOM_VEND
            		li ++ 
            		li ++
            		dbSelectArea("SE3")
            	endif
            	
            	_vendAnt := (_sAliasQ) -> VENDEDOR
            	_vendAntnome := (_sAliasQ) -> NOM_VEND
       		EndIF

			w_recebido = (_sAliasQ) -> VLR_RECEBIDO - (_sAliasQ) -> VLR_JUROS
			w_saldo    = (_sAliasQ) -> VLR_ORIGINAL - ( (_sAliasQ) -> VLR_RECEBIDO + (_sAliasQ) -> VLR_DESCONTO + (_sAliasQ) -> VLR_COMP)
			
	        if w_recebido >  0
	           	w_baseCom := U_baseCom((_sAliasQ) -> FILIAL, (_sAliasQ) -> CLIENTE, (_sAliasQ) -> LOJA, (_sAliasQ) -> PREFIXO, (_sAliasQ) -> NUMERO, (_sAliasQ) -> PARCELA, (_sAliasQ) -> VLR_ORIGINAL, w_recebido, (_sAliasQ) -> BASECOM) // ROUND( w_recebido * (_sAliasQ) -> BASECOM / (_sAliasQ) -> VLR_ORIGINAL , 2)
	           	w_paga    := w_baseCom * (_sAliasQ) -> PERC_COM /100
	        else
	         	w_paga    := 0
	        endif
	        
	        if w_saldo > 0
	        	w_baseCom  := U_baseCom((_sAliasQ) -> FILIAL, (_sAliasQ) -> CLIENTE, (_sAliasQ) -> LOJA, (_sAliasQ) -> PREFIXO, (_sAliasQ) -> NUMERO, (_sAliasQ) -> PARCELA, (_sAliasQ) -> VLR_ORIGINAL, w_saldo, (_sAliasQ) -> BASECOM) // ROUND( w_saldo * (_sAliasQ) -> BASECOM / (_sAliasQ) -> VLR_ORIGINAL , 2)	        	
	           	w_pagar    := w_baseCom * (_sAliasQ) -> PERC_COM /100
	        else
	           	w_pagar :=0
	        endif	
	           	
			if mv_par05 = 1           
	           	If li>58
	               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	           	Endif
	           	
	           	@li,  00 PSAY (_sAliasQ) -> PREFIXO
	           	@li,  04 PSAY (_sAliasQ) -> NUMERO
	           	@li,  14 PSAY (_sAliasQ) -> PARCELA
	           	@li,  25 PSAY (_sAliasQ) -> VLR_ORIGINAL Picture "@E 9,999,999.99"
	           	@li,  43 PSAY w_recebido                 Picture "@E 9,999,999.99"
	           	@li,  60 PSAY (_sAliasQ) -> VLR_DESCONTO Picture "@E 9,999,999.99"
	           	@li,  78 PSAY (_sAliasQ) -> VLR_COMP     Picture "@E 9,999,999.99"
	           	@li,  96 PSAY w_saldo                    Picture "@E 9,999,999.99"
	           	@li, 115 PSAY w_BaseCom					 Picture "@E 9,999,999.99"
	           	@li, 130 PSAY (_sAliasQ) -> PERC_COM     Picture "@E 99.99"
	           	@li, 139 PSAY w_paga  Picture "@E 9,999,999.99"
	           	@li, 162 PSAY w_pagar Picture "@E 9,999,999.99"			          		
	           	li ++
	        endif   
	        // acumula totais
           _aTotVend [1] += (_sAliasQ) -> VLR_ORIGINAL
           _aTotVend [2] += w_recebido
           _aTotVend [3] += (_sAliasQ) -> VLR_DESCONTO
           _aTotVend [4] += (_sAliasQ) -> VLR_COMP
           _aTotVend [5] += w_saldo
           _aTotVend [6] += w_paga
           _aTotVend [7] += w_pagar
           _aTotVend [8] += w_BaseCom
           
           _aTotGer [1] += (_sAliasQ) -> VLR_ORIGINAL
           _aTotGer [2] += w_recebido
           _aTotGer [3] += (_sAliasQ) -> VLR_DESCONTO
           _aTotGer [4] += (_sAliasQ) -> VLR_COMP
           _aTotGer [5] += w_saldo
           _aTotGer [6] += w_paga
           _aTotGer [7] += w_pagar
           _aTotGer [8] += w_BaseCom
                           
           (_sAliasQ) -> (dbskip())
     enddo
     
     if _aTotVend [1] > 0
        // imprime totais do vendedor
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        if mv_par05 = 1
        	@ li, 00 PSAY "TOTAL DO VENDEDOR --> "
		else
			@ li, 00 PSAY _vendAnt + ' - ' + _vendAntnome
		endif

		@ li,  25+wcol PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
        @ li,  43+wcol PSAY _aTotVend [2]  Picture "@E 9,999,999.99"
		@ li,  60+wcol PSAY _aTotVend [3]  Picture "@E 9,999,999.99"
        @ li,  78+wcol PSAY _aTotVend [4]  Picture "@E 9,999,999.99"
		@ li,  96+wcol PSAY _aTotVend [5]  Picture "@E 9,999,999.99"
		@ li, 115+wcol PSAY _aTotVend [8]  Picture "@E 9,999,999.99"
		@ li, 139+wcol PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
        @ li, 162+wcol PSAY _aTotVend [7]  Picture "@E 9,999,999.99"
        li++
        if mv_par05 = 1 
        	if mv_par04 = 1
           		li := 80 // na opcao analitica - quebra pagina por vendedor
			endif  
		else
			@ li, 000 PSAY REPLICATE("-",218)
			li:=li+1				         		
        endif	
    Endif
 
 
 	if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li,  00 PSAY "TOTAL GERAL --> "
		@ li, 23+wcol PSAY _aTotGer [1]  Picture "@E 999,999,999.99"
       	@ li, 41+wcol PSAY _aTotGer [2]  Picture "@E 999,999,999.99"
       	@ li, 58+wcol PSAY _aTotGer [3]  Picture "@E 999,999,999.99"
       	@ li, 76+wcol PSAY _aTotGer [4]  Picture "@E 999,999,999.99"
       	@ li, 94+wcol PSAY _aTotGer [5]  Picture "@E 999,999,999.99"
       	@ li,113+wcol PSAY _aTotGer [8]  Picture "@E 999,999,999.99"
       	@ li,137+wcol PSAY _aTotGer [6]  Picture "@E 999,999,999.99"
       	@ li,160+wcol PSAY _aTotGer [7]  Picture "@E 999,999,999.99"
       	
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

User Function baseCom (_wfilial, _wcliente, _wloja, _wpref, _wnumero, _wparcela, _wvlrtotal, _wvalor, _wbaseE1)
	_basePrev := _wbaseE1
	_wparcST  := 0
    // busca dados da nota
    _sQuery := ""
	_sQuery += " SELECT F2_VALBRUT  AS TOTAL_NF"
	_sQuery += "      , F2_VALIPI   AS IPI_NF"
	_sQuery += "      , F2_ICMSRET  AS ST_NF"
	_sQuery += " 	  , (SELECT ROUND(SUM(D2_TOTAL),2)
    _sQuery += "           FROM SD2010 AS SD2
    _sQuery += "       			INNER JOIN SF4010 AS SF4
    _sQuery += "						ON (SF4.D_E_L_E_T_ = ''
	_sQuery += "							AND SF4.F4_CODIGO   = SD2.D2_TES
    _sQuery += "							AND SF4.F4_MARGEM   = '3') 
    _sQuery += "   		  WHERE SD2.D2_FILIAL  = SF2.F2_FILIAL"
    _sQuery += "     		AND SD2.D2_DOC     = SF2.F2_DOC"
    _sQuery += "     		AND SD2.D2_SERIE   = SF2.F2_SERIE"
    _sQuery += "     		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE"
    _sQuery += "     		AND SD2.D2_LOJA    = SF2.F2_LOJA"
    _sQuery += "     		AND SD2.D2_EMISSAO = SF2.F2_EMISSAO"
    _sQuery += "  		 GROUP BY SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE) AS VLR_BONIFIC"
    _sQuery += "      , F2_FRETE AS FRETE_NF"
    _sQuery += "   FROM " +  RetSQLName ("SF2") + " AS SF2 "
	_sQuery += "  WHERE SF2.F2_FILIAL   = '" + _wfilial + "'"
	_sQuery += "    AND SF2.D_E_L_E_T_  = ''"
	_sQuery += "    AND SF2.F2_DOC      = '" + _wnumero + "'"
	_sQuery += "    AND SF2.F2_SERIE    = '" + _wpref + "'"
	_sQuery += "    AND SF2.F2_CLIENTE  = '" + _wcliente + "'"
	_sQuery += "    AND SF2.F2_LOJA     = '" + _wloja + "'"
	
	_Nota := U_Qry2Array(_sQuery)
    If len(_Nota) > 0
    	_brutoNota  = _Nota[1,1]
    	_baseNota   = _Nota[1,1] - _Nota[1,2] - _Nota[1,3] - _Nota[1,4] - _Nota[1,5]
    	
    	// se tem ST referenciada na nota - verifica se existi titulo sem separado para pagamento da mesma.
    	if _Nota[1,3] > 0
           	// verifica se a nota tem parcela separada de ST
			_sSQL := ""
		    _sSQL += " SELECT E1_VALOR"
		   	_sSQL += "   FROM " + RetSQLName ("SE1") + " AS SE1A " 
		   	_sSQL += "  WHERE SE1A.E1_FILIAL  = '" + _wfilial + "'"
		   	_sSQL += "    AND SE1A.E1_PREFIXO = '" + _wpref + "'"
		   	_sSQL += "    AND SE1A.E1_NUM     = '" + _wnumero + "'"
		   	_sSQL += "    AND SE1A.E1_PARCELA = 'A' "
		   	_sSQL += "    AND SE1A.E1_NATUREZ = '110199' "
		   	_sSQL += "    AND SE1A.D_E_L_E_T_ = ''"
   	
   			//u_showmemo (_sSQL)
    		_parcST := U_Qry2Array(_sSQL)
	    	If len(_parcST) > 0
	    		_wparcST = _parcST[1,1]
	    	Endif
	    endif
		// recalcula	    	
    	_basePrev = (_baseNota * _wvlrtotal) / (_brutoNota - _wparcST - _Nota[1,4] )
    endif
     _wbasecom = _basePrev
	_nNovaBase := ROUND(_wvalor * _wbasecom / _wvlrtotal , 2)		

return _nNovaBase

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Posicao em                   ?", "D", 8, 0,  "",   "   ", {}                     , ""})
    aadd (_aRegsPerg, {02, "Representante de             ?", "C", 3, 0,  "",   "SA3", {}                     , "Representante Inicial"})
    aadd (_aRegsPerg, {03, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {}                     , "Representante Final"})
    aadd (_aRegsPerg, {04, "Nova pagina p/Representante  ?", "S", 1, 0,  "",   "   ", {"Sim", "Nao"}         , ""})
    aadd (_aRegsPerg, {05, "Opção                        ?", "N", 1, 0,  "",   "   ", {"Anatica","Sintetica"}, ""})
    aadd (_aRegsPerg, {06, "Filial de                    ?", "C", 2, 0,  "",   "SM0", {},                      ""})
    aadd (_aRegsPerg, {07, "Filial até                   ?", "C", 2, 0,  "",   "SM0", {},                      ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
