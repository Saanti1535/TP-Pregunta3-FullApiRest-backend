package phm.controller

import org.springframework.web.bind.annotation.RestController
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.beans.factory.annotation.Autowired
import phm.domain.PreguntaDTO
import javax.transaction.Transactional
import phm.service.PreguntaService
import phm.domain.UpdatePregunta
import phm.domain.Pregunta
import org.bson.types.ObjectId
import phm.repository.PreguntaActivaRepository
import java.util.List

@RestController
@CrossOrigin
class ControllerPregunta {

	@Autowired
	PreguntaService preguntaService

	@Autowired
	PreguntaActivaRepository repoPreguntasActivas

	@GetMapping("/busqueda/preguntas")
	def getTodasLasPreguntas() {
		val todasLasPreguntas = preguntaService.getTodasLasPreguntasDTO()
		todasLasPreguntas
	}

	// Preguntas filtradas por la pregunta misma
	@PostMapping("/busqueda/preguntas")
	def preguntasFiltradas(@RequestBody String unaBusqueda) {
		var busqueda = Mapper.extraerStringDeJson(unaBusqueda, "unaBusqueda")
		var soloActivas = Mapper.extraerBooleanDeJson(unaBusqueda, "soloActivas")
		var List<PreguntaDTO> preguntas
		//Redis no soporta búsquedas "parciales" usando el containing, sólo exactas.
		//Como no tiene sentido buscar por pregunta exacta, sólo usamos redis para cuando se quieren las activas sin filtrar por pregunta
		preguntas = soloActivas ? preguntaService.getPreguntasActivasFiltradas(busqueda) : preguntaService.getPreguntasFiltradas(busqueda, soloActivas)
		return preguntas
	}

	@GetMapping("/busqueda/pregunta/{id}/{idUsuario}")
	def preguntaPorId(@PathVariable String id, @PathVariable long idUsuario) {
		val _id = new ObjectId(id)
		val pregunta = preguntaService.getPreguntaPorId(_id, idUsuario)
		return pregunta
	}

	@Transactional
	@PostMapping("/revisarRespuesta/{idPregunta}")
	def revisarRespuesta(@RequestBody String respuesta, @PathVariable String idPregunta) {
		var laRespuesta = Mapper.extraerStringDeJson(respuesta, "laRespuesta")
		var idUsuario = Mapper.extraerLongDeJson(respuesta, "idUsuario")

		preguntaService.verificarRespuesta(laRespuesta, idPregunta, idUsuario)
	}

	@PutMapping("/busqueda/pregunta/{id}")
	def updatePreguntaPorId(@RequestBody String body, @PathVariable String id) {
		val updatePregunta = Mapper.mapear.readValue(body, UpdatePregunta)
		preguntaService.updatePreguntaById(updatePregunta, id)
		ResponseEntity.ok().build
	}

	@PutMapping("/crearPregunta/{puntos}")
	def crearPregunta(@RequestBody String body, @PathVariable int puntos) {
		val nuevaPregunta = Mapper.mapear.readValue(body, Pregunta)
		preguntaService.crearPregunta(nuevaPregunta, puntos)
	}

}
