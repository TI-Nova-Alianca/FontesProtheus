// Programa...: MonMerc1
// Autor......: Robert Koch
// Data.......: 13/03/2017
// Descricao..: Tela de monitoramento de integracao com sistema Mercanet
//
// Historico de alteracoes:
// 24/06/2020 - Claudia - Incluida tela de parametros de pesquisa e barra de progresso. GLPI: 8091
// 10/07/2020 - Claudia - Ajustado parametro de data deixando apenas uma data como pesquisa.
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MonMerc1 ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local _dDataIni   := date ()
	local _dDataFin   := date ()
	
	u_logId ()
	u_logIni ()
	
	_ParamTela()

//	_dDataIni = U_Get ("Data de" , "D", 8, "@D", "", _dDataIni, .F., ".T.")
//	_dDataFin = U_Get ("Data até", "D", 8, "@D", "", _dDataFin, .F., ".T.")
//
//	if _dDataIni != NIL
//		processa ({|| _Tela (_dDataIni)})
//	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
//--------------------------------------------------------------
// Chama processamento
Static Function _MontaTela(oDlg,_dDtIni,_sCliente,_sLoja,_sPedido,_sVend,_sProd,_sTitulo,_sPref,_sParc,_sNfsNum,_sNfsSer,_sNfeNum,_sNfeSer)
	Local _oSQL := NIL
	
	oDlg:End()
	
	MsgRun("Processando...", "Monitor de envio de dados para o sistema Mercanet", {|| _Tela(_dDtIni,_sCliente,_sLoja,_sPedido,_sVend,_sProd,_sTitulo,_sPref,_sParc,_sNfsNum,_sNfsSer,_sNfeNum,_sNfeSer)})
	
