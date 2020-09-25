// Programa...: LeBalan2
// Autor......: Robert Koch
// Data.......: 19/07/2016
// Descricao..: Leitura de peso de balanca Saturno (portaria matriz) via executavel.
//              Baseia-se em executavel LESBR140-FULL obtido no site das Balancas Saturno.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function LeBalan2 ()
	local _nRet      := 0
	local _sArqPeso  := "C:\LESBR\PESO.TXT"
	local _sProgPeso := "C:\LESBR\LESBR140.EXE"
	local _sLinha    := ""
	local _lContinua := .T.
	local _nTenta    := 0
//	u_logIni ()
	
	if _lContinua .and. ! file (_sProgPeso)
		u_help ("Programa de leitura de peso nao encontrado --> " + _sProgPeso)
		_lContinua = .F.
	endif

	// Apaga o arquivo de peso para evitar leitura de dados antigos.
	do while _lContinua .and. file (_sArqPeso) .and. _nTenta++ < 5
		ferase (_sArqPeso)
		sleep (1000)
	enddo
	if file (_sArqPeso)
		u_help ("Nao foi possivel apagar o arquivo com o peso anterior --> " + _sArqPeso)
		_lContinua = .F.
	endif
	
	// Executa programa especifico. Configuracoes no arquivo MENU.INI no mesmo diretorio.
	if _lContinua
		/* Exemplo:
		#define SW_HIDE             0 // Escondido
		#define SW_SHOWNORMAL       1 // Normal
		#define SW_NORMAL           1 // Normal
		#define SW_SHOWMINIMIZED    2 // Minimizada
		#define SW_SHOWMAXIMIZED    3 // Maximizada
		#define SW_MAXIMIZE         3 // Maximizada
		#define SW_SHOWNOACTIVATE   4 // Na Ativação
		#define SW_SHOW             5 // Mostra na posição mais recente da janela
		#define SW_MINIMIZE         6 // Minimizada
		#define SW_SHOWMINNOACTIVE  7 // Minimizada
		#define SW_SHOWNA           8 // Esconde a barra de tarefas
		#define SW_RESTORE          9 // Restaura a posição anterior
		#define SW_SHOWDEFAULT      10// Posição padrão da aplicação
		#define SW_FORCEMINIMIZE    11// Força minimização independente da aplicação executada
		#define SW_MAX              11// Maximizada
		WaitRun("CALC.EXE", SW_SHOWNORMAL )
		*/
		if waitrun (_sProgPeso, 5) != 0
			_lContinua = .F.
		endif
	endif

	// Leitura do arquivo gerado pelo executavel.
	if _lContinua .and. file (_sArqPeso)  // Em caso de peso zerado, o executavel nao gera o arquivo de peso.
		FT_FUSE(_sArqPeso)
		FT_FGOTOP()
		if !FT_FEOF()
			_sLinha := FT_FReadLN()
		endif
		FT_FUSE()
//		u_log (_sLinha)
		if left (_sLinha, 6) == '[Bruto' .and. substr (_sLinha, 19, 1) == ']'
			_nRet = val (substr (_sLinha, 7, 12))
		else
			u_help ("Arquivo de peso (" + _sArqPeso + ") retornou conteudo invalido: " + _sLinha)
		endif
	endif
 
//	u_log ('retornando Peso = ', _nRet)
//	u_logFim ()
return _nRet
