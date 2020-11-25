#include 'totvs.ch'

// Programa...: ZZS
// Autor......: Robert Koch
// Data.......: 04/10/2013
// Descricao..: Manutencao de arquivos de pedidos de venda recebidos pelo EDI

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Importa o conteudo dos arquivos de EDI da Neogrid (pedidos de clientes) e chama seu processamento.
// #PalavasChave      #EDI #faturamento #pedidos #Neogrid
// #TabelasPrincipais #ZZS
// #Modulos           #FAT

// Historico de alteracoes:
// 24/11/2020 - Robert - Adicionado um item no aRotina para nao dar erro no AXDeleta().
//                     - Inseridas tags para catalogo de fontes.
//

// --------------------------------------------------------------------------
User Function ZZS()
	local _aCores     := U_ZZSLG (.T.)
	Private aRotina   := {}
	private cCadastro := "Pedidos de Venda EDI"
	private _sArqLog := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
	
	aadd (aRotina, {"&Pesquisar",   "AxPesqui", 0, 1})
	aadd (aRotina, {"&Visualizar",  "AxVisual", 0, 2})
	aadd (aRotina, {"Reprocessa",   "U_ZZSR (.F.)",   0, 2})
	aadd (aRotina, {"&Em_desuso",	"allwaystrue()", 0, 4})  // Apenas para ter mais um elemento no aRotina.
	aadd (aRotina, {"&Excluir",		"U_ZZSX", 0, 5})
	Private cDelFunc := ".T."
	Private cString  := "ZZS"
	dbSelectArea(cString)
	dbSetOrder(1)
	mBrowse(,,,,cString,,,,,2, _aCores)
Return


// --------------------------------------------------------------------------
// Reprocessa arquivo do EDI para incluir pedido de venda
user function ZZSR (_lAuto)
    local _sArqTXT   := ""
    local _sDados    := ""
    local _lContinua := .T.
	local nHdl       := 0

	if ! empty (zzs -> zzs_numped)
		u_help ("Pedido ja´ gerado no sistema",, .t.)
		_lContinua = .F.
	endif
	if _lContinua
		CursorWait ()
		
		// chama função para reprocessar o arquivo EDI
		do case
		case zzs -> zzs_origem == "M"
			_sDados = MSMM (ZZS->ZZS_MEMARQ,,,,3)
			_sArqTXT := "\mercador\ped\" + alltrim(ZZS->ZZS_NOMARQ)
			nHdl = fCreate(_sArqTXT)
			FT_FUSE(_sArqTXT)	 
			fwrite(nHdl,_sDados,Len(_sDados)) 
			fClose(nHdl)
			FT_FUSE()
			U_EDIM1(_lAuto, _sArqTxt, zzs -> (recno ()))
		otherwise
			u_help ("Sem tratamento para esta origem de dados",, .t.)
		endcase
		CursorArrow ()
	endif
return

// --------------------------------------------------------------------------
// Exclusao.
user function ZZSX () 

	local _lContinua := .T.
	local _sCodmemo  := ZZS->ZZS_MEMARQ

	if _lContinua   
		RegToMemory ("ZZS",.F.,.F.)
		if AxDeleta ("ZZS",ZZS->(recno()),5) == 2
			// Exclui campo memo.
			if !empty(_sCodMemo)
				CursorWait()
				msmm(_sCodMemo,,,, 2,,, "ZZS", "ZZS_MEMARQ")
				Cursorarrow()
			endif
		endif
	endif
return

// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function ZZSLG (_lRetCores)
	local _aCores   := {}
	local _aCores2  := {}
	local _i		:= 0
	aadd (_aCores, {"ZZS->ZZS_NUMPED =  ' '", 'BR_VERMELHO', 'Pedido Nao Importado'})
	aadd (_aCores, {"ZZS->ZZS_NUMPED <> ' '", 'BR_VERDE',    'Pedido Importado'})

	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
