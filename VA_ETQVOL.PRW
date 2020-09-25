//  Programa...: ETQVOL
//  Autor......: Catia Cardoso
//  Data.......: 06/04/2015
//  Descricao..: Impressao de etiquetas de volumes
//
//  Historico de alteracoes:
//  14/04/2015 - alterado volumes cliente
// ----------------------------------------------------------------
User Function ETQVOL(_sCarga)
	local _aAreaAnt      := U_ML_SRArea ()
	Local _Enter         := chr(13)+chr(10)
	local _lContinua     := .F.
	local _wProdCont     := {}
	local _wCliCont      := {}
	local _wProdTotVol   := 0
	local _wCliTotVol    := 0
	local _wnro_etiq     := 0		
	local i				 := 0		    	 
	private _sArq        := criatrab (NIL, .F.)
	private _nHdl        := fCreate(_sArq)
	private cPerg        := "ETQVOL"	
	
	u_logIni ()
	
	_ValidPerg()
	if Pergunte(cPerg)
		cPorta = alltrim (mv_par01)
		_lContinua = .T.
	endif
	
	if _lContinua
		for i=1 to 4
			if i=1 
				_sQuery := "SELECT SC9.C9_CLIENTE     AS CODCLI
				_sQuery += "	 , SUM(SC9.C9_QTDLIB) AS TOT_VOL_CLI"
			elseif i=2
				_sQuery := "SELECT SC9.C9_PRODUTO     AS CODPRO" 
				_sQuery += "     , SUM(SC9.C9_QTDLIB) AS TOT_VOL"
			elseif i=4
				_sQuery := "SELECT SUM(SC9.C9_QTDLIB) AS TOT_VOL"
			elseif i=3
				_sQuery := "SELECT DAI.DAI_FILIAL AS FILIAL"
				_sQuery += " 	 , DAI.DAI_COD    AS CARGA"
    			_sQuery += " 	 , SC9.C9_PRODUTO AS CODPRO"
				_sQuery += " 	 , SB1.B1_DESC    AS DESCPRO"
				_sQuery += " 	 , SB1.B1_UM      AS UM"
				_sQuery += " 	 , SB1.B1_VAPLLAS AS LASTRO
				_sQuery += " 	 , SB1.B1_VAPLCAM AS CAMADA
				_sQuery += " 	 , SC9.C9_QTDLIB  AS QTDE"
				_sQuery += " 	 , SC5.C5_TIPO    AS TIPO"
				_sQuery += " 	 , SC9.C9_CLIENTE AS CODCLI"
				_sQuery += " 	 , SC9.C9_NREDUZ  AS NOMCLI"
			endif		
			_sQuery += "  FROM " + RetSQLName ("DAI") + " AS DAI "
    		_sQuery += " INNER JOIN " + RetSQLName ("SC5") + " AS SC5 "
    		_sQuery += "		ON (SC5.D_E_L_E_T_ = ''" 
    		_sQuery += "			AND SC5.C5_FILIAL = DAI.DAI_FILIAL"
    		_sQuery += "			AND SC5.C5_NUM    = DAI.DAI_PEDIDO)"
  			_sQuery += " INNER JOIN " + RetSQLName ("SC9") + " AS SC9 "
    		_sQuery += "		ON (SC9.D_E_L_E_T_ = ''" 
    		_sQuery += "			AND SC9.C9_FILIAL = DAI.DAI_FILIAL"
    		_sQuery += "			AND SC9.C9_PEDIDO = DAI.DAI_PEDIDO)"
			_sQuery += " INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
    		_sQuery += "		ON (SB1.D_E_L_E_T_ = ''" 
    		_sQuery += "			AND SB1.B1_COD = SC9.C9_PRODUTO)"
    		_sQuery += " WHERE DAI.D_E_L_E_T_ = ''"
    		_sQuery += "   AND DAI.DAI_FILIAL = '" + xfilial ("DAI") + "'"   // PADRAO
    		_sQuery += "   AND DAI.DAI_COD    = '" + _sCarga + "'"          // CARGA
    		
    		//u_showmemo(_sQuery) 
    		
    		if  i=1
				_sQuery += " GROUP BY DAI.DAI_COD, SC9.C9_CLIENTE"
				aDados1 := U_Qry2Array(_sQuery)
    		endif
			
    		if i=2
				_sQuery += " GROUP BY DAI.DAI_COD, SC9.C9_PRODUTO"
				aDados := U_Qry2Array(_sQuery)
			endif    			
			
			if i=3
				_sQuery += " ORDER BY DAI.DAI_COD, SC9.C9_PRODUTO, SC9.C9_CLIENTE"
				_sAliasQ = GetNextAlias ()
    			DbUseArea(.T., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .F., .T.)
    		endif
    		
    		if i=4
				_sQuery += " GROUP BY DAI.DAI_COD"
				aDados2 := U_Qry2Array(_sQuery)
				if len (aDados2) >0
					_wtotvolumes = aDados2[1,1] 		
				endif
			endif    			
    		
    	next
    	
    	
    	(_sAliasQ) -> (DBGoTop ())
    	Do While ! (_sAliasQ) -> (Eof ())
    		// buscca cidade e estado do cliente
			if (_sAliasQ) -> tipo = 'N'
				_wcidade = ALLTRIM(fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) -> CODCLI + '01', "A1_MUN"))
				_westado = fBuscaCpo ('SA1', 1, xfilial('SA1') + (_sAliasQ) -> CODCLI + '01', "A1_EST")
			else
				_wcidade = ALLTRIM(fBuscaCpo ('SA2', 1, xfilial('SA2') + (_sAliasQ) -> CODCLI + '01', "A2_MUN"))
				_westado = fBuscaCpo ('SA2', 1, xfilial('SA2') + (_sAliasQ) -> CODCLI + '01', "A2_EST")
			endif
			// calcula a quantidade de etiquetas a imprimir de cada item 
			//_nUmPallet = (_sAliasQ) -> LASTRO  * (_sAliasQ) -> CAMADA
			//_nQtdPal = INT( (_sAliasQ) -> QTDE / _nUmPallet)
			//_wtqde = (_sAliasQ) -> QTDE - (_nUmPallet * _nQtdPal) + _nQtdPal
			_wtqde = (_sAliasQ) -> QTDE
			// total de volumes do produto na carga
			_wProdTotVol = aDados[ ascan ( aDados, {|_aVal| _aVal [1] == (_sAliasQ) -> CODPRO } ) ,2 ]
			// total de volumes do cliente
			_wCliTotVol = aDados1[ ascan ( aDados1, {|_aVal| _aVal [1] == (_sAliasQ) -> CODCLI } ) ,2 ]
			
			for i=1 to _wtqde 
				_npos = aScan (_wProdCont, {|_x |_x[1] == (_sAliasQ) -> CODPRO })
				if _npos = 0
					Aadd(_wProdCont,{(_sAliasQ) -> CODPRO , 1 })
				else
					_wProdCont[_npos, 2] ++
				endif
				
				_npos =  aScan ( _wCliCont, {|_x|_x [1]== (_sAliasQ) -> CODCLI } )
				if _npos = 0
					Aadd(_wCliCont,{(_sAliasQ) -> CODCLI, 1})
				else
					_wCliCont[_npos, 2] ++
				endif
				
				_wnro_etiq = _wnro_etiq + 1
									
				// impressão das etiquetas
				if mv_par02 = 0 .or. mv_par02 = _wnro_etiq
					_wetiqueta = ""
					_wetiqueta += 'n'  + _Enter
					_wetiqueta +='f220' + _Enter
					_wetiqueta +='D' + _Enter
					_wetiqueta +='L' + _Enter
					_wetiqueta +='D11'+ _Enter
					_wetiqueta +='H13'+ _Enter  // alterado de H12 para H13
					_wetiqueta +='A2'+ _Enter  // essa linha nao tinha na anterior
					_wetiqueta +='141100001330021' + ALLTRIM((_sAliasQ) -> CODPRO) + ' - ' +  SUBSTR(ALLTRIM((_sAliasQ) -> DESCPRO),1,20) +  ' - ' + ALLTRIM((_sAliasQ) -> UM) + _Enter
					_wetiqueta +='131100001150021' + ALLTRIM((_sAliasQ) -> CODCLI) + ' - ' + SUBSTR(ALLTRIM((_sAliasQ) -> NOMCLI),1,30)  + _Enter
					_wetiqueta +='161100000660021' + SUBSTR(_wcidade,1,20) + ' - ' + _westado + _Enter
					_wetiqueta +='131100000480025' + 'VOLUME CLIENTE' + _Enter
					_wetiqueta +='121100000370265' + 'SEQUENCIAL ITEM' + _Enter
					// contador de volumes do cliente na carga
					_npos = aScan ( _wCliCont, {|_x|_x [1] == (_sAliasQ) -> CODCLI } )
					_wCliVolCont = _wCliCont[_npos, 2]
					_wetiqueta +='161100000100021' + strzero(_wCliVolCont,3) + '/' + strzero(_wCliTotVol,3) + _Enter
					// contador de volumes do produto na carga
					_npos = aScan ( _wProdCont, {|_x|_x [1]==(_sAliasQ) -> CODPRO } )
					_wProdVolCont = _wProdCont[_npos, 2]
					_wetiqueta +='141100000110265' + strzero(_wProdVolCont,3)  + '/' + strzero(_wProdTotVol,3)  + _Enter
					_wetiqueta +='131100001620021' + "CARGA :" + ALLTRIM((_sAliasQ) -> CARGA) + "                 ETIQUETA : " + STRZERO(_wnro_etiq,4) + _Enter
					_wetiqueta +='Q0001' + _Enter
					_wetiqueta +='E' + _Enter
					
					/*
					_wetiqueta +='141100001680016' + ALLTRIM((_sAliasQ) -> CODPRO) + ' - ' +  SUBSTR(ALLTRIM((_sAliasQ) -> DESCPRO),1,24) +  ' - ' + ALLTRIM((_sAliasQ) -> UM) + _Enter 
					_wetiqueta +='131100001380016' + ALLTRIM((_sAliasQ) -> CODCLI) + ' - ' + SUBSTR(ALLTRIM((_sAliasQ) -> NOMCLI),1,30)  + _Enter
					_wetiqueta +='161100000850016' + SUBSTR(_wcidade,1,20) + ' - ' + _westado + _Enter
					_wetiqueta +='131100000480037' + 'VOLUME' + _Enter
					_wetiqueta +='121100000370320' + 'SEQUENCIAL' + _Enter
					// contador de volumes do cliente na carga
					_npos = aScan ( _wCliCont, {|_x|_x [1] == (_sAliasQ) -> CODCLI } )
					_wCliVolCont = _wCliCont[_npos, 2]
					_wetiqueta +='161100000100016' + strzero(_wCliVolCont,4) + '/' + strzero(_wCliTotVol,4) + _Enter
					// contador de volumes do produto na carga
					_npos = aScan ( _wProdCont, {|_x|_x [1]==(_sAliasQ) -> CODPRO } )
					_wProdVolCont = _wProdCont[_npos, 2]
					_wetiqueta +='141100000110310' + strzero(_wProdVolCont,4)  + '/' + strzero(_wProdTotVol,4)  + _Enter
					_wetiqueta +='Q0001' + _Enter
					_wetiqueta +='E' + _Enter
					*/
					
					fwrite (_nHdl, _wetiqueta)
				endif					
			next
			(_sAliasQ) -> (dbskip())
		enddo

		fclose (_nHdl)
		copy file (_sArq) to (cPorta)
		delete file (_sArq)
		
	endif
	
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
Return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Porta impressora etiquetas    ?", "C", 60, 0,  "",   "   ", {},     ""})
	aadd (_aRegsPerg, {02, "Etiqueta a reimprimir         ?", "N", 04, 0,  "",   "   ", {},     ""})
	
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return