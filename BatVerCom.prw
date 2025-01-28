
// Programa...: BatVerCom
// Autor......: Claudia Lionço
// Data.......: 23/01/2025
// Descricao..: Verificações Comerciais
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Verificações Comerciais
// #PalavasChave      #comercial #verificacoes
// #TabelasPrincipais #SC5 #SC6 #SE1
// #Modulos           #FAT 
//
// Historico de alteracoes:
// 28/01/2025 - Claudia - Incluido envio de e-mail de alteração de vendedores em cientes. GLPI 12756
//
// ------------------------------------------------------------------------------------------------------
User Function BatVerCom()
    Local _aAreaAnt := U_ML_SRArea()

    // Verifica comissão não gerada
    _VerifComissao()

    //Envia aviso de alteração de tabela de preço
    _AltTabela()

    //Envia aviso de alteração de vendedor em cliente
    _AltVend()

    U_ML_SRArea(_aAreaAnt)
Return
//
// ------------------------------------------------------------------------------------------------------
// Verifica titulos sem comissao
Static Function _VerifComissao()
    Local _oSQL     := NIL
	Local _sMsg     := ""
    Local _dData    := date()

    _oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SA3.A3_COD "
    _oSQL:_sQuery += "    ,SA3.A3_NOME "
    _oSQL:_sQuery += "    ,SE1.E1_NUM + ' '+ SE1.E1_PREFIXO + '/'+ SE1.E1_PARCELA AS TITULO
    _oSQL:_sQuery += "    ,SE1.E1_EMISSAO "
    _oSQL:_sQuery += " FROM SA3010 SA3 "
    _oSQL:_sQuery += " INNER JOIN SE1010 SE1 "
    _oSQL:_sQuery += " 	ON SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE1.E1_VEND1 = SA3.A3_COD "
    _oSQL:_sQuery += " 		AND SE1.E1_COMIS1 = 0 "
    _oSQL:_sQuery += " 		AND SE1.E1_EMISSAO >= '20250101' "
    _oSQL:_sQuery += " 		AND SE1.E1_PREFIXO = '10' "
    _oSQL:_sQuery += " 		AND SE1.E1_PARCELA <> '1' "
    _oSQL:_sQuery += " 		AND SE1.E1_TIPO = 'NF' "
    _oSQL:_sQuery += " WHERE SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND A3_MSBLQL = '2' "
    _oSQL:_sQuery += " AND A3_COMIS > 0 "
    _oSQL:_sQuery += " ORDER BY A3_COD, SE1.E1_EMISSAO "
    u_log(_oSQL:_sQuery)
	
	If Len(_oSQL:Qry2Array(.F., .F.)) > 0
        _aCols := {}

        AADD(_aCols, {'CODIGO' 	, 'left',  ''})
        AADD(_aCols, {'NOME' 	    , 'left',  ''})
        AADD(_aCols, {'TITULO'		, 'left',  ''})
        AADD(_aCols, {'EMISSAO'	, 'left',  ''})

	    _sMsg = _oSQL:Qry2HTM("Títulos sem comissão " + DTOC(_dData), _aCols, "", .F.,.T.)
		U_ZZUNU({'163'}, "Títulos sem comissão " + DTOC(_dData) , _sMsg, .F.)
	EndIf
Return
//
// ------------------------------------------------------------------------------------------------------
// Envia e-mail de aviso de alteração de tabelas
Static Function _AltTabela()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _oSQL     := NIL
	Local _sMsg     := ""
	Local _dData    := Date()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
    _oSQL:_sQuery += " 	     CODIGO_ALIAS "
	_oSQL:_sQuery += "      ,DA0.DA0_DESCRI "
    _oSQL:_sQuery += " 	    ,USUARIO "
    _oSQL:_sQuery += " 	    ,TRIM(PRODUTO) "
    _oSQL:_sQuery += " 	    ,TRIM(DESCRITIVO) "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
	_oSQL:_sQuery += " INNER JOIN DA0010 DA0 "
	_oSQL:_sQuery += " 	ON DA0.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND DA0.DA0_FILIAL = FILIAL "
	_oSQL:_sQuery += " 		AND DA0.DA0_CODTAB = CODIGO_ALIAS "
    _oSQL:_sQuery += " WHERE (CODEVENTO LIKE ('%DA0%') "
    _oSQL:_sQuery += " OR CODEVENTO LIKE ('%DA1%')) "
    _oSQL:_sQuery += " AND DATA = '"+dtos(_dData)+"' "
    _oSQL:_sQuery += " ORDER BY DATA, HORA, CODIGO_ALIAS "
	u_log(_oSQL:_sQuery)
	
	If Len (_oSQL:Qry2Array (.F., .F.)) > 0
		_aCols := {}
		
	   AADD (_aCols, {'TABELA' 		, 'left',  ''})
	   AADD (_aCols, {'DESCRICAO' 	, 'left',  ''})
	   AADD (_aCols, {'USUARIO'		, 'left',  ''})
	   AADD (_aCols, {'PRODUTO'		, 'left',  ''})
       AADD (_aCols, {'OBS'    		, 'left',  ''})

		_sMsg = _oSQL:Qry2HTM ("Alteração de tabela de preço  - Data " + DTOC(_dData), _aCols, "", .F.,.T.)
		U_ZZUNU ({'156'}, "Alteração de tabela de preço  - Data " + DTOC(_dData) , _sMsg, .F.)
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return .T.
//
// ------------------------------------------------------------------------------------------------------
// Envia e-mail de aviso de alteração de vendedores
Static Function _AltVend()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _oSQL     := NIL
	Local _sMsg     := ""
	Local _dData    := Date()

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT "
    _oSQL:_sQuery += " 	   CLIENTE + '/' + LOJA_CLIENTE + ' - ' + A1_NOME "
    _oSQL:_sQuery += "    ,DESCRITIVO "
    _oSQL:_sQuery += "    ,USUARIO "
    _oSQL:_sQuery += " FROM VA_VEVENTOS "
    _oSQL:_sQuery += " INNER JOIN SA1010 SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND A1_COD = CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = LOJA_CLIENTE "
    _oSQL:_sQuery += " WHERE DATA = '" + dtos(_dData) + "' "
    _oSQL:_sQuery += " AND CODEVENTO = 'SA1007' "
    _aDados := aclone(_oSQL:Qry2Array())
	u_log(_oSQL:_sQuery)
	
	If Len (_oSQL:Qry2Array (.F., .F.)) > 0
		_aCols := {}
		
	   AADD (_aCols, {'CLIENTE' 	, 'left',  ''})
	   AADD (_aCols, {'ALTERACAO' 	, 'left',  ''})
	   AADD (_aCols, {'USUARIO'		, 'left',  ''})
	EndIf

    _sMsg = _oSQL:Qry2HTM ("Alteração de vendedor no cliente  - Data " + DTOC(_dData), _aCols, "", .F.,.T.)
	U_ZZUNU ({'146'}, "Alteração de vendedor no cliente  - Data " + DTOC(_dData) , _sMsg, .F.)

	U_ML_SRArea (_aAreaAnt)

Return
