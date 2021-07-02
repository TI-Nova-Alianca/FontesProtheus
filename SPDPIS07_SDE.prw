// Programa...: SPDPIS07
// Autor......: Cláudia Lionço
// Data.......: 01/07/2021
// Descricao..: P.E. para possibilitar a geração do registro 0500 quando o 
//              código da conta contábil é diferente do informado na nota fiscal.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para possibilitar a geração do registro 0500 quando o código da conta contábil é diferente do informado na nota fiscal.
// #PalavasChave      #rateio #500 
// #TabelasPrincipais #SD1 #SFT #SDE
// #Modulos   		  #FIS 
//
// Historico de alteracoes:
//
// -------------------------------------------------------------------------------------
#INCLUDE "PROTHEUS.CH" 
#INCLUDE "RWMAKE.CH"

User Function SPDPIS07()
    Local   _oSQL  	:= ClsSQL ():New ()
	Local	_cFilial    :=	PARAMIXB[1]	//FT_FILIAL
	Local	cTpMov		:=	PARAMIXB[2]	//FT_TIPOMOV
	Local	cSerie		:=	PARAMIXB[3]	//FT_SERIE
	Local	cDoc		:=	PARAMIXB[4]	//FT_NFISCAL
	Local	cClieFor	:=	PARAMIXB[5]	//FT_CLIEFOR
	Local	cLoja		:=	PARAMIXB[6]	//FT_LOJA
	Local	cItem		:=	PARAMIXB[7]	//FT_ITEM FT
	Local	cProd		:=	PARAMIXB[8]	//FT_PRODUTO	 	
	Local	cConta		:=	""
    Local   _i          :=  0
    Local   _x          :=  0
    
    cConta :=	Posicione("SFT",1,_cFilial + cTpMov + cSerie + cDoc + cClieFor + cLoja + cItem + cProd,"FT_CONTA")

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     D1_FILIAL "
    _oSQL:_sQuery += "    ,D1_DOC "
    _oSQL:_sQuery += "    ,D1_SERIE "
    _oSQL:_sQuery += "    ,D1_FORNECE "
    _oSQL:_sQuery += "    ,D1_LOJA "
    _oSQL:_sQuery += "    ,D1_ITEM "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SD1") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND D1_FILIAL    = '" + _cFilial + "' "
    _oSQL:_sQuery += " AND D1_DOC       = '" + cDoc     + "' "
    _oSQL:_sQuery += " AND D1_SERIE     = '" + cSerie   + "' "
    _oSQL:_sQuery += " AND D1_FORNECE   = '" + cClieFor + "' "
    _oSQL:_sQuery += " AND D1_LOJA      = '" + cLoja    + "' "
    _oSQL:_sQuery += " AND D1_COD       = '" + cProd    + "' "
    _aSD1 := aclone (_oSQL:Qry2Array ())

    If Len(_aSD1)
        For _i := 1 to Len(_aSD1)
            _sSD1Fil := _aSD1[_i, 1]
            _sSD1Doc := _aSD1[_i, 2]
            _sSD1Ser := _aSD1[_i, 3] 
            _sSD1For := _aSD1[_i, 4]
            _sSD1Loj := _aSD1[_i, 5]
            _sSD1Inf := _aSD1[_i, 6]

            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT "
            _oSQL:_sQuery += " 	    DE_CONTA "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SDE") 
            _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND DE_FILIAL   = '" + _sSD1Fil + "' "
            _oSQL:_sQuery += " AND DE_DOC      = '" + _sSD1Doc + "' "
            _oSQL:_sQuery += " AND DE_SERIE    = '" + _sSD1Ser + "' "
            _oSQL:_sQuery += " AND DE_FORNECE  = '" + _sSD1For + "' "
            _oSQL:_sQuery += " AND DE_LOJA     = '" + _sSD1Loj + "' "
            _oSQL:_sQuery += " AND DE_ITEMNF   = '" + _sSD1Inf + "' "
            _oSQL:_sQuery += " AND DE_ITEM     = '" + cItem    + "' "
            _aSDE := aclone (_oSQL:Qry2Array ())

            If Len(_aSDE) > 0
                For _x := 1 to Len(_aSDE)
                    cConta := _aSDE[_x, 1]
                Next
            EndIf
        Next
    EndIf
Return cConta
