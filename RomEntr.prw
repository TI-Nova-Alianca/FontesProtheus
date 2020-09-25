// Programa:   RomEntr
// Autor:      Robert Koch
// Data:       12/08/2014
// Descricao:  Imprime romaneio de entrada de mercadorias.
//
// Historico de alteracoes:
//
// 01/12/2016 - Catia   - Incluido solicitante
// 18/08/2017 - Catia   - Alterada a mascara do campo quantidade para que imprima com 7 decimais
// 07/01/2019 - Andre   - Ajustado para imprimir romaneio e levar paramêtros contidos na nota.
// 09/01/2019 - Andre   - Adicionado colune com Lote Multiplo e Almoxarifado.
// 09/09/2019 - Claudia - Incluida pergunta para impressão do relatório de romaneio de entrada.
// 30/09/2019 - Cláudia - Alterado relatório para modelo TReport, aumentando a letra e realizando a impressão de 3 vias 
//                        quando algum produto do tipo MM ou CL
// 17/10/2019 - Cláudia - Conforme GLPI 6843, retirada a impressão de 3 vias 
// 19/12/2019 - Claudia - Ajuste de layout de campos pois estava cortando em alguns casos o almoxarifado.
// 06/01/2020 - Claudia - Devido aos problemas de campos cortados, foi alterada a letra e layout de impressão do romaneio.
// 08/01/2020 - Claudia - Ajuste das letras e configurações de layout devido a problemas de cortes nas colunas.
// 26/02/2020 - Cláudia - Incluida coluna de lote interno
// -------------------------------------------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function ROMENTR(_sFornece, _sLoja, _sNF, _sSerie)
	Private oReport
	Private cPerg   := "ROMENTR"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	if _sFornece != NIL
		U_GravaSX1 (cPerg, "01", _sFornece)
		U_GravaSX1 (cPerg, "02", _sLoja)
		U_GravaSX1 (cPerg, "03", _sNF)
		U_GravaSX1 (cPerg, "04", _sSerie)
		
		mv_par01 = _sFornece
		mv_par02 = _sLoja
		mv_par03 = _sNF
		mv_par04 = _sSerie
		
	endif
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return

Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil
	Local oFunction
	
	oReport := TReport():New("ROMENTR","Romaneio de Entrada",cPerg,{|oReport| PrintReport(oReport)},"Romaneio de Entrada")
	
	oReport:SetPortrait()
	//oReport:SetLandscape()
	//oReport:SetTotalInLine(.F.)
	oReport:SetLineHeight(50)
	//oReport:SetColSpace(1)
	//oReport:SetLeftMargin(0)
	oReport:cFontBody := "Arial"
	//oReport:nFontBody := 10
	//oReport:lParamPage := .F.

	//SESSÃO 1 CUPONS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 

	TRCell():New(oSection1,"COLUNA1", 	"" ,"Produto"	 ,	    				,18,/*lPixel*/,{||  },"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"	 ,	    				,35,/*lPixel*/,{||	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Quant."     ,"@E 999,999,999.99"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"UM"		 ,    					, 4,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Solicitante",       				,22,/*lPixel*/,{|| 	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Pedido" 	 ,						,22,/*lPixel*/,{|| 	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Lote M."	 ,						,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Almox"		 ,						 ,6,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Lote Int."	 ,						,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)

Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""		
	Local nVia      := 0
	Local nQtdProd  := 0
    
	sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	If ! sf1 -> (dbseek (xfilial ("SF1") + mv_par03 + mv_par04 + mv_par01 + mv_par02, .F.))
		u_help ("NF não encontrada!")
	Else

		cQuery := ""
		cQuery += " SELECT D1_COD, D1_DESCRI, D1_QUANT, D1_UM, D1_VAVOLQT, D1_VAVOLES, D1_PEDIDO, D1_ITEMPC, SC1.C1_SOLICIT AS SOLICITANTE, SA5.A5_LOTEMUL AS LOTE_MULTIPLO, D1_LOCAL, D1_TP, D1_LOTECTL "
		cQuery += " FROM " + RetSQLName ("SD1") + " SD1"
		cQuery += " LEFT JOIN SC1010 AS SC1"
		cQuery += " 		ON (SC1.D_E_L_E_T_ = ''"
		cQuery += " 		    AND SD1.D1_PEDIDO != ''"
		cQuery += " 			AND SC1.C1_FILIAL   = SD1.D1_FILIAL"
		cQuery += " 			AND SC1.C1_PEDIDO   = SD1.D1_PEDIDO"
		cQuery += " 			AND SC1.C1_ITEMPED  = SD1.D1_ITEMPC)"
		cQuery += " LEFT JOIN SA5010 AS SA5 "
		cQuery += "		ON ( SA5.A5_FORNECE = SD1.D1_FORNECE"
		cQuery += "			 AND SA5.A5_PRODUTO = SD1.D1_COD"
        cQuery += "			 AND SA5.A5_LOJA = SD1.D1_LOJA"
        cQuery += "			 AND SA5.D_E_L_E_T_ = '' )"
		cQuery += " WHERE SD1.D_E_L_E_T_ != '*'"
		cQuery += "   AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
		cQuery += "   AND SD1.D1_FORNECE  = '" + mv_par01 + "'"
		cQuery += "   AND SD1.D1_LOJA     = '" + mv_par02 + "'"
		cQuery += "   AND SD1.D1_DOC      = '" + mv_par03 + "'"
		cQuery += "   AND SD1.D1_SERIE    = '" + mv_par04 + "'"
		cQuery += " ORDER BY D1_COD"
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		
//		// Verifica se tem produto MM ou CL para imprimir 3 vias
//		TRA->(DbGotop())
//		While TRA->(!Eof())
//			nQtdProd += 1 
//			If alltrim(TRA-> D1_TP)=='MM' .or. alltrim(TRA-> D1_TP)=='CL'
//				nVia += 1
//			EndIf
//			DBSelectArea("TRA")
//			dbskip()
//		enddo
		//
//		If nVia > 0
//			nRepete := 3
//		Else
//			nRepete := 2
//		EndIf
		
//		For x:=1 to nRepete
			// Imprime linha NF
			_sLinImp := 'Nota fiscal/serie: ' + sf1 -> f1_doc + '/' + sf1 -> f1_serie + '    Tipo: ' + sf1 -> f1_tipo + '  '
			If sf1 -> f1_tipo $ 'BD'
				_sLinImp += 'Cliente/loja:    ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA1", 1, xfilial ("SA1") + mv_par01 + mv_par02, "A1_NOME")
			Else
				_sLinImp += 'Fornecedor/loja: ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA2", 1, xfilial ("SA2") + mv_par01 + mv_par02, "A2_NOME")
			EndIf
					
			// Imprime 1º via
			oReport:PrintText(" ",,100)
			oReport:PrintText(_sLinImp,,100)
			oReport:PrintText(" ",,100)
			
			oSection1:Init()
			oSection1:SetHeaderSection(.T.)
			
			TRA->(DbGotop())
			
			While TRA->(!Eof())	
				oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->D1_COD  	 					})
				oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->D1_DESCRI   					})
				oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->D1_QUANT 	  					})
				oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->D1_UM	  						})
				oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->SOLICITANTE 					})
				oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->D1_PEDIDO +'/'+ TRA->D1_ITEMPC})
				oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->LOTE_MULTIPLO   				})
				oSection1:Cell("COLUNA8")	:SetBlock   ({|| TRA->D1_LOCAL    					})
				oSection1:Cell("COLUNA9")	:SetBlock   ({|| TRA->D1_LOTECTL    				})
				oSection1:PrintLine()
				
				DBSelectArea("TRA")
				dbskip()
			enddo
			oReport:PrintText(" ",,100)
			
