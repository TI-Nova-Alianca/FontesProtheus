// Programa:   BatOcor
// Autor:      Robert Koch
// Data:       13/11/2019
// Descricao:  Importacao e exportacao de arquivos do proceda.
//
// Historico de alteracoes:
// ??/??/???? - Andre? - Gravacao evento
// 11/03/2021 - Robert - Deleta arquivo quando jah importado.
//                     - Nao fechava arquivos apos a leitura e nao permitia deletar.
//

#include "totvs.ch"                                                            	
#include "protheus.ch"
#include "fileio.ch"

// --------------------------------------------------------------------------
user function BatOcor ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _nDir      := 0
	local _aDir      := {}
	local _nLock     := 0
	local _lContinua := .T.
	Local cLinha     := ''
	local _nQtArqImp := 0
	local _nQtArqErr := 0
	local _nQtArqDup := 0

	_oBatch:Retorno = 'S'  // Ateh prova em contrario, retorno = ok

	// Controla acesso via semaforo para evitar chamadas concorrentes, pois a importacao e a exportacao sao
	// agendadas separadamente nas rotinas de batch. A principio, o problema seria apenas a geracao de logs misturados.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			u_log2 ('info', "Bloqueio de semaforo.")
			_lContinua = .F.
			_oBatch:Retorno = 'N'
		endif
	endif

	if _lContinua 
		_aDir = Directory ("\PROCEDA\*.TXT")
		_aDir = asort (_aDir,,, {|_x, _y| _x [1] < _y [1]})
		if len (_aDir) == 0
			U_Log2 ('info', 'Nenhum arquivo a importar.')
			_lContinua = .F.
		endif
	endif
	if _lContinua 
		for _nDir = 1 to len (_aDir)
			u_log2 ('info', "Lendo arquivo " + _aDir [_nDir, 1])
			cArq := "\PROCEDA\" + _aDir [_nDir, 1]
			cArqDest := "\PROCEDA\IMPORTADO\" + _aDir [_nDir, 1]
			if file (cArqDest)
				_nQtArqDup ++
				u_log2 ('aviso', "Arquivo " + cArq + " ja importado.")
				// U_Log2 ('debug', 'deletando arquivo >>' + cArq + '<<')
				delete file (cArq)
				loop
			else
				_aDados := {}
				cLinha = ""
				FT_FUSE(cArq)
				ProcRegua(FT_FLASTREC())
				FT_FGOTOP()
				While !FT_FEOF()
					IncProc("Lendo arquivo texto EDI...")
					cLinha = FT_FREADLN() + chr(13) + chr(10)
					AADD (_aDados,cLinha)
					FT_FSKIP()
				EndDo
				FT_FUSE()  // Fecha arquivo
				if _Grava (_aDados) = .T.
					_nQtArqImp ++
					_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Importado")
				else
					_nQtArqErr ++
					_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Erro")
				endif
			endif
		next
	endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif

	_oBatch:Mensagens += cvaltochar (_nQtArqImp) + ' arq.lidos; ' + cvaltochar (_nQtArqDup) + ' arq.ja importados; ' + cvaltochar (_nQtArqErr) + ' arq.c/erro.'

	U_ML_SRArea (_aAreaAnt)
return (_oBatch:Retorno == 'N')



// --------------------------------------------------------------------------
// Move o arquivo importado para uma subpasta, para evitar nova tentativa de importacao.
Static Function _Move (_sArq, _sDest)
	local _sDrvRmt  := ""
	local _sDirRmt  := ""
	local _sArqRmt  := ""
	local _sExtRmt  := ""
	local _sArqDest := ""

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArq, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )

	// Cria diretorio, caso nao exista
	makedir (_sDirRmt + _sDest)

	// Copia o arquivo e depois deleta do local original.
	_sArqDest = _sArqRmt
	// U_Log2 ('debug', 'Movendo >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<< para >>' + _sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt + '<<')
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
	
	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt,, .t.)
	else
		// U_Log2 ('debug', 'Apagando arquivo movido >>' + _sDirRmt + _sArqRmt + _sExtRmt + '<<')
		delete file (_sDirRmt + _sArqRmt + _sExtRmt)
	endif

return

