
// Programa...: VA_VERIFC
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
//
// ------------------------------------------------------------------------------------------
User Function VA_VERIFC()
    Local _aAreaAnt := U_ML_SRArea()

    _VerifComissao()

    U_ML_SRArea(_aAreaAnt)
Return
//
// ------------------------------------------------------------------------------------------
// verifica titulos sem comissao
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
