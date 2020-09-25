#include "protheus.ch"

// Programa:  M050TOK
// Autor:     Andre Alves
// Data:      12/03/2019
// Descricao: Ponto de entrada utilizado para validar a inclusão e/ou alteração do cadastro de transportadora. 
//            
//            

// Historico de alteracoes:

// --------------------------------------------------------------------------
user function M050TOK()
	local _lRet := .T.
	local _xFim     := chr(13)+chr(10)
		
	if inclui
		_sMsg = "Nova transportadora com codigo " + M->A4_COD + " ,cadastrado com o nome " + M->A4_NOME + " e CNPJ " + M->A4_CGC + " incluida no sistema."+_xFim+"Cadastrado pelo usuario " + M->A4_VAUSER + "."
		U_ZZUNU ({"017"}, "Inclusao de Transportadora", _sMsg, .F., cEmpAnt, cFilAnt)
		//U_SendMail ("andre.alves@novaalianca.coop.br", "Inclusão de Transportadora", _sMsg)
	endif

Return _lRet