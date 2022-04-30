//  Programa...: VA_XLS58
//  Autor......: Cl�udia Lion�o
//  Data.......: 25/01/2021
//  Descricao..: Planilha informativa Cenecoop
//
// #TipoDePrograma    #relatorio
// #Descricao         #Planilha informativa Cenecoop
// #PalavasChave      #cenecoop #vendas_cenecoop
// #TabelasPrincipais #SD2 #SD1 #SD3 #SZE 
// #Modulos           #FAT
//
// Historico de alteracoes:
// 14/02/2022 - Claudia - Incluida quantidade proporcionalizada. GLPI: 11624
// 16/02/2022 - Claudia - Limpeza do array a cada chamada da rotina de rastreabilidade. GLPI: 11624
// 17/02/2022 - Claudia - Criada novas colunas para linha. GLPI: 11624
// 23/02/2022 - Robert  - Incluidas colunas filial e safra (GLPI 11664).
// 02/03/2022 - Robert  - Coluna 'Kg' (COLUNA5) passada para a frente da coluna 'Produto'.
// 21/03/2022 - Claudia - Incluido o codigo CR (sisdevin). GLPI: 11727
// 27/04/2022 - Robert  - Criados parametros de NF de... ate
//
// ------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'

User function VA_XLS58()
	Private oReport
	Private cPerg   := "VA_XLS58"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil

	oReport := TReport():New("VA_XLS58","Planilha informativa Cenecoop",cPerg,{|oReport| PrintReport(oReport)},"Planilha informativa Cenecoop")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Nota Fiscal"	    ,	    				,20,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Num.Carga"         ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2_1", "" ,"Filial"            ,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2_2", "" ,"Safra"             ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Variedade"		    ,       				,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4", 	"" ,"Descri��o"		    ,       				,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Kg"	            , "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4_1", "" ,"Produto"		    ,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA4_2", "" ,"Descri��o "		,       				,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA6", 	"" ,"Babo"	            ,                       ,15,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6_1", "" ,"C�d.CR"	        ,       		        ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA7", 	"" ,"Lote carga"	    ,       		        ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA8", 	"" ,"Lote produto"	    ,       		        ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA9", 	"" ,"Emiss�o NF"	    ,       		        ,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Cod.Cliente"	    ,       		        ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Nome"	            ,       		        ,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
    Local _oSQL     := ClsSQL():New ()
    Local _x        := 0
    Local _i        := 0
    Private _aLtXLS58 := {} 

    _oSQL:_sQuery := ""
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	   SD2.D2_FILIAL AS FILIAL "
    _oSQL:_sQuery += "    ,SD2.D2_DOC AS DOC "
    _oSQL:_sQuery += "    ,SD2.D2_SERIE AS SERIE "
    _oSQL:_sQuery += "    ,SD2.D2_CLIENTE AS CLIENTE "
    _oSQL:_sQuery += "    ,SD2.D2_LOJA AS LOJA "
    _oSQL:_sQuery += "    ,SA1.A1_NOME AS NOME "
    _oSQL:_sQuery += "    ,SD2.D2_EMISSAO AS EMISSAO"
    _oSQL:_sQuery += "    ,SD2.D2_COD AS PRODUTO "
    _oSQL:_sQuery += "    ,SD2.D2_LOTECTL AS LOTE"
    _oSQL:_sQuery += "    ,SD2.D2_QUANT AS QUANT "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_   = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD  = F2_CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = SF2.F2_LOJA "
    _oSQL:_sQuery += " 		AND A1_COD  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' "
    _oSQL:_sQuery += " 		AND A1_LOJA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SD2") + " SD2 "
    _oSQL:_sQuery += " 	ON SD2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SD2.D2_FILIAL  = SF2.F2_FILIAL "
    _oSQL:_sQuery += " 		AND SD2.D2_DOC     = SF2.F2_DOC "
    _oSQL:_sQuery += "      AND SD2.D2_SERIE   = SF2.F2_SERIE ""
    _oSQL:_sQuery += " 		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
    _oSQL:_sQuery += "      AND SD2.D2_LOJA    = SF2.F2_LOJA "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery += "  ON SB1.D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " 	    AND SB1.B1_COD  = SD2.D2_COD "
	_oSQL:_sQuery += " 	    AND SB1.B1_TIPO = 'VD' "
    _oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND F2_FILIAL BETWEEN '"+ mv_par03 + "' AND '" + mv_par04 +"'"
    _oSQL:_sQuery += " AND F2_EMISSAO BETWEEN '"+ DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) +"'"
    _oSQL:_sQuery += " AND F2_DOC BETWEEN '"+ mv_par09 + "' AND '" + mv_par10 +"'"
    _oSQL:Log ()
    _aNf := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aNf)
        // Busca dados na fun��o do robert
        _aLtXLS58 :={}
		_sMapa := U_RastLT (_aNf[_x,1], U_TamFixo (_aNf[_x,8], 15, ' '), alltrim(_aNf[_x,9]), 0, NIL, _aNf[_x,10])

		// Habilitar este trecho se precisar gerar a arvore de cada nota fiscal
        _sArq  := 'c:\temp\rast_F' + _aNf[_x,1] + '_NF' + _aNf[_x,2] + '_Lt_' + alltrim(_aNf[_x,9]) + '.mm'
        delete file (_sArq)
        if file (_sArq) 
            _nHdl = fopen(_sArq, 1)
        else
            _nHdl = fcreate(_sArq, 0)
        endif
        fwrite (_nHdl, _sMapa)
        fclose (_nHdl)
        ShellExecute ("Open", _sArq, "", "", 1)
