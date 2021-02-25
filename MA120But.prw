// Programa....: MA120But
// Autor.......: Robert Koch
// Data........: 12/07/2012
// Descricao...: P.E. para inclusao de botoes nas telas de pedido de compras e autorizacoes de entrega.
//               Criado inicialmente para chamar tela de dados adicionais.
//
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para inclusao de botoes nas telas de pedido de compras e autorizacoes de entrega
// #PalavasChave      #pedido_de_compra #pedido #compras #botoes
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM
//
// Historico de alteracoes:
// 06/10/2015 - Robert - Passa extensao na chamada da visualizacao de especificacoes / imagem do produto.
// 25/02/2021 - Claudia - Observações para pedidos de serviço. GLPI: 7846
//
// ---------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#Include "PROTHEUS.CH"    

User Function MA120But()
	local _aRet := {}

	aadd (_aRet, {"LANDSCAPE", {|| _Menu ()}, "Especificos"})

Return _aRet
//
// --------------------------------------------------------------------------
// Menu
static function _Menu ()
	local _aF3      := {}
	local _nF3      := 0
	local _aCols    := {}
	local _aAmbAnt  := U_SalvaAmb ()
	local _aAreaAnt := U_ML_SRArea ()

	// Colunas para menu de opcoes
	aadd (_aCols, {1, "Opcao",     100, ""})

	// Define opcoes a mostrar
	aadd (_aF3, {"Dados adicionais pedido",           "DadosAdic"})
	aadd (_aF3, {"Eventos do pedido",                 "Eventos"})
	aadd (_aF3, {"Visualizar especificacoes produto", "Espec_produto"})
	aadd (_aF3, {"Visualizar imagem do produto",      "Imagem_produto"})
	aadd (_aF3, {"Cancelar",                          "Cancelar"})
	aadd (_aF3, {"Obs.Serviços",                      "ObsServico"})

	_nF3 = U_F3Array (_aF3, procname () + " - Opcoes", _aCols, oMainWnd:nClientWidth / 3, oMainWnd:nClientHeight / 1.5, "", "", .F.)
	do case
	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "DadosAdic"
		_DadosAdic ()

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Eventos"
		U_VA_SZNC ("PedCompra", CA120Num)

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Espec_produto"
		U_EspPrd (GDFieldGet ("C7_PRODUTO"), 'PDF')

	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "Imagem_produto"
		U_EspPrd (GDFieldGet ("C7_PRODUTO"), 'JPG')
	
	case _nF3 != 0 .and. _aF3 [_nF3, 2] == "ObsServico"
		_ObsServico ()

	endcase

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)

