// Programa  : MNTNG
// Autor     : Andre Alves
// Data      : 18/06/2019
// Descricao : PE para validações especificas do aplicativo MNT NG	
//
// Historico de alteracoes:
// 21/06/2019 - Andre  - Adicionado validação de datas retroativas.
// 07/04/2021 - Robert - Faltava declaracao variavel _oObjMnt (GLPI 9774)
// 09/03/2022 - Robert - Instanciava objeto oWS sempre, mas parece que paramixb[2] muda conforme o caso.
// 16/03/2022 - Robert - Filtro busca produtos mudado de tipo MM para MM e MC (GLPI 11296)
// 08/04/2022 - Robert - Criado filtro de OS conforme usuario (cada manutentor visualiza apenas as suas OS) - GLPI 11886

//  ---------------------------------------------------------------------------------------------------------------------

// https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878
#include "PROTHEUS.ch"
User Function MNTNG()
	Local _sIDdLocal := ''
//	Local oWS := ''
	local _oObjMnt   := NIL
	local _sRet      := ''
	local _sCodFunc  := ''
	private _sArqLog := 'U_MNTNG.log'  // Quero usar o mesmo arquivo de log para todos os usuarios.

	_sIDdLocal := PARAMIXB[1] //Indica o momento da chamada do PE
//	U_Log2 ('debug', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal))

	If _sIDdLocal == "CANCEL_VALID" //valida cancelamento da ordem
//		oWS := PARAMIXB[2] //Objeto com referência ao webservice
//		If FWJsonDeserialize(oWS:GetContent(),@_oObjMnt) //Parse da string no formato Json
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(),@_oObjMnt) //Parse da string no formato Json
			If Empty(_oObjMnt:message )//verifica campo observação foi passado vazio
				Return "A observação do cancelamento é obrigatória."
			EndIf
		else
			U_Log2 ('erro', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal) + ': Nao foi possivel desserializar objeto.')
		EndIf

	ElseIf _sIDdLocal == "FINISH_VALID_ORDER"
//		oWS := PARAMIXB[2] //Objeto com referência ao webservice
//		If FWJsonDeserialize(oWS:GetContent(), @_oObjMnt)
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(), @_oObjMnt)
			If Empty(_oObjMnt:observation ) //verifica campo observação foi passado vazio
				Return "Campo observação deve ser informado."
			EndIf
			if STOD(substr(_oObjMnt:startDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:startDate, 1, 8)) > date () 
				Return "Data inicial nao pode ser menor do que data de hoje."
			endif
			if STOD(substr(_oObjMnt:endDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:endDate, 1, 8)) > date ()
				Return "Data final nao pode ser menor do que data de hoje."
			endif
		else
			U_Log2 ('erro', '[' + procname () + ']_sIDdLocal:' + cvaltochar (_sIDdLocal) + ': Nao foi possivel desserializar objeto.')
		EndIf
		
	ElseIf _sIDdLocal == "FILTER_PRODUCT" //adiciona filtro para busca de produtos
		//Return  "AND B1_TIPO = 'MM'" 
		Return  "AND B1_TIPO IN ('MM','MC')" 
	
	ElseIf _sIDdLocal == "FILTER_ORDER" // Filtro para ordens de servico
		U_Log2 ('debug', '[' + procname () + ']filtrando OS')
//		U_Log2 ('debug', '[' + procname () + ']cUserName: >>' + cUserName + '<<')

		// Define o codigo de funcionario (campo T1_CODFUNC) para que o usuario receba somente as OS designadas para ele.
		// Siiiim, eu sei que chumbar os nomes no fonte é deselegante, mas ainda nao tenho uma forma melhor de descobrir o codigo do funcionario.
		_sCodFunc = ''
		do case
		case alltrim (upper (cUserName)) $ 'EVALDO.AGNOLETO/LEONARDO.BORGES/APP.MNTNG/ELSO.RODRIGUES/MARCOS.OLIVEIRA/JONATHAN.SANTOS'
			_sCodFunc = ''  // Sem filtro para estes usuarios.
		case alltrim (upper (cUserName)) = 'ELIEL.PEDRON'    ; _sCodFunc = '2119'
		// segundo turno --> case alltrim (upper (cUserName)) = 'ELSO.RODRIGUES'  ; _sCodFunc = '2413'
		case alltrim (upper (cUserName)) = 'FABRICIO.GOMES'  ; _sCodFunc = '2010'
		case alltrim (upper (cUserName)) = 'FLAVIO.ALVES'    ; _sCodFunc = '2202'
		// segundo turno --> case alltrim (upper (cUserName)) = 'JONATHAN.SANTOS' ; _sCodFunc = '2419'
		case alltrim (upper (cUserName)) = 'MARCOS.CORSO'    ; _sCodFunc = '1648'
		// segundo turno --> case alltrim (upper (cUserName)) = 'MARCOS.OLIVEIRA' ; _sCodFunc = '2012'
		case alltrim (upper (cUserName)) = 'MARLON.SENE'     ; _sCodFunc = '2322'
		case alltrim (upper (cUserName)) = 'TAILOR.BACCA'    ; _sCodFunc = '2369'
		otherwise
			U_Log2 ('aviso', '[' + procname () + "]Usuario '" + cUserName + "' sem tratamento para filtrar OS.")
		endcase
		if ! empty (_sCodFunc)
			_sRet := ""
			_sRet += "AND EXISTS ("
			_sRet +=     "SELECT * FROM " + RetSQLName ("STL")
			_sRet +=     " WHERE D_E_L_E_T_ = ''"
			_sRet +=       " AND TL_FILIAL  = TJ_FILIAL"
			_sRet +=       " AND TL_ORDEM   = TJ_ORDEM"
			_sRet +=       " AND TL_CODIGO  = '" + _sCodFunc + "')"
			U_Log2 ('debug', '[' + procname () + ']' + _sRet)
			return _sRet
		else
			return ''
		endif
		// robert = &('quero_que_de_erro')
	EndIf

Return
