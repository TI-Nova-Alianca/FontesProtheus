// Programa: VA_DA0TAB
// Autor...: Cláudia Lionço
// Data....: 06/10/2023
// Funcao..: Impressão de tabela de preço
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Impressão de tabela de preço
// #PalavasChave      #vendas #tabela_de_preco
// #TabelasPrincipais #DA0 #DA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_DA0TAB()
	Private oReport
	Private cPerg := "VA_DA0TAB"
	
    If ! U_ZZUVL ('156', __cUserID, .T.)
        u_help("Usuário sem permissão no grupo 156!")
		return
	EndIf
    
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
    Local oBreak

	oReport := TReport():New("VA_DA0TAB","Impressão de tabela de preço",cPerg,{|oReport| PrintReport(oReport)},"Impressão de tabela de preço")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				    , 10,/*lPixel*/,{||     },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Tabela"		,       					, 10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA3", 	"" ,"Tipo Frete"	,       					, 12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"% Rapel"		,       					, 12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Descrição"		,       					, 30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Item"		    ,       					, 08,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Produto"		,       					, 20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7_1", "" ,"Descrição"		,       					, 30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7_2", "" ,"Marca"		    ,       					, 20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7_3", "" ,"Linha"		    ,       					, 20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Estado"		,       					, 08,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Preço Venda"	, "@E 999,999,999.99"   	, 20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Vlr.ST"	    , "@E 999,999,999.99"   	, 20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Coordenador"	,                           , 30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA12", 	"" ,"Último Fat."	,                         	, 20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)

    oBreak := TRBreak():New(oSection1,oSection1:Cell("COLUNA2"),"",.T.,"",.T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local _aDados   := {}
	Local _x        := 0
    Local _y        := 0

    oSection1:Init()
    oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   DA0.DA0_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,DA0.DA0_CODTAB AS TABELA "
    _oSQL:_sQuery += "    ,CASE "
    _oSQL:_sQuery += "          WHEN DA0.DA0_VATPFR = 'C' THEN 'CIF' "
    _oSQL:_sQuery += "          WHEN DA0.DA0_VATPFR = 'F' THEN 'FOB' "
    _oSQL:_sQuery += "     END AS TIPO_FRETE "
    _oSQL:_sQuery += "    ,DA0.DA0_RAPEL AS PERC_RAPEL "
    _oSQL:_sQuery += "    ,DA0.DA0_DESCRI AS DESCRICAO "
    _oSQL:_sQuery += " FROM " + RetSQLName ("DA0") + " AS DA0 "
    _oSQL:_sQuery += " WHERE DA0.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND DA0.DA0_FILIAL BETWEEN '"+ mv_par01 +"' AND '"+ mv_par02 +"' "
    If mv_par09 == 1
        _oSQL:_sQuery += " AND DA0_ATIVO <> '2' "
    elseif mv_par09 == 2
        _oSQL:_sQuery += " AND DA0_ATIVO = '2' "
    endif
    _oSQL:_sQuery += " AND DA0_CODTAB BETWEEN '"+ mv_par03 +"' AND '"+ mv_par04 +"' "
    _oSQL:_sQuery += " ORDER BY DA0.DA0_FILIAL, DA0.DA0_CODTAB "

    _aDados := aclone(_oSQL:Qry2Array())

	For _x :=1 to Len(_aDados)
        _sGerente := ""
        _dUltVen  := ""

        // busca gerente
        if mv_par10 == 1
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT DISTINCT "
            _oSQL:_sQuery += " 	    A3_VAGEREN "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SA1") + " AS SA1 "
            _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
            _oSQL:_sQuery += " 	ON SA3.D_E_L_E_T_   = '' "
            _oSQL:_sQuery += " 		AND SA3.A3_COD  = A1_VEND "
            _oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND SA1.A1_MSBLQL    = '2' "
            _oSQL:_sQuery += " AND A1_VAFILAT       = '"+ _aDados[_x, 1] +"' "
            _oSQL:_sQuery += " AND A1_TABELA        = '"+ _aDados[_x, 2] +"' "
            
            _aGerente := aclone(_oSQL:Qry2Array())

            for _y:=1 to Len(_aGerente)
                if Len(_aGerente) > 1
                    _sGerente += _aGerente[_y, 1] + "|"
                else
                    _sGerente += _aGerente[_y, 1] 
                endif
            next
        endif

        if mv_par11 == 1
            _oSQL:= ClsSQL ():New ()
            _oSQL:_sQuery := ""
            _oSQL:_sQuery += " SELECT TOP 1 "
            _oSQL:_sQuery += " 	F2_EMISSAO "
            _oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " AS SF2 "
            _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SC5") + " AS SC5 "
            _oSQL:_sQuery += " 	ON SC5.D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " 		AND SC5.C5_FILIAL = SF2.F2_FILIAL "
            _oSQL:_sQuery += " 		AND SC5.C5_NOTA = SF2.F2_DOC "
            _oSQL:_sQuery += " 		AND SC5.C5_TABELA = '"+ _aDados[_x, 2] +"' "
            _oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
            _oSQL:_sQuery += " AND F2_FILIAL = '"+ _aDados[_x, 1] +"' "
            _oSQL:_sQuery += " ORDER BY SF2.F2_EMISSAO DESC "
            _aUltVen := aclone(_oSQL:Qry2Array())

            if Len(_aUltVen) > 0
                _dUltVen := _aUltVen[1,1]
            endif
        endif

        _oSQL:= ClsSQL ():New ()
        _oSQL:_sQuery := ""
        _oSQL:_sQuery += " SELECT "
        _oSQL:_sQuery += "     DA1.DA1_ITEM AS ITEM "
        _oSQL:_sQuery += "    ,DA1.DA1_CODPRO AS PRODUTO "
        _oSQL:_sQuery += "    ,SB1.B1_DESC "
        _oSQL:_sQuery += "    ,ZX540.ZX5_40COD + ' - ' + ZX540.ZX5_40DESC AS MARCA  "
        _oSQL:_sQuery += "    ,ZX539.ZX5_39COD + ' - ' + ZX539.ZX5_39DESC AS LINHA "
        _oSQL:_sQuery += "    ,DA1.DA1_ESTADO AS ESTADO "
        _oSQL:_sQuery += "    ,DA1.DA1_PRCVEN AS PRECO_VENDA "
        _oSQL:_sQuery += "    ,DA1.DA1_VAST AS VALOR_ST "
        _oSQL:_sQuery += " FROM " + RetSQLName ("DA1") + " AS DA1 "
        _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
        _oSQL:_sQuery += " 	ON SB1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND SB1.B1_COD = DA1_CODPRO "
        _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZX5") + " AS ZX540 " 
        _oSQL:_sQuery += " 	ON ZX540.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND ZX540.ZX5_TABELA = '40' "
        _oSQL:_sQuery += " 		AND ZX540.ZX5_40COD = SB1.B1_VAMARCM "
        _oSQL:_sQuery += " LEFT JOIN " + RetSQLName ("ZX5") + " AS ZX539 " 
        _oSQL:_sQuery += " 	ON ZX539.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " 		AND ZX539.ZX5_TABELA = '39' "
        _oSQL:_sQuery += " 		AND ZX539.ZX5_39COD = SB1.B1_CODLIN "
        _oSQL:_sQuery += " WHERE DA1.D_E_L_E_T_ = '' "
        _oSQL:_sQuery += " AND DA1.DA1_FILIAL = '"+ _aDados[_x, 1] +"' "
        _oSQL:_sQuery += " AND DA1.DA1_CODTAB = '"+ _aDados[_x, 2] +"' "
        _oSQL:_sQuery += " AND DA1.DA1_CODPRO BETWEEN '"+ mv_par05 +"' AND '"+ mv_par06 +"' "
        _oSQL:_sQuery += " AND DA1.DA1_ESTADO BETWEEN '"+ mv_par07 +"' AND '"+ mv_par08 +"' "
        _aItens := aclone(_oSQL:Qry2Array())

        for _y:=1 to Len(_aItens)

            oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1] }) 
            oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2] }) 
            oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 3] }) 
            oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_x, 4] }) 
            oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_x, 5] }) 
            oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aItens[_y, 1] }) 
            oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aItens[_y, 2] }) 
            oSection1:Cell("COLUNA7_1")	:SetBlock   ({|| _aItens[_y, 3] }) 
            oSection1:Cell("COLUNA7_2")	:SetBlock   ({|| _aItens[_y, 4] }) 
            oSection1:Cell("COLUNA7_3")	:SetBlock   ({|| _aItens[_y, 5] }) 
            oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aItens[_y, 6] }) 
            oSection1:Cell("COLUNA9")	:SetBlock   ({|| _aItens[_y, 7] }) 
            oSection1:Cell("COLUNA10")	:SetBlock   ({|| _aItens[_y, 8] }) 
            oSection1:Cell("COLUNA11")	:SetBlock   ({|| _sGerente      }) 
            oSection1:Cell("COLUNA12")	:SetBlock   ({|| _dUltVen       }) 

            oSection1:PrintLine()
        next
	Next
	oSection1:Finish()
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de         ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Filial até        ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {03, "Tabela de         ", "C",  3, 0,  "",       "DA0", {},                         		 ""})
    aadd (_aRegsPerg, {04, "Tabela até        ", "C",  3, 0,  "",       "DA0", {},                         		 ""})
    aadd (_aRegsPerg, {05, "Produto de        ", "C", 15, 0,  "",       "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {06, "Produto até       ", "C", 15, 0,  "",       "SB1", {},                         		 ""})
    aadd (_aRegsPerg, {07, "Estado de         ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {08, "Estado até        ", "C",  2, 0,  "",       "   ", {},                         		 ""})
    aadd (_aRegsPerg, {09, "Ativo/Inativo     ", "N",  1, 0,  "",       "   ", {"Ativas","Inativas","Ambas"},    ""})
    aadd (_aRegsPerg, {10, "Imp.Gerente       ", "N",  1, 0,  "",       "   ", {"Sim","Não"},                    ""})
    aadd (_aRegsPerg, {11, "Ult.Venda         ", "N",  1, 0,  "",       "   ", {"Sim","Não"},                    ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
