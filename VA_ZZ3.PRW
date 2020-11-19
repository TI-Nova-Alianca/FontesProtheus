// Programa...: VA_ZZ3
// Autor......: Leandro Scapini / Robert Koch
// Data.......: 06/06/2008
// Cliente....: Alianca
// Descricao..: Tela de manutencao de amarracao transportadoras X pracas de atendimento X valores de frete.
//
// Projeto....: Controle de fretes
//
// Historico de alteracoes:
// 

// --------------------------------------------------------------------------
User Function VA_zz3 ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Transportadoras X pracas de entrega"

   aAdd(aRotina, {"Pesquisar",  "AxPesqui" , 0, 1})
   aAdd(aRotina, {"Visualizar", "U_VA_ZZ3A", 0, 2})
   aAdd(aRotina, {"Incluir"  ,  "U_VA_ZZ3A", 0, 3})
   aAdd(aRotina, {"Alterar"  ,  "U_VA_ZZ3A", 0, 4})
   aAdd(aRotina, {"Excluir"  ,  "U_VA_ZZ3E", 0, 5})

   dbSelectArea ("ZZ3")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "ZZ3",,,,, 2)
return



// --------------------------------------------------------------------------
// Tela de manutencao
user function VA_ZZ3a ()
   private _sTransp  := ""
   private _sNomeTra := space (50)
   private aHeader   := {}
   private aCols     := {}
   private N         := 1
	private aGets     := {}
	private aTela     := {}

   nOpc := 2
   if inclui .or. altera
      nOpc = 4
   endif

   if inclui
      _sTransp  = CriaVar ("ZZ3_TRANSP")
   else
      _sTransp = zz3 -> zz3_transp
   endif
	_sNomeTra = CriaVar ("ZZ3_NOMTRA")

   // Gera aHeader e aCols.
   aHeader := U_GeraHead ("ZZ3", .F., {"ZZ3_TRANSP", "ZZ3_NOMTRA"})
   if ! inclui
      aCols := U_GeraCols ("ZZ3", ;  // Alias
                           1, ;  // Indice
                           xfilial ("ZZ3") + zz3 -> zz3_transp, ;  // Seek inicial
                           'xfilial ("ZZ3") + zz3 -> zz3_transp == "' + xfilial ("ZZ3") + zz3 -> zz3_transp + '"', ;  // While
                           aHeader, ;  // Passa aHeader por que posso estar usando MsNewGetDados
                           .F.)  // Executa ou nao os gatilhos.
   else
      aCols := {}
      aadd (aCols, aclone (U_LinVazia (aHeader)))
   endif

   // Variaveis do cabecalho da tela:
   aC:={}
   aadd (aC, {"_sTransp",  {15, 5},   "Transportadora", "@!", "vazio () .or. (existcpo ('SA4') .and. existchav ('ZZ3') .and. U_VA_ZZ3VT ())", "SA4", inclui})
   aadd (aC, {"_sNomeTra", {15, 100}, "Nome ",          "@!", "", "", .F.})

   aR := {}
   _aJanela := {100, 50, oMainWnd:nClientHeight - 50, oMainWnd:nClientWidth - 50}  // Janela (dialog) do modelo2
   aCGD := {55,20,118,315}
   if Modelo2 (cCadastro, ;  // Titulo
                 aC, ;  // Cabecalho
                 aR, ;  // Rodape
                 aCGD, ;  // Coordenadas da getdados
                 nOpc, ;  // nOPC
                 'U_VA_ZZ3LK ()', ;  // Linha OK
                 'U_VA_ZZ3TK ()', ;  // Tudo OK
                 , ;  // Gets editaveis
                 , ;  // bloco codigo para tecla F4
                 , ;  // Campos inicializados
                 9999, ;  // Numero maximo de linhas
                 _aJanela, ;  // Coordenadas da janela
                 .T.)  // Linhas podem ser deletadas.

		// Gravacao
      // Monta lista de campos que nao estao no browse, com seu devido conteudo, para posterior gravacao.
      _aCposFora := {}
      aadd (_aCposFora, {"ZZ3_FILIAL", xfilial ("ZZ3")})
      aadd (_aCposFora, {"ZZ3_TRANSP", _sTransp})

      // Grava dados do aCols.
      ZZ3 -> (dbsetorder (1))  // ZZ3_FILIAL + ZZ3_TRANSP + ZZ3_ORIGEM + ZZ3_DESTIN
      for N = 1 to len (aCols)

         // Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
         if ZZ3 -> (dbseek (xfilial ("ZZ3") + _sTransp + GDFieldGet ("ZZ3_ITEM") , .F.))

            // Se estah deletado em aCols, preciso excluir do arquivo tambem.
            if GDDeleted ()
               reclock ("ZZ3", .F.)
               ZZ3 -> (dbdelete ())
               msunlock ("ZZ3")
            else  // Alteracao
               reclock ("ZZ3", .F.)
               U_GrvACols ("ZZ3", N, _aCposFora)
               msunlock ("ZZ3")
            endif

         else  // A linha ainda nao existe no arquivo
            if GDDeleted ()
               loop
            else
               reclock ("ZZ3", .T.)
               U_GrvACols ("ZZ3", N, _aCposFora)
               msunlock ("ZZ3")
            endif
         endif
      next

   endif
