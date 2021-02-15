//  Programa...: ZB1RTIT
//  Autor......: Cláudia Lionço
//  Data.......: 08/12/2020
//  Cliente....: Alianca
//  Descricao..: Relatório Importações
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de importações
// #PalavasChave      #cartao #titulos #
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function ZB1REL()
	Private oReport
	Private cPerg := "ZB1REL"
	
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
	//Local oBreak1

	oReport := TReport():New("ZB1REL","Importação de pagamentos Cielo",cPerg,{|oReport| PrintReport(oReport)},"Importação de pagamentos Cielo")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Liquido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Parcela"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"%.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Dt.Venda"		,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Dt.Proces."	,       					,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"Status"		,	    					,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"Cre/Deb"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	Local i          := 0
	Local _nTotVenda := 0
	Local _nTotTax   := 0
	Local _nTotDVenda:= 0
	Local _nTotDTax  := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "      ZB1_FILIAL"
    _oSQL:_sQuery += "      ,ZB1_VLRLIQ"
    _oSQL:_sQuery += "      ,ZB1_VLRPAR"
    _oSQL:_sQuery += "      ,ZB1_PERTAX"
    _oSQL:_sQuery += "      ,ZB1_DTAVEN"
    _oSQL:_sQuery += "      ,ZB1_DTAPRO"
    _oSQL:_sQuery += "      ,ZB1_AUTCOD"
    _oSQL:_sQuery += "      ,ZB1_NSUCOD"
    _oSQL:_sQuery += "      ,ZB1_PARNUM"
    _oSQL:_sQuery += "      ,ZB1_STAIMP"
    _oSQL:_sQuery += "      ,ZB1_SINAL"
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZB1") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_=''
    If !empty(mv_par01)
        _oSQL:_sQuery += " AND ZB1_FILIAL BETWEEN '" + mv_par01 +"' AND '" + mv_par02 +"'"
    EndIf
    _oSQL:_sQuery += " AND ZB1_DTAPRO = '"+ DTOS(mv_par03)+"'"
    _aZB1 := aclone (_oSQL:Qry2Array ())

	For i:=1 to Len(_aZB1)

		_sParc := ''
		If alltrim(_aZB1[i, 9]) <> '00' .or. alltrim(_aZB1[i, 9]) <> '' 
			_sParc := BuscaParcela(_aZB1[i, 9])
		EndIf
		// Busca dados do título para fazer a baixa
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += "     SE1.E1_PREFIXO"	// 01
		_oSQL:_sQuery += "    ,SE1.E1_NUM"		// 02
		_oSQL:_sQuery += "    ,SE1.E1_PARCELA"	// 03
		_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"	// 04
		_oSQL:_sQuery += "    ,SE1.E1_LOJA"		// 05
		_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
		_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + _aZB1[i, 1] + "'"
		If alltrim(_aZB1[i, 1]) <> '01'
			_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,7] + "'" // Loja salva cod.aut no campo NSU
			_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aZB1[i,5]) + "'"
		Else
			_oSQL:_sQuery += " AND SE1.E1_CARTAUT = '" + _aZB1[i,7] + "'"
			_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,8] + "'"
		EndIf
		If alltrim(_sParc) <> ''
			_oSQL:_sQuery += " AND SE1.E1_PARCELA   = '" + _sParc + "'"
		EndIf
		_oSQL:_sQuery += " AND SE1.E1_TIPO   IN ('CC','CD')"
		_aTitulo := aclone (_oSQL:Qry2Array ())

		If len(_aTitulo) > 0
			_sTitulo  := alltrim(_aTitulo[1,2]) +"/" + alltrim(_aTitulo[1,1] +"/"+_aTitulo[1,3])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aTitulo[1,4] + _aTitulo[1,5],"A1_NOME")
			_sCliente := alltrim(_aTitulo[1,4]) +"/" + alltrim(_sNome)
		Else
			_sTitulo  := "-"
			_sNome    := "-"
			_sCliente := "-"
		EndIf

		If _aZB1[i,11] == '+'
			_sCreDeb := 'Crédito'
		Else
			_sCreDeb := 'Débito'
		EndIf

        _vlrTaxa := ROUND((_aZB1[i,3] * _aZB1[i,4])/100 ,2)
        
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aZB1[i,1] }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo   }) // titulo
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sCliente  }) // cliente
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aZB1[i,2] }) // vlr. liquido
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aZB1[i,3] }) // vlr.parcela
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aZB1[i,4] }) // % taxa
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _vlrTaxa   }) // vlr. taxa
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aZB1[i,5] }) // dt. venda
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aZB1[i,6] }) // dt. process
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aZB1[i,7] }) // cod.autoriz
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| _aZB1[i,8] }) // NSU
		oSection1:Cell("COLUNA12")	:SetBlock   ({|| _aZB1[i,10]}) // status
		oSection1:Cell("COLUNA13")	:SetBlock   ({|| _sCreDeb  }) // status
		
		If alltrim(_aZB1[i,10]) == 'I'
			_nTotVenda += _aZB1[i,3]
			_nTotTax   += _vlrTaxa
		Else
			If alltrim(_aZB1[i,10]) == 'D'
				_nTotDVenda += _aZB1[i,3]
				_nTotDTax   += _vlrTaxa
			EndIf
		EndIf
		oSection1:PrintLine()
	Next

	oReport:ThinLine()
	oReport:SkipLine(1)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL CREDITO EM CONTA:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVenda, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)

	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL DEBITO EM CONTA:" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotDVenda, "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotDTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)
	oReport:ThinLine()

	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("TOTAL GERAL" ,, 100)
	_nLinha:= _PulaFolha(_nLinha)
	oReport:PrintText("Valor da Parcela:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotVenda - _nTotDVenda , "@E 999,999,999.99"),20,' '),, 900)
	oReport:PrintText("Valor da Taxa:" ,, 100)
	oReport:PrintText(PADL('R$' + Transform(_nTotTax - _nTotDTax, "@E 999,999,999.99"),20,' '),, 900)
	oReport:SkipLine(1)
	oReport:ThinLine()

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Pular folha na impressão
Static Function _PulaFolha(_nLinha)
	local _nRet := 0

	If  _nLinha > 2300
		oReport:EndPage()
		oReport:StartPage()
		_nRet := oReport:Row()
	Else
		_nRet := _nLinha
	EndIf
Return _nRet
// --------------------------------------------------------------------------
// Busca Parcelas
Static Function BuscaParcela(_sParcela)
	Local _sParc := ''

	Do Case
		Case alltrim(_sParcela) == '01'
			_sParc:= 'A'
		Case alltrim(_sParcela) == '02'
			_sParc:= 'B'
		Case alltrim(_sParcela) == '03'
			_sParc:= 'C'
		Case alltrim(_sParcela) == '04'
			_sParc:= 'D'
		Case alltrim(_sParcela) == '05'
			_sParc:= 'E'
		Case alltrim(_sParcela) == '06'
			_sParc:= 'F'
		Case alltrim(_sParcela) == '07'
			_sParc:= 'G'
		Case alltrim(_sParcela) == '08'
			_sParc:= 'H'
		Case alltrim(_sParcela) == '09'
			_sParc:= 'I'
		Case alltrim(_sParcela) == '10'
			_sParc:= 'J'
		Case alltrim(_sParcela) == '11'
			_sParc:= 'K'
		Case alltrim(_sParcela) == '12'
			_sParc:= 'L'
		Otherwise
			_sParc:=''
	EndCase
Return _sParc

//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de        ", "C", 2, 0,  "",   "   ", {},                         		 ""})
	aadd (_aRegsPerg, {02, "Filial até       ", "C", 2, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Data             ", "D", 8, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
