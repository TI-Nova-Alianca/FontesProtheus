// Programa...: ZAF
// Autor......: Robert Koch
// Data.......: 23/07/2016
// Descricao..: Manutencao de laudos tecnicos.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #cadastro
// #Descricao         #Manutencao de laudos tecnicos.
// #PalavasChave      #laudos_tecnicos
// #TabelasPrincipais #ZAF
// #Modulos   		  #COOP 
//
// Historico de alteracoes:
// 27/05/2017 - Robert  - Inclusao de laudos passa a ter controle de semaforo.
// 14/03/2018 - Robert  - Validacao da composicao de safras (deve somar 100%).
// 04/11/2018 - Robert  - Merge de laudos: - assume maior validade entre os laudos envolvidos.
//                                         - assume finalidade se for igual em todos os laudos envolvidos.
//                                         - recebe observacao por parametro.
// 30/09/2019 - Robert  - Acrescentados logs para depuracao na funcao de 'merge' de ensaios.
// 31/03/2021 - Robert  - Alteracao logs.
// 06/12/2021 - Robert  - Pequena melhoria nos logs de laudos para fazer merge.
// 19/01/2022 - Claudia - Incluido novos campos de brix e solidos. GLPI: 11490
//
// ----------------------------------------------------------------------------------------------------------
User Function ZAF ()
	local _aCores      := U_ZAFLG (.T.)
	private cString    := "ZAF"
	private cCadastro  := "Controle laudos / ensaios"
	private aRotina    := {}
	
	// Menu principal
	aadd (aRotina, {"&Pesquisar",      "AxPesqui",      				0, 1})
	aadd (aRotina, {"&Visualizar",     "AxVisual",      				0, 2})
	aadd (aRotina, {"&Incluir",        "U_ZAFI",        				0, 3})
	aadd (aRotina, {"&Alterar",        "U_ZAFA",        				0, 4})
	aadd (aRotina, {"&Excluir",        "U_ZAFE",        				0, 5})
	aadd (aRotina, {"&Imprime Laudo",  "U_VARCOOP01(ZAF->ZAF_ENSAIO)", 	0, 4})
	aadd (aRotina, {"&Legenda",        "U_ZAFLG (.F.)",       			0, 5})

	DbSelectArea(cString)
	mBrowse(,,,,cString,,,,,2, _aCores)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZAFLG (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	local _i       := 0

	aadd (_aCores, {"zaf -> zaf_valid >= date () .and. posicione('SB8',5,zaf->zaf_filial+zaf->zaf_produt+zaf->zaf_lote,'B8_SALDO')>0",  'BR_VERDE', 'Valido'})
	aadd (_aCores, {"zaf -> zaf_valid >= date () .and. posicione('SB8',5,zaf->zaf_filial+zaf->zaf_produt+zaf->zaf_lote,'B8_SALDO')<=0", 'BR_PRETO', 'Valido (sem estoque)'})
	aadd (_aCores, {"zaf -> zaf_valid < date ()",  'BR_VERMELHO', 'Fora validade'})

	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return



// --------------------------------------------------------------------------
// Alteracao.
user function ZAFA ()
	//local _aBotAdic := {}
	private _nTpLaudo := 0  // Deixar private para ser vista por validacoes de campos.

	//aadd(_aBotAdic,{"BALANCA",{|| U_PesaZZT()},"Pesagem"})
	if AxAltera ("ZAF", ZAF -> (Recno ()), 4, NIL, NIL, NIL, NIL, "U_ZAF_TOk ()") == 1
	endif
return



// --------------------------------------------------------------------------
// Inclusao.
user function ZAFI ()
	local _aBotAdic   := {}
	local _nLock      := 0
	local _aOpcoes    := {}
	local _nOpcao     := {}
	private _nTpLaudo := 0  // Deixar private para ser vista por validacoes de campos.

	//aadd(_aBotAdic,{"BALANCA",{|| U_PesaZZT()},"Pesagem"})

	_aOpcoes = {}
	aadd (_aOpcoes, {'Por tanque (define o produto / lote a partir do conteudo de um endereco de estoque)'})
	aadd (_aOpcoes, {'Por ordem de producao (define o produto / lote a partir do que foi produzido da OP)'})
	aadd (_aOpcoes, {'Informar manualmente o produto e lote'})
	aadd (_aOpcoes, {'Cancelar'})
	_nOpcao = U_F3Array (_aOpcoes, ;  // Opcoes
	                     "Forma de entrada de dados", ;  // Titulo janela
	                     {{1, "Opcao", 150, ''}}, ;  // Titulos colunas
	                     oMainWnd:nClientWidth / 2, ;  // Largura janela
	                     oMainWnd:nClientHeight / 2, ;  // Altura janela
	                     "Selecione a forma de identificacao do produto / lote ensaiado", ;  //  Linha sup
	                     "", ;  // Linha inf
	                     .F., ;  // .T.=mostra botao de exportacao para planilha
	                     "")  // Tipo pesquisa
	if valtype (_nOpcao) == 'N' .and. _nOpcao > 0 .and. _nOpcao < 4
		_nTpLaudo = _nOpcao

		// Controla inclusao de laudos via semaforo por que desejamos manter numeracao unica entre
		// todas as filiais via 'SELECT MAX (ZAF_ENSAIO)' e o acesso concorrente nao respeita isso.
		_nLock := U_Semaforo ('Laudos')
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		else
			if AxInclui ("ZAF", ZAF -> (recno ()), 3, NIL, NIL, NIL, "U_ZAF_TOk ()",,,_aBotAdic) == 1
			endif
		endif

		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
return



// --------------------------------------------------------------------------
// Exclusao de laudo.
User Function ZAFE ()
	private _nTpLaudo := 0  // Deixar private para ser vista por validacoes de campos.
	AxDeleta ("ZAF", zaf -> (recno ()), 5)
return



// --------------------------------------------------------------------------
// Validacao 'Tudo OK' da inclusao/alteracao.
user function ZAF_TOk ()
	local _nSafra    := 0
	local _sSafra    := ""
	local _sSafras   := ""
	local _nPerc     := 0
	local _nSomaPerc := 0
	local _lTemSafra := .F.
	local _lRet      := .T.

	if m->zaf_finali == 'PE' .and. empty (m->zaf_lindes)
		u_help ("Quando finalidade for pre-envase, deve ser informada a linha de envase destino.")
		_lRet = .F.
	endif

	// Verifica preenchimento dos percentuais de safra.
	_nSomaPerc = 0
	_nSafra = 1
	_sSafras = ''
	do while zaf->(fieldpos ('zaf_safra' + cvaltochar (_nSafra))) > 0
		_sSafra = m->&('zaf_safra' + cvaltochar (_nSafra))
		_nPerc = m->&('zaf_psafr' + cvaltochar (_nSafra))
		if !empty (_sSafra) .or. _nPerc != 0
			_lTemSafra = .T.
		endif
		if (empty (_sSafra) .and. _nPerc != 0) .or. (! empty (_sSafra) .and. _nPerc <= 0)
			u_help ("Composicao de safras [" + cvaltochar (_nSafra) + "]: informe ambos (safra e percentual de participacao) ou nenhum deles.")
			_lRet = .F.
		else
			if ! empty (_sSafra) .and. _sSafra $ _sSafras
				u_help ("Composicao de safras [" + cvaltochar (_nSafra) + "]: safra '" + _sSafra + "' informada mais de uma vez.")
				_lRet = .F.
			else
				_sSafras += _sSafra + '/'
				_nSomaPerc += _nPerc
			endif
		endif
		_nSafra ++
	enddo
	if _lRet .and. _lTemSafra .and. _nSomaPerc != 100
		u_help ("Composicao de safras: a soma das participacoes ficou em " + cvaltochar (_nSomaPerc) + "% (deve fechar em 100%).")
		_lRet = .F.
	endif
return _lRet



// --------------------------------------------------------------------------
// Gera laudo (merge) com base em uma lista de laudos originais.
// Recebe array com: 1 - Numero do laudo
//                   2 - Quantidade utilizada (para proporcionalizar no total)
User Function ZAFM (_aLaudos, _sProduto, _sOP, _sLote, _sAlmox, _sObs)
	Local _aAreaAnt  := U_ML_SRArea ()
	local _nLock     := 0
	local _sLauDest  := ""
	local _nLaudo    := 0
	local _nQtLaudos := 0
	local _aEnsOri   := {}
	local _nAcVol    := 0
	local _nAcTot    := 0
	local _nAcRed    := 0
	local _nAlcool   := 0
	local _nDensid   := 0
	local _nExtrSe   := 0
	local _nSO2Liv   := 0
	local _nSO2Tot   := 0
	local _nBrix     := 0
	local _nBrix2    := 0
	local _nBrix3    := 0
	local _nSolid    := 0
	local _nSolid2   := 0
	local _nSolid3   := 0
	local _nPH       := 0
	local _nTurbid   := 0
	local _nCor420   := 0
	local _nCor520   := 0
	local _nCor620   := 0
	local _nBolor    := 0
	local _nColif    := 0
	local _nSabor    := 0
	local _nAroma    := 0
	local _nEstTar   := 0
	local _nAcetal   := 0
	local _aSafras   := {}
	local _nTotSafr  := 0
	local _dValid    := ctod ('')
	local _aFinalid  := {}
	local _nContSafr := 0
	local _nSafra    := 0

	// Pega antes os laudos de maior volume.
	asort (_aLaudos,,, {|_x, _y| _x [2] > _y [2]})
	if len (_aLaudos) == 0
		u_log2 ('info', '[' + procname () + '] Nao ha laudos para fazer merge')
	else
		u_log2 ('info', '[' + procname () + '] Laudos para fazer merge:')
		u_log2 ('info', _aLaudos)
	endif

	_aEnsOri = {}
	_aSafras = {}
	zaf -> (dbsetorder (1))  // ZAF_FILIAL+ZAF_ENSAIO
	for _nLaudo = 1 to len (_aLaudos)
		if ! zaf -> (dbseek (xfilial ("ZAF") + _aLaudos [_nLaudo, 1], .F.))
			u_log2 ('erro', "Laudo '" + _aLaudos [_nLaudo, 1] + "' nao cadastrado.")
		else
			_nAcVol  += zaf -> zaf_acvol
			_nAcTot  += zaf -> zaf_actot
			_nAcRed  += zaf -> zaf_acred
			_nAlcool += zaf -> zaf_alcool
			_nDensid += zaf -> zaf_densid
			_nExtrSe += zaf -> zaf_extrse
			_nSO2Liv += zaf -> zaf_so2liv
			_nSO2Tot += zaf -> zaf_so2tot
			_nBrix   += zaf -> zaf_brix
			_nBrix2  += zaf -> zaf_brix1
			_nBrix3  += zaf -> zaf_brix2
			_nSolid  += zaf -> zaf_solid
			_nSolid2 += zaf -> zaf_solid1
			_nSolid3 += zaf -> zaf_solid2
			_nPH     += zaf -> zaf_ph
			_nTurbid += zaf -> zaf_turbid
			_nCor420 += zaf -> zaf_cor420
			_nCor520 += zaf -> zaf_cor520
			_nCor620 += zaf -> zaf_cor620
			_nBolor  += zaf -> zaf_bolor
			_nColif  += zaf -> zaf_colif
			_nSabor  += zaf -> zaf_sabor
			_nAroma  += zaf -> zaf_aroma
			_nEstTar += zaf -> zaf_esttar
			_nAcetal += zaf -> zaf_acetal
			_dValid  := max (_dValid, zaf -> zaf_valid)
			
			// Gera lista de finalidades encontradas.
			if ascan (_aFinalid, zaf -> zaf_finali) == 0
				aadd (_aFinalid, zaf -> zaf_finali)
			endif
			
			// Acumula volume de participacao de cada safra
			for _nContSafr = 1 to 4  // Por enquanto tenho apenas 4 campos de safra no ZAF.
				if ! empty (zaf -> &('zaf_safra' + cvaltochar (_nContSafr)))
					_nSafra = ascan (_aSafras, {|_x| _x [1] == zaf -> &('zaf_safra' + cvaltochar (_nContSafr))})
					if _nSafra == 0
						aadd (_aSafras, {zaf -> &('zaf_safra' + cvaltochar (_nContSafr)), 0, 0})
						_nSafra = len (_aSafras)
					endif
					_aSafras [_nSafra, 2] += zaf -> &('zaf_psafr' + cvaltochar (_nContSafr)) * _aLaudos [_nLaudo, 2]
				endif
			next

			_nQtLaudos ++
			aadd (_aEnsOri, zaf -> zaf_ensaio)
		endif
	next

	// Calcula novo percentual de participacao de cada safra.
	_nTotSafr = 0
	for _nSafra = 1 to len (_aSafras)
		_nTotSafr += _aSafras [_nSafra, 2]
	next
	for _nSafra = 1 to len (_aSafras)
		_aSafras [_nSafra, 3] = _aSafras [_nSafra, 2] * 100 / _nTotSafr
	next
	
	// Cria novo laudo
	if _nQtLaudos > 0

		// Controla inclusao de laudos via semaforo por que desejamos manter numeracao unica entre
		// todas as filiais via 'SELECT MAX (ZAF_ENSAIO)' e o acesso concorrente nao respeita isso.
		_nLock := U_Semaforo ('Laudos')
		if _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		else
			_sLauDest = U_VA_INIPD ("ZAF_ENSAIO", .F.)
			if ! empty (_sLauDest)
				u_log2 ('info', 'Gravando ZAF_ENSAIO = ' + _sLauDest)
				reclock ("ZAF", .T.)
				zaf -> zaf_filial = xfilial ("ZAF")
				zaf -> zaf_ensaio = _sLauDest
				zaf -> zaf_produt = _sProduto
				zaf -> zaf_op     = _sOP
				zaf -> zaf_lote   = _sLote
				zaf -> zaf_local  = _sAlmox
				zaf -> zaf_data   = dDataBase
				zaf -> zaf_dtinc  = date ()
				zaf -> zaf_hrinc  = time ()
				zaf -> zaf_user   = cUserName     
				zaf -> zaf_ensori = _aEnsOri [1]
				zaf -> zaf_ensor2 = iif (len (_aEnsOri) >= 2, _aEnsOri [2], '')
				zaf -> zaf_ensor3 = iif (len (_aEnsOri) >= 3, _aEnsOri [3], '')
				zaf -> zaf_ensor4 = iif (len (_aEnsOri) >= 4, _aEnsOri [4], '')  // Por enquanto tenho poucos campos para laudo origem.
				for _nSafra = 1 to len (_aSafras)
					zaf -> &('zaf_safra' + cvaltochar (_nSafra)) = _aSafras [_nSafra, 1]
					zaf -> &('zaf_psafr' + cvaltochar (_nSafra)) = _aSafras [_nSafra, 3]
				next
				zaf -> zaf_acvol  = _nAcVol  / _nQtLaudos
				zaf -> zaf_actot  = _nAcTot  / _nQtLaudos
				zaf -> zaf_acred  = _nAcRed  / _nQtLaudos
				zaf -> zaf_alcool = _nAlcool / _nQtLaudos
				zaf -> zaf_densid = _nDensid / _nQtLaudos
				zaf -> zaf_extrse = _nExtrSe / _nQtLaudos
				zaf -> zaf_so2liv = _nSO2Liv / _nQtLaudos
				zaf -> zaf_so2tot = _nSO2Tot / _nQtLaudos
				zaf -> zaf_brix   = _nBrix   / _nQtLaudos
				zaf -> zaf_brix1  = _nBrix2  / _nQtLaudos
				zaf -> zaf_brix2  = _nBrix3  / _nQtLaudos
				zaf -> zaf_solid  = _nSolid  / _nQtLaudos
				zaf -> zaf_solid1 = _nSolid2 / _nQtLaudos
				zaf -> zaf_solid2 = _nSolid3 / _nQtLaudos
				zaf -> zaf_ph     = _nPH     / _nQtLaudos
				zaf -> zaf_turbid = _nTurbid / _nQtLaudos
				zaf -> zaf_cor420 = _nCor420 / _nQtLaudos
				zaf -> zaf_cor520 = _nCor520 / _nQtLaudos
				zaf -> zaf_cor620 = _nCor620 / _nQtLaudos
				zaf -> zaf_bolor  = _nBolor  / _nQtLaudos
				zaf -> zaf_colif  = _nColif  / _nQtLaudos
				zaf -> zaf_sabor  = _nSabor  / _nQtLaudos
				zaf -> zaf_aroma  = _nAroma  / _nQtLaudos
				zaf -> zaf_esttar = _nEstTar / _nQtLaudos
				zaf -> zaf_acetal = _nAcetal / _nQtLaudos
				//zaf -> zaf_obs    = 'Ensaio gerado pelo apontamento da OP ' + _sOP
				zaf -> zaf_obs    = _sObs
				zaf -> zaf_valid  = _dValid
				zaf -> zaf_finali = iif (len (_aFinalid) == 1, _aFinalid [1], '')  // Finalidade: se for a mesma em todos os laudos, mantem.
				msunlock ()
			endif
		endif

		// Confirma sequenciais, se houver.
		do while __lSX8
			ConfirmSX8 ()
		enddo

		// Libera semaforo.
		if _nLock > 0
			U_Semaforo (_nLock)
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return
