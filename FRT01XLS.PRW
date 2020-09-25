// Programa...: FRT01XLS
// Autor......: Catia Cardoso
// Data.......: 17/11/2015 (nova versao)
// Descricao..: Analise Fretes SAIDAS
//
// -------------------------------------------------------------------------------------------------------
// Historico de alteracoes:
//
// 22/01/2016 - Catia - cString não estava SF2 
// 09/06/2016 - Catia - incluido parametro de fornecedor de transporte - filtro de fornecedor direto na SZH
// 31/07/2018 - Catia - quando informava "branco" no parametro de fornecedor de transporte nao mostrava nada
// ---------------------------------------------------------------------------------------------------------
User Function FRTXLS01 (_lAutomat)
    Private cPerg    := "FRTXLS01"
    
    if ! u_zzuvl ('032', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina/relatório.")
		return
	endif
    
    _ValidPerg()
    if Pergunte(cPerg,.T.)
            
        Processa( { |lEnd| _ExecQuery() } )
        if mv_par11 = 2
           Processa( { |lEnd| _GeraArq() } )
        else
           Processa( { |lEnd| _Lista() } )
        endif
	    
    endif
    
return

// --------------------------------------------------------------------------
Static Function _ExecQuery()
    local  _sQuery    := ""
    public _sAliasQ   := ""
    
    procregua (10)
    incproc ("Buscando dados")
    
    _sQuery := ""
    _sQuery += " SELECT SD2.D2_FILIAL      AS FILIAL"
    _sQuery += " 	 , dbo.VA_DTOC(SD2.D2_EMISSAO)  AS DT_EMISSAO"
    _sQuery += " 	 , SD2.D2_DOC          AS NOTA"
  	_sQuery += " 	 , SD2.D2_SERIE        AS SERIE"
  	_sQuery += " 	 , SD2.D2_TIPO         AS TIPO"
  	_sQuery += " 	 , SD2.D2_CLIENTE      AS CLIENTE"
  	_sQuery += " 	 , SD2.D2_LOJA         AS LOJA"
  	_sQuery += " 	 , SA1.A1_NOME         AS NOME_CLI"
  	_sQuery += " 	 , SA1.A1_MUN          AS CID_CLI"
  	_sQuery += " 	 , SD2.D2_EST          AS UF"
  	_sQuery += "     , SF2.F2_TPFRETE      AS TPFRETE"
  	_sQuery += "     , SF2.F2_PBRUTO       AS PESO_BRUTO"
  	_sQuery += "	 , SUM(SD2.D2_VALBRUT)           AS VLR_BRT"
  	_sQuery += "     , ISNULL(SUM(SZH1.RATEIO),0)    AS VLR_FRETE"
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
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES"
  	_sQuery += "			    AND SF4.F4_MARGEM IN ('1','3') )"
  	_sQuery += "	INNER JOIN SA1010 AS SA1"
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "				AND SA1.A1_LOJA  = SD2.D2_LOJA)"
	if mv_par13 != '      ' .and. mv_par13 != 'zzzzzz' .and. mv_par13 != 'ZZZZZZ'
		_sQuery += "     INNER JOIN (SELECT SUM(SZH.ZH_RATEIO) AS RATEIO"
	else
		_sQuery += "     LEFT JOIN (SELECT SUM(SZH.ZH_RATEIO) AS RATEIO"
	endif					
	_sQuery += "     			     , SZH.ZH_FILIAL"
	_sQuery += "     				 , SZH.ZH_NFSAIDA"
	_sQuery += "     				 , SZH.ZH_SERNFS"
	_sQuery += "     				 , SZH.ZH_ITNFS"
	_sQuery += "                  FROM " + RetSQLName ("SZH") + " SZH"
	_sQuery += "			     WHERE SZH.D_E_L_E_T_ = ''"
	if mv_par13 != '' .and. mv_par13 != 'zzzzzz' .and. mv_par13 != 'ZZZZZZ'
		_sQuery += "                   AND SZH.ZH_FORNECE = '004277'"
	endif
	_sQuery += "		  		 GROUP BY SZH.ZH_FILIAL, SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SZH.ZH_ITNFS) AS SZH1"
	_sQuery += "             ON (SZH1.ZH_FILIAL        = SD2.D2_FILIAL"		  		 
	_sQuery += "    			 AND SZH1.ZH_NFSAIDA   = SD2.D2_DOC"
	_sQuery += "    			 AND SZH1.ZH_SERNFS    = SD2.D2_SERIE"
	_sQuery += "    			 AND SZH1.ZH_ITNFS     = SD2.D2_ITEM)"
	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
    _sQuery += "   AND SD2.D2_EMISSAO   BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += "   AND SD2.D2_EST       BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "   AND SD2.D2_CLIENTE   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "   AND SD2.D2_LOJA      BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    _sQuery += " GROUP BY SD2.D2_FILIAL, SD2.D2_EMISSAO, SD2.D2_DOC ,SD2.D2_SERIE, SD2.D2_TIPO, SD2.D2_CLIENTE , SD2.D2_LOJA, SA1.A1_NOME, SA1.A1_MUN, SD2.D2_EST, SF2.F2_TPFRETE, SF2.F2_PBRUTO"
    
    //u_showmemo (_sQuery)
 	
 	u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
return
        
Static Function _GeraArq()
     incproc ("Gerando arquivo de exportacao")
     DbGoTop()
     processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
     (_sAliasQ) -> (dbclosearea ())
return

Static Function _Lista()
        // seta variaveis usadas no relatorio
        cString :="SF2"
        cDesc1  :="Este programa tem como objetivo, imprimir relatorio de"
        cDesc2  :="Analise de Fretes s/Saidas"
        cDesc3  :=""
        aLinha  :={ }
        nLastKey:=0
        titulo   :=""
        wnrel    :="FRT01XLS"            
        tamanho  :="G"
        aReturn :={ "Zebrado", 1,"Administracao", 1, 2, 1, "",1 }
        
        wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
        If nLastKey == 27
            Return
        Endif

        SetDefault(aReturn,cString)
        If nLastKey == 27
            Return
        Endif
        
        titulo   := "Analise de Fretes s/Saidas"
        titulo   += " - Período: " + dtoc(mv_par01) + ' até '+ dtoc(mv_par02)
        RptStatus({|| RptDetAnSin()})
         
return


Static Function RptDetAnSin()
    SetRegua(LastRec())
    nTipo     := IIF(aReturn[4]==1,15,18)
    li        := 80
    m_pag     := 1
    cabec1    := "    NOTA   SER  DT.EMISSAO   CLIENTE                                      CIDADE                   UF                                    PESO BRUTO    TOTAL DA NOTA   TOTAL FRETE   TIPO FRETE   FRETE/KG FRETE/PERCENT"
    cabec2    := ""
    
    _aTotGer  = {0,0,0,0,0,0}
    _nota     := " "
    // processa relatorio conforme opcao desejada
    	
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     
     	if mv_par12 == 2 
     		if (_sAliasQ) -> VLR_FRETE > 0 .or. (_sAliasQ) -> TPFRETE != 'C'  
     			(_sAliasQ) -> (dbskip())
    			loop
			endif     				
     	endif

        If li>62
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif
        @ li, 000 PSAY (_sAliasQ) -> NOTA
        //@ li, 010 PSAY (_sAliasQ) -> MARGEM
        @ li, 012 PSAY (_sAliasQ) -> SERIE
        @ li, 016 PSAY (_sAliasQ) -> DT_EMISSAO
        @ li, 029 PSAY (_sAliasQ) -> CLIENTE
        @ li, 037 PSAY substr( (_sAliasQ) -> NOME_CLI,1,33)
        @ li, 074 PSAY substr( (_sAliasQ) -> CID_CLI,1,20)
        @ li, 099 PSAY (_sAliasQ) -> UF
        @ li, 135 PSAY (_sAliasQ) -> PESO_BRUTO   Picture "@E 9,999,999.99" 
        @ li, 150 PSAY (_sAliasQ) -> VLR_BRT      Picture "@E 999,999,999.99"
        @ li, 167 PSAY (_sAliasQ) -> VLR_FRETE    Picture "@E 999,999.99"
        if (_sAliasQ) -> TPFRETE != '' 
        	@ li, 184 PSAY iif((_sAliasQ) -> TPFRETE ='C','CIF','FOB')
        endif	
        // calcula frete quilo e frete percentual
        _wfretekg   = ( _sAliasQ) -> VLR_FRETE  / (_sAliasQ) -> PESO_BRUTO 
        _wfreteperc = (( _sAliasQ) -> VLR_FRETE / (_sAliasQ) -> VLR_BRT)*100
        @ li, 193 PSAY _wfretekg   Picture "@E 9,999.99"
        @ li, 208 PSAY _wfreteperc Picture "@E 999.99 %"
        
        // total
        _aTotGer [1] += (_sAliasQ) -> PESO_BRUTO
       	_aTotGer [2] += (_sAliasQ) -> VLR_BRT
       	_aTotGer [3] += (_sAliasQ) -> VLR_FRETE
		li ++
        (_sAliasQ) -> (dbskip())
            
     enddo
     // imprime totais
     If li>62
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     li ++
     li ++
	 li ++
	 If li>62
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     // imprime totais por operacao
     //@ li, 005 PSAY "TOTAIS POR OPERACAO: "
     //li ++
     //li ++
	 // imprime total da venda
	 If li>62
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     @ li, 005 PSAY "TOTAIS "//1 - VENDAS:"
	 @ li, 135 PSAY _aTotGer [1] Picture "@E 9,999,999.99"
	 @ li, 150 PSAY _aTotGer [2] Picture "@E 999,999,999.99"
	 @ li, 167 PSAY _aTotGer [3] Picture "@E 999,999.99"
	 // calcula frete quilo e frete percentual
     _wfretekg   =  _aTotGer[3]  / _aTotGer[1]
     _wfreteperc = ( _aTotGer[3] / _aTotGer[2]) *100
     @ li, 193 PSAY _wfretekg   Picture "@E 9,999.99"
     @ li, 208 PSAY _wfreteperc Picture "@E 999.99 %"
     li ++
     If li>62
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     /*
     // imprime total de bonificacoes
 	 @ li, 005 PSAY "3 - BONIFICAÇÕES:"
	 @ li, 135 PSAY _aTotBonif[1] Picture "@E 9,999,999.99"
	 @ li, 150 PSAY _aTotBonif[2] Picture "@E 999,999,999.99"
	 @ li, 167 PSAY _aTotBonif[3] Picture "@E 999,999.99"
	 // calcula frete quilo e frete percentual
     _wfretekg   = _aTotBonif[3]  / _aTotBonif[1]
     _wfreteperc = (_aTotBonif[3]/ _aTotBonif[2]) *100
     @ li, 193 PSAY _wfretekg   Picture "@E 9,999.99"
     @ li, 208 PSAY _wfreteperc Picture "@E 999.99 %"
     If li>62
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     li ++
	 li ++
	 
     @ li, 005 PSAY "TOTAIS PARA ANALISE FRETE SOBRE SAIDAS ( VENDAS + BONIFICAÇÕES): "
     @ li, 135 PSAY _aTotVenda[1]+_aTotBonif[1] Picture "@E 9,999,999.99"
	 @ li, 150 PSAY _aTotVenda[2]+_aTotBonif[2] Picture "@E 999,999,999.99"
	 @ li, 167 PSAY _aTotVenda[3]+_aTotBonif[3] Picture "@E 999,999.99"
	 // calcula frete quilo e frete percentual
     _wfretekg   = (_aTotVenda[3]+_aTotBonif[3]) / (_aTotVenda[1]+_aTotBonif[1])
     _wfreteperc = ((_aTotVenda[3]+_aTotBonif[3]) / (_aTotVenda[2]+_aTotBonif[2])) *100
     @ li, 193 PSAY _wfretekg   Picture "@E 9,999.99"
     @ li, 208 PSAY _wfreteperc Picture "@E 999.99 %"
     li ++
     */
     (_sAliasQ) -> (dbclosearea ())
    
     U_ImpParam(62)
	 
     Set Device To Screen

     If aReturn[5]==1
        Set Printer TO
        dbcommitAll()
        ourspool(wnrel)
     Endif
     MS_FLUSH()
     
return
     
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Data emissao de              ?", "D", 8, 0,  "",   "   ", {},                        "Data inicial de digitacao dos conhecimentos de frete"})
	aadd (_aRegsPerg, {02, "Data emissao ate             ?", "D", 8, 0,  "",   "   ", {},                        "Data final de digitacao dos conhecimentos de frete"})
	aadd (_aRegsPerg, {03, "UF de                        ?", "C", 2, 0,  "",   "12 ", {},                        "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate                       ?", "C", 2, 0,  "",   "12 ", {},                        "UF final do cliente"})
	aadd (_aRegsPerg, {05, "Cliente de                   ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {06, "Cliente ate                  ?", "C", 6, 0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {07, "Loja de                      ?", "C", 2, 0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {08, "Loja ate                     ?", "C", 2, 0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {09, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        "Representante Inicial"})
	aadd (_aRegsPerg, {10, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        "Representante Final"})
	aadd (_aRegsPerg, {11, "Listar                       ?", "N", 1, 0,  "",   "   ", {"Relatório","Planilha"},   ""})
	aadd (_aRegsPerg, {12, "Apenas CIF c/valor zerado    ?", "N", 1, 0,  "",   "   ", {"Nao", "Sim"}, ""})
	aadd (_aRegsPerg, {13, "Fornecedor Transporte        ?", "C", 6, 0,  "",   "SA2", {},  ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return