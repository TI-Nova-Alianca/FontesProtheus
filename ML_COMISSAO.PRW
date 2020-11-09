//  Programa...: ML_COMISSAO
//  Autor......: Catia Cardoso
//  Data.......: 07/11/2014
//  Cliente....: Alianca
//  Descricao..: Relatório de Comissoes
//
//  Historico de alteracoes:
//  28/11/2014 - Catia   - Criada opcao analistica ou sintetica       - mv_par07
//  28/11/2014 - Catia   - Criada opcao razao social ou nome reduzido - mv_par06
//  28/11/2014 - Catia   - Criada opcao razao social ou nome reduzido - mv_par06
//  02/12/2014 - Catia   - Imprimir **** quando situacao de erro de a base de comissao liberada ser maior que o valor do titulo          
//  07/01/2015 - Catia   - Buscar os descontos e compensacoes totais do mes para o titulo (deve ter apenas um registro por titulo)
//  29/01/2015 - Catia   - tratamento para rep. que sao optantes do simples nacional - nao fazer retenção IR - A2_SIMPNAC 
//  19/02/2015 - Catia   - incluida coluna referente a bonificacoes que baixam a base de comissao da nota
//  20/02/2015 - Catia   - alguns titulos nao listavam pq nao encontrava o registro SF2
//  04/03/2015 - Catia   - separados os valores de estorno de compensacao do valor do estorno de pagamentos
//  17/03/2015 - Catia   - erro na opcao sintetica
//  17/05/2015 - Catia   - desconsiderar o frete tambem na base da comissao F2_FRETE
//  16/06/2015 - Catia   - não imprimia o ultimo vendedor na opcao sintetica
//  22/08/2015 - Catia   - alterado para que imprima total geral na opcao sintetica
//  15/09/2015 - Catia   - estava imprimindo o tipo da indenizacao errada para alguns representantes
//  21/09/2015 - Catia   - opção de enviar email - cria um PDF e envia por email para o representante
//  23/09/2015 - Catia   - opção analitica - alterado para que imprima os dados de pagamento
//  02/10/2015 - Catia   - funcao para buscar o nome dos bancos sem ser pela tabela do SA6
//  05/10/2015 - Catia   - envio por email representantes filial 13 mandava de todos os representantes novamente
//  04/11/2015 - Catia   - desconsiderar vendedor 240
//  12/01/2016 - Catia   - tratamento para os RA (recebimento antecipado)
//  02/08/2016 - Robert  - Alterado caminho de '\protheus11\' para '\protheus12\'
//  13/09/2016 - Catia   - inibida impressao de totais da nota que estavam causando duvidas na analise do relatorio
//  19/10/2016 - Catia   - Alterado teste de vendedores diretos por parametro $GETMV("MV_VENDDIR")
//  27/10/2016 - Catia   - Criada opcao de imprimir aberta por itens
//  28/10/2016 - Catia   - Criado quadrinho para dados da indenização
//  05/12/2016 - Catia   - alterado o email para envio dos emails de comissoes
//  10/05/2017 - Catia   - IR de indenização - alterado para que imprima so se o representante nao for do simples... mesma regra do IR normal 
//  08/08/2017 - Catia   - alterar para que não apareçam os vendedores inativos/bloqueados
//  16/08/2017 - Catia   - na opcao de impressao das comissoes pagas por email aos representantes - incluido o recibo da indenizacao se indenizacao paga
//  15/10/2018 - Catia   - total geral na opcao sintetica nao estava imprimindo corretamente
//  08/03/2019 - Catia   - acessar o SE5 com a sequencia do SE3, no caso de mais de um desconto no mesmo titulo que estava listando sempre o valor somado
//  03/04/2019 - Catia   - estava dando erro na variavel _SIMPLES na linha 915
//  12/06/2019 - Catia   - incluido na impressao dos dados bancarios o digito verificador na agencia e conta
//  13/06/2019 - Catia   - esqueci um u_showmemo aberto
//  18/11/2019 - Andre   - Adicionado validação para que e-mails sejam enviados para vendedores ativos.
//						 - Removi e-mail da Catia no envio do relatorio.
//  02/12/2019 - Robert  - Declaradas variaveis locais para for...next - tratamentp para mensagem [For variable is not Local]
//  10/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Parametro em Looping (criada sub rotina para a busca do parametro)
//
// ---------------------------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include 'fivewin.ch'
#include 'topconn.ch'
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_COMISSAO()
    cString := "SE3"
    cDesc1  := "Relatório de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_COMISSAO"
    wnrel   := "ML_COMISSAO"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    
    	titulo  := "Relatório de Comissões " + iif (mv_par05 = 1 , 'Liberadas', 'Pagas') + ' - ' + iif (mv_par07 = 1 , 'Opção Analítica', 'Opção Sintética')
    
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo ,cDesc1,cDesc2,cDesc3,.F.,"",,tamanho)
    	If nLastKey == 27
       		Return
    	Endif
    
    	SetDefault(aReturn,cString)
    	If nLastKey == 27
       		Return
    	Endif
    	
		if mv_par07 = 3  // se opcao email - executa rotina em separa para leitura da query
			if ! u_zzuvl ('046', __cUserId, .T.)
				return
			else
				if mv_par05 != 2
					msgalert("Só é possível enviar por email, se as comissoes ja estiverem geradas no financeiro.")
					return
				else									
					_GeraPDF_Email() // gera PDF e manda por email	
				endif													
			endif
		else
    		RptStatus({|| RptDetail()}) // relatorio normal
		endif    		
	endif
	
