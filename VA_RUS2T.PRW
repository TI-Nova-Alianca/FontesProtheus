// Programa...: VA_RUS2T
// Autor......: Robert Koch
// Data.......: 03/01/2019
// Descricao..: Validacao 'tudo OK' da tela VA_RUS2 (recebimento safra)
//              Desmembrada do programa VA_RUS2.PRW
//
// Historico de alteracoes:
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function VA_RUS2T (_nOpc)
	local _lRet      := .T.
	local _nPesoTot  := 0
	local _nBkpN     := N
	local _nLinha    := 0
//	local _sSelect   := ""
//	local _sBusca    := ""       
//	local _sPerg     := 'S'
//	local _oSQL      := NIL
//	local _aRetAge   := {}
	local _nCpoSZE   := 0

	u_logIni ()

	if (cEmpAnt + cFilAnt == '0101' .and. ! m->ze_local $ 'LB/QL/GS/GB') ;
		.or. (cEmpAnt + cFilAnt == '0103' .and. ! m->ze_local $ 'LV') ;
		.or. (cEmpAnt + cFilAnt == '0107' .and. ! m->ze_local $ 'JC') ;
		.or. (cEmpAnt + cFilAnt == '0109' .and. ! m->ze_local $ 'SP') ;
		.or. (cEmpAnt + cFilAnt == '0110' .and. ! m->ze_local $ 'SA') ;
		.or. (cEmpAnt + cFilAnt == '0111' .and. ! m->ze_local $ 'NP') ;
		.or. (cEmpAnt + cFilAnt == '0112' .and. ! m->ze_local $ 'PB/AP') ;
		.or. (cEmpAnt + cFilAnt == '0113' .and. ! m->ze_local $ 'AL')
		u_help ("Balanca invalida para esta filial ou filial nao autorizada a receber safra.",, .t.)
		_lRet = .F.
	endif

	// Em caso de inclusao via web service, tenta validar todos os campos.
	if _lRet .and. inclui .and. IsInCallStack ("U_GERASZE")
		for _nCpoSZE = 1 to sze -> (fcount ())
//			u_log ('verificando se preciso validar campo', sze -> (fieldname (_nCpoSZE)))
			if type ("M->" + sze -> (fieldname (_nCpoSZE))) != 'U'
//				u_log ('variavel M-> existe:', &('M->' + sze -> (fieldname (_nCpoSZE))))
				_sValSZE = GetSX3Cache (sze -> (fieldname (_nCpoSZE)), "X3_VALID")
				If !Empty (_sValSZE)
//					u_log ('valid:', _sValSZE)
					_lRet := &(_sValSZE)
				Endif
				If _lRet
					_sValSZE := GetSX3Cache (sze -> (fieldname (_nCpoSZE)), "X3_VLDUSER" )
					if !Empty(_sValSZE)
