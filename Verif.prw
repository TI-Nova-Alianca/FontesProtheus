// Programa:  Verif
// Autor:     Robert Koch
// Data:      12/11/2016
// Descricao: Executa verificacoes diversas.
//
// Historico de alteracoes:
// 24/11/2016 - Robert - Tratamento para consultas que precisam ler parametros de usuario.
// 28/03/2017 - Robert - Possibilita receber array com os parametros para execucao.
// 01/06/2022 - Robert - Busca qt.validacoes via atributo :UltVerif.
// 18/05/2023 - Robert - Criado botao para consulta de documentacao das verificacoes.
//

// --------------------------------------------------------------------------
User Function Verif (_nQual, _aParam)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aRet      := {}
	local _aVerif    := {}
	local _nVerif    := 0
	local _nParam    := 0
	local _nUltVerif := 0
	local _aBotAdic  := {}

	_nQual     := iif (_nQual == NIL, 0, _nQual)

	// Sem interface (outra rotina solicitando dados)
	if _nQual != 0
		_aRet = {}
		_oVerif := ClsVerif ():New (_nQual)
		if _oVerif:Numero == 0 .or. empty (_oVerif:Descricao)  // Provavelmente seja um numero invalido / inexistente.
			u_help (_oVerif:UltMsg)
		else
			if _oVerif:Ativa .and. (_oVerif:Filiais == '*' .or. cFilAnt $ _oVerif:Filiais)
				if _PodeVer (_oVerif)
					_oVerif:ComTela = .F.
					if _oVerif:Pergunte ()
	
						// Se recebi os parametros, informo-os no objeto.
						if valtype (_aParam) == 'A'
							for _nParam = 1 to len (_aParam)
								_oVerif:SetParam (strzero (_nParam, 2), _aParam [_nParam])
							next
						endif
						
						if _oVerif:Executa ()
							_aRet = aclone (_oVerif:Result)
						else
							u_help ("Problemas ao executar a verificacao '" + _oVerif:Descricao + "'. Descricao do erro: " + _oVerif:UltMsg)
						endif
					endif
				else
					u_help ("Usuario sem acesso a esta consulta.")
				endif 
			else
				u_help ("Verificacao '" + cvaltochar (_oVerif:Numero) + " - " + _oVerif:Descricao + "' encontra-se inativa ou destina-se a outra(s) filial(is).")
			endif
		endif

	else  // Com interface com o usuario

		// Monta lista das verificacoes disponiveis.
		_aVerif = {}
		_oVerif := ClsVerif ():New () //1)
		_nUltVerif = _oVerif:UltVerif
		U_Log2 ('debug', '[' + procname () + ']ultima verif:' + cvaltochar (_nUltVerif))
		for _nVerif = 1 to _nUltVerif
			_oVerif := ClsVerif ():New(_nVerif)
			if _oVerif:Ativa .and. (_oVerif:Filiais == '*' .or. cFilAnt $ _oVerif:Filiais)
				aadd (_aVerif, {.F., _oVerif:Numero, _oVerif:Setores, _oVerif:Descricao, _oVerif})
			endif
		next
		U_Log2 ('debug', _aVerif)
	
		// Executa em loop para poder fazer consultas repetidamente sem sair da tela.
		do while .T.
			_aCols = {}
			aadd (_aCols, {2, "Tipo",            20, ""})
			aadd (_aCols, {3, "Areas interesse", 70, ""})
			aadd (_aCols, {4, "Descricao",      150, ""})
			_aBotAdic = {{"Documentacao", "processa ({|| U_VerifHlp ()})"}}
			U_MBArray (@_aVerif, "Selecione verificacoes a fazer", _aCols, 1, nil, nil, '.t.', _aBotAdic)
			u_log2 ('info', _aVerif)
			for _nVerif = 1 to len (_aVerif)
				if _aVerif [_nVerif, 1]
					_oVerif = _aVerif [_nVerif, 5]
					_oVerif:ComTela = .T.
					U_Log2 ('debug', '[' + procname () + ']::Numero    = ' + cvaltochar (_oVerif:Numero))
					U_Log2 ('debug', '[' + procname () + ']::GrupoPerg = ' + _oVerif:GrupoPerg)
					if _oVerif:Pergunte ()
						U_Log2 ('debug', '[' + procname () + ']::Pergunte() retornou .t.')
						if _oVerif:Executa ()
							if _oVerif:QtErros == 0
								u_help ("Nada encontrado para: " + _oVerif:Descricao)
							else

								// Deixa variavel aHeader criada para o caso do usuario pedir exportacao para planilha.
								private aHeader := aclone (_oVerif:aHeader)

								U_Log2 ('debug', _oVerif:Result)

								// Mostra o resultado para o usuario.
								u_showarray (_oVerif:Result, "Pendencias do tipo " + _oVerif:Descricao)
							endif
						else
							u_help ("Problemas ao executar a verificacao '" + _oVerif:Descricao + "'. Descricao do erro: " + _oVerif:UltMsg)
						endif
					endif
				endif
			next
			if ! U_msgyesno ("Deseja fazer nova consulta?", .F.)
				exit
			endif
		enddo
	endif

	U_ML_SRArea (_aAreaAnt)
return _aRet



// --------------------------------------------------------------------------
// Verifica se o usuario tem acesso a esta verificacao.
static function _PodeVer (_oVerif)
	local _lRet   := .F.
	local _nGrupo := 0

	if len (_oVerif:LiberZZU) == 0
		_lRet = .T.
	else
		for _nGrupo = 1 to len (_oVerif:LiberZZU)
			if U_ZZUVL (_oVerif:LiberZZU [_nGrupo], __cUserId, .F.)
				_lRet = .T.
				exit
			endif
		next
	endif
return _lRet


// --------------------------------------------------------------------------
// Abre documentacao das verificacoes.
user function VerifHlp ()
//	local _nVerif   := 0
	local _oVerif   := NIL
	local _sHTML    := ''

	procregua (10)
	incproc ("Gerando documentacao...")

	/* A funcao U_MBArray(), no momento da chamada do botao, nao tem a array atualizada ainda...
	for _nVerif = 1 to len (_aVerif)
		if _aVerif [_nVerif, 1]
			_oVerif = _aVerif [_nVerif, 5]
			_sHTML += _oVerif:GeraHelp (_oVerif:Numero, (empty (_sHTML)))
			U_Log2 ('debug', '[' + procname () + ']' + _sHTML)
		endif
	next
	*/

	_oVerif := ClsVerif ():New ()
	_sHTML += _oVerif:GeraHelp ()
	_sHTML = strtran (_sHTML, chr (13) + chr (10), '')  // A funcao U_ShowHTM substitui as quebras de linha

	U_ShowHTM (_sHTML, 'N')
return
