// Programa:  A650AltD4
// Autor:     Robert Koch
// Data:      30/08/2023
// Descricao: P.E. ajuste aCols dos empenhos da abertura de OP
//            Criado inicialmente para empenhar ME no ax.08 (GLPI 14146)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #P.E. durante a leitura da estrutura e geracao do aCols dos empenhos da abertura de OP
// #PalavasChave      #empenho_OP #almox
// #TabelasPrincipais #SC2 #SD4
// #Modulos           #PCP #EST

// --------------------------------------------------------------------------
user function A650AltD4 ()
	local _aAreaAnt := U_ML_SRArea ()
	local _nLinha   := 0
	local _sComp    := ''
	local _sLocEmpA := ''  // Local (almox) do empenho antes
	local _sLocEmpD := ''  // Local (almox) do empenho depois
// Nao pude ativar esta parte ainda... Robert, 30/08/23 --->	local _sCCNovo  := ''
// Nao pude ativar esta parte ainda... Robert, 30/08/23 --->	local _sMMMNovo := ''

//	U_Log2 ('debug', '[' + procname () + ']aCols antes:')
//	U_LogACols ()
	//U_Log2 ('debug', aCols)
	
	// Altera local dos empenhos.
	if cFilAnt == '01'
		sb1 -> (dbsetorder (1))
		for _nLinha = 1 to len (aCols)
			_sComp = GDFieldGet ("G1_COMP", _nLinha)
			if ! sb1 -> (dbseek (xfilial ("SB1") + _sComp, .F.))
				u_help ("Cadastro do componente '" + alltrim (_sComp) + "' nao localizado na tabela SB1. Aluste de empenhos nao pode ser feito.",, .t.)
			else
				_sLocEmpA = GDFieldGet ("D4_LOCAL", _nLinha)
				_sLocEmpD = _sLocEmpA
				if sb1 -> b1_tipo == 'ME' .or. alltrim (sb1 -> b1_cod) $ '4191/4360'
					_sLocEmpD = '08'
				elseif sb1 -> b1_tipo == 'PS' .or. alltrim (sb1 -> b1_grupo) $ '4000/0407'
					_sLocEmpD = '07'
				endif
				if _sLocEmpD != _sLocEmpA
					U_Log2 ('debug', '[' + procname () + ']OP: ' + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + '  empenho do item ' + alltrim (_sComp) + ' vai ser mudado do alm ' + _sLocEmpA + ' para ' + _sLocEmpD)
					GDFieldPut ("D4_LOCAL", _sLocEmpD, _nLinha)
				endif
			endif
		next
	endif

/* Nao posso ativar este trecho ainda por que as linhas
do aCols estao vindo todas como ativas, mas sei que posteriormente
vao ser marcadas como deletadas quando o componente estiver fora
de validade, etc.
Se eu alterar os MMM agora, corro o ricso de ter 2 empenhos do mesmo
item, por exeplo trocando MMM091401 (linha deletada) para MMM011401
sendo que jah existiria uma outra linha com MMM011401 (nao deletada)
Vou abrir chamado na Totvs pedindo que o aCols venha com a indicacao
da linha deletada. Robert, 30/08/23

	// Altera centro de custo da mao de obra conforme a filial.
	if cFilAnt == '01'
		for _nLinha = 1 to len (aCols)
			_sComp = GDFieldGet ("G1_COMP", _nLinha)
			if len (alltrim (_sComp)) == 9 .and. left (_sComp, 3) == 'MMM' .and. substr (_sComp, 4, 2) != cFilAnt
				_sCCNovo = cFilAnt + substr (_sComp, 6, 7)

				// Se o CC nao existir nesta filial ou estiver bloqueado, troca pelo da 01.
				ctt -> (dbsetorder (1))  // CTT_FILIAL+CTT_CUSTO
				if ! ctt -> (dbseek (xfilial ("CTT") + _sCCNovo, .F.))
	// Como o aCols nao estah diferenciando linhas deletadas, optei por nao mostrar esta msg agora.				u_help ('O CC a ser usado na OP (' + _sCCNovo + ') nao existe nesta filial! Ajuste manualmente o empenho de mao de obra.',, .t.)
				else
					if ctt -> ctt_bloq == '1'
	// Como o aCols nao estah diferenciando linhas deletadas, optei por nao mostrar esta msg agora.					u_help ('O CC a ser usado na OP (' + _sCCNovo + ') encontra-se bloqueado nesta filial! Ajuste manualmente o empenho de mao de obra.',, .t.)
					else

						// Incluir empenho do CC novo
						_sMMMNovo = left ('MMM' + _sCCNovo + space (100), TamSX3 ("B1_COD")[1])
						sb1 -> (dbsetorder (1))
						if ! sb1 -> (dbseek (xfilial ("SB1") + _sMMMNovo, .F.))
	// Como o aCols nao estah diferenciando linhas deletadas, optei por nao mostrar esta msg agora.						U_help ('O item a ser incluido da OP (' + _sMMMNovo + ') nao existe no cadastro! Ajuste manualmente o empenho de mao de obra.',, .t.)
						else
							if sb1 -> b1_msblql == '1'
	// Como o aCols nao estah diferenciando linhas deletadas, optei por nao mostrar esta msg agora.							U_help ('O item a ser incluido na OP (' + _sMMMNovo + ') encontra-se bloqueado no cadastro! Ajuste manualmente o empenho de mao de obra.',, .t.)
							else
								U_Log2 ('debug', '[' + procname () + ']OP: ' + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + '  empenho do item ' + alltrim (_sComp) + ' vai ser mudado para ' + _sMMMNovo)
								GDFieldPut ("G1_COMP", _sMMMNovo, _nLinha)
								GDFieldPut ("G1_DESC", fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sMMMNovo, 'B1_DESC'), _nLinha)
							endif
						endif
					endif
				endif
			endif
		next
	endif
*/

//	U_Log2 ('debug', '[' + procname () + ']aCols depois:')
//	U_LogACols ()
	U_ML_SRArea (_aAreaAnt)
return
