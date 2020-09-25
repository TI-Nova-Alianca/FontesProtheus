// Programa: MT110Grv
// Autor:    Robert Koch
// Data:     29/12/2008
// Funcao:   PE apos gravacao / exclusao da solicitacao de compra.
//           Criado inicialmente para tratamento de campo memo.
//
// Historico de alteracoes:
// 14/11/2016 - Robert - Procura evitar casos de linhas deletadas no aCols.
//

// --------------------------------------------------------------------------
user function mt110grv ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	
	// Tratamento para campo 'memo' criado na solicitacao de compras
	_TrataMemo ()

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return



// --------------------------------------------------------------------------
static function _TrataMemo ()
	local _sMsg := ""

	if GDFieldPos ("C1_VACODM1") == 0
		_sMsg = "Para que o campo de detalhes possa ser gravado, o campo 'C1_VACODM1' devera' constar como 'usado' no dicionario de dados."
		u_help (_sMsg)
		U_AvisaTI ("Problema gravacao campo MEMO no SC1: " + _sMsg)
	else
		CursorWait ()
		N = ascan (aCols, {|_aVal| _aVal [GDFieldPos ("C1_ITEM")] == sc1 -> c1_item})
		if N > 0  // Para evitar casos de linhas deletadas no aCols
			if inclui .and. !GDDeleted () .and. !empty (GDFieldGet ("C1_VADETAL"))  // Inclusao de SC e usuario informou memo
				msmm (,,,GDFieldGet ("C1_VADETAL"), 1,,,"SC1","C1_VACODM1")
			elseif altera  // Alteracao de SC
				if !GDDeleted ()  // Linha alterada
					if !empty (GDFieldGet ("C1_VADETAL"))  // Tem informacao no campo memo.
						if empty (GDFieldGet ("C1_VACODM1"))  // Antes nao tinha nada no campo memo.
							msmm (,,,GDFieldGet ("C1_VADETAL"), 1,,,"SC1","C1_VACODM1")
						else  // Usuario alterou o memo
							msmm (GDFieldGet ("C1_VACODM1"),,,GDFieldGet ("C1_VADETAL"), 1,,,"SC1","C1_VACODM1")
						endif
					else  // Campo memo estah vazio
						if ! empty (GDFieldGet ("C1_VACODM1")) // Usuario deletou o memo
							msmm (GDFieldGet ("C1_VACODM1"),,,,2,,,"SC1","C1_VACODM1")
						endif
					endif
				else  // Linha excluida
					if !empty (GDFieldGet ("C1_VACODM1"))
						msmm (GDFieldGet ("C1_VACODM1"),,,,2,,,"SC1","C1_VACODM1")
					endif
				endif
			else
				if !empty (GDFieldGet ("C1_VACODM1"))  // Exclusao de SC e a linha tinha memo
					msmm (GDFieldGet ("C1_VACODM1"),,,,2,,,"SC1","C1_VACODM1")
				endif
			endif
		endif
		CursorArrow ()
	endif
return