//			If nRepete == 2 .and. nQtdProd <= 6
//				Do Case 
//					Case nQtdProd = 6
//						nX := 8
//					Case nQtdProd = 5
//						nX := 10
//					Case nQtdProd = 4
//						nX := 12
//					Case nQtdProd = 3
//						nX := 14
//					Case nQtdProd = 2
//						nX := 16
//					Case nQtdProd = 1 
//						nX := 18
//				EndCase
//				
//				For y:=1 to nX
//					oReport:PrintText(" ")
//				Next
//			EndIf
//			
//			Do Case
//				Case x == 1
//					oReport:PrintText("1º Via - Recebimento Fiscal      					Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//				Case x == 2
//					oReport:PrintText("2º Via - Almoxarifado     							Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//				Case x == 3
//					oReport:PrintText("3º Via - Manutenção      							Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//			EndCase
//			
//			oReport:PrintText("----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
//		Next
		oSection1:Finish()
		TRA->(DbCloseArea())
    EndIf
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Fornecedor                    ", "C", 6,  0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {02, "Loja                          ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "NF                            ", "C", 9,  0,  "",   "SF1", {},    ""})
	aadd (_aRegsPerg, {04, "Serie                         ", "C", 3,  0,  "",   "   ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {})
return




//user function RomEntr (_sFornece, _sLoja, _sNF, _sSerie)
//
//	// Variaveis obrigatorias dos programas de relatorio
//	cDesc1   := "Romaneio de entrada"
//	cDesc2   := ""
//	cDesc3   := ""
//	cString  := "SF1"
//	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
//	nLastKey := 0
//	Titulo   := cDesc1
//	cPerg    := "ROMENTR"
//	nomeprog := "ROMENTR"
//	wnrel    := "ROMENTR"
//	tamanho  := "M"
//	limite   := 132
//	nTipo    := 15
//	m_pag    := 1
//	li       := 80
//	cCabec1  := "Produto     Descricao                                          Quantidade UM   Solicitante        Ped.compra      Lote M.     Almox"
//	cCabec2  := ""
//	aOrd     := {}
//		
//	_ValidPerg ()
//	pergunte (cPerg, .F.)
//
//	if _sFornece != NIL
//		U_GravaSX1 (cPerg, "01", _sFornece)
//		U_GravaSX1 (cPerg, "02", _sLoja)
//		U_GravaSX1 (cPerg, "03", _sNF)
//		U_GravaSX1 (cPerg, "04", _sSerie)
//		
//		mv_par01 = _sFornece
//		mv_par02 = _sLoja
//		mv_par03 = _sNF
//		mv_par04 = _sSerie
//		
//	endif
//	
//	wnrel := SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
//	
//	
//	If nLastKey == 27
//		Return
//	Endif
//	delete file (__reldir + wnrel + ".##r")
//	SetDefault (aReturn, cString)
//	If nLastKey == 27
//		Return
//	Endif
//		
//	processa ({|| _Imprime ()})
//	MS_FLUSH ()
//	DbCommitAll ()
//
//	if aReturn [5] == 1
//		ourspool (wnrel)
//	endif
//return
////
//// --------------------------------------------------------------------------
//static function _Imprime ()
//	local _oSQL      := NIL
//	local _sAliasQ   := ""
//	local _sLinImp   := ""
//	local _aDescri   := {}
//	local _nDescri   := 0
//	private _nMaxLin := 68
//	oFont1:= TFont():New( "Arial",0,-21,,.T.,0,,700,.T.,.F.,,,,,, )
//	
//	li = _nMaxLin + 1
//	
//	procregua (3)
//
//	// Nao aceita filtro por que precisaria inserir na query.
//	If !Empty(aReturn[7])
//		msgalert ("Este relatorio nao aceita filtro do usuario.")
//		return
//	EndIf	
//
//	procregua (10)
//	incproc ("Lendo dados...")
//	sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
//	if ! sf1 -> (dbseek (xfilial ("SF1") + mv_par03 + mv_par04 + mv_par01 + mv_par02, .F.))
//		u_help ("NF nao encontrada!")
//	else
//
//		_oSQL := ClsSQL ():New ()
//		_oSQL:_sQuery := ""
////		_oSQL:_sQuery += " SELECT D1_COD, D1_DESCRI, D1_QUANT, D1_UM, D1_VAVOLQT, D1_VAVOLES, D1_PEDIDO, D1_ITEMPC, SC1.C1_SOLICIT AS SOLICITANTE"
//		_oSQL:_sQuery += " SELECT D1_COD, D1_DESCRI, D1_QUANT, D1_UM, D1_VAVOLQT, D1_VAVOLES, D1_PEDIDO, D1_ITEMPC, SC1.C1_SOLICIT AS SOLICITANTE, SA5.A5_LOTEMUL AS LOTE_MULTIPLO, D1_LOCAL"
//		_oSQL:_sQuery += " FROM " + RetSQLName ("SD1") + " SD1"
//		_oSQL:_sQuery += " LEFT JOIN SC1010 AS SC1"
//		_oSQL:_sQuery += " 		ON (SC1.D_E_L_E_T_ = ''"
//		_oSQL:_sQuery += " 		    AND SD1.D1_PEDIDO != ''"
//		_oSQL:_sQuery += " 			AND SC1.C1_FILIAL   = SD1.D1_FILIAL"
//		_oSQL:_sQuery += " 			AND SC1.C1_PEDIDO   = SD1.D1_PEDIDO"
//		_oSQL:_sQuery += " 			AND SC1.C1_ITEMPED  = SD1.D1_ITEMPC)"
//		_oSQL:_sQuery += " LEFT JOIN SA5010 AS SA5 "
//		_oSQL:_sQuery += "		ON ( SA5.A5_FORNECE = SD1.D1_FORNECE"
//		_oSQL:_sQuery += "			 AND SA5.A5_PRODUTO = SD1.D1_COD"
//        _oSQL:_sQuery += "			 AND SA5.A5_LOJA = SD1.D1_LOJA"
//        _oSQL:_sQuery += "			 AND SA5.D_E_L_E_T_ = '' )"
//		_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ != '*'"
//		_oSQL:_sQuery += "   AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
//		_oSQL:_sQuery += "   AND SD1.D1_FORNECE  = '" + mv_par01 + "'"
//		_oSQL:_sQuery += "   AND SD1.D1_LOJA     = '" + mv_par02 + "'"
//		_oSQL:_sQuery += "   AND SD1.D1_DOC      = '" + mv_par03 + "'"
//		_oSQL:_sQuery += "   AND SD1.D1_SERIE    = '" + mv_par04 + "'"
//		_oSQL:_sQuery += " ORDER BY D1_COD"
//		_sAliasQ = _oSQL:Qry2Trb ()
//				
//		if li > _nMaxLin
//			cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
//		endif
//		_sLimImp := ""
//		_sLinImp += 'Nota fiscal/serie: ' + sf1 -> f1_doc + '/' + sf1 -> f1_serie + '    Tipo: ' + sf1 -> f1_tipo + '  '
//		if sf1 -> f1_tipo $ 'BD'
//			_sLinImp += 'Cliente/loja:    ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA1", 1, xfilial ("SA1") + mv_par01 + mv_par02, "A1_NOME")
//		else
//			_sLinImp += 'Fornecedor/loja: ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA2", 1, xfilial ("SA2") + mv_par01 + mv_par02, "A2_NOME")
//		endif
//		@ li, 0 psay _sLinImp
//		li += 2
//		
//		(_sAliasQ) -> (dbgotop ())
//		do while ! (_sAliasQ) -> (eof ())
//			incproc ()
//	
//			// Quebra a descricao para imprimir em mais de uma linha.
//			_aDescri := aclone (U_QuebraTXT (alltrim ((_sAliasQ) -> d1_descri), 48))
//		
//			for _nDescri = 1 to len (_aDescri)
//				_sLinImp := ""
//				if _nDescri == 1
//					_sLinImp += (_sAliasQ) -> d1_cod
//				//else
//				//	_sLinImp += space (16)
//				endif
//				//_sLinImp += U_TamFixo (_aDescri [_nDescri], 48, ' ') + ' '
//				@li,  12 PSAY U_TamFixo (_aDescri [_nDescri], 48, ' ')
//				if _nDescri == 1
//					//_sLinImp += transform ((_sAliasQ) -> d1_quant, "@E 9,999,999.999999999") + ' '
//					//_sLinImp += (_sAliasQ) -> d1_um + '  '
//					//_sLinImp += U_TamFixo ( (_sAliasQ) -> SOLICITANTE, 20, ' ')
//					//_sLinImp += (_sAliasQ) -> d1_pedido + '/' + (_sAliasQ) -> d1_itempc + ' '
//					//_sLinImp += transform ((_sAliasQ) -> LOTE_MULTIPLO, "@E 999,999.99") + ' '
//					//_sLinImp += (_sAliasQ) -> cc_desc + '  '
//					@li,  60 PSAY transform ((_sAliasQ) -> d1_quant, "@E 9,999,999.99")
//					@li,  74 PSAY (_sAliasQ) -> d1_um
//					@li,  80 PSAY U_TamFixo ((_sAliasQ) -> SOLICITANTE, 15, ' ')
//					@li,  98 PSAY (_sAliasQ) -> d1_pedido + '/' + (_sAliasQ) -> d1_itempc
//					@li,  110 PSAY transform ((_sAliasQ) -> LOTE_MULTIPLO, "@E 999,999.99")
//					@li,  128 PSAY (_sAliasQ) -> d1_local
//				endif
//				if li > _nMaxLin
//					cabec(titulo,cCabec1,cCabec2,nomeprog,tamanho,nTipo)
//				endif
//				@ li, 0 psay _sLinImp
//				li ++
//			next
//			(_sAliasQ) -> (dbskip ())
//		enddo
//		@ li, 0 psay __PrtThinLine ()
//		li += 2
//		
//		(_sAliasQ) -> (dbclosearea ())
//	endif
//return
//
//
//
//// --------------------------------------------------------------------------
//// Cria Perguntas no SX1
//Static Function _ValidPerg ()
//	local _aRegsPerg := {}
//	local _aDefaults := {}
//	
//	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
//	aadd (_aRegsPerg, {01, "Fornecedor                    ", "C", 6,  0,  "",   "SA2", {},    ""})
//	aadd (_aRegsPerg, {02, "Loja                          ", "C", 2,  0,  "",   "   ", {},    ""})
//	aadd (_aRegsPerg, {03, "NF                            ", "C", 9,  0,  "",   "SF1", {},    ""})
//	aadd (_aRegsPerg, {04, "Serie                         ", "C", 3,  0,  "",   "   ", {},    ""})
//
//	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
//return
