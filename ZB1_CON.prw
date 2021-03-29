// Programa...: ZB1_CON
// Autor......: Cláudia Lionço
// Data.......: 27/08/2020
// Descricao..: Conciliação/baixa de títulos por registros de pgto Cielo - EDI 13 Cielo
//				Para cartões CIELO - LOJAS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Conciliação/baixa de títulos por registros de pgto Cielo - cartões CIELO - LOJAS
// #PalavasChave      #extrato #cielo #recebimento #cartoes #baixa_de_titulos
// #TabelasPrincipais #ZB1 #SE1
// #Modulos   		  #FIN 
//
// parametro _sConciliar: 
// '1' = CIELO LOJAS 
// '2' = CIELO LINK
//
// Historico de alteracoes:
// 03/11/2020 - Claudia - Incluida a gravação do SXK
// 19/11/2020 - Claudia - Retirada a data de emissão de vendas link
// 04/12/2020 - Claudia - Alteração de ajustes para arredondamento. GLPI: 8970
// 07/12/2020 - Claudia - Inclusao do calculo de taxa para registros que a cielo adiciona em apenas um cabeçalho.
// 08/03/2021 - Cláudia - Alterado o motivo da baixa para links. GLPI:9574
// 29/03/2021 - Claudia - Incluida filial 13. GLPI: 9710
//
// -----------------------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB1_CON(_sConciliar)
	Local _oSQL  	:= ClsSQL ():New ()
	Local _aZB1  	:= {}
	Local _aTitulo  := {}
	Local _lcont    := .T.
	Local i		 	:= 0
	Local x      	:= 0
	Local y         := 0
	Private _aRelImp  := {}
	Private _aRelErr  := {}
	
	u_logIni ("Inicio Conciliação Cielo LOJAS" + DTOS(date()) )

	If cFilAnt == '01' .and. _sConciliar == '1' // conciliação das lojas
		u_help("Empresa matriz não pode efetuar baixa pelo menu Conciliar Cielo Loja")
		_lcont := .F.
	EndIf
	If (cFilAnt == '10' .or. cFilAnt == '13') .and. _sConciliar == '2' // conciliação link
		u_help("Baixas pelo Conciliar Cielo Link efetuadas apenas na empresa matriz")
		_lcont := .F.
	EndIf
	If _lcont == .T.
		cPerg   := "ZB1_CON"
		_ValidPerg ()
		
		If ! pergunte (cPerg, .T.)
			return
		Endif
		
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 	   ZB1_FILIAL" // 01
		_oSQL:_sQuery += "    ,ZB1_VLRBRT" // 02
		_oSQL:_sQuery += "    ,ZB1_VLRTAX" // 03
		_oSQL:_sQuery += "    ,ZB1_PERTAX" // 04
		_oSQL:_sQuery += "    ,ZB1_VLRTAR" // 05
		_oSQL:_sQuery += "    ,ZB1_VLRREJ" // 06
		_oSQL:_sQuery += "    ,ZB1_VLRLIQ" // 07
		_oSQL:_sQuery += "    ,ZB1_VLRPAR" // 08
		_oSQL:_sQuery += "    ,ZB1_PARNUM" // 09
		_oSQL:_sQuery += "    ,ZB1_PARTOT" // 10
		_oSQL:_sQuery += "    ,ZB1_BANCO"  // 11
		_oSQL:_sQuery += "    ,ZB1_AGENCI" // 12
		_oSQL:_sQuery += "    ,ZB1_CONTA"  // 13
		_oSQL:_sQuery += "    ,ZB1_ADM"	   // 14
		_oSQL:_sQuery += "    ,ZB1_ADMDES" // 15
		_oSQL:_sQuery += "    ,ZB1_DTAVEN" // 16
		_oSQL:_sQuery += "    ,ZB1_AUTCOD" // 17 
		_oSQL:_sQuery += "    ,ZB1_NSUCOD" // 18
		_oSQL:_sQuery += "    ,ZB1_NUMNFE" // 19
		_oSQL:_sQuery += "    ,ZB1_STAIMP" // 20
		_oSQL:_sQuery += "    ,ZB1_DTAAPR" // 21 - DATA DE EMISSAO
		_oSQL:_sQuery += "    ,ZB1_DTAPRO" // 22 - DATA DE PROCESSAMENTO
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZB1") 
		_oSQL:_sQuery += " WHERE ZB1_FILIAL = '" + cFilAnt + "'"
		_oSQL:_sQuery += " AND D_E_L_E_T_ = ''" 
		_oSQL:_sQuery += " AND ZB1_STAPGT = '01'" 		 //-- PAGO
		_oSQL:_sQuery += " AND ZB1_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
		_oSQL:_sQuery += " AND ZB1_ARQUIV LIKE'%CIELO%'" //-- APENAS ARQUIVOS DA CIELO
		If !empty(mv_par01)
			_oSQL:_sQuery += " AND ZB1_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
		EndIf
		If !empty(mv_par02) 
			_oSQL:_sQuery += " AND ZB1_AUTCOD = '" + mv_par02 + "' " // FILTRA PELO CÓDIGO DE AUTORIZAÇÃO
		EndIf
		_oSQL:Log ()
		
		_aZB1 := aclone (_oSQL:Qry2Array ())
		
		_cMens := "Existem " + alltrim(str(len(_aZB1))) + " registros para realizar a baixa de títulos. Deseja continuar?"
		If MsgYesNo(_cMens,"Baixa de titulos")
			_nImpReg := 0
			_nTotReg := Len(_aZB1)

			For i:=1 to Len(_aZB1)
				
				// Verificações de parcela Cielo X Protheus
				_sParc := ''
				If alltrim(_aZB1[i, 9]) <> '00' .or. alltrim(_aZB1[i, 9]) <> '' 
					_sParc := BuscaParcela(_aZB1[i, 9])
				EndIf

				// Busca dados do título para fazer a baixa
				_oSQL:= ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT "
				_oSQL:_sQuery += " 	   SE1.E1_FILIAL"	// 01
				_oSQL:_sQuery += "    ,SE1.E1_PREFIXO"	// 02
				_oSQL:_sQuery += "    ,SE1.E1_NUM"		// 03
				_oSQL:_sQuery += "    ,SE1.E1_PARCELA"	// 04
				_oSQL:_sQuery += "    ,SE1.E1_VALOR"	// 05
				_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"	// 06
				_oSQL:_sQuery += "    ,SE1.E1_LOJA"		// 07
				_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"	// 08
				_oSQL:_sQuery += "    ,SE1.E1_TIPO"		// 09
				_oSQL:_sQuery += "    ,SE1.E1_BAIXA"	// 10
				_oSQL:_sQuery += "    ,SE1.E1_SALDO"	// 11
				_oSQL:_sQuery += "    ,SE1.E1_STATUS "	// 12
				_oSQL:_sQuery += "    ,SE1.E1_ADM "	    // 13
				_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
				_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + _aZB1[i, 1] + "'"
				If _sConciliar == '1'
					_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,17] + "'" // Loja salva cod.aut no campo NSU
					_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aZB1[i,16]) + "'"
				Else
					_oSQL:_sQuery += " AND SE1.E1_CARTAUT = '" + _aZB1[i,17] + "'"
					_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,18] + "'"
				EndIf
				_oSQL:_sQuery += " AND SE1.E1_BAIXA   = ''"
				If alltrim(_sParc) <> ''
					_oSQL:_sQuery += " AND SE1.E1_PARCELA   = '" + _sParc + "'"
				EndIf
				_oSQL:_sQuery += " AND SE1.E1_TIPO IN ('CC','CD')"
				_oSQL:Log ()

				_aTitulo := aclone (_oSQL:Qry2Array ())
				
				If len(_aTitulo) <= 0
					u_log("TÍTULO NÃO ENCONTRADO: Registro NSU+AUT:" + _aZB1[i,18] + _aZB1[i,17])
				Else
					
					For x:=1 to len(_aTitulo)	
						_lContinua  := .T.

						_sDtPro     := DTOS(_aZB1[i,22])	// ZB1_DTAPRO
						_sNSUCod    := _aZB1[i,18]			// ZB1_NSUCOD
						_sAutCod    := _aZB1[i,17]			// ZB1_AUTCOD

						_nVlrTit    := _aTitulo[x,05] 		// E1_VALOR
						_nVlrLiq    := _aZB1[i,07]  		// ZB1_VLRLIQ
						_nVlrPar    := _aZB1[i,08]          // ZB1_VLRPAR
						_nVlrTax    := _nVlrTit - _nVlrLiq  // valor da taxa calculada
						_nTaxCielo  := _aZB1[i,03]  		// ZB1_VLRTAX cielo
					
						If ROUND(_nVlrTax, 2) <> ROUND(_nTaxCielo, 2) // taxa calculada X taxa cielo
							_nDif := _nVlrTax - _nTaxCielo

							If _nDif >= -0.5 .and. _nDif <= 0.5
								_lContinua := .T.
								u_log("DIFERENÇA DE ARREDONDAMENTO TAXA:Registro NSU+AUT:" + _sNSUCod + _sAutCod + " Valor com diferença de arredondameto. Diferença:" + alltrim(str(_nDif)))
							Else
								// Diferença é maior que a permitida
								// Pode ser devido a cielo "juntar" itens
								// dessa forma será calculado valor do titulo Protheus * percentual da taxa
								_nPerTax := (_aZB1[i,4]/100) 
								_nVlrTax := ROUND(_nVlrTit * _nPerTax,2)
								_nVlrLiq := _nVlrPar - _nVlrTax
								_lContinua := .T.
								u_log("DIFERENÇA DE TAXA:Registro NSU+AUT:" + _sNSUCod + _sAutCod + " Valor CALCULADO pelo percentual da taxa.")
							EndIf
						EndIf

						If _lContinua == .T.

							lMsErroAuto := .F.
							If _sConciliar == '2' // link
								_sMotBaixa := 'NORMAL' 
								_sHist     := 'Baixa Link'
							Else
								_sMotBaixa := 'DEBITO CC' 
								_sHist     := 'Baixa Cielo'	
							EndIf

							// executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
							_aAutoSE1 := {}
							aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[x,1]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[x,2]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[x,3]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[x,4]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[x,6] 					, Nil})
							aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[x,7] 					, Nil})
							aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[x,9] 					, Nil})
							AAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  						, Nil})
							AAdd(_aAutoSE1, {"CBANCO"  		, alltrim(_aZB1[i,11])	    		, Nil})  	
							AAdd(_aAutoSE1, {"CAGENCIA"   	, alltrim(_aZB1[i,12])		    	, Nil})  
							AAdd(_aAutoSE1, {"CCONTA"  		, alltrim(_aZB1[i,13])				, Nil})
							AAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase		 					, Nil})
							AAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		 					, Nil})
							AAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    					    , Nil})
							AAdd(_aAutoSE1, {"AUTDESCONT"	, _nVlrTax         					, Nil})
							AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTVALREC"  	, _nVlrLiq							, Nil})
						
							_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

							cPerg = 'FIN070'
							_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
							U_GravaSX1 (cPerg, "01", 2)    // testar mostrando o lcto contabil depois pode passar para nao
							U_GravaSX1 (cPerg, "04", 2)    // esse movimento tem que contabilizar
							U_GravaSXK (cPerg, "01", "2", 'G' )
							U_GravaSXK (cPerg, "04", "2", 'G' )

							MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

							If lMsErroAuto
								u_log(memoread (NomeAutoLog ()))
								u_log("IMPORTAÇÃO NÃO REALIZADA: Registro NSU+AUT:" + _sNSUCod + _sAutCod)
								
								// Salva dados para impressão
								_sErro := ALLTRIM(memoread (NomeAutoLog ()))
								aadd(_aRelErr,{ _aTitulo[x,1],; // filial
												_aTitulo[x,2],; // prefixo
												_aTitulo[x,3],; // número
												_aTitulo[x,4],; // parcela
												_aTitulo[x,6],; // cliente
												_aTitulo[x,7],; // loja
												_nVlrLiq	 ,; // valor recebido
												_nVlrTax     ,; // taxa
												_aZB1[i,17]  ,; // autorização
												_aZB1[i,18]  ,; // NSU
												_sErro       }) // status

							Else
								// Atualiza banco e administradora
								if alltrim(_aTitulo[x,1]) == '01' // matriz - link
									_sAdm := alltrim(_aTitulo[x,13]) 
								else
									_sAdm := alltrim(_aTitulo[x,6]) 
								endif

								_oSQL:= ClsSQL ():New ()
								_oSQL:_sQuery := ""
								_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE5") + " SET E5_BANCO = '"+ alltrim(_aZB1[i,11]) + "', E5_AGENCIA = '"+ alltrim(_aZB1[i,12]) +"',"
								_oSQL:_sQuery += " E5_CONTA = '" + alltrim(_aZB1[i,13]) + "', E5_ADM = '" + _sAdm + "'"
								_oSQL:_sQuery += " WHERE D_E_L_E_T_=''"
								_oSQL:_sQuery += " AND E5_FILIAL  ='" + _aTitulo[x,1] + "'"
								_oSQL:_sQuery += " AND E5_PREFIXO ='" + _aTitulo[x,2] + "'"
								_oSQL:_sQuery += " AND E5_NUMERO  ='" + _aTitulo[x,3] + "'"
								_oSQL:_sQuery += " AND E5_PARCELA ='" + _aTitulo[x,4] + "'"
								_oSQL:_sQuery += " AND E5_CLIFOR  ='" + _aTitulo[x,6] + "'"
								_oSQL:_sQuery += " AND E5_LOJA    ='" + _aTitulo[x,7] + "'"
								_oSQL:_sQuery += " AND E5_TIPO    ='" + _aTitulo[x,9] + "'"
								_oSQL:Log ()
								_oSQL:Exec ()
								
								// Salva dados para impressão
								aadd(_aRelImp,{ _aTitulo[x,1],; // filial
												_aTitulo[x,2],; // prefixo
												_aTitulo[x,3],; // número
												_aTitulo[x,4],; // parcela
												_aTitulo[x,6],; // cliente
												_aTitulo[x,7],; // loja
												_nVlrLiq	 ,; // valor recebido
												_nVlrTax     ,; // taxa
												_aZB1[i,17]  ,; // autorização
												_aZB1[i,18]  ,; // NSU
												'BAIXADO'    }) // status

								dbSelectArea("ZB1")
								dbSetOrder(4) // DTA PROCESSAMENTO + ZB1_NUMNSU + ZB1_CODAUT + ZB1_SINAL
								dbGoTop()

								If dbSeek(_sDtPro + PADR(_sNSUCod ,8,' ') +_sAutCod)
									Reclock("ZB1",.F.)
										ZB1 -> ZB1_STAIMP := 'C'
										ZB1 -> ZB1_DTABAI := date()
									ZB1->(MsUnlock())
								EndIf

								_nImpReg += 1
								u_log("IMPORTAÇÃO FINALIZADA COM SUCESSO: Registro NSU+AUT:" + _sNSUCod + _sAutCod)
							Endif
							
							U_GravaSXK (cPerg, "01", "2", 'D' )
							U_GravaSXK (cPerg, "04", "2", 'D' )

							U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
						
						EndIf
					Next
				Endif		
			Next
			u_help("Processo finalizado! Baixados "+ alltrim(str(_nImpReg)) +" de " + alltrim(str(_nTotReg)) )

			If len(_aRelErr) > 0 .or. len(_aRelImp) > 0
				RelBaixas(_aRelImp, _aRelErr)
			Endif
		Else
			u_help("Processo não realizado!")
			u_log("IMPORTAÇÃO ABORTADA PELO USUÁRIO")
		EndIf
	EndIf
	
	u_logFim ("Fim Conciliação Cielo " + DTOS(date()) )
