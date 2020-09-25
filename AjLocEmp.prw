// Programa...: AjLocEmp
// Autor......: Robert Koch (royatlies para Leandro Perondi - DWT. Migrado do MTAgrSD4.prw de 02/07/2014)
// Data.......: 11/05/2017
// Descricao..: Ajusta local dos empenhos das OPs
//
// Historico de alteracoes:
//
// 08/04/2019 - Catia - include TbiConn.ch 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function AjLocEmp (_sLocal)
	local _aAreaAnt := U_ML_SRArea ()
	local _aVetor := {}

//	u_logIni ()
//	u_log ('OP', sd4 -> d4_op, ': empenho do', sd4 -> d4_cod, 'vai ser mudado do alm', sd4 -> d4_local, 'para', _sLocal)
	
	// Cria armazem caso ainda não existir.
	sb2 -> (DbSetOrder(1))
	If ! sb2 -> (dbSeek(xfilial("SB2") + SD4->D4_COD + _sLocal, .F.))
		CriaSB2(SD4->D4_COD,_sLocal)
	endif
		
	private lMsErroAuto := .F.
	private _sErroAuto := ""
	_aVetor := {{"D4_COD"  	 , SD4->D4_COD, Nil},;
				{"D4_OP"     , SD4->D4_OP,  Nil},;
				{"D4_SEQ"    , SD4->D4_SEQ, Nil},;
				{"D4_LOCAL"  , _sLocal,     Nil}}
	_aVetor = aclone (U_OrdAuto (_aVetor))
	//u_log (_aVetor)
	MSExecAuto ({|_x, _y| mata380 (_x, _y)}, _aVetor, 4)  // alteracao
	If lMsErroAuto
		u_log (U_LeErro (memoread (NomeAutoLog ())))
		MostraErro()
	Endif		

	U_ML_SRArea (_aAreaAnt)
//	u_logFim ()
return
