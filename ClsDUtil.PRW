// Programa:  ClsDUtil
// Autor:     Robert Koch
// Data:      27/07/2009
// Cliente:   Alianca
// Descricao: Declaracao de classe de utilitarios para trabalhar com datas, para uso em outros programas.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// /H/storico de alteracoes:
// 18/06/2010 - Robert - Acrescentado metodo SomaDiaUt.
// 25/06/2010 - Robert - Acrescentado metodo PerIndComl.
// 01/07/2011 - Robert - Acrescentado metodo Aniver.
// 14/05/2012 - Robert - Acrescentado metodo DifDatas (por enquanto, apenas calculos de anos).
// 06/07/2015 - Robert - Metodo DifDatas() descontinuado.
//                     - Criado metodo DifMeses().
// 11/09/2020 - Robert - Testes para uso de metodos estaticos (aguarda atualizar build)
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsDUtil ()
return


// ==========================================================================
CLASS ClsDUtil

	// Declaração dos Métodos da Classe
	/*public */METHOD New ()
	/*public */METHOD Aniver ()
	/*public */METHOD DifMeses ()
	/*public */METHOD PerIndComl ()
	/*public */METHOD SomaDiaUt ()
	/*public */METHOD SomaMes ()
	/*static */METHOD SubtrMes ()
	/*public */METHOD Semanas ()
ENDCLASS


// --------------------------------------------------------------------------
METHOD New () Class ClsDUtil
Return Self

                                                       	

// --------------------------------------------------------------------------
// Retorna a data em que se completam X anos, considerando anos bissextos.
method Aniver (_dNasc, _nQtAnos) class ClsDUtil
	local _sDia    := strzero (day (_dNasc), 2)
	local _sMes    := left (dtos (_dNasc), 6)
	local _k       := 0
	local _dUltimo := ctod ("")
	local _dRet    := ctod ("")

	// Soma os anos de 12 em 12 meses para nao ocorrer estouro de pilha.
	for _k = 1 to _nQtAnos
		_sMes = self:SomaMes (_sMes, 12)
	next
	
	// Teste p/ ano bissexto
	_dUltimo = lastday (stod (_sMes + "01"))
	if dtos (_dUltimo) < _sMes + _sDia
		_dRet = _dUltimo
	else
		_dRet = stod (_sMes + _sDia)
	endif
return _dRet


/* Metodo descontinuado.
// --------------------------------------------------------------------------
// Retorna array com a diferenca entre a data inicial e final:
// Pos.1 = diferenca em anos
// Pos.2 = diferenca em meses
// Pos.3 = diferenca em dias
method DifDatas (_dDataIni, _dDataFim) class ClsDUtil
	local _dAnos := 0
//	u_logIni ()

	// Calcula a diferenca em anos
	_dAnos = year (_dDataFim) - year (_dDataIni)
	if month (_dDataFim) < month (_dDataIni)
		_dAnos --
	endif

	// Calcula a diferenca em meses
	// COMO AINDA NAO PRECISEI DESTA PARTE, NEM VOU TERMINAR DE FAZER
//	u_log (_dAnos)
//	u_logFim ()
return {_dAnos} //, _dMeses, _dDataFim - _dDataIni}
*/


// --------------------------------------------------------------------------
// Diferenca em meses (completos).
method DifMeses (_dDataIni, _dDataFim) Class ClsDUtil
	local _nMeses := 0
	local _nAnos  := 0
//	u_log (procname (), 'entre', _dDataIni, 'e', _dDataFim)

	if ! empty (_dDataIni) .and. !empty (_dDataFim)
		if _dDataIni > _dDataFim
	//		u_log ('Fim < ini')
			return ::DifMeses (_dDataFim, _dDataIni)
		else
			if year (_dDataIni) == year (_dDataFim)
				_nMeses = month (_dDataFim) - month (_dDataIni)
				
				// Se forem datas de inicio e final de mes, tenho mais um mes completo.
				if _dDataIni == firstday (_dDataIni) .and. _dDataFim == lastday (_dDataFim)
	//				u_log ('meses cheios: tenho mais 1 mes')
					_nMeses ++
				endif
				if _nMeses > 0 .and. day (_dDataIni) > day (_dDataFim)
	//				u_log ('dia inicial > final')
					_nMeses --
				endif
			else
	//			u_log ('Anos diferentes')
				// Datas em anos diferentes: Calcula em partes:
				// (+) Quantidade de anos cheios, desconsiderando os anos das datas inicial e final
				// (+) Diferenca em meses entre a data inicial e o final do ano da data inicial
				// (+) Diferenca em meses entre o inicio do ano da data final e a data final
				_nAnos = 1 + (year (_dDataFim) - 1) - (year (_dDataIni) + 1)
	//			u_log ('anos cheios: dif. entre ', (year (_dDataFim) - 1) ,'e', (year (_dDataIni) + 1), ':', _nAnos)
				return _nAnos * 12 + ::DifMeses (_dDataIni, stod (strzero (year (_dDataIni), 4) + '1231')) + ::DifMeses (stod (strzero (year (_dDataFim), 4) + '0101'), _dDataFim)
			endif 
		endif
	endif
