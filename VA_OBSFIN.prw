// Programa...: VA_OBSFIN
// Autor......: Cláudia Lionço
// Data.......: 27/11/2020
// Descricao..: Tela para gravação e visualização de observações financeiras
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Tela #Atualizacao
// #Descricao         #Tela para gravação e visualização de observações financeiras
// #PalavasChave      #observacoes_financeiras #cliente
// #TabelasPrincipais #SZN 
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 07/12/2020 - Claudia - Inclusão de botao para visualização de observações 
//                        de clientes. GLPI: 8971
// 03/02/2021 - Cláudia - Ajuste para visualização das OBS nas demais filiais. GLPI: 9263
// 12/02/2021 - Cláudia - Alterada a estrutura para criar uma tabela temporária 
//                        para manipulação dos dados. GLPI: 9263
//
// ---------------------------------------------------------------------------------------

#include "rwmake.ch"
#Include "PROTHEUS.CH"   

User Function VA_OBSFIN(_sTipo,_sCliente, _sLoja)
	Local aStruct     := {}
	Local aHead       := {}
	Local _aArqTrb    := {}
	Local aDados      := {}
	local i           := 0
	Private cCadastro := "Observações financeiras "	
	Private cDelFunc  := ".T."
	Private cString   := "SZN"
	Private aRotina   := {}
	

	If !u_zzuvl ('036', __cUserId, .T.)
		Return
	EndIf

	If _sTipo == '1'
		_sCliente := M->A1_COD
		_sLoja    := M->A1_LOJA
	EndIf

	_VerificaOBS(_sCliente, _sLoja)

	AAdd( aHead, { "Data"      ,{|| TOBS->DT}       ,"D", 08 , 0, "" } )
	AAdd( aHead, { "Hora"      ,{|| TOBS->HORA}     ,"C", 08 , 0, "" } )
	AAdd( aHead, { "Usuário"   ,{|| TOBS->USU}      ,"C", 15 , 0, "" } )
	AAdd( aHead, { "Obs"       ,{|| TOBS->OBS}      ,"C", 20000 , 0, "" } )
	
	AAdd( aStruct, { "DT"      , "D", 08, 0 } )
	AAdd( aStruct, { "HORA"    , "C", 08, 0 } )
	AAdd( aStruct, { "USU"     , "C", 15, 0 } )
	AAdd( aStruct, { "OBS"     , "M", 30, 0 } )
	
	U_ArqTrb ("Cria", "TOBS", aStruct, {"DT + HORA + USU"}, @_aArqTrb)		

	_sSQL := " SELECT"
	_sSQL += " 	   ZN_DATA"
	_sSQL += "    ,ZN_HORA"
	_sSQL += "    ,ZN_USUARIO"
	_sSQL += "    ,ISNULL(CAST(CAST(ZN_TXT AS VARBINARY(8000)) AS VARCHAR(8000)), '')"
	_sSQL += " FROM SZN010"
	_sSQL += " WHERE D_E_L_E_T_ = '' "
	_sSQL += " AND ZN_CLIENTE = '" + _sCliente + "'"
	_sSQL += " AND ZN_LOJACLI   = '" + _sLoja    + "'"
	_sSQL += " AND ZN_CODEVEN   = 'SA1004'"
	aDados := U_Qry2Array(_sSQL)
	
	If len (aDados) > 0
		For i :=1 to len(aDados)
			DbSelectArea("TOBS")
			RecLock("TOBS",.T.)
				TOBS-> DT      := aDados[i, 1]
				TOBS-> HORA    := aDados[i, 2]
				TOBS-> USU     := aDados[i, 3]
				TOBS-> OBS     := aDados[i, 4]
				
			MsUnLock()
		Next
	Endif

	aRotina   := {	{"Observações"	,"U_VAOBSFIN('"+_sCliente +"','"+_sLoja+"')"	,0,6} ,;
					{"Visualizar"	,"U_VAOBSVIS('"+_sCliente +"','"+_sLoja+"')"	,0,6} ,;
					{"Excluir"   	,"U_VAOBSEXC('"+_sCliente +"','"+_sLoja+"')"	,0,6}  }

    dbSelectArea("TOBS")
	dbSetOrder(1)

	mBrowse(6,1,22,75,"TOBS",aHead,,,,2,,,,,,.T.)

	TOBS->(dbCloseArea())    
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)    
Return
//
// --------------------------------------------------------------------------
// Abre tela para incluir observações
User Function VAOBSFIN(_sCliente, _sLoja)
	local _aAreaAnt  	:= U_ML_SRArea ()
	local _aAmbAnt   	:= U_SalvaAmb ()
	local _oEvento 		:= NIL
	Local _texto 		:= " "
	Local oButton1
	Local oButton2
	Local oMultiGe1
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Static oDlg

	sData    := DTOC(date())
	sUsuario := UsrRetName(__cUserID)

	DEFINE MSDIALOG oDlg TITLE "Observações Financeiras" FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

	@ 015, 015 SAY oSay1 PROMPT "Data" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 015, 045 SAY oSay2 PROMPT sData SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 030, 015 SAY oSay3 PROMPT "Usuário" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 030, 045 SAY oSay4 PROMPT sUsuario SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 045, 015 SAY oSay5 PROMPT "Observações" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 057, 015 GET oMultiGe1 VAR _texto OF oDlg MULTILINE SIZE 219, 173 COLORS 0, 16777215 HSCROLL PIXEL
	@ 235, 195 BUTTON oButton1 PROMPT "Gravar" SIZE 037, 012 OF oDlg ACTION  (_ret := .T., oDlg:End ()) PIXEL
	@ 235, 146 BUTTON oButton2 PROMPT "Sair" SIZE 037, 012 OF oDlg ACTION  (_ret := .F., oDlg:End ())  PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	if _ret

		_oEvento    := NIL

		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "SA1004"
		_oEvento:DtEvento  = date()
		_oEvento:Texto	   = _texto
		_oEvento:Cliente   = _sCliente
		_oEvento:LojaCli   = _sLoja
		_oEvento:Grava ()
			
		AtualizaTela(_sCliente,_sLoja)
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)

