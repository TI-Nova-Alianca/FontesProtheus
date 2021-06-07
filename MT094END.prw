
// Programa.: MT094END
// Autor....: Claudia Lionço
// Data.....: 04/05/2021
// Descricao: P.E. executado antes da conclusão do tipo de operação que está em andamento
//            Criado inicialmente para gravar observação de liberação.
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. executado antes da conclusão do tipo de operação que está em andamento
// #PalavasChave      #pedido_de_compra #liberacao_de_pedido
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
//
// -----------------------------------------------------------------------------------------
#Include 'Protheus.ch'

User Function MT094END()
    Local cDocto  := PARAMIXB[1]
    //Local cTipo   := PARAMIXB[2]
    //Local nOpc    := PARAMIXB[3]
    Local cFilDoc := PARAMIXB[4]

    _ObsMATA094(cFilDoc, cDocto)

Return
//
// --------------------------------------------------------------------------
// Observação de liberação de pedidos de compras
static function _ObsMATA094(cFilDoc,cDocto)
	Local oButton1
	Local oButton2
	Local oMultiGe1
	Local _lRet     := .F.
	Local _sTexto   := " "
	Local _oSQL     := ClsSQL():New ()
	Local _sChave   := 'MATA094' + cFilDoc + cDocto
	Static oDlg

	// Leitura dos dados anteriores (para caso de alteracao).
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT RTRIM (CAST (CAST (TEXTO AS VARBINARY (8000)) AS VARCHAR (8000))) AS TEXTO"
	_oSQL:_sQuery += " FROM VA_TEXTOS"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CHAVE = '" + _sChave + "'"
	_sTexto = alltrim (_oSQL:RetQry ())  

	DEFINE MSDIALOG oDlg TITLE "Observação da Aprovação" FROM 000, 000  TO 600, 800 COLORS 0, 16777215 PIXEL

	@ 007, 006 GET oMultiGe1 VAR _sTexto OF oDlg MULTILINE SIZE 387, 275 COLORS 0, 16777215 HSCROLL PIXEL
	@ 285, 342 BUTTON oButton1 PROMPT "Salvar" SIZE 050, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL
	@ 285, 287 BUTTON oButton2 PROMPT "Sair" SIZE 050, 012 OF oDlg ACTION  (_lRet := .F., oDlg:End ()) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	if _lRet
		// Verifica existencia da chave. O registro poderah ser reativado, caso esteja deletado.
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT COUNT (*)"
		_oSQL:_sQuery += " FROM VA_TEXTOS"
		_oSQL:_sQuery += " WHERE CHAVE = '" + _sChave + "'"
		if _oSQL:RetQry () > 0
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " UPDATE VA_TEXTOS"
			_oSQL:_sQuery += " SET D_E_L_E_T_ = ' ',"
			_oSQL:_sQuery += "       TEXTO = '" + _sTexto + "'"
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
