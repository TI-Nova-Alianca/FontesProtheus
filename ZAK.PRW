// Programa:   ZAK
// Autor:      Robert Koch
// Data:       16/09/2017
// Descricao:  Tela de manutencao amarracao associados X grupos familiares.
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function ZAK ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Amarracao grupos familiares X associados"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T.)//, cEmpAnt, cFilAnt)
		return
	endif

   aAdd(aRotina, {"Pesquisar"   , "AxPesqui", 0, 1})
   aAdd(aRotina, {"Visualizar"  , "AxVisual", 0, 2})
   aAdd(aRotina, {"Incluir"     , 'axinclui ("ZAK", zak->(recno ()), 3, NIL, NIL, NIL, "U_ZAKIK ()")', 0, 3})
   aAdd(aRotina, {"Alterar"     , "AxAltera", 0, 4})
   aAdd(aRotina, {"Excluir"     , "AxDeleta", 0, 5})

   dbSelectArea ("ZAK")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "ZAK",,,,, 2)
return



// --------------------------------------------------------------------------
// Valida 'Tudo OK' da inclusao.
user function ZAKIK ()
	local _lRet     := .T.
	
	zak -> (dbsetorder (1))  // ZAK_FILIAL+ZAK_ASSOC+ZAK_LOJA+ZAK_IDZAN
	if zak -> (dbseek (xfilial ("ZAK") + m->zak_assoc + m->zak_loja, .F.))
		u_help ("Associado ja relacionado ao grupo familiar '" + zak -> zak_idzan + "'.")
		_lRet = .F.
	endif
return _lRet	
