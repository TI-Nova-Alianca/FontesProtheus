//  Programa...: VA_COMREL
//  Autor......: Cláudia Lionço
//  Cliente....: Alianca
//  Descricao..: Relatório de Comissoes - Reescrito para novo modelo TREPORT 
//			     e alterações de verbas/comissões.
//
// #TipoDePrograma    #relatorio
// #PalavasChave      #comissoes #verbas #bonificação #comissões #representante #comissão #treport
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 #SE5 #SA3
// #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//  06/11/2020 - Claudia - Incluida impressão de indenização e dados de pgto. GLPI: 8775
//  08/01/2021 - Claudia - Alterada a indenização, pegando direto o Total da comissão e dividindo por 12
//
//
// --------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_COMREL()
	Private oReport
	Private cPerg   := "VA_COMREL"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport   := Nil
	Local oSection1 := Nil
	Local oSection2 := Nil
	Local oSection3 := Nil
	Local oSection4 := Nil
	
	oReport := TReport():New("VA_COMREL","Relatório de Comissões",cPerg,{|oReport| PrintReport(oReport)},"Relatório de Comissões")
	TReport():ShowParamPage()
	oReport:SetTotalInLine(.F.)
	oReport:SetLandScape()
	
	// NOTAS FISCAIS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	//TRCell():New(oSection1,"COLUNA1", 	"" ,"PRF"					,	    				, 4,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"TÍTULO"				,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"PARC."					,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"CLIENTE"				,						,60,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"TOTAL NOTA"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"IPI"					, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"ST"					, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"BONIF."				, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"FRETE."				, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"DT.PGTO"				,	    				,12,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	//TRCell():New(oSection1,"COLUNA11", 	"" ,"PEDIDO"				,	    				,12,/*lPixel*/,{||  },"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"COLUNA12", 	"" ,"VLR.TITULO"			, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA13", 	"" ,"DESC.FIN."				, "@E 999,999,999.99"   ,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA14", 	"" ,"VLR.RECEBIDO"			, "@E 999,999,999.99"   ,19,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA15", 	"" ,"BASE PREV."			, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA16", 	"" ,"BASE LIB."				, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA17", 	"" ,"% MÉDIO"				, "@E 9,999.99"   		,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"COLUNA18", 	"" ,"VLR.COMISSÃO"			, "@E 999,999,999.99"   ,22,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.T.)
	
	// ITENS DA NF
	oSection2 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
	TRCell():New(oSection2,"COLUNA1", 	"" ,"Produto"				,       				,16 ,/*lPixel*/,{|| 	},"RIGHT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA2", 	"" ,"Descrição"				,					    ,95 ,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA3", 	"" ,"Espaço"				,						,135 ,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection2,"COLUNA4", 	"" ,"B.Com.Prev."			, "@E 999,999,999.99"   ,30 ,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA5", 	"" ,"B.Com.Lib."			, "@E 999,999,999.99"   ,30 ,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA6", 	"" ,"% Médio"				, "@E 9,999.99"   		,15 ,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection2,"COLUNA7", 	"" ,"Vlr.Comissão"			, "@E 999,999,999.99"   ,22 ,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	// VERBAS/BONIFIFICAÇÕES
	oSection3 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.,,15) 
	
	TRCell():New(oSection3,"COLUNA1", 	"" ,"Tipo"			,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA2", 	"" ,"Vend.Verba"	,					    ,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA3", 	"" ,"Vend.NF"		,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA4", 	"" ,"Verba"			,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA5", 	"" ,"Nota/Série"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA6", 	"" ,"Cliente/Loja"	,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection3,"COLUNA7", 	"" ,"Percentual"	, "@E 9,999.99"   		,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA8", 	"" ,"Base/valor"	, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA9", 	"" ,"Comissao"		, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection3,"COLUNA10", 	"" ,"Valor  "		, 					    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	
	// DEVOLUÇÕES
	oSection4 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.,,15) 
	
	TRCell():New(oSection4,"COLUNA1", 	"" ,"Título"		,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA2", 	"" ,"Prefixo"		,					    ,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA3", 	"" ,"Parcela"		,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA4", 	"" ,"Cliente/Loja"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA5", 	"" ,"Nome"			,						,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection4,"COLUNA6", 	"" ,"Valor Mov."	, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection4,"COLUNA7", 	"" ,"% Comis.Médio"	, "@E 999.99"   		,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection4,"COLUNA8", 	"" ,"Comissão"		, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(2)
	Local oSection3 := oReport:Section(3)
	Local oSection4 := oReport:Section(4)
	Local _aVend 	:= {}
	Local _aItens   := {}
	Local _aDev     := {}
	Local _x		:= 0
	Local _y        := 0
	Local _i        := 0
	Local _sAliasQ  := ""
	
	If mv_par07 = 1 // IMPRIME RELATÓRIO
				
		oSection1:Init()
		oSection1:SetHeaderSection(.T.)
		
		_aVend = _COMVEND(mv_par01, mv_par02, mv_par03, mv_par04, mv_par05)
			
		For _x:=1 to len(_aVend)
			_sVend     := _aVend[_x,1]
			_sVendNome := _aVend[_x,2]
			_sVendedor := 'REPRESENTANTE: '+ alltrim(_aVend[_x,1]) + ' - ' + alltrim(_sVendNome)
			
			_sAliasQ = U_VA_COMEXE(mv_par01, mv_par02, _sVend, mv_par05) // Consulta principal
			(_sAliasQ) -> (dbgotop ())
			
			oReport:ThinLine()
			oReport:PrintText("" ,,100)
			oReport:PrintText(_sVendedor ,,100)
			oReport:PrintText("" ,,100)
			oReport:ThinLine()
			
			_nTotComis    := 0
			_nTotPerComis := 0
			_nTotBaseLib  := 0
			_nTotBaseTit  := 0
			_nTotVlrRec   := 0
			_nTotVlrDesc  := 0
			_nTotVlrTit   := 0
				
			
			Do while ! (_sAliasQ) -> (eof ())
				
				_sFilial    := (_sAliasQ) -> FILIAL
				_sNota      := (_sAliasQ) -> NUMERO
				_sSerie     := (_sAliasQ) -> PREFIXO
				_sParcela   := (_sAliasQ) -> PARCELA
				_sTipo      := (_sAliasQ) -> E3_TIPO
				_sCliente   := (_sAliasQ) -> CODCLI
				_sLoja      := (_sAliasQ) -> LOJA
				_nBaseComis	:= (_sAliasQ) -> BASE_COMIS
				_nVlrComis  := (_sAliasQ) -> VLR_COMIS
				_VlrDescNf  := (_sAliasQ) -> BONIF_NF
				_nBaseNota  := (_sAliasQ) -> TOTAL_NF - (_sAliasQ) -> IPI_NF  - (_sAliasQ) -> ST_NF - (_sAliasQ) -> FRETE_NF - _VlrDescNf 
				_sDataVenc  := STOD((_sAliasQ) -> VENCIMENTO)
				_sDtaPgto   := STOD((_sAliasQ) ->DT_COMIS)
				_nSimples   := (_sAliasQ) -> SIMPLES
				_sTipIndeniz:= (_sAliasQ) -> INDENIZ
				_sBanco     := (_sAliasQ) -> BANCO
				_sNomeBanco := (_sAliasQ) -> NOMEBANCO
	       		_nAgencia   := (_sAliasQ) -> AGENCIA
	       		_nConta     := (_sAliasQ) -> CONTA
				_nIpiNota	:= (_sAliasQ) -> IPI_NF
				_nStNota	:= (_sAliasQ) -> ST_NF
	       		
	       		// Monta campo de parcela
	       		_sParcNew := MontaParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)

				//// Monta campo de parcela
	       		//_nQtdParc := QntParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)

				//// Busca IPI e ST
				//_nVlrIpi := U_VA_COMIPIST(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela,_nIpiNota,_nStNota,_nQtdParc, 'I')
				//_nVlrSt  := U_VA_COMIPIST(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela,_nIpiNota,_nStNota,_nQtdParc, 'I')

				//oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> PREFIXO	})
				oSection1:Cell("COLUNA2")	:SetBlock   ({|| (_sAliasQ) -> NUMERO	})
				oSection1:Cell("COLUNA3")	:SetBlock   ({|| _sParcNew				})
				If mv_par06 = 1
					oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> NOMECLIENTE	})
				Else
					oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> NOMEREDUZIDO	})
				EndIf
				oSection1:Cell("COLUNA5")	:SetBlock   ({|| (_sAliasQ) -> TOTAL_NF		})
				oSection1:Cell("COLUNA6")	:SetBlock   ({|| _nIpiNota					})
				oSection1:Cell("COLUNA7")	:SetBlock   ({|| _nStNota					})
				oSection1:Cell("COLUNA8")	:SetBlock   ({|| (_sAliasQ) -> BONIF_NF		})
				oSection1:Cell("COLUNA9")	:SetBlock   ({|| (_sAliasQ) -> FRETE_NF		})
				oSection1:Cell("COLUNA10")	:SetBlock   ({|| _sDtaPgto					})
				//oSection1:Cell("COLUNA11")	:SetBlock   ({|| (_sAliasQ) -> PEDIDO		})
				oSection1:Cell("COLUNA12")	:SetBlock   ({|| (_sAliasQ) -> VALOR_TIT	})
				oSection1:Cell("COLUNA13")	:SetBlock   ({|| (_sAliasQ) -> VLR_DESCONTO	})
				oSection1:Cell("COLUNA14")	:SetBlock   ({|| (_sAliasQ) -> VLR_RECEBIDO	})
				oSection1:Cell("COLUNA15")	:SetBlock   ({|| (_sAliasQ) -> BASE_TIT		})
				oSection1:Cell("COLUNA16")	:SetBlock   ({|| (_sAliasQ) -> BASE_COMIS	})
				oSection1:Cell("COLUNA17")	:SetBlock   ({|| (_sAliasQ) -> PERCENTUAL	})
				oSection1:Cell("COLUNA18")	:SetBlock   ({|| (_sAliasQ) -> VLR_COMIS	})
				
				oSection1:PrintLine()
				
				_nTotComis    += (_sAliasQ) -> VLR_COMIS
				_nTotPerComis += (_sAliasQ) -> PERCENTUAL
				_nTotBaseLib  += (_sAliasQ) -> BASE_COMIS
				_nTotBaseTit  += (_sAliasQ) -> BASE_TIT	
				_nTotVlrRec   += (_sAliasQ) -> VLR_RECEBIDO
				_nTotVlrDesc  += (_sAliasQ) -> VLR_DESCONTO
				_nTotVlrTit   += (_sAliasQ) -> VALOR_TIT
				
				// Imprime itens da nota
				If mv_par08 == 2 .and. mv_par07 == 1 
					
					_aItens = U_VA_COMITNF(_sFilial, _sNota, _sSerie, _nBaseComis, _nVlrComis, _nBaseNota)
					
					oSection2:Init()
					oSection2:SetHeaderSection(.F.)
					
					For _y := 1 to len(_aItens)
						oSection2:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_aItens[_y,1]) })
						oSection2:Cell("COLUNA2")	:SetBlock   ({|| alltrim(_aItens[_y,2]) })
						oSection2:Cell("COLUNA3")	:SetBlock   ({|| ""						})
						oSection2:Cell("COLUNA4")	:SetBlock   ({|| _aItens[_y,3]			})
						oSection2:Cell("COLUNA5")	:SetBlock   ({|| _aItens[_y,4] 			})
						oSection2:Cell("COLUNA6")	:SetBlock   ({|| _aItens[_y,5] 			})
						oSection2:Cell("COLUNA7")	:SetBlock   ({|| _aItens[_y,6]			})
						
						oSection2:PrintLine()
					Next
					
					oReport:PrintText(" ",,100)
					oSection2:Finish()
				EndIf
				(_sAliasQ) -> (dbskip ())
			EndDo	
			//
			//--------------------------------------------------------------------------------------------------
			// DESCONTO DE VERBAS E BONIFICAÇÕES
			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT"
			_oSQL:_sQuery += "     ZB0_TIPO"
			_oSQL:_sQuery += "    ,ZB0_VENVER"
			_oSQL:_sQuery += "    ,ZB0_VENNF"
			_oSQL:_sQuery += "    ,ZB0_NUM"
			_oSQL:_sQuery += "    ,ZB0_DOC"
			_oSQL:_sQuery += "    ,ZB0_PREFIX"
			_oSQL:_sQuery += "    ,ZB0_CLI"
			_oSQL:_sQuery += "    ,ZB0_LOJA"
			_oSQL:_sQuery += "    ,ZB0_PERCOM"
			_oSQL:_sQuery += "    ,ZB0_VLBASE"
			_oSQL:_sQuery += "    ,ZB0_VLCOMS"
			_oSQL:_sQuery += "    ,CASE"
			_oSQL:_sQuery += " 			WHEN ZB0_ACRDES = 'D' THEN 'DESCONTO'"
			_oSQL:_sQuery += " 			ELSE 'ACRESCIMO'"
			_oSQL:_sQuery += "     END AS ACRDES"
			_oSQL:_sQuery += "    ,ZB0_DTAPGT"
			_oSQL:_sQuery += " FROM " + RetSQLName ("ZB0") 
			_oSQL:_sQuery += " WHERE ZB0_FILIAL = '" +  xFilial('ZB0')  +"'" 
			_oSQL:_sQuery += " AND ZB0_DATA BETWEEN '" + DTOS(mv_par01) + "' AND '" + DTOS(mv_par02) +"'"
			_oSQL:_sQuery += " AND ZB0_VENDCH = '"+_sVend+"'"
			_oSQL:Log ()
				
			_aDescVerb  = aclone (_oSQL:Qry2Array ())			
			
			oSection3:Init()
			//oSection3:SetHeaderSection(.F.)
			
			_nVlrTVerbas := 0
			_nVlrBon     := 0
			_nVlrVer     := 0
			If len(_aDescVerb)> 0
				oReport:PrintText(" *** DESCONTOS DE VERBAS/BONIFICAÇÕES:",,100)
				oSection3:SetHeaderSection(.T.)
			EndIf
			
			For _y := 1 to len(_aDescVerb)
				
				_dDtaPgto := DTOS(_aDescVerb[_y,13])
				
				// Descrição de tipo
				_sTipoZb0 := ""
				Do Case
					Case alltrim(_aDescVerb[_y,1]) == '1'
						_sTipoZb0 := '1 - VERBAS S/ MOV. NO TITULO'
						
					Case alltrim(_aDescVerb[_y,1]) == '2'
						_sTipoZb0 := '2 - VERBA DE OUTROS NO TITULO'
						
					Case alltrim(_aDescVerb[_y,1]) == '3'
						_sTipoZb0 := '3 - BONIFICAÇÕES' 
						
					Case alltrim(_aDescVerb[_y,1]) == '4'
						_sTipoZb0 := '4 - VERBAS BOLETO/DEPOSITO'
						
					Case alltrim(_aDescVerb[_y,1]) == '5'
						_sTipoZb0 := '5 - VERBA EM TITULO DE OUTROS'
						
					Case alltrim(_aDescVerb[_y,1]) == '6'
						_sTipoZb0 := '6 - VERBA EM TITULO SEM COMISSÃO'
				EndCase
				
				
				Do Case
				
					Case mv_par10 == 2 .and. ( empty(_dDtaPgto) .or. _dDtaPgto =='19000101')  // pagas
						// registro sem data de pgto nao entra nas pagas
					Case mv_par10 == 3 	.and.  _dDtaPgto != '19000101'  // em aberto
						// registro com data de pagamento n entra nos registros em aberto
					Otherwise
						oSection3:Cell("COLUNA1")	:SetBlock   ({|| alltrim(_sTipoZb0) 									    })
						oSection3:Cell("COLUNA2")	:SetBlock   ({|| alltrim(_aDescVerb[_y,2]) 									})
						oSection3:Cell("COLUNA3")	:SetBlock   ({|| alltrim(_aDescVerb[_y,3])									})
						oSection3:Cell("COLUNA4")	:SetBlock   ({|| alltrim(_aDescVerb[_y,4])									})
						oSection3:Cell("COLUNA5")	:SetBlock   ({|| alltrim(_aDescVerb[_y,5]) +"/"+ alltrim(_aDescVerb[_y,6])	})
						oSection3:Cell("COLUNA6")	:SetBlock   ({|| alltrim(_aDescVerb[_y,7]) +"/"+ alltrim(_aDescVerb[_y,8])	})
						oSection3:Cell("COLUNA7")	:SetBlock   ({||   ROUND(_aDescVerb[_y, 9],2)								})
						oSection3:Cell("COLUNA8")	:SetBlock   ({||   ROUND(_aDescVerb[_y,10],2)								})
						oSection3:Cell("COLUNA9")	:SetBlock   ({||   ROUND(_aDescVerb[_y,11],2)								})
						oSection3:Cell("COLUNA10")	:SetBlock   ({|| alltrim(_aDescVerb[_y,12]) 								})
				
						oSection3:PrintLine()
						 
						If alltrim(_aDescVerb[_y,1]) == '3'
							_nVlrBon += _aDescVerb[_y,11]
						Else
							_nVlrVer += _aDescVerb[_y,11]
						EndIf
				EndCase	
			Next
			
			If len(_aDescVerb)> 0
				_nVlrBon:= ROUND(_nVlrBon,2)
				_nVlrVer:= ROUND(_nVlrVer,2)
				_nVlrTVerbas := _nVlrBon+_nVlrVer
				
				_nLinha :=  oReport:Row()
				oReport:PrintText(" ",,100)
				oReport:PrintText("TOTAL DAS VERBAS/BONIFICAÇÕES DESCONTADAS: " + PADL('R$' + Transform(_nVlrTVerbas, "@E 999,999,999.99"),20,' ') ,_nLinha, 100)
				oReport:SkipLine(1) 
	
				oSection3:Finish()
			EndIf
			
			oReport:PrintText(" ",,100)
			oSection3:Finish()
			//
			//--------------------------------------------------------------------------------------------------
			// DEVOLUÇÕES
			_aDev = U_VA_COMDEV(mv_par01, mv_par02, _sVend)
					
			oSection4:Init()

			If len(_aDev)> 0
				oReport:PrintText(" *** DESCONTOS DE DEVOLUÇÕES:",,100)
				oSection4:SetHeaderSection(.T.)
			EndIf

			_nTotDev := 0
			For _i := 1 to len(_aDev)
				oSection4:Cell("COLUNA1")	:SetBlock   ({|| _aDev[_i,2] })
				oSection4:Cell("COLUNA2")	:SetBlock   ({|| _aDev[_i,3] })
				oSection4:Cell("COLUNA3")	:SetBlock   ({|| _aDev[_i,4] })
				oSection4:Cell("COLUNA4")	:SetBlock   ({|| _aDev[_i,5] +"/"+ _aDev[_i,6] })
				oSection4:Cell("COLUNA5")	:SetBlock   ({|| _aDev[_i,7] })
				oSection4:Cell("COLUNA6")	:SetBlock   ({|| _aDev[_i,8] })
				oSection4:Cell("COLUNA7")	:SetBlock   ({|| _aDev[_i,10] })
				oSection4:Cell("COLUNA8")	:SetBlock   ({|| _aDev[_i,11] })
				
				oSection4:PrintLine()

				_nTotDev += _aDev[_i,11] 
			Next

			If Len(_aDev) > 0
				_nLinha :=  oReport:Row()
				oReport:PrintText(" ",,100)
				oReport:PrintText("TOTAL DAS DEVOLUÇÕES DESCONTADAS: " + PADL('R$' + Transform(_nTotDev, "@E 999,999,999.99"),20,' ') ,_nLinha, 100)
				oReport:SkipLine(1) 

				oSection4:Finish()
			EndIf
			
			oReport:PrintText(" ",,100)
			
			//
			// ----------------------------------------------------------------------------------------------------------
			// TOTALIZADORES
			oReport:ThinLine()
			oReport:PrintText(" ",,100)
			oReport:PrintText("RESUMO DO CÁLCULO DE COMISSÕES " + AllTrim(_sVendedor) ,,100)
			oReport:PrintText(" ",,100)

			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("BASE COMISSÃO LIBERADA:" ,_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nTotBaseLib, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 
			
			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("OUTRAS VERBAS:" ,_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nVlrVer, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 
			
			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("OUTROS DESCONTOS/BONIFICAÇÕES:" ,_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nVlrBon, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 

			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("DEVOLUÇÕES:" ,_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nTotDev, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 

			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			// DESCONTA AS VERBAS
			If _nVlrTVerbas < 0
				_nVlrTVerbas = _nVlrTVerbas * -1
				_nVlrCom:= _nTotComis - _nVlrTVerbas
			Else
				_nVlrCom:= _nTotComis + _nVlrTVerbas
			EndIf

			// DESCONTA AS DEVOLUÇÕES
			If _nTotDev < 0
				_nTotDev = _nTotDev * -1
				_nVlrCom:= _nVlrCom - _nTotDev
			Else
				_nVlrCom:= _nVlrCom + _nTotDev
			EndIf
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("COMISSÃO TOTAL: ",_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nVlrCom, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 

			// IR - so faz a retenção de IR para representantes que NAO ESTAO no simples nacional
			_nVlrIR := 0
			If _nSimples != '1' // 1=SIM
				_nVlrIR := ROUND(_nVlrCom * 1.5 /100 , 2)
				If _nVlrIR > 10
					_nLinha :=  oReport:Row()
					_nLinha:= _PulaFolha(_nLinha)
					oReport:PrintText("TOTAL DO IR:" ,_nLinha,100)
					oReport:PrintText(PADL('R$' + Transform(_nVlrIR, "@E 999,999,999.99"),20,' '),_nLinha, 900)
					oReport:SkipLine(1) 
				Else
					_nVlrIR = 0            	
				Endif            	
			EndIf
			
			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("TOTAL COMISSÃO A RECEBER:" ,_nLinha, 100)
			oReport:PrintText(PADL('R$' + Transform(_nVlrCom - _nVlrIR, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 

			//
			// ----------------------------------------------------------------------------------------------------------
			// Indenização
			//_nTotalInde := _nTotComis - _nVlrTVerbas - _nTotDev //_nVlrCom // Sem IR
			_nTotalInde := _nVlrCom // alterado para pegar ja direta a comissão total
			_nIndeniz = ROUND(_nTotalInde /12 , 2)

			_nLinha :=  oReport:Row()
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("VLR INDENIZAÇÃO 1/12 " + IIF (_sTipIndeniz ='S', 'PAGA', 'PROVISIONADA')	+":" ,_nLinha,100)
			oReport:PrintText(PADL('R$' + Transform(_nIndeniz, "@E 999,999,999.99"),20,' '),_nLinha, 900)
			oReport:SkipLine(1) 

			If _sTipIndeniz ='S' 
				_vIRind := 0
				If _nSimples != '1'
					_vIRind = ROUND(_nIndeniz * 15 /100 , 2)
					If _vIRind > 10
						_nLinha :=  oReport:Row()
						_nLinha:= _PulaFolha(_nLinha)
						oReport:PrintText("TOTAL DO IR (INDENIZ):" ,_nLinha,100)
						oReport:PrintText(PADL('R$' + Transform(_vIRind, "@E 999,999,999.99"),20,' '),_nLinha, 900)
						oReport:SkipLine(1) 
						
						_nLinha :=  oReport:Row()
						_nLinha:= _PulaFolha(_nLinha)
						oReport:PrintText("TOTAL INDENIZ (-) IR :" ,_nLinha,100)
						oReport:PrintText(PADL('R$' + Transform(_nIndeniz - _vIRind, "@E 999,999,999.99"),20,' '),_nLinha, 900)
						oReport:SkipLine(1) 
					Else
						_vIRind := 0
					Endif
				Endif
			Endif
		
			//
			// ----------------------------------------------------------------------------------------------------------
			// Banco
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText(" "  ,,100)
			oReport:ThinLine()
			oReport:PrintText(" "  ,,100)
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("*** DADOS DO PAGAMENTO "  ,,100)
			oReport:PrintText(" "  ,,100)
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("BANCO   :" + alltrim(_sBanco) + " - " + alltrim(_sNomeBanco) ,,100)
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("AGENCIA :" + _nAgencia ,,100)
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText("CONTA   :" + _nConta ,,100)
			_nLinha:= _PulaFolha(_nLinha)
			oReport:PrintText(" "  ,,100)

			oReport:EndPage()
			oReport:StartPage()
		Next
		
		oSection1:Finish()

	EndIf
Return
//
// --------------------------------------------------------------------------
// Busca os vendedores para serem impressos
//Static Function _BuscaVendedores()
Static Function _COMVEND(_dtaIni, _dtaFin, _sVendIni, _sVendFin, _nLibPg)
	Local _aVend := {}
	Local _oSQL  := ClsSQL ():New ()
	
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT
	_oSQL:_sQuery += " 	E3_VEND AS VENDEDOR
	_oSQL:_sQuery += "    ,A3_NOME AS NOM_VEND
	_oSQL:_sQuery += "    FROM " + RetSQLName ("SE3") + " AS SE3 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
	_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''
	_oSQL:_sQuery += " 			AND SA3.A3_MSBLQL != '1'
	_oSQL:_sQuery += " 			AND SA3.A3_ATIVO != 'N'
	_oSQL:_sQuery += " 			AND SA3.A3_COD = SE3.E3_VEND)
	_oSQL:_sQuery += " WHERE E3_FILIAL = '" + xFilial('SE3') + "' "   
	_oSQL:_sQuery += " AND E3_VEND BETWEEN '" + _sVendIni + "' and '" + _sVendFin + "'"
	_oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '" + dtos (_dtaIni) + "' AND '" + dtos (_dtaFin) + "'"
	_oSQL:_sQuery += " AND E3_BAIEMI = 'B'
	_oSQL:_sQuery += " AND SE3.D_E_L_E_T_ = ''
	If _nLibPg = 1  // comissoes liberadas
		_oSQL:_sQuery += "   AND E3_DATA   = ''"
	Else // comissoes pagas
		_oSQL:_sQuery += "  AND E3_DATA   != ''"
	EndIf
	_aVend := _oSQL:Qry2Array ()
	
Return _aVend
// //
// // --------------------------------------------------------------------------
// // Quantidade de parcelas do titulo
// Static Function QntParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)
// 	local _aParc   := {}
// 	local _qtdParc := 1
	
// 	_sQuery := ""
// 	_sQuery += " SELECT COUNT (*) "
// 	_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
// 	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
// 	_sQuery += " AND E1_FILIAL  = '" + _sFilial  + "'"
// 	_sQuery += " AND E1_NUM     = '" + _sNota    + "'"
// 	_sQuery += " AND E1_PREFIXO = '" + _sSerie   + "'"
// 	_sQuery += " AND E1_CLIENTE = '" + _sCliente + "'"
// 	_sQuery += " AND E1_LOJA   	= '" + _sLoja    + "'"
// 	_aParc := U_Qry2Array(_sQuery)
	
// 	If Len(_aParc) > 0
// 		_qtdParc := _aParc[1,1]
// 	Else
// 		_qtdParc := 1
// 	EndIf
	
// Return _qtdParc
//
// --------------------------------------------------------------------------
// parcelas do titulo String
Static Function MontaParcelas(_sFilial,_sNota,_sSerie,_sCliente,_sLoja,_sParcela)
	local _aParc   := {}
	local _qtdParc := 1
	local _sRet    := ""
	local _sP      := ""
	
	_sQuery := ""
	_sQuery += " SELECT COUNT (*) "
	_sQuery += " FROM " +  RetSQLName ("SE1") + " AS SE1 "
	_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_sQuery += " AND E1_FILIAL  = '" + _sFilial  + "'"
	_sQuery += " AND E1_NUM     = '" + _sNota    + "'"
	_sQuery += " AND E1_PREFIXO = '" + _sSerie   + "'"
	_sQuery += " AND E1_CLIENTE = '" + _sCliente + "'"
	_sQuery += " AND E1_LOJA   	= '" + _sLoja    + "'"
	_aParc := U_Qry2Array(_sQuery)
	
	If Len(_aParc) > 0
		_qtdParc := _aParc[1,1]
	Else
		_qtdParc := 1
	EndIf
	
	// Transforma parcelas em numeros
	
	Do case
		Case alltrim(_sParcela) == ''
			_sP := '1'
		Case alltrim(_sParcela) == 'A'
			_sP := '1'
		Case alltrim(_sParcela) == 'B'
			_sP := '2'
		Case alltrim(_sParcela) == 'C'
			_sP := '3'
		Case alltrim(_sParcela) == 'D'
			_sP := '4'
		Case alltrim(_sParcela) == 'E'
			_sP := '5'
		Case alltrim(_sParcela) == 'F'
			_sP := '6'
		Case alltrim(_sParcela) == 'G'
			_sP := '7'
		Case alltrim(_sParcela) == 'H'
			_sP := '8'
		Case alltrim(_sParcela) == 'I'
			_sP := '9'
		Case alltrim(_sParcela) == 'J'
			_sP := '10'
		Case alltrim(_sParcela) == 'K'
			_sP := '11'
		Case alltrim(_sParcela) == 'L'
			_sP := '12'
		Case alltrim(_sParcela) == 'M'
			_sP := '13'
		Case alltrim(_sParcela) == 'N'
			_sP := '14'
		Case alltrim(_sParcela) == 'O'
			_sP := '15'
		Case alltrim(_sParcela) == 'P'
			_sP := '16'
		Case alltrim(_sParcela) == 'Q'
			_sP := '17'
		Case alltrim(_sParcela) == 'R'
			_sP := '18'
		Case alltrim(_sParcela) == 'S'
			_sP := '19'
		Case alltrim(_sParcela) == 'T'
			_sP := '20'
		Case alltrim(_sParcela) == 'U'
			_sP := '21'
		Case alltrim(_sParcela) == 'V'
			_sP := '22'
		Case alltrim(_sParcela) == 'X'
			_sP := '23'
		Case alltrim(_sParcela) == 'Z'
			_sP := '24'
	EndCase
	
	_sRet := _sParcela + ' ' + _sP +'/'+ alltrim(str(_qtdParc))
Return _sRet
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
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Base de                 ?", "D", 8, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Data Base ate                ?", "D", 8, 0,  "",   "   ", {},                        		 ""})
    aadd (_aRegsPerg, {03, "Representante de             ?", "C", 3, 0,  "",   "SA3", {},                        		 "Representante Inicial"})
    aadd (_aRegsPerg, {04, "Representante ate            ?", "C", 3, 0,  "",   "SA3", {},                        		 "Represenante Final"})
    aadd (_aRegsPerg, {05, "Lista Comissoes              ?", "N", 1,  0,  "",   "   ", {"Liberadas","Pagas","Ambas"}    ,""})
    aadd (_aRegsPerg, {06, "Lista no Cliente             ?", "N", 1,  0,  "",   "   ", {"Razão Social","Nome Reduzido"} ,""})
    aadd (_aRegsPerg, {07, "Opção                        ?", "N", 1,  0,  "",   "   ", {"Analitica"}					,""})
    aadd (_aRegsPerg, {08, "Lista comissao por item      ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {09, "Considera bloqueados         ?", "N", 1,  0,  "",   "   ", {"Não","Sim"},   				 ""})
    aadd (_aRegsPerg, {10, "Ajustes de comissões         ?", "N", 1,  0,  "",   "   ", {"Ambas","Pagas","Em Aberto"},    ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
