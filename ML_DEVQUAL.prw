// Programa  : ML_DEVQUAL
// Autor     : Catia Cardoso
// Data      : 12/04/2016
// Descricao : Relatorio de devolucoes - especifico QUALIDADE
// 
// Historico de alteracoes:
// 03/04/2019 - Robert - Ajustada laitura H1_FILIAL (pretendo mudar para compartilhado).
//

// --------------------------------------------------------------------------
user function ML_DEVQUAL
	
private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SD1"
    cDesc1  := "Relatorio Devoluções - Qualidade"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_DEVQUAL"
    titulo  := "Relatorio Devoluções - Qualidade"
    wnrel   := "ML_DEVQUAL"
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
    cabec1 := "DT.DEVOLUCAO   PRODUTO                            LINHA                           		   QUANTIDADE            VALOR    CLIENTE                          MOTIVO DEVOLUCAO                                  A.RESP" 
    cabec2 := ""
    
    _sQuery := " "
    _sQuery += " SELECT dbo.VA_DTOC(SD1.D1_DTDIGIT)  AS DATA_DEV"
    _sQuery += "      , SD1.D1_COD      AS PROD_COD"
    _sQuery += " 	  , SD1.D1_DESCRI   AS PROD_DESC"
    _sQuery += " 	  , SB1.B1_VALINEN  AS LINHA_COD"
    _sQuery += " 	  , SH1.H1_DESCRI   AS LINHA_DESC"
    _sQuery += " 	  , SD1.D1_QUANT    AS QUANT"
    _sQuery += " 	  , SD1.D1_TOTAL    AS VALOR"
    _sQuery += " 	  , SA1.A1_COD      AS CLI_COD"
    _sQuery += " 	  , SA1.A1_NOME     AS CLI_NOME"
    _sQuery += " 	  , SD1.D1_MOTDEV   AS MOT_COD"
    _sQuery += " 	  , ZX5_02DESC      AS MOT_DESC
    _sQuery += " 	  , ZX5.ZX5_02RESP  AS MOT_RESP"
    _sQuery += "  FROM SD1010 AS SD1"
	_sQuery += " 	INNER JOIN SF4010 AS SF4"
	_sQuery += "         ON (SF4.D_E_L_E_T_    = ''"
	_sQuery += "             AND SF4.F4_CODIGO = SD1.D1_TES"
	_sQuery += "             AND SF4.F4_MARGEM = '2')"
	_sQuery += " 	INNER JOIN SA1010 AS SA1"
	_sQuery += "         ON (SA1.D_E_L_E_T_    = ''"
	_sQuery += "             AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sQuery += "             AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sQuery += " 	INNER JOIN SB1010 AS SB1"
	_sQuery += " 		ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += " 			AND SB1.B1_COD = SD1.D1_COD
	_sQuery += " 			AND SB1.B1_VALINEN BETWEEN '" + mv_par12 + "' AND '" + mv_par13 + "')"
	_sQuery += " 	INNER JOIN SH1010 AS SH1"
	_sQuery += " 		ON (SH1.D_E_L_E_T_ = ''"
