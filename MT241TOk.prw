// Programa:  MT241TOk
// Autor:     Robert Koch
// Data:      24/09/2016
// Descricao: P.E. 'Tudo OK' na tela de movimentos internos mod.II.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida a tela inteira de movimentacoes internas modelo II (multiplas).
// #PalavasChave      #validacao #movimentacoes_internas #modelo_II #tudo_ok
// #TabelasPrincipais #SD3
// #Modulos           #EST

// Historico de alteracoes:
// 14/03/2018 - Robert  - Data nao pode mais ser diferente de date().
// 02/04/2018 - Robert  - Movimentacao retroativa habilitada para o grupo 084.
// 28/01/2020 - Cl�udia - Inclus�o de valida��o de OP, conforme GLPI 7401
// 03/09/2020 - Robert  - Liberado movimentar retroativo quando tipo MO (para quando nao havia MO em alguma OP)
//
// -----------------------------------------------------------------------------------
user function MT241TOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _sMsg     := ""
	local _x        := 0
	local _nPos     := 0

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
			If ! GDDeleted (_x) .and. fBuscaCpo ("SB1", 1, xfilial ("SB1") + aCols[_x,_nPos], 'B1_TIPO') != 'MO'  // Para nao de obra pode movimentar retroativo.
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
			u_help ("Este tipo de movimento foi parametrizado para exigir a inclus�o do n�mero da OP.",, .t.)
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet