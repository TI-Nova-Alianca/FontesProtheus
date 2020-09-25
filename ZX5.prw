// Programa...: ZX5
// Autor......: Robert Koch
// Data.......: 19/05/2009
// Descricao..: Tela de manutencao do arquivo ZX5 - tabelas genericas (especificas Alianca)
//
// Historico de alteracoes:
// 12/05/2010 - Robert - Incluida validacao de 'linha OK' da tabela 06.
// 07/12/2010 - Robert - Incluida validacao de 'linha OK' da tabela 08 e 09.
// 17/01/2012 - Elaine - Incluida validacao de 'linha OK' da tabela 17.
// 26/04/2013 - Robert - Passa a abrir Get para usuário informar filtro na tela de atualizacao.
// 05/05/2013 - Robert - Passa a controlar gravacao com o campo ZZZ_RECNO para possibilitar filtros.
// 08/12/2016 - Robert - Tratamento para envio de dados para o Mercanet.
// 14/01/2017 - Robert - Passa a usar classe ClsTabGen para ler lista de campos chave no 'linha ok'.
// 14/03/2017 - Júlio  - Habilita a edição da descrição se a função chamada for ZX5, nas demais chamadas não permite alterar a descrição.
// 07/12/2017 - Robert - Chama metodo PodeExcl() da classe ClsTabGen na validacao de linha deletada.
// 24/12/2018 - Robert - Criado parametro para receber filtro inicial na funcao ZX5A().
// 08/01/2019 - Robert - Criado parametro para receber nomes de campos a serem usados para ordenar o aCols.
// 13/12/2019 - Robert - Paltavam parametros na visualizacao e dava erro.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function ZX5 ()
	private aRotina := {}
	aadd (aRotina, {"&Pesquisar",  "AxPesqui", 0, 1})
	aadd (aRotina, {"&Visualizar", "U_ZX5A (2, zx5 -> zx5_chave, 'allwaystrue ()', 'allwaystrue ()', .T.)",   0, 2})
	aadd (aRotina, {"&Incluir",    "U_ZX5I",   0, 3})
	aadd (aRotina, {"&Alterar",    "U_ZX5A (4, zx5 -> zx5_chave, 'allwaystrue ()', 'allwaystrue ()', .T.)",   0, 4})
	aadd (aRotina, {"&Excluir",    "U_ZX5A (5)",   0, 5})
	private cString   := "ZX5"
	private cCadastro := "Manutencao de tabelas genericas - Alianca"
	dbselectarea ("ZX5")
	dbSetOrder (1)
	mBrowse(,,,,"ZX5")
return



// --------------------------------------------------------------------------
// Inclusao
User Function ZX5I ()
	private _sTabela  := space (tamsx3 ("ZX5_TABELA")[1])
	private _sNomeTab := space (tamsx3 ("ZX5_DESCRI")[1])
	private _sModo    := space (tamsx3 ("ZX5_MODO")[1])

	@ 0, 0 TO 350, 320 DIALOG oDlg1 TITLE "Inclusao de tabela"
	@ 25, 5  say "Tabela:"
	@ 40, 5  say "Descricao:"
	@ 55, 5  say "Modo [E/C]:"
	@ 25, 65 GET _sTabela  PICTURE "@!" valid vazio () .or. existchav ('ZX5', '00' + _sTabela)
	@ 40, 65 GET _sNomeTab PICTURE "@!"
	@ 55, 65 GET _sModo    PICTURE "@!"
	@ 120, 124 BMPBUTTON TYPE 1 ACTION Close(oDlg1)
	ACTIVATE DIALOG oDlg1 CENTERED
	if ! empty (_sTabela)
		// Se for a inclusao de uma nova tabela, a mesma deve ser criada na tabela 00 (descritor de tabelas)
		reclock ("ZX5", .T.)
		zx5 -> zx5_filial = "  "  // A tabela 00 (descritor) eh compartilhada.
		zx5 -> zx5_tabela = "00"
		zx5 -> zx5_chave  = _sTabela
		zx5 -> zx5_modo   = _sModo
		zx5 -> zx5_descri = _sNomeTab
		msunlock ()
	endif
return



