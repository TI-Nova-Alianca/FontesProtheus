// Programa...: ZB3MAN
// Autor......: Cláudia Lionço
// Data.......: 18/08/2021
// Descricao..: Fechar registros pagar-me com titulos baixados manualmente
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #echar registros pagar-me com titulos baixados manualmente
// #PalavasChave      #pagarme #pagar #recebimento #ecommerce #baixa_de_titulos
// #TabelasPrincipais #ZB1 #SE1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB3MAN()
    Local _oSQL  	  := ClsSQL ():New ()
	Local _aZB3  	  := {}
	Local i		 	  := 0
	Private _aRelImp  := {}
	Private _aRelErr  := {}

    u_logIni ("Inicio ajuste de registros pagar-me com titulos baixados manualmente " + DTOS(date()) )

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += "	SELECT "
    _oSQL:_sQuery += "		SE1.E1_FILIAL AS FILIAL "       // 01
    _oSQL:_sQuery += "	   ,SE1.E1_PREFIXO AS PREFIXO "     // 02
    _oSQL:_sQuery += "	   ,SE1.E1_NUM AS NUMERO "          // 03
    _oSQL:_sQuery += "	   ,SE1.E1_PARCELA AS PARCELA "     // 04
    _oSQL:_sQuery += "	   ,SE1.E1_VALOR AS VALOR "         // 05
    _oSQL:_sQuery += "	   ,SE1.E1_CLIENTE AS CLIENTE "     // 06
    _oSQL:_sQuery += "	   ,SE1.E1_LOJA AS LOJA "           // 07
    _oSQL:_sQuery += "	   ,SE1.E1_EMISSAO AS EMISSAO "     // 08
    _oSQL:_sQuery += "	   ,SE1.E1_TIPO AS TIPO "           // 09
    _oSQL:_sQuery += "	   ,SE1.E1_BAIXA AS BAIXA "         // 10
    _oSQL:_sQuery += "	   ,SE1.E1_SALDO AS SALDO "         // 11
    _oSQL:_sQuery += "	   ,SE1.E1_STATUS AS TIT_STATUS "   // 12
    _oSQL:_sQuery += "	   ,SE1.E1_ADM AS TIT_ADM "         // 13
    _oSQL:_sQuery += "	   ,SE1.E1_VENCREA AS DTA_VENC "    // 14
    _oSQL:_sQuery += "	   ,ZB3.ZB3_IDTRAN AS ID_TRANS "    // 15
    _oSQL:_sQuery += "	   ,ZB3.ZB3_NSUCOD AS NSU "         // 16
    _oSQL:_sQuery += "	   ,ZB3.ZB3_AUTCOD AS AUTORIZACAO " // 17
    _oSQL:_sQuery += "	   ,ZB3.ZB3_DTAPGT AS DTA_PGTO "    // 18
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTOT AS VLR_TOTAL "   // 19
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRPAR AS VLR_PARC "    // 20
    _oSQL:_sQuery += "	   ,ZB3.ZB3_VLRTAX AS VLR_TAXA "    // 21
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'paid' THEN 'PAGO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_STATRN = 'refunded' THEN 'DEVOL/RECUSADO' "
    _oSQL:_sQuery += "		END AS STATUS "                 // 22
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_BOLCOD <> '' THEN 'SIM' "
    _oSQL:_sQuery += "			ELSE 'NÃO' "
    _oSQL:_sQuery += "		END AS BOLETO "                 // 23
    _oSQL:_sQuery += "	   ,ZB3.ZB3_BOLDTA AS DTA_BOL "     // 24
    _oSQL:_sQuery += "	   ,CASE "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'boleto' THEN 'BOLETO' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'credit_card' THEN 'CARTÃO CRED' "
    _oSQL:_sQuery += "			WHEN ZB3.ZB3_METPGT = 'pix' THEN 'PIX' "
    _oSQL:_sQuery += "		END AS TP_PGTO "                // 25
    _oSQL:_sQuery += "	   ,UPPER(ZB3.ZB3_ADMNOM) AS OPER " // 26
    _oSQL:_sQuery += "     ,ZB3.ZB3_STAIMP AS STAIMP"       // 27
    _oSQL:_sQuery += "     ,ZB3.ZB3_RECID "                 // 28
    _oSQL:_sQuery += "	FROM " + RetSQLName ("ZB3") + " AS ZB3 "
    _oSQL:_sQuery += "	LEFT JOIN " + RetSQLName ("SE1") + " AS SE1 "
    _oSQL:_sQuery += "		ON SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "			AND SE1.E1_VAIDT = ZB3.ZB3_IDTRAN "
    _oSQL:_sQuery += "			AND ((SE1.E1_PARCELA = ZB3.ZB3_PARPRO) "
    _oSQL:_sQuery += "				OR (TRIM(SE1.E1_PARCELA) = '' "
    _oSQL:_sQuery += "					AND ZB3.ZB3_PARPRO = 'A')) "
    _oSQL:_sQuery += "	WHERE ZB3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += "	AND SE1.E1_NUM    <> '' "   // títulos encontrados
    _oSQL:_sQuery += "	AND SE1.E1_BAIXA   <> '' "  // títulos baixados
    _oSQL:_sQuery += "	AND ZB3.ZB3_STAIMP = 'I'"   // títulos com status importado
    _oSQL:_sQuery += "	ORDER BY SE1.E1_NUM "              
    _oSQL:Log ()
		
	_aZB3 := aclone (_oSQL:Qry2Array ())

    _cMens := "Existem " + alltrim(str(len(_aZB3))) + " registros com titulos já baixados. Deseja fechar esses registros?"
    
    If MsgYesNo(_cMens,"Fechar registros")
        For i:=1 to Len(_aZB3)

            _sIdRec  := alltrim(str(_aZB3[i,28]))   // ZB3_RECID
            _sIdTran := alltrim(str(_aZB3[i,15]))   // ZB3_IDTRAN

            dbSelectArea("ZB3")
            dbSetOrder(1) // ZB3_RECID + ZB3_IDTRAN
            dbGoTop()
            
            If dbSeek(PADR(_sIdRec,12,' ') + PADR(_sIdTran ,12,' '))
                Reclock("ZB3",.F.)
                ZB3 -> ZB3_STAIMP := 'M'
                ZB3->(MsUnlock())
            EndIf
        Next
        u_help(" Rotina finalizada!")
    EndIf
Return
