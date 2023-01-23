// Programa...: MTAGrSD4
// Autor......: Leandro Perondi - DWT
// Data.......: 02/07/2014
// Descricao..: P.E. apos gravar SD4.
//              Criado inicialmente para mudar local dos empenhos.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Possibilita alteracao empenhos de OP
// #PalavasChave      #empenhos
// #TabelasPrincipais #SD4
// #Modulos           #EST #PCP

// Historico de alteracoes:
// 19/08/2014 - Robert - salva e restaura areas de trabalho.
// 25/10/2014 - Robert - Passa a usar a funcao U_LocEmp.
// 05/10/2016 - Robert - Passa a verificar campo B1_APROPRI antes de alterar o almox. dos empenhos.
// 11/05/2017 - Robert - Funcao de ajuste de almox. dos empenhos passa a ser externa.
// 08/04/2019 - Catia  - include TbiConn.ch 
// 23/01/2023 - Robert - Migrado de MATA380 para MATA381 (GLPI 11997)
//                     - Gera aviso em caso de erro na alteracao de empenhos.
//

//#include "colors.ch"
//#Include "Protheus.ch"
//#Include "RwMake.ch"
//#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function mtagrsd4()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _sLocEmp  := ""

	// Altera armazem dos empenhos.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT dbo.VA_FLOC_EMP_OP ('" + cFilAnt + "', D4_COD) AS LOCEMP"
	_oSQL:_sQuery +=  " FROM " + RetSqlName ("SD4") + " SD4 "
	_oSQL:_sQuery +=  " WHERE SD4.R_E_C_N_O_ = " + cvaltochar (sd4 -> (recno ()))
	_sLocEmp = _oSQL:RetQry (1, .F.)
	if _sLocEmp != sd4 -> d4_local
		U_AjLocEmp (_sLocEmp)
	endif

	// Altera centro de custo da mao de obra conforme a filial.
	_AltCC ()

	U_ML_SRArea (_aAreaAnt)
return



