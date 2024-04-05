// Programa...: PEBOT006
// Autor......: Cláudia Lionço
// Data.......: 04/01/2023
// Descricao..: Ponto de entrada para botões no Painel XML Totvs RS

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada para botões no Painel XML Totvs RS
// #PalavasChave      #ponto_entrada #importador_XML
// #TabelasPrincipais
// #Modulos           #COM #EST

// Historico de alteracoes:
// 08/03/2023 - Robert - Criado botao para visualizar o XML em modo texto.
// 01/04/2024 - Robert - Tratamento para encontrar o arquivo XML (pois o caminho refere-se ao servidor) na funcao de visualizacao.
//

#include "fileio.ch"

// --------------------------------------------------------------------------------------
User Function PEBOT006()
	local _aRet := PARAMIXB[1]
	aADD (_aRet, {"Alianca - Controle Portaria", "U_VA_CPORT", 0, 4,0,.F.})
	aADD (_aRet, {"Alianca - Visualizar XML",    "U_ZBEBot ('VisualizarXML')", 0, 4,0,.F.})
	aADD (_aRet, {"Alianca - Eventos chave NFe", "U_VA_SZNC ('CHAVENFE',zbe->zbe_chvnfe)", 0, 4,0,.F.})
Return _aRet


// --------------------------------------------------------------------------------------
User Function ZBEBot (_sQueFazer)
	local _sXML    := ''
	local _nHdl    := 0
	local _sArqX   := ''
	local _sCAMXML := ''

	do case
	case _sQueFazer == upper ('VisualizarXML')

		// O caminho pode variar (arquivo baixado / recebido do U_ZZX / importado pelo usuario / ...)
		_sCAMXML = alltrim (GetMv ("006_CAMXML"))
		if upper (left (zbe -> zbe_file, len (_sCAMXML))) == upper (_sCAMXML)  // Deve estar alguma coisa assim "\XmlNfe\109_202207013207176_XXXX.XML"
			_sArqX = '\\192.168.1.3\siga\protheus12\protheus_data' + _sCAMXML + 'processado\' + strtran (zbe -> zbe_file, _sCAMXML, '')
		else
			_sArqX = alltrim (zbe -> zbe_file)
		endif

		_nHdl = FOpen (_sArqX, FO_READ + FO_SHARED)
		if _nHdl == -1
			u_help ("Erro ao abrir arquivo '" + _sArqX + "'.",, .t.)
		else
			_sXML = fReadStr (_nHdl, 10000)
			u_showMemo (_sXML)
		endif
		FClose (_nHdl)
	otherwise
		u_help ("Acao nao definida para '" + _sQueFazer + "'.",, .t.)
	endcase
return
