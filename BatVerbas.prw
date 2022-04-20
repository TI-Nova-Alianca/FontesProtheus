//  Programa...: BatVerbas
//  Autor......: Cláudia Lionço
//  Data.......: 24/07/2020
//  Descricao..: Realiza a gravação da tabela ZB0 - Acrescimo/desconto de Verbas e bonificações
//				 _nTipo: 	1 = Bat executado diariamente/ 
//							2 = Processo executado via menu do Protheus
// 
//  #TipoDePrograma    #Batch
//  #PalavasChave      #verbas #comissoes #vendedores
//  #TabelasPrincipais #ZA4 #ZA5 #SA1 #SF2 #SD2 #ZB0
//  #Modulos 		   #FIN 
//
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'

User function BatVerbas(_nTipo, _sFilial)
	Local _aDados   := {}
	Local _aVend    := {}
	Local _x		:= 0
	Local _i		:= 0
	Private cPerg   := "BatVerbas"
	
	If _nTipo != 1
		If ! u_zzuvl ('118', __cUserId, .T.)
			u_help ("Usuário sem permissão para usar estar rotina")
			Return
		Endif

		// Somente uma estacao por vez, pois a rotina eh pesada e certos usuarios derrubam o client na estacao e mandam rodar novamente...
		_nLock := U_Semaforo (procname ())
		If _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			Return
		Endif
		
		u_help("Essa rotina permite realizar o preenchimento da tabela de ajuste de comissões(ZB0) manualmente")
	EndIf
	
	If _nTipo == 1
		_dDtaIni  := FirstDate ( Date())
		_dDtaFin  := LastDate ( Date())
	Else
		_ValidPerg()
		If Pergunte(cPerg,.T.)
			_dDtaIni := mv_par01
			_dDtaFin := mv_par02
		Else
			Return
		EndIf
	EndIf
	
	u_logIni ()
	_sErroAuto := ''  // Para a funcao u_help gravar mensagens
	u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin))
	_sSQL := " DELETE FROM ZB0010" 
	_sSQL += " WHERE ZB0_FILIAL= '" +_sFilial +"' AND ZB0_DATA BETWEEN '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	u_log (_sSQL)
	
	If TCSQLExec (_sSQL) < 0
		if type ('_oBatch') == 'O'
			_oBatch:Mensagens += 'Erro ao limpar tabela ZB0010'
			_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
		else
			u_help ('Erro ao limpar tabela ZB0010',, .t.)
		endif
	Else
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT DISTINCT
		_oSQL:_sQuery += " 	   E3_VEND AS VENDEDOR
		_oSQL:_sQuery += "    ,A3_NOME AS NOM_VEND
		_oSQL:_sQuery += "    FROM " + RetSQLName ("SE3") + " AS SE3 "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
		_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''
		_oSQL:_sQuery += " 			AND SA3.A3_MSBLQL != '1'
		_oSQL:_sQuery += " 			AND SA3.A3_ATIVO != 'N'
		_oSQL:_sQuery += " 			AND SA3.A3_COD = SE3.E3_VEND)
		_oSQL:_sQuery += " WHERE E3_FILIAL = '" + xFilial('SE3') + "' "   
		_oSQL:_sQuery += " AND E3_VEND BETWEEN ' ' and 'ZZZ'"
		_oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '" + dtos (_dDtaIni) + "' AND '" + dtos (_dDtaFin) + "'"
		_oSQL:_sQuery += " AND E3_BAIEMI = 'B'
		_oSQL:_sQuery += " AND SE3.D_E_L_E_T_ = ''

		_oSQL:Log ()
		_aVend := _oSQL:Qry2Array ()
		
		For _i := 1 to Len(_aVend)
			_aDados := U_VA_COMVERB(_dDtaIni, _dDtaFin, _aVend[_i,1], 3, _sFilial)
			
			u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin) +'/'+_aVend[_i,1])
			For _x := 1 to Len(_aDados)
				If alltrim(_aDados[_x,17]) == ''
					_dDtPgto := STOD('19000101')
				Else
					_dDtPgto := STOD(_aDados[_x,17])
				EndIf
				dbselectArea("ZB0")
				RecLock("ZB0",.T.)
					ZB0 -> ZB0_FILIAL	:= _aDados[_x,14]		
					ZB0 -> ZB0_NUM		:= _aDados[_x,4]	
					ZB0 -> ZB0_SEQ		:= _aDados[_x,15]		                                      
					ZB0 -> ZB0_DATA		:= stod(_aDados[_x,16])	
					ZB0 -> ZB0_TIPO		:= _aDados[_x,13]
					ZB0 -> ZB0_ACRDES   := _aDados[_x,12]
					ZB0 -> ZB0_VENDCH   := _aVend[_i,1]
					ZB0 -> ZB0_VENVER  	:= _aDados[_x,2]
					ZB0 -> ZB0_VENNF 	:= _aDados[_x,3]
					ZB0 -> ZB0_DOC		:= _aDados[_x,5]	
					ZB0 -> ZB0_PREFIX	:= _aDados[_x,6]
					ZB0 -> ZB0_CLI		:= _aDados[_x,7]
					ZB0 -> ZB0_LOJA		:= _aDados[_x,8]
					ZB0 -> ZB0_VLBASE	:= _aDados[_x,10]
					ZB0 -> ZB0_VLCOMS  	:= _aDados[_x,11]
					ZB0 -> ZB0_PERCOM   := _aDados[_x,9]
					ZB0 -> ZB0_DTAPGT   := _dDtPgto 

				MsUnLock() 
			Next
		Next
	EndIf

	If _nTipo != 1
		u_help("Processo finalizado com sucesso")
	EndIf
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT         TIPO TAM DEC VALID F3     Opcoes             Help
	aadd (_aRegsPerg, {01, "Data inicial ", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final   ", "D", 08, 0,  "",   "   ", {},                ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