Return
// --------------------------------------------------------------------------
// Exclui observações
User Function VAOBSEXC(_sCliente, _sLoja)
    Local _oSQL := ClsSQL ():New ()
    //_sData := DTOS(SZN->ZN_DATA)
    //_sHora := SZN->ZN_HORA
	_sData := DTOS(TOBS->DT)
    _sHora := TOBS->HORA

    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSQLName ("SZN") 
	_oSQL:_sQuery += " SET D_E_L_E_T_ = '*'"
    _oSQL:_sQuery += " WHERE ZN_CLIENTE = '" + _sCliente + "'"
    _oSQL:_sQuery += " AND ZN_LOJACLI   = '" + _sLoja    + "'"
    _oSQL:_sQuery += " AND ZN_DATA      = '" + _sData    + "'"
    _oSQL:_sQuery += " AND ZN_HORA      = '" + _sHora    + "'"
    _oSQL:_sQuery += " AND ZN_CODEVEN = 'SA1004'"
    _oSQL:Exec ()
	u_log()

    If ! _oSQL:Exec ()
        u_help("Registro não deletado!")
    else
        u_help("Registro deletado!")
		AtualizaTela(_sCliente,_sLoja)
    EndIf
Return
// --------------------------------------------------------------------------
// Visualiza observações
User Function VAOBSVIS(_sCliente, _sLoja)
    Local _oSQL := ClsSQL ():New ()
	Local _aSZN := {}
	Local i     := 0
	Local oButton1
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oSay5
	Local oMultiGe1
	Static oDlg

    //_sData := DTOS(SZN->ZN_DATA)
    //_sHora := SZN->ZN_HORA
	_sData := DTOS(TOBS->DT)
    _sHora := TOBS->HORA

    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ZN_DATA, ZN_USUARIO, ISNULL(CAST(CAST(ZN_TXT AS VARBINARY(8000)) AS VARCHAR(8000)),'') "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SZN") 
    _oSQL:_sQuery += " WHERE ZN_CLIENTE = '" + _sCliente + "'"
    _oSQL:_sQuery += " AND ZN_LOJACLI   = '" + _sLoja    + "'"
    _oSQL:_sQuery += " AND ZN_DATA      = '" + _sData    + "'"
    _oSQL:_sQuery += " AND ZN_HORA      = '" + _sHora    + "'"
    _oSQL:_sQuery += " AND ZN_CODEVEN = 'SA1004'"
    _aSZN := aclone (_oSQL:Qry2Array ())

	For i:=1 to Len(_aSZN)
		sData    := DTOC(_aSZN[i,1])
		sUsuario := _aSZN[i,2]
		sTxt     := _aSZN[i,3]

		DEFINE MSDIALOG oDlg TITLE "Observações Financeiras" FROM 000, 000  TO 500, 500 COLORS 0, 16777215 PIXEL

		@ 015, 015 SAY oSay1 PROMPT "Data" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 015, 045 SAY oSay2 PROMPT sData SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 030, 015 SAY oSay3 PROMPT "Usuário" SIZE 025, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 030, 045 SAY oSay4 PROMPT sUsuario SIZE 150, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 045, 015 SAY oSay5 PROMPT "Observações" SIZE 035, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 057, 015 GET oMultiGe1 VAR sTxt OF oDlg MULTILINE SIZE 219, 173 COLORS 0, 16777215 HSCROLL PIXEL
		@ 235, 198 BUTTON oButton1 PROMPT "Sair" SIZE 037, 012 OF oDlg ACTION  ( oDlg:End ())  PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED
	Next
