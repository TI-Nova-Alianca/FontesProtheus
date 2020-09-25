// Programa:   F340Can
// Autor:      Robert Koch
// Data:       03/03/2011
// Cliente:    Alianca
// Descricao:  P.E. apos confirmacao do cancelamento de compensacao de contas a pagar.
//             Criado inicialmente para atualizar saldo do arquivo SZI.
// 
// Historico de alteracoes:
// 28/03/2011 - Robert - Incluido tratamento pata ZI_TM = '03'.
// 07/07/2011 - Robert - Nao olha mais o tipo de movimento do SZI.
//                     - Nao buscava corretamente os valores dos titulos selecionados.
// 29/11/2012 - Elaine - Retornar saldo correto de titulos dependentes quando feito um cancelamento de Compensacao
// 07/02/2018 - Robert - Metodo AtuSaldo da Classe ClsAssoc nao recebe mais a filial por parametro.
// 17/07/2020 - Robert - Inseridas tags para catalogacao de fontes
//                     - Melhorada chamada de reprocessamento de saldo associado (regua de processamento).
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #PalavasChave      #compensacao #contas_a_pagar
// #TabelasPrincipais #SE5 #FK2
// #Modulos           #FIN

// --------------------------------------------------------------------------
user function f340can ()
	local _aAreaAnt := U_ML_SRArea ()
	u_logIni ()

	// Atualiza (se for o caso) o arquivo SZI.
	_AtuSZI ()

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return .t.



// --------------------------------------------------------------------------
// Atualiza (se for o caso) o arquivo SZI.
static function _AtuSZI ()
	local _i         := 0
	local _nValor    := 0
    local _nAssoc    := ""
	local _nLoja     := "" 
	local _nSeq       := ""
	local _nValUni   := 0
	local _cDocument := ""
	local _cPref     := ""
	local _cNum      := ""
	local _cParc     := ""
	local _cTipoDoc  := ""
    local _cVACHAV   := ""                           
    local _oAssoc    := ""
                                            

	u_logIni ()
//	u_log ("aTitulos:", atitulos)
//	u_log ("strlctpad:", STRLCTPAD)
//	u_logtrb ("SE2")
	se2 -> (dbsetorder (1))  // E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	if se2 -> (dbseek (xfilial ("SE2") + StrLctPad, .F.))  // Variavel private do FINA340 contendo os dados do titulo original.
 //		u_log ("Encontrei SE2 original.")
 //		u_log ("chave externa:", se2 -> e2_vachvex)
		if left (se2 -> e2_vachvex, 3) == "SZI"
			szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
			if szi -> (dbseek (xfilial ("SZI") + substr (se2 -> e2_vachvex, 4), .F.))
			    _nAssoc := SZI->ZI_ASSOC
			    _nLoja  := SZI->ZI_LOJASSO
			    _nSeq    := SZI->ZI_SEQ
//u_log ("Associado: ", _nAssoc)
//u_log ("Loja: ", _nLoja)
//u_log ("Seq: ", _nSeq)


				//u_log ("Achei SZI. Saldo atual:", szi -> zi_saldo)

				// Soma valores das compensacoes selecionadas. Para isso, utiliza array private do
				// programa FINA340, usada para a selecao dos titulos pelo usuario. A coluna do
				// valor estah formatada para mostrar em tela, entao precisa converter para valor.
				_nValor = 0
				for _i = 1 to len (aTitulos)
					if aTitulos [_i, 10]           
					    _nValUni  := val (strtran (strtran (aTitulos [_i, 9], '.', ''), ',', '.'))  // Campo formatado para mostrar na tela.
						_nValor += _nValUni
           
//u_log ("Valor Uni: ",_nValUni)
//u_log ("Valor Somando: ",_nValor)
                        // Atualiza o valor de cada compensacao
						_cDocument := aTitulos [_i, 6]
						_cPref     := substr(_cDocument,1,3)
						_cNum      := substr(_cDocument,4,9) 
						_cParc     := substr(_cDocument,13,1)
						_cTipoDoc  := substr(_cDocument,14,3) 

//u_log ("Documento: ",_cDocument)
//u_log ("Prefixo: ",_cPref)
//u_log ("Numero: ",_cNum) 
//u_log ("Parc: ",_cParc)
//u_log ("TipoDoc: ",_cTipoDoc)

            			se5 -> (dbsetorder (7))  // E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
		            	if se5 -> (dbseek (xfilial ("SE5") + _cPref + _cNum + _cParc + _cTipoDoc + _nAssoc + _nLoja, .T.))
		            	RecLock("SE5",.F.)
		            	SE5->E5_VAUSER   := alltrim(cUserName)
		            	MsUnLock()
//u_log("Encontrou se5")
                           _cVACHAV := substr (se5 -> e5_vachvex, 4)
//u_log ("_cVACHAV: ", _cVACHAV)

                           szi -> (dbsetorder (2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
                           If szi -> (dbseek (xfilial ("SZI") + _cVACHAV, .T.))
//u_log ("Encontrou SZI para alterar ")


            				  reclock ("SZI", .F.)
    			              szi -> zi_saldo += _nValUni
	    		              msunlock ()                

                              // Atualiza saldo do Associado                                          
                              _oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
	                          if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
	                          else
                    //             _oAssoc:AtuSaldo (szi -> zi_data)
								processa ({ || _oAssoc:AtuSaldo (szi -> zi_data)})
	                          endif                            
	    		                  		              
                           endif
						endif
						 
					endif
				next
//				u_log ("Ajustando saldo do SZI em", _nValor)
 			    szi -> (dbsetorder(2))  // ZI_FILIAL+ZI_ASSOC+ZI_LOJASSO+ZI_SEQ
			    if szi -> (dbseek(xfilial ("SZI") + _nAssoc + _nLoja + _nSeq, .F.))

//      			   _cFilial := szi -> zi_filial
// 			       _cAssoc := szi -> zi_assoc
//			       _cLjAssoc := szi -> zi_ljasso
//			       _dDtAtu := szi -> zi_data

                   // Atualiza saldo do Associado                                          
//                   _oAssoc := ClsAssoc():New (_cAssoc, _cLjAssoc)
                   _oAssoc := ClsAssoc():New (szi -> zi_assoc, szi -> zi_lojasso)
	               if valtype (_oAssoc) == NIL .or. valtype (_oAssoc) != "O"
	               else
//                      _oAssoc:AtuSaldo (_cFilial, _dDtAtu)                                              
                  //    _oAssoc:AtuSaldo (szi -> zi_data)     
					  processa ({ || _oAssoc:AtuSaldo (szi -> zi_data)})                                         
	               endif                            

	    		endif     
//				u_log ("Ajustei SZI. Saldo atual:", szi -> zi_saldo)
			endif
		endif
	endif
	u_logFim ()
return
