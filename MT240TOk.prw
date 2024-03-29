// Programa.: MT240TOk
// Autor....: Robert Koch
// Data.....: 24/09/2016
// Descricao: P.E. 'Tudo OK' na tela de movimentos internos.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. 'Tudo OK' na tela de movimentos internos.
// #PalavasChave      #validacao #movimentacoes_internas #modelo_II #tudo_ok
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
// 14/03/2018 - Robert  - dDataBase nao pode mais ser diferente de date().
// 02/04/2018 - Robert  - Movimentacao retroativa habilitada para o grupo 084.
// 28/01/2020 - Cl�udia - Inclus�o de valida��o de OP, conforme GLPI 7401
// 29/05/2020 - Robert  - Liberada gravacao mov.retroativo para programa U_ESXEST01.
// 03/02/2021 - Cl�udia - Vincula��o Itens C ao movimento 573 - GLPI: 9163
// 13/04/2021 - Claudia - Valida��o Centro de Custo X Conta Cont�bil - GLPI: 9120
// 15/06/2021 - Claudia - Incluida novas valida��es C.custo X C.contabil. GLPI: 10224
// 09/07/2021 - Robert  - Criada chamada da funcao U_ConsEst (GLPI 10464).
// 15/10/2021 - Claudia - Valida��o MC ao movimento 573. GLPI: 10765
// 13/10/2022 - Robert  - Novos parametros funcao U_ConsEst().
//

// -----------------------------------------------------------------------------------------------------
user function MT240TOk ()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()
	
	if empty (m->d3_cc)
		sf5 -> (dbsetorder (1))  // F5_FILIAL+F5_CODIGO
		if sf5 -> (dbseek (xfilial ("SF5") + m->d3_tm, .F.)) .and. sf5 -> f5_vaExiCC == 'S'
			u_help ("Este tipo de movimento foi parametrizado para exigir centro de custo.")
			_lRet = .F.
		endif
	else
		if left (m->d3_cc, 2) != cFilAnt
			u_help ("Centro de custo nao pertence a esta filial.")
			_lRet = .F.
		endif
	endif

	if _lRet .and. dDataBase != date ()
		_sMsg = "Alteracao de data da movimentacao ou data base do sistema: bloqueada para esta rotina."
		if U_ZZUVL ('084', __cUserId, .F.)
			if ! IsInCallStack ("U_ESXEST01")  // Esse prog.sempre grava movtos retroativos.
 				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			endif
		else
			u_help (_sMsg)
			_lRet = .F.
		endif
	endif
	
	sf5 -> (dbsetorder (1))  // F5_FILIAL+F5_CODIGO
	if sf5 -> (dbseek (xfilial ("SF5") + m->d3_tm, .F.)) .and. sf5 -> f5_vainfop == 'S' .and. empty (m->d3_op)
		u_help ("Este tipo de movimento foi parametrizado para exigir a inclus�o do n�mero da OP.")
		_lRet = .F.
	endif

	// movimenta��es de produtos MC apenas pela TM 573
	if _lRet  
		_sTipo  := fbuscacpo("SB1",1,xfilial("SB1") + m->d3_cod,"B1_TIPO")

		if alltrim(m->d3_tm) != '573' .and. _sTipo $ ('MC') 
			u_help ("Itens tipo MC s� podem ser movimentados com movimento 573.",, .t.)
			_lRet = .F.
		endif
	endIf

	if _lRet  
		_ProdC := RIGHT(alltrim(m->d3_cod), 1)  
		_sTipo  := fbuscacpo("SB1",1,xfilial("SB1") + m->d3_cod,"B1_TIPO")

		if alltrim(_ProdC) == 'C' .and. alltrim(m->d3_tm) != '573' .and. _sTipo $ ('MM/BN/MC/CL') 
			u_help ("Itens da manuten��o com final C s� podem ser movimentados com movimento 573.")
			_lRet = .F.
		endif
	endIf

	// realiza a valida��o de amarra��o centro de custo x conta cont�bil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as valida��es
		_sConta := m->d3_conta
		_sCC    := m->d3_cc

		if empty(_sConta)
			u_help("Conta cont�bil � obrigat�ria!")
			_lRet = .F.
		endif

		_sPConta := SubStr( _sConta, 1, 1 )
		if _lRet .and. (_sPConta == '4' .or. _sPConta == '7') .and. empty(_sCC)  // obrigatorio CC
			u_help("Contas iniciadas em 4 e 7 � obrigat�rio inserir o centro de custo!")
			_lRet = .F.
		endif

		if _lRet .and. (_sPConta == '1' .or. _sPConta == '2')  .and. !empty(_sCC)
			u_help("Conta cont�bil iniciada em 1, n�o � necess�rio a informa��o do centro de custo! Retire o Centro de custo.")
			_lRet = .F.
		endif
		// _sConta := U_VA_CUSXCON(m->d3_conta,'1')
		// _sCC    := U_VA_CUSXCON(m->d3_cc,'2')
		// if !empty(m->d3_conta) .and. !empty(m->d3_cc)
		// if !empty(_sConta) .and. !empty(_sCC)
		// 	if alltrim(_sConta) !=alltrim(_sCC)
		// 		u_help ("Divergencia no cadastro de Amarra��o C.Custo X C.Contabil. Grupo C.Custo:" + alltrim(_sCC) + " Grupo C.Contabil:" + alltrim(_sConta))
		// 		_lRet = .F.
		// 	endif
		// endif
		// endif
	endif

	// Verifica se tem alguma mensagem de inconsistencia de estoque.
	if _lRet
		_lRet := U_ConsEstq (xfilial ("SD3"), m->d3_cod, m->d3_local, '*')
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
