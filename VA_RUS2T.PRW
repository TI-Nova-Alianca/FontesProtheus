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
	local _nCpoSZE   := 0

	u_Log2 ('info', 'Iniciando ' + procname ())

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
			if type ("M->" + sze -> (fieldname (_nCpoSZE))) != 'U'
				_sValSZE = GetSX3Cache (sze -> (fieldname (_nCpoSZE)), "X3_VALID")
				If !Empty (_sValSZE)
					_lRet := &(_sValSZE)
				Endif
				If _lRet
					_sValSZE := GetSX3Cache (sze -> (fieldname (_nCpoSZE)), "X3_VLDUSER" )
					if !Empty(_sValSZE)
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
			u_help ("Peso tara e peso bruto devem ser informados",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. altera .and. m->ze_pesotar >= m->ze_pesobru
			u_help ("Peso tara deve ser menor que o peso bruto",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_nfprod) .and. m->ze_aglutin == 'D'
			u_help ("NF produtor deve ser informada",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_placa)
			u_help ("Placa do veiculo deve ser informada",, .T.)
			_lRet = .F.
		endif
		if _lRet .and. empty (m->ze_coop)
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

	// Em caso de carga compartilhada (mais de um fornecedor no mesmo caminhao), preciso validar as demais cargas.
	if _lRet .and. ! empty (m->ze_cargaC1)
		_lRet = _ValCompar (m->ze_cargaC1)
	endif
	if _lRet .and. ! empty (m->ze_cargaC2)
		_lRet = _ValCompar (m->ze_cargaC2)
	endif

	N = _nBkpN
return _lRet



// --------------------------------------------------------------------------
// Valida 'carga compartilhada'.
// Em caso de mais de um fornecedor no mesmo caminhao, preciso validar as demais cargas.
static function _ValCompar (_sCarComp)
	local _aAreaSZE  := {}
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sCarUsada := ''

	U_Log2 ('debug', '[' + procname () + ']Validando carga compartilhada1: ' + _sCarComp)
	_aAreaSZE := sze -> (getarea ())
	sze -> (dbsetorder (1))  // filial + safra + carga + item
	if _lRet .and. ! sze -> (dbseek (xfilial ("SZE") + m->ze_safra + _sCarComp, .F.))
		u_help ("Carga compartilhada '" + _sCarComp + "' nao localizada.",, .t.)
		_lRet = .F.
	endif
	if _lRet .and. ! empty (sze -> ze_status $ 'C/D')
		U_help ("Carga compartilhada '" + _sCarComp + "' foi cancelada ou redirecionada para outra filial.",, .t.)
		_lRet = .f.
	endif
	if _lRet .and. ! empty (sze -> ze_nfger)
		_lRet = U_MsgNoYes ("Carga compartilhada '" + _sCarComp + "' ja gerou contranota. Quando compartilhadas, as cargas devem ser geradas em sequencia para poder, posteriormente, compartilhar informacoes como grau, precos, etc. Confirma assim mesmo?")
	endif
	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT ZE_CARGA + ' de ' + RTRIM (ZE_NOMASSO) + ' em ' + dbo.VA_DTOC (ZE_DATA)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZE") + " SZE"
		_oSQL:_sQuery += " WHERE SZE.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SZE.ZE_FILIAL   = '" + xfilial ("SZE") + "'"
		_oSQL:_sQuery +=   " AND SZE.ZE_SAFRA    = '" + m->ze_safra + "'"
		_oSQL:_sQuery +=   " AND SZE.ZE_CARGA   != '" + m->ze_carga + "'"
		_oSQL:_sQuery +=   " AND SZE.ZE_STATUS  != 'C'"
		_oSQL:_sQuery +=   " AND (SZE.ZE_CARGAC1 = '" + _sCarComp + "' OR SZE.ZE_CARGAC2 = '" + _sCarComp + "')"
		_oSQL:Log ()
		_sCarUsada = _oSQL:RetQry (1, .f.)
		if ! empty (_sCarUsada)
			u_help ("A carga '" + _sCarComp + "' ja foi informada como 'compartilhada' na carga " + _sCarUsada,, .t.)
			_lRet = .F.
		endif
	endif
	sze -> (restarea (_aAreaSZE))
return _lRet
