// Programa:   BatEDIM
// Autor:      Robert Koch
// Data:       22/11/2010
// Descricao:  Importacao e exportacao de arquivos de EDI padrao mercador.
//             Criado para ser executado via batch.
//
// Historico de alteracoes:
// 17/01/2011 - Robert - Implementada chamada para exportacao automatica de arquivos.
// 22/06/2011 - Robert - Exportacao para Carrefour passa a ser feita no mesmo dia.
// 19/12/2011 - Robert - Incluido CNPJ do Makro para exportacao de notas fiscais.
// 30/07/2012 - Robert - Melhorados logs de execucao.
// 21/08/2012 - Robert - Passa a considerar o campo A1_VAEDING para exportacao de notas.
// 22/06/2020 - Robert - Melhorados logs.
//

#include "totvs.ch"                                                            	
#include "protheus.ch"

// --------------------------------------------------------------------------
user function BatEDIM (_sQueFazer)
	local _lRet      := .F.
	local _aAreaAnt  := {}
	local _aAmbAnt   := {}
	local _nDir      := 0
	local _aDir      := {}
	local _sQuery    := ""
	local _aClientes := {}
	local _nCliente  := 0
	local _nLock     := 0
	local _lContinua := .T.
	Local cLinha     := ''

	// Controla acesso via semaforo para evitar chamadas concorrentes, pois a importacao e a exportacao sao
	// agendadas separadamente nas rotinas de batch. A principio, o problema seria apenas a geracao de logs misturados.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			u_log2 ('erro', "Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif

	if _lContinua .and. _sQueFazer == "I"  // Importar pedidos.
		_aDir = Directory ("\Mercador\Ped\*.TXT")
	    if len (_aDir) > 0
			_aAreaAnt  := U_ML_SRArea ()
			_aAmbAnt   := U_SalvaAmb ()
			for _nDir = 1 to len (_aDir)
				u_log2 ('info', "Chamando leitura do arquivo " + _aDir [_nDir, 1])

				zzs -> (dbsetorder (2))
				if zzs -> (dbseek (xfilial ("ZZS") + _aDir [_nDir, 1], .F.))
					u_log2 ('info', "Arquivo ja importado para o ZZS. Movendo-o para pasta de ja importados.")
					_Move ("\mercador\ped\" + _aDir [_nDir, 1], "Lido_para_ZZS")
				else
					// grava na tabela ZZS, para histórico dos pedidos
					reclock("ZZS", .T.)
					Replace ZZS->ZZS_FILIAL  With xFilial()
					Replace ZZS->ZZS_NOMARQ  With _aDir [_nDir, 1]
					Replace ZZS->ZZS_DATA    With date()
					Replace ZZS->ZZS_HORA    With time()
					Replace ZZS->ZZS_USER    With upper(alltrim(cUserName))
					Replace ZZS->ZZS_ORIGEM  With "M"
					msunlock()
	
					cArq := "\mercador\ped\" + _aDir [_nDir, 1]
					cLinha = ""
					FT_FUSE(cArq)
					ProcRegua(FT_FLASTREC())
					FT_FGOTOP()
					While !FT_FEOF()
						IncProc("Lendo arquivo texto EDI...")
						cLinha += FT_FREADLN() + chr(13) + chr(10)
						FT_FSKIP()
					EndDo
					msmm (,,, cLinha, 1,,, "ZZS", "ZZS_MEMARQ")
					_Move ("\mercador\ped\" + _aDir [_nDir, 1], "Lido_para_ZZS")
					
					// Chama reprocessamento deste registro do ZZS para que seja feita a geracao do pedido de venda.
					U_ZZSR (.T.)
				endif
			next
			U_SalvaAmb (_aAmbAnt)
			U_ML_SRArea (_aAreaAnt)
		endif
		u_log2 ('info', "Nao ha arquivos a importar.")
		_lRet = .T.
	endif

	if _lContinua .and. _sQueFazer == "E"  // Exportar NF.

		// Seleciona clientes (o programa de exportacao trabalha por cliente)
		_sQuery := ""
		_sQuery += " select A1_COD, A1_VAEDING"
		_sQuery +=   " from " + RetSQLName ("SA1") + " SA1 "
		_sQuery +=  " where SA1.D_E_L_E_T_ = ''"
		_sQuery +=    " and A1_FILIAL  = '" + xfilial ("SA1") + "'"
		_sQuery +=    " and A1_VAEDING IN ('2', '4')"
		_aClientes = aclone (U_Qry2Array (_sQuery))

		for _nCliente = 1 to len (_aClientes)

			// Exporta as notas apos algum tempo, visando evitar que alguma NF ainda seja cancelada.
			// Tambem seta data inicial de alguns dias atras, para nao deixar nenhuma nota para tras.
			//u_log (_aClientes [_nCliente, 1])
			U_EDIM2 (.T., date ()-10, date (), _aClientes [_nCliente, 1], _aClientes [_nCliente, 1], "", "zzzzzz", "10 ", "\mercador\nf\")
		next
		_lRet = .T.
	endif

	// Libera semaforo.
	if _lContinua .and. _nLock > 0
		U_Semaforo (_nLock)
	endif

return _lRet



// --------------------------------------------------------------------------
// Move o arquivo importado para uma subpasta, para evitar nova tentativa de importacao.
Static Function _Move (_sArq, _sDest)
	local _sDrvRmt  := ""
	local _sDirRmt  := ""
	local _sArqRmt  := ""
	local _sExtRmt  := ""
//	local _sPath    := ""
	local _sArqDest := ""
	local _nSeqNome := 0

	// Separa drive, diretorio, nome e extensao.
	SplitPath (_sArq, @_sDrvRmt, @_sDirRmt, @_sArqRmt, @_sExtRmt )

	// Cria diretorio, caso nao exista
	makedir (_sDirRmt + _sDest)

	// Copia o arquivo e depois deleta do local original.
	//
	// Se o arquivo destino jah existir, renomeia-o acrescentando numeros no final.
	_sArqDest = _sArqRmt
	_nSeqNome = 1
	do while file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		_sArqDest = _sArqRmt + "(" + cvaltochar (_nSeqNome++) + ")"
	enddo
	u_log2 ('info', 'Movendo arquivo ' + (_sDirRmt + _sArqRmt + _sExtRmt) + ' para ' + (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt))
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)

	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		if funname() == 'ZZS'
			delete file (_sDirRmt + _sArqRmt + _sExtRmt)
		else
			u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt)
		endif
	else
		delete file (_sDirRmt + _sArqRmt + _sExtRmt)
	endif
return