//	u_log ('Diferenca em meses entre', _dDataIni, 'e', _dDataFim, ':', _nMeses, 'meses ', 'dFim-dIni:', _dDataFim - _dDataIni)
//	u_logFim ()
return _nMeses



// --------------------------------------------------------------------------
// Monta arrays com os periodos a serem comparados em indicadores comerciais.
// Serao sempre 3 periodos correspondentes nos ultimos 3 anos.
// Serao considerados sempre periodos completos, ou seja: anos cheios,
// trimestres cheios, meses cheios.
method PerIndComl () Class ClsDUtil
	local _sAno1     := strzero (year (date ()) - 3, 4)
	local _sAno2     := strzero (year (date ()) - 2, 4)
	local _sAno3     := strzero (year (date ()) - 1, 4)  // O ano atual nunca estah completo
	local _sAno0     := strzero (year (date ())    , 4)  // Ano atual
	local _aAnos     := {}
	local _aTrim     := {}
	local _aMeses    := {}
	local _sMes      := ""
	local _aPeriodos := {}

	aadd (_aAnos, {_sAno1, _sAno1 + "01", _sAno1 + "12"})
	aadd (_aAnos, {_sAno2, _sAno2 + "01", _sAno2 + "12"})
	aadd (_aAnos, {_sAno3, _sAno3 + "01", _sAno3 + "12"})

	if month (date ()) >= 10
		aadd (_aTrim, {"Jul-set/" + _sAno2, _sAno2 + "07", _sAno2 + "09"})
		aadd (_aTrim, {"Jul-set/" + _sAno3, _sAno3 + "07", _sAno3 + "09"})
		aadd (_aTrim, {"Jul-set/" + _sAno0, _sAno0 + "07", _sAno0 + "09"})
	elseif month (date ()) >= 7
		aadd (_aTrim, {"Abr-jun/" + _sAno2, _sAno2 + "04", _sAno2 + "06"})
		aadd (_aTrim, {"Abr-jun/" + _sAno3, _sAno3 + "04", _sAno3 + "06"})
		aadd (_aTrim, {"Abr-jun/" + _sAno0, _sAno0 + "04", _sAno0 + "06"})
	elseif month (date ()) >= 4
		aadd (_aTrim, {"Jan-mar/" + _sAno2, _sAno2 + "01", _sAno2 + "03"})
		aadd (_aTrim, {"Jan-mar/" + _sAno3, _sAno3 + "01", _sAno3 + "03"})
		aadd (_aTrim, {"Jan-mar/" + _sAno0, _sAno0 + "01", _sAno0 + "03"})
	else
		aadd (_aTrim, {"Out-dez/" + _sAno1, _sAno1 + "10", _sAno1 + "12"})
		aadd (_aTrim, {"Out-dez/" + _sAno2, _sAno2 + "10", _sAno2 + "12"})
		aadd (_aTrim, {"Out-dez/" + _sAno3, _sAno3 + "10", _sAno3 + "12"})
	endif

	if month (date ()) >= 2
		_sMes = strzero (month (date ()) - 1, 2)
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno2, _sAno2 + _sMes, _sAno2 + _sMes})
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno3, _sAno3 + _sMes, _sAno3 + _sMes})
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno0, _sAno0 + _sMes, _sAno0 + _sMes})
	else
		_sMes = "12"
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno1, _sAno1 + _sMes, _sAno1 + _sMes})
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno2, _sAno2 + _sMes, _sAno2 + _sMes})
		aadd (_aMeses, {left (MesExtenso (val (_sMes)), 3) + "/" + _sAno3, _sAno3 + _sMes, _sAno3 + _sMes})
	endif

	_aPeriodos = {}
	aadd (_aPeriodos, {"Comparativo anual", aclone (_aAnos)})
	aadd (_aPeriodos, {"Comparativo trimestral", aclone (_aTrim)})
	aadd (_aPeriodos, {"Comparativo mensal", aclone (_aMeses)})
return _aPeriodos



// --------------------------------------------------------------------------
// Acrescenta `a data informada o numero de dias uteis informados. Se for
// informado um numero negativo de dias, calcula retroativamente.
// Autor: Robert Koch - Microsiga Caxias - 25/06/2003
method SomaDiaUt (_dDataIni, _nDias) Class ClsDUtil
   local _i         := 0
   local _dNovaData := _dDataIni
//   local _dDataAux  := ctod ("")
   if valtype (_nDias) != "N" .or. valtype (_dDataIni) != "D"
      msgalert ("Metodo SomaDiaUt recebeu parametro(s) invalido(s)")
      return NIL
   endif
   for _i = 1 to abs (_nDias)
      if _nDias > 0  // Somar dias
         _dNovaData = datavalida (_dNovaData + 1)
      else  // Subtrair dias
         _dNovaData --
         do while datavalida (_dNovaData) != _dNovaData
            _dNovaData --
         enddo
      endif
   next
return _dNovaData



