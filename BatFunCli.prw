// Programa...: BatFunCli
// Autor......: Cláudia Lionço
// Data.......: 01/04/2021
// Descricao..: Bat para troca de status funcionário/nao func. conforme situação
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Bat para troca de status funcionário/nao func. conforme situação
// #PalavasChave      #venda_funcionarios #cliente_funcionario 
// #TabelasPrincipais #AI0
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 04/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//                     - Passa a testar se tem linked server para o Metadados (GLPI 15031)
//

//#Include "Protheus.ch"
//#include 'parmtype.ch'
//#Include "totvs.ch"

// --------------------------------------------------------------------------
User Function BatFunCli ()
    Local _aFunc    := {}
    Local _aAI0     := {}
    Local _aCliente := {}
    Local _x        := 0
    Local _i        := 0
    Local _z        := 0
	local _lContinua := .T.
	local _sLkSrvRH  := U_LkServer ("METADADOS")

	if _lContinua .and. empty (_sLkSrvRH)
		u_help ("Impossivel continuar sem definicao de linked server para acesso ao Metadados.",, .t.)
		_lContinua = .F.
	endif

    // Busca funcionários
	if _lContinua
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT ""
		_oSQL:_sQuery += " 	    CPF"
		_oSQL:_sQuery += "     ,SITUACAO"
		_oSQL:_sQuery += " FROM " + _sLkSrvRH + ".VA_VFUNCIONARIOS"
		_oSQL:_sQuery += " ORDER BY NOME"
		_oSQL:Log ('[' + procname () + ']')
		_aFunc := aclone (_oSQL:Qry2Array (.f., .f.)) 

		For _x:=1 to Len(_aFunc)
			_sCPF      := alltrim(_aFunc[_x, 1])
			_sSituacao := alltrim(_aFunc[_x, 2])

			_oSQL:= ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT"
			_oSQL:_sQuery += " 		 A1_COD"
			_oSQL:_sQuery += " 		,A1_LOJA"
			_oSQL:_sQuery += " 	FROM SA1010"
			_oSQL:_sQuery += " 	WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery += " 	AND A1_CGC = '" + _sCPF + "'"
			// u_log(_oSQL:_sQuery)
			_aCliente := aclone (_oSQL:Qry2Array (.f., .f.))

			For _i:=1 to Len(_aCliente)
				_sCodCli := _aCliente[_i, 1] 
				_sLoja   := _aCliente[_i, 2] 

				_oSQL:= ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT"
				_oSQL:_sQuery += " 		AI0_CLIFUN"
				_oSQL:_sQuery += " FROM AI0010"
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery += " AND AI0_CODCLI = '"+ _sCodCli +"'"
				_oSQL:_sQuery += " AND AI0_LOJA   = '"+ _sLoja   +"'"
				// u_log(_oSQL:_sQuery)
				_aAI0 := aclone (_oSQL:Qry2Array (.f., .f.))

				If Len(_aAI0) > 0
					For _z:=1 to Len(_aAI0)
						_sCliFun := _aAI0[_z, 1]

						If Len(_aAI0) > 0
							dbSelectArea("AI0")
							dbSetOrder(1) // filial + cliente + loja
							dbGoTop()
	
							Do Case 
								Case _sSituacao == '1' .and. _sCliFun == '2' // usuario ativo e cliente não funcionário
									If dbSeek(xFilial("AI0") + _sCodCli + _sLoja )  
										Reclock("AI0",.F.)
											AI0->AI0_CLIFUN := '1' // eh funcionario
										AI0->(MsUnlock())

									//   u_log ("ALTERACAO - Cliente " + _sCodCli+"/"+_sLoja + " alterado para funcionario! CPF:" + _sCPF)
										U_Log2 ('aviso', '[' + procname () + "]ALTERACAO - Cliente " + _sCodCli+"/"+_sLoja + " alterado para funcionario! CPF:" + _sCPF)

										_oEvento := ClsEvent():New ()
										_oEvento:Alias   = 'AI0'
										_oEvento:Texto   = "Alteracao no campo <AI0_CLIFUN> para 1 (funcionario) "
										_oEvento:CodEven = "AI0002"
										_oEvento:Cliente = _sCodCli
										_oEvento:LojaCli = _sLoja
										_oEvento:Grava()
									EndIf
								Case _sSituacao != '1' .and. _sCliFun == '1' // usuário nao ativo e cliente funcionario
									If dbSeek(xFilial("AI0") + _sCodCli + _sLoja )  
										Reclock("AI0",.F.)
										AI0->AI0_CLIFUN := '2' // nao eh funcionario
										AI0->(MsUnlock())

									//  u_log ("ALTERACAO - Cliente " + _sCodCli+"/"+_sLoja + " não eh mais funcionario! CPF:" + _sCPF)
										U_Log2 ('aviso', '[' + procname () + "]ALTERACAO - Cliente " + _sCodCli+"/"+_sLoja + " não eh mais funcionario! CPF:" + _sCPF)

										_oEvento := ClsEvent():New ()
										_oEvento:Alias   = 'AI0'
										_oEvento:Texto   = "Alteracao no campo <AI0_CLIFUN> para 2 (nao e funcionario)"
										_oEvento:CodEven = "AI0002"
										_oEvento:Cliente = _sCodCli
										_oEvento:LojaCli = _sLoja
										_oEvento:Grava()
									EndIf
							EndCase
						EndIf
					Next
				Else
					If _sSituacao == '1' // se usuário ativo sem tabela AI0 -> crio ela como funcionario
						// Grava registro AI0
						Reclock("AI0",.T.)
							AI0->AI0_CODCLI := _sCodCli
							AI0->AI0_LOJA   := _sLoja
							AI0->AI0_CLIFUN := '1'
						AI0->(MsUnlock())

					//  u_log ("INCLUSAO - Cliente " + _sCodCli+"/"+_sLoja + " é funcionario! CPF:" + _sCPF)
						U_Log2 ('aviso', '[' + procname () + "]INCLUSAO - Cliente " + _sCodCli+"/"+_sLoja + " é funcionario! CPF:" + _sCPF)
					Else
						// Grava registro AI0
						Reclock("AI0",.T.)
							AI0->AI0_CODCLI := _sCodCli
							AI0->AI0_LOJA   := _sLoja
							AI0->AI0_CLIFUN := '2'
						AI0->(MsUnlock())

					//  u_log ("INCLUSAO - Cliente " + _sCodCli+"/"+_sLoja + " NAO eh funcionario! CPF:" + _sCPF)
						U_Log2 ('aviso', '[' + procname () + "]INCLUSAO - Cliente " + _sCodCli+"/"+_sLoja + " NAO eh funcionario! CPF:" + _sCPF)
					EndIf
				EndIf
			Next
		Next
	endif

Return _lContinua
