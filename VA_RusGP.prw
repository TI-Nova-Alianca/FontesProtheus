// Programa...: VA_RusGP
// Autor......: Robert Koch
// Data.......: 07/01/2021
// Descricao..: Define em qual grupo de pagamento de safra as uvas devem ser enquadradas.
//
// Historico de alteracoes:
// 08/01/2021 - Robert - Uvas niagara, concord e 'concord clone 30' passadas do grupo C para A
// 16/02/2021 - Robert - Passa a consistir a safra para definir os grupos de pagamento (GLPI 9420)
// 10/01/2023 - Robert - Ajustes para safra 2023 (a principio, mesmos grupos do ano passado)
//

// --------------------------------------------------------------------------
User Function VA_RusGP (_sSafra, _sVaried, _sConduc)
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
	local _sRetGrpPg := ''

	// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
	if type ("_oCarSaf") != 'O'
		private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
	endif
	if empty (_oCarSaf:Carga)
		u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
		_lContinua = .F.
	endif

	if _lContinua
		
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sVaried, .F.))
			u_help ("Produto '" + _sVaried + "' nao cadastrado.",, .t.)
			_lContinua = .F.
		else
			if sb1 -> b1_grupo != '0400'
				u_help ("Produto '" + _sVaried + "' nao parece ser uva (grupo diferente de 0400)",, .t.)
				_lContinua = .F.
			endif
		endif
	endif

	// Segue politicas definidas para cada safra e que devem ser consistentes com o que consta
	// na tag <regraPagamento> retornada pelo metodo ClsAssoc:FechSafra()
	// Possivelmente seja necessario dar manutencao a cada nova safra...
	if _lContinua
		do case
		case _sSafra == '2020'
			// Nao tenho muitas opcoes alem de fazer alguns testes com codigos fixos...
			if alltrim (sb1 -> b1_cod) $ '9925'  // bordo
				_sRetGrpPg = 'A'
			elseif alltrim (sb1 -> b1_codpai) $ '9925'  // Alguma possivel nova variacao de bordo
				_sRetGrpPg = 'A'
			elseif sb1 -> b1_vaorgan == 'O'  // Organicas
				_sRetGrpPg = 'A'
			elseif sb1 -> b1_vattr == 'S'  // Tintorias
				_sRetGrpPg = 'B'
			elseif sb1 -> b1_varuva == 'F'
				if _sConduc == 'E'  // Viniferas em espaldeira
					_sRetGrpPg = 'B'
				elseif _sConduc == 'L'
					_sRetGrpPg = 'C'
				else
					u_help (procname () + ": Sistema de conducao '" + _sConduc + "' invalido.",, .t.)
					_lContinua = .F.
				endif
			else
				_sRetGrpPg = 'C'
			endif

		case _sSafra == '2021' .or. _sSafra == '2022' .or. _sSafra == '2023'
			// Nao tenho muitas opcoes alem de fazer alguns testes com codigos fixos...
			if alltrim (sb1 -> b1_cod) $ '9925/9904/9922/9855'  // bordo, niagara, concord
				_sRetGrpPg = 'A'
			elseif alltrim (sb1 -> b1_codpai) $ '9925/9904/9922/9855'  // Alguma possivel nova variacao de bordo, niagara, concord
				_sRetGrpPg = 'A'
			elseif sb1 -> b1_vaorgan == 'O'  // Organicas
				_sRetGrpPg = 'A'
			elseif sb1 -> b1_vattr == 'S'  // Tintorias
				_sRetGrpPg = 'B'
			elseif sb1 -> b1_varuva == 'F'
				if _sConduc == 'E'  // Viniferas em espaldeira
					_sRetGrpPg = 'B'
				elseif _sConduc == 'L'
					_sRetGrpPg = 'C'
				else
					u_help (procname () + ": Sistema de conducao '" + _sConduc + "' invalido.",, .t.)
					_lContinua = .F.
				endif
			else
				_sRetGrpPg = 'C'
			endif

		otherwise
			u_help ("Sem definicao de regras para grupos de pagamento para a safra '" + _sSafra + "'.",, .t.)
		endcase
	endif

	U_ML_SRArea (_aAreaAnt)
return _sRetGrpPg
