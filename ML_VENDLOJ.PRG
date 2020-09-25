//  Programa...: ML_VENDLOJ
//  Autor......: Catia Cardoso
//  Data.......: 01/09/2017
//  Descricao..: relatorio de compras de funcionarios
//  Historico de alteracoes:
//

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_VENDLOJ()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SL1"
    cDesc1  := "Relatório Compras de Funcionários"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório de Compras de Funcionarios"
    cPerg   := "ML_VENDLOJ"
    wnrel   := "ML_VENDLOJ"
    nTipo   := 0
    
    _ValidPerg()
    if Pergunte(cPerg,.T.)
    	titulo  := "Relatório de Vendas da Loja - Período : " + dtoc(mv_par01) + " até " + dtoc(mv_par02)
    	
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
	local _nTPPROD	:= 0
	local _nPROD	:= 0
	
    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    
    _aTotGer    = {0,0,0}
    _aTotFunc   = {0,0,0}
    _aTotAssoc  = {0,0,0}
	
	
	_aTPPROD := {}
	_aPROD   := {}
	_nTPPROD := 0
	_nPROD   := 0
			        
    cabec1  :=" FL  DT.EMISSAO  CUPOM    ITEM   DESCRICAO                                                  TIPO  QUANT    VLR.UNIT VLR.DESCONTO 	    VLR.TOTAL  TABELA    VLR.TABELA CLIENTE/CONTATO	                    OBERVAÇÕES"
    cabec2  :=""

	_sSQL := " "
	_sSQL += " SELECT SL2.L2_FILIAL				  AS FILIAL"
    _sSQL += "      , dbo.VA_DTOC(SL2.L2_EMISSAO) AS DTEMIS"
	_sSQL += "      , SL2.L2_DOC				  AS DOC"
	_sSQL += "		, SL2.L2_SERIE				  AS SERIE"
	_sSQL += "      , SL2.L2_PRODUTO			  AS PRODUTO"
	_sSQL += "		, SB1.B1_DESC				  AS DESCR"
	_sSQL += "      , SD2.D2_TP					  AS TPPROD"
	_sSQL += "      , SL2.L2_QUANT				  AS QUANT"
	_sSQL += "		, SL2.L2_VRUNIT				  AS VLRUNIT"
	_sSQL += "		, SL2.L2_VLRITEM			  AS VLRITEM"
	_sSQL += "      , SL2.L2_DESC				  AS DESCPER"
	_sSQL += "		, SL2.L2_VALDESC			  AS DESCVLR"
	_sSQL += "      , SD2.D2_CUSTO1				  AS CUSTMED"
	_sSQL += "      , SB1.B1_CUSTD				  AS CUSTSTAND"
	_sSQL += "      , (SB1.B1_CUSTD * SL2.L2_QUANT) AS CSTATOT"
	_sSQL += "      , SL2.L2_PRCTAB				  AS VLRTAB"
	_sSQL += "  	, SL2.L2_TABELA				  AS TABELA"
	_sSQL += " 	 	, CASE WHEN (SL1.L1_CONTATO != '000000' AND SL1.L1_CONTATO != '') THEN SL1.L1_CONTATO"
	_sSQL += " 	 		   ELSE SL1.L1_CLIENTE END  AS CONTCOD"
	_sSQL += "		, (CASE WHEN (SL1.L1_CONTATO != '000000' AND SL1.L1_CONTATO != '')  THEN (SELECT SU5.U5_CONTAT"
	_sSQL += "																			 FROM SU5010 AS SU5"
	_sSQL += "																			WHERE SU5.U5_CODCONT = SL1.L1_CONTATO"
	_sSQL += "																			  AND SU5.D_E_L_E_T_ = '')"
	_sSQL += "		        WHEN SL1.L1_CLIENTE != '000000' THEN (SELECT A1_NOME"
	_sSQL += "										                FROM SA1010 AS SA1"
	_sSQL += "										               WHERE SA1.A1_COD = SL1.L1_CLIENTE"
	_sSQL += "														 AND SA1.D_E_L_E_T_ = '')"
	_sSQL += "				ELSE 'CONSUMIDOR FINAL' END) AS CONTNOM"
	_sSQL += "  	, SL1.L1_CGCCLI 		AS CGC"
	_sSQL += "  	, ISNULL((CASE WHEN SL1.L1_CGCCLI != '' THEN (SELECT CASE WHEN ZAD.ZAD_SITUA IN ('1','2') THEN 'SIM'"
	_sSQL += "                                                      ELSE 'DESLIGADO' END AS FUNCIONARIO"
	_sSQL += " 											   			FROM ZAD010 AS ZAD"
	_sSQL += " 											  		   WHERE ZAD.ZAD_CPF = SL1.L1_CGCCLI"
	_sSQL += " 											    		 AND ZAD.D_E_L_E_T_ = '')" 
	_sSQL += " 		   ELSE '' END ),'') 	AS FUNCIONARIO"
	_sSQL += "  	, ISNULL((CASE WHEN SL1.L1_CGCCLI != '' THEN (SELECT TOP 1 'SIM'"
	_sSQL += " 									     			    FROM SA2010 AS SA2"
	_sSQL += " 									    			   WHERE SA2.A2_CGC = SL1.L1_CGCCLI"
	_sSQL += " 										  				 AND SA2.D_E_L_E_T_ = '')"
	_sSQL += "        ELSE '' END ),'') 	AS ASSOCIADO"
  	_sSQL += " 	 FROM SL2010 AS SL2"
	_sSQL += " 		INNER JOIN SD2010 AS SD2"
	_sSQL += " 			ON (SD2.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SD2.D2_FILIAL = SL2.L2_FILIAL"
	_sSQL += " 				AND SD2.D2_DOC    = SL2.L2_DOC"
	_sSQL += " 				AND SD2.D2_SERIE  = SL2.L2_SERIE"
	_sSQL += " 				AND SD2.D2_ITEM   = SL2.L2_ITEM"
	_sSQL += " 				AND SD2.D2_COD    = SL2.L2_PRODUTO)"
	_sSQL += " 		INNER JOIN SA1010 AS SA1"
	_sSQL += " 			ON (SA1.D_E_L_E_T_  = ''"
	_sSQL += " 				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sSQL += " 				AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SB1.B1_COD = SD2.D2_COD)"
	_sSQL += " 		INNER JOIN SL1010 AS SL1"
	_sSQL += " 			ON (SL1.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SL1.L1_FILIAL = SL2.L2_FILIAL"
	_sSQL += " 				AND SL1.L1_DOC    = SL2.L2_DOC"
	_sSQL += " 				AND SL1.L1_SERIE  = SL2.L2_SERIE)"
 	_sSQL += "  WHERE SL2.D_E_L_E_T_ = ''"
    _sSQL += " 	  AND SL2.L2_FILIAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _sSQL += "    AND SL2.L2_SERIE = '001'"
    _sSQL += "    AND SL2.L2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sSQL += " 	  AND SL2.L2_PRODUTO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sSQL += " ORDER BY SL2.L2_EMISSAO, SL2.L2_SERIE, SL2.L2_DOC"
	
	u_showmemo(_sSQL)

	_sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sSQL), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     	   
			If li>67
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif
			
			if mv_par08 == 2           	
	           	@li,  01 PSAY (_sAliasQ) -> FILIAL
			    @li,  05 PSAY (_sAliasQ) -> DTEMIS
				@li,  17 PSAY (_sAliasQ) -> DOC
				@li,  25 PSAY ALLTRIM((_sAliasQ) -> PRODUTO)
				@li,  32 PSAY (_sAliasQ) -> DESCR
				@li,  93 PSAY (_sAliasQ) -> TPPROD
				@li,  98 PSAY (_sAliasQ) -> QUANT		Picture "@E 9999"
				@li, 105 PSAY (_sAliasQ) -> VLRUNIT		Picture "@E 99,999.99"
				@li, 118 PSAY (_sAliasQ) -> DESCVLR     Picture "@E 99,999.99"
				@li, 132 PSAY (_sAliasQ) -> VLRITEM		Picture "@E 99,999.99"
				@li, 147 PSAY (_sAliasQ) -> TABELA
				@li, 154 PSAY (_sAliasQ) -> VLRTAB		Picture "@E 99,999.99"
				if (_sAliasQ) -> CONTCOD != '000000'
					@li, 165 PSAY (_sAliasQ) -> CONTCOD + '-' + SUBSTR(CONTNOM,1,25)
				endif
				if (_sAliasQ) -> FUNCIONARIO = 'SIM'					
					@li, 200 PSAY 'Funcionario'
					_aTotFunc [1] += (_sAliasQ) -> VLRITEM
				elseif (_sAliasQ) -> ASSOCIADO = 'SIM' 					
					@li, 200 PSAY 'Associado'
					_aTotAssoc [1] += (_sAliasQ) -> VLRITEM
				elseif (_sAliasQ) -> CUSTMED > (_sAliasQ) ->VLRITEM
					if mv_par07 == 1
						@li, 200 PSAY 'Abaixo Custo'
					endif											  						
				endif					
	           	li:=li + 1
           	endif
			// --- acumula total geral
			_aTotGer [1] += (_sAliasQ) -> VLRITEM
			// --- acumula totais por tipo de produto
			_nTPPROD = ascan ( _aTPPROD, {|_aVal| _aVal [1] == (_sAliasQ) -> TPPROD})
			if _nTPPROD == 0
				aadd (_aTPPROD, {(_sAliasQ) -> TPPROD, alltrim(fbuscacpo ("SX5", 1 , xFilial("SX5")+ "02" + (_sAliasQ) -> TPPROD , "X5_DESCRI"))  , 0,0,0,0,0})
				_nTPPROD = len (_aTPPROD)
			endif
			_aTPPROD [_nTPPROD, 3] += (_sAliasQ) -> VLRITEM
			// --- acumula totais por produto
			_nPROD = ascan (_aPROD, {|_aVal| _aVal [1] == (_sAliasQ) -> PRODUTO})
			if _nPROD == 0
				aadd (_aPROD, {(_sAliasQ) -> PRODUTO, alltrim((_sAliasQ) -> DESCR), 0,0,0,0,0})
				_nPROD = len (_aPROD)
			endif
			_aPROD [_nPROD, 3] += (_sAliasQ) -> VLRITEM
			_aPROD [_nPROD, 4] += (_sAliasQ) -> QUANT 
			
			(_sAliasQ) -> (dbskip())
     enddo
					
	if li>67
    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif     

    li:=li + 2   
	@ li,  50 PSAY "TOTAL GERAL:"
	@ li, 129 PSAY _aTotGer [1] Picture "@E 99,999,999.99"
	li:=li + 2
	@ li,  50 PSAY "Venda pra Funcionarios:"
	@ li, 129 PSAY _aTotFunc [1] Picture "@E 99,999,999.99"
	li++
	@ li,  50 PSAY "Venda pra Associados:"
	@ li, 129 PSAY _aTotAssoc [1] Picture "@E 99,999,999.99"
	li++
	@ li,  50 PSAY "Venda pra Consumidor Final:"
	@ li, 129 PSAY _aTotGer [1] - (_aTotFunc [1] + _aTotAssoc [1]) Picture "@E 99,999,999.99"
	li++
	
	// imprime totais por tipo de produto
	if len (_aTPPROD) > 0
		if li > 67
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		endif
		_aTPPROD = asort (_aTPPROD,,, {|_x, _y| _x [1] < _y [1]})
		@ li, 50 psay "Totais por Tipo de Produto:"
		li ++
		@ li, 50 psay "--------------------------------------------------------------------------------------------"
		li ++
		for _nTPPROD = 1 to len (_aTPPROD)
			if li > 67 - 2
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 50 psay U_TamFixo (_aTPPROD [_nTPPROD, 1] + " - " + _aTPPROD [_nTPPROD, 2], 30) + "                                                " + ;
						 transform (_aTPPROD [_nTPPROD, 3], "@E 999,999,999.99")  
			li ++
		next
		@ li, 50 psay "--------------------------------------------------------------------------------------------"
		li ++
		li ++
		li ++
	endif
	// imprime por produto
	if len (_aTPPROD) > 0
		if li > 67
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
		endif
		_aPROD = asort (_aPROD,,, {|_x, _y| _x [1] < _y [1]})
		@ li, 50 psay "Totais por Produto:"
		li ++
		@ li, 50 psay "--------------------------------------------------------------------------------------------"
		li ++
		for _nPROD = 1 to len (_aPROD)
			if li > 67
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 50 psay U_TamFixo (alltrim(_aPROD [_nPROD, 1]) + " - " + _aPROD [_nPROD, 2], 30) + "                   " + ;
						transform (_aPROD [_nPROD, 4], "@E 9999") + "                         " + ;
			            transform (_aPROD [_nPROD, 3], "@E 999,999,999.99")  
			li ++
		next
		@ li, 50 psay "--------------------------------------------------------------------------------------------"
		li ++
		li ++
	endif
	
	U_ImpParam (60)
	      
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
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes       Help
    aadd (_aRegsPerg, {01, "Data da Venda de             ?", "D", 8, 0,  "",  "   ", {},             ""})
    aadd (_aRegsPerg, {02, "Data de Venda até            ?", "D", 8, 0,  "",  "   ", {},             ""})
    aadd (_aRegsPerg, {03, "Filial de                    ?", "C", 2, 0,  "",  "SM0", {},             ""})
    aadd (_aRegsPerg, {04, "Filial até                   ?", "C", 2, 0,  "",  "SM0", {},             ""})
    aadd (_aRegsPerg, {05, "Produto de                   ?", "C", 6, 0,  "",  "SB1", {},             ""})
	aadd (_aRegsPerg, {06, "Produto ate                  ?", "C", 6, 0,  "",  "SB1", {},             ""})
	aadd (_aRegsPerg, {07, "Sinaliza itens abaixo custo  ?", "N", 1, 0,  "",  "   ", {"Sim", "Não"}, ""})
	aadd (_aRegsPerg, {08, "Opção                        ?", "N", 1,  0,  "",   "   ", {"Sintético", "Analitico"}  , ""})
	

    U_ValPerg (cPerg, _aRegsPerg)
Return