Return
//--------------------------------------------------------------
// Query e tela
Static Function _Tela(_dDtIni,_sCliente,_sLoja,_sPedido,_sVend,_sProd,_sTitulo,_sPref,_sParc,_sNfsNum,_sNfsSer,_sNfeNum,_sNfeSer)
	Local _oSQL := NIL
	
	_sDtIni := DTOS(_dDtIni) + ' 00:00:00.000'
	_sDtFin := DTOS(_dDtIni) + ' 23:59:59.000'
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT DATA_GRAV AS GRAVACAO,"
	_oSQL:_sQuery += " 'AINDA NAO ENVIADO' AS RESULTADO,"
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SC5' THEN RTRIM (CHAVE1) ELSE '' END AS PEDIDO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF2' THEN RTRIM (CHAVE1) ELSE '' END AS NFS_NUMERO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF2' THEN RTRIM (CHAVE2) ELSE '' END AS NFS_SERIE, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'DA0' THEN RTRIM (CHAVE1) ELSE '' END AS TAB_PRECO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SA1' THEN RTRIM (CHAVE1) ELSE '' END AS CLIENTE, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SA1' THEN RTRIM (CHAVE2) ELSE '' END AS LOJA, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SA3' THEN RTRIM (CHAVE1) ELSE '' END AS VENDEDOR, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SA4' THEN RTRIM (CHAVE1) ELSE '' END AS TRANSP, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SB1' THEN RTRIM (CHAVE1) ELSE '' END AS PRODUTO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE4' THEN RTRIM (CHAVE1) ELSE '' END AS COND_PAGTO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF4' THEN RTRIM (CHAVE1) ELSE '' END AS TES, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF1' THEN RTRIM (CHAVE1) ELSE '' END AS NFE_NUMERO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF1' THEN RTRIM (CHAVE2) ELSE '' END AS NFE_SERIE, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF1' THEN RTRIM (CHAVE3) ELSE '' END AS NFE_FORNECE, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SF1' THEN RTRIM (CHAVE4) ELSE '' END AS NFE_LOJA, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE1' THEN RTRIM (CHAVE1) ELSE '' END AS TITULO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE1' THEN RTRIM (CHAVE2) ELSE '' END AS PREFIXO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE1' THEN RTRIM (CHAVE3) ELSE '' END AS PARCELA, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE5' THEN RTRIM (CHAVE1) ELSE '' END AS MOV_FIN_TITULO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE5' THEN RTRIM (CHAVE2) ELSE '' END AS MOV_FIN_PREFIXO, "
	_oSQL:_sQuery += " CASE ALIAS WHEN 'SE5' THEN RTRIM (CHAVE3) ELSE '' END AS MOV_FIN_PARCELA, "
	_oSQL:_sQuery += " CASE WHEN ALIAS = 'ZX5' AND CHAVE1 = '39' THEN RTRIM (CHAVE2) ELSE '' END AS LINHA_COML, "
	_oSQL:_sQuery += " CASE WHEN ALIAS = 'ZX5' AND CHAVE1 = '40' THEN RTRIM (CHAVE2) ELSE '' END AS MARCA,"
	_oSQL:_sQuery += " CAST ('' AS DATETIME) AS DATA_PROCESSADO, "
	_oSQL:_sQuery += " TIPO,"
	_oSQL:_sQuery += " RECNO,"
	_oSQL:_sQuery += " '' AS MSG_ERRO"
	_oSQL:_sQuery += " FROM VA_INTEGR_MERCANET"
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT DATA_GRAVACAO AS GRAVACAO,"
	_oSQL:_sQuery += " CASE STATUS WHEN 'INS' THEN 'AGUARDANDO' WHEN 'PRO' THEN 'ACEITO' WHEN 'ERR' THEN 'ERRO' END COLLATE DATABASE_DEFAULT AS RESULTADO,"
	_oSQL:_sQuery += " CASE TIPO WHEN 30   THEN SUBSTRING (AUX_0, 1, 6)  ELSE '' END COLLATE DATABASE_DEFAULT AS PEDIDO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 37   THEN SUBSTRING (AUX_0, 1, 9)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFS_NUMERO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 37   THEN SUBSTRING (AUX_1, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFS_SERIE, "
	_oSQL:_sQuery += " CASE TIPO WHEN 41   THEN SUBSTRING (AUX_0, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS TAB_PRECO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 20   THEN SUBSTRING (AUX_0, 1, 6)  ELSE '' END COLLATE DATABASE_DEFAULT AS CLIENTE, "
	_oSQL:_sQuery += " CASE TIPO WHEN 20   THEN SUBSTRING (AUX_1, 1, 2)  ELSE '' END COLLATE DATABASE_DEFAULT AS LOJA, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8005 THEN SUBSTRING (AUX_0, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS VENDEDOR, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8020 THEN SUBSTRING (AUX_0, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS TRANSP, "
	_oSQL:_sQuery += " CASE TIPO WHEN 40   THEN SUBSTRING (AUX_0, 1, 15) ELSE '' END COLLATE DATABASE_DEFAULT AS PRODUTO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8012 THEN SUBSTRING (AUX_0, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS COND_PAGTO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8007 THEN SUBSTRING (AUX_0, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS TES, "
	_oSQL:_sQuery += " CASE TIPO WHEN 35   THEN SUBSTRING (AUX_0, 1, 9)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFE_NUMERO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 35   THEN SUBSTRING (AUX_1, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFE_SERIE, "
	_oSQL:_sQuery += " CASE TIPO WHEN 35   THEN SUBSTRING (AUX_3, 1, 6)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFE_FORNECE, "
	_oSQL:_sQuery += " CASE TIPO WHEN 35   THEN SUBSTRING (AUX_4, 1, 2)  ELSE '' END COLLATE DATABASE_DEFAULT AS NFE_LOJA, "
	_oSQL:_sQuery += " CASE TIPO WHEN 50   THEN SUBSTRING (AUX_0, 1, 9)  ELSE '' END COLLATE DATABASE_DEFAULT AS TITULO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 50   THEN SUBSTRING (AUX_1, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS PREFIXO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 50   THEN SUBSTRING (AUX_3, 1, 1)  ELSE '' END COLLATE DATABASE_DEFAULT AS PARCELA, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8108 THEN SUBSTRING (AUX_0, 1, 9)  ELSE '' END COLLATE DATABASE_DEFAULT AS MOV_FIN_TITULO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8108 THEN SUBSTRING (AUX_1, 1, 3)  ELSE '' END COLLATE DATABASE_DEFAULT AS MOV_FIN_PREFIXO, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8108 THEN SUBSTRING (AUX_3, 1, 1)  ELSE '' END COLLATE DATABASE_DEFAULT AS MOV_FIN_PARCELA, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8004 THEN SUBSTRING (AUX_1, 1, 2)  ELSE '' END COLLATE DATABASE_DEFAULT AS LINHA_COML, "
	_oSQL:_sQuery += " CASE TIPO WHEN 8101 THEN SUBSTRING (AUX_1, 1, 2)  ELSE '' END COLLATE DATABASE_DEFAULT AS MARCA,"
	_oSQL:_sQuery += " DATA_PROCESSADO, "
	_oSQL:_sQuery += " TIPO, "
	_oSQL:_sQuery += " R_E_C_N_O_,"
	_oSQL:_sQuery += " ISNULL (ERRO, '') COLLATE DATABASE_DEFAULT AS MSG_ERRO"
	_oSQL:_sQuery += " FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_INTERFACE_PROTHEUS"
	_oSQL:_sQuery += " WHERE DATA_GRAVACAO BETWEEN '" + _sDtIni + "' AND '" + _sDtFin + "')"
	_oSQL:_sQuery += " SELECT * FROM C "
	_oSQL:_sQuery += " WHERE GRAVACAO BETWEEN '" + _sDtIni + "' AND '" + _sDtFin + "'"
	If !empty(_sCliente)
		_oSQL:_sQuery += " AND CLIENTE = '" + _sCliente + "'"
		_oSQL:_sQuery += " AND LOJA    = '" + _sLoja    + "'"
	EndIf
	If !empty(_sPedido)
		_oSQL:_sQuery += " AND PEDIDO 	  = '" + _sPedido + "'"
	EndIf
	If !empty(_sVend)
		_oSQL:_sQuery += " AND VENDEDOR   = '" + _sVend + "'"
	EndIf
	If !empty(_sProd)
		_oSQL:_sQuery += " AND PRODUTO 	  = '" + _sProd + "'"
	EndIf
	If !empty(_sNfsNum)
		_oSQL:_sQuery += " AND NFS_NUMERO = '" + _sNfsNum + "'"
		_oSQL:_sQuery += " AND NFS_SERIE  = '" + _sNfsSer + "'"
	EndIf
	If !empty(_sNfeNum)
		_oSQL:_sQuery += " AND NFE_NUMERO = '" + _sNfeNum + "'"
		_oSQL:_sQuery += " AND NFE_SERIE  = '" + _sNfeSer + "'"
	EndIf
	If !empty(_sTitulo)
		_oSQL:_sQuery += " AND TITULO     = '" + _sTitulo + "'"
		_oSQL:_sQuery += " AND PREFIXO    = '" + _sPref   + "'"
		_oSQL:_sQuery += " AND PARCELA    = '" + _sParc   + "'"
	EndIf
	_oSQL:_sQuery += " ORDER BY GRAVACAO"
	_oSQL:Log ()
	_oSQL:F3Array ('Monitor de envio de dados para o sistema Mercanet')
