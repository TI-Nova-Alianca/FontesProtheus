// Programa..: VA_PREVCOM
// Autor.....: Claudia Lionço
// Data......: 09/11/2022
// Descricao.: Relatório de Provisão de Comissão
// 
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de Provisão de Comissão
// #PalavasChave      #comissões #comissoes #calculo 
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------------------------------------------------
User Function VA_PREVCOM ()
	Private oReport
	Private cPerg := "VA_PREVCOM"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil

	oReport := TReport():New("VA_PREVCOM","Provisão de Comissão",cPerg,{|oReport| PrintReport(oReport)},"Provisão de Comissão")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"    ,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Vendedor"	,       					,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Título"	,       					,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Cliente"	,       					,50,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Emissão"  	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Vlr.Base"  , "@E 999,999,999.99"       ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Percentual", "@E 999,999,999.99"       ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Comissão"  , "@E 999,999,999.99"       ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

	oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA2"),"Total")
   
    TRFunction():New(oSection1:Cell("COLUNA8")  ,,"SUM" ,oBreak1,""          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	local oSection1  := oReport:Section(1)
	local _nNovaBase := 0
	local _nNovaComi := 0
    local _aComissao := {}
    local _x         := 0

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   E3_FILIAL "
    _oSQL:_sQuery += "    ,E3_VEND "
    _oSQL:_sQuery += "    ,E3_NUM "
    _oSQL:_sQuery += "    ,E3_PREFIXO "
    _oSQL:_sQuery += "    ,E3_PARCELA "
    _oSQL:_sQuery += "    ,E3_SEQ "
    _oSQL:_sQuery += "    ,E3_EMISSAO "
    _oSQL:_sQuery += "    ,E3_CODCLI "
    _oSQL:_sQuery += "    ,E3_LOJA "
    _oSQL:_sQuery += "    ,E3_BASE "
    _oSQL:_sQuery += "    ,E3_PORC "
    _oSQL:_sQuery += "    ,E3_COMIS "
    _oSQL:_sQuery += "    ,E1_VEND1 "
    _oSQL:_sQuery += "    ,E1_VEND2 "
    _oSQL:_sQuery += "    ,E1_BASCOM1 "
    _oSQL:_sQuery += "    ,E1_VALOR "
    _oSQL:_sQuery += "    ,E1_COMIS1 "
    _oSQL:_sQuery += "    ,E1_COMIS2 "
    _oSQL:_sQuery += " FROM " +  RetSQLName ("SE3") + " AS SE3 "
    _oSQL:_sQuery += " INNER JOIN " +  RetSQLName ("SE1") + " AS SE1 "
    _oSQL:_sQuery += " 	ON SE1.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SE1.E1_FILIAL  = SE3.E3_FILIAL "
    _oSQL:_sQuery += " 		AND SE1.E1_NUM     = SE3.E3_NUM "
    _oSQL:_sQuery += " 		AND SE1.E1_PREFIXO = SE3.E3_PREFIXO "
    _oSQL:_sQuery += " 		AND SE1.E1_PARCELA = SE3.E3_PARCELA "
    _oSQL:_sQuery += " 		AND SE1.E1_CLIENTE = SE3.E3_CODCLI "
    _oSQL:_sQuery += " 		AND E1_LOJA        = SE3.E3_LOJA "
    _oSQL:_sQuery += " WHERE SE3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND E3_FILIAL BETWEEN  '"+ mv_par01       +"' AND '"+ mv_par02       +"' "
    _oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '"+ dtos(mv_par03) +"' AND '"+ dtos(mv_par04) +"' "
    _oSQL:_sQuery += " AND E3_VEND BETWEEN    '"+ mv_par05       +"' AND '"+ mv_par06       +"' "
    _oSQL:_sQuery += " AND E3_DATA = '' "
    _oSQL:_sQuery += " ORDER BY E3_VEND, E3_EMISSAO, E3_NUM "
    _aComissao := aclone(_oSQL:Qry2Array())

    For _x:=1 to Len(_aComissao)

        // prepara variáveis
        _filial    := _aComissao[_x, 1] 
        _vendCom   := _aComissao[_x, 2] 
        _titulo    := _aComissao[_x, 3] 
        _prefixo   := _aComissao[_x, 4] 
        _parcela   := _aComissao[_x, 5] 
        _sequencia := _aComissao[_x, 6] 
        _dtEmissao := _aComissao[_x, 7]
        _cliente   := _aComissao[_x, 8]
        _loja      := _aComissao[_x, 9]
        _base      := _aComissao[_x,10]
        _percent   := _aComissao[_x,11]
        _comissao  := _aComissao[_x,12]
        _vend1     := _aComissao[_x,13]  
		_vend2     := _aComissao[_x,14]   
		_baseComis := _aComissao[_x,15] 
		_valorTit  := _aComissao[_x,16] 
        _comis1    := _aComissao[_x,17] 
        _comis2    := _aComissao[_x,18] 

        If _vendCom == _vend1
			_npercSE3 := _comis1 
		Elseif _vendCom == _vend2
			_npercSE3 := _comis2 
		Endif
		// monta data inicial e final para compor os valores de descontos, compensacoes e juros
		_dtini := substr(dtos(_dtEmissao),1,6) + '01'
		_dtfim := substr(dtos(_dtEmissao),1,6) + '31'
		//
		// **********************************************************************************************
		//Valor recebido
		_vlrRec := 0
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	    ROUND(SUM(E5_VALOR), 2)"
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial    + "'"
		_oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo    + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo   + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela   + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente   + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja      + "'"
		_oSQL:_sQuery += " AND E5_SEQ      = '" + _sequencia + "'"
		_oSQL:_sQuery += " AND E5_RECPAG   = 'R'"
		_oSQL:_sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
		_oSQL:_sQuery += " AND E5_DATA BETWEEN  '" + _dtini + "' AND '" + _dtfim + "'"
		_aVlrRec := aclone(_oSQL:Qry2Array())

		If Len(_aVlrRec) > 0
			_vlrRec := _aVlrRec[1,1]
		Else
			_vlrRec := 0
		EndIf
		//
		// **********************************************************************************************
		//busca descontos do título
		_vlrDesc := 0
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	     ROUND(SUM(E5_VALOR), 2)"
		_oSQL:_sQuery += "      ,ROUND(SUM(E5_VARAPEL), 2)"
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial    + "'"
		_oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo    + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo   + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela   + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente   + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja      + "'"
		_oSQL:_sQuery += " AND E5_SEQ      = '" + _sequencia + "'"
		_oSQL:_sQuery += " AND E5_RECPAG   = 'R'"
		_oSQL:_sQuery += " AND E5_SITUACA != 'C'"
		_oSQL:_sQuery += " AND (E5_TIPODOC = 'DC' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN NOT LIKE '% RA %'))"
		_oSQL:_sQuery += " AND E5_DATA BETWEEN '" + _dtini + "' AND '" + _dtfim + "'"
		_aDesc := aclone(_oSQL:Qry2Array())
		
		If Len(_aDesc) > 0
			_vlrDesc := _aDesc[1,1]
		Else
			_vlrDesc := 0
		EndIf
		//
		// **********************************************************************************************
		// valor recebido no titulo
		_vlrReceb := 0
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	ROUND(SUM(E5_VALOR), 2)"
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial    + "'"
		_oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo    + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo   + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela   + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente   + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja      + "'"
		_oSQL:_sQuery += " AND E5_RECPAG   = 'R'"
		_oSQL:_sQuery += " AND E5_SITUACA != 'C'"
		_oSQL:_sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
		_oSQL:_sQuery += " AND E5_DATA BETWEEN '" + _dtini + "' AND '" + _dtfim + "'"
		_aReceb := aclone(_oSQL:Qry2Array())

		If Len(_aReceb)>0
			_vlrReceb := _aReceb[1,1]
		Else
			_vlrReceb := 0
		EndIf
		//
		// **********************************************************************************************
		// valor estornado no titulo
		_vlrEstorno := 0
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "      ROUND(SUM(E5_VALOR),2)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE5") + " AS SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial  + "'"
	    _oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo  + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja    + "'"
        _oSQL:_sQuery += " AND E5_RECPAG   = 'P'"
		_oSQL:_sQuery += " AND E5_TIPODOC  = 'ES'"
		_oSQL:_sQuery += " AND E5_MOTBX   != 'CMP'"
		_oSQL:_sQuery += " AND E5_DATA BETWEEN '"+ _dtini + "' AND '" + _dtfim + "'"
		_oSQL:_sQuery += " GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO "
		_aEstor := aclone(_oSQL:Qry2Array())
		
		If len(_aEstor) > 0
			_vlrEstorno := _aEstor[1,1]
		Else
			_vlrEstorno := 0
		Endif
		//
		// **********************************************************************************************
		// valor de juros no titulo
		_vlrJuros := 0
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "      ROUND(SUM(E5_VALOR),2)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE5")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial  + "'"
	    _oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo  + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja    + "'"
		_oSQL:_sQuery += " AND E5_RECPAG  = 'R'"
		_oSQL:_sQuery += " AND E5_TIPODOC = 'JR'"
		_oSQL:_sQuery += " AND E5_SITUACA != 'C'"
		_oSQL:_sQuery += " AND E5_DATA BETWEEN '" + _dtini + "' AND '" + _dtfim + "'"
		_oSQL:_sQuery += " GROUP BY E5_FILIAL, E5_RECPAG, E5_NUMERO, E5_PARCELA, E5_PREFIXO"
		_aJuros := aclone(_oSQL:Qry2Array())
		
		If len(_aJuros) > 0
			_vlrJuros := _aJuros[1,1]
		Else
			_vlrJuros := 0
		Endif
		//
		// **********************************************************************************************
		// quantidade de parcelas do titulo
		_qtdParc := 1
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "      COUNT (*) "
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
		_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND E1_FILIAL  = '" + _filial  +"'"
		_oSQL:_sQuery += " AND E1_NUM     = '" + _titulo  + "'"
		_oSQL:_sQuery += " AND E1_PREFIXO = '" + _prefixo + "'"
		_oSQL:_sQuery += " AND E1_CLIENTE = '" + _cliente + "'"
		_oSQL:_sQuery += " AND E1_LOJA    = '" + _loja    + "'"
		_aParc := aclone(_oSQL:Qry2Array())
		
		If Len(_aParc) > 0
			_qtdParc := _aParc[1,1]
		Else
			_qtdParc := 1
		EndIf
		//
		// **********************************************************************************************
		// condição de pagamento 
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	   SC5.C5_FILIAL"	//01
		_oSQL:_sQuery += "    ,SC5.C5_NUM"	//02
		_oSQL:_sQuery += "    ,SC5.C5_CLIENTE"//03
		_oSQL:_sQuery += "    ,SC5.C5_LOJACLI"//04
		_oSQL:_sQuery += "    ,SC5.C5_CONDPAG"//05
		_oSQL:_sQuery += "	  ,SC5.C5_PARC1"	//06
		_oSQL:_sQuery += "    ,SC5.C5_PARC2"	//07	
		_oSQL:_sQuery += "    ,SC5.C5_PARC3"	//08
		_oSQL:_sQuery += "    ,SC5.C5_PARC4"	//09
		_oSQL:_sQuery += "    ,SC5.C5_PARC5"	//10
		_oSQL:_sQuery += "    ,SC5.C5_PARC6"	//11
		_oSQL:_sQuery += "    ,SC5.C5_PARC7"	//12
		_oSQL:_sQuery += "    ,SC5.C5_PARC8"	//13
		_oSQL:_sQuery += "    ,SC5.C5_PARC9"	//14
		_oSQL:_sQuery += "    ,SC5.C5_PARCA"	//15
		_oSQL:_sQuery += "    ,SC5.C5_PARCB"	//16
		_oSQL:_sQuery += "    ,SC5.C5_PARCC"	//17
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SC5") + " AS SC5" 
		_oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SC5.C5_FILIAL  = '" + _filial  + "'"
		_oSQL:_sQuery += " AND SC5.C5_NOTA    = '" + _titulo  + "'"
		_oSQL:_sQuery += " AND SC5.C5_SERIE   = '" + _prefixo + "'"
		_oSQL:_sQuery += " AND SC5.C5_CLIENTE = '" + _cliente + "'"
		_oSQL:_sQuery += " AND SC5.C5_LOJACLI = '" + _loja    + "'"
		_aCondPgto := aclone(_oSQL:Qry2Array())

		If Len(_aCondPgto) > 0
			_sPedFil 	:= _aCondPgto[1,1]
			_sPedNum	:= _aCondPgto[1,2]
			_sPedCli	:= _aCondPgto[1,3]
			_sPedLoj	:= _aCondPgto[1,4]
			_sCondPgto  := _aCondPgto[1,5]
			_sParc1		:= _aCondPgto[1,6]
			_sParc2		:= _aCondPgto[1,7]
			_sParc3		:= _aCondPgto[1,8]
			_sParc4		:= _aCondPgto[1,9]
			_sParc5		:= _aCondPgto[1,10]
			_sParc6		:= _aCondPgto[1,11]
			_sParc7		:= _aCondPgto[1,12]
			_sParc8		:= _aCondPgto[1,13]
			_sParc9		:= _aCondPgto[1,14]
			_sParcA		:= _aCondPgto[1,15]
			_sParcB		:= _aCondPgto[1,16]
			_sParcC		:= _aCondPgto[1,17]
			
			_sCondTipo := Posicione("SE4",1,'  ' + _sCondPgto,"E4_TIPO")
			_sCondIPI  := Posicione("SE4",1,'  ' + _sCondPgto,"E4_IPI") 
		Else	
			_sCondTipo  := '1'
			_sCondIPI   := 'N'
			_sParc1		:= 100
			_sParc2		:= 100
			_sParc3		:= 100
			_sParc4		:= 100
			_sParc5		:= 100
			_sParc6		:= 100
			_sParc7		:= 100
			_sParc8		:= 100
			_sParc9		:= 100
			_sParcA		:= 100
			_sParcB		:= 100
			_sParcC		:= 100
		EndIf
		//
		// **********************************************************************************************
		// busca dados da nota de IP e ST - e base de comissao prevista
		_vlrIpi 	:= 0
		_vlrST  	:= 0
		_vlrBC  	:= 0
		_vlFrete    := 0
		_Vlrseg     := 0
		_vlrDesp    := 0
		_vlrBasePrev:= _baseComis
		
        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "     F2_VALBRUT AS TOTAL_NF "
        _oSQL:_sQuery += "    ,F2_VALIPI AS IPI_NF "
        _oSQL:_sQuery += "    ,F2_ICMSRET AS ST_NF "
        _oSQL:_sQuery += "    ,(SELECT "
        _oSQL:_sQuery += " 			ROUND(SUM(D2_TOTAL), 2) "
        _oSQL:_sQuery += " 		FROM " +  RetSQLName ("SD2") + " AS SD2" 
        _oSQL:_sQuery += " 		INNER JOIN " +  RetSQLName ("SF4") + " AS SF4" 
        _oSQL:_sQuery += " 			ON (SF4.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 			AND SF4.F4_CODIGO  = SD2.D2_TES "
        _oSQL:_sQuery += " 			AND SF4.F4_MARGEM  = '3') "
        _oSQL:_sQuery += " 		WHERE SD2.D2_FILIAL = SF2.F2_FILIAL "
        _oSQL:_sQuery += " 		AND SD2.D2_DOC      = SF2.F2_DOC "
        _oSQL:_sQuery += " 		AND SD2.D2_SERIE    = SF2.F2_SERIE "
        _oSQL:_sQuery += " 		AND SD2.D2_CLIENTE  = SF2.F2_CLIENTE "
        _oSQL:_sQuery += " 		AND SD2.D2_LOJA     = SF2.F2_LOJA "
        _oSQL:_sQuery += " 		AND SD2.D2_EMISSAO  = SF2.F2_EMISSAO "
        _oSQL:_sQuery += " 		GROUP BY SD2.D2_FILIAL "
        _oSQL:_sQuery += " 				,SD2.D2_DOC "
        _oSQL:_sQuery += " 				,SD2.D2_SERIE) "
        _oSQL:_sQuery += " 	AS VLR_BONIFIC "
        _oSQL:_sQuery += "    ,F2_FRETE AS FRETE_NF "
        _oSQL:_sQuery += "    ,(SELECT "
        _oSQL:_sQuery += " 			ROUND(SUM(D2_TOTAL), 2) "
        _oSQL:_sQuery += " 		FROM " +  RetSQLName ("SD2") + " AS SD2" 
        _oSQL:_sQuery += " 		WHERE SD2.D2_FILIAL = SF2.F2_FILIAL "
        _oSQL:_sQuery += " 		AND SD2.D2_DOC      = SF2.F2_DOC "
        _oSQL:_sQuery += " 		AND SD2.D2_SERIE    = SF2.F2_SERIE "
        _oSQL:_sQuery += " 		AND SD2.D2_CLIENTE  = SF2.F2_CLIENTE "
        _oSQL:_sQuery += " 		AND SD2.D2_LOJA     = SF2.F2_LOJA "
        _oSQL:_sQuery += " 		AND SD2.D2_EMISSAO  = SF2.F2_EMISSAO) "
        _oSQL:_sQuery += " 	AS TOTBASCOM "
        _oSQL:_sQuery += "    ,SF2.F2_SEGURO AS SEGURO "
        _oSQL:_sQuery += "    ,SF2.F2_DESPESA AS DESPESA "
        _oSQL:_sQuery += " FROM " +  RetSQLName ("SF2") + " AS SF2" 
        _oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = ''  "
        _oSQL:_sQuery += " AND SF2.F2_FILIAL   =  '" + _filial  + "'"
        _oSQL:_sQuery += " AND SF2.F2_DOC      =  '" + _titulo  + "'"
        _oSQL:_sQuery += " AND SF2.F2_SERIE    =  '" + _prefixo + "'"
        _oSQL:_sQuery += " AND SF2.F2_CLIENTE  =  '" + _cliente + "'"
        _oSQL:_sQuery += " AND SF2.F2_LOJA     =  '" + _loja    + "'"
		_aNota := aclone(_oSQL:Qry2Array())
		
		If len(_aNota) > 0
			_brutoNota:= _aNota[1,1]
			_ipiNota  := _aNota[1,2]
			_stNota	  := _aNota[1,3]
			_vlBonif  := _aNota[1,4]
			_vlFrete  := _aNota[1,5]
			_vlrBC	  := _aNota[1,6]
			_vlrSeg	  := _aNota[1,7]
			_vlrDesp  := _aNota[1,8]

			If _sCondTipo == '9' // Escolhe o percentual de cada parcela
				Do Case 
					Case alltrim(_parcela) == '' 
						_vlrIpi := (_ipiNota * _sParc1) / 100
						_vlrST  := (_stNota  * _sParc1) / 100
					Case alltrim(_parcela) == 'A'
						_vlrIpi := (_ipiNota * _sParc1) / 100
						_vlrST  := (_stNota  * _sParc1) / 100 
					Case alltrim(_parcela) == 'B' 
						_vlrIpi := (_ipiNota * _sParc2) / 100
						_vlrST  := (_stNota  * _sParc2) / 100 
					Case alltrim(_parcela) == 'C' 
						_vlrIpi := (_ipiNota * _sParc3) / 100
						_vlrST  := (_stNota  * _sParc3) / 100 
					Case alltrim(_parcela) == 'D' 
						_vlrIpi := (_ipiNota * _sParc4) / 100
						_vlrST  := (_stNota  * _sParc4) / 100 
					Case alltrim(_parcela) == 'E' 
						_vlrIpi := (_ipiNota * _sParc5) / 100
						_vlrST  := (_stNota  * _sParc5) / 100 
					Case alltrim(_parcela) == 'F' 
						_vlrIpi := (_ipiNota * _sParc6) / 100
						_vlrST  := (_stNota  * _sParc6) / 100 
					Case alltrim(_parcela) == 'G' 
						_vlrIpi := (_ipiNota * _sParc7) / 100
						_vlrST  := (_stNota  * _sParc7) / 100 
					Case alltrim(_parcela) == 'H' 
						_vlrIpi := (_ipiNota * _sParc8) / 100
						_vlrST  := (_stNota  * _sParc8) / 100 
					Case alltrim(_parcela) == 'I' 
						_vlrIpi := (_ipiNota * _sParc9) / 100
						_vlrST  := (_stNota  * _sParc9) / 100 
					Case alltrim(_parcela) == 'J' 
						_vlrIpi := (_ipiNota * _sParcA) / 100
						_vlrST  := (_stNota  * _sParcA) / 100 
					Case alltrim(_parcela) == 'K'
						_vlrIpi := (_ipiNota * _sParcB) / 100
						_vlrST  := (_stNota  * _sParcB) / 100 
					Case alltrim(_parcela) == 'L'  
						_vlrIpi := (_ipiNota * _sParcC) / 100
						_vlrST  := (_stNota  * _sParcC) / 100 
				EndCase

			Else
				If _sCondIPI == 'N' // IPI distribuídos nas "N" parcelas
					If alltrim(_parcela) == '' .or. alltrim(_parcela) == 'A' // se for primeira parcela, verificar se tem mais baixas nele
						// verificar se existe mais que um registro de comissão. se sim, so retira IPI e ST da primeira.
						_nQtdCom := BuscaQtdComissao(_filial, _titulo, _prefixo, _parcela, _cliente, _loja)

						If _nQtdCom == 0 
							_vlrIpi := _ipiNota/_qtdParc
							_vlrST  := _stNota/_qtdParc
						Else
							_vlrIpi := 0
							_vlrST  := 0
						EndIf
					Else
						_vlrIpi := _ipiNota/_qtdParc
						_vlrST  := _stNota/_qtdParc
					EndIf

				Else 				// IPI cobrado na primeira parcela
					If alltrim(_parcela) == '' .or. alltrim(_parcela) == 'A' // se for a primeira parcela, desconta IPI e ST
						// verificar se existe mais que um registro de comissão. se sim, so retira IPI e ST da primeira.
						_nQtdCom := BuscaQtdComissao(_filial, _titulo, _prefixo, _parcela, _cliente, _loja)

						If _nQtdCom == 0
							_vlrIpi := _ipiNota
							_vlrST  := _stNota
						Else
							_vlrIpi := 0
							_vlrST  := 0
						EndIf
					Else
						_vlrIpi := 0
						_vlrST  := 0
					EndIf
				EndIf
			EndIf
			
			_vlrBasePrev := _vlrBC
		else
			_vlrIpi := 0
			_vlrST  := 0
			_ipiNota:= 0
			_stNota := 0
		endif
		//
		// **********************************************************************************************
		// verifica se o mesmo titulo possui dois pagamentos em meses diferentes
		_oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	    COUNT(*)"
		_oSQL:_sQuery += " FROM " +  RetSQLName ("SE5") + " AS SE5 "
		_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ = ''"
        _oSQL:_sQuery += " AND E5_FILIAL   = '" + _filial  + "'"
	    _oSQL:_sQuery += " AND E5_NUMERO   = '" + _titulo  + "'"
		_oSQL:_sQuery += " AND E5_PREFIXO  = '" + _prefixo + "'"
		_oSQL:_sQuery += " AND E5_PARCELA  = '" + _parcela + "'"
		_oSQL:_sQuery += " AND E5_CLIFOR   = '" + _cliente + "'"
		_oSQL:_sQuery += " AND E5_LOJA     = '" + _loja    + "'"
		_oSQL:_sQuery += " AND E5_RECPAG   = 'R'"
		_oSQL:_sQuery += " AND E5_SITUACA != 'C'"
		_oSQL:_sQuery += " AND (E5_TIPODOC = 'VL' OR (E5_TIPODOC = 'CP' AND E5_DOCUMEN LIKE '% RA %'))"
		_oSQL:_sQuery += " AND  E5_DATA < '" + _dtini + "'"
		_aPgtos := aclone(_oSQL:Qry2Array())

		If Len(_aPgtos) > 0
			If _aPgtos[1,1] > 0 // se existir algum registro de movimento nos meses anteriores
				_vlrIpi := 0
				_vlrST  := 0
			EndIf
		EndIf
		//
		// **********************************************************************************************
		// calculo da base de comissao liberada

		_vlrComBaseLib := (_vlrRec - _vlrIpi - _vlrST - _vlFrete - _vlrSeg - _vlrDesp)

		_vlrComis      := _vlrComBaseLib * _npercSE3
		
		_nNovaBase := ROUND(_vlrComBaseLib,2)
		_nNovaComi := ROUND(_vlrComis/100,2)	

        _vendedor := _vendCom + " - " + alltrim(Posicione("SA3",1,xFilial("SA3") + _vendCom , "A3_NOME"))
        _tit      := _titulo + "/" + _prefixo + " " + _parcela
        _cli      := _cliente + "/" + _loja + " - " + alltrim(Posicione("SA1",1, xFilial("SA1") + _cliente + _loja, "A1_NOME"))

		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _filial    }) 		// filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _vendedor  }) 		// vendedor
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _tit       }) 		// titulo
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _cli       }) 		// cliente
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _dtEmissao }) 		// emissao
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _nNovaBase }) 		// vlr base
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _percent   }) 	    // percentual
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _nNovaComi }) 		// comissao
		
		oSection1:PrintLine()
			
    Next

    oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3        Opcoes                               Help
    aadd (_aRegsPerg, {01, "Filial de       ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
	aadd (_aRegsPerg, {02, "Filial até      ", "C", 2, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {03, "Emissão de      ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {04, "Emissão até     ", "D", 8, 0,  "",   "   "      , {},                         		 ""})
    aadd (_aRegsPerg, {05, "Vendedor de     ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})
    aadd (_aRegsPerg, {06, "Vendedor até    ", "C", 6, 0,  "",   "SA3"      , {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
//
// ---------------------------------------------------------------------------------------
// Busca		
Static Function BuscaQtdComissao(_sFilial, _sNum, _sPrefixo, _sParcela, _sCliente, _sLoja)
	Local _nQtdCom := 0
	Local _aQtdCom := {}
	Local _x       := 0

	_sQuery := ""
	_sQuery += " SELECT
	_sQuery += " 	COUNT(E3_SEQ) AS QTD
	_sQuery += " FROM SE3010
	_sQuery += " WHERE D_E_L_E_T_ = ''"
	_sQuery += " AND E3_FILIAL  = '" + _sFilial  + "'"
	_sQuery += " AND E3_NUM     = '" + _sNum     + "'"
	_sQuery += " AND E3_SERIE   = '" + _sPrefixo + "'"
	_sQuery += " AND E3_PARCELA = '" + _sParcela + "'"
	_sQuery += " AND E3_CODCLI  = '" + _sCliente + "'"
	_sQuery += " AND E3_LOJA    = '" + _sLoja    + "'"
	_aQtdCom := U_Qry2Array(_sQuery)

	For _x:= 1 to Len(_aQtdCom)
		_nQtdCom := _aQtdCom[_x, 1]
	Next

Return _nQtdCom
