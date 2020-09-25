// Programa:   VA_ETQPRODF
// Autor:      Andre Alves
// Data:       02/10/2018
// Descricao:  Impressão de etiquetas dos produtos da manutenção
//
// Historico de alteracoes:
//
// 02/10/2018 - Criação para impressão das etiquetas para produtos da manutenção
// 15/10/2019 - Ajustado fonte para inserir quantidade de peças por etiquetas.
// 

#INCLUDE "rwmake.ch"
#Include "PROTHEUS.CH"

User Function VA_ETQPRODF

Local _lContinua := .T.
Local _sQuery := ''
Local _aEtiqs := {}
Local cPorta   := ""
Local _Enter := chr(13)+chr(10)
Local _Esc   := chr(27)
Local _QtdPcs := 0
Local _QtdEtq := 0
Local _QtdUsada := 0
Local _QtdAUsar := 0
cPerg    := "VA_ETQPRODF"
private _sArq  := criatrab (NIL, .F.)
private _nHdl  := 0
private _CRLF  := chr (13) + chr (10)
static _sPortaImp := ""  
static _nModelImp := 0   

_ValidPerg()

	If Pergunte(cPerg)
		_sPortaImp = U_RetZX5 ('49', mv_par05, 'ZX5_49CAM')
		_nModelImp = val (U_RetZX5 ('49', mv_par05, 'ZX5_49LING'))
		
		_QtdPcs := (mv_par06)
		_QtdEtq := 0
		_QtdUsada := 0
		_QtdAUsar := (mv_par07)
		
		_sQuery := " SELECT DISTINCT B1_COD AS NOSSO_COD, B1_DESC AS NOSSA_DESC, SA5.A5_CODPRF AS COD_DO_FORNECEDOR, SBF.BF_LOCALIZ AS LOCALIZACAO, SBF.BF_NUMSERI AS SERIAL "
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
				
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		do while ! (_sAliasQ) -> (eof ())
		  nConta := 1
		  _sArq  := criatrab (NIL, .F.)
		  _nHdl = fcreate (_sArq, 0)
		  _sMargEsq = '070'
				
			do while ! (_sAliasQ) -> (eof ()) .and. nConta <= 1
				if _nModelImp == 2  // Impressora Argox
					_sCod1    := '' + (_sAliasQ) -> NOSSO_COD
					_sDescri1 := '' + substr (alltrim ((_sAliasQ) -> NOSSA_DESC),1,40)
					_sDescri2 := '' + substr (alltrim ((_sAliasQ) -> NOSSA_DESC),41,70)
					_sCod2    := '' + (_sAliasQ) -> COD_DO_FORNECEDOR
					_sLocaliz := '' + (_sAliasQ) -> LOCALIZACAO
					_sSerial  := '' + (_sAliasQ) -> SERIAL 
					//if nConta = 1
					do while _QtdUsada < _QtdPcs
//						_QtdAUsar := INT(_QtdPcs / _QtdEtq)
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
						fwrite (_nHdl, '121100000100030' + 'Qtd Pcs:' + cvaltochar (_QtdAUsar) + _Enter)
						fwrite (_nHdl, 'Q0001' + _Enter)
						fwrite (_nHdl, 'E' + _Enter)
						_QtdUsada += _QtdAUsar
					enddo
					//endif
				endif
			(_sAliasQ) -> (dbskip ())
			nConta = nConta+1
			enddo
			fclose (_nHdl)
			copy file (_sArq) to (_sPortaImp)
			delete file (_sArq)
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif	
	
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                         PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      Help
		aadd (_aRegsPerg, {01, "Codigo De      ", "C", 15, 0,  "",   "SB1", {},  						  ""})
		aadd (_aRegsPerg, {02, "Codigo Até     ", "C", 15, 0,  "",   "SB1", {},  						  ""})
		aadd (_aRegsPerg, {03, "Endereco De    ", "C", 15, 0,  "",   "SBE", {},  	    	    	  	  ""})
		aadd (_aRegsPerg, {04, "Endereco Até   ", "C", 15, 0,  "",   "SBE", {},  						  ""})
		aadd (_aRegsPerg, {05, "Impressora     ", "C", 2,  0,  "",   "ZX549", {},                         ""})
		aadd (_aRegsPerg, {06, "Qtd Peças      ", "N", 3,  0,  "",   "",    {},                           ""})
		aadd (_aRegsPerg, {07, "Qtd p/embalagem", "N", 3,  0,  "",   "",    {},                           ""})
		 
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
