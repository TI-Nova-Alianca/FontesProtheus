// Programa...: ML_RECEBIMENTO
// Autor......: Catia Cardoso
// Data.......: 13/11/2014
// Cliente....: Alianca
// Descricao..: Relatório de Recebimentos
//
// Historico de alteracoes:
// 21/11/2014 - Incluido nro do pedido e solicitante no relatorio e opcao de listar notas de devolução
// 23/01/2015 - Estava errada a variavel cString - e trazia a tabela errada nos filtros
// 30/01/2015 - Incluido intervalo de produto
// 22/01/2016 - Estava acessando o Xfilial com a string errada


#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_RECEBIMENTO()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SD1"
    cDesc1  := "Relatorio de Recebimentos"
    cDesc2  := ""
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_RECEBIMENTO"
    titulo  := "Relatório de Recebimentos"
    wnrel   := "ML_RECEBIMENTO"
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

return

Static Function RptDetail()

    SetRegua(LastRec())
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    cabec1:="CODIGO DESCRICAO                                     UNIDADE   ARM        QUANTIDADE     EMISSAO    DIGITACAO  RECEBIMENTO  DOCUMENTO  SERIE  FORNECEDOR  LJ  RAZAO SOCIAL                       PEDIDO   SOLICITANTE"
    cabec2:=""
    
    _sQuery := " "
    _sQuery += " SELECT SD1.D1_COD      AS COD_PROD"
    _sQuery += "      , SB1.B1_DESC     AS DESCRICAO"
    _sQuery += "      , SD1.D1_UM       AS UM"
    _sQuery += "      , SD1.D1_QUANT    AS QUANT"
    _sQuery += "      , SD1.D1_LOCAL    AS ARM"
    _sQuery += "      , SF1.F1_EMISSAO  AS EMISSAO"
    _sQuery += "      , SF1.F1_DTDIGIT  AS DIGIT"
    _sQuery += "      , SF1.F1_RECBMTO  AS RECEBIMENTO"     
    _sQuery += "      , SF1.F1_DOC      AS DOC"
    _sQuery += "      , SF1.F1_SERIE    AS SERIE"
    _sQuery += "      , SF1.F1_FORNECE  AS FORNECE"
    _sQuery += "      , SF1.F1_LOJA     AS LJ"
    _sQuery += "      , SA2.A2_NOME     AS NOME"
    _sQuery += "	  , SD1.D1_PEDIDO   AS PEDIDO"
	_sQuery += "      , SC1.C1_SOLICIT  AS SOLICITANTE"
    _sQuery += "   FROM " + RetSQLName ("SF1") + " AS SF1 "
    _sQuery += "   INNER JOIN " + RetSQLName ("SD1") + " AS SD1 "
    _sQuery += "          ON (SD1.D_E_L_E_T_ = ''" 
    _sQuery += "              AND SD1.D1_DOC     = SF1.F1_DOC"
    _sQuery += "              AND SD1.D1_SERIE   = SF1.F1_SERIE"
    _sQuery += "              AND SD1.D1_FORNECE = SF1.F1_FORNECE" 
    _sQuery += "              AND SD1.D1_COD     BETWEEN '" + mv_par04 + "' AND '" + mv_par05 + "'"
    _sQuery += "              AND SD1.D1_LOJA    = SF1.F1_LOJA)"
    _sQuery += "    LEFT JOIN SC1010 AS SC1 " 
    _sQuery += "           ON (SC1.D_E_L_E_T_     = ''"
    _sQuery += "               AND SC1.C1_PEDIDO  = SD1.D1_PEDIDO"
    _sQuery += "               AND SC1.C1_ITEM    = SD1.D1_ITEMPC)"
    _sQuery += "    INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
    _sQuery += "           ON (SB1.D_E_L_E_T_ = '' "
    _sQuery += "               AND SB1.B1_COD     = SD1.D1_COD)"
    _sQuery += "    INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
    _sQuery += "           ON (SA2.D_E_L_E_T_ = '' "
    _sQuery += "               AND SA2.A2_COD     = SF1.F1_FORNECE" 
    _sQuery += "               AND SA2.A2_LOJA    = SF1.F1_LOJA)"
    _sQuery += "   WHERE SF1.F1_FILIAL = '" + xFilial('SF1') + "' "
    _sQuery += "     AND SF1.D_E_L_E_T_ = ''"
    _sQuery += "     AND SF1.F1_ESPECIE = 'SPED'"
    if mv_par03 = 2 
    	_sQuery += "     AND SF1.F1_TIPO   != 'D'"
    endif
    _sQuery += "     AND SF1.F1_RECBMTO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sQuery += "   ORDER BY D1_COD"
    
    //u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
           
           If li>58
                cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           Endif
           
           @li, 000 PSAY (_sAliasQ) -> COD_PROD
           @li, 008 PSAY left((_sAliasQ) -> DESCRICAO ,43)
           @li, 059 PSAY (_sAliasQ) -> UM
           @li, 065 PSAY (_sAliasQ) -> ARM
           @li, 069 PSAY (_sAliasQ) -> QUANT Picture "@E 9,999,999,999.99"
           @li, 087 PSAY stod((_sAliasQ) -> EMISSAO)
           @li, 101 PSAY stod((_sAliasQ) -> DIGIT)
           @li, 113 PSAY stod((_sAliasQ) -> RECEBIMENTO)
           @li, 125 PSAY (_sAliasQ) -> DOC
           @li, 138 PSAY (_sAliasQ) -> SERIE
           @li, 147 PSAY (_sAliasQ) -> FORNECE
           @li, 155 PSAY (_sAliasQ) -> LJ
           @li, 159 PSAY left ((_sAliasQ) -> NOME ,30)
           @li, 194 PSAY (_sAliasQ) -> PEDIDO
           @li, 203 PSAY left ((_sAliasQ) -> SOLICITANTE ,15)
           
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

return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Recebimento de          ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Data Recebimento ate         ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Lista Devoluções de Venda?    ", "N", 01, 0,  "",   "      ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {04, "Produto de                    ", "C", 6,  0,  "",   "SB1", {},                        "Produto Inicial"})
	aadd (_aRegsPerg, {05, "Produto ate                   ", "C", 6,  0,  "",   "SB1", {},                        "Produto Final"})
	U_ValPerg (cPerg, _aRegsPerg)
Return