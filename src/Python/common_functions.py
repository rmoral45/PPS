def list_to_hex(hex_list):
	"""Genera un numero a partir de una lista.
	
	Args:
		hex_list: lista de enteros de 8 bits
	Comentarios:
		Concatena los elementos de una lista de octetos para formar un unico numero equivalente,
		el numero resutante tiene al octeto de la posicion 0 de la lista
		como sus bits mas significativos
	"""
	result = 0x000000000
	counter = ( len(hex_list)-1 )
	for value in hex_list:
		result |= (value << (counter*8))
		counter-=1
	#return hex(result).rstrip('L')
	return result

def block_to_hex(block,block_format = 'list'):
	"""Genera un numero a partir de los valores en un diccionario.
	
	Args:
		block : bloque de datos
		block_format: indica de que forma esta representado el bloque de datos
			'list' : es una lista de octetos [D0,D1......D7], se concatenan todos los bytes de la lista 
			'encoder' : es un diccionario como el que utilizamos como salida del encoder{
				en este caso NO se concatena el sh																		'sh' (2bits)          : value
																						'block_type'(8 bits)  : value
																						'payload'(56 bits)    : value	 
																			   			}
			'scrambled' : es un diccionario como el de salida del scrambler :			{
				en este caso SI se cooncatena el sh																		 'sh' (2 bits)        : value
																						 'payload'(64 bits)	  : value
	
																						}																			   			
	Concatena los elementos de un bloque para formar un unico numero equivalente,
	con la forma {sh, block_type, payload}.
	"""
	if block_format == 'list' :
		hexnum = list_to_hex(block)

	elif block_format == 'encoder' :	
		hex_list = []
		hex_list.append(block['block_type'])
		hex_list+= block['payload']
		hexnum = list_to_hex(hex_list)
		
	elif block_format == 'scrambled' :
		hexnum = 0x000000000
		hexnum |= ( block['sh'] << 64)
		hexnum |= block['payload']
	
	return hexnum

	
def reverse_byte(num):
	"""Invierte el orden de los bits de un numero
	
	Ejemplo:
		param: num = 225 = 0xE1 = 0b11100001 ; return: 135 = 0x87 = 0b10000111
	Comentario:
		esta funcion en necesaria por la manera en que el estandar define la  transmision de datos		
	"""
	binary = bin(num) 
	reverse = binary[-1:1:-1] 
	return int(reverse,2)		