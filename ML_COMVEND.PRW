// Programa.: ML_COMVEND
// Autor....: Claudia Lionço
// Data.....: 13/01/2022
// Descricao: Demonstrativo de indenização sobre comissões
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Relatório
// #Descricao         #Demonstrativo de indenização sobre comissões
// #PalavasChave      #comissao #provisionado 
// #TabelasPrincipais #SE3 #SA1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 13/01/2022 - Claudia - Realizado melhorias no relatorio, originalmente desenvolvido por 
//                        Catia Cardoso, conforme GLPI: 11468
//
// --------------------------------------------------------------------------------------------------- 
#include 'protheus.ch'
#include 'parmtype.ch'

User Function ML_COMVEND()
	Private oReport
	Private cPerg   := "ML_COMVEND"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// --------------------------------------------------------------------------
// Imprime relatório
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("ML_COMVEND","Demonstrativo de indenização sobre comissões",cPerg,{|oReport| PrintReport(oReport)},"Demonstrativo de indenização sobre comissões")
	
	//oReport:ShowParamPage() // imprime parametros
	oReport:SetTotalInLine(.F.)
	//oReport:SetLandScape(.T.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
    TRCell():New(oSection1,"COLUNA0", 	"" ,"Vendedor"		    ,	    					,30,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
    TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		    ,	    					,10,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Dt.Pagamento"      ,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Valor Comissão"    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Comissão corrigida", "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"1/2 Avos"		    , "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
    
    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA0"),"Total do vendedor")
    TRFunction():New(oSection1:Cell("COLUNA3")	,,"SUM"	,oBreak1,"Total comissão "          , "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	,oBreak1,"Total comissão corrigida ", "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Valor 1/2 Avos "          , "@E 99,999,999.99", NIL, .F., .T.)

Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

    _oSQL:= ClsSQL ():New ()
    _oSQL:_sQuery := ""

    _oSQL:_sQuery += " WITH C
    _oSQL:_sQuery += " AS "
    _oSQL:_sQuery += " (SELECT "
    _oSQL:_sQuery += " 		SE3.E3_VEND AS COD_VEND "
    _oSQL:_sQuery += " 	   ,SA3.A3_NOME AS COD_NOME "
    _oSQL:_sQuery += " 	   ,SE3.E3_FILIAL AS FILIAL "
    _oSQL:_sQuery += " 	   ,SE3.E3_EMISSAO AS EMISSAO "
    _oSQL:_sQuery += " 	   ,CASE "
    _oSQL:_sQuery += " 			WHEN SE3.E3_EMISSAO < '20220101' THEN SA3.A3_INDENIZ "
    _oSQL:_sQuery += " 			ELSE SA3.A3_INDEBKP "
    _oSQL:_sQuery += " 		END AS INDENIZACAO "
    _oSQL:_sQuery += " 	   ,SUM(SE3.E3_COMIS) AS COMISSAO "
    _oSQL:_sQuery += " 	   ,ROUND(SUM(SE3.E3_COMIS) / 12, 2) AS AVOS_1_2 "
    _oSQL:_sQuery += " 	FROM " + RetSqlName("SE3") + " AS SE3"
    _oSQL:_sQuery += " 	INNER JOIN " + RetSqlName("SA3") + " AS SA3"
    _oSQL:_sQuery += " 		ON (SA3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 		AND SA3.A3_COD = SE3.E3_VEND) "
    _oSQL:_sQuery += " 	WHERE SE3.D_E_L_E_T_ = '' "
    _oSQL:_sQuery += " 	AND SE3.E3_VEND = '" + mv_par01 + "' "
    _oSQL:_sQuery += " 	AND SE3.E3_DATA <> '' "
    _oSQL:_sQuery += " 	GROUP BY SE3.E3_FILIAL "
    _oSQL:_sQuery += " 			,SE3.E3_VEND "
    _oSQL:_sQuery += " 			,SA3.A3_NOME "
    _oSQL:_sQuery += " 			,SE3.E3_EMISSAO "
    _oSQL:_sQuery += " 			,SA3.A3_INDENIZ "
    _oSQL:_sQuery += " 			,SA3.A3_INDEBKP) "
    _oSQL:_sQuery += " SELECT "
    _oSQL:_sQuery += " 	* "
    _oSQL:_sQuery += " FROM C "
    If (mv_par03 == 1)
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'S' "
    else
        _oSQL:_sQuery += " WHERE INDENIZACAO = 'N' "
    EndIf
    _oSQL:_sQuery += " ORDER BY FILIAL, COD_VEND, DATA DESC"
    _aDados := aclone (_oSQL:Qry2Array ())

	For _x:=1 to Len(_aDados)
        If _x == 1 // primeira linha
            _sVendedor := alltrim(_aDados[_x, 1]) + " - " + _aDados[_x, 2]

            oReport:PrintText("VENDEDOR:" +  _sVendedor,, 100)
            oReport:SkipLine(1)
        EndIf

		_nComissao  := _aDados[_x, 6]
		_nComisPaga := _aDados[_x, 6]
		_n12Avos    := _nComisPaga/12

        If mv_par02 == 1
			_sDtInicial  = dtos(stod(_aDados[_x, 4]) - 30) 

        	DbSelectArea('ZAI')
			DbSetOrder(1)
            DbSeek(xFilial('ZAI') + _sDtInicial,.T.)
            
			Do While !eof()
                _nComissao  := _aDados[_x, 6]
                _nIgpm      := ZAI->ZAI_IGPM
                _nComisPaga := ROUND(_nComissao + (_nComissao * _nIgpm/100) ,4)
                DbSkip()
            EndDo
            _n12Avos := _nComisPaga/12
        EndIf
        
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 3]       }) // filial
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| stod(_aDados[_x, 4]) }) // dt.pagto
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _nComissao           }) // vlr.comissao
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _nComisPaga          }) // vlr.comissao corrigida
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _n12Avos             }) // vlr.1/2 avos
		
		oSection1:PrintLine()
	Next

	// oReport:ThinLine()
	// oReport:SkipLine(1)
	// _nLinha:= _PulaFolha(_nLinha)
	// oReport:PrintText("TOTAL CREDITO EM CONTA:" ,, 100)
	// _nLinha:= _PulaFolha(_nLinha)
	// oReport:PrintText("Valor da Parcela:" ,, 100)
	// oReport:PrintText(PADL('R$' + Transform(_nTotVenda, "@E 999,999,999.99"),20,' '),, 900)
	// oReport:PrintText("Valor da Taxa:" ,, 100)
	// oReport:PrintText(PADL('R$' + Transform(_nTotTax, "@E 999,999,999.99"),20,' '),, 900)
	// oReport:SkipLine(1)

	oSection1:Finish()
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Representante          ", "C", 6,  0,  "", "SA3", {}                        ,  ""})
	aadd (_aRegsPerg, {02, "Lista valor corrigido ?", "N", 1,  0,  "",    "", {"Sim", "Não"}			,  ""})
    aadd (_aRegsPerg, {03, "Tipo comissão          ", "N", 1,  0,  "",    "", {"Provisionado", "Pago"}	, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return



// //  Programa...: ML_COMVEND
// //  Autor......: Catia Cardoso
// //  Data.......: 13/10/2016
// //  Descricao..: Consulta Valor de Comissao por Vendedor 
// // 
// //  Historico de alterações
// //  
// //  15/08/2018 - Catia - Criada opcao de listar com ou sem correção pelo IGPM  
// //

// #include "rwmake.ch"
// #include "VA_INCLU.prw"

// User function ML_COMVEND()

// 	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
//     delete file (_sArqLog)

//     cString := "SE3"
//     cDesc1  := "Relatório de Comissões"
//     cDesc2  := ""
//     cDesc3  := ""
//     tamanho := "G"
//     aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
//     aLinha  := {}
//     nLastKey:= 0
//     cPerg   := "ML_COMVEND"
//     wnrel   := "ML_COMVEND"
//     nTipo   := 0
	
// 	_ValidPerg()
	
//     if Pergunte(cPerg,.T.) 
	
// 		titulo  := "Relatório demonstrativo de indenização sobre comissoes"
    
//     	wnrel:=SetPrint(cString,wnrel,cPerg,titulo ,cDesc1,cDesc2,cDesc3,.F.,"",,tamanho)
//     	If nLastKey == 27
//        		Return
//     	Endif
    
//     	SetDefault(aReturn,cString)
//     	If nLastKey == 27
//        		Return
//     	Endif
    	
// 		RptStatus({|| RptDetail()})
// 	endif
	
// return

// Static Function RptDetail()

//     SetRegua(LastRec())
//     nTipo := IIF(aReturn[4]==1,15,18)
//     li    := 80
//     m_pag := 1
    
//     if mv_par03 == 1 
//     	cabec1:=" VENDEDOR                                                FILIAL       DT PAGAMENTO      VALOR COMISSAO           COMISSAO CORRIGIDA              1/2 AVOS"
// 	else
// 		cabec1:=" VENDEDOR                                                FILIAL       DT PAGAMENTO      VALOR COMISSAO                  1/2 AVOS"
// 	endif	    	
//     cabec2:=""

// 	_sQuery := ""
// 	_sQuery += " SELECT SE3.E3_VEND              AS COD_VEND"
//    	_sQuery += "      , SA3.A3_NOME              AS COD_NOME"
//    	_sQuery += "      , SE3.E3_FILIAL            AS FILIAL"
//    	_sQuery += "      , SE3.E3_DATA			     AS DATA"
//    	_sQuery += "      , sum(SE3.E3_COMIS)        AS COMISPAGA"
// 	_sQuery += "   FROM SE3010 AS SE3"
// 	_sQuery += "		INNER JOIN SA3010 AS SA3"
// 	_sQuery += "			ON (SA3.D_E_L_E_T_ = ''"
// 	_sQuery += "				AND SA3.A3_COD = SE3.E3_VEND)"
// 	_sQuery += "  WHERE SE3.D_E_L_E_T_ = ''"
// 	_sQuery += "	AND SE3.E3_FILIAL  = '" + xfilial ("SE3") + "'"
// 	_sQuery += "	AND SE3.E3_VEND   BETWEEN '" + mv_par01 + "' and '" + mv_par02 + "'"
// 	_sQuery += "	AND SE3.E3_DATA  != ''"
// 	_sQuery += " GROUP BY SE3.E3_FILIAL, SE3.E3_VEND, SA3.A3_NOME, SE3.E3_DATA"
// 	_sQuery += " ORDER BY SE3.E3_FILIAL, SE3.E3_VEND, SE3.E3_DATA"
	
// 	//u_showmemo(_sQuery)
	
//     _sAliasQ = GetNextAlias ()
//     DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
//     count to _nRecCount
//     procregua (_nRecCount)
    
//     _aTotVend = {0,0,0}
//     _wcol=115
//     if mv_par03 == 1
// 		_wcol=140    	
// 	endif    
//     (_sAliasQ) -> (DBGoTop ())
//      Do While ! (_sAliasQ) -> (Eof ())
//      	   // imprime totais do vendedor
//             If li>65
//                 cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//             	@li, 02 PSAY ALLTRIM((_sAliasQ) -> COD_VEND)
//             	@li, 07 PSAY (_sAliasQ) -> COD_NOME
//         	endif
            
//             If li>65
//                	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//            	Endif
           
//            	@li, 61 PSAY (_sAliasQ) -> FILIAL 
//            	@li, 72 PSAY stod((_sAliasQ) -> DATA)  
//            	@li, 90 PSAY (_sAliasQ) -> COMISPAGA    Picture "@E 9,999,999.99"
//            	// calcula valor corrigido ate o mes anterior a data de emissao do relatorio
//            	_wdataini  = dtos(stod((_sAliasQ) -> DATA) - 30) 
//            	_wvalorcor = (_sAliasQ) -> COMISPAGA
//            	if mv_par03 == 1
// 	           	DbSelectArea('ZAI')
// 				DbSeek(xFilial('ZAI') + _wdataini,.T.)
// 				Do While !eof()
// 					_wigpm = ZAI->ZAI_IGPM
// 					_wvalorcor = ROUND(_wvalorcor + (_wvalorcor * _wigpm/100) ,4)
// 					DbSkip()
// 				EndDo
// 				@li, 115 PSAY _wvalorcor Picture "@E 9,999,999,999.99"
// 			endif
// 			_w12avos = _wvalorcor/12
// 			// imprime valor da comissao corrigida e os 1/12 avos
// 			@li, _wcol PSAY _w12avos   Picture "@E 99,999,999.99"
// 			li ++
//             // acumula total
//           	_aTotVend [1]  += (_sAliasQ) -> COMISPAGA
//           	_aTotVend [2]  += _wvalorcor
//           	_aTotVend [3]  += _w12avos
//           	(_sAliasQ) -> (dbskip())
//      enddo
       	 
//      // imprime totais do vendedor
//      If li>65
//         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//      Endif        
//      li++
//      @ li, 02 PSAY "TOTAL DO VENDEDOR --> "
//      @ li, 90 PSAY _aTotVend [1]  Picture "@E 9,999,999.99"
//      if mv_par03 == 1
// 	     @ li,115 PSAY _aTotVend [2]  Picture "@E 9,999,999,999.99"
// 	     @ li,140 PSAY _aTotVend [3]  Picture "@E 99,999,999.99"
// 	 else
// 	 	@ li,115 PSAY _aTotVend [3]  Picture "@E 99,999,999.99"
// 	 endif			     
//      li++
     
//      Set Device To Screen

//      If aReturn[5]==1
//            Set Printer TO
//            dbcommitAll()
//            ourspool(wnrel)
//      Endif

//      MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

// return

// // --------------------------------------------------------------------------
// // Cria Perguntas no SX1
// Static Function _ValidPerg ()
//     local _aRegsPerg := {}
//     aadd (_aRegsPerg, {01, "Representante de      ?", "C", 6, 0,  "", "SA3", {},  ""})
// 	aadd (_aRegsPerg, {02, "Representante até     ?", "C", 6, 0,  "", "SA3", {},  ""})
// 	aadd (_aRegsPerg, {03, "Lista valor corrigido ?", "N", 1,  0,  "", "", {"Sim", "Não"}			, ""})
	
//     U_ValPerg (cPerg, _aRegsPerg)
// Return
