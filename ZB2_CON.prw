
// Programa...: ZB2_CON
// Autor......: Cláudia Lionço
// Data.......: 11/11/2020
// Descricao..: Conciliação/baixa de títulos por registros de pgto Banrisul
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Conciliação/baixa de títulos por registros de pgto Banrisul
// #PalavasChave      #extrato #banrisul #recebimento #cartoes #baixa_de_titulos
// #TabelasPrincipais #ZB2 #SE1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "totvs.ch"

User Function ZB2_CON()
	Local _oSQL  	:= ClsSQL ():New ()
	Local _aZB2  	:= {}
	Local _aTitulo  := {}
	Local i		 	:= 0
	Local x      	:= 0
	Local y         := 0
	Private _aRelImp  := {}
	Private _aRelErr  := {}
	
	u_logIni ("Inicio Conciliação BANRI " + DTOS(date()) )

    cPerg   := "ZB2_CON"
    _ValidPerg ()
    
    If ! pergunte (cPerg, .T.)
        return
    Endif
		
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += "       ZB2_FILIAL " // 1
	_oSQL:_sQuery += "      ,ZB2_IDARQ  " // 2
	_oSQL:_sQuery += "      ,ZB2_DTAREF " // 3
	_oSQL:_sQuery += "      ,ZB2_DTAGER " // 4
	_oSQL:_sQuery += "      ,ZB2_ORIGEM " // 5
	_oSQL:_sQuery += "      ,ZB2_CODEST " // 6
	_oSQL:_sQuery += "      ,ZB2_AGENCI " // 7
	_oSQL:_sQuery += "      ,ZB2_CONTA  " // 8
	_oSQL:_sQuery += "      ,ZB2_VLRLIQ " // 9
	_oSQL:_sQuery += "      ,ZB2_DTALAN " //10
	_oSQL:_sQuery += "      ,ZB2_CODLAN " //11
	_oSQL:_sQuery += "      ,ZB2_DESLAN " //12
	_oSQL:_sQuery += "      ,ZB2_DTAMOV " //13
	_oSQL:_sQuery += "      ,ZB2_NSUCOD " //14
	_oSQL:_sQuery += "      ,ZB2_AUTCOD " //15
	_oSQL:_sQuery += "      ,ZB2_NUMPAR " //16
	_oSQL:_sQuery += "      ,ZB2_PARBRT " //17
	_oSQL:_sQuery += "      ,ZB2_TARFIX " //18
	_oSQL:_sQuery += "      ,ZB2_PERTAX " //19
	_oSQL:_sQuery += "      ,ZB2_VLRTAR " //20
	_oSQL:_sQuery += "      ,ZB2_TARCOM " //21
	_oSQL:_sQuery += "      ,ZB2_VLRPAR " //22
	_oSQL:_sQuery += "      ,ZB2_SEQREG " //23
	_oSQL:_sQuery += "      ,ZB2_PARTIT " //24
	_oSQL:_sQuery += " FROM " + RetSQLName ("ZB2") 
	_oSQL:_sQuery += " WHERE ZB2_FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery += " AND D_E_L_E_T_ = ''" 
	_oSQL:_sQuery += " AND ZB2_STAIMP = 'I' "        //-- APENAS OS IMPORTADOS
	If !empty(mv_par01)
		_oSQL:_sQuery += " AND ZB2_NSUCOD = '" + mv_par01 + "' " // FILTRA POR NSU
	EndIf
	_oSQL:Log ()
	
	_aZB2 := aclone (_oSQL:Qry2Array ())
		
	_cMens := "Existem " + alltrim(str(len(_aZB2))) + " registros para realizar a baixa de títulos. Deseja continuar?"
	If MsgYesNo(_cMens,"Baixa de titulos")
		_nImpReg := 0
		_nTotReg := Len(_aZB2)
		For i:=1 to Len(_aZB2)
			_sNSUCod := _aZB2[i,14]
			_sAutCod := _aZB2[i,15]
			_sDtaMov := DTOS(_aZB2[i,13])

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
			_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '" + _aZB2[i, 1] + "'"
			_oSQL:_sQuery += " AND SE1.E1_NSUTEF  = '" + _aZB2[i,14] + "'" 
			_oSQL:_sQuery += " AND SE1.E1_EMISSAO = '" + DTOS(_aZB2[i,13]) + "'"
			_oSQL:_sQuery += " AND SE1.E1_PARCELA = '" + _aZB2[i,24] + "'"
			_oSQL:_sQuery += " AND SE1.E1_BAIXA   = ''"

			_oSQL:Log ()

			_aTitulo := aclone (_oSQL:Qry2Array ())
			
			If len(_aTitulo) <= 0
				u_log("TÍTULO NÃO ENCONTRADO: Registro NSU:" + _sNSUCod )
			Else
				For x:=1 to len(_aTitulo)	

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
					AAdd(_aAutoSE1, {"CBANCO"  		, '041'	    		                , Nil})  	
					AAdd(_aAutoSE1, {"CAGENCIA"   	, '0873 '		    	            , Nil})  
					AAdd(_aAutoSE1, {"CCONTA"  		, '0619710901'				        , Nil})
					AAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase		 					, Nil})
					AAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		 					, Nil})
					AAdd(_aAutoSE1, {"AUTHIST"   	, 'Baixa Banri'					    , Nil})
					AAdd(_aAutoSE1, {"AUTDESCONT"	, _aZB2[i,20]         				, Nil})
					AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
					AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
					AAdd(_aAutoSE1, {"AUTVALREC"  	, _aZB2[i,22]						, Nil})
					
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

					Else// Se gravado, inclui campos n SE5 finaliza o registro da ZA1
						// Atualiza banco e administradora
						_sAdm := alltrim(_aTitulo[x,6]) 

						_oSQL:= ClsSQL ():New ()
						_oSQL:_sQuery := ""
						_oSQL:_sQuery += " UPDATE " + RetSQLName ("SE5") + " SET E5_BANCO = '041', E5_AGENCIA = '0873 ',"
						_oSQL:_sQuery += " E5_CONTA = '0619710901', E5_ADM = '" + _sAdm + "'"
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
							
						dbSelectArea("ZB2")
						dbSetOrder(1) // ZB2_NSUCOD + ZB2_AUTCOD + ZB2_DTAMOV
						dbGoTop()
							
						If dbSeek(_sNSUCod + _sAutCod + _sDtaMov)
							Reclock("ZB2",.F.)
								ZB2 -> ZB2_STAIMP := 'C'
								ZB2 -> ZB2_DTABAI := date()
							ZB2->(MsUnlock())
						EndIf

						_nImpReg += 1
						u_log("IMPORTAÇÃO FINALIZADA COM SUCESSO: Registro NSU+AUT:" + _sNSUCod + _sAutCod)						
					EndIf
					U_GravaSXK (cPerg, "01", "2", 'D' )
					U_GravaSXK (cPerg, "04", "2", 'D' )

					U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
				Next
			Endif		
		Next
		u_help("Processo finalizado! Baixados "+ alltrim(str(_nImpReg)) +" de " + alltrim(str(_nTotReg)) )
	Else
		u_help("Processo não realizado!")
		u_log("IMPORTAÇÃO ABORTADA PELO USUÁRIO")
	EndIf
	
	u_logFim ("Fim Conciliação Cielo " + DTOS(date()) )
Return
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      			Help
    aadd (_aRegsPerg, {01, "NSU                ", "C",  8, 0,  "",  "   ", {},                         				""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
