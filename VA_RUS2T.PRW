// Programa...: VA_RUS2T
// Autor......: Robert Koch
// Data.......: 03/01/2019
// Descricao..: Validacao 'tudo OK' da tela VA_RUS2 (recebimento safra)
//              Desmembrada do programa VA_RUS2.PRW
//
// Historico de alteracoes:
// 01/02/2023 - Robert - Passa a chamar, tambem, o metodo ClsCarSaf.SegPesTOk()
// 18/11/2023 - Robert - Versao inicial do metodo ClsCarSaf:PodeGravar().
// 20/01/2024 - Robert - Melhorados logs, eliminadas linhas comentariadas.
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function VA_RUS2T (_nOpc, _oCarSaf)
	local _lRet      := .T.
	local _nPesoTot  := 0
	local _nBkpN     := N
	local _nLinha    := 0
	local _nCpoSZE   := 0
	private _sPrefLog  := 'Car.' + iif (inclui, m->ze_carga, sze -> ze_carga)

	//  COM O TEMPO, PRETENDO MIGRAR PARA O METODO ClsCarSaf:SegPesTOk()

//	u_Log2 ('info', 'Iniciando ' + procname ())

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

		U_Log2 ('debug', '[' + procname () + ']Vou validar a seguinte carga:')
		_oCarSaf:Log ()
		if ! _oCarSaf:PodeGravar ()
			u_help (_oCarSaf:UltMsg,, .t.)
			_lRet = .F.
		endif

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

	// Estou migrando para dentro da classe.
	if _lRet .and. altera
		_lRet = _oCarSaf:SegPesTOk ()
		if ! _lRet
			u_help (_oCarSaf:UltMsg,, .t.)
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
return _lRet
