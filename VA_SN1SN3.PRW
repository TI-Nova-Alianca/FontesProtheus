// Programa...: VA_SN1SN3
// Autor......: Catia Cardoso
// Data.......: 25/11/2016
// Descricao..: Itens Imobilizado
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatorio
// #Descricao         #Relatorio simplificado de ativos e seus valores principais
// #PalavasChave      #relatorio #ativos #planilha
// #TabelasPrincipais #SN3 #SN1
// #Modulos           #ATF
//
// Historico de alteracoes:
// 13/02/2018 - Alteração para que nao traga itens baixados
// 15/02/2019 - Andre   - Adicionado coluna Depreciacao Acumulada (N3_VRDACM1) 
//                        e valor residual (SN3.N3_VORIG1 - SN3.N3_VRDACM1)
// 15/05/2019 - Catia   - alterar para que considere itens tipo 13 e 03 tambem
// 10/05/2021 - Robert  - Incluido N3_TIPO = 12 nas filtragens (GLPI 10000)
//                      - Query estava com os nomes de tabelas fixos. Passa a usar RetSQLName().
// 01/08/2023 - Claudia - Cast da data para realizar a impressão correta no arquivo excel. GLPI: 14027
//
// -------------------------------------------------------------------------------------------------------------
User Function VA_SN1SN3()
    Private cPerg    := "VA_SN1SN3"
   
    _ValidPerg()
    if Pergunte(cPerg,.T.)
            
    	_sQuery    := ""
    	_sAliasQ   := ""
    
	    _sQuery := ""
	    _sQuery += " SELECT SN1.N1_FILIAL   AS FILIAL"
	    _sQuery += "      , SN1.N1_CBASE    AS COD_BASE"
		_sQuery += "  	  , SN1.N1_ITEM     AS INCORPORACAO"
	    _sQuery += "  	  , SN1.N1_CHAPA    AS PLAQUETA"
		_sQuery += " 	  , SN1.N1_DESCRIC  AS DESCRICAO"
		_sQuery += " 	  , SN1.N1_GRUPO    AS GRU_COD"
		_sQuery += " 	  , SNG.NG_DESCRIC  AS GRU_DESCRICAO"
		_sQuery += " 	  , SN3.N3_CCONTAB  AS CTA"
		_sQuery += " 	  , SN3.N3_CUSTBEM  AS CCUSTO"
		_sQuery += " 	  , CTT.CTT_DESC01  AS CCUS_DESCRICAO"
	  	_sQuery += " 	  , SN1.N1_NFISCAL  AS NF_NUM"
		_sQuery += " 	  , SN1.N1_FORNEC	AS FORN_COD"
		_sQuery += " 	  , SN1.N1_QUANTD   AS QUANTIDADE"
		_sQuery += "	  ,CONVERT(VARCHAR(30), convert(datetime,convert(varchar,SN1.N1_AQUISIC),103), 103) AS DT_AQUI "
		_sQuery += " 	  , SN3.N3_VORIG1   AS VLR_AQUI"
		_sQuery += "      , ISNULL ((SELECT TOP 1 N3_VRDACM1" 
		_sQuery += "      FROM " + RetSQLName ("SN3") + " N1"
		_sQuery += "     		WHERE N1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND N1.N3_FILIAL = SN1.N1_FILIAL"
		_sQuery += " 				AND N1.N3_CBASE  = SN1.N1_CBASE"
		_sQuery += " 				AND N1.N3_ITEM   = SN1.N1_ITEM"
		_sQuery += " 				AND N1.N3_CCONTAB = SN3.N3_CCONTAB"
		_sQuery += " 				AND N1.N3_TIPO   IN ('10','13','12')) ,0) AS DPR_ACU"
		_sQuery += "      , ISNULL ((SELECT TOP 1 N3_VORIG1 -  N3_VRDACM1" 
		_sQuery += "      FROM " + RetSQLName ("SN3") + " N1"
		_sQuery += "     		WHERE N1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND N1.N3_FILIAL = SN1.N1_FILIAL"
		_sQuery += " 				AND N1.N3_CBASE  = SN1.N1_CBASE"
		_sQuery += " 				AND N1.N3_ITEM   = SN1.N1_ITEM"
		_sQuery += " 				AND N1.N3_CCONTAB = SN3.N3_CCONTAB"
		_sQuery += " 				AND N1.N3_TIPO   IN('10','13','12')) ,0) AS VLR_RES"
		_sQuery += "   FROM " + RetSQLName ("SN1") + " SN1"
		_sQuery += " 		INNER JOIN " + RetSQLName ("SN3") + " SN3"
		_sQuery += " 			ON (SN3.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SN3.N3_FILIAL = SN1.N1_FILIAL"
		_sQuery += " 				AND SN3.N3_CBASE  = SN1.N1_CBASE"
		_sQuery += " 				AND SN3.N3_ITEM   = SN1.N1_ITEM"
		_sQuery += " 				AND SN3.N3_DTBAIXA = ''"
		_sQuery += "                AND SN3.N3_CCONTAB BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
		_sQuery += "                AND SN3.N3_CUSTBEM BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
		_sQuery += " 				AND SN3.N3_TIPO   IN ('01','03','12') )"
		_sQuery += " 		LEFT JOIN " + RetSQLName ("SNG") + " AS SNG"
		_sQuery += " 			ON (SNG.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SNG.NG_GRUPO = SN1.N1_GRUPO)"
		_sQuery += " 		LEFT JOIN " + RetSQLName ("CT1") + " AS CT1"
		_sQuery += " 			ON (CT1.D_E_L_E_T_ = ''"
		_sQuery += " 				AND CT1.CT1_CONTA = SN3.N3_CCONTAB)"
		_sQuery += " 		LEFT JOIN " + RetSQLName ("CTT") + " AS CTT"
		_sQuery += " 			ON (CTT.D_E_L_E_T_ = ''"
		_sQuery += " 				AND CTT.CTT_CUSTO = SN3.N3_CUSTBEM)"
		_sQuery += " 		LEFT JOIN " + RetSQLName ("SA2") + " AS SA2"
		_sQuery += " 			ON (SA2.D_E_L_E_T_ = ''"
		_sQuery += " 				AND SA2.A2_COD = SN1.N1_FORNEC)"
	 	_sQuery += "   WHERE SN1.D_E_L_E_T_ = ''"
	 	_sQuery += "     AND SN1.N1_BAIXA = ''"
	 	_sQuery += "     AND SN1.N1_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	 	_sQuery += "     AND SN1.N1_AQUISIC BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	 	_sQuery += "     AND SN1.N1_FORNEC  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	 	_sQuery += "     AND SN1.N1_GRUPO BETWEEN '" + mv_par11 + "' AND '" + mv_par12 + "'"
	 	_sQuery += "  ORDER BY SN1.N1_CBASE, SN1.N1_ITEM"
	
	    //u_showmemo (_sQuery)
 	
	 	u_log (_sQuery)
	    _sAliasQ = GetNextAlias ()
	    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	    count to _nRecCount
	    procregua (_nRecCount)

		if mv_par13 = 1
			incproc ("Gerando arquivo de exportacao")
     		DbGoTop()
     		processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
     		(_sAliasQ) -> (dbclosearea ())
			return
		endif			

		// seta variaveis usadas no relatorio
		cString  :="SN1"
		cDesc1   :=""
		cDesc2   :=""
		cDesc3   :=""
		aLinha   :={ }
		titulo   :=""
		wnrel    :="VA_SN1SN3"            
		tamanho  :="G"
		aReturn  :={ "Zebrado", 1,"Administracao", 1, 2, 1, "",1 }
		
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	    SetDefault(aReturn,cString)
    
	    titulo   := "Itens do Imobilizado"
	    nTipo     := IIF(aReturn[4]==1,15,18)
		li        := 80
		m_pag     := 1
		//FIL COD_BASE   INC PLAQUETA DESCRICAO                           GRUPO               CONTA CONTABIL                CENTRO DE CUSTO       NOTA    SERIE FORNECEDOR                QUANT AQUISICAO  VLR_AQUISICAO   
		//001 0000057733 000 005408   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 0013-xxxxxxxxxxxxxx 103050105001-XXXXXXXXXXXXXXX  013002-XXXXXXXXXXXXXX 000111222 001 002525-xxxxxxxxxxxxxxxxxx  1,00 11/11/2016  1.150.000,00   	
		
		cabec1    := "FIL COD_BASE   INC PLAQUETA DESCRICAO                           GRUPO               CNT CONTABIL        CENTRO DE CUSTO       NOTA         FORNECEDOR      QUANT   AQUISICAO      VLR_AQUISICAO      DPR_ACU       VLR_RES"
		cabec2    := ""

		// impressao
	    (_sAliasQ) -> (DBGoTop ())
	     Do While ! (_sAliasQ) -> (Eof ())
	     
	        If li>62
	            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	        Endif
	     
	        @ li, 001 PSAY (_sAliasQ) -> FILIAL
	        @ li, 004 PSAY (_sAliasQ) -> COD_BASE
	        @ li, 015 PSAY SUBSTR(ALLTRIM((_sAliasQ) -> INCORPORACAO),1,3)
	        @ li, 020 PSAY (_sAliasQ) -> PLAQUETA
	        @ li, 029 PSAY SUBSTR((_sAliasQ) -> DESCRICAO,1,33)
	        @ li, 065 PSAY (_sAliasQ) -> GRU_COD + '-' + SUBSTR((_sAliasQ) -> GRU_DESCRICAO,1,13)
	        if ! empty((_sAliasQ) -> CTA)
	        	@ li, 085 PSAY ALLTRIM((_sAliasQ) -> CTA)//  + '-' + SUBSTR((_sAliasQ) -> CTA_DESCRICAO,1,15)
			endif	        
			if ! empty((_sAliasQ) -> CCUSTO)
	        	@ li, 105 PSAY ALLTRIM((_sAliasQ) -> CCUSTO)  + '-' + SUBSTR((_sAliasQ) -> CCUS_DESCRICAO,1,13)
			endif	        	
	        @ li, 127 PSAY (_sAliasQ) -> NF_NUM
	        if ! empty((_sAliasQ) -> FORN_COD)
	        	@ li, 140 PSAY ALLTRIM((_sAliasQ) -> FORN_COD)// + '-' + SUBSTR((_sAliasQ) -> FORN_NOME,1,15)
			endif	        	
	        @ li, 150 PSAY (_sAliasQ) -> QUANTIDADE Picture "@E 999,999.99"
	        @ li, 164 PSAY (_sAliasQ) -> DT_AQUI
	        @ li, 180 PSAY (_sAliasQ) -> VLR_AQUI   Picture "@E 9,999,999.99"
	        @ li, 193 PSAY (_sAliasQ) -> DPR_ACU    Picture "@E 9,999,999.99"
	        @ li, 207 PSAY (_sAliasQ) -> VLR_RES    Picture "@E 9,999,999.99"
	        
	        li ++
	        
	        (_sAliasQ) -> (dbskip())      
	     enddo
	     
	     U_ImpParam(62)
		 
	     Set Device To Screen
	
	     If aReturn[5]==1
	        Set Printer TO
	        dbcommitAll()
	        ourspool(wnrel)
	     Endif
	     
	     MS_FLUSH()
	     
     endif