Return
//--------------------------------------------------------------
// Parametros de entrada - Tela de parametros
Static Function _ParamTela()
	Local _dDtFin 
	Local cdDtFin  := date()
	Local _dDtIni 
	Local cdDtIni  := date()
	Local _sCliente
	Local csCliente := "      "
	Local _sLoja
	Local csLoja 	:= "  "
	Local _sNfeNum
	Local csNfeNum 	:= "         "
	Local _sNfeSer
	Local csNfeSer 	:= "   "
	Local _sNfsNum
	Local csNfsNum	:= "         "
	Local _sNfsSer
	Local csNfsSer 	:= "   "
	Local _sParc
	Local csParc 	:= "   "
	Local _sPedido
	Local csPedido	:= "      "
	Local _sPref
	Local csPref 	:= "   "
	Local _sProd
	Local csProd 	:= "      "
	Local _sTitulo
	Local csTitulo 	:= "         "
	Local _sVend
	Local csVend 	:= "   "
	Local oSay1
	Local oSay10
	Local oSay11
	Local oSay12
	Local oSay13
	Local oSay14
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oSay6
	Local oSay7
	Local oSay8
	Local oSay9
	Local aButtons := {}
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Parâmetros" FROM 000, 000  TO 310, 490 COLORS 0, 16777215 PIXEL

    @ 045, 010 SAY oSay1 PROMPT "Data " SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL
    //@ 047, 120 SAY oSay2 PROMPT "Data Final" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 043, 055 MSGET _dDtIni VAR cdDtIni SIZE 060, 010 OF oDlg PICTURE "@R 99/99/9999" COLORS 0, 16777215 PIXEL
    //@ 043, 150 MSGET _dDtFin VAR cdDtFin SIZE 060, 010 OF oDlg PICTURE "@R 99/99/9999" COLORS 0, 16777215 PIXEL
    @ 058, 010 SAY oSay3 PROMPT "Cliente" SIZE 025, 007 OF oDlg  COLORS 0, 16777215 PIXEL
    @ 055, 055 MSGET _sCliente VAR csCliente SIZE 060, 010 OF oDlg PICTURE "@N 999999" COLORS 0, 16777215 F3 "SA1" PIXEL
    @ 058, 120 SAY oSay4 PROMPT "Loja" SIZE 025, 008 OF oDlg COLORS 0, 16777215 PIXEL
    @ 056, 150 MSGET _sLoja VAR csLoja SIZE 020, 010 OF oDlg PICTURE "@N 99" COLORS 0, 16777215 PIXEL
    @ 070, 010 SAY oSay5 PROMPT "Pedido" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 083, 010 SAY oSay6 PROMPT "Vendedor" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 095, 010 SAY oSay7 PROMPT "Produto" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 108, 010 SAY oSay8 PROMPT "Título" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 108, 120 SAY oSay9 PROMPT "Prefixo" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 108, 178 SAY oSay10 PROMPT "Parcela" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 068, 055 MSGET _sPedido VAR csPedido SIZE 060, 010 OF oDlg PICTURE "@N 999999" COLORS 0, 16777215 PIXEL
    @ 080, 055 MSGET _sVend VAR csVend SIZE 060, 010 OF oDlg PICTURE "@N 999" COLORS 0, 16777215 F3 "SA3" PIXEL
    @ 093, 055 MSGET _sProd VAR csProd SIZE 060, 010 OF oDlg PICTURE "@N 999999" COLORS 0, 16777215 PIXEL
    @ 105, 055 MSGET _sTitulo VAR csTitulo SIZE 060, 010 OF oDlg PICTURE "@N 999999999" COLORS 0, 16777215 PIXEL
    @ 105, 150 MSGET _sPref VAR csPref SIZE 025, 010 OF oDlg PICTURE "@N 999" COLORS 0, 16777215 PIXEL
    @ 105, 205 MSGET _sParc VAR csParc SIZE 025, 010 OF oDlg PICTURE "@N 999" COLORS 0, 16777215 PIXEL
    @ 120, 010 SAY oSay11 PROMPT "NFS Número" SIZE 039, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 120, 120 SAY oSay12 PROMPT "NFS Série" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 133, 010 SAY oSay13 PROMPT "NFE Número" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 132, 120 SAY oSay14 PROMPT "NFE Série" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 118, 055 MSGET _sNfsNum VAR csNfsNum SIZE 060, 010 OF oDlg PICTURE "@N 999999999" COLORS 0, 16777215 PIXEL
    @ 118, 150 MSGET _sNfsSer VAR csNfsSer SIZE 025, 010 OF oDlg PICTURE "@N 999" COLORS 0, 16777215 PIXEL
    @ 130, 055 MSGET _sNfeNum VAR csNfeNum SIZE 060, 010 OF oDlg PICTURE "@N 999999999" COLORS 0, 16777215 PIXEL
    @ 130, 150 MSGET _sNfeSer VAR csNfeSer SIZE 025, 010 OF oDlg PICTURE "@N 999" COLORS 0, 16777215 PIXEL

	ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg, {||_MontaTela(oDlg,cdDtIni,csCliente,csLoja,csPedido,csVend,csProd,csTitulo,csPref,csParc,csNfsNum,csNfsSer,csNfeNum,csNfeSer),{||oDlg:End()}}, {|| oDlg:End ()},,aButtons))

Return