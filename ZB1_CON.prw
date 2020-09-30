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
//
// --------------------------------------------------------------------------
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
	
	u_logIni ("Inicio Conciliação Cielo LOJAS" + DTOS(date()) )

	If cFilAnt == '01' .and. _sConciliar == '1' // conciliação das lojas
		u_help("Empresa matriz não pode efetuar baixa pelo menu Conciliar Cielo Loja")
		_lcont := .F.
	EndIf
	If cFilAnt == '10' .and. _sConciliar == '2' // conciliação link
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
		_oSQL:_sQuery += "    ,ZB1_PARNUM" // 21
		_oSQL:_sQuery += "    ,ZB1_DTAAPR" // 22 - DATA DE EMISSAO
		_oSQL:_sQuery += " FROM " + RetSQLName ("ZB1") 
		//_oSQL:_sQuery += " WHERE ZB1_FILIAL = '" +xFilial("ZB1")+ "'"
		_oSQL:_sQuery += " WHERE ZB1_FILIAL = '" + cFilAnt + "'"
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
				
				_sParc := ''
				If alltrim(_aZB1[i, 21]) <> '00' .or. alltrim(_aZB1[i, 21]) <> '' 
					_sParc := BuscaParcela(_aZB1[i, 21])
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
				_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
				_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + _aZB1[i, 1] + "'"
				_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aZB1[i,16]) + "'"
				If _sConciliar == '1'
					_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,17] + "'" // Loja salva cod.aut no campo NSU
				Else
					_oSQL:_sQuery += " AND SE1.E1_CARTAUT = '" + _aZB1[i,17] + "'"
					_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB1[i,18] + "'"
				EndIf
				_oSQL:_sQuery += " AND SE1.E1_BAIXA   = ''"
				If alltrim(_sParc) <> ''
					_oSQL:_sQuery += " AND SE1.E1_PARCELA   = '" + _sParc + "'"
				EndIf
				_oSQL:Log ()

				_aTitulo := aclone (_oSQL:Qry2Array ())
				
				If len(_aTitulo) <= 0
					u_log("TÍTULO NÃO ENCONTRADO: Registro NSU+AUT:" + _aZB1[i,18] + _aZB1[i,17])
				Else
					
					For x:=1 to len(_aTitulo)	
						_lContinua := .T.
						_nVlrTax   := ROUND((_aZB1[i,08] * _aZB1[i,04])/100,2)
						_nVlrRec   := ROUND(_aZB1[i,08] - _nVlrTax,2)
						_nVlrTit   := _aTitulo[x,05]
						_sNSUCod   := _aZB1[i,18]
						_sAutCod   := _aZB1[i,17]

						// Verifica se valor + taxa cielo é igual ao valor do título (podem ter ajustes de arredondamento)
						If ROUND(_nVlrTax + _nVlrRec,2) == ROUND(_nVlrTit,2)
							_lContinua := .T.
							u_log("REGISTRO DE VALOR OK: Registro NSU+AUT:" + _sNSUCod + _sAutCod + " Valor compatível.")
						Else
							_nDif := _nVlrTit - (_nVlrTax + _nVlrRec)

							// Quando existe diferenças de arredondamento, pega vlr do titulo e diminui a taxa para dar baixa correta
							If  _nDif >= -0.5 .and. _nDif <= 0.5 
								_nVlrRec := _nVlrTit - _nVlrTax 
								_lContinua := .T.
								u_log("DIFERENÇA DE ARREDONDAMENTO:Registro NSU+AUT:" + _sNSUCod + _sAutCod + " Valor com diferença de arredondameto. Diferença:" + alltrim(str(_nDif)))
							Else
								// Diferença é maior que a permitida
								_lContinua := .F.
								u_log("DIFERENÇA DE VALOR TITULO X CIELO: Registro NSU+AUT:" + _sNSUCod + _sAutCod + " Valor com diferença e não será importado. Diferença:" + alltrim(str(_nDif)))
							EndIf
						EndIf

						If _lContinua == .T.

							lMsErroAuto := .F.

							// executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
							_aAutoSE1 := {}
							aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[x,1]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[x,2]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[x,3]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[x,4]	    				, Nil})
							aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[x,6] 					, Nil})
							aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[x,7] 					, Nil})
							aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[x,9] 					, Nil})
							AAdd(_aAutoSE1, {"AUTMOTBX"		, 'DEBITO CC'  						, Nil})
							AAdd(_aAutoSE1, {"CBANCO"  		, alltrim(_aZB1[i,11])	    		, Nil})  	
							AAdd(_aAutoSE1, {"CAGENCIA"   	, alltrim(_aZB1[i,12])		    	, Nil})  
							AAdd(_aAutoSE1, {"CCONTA"  		, alltrim(_aZB1[i,13])				, Nil})
							AAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase		 					, Nil})
							AAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		 					, Nil})
							AAdd(_aAutoSE1, {"AUTHIST"   	, 'Baixa Cielo'					    , Nil})
							AAdd(_aAutoSE1, {"AUTDESCONT"	, _nVlrTax         					, Nil})
							AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
							AAdd(_aAutoSE1, {"AUTVALREC"  	, _nVlrRec							, Nil})
						
							_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

							cPerg = 'FIN070'
							_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
							U_GravaSX1 (cPerg, "01", 2)    // testar mostrando o lcto contabil depois pode passar para nao
							U_GravaSX1 (cPerg, "04", 2)    // esse movimento tem que contabilizar

							MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

							If lMsErroAuto
								u_log(memoread (NomeAutoLog ()))
								u_log("IMPORTAÇÃO NÃO REALIZADA: Registro NSU+AUT:" + _sNSUCod + _sAutCod)

							Else// Se gravado, inclui campos n SE5 finaliza o registro da ZA1
								// Atualiza banco e administradora
								_oSQL:= ClsSQL ():New ()
								_oSQL:_sQuery := ""
								_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE5") + " SET E5_BANCO = '"+ alltrim(_aZB1[i,11]) + "', E5_AGENCIA = '"+ alltrim(_aZB1[i,12]) +"',"
								_oSQL:_sQuery += " E5_CONTA = '" + alltrim(_aZB1[i,13]) + "', E5_ADM = '" + alltrim(_aTitulo[x,6]) + "'"
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
								
								dbSelectArea("ZB1")
								dbSetOrder(1) // ZB1_NUMNSU + ZB1_CODAUT
								dbGoTop()
								If dbSeek(_sNSUCod + _sAutCod)
									Reclock("ZB1",.F.)
										ZB1 -> ZB1_STAIMP := 'C'
										ZB1 -> ZB1_DTABAI := date()
									ZB1->(MsUnlock())
								EndIf
								_nImpReg += 1
								u_log("IMPORTAÇÃO FINALIZADA COM SUCESSO: Registro NSU+AUT:" + _sNSUCod + _sAutCod)
							Endif

							U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
						EndIf
					Next
				Endif		
			Next
			u_help("Processo finalizado! Baixados "+ alltrim(str(_nImpReg)) +" de " + alltrim(str(_nTotReg)) )
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
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    //aadd (_aRegsPerg, {01, "Filial de          ", "C",  2, 0,  "",  "   ", {},                         				""})
    //aadd (_aRegsPerg, {02, "Filial até         ", "C",  2, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {01, "NSU                ", "C",  6, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Cod.Autorização    ", "C",  6, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
