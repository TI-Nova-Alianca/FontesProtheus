// Programa...: VA_RUS1
// Autor......: Robert Koch
// Data.......: 18/01/2010
// Descricao..: Tela 1a pesagem recebimento de uva durante a safra (uso na balanca).
//
// Historico de alteracoes:
// 16/04/2010 - Robert - Criado tratamento para associados do Condominio.
// 06/01/2011 - Robert - Ajustes para safra 2011
// 16/02/2011 - Robert - Testa bloqueio do cadastro do fornecedor.
// 17/02/2011 - Robert - Verifica revisao do cadastro viticola.
// 22/03/2011 - Robert - Bloqueia acesso mutuo `a mesma filial via semaforo.
// 27/12/2011 - Robert - Nao bloqueia mais acesso mutuo `a mesma filial (gera carga via SXE e SXF).
//                     - Melhorias gerais para safra 2012.        
// 21/09/2012 - Elaine - Alteracao para tratar nota de 6 para 9 posicoes
// 11/01/2015 - Robert - Melhoradas validacoes para safra 2015.
// 05/01/2017 - Robert - Ajustes para safra 2017.
//    02/2019 - Robert - Melhorias gerais para safra 2019
// 05/02/2019 - Robert - Ajustes para receber uva de associados da Coop.Garibaldi.
// 03/02/2021 - Robert - Novos parametros funcao U_VA_Rus2().
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function va_rus1 ()
	local _nCoop       := 0
	local _sCoop       := ""
	local _nAssoc      := 0
	local _aCols       := {}
	local _lContinua   := .T.
	local _sBarras     := ""
	local _sQuery      := ""
	local _aRetQry     := {}
	local _nF3         := 0
	local _oSQL        := NIL

	u_Log2 ('info', 'Iniciando ' + procname ())

	private _oAssoc    := NIL
	private _ZESAFRA   := _xSafraJ   // Variavel private para alimentar a tela final de AxInclui
	private _ZELOCAL   := _sBalanca  // Variavel private para alimentar a tela final de AxInclui
	private _ZECOOP    := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZELOJCOOP := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZENOMCOOP := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZEASSOC   := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZELOJASSO := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZENOMASSO := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZECPFTERC := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZENOMTERC := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZEPATRIAR := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZESNFPROD := ""  // Variavel private para alimentar a tela final de AxInclui
	private _ZENFPROD  := ""  // Variavel private para alimentar a tela final de AxInclui
	private _oCarSaf   := ClsCarSaf ():New ()


	// Este teste parece que vai exigir manutencao eterna...
	if _ZESAFRA >= '2014' .and. ! cEmpAnt + cFilAnt $ '0101/0103/0107/0109/0110/0111/0112/0113'
		u_help ("Filial nao liberada para recebimento de safra.")
		return
	endif

	// Identificacao do associado: pode ser manual ou via leitor de codigo de barras.
	_oAssoc := NIL
	//
	// Se usa leitor de codigo de barras, faz a identificacao do produtor pela inscricao estadual.
	if _lLeitBar
		_sBarras = U_Get ("Codigo barras do talao", "C", 20, "", "", space (20), .F., '.T.')
		if ! empty (_sBarras)
			_sInscr = substr (_sBarras, 2, 10)

			// Busca via query por que foi criado um indice direto no banco de dados
			// e nao no SINDEX, jah que vai ter utilizacao bastante especifica.
			_sQuery := ""
			_sQuery += "SELECT A2_NOME, A2_CGC, A2_MUN, A2_END, A2_COD, A2_LOJA"
			_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2"
			_sQuery += " WHERE D_E_L_E_T_ = ''"
			_sQuery +=   " AND A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_sQuery +=   " AND A2_INSCR   = '" + _sInscr + "'"
			_aRetQry = aclone (U_Qry2Array (_sQuery))
			if len (_aRetQry) > 0
				if len (_aRetQry) == 1
					_nF3 = 1
				else
					// Browse para usuario selecionar o associado, caso tenha mais de um ligado `a mesma inscricao estadual.
					_aRetQry = asort (_aRetQry,,, {|_x, _y| _x[1] < _y [1]})
					_aCols = {}
					aadd (_aCols, {1, "Nome",       80, ""})
					aadd (_aCols, {2, "CPF",        30, ""})
					aadd (_aCols, {3, "Municipio",  60, ""})
					aadd (_aCols, {4, "Endereco",   60, ""})
					aadd (_aCols, {5, "Codigo",     40, ""})
					aadd (_aCols, {6, "Loja",       20, ""})
					_nF3 = U_F3Array (_aRetQry, "Selecione o associado", _aCols, oMainWnd:nClientWidth - 200, oMainWnd:nClientHeight - 100, "Selecione o associado", "", .F., 'C')
				endif
				if _nF3 > 0
					if _lContinua
						U_Log2 ('debug', 'Instanciando associado')
						_oAssoc := ClsAssoc():New (_aRetQry [_nF3, 5], _aRetQry [_nF3, 6])
						if valtype (_oAssoc) != "O" .or. empty (_oAssoc:Codigo) .or. empty (_oAssoc:Loja)
							u_help ("Problemas no cadastro do associado.")
							_lContinua = .F.
						else
							_sCoop     := '00002101'
							_ZECOOP    := substr (_sCoop, 1, 6)
							_ZELOJCOOP := substr (_sCoop, 7, 2)
							_ZENOMCOOP := sm0 -> m0_nomecom 
							_ZEASSOC   := _oAssoc:Codigo
							_ZELOJASSO := _oAssoc:Loja
							_ZENOMASSO := _oAssoc:Nome
							_ZESNFPROD := substr (_sBarras, 12, 3)    
							// 20120927 - Robert: Mantido tamanho 6 por que depende do que consta no codigo de barras do talao.
							_ZENFPROD  := padl (substr (_sBarras, 15, 6), tamsx3 ("ZE_NFPROD")[1], '0')
	
							// Valida NF produtor, jah que o campo nao vai ser digitado manualmente.
							_oSQL := ClsSQL():New ()
							_oSQL:_sQuery := ""
							_oSQL:_sQuery += "SELECT COUNT (*)"
							_oSQL:_sQuery +=  " FROM " + RetSQLName ("SZE") + " SZE "
							_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
							_oSQL:_sQuery +=   " AND ZE_FILIAL  = '" + xfilial ("SZE") + "'"
							_oSQL:_sQuery +=   " AND ZE_SAFRA   = '" + _xSafraJ   + "'"
							_oSQL:_sQuery +=   " AND ZE_COOP    = '" + _ZECOOP    + "'"
							_oSQL:_sQuery +=   " AND ZE_LOJCOOP = '" + _ZELOJCOOP + "'"
							_oSQL:_sQuery +=   " AND ZE_ASSOC   = '" + _ZEASSOC   + "'"
							_oSQL:_sQuery +=   " AND ZE_LOJASSO = '" + _ZELOJASSO + "'"
							_oSQL:_sQuery +=   " AND ZE_NFPROD  = '" + _ZENFPROD  + "'"
							_oSQL:_sQuery +=   " AND ZE_SNFPROD = '" + _ZESNFPROD  + "'"
							_oSQL:_sQuery +=   " AND ZE_STATUS != 'C'"
							if _oSQL:RetQry () > 0
								U_Help ("NF de produtor/serie '" + _ZENFPROD + '/' + _ZESNFPROD + "' ja informada em outra carga deste associado.")
								_lContinua = .F.
							endif
						endif
					endif
				endif
			else
				u_help ("Nenhum fornecedor encontrado com inscricao '" + _sInscr + "'",, .t.)
				_lContinua = .F.
			endif
		endif
	endif
	//
	// Se chegou aqui sem identificacao do associado, eh por que nao funcionou pelo codigo de barras
	// ou por que nao tem leitor instalado na estacao.
	if _oAssoc == NIL

		// Browse para o usuario selecionar a cooperativa.
		_nCoop = U_F3Array (_aCoop, "Selecione a cooperativa", {{1, "Cooperativa", 160, ""}, {4, "Nome reduzido", 160, ""}}, 600, 400, "Selecione a cooperativa", "", .F., '')
		if _nCoop == 0
			_lContinua = .F.
		else
			_sCoop = _aCoop [_nCoop, 2] + _aCoop [_nCoop, 3]
		endif

		if _lContinua .and. len (&("_a" + _sCoop)) == 0
			u_help ('Nao encontrei associados habilitados para a cooperativa ' + _sCoop)
			_lContinua = .F.
		endif

		// Browse para usuario selecionar o associado, quando nao for 'outro fornecedor'.
		if _lContinua //.and. _sCoop != '99999999'
			if len (&("_a" + _sCoop)) == 0
				u_help ('Nao encontrei associados habilitados para a cooperativa ' + _sCoop)
				_lContinua = .F.
			endif
			_aCols = {}
			aadd (_aCols, {1, "Nome",      80, ""})
			aadd (_aCols, {2, "CPF",       30, ""})
			aadd (_aCols, {3, "Municipio", 60, ""})
			aadd (_aCols, {4, "Endereco",  60, ""})
			aadd (_aCols, {5, "Codigo",    40, ""})
			aadd (_aCols, {6, "Loja",      20, ""})
			aadd (_aCols, {7, "Restricao", 120, ""})
			_nAssoc = U_F3Array (&("_a" + _sCoop), "Selecione o associado", _aCols, oMainWnd:nClientWidth - 200, oMainWnd:nClientHeight - 100, "Selecione o associado", "", .F., 'C')
			if _nAssoc > 0

				if ! empty (&("_a"+_sCoop) [_nAssoc, 7])
					u_help ("Associado tem restricao: " + alltrim (&("_a"+_sCoop) [_nAssoc, 7]))
					_lContinua = .F.
				endif

				// Se nao for da nossa cooperativa, nem adianta instanciar o associado.
				if _sCoop $ "00002101"
					_oAssoc := ClsAssoc():New (&("_a"+_sCoop) [_nAssoc, 5], &("_a"+_sCoop) [_nAssoc, 6])
					if valtype (_oAssoc) != "O"
						_lContinua = .F.
					endif
				endif
				if _lContinua
					_ZECOOP    := _aCoop [_nCoop, 2]
					_ZELOJCOOP := _aCoop [_nCoop, 3]
					_ZENOMCOOP := _aCoop [_nCoop, 1]
					_ZEASSOC   := &("_a"+_sCoop) [_nAssoc, 5]
					_ZELOJASSO := &("_a"+_sCoop) [_nAssoc, 6]
					_ZENOMASSO := &("_a"+_sCoop) [_nAssoc, 1]
				endif
			endif
		endif
	endif


	// Algumas consistencias com o associado.
	if _lContinua .and. _sCoop $ '00136901/00002101'
		if valtype (_oAssoc) != "O"
			_lContinua = .F.
		endif
