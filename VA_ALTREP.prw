// Programa : VA_ALTREP
// Autor    : Cláudia Lionço
// Data     : 22/10/2019
// Descricao: Rotina para atualização de representante e comissão
// GLPI     : 6856
//
// #TipoDePrograma    #Processamento
// #PalavasChave      #clientes #representantes #comissões #comissão #ajuste_de_comissao #comissao
// #TabelasPrincipais #SA1 
// #Modulos 		  #FAT
//
// Historico de alteracoes:
// 29/06/2020 - Cláudia - Incluido parametro para alterar apenas os representantes, sem comissões. GLPI: 8124
// 16/07/2020 - Cláudia - Retirada a obrigatoriedade de incluir comissão. GLPI: 8178
// ---------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_ALTREP ()
	Local cCadastro  := "Clientes x Representante"
	Local aSays      := {}
	Local aButtons   := {}
	Local nOpca      := 0
	Local lPerg      := .F.
	local _nLock     := 0

	If ! u_zzuvl ('092', __cUserId, .T.)
		u_help ("Usuário sem permissão para usar estar rotina")
		Return
	Endif

	// Somente uma estacao por vez, pois a rotina eh pesada e certos usuarios derrubam o client na estacao e mandam rodar novamente...
	_nLock := U_Semaforo (procname ())
	If _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
		Return
	Endif

	Private cPerg   := "VA_ALTREP"
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	AADD(aSays,"Este programa tem como objetivo migrar clientes de representantes ")
	AADD(aSays,"atualizando a comissão conforme parâmetro")
	
	AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
	
	FormBatch( cCadastro, aSays, aButtons )
	
	If nOpca == 1
		Processa( { |lEnd| _AtualizaRep() } )
	Endif

	// Libera semaforo.
	if _nLock > 0
		U_Semaforo (_nLock)
	endif
Return

// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
	
	If empty(mv_par01) // rep origem
		u_help(" Representante de origem é obrigatório!")
		_lRet := .F.
	Endif
	
	If empty(mv_par02) // rep destino
		u_help(" Representante de destino é obrigatório!")
		_lRet := .F.
	Endif
	
//	If empty(mv_par03) .and. mv_par04 == 1// comissão
//		u_help(" Comissão é obrigatório!")
//		_lRet := .F.
//	Endif
Return _lRet

// --------------------------------------------------------------------------
Static Function _AtualizaRep()
	Local cTexto :=""
	
	cTexto := " Deseja atualizar os clientes do representante " + alltrim(mv_par01) + " para o representante " +alltrim(mv_par02) +"?"
	
	If MSGYESNO( cTexto, "Atualização de dados" )
		sa1 -> (dbsetorder (1))
		sa1 -> (dbgotop ())
		//
		do while ! sa1 -> (eof ())
			u_log ('Verificando item', sa1 -> a1_vend)
			if alltrim(sa1 -> a1_vend) == alltrim(mv_par01)
				
				// Cria variaveis para uso na gravacao do evento de alteracao
				regtomemory ("SA1", .F., .F.)
//				If  mv_par04 == 1
					sNewVend  := alltrim(mv_par02)
					sNewComis := mv_par03
	
					// Grava evento de alteracao
					_oEvento := ClsEvent():new ()
					_oEvento:AltCadast ("SA1", sNewComis, sa1 -> (recno ()), '', .F.)
					_oEvento:Texto     = "Vend. de " + alltrim(sa1 -> a1_vend) + " para " + alltrim(sNewVend) + ". Comissão:"+ str(sNewComis)
					_oEvento:Grava()
					
					Reclock ("SA1", .f.)
						sa1 -> a1_vend  = sNewVend
						sa1 -> a1_comis = sNewComis
					Msunlock ()
//				Else
//					sNewVend  := alltrim(mv_par02)
//	
//					// Grava evento de alteracao
//					_oEvento := ClsEvent():new ()
//					_oEvento:AltCadast ("SA1", sNewVend, sa1 -> (recno ()), '', .F.)
//					_oEvento:Texto     = "Vend. de " + alltrim(sa1 -> a1_vend) + " para " + alltrim(sNewVend) 
//					_oEvento:Grava()
//					
//					Reclock ("SA1", .f.)
//						sa1 -> a1_vend  = sNewVend
//					Msunlock ()
//				EndIf
				
				U_AtuMerc ("SA1", sa1 -> (recno ()))
				
				u_log ('Cliente alterado ' + alltrim(sa1 -> a1_cod) + ' para vendedor ' + alltrim(sa1 -> a1_vend) )
				
			else
				u_log ('Nada a alterar')
			endif
			//
			sa1 -> (dbskip ())
		enddo
	EndIf 
Return
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                 TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Representante origem  	", "C", 6, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {02, "Representante destino 	", "C", 6, 0,  "",  "   ", {},                         				""})
    aadd (_aRegsPerg, {03, "Comissão       			", "N", 8, 4,  "",  "   ", {},                         				""})
    //aadd (_aRegsPerg, {04, "Atualiza comissão?     ?", "N", 1, 0,  "",  "   ", {"Sim", "Não"}, 							""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