Return

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
// --------------------------------------------------------------------------
// Relatorio de registros importados
Static Function RelBaixas(_aRelImp, _aRelErr)
	Private oReport
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ---------------------------------------------------------------------------
// Cabeçalho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oSection2:= Nil

	oReport := TReport():New("ZB1_CON","Baixas de títulos Cielo",cPerg,{|oReport| PrintReport(oReport)},"Baixas de títulos Cielo")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Vlr.Recebido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Status"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .T., .F.)
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .T., .F.)

	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Filial"		,	    					, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Título"		,       					,25,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Cliente"		,       					,35,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"Vlr.Recebido"	, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"Vlr.Taxa"		, "@E 999,999,999.99"   	,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"Autoriz."		,							,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"NSU"			,	    					,10,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA8", 	"" ,"Status"		,	    					,20,/*lPixel*/,{||	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection2:Cell("COLUNA4")	,,"SUM"	, , "Total recebido " , "@E 999,999,999.99", NIL, .T., .F.)
	TRFunction():New(oSection2:Cell("COLUNA5")	,,"SUM"	, , "Total taxa "	  , "@E 999,999,999.99", NIL, .T., .F.)
Return(oReport)
//
// -------------------------------------------------------------------------
// Impressão
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local i         := 0

	If len(_aRelImp) > 0
		oSection1:Init()

		oReport:PrintText("TÍTULOS BAIXADOS" ,,100)
		oReport:PrintText("" ,,100)

		oSection1:SetHeaderSection(.T.)

		For i:=1 to Len(_aRelImp)
			_sTitulo  := alltrim(_aRelImp[i,3]) +"/" + alltrim(_aRelImp[i,2] +"/"+_aRelImp[i,4])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aRelImp[i,5] + _aRelImp[i,6],"A1_NOME")
			_sCliente := alltrim(_aRelImp[i,5]) +"/" + alltrim(_sNome)

			oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aRelImp[i,1]  })
			oSection1:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo       })
			oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sCliente      })
			oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aRelImp[i,7]  })
			oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aRelImp[i,8]  })
			oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aRelImp[i,9]  })
			oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aRelImp[i,10] })
			oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aRelImp[i,11] })
			
			oSection1:PrintLine()
		Next
		oSection1:Finish()
	EndIf
	
	If len(_aRelErr) > 0
		oReport:PrintText("" ,,100)
		oReport:PrintText("" ,,100)
		oReport:PrintText("" ,,100)
		oReport:ThinLine()

		oSection2:Init()

		oReport:PrintText("TÍTULOS COM ERROS" ,,100)
		oReport:PrintText("" ,,100)

		oSection2:SetHeaderSection(.T.)
		For i:=1 to Len(_aRelErr)
			_sTitulo  := alltrim(_aRelErr[i,3]) +"/" + alltrim(_aRelErr[i,2] +"/"+_aRelErr[i,4])
			_sNome    := Posicione("SA1",1,xFilial("SA1")+_aRelErr[i,5] + _aRelErr[i,6],"A1_NOME")
			_sCliente := alltrim(_aRelErr[i,5]) +"/" + alltrim(_sNome)

			oSection2:Cell("COLUNA1")	:SetBlock   ({|| _aRelErr[i,1]  })
			oSection2:Cell("COLUNA2")	:SetBlock   ({|| _sTitulo       })
			oSection2:Cell("COLUNA3")	:SetBlock   ({|| _sCliente      })
			oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aRelErr[i,7]  })
			oSection2:Cell("COLUNA5")	:SetBlock   ({|| _aRelErr[i,8]  })
			oSection2:Cell("COLUNA6")	:SetBlock   ({|| _aRelErr[i,9]  })
			oSection2:Cell("COLUNA7")	:SetBlock   ({|| _aRelErr[i,10] })
			oSection2:Cell("COLUNA8")	:SetBlock   ({|| _aRelErr[i,11] })
			
			oSection2:PrintLine()
		Next
		oSection2:Finish()
	EndIf
	
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "NSU                ", "C",  6, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Cod.Autorização    ", "C",  6, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
