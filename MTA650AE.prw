// Programa...: MTA650AE
// Autor......: Robert Koch
// Data.......: 17/11/2017
// Descricao..: P.E. apos a exclusao da ordem de producao. 
//			    Usado inicialmente para excluir etiquetas da OP. 
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------
user function MTA650AE ()
	local _aAreaAnt := U_ML_SRArea ()

	processa ({|| _ExclEtq ()}, 'Excluindo etiquetas')
	
	U_ML_SRArea (_aAreaAnt)
return



// ------------------------------------------------------------------------------------
static function _ExclEtq ()
	procregua (1000)
	za1 -> (dbsetorder (2))  // ZA1_FILIAL+ZA1_OP
	//u_log ('>>' + xfilial ("ZA1") + alltrim (paramixb [1]) + '<<')
	za1 -> (dbseek (xfilial ("ZA1") + alltrim (paramixb [1]), .T.))
	//u_log (za1 -> (found ()))
	do while ! za1 -> (eof ()) .and. alltrim (za1 -> za1_op) == alltrim (paramixb [1])
		incproc ()
//		u_log ('tentando excluir etiq', za1 -> za1_codigo, 'da op', za1 -> za1_op)
		U_EtqPlltE (.F.)
		za1 -> (dbskip ())
	enddo
return
