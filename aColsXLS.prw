// Programa...: aColsXLS
// Autor......: Robert Koch
// Data.......: 25/02/2004
// Descricao..: Exporta conteudo do aCols em formado CSV
//
// Historico de alteracoes:
// 29/03/2004 - Robert - Tamanho do nome do campo limitado a 10 caracteres
//                     - Tratamento para nomes de campos repetidos
//                     - tratamento para aCols sem dados (NIL)
// 14/11/2005 - Robert - Se nao existe aHeader, cria um generico
//                     - Possibilidade de receber array de dados via parametro.
// 19/12/2007 - Robert - Passa a gerar em formato .CSV e nao mais em .DBF
// 23/04/2009 - Robert - Caso nao encontre o Excel, tenta abrir o arquivo pelo Windows.
// 15/09/2010 - Robert - Nao gera mais aviso em tela quando o MS-Excel nao estiver instalado.
// 08/02/2012 - Robert - Criada possibilidade de usar os titulos dos campos do aHeader em vez de nomes de campos.
// 02/09/2017 - Robert - Nao exporta mais a coluna 'deletado' no final.
// 26/10/2023 - Robert - Permite passar um aHeader alternativo como parametro.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function aColsXLS (_aCols, _lTitHead, _aHdr2, _sDelet)
	local _aAreaAnt := U_ML_SRArea ()
	local _sNomeArq := CriaTrab ({}, .F.)
	local _sArq     := MsDocPath () + "\" + _sNomeArq + ".CSV"
	local _sTmpPath := AllTrim (GetTempPath ())
	local oExcelApp := NIL
	local _nCampo   := 0
	local _sCampo   := ""
	local _nHdl     := 0
	local _sCrLf    := chr (13) + chr (10)
	local _nLinha 	:= 0
	//local _sCampo 	:= ""
	local _aHeader 	:= {}
	local _nMaxCols := 0
	local _lContinua:= .T.
	local _xDado    := NIL  
	local _nCol		:= 0 
	
	_lTitHead := iif (_lTitHead == NIL, .F., _lTitHead)

	if _lContinua
		
		// Cria arquivo temporario onde serao gerados os dados.
		_nHdl := MsfCreate (_sArq, 0)
		
		// Se nao foi passada uma array, assume aCols como default.
		if _aCols == NIL
			_aCols = aclone (aCols)
		endif
		
		// Se nao tem aHeader, 'inventa' um.
		if valtype (_aHdr2) == "A" .and. len (_aHdr2) > 0
			_aHeader = aclone (_aHdr2)
		elseif type ("aHeader") == "A" .and. len (aHeader) > 0
			_aHeader = aclone (aheader)
		else
			_aHeader = {}
			
			// Verifica maximo de campos (posso ter recebido uma array com tamanhos de linhas variaveis)
			for _nLinha = 1 to len (_aCols)
				_nMaxCols = max (_nMaxCols, len (_aCols [_nLinha]))
			next
			
			for _nLinha = 1 to _nMaxCols
				aadd (_aHeader, {"Col" + strzero (_nLinha, 3), ;
				"Col" + strzero (_nLinha, 3), ;
				"", ;
				18, ;
				5, ;
				"", ;
				"", ;
				"C"})
			next
		endif
		
		// Monta nomes de colunas no arquivo com base no _aHeader
		for _nLinha = 1 to len (_aHeader)
			// Definicao do nome do campo: se tem nome de campo no _aHeader, pego dali. Senao, crio nome generico
			_sCampo = ""
			if _lTitHead
				_sCampo = _aHeader [_nLinha, 1]
			elseif ! empty (_aHeader [_nLinha, 2])
				_sCampo = left (_aHeader [_nLinha, 2], 10)
			endif
			if empty (_sCampo)
				_sCampo = "Cpo" + strzero (_nLinha, 3)
			endif
			
			fWrite (_nHdl, _sCampo + iif (_nLinha < len (_aHeader), ";", ""))  // Nomes das colunas, sem ';' no final.
		next
		fWrite (_nHdl, _sCrLf )
		
		
		// Passo os dados do _aCols para o arquivo criado
		for _nLinha = 1 to len (_aCols)
			for _nCol = 1 to len (_aHeader)
				if _nCol <= len (_aCols [_nLinha])
					_xDado = cvaltochar (_aCols [_nLinha, _nCol])
					//u_log ("_aCols:", _aCols [_nLinha, _nCol], 'valtype = ', valtype (_aCols [_nLinha, _nCol]), '_xdado=', _xDado)
					
					// Valores numericos ficam com ponto decimal, mas o Excel quer virgula.
					if valtype (_aCols [_nLinha, _nCol]) == "N"
						_xDado = strtran (_xdado, ".", ",")
						//u_log ('_xdado apos strtran=', _xDado)
					endif
					fWrite (_nHdl, _xDado + iif (_nCampo < len (_aHeader), ";", ""))
				endif
			next
			fWrite (_nHdl, _sCrLf )
		next
		fClose (_nHdl)
		
		// Copio o arquivo para a pasta temporaria da estacao e deleto-o da pasta de documentos
		CpyS2T (_sArq , _sTmpPath, .T. )
		delete file (_sArq)
		
		If ApOleClient( 'MsExcel' )
			oExcelApp := MsExcel():New()
			oExcelApp:WorkBooks:Open (_sTmpPath + _sNomeArq + ".csv") // Abre uma planilha
			oExcelApp:SetVisible(.T.)
		else
//			MsgInfo ('Instalacao do MS-Excel nao encontrada. Os dados foram gravados no seguinte arquivo generico: ' + chr (13) + chr (10) + chr (13) + chr (10) + _sTmpPath + _sNomeArq + ".csv" + chr (13) + chr (10) + chr (13) + chr (10) + "O sistema vai tentar fazer a abertura desse arquivo em seguida. Caso nao seja possivel, abra o arquivo manualmente.")
			winexec ("cmd /c start " + _sTmpPath + _sNomeArq + ".csv")
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
return