// --------------------------------------------------------------------------
// Recebe uma string no formato AAAAMM (apenas ano e mes) e soma meses.
// Autor: Robert Koch - 18/02/2002
// Historico de alteracoes:
// 13/06/2005 - Robert - Aceita qt. de meses a somar (antes era apenas 1)
METHOD SomaMes (_sMes, _nQtMeses) Class ClsDUtil
	local _sNovoMes := ""
	_nQtMeses := iif (_nQtMeses == NIL, 1, _nQtMeses)
	if _nQtMeses < 0
		_sNovoMes = ::SubtrMes (_sMes, _nQtMeses * -1)
	else
		if substr (_sMes, 5, 2) == "12"
			_sNovoMes = strzero (val (substr (_sMes, 1, 4)) + 1, 4) + "01"
		else
			_sNovoMes = substr (_sMes, 1, 4) + strzero (val (substr (_sMes, 5, 2)) + 1, 2)
		endif
		if _nQtMeses != 1  // Chamada recursiva.
			_sNovoMes = ::SomaMes (_sNovoMes, _nQtMeses - 1)
		endif
	endif
return _sNovoMes


/* Nem terminei...
// --------------------------------------------------------------------------
// Acrescenta `a data e hora informadas o numero de segundos informados. Se for
// informado um numero negativo de segundos, calcula retroativamente.
// Autor: Robert Koch - 25/02/2019
method SomaSegund (_sDHIni, _nSegundos) Class ClsDUtil
	local _sDHNova := _sDHIni
	local _dDia    := stod (substring (_sDHIni, 1, 8))
	local _nHora   := val (substring (_sDHIni, 10, 2))
	local _nMin    := val (substring (_sDHIni, 13, 2))
	local _nSeg    := val (substring (_sDHIni, 16, 2))

	u_logIni (GetClassName (::Self) + '.' + procname ())
	u_log ('Somando', _nSegundos, 'a', _sDHIni)
	u_log (_nHora, _nMin, _nSeg)
	if _nSegundos > 0
		u_help ('Sem tratamento para segundos positivos por enquanto')
	else_nSegundos < 0
		if _nSegundos <= -60
			_nMin --
			
		else
		endif
	endif
	u_logFim (GetClassName (::Self) + '.' + procname ())
return _sDHNova
*/


// --------------------------------------------------------------------------
// Recebe uma string no formato AAAAMM (apenas ano e mes) e subtrai um mes,
// devolvendo o resultado.
// Autor: Robert Koch - 18/02/2002
METHOD SubtrMes (_sMes, _nQtMeses) Class ClsDUtil
	local _sNovoMes := ""
//	local _oDUtil   := NIL
	_nQtMeses := iif (_nQtMeses == NIL, 1, _nQtMeses)
	if _nQtMeses < 0
		
		/* aguarda atualizar build na base quente
		// Estou num metodo estatico tentando executar um nao estatico. Para isso preciso instanciar antes um objeto.
		// Quando o metodo SomaMes tambem for estatico, provavelmente vou apenas executar assim: ClsDUtil ():SomaMes (....)
		// Ainda nao migrei ele tambem por que quero acompanhar por um tempo. Robert, 11/09/2020
		_oDUtil := ClsDUtil ():New ()
		_sNovoMes = _oDUtil:SomaMes (_sMes, _nQtMeses * -1)
		*/
		_sNovoMes = ::SomaMes (_sMes, _nQtMeses * -1)
	else
		if substr (_sMes, 5, 2) == "01"
			_sNovoMes = strzero (val (substr (_sMes, 1, 4)) - 1, 4) + "12"
		else
			_sNovoMes = substr (_sMes, 1, 4) + strzero (val (substr (_sMes, 5, 2)) - 1, 2)
		endif
		if _nQtMeses != 1  // Chamada recursiva.
			/* aguarda atualizar build na base quente
			_sNovoMes = ClsDUtil ():SubtrMes (_sNovoMes, _nQtMeses - 1)
			*/
			_sNovoMes = ::SubtrMes (_sNovoMes, _nQtMeses - 1)
		endif
	endif
return _sNovoMes



// Retorna uma array de semanas entre as datas passadas como parametro, no
// formato: {{dInicio, dFim}, {dInicio, dFim}, ...} sendo que a data inicial
// da primeira semana e a data final da ultima semana sao as datas informadas
// como parametros na chamada, independente de qual dia da semana sejam
// Parametros: - Data inicial a ser considerada
//             - Data final a ser considerada
// Autor: Robert Koch - 08/11/2003
// --------------------------------------------------------------------------
METHOD Semanas (_dDataIni, _dDataFim) Class ClsDUtil
   local _dDia := _dDataIni
   local _aSemanas := {}
   do while _dDia <= _dDataFim
      if dow (_dDia) == 1 .or. len (_aSemanas) == 0
         aadd (_aSemanas, {_dDia, NIL})
      endif
      if dow (_dDia) == 7 .or. _dDia == _dDataFim
         _aSemanas [len (_aSemanas), 2] = _dDia
      endif
      _dDia ++
   enddo
return _aSemanas


