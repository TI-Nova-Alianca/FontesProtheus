// Programa...: GeraGraf
// Autor......: Robert Koch
// Data.......: 13/07/2009
// Cliente....: Alianca
// Descricao..: Rotina de preparacao de ambiente para mostrar graficos
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
// Param.: 1 - Nome (sem extensao) dos arquivos HTM e XML
//         2 - Conteudo a ser gravado no arquivo HTM
//         3 - Conteudo a ser gravado no arquivo XML
user function GeraGraf (_sArq, _sHTM, _sXML)
	local _nHdl      := 0
	local _sPathGraf := AllTrim (GetTempPath ()) + "Alianca\Graficos\"
	local _aDir      := {}
	local _nArq      := 0

	// Se ainda nao tem o diretorio para graficos na pasta temporaria da
	// estacao, cria-o e copia os arquivos necessarios do servidor.
	if ! file  (_sPathGraf + "*.swf") .or. ! file  (_sPathGraf + "FusionCharts.js")
		_aDir = directory ('\FusionChartsFree\fcf*.swf')
		if len (_aDir) > 0
			makedir (AllTrim (GetTempPath ()) + "Alianca")
			makedir (AllTrim (GetTempPath ()) + "Alianca\Graficos")
			
			// Copia os arquivos um a um por que usando "*.swf" parece copiar somente o primeiro.
			for _nArq = 1 to len (_aDir)
				CpyS2T ("\FusionChartsFree\" + _aDir [_nArq, 1], _sPathGraf, .F.)
			next
			CpyS2T ("\FusionChartsFree\FusionCharts.js" , _sPathGraf, .F.)
			if ! file  (_sPathGraf + "*.swf") .or. ! file  (_sPathGraf + "FusionCharts.js")
				msgalert ("Nao foi possivel criar na estacao os arquivos necessarios `a geracao de graficos.")
			endif
		endif
	endif

	_nHdl = fcreate (_sPathGraf + _sArq + ".HTM", 0)
	fwrite (_nHdl, _sHTM)
	fclose (_nHdl)

	_nHdl = fcreate (_sPathGraf + _sArq + ".XML", 0)
	fwrite (_nHdl, _sXML)
	fclose (_nHdl)

return _sPathGraf
