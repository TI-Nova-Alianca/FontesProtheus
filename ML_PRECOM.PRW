//  Programa...: ML_PRECOM
//  Autor......: Catia Cardoso
//  Data.......: 02/02/2015
//  Cliente....: Alianca
//  Descricao..: Relatório de Previsao de Comissoes
//               Serve de base para conferencia de saldos a liquidar em caso de encerramento de contrato de representante.
//
//  Historico de alteracoes:
//  15/05/2015 - Catia - Opcao de considera vencidos ou não
//  02/06/2015 - Catia - incluido parametro data inicial 
//  18/06/2016 - Catia - tinha um u_shomemo esquecido
//  15/08/2016 - Catia - alterado a forma do calculo do IR - igual ao relatorio de comissoes
//  15/08/2016 - Catia - colocado intervalo de vendedores - antes so deixava 1 por vez
//  12/06/2017 - Catia - alteração do rapel para o SD2, SF2, SE1 como valor e nao percentual

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_PRECOM()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE3"
    cDesc1  := "Relatório PREVISAO de Comissões"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_PRECOM"
    wnrel   := "ML_PRECOM"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    
    	titulo  := "Relatório PREVISÃO de Comissões - Títulos com vencimento até: " + dtoc(mv_par05)
    
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
    cabec1:="PRF NUMERO PARC  CODIGO LJ NOME                     TOTAL NOTA  TOTAL IPI   TOTAL ST BASE COMISSAO  DATA       DATA        NUMERO        VALOR BASE COMISSAO        RAPEL         VALOR   BASE COMISSAO    %      COMISSAO"
    cabec2:="    TITULO      CLIENTE                                                              PREVISTA NOTA  EMISSAO    VENCTO      PEDIDO       TITULO  PREVISTA TIT     PREVISTO      PREVISTO    * PREVISTA *           PREVISTA"
    
    _sQuery := " "
   	_sQuery += " SELECT E1_BASCOM1  AS BASE_COMIS"
   	_sQuery += "      , E1_VEND1    AS VENDEDOR"
   	_sQuery += "      , E1_COMIS1   AS PERCENTUAL"
   	_sQuery += "      , A3_NOME     AS NOM_VEND"
   	_sQuery += "      , E1_PREFIXO  AS PREFIXO"
   	_sQuery += "      , E1_NUM      AS NUMERO" 
   	_sQuery += "      , E1_PARCELA  AS PARCELA"
   	_sQuery += "      , E1_CLIENTE  AS CODCLI"
   	_sQuery += "      , E1_LOJA     AS LOJA"
   	_sQuery += "      , E1_PEDIDO   AS PEDIDO"
   	_sQuery += "      , E1_VENCTO   AS VENCIMENTO"
   	_sQuery += "      , E1_EMISSAO  AS EMISSAO
   	_sQuery += "      , E1_VALOR    AS VALOR_TIT"
   	_sQuery += "      , E1_BASCOM1  AS BASE_TIT"
   	_sQuery += "      , E1_SALDO    AS SALDO_TIT"
   	_sQuery += "      , F2_VALBRUT  AS TOTAL_NF"
   	_sQuery += "      , F2_VALIPI   AS IPI_NF"
   	_sQuery += "      , F2_ICMSRET  AS ST_NF"
   	_sQuery += "      , E1_EMISSAO  AS DTEMIS"
   	_sQuery += "      , E1_VARAPEL  AS RAPEL"
   	_sQuery += "      , A2_SIMPNAC  AS SIMPLES"
   	_sQuery += "      , ISNULL (( SELECT E1_VALOR"
   	_sQuery += "  		            FROM " + RetSQLName ("SE1") + " AS SE1A " 
   	_sQuery += "                   WHERE SE1A.E1_FILIAL  = SE1.E1_FILIAL"        
   	_sQuery += "                     AND SE1A.E1_PREFIXO = SE1.E1_PREFIXO"
   	_sQuery += "                     AND SE1A.E1_NUM     = SE1.E1_NUM"
   	_sQuery += "                     AND SE1A.E1_PARCELA = 'A' "
   	_sQuery += "   			         AND SE1A.E1_NATUREZ = '110199' "
   	_sQuery += "                     AND SE1A.D_E_L_E_T_ = '' ),0) AS PARC_ST"
   	_sQuery += "      , A3_INDENIZ     AS INDENIZ"
   	_sQuery += "   FROM " + RetSQLName ("SE1") + " AS SE1 "
   	_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
   	_sQuery += "       ON (SA3.D_E_L_E_T_ = '' 
   	_sQuery += "           AND SA3.A3_COD     = SE1.E1_VEND1"
   	_sQuery += "           AND SA3.A3_ATIVO   = 'S' )"
   	/*
   	_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
   	_sQuery += "       ON (SA1.D_E_L_E_T_ = '' 
   	_sQuery += "           AND SA1.A1_COD     = SE1.E1_CLIENTE"
   	_sQuery += "           AND SA1.A1_LOJA    = SE1.E1_LOJA)"
   	*/
   	_sQuery += " INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
   	_sQuery += "           ON (SF2.D_E_L_E_T_ = '' "
   	_sQuery += "               AND SF2.F2_DOC        = SE1.E1_NUM"
   	_sQuery += "               AND SF2.F2_SERIE      = SE1.E1_PREFIXO"
   	_sQuery += "               AND SF2.F2_CLIENTE    = SE1.E1_CLIENTE"
   	_sQuery += "               AND SF2.F2_LOJA       = SE1.E1_LOJA)"
   	_sQuery += "INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
    _sQuery += "           ON (SA2.D_E_L_E_T_ = '' "
    _sQuery += "               AND SA2.A2_COD        = SA3.A3_FORNECE"
   	_sQuery += "               AND SA2.A2_LOJA       = SA3.A3_LOJA)"
    _sQuery += " WHERE SE1.E1_SALDO    > 0 "
    _sQuery += "   AND SE1.E1_VEND1  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    _sQuery += "   AND SE1.D_E_L_E_T_  = '' "
    _sQuery += "   AND SE1.E1_COMIS1   > 0 "
    _sQuery += "   AND SE1.E1_NATUREZ != '110199' "
    if mv_par07 = 2
		_sQuery += "   AND SE1.E1_VENCTO > " + dtos (date ())
    endif
    _sQuery += "   AND SE1.E1_VENCTO >= '" + dtos (mv_par05) + "'
    _sQuery += "   AND SE1.E1_VENCTO <= '" + dtos (mv_par06) + "'
    _sQuery += "   AND SE1.E1_FILIAL   = '" + xFilial('SE1') + "' " 
    _sQuery += " ORDER BY E1_VEND1, E1_VENCTO , E1_PREFIXO, E1_NUM, E1_PARCELA"
    
    //u_showmemo(_sQuery)
 	
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotVend = {0,0,0,0,0,0}
     _simples     := ""
     _vendAnt     := ""
     _vendAntnome := ""
      
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
           	IF _vendAnt != '' .and. _vendAnt != (_sAliasQ) -> VENDEDOR .and. _aTotVend [6] > 0
                // imprime totais do vendedor
                If li>65
                    cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
                Endif        
                li++
                
                @ li, 00 PSAY "TOTAL DO VENDEDOR --> "
                @ li, 26 PSAY _vendAnt
                @ li, 35 PSAY _vendAntnome
                @ li, 130 PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
                @ li, 144 PSAY _aTotVend [2]  Picture "@E 9,999,999.99"
        		@ li, 157 PSAY _aTotVend [3]  Picture "@E 9,999,999.99"
   				@ li, 171 PSAY _aTotVend [4]  Picture "@E 9,999,999.99"
    			@ li, 187 PSAY _aTotVend [5]  Picture "@E 9,999,999.99"
    			@ li, 206 PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
				li++
                // so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
                _vlrIR = 0
                if _simples != '1' // 1=SIM
                	_vlrIR = ROUND(_aTotVend [6] * 1.5 /100 , 2)
                	if _vlrIR > 10
                    	@ li, 00  PSAY "TOTAL DO IR           --> "
                    	@ li, 206 PSAY _vlrIR Picture "@E 9,999,999.99"
                    	li ++
                    	@ li, 00  PSAY "TOTAL (-) IR          --> "
                    	@ li, 206 PSAY _aTotVend [6] - _vlrIR Picture "@E 9,999,999.99"
                    	li ++
                    else
                    	_vlrIR = 0	
                	endif
				endif
				// tratamento para indenizacao
				_windeniz = ROUND(_aTotVend [6] /12 , 2)
				li ++
				
                @ li, 00  PSAY "VLR INDENIZAÇÃO 1/12 " + IIF (_TPINDENIZ ='S', 'PAGA', 'PROVISIONADA')
                @ li, 206 PSAY _windeniz Picture "@E 9,999,999.99"
                li ++
                if _TPINDENIZ ='S'
	                
					
					// Robert 08/05/20
					if _simples != '1' // 1=SIM
          		      	_vIRind = ROUND(_windeniz * 15 /100 , 2)
					else
						_vIRind = 0
					endif


                	if _vIRind > 10
                    	@ li, 00  PSAY "TOTAL DO IR (INDENIZ) --> "
                    	@ li, 206 PSAY _vIRind Picture "@E 9,999,999.99"
                    	li ++
                    	@ li, 00  PSAY "TOTAL INDENIZ (-) IR  --> "                    	
                    	@ li, 206 PSAY _windeniz - _vIRind Picture "@E 9,999,999.99"
                    	li ++
                    else
                    	_vIRind = 0
					endif
				endif                	
                // total geral previsto
                li ++
                @ li, 00  PSAY "TOTAL GERAL PREVISTO  --> "
                @ li, 206 PSAY _aTotVend [6] - _vlrIR + _windeniz Picture "@E 9,999,999.99"
                li ++
                li ++
                
                _aTotVend [1]  := 0
                _aTotVend [2]  := 0
                _aTotVend [3]  := 0
                _aTotVend [4]  := 0
                _aTotVend [5]  := 0
                _aTotVend [6]  := 0
                
                if mv_par03 = 1
                	li :=100
				endif
                
           Endif
           
           IF _vendAnt = "" .or. _vendAnt != (_sAliasQ) -> VENDEDOR
	       		If li>65
               		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           		Endif
           		dbSelectArea("SA3")
           		dbSeek(xFilial() + (_sAliasQ) -> VENDEDOR)
           		@li, 00 PSAY (_sAliasQ) -> VENDEDOR
           		@li, 07 PSAY (_sAliasQ) -> NOM_VEND
           		li ++ 
           		li ++
           		
           	endif
            
			
        	If li>65
               	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
           
           	@li, 00 PSAY (_sAliasQ) -> PREFIXO
           	@li, 04 PSAY (_sAliasQ) -> NUMERO
           	@li, 14 PSAY (_sAliasQ) -> PARCELA
           	@li, 18 PSAY (_sAliasQ) -> CODCLI
           	@li, 25 PSAY (_sAliasQ) -> LOJA
      			
      		if mv_par04 = 2  
           		_wnomecli := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NREDUZ")
           	else
           		_wnomecli := fbuscacpo ("SA1", 1, xfilial ("SA1") + (_sAliasQ) -> CODCLI + (_sAliasQ) -> LOJA , "A1_NOME")
           	endif
           		
           	@li, 28 PSAY left(_wnomecli,18)
           	@li, 50 PSAY (_sAliasQ) -> TOTAL_NF     Picture "@E 9,999,999.99"
           	@li, 64 PSAY (_sAliasQ) -> IPI_NF       Picture "@E 99,999.99"
           	@li, 75 PSAY (_sAliasQ) -> ST_NF        Picture "@E 99,999.99"
            
            _wbasenota = (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF  - (_sAliasQ) -> ST_NF
           	@li, 86  PSAY _wbasenota                Picture "@E 9,999,999.99"
           	@li, 100 PSAY stod((_sAliasQ) -> EMISSAO)
           	@li, 111 PSAY stod((_sAliasQ) -> VENCIMENTO)
           	@li, 123 PSAY (_sAliasQ) -> PEDIDO
           	@li, 130 PSAY (_sAliasQ) -> SALDO_TIT    Picture "@E 9,999,999.99"
           	
           	_basePrev = ROUND( (_wbasenota * (_sAliasQ) -> SALDO_TIT) / ((_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> PARC_ST) , 2)
           	@li, 144 PSAY _basePrev   Picture "@E 9,999,999.99"
           	
           	// calcula rapel se tiver
           	//_wrapel :=0
           	//if (_sAliasQ) -> TXRAPEL > 0
				//_wrapel := ROUND((_sAliasQ) -> SALDO_TIT * (_sAliasQ) -> TXRAPEL / 100 , 2)
           	//endif  
           	//@li, 157 PSAY _wrapel     Picture "@E 9,999,999.99"
           	//
           	@li, 157 PSAY (_sAliasQ) -> RAPEL   Picture "@E 9,999,999.99"
           	// calcula valor previsto	
           	//_vlrprevisto := ROUND((_sAliasQ) -> SALDO_TIT - _wrapel , 2)
           	_vlrprevisto := ROUND((_sAliasQ) -> SALDO_TIT - (_sAliasQ) -> RAPEL , 2)
           	@li, 171 PSAY _vlrprevisto     Picture "@E 9,999,999.99"
           	
           	// recalcular a base do titulo 
			_basecomtit  := ROUND ( _vlrprevisto * _basePrev / (_sAliasQ) -> SALDO_TIT ,2)
			@li, 187 PSAY _basecomtit   Picture "@E 9,999,999.99"
           	
           	// imprime percentual de comissao
           	@li, 202 PSAY (_sAliasQ) -> PERCENTUAL   Picture "@E 99.99"
           	// calcula valor da comissao
           	_vlrcomis := ROUND (_basecomtit * (_sAliasQ) -> PERCENTUAL / 100 , 2)
            @li, 208 PSAY _vlrcomis                  Picture "@E 999,999.99"
            li ++
           // acumula total
           _aTotVend [1] += (_sAliasQ) -> SALDO_TIT
           _aTotVend [2] += _basePrev 
           _aTotVend [3] += (_sAliasQ) -> RAPEL
           _aTotVend [4] += _vlrprevisto 
           _aTotVend [5] += _basecomtit
           _aTotVend [6] += _vlrcomis
           
            _vendAnt     := (_sAliasQ) -> VENDEDOR
           	_vendAntnome := (_sAliasQ) -> NOM_VEND
           	_simples     := (_sAliasQ) -> SIMPLES
           	_tpindeniz   := (_sAliasQ) -> INDENIZ
                
           (_sAliasQ) -> (dbskip())
           
     enddo
     
     if _aTotVend [6] > 0
        // imprime totais do vendedor
        If li>65
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAL DO VENDEDOR --> "
        @ li, 26 PSAY (_sAliasQ) -> VENDEDOR
        @ li, 35 PSAY (_sAliasQ) -> NOM_VEND
       	@ li, 130 PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
       	@ li, 144 PSAY _aTotVend [2]  Picture "@E 9,999,999.99"
		@ li, 157 PSAY _aTotVend [3]  Picture "@E 9,999,999.99" 
        @ li, 171 PSAY _aTotVend [4]  Picture "@E 9,999,999.99"
        @ li, 187 PSAY _aTotVend [5]  Picture "@E 9,999,999.99"
        @ li, 206 PSAY _aTotVend [6]  Picture "@E 9,999,999.99"
        li++
        // so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
        _vlrIR = 0
        if _simples != '1' // 1=SIM
        	_vlrIR = ROUND(_aTotVend [6] * 1.5 /100 , 2)
        	if _vlrIR > 10
            	@ li, 00  PSAY "TOTAL DO IR           --> "
            	@ li, 206 PSAY _vlrIR Picture "@E 9,999,999.99"
            	li ++
            	@ li, 00  PSAY "TOTAL (-) IR          --> "
            	@ li, 206 PSAY _aTotVend [6] - _vlrIR Picture "@E 9,999,999.99"
            	li ++
            else
            	_vlrIR = 0	
        	endif
		endif
		// tratamento para indenizacao
		_windeniz = ROUND(_aTotVend [6] /12 , 2)
		li ++
		
        @ li, 00  PSAY "VLR INDENIZAÇÃO 1/12 " + IIF (_TPINDENIZ ='S', 'PAGA', 'PROVISIONADA')
        @ li, 206 PSAY _windeniz Picture "@E 9,999,999.99"
        li ++
        if _TPINDENIZ ='S'
//        	_vIRind = ROUND(_windeniz * 15 /100 , 2)
	                
					
					// Robert 08/05/20
					if _simples != '1' // 1=SIM
          		      	_vIRind = ROUND(_windeniz * 15 /100 , 2)
					else
						_vIRind = 0
					endif


        	if _vIRind > 10
            	@ li, 00  PSAY "TOTAL DO IR (INDENIZ) --> "
            	@ li, 206 PSAY _vIRind Picture "@E 9,999,999.99"
            	li ++
            	@ li, 00  PSAY "TOTAL INDENIZ (-) IR  --> "                    	
            	@ li, 206 PSAY _windeniz - _vIRind Picture "@E 9,999,999.99"
            	li ++
            else
            	_vIRind = 0
			endif
		endif   
		
		// total geral previsto
		li ++
        @ li, 00  PSAY "TOTAL GERAL PREVISTO  --> "
        @ li, 206 PSAY _aTotVend [6] - _vlrIR + _windeniz Picture "@E 9,999,999.99"
        li ++
        li ++
                             	
        _aTotVend [1]  := 0
        _aTotVend [2]  := 0
        _aTotVend [3]  := 0
        _aTotVend [4]  := 0
        _aTotVend [5]  := 0
        _aTotVend [6]  := 0
        
        if mv_par03 = 1
           	li :=100
		endif
                
    Endif
 
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
    aadd (_aRegsPerg, {01, "Representante                ?", "C", 6, 0,  "",   "SA3", {},                        "Representante Inicial"})
    aadd (_aRegsPerg, {02, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {},                        "Representante Final"})
    aadd (_aRegsPerg, {03, "Nova pagina p/Representante  ?", "S", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
    aadd (_aRegsPerg, {04, "Lista Cliente com            ?", "N", 1, 0,  "",   "   ", {"Razão Social","Nome Reduzido"},   ""})
    aadd (_aRegsPerg, {05, "Previsão de                  ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {06, "Previsão até                 ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {07, "Considera titulos em atraso  ?", "N", 1, 0,  "",   "   ", {"Sim","Não"},   ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