// --------------------------------------------------------------------------
// Visualizacao, Alteracao, Exclusao
User Function ZX5A (_nOpcao, _sCodTab, _sLinhaOK, _sTudoOK, _lFiltro, _sPreFiltr, _aCposOrd)
	local _lContinua  := .T.
	local _aCampos    := {}
	local _sFilial    := ""
	local _sFiltro    := ""
	local _sSort1     := ''
	local _sSort2     := ''
	local _bSort      := NIL
	local _nCpoOrd    := 0
	local _nPosCpo    := 0
	local _nLinha     := 0
	private _sModo    := ""
	private _sTabela  := ""
	private _sNomeTab := ""
	private aHeader   := {}
	private aCols     := {}
	private N         := 1
	private inclui    := (_nOpcao == 3)
	private altera    := (_nOpcao == 4)
	private nOpc      := _nOpcao
	private _oTab     := NIL

	u_logIni ()
	zx5 -> (dbsetorder (1))
	if ! zx5 -> (dbseek (xfilial ("ZX5") + '00' + _sCodTab, .F.))
		u_help ("Cadastro da tabela '" + _sCodTab + "' nao encontrado no arquivo ZX5. Para ter dados cadastrados, uma tabela deve ser criada, antes, com chave '00' no arquivo ZX5.")
		_lContinua = .F.
	else
		_oTab := ClsTabGen ():New (_sCodTab)
	endif

	if _lContinua
		_lFiltro = iif (valtype (_lFiltro) == 'L', _lFiltro, .F.)
		if nOpc != 5 .and. _lFiltro
			_sFiltro  = U_Get ('Expressao para filtro adicional', 'C', 255, '', '', space (255), .F., '.t.')
			if empty (_sFiltro)
				_sFiltro = '.t.'
			endif
		else
			_sFiltro = '.T.'
		endif
		if valtype (_sPreFiltr) == 'C' .and. ! empty (_sPreFiltr)
			_sFiltro += '.and.' + _sPreFiltr
		endif
	endif

	if _lContinua
		CursorWait ()
		_sTabela  = iif (zx5 -> zx5_tabela == "00", zx5 -> zx5_chave, zx5 -> zx5_tabela)
		_sModo    = zx5 -> zx5_modo
		_sFilial  = iif (_sModo == "C", "  ", cFilAnt)
		_sNomeTab = fBuscaCpo ("ZX5", 1, xfilial ("ZX5") + "00" + _sTabela, "ZX5_DESCRI")
		_aCampos  = U_ZX5Cpos (_sTabela)
		aHeader := aclone (U_GeraHead ("", ;        // Arquivo
		                               .F., ;       // Para MSNewGetDados, informar .T.
		                               {}, ;        // Campos a nao incluir
		                               _aCampos, ;  // Campos a incluir
		                               .T.))        // Apenas os campos informados.
		
		aCols := aclone (U_GeraCols ("ZX5", ;      // Alias
		                             1, ;          // Indice
		                             _sFilial + _sTabela, ;  // Seek inicial
		                             "zx5_filial == '" + _sFilial + "' .and. zx5_tabela == '" + _sTabela + "'", ;  // While
		                             aHeader, ;    // aHeader
		                             .F., ;        // Nao executa gatilhos
		                             altera, ;     // Gera linha vazia, se nao encontrar dados.
		                             .T., ;        // Trava registros
		                             _sFiltro))    // Expressao para filtro adicional
		

		// Se recebeu array com campos para ordenacao do aCols, aplica-os
		if valtype (_aCposOrd) == 'A'

			// Monta string com expressao de ordenacao, para ser transformado em 'codeblock'
			_sSort1 = ''
			_sSort2 = ''
			for _nCpoOrd = 1 to len (_aCposOrd)
				_nPosCpo = ascan (aHeader, {|_aVal| upper (alltrim (_aVal [2])) == upper (alltrim (_aCposOrd [_nCpoOrd]))})
				if _nPosCpo > 0
					_sSort1 += "cvaltochar(_x[" + alltrim (str (_nPosCpo)) + "])"
					_sSort2 += "cvaltochar(_y[" + alltrim (str (_nPosCpo)) + "])"
					if _nCpoOrd < len (_aCposOrd)
						_sSort1 += '+'
						_sSort2 += '+'
					endif
				endif
			next