Return
// --------------------------------------------------------------------------
// Inicializa observações
Static Function _VerificaOBS(_sCliente, _sLoja)
    Local _oSQL := ClsSQL ():New ()
    Local _aSZN := {}

    _oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT * "
    _oSQL:_sQuery += " FROM " + RetSQLName ("SZN") 
    _oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND ZN_CLIENTE = '" + _sCliente + "'"
    _oSQL:_sQuery += " AND ZN_LOJACLI = '" + _sLoja    + "'"
    _oSQL:_sQuery += " AND ZN_CODEVEN = 'SA1004'"
    _aSZN := aclone (_oSQL:Qry2Array ())

    If Len(_aSZN) == 0
        _oEvento := ClsEvent():new ()
        _oEvento:CodEven   = "SA1004"
        _oEvento:DtEvento  = date()
        _oEvento:Texto	   = "Inicializador"
        _oEvento:Cliente   = _sCliente
        _oEvento:LojaCli   = _sLoja
        _oEvento:Grava ()
    EndIf

Return
// --------------------------------------------------------------------------
// Realiza a atualização da tela após excluir/alterar
Static Function AtualizaTela(_sCliente,_sLoja)
	Local aStruct     := {}
	Local _aArqTrb    := {}
	Local aDados      := {}
	local i           := 0

	TOBS->(dbCloseArea())    
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
	AAdd( aStruct, { "DT"      , "D", 08, 0 } )
	AAdd( aStruct, { "HORA"    , "C", 08, 0 } )
	AAdd( aStruct, { "USU"     , "C", 15, 0 } )
	AAdd( aStruct, { "OBS"     , "M", 30, 0 } )
	
	U_ArqTrb ("Cria", "TOBS", aStruct, {"DT + HORA + USU"}, @_aArqTrb)		

	_sSQL := " SELECT"
	_sSQL += " 	   ZN_DATA"
	_sSQL += "    ,ZN_HORA"
	_sSQL += "    ,ZN_USUARIO"
	_sSQL += "    ,ISNULL(CAST(CAST(ZN_TXT AS VARBINARY(8000)) AS VARCHAR(8000)), '')"
	_sSQL += " FROM SZN010"
	_sSQL += " WHERE D_E_L_E_T_ = '' "
	_sSQL += " AND ZN_CLIENTE = '" + _sCliente + "'"
	_sSQL += " AND ZN_LOJACLI   = '" + _sLoja    + "'"
	_sSQL += " AND ZN_CODEVEN   = 'SA1004'"
	aDados := U_Qry2Array(_sSQL)
	
	If len (aDados) > 0
		For i :=1 to len(aDados)
			DbSelectArea("TOBS")
			RecLock("TOBS",.T.)
				TOBS-> DT      := aDados[i, 1]
				TOBS-> HORA    := aDados[i, 2]
				TOBS-> USU     := aDados[i, 3]
				TOBS-> OBS     := aDados[i, 4]
				
			MsUnLock()
		Next
	Endif

	aRotina   := {	{"Observações"	,"U_VAOBSFIN('"+_sCliente +"','"+_sLoja+"')"	,0,6} ,;
					{"Visualizar"	,"U_VAOBSVIS('"+_sCliente +"','"+_sLoja+"')"	,0,6} ,;
					{"Excluir"   	,"U_VAOBSEXC('"+_sCliente +"','"+_sLoja+"')"	,0,6}  }

    dbSelectArea("TOBS")
	dbSetOrder(1)

Return
