// Programa.: ALTCLI
// Autor....: Andre Alves
// Data.....: Março 2019
// Descricao: Altera tabela de clientes.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Altera tabela de clientes.
// #PalavasChave      #tabela_de_preço #tabela_de_clientes 
// #TabelasPrincipais #SA1 
// #Modulos           #FAT
//
// Historico de alteracoes:
// 20/03/2019 - Andre  - Criado para alterar tabelas dos clientes conforme necessidade.
// 25/03/2019 - Andre  - criado filtro por estado
// 08/04/2019 - Catia  - include TbiConn.ch 
//
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function ALTCLI (_lAutomat)
	Local cCadastro   := "Arquivo p/ alteração de tabela"
	Local aSays       := {}
	Local aButtons    := {}
	Local nOpca       := 0
	Local lPerg       := .F.
	private _lAuto    := iif (_lAutomat == NIL, .F., _lAutomat)
	private _sGranel  := ""
	private _sSOper   := ""

	U_LogId ()

	Private cPerg   := "ALTCLI"
	_ValidPerg ()
	Pergunte (cPerg, .F.)

	AADD (aSays, "Este Programa Tem Como Objetivo Alterar a tabela de preço")
	AADD (aSays, "dos clientes.")

	AADD (aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
	AADD (aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
	AADD (aButtons, { 2,.T.,{|| FechaBatch() }} )

	if _lAuto
		Processa( { |lEnd| GeraTxt() } )
	else
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| GeraTxt() } )
		Endif
	endif
return
//
// --------------------------------------------------------------------------
// Gera arquivo txt
Static Function GeraTxt()
	private _aProdutos := {}
	private _aMarcas   := {}
	private _sErros    := ""
	private _sAvisos   := ""
	private _aTotOper  := {}
	private _nHdl      := 0

	SA1 -> (dbgotop ())
	_sVend = MV_PAR01
	_sUF   = MV_PAR02
	_Tab1  = MV_PAR03
	_Tab2  = MV_PAR04
	
	DA0 -> (dbsetorder (1))
	if .not. DA0 -> (dbseek (xFilial('DA0') + _Tab2, .F.))
		u_help ( 'Tabela' + _Tab2 + 'nao cadastrada.')
	else 
		do while ! SA1 -> (eof ())
		u_log (SA1 -> A1_COD)
			if SA1 -> A1_VEND = _sVend .and. SA1 -> A1_EST = _sUF .and. SA1 -> A1_TABELA = _Tab1 .and. SA1 -> A1_MSBLQL = '2'
				u_log ('Vou atualizar Vendedor', SA1 -> A1_vend)

				reclock ('SA1', .F.)
					SA1 -> A1_TABELA = _Tab2
				msunlock ()
				_oEvento := ClsEvent():new ()
				_oEvento:Cliente = SA1 -> a1_cod
				_oEvento:LojaCli = SA1 -> a1_loja
				_oEvento:AltCadast ("SA1", SA1 -> a1_cod + SA1 -> a1_loja, sa1 -> (recno ()))
				U_AtuMerc ('SA1',sa1 -> (recno()))
			endif
			SA1 -> (dbskip ())
		enddo
	endif
return
//	
// --------------------------------------------------------------------------
// Valida o TudoOk do Processamento
Static Function _TudoOk()
	Local _aArea    := GetArea()
	Local _lRet     := .T.
	RestArea(_aArea)
Return (_lRet)
//	
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

//                         PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                                  Help
	aadd (_aRegsPerg, {01, "Vendedor                      ", "C", 6,  0,  "",   "SA3  ", {},    ""})
	aadd (_aRegsPerg, {02, "Estado                        ", "C", 2,  0,  "",   "SA3  ", {},    ""})
	aadd (_aRegsPerg, {03, "Tabela original               ", "C", 3,  0,  "",   "DA0  ", {},    ""})
	aadd (_aRegsPerg, {04, "Tabela destino                ", "C", 3,  0,  "",   "DA0  ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg)
Return
