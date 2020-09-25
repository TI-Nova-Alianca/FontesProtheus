// Programa...: SeparaCpo
// Autor......: Robert Koch
// Data.......: 01/06/2002
// Descricao..: Recebe um string com varios campos separados por determinado caractere e
//              devolve os campos em uma array.
//
// Historico de alteracoes:
// 29/01/2003 - Robert - Passa a receber tambem o caracter separador
// 13/07/2005 - Robert - Passa a aceitar caracter separador com tamanho maior do que 1 (CRLF, por exemplo)
// 18/07/2016 - Robert - Testa se foi passado parametro de cadacter separador.
//

// --------------------------------------------------------------------------
// Parametros: _sRegistro = string de dados e separadores
//             _sSeparad  = caracter separador
user function SeparaCpo (_sRegistro, _sSeparad)
   local _aTokens := {}

   if ! empty (_sSeparad)

	   // Enquanto houver dados em _sRegistro...
	   While len (_sRegistro) > 0
	
	      // ...se ainda tem algum separador de campos...
	      if at (_sSeparad, _sRegistro) != 0                                                    		
	
	         // ...pega do inicio de _sRegistro ateh o separador e joga para _aCampos...
	         aadd (_aTokens, substr (_sRegistro, 1, at (_sSeparad, _sRegistro) - 1))
	
	         // ...removendo de _sRegistro o campo lido.
	         _sRegistro = substr (_sRegistro, len (_aTokens [len (_aTokens)]) + len (_sSeparad) + 1)
	
	         // ... se nao tem mais separador de campos em _sRegistro...
	      else
	
	         // .. entao resta apenas o ultimo campo.
	         aadd (_aTokens, alltrim (_sRegistro))
	         _sRegistro = ""
	      endif
	   enddo
   endif
return _aTokens

