// Programa...: ML_R2T
// Autor......: Robert Koch
// Data.......: 13/04/2005
// Cliente....: Generico
// Descricao..: Converte arquivos ##R para TXT removendo os caracteres de controle.
//
// Historico de alteracoes:
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #PalavasChave      #conversao #tipo_arquivo ###r #txt
// #TabelasPrincipais 
// #Modulos           #todos_modulos

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function ML_R2T (_sArq1, _sArq2)
	local _nHdl1     := 0
	local _nHdl2     := 0
	local _sChar     := ""
	local _nCodASC   := 0
	local _lContinua := .T.
	
	if _lContinua
		if ! file (_sArq1)
			u_help ("Arquivo nao encontado: " + _sArq1,, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_nHdl1 = fopen (_sArq1, 0)
		if _nHdl1 == -1
			u_help ("Nao foi possivel abrir o arquivo " + _sArq1 + " para leitura.",, .t.)
			_lContinua = .F.
		endif
	endif
	if _lContinua
		_nHdl2 = fcreate (_sArq2, 0)
		if _nHdl1 == -2
			u_help ("Nao foi possivel abrir o arquivo " + _sArq2 + " para gravacao.",, .t.)
			_lContinua = .F.
		endif
	endif
	_nContChar := 0
	do while _lContinua .and. fread (_nHdl1, @_sChar, 1) > 0
		_nCodASC = asc (_sChar)
	//	u_log (_nContChar ++, 'testando char', _nCodASC, _sChar)
		
		// Remove logotipo
		if _nCodASC == 17
			fread (_nHdl1, @_sChar, 11)
			fwrite (_nHdl2, "   ")
			//fread (_nHdl1, @_sChar, 1)
			//_nCodASC = asc (_sChar)
			loop
		endif
		
		// Demais caracteres de controle (exceto 'form feed') sao simplesmente removidos.
		if _nCodASC != 1 .and. _nCodASC != 2 .and. _nCodASC != 3  .and. _nCodASC != 4  .and. _nCodASC != 5 .and. ;
			_nCodASC != 6 .and. _nCodASC != 8 .and. _nCodASC != 15 .and. _nCodASC != 18 .and. _nCodASC != 27
			if fwrite (_nHdl2, _sChar) != 1
				u_help ("Erro ao gravar no arquivo " + _sArq2,, .t.)
				_lContinua = .F.
			endif
		endif
	enddo
	if _lContinua
		fclose (_nHdl1)
		fclose (_nHdl2)
	endif
return _lContinua
