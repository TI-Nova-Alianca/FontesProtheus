// Programa...: VA_FIN650
// Autor......: Cláudia Lionço
// Data.......: 10/08/2022
// Descricao..: Relatório retorno do CNAB 
//              Customizado para poder trazer a tela de eventos de juros indevidos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatório
// #Descricao         #Relatório retorno do CNAB 
// #PalavasChave      #CNAB  
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 10/08/2022 - Claudia - Incluida gravação de eventos de juros indevidos. GLPI: 12454
// 18/01/2023 - Claudia - Verificação de juros indevido existente. GLPI: 10907
// 28/11/2024 - Claudia - O relatorio FINR650 foi descontinuado pela TOTVS, 
//                        sendo necessário utilizar o fonte disponibilizado. GLPI: 16165
//
// ------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#Include "PROTHEUS.CH"   

User Function VA_FIN650()
    local _cMens       := ""
	Private _nValJuros := 0
	
    // chama relatorio
    U_VA_CNAB()

	If _nValJuros > 0
		_cMens := "Deseja abrir a tela de eventos CNAB - Juros indevidos?"
		If msgyesno(_cMens,"Confirmar")
			U_VA_CNABEV()
		EndIf
	EndIf
Return
//
// ------------------------------------------------------------------------------------------------
// Eventos Financeiros - Juros indevidos
User Function VA_CNABEV()
	Local aStruct     := {}
	Local aHead       := {}
	Local _aArqTrb    := {}
	Local aDados      := {}
	Local i           := 0
    Local _oSQL := ClsSQL():New () 
	Private cCadastro := "Eventos Financeiros - Juros indevidos"	
	Private cDelFunc  := ".T."
	Private cString   := "SZN"
	Private aRotina   := {}
	
	If !u_zzuvl ('036', __cUserId, .T.)
		Return
	EndIf

	AAdd( aHead, { "Filial"   ,{|| TOBS->FIL}      ,"D", 08 , 0, "" } )
	AAdd( aHead, { "Emissão"  ,{|| TOBS->DT}       ,"D", 08 , 0, "" } )
	AAdd( aHead, { "Hora"     ,{|| TOBS->HOR}      ,"C", 08 , 0, "" } )
	AAdd( aHead, { "Usuário"  ,{|| TOBS->USU}      ,"C", 15 , 0, "" } )
	AAdd( aHead, { "Titulo"   ,{|| TOBS->TIT}      ,"C", 20 , 0, "" } )
	AAdd( aHead, { "Cliente"  ,{|| TOBS->CLI}      ,"C", 40 , 0, "" } )
	AAdd( aHead, { "Datas"    ,{|| TOBS->OBS1}     ,"C", 50 , 0, "" } )
	AAdd( aHead, { "Evento"   ,{|| TOBS->OBS2}     ,"C",100 , 0, "" } )
	
	AAdd( aStruct, { "FIL"     , "C",  02, 0 } )
	AAdd( aStruct, { "DT"      , "D",  08, 0 } )
	AAdd( aStruct, { "HOR"     , "C",  08, 0 } )
	AAdd( aStruct, { "USU"     , "C",  15, 0 } )
	AAdd( aStruct, { "TIT"     , "C",  20, 0 } )
	AAdd( aStruct, { "CLI"     , "C",  40, 0 } )
	AAdd( aStruct, { "OBS1"    , "C",  50, 0 } )
	AAdd( aStruct, { "OBS2"    , "C", 100, 0 } )
	
	U_ArqTrb ("Cria", "TOBS", aStruct, {"FIL + DT + HOR + USU"}, @_aArqTrb)		

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += "  	ZN_FILIAL "
	_oSQL:_sQuery += " 	   ,ZN_DATA "
	_oSQL:_sQuery += "     ,ZN_HORA "
	_oSQL:_sQuery += "     ,ZN_USUARIO "
	_oSQL:_sQuery += "     ,ZN_NFS + ' ' + ZN_SERIES + ' ' + ZN_PARCTIT "
	_oSQL:_sQuery += "     ,ZN_CLIENTE + '-' + ZN_LOJACLI + ' - ' + SA1.A1_NOME "
	_oSQL:_sQuery += "     ,ZN_CHVNFE "
	_oSQL:_sQuery += "     ,ZN_TEXTO "
	_oSQL:_sQuery += "  FROM " + RetSQLName ("SZN")  + " SZN "
    _oSQL:_sQuery += "  INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += "  ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "  	AND A1_COD = ZN_CLIENTE "
	_oSQL:_sQuery += "  	AND SA1.A1_LOJA = SZN.ZN_LOJACLI "
	_oSQL:_sQuery += "  WHERE SZN. D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "  AND ZN_CODEVEN = 'SE1008' "
	aDados := aclone (_oSQL:Qry2Array ())
	
	If len (aDados) > 0
		For i :=1 to len(aDados)
			DbSelectArea("TOBS")
			RecLock("TOBS",.T.)
				TOBS-> FIL     := aDados[i, 1]
				TOBS-> DT      := aDados[i, 2]
				TOBS-> HOR     := aDados[i, 3]
				TOBS-> USU     := aDados[i, 4]
				TOBS-> TIT     := aDados[i, 5]
				TOBS-> CLI     := aDados[i, 6]
				TOBS-> OBS1    := aDados[i, 7]
				TOBS-> OBS2    := aDados[i, 8]
			MsUnLock()
		Next
	Endif

    dbSelectArea("TOBS")
	dbSetOrder(1)

	mBrowse(6,1,22,75,"TOBS",aHead,,,,2,,,,,,.T.)

	TOBS->(dbCloseArea())    
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb)    
Return
