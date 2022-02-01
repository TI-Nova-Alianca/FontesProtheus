//  Programa...: VA_XLS58
//  Autor......: Cláudia Lionço
//  Data.......: 25/01/2021
//  Descricao..: Planilha informativa Cenecoop
//
// #TipoDePrograma    #relatorio
// #Descricao         #Planilha informativa Cenecoop
// #PalavasChave      #cenecoop #vendas_cenecoop
// #TabelasPrincipais #SD2 #SD1 #SD3 #SZE 
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
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
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Nota Fiscal"	 ,	    				,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Número da carga",       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Variedade"		 ,       				,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Kg"	         , "@E 999,999,999.99"  ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    TRCell():New(oSection1,"COLUNA5", 	"" ,"Babo"	         ,                      ,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Lote NA"		 ,       		        ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
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
    _oSQL:_sQuery += " FROM " + RetSQLName ("SF2") + " SF2 "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
    _oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_   = '' "
    _oSQL:_sQuery += " 		AND SA1.A1_COD  = F2_CLIENTE "
    _oSQL:_sQuery += " 		AND SA1.A1_LOJA = SF2.F2_LOJA "
    _oSQL:_sQuery += " 		AND A1_COD = '009319' "
    _oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SD2") + " SD2 "
    _oSQL:_sQuery += " 	ON SD2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SD2.D2_FILIAL  = SF2.F2_FILIAL "
    _oSQL:_sQuery += " 		AND SD2.D2_DOC     = SF2.F2_DOC "
    _oSQL:_sQuery += " 		AND SD2.D2_CLIENTE = SF2.F2_CLIENTE "
    _oSQL:_sQuery += " WHERE SF2.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " AND F2_FILIAL BETWEEN '"+ mv_par03 + "' AND '" + mv_par04 +"'"
    _oSQL:_sQuery += " AND F2_EMISSAO BETWEEN '"+ DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) +"'"
    _oSQL:Log ()
    _aNf := aclone (_oSQL:Qry2Array (.F., .F.))

    For _x:=1 to Len(_aNf)
        // Busca dados na função do robert
		_sMapa := U_RastLT (_aNf[_x,1], U_TamFixo (_aNf[_x,8], 15, ' '), alltrim(_aNf[_x,9]), 0, NIL)
        _sArq  := 'c:\temp\rast.mm'
         
        delete file (_sArq)
        if file (_sArq) 
            _nHdl = fopen(_sArq, 1)
        else
            _nHdl = fcreate(_sArq, 0)
        endif

        fwrite (_nHdl, _sMapa)
        fclose (_nHdl)
        ShellExecute ("Open", _sArq, "", "", 1)
            
        u_log (_aLtXLS58)

        For _i:=1 to Len(_aLtXLS58)
            _sNota := _aNf[_x,2] +"-" + _aNf[_x,3] 

            // Imprimir os dados
            oSection1:Init()
            oSection1:SetHeaderSection(.T.)
            oSection1:Cell("COLUNA1")	:SetBlock   ({||  _aNf[_x,2] +"/" + _aNf[_x,3] }) // nota
            oSection1:Cell("COLUNA2")	:SetBlock   ({||  _aLtXLS58[_i, 4]	}) // carga
            oSection1:Cell("COLUNA3")	:SetBlock   ({||  ''	            }) // variedade
            oSection1:Cell("COLUNA4")	:SetBlock   ({||  _aLtXLS58[_i, 3] 	}) // kg
            oSection1:Cell("COLUNA5")	:SetBlock   ({||  _aLtXLS58[_i, 6]  }) // grau
            oSection1:Cell("COLUNA6")	:SetBlock   ({||  _aLtXLS58[_i, 2]  }) // lote NA

            oSection1:PrintLine()
        Next

    Next
    oSection1:Finish()
    TRA->(DbCloseArea())
Return
//
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Emissao de      	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Emissao até     	", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Filial de        	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Filial até       	", "C", 2, 0,  "",  "   ", {},                         					""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
