package phm.service

import org.springframework.stereotype.Service
import org.springframework.beans.factory.annotation.Autowired
import phm.repository.PreguntaRepository
import phm.domain.PreguntaDTO
import phm.domain.Pregunta
import java.util.Arrays
import phm.domain.Usuario
import phm.repository.RegistroRespuestasRepository
import phm.domain.UpdatePregunta
import org.springframework.web.server.ResponseStatusException
import org.springframework.http.HttpStatus
import phm.domain.PreguntaSolidaria
import org.springframework.http.ResponseEntity
import org.springframework.validation.annotation.Validated
import javax.validation.Valid
import javax.transaction.Transactional

@Service
@Validated
class PreguntaService {

	@Autowired
	PreguntaRepository repoPregunta	
	
	@Autowired
	UsuarioService usuarioService
	
	@Autowired
	RegistroRespuestasRepository repoRegistro
	
	def getTodasLasPreguntasDTO(){
		return repoPregunta.findAll().toList.map [ PreguntaDTO.fromPregunta(it) ]
	}
	
	def getPreguntasFiltradas(String busqueda, boolean soloActivas){
			
			var Pregunta[] preguntas = repoPregunta.findByPreguntaContaining(busqueda)
			
			if(soloActivas){
				preguntas = preguntas.filter[pregunta | pregunta.estaActiva].toList()				
			}
			
			return preguntas.map [ PreguntaDTO.fromPregunta(it) ]		
	}
	
	def getPreguntaPorId(long idPregunta, long idUsuario){
			var Pregunta pregunta
			try{
				pregunta = repoPregunta.findById(idPregunta).orElse(null)
			}catch (Exception e){
				return new ResponseEntity<String>("Id de pregunta inexistente", HttpStatus.BAD_REQUEST)			
			}
			
			var Usuario usuario = usuarioService.buscarPorId(idUsuario).orElse(null)
			
			pregunta.opciones = Arrays.asList(pregunta.opciones)
			pregunta.autor = usuarioService.buscarPorId(pregunta.autor.id).orElse(null) // ver de que venga todo junto con la pregunta (preg y autor)
			
			if(!usuario.yaRespondio(pregunta.pregunta)){
				pregunta
			}else{
				return new ResponseEntity<String>("No se puede acceder a la pregunta dado que ya la respondió anteriormente", HttpStatus.UNAUTHORIZED)					
			}
		
	}
	
	def verificarRespuesta(String laRespuesta, long idPregunta, long idUsuario){
			

			var pregunta = repoPregunta.findById(idPregunta).get()
			var Usuario usuario = usuarioService.buscarPorId(idUsuario).orElse(null)
			
			if (pregunta.estaActiva) {
				
				pregunta.responder(usuario, laRespuesta)
				repoRegistro.save(usuario.historial.last) //Se crea el registro en la base
				usuarioService.actualizar(usuario) //Actualizacion del historial	
				
				var String esRespuesta
				
				if(pregunta.esRespuestaCorrecta(laRespuesta)){
					esRespuesta = 'Correcto'				
				}else{
					esRespuesta = 'Incorrecto'
				}	
				
				return esRespuesta
			} else {
				return 'No puede responder esta pregunta ya que se encuentra inactiva'
			}
			
			
	}
	
	@Transactional
	def updatePreguntaById(UpdatePregunta updatePregunta, long idPregunta){
			
			repoPregunta.findById(idPregunta).map[pregunta | 
				pregunta => [ 
					opciones = updatePregunta.opciones
				]
				repoPregunta.save(pregunta)
			].orElseThrow([
				throw new ResponseStatusException(HttpStatus.NOT_FOUND, "La pregunta con ID = " + idPregunta + " no existe") // No se usa ResponseEntity porque no funciona con throw 
			])
	}
	
	@Transactional
	def void crearPregunta(@Valid Pregunta nuevaPregunta, long idAutor, int puntos){
			
			nuevaPregunta.autor = usuarioService.buscarPorId(idAutor).orElse(null)
			
			if (nuevaPregunta instanceof PreguntaSolidaria){
				nuevaPregunta.asignarPuntos(puntos)
			}
			repoPregunta.save(nuevaPregunta)
	}
	
}