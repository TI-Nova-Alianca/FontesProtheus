// Programa...: VA_ZA6GER
// Autor......: Catia Cardoso
// Data.......: 09/04/2015
// Cliente....: Alianca
// Descricao..: Controle de Verbas 
//				Gera Verbas Conforme Contrato
//

#include "VA_Inclu.prw"
// --------------------------------------------------------------------------
User Function VA_ZA6GER()
	local _i		   	:= 0
	local i				:= 0
	private cCadastro  	:= "Contratos"
	private cString    	:= "ZA6"
    private aRotina    	:= {}
    private cPerg      	:= "ZA6"
    private _sarqlog   	:= U_NomeLog ()
	private _sQuery 	:= ""
	private _aDados 	:= {}
	
    u_logIni ()
    
    _ValidPerg()
    if Pergunte(cPerg,.T.)
	    // buscando contrato conforme cliente e vigencia informada
	    _sQuery := ""
	    _sQuery += "  SELECT ZA7.ZA7_DBASE"						// -- 1
	    _sQuery += "       , ZA7.ZA7_PINI"						// -- 2
	    _sQuery += "       , ZA7.ZA7_PFIM"						// -- 3
	    _sQuery += "       , ZA7.ZA7_CONT"						// -- 4
	    _sQuery += "       , ZA6.ZA6_CODVER"					// -- 5
	    _sQuery += "       , ZA6.ZA6_PERC"						// -- 6
	    _sQuery += "       , ZA6.ZA6_BASE"						// -- 7
	    _sQuery += "       , ZA6.ZA6_VALOR"						// -- 8
	    _sQuery += "       , ZA6.ZA6_TP"						// -- 9
	    _sQuery += "       , CASE WHEN ZA6.ZA6_TP='1' THEN 'VALOR' "	
	    _sQuery += "              WHEN ZA6.ZA6_TP='2' THEN 'PERCENTUAL' END AS TP_VER" // -- 10
	    _sQuery += "       , ZA3.ZA3_IND "						// -- 11
	    _sQuery += "       , CASE WHEN ZA3.ZA3_IND='1' THEN 'ANUAL' "
	    _sQuery += "              WHEN ZA3.ZA3_IND='2' THEN 'TRIMESTRAL'" 
	    _sQuery += "              WHEN ZA3.ZA3_IND='3' THEN 'MENSAL' "
	    _sQuery += "              WHEN ZA3.ZA3_IND='4' THEN 'SEMESTRAL' END AS IND_VER"	// -- 12
	    _sQuery += "       , ZA7.ZA7_CLI"						// -- 13
	    _sQuery += "       , ZA7.ZA7_LOJA"						// -- 14
	    _sQuery += "       , ZA7.ZA7_SEQ"						// -- 15
	    _sQuery += "   FROM " + RetSQLName ("ZA6") + " ZA6 "
	    _sQuery += "   		INNER JOIN " + RetSQLName ("ZA7") + " ZA7 "
	    _sQuery += "          	ON (ZA7.D_E_L_E_T_ = '' "
	    _sQuery += "              	AND ZA7.ZA7_FILIAL = ZA6.ZA6_FILIAL"
	    _sQuery += "              	AND ZA7.ZA7_CONT   = ZA6.ZA6_CONT"
	    _sQuery += "              	AND ZA7.ZA7_CLI    = ZA6.ZA6_CLI"
	    _sQuery += "              	AND ZA7.ZA7_LOJA   = ZA6.ZA6_LOJA"
	    _sQuery += "              	AND ZA7.ZA7_VIGENT = '1')"
	    _sQuery += "   		INNER JOIN " + RetSQLName ("ZA3") + " ZA3 "
	    _sQuery += "          	ON (ZA3.D_E_L_E_T_     = '' "
	    _sQuery += "              	AND ZA3.ZA3_FILIAL = ZA6.ZA6_FILIAL"
	    _sQuery += "              	AND ZA3.ZA3_COD    = ZA6.ZA6_CODVER"
	    _sQuery += "               	AND ZA3.ZA3_IND  != '9')"
	    _sQuery += "  WHERE ZA6.D_E_L_E_T_ = ''"
	    _sQuery += "  ORDER BY IND_VER, ZA6.ZA6_CODVER"
	
	    //u_showmemo(_sQuery)
	    
	    _aDados := U_Qry2Array (_sQuery)
	    _wcont  := 0
	    _aHist  := ''
	    _wcontrato = ''
		_wmes_ano_atual := substr(dtos(date()),1,6)
		    	
    	If Len (_aDados) > 0
    		for _i=1 to len(_aDados)
    			_wcontinua = .T.
    		 	// testa se ja foi gerada, nao gera novamente
    			_sQuery := ""
	    		_sQuery += "SELECT 1 "
	     		_sQuery += "  FROM ZA4010 AS ZA4"
				_sQuery += "	INNER JOIN ZA3010 AS ZA3"
				_sQuery += "		ON (ZA3.D_E_L_E_T_ = ''" 
				_sQuery += "			AND ZA3.ZA3_COD = ZA4.ZA4_COD"
				_sQuery += "			AND ZA3.ZA3_IND != '3')"
	 			_sQuery += " WHERE ZA4.D_E_L_E_T_ = ''"
	   			_sQuery += "   AND ZA4.ZA4_CLI	  = '" + _aDados[_i,13] + "'"
	   			_sQuery += "   AND ZA4.ZA4_LOJA   = '" + _aDados[_i,14] + "'"
	   			_sQuery += "   AND ZA4.ZA4_CONT   = '" + _aDados[_i,4] + "'"
	   			_sQuery += "   AND ZA4.ZA4_SEQCON = '" + _aDados[_i,15] + "'"
	   			_sQuery += "   AND ZA4.ZA4_COD    = '" + _aDados[_i,5] + "'"
	   			//u_showmemo(_sQuery)
	   			
	   			_JaTem := U_Qry2Array(_sQuery)
	   			if len (_JaTem) >0
					_wcontinua = .F.					 		
				endif
	   			
	   			if _wcontinua
		        	if _wcontrato != _aDados[_i,4]
		        		_wano = val(substr(dtos(_aDados[_i,1]),1,4))   // ano da database do contrato
						_wmes = val(substr(dtos(_aDados[_i,1]),5,2))   // mes da database do contrato
						_wtrimestral = ''
						_wsemestral  = ''
						for i=1 to 12
		            		_wmes = _wmes + 1
		            		if _wmes > 12
		            			_wmes = _wmes - 12
		            			_wano = val(substr(dtos(_aDados[_i,1]),1,4)) + 1
		            		endif
		            		_wanomes = strzero(_wano,4) + strzero(_wmes,2)
		            		do case
		            			case i=3
		            				_wtrimestral = _wtrimestral + '#' + _wanomes
		            			case i=6	
		            				_wtrimestral = _wtrimestral + '#' + _wanomes
		            				_wsemestral  = _wsemestral + '#' + _wanomes
		            			case i=9
		            				_wtrimestral = _wtrimestral + '#' + _wanomes
		            			case i=12
		            				_wanual = _wanomes
		            				_wtrimestral = _wtrimestral + '#' + _wanomes
		            				_wsemestral  = _wsemestral + '#' + _wanomes
		            		endcase
		            	next
		            endif
		            _wcontrato = _aDados[_i,4]
		            // para ver se tem realmente que gerar ou não
		            _wgera := 1
		            do case
		            	case _aDados[_i,12] = "ANUAL"
		                    if _wmes_ano_atual = _wanual
		                       _wgera := 0
		                    endif
		                case _aDados[_i,12] = "TRIMESTRAL"
		                    if _wmes_ano_atual $ (_wtrimestral)
		                        _wgera := 0
		                    endif                    
		                case _aDados[_i,12] = "SEMESTRAL"
		                    if _wmes_ano_atual $ (_wsemestral)
		                        _wgera := 0
		                    endif                    
		            endcase
		            // verificar no  ZA4 ja se foi paga
		            if _wgera = 1
		            	_aHist = ''
		                // se é valor e ja foi informada, lê a proxima
		                // se é percentual e ja foi informada, calcula a diferença e gera
		                // se não foi informada, gera
		                if  _aDados[_i, 10] = 'PERCENTUAL'
		                    _perc  = _aDados[_i,6]
		                    _base  = _aDados[_i,7]
		                    _pini  = _aDados[_i,2]
		                    _pfim  = _aDados[_i,3]
		                    _pcli  = _aDados[_i,13]
		                	_ploja = _aDados[_i,14]
		                    // se verba é percentual, apura periodo para calculo do valor
		                    _sQuery := ""
		                    _sQuery += "  SELECT SF2.F2_CLIENTE"
		                    _sQuery += "       , SF2.F2_LOJA"    
		                    _sQuery += "       , SUM(SF2.F2_VALBRUT) AS VLR_BRUTO"
		                    _sQuery += "       , ROUND(SUM(SF2.F2_VALBRUT*"+cvaltochar(_perc)+"/100),2) AS VLR_CALC_S_BRUT"
		                    _sQuery += "       , SUM(SF2.F2_VALMERC) AS VLR_MERCADORIA"
		                    _sQuery += "       , ROUND(SUM(SF2.F2_VALMERC*"+cvaltochar(_perc)+"/100),2) AS VLR_CALC_S_MERC"
		                    _sQuery += "    FROM " + RetSQLName ("SF2") + " AS SF2"
		                    _sQuery += "   WHERE SF2.D_E_L_E_T_ != '*'"
		                    _sQuery += "     AND SF2.F2_CLIENTE  = " + _pcli
		                    _sQuery += "     AND SF2.F2_LOJA     = " + _ploja
		                    _sQuery += "     AND SF2.F2_EMISSAO >= " + dtos(_pini)
		                    _sQuery += "     AND SF2.F2_EMISSAO <= " + dtos(_pfim)
		                    _sQuery += "GROUP BY SF2.F2_CLIENTE, SF2.F2_LOJA" 
		                    _aVlrCalc := U_Qry2Array (_sQuery)
		                    _aVlr := 0
		                    If Len (_aVlrCalc) > 0
		                        _aHist := 'Período ........... : ' + dtos(_pini) + ' até ' + dtos(_pfim) + chr(13) + chr(10)
		                        _aHist += 'Percentual da Verba : ' + transform (_perc,          "@E 999,999,999.99") + chr(13) + chr(10)
		                        if _base = '1' // mercadoria
		                           _aVlr  := _aVlrCalc[1,6]
		                           _aHist += 'Base (Mercadoria).. : ' + transform (_aVlrCalc[1,5], "@E 999,999,999.99") + chr(13) + chr(10)
		                           _aHist += 'Valor Calculado.... : ' + transform (_aVlrCalc[1,6], "@E 999,999,999.99") + chr(13) + chr(10)
		                        else // total da nota
		                           _aVlr  := _aVlrCalc[1,4]
		                           _aHist += 'Base (Total NF).... : ' + transform (_aVlrCalc[1,3], "@E 999,999,999.99") + chr(13) + chr(10)
		                           _aHist += 'Valor Calculado.... : ' + transform (_aVlrCalc[1,4], "@E 999,999,999.99") + chr(13) + chr(10)
		                        endif                          
		                    endif
		                endif
		                // Cria registro no ZA4 - GERA VERBA
		                _sNumero = GetSXENum ("ZA4", "ZA4_NUM")
		                reclock ("ZA4", .T.)
		                za4 -> za4_num    = _sNumero 
		                za4 -> za4_cli    = _aDados[_i,13]
		                za4 -> za4_loja   = _aDados[_i,14]
		                za4 -> za4_cod    = _aDados[_i,5]
		                za4 -> za4_vlr    = iif( _aDados[_i, 10]='VALOR', _aDados[_i,8], _aVlr)
		                za4 -> za4_cont   = _aDados[_i,4]
		                za4 -> za4_seqcon = _aDados[_i,15]
		                za4 -> za4_dger   = date()
		                za4 -> za4_sger   = '1'
		                za4 -> za4_uger   = alltrim (cUserName)
		                za4 -> za4_sutl   = '0'
		                za4 -> za4_hg_obs = _aHist
		                msunlock ()
		                _wcont = _wcont+1
		            endif
		        endif		            
	        next _i
	    endif
	    if _wcont > 0
	        // Confirma sequenciais, se houver.
	        do while __lSX8
	           ConfirmSX8 ()
	        enddo
	        u_help ('Verbas geradas com sucesso.')
		else
			u_help ('Não ha verbas a serem geradas.')			        
	    endif
	    u_logFim ()
	endif	    
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Gerar Verbas Contratuais ?", "S", 01, 0,  "",   "      ", {"Sim", "Nao"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