return



// --------------------------------------------------------------------------
// Exclusao total.
user function VA_ZZ3E ()
	//local _aArea     := getarea ()
   local _sTransp   := zz3 -> zz3_transp
	local _sQuery    := ""
	local _lContinua := .T.

	_sQuery := ""
	_sQuery += " select count (ZZ0_FILIAL)"
	_sQuery += "   from " + RetSQLName ("ZZ0") + " ZZ0 "
	_sQuery += "  where ZZ0.D_E_L_E_T_ != '*'"
	_sQuery += "    and ZZ0.ZZ0_FILIAL =  '" + xfilial ("ZZ0") + "'"
	_sQuery += "    and ZZ0.ZZ0_TRANSP =  '" + _sTransp + "'"
	if U_RetSQL (_sQuery) > 0
		u_help ("Tabela nao pode ser deletada, pois tem relacionamento(s) na tabela de cidades atendidas.")
		_lContinua = .F.
	endif

	if _lContinua .and. msgyesno ("Confirma a exclusao de todos os valores para a transportadora " + zz3 -> zz3_transp + "?","Exclusão")
		zz3 -> (dbsetorder (1))  // zz3_FILIAL + zz3_TRANSP + zz3_ORIGEM + zz3_DESTIN
		zz3 -> (dbseek (xfilial ("zz3") + _sTransp, .T.))
		do while ! zz3 -> (eof ()) .and. zz3 -> zz3_filial == xfilial ("zz3") .and. zz3 -> zz3_transp == _sTransp
			reclock ("zz3", .F.)
			zz3 -> (dbdelete ())
			msunlock ()
			zz3 -> (dbskip ())
		enddo
		u_help ("Dados excluidos.")
	endif
return



// --------------------------------------------------------------------------
// Validacao transportadora
user function VA_zz3VT ()
   local _lRet    := .T.
   _sNomeTra = fbuscacpo ("SA4", 1, xfilial ("SA4") + _sTransp, "A4_NOME")
return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Linha OK'
user function VA_zz3LK ()
   local _lRet    := .T.
   //local _nLinha  := 0

   // Verifica campos obrigatorios
   if _lRet .and. ! GDDeleted ()
      _lRet = MaCheckCols (aHeader, aCols, N, {})
   endif

   if _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZZ3_ITEM"}, 4)
	endif
return _lRet



// --------------------------------------------------------------------------
// Validacao de 'Tudo OK'
user function VA_zz3TK ()
   local _lRet    := .T.
   //local _nLinha  := 0
	local _sQuery  := ""

	for N = 1 to len (aCols)
		if _lRet .and. GDDeleted ()
			_sQuery := ""
			_sQuery += " select count (ZZ0_FILIAL)"
			_sQuery += "   from " + RetSQLName ("ZZ0") + " ZZ0 "
			_sQuery += "  where ZZ0.D_E_L_E_T_ != '*'"
			_sQuery += "    and ZZ0.ZZ0_FILIAL =  '" + xfilial ("ZZ0") + "'"
			_sQuery += "    and ZZ0.ZZ0_TRANSP =  '" + _sTransp + "'"
			_sQuery += "    and ZZ0.ZZ0_ITEM   =  '" + GDFieldGet ("ZZ3_ITEM") + "'"
			if U_RetSQL (_sQuery) > 0
				u_help ("Linha " + cvaltochar (N) + " nao pode ser deletada, pois tem relacionamento na tabela de cidades atendidas.")
				_lRet = .F.
				exit
			endif
		endif
	next
return _lRet
