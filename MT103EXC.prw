
// Programa...: MT103EXC
// Autor......: Cláudia Lionço
// Data.......: 27/05/2022
// Descricao..: P.E.  para validação da exclusão do documento de entrada.
//              Criado inicialmente para debitar valor de rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para validação da exclusão do documento de entrada.
// #PalavasChave      #ponto_de_entrada #nota_de_entrada
// #TabelasPrincipais #SF1 #SD1
// #Modulos           #FIS #EST
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------------------
User Function MT103EXC()
    lRet := .T.

    _AtuZC0()

Return lRet
//
// --------------------------------------------------------------------------
// Credita rapel da NF de devolução
Static Function _AtuZC0()
	Local _x := 0
	Local _i := 0

	If GetMV('VA_RAPEL')
		_oSQL:= ClsSQL():New()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery +=   " SELECT "
		_oSQL:_sQuery +=   "     D1_FILIAL "
		_oSQL:_sQuery +=   "    ,D1_NFORI "
		_oSQL:_sQuery +=   "    ,D1_SERIORI "
		_oSQL:_sQuery +=   "    ,D1_ITEMORI "
		_oSQL:_sQuery +=   " 	,D1_COD "
		_oSQL:_sQuery +=   "    ,D1_QUANT "
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery +=   " WHERE D_E_L_E_T_   = '' "
		_oSQL:_sQuery +=   " AND SD1.D1_FILIAL  = '" + sf1 -> f1_filial  + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_FORNECE = '" + sf1 -> f1_fornece + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_LOJA    = '" + sf1 -> f1_loja    + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_DOC     = '" + sf1 -> f1_doc     + "'"
		_oSQL:_sQuery +=   " AND SD1.D1_SERIE   = '" + sf1 -> f1_serie   + "'"
		_aNfDev := aclone (_oSQL:Qry2Array ())

		For _x:=1 to Len(_aNfDev)
			_oSQL:= ClsSQL():New()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery +=   " SELECT "
			_oSQL:_sQuery +=   " 	 D2_ITEM "
			_oSQL:_sQuery +=   "    ,D2_COD "
			_oSQL:_sQuery +=   "    ,D2_QUANT "
			_oSQL:_sQuery +=   "    ,D2_RAPEL "
			_oSQL:_sQuery +=   "    ,D2_VRAPEL "
			_oSQL:_sQuery +=   "    ,D2_CLIENTE "
			_oSQL:_sQuery +=   "    ,D2_LOJA"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD2") 
			_oSQL:_sQuery +=   " WHERE D_E_L_E_T_= '' "
			_oSQL:_sQuery +=   " AND D2_FILIAL   = '"+ _aNfDev[_x, 1] + "' "
			_oSQL:_sQuery +=   " AND D2_DOC      = '"+ _aNfDev[_x, 2] + "' "
			_oSQL:_sQuery +=   " AND D2_SERIE    = '"+ _aNfDev[_x, 3] + "' "
			_oSQL:_sQuery +=   " AND D2_COD      = '"+ _aNfDev[_x, 5] + "' "
			_aNfVen := aclone (_oSQL:Qry2Array ())

			For _i:=1 to Len(_aNfVen)
					_oCtaRapel := ClsCtaRap():New ()
					_sRede     := _oCtaRapel:BuscaRede(_aNfVen[_i, 6], _aNfVen[_i, 7])
					_sTpRapel  := _oCtaRapel:TipoRapel(_aNfVen[_i, 6], _aNfVen[_i, 7])

				If alltrim(_sTpRapel) <> '0' // Se o cliente tem configuração de rapel
					If _aNfDev[_x, 6] == _aNfVen[_i,3] // Se as quantidades de venda e devolução for igual, desconta 100% do valor
						_nRapel := _aNfVen[_i, 5]

						_oCtaRapel:Filial  	 = sf1 -> f1_filial
						_oCtaRapel:Rede      = _sRede	
						_oCtaRapel:LojaRed   = sf1 -> f1_loja
						_oCtaRapel:Cliente 	 = sf1 -> f1_fornece 
						_oCtaRapel:LojaCli	 = sf1 -> f1_loja
						_oCtaRapel:TM      	 = '08' 	
						_oCtaRapel:Data    	 = date()
						_oCtaRapel:Hora    	 = time()
						_oCtaRapel:Usuario 	 = cusername 
						_oCtaRapel:Histor  	 = 'Inclusão de rapel por exclusão de NF devolução' 
						_oCtaRapel:Documento = sf1 -> f1_doc
						_oCtaRapel:Serie 	 = sf1 -> f1_serie
						_oCtaRapel:Parcela	 = ''
						_oCtaRapel:Produto	 = _aNfVen[_i,2]
						_oCtaRapel:Rapel	 = _nRapel
						_oCtaRapel:Origem	 = 'MT103EXC'

						If _oCtaRapel:Grava (.F.)
							_oEvento := ClsEvent():New ()
							_oEvento:Alias     = 'ZC0'
							_oEvento:Texto     = "Inclusão rapel "+ sf1 -> f1_doc + "/" + sf1 -> f1_serie
							_oEvento:CodEven   = 'ZC0001'
							_oEvento:Cliente   = sf1 -> f1_fornece 
							_oEvento:LojaCli   = sf1 -> f1_loja
							_oEvento:NFSaida   = sf1 -> f1_doc
							_oEvento:SerieSaid = sf1 -> f1_serie
							_oEvento:Grava()
						EndIf
                    Else                    // Rapel proporcional
                        
					EndIf
				EndIf
			Next
		Next
	EndIf
Return
