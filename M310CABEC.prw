// Programa...: M310CABEC
// Autor......: Andre Alves
// Data.......: 06/04/2020
// Descricao..: Manipula��o do array aCabec 
//              Executada ap�s a montagem do array Acabec antes das chamadas das rotinas 
//              autom�ticas que ir�o gerar 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Manipula��o do array aCabec
// #PalavasChave      #Transferencias #Transferencias_de_produtos #transferencias_entre_filiais 
// #TabelasPrincipais #SC5 #SC6 #SD1 #SF1
// #Modulos   		  #COM 
//
// Historico de alteracoes:
// 06/04/2020 - Andre   - Criado par preencher Frete na tela de transferencia entre filiais.
// 01/09/2021 - Claudia - Incluido a grava��o do campo C5_INDPRES que � obrigat�rio. GLPI: 10881
// 03/09/2021 - Claudia - Incluida tela de observa��o. GLPI: 10894
//
// ---------------------------------------------------------------------------------------------------
#Include "PROTHEUS.CH"

User Function M310CABEC
	Local cProg  := PARAMIXB[1]
	Local aCabec := PARAMIXB[2]
	local _sTPFrete := ""
	local _sTransp  := ""

	If cProg == 'MATA410' 
	    _sTPFrete := U_Get ("Informe o tipo de frete:", "C", 1, "", "", sc5 -> c5_tpfrete, .F., '.t.')
	   	aadd(aCabec,{'C5_TPFRETE',_sTPFrete,Nil})

	   	_sTransp := U_Get ("Informe a transportadora:", "C", 6, "", "SA4", sc5 -> c5_transp, .F., '.t.')
	   	aadd(aCabec,{'C5_TRANSP', _sTransp,Nil})

		_sObs := BuscaObs(sc5->c5_obs)
	   	aadd(aCabec,{'C5_OBS', _sObs, Nil})

		aadd(aCabec,{'C5_VAOBSNF', 'S',Nil})

		aadd(aCabec,{'C5_INDPRES', '1',Nil})
	endif
Return(aCabec)
//
//--------------------------------------------------------------------------
// Dados complementares/Observa��o
Static Function BuscaObs(_mObs)
Local oButton1
Local oMultiGe1
Local oSay1
Static oDlg

  DEFINE MSDIALOG oDlg TITLE "Entrada de dados" FROM 000, 000  TO 220, 400 COLORS 0, 16777215 PIXEL

    @ 008, 008 SAY oSay1 PROMPT "Observa��o:" SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 017, 009 GET oMultiGe1 VAR _mObs OF oDlg MULTILINE SIZE 179, 071 COLORS 0, 16777215 HSCROLL PIXEL
	@ 095, 008 BUTTON oButton1 PROMPT "Ok" SIZE 029, 011 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

    if _lRet
		_sValOBS := _mObs
	else
		_sValOBS := ""
	endif

Return _sValOBS
