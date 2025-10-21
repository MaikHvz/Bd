package com.dolphinconsulting.asignaciones.controller;

import com.dolphinconsulting.asignaciones.service.AsignacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;

@Controller
public class PruebasController {

    @Autowired(required = false)
    private AsignacionService service;

    @GetMapping("/pruebas")
    public String pruebas() {
        return "pruebas";
    }

    @PostMapping("/pruebas/calcular-honorarios")
    public String calcularHonorarios(@RequestParam("sueldo") BigDecimal sueldo, Model model) {
        if (service != null) {
            BigDecimal valor = service.calcularHonorarios(sueldo);
            model.addAttribute("honorarios", valor);
            model.addAttribute("ok", true);
        }
        return "pruebas";
    }

    @PostMapping("/pruebas/calcular-asig-contrato")
    public String calcularAsigContrato(@RequestParam("codTpContrato") Integer codTpContrato,
                                       @RequestParam("honorarios") BigDecimal honorarios, Model model) {
        if (service != null) {
            BigDecimal valor = service.calcularAsigContrato(codTpContrato, honorarios);
            model.addAttribute("asigContrato", valor);
            model.addAttribute("ok", true);
        }
        return "pruebas";
    }

    @PostMapping("/pruebas/calcular-asig-profesion")
    public String calcularAsigProfesion(@RequestParam("codProfesion") Integer codProfesion,
                                        @RequestParam("sueldo") BigDecimal sueldo, Model model) {
        if (service != null) {
            BigDecimal valor = service.calcularAsigProfesion(codProfesion, sueldo);
            model.addAttribute("asigProfesion", valor);
            model.addAttribute("ok", true);
        }
        return "pruebas";
    }

    @PostMapping("/pruebas/calcular-asig-movilizacion")
    public String calcularAsigMov(@RequestParam("codComuna") Integer codComuna,
                                  @RequestParam("honorarios") BigDecimal honorarios, Model model) {
        if (service != null) {
            BigDecimal valor = service.calcularAsigMovilizacion(codComuna, honorarios);
            model.addAttribute("asigMovilizacion", valor);
            model.addAttribute("ok", true);
        }
        return "pruebas";
    }

    @PostMapping("/pruebas/trigger-actualizar-sueldo")
    public String triggerActualizar(@RequestParam("run") String run,
                                    @RequestParam("nuevoSueldo") BigDecimal nuevoSueldo,
                                    Model model) {
        if (service != null) {
            int filas = service.actualizarSueldo(run, nuevoSueldo);
            model.addAttribute("triggerOk", filas > 0);
            return "redirect:/auditorias";
        }
        return "redirect:/?error=SinConexionBD";
    }
}