//						u_log ('vlduser:', _sValSZE)
						_lRet := &(_sValSZE)
					endif
				Endif
			endif
		next
	endif

	if _lRet .and. (inclui .or. altera)  // Na exclusao nao precisa validar nada.

		// Verifica linha OK para todas as linhas, pois o gatilho de distribuicao de quantidade
		// pode ter deixado alguma das linhas com quantidade zerada.
		if _lRet .and. ! GDDeleted ()
			_nBkpN = N
			for _nLinha = 1 to len (aCols)
				N = _nLinha
				_lRet = U_VA_RUS2L ()
				if ! _lRet
					exit
				endif
			next
			N = _nBkpN
		endif

		if _lRet .and. altera .and. _nOpc == 4 .and. (empty (m->ze_pesotar) .or. empty (m->ze_pesobru))
			//if type ('_sErros') == 'C' ; _sErros += 'Peso tara e peso bruto devem ser informados.' ; endif
			u_help ("Peso tara e peso bruto devem ser informados",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. altera .and. m->ze_pesotar >= m->ze_pesobru
			//if type ('_sErros') == 'C' ; _sErros += 'Peso tara deve ser menor que o peso bruto.' ; endif
			u_help ("Peso tara deve ser menor que o peso bruto",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_nfprod) .and. m->ze_aglutin == 'D'
			//if type ('_sErros') == 'C' ; _sErros += 'NF produtor deve ser informada' ; endif
			u_help ("NF produtor deve ser informada",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_placa)
			//if type ('_sErros') == 'C' ; _sErros += 'Placa do veiculo deve ser informada.' ; endif
			u_help ("Placa do veiculo deve ser informada",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_coop)
			//if type ('_sErros') == 'C' ; _sErros += 'Cooperativa deve ser informada.' ; endif
			u_help ("Cooperativa deve ser informada",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. altera
			_nPesoTot = 0
			for _nLinha = 1 to len (aCols)
				_nPesoTot += iif (! GDDeleted (_nLinha), GDFieldGet ("ZF_PESO", _nLinha), 0)
			next
			if _nPesoTot != m->ze_pesobru - m->ze_pesotar
				u_help ("Peso liquido total (" + cvaltochar (m->ze_pesobru - m->ze_pesotar) + ") nao confere com a soma dos pesos dos itens (" + cvaltochar (_nPesoTot) + ").",, .T.)
				_lRet = .F.
			endif
		endif
	endif

	if _lRet .and. (inclui .or. altera) .and. cEmpAnt + cFilAnt $ '0101/0107' .and. empty (m->ZE_LOCDESC)
		//if type ('_sErros') == 'C' ; _sErros += 'Informe tombador para descarga.' ; endif
		u_help ("Informe tombador para descarga.",, .T.)
		_lRet = .F.
	endif


	// Tratamento para quando consta variedade nao prevista no cadastro viticola. Nao tenho como saber quantos e nem quais
	// sao os casos (a agenda apenas diz que houve algum caso), entao vou me contentar em ter pelo menos uma linha com o campo preenchido.
	if _lRet .and. m->ze_VarNVit == 'S'
		_lRet = .F.
		for _nLinha = 1 to len (aCols)
			if ! GDDeleted (_nLinha)
				if ! empty (GDFieldGet ("ZF_PRREAL", _nLinha))
					_lRet = .T.
					exit
				endif
			endif
		next
		if ! _lRet
			u_help ("Durante a inspecao desta carga foi apontado que existe variedade nao prevista no cadastro viticola. Sendo assim, o campo '" + alltrim (RetTitle ("ZF_PRREAL")) + "' deve ser informado para manter um historico de qual era a variedade efetivamente recebida.",, .T.)
		endif
	endif
 

	// Verifica situacao das inspecoes no NaWeb.
	if _lRet .and. _nOpc == 4
		// Por enquanto apenas me interessa saber se apareceu alguma variedade nao prevista.
		// Nao tenho como saber quantas sao, entao vou me contentar em ter mais de uma linha de itens.
		if len (aCols) < 2 .or. (len (aCols) >= 2 .and. GDDeleted (2))  // Segunda linha nao deletada

			if left (_aRusInsp [.InspecoesSafraMisturaNoTombador], 1) == 'S'
				u_help ("Inspecao de tombador indica que tem mistura de variedades (" + alltrim (_aRusInsp [.InspecoesSafraMisturaNoTombador]) + "), mas consta apenas uma linha na carga.")
				if U_ZZUVL ('045', __cUserID, .F.)//, cEmpAnt, cFilAnt)
					_lRet = U_MsgNoYes ("A T E N C A O: Confirma a finalizacao da segunda pesagem mesmo com a inspecao e tombador indicando falta de alguma variedade?")
					_oEvento := ClsEvent ():New ()
					_oEvento:Alias   = 'SZE'
					_oEvento:Texto   = 'Recebimento da carga ' + sze -> ze_carga + ' com provavel mistura de variedades'
					_oEvento:CodEven = 'SZE003'
					_oEvento:Fornece = sze -> ze_assoc
					_oEvento:LojaFor = sze -> ze_lojasso
					_oEvento:Recno   = sze -> (recno ())
					_oEvento:CodAlias = sze -> ze_safra + sze -> ze_carga
					_oEvento:Grava ()
				else
					u_help ("Verifique no sistema de agenda / inspecao se esta carga realmente teve misturas. Para prosseguir com a pesagem assim mesmo, deve ser feito com algum usuario responsavel pelos cadastros de safra (" + U_ZZULD ('045')[1] + ").",, .T.)
					_lRet = .F.
				endif
			endif
		endif
	endif

	N = _nBkpN
	u_logFim ()
return _lRet
