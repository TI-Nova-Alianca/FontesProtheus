// Programa...: VA_INTEGR.prw
// Autor......: Cláudia Lionço
// Data.......: 10/06/2024
// Descricao..: Relatorio de verificação de integralizações de associados
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de verificação de integralizações de associados
// #PalavasChave      #associados #integralizacoes 
// #TabelasPrincipais #VA_VASSOC_INTEGRALIZACOES
// #Modulos   		  #COOP 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function VA_INTEGR()
	Private oReport
	Private cPerg   := "VA_INTEGR"

	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oBreak1

	oReport := TReport():New("VA_INTEGR","Integralizações de Associados",cPerg,{|oReport| PrintReport(oReport)},"Integralizações de Associados")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA01", 	"" ,"Código"		,	    					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA02", 	"" ,"Nome"		    ,       					,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA03", 	"" ,"Dt.Entrega"	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA04", 	"" ,"Dt.Saida"	    ,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA05", 	"" ,"Qtd.Movtos"	,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA06", 	"" ,"1ª Entr."		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA07", 	"" ,"Ult.Entr."		,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA08", 	"" ,"Ano 1"		    ,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA09", 	"" ,"Vlr.Pendente 1","@E 999,999,999.99"   	    ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Ano 2"		    ,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Vlr.Pendente 2","@E 999,999,999.99"   	    ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Ano 3"		    ,       					,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"Vlr.Pendente 3","@E 999,999,999.99"   	    ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,{|| },"Total ")
    TRFunction():New(oSection1:Cell("COLUNA09")	,,"SUM"	,oBreak1, "Vlr.1" , 					, NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA11")	,,"SUM"	,oBreak1, "Vlr.2" , 					, NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA13")	,,"SUM"	,oBreak1, "Vlr.3" , 					, NIL, .F., .T.)


Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1:= oReport:Section(1)
    Local _aDados  := {}
    Local _aVlr    := {}
	Local _x       := 0
    Local _i       := 0

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT * FROM VA_VASSOC_INTEGRALIZACOES "
    _oSQL:_sQuery += " ORDER BY A2_NOME "
    _aDados := aclone(_oSQL:Qry2Array(.f., .f.))

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    For _x:=1 to Len(_aDados)
        _sAssoc  := _aDados[_x, 1]
        _sLoja   := _aDados[_x, 2]
        _nQtdMov := _aDados[_x, 6]
        _aVlr    := {}

        _nQtdTot := 3 - _nQtdMov

        If _nQtdMov == 0
            _dData := stod(_aDados[_x, 7] +'0101')
        else
            _dData := YearSum(stod(_aDados[_x, 8]+'0101'), 1)
        EndIf

        For _i := 1 to 3
            if _i <= _nQtdTot
                _nVlr := _BuscaValor(str(year(_dData)), _sAssoc, _sLoja)
                aadd(_aVlr,{alltrim(str(year(_dData))), _nVlr})

                _dData := YearSum(_dData, 1)
            else
                aadd(_aVlr,{'', 0})
            endif
        Next

        oSection1:Cell("COLUNA01")	:SetBlock   ({|| _aDados[_x, 1] + '/' + _aDados[_x, 2]}) 
		oSection1:Cell("COLUNA02")	:SetBlock   ({|| _aDados[_x, 3] }) 
		oSection1:Cell("COLUNA03")	:SetBlock   ({|| stod(_aDados[_x, 4]) }) 
		oSection1:Cell("COLUNA04")	:SetBlock   ({|| stod(_aDados[_x, 5]) }) 
		oSection1:Cell("COLUNA05")	:SetBlock   ({|| _aDados[_x, 6] }) 
		oSection1:Cell("COLUNA06")	:SetBlock   ({|| _aDados[_x, 7] }) 
		oSection1:Cell("COLUNA07")	:SetBlock   ({|| _aDados[_x, 8] }) 
		oSection1:Cell("COLUNA08")	:SetBlock   ({|| _aVlr[1,1] }) 
		oSection1:Cell("COLUNA09")	:SetBlock   ({|| _aVlr[1,2] }) 
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aVlr[2,1] }) 
        oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aVlr[2,2] }) 
        oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aVlr[3,1] }) 
        oSection1:Cell("COLUNA13")	:SetBlock   ({|| _aVlr[3,2] }) 

        oSection1:PrintLine()
    Next

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Busca valor da integralização
Static Function _BuscaValor(_sData, _sAssoc, _sLoja)
    local _nRet    := 0
    local _x       := 0
    local _aDados1 := {}

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT SUM (VALOR_TOTAL) "
    _oSQL:_sQuery += " FROM VA_VNOTAS_SAFRA "
    _oSQL:_sQuery += " WHERE SAFRA    = '"+ alltrim(_sData)  +"' "
    _oSQL:_sQuery += " AND ASSOCIADO  = '"+ _sAssoc +"' "
    _oSQL:_sQuery += " AND LOJA_ASSOC = '"+ _sLoja  +"' "
    _oSQL:_sQuery += " AND TIPO_NF IN ('C', 'V') "
    _aDados1 := aclone(_oSQL:Qry2Array(.f., .f.))

    For _x:= 1 to Len(_aDados1)
        _nRet := _aDados1[_x,1] * 0.05 // 5% do valor entregue
    Next

Return _nRet
// //
// // --------------------------------------------------------------------------
// // Perguntas
// Static Function _ValidPerg ()
//     local _aRegsPerg := {}
//     //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
//     aadd (_aRegsPerg, {01, "Diretorio          ", "C", 40, 0,  "",  "   ", {},                         				""})
//     aadd (_aRegsPerg, {02, "Nome do arquivo    ", "C", 20, 0,  "",  "   ", {},                         				""})
//     aadd (_aRegsPerg, {03, "Extensão           ", "C",  4, 0,  "",  "   ", {},                         				""})
//     U_ValPerg (cPerg, _aRegsPerg)
// Return
