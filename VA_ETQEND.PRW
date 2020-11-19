// Programa:   VA_ETQEND
// Autor:      Leandro Perondi
// Data:       27/09/2013
// Descricao:  Impressão de etiquetas dos endereços
//
// Historico de alteracoes:
//
// 11/10/2013 - Endereço MAC da impressora: [00:80:92:4B:41:70]
// 11/10/2013 - Leandro - mapeamento da impressora, configurado por Matheus: net use LPT1 \\192.168.1.7\prn1 /persistent:yes
// 11/10/2013 - Leandro - para imprimir configurações, tem que setar o pino 3 da placa interna como SIM (ON)
// 11/10/2013 - Leandro - Alteração de layout, pois etiquetas compradas saem na vertical da impressora, e as de teste saíam na horizontal
// 02/01/2014 - Robert  - Criado parametro para especificar porta da impressora.
//                      - Nao verificava a filial atual.
// 01/10/2018 - Andre   - Ajustado para imprimir etiquetas de endereços da Manutencao.

#INCLUDE "rwmake.ch"
#Include "PROTHEUS.CH"

User Function VA_ETQEND

//Local _lContinua := .T.
Local _sQuery := ''
//Local _aEtiqs := {}
//Local cPorta   := ""
Local _Enter := chr(13)+chr(10)
//Local _Esc   := chr(27)
cPerg    := "VA_ETQENDE"
private _sArq  := criatrab (NIL, .F.)
private _nHdl  := 0
private _CRLF  := chr (13) + chr (10)
static _sPortaImp := ""  
static _nModelImp := 0   

_ValidPerg()

	If Pergunte(cPerg)
		_sPortaImp = U_RetZX5 ('49', mv_par03, 'ZX5_49CAM')
		_nModelImp = val (U_RetZX5 ('49', mv_par03, 'ZX5_49LING'))
	
		_sQuery := " SELECT BE_LOCALIZ AS ENDERECO "
		_sQuery += " FROM " + RetSQLName ("SBE") + " SBE "
		_sQuery += " WHERE SBE.D_E_L_E_T_ = '' "
		_sQuery += " AND SBE.BE_FILIAL = '" + xfilial ("SBE") + "'"
		_sQuery += " AND SBE.BE_LOCALIZ >= '" + alltrim(mv_par01) + "' "
		_sQuery += " AND SBE.BE_LOCALIZ <= '" + alltrim(mv_par02) + "' "
		_sQuery += " ORDER BY ENDERECO "
		
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		do while ! (_sAliasQ) -> (eof ())
		  nConta := 1
		  _sArq  := criatrab (NIL, .F.)
		  _nHdl = fcreate (_sArq, 0)
		  _sMargEsq = '070'
				fwrite (_nHdl, chr (2) + 'f220' + _Enter)  //  STX - inicio de etiqueta
				fwrite (_nHdl, chr (1) + 'D' + _Enter)  // SOH - inicio de header
				fwrite (_nHdl, chr (2) + 'n' + _Enter)
				fwrite (_nHdl, chr (2) + 'L' + _Enter)
				fwrite (_nHdl, 'D11' + _Enter)
				fwrite (_nHdl, 'H13' + _Enter)  // Temperatura
				fwrite (_nHdl, 'PC' + _Enter)   // Velocidade
			do while ! (_sAliasQ) -> (eof ()) .and. nConta <= 7
				if _nModelImp == 2  // Impressora Argox
					_sDescri1 := '' + alltrim((_sAliasQ) -> ENDERECO)
					if nConta = 1
						fwrite (_nHdl, '461100000' + _sMargEsq + '050' + _sDescri1 + _Enter)
					elseif nConta = 2
						fwrite (_nHdl, '461100000' + _sMargEsq + '105' + _sDescri1 + _Enter)
					elseif nConta = 3
						fwrite (_nHdl, '461100000' + _sMargEsq + '160' + _sDescri1 + _Enter)
					elseif nConta = 4
						fwrite (_nHdl, '461100000' + _sMargEsq + '215' + _sDescri1 + _Enter)
					elseif nConta = 5
						fwrite (_nHdl, '461100000' + _sMargEsq + '270' + _sDescri1 + _Enter)
					elseif nConta = 6
						fwrite (_nHdl, '461100000' + _sMargEsq + '325' + _sDescri1 + _Enter)
					elseif nConta = 7
						fwrite (_nHdl, '461100000' + _sMargEsq + '380' + _sDescri1 + _Enter)
					endif
				endif
			(_sAliasQ) -> (dbskip ())
			nConta = nConta+1
			enddo
			fwrite (_nHdl, 'Q0001' + _Enter)
			fwrite (_nHdl, 'E' + _Enter)
			fclose (_nHdl)
			copy file (_sArq) to (_sPortaImp)
			delete file (_sArq)
		enddo
		(_sAliasQ) -> (dbclosearea ())
	endif	
	
