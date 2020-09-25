// Programa...: TemNick
// Autor......: Robert Koch
// Data.......: 03/09/2008
// Cliente....: Alianca
// Descricao..: Verifica a existencia de indice com o NickName informado.
//              A funcao dbOrderNickName() nao faz a verificacao e derruba a sessao.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function TemNick (_sArq, _sNick)
	local _lTemNick  := .F.
	six -> (dbseek (_sArq, .T.))
	do while ! six -> (eof ()) .and. six -> indice == _sArq
		if upper (alltrim (six -> NickName)) == upper (alltrim (_sNick))
			_lTemNick = .T.
			exit
		endif
		six -> (dbskip ())
	enddo
return _lTemNick
