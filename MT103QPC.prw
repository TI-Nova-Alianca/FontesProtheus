// Programa...: MT103QPC
// Autor......: Cláudia Lionço
// Data.......: 13/10/2021
// Descricao..: O P.E. que permite manipular a query gerada ao pressionar as teclas: F5 ou F6 para selecionar o 
//              Pedido de Compra ou um Item do Pedido de Compra que será utilizado no Documento de Entrada.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #permite manipular a query gerada ao selecionar o Pedido de Compra ou um Item do Pedido de Compra
// #PalavasChave      #pedido_de_compra #item_do_pedido 
// #TabelasPrincipais #SC7
// #Modulos   		  #COM 
//
// Historico de alteracoes:
// 13/10/2021 - Claudia - Criado ponto de entrada conforme GLPI: 11032
// 15/10/2021 - Claudia - Incluida a pesquisa F6 quando não tiver linhas adicionadas. GLPI: 11089
// 19/10/2021 - Sandra  - Exclusão dos campos C7_VAZZG, C7_VAZZG2, C7_VAZZG2D, C7_VAZZGC .
//
// -------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function MT103QPC    
    //Local cQry:=ParamIxb[1]
    Local nOpc:=ParamIxb[2]
    Local cQryRet:= ""

    If nOpc==1  // Montar a Query ao pressionar F5      
        cQryRet := " SELECT	R_E_C_N_O_ RECSC7 "
        cQryRet += " FROM " + RetSQLName ("SC7") + " SC7 "
        cQryRet += " WHERE C7_FILENT = '" + cFilant  + "'"
        cQryRet += " AND C7_FORNECE  = '" + ca100for + "'"
        cQryRet += " AND C7_LOJA     = '" + cloja    + "'"
        cQryRet += " AND (C7_QUANT - C7_QUJE - C7_QTDACLA) > 0"
        cQryRet += " AND C7_RESIDUO  = ' '"
        cQryRet += " AND C7_TPOP    <> 'P'"
        cQryRet += " AND C7_CONAPRO <> 'B'"
        cQryRet += " AND C7_CONAPRO <> 'R'"
        cQryRet += " AND D_E_L_E_T_  = ' '"
        cQryRet += " ORDER BY C7_FILENT,C7_DATPRF, C7_FORNECE, C7_LOJA, C7_NUM, C7_ITEM"

    Else        // Montar a Query ao pressionar F6
        if empty(aCols[N,1])
            cQryRet := ""
            cQryRet += " SELECT
            cQryRet += " 	 C7_FILIAL,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DATPRF,C7_EMAIL,C7_DESCRI,C7_UM,C7_SEGUM,C7_QUANT,C7_CODTAB,C7_PRECO "
            cQryRet += " 	,C7_TOTAL,C7_CONTA,C7_CC,C7_ITEMCTA,C7_QTSEGUM,C7_IPI,C7_NUMSC,C7_ITEMSC,C7_LOCAL,C7_COND "
            cQryRet += " 	,C7_CONTATO,C7_OBS,C7_TRANSP,C7_NOMTRAN,C7_FORNECE,C7_EMISSAO,C7_NUM,C7_LOJA,C7_FILENT,C7_DESC1 "
            cQryRet += " 	,C7_DESC2,C7_DESC3,C7_QUJE,C7_REAJUST,C7_FRETE,C7_EMITIDO,C7_TPFRETE,C7_QTDREEM,C7_TX,C7_CODLIB "
            cQryRet += " 	,C7_RESIDUO,C7_ENCER,C7_OP,C7_NUMCOT,C7_MSG,C7_CONTROL,C7_IPIBRUT,C7_VLDESC,C7_SEQUEN,C7_NUMIMP "
            cQryRet += " 	,C7_ORIGEM,C7_QTDACLA,C7_VALEMB,C7_FLUXO,C7_TPOP,C7_APROV,C7_CONAPRO,C7_GRUPCOM,C7_USER,C7_STATME "
            cQryRet += " 	,C7_OK,C7_QTDSOL,C7_VALIPI,C7_VALICM,C7_TES,C7_DESC,C7_PICM,C7_BASEICM,C7_BASEIPI,C7_TXMOEDA "
            cQryRet += " 	,C7_SEGURO,C7_DESPESA,C7_VALFRE,C7_MOEDA,C7_PENDEN,C7_CLVL,C7_BASEIR,C7_ALIQIR,C7_VALIR,C7_SEQMRP "
            cQryRet += " 	,C7_ICMCOMP,C7_ICMSRET,C7_CODORCA,C7_CONTRA,C7_CONTREV,C7_PLANILH,C7_MEDICAO,C7_ITEMED,C7_BASESOL "
            cQryRet += " 	,C7_DTLANC,C7_CODCRED,C7_TIPOEMP,C7_ESPEMP,C7_MSEXP,C7_MSIMP,C7_MSIDENT,C7_MSFIL,C7_POLREPR,C7_MSRESP "
            cQryRet += " 	,C7_PERREPR,C7_CO,C7_CLASSE,C7_OPER1,C7_VALSOL,C7_FREPPCC,C7_DT_IMP,C7_AGENTE,C7_GRADE,C7_ITEMGRD "
            cQryRet += " 	,C7_FORWARD,C7_TIPO_EM,C7_ORIGIMP,C7_DEST,C7_COMPRA,C7_PESO_B,C7_INCOTER,C7_IMPORT,C7_CONSIG,C7_CONF_PE "
            cQryRet += " 	,C7_DESP,C7_EXPORTA,C7_LOJAEXP,C7_CONTAIN,C7_MT3,C7_CONTA20,C7_CONTA40,C7_CON40HC,C7_ARMAZEM,C7_FABRICA "
            cQryRet += " 	,C7_LOJFABR,C7_DT_EMB,C7_TEC,C7_EX_NCM,C7_EX_NBM,C7_DIACTB,C7_NODIA,C7_VAOBRA,C7_VAPROSE"
            cQryRet += " 	,C7_VAFCOBR,C7_VAMTINV,C7_ESTOQUE,C7_CODED,C7_PO_EIC,C7_NUMPR,C7_RATEIO,C7_FILCEN "
            cQryRet += " 	,C7_ACCPROC,C7_ACCNUM,C7_ACCITEM,C7_IDTSS,C7_TPCOLAB,C7_DINICOM,C7_DINITRA,C7_DINICQ,C7_RESREM,C7_SOLICIT "
            cQryRet += " 	,C7_NUMSA,C7_ALIQISS,C7_VALISS,C7_REVISAO,C7_BASECSL,C7_ALIQINS,C7_VALINS,C7_ALQCSL,C7_GCPIT,C7_GCPLT "
            cQryRet += " 	,C7_CODNE,C7_ITEMNE,C7_VALCSL,C7_LOTPLS,C7_CODRDA,C7_BASEISS,C7_FISCORI,C7_BASEINS,C7_PLOPELT,C7_OBRIGA "
            cQryRet += " 	,C7_DIREITO,C7_BASIMP5,C7_BASIMP6,C7_VALIMP5,C7_VALIMP6,C7_FILEDT,C7_OBSM,C7_TIPCOM,C7_VAFNOME,C7_RETENCA "
            cQryRet += " 	,C7_QUJEFAT,C7_QUJERET,C7_DEDUCAO,C7_QUJEDED,C7_FATDIRE,C7_FRETCON,C7_TRANSLJ,C7_IDTRIB,C7_COMNOM,C7_VADESTI "
            cQryRet += "    ,C7_VACCDES,R_E_C_N_O_ RECSC7 "
            cQryRet += " FROM " + RetSQLName ("SC7") + " SC7 "
            cQryRet += " WHERE C7_FILENT = '" + cFilant    + "'"
            cQryRet += " AND C7_FORNECE  = '" + ca100for   + "'"
            cQryRet += " AND C7_LOJA     = '" + cloja      + "'"
            cQryRet += " AND C7_TPOP    <> 'P' "
            cQryRet += " AND (C7_CONAPRO = 'L' "
            cQryRet += " OR C7_CONAPRO   = ' ') "
            cQryRet += " AND (SC7.C7_QUJE + SC7.C7_QTDACLA) < SC7.C7_QUANT "
            cQryRet += " AND SC7.C7_RESIDUO = ' ' "
            cQryRet += " AND SC7.D_E_L_E_T_ = ' ' "
            cQryRet += " ORDER BY C7_FILENT, C7_DATPRF, C7_PRODUTO, C7_FORNECE, C7_LOJA, C7_NUM, C7_ITEM, C7_ITEMGRD "

        else
            cQryRet := ""
            cQryRet += " SELECT
            cQryRet += " 	 C7_FILIAL,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DATPRF,C7_EMAIL,C7_DESCRI,C7_UM,C7_SEGUM,C7_QUANT,C7_CODTAB,C7_PRECO "
            cQryRet += " 	,C7_TOTAL,C7_CONTA,C7_CC,C7_ITEMCTA,C7_QTSEGUM,C7_IPI,C7_NUMSC,C7_ITEMSC,C7_LOCAL,C7_COND "
            cQryRet += " 	,C7_CONTATO,C7_OBS,C7_TRANSP,C7_NOMTRAN,C7_FORNECE,C7_EMISSAO,C7_NUM,C7_LOJA,C7_FILENT,C7_DESC1 "
            cQryRet += " 	,C7_DESC2,C7_DESC3,C7_QUJE,C7_REAJUST,C7_FRETE,C7_EMITIDO,C7_TPFRETE,C7_QTDREEM,C7_TX,C7_CODLIB "
            cQryRet += " 	,C7_RESIDUO,C7_ENCER,C7_OP,C7_NUMCOT,C7_MSG,C7_CONTROL,C7_IPIBRUT,C7_VLDESC,C7_SEQUEN,C7_NUMIMP "
            cQryRet += " 	,C7_ORIGEM,C7_QTDACLA,C7_VALEMB,C7_FLUXO,C7_TPOP,C7_APROV,C7_CONAPRO,C7_GRUPCOM,C7_USER,C7_STATME "
            cQryRet += " 	,C7_OK,C7_QTDSOL,C7_VALIPI,C7_VALICM,C7_TES,C7_DESC,C7_PICM,C7_BASEICM,C7_BASEIPI,C7_TXMOEDA "
            cQryRet += " 	,C7_SEGURO,C7_DESPESA,C7_VALFRE,C7_MOEDA,C7_PENDEN,C7_CLVL,C7_BASEIR,C7_ALIQIR,C7_VALIR,C7_SEQMRP "
            cQryRet += " 	,C7_ICMCOMP,C7_ICMSRET,C7_CODORCA,C7_CONTRA,C7_CONTREV,C7_PLANILH,C7_MEDICAO,C7_ITEMED,C7_BASESOL "
            cQryRet += " 	,C7_DTLANC,C7_CODCRED,C7_TIPOEMP,C7_ESPEMP,C7_MSEXP,C7_MSIMP,C7_MSIDENT,C7_MSFIL,C7_POLREPR,C7_MSRESP "
            cQryRet += " 	,C7_PERREPR,C7_CO,C7_CLASSE,C7_OPER1,C7_VALSOL,C7_FREPPCC,C7_DT_IMP,C7_AGENTE,C7_GRADE,C7_ITEMGRD "
            cQryRet += " 	,C7_FORWARD,C7_TIPO_EM,C7_ORIGIMP,C7_DEST,C7_COMPRA,C7_PESO_B,C7_INCOTER,C7_IMPORT,C7_CONSIG,C7_CONF_PE "
            cQryRet += " 	,C7_DESP,C7_EXPORTA,C7_LOJAEXP,C7_CONTAIN,C7_MT3,C7_CONTA20,C7_CONTA40,C7_CON40HC,C7_ARMAZEM,C7_FABRICA "
            cQryRet += " 	,C7_LOJFABR,C7_DT_EMB,C7_TEC,C7_EX_NCM,C7_EX_NBM,C7_DIACTB,C7_NODIA,C7_VAOBRA,C7_VAPROSE"
            cQryRet += " 	,C7_VAFCOBR,C7_VAMTINV,C7_ESTOQUE,C7_CODED,C7_PO_EIC,C7_NUMPR,C7_RATEIO,C7_FILCEN "
            cQryRet += " 	,C7_ACCPROC,C7_ACCNUM,C7_ACCITEM,C7_IDTSS,C7_TPCOLAB,C7_DINICOM,C7_DINITRA,C7_DINICQ,C7_RESREM,C7_SOLICIT "
            cQryRet += " 	,C7_NUMSA,C7_ALIQISS,C7_VALISS,C7_REVISAO,C7_BASECSL,C7_ALIQINS,C7_VALINS,C7_ALQCSL,C7_GCPIT,C7_GCPLT "
            cQryRet += " 	,C7_CODNE,C7_ITEMNE,C7_VALCSL,C7_LOTPLS,C7_CODRDA,C7_BASEISS,C7_FISCORI,C7_BASEINS,C7_PLOPELT,C7_OBRIGA "
            cQryRet += " 	,C7_DIREITO,C7_BASIMP5,C7_BASIMP6,C7_VALIMP5,C7_VALIMP6,C7_FILEDT,C7_OBSM,C7_TIPCOM,C7_VAFNOME,C7_RETENCA "
            cQryRet += " 	,C7_QUJEFAT,C7_QUJERET,C7_DEDUCAO,C7_QUJEDED,C7_FATDIRE,C7_FRETCON,C7_TRANSLJ,C7_IDTRIB,C7_COMNOM,C7_VADESTI "
            cQryRet += "    ,C7_VACCDES,R_E_C_N_O_ RECSC7 "
            cQryRet += " FROM " + RetSQLName ("SC7") + " SC7 "
            cQryRet += " WHERE C7_FILENT = '" + cFilant    + "'"
            cQryRet += " AND C7_FORNECE  = '" + ca100for   + "'"
            cQryRet += " AND C7_LOJA     = '" + cloja      + "'"
            cQryRet += " AND C7_PRODUTO  = '" + aCols[N,1] + "'"
            cQryRet += " AND C7_TPOP    <> 'P' "
            cQryRet += " AND (C7_CONAPRO = 'L' "
            cQryRet += " OR C7_CONAPRO   = ' ') "
            cQryRet += " AND (SC7.C7_QUJE + SC7.C7_QTDACLA) < SC7.C7_QUANT "
            cQryRet += " AND SC7.C7_RESIDUO = ' ' "
            cQryRet += " AND SC7.D_E_L_E_T_ = ' ' "
            cQryRet += " ORDER BY C7_FILENT, C7_DATPRF, C7_PRODUTO, C7_FORNECE, C7_LOJA, C7_NUM, C7_ITEM, C7_ITEMGRD "
        endif
    EndIf
    
Return cQryRet