/*	
	if _lContinua
	
		// configuração de velocidade
		_nHdl = fcreate (_sArq, 0)
		fwrite (_nHdl, _Esc + 'A'   + _Enter)
		fwrite (_nHdl, _Esc + 'CS6' + _Enter)
		fwrite (_nHdl, _Esc + 'Z'   + _Enter)
		fclose (_nHdl)
		copy file (_sArq) to (cPorta)
		delete file (_sArq)
		
		// configuração de claridade
		_nHdl = fcreate (_sArq, 0)
		fwrite (_nHdl, _Esc + 'A'   + _Enter)
		fwrite (_nHdl, _Esc + '#E1' + _Enter)
		fwrite (_nHdl, _Esc + 'Z'   + _Enter)
		fclose (_nHdl)
		copy file (_sArq) to (cPorta)
		delete file (_sArq)
			
		_aEtiqs = U_Qry2Array (_sQuery)
		
		// impressão das etiquetas
		_nHdl = fcreate (_sArq, 0)
		RptStatus({|| _Imprimir (_aEtiqs,_nOpcao)})
		fclose (_nHdl)
		copy file (_sArq) to (cPorta)
		delete file (_sArq)
	endif
	
endif

Return


//****************************************************************************************
// Função para imprimir as etiquetas

Static Function _Imprimir(_aEtiqs,_nOpcao)

Local _Enter := chr(13)+chr(10)
Local _Esc   := chr(27)

if len(_aEtiqs) > 0
	if _nOpcao == 1
		
		For _x := 1 to len(_aEtiqs)
			
			_sEnd := alltrim(_aEtiqs[_x][1])
							
			fwrite (_nHdl, _Esc + 'A' + _Enter)				// Inicializa etiqueta
			
			fwrite (_nHdl, _Esc + '%1')  			 		// Define rotação
			fwrite (_nHdl, _Esc + 'H0' + '340')		 		// Define ponto horizontal
			fwrite (_nHdl, _Esc + 'V0' + '670')		 		// Define ponto vertical
			fwrite (_nHdl, _Esc + '$A,400,480,0')	 		// Define fonte (espaçamento, largura, altura e tipo)
			fwrite (_nHdl, _Esc + '$=' + _sEnd + _Enter )	// Informação a ser impressa
			
			fwrite (_nHdl, _Esc + 'Q1' + _Enter)		 	// Define quantidade
			fwrite (_nHdl, _Esc + 'Z'  + _Enter)  	 		// Finaliza etiqueta
		next _x
	elseif _nOpcao == 2
		
		For _x := 1 to len(_aEtiqs)
			
			//_sEnd := alltrim(substr(_aEtiqs[_x][1],1,3) + '-' + substr(_aEtiqs[_x][1],4,2) + substr(_aEtiqs[_x][1],6,1))
			_sEnd := alltrim(substr(_aEtiqs[_x][1],1,1)) + '-' + alltrim(substr(_aEtiqs[_x][1],2,2)) + '-' + alltrim(substr(_aEtiqs[_x][1],4,2)) + '-' + alltrim(substr(_aEtiqs[_x][1],6,1))
			_sAnd := alltrim(substr(_aEtiqs[_x][1],5,1))
			_sBar := alltrim(_aEtiqs[_x][1])
			
			fwrite (_nHdl, _Esc + 'A' + _Enter)  	 		// Inicializa etiqueta
			
			fwrite (_nHdl, _Esc + '%0')  			 		// Define rotação
			fwrite (_nHdl, _Esc + 'H0' + '500')		 		// Define ponto horizontal
			fwrite (_nHdl, _Esc + 'V0' + '000')		 		// Define ponto vertical
			fwrite (_nHdl, _Esc + '$A,300,400,0')	 		// Define fonte (espaçamento, largura, altura e tipo)
			fwrite (_nHdl, _Esc + '$=' + _sAnd + _Enter )	// Informação a ser impressa
			
			fwrite (_nHdl, _Esc + '%0')  			 		// Define rotação
			fwrite (_nHdl, _Esc + 'H0' + '680')		 		// Define ponto horizontal
			fwrite (_nHdl, _Esc + 'V0' + '015')		 		// Define ponto vertical
			fwrite (_nHdl, _Esc + '$A,100,150,0')	 		// Define fonte (espaçamento, largura, altura e tipo)
			fwrite (_nHdl, _Esc + '$=' + "o" + _Enter )		// Informação a ser impressa
			
			fwrite (_nHdl, _Esc + '%0')  			 		// Define rotação
			fwrite (_nHdl, _Esc + 'H0' + '380')		 		// Define ponto horizontal
			fwrite (_nHdl, _Esc + 'V0' + '350')		 		// Define ponto vertical
			fwrite (_nHdl, _Esc + '$A,100,190,0')	 		// Define fonte (espaçamento, largura, altura e tipo)
			fwrite (_nHdl, _Esc + '$=' + _sEnd + _Enter )	// Informação a ser impressa
			
			
			fwrite (_nHdl, _Esc + '%0')  			 		// Define rotação
			fwrite (_nHdl, _Esc + 'H0' + '390')		 		// Define ponto horizontal
			fwrite (_nHdl, _Esc + 'V0' + '540')		 		// Define ponto vertical
			fwrite (_nHdl, _Esc + 'BG04200')	 			// Define código de barras (tipo, tamanho, altura)
			fwrite (_nHdl, '>G' + _sBar + _Enter )			// Informação a ser impressa no código de barras (estilo, dado)
			
			
			fwrite (_nHdl, _Esc + 'Q1' + _Enter)		 	// Define quantidade
			fwrite (_nHdl, _Esc + 'Z'  + _Enter)  	 		// Finaliza etiqueta
		next _x
	endif
else
	msgalert('Endereços não encontrados')
endif

Return
*/

//****************************************************************************************
// Perguntas
/*
Static Function ValidPerg()
aRegs  := {}

AADD(aRegs,{cPerg,"01","Endereço de     ?","","","mv_ch1","C",15,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SBE",""})
AADD(aRegs,{cPerg,"02","Endereço ate    ?","","","mv_ch2","C",15,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SBE",""})
AADD(aRegs,{cPerg,"03","impressora      ?","","","mv_ch3","C",60,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",   ""})

DbSelectArea("SX1")
DbSetOrder(1)
For i:=1 to Len(aRegs)
	If !DbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j<=Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next

Return
*/
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                         PERGUNT            TIPO TAM DEC VALID F3     Opcoes                      Help

		aadd (_aRegsPerg, {01, "Endereço de    ", "C", 15, 0,  "",   "SBE", {},  ""})
		aadd (_aRegsPerg, {02, "Endereço Até   ", "C", 15, 0,  "",   "SBE", {},  ""})
		aadd (_aRegsPerg, {03, "Impressora     ", "C", 2,  0,  "",   "ZX549", {},""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