// --------------------------------------------------------------------------
Static Function _Grava (_aDados)
	local _nLinha    := 0
	local _oEvento   := NIL
	local _lRet      := .T.
	local _sTransp   := ''
	local _sOcor     := ''
	local _sDescProc := ''
	local _sSerie    := ''
	local _sNota     := ''
	local _sData     := ''
	local _dData     := ctod ('')
	local _sPedido   := ''

	for _nLinha = 1 to LEN (_aDados)
		// U_Log2 ('debug', 'lendo linha ' + cvaltochar (_nLinha) + ' --> ' + _aDados[_nLinha])
		if _nLinha = 1 .and. substr (_aDados[_nLinha],1,3) != '000'
			u_log ('erro', 'Formato de arquivo invalido.')
			_lRet := .F.
			exit
		endif
		if substr (_aDados[_nLinha],1,3) = '341'
			_sCGC := substr (_aDados[_nLinha],4,14)
			sa4->(dbsetorder(3))
			if ! sa4->(dbseek(xfilial('SA4') + _sCGC,.F.))
				u_help ('CNPJ ' + _sCGC + ' NÃO CADASTRADO COMO TRANSPORTADORA.',, .t.)
				_lRet := .F.
				exit
			else
				_sTransp := sa4->a4_cod
				// U_Log2 ('debug', 'transp: ' + _stransp)
			endif
		endif
		if _lRet .and. substr (_aDados[_nLinha],1,3) = '342'
			if empty (_sTransp)	
				U_Log2 ('erro', 'Encontrei registro tipo 342, mas nao tenho transportadora definida.')
				_lRet := .F.
				exit
			endif
			_sCGC := substr (_aDados[_nLinha],4,14)
			if substr (_sCGC,1,8) != substr (sm0->m0_cgc,1,8)
				u_log2 ('aviso', 'Ocorrencia com CGC de outra empresa.(' + _sCGC + ')')
				_lRet := .F.
				exit
			endif
			if substr (_sCGC,11,2) != cFilAnt
			 	u_log2 ('aviso', 'Ocorrencia se refere a NF de outra Filial.')
				_lRet := .F.
				exit
			endif
			_sOcor := substr (_aDados[_nLinha],29,2)
			_sDescProc = u_retZX5('51',_sOcor,'ZX5_51DESC')
			if empty (_sDescProc)
				u_log2 ('aviso', "Ocorrencia '" + _sOcor + "' nao cadastrada na tabela 51 do ZX5.")
				_lRet := .F.
				exit
			endif
			_sSerie := substr (_aDados[_nLinha],18,3)
			_sNota := '0' + substr (_aDados[_nLinha],21,8) // Layout contempla 8 posicoes apenas
			_sData := substr (_aDados[_nLinha],31,8)
			_dData := STOD(substr (_sData,5,4) + substr (_sData,3,2) + substr (_sData,1,2)) 
			sf2->(dbsetorder(1))
			if ! sf2->(dbseek(xfilial('SF2') + _sNota + _sSerie,.F.))
				u_log2 ('aviso', "NF '" + _sNota + '/' + _sSerie + "' nao encontrada.")
				_lRet := .F.
				exit
			else
				if _sOcor == '01' .and. empty (sf2 -> f2_vaDtEnt)
					// U_Log2 ('debug', 'atualizando f2_vaDtEnt')
					reclock ("SF2", .f.)
					sf2 -> f2_vaDtEnt = _dDATA
					msunlock ()
				endif
			endif

			//posiciona SD2 para buscar numero do pedido.
			sd2->(dbsetorder(3))
			if sd2->(dbseek(xfilial('SD2') + _sNota + _sSerie,.F.))
				_sPedido := sd2->d2_pedido
			else
				_sPedido := ''
			endif
			_oEvento := ClsEvent():new ()
			_oEvento:CodEven    = "SF2009"
			_oEvento:Texto      = ALLTRIM(_sDescProc)
			_oEvento:NFSaida    = sf2 -> f2_doc
			_oEvento:SerieSaid  = sf2 -> f2_serie
			_oEvento:PedVenda   = _sPedido
			_oEvento:Cliente    = sf2 -> f2_cliente
			_oEvento:LojaCli    = sf2 -> f2_loja
			_oEvento:DtEvento   = _dDATA
			_oEvento:HrEvento   = substr (_aDados[_nLinha],39,2) + ':' + substr (_aDados[_nLinha],41,2) 
			_oEvento:CodProceda = _sOcor
			_oEvento:Transp	    = _sTransp
			_oEvento:TranspReds = ''
			// _oEvento:Log ()
			_oEvento:GravaNovo ()
		endif
	next

Return _lRet
