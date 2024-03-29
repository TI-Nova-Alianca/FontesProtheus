// Programa..: VA_ETQPRODF
// Autor.....: Andre Alves
// Data......: 02/10/2018
// Descricao.: Impress�o de etiquetas dos produtos da manuten��o
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Impress�o de etiquetas dos produtos da manuten��o
// #PalavasChave      #etiquetas #etiquetas_manutencao 
// #TabelasPrincipais #SB1 #SBF #SA5 
// #Modulos   		  #MNT
//
// Historico de alteracoes:
// 02/10/2018 - Andre   - Cria��o para impress�o das etiquetas para produtos da manuten��o
// 15/10/2019 - Andre   - Ajustado fonte para inserir quantidade de pe�as por etiquetas.
// 18/02/2021 - Claudia - Incluida msg quando n existe endere�amento do produto. GLPI: 9271
// 10/06/2021 - Claudia - Incluido loop para impress�o. GLPI: 10186
// 28/02/2024 - Sandra  - Incluso campo unidade medidas. GLPI: 14641
// ------------------------------------------------------------------------------------------------
#INCLUDE "rwmake.ch"
#Include "PROTHEUS.CH"

User Function VA_ETQPRODF()
	Local _sQuery 	:= ''
	Local _Enter 	:= chr(13)+chr(10)
	Local _QtdPcs 	:= 0
	Local _QtdEtq 	:= 0
	Local _QtdUsada := 0
	Local _QtdAUsar := 0
	Local _aDados   := {}
	private _sArq  	:= criatrab (NIL, .F.)
	private _nHdl  	:= 0
	private _CRLF  	:= chr (13) + chr (10)
	static _sPortaImp := ""  
	static _nModelImp := 0   

	cPerg    := "VA_ETQPRODF"

	_ValidPerg()

	//If Pergunte(cPerg)
	Do While Pergunte(cPerg)
		_sPortaImp = U_RetZX5 ('49', mv_par05, 'ZX5_49CAM')
		_nModelImp = val (U_RetZX5 ('49', mv_par05, 'ZX5_49LING'))
		
		_QtdPcs := (mv_par06)
		_QtdEtq := 0
		_QtdUsada := 0
		_QtdAUsar := (mv_par07)
		
		_sQuery := " SELECT DISTINCT B1_COD AS NOSSO_COD, B1_DESC AS NOSSA_DESC, B1_UM AS UNIDADE, SA5.A5_CODPRF AS COD_DO_FORNECEDOR, SBF.BF_LOCALIZ AS LOCALIZACAO, SBF.BF_NUMSERI AS SERIAL "
		_sQuery += " FROM " + RetSQLName ("SB1") + " SB1, "
		_sQuery +=			  RetSQLName ("SA5") + " SA5, "
		_sQuery +=			  RetSQLName ("SBF") + " SBF "
		_sQuery += " WHERE SB1.D_E_L_E_T_ = '' AND SA5.D_E_L_E_T_ = '' AND SBF.D_E_L_E_T_ = '' "
		_sQuery += " AND SA5.A5_FILIAL = ' '"
		_sQuery += " AND SB1.B1_FILIAL = ' '"
		_sQuery += " AND SB1.B1_COD >= '" + alltrim(mv_par01) + "' "
		_sQuery += " AND SB1.B1_COD <= '" + alltrim(mv_par02) + "' "
		_sQuery += " AND SBF.BF_LOCALIZ >= '" + alltrim(mv_par03) + "' "
		_sQuery += " AND SBF.BF_LOCALIZ <= '" + alltrim(mv_par04) + "' "
		_sQuery += " AND SBF.BF_QUANT   != ' '"
		_sQuery += " AND SA5.A5_PRODUTO = SB1.B1_COD "
		_sQuery += " AND SA5.A5_PRODUTO = SBF.BF_PRODUTO"
		_sQuery += " ORDER BY NOSSO_COD, NOSSA_DESC, COD_DO_FORNECEDOR, LOCALIZACAO, SERIAL"
				
		_aDados := U_Qry2Array(_sQuery)

		If Len(_aDados) > 0 // Encontrou endere�amento

			_sAliasQ = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)

			Do while ! (_sAliasQ) -> (eof ())
				nConta := 1
				_sArq  := criatrab (NIL, .F.)
				_nHdl = fcreate (_sArq, 0)
				_sMargEsq = '070'
						
				Do while ! (_sAliasQ) -> (eof ()) .and. nConta <= 1
					if _nModelImp == 2  // Impressora Argox
						_sCod1    := '' + (_sAliasQ) -> NOSSO_COD
						_sDescri1 := '' + substr (alltrim ((_sAliasQ) -> NOSSA_DESC),1,40)
						_sDescri2 := '' + substr (alltrim ((_sAliasQ) -> NOSSA_DESC),41,70)
						_sUM      := '' + substr (alltrim ((_sAliasQ) -> UNIDADE),1,2)
						_sCod2    := '' + (_sAliasQ) -> COD_DO_FORNECEDOR
						_sLocaliz := '' + (_sAliasQ) -> LOCALIZACAO
						_sSerial  := '' + (_sAliasQ) -> SERIAL 

						do while _QtdUsada < _QtdPcs
							if _QtdAUsar > (_QtdPcs - _QtdUsada)
								_QtdAUsar := (_QtdPcs - _QtdUsada)
							endif

							fwrite (_nHdl, chr (2) + 'f220' + _Enter)  //  STX - inicio de etiqueta
							fwrite (_nHdl, chr (1) + 'D' + _Enter)  // SOH - inicio de header
							fwrite (_nHdl, chr (2) + 'n' + _Enter)
							fwrite (_nHdl, chr (2) + 'L' + _Enter)
							fwrite (_nHdl, 'D11' + _Enter)
							fwrite (_nHdl, 'H13' + _Enter)  // Temperatura
							fwrite (_nHdl, 'PC' + _Enter)  // Velocidade
							fwrite (_nHdl, '121100001900030' + 'Codigo Alianca' + _Enter)
							fwrite (_nHdl, '141100001700030' + _sCod1 + _Enter)
							fwrite (_nHdl, '121100001600030' + 'Descricao Alianca' + _Enter)
							fwrite (_nHdl, '131100001400030' + _sDescri1 + _Enter)
							fwrite (_nHdl, '131100001200030' + _sDescri2 + _Enter)
							fwrite (_nHdl, '121100001100030' + 'Codigo Fornecedor' + _Enter)
							fwrite (_nHdl, '141100000900030' + _sCod2 + _Enter)
							fwrite (_nHdl, '121100000800030' + 'Localizacao' + _Enter)
							fwrite (_nHdl, '141100000600030' + _sLocaliz + _Enter)
							fwrite (_nHdl, '121100000500030' + 'Serial' + _Enter)
							fwrite (_nHdl, '141100000300030' + _sSerial + _Enter)
							fwrite (_nHdl, '141100000600200' + 'Qtd Pcs:' + cvaltochar (_QtdAUsar) + ' ' +  _sUM  + _Enter)
							fwrite (_nHdl, 'Q0001' + _Enter)
							fwrite (_nHdl, 'E' + _Enter)
							_QtdUsada += _QtdAUsar
						enddo
					endif
					(_sAliasQ) -> (dbskip ())
					nConta = nConta+1
				enddo
				fclose (_nHdl)
				copy file (_sArq) to (_sPortaImp)
				delete file (_sArq)
			enddo
			(_sAliasQ) -> (dbclosearea ())
		Else
			u_help("Produto sem endere�amento! A etiqueta n�o ser� impressa.")
		EndIf
	EndDo
	//Endif	
Return
//
// -----------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
//                         PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Codigo De      ", "C", 15, 0,  "",   "SB1", {},  						  ""})
	aadd (_aRegsPerg, {02, "Codigo At�     ", "C", 15, 0,  "",   "SB1", {},  						  ""})
	aadd (_aRegsPerg, {03, "Endereco De    ", "C", 15, 0,  "",   "SBE", {},  	    	    	  	  ""})
	aadd (_aRegsPerg, {04, "Endereco At�   ", "C", 15, 0,  "",   "SBE", {},  						  ""})
	aadd (_aRegsPerg, {05, "Impressora     ", "C", 2,  0,  "",   "ZX549", {},                         ""})
	aadd (_aRegsPerg, {06, "Qtd Pe�as      ", "N", 3,  0,  "",   "",    {},                           ""})
	aadd (_aRegsPerg, {07, "Qtd p/embalagem", "N", 3,  0,  "",   "",    {},                           ""})
		 
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