// ----------------------------------------------------------------------
// Alguns centros de custo existem apenas na matriz.
static function _AltCC ()
	local _sCCNovo   := ""
	local _sMMMNovo  := ""
	local _sLocal    := ""
	Local _aCab      := {}
	Local _aLinha    := {}
	Local _aItens    := {}
	local _lContinua := .T.
	local _oAviso    := NIL
	private _sErroAuto := ''

	if cEmpAnt == '01' .and. left (sd4 -> d4_cod, 3) == 'MMM' .and. substr (sd4 -> d4_cod, 4, 2) != cFilAnt

		// Monta o cabeçalho com o número da OP que será alterada.
		// Necessário utilizar o índice 2 para efetuar a alteração.
		_aCab := {{"D4_OP",sd4 -> d4_op,NIL},{"INDEX",2,Nil}}

		// Excluir empenho do CC errado
		//
		//Adiciona as informações do empenho, conforme estão na tabela SD4.
		_aLinha := {}
		//
		// Preciso disponibilizar os campos que compoe a chave unica da tabela.
		aadd (_aLinha, {"D4_FILIAL", sd4 -> d4_filial, NIL})
		aadd (_aLinha, {"D4_OP", sd4 -> d4_op, NIL})
		aadd (_aLinha, {"D4_COD", sd4 -> d4_cod, NIL})
		aadd (_aLinha, {"D4_SEQ", sd4 -> d4_seq, NIL})
		aadd (_aLinha, {"D4_TRT", sd4 -> d4_trt, NIL})
		aadd (_aLinha, {"D4_LOTECTL", sd4 -> d4_lotectl, NIL})
		aadd (_aLinha, {"D4_NUMLOTE", sd4 -> d4_numlote, NIL})
		aadd (_aLinha, {"D4_OPORIG", sd4 -> d4_oporig, NIL})
		aadd (_aLinha, {"D4_LOCAL", sd4 -> d4_local, NIL})
		//
		//Adiciona o identificador LINPOS para identificar que o registro já existe na SD4
		// Pelo que entendi, devem permanecer aqui todos os campos da chave unica da tabela
		aAdd(_aLinha,{"LINPOS","D4_COD+D4_TRT+D4_LOTECTL+D4_NUMLOTE+D4_LOCAL+D4_OPORIG+D4_SEQ",;
		SD4->D4_COD,;
		SD4->D4_TRT,;
		SD4->D4_LOTECTL,;
		SD4->D4_NUMLOTE,;
		SD4->D4_LOCAL,;
		SD4->D4_OPORIG,;
		SD4->D4_SEQ})
		//
		// Preciso excluir a linha do empenho.
		aAdd(_aLinha,{"AUTDELETA","S",Nil})
		U_Log2 ('debug', _aLinha)
		//
		//Adiciona as informações do empenho no array de itens.
		aAdd(_aItens,_aLinha)

		_sCCNovo = cFilAnt + substr (sd4 -> d4_cod, 6, 7)
		
		// Se o CC nao existir nesta filial ou estiver bloqueado, troca pelo da 01.
		ctt -> (dbsetorder (1))  // CTT_FILIAL+CTT_CUSTO
		if ! ctt -> (dbseek (xfilial ("CTT") + _sCCNovo, .F.))
			u_help ('O CC a ser usado na OP (' + _sCCNovo + ') nao existe nesta filial!',, .t.)
			_lContinua = .F.
		else
			if ctt -> ctt_bloq == '1'
				u_help ('O CC a ser usado na OP (' + _sCCNovo + ') encontra-se bloqueado nesta filial!',, .t.)
				_lContinua = .F.
			else

				// Incluir empenho do CC novo
				_sMMMNovo = left ('MMM' + _sCCNovo + space (15), 15)
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sMMMNovo, .F.))
					U_help ('O item a ser incluido da OP (' + _sMMMNovo + ') nao existe no cadastro!',, .t.)
					_lContinua = .F.
				else
					if sb1 -> b1_msblql == '1'
						U_help ('O item a ser incluido na OP (' + _sMMMNovo + ') encontra-se bloqueado no cadastro!',, .t.)
						_lContinua = .F.
					else
						_sLocal = FBuscaCpo ("SB1", 1, xfilial ("SB1") + _sMMMNovo, "B1_LOCPAD")

						// Insere uma nova linha com o novo CC.
						_aLinha = {}
						aadd (_aLinha, {"D4_FILIAL", sd4 -> d4_filial, NIL})
						aadd (_aLinha, {"D4_OP", sd4 -> d4_op, NIL})
						aadd (_aLinha, {"D4_COD", _sMMMNovo, NIL})
						aadd (_aLinha, {"D4_LOCAL", _sLocal, NIL})
						aadd (_aLinha, {"D4_DATA", FBuscaCpo ("SC2", 1, xfilial ("SC2") + sd4 -> d4_op, "C2_DATPRI"), NIL})
						aadd (_aLinha, {"D4_QUANT", sd4 -> d4_quant, NIL})
						aadd (_aLinha, {"D4_QTDEORI", sd4 -> d4_qtdeori, NIL})
						U_Log2 ('debug', _aLinha)
						aAdd(_aItens,_aLinha)
					endif
				endif
			endif
		endif

		// Executa o MATA381, com opcao de alteracao, apenas uma vez, pois vai
		// receber uma array com duas linhas: uma com o CC velho (previamente
		// marcada como AUTDELETA) e uma com o CC novo.
		if _lContinua
			private lMsErroAuto := .F.
			MSExecAuto({|x,y,z| mata381(x,y,z)},_aCab,_aItens,4)
			If lMsErroAuto
				_lContinua = .F.
				_sErroAuto = U_LeErro (memoread (NomeAutoLog ()))
				U_Log2 ('erro', '[' + procname () + ']' + _sErroAuto)
				MostraErro()
			EndIf
		endif

		if ! empty (_sErroAuto)
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'047', '122'}  // 047 = Grupo do PCP; 122 = grupo da TI
			_oAviso:Titulo     = "Erro ajuste empenhos OP " + sd4 -> d4_op
			_oAviso:Texto      = _sErroAuto
			_oAviso:Origem     = procname (1) + '.' + procname (0)
			_oAviso:InfoSessao = .T.  // Incluir informacoes adicionais de sessao na mensagem.
			_oAviso:Grava ()
		endif

	endif
return
