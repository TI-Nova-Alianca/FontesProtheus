// Programa...: ZZXEXP
// Autor......: Cláudia Lionço
// Data.......: 14/04/2022
// Descricao..: Exporta dados de Xmls - Tabela ZZX
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Exporta dados de Xmls - Tabela ZZX
// #PalavasChave      #XML NF_eletronica 
// #TabelasPrincipais #ZZX
// #Modulos           #COM #FAT
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#include "protheus.ch"
#include "totvs.ch"

User Function ZZXEXP()
	Private oReport
	Private cPerg   := "ZZXEXP"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ----------------------------------------------------------------------------------------------------
// Monta cabeçalhos
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("ZZXEXP","Itens da nota - Manutenção de XML",cPerg,{|oReport| PrintReport(oReport)},"Itens da nota - Manutenção de XML")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandScape(.T.)
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"	    ,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Documento"	    ,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Serie"		    ,, 5,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3_1", "" ,"Fornecedor"    ,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3_2", "" ,"Nome"		    ,, 5,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3_3", "" ,"Emissão"		,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"CFOP"		    ,,10,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Desc.XML"	    ,,40,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Desc.Interno"	,,30,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Ordem compra"	,,15,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Qnt."			,,10,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Vlr.Total"		,,18,/*lPixel*/,{|| },"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Item XML"		,,20,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Cod.Interno"	,,20,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"UM XML"		,,10,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA13", 	"" ,"UM Interno"	,,10,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA14", 	"" ,"Conversão"		,,10,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA15", 	"" ,"NCM XML"		,,20,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA16", 	"" ,"NCM Interna"	,,20,/*lPixel*/,{|| },"LEFT",,"",,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local _x        := 0
    Local _nItem    := 0

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += "     ZZX_FILIAL "
    _oSQL:_sQuery += "    ,ZZX_DOC "
    _oSQL:_sQuery += "    ,ZZX_SERIE "
    _oSQL:_sQuery += "    ,ZZX_CODMEM "
    _oSQL:_sQuery += "    ,ZZX_CLIFOR "
    _oSQL:_sQuery += "    ,ZZX_LOJA "
    _oSQL:_sQuery += "    ,ZZX_EMISSA "
    _oSQL:_sQuery += " FROM " + RetSQLName ("ZZX") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND ZZX_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    If mv_par03 == 1
        _oSQL:_sQuery += " AND ZZX_DTIMP BETWEEN '" + dtos(mv_par04) + "' AND '" + dtos(mv_par05) + "' "
    Else
        _oSQL:_sQuery += " AND ZZX_EMISSA BETWEEN '" + dtos(mv_par06) + "' AND '" + dtos(mv_par07) + "' "
    EndIf
    _oSQL:_sQuery += " AND ZZX_CLIFOR BETWEEN '" + mv_par08 + "' AND '" + mv_par09 + "'"
    //if !empty(mv_par09)
    //    _oSQL:_sQuery += " AND ZZX_DOC = '000014937'"
    //endif
    _oSQL:_sQuery += " ORDER BY ZZX_FILIAL,ZZX_DOC,ZZX_SERIE"
    _oSQL:Log()
    _aDados := _oSQL:Qry2Array ()

    oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    For _x:=1 to Len(_aDados)
        _sXML := MSMM (_aDados[_x, 4],,,,3)
		_oXMLSEF := ClsXMLSEF ():New ()
		_oXMLSEF:LeXML (_sXML)
		
		if valtype (_oXMLSEF:NFe) == 'O'
			// Monta array com dados dos itens.
			for _nItem := 1 to len(_oXMLSEF:NFe:ItCFOP)
			    _wxmlpro := UPPER(_oXMLSEF:NFe:ItCprod [_nItem])
				_wcodpro := fbuscacpo ("SA5", 14, xfilial ("SA5") + _aDados[_x, 5] + _aDados[_x, 6] + _wxmlpro,  "A5_PRODUTO") // codigo interno

                oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1] }) 
                oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2] }) 
                oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 3] }) 
                oSection1:Cell("COLUNA3_1")	:SetBlock   ({|| _aDados[_x, 5] + "-" + _aDados[_x, 6]  }) 
                oSection1:Cell("COLUNA3_2")	:SetBlock   ({|| fbuscacpo("SA2", 1, xfilial ("SA2") + _aDados[_x, 5] + _aDados[_x, 6], "A2_NOME") }) 
                oSection1:Cell("COLUNA3_3")	:SetBlock   ({|| _aDados[_x, 7] }) 
                oSection1:Cell("COLUNA4")	:SetBlock   ({|| _oXMLSEF:NFe:ItCFOP [_nItem] + ' - ' + Tabela ('13', _oXMLSEF:NFe:ItCFOP [_nItem]) }) 
                oSection1:Cell("COLUNA5")	:SetBlock   ({|| _oXMLSEF:NFe:ItDescri [_nItem] }) 
                oSection1:Cell("COLUNA6")	:SetBlock   ({|| fbuscacpo("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_DESC")  }) 
                oSection1:Cell("COLUNA7")	:SetBlock   ({|| _oXMLSEF:NFe:ItXPed  [_nItem] }) 
                oSection1:Cell("COLUNA8")	:SetBlock   ({|| _oXMLSEF:NFe:ItQuant [_nItem] }) 
                oSection1:Cell("COLUNA9")	:SetBlock   ({|| _oXMLSEF:NFe:ItVlTot [_nItem] }) 
                oSection1:Cell("COLUNA10")	:SetBlock   ({|| _wxmlpro }) 
                oSection1:Cell("COLUNA11")	:SetBlock   ({|| _wcodpro }) 
                oSection1:Cell("COLUNA12")	:SetBlock   ({|| _oXMLSEF:NFe:ItuCom [_nItem] }) 
                oSection1:Cell("COLUNA13")	:SetBlock   ({|| fbuscacpo("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_UM")  }) 

                if _oXMLSEF:NFe:ItuCom [_nItem] != fbuscacpo("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_UM") 
                    _wfator =  fbuscacpo ("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_CONV") // fator de conversao
                    if _wfator > 0 
                        _wconversao := 'OK'
                    else
                        _wconversao := 'NAO INFORMADA'
                    endif																	
                else
                    _wconversao := "MESMA UNIDADE"
                endif

                oSection1:Cell("COLUNA14")	:SetBlock   ({|| _wconversao }) 
                oSection1:Cell("COLUNA15")	:SetBlock   ({|| _oXMLSEF:NFe:ItNCM [_nItem] }) 
                oSection1:Cell("COLUNA16")	:SetBlock   ({|| fbuscacpo("SB1", 1, xfilial ("SB1") + _wcodpro,  "B1_POSIPI") }) 

                oSection1:PrintLine()
			Next
        EndIf
    Next
Return
//
// ------------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
    aadd (_aRegsPerg, {01, "Filial de     ", "C", 2, 0,  "",   "   ", {} , ""})
	aadd (_aRegsPerg, {02, "Filial até    ", "C", 2, 0,  "",   "   ", {} , ""})
    aadd (_aRegsPerg, {03, "Por data de   ", "N", 1, 0,  "",   "   ", {"Digitação","Emissao"} , ""})
    aadd (_aRegsPerg, {04, "Digitacao de  ", "D", 8, 0,  "",   "   ", {} , ""})
    aadd (_aRegsPerg, {05, "Digitacao até ", "D", 8, 0,  "",   "   ", {} , ""})
	aadd (_aRegsPerg, {06, "Emissao de    ", "D", 8, 0,  "",   "   ", {} , ""})
	aadd (_aRegsPerg, {07, "Emissao até   ", "D", 8, 0,  "",   "   ", {} , ""})
	aadd (_aRegsPerg, {08, "Fornecedor de ", "C", 6, 0,  "",   "SA2", {} , "Código do Fornecedor"})
	aadd (_aRegsPerg, {09, "Fornecedor ate", "C", 6, 0,  "",   "SA2", {} , "Código do Fornecedor"})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
