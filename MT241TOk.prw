// Programa.: MT241TOk
// Autor....: Robert Koch
// Data.....: 24/09/2016
// Descricao: P.E. 'Tudo OK' na tela de movimentos internos mod.II.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida a tela inteira de movimentacoes internas modelo II (multiplas).
// #PalavasChave      #validacao #movimentacoes_internas #modelo_II #tudo_ok
// #TabelasPrincipais #SD3
// #Modulos           #EST
//
// Historico de alteracoes:
// 14/03/2018 - Robert  - Data nao pode mais ser diferente de date().
// 02/04/2018 - Robert  - Movimentacao retroativa habilitada para o grupo 084.
// 28/01/2020 - Cláudia - Inclusão de validação de OP, conforme GLPI 7401
// 03/09/2020 - Robert  - Liberado movimentar retroativo quando tipo MO 
//                        (para quando nao havia MO em alguma OP)
// 03/02/2021 - Cláudia - Vinculação Itens C ao movimento 573 - GLPI: 9163
// 13/04/2021 - Claudia - Validação Centro de Custo X Conta Contábil - GLPI: 9120
// 15/06/2021 - Claudia - Incluida novas validações C.custo X C.contabil. GLPI: 10224
// 15/10/2021 - Claudia - Validação MC ao movimento 573. GLPI: 10765
// 25/07/2022 - Robert  - Liberados TMs 008/510/573 para itens tipo MC
// 18/04/2023 - Robert  - Liberados TMs 005/512 para itens tipo MC (ajustes valores infimos que estao no SB9)
// 05/05/2023 - Robert  - Nao mostrar msg. de data retroativa, quando executado a partir do programa U_ESXEST01 (GLPI 12158)
// 05/07/2023 - Robert  - Nao mostrar msg. de data retroativa, quando executado a partir do programa U_ESXEST02
//

// ------------------------------------------------------------------------------------------
user function MT241TOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _sMsg     := ""
	local _x        := 0
	local _nPos     := 0
	local _sTM_MC   := '008/510/573/005/512'

	if empty (cCC)
		sf5 -> (dbsetorder (1))  // F5_FILIAL+F5_CODIGO
		if sf5 -> (dbseek (xfilial ("SF5") + cTM, .F.)) .and. sf5 -> f5_vaExiCC == 'S'
			u_help ("Este tipo de movimento foi parametrizado para exigir centro de custo.",, .t.)
			_lRet = .F.
		endif
	else
		if left (cCC, 2) != cFilAnt
			u_help ("Centro de custo nao pertence a esta filial.",, .t.)
			_lRet = .F.
		endif
	endif

	// Data retroativa: valida linha a linha por que existem produtos para os quais eh permitido.
	if _lRet .and. (da241data != date () .or. dDataBase != date ())
		_nPos := aScan(aHeader,{|x| Alltrim(x[2]) == "D3_COD"})
		for _x:=1 to len(aCols)
//			If ! GDDeleted (_x) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + aCols[_x,_nPos], 'B1_TIPO') != 'MO'  // Para nao de obra pode movimentar retroativo.
//			If ! GDDeleted (_x) .and. ! IsInCallStack ('U_ESXEST01') .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + aCols[_x,_nPos], 'B1_TIPO') != 'MO'  // Para nao de obra pode movimentar retroativo.
			If ! GDDeleted (_x) .and. ! IsInCallStack ('U_ESXEST01') .and. ! IsInCallStack ('U_ESXEST02') .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + aCols[_x,_nPos], 'B1_TIPO') != 'MO'  // Para nao de obra pode movimentar retroativo.
				_sMsg = "Linha " + cvaltochar (_x) + ": Alteracao de data da movimentacao ou data base do sistema: bloqueado para esta rotina x tipo de produto."
				_lRet = .F.
				exit
			EndIf
		next
		if _lRet = .F.
			if U_ZZUVL ('084', __cUserId, .F.)
				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
			else
				u_help (_sMsg,, .t.)
				_lRet = .F.
			endif
		endif
	endif
	
	sf5 -> (dbsetorder (1))  // F5_FILIAL+F5_CODIGO
	if sf5 -> (dbseek (xfilial ("SF5") + cTM, .F.)) .and. sf5 -> f5_vainfop == 'S' 
		_nPos := aScan(aHeader,{|x| Alltrim(x[2]) == "D3_OP" })
		for _x:=1 to len(aCols)
	        If empty (aCols[_x,_nPos])
	        	_lRet = .F.
	        EndIf
		next
		if _lRet = .F.
			u_help ("Este tipo de movimento foi parametrizado para exigir a inclusão do número da OP.",, .t.)
		endif
	endif

	// movimentações de produtos MC apenas pela TM 573
	if _lRet
		_nPos := aScan(aHeader,{|x| Alltrim(x[2]) == "D3_COD" }) // produto

		for _x:=1 to len(aCols)
			_sTipo := fbuscacpo("SB1",1,xfilial("SB1") + aCols[_x,_nPos],"B1_TIPO")

//			if alltrim(cTM) != '573' .and. _sTipo $ ('MC') .and. !GDDeleted (_x)
			if ! alltrim(cTM) $ _sTM_MC .and. _sTipo $ ('MC') .and. !GDDeleted (_x)
				_lRet = .F.
				u_help ("Itens tipo MC só podem ser movimentados com movimentos " + _sTM_MC,, .t.)
			EndIf
		next
	endif 

	if _lRet 
		_nPos := aScan(aHeader,{|x| Alltrim(x[2]) == "D3_COD" })
		for _x:=1 to len(aCols)
			_sProdC := RIGHT(alltrim(aCols[_x,_nPos]), 1) 
			_sTipo  := fbuscacpo("SB1",1,xfilial("SB1")+aCols[_x,_nPos],"B1_TIPO")
//			if alltrim(_sProdC) == 'C' .and. alltrim(CTM) != '573' .and. _sTipo $ ('MM/BN/MC/CL') .and. !GDDeleted (_x)
			if alltrim(_sProdC) == 'C' .and. ! alltrim(CTM) != _sTM_MC .and. _sTipo $ ('MM/BN/MC/CL') .and. !GDDeleted (_x)
				_lRet = .F.
				u_help ("Itens da manutenção com final C só podem ser movimentados com movimento 573.",, .t.)
			EndIf
		next
	endIf

	// realiza a validação de amarração centro de custo x conta contábil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as validações
		_nPos := aScan(aHeader,{|x| Alltrim(x[2]) == "D3_CONTA" })

		for _x := 1 to Len(aCols)
	
			_sConta := aCols[_x,_nPos]
			_sCC    := cCC

			if empty(_sConta)
				u_help("Conta contábil é obrigatória!")
				_lRet = .F.
			endif

			_sPConta := SubStr( _sConta, 1, 1 )
			if _lRet .and. (_sPConta == '4' .or. _sPConta == '7') .and. empty(_sCC)  // obrigatorio CC
				u_help("Contas iniciadas em 4 e 7 é obrigatório inserir o centro de custo!")
				_lRet = .F.
			endif

			if _lRet .and. (_sPConta == '1' .or. _sPConta == '2') .and. !empty(_sCC) 
				u_help("Conta contábil iniciada em 1, não é necessário a informação do centro de custo! Retire o Centro de custo.")
				_lRet = .F.
			endif
		next	
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet
