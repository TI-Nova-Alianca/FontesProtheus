// Programa...: VA_XLS54
// Autor......: Robert Koch
// Data.......: 23/02/2021
// Descricao..: Exporta planiha com medicao continua X amostras grau uva (GLPI 9454).

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #exporta_planilha
// #Descricao         #Exporta planiha comparativa com dados da medicao continua X amostras grau uva.
// #PalavasChave      #safra #grau #medicao_continua_grau_uva
// #TabelasPrincipais #ZZA
// #Modulos 		  #COOP

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
User Function VA_XLS54 (_sFilial, _sSafra, _sCarga)
	
	// Apenas para mostrar regua de processamento.
	processa ({|| _AndaLogo (_sFilial, _sSafra, _sCarga)})
return


// --------------------------------------------------------------------------
static function _AndaLogo (_sFilial, _sSafra, _sCarga)
	local _oSQL     := NIL
	local _sLinkSrv := U_LkServer ('BL01')

	procregua (10)

	// Busca dados
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT CONTINUA_FILIAL"
	_oSQL:_sQuery +=      ", CONTINUA_LINHA"
	_oSQL:_sQuery +=      ", substring (format (CONTINUA_HORA, 'dd/MM/yyyy HH:mm:ss.fff'), 1, 23) as CONTINUA_HORA"
	_oSQL:_sQuery +=      ", CONTINUA_STATUS"
	_oSQL:_sQuery +=      ", CONTINUA_GRAU"
	_oSQL:_sQuery +=      ", BL01_FILIAL"
	_oSQL:_sQuery +=      ", BL01_SAFRA"
	_oSQL:_sQuery +=      ", BL01_CARGA"
	_oSQL:_sQuery +=      ", BL01_SAMPLE"
	_oSQL:_sQuery +=      ", BL01_RESULT"
	_oSQL:_sQuery +=      ", substring (format (BL01_HORA_MEDICAO, 'dd/MM/yyyy HH:mm:ss.fff'), 1, 23) as BL01_HORA"
	_oSQL:_sQuery +=      ", BL01_OBS"
	_oSQL:_sQuery +=  " FROM " + _sLinkSrv + ".FMEDICAO_CONTINUA_CARGA_SAFRA ("
	_oSQL:_sQuery +=         "'" + _sFilial + "',"
	_oSQL:_sQuery +=         "'" + _sSafra + "',"
	_oSQL:_sQuery +=         "'" + _sCarga + "')"
	_oSQL:_sQuery += " ORDER BY CONTINUA_HORA, BL01_CARGA, BL01_SAMPLE"
	_oSQL:Log ()
	_oSQL:Qry2Xls (.F., .F., .F.)
	if _oSQL:QtLinRet == 0
		u_help ("Nao foram encontradas medicoes para esta carga. Verifique se os dados do programa do grau foram importados do sistema BL01 e se, no computador do grau, o programa de sincronizacao encontra-se ativo.")
	endif
return
