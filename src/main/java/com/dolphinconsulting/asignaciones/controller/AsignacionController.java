package com.dolphinconsulting.asignaciones.controller;

import com.dolphinconsulting.asignaciones.service.AsignacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Map;

@Controller
public class AsignacionController {

    @Autowired(required = false)
    private AsignacionService asignacionService;

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam("mes") Integer mes,
                           @RequestParam("anio") Integer anio) {
        if (asignacionService != null) {
            asignacionService.procesarAsignaciones(mes, anio);
            return "redirect:/asignaciones?mes=" + mes + "&anio=" + anio;
        }
        return "redirect:/?error=SinConexionBD";
    }

    @GetMapping("/asignaciones")
    public String asignaciones(@RequestParam("mes") Integer mes,
                               @RequestParam("anio") Integer anio,
                               @RequestParam(value = "run", required = false) String run,
                               Model model) {
        if (asignacionService != null) {
            List<Map<String, Object>> datos = asignacionService.listarAsignaciones(mes, anio, run);
            model.addAttribute("asignaciones", datos);
        }
        model.addAttribute("mes", mes);
        model.addAttribute("anio", anio);
        model.addAttribute("run", run);
        return "asignaciones";
    }

    @GetMapping("/buscar")
    public String buscar(@RequestParam("q") String q, Model model) {
        if (asignacionService != null) {
            List<Map<String, Object>> profesionales = asignacionService.buscarProfesionales(q);
            model.addAttribute("profesionales", profesionales);
        }
        model.addAttribute("q", q);
        return "index"; // reutilizamos index mostrando resultados debajo
    }
}