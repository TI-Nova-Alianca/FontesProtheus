// Programa:   BatOcor
// Autor:      Robert Koch
// Data:       13/11/2019
// Descricao:  Importacao e exportacao de arquivos do proceda.
//
// Historico de alteracoes:
//

#include "totvs.ch"                                                            	
#include "protheus.ch"
#include "fileio.ch"

// --------------------------------------------------------------------------
user function BatOcor ()
	local _lRet      := .F.
	local _aAreaAnt  := {}
	local _aAmbAnt   := {}
	local _nDir      := 0
	local _aDir      := {}
	//local _sQuery    := ""
	//local _aClientes := {}
	//local _nCliente  := 0
	local _nLock     := 0
	local _lContinua := .T.
	Local cLinha     := ''
	
	
	// Controla acesso via semaforo para evitar chamadas concorrentes, pois a importacao e a exportacao sao
	// agendadas separadamente nas rotinas de batch. A principio, o problema seria apenas a geracao de logs misturados.
	if _lContinua
		_nLock := U_Semaforo (procname () + cEmpAnt + cFilAnt, .F.)
		if _nLock == 0
			//u_log ("Bloqueio de semaforo.")
			_lContinua = .F.
		endif
	endif

	if _lContinua 
		_aDir = Directory ("\PROCEDA\*.TXT")
	    if len (_aDir) > 0
			_aAreaAnt  := U_ML_SRArea ()
			_aAmbAnt   := U_SalvaAmb ()
			//u_log ("Arquivos a importar:", _aDir)
			for _nDir = 1 to len (_aDir)
				//u_log ("Chamando leitura do arquivo ", _aDir [_nDir, 1])
				cArq := "\PROCEDA\" + _aDir [_nDir, 1]
				cArqDest := "\PROCEDA\IMPORTADO\" + _aDir [_nDir, 1]
				if file (cArqDest)
					u_help ("Arquivo já importado.")
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
					if _Grava (_aDados) = .T.
						_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Importado")
					else
						_Move ("\PROCEDA\" + _aDir [_nDir, 1], "Erro")
					endif
				endif
			next
			U_SalvaAmb (_aAmbAnt)
			U_ML_SRArea (_aAreaAnt)
		endif
		//u_log ("Nao ha arquivos a importar.")
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
	//local _sPath    := ""
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
	copy file (_sDirRmt + _sArqRmt + _sExtRmt) to (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
	
	if ! file (_sDirRmt + _sDest + "\" + _sArqDest + _sExtRmt)
		u_help ("Erro ao mover arquivo " + _sArqRmt + _sExtRmt)
	else
		delete file (_sDirRmt + _sArqRmt + _sExtRmt)
	endif

return

// --------------------------------------------------------------------------
Static Function _Grava (_aDados)
	local _nLinha := 0
	local _oEvento := NIL
	local _lRet := .T.
	
	_nLinha := 1
	do while _nLinha <= LEN (_aDados)
		if _nLinha = 1 .and. substr (_aDados[_nLinha],1,3) != '000' 
			u_help ('Formato de arquivo invalido.')
			_lRet := .F.
			exit
		else
			if substr (_aDados[_nLinha],1,3) = '341'
				_sTransp := ''
				_sCGC := substr (_aDados[_nLinha],4,14)
				sa4->(dbsetorder(3))
				if ! sa4->(dbseek(xfilial('SA4') + _sCGC,.F.))
					u_help ('CNPJ ' + _sCGC + ' NÃO CADASTRADO COMO TRANSPORTADORA.')
					_lRet := .F.
					exit
				else
					_sTransp := sa4->a4_cod
				endif
			endif
			if substr (_aDados[_nLinha],1,3) = '342'
				_sCGC := substr (_aDados[_nLinha],4,14)
				if substr (_sCGC,1,8) != substr (sm0->m0_cgc,1,8)
					u_help ('Ocorrencia com CGC de outra empresa.(' + _sCGC + ')')
				else
					if substr (_sCGC,11,2) != cFilAnt
					 	u_help ('Ocorrencia se refere a NF de outra Filial.')
					else 	
						_sSerie := substr (_aDados[_nLinha],18,3)
						_sNota := '0' + substr (_aDados[_nLinha],21,8) // Layout contempla 8 posicoes apenas
						_sOcor := substr (_aDados[_nLinha],29,2)
						_sData := substr (_aDados[_nLinha],31,8)
						_dData := STOD(substr (_sData,5,4) + substr (_sData,3,2) + substr (_sData,1,2)) 
						sf2->(dbsetorder(1))
						if ! sf2->(dbseek(xfilial('SF2') + _sNota + _sSerie,.F.))
							u_help ('Nota nao encontrada.')
						else
							//posiciona SD2 para buscar numero do pedido.
							sd2->(dbsetorder(3))
							if sd2->(dbseek(xfilial('SD2') + _sNota + _sSerie,.F.))
								_sPedido := sd2->d2_pedido
							else
								_sPedido := ''
							endif
							_oEvento := ClsEvent():new ()
							_oEvento:CodEven   = "SF2009"
							_oEvento:Texto     = ALLTRIM(u_retZX5('51',_sOcor,'ZX5_51DESC'))
							_oEvento:NFSaida   = sf2 -> f2_doc
							_oEvento:SerieSaid = sf2 -> f2_serie
							_oEvento:PedVenda  = _sPedido
							_oEvento:Cliente   = sf2 -> f2_cliente
							_oEvento:LojaCli   = sf2 -> f2_loja
							_oEvento:DtEvento  = _dDATA
							_oEvento:HrEvento  = substr (_aDados[_nLinha],39,2) + ':' + substr (_aDados[_nLinha],41,2) 
							_oEvento:CodProceda= _sOcor
							_oEvento:Transp	   = _sTransp
							_oEvento:TranspReds= ''
							_oEvento:Grava ()
							
						endif
					endif
				endif
			endif
		endif
		_nLinha ++
	enddo
						
Return _lRet