return
//
// --------------------------------------------------------------------------
// Dados adicionais
static function _DadosAdic ()
	local _oDlg     := NIL
	local _oGetMemo := NIL
	local _sTitulo  := "Dados acicionais"
	local _sTexto   := ""
	local _oSQL     := ClsSQL():New ()
	local _sChave   := "SC7" + cEmpAnt + cFilAnt + CA120Num
	local _nTamMax  := 7998  // Sao 8000 caracteres do camposvarchar + 2 caracteres de controle (final de campo).
	private _nOpcao := 0

	// Leitura dos dados anteriores (para caso de alteracao).
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT RTRIM (CAST (CAST (TEXTO AS VARBINARY (8000)) AS VARCHAR (8000))) AS TEXTO"
	_oSQL:_sQuery +=  " FROM VA_TEXTOS"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CHAVE = '" + _sChave + "'"
	_sTexto = alltrim (_oSQL:RetQry ())  // Preciso do ALLTRIM por que o TopConnect retorna com 8000 caracteres cfe. configurado no SQL.

	// Leitura em loop para possibilitar validacoes.
	do while .T.
		_nOpcao = 0
		define msdialog _oDlg from 0, 0 to oMainWnd:nClientHeight - 250, oMainWnd:nClientwidth - 200 of oMainWnd pixel title _sTitulo
			@ 15, 15 get _sTexto MEMO size (_oDlg:nClientWidth / 2 - 30), (_oDlg:nClientHeight / 2 - 50) when .T. object _oGetMemo // Se colocar when .F., nao tem barra de rolagem
			
			// Soh habilita o botao 'Ok' se estiver alterando o pedido. Isso por que o usuario poderia
			// chamar a inclusao, gravar as observacoes e depois cancelar a inclusao do pedido.
			if altera
				@ (_oDlg:nClientHeight / 2 - 25), (_oDlg:nClientWidth / 2 - 80) bmpbutton type 1 action (_nOpcao := 1, close (_oDlg))
			endif

			@ (_oDlg:nClientHeight / 2 - 25), (_oDlg:nClientWidth / 2 - 40) bmpbutton type 2 action (_nOpcao := 0, close (_oDlg))
			_oGetMemo:oFont := TFont():New ("Courier New", 7, 16)
		activate msdialog _oDlg center

		if _nOpcao == 0
			exit
		endif
		if _nOpcao == 1
			_sTexto = alltrim (_sTexto)
			if len (_sTexto) > _nTamMax
				u_help ("O texto informado contem " + cvaltochar (len (_sTexto)) + " caracteres. Tamanho maximo: " + cvaltochar (_nTamMax) + " caracteres.")
				loop
			endif
			exit
		endif
	enddo

	// Se o usuario informou aspas simples, troco-as por aspas duplas por que
	// o SQL delimita as strings com aspas simples.
	_sTexto = alltrim (strtran (_sTexto, "'", '"'))

	if _nOpcao == 1

		// Verifica existencia da chave. O registro poderah ser reativado, caso esteja deletado.
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM VA_TEXTOS"
		_oSQL:_sQuery += " WHERE CHAVE = '" + _sChave + "'"
		if _oSQL:RetQry () > 0
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE VA_TEXTOS"
			_oSQL:_sQuery +=   " SET D_E_L_E_T_ = ' ',"
			_oSQL:_sQuery +=       " TEXTO = '" + _sTexto + "'"
			_oSQL:_sQuery += " WHERE CHAVE = '" + _sChave + "'"
			_oSQL:Exec ()
		elseif ! empty (_sTexto)  // Soh inclui se tiver texto a gravar.
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "INSERT INTO VA_TEXTOS (CHAVE, D_E_L_E_T_, TEXTO)"
			_oSQL:_sQuery += " VALUES ('" + _sChave + "',"
			_oSQL:_sQuery +=          "' ',"
			_oSQL:_sQuery +=          "'" + _sTexto + "')"
			_oSQL:Exec ()
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Observação de serviço
static function _ObsServico ()
	Local oButton1
	Local oButton2
	Local oMultiGe1
	Local _lRet     := .F.
	Local _sTexto   := " "
	Local _oSQL     := ClsSQL():New ()
	Local _sChave   := 'OBS_SERVICO'
	Static oDlg

	// Leitura dos dados anteriores (para caso de alteracao).
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT RTRIM (CAST (CAST (TEXTO AS VARBINARY (8000)) AS VARCHAR (8000))) AS TEXTO"
	_oSQL:_sQuery +=  " FROM VA_TEXTOS"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND CHAVE = '" + _sChave + "'"
	_sTexto = alltrim (_oSQL:RetQry ())  // Preciso do ALLTRIM por que o TopConnect retorna com 8000 caracteres cfe. configurado no SQL.

	DEFINE MSDIALOG oDlg TITLE "Obsercações de Serviço" FROM 000, 000  TO 600, 800 COLORS 0, 16777215 PIXEL

	@ 007, 006 GET oMultiGe1 VAR _sTexto OF oDlg MULTILINE SIZE 387, 275 COLORS 0, 16777215 HSCROLL PIXEL
	@ 285, 342 BUTTON oButton1 PROMPT "Salvar" SIZE 050, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL
	@ 285, 287 BUTTON oButton2 PROMPT "Sair" SIZE 050, 012 OF oDlg ACTION  (_lRet := .F., oDlg:End ()) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	if _lRet
		// Verifica existencia da chave. O registro poderah ser reativado, caso esteja deletado.
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM VA_TEXTOS"
		_oSQL:_sQuery += " WHERE CHAVE = '" + _sChave + "'"
		if _oSQL:RetQry () > 0
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "UPDATE VA_TEXTOS"
			_oSQL:_sQuery +=   " SET D_E_L_E_T_ = ' ',"
			_oSQL:_sQuery +=       " TEXTO = '" + _sTexto + "'"
			_oSQL:_sQuery += " WHERE CHAVE = '" + _sChave + "'"
			_oSQL:Exec ()
		elseif ! empty (_sTexto)  // Soh inclui se tiver texto a gravar.
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "INSERT INTO VA_TEXTOS (CHAVE, D_E_L_E_T_, TEXTO)"
			_oSQL:_sQuery += " VALUES ('" + _sChave + "',"
			_oSQL:_sQuery +=          "' ',"
			_oSQL:_sQuery +=          "'" + _sTexto + "')"
			_oSQL:Exec ()
		endif
	endif
return
