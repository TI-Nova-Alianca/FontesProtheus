// Programa...: VA_RAPCAD
// Autor......: Cláudia Lionço
// Data.......: 22/08/2023
// Descricao..: Tela de manutenção de percentual de contratos rapel
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de manutenção de percentual de contratos rapel
// #PalavasChave      #rapel #contratos_de_rapel #percentual_de_contratos_rapel
// #TabelasPrincipais #ZBG
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------------------
#include "Totvs.ch"
#include 'protheus.ch'

User Function VA_RAPCTR()
	Private cCadastro 	:= "Composição do Contrato de Verbas"
	Private aRotina 	:= {}
	
    _sPreFiltr := "ZBG_CLI='" + ZA7->ZA7_CLI + "' AND ZBG_LOJA='" + ZA7->ZA7_LOJA + "'"

	AADD( aRotina, {"Pesquisar"  		,"AxPesqui" 	    ,0,1})
	AADD( aRotina, {"Visualizar" 		,"U_VA_RAPA(2)"  	,0,2})
	AADD( aRotina, {"Incluir"    		,"U_VA_RAPI()"  	,0,3})
	AADD( aRotina, {"Alterar"    		,"U_VA_RAPA(4, 	'allwaystrue ()', 'allwaystrue ()', .T., '','" + xfilial("ZA7") +"','" + ZA7->ZA7_CLI + "','" + ZA7->ZA7_LOJA +"')"  ,0,4})

	dbSelectArea("ZBG")
	dbSetOrder(1)
	dbGoTop()
	
	aCabTela  := {} 
	aadd (aCabTela,{ "Filial"		,"ZBG_FILIAL" 	})
	aadd (aCabTela,{ "Cliente"		,"ZBG_CLI"	 	})
	aadd (aCabTela,{ "loja"			,"ZBG_LOJA"		})
	aadd (aCabTela,{ "Tipo"			,"ZBG_TIPO"		})
	aadd (aCabTela,{ "Percentual"	,"ZBG_PERC"		})
    aadd (aCabTela,{ "Observacao"	,"ZBG_OBS"		})

	mBrowse(,,,,"ZBG",aCabTela,,,,,,,,,,,,,_sPreFiltr)

Return
//
// ------------------------------------------------------------------------------------------------
// Incluir AxCadastro
User Function VA_RAPI()
	AxInclui("ZBG",,,,,,"U_VA_RAPTOK()")
Return
//
// ------------------------------------------------------------------------------------------------
// Rotina Tudo OK tabela ZBG
User Function VA_RAPTOK()
	Local _lRet   := .T.

Return _lRet
//
// ------------------------------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function VA_RAPLOK ()
	local _lRet := .T.

	If _lRet .and. ! GDDeleted ()
		If empty(GDFieldGet("ZBG_CLI"))
			u_help("Campo <Cliente> é obrigatório!")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("ZBG_LOJA"))
			u_help("Campo <Loja> é obrigatório!")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("ZBG_TIPO"))
			u_help("Campo <Tipo> é obrigatório")
			_lRet := .F.
		EndIf

        If empty(GDFieldGet("ZBG_PERC"))
			u_help("Campo <Percentual> é obrigatório")
			_lRet := .F.
		EndIf
	EndIf
Return _lRet
//
// ------------------------------------------------------------------------------------------------
// Visualizacao, Alteracao, Exclusao
User Function VA_RAPA (_nOpcao, _sLinhaOK, _sTudoOK, _lFiltro, _sPreFiltr, _sFilial, _sCliente, _sLoja)
	local _lContinua  := .T.
	local _aCampos    := {}
	local _n		  := 1
	local aButtons 	  := {}
	private _sModo    := ""
	private aHeader   := {}
	private aCols     := {}
	private nOpc      := _nOpcao
	private N		  := 1

	DbSelectArea("ZBG")
	ZBG -> (dbsetorder(1))
	
	If _lContinua	
		CursorWait ()
		_sSeek    := _sFilial +_sCliente + _sLoja
		_sWhile   := "ZBG->ZBG_CLI == '"+_sCliente +"' .AND. ZBG->ZBG_LOJA == '" + _sLoja + "'"
		
        // DEFINE CAMPOS
        _aCampos    := {}
        aadd (_aCampos, "ZBG_FILIAL")
        aadd (_aCampos, "ZBG_CLI")
        aadd (_aCampos, "ZBG_LOJA")
        aadd (_aCampos, "ZBG_TIPO")
        aadd (_aCampos, "ZBG_PERC")
        aadd (_aCampos, "ZBG_OBS")
        aadd (_aCampos, "ZZZ_RECNO") 	    // Adiciona sempre o campo RECNO para posterior uso em gravacoes.
		
		aHeader := U_GeraHead (""		,;  // Arquivo
		                       .F.		,;  // Para MSNewGetDados, informar .T.
		                       {}		,;  // Campos a nao incluir
		                       _aCampos	,;  // Campos a incluir
		                       .T.		 )  // Apenas os campos informados.
		
		aCols := U_GeraCols ("ZBG"		,;  // Alias
		                      1			,;  // Indice
		                      _sSeek	,;  // Seek inicial
		                      _sWhile  	,;  // While
		                      aHeader	,;  // aHeader
		                      .F.		)   // Nao executa gatilhos

		// Variaveis para o Modelo2
		sTitulo := "Percentual de Contratos"
		aC   	:= {}
		aR   	:= {}
		aCGD 	:= {80,   5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		aCJN 	:= {100, 50, oMainWnd:nClientHeight - 50     , oMainWnd:nClientWidth - 50}
		aButtons:= {}

		_lContinua = Modelo2 (sTitulo	,;  // Titulo
		                 aC				,;  // Cabecalho
		                 aR				,;  // Rodape
		                 aCGD			,;  // Coordenadas da getdados
		                 nOpc			,;  // nOPC
		                 "U_VA_RAPLOK()",;  // Linha OK
		                 "U_VA_RAPTOK()",;  // Tudo OK
										,;  // Gets editaveis
										,;  // bloco codigo para tecla F4
										,;  // Campos inicializados
						 9999			,;  // Numero maximo de linhas
		                 aCJN			,;  // Coordenadas da janela
		                 .T.			,;  // Linhas podem ser deletadas.
		                 .F.			,;  // Se a tela virá Maximizada
		                 aButtons  		 )  // Array com botoes

		If _lContinua
			If nOpc == 5 
				// caso necessite
			Else		
				// Grava dados do aCols.
				ZBG -> (dbsetorder(1))
				_aCposFora := {}
				
				For _n = 1 to len (aCols)
					N := _n

					// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
					If GDFieldGet("ZZZ_RECNO") > 0
						ZBG -> (dbgoto(GDFieldGet("ZZZ_RECNO")))
						//		
						// Se esta deletado em aCols, preciso excluir do arquivo tambem.
						If GDDeleted()
                            reclock("ZBG", .F.)
                                ZBG -> (dbdelete())
                            msunlock("ZBG")						
						Else							
							reclock("ZBG", .F.)
							    U_GrvACols("ZBG", N, _aCposFora)
							msunlock("ZBG")
						EndIf
		
					Else  // A linha ainda nao existe no arquivo
						If GDDeleted ()

						Else	
							reclock("ZBG", .T.)
							    U_GrvACols("ZBG", N, _aCposFora)
							msunlock("ZBG")
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	Endif

	ZBG -> (dbgotop())
Return
