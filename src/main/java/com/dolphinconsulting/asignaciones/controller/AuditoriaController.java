package com.dolphinconsulting.asignaciones.controller;

import com.dolphinconsulting.asignaciones.service.AsignacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AuditoriaController {

    @Autowired(required = false)
    private AsignacionService asignacionService;

    @GetMapping("/auditorias")
    public String verAuditorias(Model model) {
        if (asignacionService != null) {
            model.addAttribute("auditorias", asignacionService.listarAuditorias());
        }
        return "auditorias";
    }
}