return
//     
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//           			PERGUNT                         TIPO TAM DEC VALID F3     Opcoes                     Help
	aadd (_aRegsPerg, {01, "Filial de                    ?", "C",  2, 0,  "",  "SM0", {},    ""})
    aadd (_aRegsPerg, {02, "Filial até                   ?", "C",  2, 0,  "",  "SM0", {},    ""})
	aadd (_aRegsPerg, {03, "Data de Aquisição            ?", "D",  8, 0,  "",  "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Data de Aquisição            ?", "D",  8, 0,  "",  "   ", {},    ""})
	aadd (_aRegsPerg, {05, "Fornecedor de                ?", "C",  6, 0,  "",  "SA2", {},    ""})
	aadd (_aRegsPerg, {06, "Fornecedor até               ?", "C",  6, 0,  "",  "SA2", {},    ""})
	aadd (_aRegsPerg, {07, "Conta Contabil de            ?", "C", 12, 0,  "",  "CT1", {},    ""})
	aadd (_aRegsPerg, {08, "Conta Contabil ate           ?", "C", 12, 0,  "",  "CT1", {},    ""})
	aadd (_aRegsPerg, {09, "Centro de custo de           ?", "C",  9, 0,  "",  "CTT", {},    ""})
	aadd (_aRegsPerg, {10, "Centro de custo ate          ?", "C",  9, 0,  "",  "CTT", {},    ""})
	aadd (_aRegsPerg, {11, "Grupo de imobilizado de      ?", "C",  4, 0,  "",  "SNG", {},    ""})
	aadd (_aRegsPerg, {12, "Grupo de imobilizado ate     ?", "C",  4, 0,  "",  "SNG", {},    ""})
	aadd (_aRegsPerg, {13, "Gera planilha                ?", "N",  1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