*/

        u_log2 ('debug', _aLtXLS58)

        For _i:=1 to Len(_aLtXLS58)
            _sDesc    := POSICIONE("SB1",1,XFILIAL("SB1") + _aLtXLS58[_i, 1] ,"B1_DESC")  
            _sDescProd:= POSICIONE("SB1",1,XFILIAL("SB1") + _aNf[_x,8]       ,"B1_DESC")

            _sCodCR := _BuscaCodCR(_aNf[_x,1], _aNf[_x,8])

            // Imprimir os dados
            oSection1:Init()
            oSection1:SetHeaderSection(.T.)
            oSection1:Cell("COLUNA1")	:SetBlock   ({||  _aNf[_x,2] +"/" + _aNf[_x,3]  })  // nota
            oSection1:Cell("COLUNA2")	:SetBlock   ({||  _aLtXLS58[_i, 4]	            })  // carga
            oSection1:Cell("COLUNA2_1")	:SetBlock   ({||  _aLtXLS58[_i, 8]              })  // filial da carga
            oSection1:Cell("COLUNA2_2")	:SetBlock   ({||  _aLtXLS58[_i, 9]              })  // safra da carga
            oSection1:Cell("COLUNA3")	:SetBlock   ({||  alltrim(_aLtXLS58[_i, 1])     })  // variedade
            oSection1:Cell("COLUNA4")	:SetBlock   ({||  _sDesc                        })  // descri��o
            oSection1:Cell("COLUNA4_1")	:SetBlock   ({||  _aNf[_x,8]                    })  // Produto
            oSection1:Cell("COLUNA4_2")	:SetBlock   ({||  _sDescProd                    })  // produto descri��o
            oSection1:Cell("COLUNA5")	:SetBlock   ({||  _aLtXLS58[_i, 7] 	            })  // kg
            oSection1:Cell("COLUNA6")	:SetBlock   ({||  _aLtXLS58[_i, 6]              })  // grau
            oSection1:Cell("COLUNA6_1")	:SetBlock   ({||  _sCodCR                       })  // cod.CR
            oSection1:Cell("COLUNA7")	:SetBlock   ({||  _aLtXLS58[_i, 2]              })  // lote carga
            oSection1:Cell("COLUNA8")	:SetBlock   ({||  _aNf[_x, 9]                   })  // lote nota
            oSection1:Cell("COLUNA9")	:SetBlock   ({||  STOD(_aNf[_x, 7])             })  // emissao
            oSection1:Cell("COLUNA10")	:SetBlock   ({||  _aNf[_x, 4]                   })  // cod.cliente
            oSection1:Cell("COLUNA11")	:SetBlock   ({||  _aNf[_x, 6]                   })  // nome cliente

            oSection1:PrintLine()
        Next
    Next
    oSection1:Finish()
    TRA->(DbCloseArea())
Return
//
// -------------------------------------------------------------------------
// Busca c�digo CR
Static Function _BuscaCodCR(_sFilial, _sProduto)
    Local _sCodCR := ""

    Do Case
        Case _sFilial == '01'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD01")  
        Case _sFilial == '03'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD03")  
        Case _sFilial == '05'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD05")  
        Case _sFilial == '06'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD06")  
        Case _sFilial == '07'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD07")  
        Case _sFilial == '08'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD08")  
        Case _sFilial == '09'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD09")  
        Case _sFilial == '10'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD10")  
        Case _sFilial == '11'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD11")  
        Case _sFilial == '12'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD12")  
        Case _sFilial == '13'
            _sCodCR := POSICIONE("SB5",1,XFILIAL("SB5") + _sProduto ,"B5_VACSD13")  
    EndCase
Return _sCodCR
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Emissao de         ", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Emissao at�        ", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Filial de          ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Filial at�         ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "Cliente de         ", "C", 6, 0,  "",  "SA1", {},                         					""})
    aadd (_aRegsPerg, {06, "Cliente at�        ", "C", 6, 0,  "",  "SA1", {},                         					""})
    aadd (_aRegsPerg, {07, "Loja de            ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {08, "Loja at�           ", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {09, "NF de              ", "C", 9, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {10, "NF at�             ", "C", 9, 0,  "",  "   ", {},                         					""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
