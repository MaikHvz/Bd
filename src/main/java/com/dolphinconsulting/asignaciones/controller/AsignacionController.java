package com.dolphinconsulting.asignaciones.controller;

import com.dolphinconsulting.asignaciones.service.AsignacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@Controller
@RequiredArgsConstructor
public class AsignacionController {

    private final AsignacionService asignacionService;

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("mesActual", LocalDate.now().getMonthValue());
        model.addAttribute("anioActual", LocalDate.now().getYear());
        return "index";
    }

    @GetMapping("/asignaciones")
    public String verAsignaciones(@RequestParam(defaultValue = "0") int mes, 
                                 @RequestParam(defaultValue = "0") int anio,
                                 Model model) {
        if (mes == 0) mes = LocalDate.now().getMonthValue();
        if (anio == 0) anio = LocalDate.now().getYear();
        
        model.addAttribute("asignaciones", asignacionService.obtenerAsignaciones(mes, anio));
        model.addAttribute("mes", mes);
        model.addAttribute("anio", anio);
        return "asignaciones";
    }

    @GetMapping("/auditorias")
    public String verAuditorias(Model model) {
        model.addAttribute("auditorias", asignacionService.obtenerAuditorias());
        return "auditorias";
    }

    @PostMapping("/procesar")
    public String procesarAsignaciones(@RequestParam int mes, @RequestParam int anio, Model model) {
        try {
            asignacionService.procesarAsignaciones(mes, anio);
            model.addAttribute("mensaje", "Asignaciones procesadas correctamente");
        } catch (Exception e) {
            model.addAttribute("error", "Error al procesar asignaciones: " + e.getMessage());
        }
        return "redirect:/asignaciones?mes=" + mes + "&anio=" + anio;
    }
}