//	_sQuery += "			AND SH1.H1_FILIAL = SD1.D1_FILIAL"
	_sQuery += "			AND SH1.H1_FILIAL = '" + xfilial ("SH1") + "'"
	_sQuery += " 			AND SH1.H1_CODIGO = SB1.B1_VALINEN)"
	_sQuery += " 	INNER JOIN ZX5010 AS ZX5"
	_sQuery += "         ON (ZX5.D_E_L_E_T_     = ''"
	_sQuery += "             AND ZX5.ZX5_TABELA = '02'"
	do case
		case mv_par05 == 2
			_sQuery +=   "   AND ZX5.ZX5_02RESP = 'A'"
		case mv_par05 == 3
			_sQuery +=   "   AND ZX5.ZX5_02RESP = 'C'"
		case mv_par05 == 4
			_sQuery +=   "   AND ZX5.ZX5_02RESP = 'I'"
	endcase
	_sQuery += "             AND ZX5.ZX5_02MOT = SD1.D1_MOTDEV)"
	_sQuery += " WHERE SD1.D_E_L_E_T_   = ''"
	_sQuery += "   AND SD1.D1_FILIAL    = '" + xfilial ("SD1")  + "'"
	_sQuery += "   AND SD1.D1_TIPO      = 'D'"
	_sQuery += "   AND SD1.D1_NFORI    != ''"
	_sQuery += "   AND SD1.D1_DTDIGIT   BETWEEN '" + dtos (mv_par01)   + "' AND '" + dtos (mv_par02)   + "'"
	_sQuery += "   AND SD1.D1_MOTDEV    BETWEEN '" + mv_par03          + "' AND '" + mv_par04          + "'"
	_sQuery += "   AND SD1.D1_FORNECE   BETWEEN '" + mv_par06          + "' AND '" + mv_par07          + "'"
	_sQuery += "   AND SD1.D1_LOJA      BETWEEN '" + mv_par08          + "' AND '" + mv_par09          + "'"
	_sQuery += "   AND SD1.D1_COD       BETWEEN '" + mv_par10          + "' AND '" + mv_par11          + "'"
	
	_sQuery += " ORDER BY SD1.D1_DTDIGIT, SD1.D1_DOC"						
	
	//u_showmemo (_sQuery)
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "D1_DTDIGIT", "D")
	
	if mv_par14 == 1  // gera em planilha
		processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		return
	endif
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    (_sAliasQ) -> (DBGoTop ())
    Do While ! (_sAliasQ) -> (Eof ())
    	If li>58
	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	    Endif
	    
	    @ li, 002 PSAY (_sAliasQ) -> DATA_DEV
	    @ li, 015 PSAY ALLTRIM((_sAliasQ) -> PROD_COD)  + ' - ' + SUBSTR((_sAliasQ) -> PROD_DESC,1,25)
	    @ li, 050 PSAY ALLTRIM((_sAliasQ) -> LINHA_COD) + ' - ' + SUBSTR((_sAliasQ) -> LINHA_DESC,1,20) 
	    @ li, 079 PSAY (_sAliasQ) -> QUANT     Picture "@E 999,999,999.9999"
	    @ li, 098 PSAY (_sAliasQ) -> VALOR     Picture "@E 999,999,999.99"
	    @ li, 116 PSAY ALLTRIM((_sAliasQ) -> CLI_COD) + ' - ' + SUBSTR((_sAliasQ) -> CLI_NOME,1,20)
	    @ li, 149 PSAY ALLTRIM((_sAliasQ) -> MOT_COD) + ' - ' + SUBSTR((_sAliasQ) -> MOT_DESC,1,40)
	    @ li, 201 PSAY (_sAliasQ) -> MOT_RESP

	    li ++
	 	(_sAliasQ) -> (dbskip())
    enddo
     
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
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                         Help
	aadd (_aRegsPerg, {01, "Data devolução de              ?", "D", 8,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {02, "Data devolução até             ?", "D", 8,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {03, "Motivo devolução de            ?", "C", 6,  0,  "",   "ZX502", {},                            ""})
	aadd (_aRegsPerg, {04, "Motivo devolução até           ?", "C", 6,  0,  "",   "ZX502", {},                            ""})
	aadd (_aRegsPerg, {05, "Area de Responsabilidade       ?", "N", 1,  0,  "",   "   ",   {"Totas", "Administrativo","Comercial","Industrial"}, "Indique a área de responsabilidade desejada."})
	aadd (_aRegsPerg, {06, "Cliente de                     ?", "C", 6,  0,  "",   "SA1",   {},                            ""})
	aadd (_aRegsPerg, {07, "Cliente até                    ?", "C", 6,  0,  "",   "SA1",   {},                            ""})
	aadd (_aRegsPerg, {08, "Loja cliente de                ?", "C", 2,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {09, "Loja cliente até               ?", "C", 2,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {10, "Produto de                     ?", "C", 15, 0,  "",   "SB1",   {},                            "Produto inicial a ser considerado."})
	aadd (_aRegsPerg, {11, "Produto até                    ?", "C", 15, 0,  "",   "SB1",   {},                            "Produto final a ser considerado."})
	aadd (_aRegsPerg, {12, "Linha de Envase de             ?", "C", 6,  0,  "",   "SH1",   {},                            "Linha de Envase inicial a ser considerado."})
	aadd (_aRegsPerg, {13, "Linha de Envase até            ?", "C", 6,  0,  "",   "SH1",   {},                            "Linha de Envase final a ser considerado."})
	aadd (_aRegsPerg, {14, "Gera em Planilha               ?", "N", 1,  0,  "",   "   ",   {"Sim", "Nao"},                "Indique se deseja gerar em planilha."})
	
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
