// Programa:  LeErro
// Autor:     Robert Koch
// Data:      06/11/2006
// Descricao: Recebe um log de erro de rotina automatica e extrai apenas o cabecalho
//            e o campo invalido, para uso em relatorios, etc.
//            Devolve tudo em uma string sem quebras de linha.
//
// Historico de alteracoes:
// 04/05/2016 - Robert - Retorna conteudo passado pela funcao U_NoAcento().
//

// --------------------------------------------------------------------------
user function LeErro (_sErro)
  local _sRet := ""
  local _nLinha := 0 

  // Pega o cabecalho do erro
  _nLinha = 2
  do while _nLinha <= mlcount (_sErro) .and. ! empty (memoline (_sErro,, _nLinha))
     _sRet += " " + alltrim (memoline (_sErro,, _nLinha))
     _nLinha ++
  enddo

  // Procura uma linha que contenha indicacao de campo invalido
  do while _nLinha <= mlcount (_sErro)
     if "< -- Invalido" $ memoline (_sErro,, _nLinha)
        _sRet += " " + alltrim (memoline (_sErro,, _nLinha))
        exit
     endif
     _nLinha ++
  enddo

//return _sRet
return U_NoAcento (_sRet)
