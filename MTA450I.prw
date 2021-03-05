// Programa...: MTA450I
// Autor......: Robert Koch
// Data.......: 04/12/2008
// Cliente....: Alianca
// Descricao..: P.E. apos inclusao (por item) do SC9 na liberacao de pedido (credito).
//              Criado inicialmente para gravar log de eventos.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos inclusao (por item) do SC9 na liberacao de pedido (credito).
// #PalavasChave      #liberacao_de_pedido #liberacao_de_credito
// #TabelasPrincipais #SC5 #SC9
// #Modulos   		  #FAT
//
// Historico de alteracoes:
// 04/03/2021 - Claudia - Incluída tela de inclusão de NSU e Cod.autorização. GLPI: 9075
//
// --------------------------------------------------------------------------------------------
#Include "PROTHEUS.CH"   

User Function MTA450I()
	local _oEvento  := NIL

	_oEvento := ClsEvent():new ()
	_oEvento:CodEven   = "SC9002"
	_oEvento:Texto     = "Liberacao credito pedido c/ Banco=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_BANCO") + " e cond.pagto.=" + fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_CONDPAG")
	_oEvento:Cliente   = sc9 -> c9_cliente
	_oEvento:LojaCli   = sc9 -> c9_loja
	_oEvento:PedVenda  = sc9 -> c9_pedido
	_oEvento:Produto   = sc9 -> c9_produto
	_oEvento:Grava ()

	// verifica se é link cielo para atualizar NSU e autorização
	_sTipo := fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_VATIPO")
	_sNsu  := fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_VANSU")
	_sAut  := fBuscaCpo ("SC5", 1, xfilial ("SC5") + sc9 -> c9_pedido, "C5_VAAUT")

	If alltrim(_sTipo) $ 'CC/CD' .and. (cFilAnt == '01' .or. cFilAnt == '16') // se sao itens de cartões da matriz ou F16
		If empty(_sNsu) .and. empty(_sAut)
			If MsgYesNo("NSU/Código Autorização", "Deseja incluir NSU/Cód.Autorização?")
				IncluirCod(xfilial ("SC5"),sc9 -> c9_pedido)
			EndIf
		EndIf
	EndIf
Return
//
// --------------------------------------------------------------------------
// Observação de serviço
Static function IncluirCod(_sFilial, _sPedido)                    
	Local oButton1
	Local oGet1
	Local _sNSU := "         "
	Local oGet2
	Local _sAut := "      "
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4 := alltrim(_sFilial) +'/'+ alltrim(_sPedido)
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Inclusão de NSU/Cod.Autorização" FROM 000, 000  TO 140, 335 COLORS 0, 16777215 PIXEL

		@ 025, 012 SAY oSay1 PROMPT "Nsu:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 037, 012 SAY oSay2 PROMPT "Cód.Autorização:" SIZE 046, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 012, 012 SAY oSay3 PROMPT "PEDIDO:" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 025, 055 MSGET oGet1 VAR _sNSU SIZE 100, 010 OF oDlg COLORS 0, 16777215 PIXEL
		@ 037, 055 MSGET oGet2 VAR _sAut SIZE 100, 010 OF oDlg COLORS 0, 16777215 PIXEL
		@ 012, 055 SAY oSay4  SIZE 100, 007 OF oDlg COLORS 0, 16777215 PIXEL
    	@ 055, 115 BUTTON oButton1 PROMPT "Gravar" SIZE 040, 010 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL
    	@ 055, 069 BUTTON oButton2 PROMPT "Sair" SIZE 040, 010 OF oDlg ACTION  (_lRet := .F., oDlg:End ()) PIXEL
	ACTIVATE MSDIALOG oDlg CENTERED

	If _lRet
		dbSelectArea("SC5")
		dbSetOrder(1) // C5_FILIAL + C5_NUM
		dbGoTop()
		If dbSeek(_sFilial + _sPedido)
			RecLock("SC5", .F.)	
				SC5 -> C5_VANSU := _sNSU
				SC5 -> C5_VAAUT := _sAut
			MsUnLock()
		EndIf
	EndIf
Return


