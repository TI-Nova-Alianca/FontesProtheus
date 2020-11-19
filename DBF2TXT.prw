// Programa...: DBF2TXT
// Autor......: Robert Koch
// Data.......: 18/06/2004
// Cliente....: Generico
// Descricao..: Exporta arquivo DBF para TXT, mantendo a configuracao
//              de tamanhos de campos do arquivo DBF.
//
// Historico de alteracoes:
// 31/10/2009 - Robert - Criada possibilidade de exportar com o ponto decimal.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Parametros recebidos:
// 1 - Alias do arquivo DBF a ser exportado
// 2 - Caminho completo do arquivo TXT
// 3 - Se .T. indica que o arquivo TXT anterior deve ser deletado antes de gerar
// 4 - Se .T. utiliza barras nas datas (cfe. funcao padrao GRAVADATA)
// 5 - Formato da data cfe. funcao padrao GRAVADATA: 1 - ddmmaa
//                                                   2 - mmddaa
//                                                   3 - aaddmm
//                                                   4 - aammdd
//                                                   5 - ddmmaaaa
//                                                   6 - mmddaaaa
//                                                   7 - aaaaddmm
//                                                   8 - aaaammdd
// 6 - Se .T. exporta tambem a parte decimal de campos numericos
// 7 - Se .T. exporta valores numericos com ponto(.) decimal.
// Parametros retornados:
// .T. ou .F. indicando se gerou o arquivo.
user function DBF2TXT (_sAlias, _sArqTXT, _lDeleta, _lBarras, _nFormData, _lDecimais, _lPontoDec)
	local _nCampo   := 0
	local _aEstrut  := (_sAlias) -> (dbstruct ())
	local _nHdl     := 0
	local _sDado    := NIL
	local _nValor   := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _nDec		:= 0
	
	// Verifica se deve deletar o arquivo anterior.
	if _lDeleta .and. file (_sArqTXT)
		delete file (_sArqTXT)
		if file (_sArqTXT)
			u_help (procname () + ": Problema na geracao do arquivo texto '" + _sArqTXT + "': o arquivo ja' existe a nao foi possivel remove-lo.")
			U_ML_SRArea (_aAreaAnt)
			return .F.
		endif
	endif
	
	// Se cheguei ateh aqui e o arquivo jah existir, deve ser por
	// que nao era para deletar o anterior. Acrescentarei no final.
	if file (_sArqTXT)
		_nHdl = fopen(_sArqTXT, 1)
		fseek (_nHdl, 0, 2)  // Encontra final do arquivo
	else
		_nHdl = fcreate(_sArqTXT, 0)
	endif
	
	// Processa o arquivo DBF a exportar.
	(_sAlias) -> (dbgotop ())
	do while ! (_sAlias) -> (eof ())

		// Exporta campo a campo, formatando-o conforme seu tipo e tamanho.
		for _nCampo = 1 to len (_aEstrut)
			do case
				case _aEstrut [_nCampo, 2] == "C"
					_sDado = (_sAlias) -> (fieldget (_nCampo))
				case _aEstrut [_nCampo, 2] == "N"
					_nValor = (_sAlias) -> (fieldget (_nCampo))
					if ! _lDecimais  // Exportar somente a parte inteira
						_sDado = strzero (int (_nValor), _aEstrut [_nCampo, 3])
					else
						if ! _lPontoDec  // Exportar sem ponto decimal
							for _nDec = 1 to _aEstrut [_nCampo, 4]
								_nValor *= 10
							next
							_sDado = strzero (int (_nValor), _aEstrut [_nCampo, 3])
						else
							if _aEstrut [_nCampo, 4] > 0
								_sDado = strzero (int (_nValor), _aEstrut [_nCampo, 3] - (_aEstrut [_nCampo, 4] + 1))  // Desconta decimais e o proprio ponto decimal
								_nValor = _nValor - int (_nValor)  // Pega soh a parte decimal
								for _nDec = 1 to _aEstrut [_nCampo, 4]
									_nValor *= 10
								next
								_sDado += "." + strzero (int (_nValor), _aEstrut [_nCampo, 4])
							else
								_sDado = strzero (int (_nValor), _aEstrut [_nCampo, 3])
							endif
						endif
					endif
				case _aEstrut [_nCampo, 2] == "D"
					_sDado = GravaData ((_sAlias) -> (fieldget (_nCampo)), _lBarras, _nFormData)  //dtos ((_sAlias) -> (fieldget (_nCampo)))
				otherwise
					u_help ("Tipo de campo nao suportado na exportacao: " + _aEstrut [_nCampo, 1])
			endcase
			fwrite (_nHdl, _sDado)
		next
		fwrite (_nHdl, chr (13) + chr (10))  // Nova linha
		(_sAlias) -> (dbskip ())
	enddo
	fclose (_nHdl)
	U_ML_SRArea (_aAreaAnt)
return .T.
