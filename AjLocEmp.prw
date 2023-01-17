// Programa...: AjLocEmp
// Autor......: Robert Koch (royatlies para Leandro Perondi - DWT. Migrado do MTAgrSD4.prw de 02/07/2014)
// Data.......: 11/05/2017
// Descricao..: Ajusta local dos empenhos das OPs
//
// Historico de alteracoes:
// 08/04/2019 - Catia  - include TbiConn.ch 
// 16/01/2023 - Robert - Migrado de MATA380 para MATA381 (GLPI 11997)
//

#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
user function AjLocEmp (_sLocal)
	local _aAreaAnt  := U_ML_SRArea ()
	local _lContinua := .T.
//	local _aVetor := {}

	Local _aCab      := {}
	Local _aLinha    := {}
	Local _aItens    := {}

	U_Log2 ('debug', '[' + procname () + ']D4_OP: ' + sd4 -> d4_op + '  empenho do item ' + sd4 -> d4_cod + ' vai ser mudado do alm ' + sd4 -> d4_local + ' para ' + _sLocal)
	if _lContinua
		sb1 -> (DbSetOrder(1))
		if ! sb1 -> (dbSeek(xfilial("SB1") + SD4->D4_COD, .F.))
			U_Log2 ('erro', '[' + procname () + ']SB1 nao localizado!')
			_lContinua = .F.
		endif
	endif

	// Cria armazem caso ainda não existir.
	if _lContinua
		sb2 -> (DbSetOrder(1))
		If ! sb2 -> (dbSeek(xfilial("SB2") + SD4->D4_COD + _sLocal, .F.))
			U_Log2 ('debug', '[' + procname () + ']Vou criar SB2')
			CriaSB2(SD4->D4_COD,_sLocal)
			U_Log2 ('debug', '[' + procname () + ']Criei SB2')
		endif
	endif
/*
	private lMsErroAuto := .F.
	private _sErroAuto := ""
	_aVetor := {{"D4_COD"  	 , SD4->D4_COD, Nil},;
				{"D4_OP"     , SD4->D4_OP,  Nil},;
				{"D4_SEQ"    , SD4->D4_SEQ, Nil},;
				{"D4_LOCAL"  , _sLocal,     Nil}}
	_aVetor = aclone (U_OrdAuto (_aVetor))
	U_Log2 ('debug', '[' + procname () + ']_aVetor:')
	U_Log2 ('debug', _aVetor)
	MSExecAuto ({|_x, _y| mata380 (_x, _y)}, _aVetor, 4)  // alteracao
	U_Log2 ('debug', '[' + procname () + ']Retornou do MATA380')
	If lMsErroAuto
		U_Log2 ('erro', '[' + procname () + ']' + U_LeErro (memoread (NomeAutoLog ())))
		MostraErro()
	Endif
*/

	if _lContinua
		private lMsErroAuto := .F.
		private _sErroAuto := ""

		// A forma de alterar o local do empenho que era usada no MATA380 (alterar
		// simplesmente) nao funciona mais no MATA381, pois esse campo eh chave.
		// Foi necessario excluir a linha original dos empenhos e incluir uma nova.
		//
		// Monta o cabeçalho com o número da OP que será alterada.
		// Necessário utilizar o índice 2 para efetuar a alteração.
		_aCab := {{"D4_OP",sd4 -> d4_op,NIL},{"INDEX",2,Nil}}
	 
		//Adiciona as informações do empenho, conforme estão na tabela SD4.
		_aLinha := {}

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
	         
		// Preciso excluir a linha e incluir uma nova, pois o campo D4_LOCAL eh chave.
		aAdd(_aLinha,{"AUTDELETA","S",Nil})
		U_Log2 ('debug', _aLinha)
	      
		//Adiciona as informações do empenho no array de itens.
		aAdd(_aItens,_aLinha)

		// Insere uma nova linha com o novo almox.
		_aLinha = {}
		aadd (_aLinha, {"D4_FILIAL", sd4 -> d4_filial, NIL})
		aadd (_aLinha, {"D4_OP", sd4 -> d4_op, NIL})
		aadd (_aLinha, {"D4_COD", sd4 -> d4_cod, NIL})
		aadd (_aLinha, {"D4_SEQ", sd4 -> d4_seq, NIL})
		aadd (_aLinha, {"D4_TRT", sd4 -> d4_trt, NIL})
		if sb1 -> b1_rastro == 'L'
			aadd (_aLinha, {"D4_LOTECTL", sd4 -> d4_lotectl, NIL})
		endif
		if sb1 -> b1_rastro == 'S'
			aadd (_aLinha, {"D4_NUMLOTE", sd4 -> d4_numlote, NIL})
		endif
		aadd (_aLinha, {"D4_OPORIG", sd4 -> d4_oporig, NIL})
		aadd (_aLinha, {"D4_QUANT", sd4 -> d4_quant, NIL})
		aadd (_aLinha, {"D4_QTDEORI", sd4 -> d4_qtdeori, NIL})
		aadd (_aLinha, {"D4_LOCAL", _sLocal, NIL})
		U_Log2 ('debug', _aLinha)
		aAdd(_aItens,_aLinha)

		//Executa o MATA381, com a operação de Alteração.
		MSExecAuto({|x,y,z| mata381(x,y,z)},_aCab,_aItens,4)
		If lMsErroAuto
			_lContinua = .F.
			U_Log2 ('erro', '[' + procname () + ']' + U_LeErro (memoread (NomeAutoLog ())))
			MostraErro()
		EndIf
	endif

	U_ML_SRArea (_aAreaAnt)
return _lContinua