return
// ---------------------------------------------------------------------------------
//
Static Function RptDetail()
	local i := 0
	local _aVerbOut := {}
	local _nVerbOut := 0
	local _oSQL     := NIL

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
    cabec1:="PRF NUMERO PARC  CLIENTE                                 TOTAL NOTA TOTAL IPI   TOTAL ST   BONIFIC     FRETE   BASE COMISSAO  DATA        NUMERO         VALOR     DESCONTOS       VALOR  BASE COMISSAO   %          VALOR"
    cabec2:="    TITULO                                                                                                     PREVISTA NOTA  PAGTO       PEDIDO        TITULO    CONCEDIDOS    RECEBIDO   * LIBERADA *           COMISSAO"

	_sQuery := ""
	_ExeQuery()
 	
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0,0,0,0,0,0,0,0,0,0}
    _aTotGer  = {0,0,0,0,0,0,0,0,0,0,0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     _vendAnt     := ""
     _vendAntnome := ""
     
     Do While ! (_sAliasQ) -> (Eof ())
     	   IF _vendAnt != "" .and. _vendAnt != (_sAliasQ) -> VENDEDOR
                // imprime totais do vendedor
                If li>65
                    cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
                Endif        
                li++
                
                @ li, 00 PSAY "TOTAL DO VENDEDOR --> "
                if mv_par07 = 2 // sintetica - imprime linha de separacao
                	@ li, 26 PSAY _vendAnt
                	@ li, 35 PSAY _vendAntnome
                endif
                if mv_par07 = 1
                	@ li, 146 PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
        			@ li, 160 PSAY _aTotVend [7]  Picture "@E 9,999,999.99"
					@ li, 171 PSAY _aTotVend [8]  Picture "@E 9,999,999.99"					
				endif 
        		@ li, 185 PSAY _aTotVend [9]  Picture "@E 9,999,999.99"
        		@ li, 205 PSAY _aTotVend [10] Picture "@E 9,999,999.99"
        		li++
        		
                // so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
                _vlrIR := 0
                if _simples != '1' // 1=SIM
                	_vlrIR = ROUND(_aTotVend [10] * 1.5 /100 , 2)
                	if _vlrIR > 10
                    	@ li, 00  PSAY "TOTAL DO IR           --> "
                    	@ li, 206 PSAY _vlrIR Picture "@E 9,999,999.99"
                    	li ++
                    	@ li, 00  PSAY "TOTAL (-) IR          --> "
                    	@ li, 206 PSAY _aTotVend [10] - _vlrIR Picture "@E 9,999,999.99"
                    	li ++
                    else
                    	_vlrIR := 0	
                	endif
				endif
				_aTotGer [10] += _vlrIR
				
				// tratamento para indenizacao
				_windeniz = ROUND(_aTotVend [10] /12 , 2)
				li ++
				
                @ li, 00  PSAY "VLR INDENIZAÇÃO 1/12 " + IIF (_TPINDENIZ ='S', 'PAGA', 'PROVISIONADA')
                @ li, 206 PSAY _windeniz Picture "@E 9,999,999.99"
                li ++
                _vIRind := 0
                if _TPINDENIZ ='S' 
                	if _simples != '1' // 1=SIM
	                	_vIRind = ROUND(_windeniz * 15 /100 , 2)
	                	if _vIRind > 10
	                    	@ li, 00  PSAY "TOTAL DO IR (INDENIZ) --> "
	                    	@ li, 206 PSAY _vIRind Picture "@E 9,999,999.99"
	                    	li ++
	                    	@ li, 00  PSAY "TOTAL INDENIZ (-) IR  --> "                    	
	                    	@ li, 206 PSAY _windeniz - _vIRind Picture "@E 9,999,999.99"
	                    	li ++
	                    else
	                     	_vIRind := 0
						endif
					endif
					_aTotGer [8]  += _windeniz - _vIRind  // total indenizacao paga
					_aTotGer [11] += _vIRind // total IR sobre indenizacao					                    	
				else
					_aTotGer [7]  += _windeniz  // total indenizacao provisionada
				endif                	
                
                if mv_par07 = 2 // sintetica - imprime linha de separacao
                	@ li, 000 PSAY REPLICATE("-",218)
				   	li ++
                else
                	// buscar nome do banco
                	_wbanco := '' 
                	do case
                		case _banco = '001'
                			_wbanco := "BANCO DO BRASIL"		
                		case _banco = '041'
                			_wbanco := "BANRISUL"
                		case _banco = '748'
                			_wbanco := "SICREDI"
                		case _banco = '237'
                			_wbanco := "BRADESCO"
                		case _banco = '341'
                			_wbanco := "ITAU"
                		case _banco = '104'
                			_wbanco := "CAIXA FEDERAL"
                		case _banco = '746'
                			_wbanco := "SICOOB"
                	endcase
                	// imprime dados do pagamento
                	@ li, 150 PSAY "*** DADOS DO PAGAMENTO"
                	li ++
                	@ li, 150 PSAY 'BANCO  : ' + _BANCO + ' - ' + _wbanco
                	li ++
                	@ li, 150 PSAY 'AGENCIA: ' + _AGENCIA 
                	li ++
                	@ li, 150 PSAY 'CONTA  : ' + _CONTA
                	li ++
                	li := 80 // analitica - quebra pagina por vendedor
                endif	
                
                _aTotVend [6]  := 0
                _aTotVend [7]  := 0
                _aTotVend [8]  := 0
                _aTotVend [9]  := 0
                _aTotVend [10] := 0
                _aTotVend [11] := 0
                
           Endif

	   	   IF _vendAnt = "" .or. _vendAnt != (_sAliasQ) -> VENDEDOR
	   			if mv_par07 = 1
            		If li>65
                		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
            		Endif
            		dbSelectArea("SA3")
            		dbSeek(xFilial() + (_sAliasQ) -> VENDEDOR)
            		@li, 00 PSAY (_sAliasQ) -> VENDEDOR
            		@li, 07 PSAY (_sAliasQ) -> NOM_VEND
            		li ++ 
            		li ++
            		dbSelectArea("SE3")
            	endif
            	
            	_vendAnt     := (_sAliasQ) -> VENDEDOR
            	_vendAntnome := (_sAliasQ) -> NOM_VEND
            	
            	_TPINDENIZ := (_sAliasQ) -> INDENIZ
           		_simples   := (_sAliasQ) -> SIMPLES
           
       	   EndIF

           if mv_par07 = 1
           		_BANCO     = (_sAliasQ) -> BANCO
	       		_AGENCIA   = (_sAliasQ) -> AGENCIA
	       		_CONTA     = (_sAliasQ) -> CONTA
		   endif
		   
           if mv_par07 = 1
           		If li>65
                	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           		Endif
           
           		@li, 00 PSAY (_sAliasQ) -> PREFIXO
           		@li, 04 PSAY (_sAliasQ) -> NUMERO
           		@li, 14 PSAY (_sAliasQ) -> PARCELA
           		
      			if mv_par06 = 2  
           			_wnomecli := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NREDUZ")
           		else
           			_wnomecli := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NOME")
           		endif
           		
           		if (_sAliasQ) -> BASE_COMIS > (_sAliasQ) -> VALOR_TIT //.OR. (_sAliasQ) -> BASE_TIT > (_sAliasQ) -> VALOR_TIT 
           			_wnomecli = '***************************'
           		endif	
           
           		@li, 18 PSAY left(_wnomecli,35)
           		@li, 55 PSAY (_sAliasQ) -> TOTAL_NF     Picture "@E 9,999,999.99"
           		@li, 68 PSAY (_sAliasQ) -> IPI_NF       Picture "@E 99,999.99"
           		@li, 79 PSAY (_sAliasQ) -> ST_NF        Picture "@E 99,999.99"
           		_wvlrdesc_nota = (_sAliasQ) -> BONIF_NF
        		@li, 89 PSAY  _wvlrdesc_nota Picture "@E 99,999.99"
        		@li, 101 PSAY (_sAliasQ) -> FRETE_NF    Picture "@E 99,999.99"
           		_wbasenota = (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF  - (_sAliasQ) -> ST_NF - (_sAliasQ) -> FRETE_NF - _wvlrdesc_nota 
           		@li, 112  PSAY _wbasenota                Picture "@E 9,999,999.99"
           		@li, 126 PSAY stod((_sAliasQ) -> DT_COMIS)
           		@li, 138 PSAY (_sAliasQ) -> PEDIDO
           		@li, 146 PSAY (_sAliasQ) -> VALOR_TIT    Picture "@E 9,999,999.99"
           		
           		_vlrdesconto := (_sAliasQ) -> VLR_DESCONTO - (_sAliasQ) -> VLR_CP_ESTORNADO
           		@li, 160 PSAY _vlrdesconto Picture "@E 9,999,999.99"
           		
           		_vlrrecebido := (_sAliasQ) -> VLR_RECEBIDO - ((_sAliasQ) -> VLR_PG_ESTORNADO + (_sAliasQ) -> VLR_JUROS)
           		@li, 171 PSAY _vlrrecebido Picture "@E 9,999,999.99"
           		@li, 185 PSAY (_sAliasQ) -> BASE_COMIS   Picture "@E 9,999,999.99"
           		if (_sAliasQ) -> BASE_COMIS > (_sAliasQ) -> VALOR_TIT 
           			@li, 199 PSAY '*'
           		endif
           		if mv_par08 = 1
           			@li, 200 PSAY (_sAliasQ) -> PERCENTUAL   Picture "@E 99.99"
				endif           			
           		@li, 208 PSAY (_sAliasQ) -> VLR_COMIS    Picture "@E 99,999.99"
           		li ++

				// Verifica se houve descontos no titulo atual referentes a verbas de outros representantes.
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += "SELECT ZA4_VEND, ZA5_NUM, SUM (ZA5_VLR)"
				_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZA5") + " ZA5, "
				_oSQL:_sQuery +=             RetSQLName ("ZA4") + " ZA4 "
				_oSQL:_sQuery += " WHERE ZA5.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZA5_FILIAL = '" + xfilial ("ZA5")       + "'"
				_oSQL:_sQuery +=   " AND ZA5_PREFIX = '" + (_sAliasQ) -> prefixo + "'"
				_oSQL:_sQuery +=   " AND ZA5_DOC    = '" + (_sAliasQ) -> numero  + "'"
				_oSQL:_sQuery +=   " AND ZA5_PARC   = '" + (_sAliasQ) -> parcela + "'"
				_oSQL:_sQuery +=   " AND ZA5_TIPO   = '" + (_sAliasQ) -> e3_tipo + "'"
				_oSQL:_sQuery +=   " AND ZA5_CLI    = '" + (_sAliasQ) -> codcli  + "'"
				_oSQL:_sQuery +=   " AND ZA5_LOJA   = '" + (_sAliasQ) -> loja    + "'"
				_oSQL:_sQuery +=   " AND ZA4.D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=   " AND ZA4_FILIAL = '" + xfilial ("ZA4") + "'"
				_oSQL:_sQuery +=   " AND ZA4_NUM    = ZA5_NUM"
				_oSQL:_sQuery +=   " AND ZA4_VEND  != ''"
				_oSQL:_sQuery +=   " AND ZA4_VEND  != '" + (_sAliasQ) -> vendedor + "'"
				_oSQL:_sQuery += " GROUP BY ZA4_VEND, ZA5_NUM"
			//	_oSQL:Log ()
				_aVerbOut = aclone (_oSQL:Qry2Array ())

		   else
				_vlrrecebido := 0		              		
		   endif           		
           
           // acumula total
           if mv_par07 = 1
           		_aTotVend [6]  += (_sAliasQ) -> VALOR_TIT
           		_aTotVend [7]  += _vlrdesconto
           		_aTotVend [8]  +=  _vlrrecebido
           		_aTotVend [11]  += (_sAliasQ) -> FRETE_NF  
			endif           		
           
           _aTotVend [9]  += (_sAliasQ) -> BASE_COMIS
           _aTotVend [10] += (_sAliasQ) -> VLR_COMIS
           
           _aTotGer [9]  += (_sAliasQ) -> VLR_COMIS

			// imprime ITENS
			if mv_par08 = 2 .and. mv_par07 = 1
				_sQuery := "" 
				_sQuery += " SELECT SD2.D2_COD, SB1.B1_DESC, SD2.D2_COMIS1, SD2.D2_TOTAL"
  				_sQuery += "   FROM SD2010 AS SD2"
				_sQuery += " 	   INNER JOIN SB1010 AS SB1"
				_sQuery += " 		  ON (SB1.D_E_L_E_T_ = ''"
				_sQuery += " 			  AND SB1.B1_COD = SD2.D2_COD)"
 				_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"
 				_sQuery += "    AND SD2.D2_FILIAL  = '" + (_sAliasQ) -> FILIAL + "'"
   				_sQuery += "    AND SD2.D2_DOC     = '" + (_sAliasQ) -> NUMERO + "'"  
   				_sQuery += "    AND SD2.D2_SERIE   = '" + (_sAliasQ) -> PREFIXO + "'"
   				_sQuery += " ORDER BY SD2.D2_COD"
				
				_aDados := U_Qry2Array(_sQuery)
     
    			if len (_aDados) > 0
    				_wbasearred := (_sAliasQ) -> BASE_COMIS
    				_wvlrarred  := (_sAliasQ) -> VLR_COMIS
    				for i=1 to len(_aDados)
    					_wcodprod    = _aDados[i,1]
    					_wdesprod    = _aDados[i,2]
    					_wpercomitem = _aDados[i,3]
    					_wvlritem    = _aDados[i,4]
    			
	    				If li>65
	                		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	           			Endif
	           			
	    				@ li, 23  PSAY alltrim(_wcodprod)
						@ li, 30  PSAY LEFT(_wdesprod,50)
						@ li, 112 PSAY _wvlritem Picture "@E 9,999,999.99"
						_wlibitem =  ROUND(_wvlritem * (_sAliasQ) -> BASE_COMIS / _wbasenota,2)
						// ajusta diferença centavos no ultimo item - BASE COMISSAO LIBERADA
						_wbasearred = _wbasearred - _wlibitem
						if i = len(_aDados).and. _wbasearred <> _wlibitem
							_wlibitem = _wlibitem + _wbasearred
						endif
						@ li, 186 PSAY _wlibitem Picture "@E 9,999,999.99"
						@ li, 201 PSAY _wpercomitem   Picture "@E 99.99"
						_wcomitem = ROUND(_wlibitem * _wpercomitem /100,2)
						// ajusta diferença centavos no ultimo item - VALOR COMISSAO
						_wvlrarred = _wvlrarred - _wcomitem 
						if i = len(_aDados) .and. _wvlrarred <> _wcomitem 
							_wcomitem = _wcomitem + _wvlrarred 	
						endif
						@ li, 209 PSAY _wcomitem Picture "@E 99,999.99"
						li++
					next
				endif					
				
			endif

			// Ainda nao liberado em producao
			if 'ROBERT' $ upper (GetEnvServer ())
				if len (_aVerbOut) > 0
					@ li, 0 psay 'Verbas descontadas em titulos de outros vendedores:'
					li ++
					for _nVerbOut = 1 to len (_aVerbOut)
						@ li, 0 psay _aVerbOut [_nVerbOut, 1]
						li ++
					next
				endif
			endif
			        		
           (_sAliasQ) -> (dbskip())
     enddo
       	 
     if _aTotVend [10] > 0
        // imprime totais do vendedor
        If li>65
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAL DO VENDEDOR --> "
        if mv_par07 = 2 // sintetica - imprime linha de separacao
        	@ li, 26 PSAY _vendAnt
        	@ li, 35 PSAY _vendAntnome
		endif      
		
		if mv_par07 = 1
    		@ li, 146 PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
        	@ li, 160 PSAY _aTotVend [7]  Picture "@E 9,999,999.99"
			@ li, 171 PSAY _aTotVend [8]  Picture "@E 9,999,999.99"
		endif 
		@ li, 185 PSAY _aTotVend [9]  Picture "@E 9,999,999.99"
		@ li, 205 PSAY _aTotVend [10] Picture "@E 9,999,999.99"
		li++
        // so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
        _vlrIR := 0
        if _simples != '1' // 1=SIM
        	_vlrIR = ROUND(_aTotVend [10] * 1.5 /100 , 2)
        	if _vlrIR > 10
            	@ li, 00  PSAY "TOTAL DO IR           --> "
            	@ li, 206 PSAY _vlrIR Picture "@E 9,999,999.99"
            	li ++
            	@ li, 00  PSAY "TOTAL (-) IR          --> "
            	@ li, 206 PSAY _aTotVend [10] - _vlrIR Picture "@E 9,999,999.99"
            	li ++
			else
				_vlrIR = 0            	
			endif            	
        endif
        _aTotGer [10] += _vlrIR
        // tratamento para indenizacao
		_windeniz = ROUND(_aTotVend [10] /12 , 2)
		li ++
		@ li, 00  PSAY "VLR INDENIZAÇÃO 1/12 " + IIF (_TPINDENIZ ='S', 'PAGA', 'PROVISIONADA')
        @ li, 206 PSAY _windeniz Picture "@E 9,999,999.99"
        li ++
        if _TPINDENIZ ='S' 
        	_vIRind := 0
            if _simples != '1'
            	_vIRind = ROUND(_windeniz * 15 /100 , 2)
				if _vIRind > 10
					@ li, 00  PSAY "TOTAL DO IR (INDENIZ) --> "
					@ li, 206 PSAY _vIRind Picture "@E 9,999,999.99"
					li ++
					@ li, 00  PSAY "TOTAL INDENIZ (-) IR  --> "                    	
					@ li, 206 PSAY _windeniz - _vIRind Picture "@E 9,999,999.99"
					li ++
				else
					_vIRind := 0
				endif
            endif
			_aTotGer [8]  += _windeniz - _vIRind  // total indenizacao paga
			_aTotGer [11] += _vIRind // total IR sobre indenizacao					                    	
		else
			_aTotGer [7]  += _windeniz  // total indenizacao provisionada
		endif
		        
        if mv_par07 = 2 // sintetica - imprime linha de separacao
          	@ li, 000 PSAY REPLICATE("-",218)
		   	li ++
        else
        	// buscar nome do banco
            _wbanco := '' 
            do case
        		case _banco = '001'
        			_wbanco := "BANCO DO BRASIL"		
        		case _banco = '041'
        			_wbanco := "BANRISUL"
        		case _banco = '748'
        			_wbanco := "SICREDI"
        		case _banco = '237'
        			_wbanco := "BRADESCO"
        		case _banco = '341'
        			_wbanco := "ITAU"
        		case _banco = '104'
        			_wbanco := "CAIXA FEDERAL"
        		case _banco = '746'
        			_wbanco := "SICOOB"
        	endcase        		
        	// imprime dados do pagamento
        	@ li, 150  PSAY "*** DADOS DO PAGAMENTO"
        	li ++
        	@ li, 150 PSAY 'BANCO  : ' + _BANCO  + ' - ' + _wbanco
        	li ++
        	@ li, 150 PSAY 'AGENCIA: ' + _AGENCIA 
        	li ++
        	@ li, 150 PSAY 'CONTA  : ' + _CONTA
        	li ++
           	li := 80 // analitica - quebra pagina por vendedor
        endif	
        
    Endif
    
    if _aTotGer [9] > 0
    	if mv_par07 = 1
    		li := 80 // na opcao analitica salta pagina e imprime o total geral na ultima pagina
    		If li>65
            	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        	Endif
		endif        	        	
        li++
        @ li, 100 PSAY "TOTAL GERAL COMISSAO                      ---> "
        @ li, 205 PSAY _aTotGer [9]  Picture "@E 99,999,999.99"
        li++
        @ li, 100 PSAY "TOTAL GERAL IR                            ---> " 
        @ li, 205 PSAY _aTotGer [10] Picture "@E 99,999,999.99"
        li++
        @ li, 100 PSAY "TOTAL GERAL LIQUIDO                       ---> " 
        @ li, 205 PSAY _aTotGer [9] - _aTotGer [10] Picture "@E 99,999,999.99"
    	li++
    	@ li, 100 PSAY "TOTAL GERAL INDENIZACAO 1/12 PAGA         ---> "
    	@ li, 205 PSAY _aTotGer [8] Picture "@E 99,999,999.99"
    	li++
    	@ li, 100 PSAY "TOTAL GERAL IR SOBRE INDENIZACAO 1/12 PAGA---> "
    	@ li, 205 PSAY _aTotGer [11] Picture "@E 99,999,999.99"
    	li++
    	@ li, 100 PSAY "TOTAL GERAL INDENIZACAO 1/12 PROVISIONADA ---> "
    	@ li, 205 PSAY _aTotGer [7] Picture "@E 99,999,999.99"
    	li:=li+1
    endif
 
     Set Device To Screen

     If aReturn[5]==1
           Set Printer TO
           dbcommitAll()
           ourspool(wnrel)
     Endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

Return
// -----------------------------------------------------------------------------
//
Static Function _ExeQuery()
	_sQuery := " "
    if mv_par07 = 1  // opcao analitica
    
    	_sQuery += " SELECT E3_BASE     AS BASE_COMIS"
    	_sQuery += "      , E3_COMIS    AS VLR_COMIS"
    	_sQuery += "      , E3_VEND     AS VENDEDOR"
    	_sQuery += "      , E3_PORC     AS PERCENTUAL"
    	_sQuery += "      , A3_NOME     AS NOM_VEND"
    	_sQuery += "      , A3_INDENIZ  AS INDENIZ"
    	_sQuery += "      , E3_PREFIXO  AS PREFIXO"
    	_sQuery += "      , E3_NUM      AS NUMERO" 
    	_sQuery += "      , E3_PARCELA  AS PARCELA"
    	_sQuery += "      , E3_CODCLI   AS CODCLI"
    	_sQuery += "      , E3_LOJA     AS LOJA"
    	_sQuery += "      , E3_PEDIDO   AS PEDIDO"
    	_sQuery += "      , E1_VENCTO   AS VENCIMENTO"
    	_sQuery += "      , E1_BAIXA    AS BAIXA"
    	_sQuery += "      , E1_VALOR    AS VALOR_TIT"
    	_sQuery += "      , E1_BASCOM1  AS BASE_TIT"
    	_sQuery += "      , E1_SALDO    AS SALDO"
    	_sQuery += "      , F2_VALBRUT  AS TOTAL_NF"
    	_sQuery += "      , F2_VALIPI   AS IPI_NF"
    	_sQuery += "      , F2_ICMSRET  AS ST_NF"
    	_sQuery += "      , F2_FRETE    AS FRETE_NF"
    	_sQuery += " 	  , (SELECT ROUND(SUM(D2_TOTAL),2) AS VLR_COM
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
    	_sQuery += "  		 GROUP BY SD2.D2_FILIAL, SD2.D2_DOC, SD2.D2_SERIE) AS BONIF_NF"
    	_sQuery += "      , ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
    	_sQuery += "                    FROM " + RetSQLName ("SE5") + " AS SE5 "
    	_sQuery += "                   WHERE E5_FILIAL = E3_FILIAL"
    	_sQuery += "                     AND D_E_L_E_T_ != '*'"
    	_sQuery += "                     AND E5_RECPAG = 'R'"
    	_sQuery += "                     AND E5_SITUACA != 'C'"
    	_sQuery += "                     AND E5_NUMERO = E3_NUM"
    	_sQuery += "                     AND (E5_TIPODOC = 'DC' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '% RA %'))"
    	_sQuery += "                     AND E5_PREFIXO = E3_PREFIXO"
    	_sQuery += "                     AND E5_PARCELA = E3_PARCELA"
    	_sQuery += "                     AND E5_SEQ     = E3_SEQ"
    	_sQuery += "                     AND E5_DATA BETWEEN '"+ dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    	_sQuery += "                  GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO),0)  AS VLR_DESCONTO"
    	_sQuery += "      , ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
    	_sQuery += "                    FROM " + RetSQLName ("SE5") + " AS SE5 "
    	_sQuery += "                   WHERE E5_FILIAL = E3_FILIAL"
    	_sQuery += "                     AND D_E_L_E_T_ != '*'"
    	_sQuery += "                     AND E5_RECPAG = 'R'"
    	_sQuery += "                     AND E5_NUMERO = E3_NUM"
    	_sQuery += "                     AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
    	_sQuery += "                     AND E5_PREFIXO = E3_PREFIXO"
    	_sQuery += "                     AND E5_PARCELA = E3_PARCELA"
    	_sQuery += "                     AND E5_SEQ     = E3_SEQ"
    	_sQuery += "                     AND E5_DATA BETWEEN '"+ dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    	_sQuery += "                  GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0) AS VLR_RECEBIDO"
    	_sQuery += "      , E3_EMISSAO   AS DT_COMIS"
    	_sQuery += "      , ISNULL (( SELECT ROUND(SUM(E5_VALOR),2)"
    	_sQuery += "                    FROM " + RetSQLName ("SE5") + " AS SE5 "
    	_sQuery += "                   WHERE E5_FILIAL = E3_FILIAL"
    	_sQuery += "                     AND D_E_L_E_T_ != '*'"
    	_sQuery += "                     AND E5_RECPAG = 'R'"
    	_sQuery += "                     AND E5_NUMERO = E3_NUM"
    	_sQuery += "                     AND E5_TIPODOC = 'JR'"
    	_sQuery += "                     AND E5_PREFIXO = E3_PREFIXO"
    	_sQuery += "                     AND E5_PARCELA = E3_PARCELA"
    	_sQuery += "                     AND E5_SEQ     = E3_SEQ"
    	_sQuery += "                     AND E5_DATA BETWEEN '"+ dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    	_sQuery += "                  GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0)  AS VLR_JUROS"
    	_sQuery += "     , ISNULL ( ( SELECT ROUND(SUM(E5_VALOR),2)"
    	_sQuery += "                    FROM " + RetSQLName ("SE5") + " AS SE5 "
    	_sQuery += "                   WHERE E5_FILIAL   = E3_FILIAL"
    	_sQuery += "                     AND D_E_L_E_T_ != '*'"
    	_sQuery += "                     AND E5_RECPAG   = 'P'"
    	_sQuery += "                     AND E5_NUMERO   = E3_NUM"
    	_sQuery += "                     AND E5_TIPODOC  = 'ES'"
    	_sQuery += "                     AND E5_MOTBX   != 'CMP'"
    	_sQuery += "                     AND E5_PREFIXO  = E3_PREFIXO"
    	_sQuery += "                     AND E5_PARCELA  = E3_PARCELA"
    	_sQuery += "                     AND E5_SEQ     = E3_SEQ"
    	_sQuery += "                     AND E5_DATA BETWEEN '"+ dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    	_sQuery += "                  GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0) AS VLR_PG_ESTORNADO"
    	_sQuery += "     , ISNULL ( ( SELECT ROUND(SUM(E5_VALOR),2)"
    	_sQuery += "                    FROM " + RetSQLName ("SE5") + " AS SE5 "
    	_sQuery += "                   WHERE E5_FILIAL   = E3_FILIAL"
    	_sQuery += "                     AND D_E_L_E_T_ != '*'"
    	_sQuery += "                     AND E5_RECPAG   = 'P'"
    	_sQuery += "                     AND E5_NUMERO   = E3_NUM"
    	_sQuery += "                     AND E5_TIPODOC  = 'ES'"
    	_sQuery += "                     AND E5_MOTBX    = 'CMP'"
    	_sQuery += "                     AND E5_PREFIXO  = E3_PREFIXO"
    	_sQuery += "                     AND E5_PARCELA  = E3_PARCELA"
    	_sQuery += "                     AND E5_SEQ     = E3_SEQ"
    	_sQuery += "                     AND E5_DATA BETWEEN '"+ dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    	_sQuery += "                  GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO ),0) AS VLR_CP_ESTORNADO"
    	_sQuery += "      , SA2.A2_SIMPNAC        AS SIMPLES"
    	_sQuery += "      , RTRIM(SA2.A2_BANCO)   AS BANCO"
	    _sQuery += "      , RTRIM(SA2.A2_AGENCIA) + '-' + RTRIM(SA2.A2_DVAGE) AS AGENCIA"
	    _sQuery += "      , RTRIM(SA2.A2_NUMCON)  + '-' + RTRIM(SA2.A2_DVCTA) AS CONTA"
	    _sQuery += "      , SF2.F2_FILIAL         AS FILIAL"
	    _sQuery += "      , SE3.E3_TIPO           AS E3_TIPO"
		_sQuery += "   FROM " + RetSQLName ("SE3") + " AS SE3 "
    	_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
    	_sQuery += "       ON (SA3.D_E_L_E_T_ = '' 
    	if mv_par09 = 1
    		_sQuery += "           AND SA3.A3_MSBLQL != '1'"
    		_sQuery += "           AND SA3.A3_ATIVO  != 'N'"
		endif    		
    	_sQuery += "           AND SA3.A3_COD     = SE3.E3_VEND)"
    	_sQuery += " INNER JOIN " + RetSQLName ("SE1") + " AS SE1 "
    	_sQuery += "   ON (SE1.D_E_L_E_T_ = ''" 
    	_sQuery += "       AND SE1.E1_FILIAL     = SE3.E3_FILIAL"
    	_sQuery += "       AND SE1.E1_NUM        = SE3.E3_NUM"
    	_sQuery += "       AND SE1.E1_PARCELA    = SE3.E3_PARCELA"
    	_sQuery += "       AND SE1.E1_PREFIXO    = SE3.E3_PREFIXO"
    	_sQuery += "       AND SE1.E1_TIPO       = SE3.E3_TIPO"
    	_sQuery += "       AND SE1.E1_CLIENTE    = SE3.E3_CODCLI)"
    	_sQuery +=  "LEFT JOIN " + RetSQLName ("SF2") + " AS SF2 "
    	_sQuery += "           ON (SF2.D_E_L_E_T_ = '' "
    	_sQuery += "               AND SF2.F2_DOC        = SE3.E3_NUM"
    	_sQuery += "               AND SF2.F2_SERIE      = SE3.E3_PREFIXO"
    	_sQuery += "               AND SF2.F2_CLIENTE    = SE3.E3_CODCLI"
    	_sQuery += "               AND SF2.F2_LOJA       = SE3.E3_LOJA)"
    	_sQuery += " LEFT JOIN " + RetSQLName ("SA2") + " AS SA2 "
    	_sQuery += "           ON (SA2.D_E_L_E_T_ = '' "
    	_sQuery += "               AND SA2.A2_COD        = SA3.A3_FORNECE"
    	_sQuery += "               AND SA2.A2_LOJA       = SA3.A3_LOJA)"
	else  // opcao sintetica
	  	_sQuery += "SELECT SUM(E3_BASE)   AS BASE_COMIS"
        _sQuery += "     , SUM(E3_COMIS)  AS VLR_COMIS"
        _sQuery += "     , 0              AS VALOR_TIT"
        _sQuery += "     , E3_VEND        AS VENDEDOR"
        _sQuery += "     , A3_NOME        AS NOM_VEND"
        _sQuery += "     , A3_INDENIZ     AS INDENIZ"
        _sQuery += "     , A2_SIMPNAC     AS SIMPLES"
	    _sQuery += "     , 0              AS BASE_TIT"
        _sQuery += "     , 0              AS VLR_DESCONTO"
        _sQuery += "     , 0              AS VLR_RECEBIDO"
        _sQuery += "     , 0              AS VLR_JUROS"
        _sQuery += "     , 0              AS VLR_PG_ESTORNADO"
        _sQuery += "     , 0              AS VLR_CP_ESTORNADO"
        _sQuery += "  FROM " + RetSQLName ("SE3") + " AS SE3 "
   		_sQuery += " INNER JOIN  " + RetSQLName ("SA3") + " AS SA3 "
        _sQuery += "  	ON (SA3.D_E_L_E_T_ = ''
        _sQuery += "        AND SA3.A3_COD     = SE3.E3_VEND
        if mv_par09 = 1
        	_sQuery += "        AND SA3.A3_MSBLQL != '1'"
    		_sQuery += "        AND SA3.A3_ATIVO  != 'N' )"
		else    		
			_sQuery += " )"
    	endif
    	//_sQuery += " INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
    	_sQuery += " LEFT JOIN " + RetSQLName ("SA2") + " AS SA2 "
    	_sQuery += "    ON (SA2.D_E_L_E_T_ = '' "
    	_sQuery += "        AND SA2.A2_COD        = SA3.A3_FORNECE"
    	_sQuery += "        AND SA2.A2_LOJA       = SA3.A3_LOJA)"
    endif
    _sQuery += " WHERE E3_FILIAL  = '" + xFilial('SE3') + "' "    
    _sQuery += "   AND E3_VEND    BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
    _sQuery += "   AND E3_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "   AND E3_BAIEMI  = 'B'"
    _sQuery += "   AND SE3.D_E_L_E_T_ = '' "
    
    if mv_par05 = 1  // comissoes liberadas
        _sQuery += "   AND E3_DATA   = ''"
    else /// comissoes pagas
        _sQuery += "   AND E3_DATA   != ''"
    endif
 	
 	if mv_par07 = 1   // opcao analitica
    	_sQuery += "  ORDER BY E3_VEND, E3_NUM , E3_PARCELA"
    else	// opcao sintetica
  		_sQuery += "  GROUP BY E3_VEND, A3_NOME, A2_SIMPNAC, A3_INDENIZ"
   		_sQuery += "  ORDER BY E3_VEND"
   	endif
//   	nHandle := FCreate("c:\temp\com_velho.txt")
//	FWrite(nHandle,_sQuery )
//	FClose(nHandle)
Return
// -----------------------------------------------------------------------------
//
Static Function _GeraPDF_Email()
	local i := 0
	Private _oSQL        := ClsSQL():New ()
	Private oPrint       := TMSPrinter():New(OemToAnsi('Relatorio de Comissoes'))
	Private oBrush       := TBrush():New(,4)
	Private oPen         := TPen():New(0,5,CLR_BLACK)
	Private oFont12n     := TFont():New('Tahoma',12,12,,.T.,,,,.T.,.F.)
	Private oFont13      := TFont():New('Tahoma',13,13,,.T.,,,,.T.,.F.)
	Private oFont22      := TFont():New('Arial',22,22,,.T.,,,,.T.,.F.)
	Private nLinha       := 0
	
	_dMes := mesextenso(substr(dtos(mv_par01),5,2))
	// se nao existir a pasta cria e add ao _cPathPDF
	cDestino := "\comissoes\" + _dMes +'\'
	makedir (cDestino)
	_cPathPDF := "S:\Protheus12\protheus_data\comissoes\" + _dMes +'\'
	
	// verifica quais vendedores deseja enviar o relatorio por email
	_sQuery := ""
	_sQuery += " SELECT DISTINCT(SE3.E3_VEND) AS VENDEDOR"
	_sQuery += "      , SA3.A3_EMAIL          AS EMAIL"
	_sQuery += "      , SA3.A3_INDENIZ        AS INDENIZ"
	_sQuery += "      , SA2.A2_SIMPNAC        AS SIMPLES"
	_sQuery += "      , SE3.E3_DATA           AS DTPAG"
	_sQuery += "      , SA2.A2_BANCO          AS BANCO"
	_sQuery += "      , RTRIM(SA2.A2_AGENCIA) + '-' + RTRIM(SA2.A2_DVAGE) AS AGENCIA"
	_sQuery += "      , RTRIM(SA2.A2_NUMCON)  + '-' + RTRIM(SA2.A2_DVCTA) AS CONTA"
	_sQuery += "   FROM " + RetSQLName ("SE3") + " AS SE3 "
	_sQuery += "	  INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
	_sQuery += "		 ON (SA3.D_E_L_E_T_=''"
	//_sQuery += "             AND SA3.A3_ATIVO != 'N'"
	_sQuery += "			 AND SA3.A3_COD = SE3.E3_VEND)"
	_sQuery += " 	  INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
    _sQuery += "           ON (SA2.D_E_L_E_T_ = '' "
    _sQuery += "               AND SA2.A2_COD        = SA3.A3_FORNECE"
    _sQuery += "               AND SA2.A2_LOJA       = SA3.A3_LOJA)"
    _sQuery += "  WHERE SE3.D_E_L_E_T_ = ''"
    _sQuery += "    AND SE3.E3_FILIAL  = '" + xFilial('SE3') + "' "
    _sQuery += "    AND SE3.E3_VEND NOT IN " + FormatIn (alltrim (GetMv ('MV_VENDDIR')), '/') // desconsidera os vendedores diretos
    _sQuery += "    AND SE3.E3_VEND    BETWEEN '" + mv_par03 + "' and '" + mv_par04 + "'"
    _sQuery += "    AND SE3.E3_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"

	_sAliasVend = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasVend, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    // le arquivo de trabalho dos vendedores a gerar email
    (_sAliasVend) -> (DBGoTop ())
    Do While ! (_sAliasVend) -> (Eof ())
    
    	_simples   = (_sAliasVend) -> SIMPLES
        _TPINDENIZ = (_sAliasVend) -> INDENIZ
            
    	// ajusta parametros para geracao da query de dados
    	mv_par03 = (_sAliasVend) -> VENDEDOR 
    	mv_par04 = (_sAliasVend) -> VENDEDOR
    	mv_par07 = 1 // gera query igual a opcao analitica
    	
    	_cFile := "RelCom_" + ALLTRIM((_sAliasVend) -> VENDEDOR) //nome do arquivo padrão, deve ser alterado para não sobrescrever
    	delete file(cDestino + _cFile)
    	
    	// define objeto
		oPrint := FWMSPrinter():New(_cFile, IMP_PDF, .T., , .T.)
    	oPrint:SetResolution(72)
		oPrint:SetLandscape()
		oPrint:SetPaperSize(DMPAPER_A4)
		oPrint:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
		oPrint:cPathPDF := _cPathPDF // Caso seja utilizada impressão em IMP_PDF
    
    	_ExeQuery()
    	
    	nLinha   := 4000
    	_aTotVend = {0,0,0,0,0,0,0,0,0,0,0,0}
    	_wpag    := 0
    	
    	_sAliasQ = GetNextAlias ()
    	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    	// le arquivo de trabalho dos registro de comissao de cada vendedor
    	
    	if ! (_sAliasQ) -> (Eof ())
	    	(_sAliasQ) -> (DBGoTop ())
	     	Do While ! (_sAliasQ) -> (Eof ())
				// imprime cabeçalho
				If (nLinha/50) > 46
				   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
				   _wpag += 1	
	               xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	               nlinha := 600
	            Endif
	            
	            // variáveis auxiliares
				if mv_par06 = 2  
	           		_wnomecli  := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NREDUZ")
	           	else
	           		_wnomecli  := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NOME")
	           	endif
	           	_wvlrdesc_nota := (_sAliasQ) -> BONIF_NF
	           	_wbasenota     := (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF  - (_sAliasQ) -> ST_NF - (_sAliasQ) -> FRETE_NF - _wvlrdesc_nota
	        	_vlrdesconto   := (_sAliasQ) -> VLR_DESCONTO - (_sAliasQ) -> VLR_CP_ESTORNADO
	           	_vlrrecebido   := (_sAliasQ) -> VLR_RECEBIDO - ((_sAliasQ) -> VLR_PG_ESTORNADO + (_sAliasQ) -> VLR_JUROS)
	     		// monta linha para impressao
	     		oPrint:Say(nLinha,0045, (_sAliasQ) -> NUMERO	  	 				            ,oFont12n)
				oPrint:Say(nLinha,0195, (_sAliasQ) -> PARCELA 			  					    ,oFont12n)
	           	oPrint:Say(nLinha,0270, left(_wnomecli,35) 	 			  					    ,oFont12n)
	           	oPrint:Say(nLinha,0845, TransForm( (_sAliasQ) -> TOTAL_NF  , '@E 9,999,999.99') ,oFont12n)
	           	oPrint:Say(nLinha,1045, TransForm( _wbasenota              , '@E 9,999,999.99') ,oFont12n) 
				oPrint:Say(nLinha,1275, dtoc(stod( (_sAliasQ) -> DT_COMIS)) 			        ,oFont12n)
				oPrint:Say(nLinha,1465, (_sAliasQ) -> PEDIDO       		  					    ,oFont12n)
				oPrint:Say(nLinha,1645, TransForm( (_sAliasQ) -> VALOR_TIT ,   '@E 999,999.99') ,oFont12n)
	           	oPrint:Say(nLinha,1845, TransForm( _vlrdesconto            , '@E 9,999,999.99') ,oFont12n)
	           	oPrint:Say(nLinha,2045, TransForm( _vlrrecebido            , '@E 9,999,999.99') ,oFont12n)
	           	oPrint:Say(nLinha,2285, TransForm((_sAliasQ) -> BASE_COMIS , '@E 9,999,999.99') ,oFont12n)
	           	if mv_par08 = 1
	           		oPrint:Say(nLinha,2525, TransForm((_sAliasQ) -> PERCENTUAL ,   		'@E 99.99') ,oFont12n)
	           	endif
	           	oPrint:Say(nLinha,2645, TransForm((_sAliasQ) -> VLR_COMIS  , '@E 9,999,999.99') ,oFont12n)	
	           	nLinha += 50
	           	// acumula totais
	           	_aTotVend [6]  += (_sAliasQ) -> VALOR_TIT
	           	_aTotVend [7]  += _vlrdesconto
	           	_aTotVend [8]  +=  _vlrrecebido
	           	_aTotVend [9]  += (_sAliasQ) -> BASE_COMIS
	            _aTotVend [10] += (_sAliasQ) -> VLR_COMIS
	            // imprime itens
	            // imprime ITENS
				if mv_par08 = 2 .and. mv_par07 = 1
					_sQuery := "" 
					_sQuery += " SELECT SD2.D2_COD, SB1.B1_DESC, SD2.D2_COMIS1, SD2.D2_TOTAL"
	  				_sQuery += "   FROM SD2010 AS SD2"
					_sQuery += " 	   INNER JOIN SB1010 AS SB1"
					_sQuery += " 		  ON (SB1.D_E_L_E_T_ = ''"
					_sQuery += " 			  AND SB1.B1_COD = SD2.D2_COD)"
	 				_sQuery += "  WHERE SD2.D_E_L_E_T_ = ''"
	 				_sQuery += "    AND SD2.D2_FILIAL  = '" + (_sAliasQ) -> FILIAL + "'"
	   				_sQuery += "    AND SD2.D2_DOC     = '" + (_sAliasQ) -> NUMERO + "'"  
	   				_sQuery += "    AND SD2.D2_SERIE   = '" + (_sAliasQ) -> PREFIXO + "'"
	   				_sQuery += " ORDER BY SD2.D2_COD"
					
					_aDados := U_Qry2Array(_sQuery)
	     
	    			if len (_aDados) > 0
	    				_wbasearred := (_sAliasQ) -> BASE_COMIS
	    				_wvlrarred  := (_sAliasQ) -> VLR_COMIS
	    				for i=1 to len(_aDados)
	    					_wcodprod    = _aDados[i,1]
	    					_wdesprod    = _aDados[i,2]
	    					_wpercomitem = _aDados[i,3]
	    					_wvlritem    = _aDados[i,4]
	    			
		    				If (nLinha/50) > 46
				   				_wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
				   				_wpag += 1	
	               				xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	               				nlinha := 600
	            			Endif
	            			// monta linha para impressao
	     					oPrint:Say(nLinha,0285, alltrim(_wcodprod) 	 			  	 				     ,oFont12n)
	     					oPrint:Say(nLinha,0400, LEFT(_wdesprod,40) 	 			  	 				     ,oFont12n)
	     					oPrint:Say(nLinha,1045, TransForm( _wvlritem                , '@E 9,999,999.99') ,oFont12n)
		           			_wlibitem =  ROUND(_wvlritem * (_sAliasQ) -> BASE_COMIS / _wbasenota,2)
		           			// ajusta diferença centavos no ultimo item - BASE COMISSAO LIBERADA
		           			_wbasearred = _wbasearred - _wlibitem
							if i = len(_aDados) .and. _wbasearred <> _wlibitem 
								_wlibitem = _wlibitem + _wbasearred 	
							endif
							oPrint:Say(nLinha,2285, TransForm( _wlibitem                , '@E 9,999,999.99') ,oFont12n)
		           			oPrint:Say(nLinha,2525, TransForm( _wpercomitem             , 		 '@E 99.99') ,oFont12n)
		           			_wcomitem = ROUND(_wlibitem * _wpercomitem /100,2)
		           			// ajusta diferença centavos no ultimo item - VLR COMISSAO
							_wvlrarred = _wvlrarred - _wcomitem 
							if i = len(_aDados) .and. _wvlrarred <> _wcomitem 
								_wcomitem = _wcomitem + _wvlrarred 	
							endif
							oPrint:Say(nLinha,2645, TransForm( _wcomitem                , '@E 9,999,999.99') ,oFont12n)	
		           			nLinha += 50
	           			next
					endif					
				endif
		        // le o proximo registro de comissao do vendedor
				(_sAliasQ) -> (dbskip())
		    enddo
		    If (nLinha/50) > 46
			   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
			   _wpag += 1	
	           xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	           nlinha := 600
	        Endif
	        nLinha += 50 // linha em branco
	        // imprime totais do vendedor
	        If (nLinha/50) > 46
			   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
			   _wpag += 1	
	           xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	           nlinha := 600
	        Endif
	        oPrint:Say(nLinha,0045, "TOTAIS DO VENDEDOR    --> "					        ,oFont12n)
	        oPrint:Say(nLinha,1645, TransForm( _aTotVend [6]          , '@E    999,999.99') ,oFont12n)
	        oPrint:Say(nLinha,1845, TransForm( _aTotVend [7]          , '@E  9,999,999.99') ,oFont12n)
	        oPrint:Say(nLinha,2045, TransForm( _aTotVend [8]          , '@E  9,999,999.99') ,oFont12n)
	        oPrint:Say(nLinha,2285, TransForm( _aTotVend [9]          , '@E  9,999,999.99') ,oFont12n)
	        oPrint:Say(nLinha,2645, TransForm( _aTotVend [10]         , '@E  9,999,999.99') ,oFont12n)
	        nLinha += 50 // linha em branco
	        // so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
	        _vlrIR = 0
	        if _simples != '1' // 1=SIM
	           _vlrIR = ROUND(_aTotVend [10] * 1.5 /100 , 2)
	           if _vlrIR > 10
	           	   If (nLinha/50) > 46
			   		   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
			   		   _wpag += 1	
	           		   xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	           		   nlinha := 600
	        	   Endif
	               oPrint:Say(nLinha,0045, "TOTAL DO IR           --> "		  				         ,oFont12n)
	               oPrint:Say(nLinha,2645, TransForm( _vlrIR                  , '@E 9,999,999.99')   ,oFont12n)
	               nLinha += 50
	               oPrint:Say(nLinha,0045, "TOTAL (-) IR          --> "		  				         ,oFont12n)
	               oPrint:Say(nLinha,2645, TransForm( _aTotVend [10] - _vlrIR , '@E 9,999,999.99')   ,oFont12n)
	               nLinha += 50
	           else
	               _vlrIR = 0	
	           endif
			endif
			If (nLinha/50) > 46
			   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
			   _wpag += 1	
	           xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	           nlinha := 600
	        Endif
	        nLinha += 50 // linha em branco
			// tratamento para indenizacao
			_windeniz = ROUND(_aTotVend [10] /12 , 2)
			oPrint:Say(nLinha,0045, "VLR INDENIZAÇÃO 1/12 " + IIF (_TPINDENIZ ='S', 'PAGA', 'PROVISIONADA') ,oFont12n)
	        oPrint:Say(nLinha,2645, TransForm( _windeniz  , '@E 9,999,999.99')                              ,oFont12n)
	        nLinha += 50
	        _vIRind = 0
	        if _TPINDENIZ ='S' .and. _simples != '1'
	           _vIRind = ROUND(_windeniz * 15 /100 , 2)
	           if _vIRind > 10
	           	   If (nLinha/50) > 46
					   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
					   _wpag += 1	
			           xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
			           nlinha := 600
	        	   Endif
	               oPrint:Say(nLinha,0045, "TOTAL DO IR (INDENIZ) --> "		  				         ,oFont12n)
	               oPrint:Say(nLinha,2645, TransForm( _vIRind            , '@E 9,999,999.99')        ,oFont12n)
	               nLinha += 50
	               oPrint:Say(nLinha,0045, "TOTAL INDENIZ (-) IR  --> "		  				         ,oFont12n)
	               oPrint:Say(nLinha,2645, TransForm( _windeniz - _vIRind , '@E 9,999,999.99')       ,oFont12n)
	               nLinha += 50
			   else 	
			   		_vIRind = 0               
			   endif	              
			endif
			If (nLinha/50) > 32
			   _wnomevend := fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
			   _wpag += 1	
	           xCabec((_sAliasVend) -> VENDEDOR, _wnomevend)
	           nlinha := 600
	        Endif
	        nLinha += 50 // linha em branco
	        // dados para impressao da nota fiscal
			oPrint:Box( nLinha - 30, 400, nLinha + 30 , 1300)
			oPrint:Say(nLinha,550,OemToAnsi('DADOS PARA EMISSAO NOTA FISCAL'),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30, 1600, nLinha + 30 , 2500)
				oPrint:Say(nLinha, 1750,OemToAnsi('DADOS INDENIZAÇÃO 1/2 AVOS'),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30, 400, nLinha + 30, 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('VALOR                                ' + TransForm( _aTotVend [10] , '@E  9,999,999.99')),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30, 1600, nLinha + 30, 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('VALOR                                ' + TransForm( _windeniz , '@E  9,999,999.99')),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30, 400, nLinha + 30, 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('(-)I.R.                              ' + TransForm( _vlrIR         , '@E  9,999,999.99')),oFont13)
			if _TPINDENIZ ='S' .and. _simples != '1'
				oPrint:Box( nLinha - 30, 1600, nLinha + 30, 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('(-)I.R.                              ' + TransForm( _vIRind         , '@E  9,999,999.99')),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30, 400, nLinha + 30, 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('VALOR LIQUIDO                        ' + TransForm( _aTotVend [10] - _vlrIR , '@E 9,999,999.99')),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30, 1600, nLinha + 30, 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('VALOR LIQUIDO                        ' + TransForm( _windeniz - _vIRind , '@E 9,999,999.99')),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30, 400, nLinha + 30 , 1300)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30, 1600, nLinha + 30 , 2500)
			endif
			// buscar nome do banco
	    	_wbanco := '' 
	    	do case
	    		case (_sAliasVend) -> BANCO = '001'
	    			_wbanco := "BANCO DO BRASIL"		
	    		case (_sAliasVend) -> BANCO = '041'
	    			_wbanco := "BANRISUL"
	    		case (_sAliasVend) -> BANCO = '748'
	    			_wbanco := "SICREDI"
	    		case (_sAliasVend) -> BANCO = '237'
	    			_wbanco := "BRADESCO"
	    		case (_sAliasVend) -> BANCO = '341'
	    			_wbanco := "ITAU"
	    		case (_sAliasVend) -> BANCO = '104'
	    			_wbanco := "CAIXA FEDERAL"
	    		case (_sAliasVend) -> BANCO = '746'
	    			_wbanco := "SICOOB"
	    	endcase
			oPrint:Say(nLinha, 450,OemToAnsi('DADOS DO PAGAMENTO'  ),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Say(nLinha, 1650,OemToAnsi('DADOS DO PAGAMENTO'  ),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('DATA                               '  + dtoc(stod( (_sAliasVend) -> DTPAG)) + '  *' ),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('DATA                               '  + dtoc(stod( (_sAliasVend) -> DTPAG)) + '  *' ),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('BANCO                ' + (_sAliasVend) -> BANCO ) + ' - ' + _wbanco,oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('BANCO            ' + (_sAliasVend) -> BANCO ) + ' - ' + _wbanco,oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('AGENCIA                                ' + (_sAliasVend) -> AGENCIA ),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('AGENCIA                                ' + (_sAliasVend) -> AGENCIA ),oFont13)
			endif
			nLinha += 50
			oPrint:Box( nLinha - 30,  400, nLinha + 30 , 1300)
			oPrint:Say(nLinha, 450,OemToAnsi('CONTA                                  ' + (_sAliasVend) -> CONTA ),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Box( nLinha - 30,  1600, nLinha + 30 , 2500)
				oPrint:Say(nLinha, 1650,OemToAnsi('CONTA                                  ' + (_sAliasVend) -> CONTA ),oFont13)
			endif
			nLinha += 50
			nLinha += 50 // linha em branco
			oPrint:Say(nLinha, 300,OemToAnsi('* Pagamento via depósito, mediante recebimento da NF por email.'),oFont13)
			if _TPINDENIZ ='S'
				oPrint:Say(nLinha, 1650,OemToAnsi('* Pagamento via depósito.'),oFont13)
			endif
			nLinha += 50
			oPrint:Say(nLinha, 300,OemToAnsi('  Email para envio da NF: andressa.brugnera@novaaliança.coop.br'),oFont13)
			nLinha += 50
			// monta o recibo se for indenizacao paga no mes
			if _TPINDENIZ ='S'
				_oCour14N  := TFont():New("Courier New",,14,,.T.,,,,,.F.)
				_oCour16   := TFont():New("Courier New",,16,,.F.,,,,,.F.)
				_oCour16N  := TFont():New("Courier New",,16,,.T.,,,,,.F.)
				_oCour20N  := TFont():New("Courier New",,20,,.T.,,,,,.F.)
				
				_oArial10  := TFont():New("Arial",,10,,.F.,,,,,.F.)
				_oArial16  := TFont():New("Arial",,16,,.F.,,,,,.F.)
				_oArial32N := TFont():New("Arial",,32,,.T.,,,,,.F.)
				_oArial48N := TFont():New("Arial",,48,,.T.,,,,,.F.)
				
				_nMargSup  := 250
				_nMargInf  := 260
				_nMargEsq  := 400
				_nAltPag   := 1500
				_nLargPag  := 2800
				
				// salta a pagina
				oPrint:StartPage()
	           	nlinha := 600
				// variaveis do recibo
				_wvlrrecibo = _windeniz - _vIRind
				_wcidade    = alltrim(fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_MUN"))
				_west       = fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_EST")
				_wnomeraz   = fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_NOME")
				_wcnpj      = fbuscacpo ("SA3", 1, xfilial ("SA3") + (_sAliasVend) -> VENDEDOR , "A3_CGC")
				_wdatapg    = substr((_sAliasVend) -> DTPAG,7,2) + '/' + substr((_sAliasVend) -> DTPAG,5,2)  + '/' + substr((_sAliasVend) -> DTPAG,1,4)
				
				oPrint:Box(_nMargSup + 20, _nMargEsq + 20, _nMargSup + _nAltPag, _nLargPag - _nMargEsq)
				
				_mvsim1 := BuscaPar() // GetMv ("MV_SIMB1") 
				oPrint:Say(_nMargSup + 170,  _nMargEsq + 40, "R E C I B O", _oArial32N, 100)
				oPrint:Say(_nMargSup + 170,  _nMargEsq + 1500, _mvsim1 + " " + alltrim (transform (_wvlrrecibo, "@E 999,999,999.99")) , _oArial32N, 100)
				oPrint:Say(_nMargSup + 288,  _nMargEsq + 50, "Recebi de ", _oCour16, 100)
				oPrint:Say(_nMargSup + 288,  _nMargEsq + 300, "COOPERATIVA AGROINDUSTRIAL NOVA ALIANCA LTDA", _oCour20N, 100)
				_sExtenso = Extenso (_wvlrrecibo)
				oPrint:Say(_nMargSup + 388,  _nMargEsq + 50, "A importancia de ", _oCour16, 100)
				oPrint:Say(_nMargSup + 370,  _nMargEsq + 500, left (_sExtenso, 49), _oCour20N, 100)
				_wnlinha :=0
				if len(alltrim(_sExtenso)) > 50
					oPrint:Say(_nMargSup + 470,  _nMargEsq + 50,  substr (_sExtenso, 50, 109), _oCour20N, 100)
					_wnlinha += 1
				endif
				if len(alltrim(_sExtenso)) > 109				
					oPrint:Say(_nMargSup + 570,  _nMargEsq + 50,  substr (_sExtenso, 109, 169), _oCour20N, 100)
					_wnlinha += 1
				endif				
				oPrint:Say(_nMargSup + 670  - (_wnlinha*100), _nMargEsq + 50, "Correspondente a ", _oCour16, 100)
				oPrint:Say(_nMargSup + 670  - (_wnlinha*100), _nMargEsq + 450, "PAGAMENTO 1/12 (um doze avos) DE INDENIZAÇÃO.", _oCour20N, 100)
				oPrint:Say(_nMargSup + 770  - (_wnlinha*100), _nMargEsq + 50, _wcidade + " - " + _west + ", " + _wdatapg, _oCour16 ,100)
				oPrint:Say(_nMargSup + 900  - (_wnlinha*100), _nMargEsq + 900, "_____________________________________", _oCour20N, 100)
				oPrint:Say(_nMargSup + 1000 - (_wnlinha*100), _nMargEsq + 900, "             Assinatura",  _oCour16, 100)
				oPrint:Say(_nMargSup + 1100 - (_wnlinha*100), _nMargEsq + 900, _wnomeraz,  _oCour16, 100)
				oPrint:Say(_nMargSup + 1150 - (_wnlinha*100), _nMargEsq + 900, "CNPJ" + Transform(_wcnpj, '@R 99.999.999/9999-99') ,  _oCour16, 100)
				
			endif
			// finaliza impressao
		    oPrint:EndPage()
			oPrint:Preview() //abre o PDF na tela
			
			// gera o arquivo em PDF
			CpyT2S(_cPathPDF +_cFile+ ".PDF", cDestino)
			_sCtaMail  := "envio.comissoes"
			//
			//_sMailDest := 'andressa.brugnera@novaalianca.coop.br'
			//U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
		    // copia
		    _sMailDest := 'envio.comissoes@novaalianca.coop.br'
		    U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)

		    // envia email para o represenante
		    _sMailDest := (_sAliasVend) -> EMAIL
		    U_SendMail (_sMailDest, "Relatorio de Comissões - Envio automatico", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
//		    // le o proximo vendedor
		endif
		(_sAliasVend) -> (dbskip())
	enddo
	
return
// -----------------------------------------------------------------------------
//
Static Function xCabec(_wvendedor, _wnomevend)
	oPrint:StartPage()
	oPrint:SayBitmap(150,100,'logo.jpg',720,170)
	oPrint:Say(0300,1000,OemToAnsi('Relatorio de Comissões'),oFont22)
	oPrint:Say(00270,2175,OemToAnsi('Recebimentos: ' + dtoc(mv_par01) + ' até ' + dtoc(mv_par02) ),oFont13)
	oPrint:Say(00300,2175,OemToAnsi('Emissao     : ' + dtoc(date()) + '     Pagina: ' + strzero(_wpag,2) ),oFont13)
	oPrint:Line(0350,00045,0350,2850)
	oPrint:Say(0400,0045,OemToAnsi('NUMERO PARC  CLIENTE                            TOTAL NOTA   BASE COM.   DATA        NUMERO       VALOR     DESCONTOS       VALOR  BASE COMISSAO   %            VALOR'),oFont13)
    oPrint:Say(0430,0045,OemToAnsi('TITULO                                                       PREV.NOTA   PAGTO       PEDIDO      TITULO    CONCEDIDOS    RECEBIDO   * LIBERADA *             COMISSAO'),oFont13)
    oPrint:Line(0450,00045,0450,2850)
    oPrint:Say(0500,0045,OemToAnsi('VENDEDOR: ' + _wvendedor + ' - '+ _wnomevend),oFont13)
    
Return
//
// --------------------------------------------------------------------------
Static Function BuscaPar()
	_lRet := GetMv ("MV_SIMB1") 
Return _lRet
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Base de                 ?", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Base ate                ?", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        		 "Representante Inicial"})
    aadd (_aRegsPerg, {04, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {},                        		 "Represenante Final"})
    aadd (_aRegsPerg, {05, "Lista Comissoes              ?", "N", 1,  0,  "",   "   ", {"Liberadas","Pagas"},   		 ""})
    aadd (_aRegsPerg, {06, "Lista no Cliente             ?", "N", 1,  0,  "",   "   ", {"Razão Social","Nome Reduzido"}, ""})
    aadd (_aRegsPerg, {07, "Opção                        ?", "N", 1,  0,  "",   "   ", {"Analitica","Sintetica","Email"},""})
    aadd (_aRegsPerg, {08, "Lista comissao por item      ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {09, "Considera bloqueados         ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
