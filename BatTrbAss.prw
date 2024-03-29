// Programa...: BatTrbAss
// Autor......: Claudia Lion�o
// Data.......: 30/03/2022
// Descricao..: Bat para regra de tributação de associados
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Bat para regra de tributação de associados
// #PalavasChave      #associados #cliente_associados #regra_tributacao
// #TabelasPrincipais #SA1 #SA2 #AI0
// #Modulos   		  #FIS 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function BatTrbAss()
	Local _x        := 0
	Local _sGrpTrib := ""

	U_Log2 ('info', '[' + procname () + ']Fornecedores Associados')

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT A2_COD "
	_oSQL:_sQuery +=       ", A2_LOJA "
	_oSQL:_sQuery +=       ", A2_NOME "
	_oSQL:_sQuery +=       ", A2_GRPTRIB "
	_oSQL:_sQuery +=       ", A2_TIPO "
	_oSQL:_sQuery +=       ", (SELECT CASE WHEN EXISTS (SELECT *"
	_oSQL:_sQuery +=                                    " FROM " + RetSQLName ("SZI") + ' SZI '
	_oSQL:_sQuery +=                                   " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                                     " AND SZI.ZI_FILIAL  = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery +=                                     " AND SZI.ZI_ASSOC   = A2_COD"
	_oSQL:_sQuery +=                                     " AND SZI.ZI_LOJASSO = A2_LOJA)"
	_oSQL:_sQuery +=                " THEN 'S'"
	_oSQL:_sQuery +=                " ELSE 'N'"
	_oSQL:_sQuery +=                " END "
	_oSQL:_sQuery +=         ")"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SA2") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND A2_MSBLQL = '2' "
	u_log(_oSQL:_sQuery)
	_aFornece := aclone (_oSQL:Qry2Array (.f., .f.))

	For _x:=1 to Len(_aFornece)

		// Atualiza log a cada 100 registros para nao ficar muito lento
		if _x % 100 == 0
			U_Log2 ('debug', '[' + procname () + ']Verificando fornecedores (' + cvaltochar (_x) + ' de ' + cvaltochar (len (_aFornece)) + ')')
		endif

		// Se nao tem registro no SZI, nem tento verificar se eh associado
		if _aFornece[_x,6] == 'S'
			If U_EhAssoc(_aFornece[_x,1],_aFornece[_x,2], date())
				If _aFornece[_x, 5] == 'F'
					_sGrpTrib := "005"
				Else
					If _aFornece[_x, 5] == 'J'
						_sGrpTrib := "007"
					EndIf
				EndIf

				dbselectarea("SA2")
				dbsetorder(1)
				dbseek(xFilial("SA2") + _aFornece[_x,1] + _aFornece[_x,2])
				If Found()
					_sGrpTribOld := _aFornece[_x,4]
					If alltrim(_sGrpTribOld) <> alltrim(_sGrpTrib) .and. !empty(_sGrpTrib)
						reclock("SA2", .F.)
							SA2->A2_GRPTRIB := _sGrpTrib
						MsUnLock()

						_oEvento := ClsEvent():New ()
						_oEvento:Alias   = 'SA2'
						_oEvento:Texto   = "Alteracao no campo <A2_GRPTRIB> de " + _sGrpTribOld + " para " + _sGrpTrib
						_oEvento:CodEven = "SA2001"
						_oEvento:Fornece = alltrim(_aFornece[_x,1])
						_oEvento:LojaFor = alltrim(_aFornece[_x,2])
						_oEvento:Grava()
					EndIf
				EndIf
			EndIf
		endif
	Next

	//    u_log("Clientes Associados")
	U_Log2 ('info', '[' + procname () + ']Clientes Associados')

	_sGrpTrib := ""
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   SA1.A1_COD "
	_oSQL:_sQuery += "    ,SA1.A1_LOJA "
	_oSQL:_sQuery += "    ,SA1.A1_NOME "
	_oSQL:_sQuery += "    ,SA1.A1_GRPTRIB "
	_oSQL:_sQuery += "    ,SA1.A1_PESSOA "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("AI0") + " AI0 "
	_oSQL:_sQuery += " 	ON AI0.AI0_CODCLI    = SA1.A1_COD "
	_oSQL:_sQuery += " 		AND AI0.AI0_LOJA = SA1.A1_LOJA "
	_oSQL:_sQuery += " 		AND AI0.AI0_ASSOCI IN ('I', 'A') "
	_oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = '' "
	u_log(_oSQL:_sQuery)
	_aCliente := aclone (_oSQL:Qry2Array (.f., .f.))

	For _x:=1 to Len(_aCliente)

		// Atualiza log a cada 100 registros para nao ficar muito lento
		if _x % 100 == 0
			U_Log2 ('debug', '[' + procname () + ']Verificando clientes (' + cvaltochar (_x) + ' de ' + cvaltochar (len (_aCliente)) + ')')
		endif

		If _aCliente[_x, 5] == 'F'
			_sGrpTrib := "005"
		Else
			If _aCliente[_x, 5] == 'J'
				_sGrpTrib := "007"
			EndIf
		EndIf

		dbselectarea("SA1")
		dbsetorder(1)
		dbseek(xFilial("SA1") + _aCliente[_x,1] + _aCliente[_x,2])
		If Found()
			_sGrpTribOld := _aCliente[_x,4]
			If alltrim(_sGrpTribOld) <> alltrim(_sGrpTrib) .and.  !empty(_sGrpTrib)
				reclock("SA1", .F.)
					SA1->A1_GRPTRIB := _sGrpTrib
				MsUnLock()

				_oEvento := ClsEvent():New ()
				_oEvento:Alias   = 'SA1'
				_oEvento:Texto   = "Alteracao no campo <A1_GRPTRIB> de " + _sGrpTribOld + " para " + _sGrpTrib
				_oEvento:CodEven = "SA1006"
				_oEvento:Cliente = alltrim(_aCliente[_x,1])
				_oEvento:LojaCli = alltrim(_aCliente[_x,2])
				_oEvento:Grava()
			EndIf
		EndIf
	Next
Return .T.