//		if _lContinua .and. ! _oAssoc:Codigo + _oAssoc:Loja == '00136901' .and. ! _oAssoc:Codigo + _oAssoc:Loja == '01237301'  // lIVRAMENTO E fornecedor VINHEDOS DA QUINTA
		if _lContinua .and. ! _oAssoc:Codigo + _oAssoc:Loja $ '00136901/00136902' .and. ! _oAssoc:Codigo + _oAssoc:Loja == '01237301'  // lIVRAMENTO E fornecedor VINHEDOS DA QUINTA
			if _lContinua .and. _oAssoc:Bloqueado
				u_help ("Fornecedor com cadastro bloqueado.")
				_lContinua = .F.
			endif
			if _lContinua .and. ! _oAssoc:EhSocio ()
				u_help ("Fornecedor '" + alltrim (_oAssoc:Nome) + "' nao consta como associado ativo. Verifique sua data de filiacao na conta corrente.")
				_lContinua = .F.
			endif
			if _lContinua .and. ! empty (_oAssoc:DtFalecim)
				u_help ("Associado consta como falecido em " + dtoc (_oAssoc:DtFalecim))
				_lContinua = .F.
			endif
		endif
	endif

	// Outra cooperativa
	if _lContinua .and. _oAssoc == NIL
		if _sCoop != '00002101'
			szd -> (dbsetorder (1))  // ZD_FILIAL+ZD_SAFRA+ZD_COOP+ZD_LJCOOP+ZD_FORNECE+ZD_LOJAFOR
			if ! szd -> (dbseek (xfilial ("SZD") + _xSAFRAJ + _ZECOOP + _ZELOJCOOP + _ZEASSOC + _ZELOJASSO, .F.))  // &("_a" + _sCoop) [_nAssoc, 2], .F.))
				u_help ("Cadastro do associado nao ligado `a cooperativa/loja " + _sCoop + " para esta safra.")
				_lContinua = .F.
			endif
		endif
	endif

	// Se chegou ateh aqui, abre tela para inclusao da primeira pesagem.
	if _lContinua
		U_VA_RUS2 (3, .F.)
	endif

return
