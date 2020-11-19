// Programa:  EditSX5
// Autor:     Robert Koch - TCX021
// Data:      10/10/2007
// Cliente:   Generico
// Descricao: Edicao de tabela especifica do arquivo SX5. Util para casos em que nao se deseja
//            liberar acesso ao SigaCFG para determinados usuarios.
//            A tabela jah deve existir no SX5. Serah permitida apenas sua alteracao.
//
// Historico de alteracoes:
// 18/07/2008 - Robert - Passa a retornar .T. ou .F. indicando se o usuario confirmou a gravacao.
//                     - Implementada execucao de 'Linha OK' e 'Tudo OK' do usuario.
//                     - Implementada chamada de funcoes apos inclusao, alteracao, etc.
//                     - Avisa quando a tabela nao existe no configurador.
// 04/11/2010 - Robert - Campo X5_CHAVE era exigido sempre.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Parametros:
// 1 - Codigo da tabela a editar
// 2 - Validacao para 'linha oK'
// 3 - Validacao para 'tudo oK'
// 4 - Maximo de linhas permitidas no modelo2
// 5 - .T. = permite deletar linhas
User Function EditSX5 (_sTabela, _sLinhaOK, _sTudoOK, _nMaxLin, _lPodeDel, _sAposInc, _sAposAlt, _sAntExc, _sAposExc)
	local _lRet       := .F.
	local _sFilialX5  := xFilial ("SX5")
	local _n		  := 1
	private aHeader   := {}
	private aCols     := {}
	private N         := 1
	private inclui    := .F.
	private altera    := .T.
	private nOpc      := 4

	_sAposInc := iif (_sAposInc == NIL, "NIL", _sAposInc)
	_sAposAlt := iif (_sAposAlt == NIL, "NIL", _sAposALt)
	_sAntExc  := iif (_sAntExc  == NIL, "NIL", _sAntExc)
	_sAposExc := iif (_sAposExc == NIL, "NIL", _sAposExc)

	// Tratamento especifico para a tabela 01, conforme pontos de entrada da versao padrao.
	if _sTabela == "01"
		if ExistBlock ("CHGX5FIL")
			_sFilialX5 := ExecBlock("CHGX5FIL",.f.,.f.)
		endif
	endif

	sx5 -> (dbsetorder (1))
	if ! sx5 -> (dbseek (_sFilialX5 + _sTabela, .T.))
		u_help ("Tabela " + _sTabela + " nao encontrada no configurador.")
		_lRet = .F.
	else

		aHeader := aclone (U_GeraHead (;
		"SX5", ;  // Arquivo
		.F., ;  // Para MSNeewGetDados, informar .T.
		{}, ;  // Campos a nao incluir
		{"X5_CHAVE", "X5_DESCRI", "X5_DESCSPA", "X5_DESCENG"}, ;  // Campos a incluir
		.T.))  // Apenas os campos informados.
		
		aCols := aclone (U_GeraCols (;
		"SX5", ;      // Alias
		1, ;          // Indice
		_sFilialX5 + _sTabela, ;  // Seek inicial
		"x5_filial == '" + _sFilialX5 + "' .and. x5_tabela == '" + _sTabela + "'", ;  // While
		aHeader, ;  // aHeader
		.F., ;        // Nao executa gatilhos
		.T., ;        // Gera linha vazia, se nao encontrar dados.
		.F.))         // Nao trava registros
		
		// Variaveis para o Modelo2
		aC:={}
		aR   := {}
		aCGD := {60, 5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}  // 118,315}
		N = 1
		
	   //	Modelo2(cTitulo,aC,aR,aGetdados,nOpc,"Allwaystrue()","Allwaystrue()", , ) 
		
		
		_lRet = Modelo2 (;
			"Edicao da tabela " + _sTabela, ;  // Titulo
			aC, ;  // Cabecalho
			aR, ;  // Rodape
			aCGD, ;  // Coordenadas da getdados
			nOpc, ;  // nOPC
			"U_EditSX5K (.T., .F.) .and. " + _sLinhaOK, ;  // Linha OK
			"U_EditSX5K (.F., .T.) .and. " + _sLinhaOK + " .and. " + _sTudoOK, ;  // Tudo OK
			, ;  // Gets editaveis
			, ;  // bloco codigo para tecla F4
			, ;  // Campos inicializados
			_nMaxLin, ;  // Numero maximo de linhas
		   	{100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}, ;  // Coordenadas da janela
		   	_lPodeDel)  // Linhas podem ser deletadas.
	
	
		if _lRet
	
			// Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
			_aCposFora := {}
			aadd (_aCposFora, {"X5_FILIAL", _sFilialX5})
			aadd (_aCposFora, {"X5_TABELA", _sTabela})
			
			// Grava dados do aCols.
			sx5 -> (dbsetorder (1))
			For _n = 1 to len (aCols)
				N := _n
				
				// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
				if sx5 -> (dbseek (_sFilialX5 + _sTabela + GDFieldGet ("X5_CHAVE"), .F.))
					
					// Se estah deletado em aCols, preciso excluir do arquivo tambem.
					if GDDeleted ()
						&(_sAntExc) // Executa funcao especifica antes da exclusao de registro.
						reclock ("SX5", .F.)
						sx5 -> (dbdelete ())
						msunlock ("SX5")
						&(_sAposExc)  // Executa funcao especifica apos exclusao de registro.
					else
						reclock ("SX5", .F.)
						U_GrvACols ("SX5", N, _aCposFora)
						msunlock ("SX5")
						&(_sAposAlt)  // Executa funcao especifica apos alteracao de registro.
					endif
					
				else  // A linha ainda nao existe no arquivo
	
					if GDDeleted ()
						loop
					else
						reclock ("SX5", .T.)
						U_GrvACols ("SX5", N, _aCposFora)
						msunlock ("SX5")
						&(_sAposInc)  // Executa funcao especifica apos inclusao de registro.
					endif
				endif
			next
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacoes.
user function EditSX5K (_lLinha, _lTudo)
	local _lRet := .T.
	
	// Valida 'Linha OK'
	if _lLinha .and. ! GDDeleted ()
		if _lRet
			//if empty (GDFieldGet ("X5_CHAVE")) .or. empty (GDFieldGet ("X5_DESCRI")) .or. empty (GDFieldGet ("X5_DESCSPA")) .or. empty (GDFieldGet ("X5_DESCENG"))
			if empty (GDFieldGet ("X5_DESCRI")) .or. empty (GDFieldGet ("X5_DESCSPA")) .or. empty (GDFieldGet ("X5_DESCENG"))
				u_help ("Ha' campos nao informados.")
				_lRet = .F.
			endif
		endif

		// Verifica chave duplicada.
		if _lRet
			_lRet = GDCheckKey ({"X5_CHAVE"}, 4)
		endif
	endif

return _lRet
