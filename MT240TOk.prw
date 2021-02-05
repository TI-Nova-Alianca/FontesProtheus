// Programa:  

// Autor:     Robert Koch
// Data:      24/09/2016
// Descricao: P.E. 'Tudo OK' na tela de movimentos internos.
//
// Historico de alteracoes:
// 14/03/2018 - Robert  - dDataBase nao pode mais ser diferente de date().
// 02/04/2018 - Robert  - Movimentacao retroativa habilitada para o grupo 084.
// 28/01/2020 - Cláudia - Inclusão de validação de OP, conforme GLPI 7401
// 29/05/2020 - Robert  - Liberada gravacao mov.retroativo para programa U_ESXEST01.
// 03/02/2021 - Cláudia - Vinculação Itens C ao movimento 573 - GLPI: 9163
//
// --------------------------------------------------------------------------
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
		u_help ("Este tipo de movimento foi parametrizado para exigir a inclusão do número da OP.")
		_lRet = .F.
	endif

	if _lRet  
		_ProdC := RIGHT(alltrim(m->d3_cod), 1)  
		_sTipo  := fbuscacpo("SB1",1,xfilial("SB1") + m->d3_cod,"B1_TIPO")

		if alltrim(_ProdC) == 'C' .and. alltrim(m->d3_tm) != '573' .and. _sTipo $ ('MM/BN/MC/CL') 
			u_help ("Itens da manutenção com final C só podem ser movimentados com movimento 573.")
			_lRet = .F.
		endif
	endIf

	U_ML_SRArea (_aAreaAnt)
return _lRet