//			u_log ('Ordenando aCols por:', _sSort1) 
			_bSort = "{|_x, _y|" + _sSort1 + "<" + _sSort2 + "}"
			aCols = asort (aCols,,, &(_bSort))
		endif
		CursorArrow ()

		// Variaveis para o Modelo2
		aC   := {}
		aadd (aC, {"_sTabela",  {15, 5},   "Cod.tabela",  "@!", "", "", .f.})
		aadd (aC, {"_sNomeTab", {15, 100}, "Descricao",   "@!", "", "", FunName()=='ZX5'})
		aadd (aC, {"_sModo",    {30, 5},   "Modo acesso", "@!", "", "", .f.})
	
		aR   := {}
		aCGD := {80, 5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		N = 1
		_lContinua = Modelo2 ("Edicao da tabela " + _sTabela, ;  // Titulo
		                 aC, ;     // Cabecalho
		                 aR, ;     // Rodape
		                 aCGD, ;   // Coordenadas da getdados
		                 nOpc, ;   // nOPC
		                 "U_ZX5Lk ('" + _sTabela + "') .and. " + _sLinhaOK, ;  // Linha OK
		                 _sTudoOK, ;  // Tudo OK
		                 , ;       // Gets editaveis
		                 , ;       // bloco codigo para tecla F4
		                 , ;       // Campos inicializados
		                 999, ;    // Numero maximo de linhas
		                 {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}, ;  // Coordenadas da janela
		                 inclui .or. altera)      // Linhas podem ser deletadas.
	
	endif

	if _lContinua
		if nOpc == 5 .and. u_msgyesno ("Confirma a exclusao de toda a tabela " + _sTabela + "?")
			zx5 -> (dbseek (_sFilial + _sTabela, .T.))
			do while ! zx5 -> (eof ()) .and. zx5 -> zx5_filial == _sFilial .and. zx5 -> zx5_tabela == _sTabela
				reclock ("ZX5", .F.)
				zx5 -> (dbdelete ())
				msunlock ("ZX5")
				zx5 -> (dbskip ())
			enddo
			
			// Exclui a tabela do descritor (tabela 00)
			if zx5 -> (dbseek ("  " + "00" + _sTabela, .F.))
				reclock ("ZX5", .F.)
				zx5 -> (dbdelete ())
				msunlock ("ZX5")
			endif
		else

			// Atualiza descricao da tabela no descritor de tabelas.
			if zx5 -> (dbseek ("  " + "00" + _sTabela, .F.))
				reclock ("ZX5", .F.)
				zx5 -> zx5_descri = _sNomeTab
				msunlock ("ZX5")
			endif

			// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
			_aCposFora := {}
			aadd (_aCposFora, {"ZX5_FILIAL", _sFilial})
			aadd (_aCposFora, {"ZX5_TABELA", _sTabela})
			
			// Grava dados do aCols.
			zx5 -> (dbsetorder (1))
			for _nLinha = 1 to len (aCols)
				N = _nLinha

				// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
				if GDFieldGet ("ZZZ_RECNO") > 0
					zx5 -> (dbgoto (GDFieldGet ("ZZZ_RECNO")))

					// Se estah deletado em aCols, preciso excluir do arquivo tambem.
					if GDDeleted ()
						reclock ("ZX5", .F.)
						zx5 -> (dbdelete ())
						msunlock ("ZX5")
					else
						reclock ("ZX5", .F.)
						U_GrvACols ("ZX5", N, _aCposFora)
						msunlock ("ZX5")

						// Verifica necessidade de integracao com Mercanet
						if _sTabela $ '39/40/46'
							U_AtuMerc ('ZX5', zx5 -> (recno ()))
						endif
					endif

				else  // A linha ainda nao existe no arquivo
					if GDDeleted ()
						loop
					else
						reclock ("ZX5", .T.)
						U_GrvACols ("ZX5", N, _aCposFora)
						msunlock ("ZX5")

						// Verifica necessidade de integracao com Mercanet
						if _sTabela $ '39/40/46'
							U_AtuMerc ('ZX5', zx5 -> (recno ()))
						endif
					endif
				endif
			next
		endif
	endif
	zx5 -> (dbgotop ())
	u_logFim ()
return



// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function ZX5LK (_sTabela)
	local _lRet := .T.

	if _lRet .and. ! GDDeleted ()
		u_log ('Verificando campos duplicados:', _oTab:CposChave)
		_lRet = GDCheckKey (_oTab:CposChave, 4, {}, "Campos repetidos", .t.)
	endif
	
	if _lRet .and. GDDeleted ()

		// Por enquanto valida apenas quando tem o campo _COD, mas o certo seria melhorar isto.
		if len (_oTab:CposChave) == 1 .and. _oTab:CposChave [1] == 'ZX5_' + _oTab:CodTabela + 'COD'
			_lRet = _oTab:PodeExcl (GDFieldGet ('ZX5_' + _oTab:CodTabela + 'COD'))
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Monta lista de campos pertencentes `a tabela informada.
User Function ZX5Cpos (_sTabela)
	local _aCampos := {"ZX5_CHAVE"}
	if _sTabela == "00"
		aadd (_aCampos, "ZX5_DESCRI")
	else
		sx3 -> (dbsetorder (1))
		sx3 -> (dbseek ("ZX5", .T.))
		do while ! sx3 -> (eof ()) .and. sx3 -> x3_arquivo == "ZX5"
			if left (sx3 -> x3_campo, 6) == "ZX5_" + _sTabela
				aadd (_aCampos, sx3 -> x3_campo)
			endif
			sx3 -> (dbskip ())
		enddo
	endif

	// Adiciona sempre o campo RECNO para posterior uso em gravacoes.
	aadd (_aCampos, "ZZZ_RECNO")

return _aCampos              
