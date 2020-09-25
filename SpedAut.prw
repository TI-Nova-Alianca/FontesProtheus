// Programa...: SPEDAut
// Autor......: Robert Koch
// Data.......: 29/04/2015
// Descricao..: Programa auxiliar a ser chamado apos a geracao de notas de saida (modulos de faturamento e OMS)
//              e de entrada (com formulario proprio). Verifica se as notas estao autorizadas e chama impressao de DANFe.
//
// Historico de alteracoes:
// 08/03/2017 - Robert - Melhorado teste de 'ambiente' para evitar envio de notas a partir da base 'teste'.
// 22/08/2019 - Robert - Seleciona arquivo SF2 antes de chamar rotina de transmissao (tentava dar RETINDEX em arquivo ja fechado). GLPI 6531.
//

#include "rwmake.ch"  // Deixar este include para aparecerem os botoes da tela de acompanhamento do SPED

// --------------------------------------------------------------------------
user function SPEDAut (_sEntSai, _sSerie, _sNFIni, _sNFFim)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aAmbAnt   := U_SalvaAmb ()
	local _oSQL      := NIL
	local _oNFe      := NIL
	local _aNotas    := {}
	local _nNota     := 0
	local _sRetSEFAZ := ''
	local _oDlg      := NIL
	local _oLbx      := NIL
	local _lContinua := .T.
	private _lRefresh := .F.

//	u_logIni ()

	if _lContinua
		if "TESTE" $ upper (GetEnvServer()) .or. "R2" $ upper (GetEnvServer())
			if type ("oMainWnd") == "O"  // Se tem interface com o usuario
				if ! U_msgnoyes ("Ambiente de TESTE. Confirme se deseja enviar as notas para a SEFAZ")
					_lContinua = .F.
				endif
			else
				u_help ("[" + procname () + "]: Ambiente de TESTES. O envio de notas para a SEFAZ deve ser confirmado pelo usuario, quando houver interface em uso.")
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		
		// Jah tive caso onde o sistema parecia estar tentando restaurar um indice de um arquivo ja fechado.
		// Vou selecionar um arquivo padrao e acompanhar para ver se resolve (GLPI 6531)
		dbselectarea ("SF2")

		// Variaveis usadas pelas rotinas da NFe
		private bFiltraBrw := {||".T."}
		private aFilBrw := {"SF2", ".T."}
	
		// Transmissao.
		SpedNFeRe2(_sSerie, _sNFIni, _sNFFim)  // Serie, NF ini, NF fim
	
		// Monitora autorizacao da SEFAZ.
		_oSQL := ClsSQL ():New ()
		if _sEntSai == 'E'
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT F1_DOC, '', '', ''"
			_oSQL:_sQuery +=   " FROM " + RETSQLName ("SF1") + " SF1 "
			_oSQL:_sQuery +=  " WHERE F1_FILIAL   = '" + xFilial ("SF1") + "'"
			_oSQL:_sQuery +=    " AND D_E_L_E_T_  = ' '"
			_oSQL:_sQuery +=    " AND F1_SERIE    = '" + _sSerie + "'"
			_oSQL:_sQuery +=    " AND F1_DOC      BETWEEN '" + _sNFIni + "' AND '" + _sNFFim + "'"
			_oSQL:_sQuery +=    " AND F1_FORMUL   = 'S'"
		else
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT F2_DOC, '', '', ''"
			_oSQL:_sQuery +=   " FROM " + RETSQLName ("SF2") + " SF2 "
			_oSQL:_sQuery +=  " WHERE F2_FILIAL   = '" + xFilial ("SF2") + "'"
			_oSQL:_sQuery +=    " AND D_E_L_E_T_  = ' '"
			_oSQL:_sQuery +=    " AND F2_SERIE    = '" + _sSerie + "'"
			_oSQL:_sQuery +=    " AND F2_DOC      BETWEEN '" + _sNFIni + "' AND '" + _sNFFim + "'"
		endif
		_aNotas := aclone (_oSQL:Qry2Array ())
		for _nNota = 1 to len (_aNotas)
			_aNotas [_nNota, 4] = .F.  // Inicialmente considero todas 'nao autorizadas'. 
		next
		do while .T.

			// Dorme um pouquinho, para poupar o sistema de usuarios nervosos. Nao adianta
			// monitorar imediatamente apos a transmissao das notas.
			MsgRun ("Preparando ambiente", "Ta me dando um sono...", {|| sleep (2000)})
			
			_oNFe := ClsNFe ():New ()
			for _nNota = 1 to len (_aNotas)
				if ! _aNotas [_nNota, 4]  // Se jah estah autorizada, nao precisa mais verificar.
					_oNFe:IdNFe050 = _sSerie + _aNotas [_nNota, 1]
					MsgRun ("Verificando NF-e " + _aNotas [_nNota, 1], "To quase dormindo...", {|| _sRetSEFAZ := _oNFe:ConsAutFP ()})
					if _sRetSEFAZ != '100'  // Retorno 100 = nota autorizada.
						_aNotas [_nNota, 3] = "Impossivel verificar a NF-e junto `a SEFAZ. Tente novamente mais tarde."
						_aNotas [_nNota, 4] = .F.
					else
						_aNotas [_nNota, 3] = 'Nota autorizada'
						_aNotas [_nNota, 4] = .T.
					endif
				endif
			next
	
			// Mostra status ao usuario
			define msdialog _oDlg title "Acompanhamento SEFAZ" from 0, 0 to oMainWnd:nClientHeight / 1.5, oMainWnd:nClientWidth / 1.5 of oMainWnd pixel
			_oLbx := TWBrowse ():New (15,;      // Linha
			10, ;                               // Coluna
			_oDlg:nClientWidth / 2 - 20, ;      // Largura
			_oDlg:nClientHeight / 2 - 60, ;     // Altura
			NIL, ;                              // Campos
			{"NF", "Chave", "Mensagem"}, ;      // Cabecalhos colunas
			{50,   80,      250}, ;             // Larguras colunas
			_oDlg,,,,,,,,,,,,.F.,,.T.,,.F.,,,)  // Etc. Veja pasta IXBPAD
			_oLbx:SetArray (_aNotas)
			_oLbx:bLine := {|| _aNotas [_oLbx:nAt]}
			@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 210 button "Refresh"   size 60, 14 action (_lRefresh := .T., _oDlg:End ())
			@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 140 button "SPED NF-e" size 60, 14 action (SPEDNFE ())
			@ _oDlg:nClientHeight / 2 - 30, _oDlg:nClientWidth / 2 - 70  button "Ok"        size 60, 14 action (_lRefresh := .F., _oDlg:End ())
			activate dialog _oDlg centered
	
			if ! _lRefresh
				exit
			endif
		enddo
	
		if ascan (_aNotas, {|_aVal| _aVal [4] == .F.}) == 0  .or. U_MsgYesNo ("Ha notas nao autorizadas. Deseja executar a impressao assim mesmo?")
		
			// Grava parametros para impressao de DANFe
			U_GravaSX1 ("NFSIGW", "01", _sNFIni)
			U_GravaSX1 ("NFSIGW", "02", _sNFFim)
			U_GravaSX1 ("NFSIGW", "03", _sSerie)
			U_GravaSX1 ("NFSIGW", "04", iif (_sEntSai == 'E', 1, 2))  // 1=Entrada;2=Saida
	
			SpedDanfe ()  // Impressao do DANFe
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
//	u_logFim ()
return
