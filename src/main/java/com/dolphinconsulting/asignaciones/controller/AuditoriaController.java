package com.dolphinconsulting.asignaciones.controller;

import com.dolphinconsulting.asignaciones.service.AsignacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/auditorias")
public class AuditoriaController {

    private final AsignacionService asignacionService;

    @Autowired
    public AuditoriaController(AsignacionService asignacionService) {
        this.asignacionService = asignacionService;
    }

    @GetMapping
    public String mostrarAuditorias(Model model) {
        model.addAttribute("auditorias", asignacionService.obtenerAuditorias());
        return "auditorias";
    }
}