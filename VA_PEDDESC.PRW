//  Programa...: VA_PEDDESC
//  Autor......: Catia Cardoso
//  Data.......: 02/06/2016
//  Descricao..: Relatorio de Pedidos com Desconto 
// 
//  Historico de alterações
//  
//  03/06/2016 - criado parametro para consultar apenas pedidos com frete FOB - tendo a possibilidade de consultar todos
//
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_PEDDESC()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SC5"
    cDesc1  := "Relatorio de Pedidos Com Desconto"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "VA_PEDDESC"
    titulo  := "Relatorio de Pedidos Com Desconto"
    wnrel   := "VA_PEDDESC"
    nTipo   := 0
	
    _ValidPerg()
    Pergunte(cPerg,.F.)
    
    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

    If nLastKey == 27
	   Return
    Endif
    SetDefault(aReturn,cString)
    If nLastKey == 27
	   Return
    Endif
    
    RptStatus({|| RptDetail()})
Return


Static Function RptDetail()

    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1 := "PEDIDO   DT.FATURAMENTO   NOTA FISCAL   CLIENTE                                         MUNICIPIO                            ESTADO             	                  PESO       PREÇO VENDA      PREÇO TABELA      DIF/DESCONTO"
    cabec2 := "                                        USUARIO                                         TRANSPORTADOR                        VENDEDOR"                   
    // le tabela de coordenadores / externos - conforme intervalo solicitado
	_sQuery := ""
	_sQuery += " WITH C AS ( SELECT SC5.C5_NUM, SC6.C6_DATFAT, SC6.C6_NOTA, SC5.C5_CLIENTE, SA1.A1_NOME"
 	_sQuery += " 				  , SC5.C5_VAMUN, SC5.C5_VAEST, SC5.C5_VEND1, SA3.A3_NOME"
 	_sQuery += " 				  , SC5.C5_VAUSER, SF2.F2_TRANSP, SA4.A4_NOME, SF2.F2_PBRUTO"
 	_sQuery += " 				  , SC6.C6_PRCVEN*SC6.C6_QTDVEN AS PR_VENDA"
 	_sQuery += " 				  , SC6.C6_PRUNIT*SC6.C6_QTDVEN AS PR_TABELA"
 	_sQuery += " 				  , (SC6.C6_PRUNIT*SC6.C6_QTDVEN)-(SC6.C6_PRCVEN*SC6.C6_QTDVEN) AS DIF_PRECO"
 	_sQuery += " 				  , SC5.C5_MENNOTA"
 	_sQuery += " 				  , REPLACE(ISNULL(REPLACE (REPLACE ( REPLACE ( CAST(RTRIM (CAST (SC5.C5_OBS AS VARBINARY (8000))) AS VARCHAR (8000)) , char(13), ''), char(10), ''), char(14), ''),''),char(34),' ') AS OBSPED"
	_sQuery += " 			   FROM SC6010 AS SC6"
	_sQuery += " 					INNER JOIN SC5010 AS SC5"
	_sQuery += " 						ON (SC5.D_E_L_E_T_ = ''"
	_sQuery += " 							AND SC5.C5_FILIAL  = SC6.C6_FILIAL"
	_sQuery += " 							AND SC5.C5_NUM     = SC6.C6_NUM"
	if mv_par10 == 2 
		_sQuery += " 						AND SC5.C5_TPFRETE = 'F'"
	endif		
	_sQuery += " 							AND SC5.C5_TIPO    = 'N'"
	_sQuery += "                            AND SC5.C5_VAEST   BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_sQuery += "                            AND SC5.C5_VEND1   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sQuery += "                            AND SC5.C5_CLIENTE BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sQuery += " 							AND SC5.C5_OBS IS NOT NULL)"
	_sQuery += " 					INNER JOIN SF4010 AS SF4"
	_sQuery += " 						ON (SF4.F4_CODIGO = SC6.C6_TES"
	_sQuery += " 							AND SF4.F4_MARGEM = '1')"
	_sQuery += " 					INNER JOIN SA1010 AS SA1"
	_sQuery += " 						ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += " 							AND SA1.A1_COD = SC5.C5_CLIENTE)"
	_sQuery += " 					INNER JOIN SA3010 AS SA3"
	_sQuery += " 						ON (SA3.D_E_L_E_T_ = ''"
	_sQuery += " 							AND SA3.A3_COD = SC5.C5_VEND1)"
	_sQuery += " 					INNER JOIN SF2010 AS SF2"
	_sQuery += " 						ON (SF2.D_E_L_E_T_ = ''"
	_sQuery += " 							AND SF2.F2_FILIAL = SC6.C6_FILIAL"
	_sQuery += " 							AND SF2.F2_DOC    = SC6.C6_NOTA"
	_sQuery += " 							AND SF2.F2_SERIE  = SC6.C6_SERIE"
	_sQuery += " 							AND SF2.F2_TRANSP != '032'"	
	_sQuery += " 							AND SF2.F2_EMISSAO = SC6.C6_DATFAT)"
	_sQuery += " 					INNER JOIN SA4010 AS SA4"
	_sQuery += " 						ON (SA4.D_E_L_E_T_ = ''"
	_sQuery += " 							AND SA4.A4_COD = SF2.F2_TRANSP)"
	_sQuery += " 			  WHERE SC6.D_E_L_E_T_ = ''"
	_sQuery += " 				AND SC6.C6_FILIAL  = '" + xfilial ("SC6") + "'"
	_sQuery += " 				AND SC6.C6_DATFAT  BETWEEN  '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sQuery += " 				AND SC6.C6_NOTA   != ''"
	_sQuery += " 				AND SC6.C6_PRUNIT > 0"
	//_sQuery += " 				AND SC6.C6_PRUNIT > SC6.C6_PRCVEN 
	_sQuery += " )"
	_sQuery += " SELECT C.C5_NUM AS PEDIDO, C.C6_DATFAT AS DATAFAT, C.C6_NOTA AS NOTA, C.C5_CLIENTE AS CLI_COD, C.A1_NOME AS CLI_NOME"
 	_sQuery += " 	  , C.C5_VAMUN AS CLI_MUN, C.C5_VAEST AS CLI_EST, C.C5_VEND1 AS VEND_COD, C.A3_NOME AS VEND_NOME"
 	_sQuery += "      , C.C5_VAUSER AS USUARIO, C.F2_TRANSP AS TRANSP_COD, C.A4_NOME AS TRANSP_NOME, C.F2_PBRUTO AS PESO"
 	_sQuery += "      , SUM(C.PR_VENDA) AS PR_VENDA"
 	_sQuery += "      , SUM(C.PR_TABELA) AS PR_TABELA"
 	_sQuery += "      , ROUND(SUM(C.PR_TABELA)-SUM(C.PR_VENDA),2) AS DIF_PRECO"
 	_sQuery += "      , C.C5_MENNOTA AS MEN_NOTA, C.OBSPED AS OBS_PED"
	_sQuery += " FROM C"
	_sQuery += " GROUP BY C5_NUM, C6_DATFAT, C6_NOTA, C5_CLIENTE, A1_NOME, C5_VAMUN, C5_VAEST, C5_VEND1, A3_NOME, C5_VAUSER, F2_TRANSP, A4_NOME, F2_PBRUTO, C5_MENNOTA, OBSPED"
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	
	(_sAliasQ) -> (DBGoTop ())
    _wtot1 := 0
	_wtot2 := 0
	_wtot3 := 0
	_wtot4 := 0
	Do While ! (_sAliasQ) -> (Eof ())
    	If li>63
	        cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    // verifica usuario
	    if mv_par09 != 'ZZZ' .and. mv_par09 != 'zzz' 
	 		if PswSeek(mv_par09, .T.)
				_aUser := PswRet ()
				_wnomeUser = _aUser [1, 2]
				if ALLTRIM(_wnomeUser) != ALLTRIM((_sAliasQ) -> USUARIO)
					(_sAliasQ) -> (dbskip())
					loop
    			endif    			
			endif
		endif							
    	// imprime linha 1
		@ li, 000 PSAY (_sAliasQ) -> PEDIDO
		@ li, 013 PSAY stod((_sAliasQ) -> DATAFAT)
		@ li, 028 PSAY (_sAliasQ) -> NOTA
		@ li, 040 PSAY ALLTRIM((_sAliasQ) -> CLI_COD) + ' - ' + LEFT(ALLTRIM((_sAliasQ) -> CLI_NOME),35)
		@ li, 088 PSAY LEFT(ALLTRIM((_sAliasQ) -> CLI_MUN),20)
 		@ li, 125 PSAY (_sAliasQ) -> CLI_EST
 		li ++
 		// imprime linha 2
 		@ li, 040 PSAY LEFT(ALLTRIM((_sAliasQ) -> USUARIO),15)
 		@ li, 088 PSAY ALLTRIM((_sAliasQ) -> TRANSP_COD) + ' - ' + LEFT(ALLTRIM((_sAliasQ) -> TRANSP_NOME),20)
 		@ li, 125 PSAY ALLTRIM((_sAliasQ) -> VEND_COD) + ' - ' + LEFT(ALLTRIM((_sAliasQ) -> VEND_NOME),20)
 		@ li, 152 PSAY (_sAliasQ) -> PESO      Picture "@E 9,999,999.9999"
 		@ li, 168 PSAY (_sAliasQ) -> PR_VENDA  Picture "@E 9,999,999,999.99"
 		@ li, 186 PSAY (_sAliasQ) -> PR_TABELA Picture "@E 9,999,999,999.99"
 		@ li, 203 PSAY (_sAliasQ) -> DIF_PRECO Picture "@E 9,999,999,999.99"
 		li ++
 		// imprime linha 3
 		if !EMPTY((_sAliasQ) -> MEN_NOTA)
	 		@ li, 040 PSAY LEFT( ALLTRIM( (_sAliasQ) -> MEN_NOTA) , 150)
	 		li ++
 		endif
 		// imprime linha 4
 		if (_sAliasQ) -> OBS_PED != ''
	 		@ li, 040 PSAY LEFT( ALLTRIM( (_sAliasQ) -> OBS_PED)  , 150)
	 		li ++
		endif	 		
 		li ++
 		// acumula totais
	    _wtot1 = _wtot1 + (_sAliasQ) -> PESO
		_wtot2 = _wtot2 + (_sAliasQ) -> PR_VENDA
		_wtot3 = _wtot3 + (_sAliasQ) -> PR_TABELA
		_wtot4 = _wtot4 + (_sAliasQ) -> DIF_PRECO
	 	(_sAliasQ) -> (dbskip())
    enddo
    // imprime total do periodo 
    li ++
    If li>63
	   cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	Endif
	
	@ li, 125 PSAY 'Totais:'
    @ li, 152 PSAY _wtot1 Picture "@E 9,999,999.9999"
	@ li, 168 PSAY _wtot2 Picture "@E 9,999,999,999.99"
	@ li, 186 PSAY _wtot3 Picture "@E 9,999,999,999.99"
	@ li, 203 PSAY _wtot4 Picture "@E 9,999,999,999.99"
	li ++
	
	U_ImpParam (63)
	 
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
    aadd (_aRegsPerg, {01, "Dt.Faturamento   ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Dt.Faturamento   ?", "D", 8, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "UF de            ?", "C", 2, 0,  "",   "12 ", {},  "UF inicial do cliente"})
	aadd (_aRegsPerg, {04, "UF ate           ?", "C", 2, 0,  "",   "12 ", {},  "UF final do cliente"})
	aadd (_aRegsPerg, {05, "Representante    ?", "C", 3, 0,  "",   "SA3", {},  ""})
	aadd (_aRegsPerg, {06, "Representante    ?", "C", 3, 0,  "",   "SA3", {},  ""})
	aadd (_aRegsPerg, {07, "Cliente de       ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {08, "Cliente até      ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {09, "Usuário          ?", "C", 6, 0,  "",   "USR", {},  ""})
	aadd (_aRegsPerg, {10, "Apenas Frete FOB ?", "N", 1, 0,  "",   "   ", {"Nao", "Sim"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return