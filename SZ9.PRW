// Programa:   SZ9
// Autor:      Robert Koch
// Data:       18/09/2017
// Descricao:  Tela de manutencao cadastro de talhoes das propriedades rurais (de associados).
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function SZ9 ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Manutencao de talhoes de propriedades rurais"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

   aAdd(aRotina, {"Pesquisar"   , "AxPesqui", 0, 1})
   aAdd(aRotina, {"Visualizar"  , "AxVisual", 0, 2})
   aAdd(aRotina, {"Incluir"     , "AxInclui", 0, 3})
   aAdd(aRotina, {"Alterar"     , "AxAltera", 0, 4})
   aAdd(aRotina, {"Excluir"     , "AxExclui", 0, 5})
   //aAdd(aRotina, {"Importar KML", "U_SZ9_KML('I')", 0, 4})
   //aAdd(aRotina, {"Visualizar KML", "U_SZ9_KML('V')", 0, 4})

   dbSelectArea ("SZ9")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "SZ9",,,,, 2)
return
